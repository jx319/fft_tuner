import 'dart:math';

import 'package:fft_tuner/harmonic.dart';

import 'complex.dart';
import 'fft.dart';

class FrequencyDetector {
  final int fftSize;
  int zeropadFactor = 4;
  final int sampleRate;
  final int avgCount = 20;
  int outlierCount = 0;

  List<Complex> prevSpectrum = List.empty();
  List<Complex> spectrum = List.empty();
  List<double> dBSpectrum = List.empty();
  List<double> harmonicSum = List.empty();
  List<double> prevFreqs = List.empty(growable: true);

  late FFT _fft;
  late List<double> _gaussList;

  late Stopwatch smoothingWatch;

  FrequencyDetector(this.fftSize, this.sampleRate, this.zeropadFactor) {
    _fft = FFT(fftSize * zeropadFactor ~/ 2);
    smoothingWatch = Stopwatch();

    // https://ccrma.stanford.edu/~jos/sasp/Matlab_Gaussian_Window.html
    double sigma = fftSize / 8;
    _gaussList = List.generate(
      fftSize,
      (i) => exp(-(i - fftSize / 2) * (i - fftSize / 2) / (2 * sigma * sigma)),
    );
  }

  void analyse(List<int> pcmSamples) {
    // [-32768, +32767] -> [-1.0, +1.0]
    var realSamples = List<double>.generate(
      pcmSamples.length,
      (i) => pcmSamples[i] / 32767.0,
    );

    realSamples = applyGaussWindow(realSamples);

    var positive = realSamples.skip(realSamples.length ~/ 2).toList();
    var negative = realSamples.take(realSamples.length ~/ 2).toList();
    // zeropadding
    positive.addAll(
      List.generate(realSamples.length * (zeropadFactor - 1), (_) => 0),
    );

    positive.addAll(negative);
    realSamples = positive;

    prevSpectrum = spectrum;
    spectrum = _fft.realTransform(realSamples).toList();
    spectrum[0].imaginary = 0; // see realTransform definition

    dBSpectrum = spectrum.map((z) => toDecibels(z.absSquare())).toList();
  }

  double getFundamental() {
    var maxF = spectrum.reduce(
      (value, element) => element.abs() > value.abs() ? element : value,
    );

    int index = spectrum.indexOf(maxF);

    double ret = indexToFreq(index, spectrum.length, sampleRate);

    harmonicSum = _harmonicSum(spectrum.map((z) => z.abs()).toList(), 4);

    var maxHarmonicSum = harmonicSum.reduce(
      (value, element) => element > value ? element : value,
    );

    index = harmonicSum.indexOf(maxHarmonicSum);

    var harmonics = _scanForHarmonics(index, 6);

    ret = indexToFreq(
      _interpolateQuad(index, dBSpectrum),
      dBSpectrum.length,
      sampleRate,
    );
    // print("interpolated: $ret Hz");

    ret = _fitHarmonics(harmonics);
    // print("fitted: $ret Hz");

    ret = _smoothenFrequencyResults(ret);

    return ret;
  }

  double _smoothenFrequencyResults(double next) {
    double ret = 0.0;
    if (smoothingWatch.elapsedMilliseconds > 500) {
      _resetPrevFreqs(next);
      ret = next;
    } else if (prevFreqs.isNotEmpty) {
      double avg =
          prevFreqs.fold(0.0, (sum, element) => sum += element) /
          prevFreqs.length;

      double deviation = (next - avg).abs() / avg;

      if (deviation >= 0.1) {
        // discard this result as it is too far off the other ones
        ret = avg;
        outlierCount++;
        if (outlierCount > 5) {
          _resetPrevFreqs(next);
          ret = avg;
        }
      } else {
        outlierCount = 0;
        prevFreqs.add(next);
        if (prevFreqs.length > avgCount) {
          prevFreqs.removeAt(0);
        }

        ret =
            prevFreqs.fold(0.0, (sum, element) => sum += element) /
            prevFreqs.length;
      }
    }

    smoothingWatch.reset();
    smoothingWatch.start();

    return ret;
  }

  void _resetPrevFreqs(double newFirst) {
    prevFreqs = List.empty(growable: true);
    prevFreqs.add(newFirst);
  }

  List<double> getSpectrum() => spectrum.map((z) => z.abs()).toList();

  static List<Complex> applyHannWindow(List<Complex> data) {
    for (int i = 0; i < data.length; i++) {
      data[i].real *= 0.5 * (1 - cos(2 * pi * i / (data.length - 1)));
    }
    return data;
  }

  List<double> applyGaussWindow(List<double> data) {
    for (int i = 0; i < data.length; i++) {
      data[i] *= _gaussList[i];
    }
    return data;
  }

  static double indexToFreq(num index, int length, int sampleRate) =>
      index / length * sampleRate;

  static double toDecibels(double p) => 20 * log(p / 0.00002) / ln10;

  static bool isLocalMax(int index, List<double> list) {
    if (index == 0 || index >= list.length - 1) return false;
    return list[index - 1] < list[index] && list[index + 1] < list[index];
  }

  // https://ccrma.stanford.edu/%7Ejos/sasp/Quadratic_Interpolation_Spectral_Peaks.html
  double _interpolateQuad(int index, List<double> data) {
    if (index == 0 || index == data.length - 1) {
      return index.toDouble();
    }

    double alpha = data[index - 1];
    double beta = data[index];
    double gamma = data[index + 1];

    double p = (alpha - gamma) / (2 * (alpha - (2 * beta) + gamma));

    return index + p;
  }

  /// Scan for peaks at integer multiples of a given fundamental (harmonics/overtones)
  List<Harmonic> _scanForHarmonics(int fundamentalIndex, int depth) {
    List<Harmonic> ret = List.empty(growable: true);

    ret.add(
      Harmonic(
        1,
        indexToFreq(
          _interpolateQuad(fundamentalIndex, dBSpectrum),
          dBSpectrum.length,
          sampleRate,
        ),
      ),
    );

    final double threshold = 0.3 * dBSpectrum[fundamentalIndex];
    final int radius = 5;

    for (int i = 2; i <= depth; i++) {
      int currentIndex = i * fundamentalIndex;

      if (dBSpectrum[currentIndex] >= threshold &&
          isLocalMax(currentIndex, dBSpectrum)) {
        ret.add(
          Harmonic(
            i,
            indexToFreq(
              _interpolateQuad(currentIndex, dBSpectrum),
              dBSpectrum.length,
              sampleRate,
            ),
          ),
        );
        continue;
      }

      final lowerLimit = max(0, currentIndex - radius);
      final upperLimit = min(currentIndex + radius, dBSpectrum.length);

      for (
        currentIndex = lowerLimit;
        currentIndex <= upperLimit;
        currentIndex++
      ) {
        if (dBSpectrum[currentIndex] >= threshold &&
            isLocalMax(currentIndex, dBSpectrum)) {
          ret.add(
            Harmonic(
              i,
              indexToFreq(
                _interpolateQuad(currentIndex, dBSpectrum),
                dBSpectrum.length,
                sampleRate,
              ),
            ),
          );
          break;
        }
      }
    }

    return ret;
  }

  /// least square fitting/linear regression for harmonics of a fundamental
  double _fitHarmonics(List<Harmonic> harmonics) {
    double avgX =
        harmonics.fold(0.0, (sum, harmonic) => sum + harmonic.order) /
        harmonics.length;
    double avgY =
        harmonics.fold(0.0, (sum, harmonic) => sum + harmonic.frequency) /
        harmonics.length;

    double denominator = harmonics.fold(
      0.0,
      (sum, harmonic) => sum + pow(harmonic.order - avgX, 2),
    );
    double slope =
        harmonics.fold(
          0.0,
          (sum, harmonic) =>
              sum + (harmonic.order - avgX) * (harmonic.frequency - avgY),
        ) /
        (denominator != 0 ? denominator : 1);

    return slope;
  }

  /// Sum downsampled versions of the spectrum with itself to reveal f0
  List<double> _harmonicSum(List<double> spectrum, int downsampleCount) {
    List<double> ret = spectrum.toList();
    for (int n = 2; n <= downsampleCount; n++) {
      for (int i = 0; i < ret.length; i++) {
        int index = n * i;
        ret[i] += index < spectrum.length ? spectrum[index] : 0.0;
      }
    }

    return ret
        .map((e) => pow(e, 1 / (downsampleCount + 1)).toDouble())
        .map((e) => e.isFinite ? e : 0.0)
        .toList();
  }
}
