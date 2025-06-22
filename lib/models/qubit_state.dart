import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';

class QubitState {
  // The list of complex amplitudes representing the state vector
  QuantumMatrix state;
  final int numQubits; // Store the number of qubits this state corresponds to

  // Private constructor
  QubitState._(this.state, this.numQubits);

  // ** Static factory method or constructor to create the initial state **
  factory QubitState.initial(int numQubits) {
    final int size = 1 << numQubits;
    // Set the amplitude for the |00...0> state (index 0) to 1.0 + 0.0i
    List<Complex> initialStateVector = List.generate(1, (_) => Complex.one());
    List<List<Complex>> initialStateMatrix = List.generate(1, (_) => initialStateVector);
    for (int i = 1; i < size; i++) {
      initialStateMatrix.add(List.generate(1, (_) => Complex.zero()));
    }

    return QubitState._(QuantumMatrix(initialStateMatrix), numQubits);
  }

  QubitState applyMatrix(QuantumMatrix matrix) {
    // Implement matrix-vector multiplication: matrix * this.state
    // This involves iterating through the rows of the matrix
    // and calculating the dot product with the state vector.
    // The result is a new state vector.
    QuantumMatrix finalState = matrix.dot(state);

    // Return a new QubitState object with the updated state vector
    return QubitState._(finalState, numQubits);
  }

  @override
  String toString() {
    return state.rawMatrix.transpose().toString();
  }
}