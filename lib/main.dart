import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fft_tuner/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesWithCache preferences =
      await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions(),
      );
  runApp(TunerApp(preferences: preferences));
}

class TunerApp extends StatelessWidget {
  const TunerApp({super.key, required this.preferences});
  final SharedPreferencesWithCache preferences;

  @override
  Widget build(BuildContext context) {
    final sliderTheme = SliderThemeData(
      // ignore: deprecated_member_use
      year2023: false,
    );
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) =>
          MaterialApp(
            title: 'Stimmgerät',
            theme: ThemeData(
              colorScheme:
                  lightDynamic ??
                  ColorScheme.fromSeed(seedColor: Colors.lightBlue),
              useMaterial3: true,
              sliderTheme: sliderTheme,
            ),
            darkTheme: ThemeData(
              colorScheme:
                  darkDynamic ??
                  ColorScheme.fromSeed(seedColor: Colors.lightBlue),
              useMaterial3: true,
              sliderTheme: sliderTheme,
            ),
            home: HomePage(title: 'Stimmgerät', preferences: preferences),
          ),
    );
  }
}
