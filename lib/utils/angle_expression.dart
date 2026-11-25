import 'dart:math' as math;

/// Parses a rotation angle typed by the learner, in radians.
///
/// Accepts plain radians (`1.5708`, `-0.25`, `2 rad`), multiples and
/// fractions of π written with `π` or `pi` (`π`, `pi/2`, `3π/4`, `-π/8`,
/// `0.25π`, `2*pi`, `(3/4)π`) and fractions of π written as `3/4 π`.
/// Any finite value is accepted, matching the existing angle dialog, which
/// never restricted the range; nothing is rounded. Returns null for anything
/// else.
double? parseAngleExpression(String input) {
  var text = input.trim().toLowerCase().replaceAll(' ', '');
  if (text.isEmpty) return null;
  if (text.endsWith('rad')) text = text.substring(0, text.length - 3);
  text = text
      .replaceAll('pi', 'π')
      .replaceAll('*', '')
      .replaceAll('(', '')
      .replaceAll(')', '')
      .replaceAll('−', '-');
  if (text.isEmpty) return null;

  final sign = text.startsWith('-') ? -1.0 : 1.0;
  if (text.startsWith('-') || text.startsWith('+')) text = text.substring(1);
  if (text.isEmpty) return null;

  final value = text.contains('π') ? _piExpression(text) : _number(text);
  if (value == null || !value.isFinite) return null;
  return sign * value;
}

final _numberPattern = RegExp(r'^(\d+(\.\d*)?|\.\d+)(e[+-]?\d+)?$');

double? _number(String text) {
  if (text.contains('/')) {
    final parts = text.split('/');
    if (parts.length != 2) return null;
    final numerator = _plain(parts[0]);
    final denominator = _plain(parts[1]);
    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }
    return numerator / denominator;
  }
  return _plain(text);
}

double? _plain(String text) =>
    _numberPattern.hasMatch(text) ? double.tryParse(text) : null;

/// `kπ`, `π/d`, `kπ/d`, `k/dπ`.
double? _piExpression(String text) {
  if ('π'.allMatches(text).length != 1) return null;
  final index = text.indexOf('π');
  final before = text.substring(0, index);
  final after = text.substring(index + 1);
  double coefficient;
  if (before.isEmpty) {
    coefficient = 1;
  } else {
    final value = _number(before);
    if (value == null) return null;
    coefficient = value;
  }
  if (after.isEmpty) return coefficient * math.pi;
  if (!after.startsWith('/')) return null;
  final denominator = _plain(after.substring(1));
  if (denominator == null || denominator == 0) return null;
  return coefficient * math.pi / denominator;
}

/// Formats [radians] as a compact multiple of π (`π/2`, `3π/4`, `-π`) when
/// it is a simple fraction with denominator up to 16, otherwise as a
/// decimal multiple of π (`0.3183π`).
String formatAngleAsPi(double radians) {
  if (radians == 0) return '0';
  final ratio = radians / math.pi;
  for (final denominator in const [1, 2, 3, 4, 6, 8, 12, 16]) {
    final numerator = ratio * denominator;
    final rounded = numerator.roundToDouble();
    if ((numerator - rounded).abs() < 1e-9) {
      final n = rounded.toInt();
      final sign = n < 0 ? '-' : '';
      final magnitude = n.abs();
      final head = magnitude == 1 ? 'π' : '$magnitudeπ';
      return denominator == 1 ? '$sign$head' : '$sign$head/$denominator';
    }
  }
  return '${_trim(ratio.toStringAsFixed(4))}π';
}

String _trim(String value) =>
    value.contains('.') ? value.replaceFirst(RegExp(r'\.?0+$'), '') : value;
