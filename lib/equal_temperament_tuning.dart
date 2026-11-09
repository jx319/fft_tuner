import 'dart:math';

import 'tuning.dart';
import 'tone.dart';

class EqualTemperamentTuning extends Tuning {
  EqualTemperamentTuning(double a4) {
    this.a4 = a4;
  }

  @override
  double compare(double frequency, Tone reference) {
    return _ratioToCents(frequency / toFreq(reference));
  }

  @override
  Tone closestTone(double frequency) {
    double interval = _ratioToCents(frequency / a4);

    return Tone(ToneName.A, 4) +
        (interval.isFinite ? (interval / 100).round() : 0);
  }

  @override
  double toFreq(Tone tone) {
    int interval = tone.semitones - Tone.A4.semitones;

    return a4 * pow(2, interval * 100 / 1200);
  }

  double _ratioToCents(double p) => 1200 * log(p) / ln2;
}
