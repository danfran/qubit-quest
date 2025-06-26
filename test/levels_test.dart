import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/quantum_circuit.dart';
import 'package:quantumquiz/placed_quantum_gate.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/selected_gate_type.dart';
import 'package:quantumquiz/models/qubit_state.dart'; // Assuming this is minimal for test setup


void main() {
  // Helper to create an initial empty circuit for testing
  QuantumCircuit createEmptyCircuit(int numQubits) {
    final circuit = QuantumCircuit(numQubits: numQubits);
    return circuit;
  }

  const double tolerance = 1e-9;

  group('Test results for all levels', () {
    test('level 1', () {
      final level = getQQLevelById(1)!;

      final circuit = createEmptyCircuit(level.numQubits);

      circuit.insertSinglePlacedGateAt(SelectedGateType.x, 0, 0);

      expect(circuit.placedGates[0].length, 1);
      print('After insertGateAt(X, 0, 0):\n$circuit');

      circuit.runSimulation();

      expect(circuit.currentState.state.rawMatrix, Matrix(level.solutionFinalVector));
    });

    test('level 2', () {
      final level = getQQLevelById(2)!;

      final circuit = createEmptyCircuit(level.numQubits);

      circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0);

      expect(circuit.placedGates[0].length, 1);
      print('After insertGateAt(H, 0, 0):\n$circuit');

      circuit.runSimulation();

      expect(circuit.currentState.state.rawMatrix, Matrix(level.solutionFinalVector));
    });

    test('level 3', () {
      final level = getQQLevelById(3)!;

      final circuit = createEmptyCircuit(level.numQubits);

      circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0);
      circuit.insertDoublePlacedGateAt(SelectedGateType.cnot, 1, 0, 1);

      expect(circuit.placedGates[0].length, 2);
      expect(circuit.placedGates[1].length, 2);
      print('Circuit after inserting gates:\n$circuit');

      circuit.runSimulation();

      expect(circuit.currentState.state.rawMatrix, Matrix(level.solutionFinalVector));
    });
  });
}