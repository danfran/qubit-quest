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

  test('pure row and insertion-column mapping preserves current geometry', () {
    expect(CircuitGeometry.qubitForPoint(const Offset(40, 20), 3), 0);
    expect(CircuitGeometry.qubitForPoint(const Offset(40, 60), 3), 1);
    expect(CircuitGeometry.qubitForPoint(const Offset(40, 100), 3), 2);
    expect(CircuitGeometry.qubitForPoint(const Offset(40, 121), 3), isNull);
    expect(CircuitGeometry.insertionColumnForPoint(const Offset(0, 20)), 0);
    expect(CircuitGeometry.insertionColumnForPoint(const Offset(59, 20)), 0);
    expect(CircuitGeometry.insertionColumnForPoint(const Offset(60, 20)), 1);
  });

  test('content width and preview are computed without painting', () {
    final circuit = QuantumCircuit(
      currentLevel: ComposerLevel(
        taskDescription: 'geometry',
        numQubits: 2,
        initialQubitsStateStr: '00',
        initialQubitsState: ComposerLevel.getZeroStateVector(2),
        availableGates: const [],
        solutionFinalVector: const [],
      ),
    );
    expect(CircuitGeometry.contentWidth(circuit), 120);
    final preview = CircuitGeometry.insertionPreview(
      circuit: circuit,
      point: const Offset(40, 60),
      gate: Gate.fromIdentifier(SelectedGateType.hadamard),
    );
    expect(preview[1].single.gate.type, SelectedGateType.draggedGate);
    expect(circuit.isCircuitEmpty(), isTrue);

    circuit.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1);
    expect(CircuitGeometry.contentWidth(circuit), 200);
  });
}
