import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';

class QubitState {
  QuantumMatrix state;
  // The list of complex amplitudes representing the state vector
  List<Complex> stateVector;

  // Private constructor
  QubitState._(this.state):
      stateVector = state.rawMatrix.transpose().first.map((item) => item as Complex).toList();

  QubitState.fromList(this.stateVector):
      state  = QuantumMatrix.transpose([stateVector]);

  QubitState applyMatrix(QuantumMatrix matrix) {
    // Implement matrix-vector multiplication: matrix * this.state
    // This involves iterating through the rows of the matrix
    // and calculating the dot product with the state vector.
    // The result is a new state vector.
    QuantumMatrix finalState = matrix.dot(state);

    // Return a new QubitState object with the updated state vector
    return QubitState._(finalState);
  }

  @override
  String toString() {
    return state.rawMatrix.transpose().toString();
  }
}