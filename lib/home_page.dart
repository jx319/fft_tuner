import 'dart:async';
import 'package:fft_tuner/equal_temperament_tuning.dart';
import 'package:fft_tuner/frequency_detector.dart';
import 'package:fft_tuner/gauge.dart';
import 'package:fft_tuner/plot.dart';
import 'package:fft_tuner/settings_page.dart';
import 'package:fft_tuner/tone.dart';
import 'package:fft_tuner/tuning.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title, required this.preferences});

  final String title;
  final SharedPreferencesWithCache preferences;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AudioRecorder recorder = AudioRecorder();
  Stream<Uint8List> stream = Stream.empty();
  bool recording = false;
  bool active = true;

  int fftSize = 8192;
  int sampleRate = 48000;
  late FrequencyDetector detector = FrequencyDetector(
    fftSize,
    sampleRate,
    widget.preferences.getInt("zeropad_factor") ?? 4,
  );
  late Tuning tuning = EqualTemperamentTuning(
    widget.preferences.getDouble("a4") ?? 440,
  );
  double tolerance = 3;
  int tonesToTrack = 5;
  double activationThreshold = -35;

  static int plotSpots = 2000;

  List<FlSpot> spectrumSpots = List.generate(
    plotSpots,
    (_) => FlSpot(double.nan, double.nan),
  );

  List<int> transformTimes = List.empty(growable: true);

  double spectrumFreq = 0.0;

  Tone currentRef = Tone.A4;
  List<Tone> pastTones = List.empty(growable: true);
  double centDelta = 0.0;

  List<int>? prevChunk;

  @override
  void initState() {
    super.initState();

    startRecording();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,

        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              setState(() {
                recorder.stop();
                recording = false;
              });
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsPage(preferences: widget.preferences),
                ),
              );
              // restart when the user returns from settings
              startRecording();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Gauge(value: centDelta, min: -50, max: 50, tolerance: tolerance),
            Text(
              "${centDelta > 0 ? "+" : ""}${centDelta.toStringAsFixed(1).replaceFirst(".", ",")}¢",
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_left,
                  size: 64,
                  color: centDelta > tolerance && active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
                Text(
                  currentRef.toStringDE(),
                  style: TextStyle(
                    fontSize: 32,
                    color: active
                        ? Theme.of(context).textTheme.displayLarge?.color ??
                              Colors.white
                        : Theme.of(context).disabledColor,
                  ),
                ),
                Icon(
                  Icons.arrow_right,
                  size: 64,
                  color: centDelta < -tolerance && active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
              ],
            ),

            if (widget.preferences.getBool("show_spectrum") ?? false)
              Center(
                child: Text(
                  "${(transformTimes.fold<int>(0, (prev, elem) => prev + elem) / transformTimes.length).toStringAsFixed(1)} µs",
                ),
              ),

            if (widget.preferences.getBool("show_spectrum") ?? false)
              Plot(spots: spectrumSpots, unitX: "Hz"),

            if (widget.preferences.getBool("show_spectrum") ?? false)
              Center(
                child: Text(
                  "${spectrumFreq.isFinite ? (spectrumFreq < 1000 ? "${spectrumFreq.toStringAsFixed(2)} " : "${(spectrumFreq / 1000).toStringAsFixed(2)} k").replaceFirst(".", ",") : "0,0 "}Hz",
                  style: TextStyle(fontSize: 48),
                ),
              ),

            if (widget.preferences.getBool("show_spectrum") ?? false)
              FloatingActionButton.extended(
                label: Text("Exportieren"),
                icon: Icon(Icons.share),
                onPressed: () {
                  String output = "f,Fx\n";

                  for (int i = 0; i < spectrumSpots.length; i++) {
                    if (!spectrumSpots[i].x.isFinite) break;
                    output += "${spectrumSpots[i].x},${spectrumSpots[i].y}\n";
                  }

                  SharePlus.instance.share(ShareParams(text: output));
                },
              ),
          ],
        ),
      ),
    );
  }

  void startRecording() async {
    fftSize = widget.preferences.getInt("window_length") ?? 8192;
    sampleRate = widget.preferences.getInt("sampling_rate") ?? 48000;
    detector = FrequencyDetector(
      fftSize,
      sampleRate,
      widget.preferences.getInt("zeropad_factor") ?? 4,
    );
    tuning = EqualTemperamentTuning(widget.preferences.getDouble("a4") ?? 440);
    prevChunk = null;
    tolerance = (widget.preferences.getInt("tolerance") ?? 3).toDouble();
    activationThreshold =
        widget.preferences.getDouble("activation_threshold") ?? -35;

    setState(() {
      spectrumSpots = List.generate(
        plotSpots,
        (_) => FlSpot(double.nan, double.nan),
      );
    });

    if (await recorder.hasPermission() && !await recorder.isRecording()) {
      stream = await recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          streamBufferSize: kIsWeb ? fftSize ~/ 2 : fftSize * 2,
        ),
      );

      recorder.onAmplitudeChanged(Duration(milliseconds: 250)).listen((
        Amplitude amplitude,
      ) {
        if (amplitude.current <= activationThreshold) {
          setState(() {
            active = false;
          });
        } else {
          setState(() {
            active = true;
          });
        }
      });

      stream.listen(streamChunkCallback);

      setState(() {
        recording = true;
      });
    }
  }

  void streamChunkCallback(Uint8List chunk) {
    if (!active) return;
    final stopwatch = Stopwatch()..start();

    // PCM 16bit
    final int16Data = recorder.convertBytesToInt16(chunk);

    if (prevChunk != null) {
      var halfLength = int16Data.length ~/ 2;
      var overlapped =
          prevChunk!.skip(halfLength).toList() +
          int16Data.take(halfLength).toList();

      detector.analyse(overlapped);
      updateState();
    }

    detector.analyse(int16Data);
    prevChunk = int16Data;

    updateState();

    setState(() {
      transformTimes.add(stopwatch.elapsedMicroseconds);
      // print("Took ${stopwatch.elapsedMicroseconds} µs");
    });
  }

  void updateState() {
    setState(() {
      var spectrum = detector.getSpectrum();
      for (int n = 0; n < plotSpots; n++) {
        double freq = FrequencyDetector.indexToFreq(
          n,
          spectrum.length,
          sampleRate,
        );
        if (freq < 2000) {
          spectrumSpots[n] = FlSpot(freq, spectrum[n]);
        }
      }

      spectrumFreq = detector.getFundamental();

      var closest = tuning.closestTone(spectrumFreq);
      pastTones.add(closest);
      if (pastTones.length > tonesToTrack) {
        pastTones.removeAt(0);
      }

      // only switch to new tone if it shows up often enough
      if (pastTones.every((element) => element == closest)) {
        currentRef = closest;
      }

      centDelta = tuning.compare(spectrumFreq, currentRef);
      if (!centDelta.isFinite) centDelta = 0.0;
    });
  }

  @override
  void dispose() {
    recorder.stop();
    recorder.dispose();
    super.dispose();
  }
}
