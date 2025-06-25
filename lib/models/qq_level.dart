// lib/models/level.dart

import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/selected_gate_type.dart'; // Your enum for gate types

class QQLevel {
  final int id;
  final String type;
  final String taskDescription;
  final int numQubits;
  final List<Complex> initialQubitsState; // Assuming this is a state vector (e.g., |00..0>)
  final List<SelectedGateType> availableGates; // List of gates the user can use
  final List<List<Complex>> solutionFinalVector; // The target state vector

  const QQLevel({
    required this.id,
    required this.type,
    required this.taskDescription,
    required this.numQubits,
    required this.initialQubitsState,
    required this.availableGates,
    required this.solutionFinalVector,
  });

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

// You might also add a method to load solution from JSON/file if needed
}