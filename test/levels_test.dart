import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/qubit_state.dart'; // Assuming this is minimal for test setup


void main() {
  _testBody(int levelNumber, Function(QuantumCircuit) body) {
    final level = getQQLevelById(levelNumber)!;

    debugPrint('Level $levelNumber: ${level.taskDescription}\n\n');

    final circuit = QuantumCircuit(currentLevel: level);

    body(circuit);

    debugPrint('Circuit after inserting gates:\n$circuit');

    circuit.runSimulation();

    expect(circuit.currentState.state.almostEqualTo(QuantumMatrix(level.solutionFinalVector)), true);

    debugPrint('\n\n');
  }

  group('Test results for all levels', () {
    var tests = [
      (QuantumCircuit circuit) {
      // check X is in the avaiable gates
      //   assert(circuit.availableGates.contains(SelectedGateType.x));
        circuit.insertSinglePlacedGateAt(SelectedGateType.x, 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.z, 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.y, 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.y, 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.x, 0, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.z, 1, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.x, 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.t, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.s, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.z, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.s, 1, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.z, 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.s, 3, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 4, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.x, 5, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.s, 1, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.t, 2, 0);
        circuit.insertSinglePlacedGateAt(SelectedGateType.z, 3, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(SelectedGateType.cnot, 0, 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0);
        circuit.insertDoublePlacedGateAt(SelectedGateType.cnot, 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertTriplePlacedGateAt(SelectedGateType.ccnot, 0, 1, 0, 2);
      },
    ];

    for (int i = 1; i <= tests.length; i++) {
      test('level $i', () {
        _testBody(i, tests[i - 1]);
      });
    }
  });
}