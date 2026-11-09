import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.preferences});
  final SharedPreferencesWithCache preferences;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = TextStyle(
      fontSize: 20,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text("Einstellungen"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        child: Material(
          child: Column(
            children: [
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.music_note_rounded),
                title: Text("Kammerton"),
                titleTextStyle: titleStyle,
                trailing: SizedBox(
                  width: 145,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          "a\u00B9 =",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      SizedBox(
                        width: 75,
                        child: TextField(
                          textAlign: TextAlign.end,
                          keyboardType: TextInputType.number,
                          controller: TextEditingController.fromValue(
                            TextEditingValue(
                              text: (widget.preferences.getDouble("a4") ?? 440)
                                  .toString(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          "Hz",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.exposure_rounded),
                title: Text("Toleranz"),
                subtitle: Text(
                  "±${widget.preferences.getInt("tolerance") ?? 3} ¢",
                ),
                titleTextStyle: titleStyle,
              ),
              Slider(
                value: (widget.preferences.getInt("tolerance") ?? 3).toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (newV) {
                  setState(() {
                    widget.preferences.setInt("tolerance", newV.round());
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.volume_up_rounded),
                title: Text("Aktivierungsschwelle"),
                subtitle: Text(
                  "${(widget.preferences.getDouble("activation_threshold") ?? -35.0).toStringAsFixed(1)} dBFS",
                ),
                titleTextStyle: titleStyle,
              ),
              Slider(
                value:
                    widget.preferences.getDouble("activation_threshold") ??
                    -35.0,
                min: -100,
                max: 0,
                onChanged: (newV) {
                  setState(() {
                    widget.preferences.setDouble("activation_threshold", newV);
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.mic_rounded),
                title: Text("Abtastrate"),
                subtitle: Text(
                  "${widget.preferences.getInt("sampling_rate") ?? 48000} Hz",
                ),
                titleTextStyle: titleStyle,
              ),
              Slider(
                value: (widget.preferences.getInt("sampling_rate") ?? 48000)
                    .toDouble(),
                min: 8000,
                max: 96000,
                onChanged: (newV) {
                  setState(() {
                    widget.preferences.setInt(
                      "sampling_rate",
                      (newV / 100).round() * 100,
                    );
                  });
                },
              ),
              ListTile(
                title: Text("Erweitert"),
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                contentPadding: EdgeInsetsGeometry.only(left: 20),
              ),
              SwitchListTile(
                title: Row(
                  children: [
                    Icon(Icons.equalizer_rounded),
                    SizedBox(width: 15),
                    Text("Spektrum anzeigen", style: titleStyle),
                  ],
                ),
                value: widget.preferences.getBool("show_spectrum") ?? false,
                onChanged: (newV) {
                  setState(() {
                    widget.preferences.setBool("show_spectrum", newV);
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.width_full_outlined),
                title: Text("Fensterlänge"),
                subtitle: Text(
                  "${widget.preferences.getInt("window_length") ?? 8192} Samples",
                ),
                titleTextStyle: titleStyle,
              ),
              Slider(
                value:
                    log(
                      (widget.preferences.getInt("window_length") ?? 8192)
                          .toDouble(),
                    ) /
                    ln2,
                min: 10,
                max: 16,
                divisions: 6,
                onChanged: (newV) {
                  setState(() {
                    widget.preferences.setInt(
                      "window_length",
                      pow(2, newV).round(),
                    );
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.exposure_zero_rounded),
                title: Text("Zero-Padding-Faktor"),
                subtitle: Text(
                  "${widget.preferences.getInt("zeropad_factor") ?? 4}",
                ),
                titleTextStyle: titleStyle,
              ),
              Slider(
                value:
                    log(widget.preferences.getInt("zeropad_factor") ?? 4) / ln2,
                min: 0,
                max: 3,
                divisions: 3,
                onChanged: (newV) {
                  setState(() {
                    widget.preferences.setInt(
                      "zeropad_factor",
                      pow(2, newV).round(),
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
