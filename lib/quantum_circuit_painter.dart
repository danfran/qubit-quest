// quantum_circuit_painter.dart

import 'package:flutter/material.dart';
import 'dart:math'; // For min/max
import 'package:complex/complex.dart'; // Assuming Complex is used for CNOT drawing details if needed
import 'package:quantumquiz/placed_quantum_gate.dart'; // Import PlacedQuantumGate
import 'package:quantumquiz/quantum_circuit.dart'; // Import QuantumCircuit
import 'package:quantumquiz/selected_gate_type.dart'; // Import SelectedGateType


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
  static const Color gridLinesColor = Colors.black; // Define color for qubit lines (Black)
  static const Color qubitLabelColor = Colors.black; // Color for qubit labels (q0, q1) (Black)
  // Add colors for other gate types as needed

  // ** Debugging color for hit areas **
  static const Color debugHitAreaColor = Colors.redAccent; // Color to visualize hit areas
  // ***********************************


  final QuantumCircuit circuit; // Painter needs the circuit (with List<PlacedQuantumGate> placedGates)
  final ValueNotifier<double> widthNotifier;

  QuantumCircuitPainter(this.circuit, {required this.widthNotifier});

  // Helper getter to calculate the vertical center of a qubit line
  double getQubitCenterY(int qubitIndex) {
    return qubitIndex * qubitSpacing + qubitSpacing / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    print("Painting circuit. Canvas size: $size"); // Debug canvas size
    final linePaint = Paint()
      ..color = gridLinesColor // Use the static constant for lines
      ..strokeWidth = 1.0; // Ensure consistent stroke width

    final gatePaint = Paint(); // Paint object for drawing gate icons

    // Paint for drawing debug hit areas
    final debugPaint = Paint()
      ..color = debugHitAreaColor.withOpacity(0.3) // Semi-transparent color
      ..style = PaintingStyle.fill; // Fill the rectangle


    // Draw qubit lines and labels
    for (int i = 0; i < circuit.numQubits; i++) {
      // Calculate the vertical center Y for this qubit line
      final double lineY = getQubitCenterY(i);
      print("  Painter: Drawing Qubit $i line and hit area at Y: $lineY. Hit range: ${lineY - hitTolerance} to ${lineY + hitTolerance}"); // Debug calculated drawing Y

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
          text: 'q$i', // Label text (e.g., "q0", "q1")
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

    List<int> gateXPosititionPerQubit = [0, 0];

    // Draw placed gates
    for (final placedGate in circuit.placedGates) {
      // Calculate the horizontal center x-coordinate of the gate's column
      // Gates are positioned relative to the area *after* the initial padding and labels

      // Use the helper for the vertical center of the primary qubit line
      final double gateCenterY = getQubitCenterY(placedGate.primaryDrawingQubit);
      final double gateIconTop = gateCenterY - gateSize / 2; // Use gateCenterY to center vertically

      // Calculate the top-left corner of the gate icon square
      if (placedGate.type == SelectedGateType.cnot) {
        // Drawing logic for CNOT
        int currentX = gateXPosititionPerQubit.reduce(max);
        final double gateColumnCenterX = padding + currentX * gateSpacing + gateSpacing / 2;

        gateXPosititionPerQubit = List.filled(circuit.numQubits, currentX + 1);

        // Use the helper for the vertical centers of control and target qubits
        final double controlY = getQubitCenterY(placedGate.controlQubitIndex!);
        final double targetY = getQubitCenterY(placedGate.targetQubitIndex!);

        // Draw control circle/dot
        final controlPaint = Paint()..color = SelectedGateType.cnot.color; // Use the static constant
        canvas.drawCircle(Offset(gateColumnCenterX, controlY), controlDotRadius, controlPaint);

        // Draw connection line between control and target
        final linePaint = Paint()..color = SelectedGateType.cnot.color..strokeWidth = 2.0; // Use the static constant
        canvas.drawLine(Offset(gateColumnCenterX, controlY), Offset(gateColumnCenterX, targetY), linePaint);

        // Draw target circle
        final targetPaint = Paint()..color = SelectedGateType.cnot.color; // Use the static constant
        canvas.drawCircle(Offset(gateColumnCenterX, targetY), targetRadius, targetPaint);


        // Draw '+' inside target circle
        final plusPainter = TextPainter(
          text: TextSpan(text: '+', style: TextStyle(color: Colors.white, fontSize: 24)), // Use the static constant
          textDirection: TextDirection.ltr,
        );
        plusPainter.layout();
        plusPainter.paint(canvas, Offset(gateColumnCenterX - plusPainter.width / 2, targetY - plusPainter.height / 2));

        widthNotifier.value = max(widthNotifier.value, gateColumnCenterX + gateSize + 2 * padding);
      } else {
        final double gateColumnCenterX = padding + gateXPosititionPerQubit[placedGate.primaryDrawingQubit] * gateSpacing + gateSpacing / 2;

        gateXPosititionPerQubit[placedGate.primaryDrawingQubit] += 1; // Increment for next gate

        gatePaint.color = placedGate.type.color; // Use the static constant
        canvas.drawRect(Rect.fromLTWH(gateColumnCenterX - gateSize / 2, gateIconTop, gateSize, gateSize), gatePaint);

        // Draw 'H' text centered in the square
        String gateText = placedGate.type.label; // Set the text to 'H'
        gateTextPainter(gateText, canvas, gateColumnCenterX, gateIconTop);

        widthNotifier.value = max(widthNotifier.value, gateColumnCenterX + gateSize + 2 * padding);
      }
      // Add drawing logic for other gate types here
    }
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

  // Implement the hit-testing method to find a TAPPED GATE
  // This method is called from _handleCircuitTap and receives the local tap position.
  PlacedQuantumGate? getGateAtTap(Offset tapPosition) {
    // Iterate through the list of placed gates in the circuit
    for (final placedGate in circuit.placedGates) {
      // Calculate the horizontal center x-coordinate of the gate's column
      final double gateColumnCenterX = padding + placedGate.position * gateSpacing + gateSpacing / 2;

      // Use the helper for the vertical center of the primary qubit line
      final double gateCenterY = getQubitCenterY(placedGate.primaryDrawingQubit);

      // Calculate the bounding box (rectangle) around the gate icon for hit testing
      // This rectangle is where the gate icon would be drawn, plus hit tolerance.
      final double gateIconLeft = gateColumnCenterX - gateSize / 2;
      final double gateIconTop = gateCenterY - gateSize / 2; // Use gateCenterY
      final double gateIconRight = gateColumnCenterX + gateSize / 2;
      final double gateIconBottom = gateCenterY + gateSize / 2; // Use gateCenterY

      // Create a slightly larger rectangle including hit tolerance for easier tapping
      final Rect gateHitRect = Rect.fromLTRB(
        gateIconLeft - hitTolerance,
        gateIconTop - hitTolerance,
        gateIconRight + hitTolerance,
        gateIconBottom + hitTolerance,
      );

      // Check if the tap position is inside this gate icon's hit rectangle
      if (gateHitRect.contains(tapPosition)) {
        return placedGate; // Return the specific PlacedQuantumGate object that was tapped
      }

      // Handle hit testing for CNOT connection line and target circle
      if (placedGate.type == SelectedGateType.cnot) {
        // Use the helper for the vertical centers of control and target qubits
        final double controlY = getQubitCenterY(placedGate.controlQubitIndex!);
        final double targetY = getQubitCenterY(placedGate.targetQubitIndex!);

        // The connection line is vertical at the gate's column center x-position
        final double lineX = gateColumnCenterX;
        final double lineTop = min(controlY, targetY);
        final double lineBottom = max(controlY, targetY);

        // Create a thin rectangle for the connection line (add horizontal tolerance)
        final Rect connectionLineHitRect = Rect.fromLTRB(
          lineX - hitTolerance / 2, // Make it tappable horizontally
          lineTop,
          lineX + hitTolerance / 2, // Make it tappable horizontally
          lineBottom,
        );

        // Check if the tap hit the connection line
        if (connectionLineHitRect.contains(tapPosition)) {
          return placedGate; // Return the CNOT gate if its connection line is tapped
        }

        // Check the target circle hit area
        final double targetCircleY = getQubitCenterY(placedGate.targetQubitIndex!); // Use helper
        final double targetCircleRadius = QuantumCircuitPainter.targetRadius;
        final double targetCircleLeft = gateColumnCenterX - (targetCircleRadius + hitTolerance / 2);
        final double targetCircleTop = targetCircleY - (targetCircleRadius + hitTolerance / 2);
        final double targetCircleRight = gateColumnCenterX + (targetCircleRadius + hitTolerance / 2);
        final double targetCircleBottom = targetCircleY + (targetCircleRadius + hitTolerance / 2);
        final Rect targetCircleHitRect = Rect.fromLTRB(targetCircleLeft, targetCircleTop, targetCircleRight, targetCircleBottom);

        // Check if the tap hit the target circle
        if (targetCircleHitRect.contains(tapPosition)) {
          return placedGate; // Return the CNOT gate if its target circle is tapped
        }
      }
    }

    return null; // If the loop finishes without finding a gate, return null
  }

  // Implement the hit-testing method to find a TAPPED QUBIT LINE (for placement)
  // This method is also called from _handleCircuitTap and receives the local tap position.
  int? getTappedQubitLine(Offset tapPosition) {
    const double hitTolerance = QuantumCircuitPainter.hitTolerance;
    // Iterate through each possible qubit line
    // Assuming circuit.numQubits is available (e.g., passed in constructor or from circuit)
    for (int i = 0; i < circuit.numQubits; i++) {
      // Use the helper for the vertical center of the qubit line
      final double qubitLineCenterY = getQubitCenterY(i);
      print("  Checking Qubit $i. Center Y: $qubitLineCenterY. Hit range: ${qubitLineCenterY - hitTolerance} to ${qubitLineCenterY + hitTolerance}"); // Debug line position and range

      // Check if the tap's y-coordinate is close to this qubit line center within tolerance
      if (tapPosition.dy >= qubitLineCenterY - hitTolerance && tapPosition.dy <= qubitLineCenterY + hitTolerance) {
        print("  Tap position ${tapPosition.dy} is within range for Qubit $i. Returning $i."); // Debug hit
        return i; // Return the index of the tapped qubit line
      }
      print("  Tap position ${tapPosition.dy} is outside range for Qubit $i."); // Debug miss
    }
    print("No qubit line tapped. Returning null."); // Debug null return
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
    final int potentialPosition = ((dropXRelativeToGrid / gateSpacing)).round(); // Use round() for standard rounding

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
    // print("shouldRepaint called.");
    // print("New circuit placedGates length: ${circuit.placedGates.length}");
    // print("Old circuit placedGates length: ${oldDelegate.circuit.placedGates.length}");

    // Check if the list reference is different.
    if (circuit.placedGates != oldDelegate.circuit.placedGates) {
      // print("shouldRepaint: true (list reference changed).");
      return true;
    }

    // Check if the list length has changed.
    if (circuit.placedGates.length != oldDelegate.circuit.placedGates.length) {
      // print("shouldRepaint: true (list length changed).");
      return true;
    }

    // If list reference and length are the same, perform a deep comparison of contents.
    // This is the most thorough check.
    for (int i = 0; i < circuit.placedGates.length; i++) {
      final newGate = circuit.placedGates[i];
      final oldGate = oldDelegate.circuit.placedGates[i];

      // Compare relevant properties that affect drawing
      if (newGate.type != oldGate.type ||
          newGate.position != oldGate.position ||
          newGate.singleQubitIndex != oldGate.singleQubitIndex ||
          newGate.controlQubitIndex != oldGate.controlQubitIndex ||
          newGate.targetQubitIndex != oldGate.targetQubitIndex) {
        // print("shouldRepaint: true (gate properties changed at index $i).");
        return true; // A gate's properties has changed, need to repaint
      }
      // Add debug prints to see if properties are being compared and if they match
      // print("Comparing gate at index $i:");
      // print("  New: type=${newGate.type}, pos=${newGate.position}, single=${newGate.singleQubitIndex}, control=${newGate.controlQubitIndex}, target=${newGate.targetQubitIndex}");
      // print("  Old: type=${oldGate.type}, pos=${oldGate.position}, single=${oldGate.singleQubitIndex}, control=${oldGate.controlQubitIndex}, target=${oldGate.targetQubitIndex}");
      // if (newGate.type != oldGate.type) print("    Type mismatch!");
      // if (newGate.position != oldGate.position) print("    Position mismatch!");
      // if (newGate.singleQubitIndex != oldGate.singleQubitIndex) print("    Single Qubit mismatch!");
      // if (newGate.controlQubitIndex != oldGate.controlQubitIndex) print("    Control Qubit mismatch!");
      // if (newGate.targetQubitIndex != oldGate.targetQubitIndex) print("    Target Qubit mismatch!");
    }

    // If none of the checks above indicate a change, no need to repaint.
    // print("shouldRepaint: false (no changes detected after deep comparison).");
    return false;
  }
}
