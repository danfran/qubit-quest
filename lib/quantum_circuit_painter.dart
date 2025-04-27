import 'package:flutter/material.dart';
import 'package:quantumquiz/quantum_circuit.dart';
import 'package:quantumquiz/quantum_gate.dart';

// Assume QubitState and QuantumGate classes are defined as above

class QuantumCircuitPainter extends CustomPainter {
  final QuantumCircuit circuit;

  static const double qubitSpacing = 40.0;
  static const double gateSpacing = 60.0;
  static const double gateSize = 30.0;
  static const double padding = 20.0;
  static const double hitTolerance = 30.0;

  // Define static colors for gate types
  static const Color hadamardColor = Colors.blue; // Example color for Hadamard
  static const Color cnotColor = Colors.blue; // Example color for CNOT (often same as H)
  static const Color pauliXColor = Colors.green; // Example color for Pauli-X


  QuantumCircuitPainter(this.circuit);

  @override
  void paint(Canvas canvas, Size size) {
    // print('QuantumCircuitPainter paint method called. Canvas size: ${size.width}x${size.height}');

    final Paint linePaint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 2.0;

    // Create a single gatePaint and change its color as needed
    final Paint gatePaint = Paint()
      ..style = PaintingStyle.fill; // Style remains fill

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Draw qubit lines
    for (int i = 0; i < 2; i++) {
      final double y = padding + i * qubitSpacing;
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), linePaint);

      // Draw qubit labels
      textPainter.text = TextSpan(
        text: 'q$i',
        style: TextStyle(color: Colors.black, fontSize: 14),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(padding - textPainter.width - 5, y - textPainter.height / 2));
    }

    // Draw gates
    double currentX = padding + gateSpacing / 2;
    for (var gate in circuit.gates) {
      if (gate is HadamardGate) {
        // Set the color for Hadamard
        gatePaint.color = hadamardColor;
        final double gateY = padding + gate.targetQubit * qubitSpacing - gateSize / 2;
        canvas.drawRect(Rect.fromLTWH(currentX, gateY, gateSize, gateSize), gatePaint);

        textPainter.text = TextSpan(
          text: 'H',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(currentX + gateSize / 2 - textPainter.width / 2, gateY + gateSize / 2 - textPainter.height / 2));

      } else if (gate is CNOTGate) {
        // Set the color for CNOT
        gatePaint.color = cnotColor;
        final double controlY = padding + gate.controlQubit * qubitSpacing;
        final double targetY = padding + gate.targetQubit * qubitSpacing;
        final double gateCenterX = currentX + gateSize / 2;

        // Draw the control point (filled circle) using gatePaint
        canvas.drawCircle(Offset(gateCenterX, controlY), 5.0, gatePaint);

        // Draw the line connecting control and target (using linePaint for consistency with qubit lines)
        canvas.drawLine(Offset(gateCenterX, controlY), Offset(gateCenterX, targetY), linePaint);

        // Draw the target circle with a cross (using linePaint)
        canvas.drawCircle(Offset(gateCenterX, targetY), gateSize / 2, linePaint); // Outer circle
        canvas.drawLine(Offset(gateCenterX - gateSize / 4, targetY), Offset(gateCenterX + gateSize / 4, targetY), linePaint); // Horizontal line
        canvas.drawLine(Offset(gateCenterX, targetY + gateSize / 4), Offset(gateCenterX, targetY - gateSize / 4), linePaint); // Vertical line


      }
      // Add drawing logic for other gate types, setting gatePaint.color accordingly

      currentX += gateSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  // Helper to determine which qubit line was tapped
  int? getTappedQubit(Offset tapPosition) {
    // ... (getTappedQubit implementation using static constants) ...
    for (int i = 0; i < 2; i++) {
      final double y = padding + i * qubitSpacing;
      const double hitTolerance = QuantumCircuitPainter.hitTolerance; // Use static hit tolerance
      if (tapPosition.dy >= y - hitTolerance && tapPosition.dy <= y + hitTolerance) {
        return i;
      }
    }
    return null;
  }
}
