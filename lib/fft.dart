// ignore_for_file: non_constant_identifier_names

import 'dart:math';
import 'dart:typed_data';

import 'complex.dart';

class FFT {
  final int N;
  late final int gamma;

  late final List<Complex> WP;
  late final List<Complex> A;
  late final List<Complex> B;

  FFT(this.N) {
    if (N & (N - 1) != 0) {
      throw ArgumentError("$N is not a power of two");
    }

    // N = 2^gamma
    gamma = log(N) ~/ ln2;

    print("FFT: N = $N, gamma = $gamma");

    // pregenerate reusable factors
    WP = List.generate(N, (_) => Complex(0, 0));
    A = List.generate(N, (_) => Complex(0, 0));
    B = List.generate(N, (_) => Complex(0, 0));

    for (int k = 0; k < N; k++) {
      double WParg = 2 * pi * k / N;
      WP[k] = Complex(cos(WParg), -sin(WParg));

      double ABarg = WParg / 2;
      Complex ABW = Complex(cos(ABarg), -sin(ABarg));
      A[k] = Complex(0.5, 0) - ABW * Complex(0, 0.5);
      B[k] = Complex(0.5, 0) + ABW * Complex(0, 0.5);
    }
  }

  List<Complex> transform(List<Complex> data) {
    if (data.length != N) {
      throw ArgumentError("data.length (${data.length}) != N ($N)");
    }

    int l = 1;
    int N2 = N ~/ 2;
    int NU1 = gamma - 1;
    int k = 0;

    while (l <= gamma) {
      do {
        int I = 0;

        do {
          I++;
          int M = k ~/ pow(2, NU1);
          int P = bitReverse(M, gamma);

          Complex T1 = WP[P] * data[k + N2];
          data[k + N2] = data[k] - T1;
          data[k] += T1;

          k++;
        } while (I != N2);

        k += N2;
      } while (k < N - 1);

      l++;
      N2 ~/= 2;
      NU1--;
      k = 0;
    }

    for (k = 0; k != N - 1; k++) {
      int i = bitReverse(k, gamma);

      if (i > k) {
        Complex T3 = data[k];
        data[k] = data[i];
        data[i] = T3;
      }
    }

    return data;
  }

  List<Complex> realTransform(List<double> data) {
    if (data.length != 2 * N) {
      throw ArgumentError("data.length (${data.length}) != 2N (${2 * N})");
    }

    List<Complex> input = List.generate(
      N,
      (k) => Complex(data[2 * k], data[(2 * k) + 1]),
    );

    var transformed = transform(input);

    var ret = List.generate(
      N,
      (n) =>
          (transformed[n] * A[n]) +
          (transformed[(N - n) % N].conjugate() * B[n]),
    );

    // bin N (Nyquist frequency) is needed by the inverse,
    // so store it in the imaginary part which is 0 otherwise
    ret[0] = Complex(
      ret[0].real,
      transformed[0].real - transformed[0].imaginary,
    );

    return ret;
  }

  List<Complex> inverseTransform(List<Complex> data) {
    final scale = Complex(1 / data.length, 0);
    var conjugates = data.map((z) => z.conjugate()).toList();
    return transform(conjugates).map((z) => z.conjugate() * scale).toList();
  }

  List<double> inverseRealTransform(List<Complex> data) {
    // retrieve the Nth value
    final g0 = data[0].real;
    final gN = data[0].imaginary;

    Complex getAt(int k) =>
        k == 0 ? Complex(g0, 0) : (k == N ? Complex(gN, 0) : data[k]);

    List<Complex> input = List.generate(
      N,
      (n) =>
          (getAt(n) * A[n].conjugate()) +
          (getAt(N - n).conjugate() * B[n].conjugate()),
    );

    var transformed = inverseTransform(input);

    List<double> ret = List.filled(2 * N, 0);
    for (int k = 0; k < N; k++) {
      ret[2 * k] = transformed[k].real;
      ret[(2 * k) + 1] = transformed[k].imaginary;
    }

    return ret;
  }

  static int bitReverse(int n, int length) {
    int ret = 0;

    for (int i = 0; i < length; i++) {
      ret <<= 1;

      if (n & 1 == 1) ret |= 1;

      n >>= 1;
    }

    return ret;
  }
}
