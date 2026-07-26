import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';

void main() {
  ComposerLevel simpleOneQubitLevel() {
    return ComposerLevel.fromBinaryString(
      title: 'Rotation hotfix fixture',
      taskDescription: 'Reach |1>.',
      initialQubitsStateString: '0',
      availableGates: [
        Gate.fromIdentifier(SelectedGateType.rx),
        Gate.fromIdentifier(SelectedGateType.ry),
        Gate.fromIdentifier(SelectedGateType.rz),
      ],
      solutionFinalVector: [
        [Complex.zero()],
        [Complex.one()],
      ],
    );
  }

  group('Rotation gate runtime hotfix', () {
    test('plain Rx, Ry, and Rz require angle selection before insertion', () {
      for (final type in [
        SelectedGateType.rx,
        SelectedGateType.ry,
        SelectedGateType.rz,
      ]) {
        final plainGate = Gate.fromIdentifier(type);
        final configuredGate = Gate.fromIdentifier(type, angle: math.pi / 2);

        expect(plainGate.requiresAngle, isTrue);
        expect(plainGate.hasValidRequiredParameters, isFalse);
        expect(requiresRotationAngleSelection(plainGate), isTrue);
        expect(configuredGate.hasValidRequiredParameters, isTrue);
        expect(requiresRotationAngleSelection(configuredGate), isFalse);
      }
    });

    test('cancelling angle selection must leave plain rotation uninserted', () {
      final circuit = QuantumCircuit(currentLevel: simpleOneQubitLevel());
      final before = circuit.placedGates[0].length;

      expect(
        () => circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.ry),
          0,
          0,
        ),
        throwsArgumentError,
      );
      expect(circuit.placedGates[0].length, before);
      expect(circuit.isCircuitEmpty(), isTrue);
    });

    test('selecting an angle inserts rotation with a non-null parameter', () {
      final circuit = QuantumCircuit(currentLevel: simpleOneQubitLevel());
      final gate = Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2);

      circuit.insertSinglePlacedGateAt(gate, 0, 0);

      expect(circuit.placedGates[0], hasLength(1));
      expect(circuit.placedGates[0][0].gate.type, SelectedGateType.ry);
      expect(circuit.placedGates[0][0].gate.angle, math.pi / 2);
    });

    test('malformed rotation gate cannot crash runSimulation', () {
      final circuit = QuantumCircuit(currentLevel: simpleOneQubitLevel());
      circuit.placedGates[0].add(
        PlacedQuantumGate(gate: Gate.fromIdentifier(SelectedGateType.ry)),
      );

      expect(circuit.runSimulation, returnsNormally);
      expect(circuit.lastSimulationError, isNotNull);
      expect(circuit.lastSimulationError!.gateType, SelectedGateType.ry);
      expect(circuit.lastSimulationError!.columnIndex, 0);
      expect(circuit.lastSimulationError!.qubitIndex, 0);
      expect(
        circuit.lastSimulationError!.userMessage,
        'Choose an angle for the Ry gate before checking the circuit.',
      );
    });

    test(
        'malformed rotation gate cannot pass validation after failed simulation',
        () {
      final level = simpleOneQubitLevel();
      final circuit = QuantumCircuit(currentLevel: level);
      circuit.placedGates[0].add(
        PlacedQuantumGate(gate: Gate.fromIdentifier(SelectedGateType.rz)),
      );

      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isFalse);
      expect(level.evaluateCircuit(circuit).finalReason,
          'Choose an angle for the Rz gate before checking the circuit.');
    });

    test('Mastery Challenge 42 valid configured solution passes', () {
      final level = getQQLevelById(102)! as ComposerLevel;
      final circuit = QuantumCircuit(currentLevel: level);

      circuit.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2),
        0,
        0,
      );
      circuit.runSimulation();

      expect(circuit.lastSimulationError, isNull);
      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Mastery Challenge 42 incorrect configured solution fails normally',
        () {
      final level = getQQLevelById(102)! as ComposerLevel;
      final circuit = QuantumCircuit(currentLevel: level);

      circuit.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2),
        0,
        0,
      );
      circuit.runSimulation();

      expect(circuit.lastSimulationError, isNull);
      expect(level.validateCircuit(circuit), isFalse);
    });

    test('complex vectors are compared, not probabilities alone', () {
      final level = getQQLevelById(102)! as ComposerLevel;
      final circuit = QuantumCircuit(currentLevel: level);

      circuit.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi),
        0,
        0,
      );
      circuit.runSimulation();

      final current = circuit.currentState.stateVector;
      final target = level.solutionFinalVector.map((row) => row.first).toList();
      expect(current[0].abs(), target[0].abs());
      expect(current[1].abs(), closeTo(target[1].abs(), 1e-12));
      expect(level.validateCircuit(circuit), isFalse);
    });

    test('existing pre-inserted rotation gates retain configured angles', () {
      final inverseRotation = getQQLevelById(103)! as ComposerLevel;
      final composedRotation = getQQLevelById(104)! as ComposerLevel;

      final inverseCircuit = QuantumCircuit(currentLevel: inverseRotation);
      final composedCircuit = QuantumCircuit(currentLevel: composedRotation);

      expect(inverseCircuit.placedGates[0][0].gate.type, SelectedGateType.ry);
      expect(inverseCircuit.placedGates[0][0].gate.angle, math.pi / 2);
      expect(composedCircuit.placedGates[0][0].gate.type, SelectedGateType.rx);
      expect(composedCircuit.placedGates[0][0].gate.angle, math.pi / 2);
    });

    test('replacement into an empty slot cannot remove a required angle', () {
      final circuit = QuantumCircuit(currentLevel: simpleOneQubitLevel());
      circuit.placedGates[0].add(PlacedQuantumGate.emptyGate());

      expect(
        () => circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.rx),
          0,
          0,
        ),
        throwsArgumentError,
      );
      expect(circuit.placedGates[0][0].gate.type, SelectedGateType.none);
    });
  });
}
