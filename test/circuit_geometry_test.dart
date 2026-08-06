import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';

void main() {
  group('drag-to-delete bounds', () {
    for (final bounds in <Rect>[
      const Rect.fromLTWH(20, 80, 360, 240),
      const Rect.fromLTWH(100, 30, 900, 160),
    ]) {
      test('uses the same safety margin for ${bounds.width}x${bounds.height}',
          () {
        expect(
          CircuitGeometry.isClearlyOutsideCircuitForDeletion(
            circuitBounds: bounds,
            pointerPosition: bounds.center,
          ),
          isFalse,
        );
        expect(
          CircuitGeometry.isClearlyOutsideCircuitForDeletion(
            circuitBounds: bounds,
            pointerPosition: Offset(bounds.left - 6, bounds.center.dy),
          ),
          isFalse,
        );
        expect(
          CircuitGeometry.isClearlyOutsideCircuitForDeletion(
            circuitBounds: bounds,
            pointerPosition: Offset(bounds.left - 13, bounds.center.dy),
          ),
          isTrue,
        );
      });
    }
  });

  test('controlled logical bounds hit control, connector, and target', () {
    final circuit = QuantumCircuit(
      currentLevel: ComposerLevel(
        taskDescription: 'geometry',
        numQubits: 3,
        initialQubitsStateStr: '000',
        initialQubitsState: ComposerLevel.getZeroStateVector(3),
        availableGates: const [],
        solutionFinalVector: const [],
      ),
    );
    circuit.insertDoublePlacedGateAt(
      Gate.fromIdentifier(SelectedGateType.cnot),
      0,
      2,
      0,
    );
    final id = circuit.placedGates[0][0].id!;
    final bounds = CircuitGeometry.logicalGateBounds(circuit, id)!;

    for (final position in const [
      Offset(40, 20),
      Offset(40, 60),
      Offset(40, 100),
    ]) {
      expect(bounds.contains(position), isTrue);
      expect(CircuitGeometry.hitTestGate(circuit, position)?.id, id);
    }
  });
}
