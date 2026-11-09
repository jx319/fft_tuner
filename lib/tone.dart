enum ToneName { C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B }

class Tone {
  // semitones from C0
  late int semitones;

  static Tone A4 = Tone(ToneName.A, 4);

  Tone.fromSemitones(this.semitones);

  Tone(ToneName name, int octave) {
    semitones = 12 * octave;
    semitones += name.index;
  }

  @override
  String toString() => "${getName().name}${getOctave()}";

  // convert to a string in german notation
  String toStringDE() {
    String ret = "";
    String convertName(String name) {
      if (name.length > 1) {
        switch (name[0]) {
          case 'D':
            return "Des";
          case 'E':
            return "Es";
          case 'G':
            return "Ges";
          case 'A':
            return "As";
          case 'B':
            return "B";
        }
      } else if (name == "B") {
        return "H";
      }

      return name;
    }

    final unicodeMap = {
      // superscript  subscript
      '1': ('\u00B9', '\u2081'),
      '2': ('\u00B2', '\u2082'),
      '3': ('\u00B3', '\u2083'),
      '4': ('\u2074', '\u2084'),
      '5': ('\u2075', '\u2085'),
      '6': ('\u2076', '\u2086'),
      '7': ('\u2077', '\u2087'),
      '8': ('\u2078', '\u2088'),
      '9': ('\u2079', '\u2089'),
    };

    switch (getOctave()) {
      case >= 3:
        ret =
            convertName(getName().name).toLowerCase() +
            (unicodeMap[(getOctave() - 3).toString()]?.$1 ?? "");
        break;
      case <= 2:
        ret =
            convertName(getName().name) +
            (unicodeMap[(-getOctave() + 2).abs().toString()]?.$2 ?? "");
        break;
    }

    return ret;
  }

  ToneName getName() {
    int mod = semitones % 12;

    return ToneName.values[mod >= 0 ? mod : 12 - mod];
  }

  int getOctave() => semitones ~/ 12;

  Tone operator +(int x) => Tone.fromSemitones(semitones + x);
  Tone operator -(int x) => Tone.fromSemitones(semitones - x);
  @override
  bool operator ==(other) => other is Tone && semitones == other.semitones;

  @override
  int get hashCode => semitones;
}
