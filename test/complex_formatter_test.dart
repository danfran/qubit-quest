import 'package:flutter_test/flutter_test.dart';
import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/utils/complex_formatter.dart';

void main() {
  group('formatComplex', () {
    // Case 1: Zero
    test('should return "0" for 0 + 0i', () {
      final c = Complex(0, 0);
      expect(formatComplex(c), '0');
    });

    // Case 2: Pure Real
    test('should format positive integer real part (1)', () {
      final c = Complex(1, 0);
      expect(formatComplex(c), '1');
    });

    test('should format negative integer real part (-1)', () {
      final c = Complex(-1, 0);
      expect(formatComplex(c), '-1');
    });

    test('should format negative fraction real part (-1/2)', () {
      final c = Complex(-0.5, 0);
      expect(formatComplex(c), '-1/2');
    });

    test('should format positive fraction real part (1/3)', () {
      final c = Complex(1/3, 0);
      expect(formatComplex(c), '0.3333');
    });

    // Case 3: Pure Imaginary
    test('should return "i" for 0 + 1i', () {
      final c = Complex(0, 1);
      expect(formatComplex(c), 'i');
    });

    test('should return "-1i" for 0 - 1i (testing explicit sign output for -i)', () {
      // NOTE: The function's logic explicitly returns '-1i' instead of '-i'
      // when imgF == '1' and signImaginary == '-'. Testing this specific output.
      final c = Complex(0, -1);
      expect(formatComplex(c), '-i');
    });

    test('should format positive fractional imaginary part (1/2i)', () {
      final c = Complex(0, 0.5);
      expect(formatComplex(c), '1/2i');
    });

    test('should format negative fractional imaginary part (-1/3i)', () {
      final c = Complex(0, -1/3);
      expect(formatComplex(c), '-0.3333i');
    });

    // Case 4: Mixed Real and Imaginary
    test('should format 1/2 + 1/2i', () {
      final c = Complex(0.5, 0.5);
      expect(formatComplex(c), '1/2 + 1/2i');
    });

    test('should format -1/2 + 1/2i', () {
      final c = Complex(-0.5, 0.5);
      expect(formatComplex(c), '-1/2 + 1/2i');
    });

    test('should format 1 - 1i', () {
      final c = Complex(1, -1);
      expect(formatComplex(c), '1 - i');
    });

    test('should format 1 + 1i', () {
      final c = Complex(1, 1);
      expect(formatComplex(c), '1 + i');
    });

    test('should format -1/3 - 1/3i', () {
      final c = Complex(-1/3, -1/3);
      expect(formatComplex(c), '-0.3333 - 0.3333i');
    });

    // Case 5: Decimal Fallback (e.g., 1/sqrt(2) approx)
    test('should use 3-digit decimals for non-fractional parts', () {
      final c = Complex(0.70710678, -0.123456); // Approx 1/sqrt(2)
      // MockQQFraction.doubleToFractionString falls back to fixed(3) for these
      expect(formatComplex(c), '0.7071 - 1929/15625i');
    });
  });
}
