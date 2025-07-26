// quantum_circuit_painter.dart

import 'package:flutter/material.dart';
import 'dart:math'; // For min/max
import 'package:quantumquiz/models/placed_quantum_gate.dart'; // Import PlacedQuantumGate
import 'package:quantumquiz/models/quantum_circuit.dart'; // Import QuantumCircuit
import 'package:quantumquiz/models/selected_gate_type.dart'; // Import SelectedGateType


class QuantumCircuitPainter extends CustomPainter {
  // Layout constants
  static const double qubitSpacing = 40.0; // Vertical space between qubit lines
  static const double gateSpacing = 40.0; // Horizontal space allocated per gate position (column)
  static const double gateSize = 30.0;    // Size of the square gate icon (e.g., Hadamard)
  static const double padding = 20.0;     // Padding around the circuit drawing area
  // ** Temporarily increased hitTolerance for easier testing **
  static const double hitTolerance = 20.0; // Extra padding for tap detection area around gates/lines
  // *********************************************************
  static const double targetRadius = 12.0; // Radius of the CNOT target circle
  static const double controlDotRadius = 4.0; // Radius of the CNOT control dot

  // Color constants
  static const Color gridLinesColor = Colors.white; // Define color for qubit lines (Black)
  static const Color qubitLabelColor = Colors.white; // Color for qubit labels (q0, q1) (Black)
  // Add colors for other gate types as needed

  // ** Debugging color for hit areas **
  static const Color debugHitAreaColor = Color(0xFF1E1E2C); // Color to visualize hit areas
  // ***********************************

  final QuantumCircuit circuit; // Painter needs the circuit (with List<PlacedQuantumGate> placedGates)
  final PreviewQuantumCircuit previewCircuit; // Painter needs the circuit (with List<PlacedQuantumGate> placedGates)
  final ValueNotifier<double> widthNotifier;
  final Offset? draggingOffset;
  final SelectedGateType? draggingGateType; // New: Qubit index for highlight

  QuantumCircuitPainter(this.circuit, this.widthNotifier, this.draggingOffset, this.draggingGateType):
        previewCircuit = PreviewQuantumCircuit(currentLevel: circuit.currentLevel);

  // Helper getter to calculate the vertical center of a qubit line
  double getQubitCenterY(int qubitIndex) {
    return qubitIndex * qubitSpacing + qubitSpacing / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint("Painting circuit. Canvas size: $size"); // Debug canvas size
    final linePaint = Paint()
      ..color = gridLinesColor // Use the static constant for lines
      ..strokeWidth = 1.0; // Ensure consistent stroke width

    final gatePaint = Paint(); // Paint object for drawing gate icons

    // Paint for drawing debug hit areas
    final debugPaint = Paint()
      ..color = debugHitAreaColor.withOpacity(0.3) // Semi-transparent color
      ..style = PaintingStyle.fill; // Fill the rectangle

    // Paint for the highlight box
    final Paint highlightPaint = Paint()
      ..color = Colors.grey[300]! // Gray background
      ..style = PaintingStyle.fill;
    final Paint highlightBorderPaint = Paint()
      ..color = Colors.grey.shade600 // Darker gray border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final Paint highlightShadowPaint = Paint() // For shadow effect
      ..color = Colors.grey.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0); // Blur radius for shadow

    // Draw qubit lines and labels
    for (int i = 0; i < circuit.currentLevel.numQubits; i++) {
      // Calculate the vertical center Y for this qubit line
      final double lineY = getQubitCenterY(i);
      final qubitState = circuit.currentLevel.initialQubitsStateStr[i];
      debugPrint("  Painter: Drawing Qubit $i line and hit area at Y: $lineY. Hit range: ${lineY - hitTolerance} to ${lineY + hitTolerance}"); // Debug calculated drawing Y

      // Draw the qubit line
      canvas.drawLine(
        Offset(padding, lineY), // Start line after padding
        Offset(size.width - padding, lineY), // End line before padding on the right
        linePaint,
      );

      // ** Draw the debug hit area for this qubit line **
      final Rect qubitHitRect = Rect.fromLTRB(
        0, // Start from the left edge of the canvas
        lineY - hitTolerance, // Top of the hit area
        size.width, // End at the right edge of the canvas
        lineY + hitTolerance, // Bottom of the hit area
      );
      canvas.drawRect(qubitHitRect, debugPaint); // Draw the transparent hit rectangle
      // ***********************************************


      // Draw the qubit label (q0, q1, etc.)
      final textPainter = TextPainter(
        text: TextSpan(
          text: '|$qubitState>', // Label text (e.g., "q0", "q1")
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
      final double labelX = padding / 2 - textPainter.width / 2; // Position left of padding, centered
      final double labelY = lineY - textPainter.height / 2; // Center vertically on the line

      textPainter.paint(canvas, Offset(labelX, labelY));
    }

    List<List<PlacedQuantumGate>> localPlacedGates = circuit.placedGates;

    debugPrint('Highlighting Offset: $draggingOffset');

    // **** HIGHLIGHT BOX
    // Draw the highlight box if a cell is highlighted
    if (draggingOffset != null) {
      localPlacedGates = initLocalPlacedGatesMap(localPlacedGates);
    }

    List<int> gateXPosititionPerQubit = List<int>.filled(circuit.currentLevel.numQubits, 0);

    // Draw placed gates
    for (final (primaryDrawingQubit, row) in localPlacedGates.indexed) {
      debugPrint('Drawing qubit line $primaryDrawingQubit with ${row.length} gates');
      for (final (currentX, placedGate) in row.indexed) {
        // Calculate the top-left corner of the gate icon square
        if (placedGate.type == SelectedGateType.cnot) {
          // Drawing logic for CNOT not target
          // int currentX = gateXPosititionPerQubit.reduce(max);
          final double gateColumnCenterX = padding + currentX * gateSpacing + gateSize / 2;
          debugPrint('  Drawing CNOT at $gateColumnCenterX');

          gateXPosititionPerQubit[primaryDrawingQubit] += 1; // Increment for next gate

          if (placedGate.type != SelectedGateType.none && placedGate.isTarget) {
            // Use the helper for the vertical centers of control and target qubits
            final double controlY = getQubitCenterY(placedGate.controlQubitIndex!);
            final double targetY = getQubitCenterY(primaryDrawingQubit);

            // Draw control circle/dot
            final controlPaint = Paint()
              ..color = SelectedGateType.cnot.color;
            canvas.drawCircle(Offset(gateColumnCenterX, controlY), controlDotRadius, controlPaint);

            // Draw connection line between control and target
            final linePaint = Paint()
              ..color = SelectedGateType.cnot.color
              ..strokeWidth = 2.0;
            canvas.drawLine(Offset(gateColumnCenterX, controlY), Offset(gateColumnCenterX, targetY), linePaint);

            // Draw target circle
            final targetPaint = Paint()
              ..color = SelectedGateType.cnot.color;
            canvas.drawCircle(Offset(gateColumnCenterX, targetY), targetRadius, targetPaint);

            // Draw '+' inside target circle
            final plusPainter = TextPainter(
              text: TextSpan(text: '+', style: TextStyle(color: Colors.white, fontSize: 24)),
              textDirection: TextDirection.ltr,
            );
            plusPainter.layout();
            plusPainter.paint(canvas, Offset(gateColumnCenterX - plusPainter.width / 2, targetY - plusPainter.height / 2));
          }

          widthNotifier.value = max(widthNotifier.value, gateColumnCenterX + gateSize + 2 * padding);
        } else if (placedGate.type == SelectedGateType.ccnot) {
          // Drawing logic for CCNOT not target
          // int currentX = gateXPosititionPerQubit.reduce(max);
          final double gateColumnCenterX = padding + currentX * gateSpacing + gateSize / 2;
          debugPrint('  Drawing CCNOT at $gateColumnCenterX');

          gateXPosititionPerQubit[primaryDrawingQubit] += 1; // Increment for next gate

          if (placedGate.type != SelectedGateType.none && placedGate.isTarget) {
            // Use the helper for the vertical centers of control and target qubits
            final double controlY = getQubitCenterY(placedGate.controlQubitIndex!);
            final double control2Y = getQubitCenterY(placedGate.control2QubitIndex!);
            final double targetY = getQubitCenterY(primaryDrawingQubit);

            // Draw control circle/dot
            final controlPaint = Paint()
              ..color = SelectedGateType.ccnot.color; // Use the static constant
            canvas.drawCircle(Offset(gateColumnCenterX, controlY), controlDotRadius, controlPaint);

            // Draw control 2 circle/dot
            final control2Paint = Paint()
              ..color = SelectedGateType.ccnot.color; // Use the static constant
            canvas.drawCircle(Offset(gateColumnCenterX, control2Y), controlDotRadius, control2Paint);

            // Draw connection line between control and target
            final linePaint = Paint()
              ..color = SelectedGateType.ccnot.color
              ..strokeWidth = 2.0; // Use the static constant
            canvas.drawLine(Offset(gateColumnCenterX, controlY), Offset(gateColumnCenterX, targetY), linePaint);

            // Draw connection line between control 2 and target
            final line2Paint = Paint()
              ..color = SelectedGateType.ccnot.color
              ..strokeWidth = 2.0; // Use the static constant
            canvas.drawLine(Offset(gateColumnCenterX, control2Y), Offset(gateColumnCenterX, targetY), line2Paint);

            // Draw target circle
            final targetPaint = Paint()
              ..color = SelectedGateType.ccnot.color; // Use the static constant
            canvas.drawCircle(Offset(gateColumnCenterX, targetY), targetRadius, targetPaint);

            // Draw '+' inside target circle
            final plusPainter = TextPainter(
              text: TextSpan(text: '+', style: TextStyle(color: Colors.white, fontSize: 24)),
              textDirection: TextDirection.ltr,
            );
            plusPainter.layout();
            plusPainter.paint(canvas, Offset(gateColumnCenterX - plusPainter.width / 2, targetY - plusPainter.height / 2));
          }

          widthNotifier.value = max(widthNotifier.value, gateColumnCenterX + gateSize + 2 * padding);
        } else {
          // Use the helper for the vertical center of the primary qubit line
          final double gateCenterY = getQubitCenterY(primaryDrawingQubit);
          final double gateIconTop = gateCenterY - gateSize / 2; // Use gateCenterY to center vertically

          final double gateColumnCenterX = padding + gateXPosititionPerQubit[primaryDrawingQubit] * gateSpacing + gateSpacing / 2;

          debugPrint('  Drawing GATE at $gateColumnCenterX');

          gateXPosititionPerQubit[primaryDrawingQubit] += 1; // Increment for next gate

          if (placedGate.type != SelectedGateType.none) {
            gatePaint.color = placedGate.type.color; // Use the static constant
            var gateRect = Rect.fromLTWH(gateColumnCenterX - gateSize / 2, gateIconTop, gateSize, gateSize);

            if (placedGate.type == SelectedGateType.draggedGate) {
              final RRect highlightRect = RRect.fromRectAndRadius(gateRect, const Radius.circular(8),);

              // Draw shadow, fill and border
              canvas.drawRRect(highlightRect, highlightShadowPaint);
              canvas.drawRRect(highlightRect, highlightPaint);
              canvas.drawRRect(highlightRect, highlightBorderPaint);
            } else {
              canvas.drawRect(gateRect, gatePaint);
            }

            // Draw 'H' or 'S' or 'X', etc text centered in the square
            String gateText = placedGate.type.label; // Set the text
            gateTextPainter(gateText, canvas, gateColumnCenterX, gateIconTop);
          }

          widthNotifier.value = max(widthNotifier.value, gateColumnCenterX + gateSize + 2 * padding);
        }
      }
    }
  }

  List<List<PlacedQuantumGate>> initLocalPlacedGatesMap(List<List<PlacedQuantumGate>> localPlacedGates) {
    int? qubitLine = getTappedQubitLine(draggingOffset!);
    int? gatePosition = getInsertionPosition(draggingOffset!);

    debugPrint('Highlighting qubit line: $qubitLine and gate position: $gatePosition');

    if (qubitLine != null && gatePosition != null) {
      localPlacedGates = previewCircuit.clone(circuit.placedGates);
      gatePosition = circuit.isCircuitEmpty() ? 0 : min(gatePosition, circuit.maxCircuitDepth());

      PlacedQuantumGate targetGate = PlacedQuantumGate(
        type: SelectedGateType.draggedGate,
      );

      if (draggingGateType == SelectedGateType.cnot || draggingGateType == SelectedGateType.ccnot) {
        // this needs to be the minimum across the whole
        debugPrint('Place ${draggingGateType!.label} box at Highlighting qubit line: $qubitLine and gate position: $gatePosition');
        // verify length of the vertical filler always '1'
        for (List<PlacedQuantumGate> gateRow in localPlacedGates) {
          if (gatePosition > gateRow.length) {
            final int lengthFiller = (gateRow.length - gatePosition).abs();
            final fillerList = List<PlacedQuantumGate>.filled(lengthFiller, PlacedQuantumGate.emptyGate());
            gateRow.addAll(fillerList);
          }
          gateRow.insert(gatePosition, targetGate);
        }
      } else { // from here should only be single gate
        previewCircuit.insertSinglePlacedGateAt(SelectedGateType.draggedGate, gatePosition, qubitLine);
      }
    }
    return localPlacedGates;
  }

  void gateTextPainter(String gateText, Canvas canvas, double gateColumnCenterX, double gateIconTop) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: gateText,
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr, // Required for TextPainter
    );
    textPainter.layout(); // Perform layout before painting
    textPainter.paint(canvas, Offset(gateColumnCenterX - textPainter.width / 2, gateIconTop + gateSize / 2 - textPainter.height / 2));
  }

  bool removeGateAtTap(Offset tapPosition) {
    int? qubitLine = getTappedQubitLine(tapPosition);
    int? gatePosition = getInsertionPosition(tapPosition);

    debugPrint('Gate remove tap qubit line: $qubitLine and gate position: $gatePosition');

    if (qubitLine != null && gatePosition != null && gatePosition < circuit.placedGates[qubitLine].length) {
      circuit.removePlacedGate(gatePosition, qubitLine);
      return true;
    }

    return false;
  }

  // Implement the hit-testing method to find a TAPPED QUBIT LINE (for placement)
  // This method is also called from _handleCircuitTap and receives the local tap position.
  int? getTappedQubitLine(Offset tapPosition) {
    const double hitTolerance = QuantumCircuitPainter.hitTolerance;
    // Iterate through each possible qubit line
    // Assuming circuit.numQubits is available (e.g., passed in constructor or from circuit)
    for (int i = 0; i < circuit.currentLevel.numQubits; i++) {
      // Use the helper for the vertical center of the qubit line
      final double qubitLineCenterY = getQubitCenterY(i);
      debugPrint("  Checking Qubit $i. Center Y: $qubitLineCenterY. Hit range: ${qubitLineCenterY - hitTolerance} to ${qubitLineCenterY + hitTolerance}"); // Debug line position and range

      // Check if the tap's y-coordinate is close to this qubit line center within tolerance
      if (tapPosition.dy >= qubitLineCenterY - hitTolerance && tapPosition.dy <= qubitLineCenterY + hitTolerance) {
        debugPrint("  Tap position ${tapPosition.dy} is within range for Qubit $i. Returning $i."); // Debug hit
        return i; // Return the index of the tapped qubit line
      }
      debugPrint("  Tap position ${tapPosition.dy} is outside range for Qubit $i."); // Debug miss
    }
    debugPrint("No qubit line tapped. Returning null."); // Debug null return
    return null; // If no qubit line was tapped within tolerance
  }

  // New method to calculate the horizontal insertion position (column index)
  int? getInsertionPosition(Offset dropPosition) {
    // Calculate the horizontal position based on the drop position's x-coordinate
    // Subtract padding to get position relative to the circuit grid start
    final double dropXRelativeToGrid = dropPosition.dx - padding;

    // Calculate the potential column index
    // Divide by gateSpacing to get the column index, then round to the nearest integer
    // Add 0.5 before casting to int for proper rounding
    final int potentialPosition = ((dropXRelativeToGrid / gateSpacing)).floor(); // Use round() for standard rounding

    // Ensure the potential position is not negative
    if (potentialPosition < 0) {
      return 0; // Assume insertion at the first position if dropped before it
    }

    // For drag and drop, the horizontal position directly maps to a column.
    // The insertion logic in QuantumCircuit will handle shifting existing gates.
    return potentialPosition; // Return the calculated column index
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
