// quantum_circuit_painter.dart

import 'package:flutter/material.dart';
import 'dart:math'; // For min/max
import 'package:quantumquiz/models/placed_quantum_gate.dart'; // Import PlacedQuantumGate
import 'package:quantumquiz/models/quantum_circuit.dart'; // Import QuantumCircuit
import 'package:quantumquiz/models/selected_gate_type.dart'; // Import SelectedGateType
import 'package:quantumquiz/widgets/gate_visual_style.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/widgets/circuit_layout_metrics.dart';

class QuantumCircuitPainter extends CustomPainter {
  // Layout constants
  static const double qubitSpacing = CircuitLayoutMetrics.qubitSpacing;
  static const double gateSpacing = CircuitLayoutMetrics.gateSpacing;
  static const double gateSize = CircuitLayoutMetrics.gateSize;
  static const double padding = CircuitLayoutMetrics.padding;
  // ** Temporarily increased hitTolerance for easier testing **
  static const double hitTolerance = CircuitLayoutMetrics.hitTolerance;
  // *********************************************************
  static const double targetRadius = CircuitLayoutMetrics.targetRadius;
  static const double controlDotRadius = CircuitLayoutMetrics.controlDotRadius;
  static const double gateShadowYOffset =
      CircuitLayoutMetrics.gateShadowYOffset;
  static const double gateShadowBlurRadius =
      CircuitLayoutMetrics.gateShadowBlurRadius;
  static const double firstWireY = CircuitLayoutMetrics.firstWireY;
  static const double bottomExtent = CircuitLayoutMetrics.bottomExtent;
  static const double topExtent = CircuitLayoutMetrics.topExtent;

  // Color constants
  static const Color gridLinesColor =
      Colors.white; // Define color for qubit lines (Black)
  static const Color qubitLabelColor =
      Colors.white; // Color for qubit labels (q0, q1) (Black)
  static const Color gateBorder = QubitQuestGateStyle.border;
  static const double gateBorderWidth = QubitQuestGateStyle.borderWidth;
  static const Color circuitLineBlue = Color(0xFF3B8CFF);

  final QuantumCircuit
      circuit; // Painter needs the circuit (with List<PlacedQuantumGate> placedGates)
  final List<List<PlacedQuantumGate>>? previewGates;
  final GateId? selectedGateId;
  final GateId? ghostedGateId;

  QuantumCircuitPainter(
    this.circuit, {
    this.previewGates,
    this.selectedGateId,
    this.ghostedGateId,
  });

  GateGradientStyle _visualForGate(Gate gate) =>
      QubitQuestGateStyle.forGate(gate);

  Rect? _controlledSelectionBounds(
    GateId id,
    List<List<PlacedQuantumGate>> renderedGates,
  ) {
    final source = circuit.placedGateById(id);
    if (source == null || source.isSingleQubit) return null;
    final centers = <Offset>[];
    for (final (qubit, row) in renderedGates.indexed) {
      for (final (column, gate) in row.indexed) {
        if (gate.id != id) continue;
        centers.add(Offset(
          padding + column * gateSpacing + gateSpacing / 2,
          qubitCenterYFor(qubit),
        ));
      }
    }
    if (centers.isEmpty) return null;
    final extent = targetRadius + 4;
    return Rect.fromLTRB(
      centers.map((center) => center.dx).reduce(min) - extent,
      centers.map((center) => center.dy).reduce(min) - extent,
      centers.map((center) => center.dx).reduce(max) + extent,
      centers.map((center) => center.dy).reduce(max) + extent,
    );
  }

  void _drawCircuitGateTile(
    Canvas canvas,
    Rect rect,
    Gate gate,
  ) {
    final visual = _visualForGate(gate);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: visual.colors,
      ).createShader(rect);
    final borderPaint = Paint()
      ..color = gateBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = gateBorderWidth;

    canvas.drawRRect(rrect.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  // Helper getter to calculate the vertical center of a qubit line
  double getQubitCenterY(int qubitIndex) {
    return qubitCenterYFor(qubitIndex);
  }

  static double qubitCenterYFor(int qubitIndex) {
    return CircuitLayoutMetrics.wireCenterY(qubitIndex);
  }

  static double lastWireYFor(int qubitCount) {
    return qubitCenterYFor(max(1, qubitCount) - 1);
  }

  static double wireSpanFor(int qubitCount) {
    return CircuitLayoutMetrics.wireSpan(qubitCount);
  }

  static double requiredDrawingHeightFor(int qubitCount) {
    return CircuitLayoutMetrics.drawingHeight(qubitCount);
  }

  void _drawSourceGhost(Canvas canvas) {
    final id = ghostedGateId;
    if (id == null) return;
    final footprint = circuit.logicalGateById(id);
    if (footprint == null) return;

    final ghostStroke = Paint()
      ..color = const Color(0xFF7CFFB2).withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final ghostFill = Paint()
      ..color = const Color(0xFF7CFFB2).withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;
    final centerX = CircuitLayoutMetrics.slotCenter(footprint.anchor).dx;

    if (footprint.isSingleQubit) {
      final centerY = qubitCenterYFor(footprint.anchor.qubit);
      final rect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: gateSize,
        height: gateSize,
      );
      final shape = RRect.fromRectAndRadius(rect, const Radius.circular(10));
      canvas.drawRRect(shape, ghostFill);
      canvas.drawRRect(shape, ghostStroke);
      final label = TextPainter(
        text: TextSpan(
          text: footprint.gate.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.22),
            fontSize: footprint.gate.requiresAngle ? 10 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(centerX - label.width / 2, centerY - label.height / 2),
      );
      return;
    }

    final rows = footprint.fragments
        .map((fragment) => fragment.location.qubit)
        .toSet()
        .toList()
      ..sort();
    canvas.drawLine(
      Offset(centerX, qubitCenterYFor(rows.first)),
      Offset(centerX, qubitCenterYFor(rows.last)),
      ghostStroke,
    );
    for (final fragment in footprint.fragments) {
      final gate = fragment.placedGate;
      if (!gate.isControl && !gate.isControl2 && !gate.isTarget) continue;
      final center = Offset(
        centerX,
        qubitCenterYFor(fragment.location.qubit),
      );
      final radius = gate.isTarget && footprint.type != SelectedGateType.cz
          ? targetRadius
          : controlDotRadius;
      canvas.drawCircle(center, radius, ghostFill);
      canvas.drawCircle(center, radius, ghostStroke);
      if (gate.isTarget && footprint.type != SelectedGateType.cz) {
        const arm = 6.0;
        canvas.drawLine(
          center.translate(-arm, 0),
          center.translate(arm, 0),
          ghostStroke,
        );
        canvas.drawLine(
          center.translate(0, -arm),
          center.translate(0, arm),
          ghostStroke,
        );
      }
    }
  }

  @visibleForTesting
  static List<String> initialQubitLabelsFor({
    required String initialQubitsStateStr,
    required int numQubits,
  }) {
    final String label = initialQubitsStateStr.trim();
    final List<String> ketTokens = RegExp(r'\|[^|⟩]+⟩')
        .allMatches(label)
        .map((match) => match.group(0)!)
        .toList();

    if (ketTokens.length == numQubits) {
      return ketTokens;
    }

    if (RegExp(r'^[01]+$').hasMatch(label) && label.length == numQubits) {
      // Kets are written |q(n-1)...q0>, while circuit wires are ordered
      // top-to-bottom as Q0, Q1, ... . Reverse the authored ket bits so each
      // wire label agrees with the simulator's little-endian qubit indexing.
      return label.split('').reversed.map((bit) => '|$bit⟩').toList();
    }

    return List<String>.generate(
      numQubits,
      (index) => '|q$index⟩',
    );
  }

  List<String> _initialQubitLabels() {
    return initialQubitLabelsFor(
      initialQubitsStateStr: circuit.currentLevel.initialQubitsStateStr,
      numQubits: circuit.currentLevel.numQubits,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint("Painting circuit. Canvas size: $size"); // Debug canvas size
    final linePaint = Paint()
      ..color = gridLinesColor // Use the static constant for lines
      ..strokeWidth = 1.0; // Ensure consistent stroke width

    // Paint for drawing debug hit areas
    final debugPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill; // Fill the rectangle

    // Paint for the highlight box
    final Paint highlightPaint = Paint()
      ..color = const Color(0xFF56CCF2).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final Paint highlightBorderPaint = Paint()
      ..color = const Color(0xFF56CCF2).withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Paint highlightShadowPaint = Paint() // For shadow effect
      ..color = const Color(0xFF56CCF2).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal, 8.0); // Blur radius for shadow

    final List<String> initialQubitLabels = _initialQubitLabels();

    // Draw qubit lines and labels
    for (int i = 0; i < circuit.currentLevel.numQubits; i++) {
      // Calculate the vertical center Y for this qubit line
      final double lineY = getQubitCenterY(i);
      final qubitState =
          initialQubitLabels[circuit.currentLevel.numQubits - i - 1];
      debugPrint(
          "  Painter: Drawing Qubit $i line and hit area at Y: $lineY. Hit range: ${lineY - hitTolerance} to ${lineY + hitTolerance}"); // Debug calculated drawing Y

      // Draw the qubit line
      canvas.drawLine(
        Offset(padding, lineY), // Start line after padding
        Offset(size.width - padding,
            lineY), // End line before padding on the right
        linePaint,
      );

      // ** Draw the debug hit area for this qubit line **
      final Rect qubitHitRect = Rect.fromLTRB(
        0, // Start from the left edge of the canvas
        lineY - hitTolerance, // Top of the hit area
        size.width, // End at the right edge of the canvas
        lineY + hitTolerance, // Bottom of the hit area
      );
      canvas.drawRect(
          qubitHitRect, debugPaint); // Draw the transparent hit rectangle
      // ***********************************************

      // Draw the qubit label (q0, q1, etc.)
      final textPainter = TextPainter(
        text: TextSpan(
          text: qubitState, // Label text (e.g., "|0⟩", "|−⟩")
          style: TextStyle(
            color: qubitLabelColor, // Use the static constant for label color
            fontSize: 14, // Adjust font size as needed
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr, // Required for TextPainter
      );
      textPainter.layout(); // Perform layout before painting

      // Calculate the position for the label (e.g., left of the first line, centered vertically)
      final double labelX = padding / 2 -
          textPainter.width / 2; // Position left of padding, centered
      final double labelY =
          lineY - textPainter.height / 2; // Center vertically on the line

      textPainter.paint(canvas, Offset(labelX, labelY));
    }

    final List<List<PlacedQuantumGate>> localPlacedGates =
        previewGates ?? circuit.placedGates;

    final selected = selectedGateId;
    if (selected != null &&
        (selected != ghostedGateId || previewGates != null)) {
      final controlledBounds =
          _controlledSelectionBounds(selected, localPlacedGates);
      if (controlledBounds != null) {
        final selectionFill = Paint()
          ..color = const Color(0xFF7CFFB2).withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;
        final selectionBorder = Paint()
          ..color = const Color(0xFF7CFFB2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;
        final selectionShape = RRect.fromRectAndRadius(
          controlledBounds.inflate(3),
          const Radius.circular(12),
        );
        canvas.drawRRect(selectionShape, selectionFill);
        canvas.drawRRect(selectionShape, selectionBorder);
      }
    }

    List<int> gateXPosititionPerQubit =
        List<int>.filled(circuit.currentLevel.numQubits, 0);

    // Draw placed gates
    for (final (primaryDrawingQubit, row) in localPlacedGates.indexed) {
      debugPrint(
          'Drawing qubit line $primaryDrawingQubit with ${row.length} gates');
      for (final (currentX, placedGate) in row.indexed) {
        if (previewGates == null && placedGate.id == ghostedGateId) {
          gateXPosititionPerQubit[primaryDrawingQubit] += 1;
          continue;
        }
        // Calculate the top-left corner of the gate icon square
        if (placedGate.gate.type == SelectedGateType.cnot ||
            placedGate.gate.type == SelectedGateType.cz) {
          final String gateLabel = placedGate.gate.label;
          // Drawing logic for CNOT not target
          // int currentX = gateXPosititionPerQubit.reduce(max);
          final double gateColumnCenterX =
              padding + currentX * gateSpacing + gateSpacing / 2;
          debugPrint('  Drawing $gateLabel at $gateColumnCenterX');

          gateXPosititionPerQubit[primaryDrawingQubit] +=
              1; // Increment for next gate

          if (placedGate.gate.type != SelectedGateType.none &&
              placedGate.isTarget) {
            // Use the helper for the vertical centers of control and target qubits
            final double controlY =
                getQubitCenterY(placedGate.controlQubitIndex!);
            final double targetY = getQubitCenterY(primaryDrawingQubit);

            // Draw control circle/dot
            final visual = _visualForGate(placedGate.gate);
            final controlPaint = Paint()..color = visual.top;
            canvas.drawCircle(Offset(gateColumnCenterX, controlY),
                controlDotRadius, controlPaint);

            // Draw connection line between control and target
            final linePaint = Paint()
              ..color = circuitLineBlue
              ..strokeWidth = 2.0;
            canvas.drawLine(Offset(gateColumnCenterX, controlY),
                Offset(gateColumnCenterX, targetY), linePaint);

            if (placedGate.gate.type == SelectedGateType.cnot) {
              // Draw target circle
              final targetPaint = Paint()
                ..shader = RadialGradient(
                  colors: visual.colors,
                ).createShader(
                  Rect.fromCircle(
                    center: Offset(gateColumnCenterX, targetY),
                    radius: targetRadius,
                  ),
                );
              final targetGlowPaint = Paint()
                ..color = Colors.black.withValues(alpha: 0.45)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
              canvas.drawCircle(
                Offset(gateColumnCenterX, targetY + 3),
                targetRadius + 1,
                targetGlowPaint,
              );
              canvas.drawCircle(Offset(gateColumnCenterX, targetY),
                  targetRadius, targetPaint);

              // Draw '+' inside target circle
              final plusPainter = TextPainter(
                text: TextSpan(
                    text: '+',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 24)),
                textDirection: TextDirection.ltr,
              );
              plusPainter.layout();
              plusPainter.paint(
                  canvas,
                  Offset(gateColumnCenterX - plusPainter.width / 2,
                      targetY - plusPainter.height / 2));
            } else if (placedGate.gate.type == SelectedGateType.cz) {
              final targetPaint = Paint()..color = visual.top;
              canvas.drawCircle(Offset(gateColumnCenterX, targetY),
                  controlDotRadius, targetPaint);
            }
          }
        } else if (placedGate.gate.type == SelectedGateType.ccnot) {
          // Drawing logic for CCNOT not target
          // int currentX = gateXPosititionPerQubit.reduce(max);
          final double gateColumnCenterX =
              padding + currentX * gateSpacing + gateSpacing / 2;
          debugPrint('  Drawing CCNOT at $gateColumnCenterX');

          gateXPosititionPerQubit[primaryDrawingQubit] +=
              1; // Increment for next gate

          if (placedGate.gate.type != SelectedGateType.none &&
              placedGate.isTarget) {
            // Use the helper for the vertical centers of control and target qubits
            final double controlY =
                getQubitCenterY(placedGate.controlQubitIndex!);
            final double control2Y =
                getQubitCenterY(placedGate.control2QubitIndex!);
            final double targetY = getQubitCenterY(primaryDrawingQubit);

            // Draw control circle/dot
            final visual = _visualForGate(placedGate.gate);
            final controlPaint = Paint()
              ..color = visual.top; // Use the static constant
            canvas.drawCircle(Offset(gateColumnCenterX, controlY),
                controlDotRadius, controlPaint);

            // Draw control 2 circle/dot
            final control2Paint = Paint()
              ..color = visual.top; // Use the static constant
            canvas.drawCircle(Offset(gateColumnCenterX, control2Y),
                controlDotRadius, control2Paint);

            // Draw connection line between control and target
            final linePaint = Paint()
              ..color = circuitLineBlue
              ..strokeWidth = 2.0; // Use the static constant
            canvas.drawLine(Offset(gateColumnCenterX, controlY),
                Offset(gateColumnCenterX, targetY), linePaint);

            // Draw connection line between control 2 and target
            final line2Paint = Paint()
              ..color = circuitLineBlue
              ..strokeWidth = 2.0; // Use the static constant
            canvas.drawLine(Offset(gateColumnCenterX, control2Y),
                Offset(gateColumnCenterX, targetY), line2Paint);

            // Draw target circle
            final targetPaint = Paint()
              ..shader = RadialGradient(
                colors: visual.colors,
              ).createShader(
                Rect.fromCircle(
                  center: Offset(gateColumnCenterX, targetY),
                  radius: targetRadius,
                ),
              ); // Use the static constant
            final targetGlowPaint = Paint()
              ..color = Colors.black.withValues(alpha: 0.45)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
            canvas.drawCircle(
              Offset(gateColumnCenterX, targetY + 3),
              targetRadius + 1,
              targetGlowPaint,
            );
            canvas.drawCircle(
                Offset(gateColumnCenterX, targetY), targetRadius, targetPaint);

            // Draw '+' inside target circle
            final plusPainter = TextPainter(
              text: TextSpan(
                  text: '+',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 24)),
              textDirection: TextDirection.ltr,
            );
            plusPainter.layout();
            plusPainter.paint(
                canvas,
                Offset(gateColumnCenterX - plusPainter.width / 2,
                    targetY - plusPainter.height / 2));
          }
        } else {
          // Use the helper for the vertical center of the primary qubit line
          final double gateCenterY = getQubitCenterY(primaryDrawingQubit);
          final double gateIconTop = gateCenterY -
              gateSize / 2; // Use gateCenterY to center vertically

          final double gateColumnCenterX = padding +
              gateXPosititionPerQubit[primaryDrawingQubit] * gateSpacing +
              gateSpacing / 2;

          debugPrint('  Drawing GATE at $gateColumnCenterX');

          gateXPosititionPerQubit[primaryDrawingQubit] +=
              1; // Increment for next gate

          if (placedGate.gate.type != SelectedGateType.none) {
            var gateRect = Rect.fromLTWH(gateColumnCenterX - gateSize / 2,
                gateIconTop, gateSize, gateSize);

            if (placedGate.gate.type == SelectedGateType.draggedGate) {
              final RRect highlightRect = RRect.fromRectAndRadius(
                gateRect,
                const Radius.circular(8),
              );

              // Draw shadow, fill and border
              canvas.drawRRect(highlightRect, highlightShadowPaint);
              canvas.drawRRect(highlightRect, highlightPaint);
              canvas.drawRRect(highlightRect, highlightBorderPaint);
            } else {
              _drawCircuitGateTile(canvas, gateRect, placedGate.gate);
              if (placedGate.id == selectedGateId) {
                final selectionPaint = Paint()
                  ..color = const Color(0xFF7CFFB2)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.2;
                canvas.drawRRect(
                  RRect.fromRectAndRadius(
                    gateRect.inflate(3),
                    const Radius.circular(12),
                  ),
                  selectionPaint,
                );
              }
            }

            // Draw 'H' or 'S' or 'X', etc text centered in the square
            String gateText = placedGate.gate.label; // Set the text
            double gateTextSize =
                (placedGate.gate.type == SelectedGateType.rx ||
                        placedGate.gate.type == SelectedGateType.ry ||
                        placedGate.gate.type == SelectedGateType.rz)
                    ? 10.0
                    : 16.0; // Set the text size
            gateTextPainter(
                gateText, gateTextSize, canvas, gateColumnCenterX, gateIconTop);
          }
        }
      }
    }
    _drawSourceGhost(canvas);
  }

  void gateTextPainter(String gateText, double gateTextSize, Canvas canvas,
      double gateColumnCenterX, double gateIconTop) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: gateText,
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: gateTextSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr, // Required for TextPainter
    );
    textPainter.layout(); // Perform layout before painting
    textPainter.paint(
        canvas,
        Offset(gateColumnCenterX - textPainter.width / 2,
            gateIconTop + gateSize / 2 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant QuantumCircuitPainter oldDelegate) {
    return true;
    // // debugPrint("shouldRepaint called.");
    // // debugPrint("New circuit placedGates length: ${circuit.placedGates.length}");
    // // debugPrint("Old circuit placedGates length: ${oldDelegate.circuit.placedGates.length}");
    //
    // // Check if the list reference is different.
    // if (circuit.placedGates != oldDelegate.circuit.placedGates) {
    //   // debugPrint("shouldRepaint: true (list reference changed).");
    //   return true;
    // }
    //
    // // Check if the list length has changed.
    // if (circuit.placedGates.length != oldDelegate.circuit.placedGates.length) {
    //   // debugPrint("shouldRepaint: true (list length changed).");
    //   return true;
    // }
    //
    // // If list reference and length are the same, perform a deep comparison of contents.
    // // This is the most thorough check.
    // for (int i = 0; i < circuit.placedGates.length; i++) {
    //   final newGate = circuit.placedGates[i];
    //   final oldGate = oldDelegate.circuit.placedGates[i];
    //
    //   // Compare relevant properties that affect drawing
    //   if (newGate.type != oldGate.type ||
    //       newGate.position != oldGate.position ||
    //       newGate.singleQubitIndex != oldGate.singleQubitIndex ||
    //       newGate.controlQubitIndex != oldGate.controlQubitIndex ||
    //       newGate.targetQubitIndex != oldGate.targetQubitIndex) {
    //     // debugPrint("shouldRepaint: true (gate properties changed at index $i).");
    //     return true; // A gate's properties has changed, need to repaint
    //   }
    //   // Add debug debugPrints to see if properties are being compared and if they match
    //   // debugPrint("Comparing gate at index $i:");
    //   // debugPrint("  New: type=${newGate.type}, pos=${newGate.position}, single=${newGate.singleQubitIndex}, control=${newGate.controlQubitIndex}, target=${newGate.targetQubitIndex}");
    //   // debugPrint("  Old: type=${oldGate.type}, pos=${oldGate.position}, single=${oldGate.singleQubitIndex}, control=${oldGate.controlQubitIndex}, target=${oldGate.targetQubitIndex}");
    //   // if (newGate.type != oldGate.type) debugPrint("    Type mismatch!");
    //   // if (newGate.position != oldGate.position) debugPrint("    Position mismatch!");
    //   // if (newGate.singleQubitIndex != oldGate.singleQubitIndex) debugPrint("    Single Qubit mismatch!");
    //   // if (newGate.controlQubitIndex != oldGate.controlQubitIndex) debugPrint("    Control Qubit mismatch!");
    //   // if (newGate.targetQubitIndex != oldGate.targetQubitIndex) debugPrint("    Target Qubit mismatch!");
    // }
    //
    // // If none of the checks above indicate a change, no need to repaint.
    // // debugPrint("shouldRepaint: false (no changes detected after deep comparison).");
    // return false;
  }
}
