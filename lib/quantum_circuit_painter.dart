import 'package:flutter/material.dart';
import 'dart:math'; // For sqrt
import 'package:quantumquiz/quantum_circuit.dart'; // For Complex

// Assume QubitState and QuantumGate classes are defined as above

class QuantumCircuitPainter extends CustomPainter {
  final QuantumCircuit circuit;

  QuantumCircuitPainter(this.circuit);

  @override
  void paint(Canvas canvas, Size size) {
    final double qubitSpacing = 40.0;
    final double gateSpacing = 60.0;
    final double gateSize = 30.0;
    final double padding = 20.0;

    final Paint linePaint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 2.0;

    final Paint gatePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

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
    double currentX = padding + gateSpacing;
    for (var gate in circuit.gates) {
      // This is a simplified drawing. You'll need logic to draw
      // different gate types (H, CNOT, etc.) at the correct qubit positions.
      // For a simple example, let's just draw a box for each gate.
      for (int i = 0; i < gate.getNumberOfQubits(); i++) {
         final double gateY = padding + i * qubitSpacing - gateSize / 2;
         canvas.drawRect(Rect.fromLTWH(currentX, gateY, gateSize, gateSize), gatePaint);

         // Draw gate name (simplified)
         textPainter.text = TextSpan(
           text: gate.runtimeType.toString().replaceAll('Gate', ''),
           style: TextStyle(color: Colors.white, fontSize: 12),
         );
         textPainter.layout();
         textPainter.paint(canvas, Offset(currentX + gateSize / 2 - textPainter.width / 2, gateY + gateSize / 2 - textPainter.height / 2));
      }
      currentX += gateSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint whenever the circuit changes
  }
}

class QuantumComposer extends StatefulWidget {
  @override
  _QuantumComposerState createState() => _QuantumComposerState();
}

class _QuantumComposerState extends State<QuantumComposer> {
  final QuantumCircuit circuit = QuantumCircuit();
  String simulationResult = "Run the circuit to see the result";

  void _addHadamard() {
    // This is a placeholder. You need to specify which qubit
    // circuit.addGate(HadamardGate(0)); // Add H to qubit 0
    setState(() {});
  }

  void _runSimulation() {
     circuit.run();
     setState(() {
       simulationResult = circuit.currentState.toString();
     });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomPaint(
            painter: QuantumCircuitPainter(circuit),
            child: Container(), // Placeholder child
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _addHadamard, // Needs to be refined to select qubit
                child: Text('Add H (Qubit 0)'),
              ),
              // Add buttons for other gates
              ElevatedButton(
                onPressed: _runSimulation,
                child: Text('Run Simulation'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("State Vector: $simulationResult"),
        ),
      ],
    );
  }
}