import 'dart:math';

class Complex {
  double real = 0.0;
  double imaginary = 0.0;

  Complex(this.real, this.imaginary);

  Complex operator +(Complex z) =>
      Complex(real + z.real, imaginary + z.imaginary);
  Complex operator -(Complex z) =>
      Complex(real - z.real, imaginary - z.imaginary);

  Complex operator *(Complex z) => Complex(
    real * z.real - imaginary * z.imaginary,
    real * z.imaginary + imaginary * z.real,
  );

  double abs() => sqrt(pow(real, 2) + pow(imaginary, 2));
  double absSquare() => (pow(real, 2) + pow(imaginary, 2)).toDouble();

  Complex conjugate() => Complex(real, -imaginary);

  @override
  String toString() =>
      "$real${imaginary >= 0 ? " + " : " - "}${imaginary.abs()}i";
}
