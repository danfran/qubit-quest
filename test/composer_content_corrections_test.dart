import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  ComposerLevel level(int id) => getQQLevelById(id)! as ComposerLevel;

  QuantumCircuit verify(
    int id,
    void Function(QuantumCircuit circuit) build,
  ) {
    final composerLevel = level(id);
    final circuit = QuantumCircuit(currentLevel: composerLevel);
    build(circuit);
    circuit.runSimulation();
    expect(
      composerLevel.validateCircuit(circuit),
      isTrue,
      reason: 'Corrected authored sequence must reach level $id target.',
    );
    return circuit;
  }

  group('historical qubit-order content corrections', () {
    test('ID 22 uses CNOT Q1 control to Q0 target for |10> -> |11>', () {
      verify(22, (circuit) {
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          0,
          0,
          1,
        );
      });
    });

    test('ID 75 uses CNOT Q0 control to Q1 target for |01> -> |11>', () {
      verify(75, (circuit) {
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          0,
          1,
          0,
        );
      });
    });

    test('ID 76 uses long-range CNOT Q2 control to Q0 target', () {
      verify(76, (circuit) {
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          0,
          0,
          2,
        );
      });
    });

    test('ID 77 uncomputes its fixed CNOT: |11> -> |01> -> |11>', () {
      verify(77, (circuit) {
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          1,
          1,
          0,
        );
      });
    });

    test('ID 79 uses Q0/Q3 controls and Q1 target', () {
      verify(79, (circuit) {
        circuit.insertTriplePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.ccnot),
          0,
          1,
          0,
          3,
        );
      });
    });

    test('ID 80 prose topology matches its fixed Q1/Q2 -> Q0 gate', () {
      final circuit = QuantumCircuit(currentLevel: level(80));
      final fixed = circuit.logicalGates.single;
      expect(fixed.type, SelectedGateType.ccnot);
      expect(fixed.controlQubit, 1);
      expect(fixed.secondControlQubit, 2);
      expect(fixed.targetQubit, 0);

      verify(80, (candidate) {
        candidate.insertTriplePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.ccnot),
          1,
          0,
          1,
          2,
        );
      });
    });

    test('ID 81 follows X(Q0) |010> -> |011>, then CCX -> |111>', () {
      verify(81, (circuit) {
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x),
          0,
          0,
        );
        circuit.insertTriplePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.ccnot),
          1,
          2,
          0,
          1,
        );
      });
    });

    test('ID 90 Bell sequence follows the corrected intermediate kets', () {
      verify(90, (circuit) {
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x),
          0,
          1,
        );
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard),
          1,
          0,
        );
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          2,
          1,
          0,
        );
      });
    });

    test('ID 93 uses long-range CNOT Q0 control to Q2 target', () {
      verify(93, (circuit) {
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          0,
          2,
          0,
        );
      });
    });
  });
}
