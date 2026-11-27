// Helper to format a complex number for display
import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/utils/qq_fraction.dart';

/// The imaginary part as text with an unambiguous position for i (v2.6 M9):
/// "i", "0.5i", "i/√2", "3i/4", "i√2" — never "1/√2i", which could be read
/// as 1/(√2 i).
String _imaginaryText(String magnitude) {
  if (magnitude == '1') return 'i';
  final slash = magnitude.indexOf('/');
  if (slash > 0) {
    final numerator = magnitude.substring(0, slash);
    final denominator = magnitude.substring(slash + 1);
    return numerator == '1' ? 'i/$denominator' : '${numerator}i/$denominator';
  }
  if (magnitude.startsWith('√')) return 'i$magnitude';
  return '${magnitude}i';
}

String formatComplex(Complex c) {
  QQFraction fractionReal = QQFraction.doubleToFractionString(c.real.toDouble());
  QQFraction fractionImaginary = QQFraction.doubleToFractionString(c.imaginary.toDouble());

  String realF = fractionReal.toString();
  String imgF = fractionImaginary.toString();

  String signReal = fractionReal.sign == '-' ? '-' : '';

  if (realF == '0' && imgF == '0') {
    return '0';
  }

  if (realF != '0' && imgF == '0') {
    return "$signReal$realF";
  }

  if (realF == '0' && imgF != '0') {
    String signImaginary = fractionImaginary.sign == '-' ? '-' : '';
    return '$signImaginary${_imaginaryText(imgF)}';
  }

  String signImaginary = fractionImaginary.sign == '-' ? ' - ' : ' + ';
  String newImgF = '$signImaginary${_imaginaryText(imgF)}';
  return '$signReal$realF$newImgF';
}
