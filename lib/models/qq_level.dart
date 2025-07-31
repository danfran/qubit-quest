// lib/models/level.dart

import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/utils/math_utils.dart'; // Your enum for gate types

class QQLevel {
  final String type;
  final String taskDescription;
  final int numQubits;
  final String initialQubitsStateStr; // Assuming this is a state vector (e.g., |00..0>)
  final List<Complex> initialQubitsState; // Assuming this is a state vector (e.g., |00..0>)
  final Function(QuantumCircuit)? preInsertedGates; // The target state vector
  final List<SelectedGateType> availableGates; // List of gates the user can use
  final List<List<Complex>> solutionFinalVector;

  const QQLevel({
    required this.type,
    required this.taskDescription,
    required this.numQubits,
    required this.initialQubitsStateStr,
    required this.initialQubitsState,
    required this.availableGates,
    required this.solutionFinalVector,
    this.preInsertedGates,
  });

  // Factory constructor to create a QQLevel from a binary string initial state
  factory QQLevel.fromBinaryString({
    required String type,
    required String taskDescription,
    required int numQubits,
    required String initialQubitsStateString, // Accepts the binary string here
    required List<SelectedGateType> availableGates,
    required List<List<Complex>> solutionFinalVector,
    Function(QuantumCircuit)? preInsertedGates,
  }) {
    // Determine numQubits from the string length
    final int numQubits = initialQubitsStateString.length;

    // Use your existing binaryStringToInitialStateVector logic
    final List<Complex> convertedInitialState =
    binaryStringToInitialStateVector(initialQubitsStateString, numQubits);

    // Now, call the primary constructor with the converted state and numQubits
    return QQLevel(
      type: type,
      taskDescription: taskDescription,
      numQubits: numQubits,
      initialQubitsStateStr: initialQubitsStateString,
      initialQubitsState: convertedInitialState,
      availableGates: availableGates,
      solutionFinalVector: solutionFinalVector,
      preInsertedGates: preInsertedGates,
    );
  }

  void preInsertGates(QuantumCircuit quantumCircuit) {
    if (preInsertedGates != null) {
      Function(QuantumCircuit) body = preInsertedGates!;
      body(quantumCircuit);
    }
  }

  // Optional: A helper to get the initial state for N qubits initialized to |0...0>
  // You might want to move this into a utility class if it's used broadly.
  static List<Complex> getZeroStateVector(int numQubits) {
    if (numQubits <= 0) {
      throw ArgumentError('Number of qubits must be positive.');
    }
    final int dim = 1 << numQubits; // 2^numQubits
    final List<Complex> zeroState = List.filled(dim, Complex.zero());
    zeroState[0] = Complex.one(); // |00...0> state
    return zeroState;
  }

  // Static helper to get the state vector for N qubits initialized to |1...1>
  static List<Complex> getOneStateVector(int numQubits) {
    if (numQubits <= 0) {
      throw ArgumentError('Number of qubits must be positive.');
    }
    final int dim = 1 << numQubits; // 2^numQubits
    final List<Complex> oneState = List.filled(dim, Complex.zero());
    oneState[dim - 1] = Complex.one(); // |11...1> state is at the last index (dim - 1)
    return oneState;
  }

// You might also add a method to load solution from JSON/file if needed
}