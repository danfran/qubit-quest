import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';

/// One amplitude to draw on a [ComplexAmplitudePlane].
@immutable
class PlottedAmplitude {
  const PlottedAmplitude(this.label, this.value, this.color);
  final String label;
  final Complex value;
  final Color color;
}

/// The complex plane with each amplitude as an arrow from the origin: its
/// length is the magnitude |c| and its angle the phase arg(c) (v2.6 M8).
///
/// Unlike the Bloch sphere this keeps the *global* phase of the state vector
/// exactly as given, so −|0⟩ and |0⟩ look different here and identical on
/// the sphere. Platform-neutral and reusable (Composer results, Notebook).
class ComplexAmplitudePlane extends StatelessWidget {
  const ComplexAmplitudePlane({
    super.key,
    required this.amplitudes,
    this.size = 150,
  });

  final List<PlottedAmplitude> amplitudes;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: 'Complex plane: ${[
          for (final a in amplitudes)
            '${a.label} magnitude ${_mag(a.value).toStringAsFixed(3)}, '
                'phase ${_arg(a.value).toStringAsFixed(3)} rad'
        ].join('; ')}',
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            key: const ValueKey('complex-amplitude-plane'),
            painter: _PlanePainter(amplitudes),
          ),
        ),
      );

  static double _mag(Complex c) =>
      math.sqrt((c.real * c.real + c.imaginary * c.imaginary).toDouble());
  static double _arg(Complex c) =>
      math.atan2(c.imaginary.toDouble(), c.real.toDouble());
}

class _PlanePainter extends CustomPainter {
  const _PlanePainter(this.amplitudes);
  final List<PlottedAmplitude> amplitudes;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 16;
    final grid = Paint()
      ..color = const Color(0x557C8DB0)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx - radius - 6, center.dy),
        Offset(center.dx + radius + 6, center.dy), grid);
    canvas.drawLine(Offset(center.dx, center.dy - radius - 6),
        Offset(center.dx, center.dy + radius + 6), grid);
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0x667C8DB0)
          ..style = PaintingStyle.stroke);
    _text(canvas, 'Re', Offset(center.dx + radius + 2, center.dy + 3),
        const Color(0xFFB6C4DA));
    _text(canvas, 'Im', Offset(center.dx + 4, center.dy - radius - 16),
        const Color(0xFFB6C4DA));
    for (final (index, a) in amplitudes.indexed) {
      final re = a.value.real.toDouble(), im = a.value.imaginary.toDouble();
      final tip = center + Offset(re * radius, -im * radius);
      final paint = Paint()
        ..color = a.color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      if ((tip - center).distance < 2) {
        // A zero amplitude: a hollow marker at the origin, labelled, so it
        // is never mistaken for a missing value (v2.6 M9).
        canvas.drawCircle(
            center,
            4.5,
            Paint()
              ..color = a.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        final side = index.isEven ? -1.0 : 1.0;
        _text(canvas, '${a.label} = 0', center + Offset(-14, side * 14 - 7),
            a.color);
        continue;
      }
      canvas.drawLine(center, tip, paint);
      final u = (tip - center) / (tip - center).distance;
      final n = Offset(-u.dy, u.dx);
      canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo((tip - u * 9 + n * 4.5).dx, (tip - u * 9 + n * 4.5).dy)
            ..lineTo((tip - u * 9 - n * 4.5).dx, (tip - u * 9 - n * 4.5).dy)
            ..close(),
          Paint()..color = a.color);
      // Alternate sides of the arrow so equal amplitudes stay legible.
      final side = index.isEven ? 1.0 : -1.0;
      _text(canvas, a.label, tip + u * 8 + n * 11 * side - const Offset(4, 7),
          a.color);
    }
  }

  void _text(Canvas canvas, String text, Offset at, Color color) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _PlanePainter old) {
    if (old.amplitudes.length != amplitudes.length) return true;
    for (var i = 0; i < amplitudes.length; i++) {
      final a = old.amplitudes[i].value, b = amplitudes[i].value;
      if (a.real != b.real || a.imaginary != b.imaginary) return true;
    }
    return false;
  }
}
