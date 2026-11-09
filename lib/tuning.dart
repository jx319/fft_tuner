import 'tone.dart';

abstract class Tuning {
  double a4 = 440;

  double compare(double frequency, Tone reference);
  Tone closestTone(double frequency);
  double toFreq(Tone tone);
}
