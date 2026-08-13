import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

/// Static Phase 2 renderer for the Inspector's educational visual slot.
///
/// Future Bloch-sphere and animation renderers can consume the same
/// [GateEducationalVisual] contract without changing the dialog layout.
class GateEducationalVisualView extends StatelessWidget {
  const GateEducationalVisualView({
    super.key,
    required this.visual,
    required this.footprint,
  });

  final GateEducationalVisual visual;
  final LogicalGateFootprint footprint;

  @override
  Widget build(BuildContext context) {
    final rotationRadians = visual.rotationRadians ?? footprint.gate.angle;
    final rotationLabel = _rotationLabel(rotationRadians);
    final label = switch (visual.kind) {
      GateEducationalVisualKind.blochAxis =>
        '${footprint.gate.label.replaceAll('\n', ' ')} $rotationLabel rotation about the ${visual.axisLabel} axis',
      GateEducationalVisualKind.superposition =>
        'Hadamard changes a basis state into superposition',
      GateEducationalVisualKind.controlledX =>
        'Controlled-X links a control to a target',
      GateEducationalVisualKind.controlledPhase =>
        'Controlled-Z applies a conditional phase',
      GateEducationalVisualKind.multiControlledX =>
        'Toffoli links two controls to one target',
      GateEducationalVisualKind.staticGate =>
        '${footprint.gate.label.replaceAll('\n', ' ')} gate illustration',
    };
    return Semantics(
      label: label,
      image: true,
      child: SizedBox(
        key: const ValueKey('gate-inspector-static-visual'),
        height: 92,
        child: CustomPaint(
          painter: _GateVisualPainter(
            kind: visual.kind,
            gateLabel: footprint.gate.label.split('\n').first,
            axisLabel: visual.axisLabel,
            rotationRadians: rotationRadians,
            rotationLabel: rotationLabel,
            representativeTransition: visual.representativeTransition,
          ),
        ),
      ),
    );
  }

  String _rotationLabel(double? angle) {
    if (angle == null) return '';
    final ratio = angle / math.pi;
    if ((ratio.abs() - 1).abs() < 1e-9) return ratio < 0 ? '−π' : 'π';
    if ((ratio.abs() - .5).abs() < 1e-9) return ratio < 0 ? '−π/2' : 'π/2';
    if ((ratio.abs() - .25).abs() < 1e-9) return ratio < 0 ? '−π/4' : 'π/4';
    return '${angle.toStringAsFixed(2)} rad';
  }
}

class _GateVisualPainter extends CustomPainter {
  const _GateVisualPainter({
    required this.kind,
    required this.gateLabel,
    required this.axisLabel,
    required this.rotationRadians,
    required this.rotationLabel,
    required this.representativeTransition,
  });

  final GateEducationalVisualKind kind;
  final String gateLabel;
  final String? axisLabel;
  final double? rotationRadians;
  final String rotationLabel;
  final String? representativeTransition;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case GateEducationalVisualKind.blochAxis:
        _paintBlochAxis(canvas, size);
      case GateEducationalVisualKind.superposition:
        _paintSuperposition(canvas, size);
      case GateEducationalVisualKind.controlledX:
        _paintControlled(canvas, size, controls: 1, phaseTarget: false);
      case GateEducationalVisualKind.controlledPhase:
        _paintControlled(canvas, size, controls: 1, phaseTarget: true);
      case GateEducationalVisualKind.multiControlledX:
        _paintControlled(canvas, size, controls: 2, phaseTarget: false);
      case GateEducationalVisualKind.staticGate:
        _paintGateTile(canvas, size.center(Offset.zero), gateLabel);
    }
  }

  void _paintBlochAxis(Canvas canvas, Size size) {
    final center = Offset(size.width * .32, size.height / 2);
    final radius = math.min(34.0, size.height * .39);
    final back = Paint()
      ..color = QubitQuestDialog.cyan.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final front = Paint()
      ..color = QubitQuestDialog.cyan.withValues(alpha: .68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, front);
    final equator = Rect.fromCenter(
        center: center, width: radius * 2, height: radius * .62);
    canvas.drawArc(equator, math.pi, math.pi, false, back);
    canvas.drawArc(equator, 0, math.pi, false, front);
    final diagonal = Paint()
      ..color = QubitQuestDialog.cyan.withValues(alpha: .34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(center - Offset(radius * .78, radius * .55),
        center + Offset(radius * .78, radius * .55), diagonal);
    canvas.drawLine(
        center - Offset(radius + 7, 0), center + Offset(radius + 7, 0), front);
    canvas.drawLine(
        center - Offset(0, radius + 4), center + Offset(0, radius + 4), front);

    _paintLabel(canvas, center + Offset(radius + 12, 1), 'X',
        color: QubitQuestDialog.mutedText, fontSize: 9);
    _paintLabel(canvas, center - Offset(radius * .82, radius * .7), 'Y',
        color: QubitQuestDialog.mutedText, fontSize: 9);
    _paintLabel(canvas, center - Offset(-2, radius + 9), 'Z',
        color: QubitQuestDialog.mutedText, fontSize: 9);

    final stateVector = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final stateEnd = center + Offset(radius * .45, -radius * .72);
    canvas.drawLine(center, stateEnd, stateVector);
    canvas.drawCircle(stateEnd, 3.5, Paint()..color = Colors.white);

    final arrow = Paint()
      ..color = QubitQuestDialog.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final sweep =
        (rotationRadians ?? math.pi).abs().clamp(.3, math.pi * 1.7).toDouble();
    final arcRect = Rect.fromCircle(center: center, radius: radius * .72);
    const start = math.pi * .7;
    canvas.drawArc(arcRect, start, sweep, false, arrow);
    final endAngle = start + sweep;
    final arrowEnd = Offset(center.dx + math.cos(endAngle) * radius * .72,
        center.dy + math.sin(endAngle) * radius * .72);
    final tangent = Offset(-math.sin(endAngle), math.cos(endAngle));
    canvas.drawLine(
        arrowEnd, arrowEnd - tangent * 8 + const Offset(-3, -2), arrow);

    _paintLabel(canvas, Offset(size.width * .73, size.height * .26), gateLabel,
        fontSize: 19);
    _paintLabel(canvas, Offset(size.width * .73, size.height * .49),
        '${axisLabel ?? ''} axis • $rotationLabel',
        color: QubitQuestDialog.cyan, fontSize: 11);
    if (representativeTransition != null) {
      _paintLabel(canvas, Offset(size.width * .73, size.height * .72),
          representativeTransition!,
          color: QubitQuestDialog.mutedText, fontSize: 10);
    }
  }

  void _paintSuperposition(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Paint()
      ..color = QubitQuestDialog.cyan.withValues(alpha: .7)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), line);
    _paintGateTile(canvas, Offset(size.width / 2, y), 'H');
    _paintLabel(canvas, Offset(size.width * .16, y - 22), '|0⟩', fontSize: 15);
    _paintLabel(canvas, Offset(size.width * .83, y - 22), '|+⟩',
        color: QubitQuestDialog.purple, fontSize: 15);
  }

  void _paintControlled(Canvas canvas, Size size,
      {required int controls, required bool phaseTarget}) {
    final rows = controls + 1;
    final spacing = size.height / (rows + 1);
    final x = size.width / 2;
    final wire = Paint()
      ..color = QubitQuestDialog.cyan.withValues(alpha: .7)
      ..strokeWidth = 2;
    for (var row = 1; row <= rows; row++) {
      final y = spacing * row;
      canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), wire);
    }
    canvas.drawLine(Offset(x, spacing), Offset(x, spacing * rows), wire);
    final marker = Paint()..color = QubitQuestDialog.purple;
    for (var control = 1; control <= controls; control++) {
      canvas.drawCircle(Offset(x, spacing * control), 6, marker);
    }
    final target = Offset(x, spacing * rows);
    if (phaseTarget) {
      canvas.drawCircle(target, 6, marker);
    } else {
      canvas.drawCircle(
          target,
          12,
          Paint()
            ..color = QubitQuestDialog.innerColor
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          target,
          12,
          Paint()
            ..color = QubitQuestDialog.purple
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawLine(target - const Offset(8, 0), target + const Offset(8, 0),
          wire..color = QubitQuestDialog.purple);
      canvas.drawLine(
          target - const Offset(0, 8), target + const Offset(0, 8), wire);
    }
  }

  void _paintGateTile(Canvas canvas, Offset center, String label) {
    final rect = Rect.fromCenter(center: center, width: 42, height: 42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = QubitQuestDialog.purple.withValues(alpha: .25),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..color = QubitQuestDialog.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _paintLabel(canvas, center, label, fontSize: 16);
  }

  void _paintLabel(Canvas canvas, Offset center, String label,
      {Color color = Colors.white, double fontSize = 14}) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
            color: color, fontSize: fontSize, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GateVisualPainter oldDelegate) =>
      kind != oldDelegate.kind ||
      gateLabel != oldDelegate.gateLabel ||
      axisLabel != oldDelegate.axisLabel ||
      rotationRadians != oldDelegate.rotationRadians ||
      rotationLabel != oldDelegate.rotationLabel ||
      representativeTransition != oldDelegate.representativeTransition;
}
