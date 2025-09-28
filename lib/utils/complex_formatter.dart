// Helper to format a complex number for display
import 'package:advance_math/advance_math.dart';
import 'package:flutter/cupertino.dart';
import 'package:quantumquiz/utils/qq_fraction.dart';

String formatComplex(Complex c) {
  debugPrint(">>>>>>>>>>>>>>>>>>>>> " + c.toString());
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
    return imgF == '1' ? '${signImaginary}i' : '$signImaginary${imgF}i';
  }

  String signImaginary = fractionImaginary.sign == '-' ? ' - ' : ' + ';
  String newImgF = imgF == '1' ? '${signImaginary}i' : '$signImaginary${imgF}i';
  return '$signReal$realF$newImgF';
}