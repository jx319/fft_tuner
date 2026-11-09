class Harmonic {
  int order;
  double frequency;

  Harmonic(this.order, this.frequency);

  @override
  String toString() => "#$order - $frequency Hz";
}
