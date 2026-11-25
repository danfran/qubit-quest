import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/widgets/gate_visual_style.dart';

/// Conventional measurement symbol: a meter (arc plus needle) in a gate tile,
/// optionally labelled with its classical destination (for example `c2`).
///
/// Used by the palette, placed measurements and the drag preview so all three
/// read as the same instruction.
class MeasurementGlyph extends StatelessWidget {
  const MeasurementGlyph({
    super.key,
    required this.size,
    this.classicalBit,
    this.selected = false,
    this.rejected = false,
    this.radius = QubitQuestGateStyle.buttonRadius,
  });

  final double size;
  final int? classicalBit;
  final bool selected;

  /// Drag-preview state for a slot where the measurement cannot be placed.
  final bool rejected;
  final double radius;

  /// Tile gradient, shared with palette presentations of measurement.
  static const List<Color> gradient = [
    Color(0xFF5B6478),
    Color(0xFF434B5E),
    Color(0xFF2E3445),
  ];
  static const List<Color> _colors = gradient;
  static const Color selectionColor = Color(0xFF7CFFB2);
  static const Color rejectedColor = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    final label = classicalBit == null ? null : 'c$classicalBit';
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: rejected
                ? _colors
                    .map((c) => Color.lerp(c, rejectedColor, .35)!)
                    .toList()
                : _colors,
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: rejected
                ? rejectedColor
                : selected
                    ? selectionColor
                    : QubitQuestGateStyle.border,
            width: selected || rejected ? 2.2 : QubitQuestGateStyle.borderWidth,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  size * .14,
                  size * .16,
                  size * .14,
                  label == null ? size * .2 : size * .34,
                ),
                child: const CustomPaint(painter: _MeterPainter()),
              ),
            ),
            if (label != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: size * .05,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .95),
                    fontSize: math.max(7, size * .27),
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: .95)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, size.shortestSide * .1);
    // Semicircular dial sitting on the bottom edge of the available area.
    final radius = math.min(size.width / 2, size.height);
    final pivot = Offset(size.width / 2, size.height);
    canvas.drawArc(Rect.fromCircle(center: pivot, radius: radius), math.pi,
        math.pi, false, stroke);
    // Needle towards the upper right, as in standard circuit notation.
    const angle = -math.pi / 4;
    final tip =
        pivot + Offset(math.cos(angle), math.sin(angle)) * (radius * 1.05);
    canvas.drawLine(pivot, tip, stroke);
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) => false;
}
