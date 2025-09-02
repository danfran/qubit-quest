import 'dart:math';

class QQFraction {
  final String? sign;
  final int? numerator;
  final int? denominator;
  final double? decimalValue;
  final String? radicalTeX;

  // Constructor for a traditional fraction.
  const QQFraction.asFraction({this.sign = '', required this.numerator, required this.denominator, this.decimalValue, this.radicalTeX});

  // Constructor for a decimal fallback.
  const QQFraction.asDecimal({required this.decimalValue})
      : sign = null, numerator = null, denominator = null, radicalTeX = null;

  // Constructor for a radical number.
  const QQFraction.asRadical({required this.radicalTeX})
      : sign = null, numerator = null, denominator = null, decimalValue = null;

  bool get isDecimal => numerator == null && radicalTeX == null;
  bool get isRadical => radicalTeX != null;

  // Map of common irrational values for direct lookup
  static final Map<double, String> _radicalLookups = {
    sqrt(2): '\\sqrt{2}',
    1 / sqrt(2): '\\frac{1}{\\sqrt{2}}',
    sqrt(3): '\\sqrt{3}',
    1 / sqrt(3): '\\frac{1}{\\sqrt{3}}',
    sqrt(5): '\\sqrt{5}',
    1 / sqrt(5): '\\frac{1}{\\sqrt{5}}',
    pi: '\\pi',
  };

  static int gcd(int a, int b) {
    while (b != 0) {
      int t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  // This function now returns a Fraction object with its components.
  factory QQFraction.doubleToFraction(double value) {
    if (value == 0.0) {
      return const QQFraction.asFraction(numerator: 0, denominator: 1);
    }

    String sign = '';
    if (value < 0) {
      sign = '-';
      value = -value;
    }

    double valAbs = value.abs();

    // A slightly larger epsilon to handle common floating point errors
    const double epsilon = 1.0e-11;

    // Handle common radical numbers via direct lookup
    for (final entry in _radicalLookups.entries) {
      if ((valAbs - entry.key).abs() < epsilon) {
        return QQFraction.asRadical(radicalTeX: entry.value);
      }
    }

    // Handle integers directly
    if ((valAbs - valAbs.round()).abs() < epsilon) {
      return QQFraction.asFraction(
        sign: sign,
        numerator: valAbs.round(),
        denominator: 1,
      );
    }

    // A fixed-precision approach to convert decimals to fractions
    int numerator = (valAbs * 10000000).round();
    int denominator = 10000000;

    // Simplify the fraction
    int commonDivisor = gcd(numerator, denominator);
    numerator = (numerator ~/ commonDivisor);
    denominator = (denominator ~/ commonDivisor);

    // Fallback to decimal if the approximation is not good enough
    if ((numerator / denominator - valAbs).abs() > epsilon) {
      return QQFraction.asDecimal(decimalValue: value);
    }

    return QQFraction.asFraction(
      sign: sign,
      numerator: numerator,
      denominator: denominator,
    );
  }

  @override
  String toString() {
    if (isDecimal) {
      return decimalValue!.toStringAsFixed(4);
    } else if (numerator == 0) {
      return '0';
    } else if (denominator == 1) {
      // Handle whole numbers without a fraction line.
      return '$sign$numerator';
    }
    return '$sign$numerator/$denominator';
  }

  // A new method to return the LaTeX string representation.
  String toTeXString() {
    if (isRadical) {
      return radicalTeX!;
    }

    if (isDecimal) {
      // Return the decimal value as a string for the fallback.
      return decimalValue!.toStringAsFixed(4);
    } else if (numerator == 0) {
      // Handle zero case explicitly.
      return '0';
    } else if (denominator == 1) {
      // Handle whole numbers without a fraction line.
      return '$sign$numerator';
    }
    // Return the LaTeX formatted fraction using the \frac command.
    return '$sign\\frac{$numerator}{$denominator}';
  }
}