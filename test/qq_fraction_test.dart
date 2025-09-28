import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/utils/qq_fraction.dart'; // Adjust this path if your main.dart file is in a different location.

void main() {
  group('doubleToFractionTeX', () {
    test('converts 0.5 to 1/2', () {
      final fraction = QQFraction.doubleToFractionTeX(0.5);
      expect(fraction.numerator, 1);
      expect(fraction.denominator, 2);
    });

    test('converts 0.75 to 3/4', () {
      final fraction = QQFraction.doubleToFractionTeX(0.75);
      expect(fraction.numerator, 3);
      expect(fraction.denominator, 4);
    });

    test('converts 1.0 to a whole number 1', () {
      final fraction = QQFraction.doubleToFractionTeX(1.0);
      expect(fraction.numerator, 1);
      expect(fraction.denominator, 1);
    });

    test('converts 0.0 to 0/1', () {
      final fraction = QQFraction.doubleToFractionTeX(0.0);
      expect(fraction.numerator, 0);
      expect(fraction.denominator, 1);
    });

    test('converts a negative number -0.25 to a negative fraction', () {
      final fraction = QQFraction.doubleToFractionTeX(-0.25);
      expect(fraction.sign, '-');
      expect(fraction.numerator, 1);
      expect(fraction.denominator, 4);
    });

    test('correctly identifies 0.707 as 1/sqrt(2)', () {
      final fraction = QQFraction.doubleToFractionTeX(0.7071067811865476);
      expect(fraction.isRadical, isTrue);
      expect(fraction.radicalTeX, '\\frac{1}{\\sqrt{2}}');
    });

    test('correctly identifies -0.707 as -1/sqrt(2)', () {
      final fraction = QQFraction.doubleToFractionTeX(-0.7071067811865476).toTeXString();
      expect(fraction, '\\frac{1}{\\sqrt{2}}');
    });

    test('correctly identifies 1.414 as sqrt(2)', () {
      final fraction = QQFraction.doubleToFractionTeX(1.41421356237);
      expect(fraction.isRadical, isTrue);
      expect(fraction.radicalTeX, '\\sqrt{2}');
    });

    test('correctly converts 0.12345 to a fraction', () {
      final fraction = QQFraction.doubleToFractionTeX(0.12345);
      expect(fraction.isDecimal, isFalse);
      expect(fraction.numerator, 2469);
      expect(fraction.denominator, 20000);
    });

    test('falls back to decimal for a non-convertible number', () {
      // This number is chosen to not have a simple fractional representation
      final fraction = QQFraction.doubleToFractionTeX(0.31415926535);
      expect(fraction.isDecimal, isTrue);
      expect(fraction.decimalValue, 0.31415926535);
    });
  });

  group('doubleToFractionString', () {
    test('converts 0.5 to 1/2', () {
      final fraction = QQFraction.doubleToFractionString(0.5);
      expect(fraction.numerator, 1);
      expect(fraction.denominator, 2);
    });

    test('converts 0.75 to 3/4', () {
      final fraction = QQFraction.doubleToFractionString(0.75);
      expect(fraction.numerator, 3);
      expect(fraction.denominator, 4);
    });

    test('converts 1.0 to a whole number 1', () {
      final fraction = QQFraction.doubleToFractionString(1.0);
      expect(fraction.numerator, 1);
      expect(fraction.denominator, 1);
    });

    test('converts 0.0 to 0/1', () {
      final fraction = QQFraction.doubleToFractionString(0.0);
      expect(fraction.numerator, 0);
      expect(fraction.denominator, 1);
    });

    test('converts a negative number -0.25 to a negative fraction', () {
      final fraction = QQFraction.doubleToFractionString(-0.25);
      expect(fraction.sign, '-');
      expect(fraction.numerator, 1);
      expect(fraction.denominator, 4);
    });

    test('correctly identifies 0.707 as 1/sqrt(2)', () {
      final fraction = QQFraction.doubleToFractionString(0.7071067811865476);
      expect(fraction.isRadical, isTrue);
      expect(fraction.radicalTeX, '1/√2');
    });

    test('correctly identifies 1.414 as sqrt(2)', () {
      final fraction = QQFraction.doubleToFractionString(1.41421356237);
      expect(fraction.isRadical, isTrue);
      expect(fraction.radicalTeX, '√2');
    });

    test('correctly converts 0.12345 to a fraction', () {
      final fraction = QQFraction.doubleToFractionString(0.12345);
      expect(fraction.isDecimal, isFalse);
      expect(fraction.numerator, 2469);
      expect(fraction.denominator, 20000);
    });

    test('falls back to decimal for a non-convertible number', () {
      // This number is chosen to not have a simple fractional representation
      final fraction = QQFraction.doubleToFractionString(0.31415926535);
      expect(fraction.isDecimal, isTrue);
      expect(fraction.decimalValue, 0.31415926535);
    });
  });

  group('Fraction.toTeXString', () {
    test('formats a regular fraction correctly', () {
      const fraction = QQFraction.asFraction(numerator: 1, denominator: 2);
      expect(fraction.toTeXString(), '\\frac{1}{2}');
    });

    test('formats a whole number correctly', () {
      const fraction = QQFraction.asFraction(numerator: 5, denominator: 1);
      expect(fraction.toTeXString(), '5');
    });

    test('formats a negative fraction correctly', () {
      const fraction = QQFraction.asFraction(sign: '-', numerator: 3, denominator: 4);
      expect(fraction.toTeXString(), '\\frac{3}{4}');
    });

    test('formats a radical fraction correctly', () {
      const fraction = QQFraction.asRadical(radicalTeX: '\\frac{1}{\\sqrt{2}}');
      expect(fraction.toTeXString(), '\\frac{1}{\\sqrt{2}}');
    });

    test('formats a decimal fallback correctly', () {
      const fraction = QQFraction.asDecimal(decimalValue: 0.1234567);
      expect(fraction.toTeXString(), '0.1235');
    });

    test('formats zero correctly', () {
      const fraction = QQFraction.asFraction(numerator: 0, denominator: 1);
      expect(fraction.toTeXString(), '0');
    });
  });
}
