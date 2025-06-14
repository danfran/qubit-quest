import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/quantum_matrix.dart';

class QubitState {
  // The list of complex amplitudes representing the state vector
  List<Complex> state;
  final int numQubits; // Store the number of qubits this state corresponds to

  // Private constructor
  QubitState._(this.state, this.numQubits);

  // ** Static factory method or constructor to create the initial state **
  factory QubitState.initial(int numQubits) {
    final int size = 1 << numQubits; // Calculate 2^numQubits
    // Create a list of complex numbers, initialized to zero
    List<Complex> initialStateVector = List.generate(size, (_) => Complex.zero());

    // Set the amplitude for the |00...0> state (index 0) to 1.0 + 0.0i
    initialStateVector[0] = Complex(1.0);

    // Return a new QubitState instance with this initial state vector
    return QubitState._(initialStateVector, numQubits);
  }

  QubitState applyMatrix(QuantumMatrix matrix) {
    // Implement matrix-vector multiplication: matrix * this.state
    // This involves iterating through the rows of the matrix
    // and calculating the dot product with the state vector.
    // The result is a new state vector.
    QuantumMatrix stateMatrix = QuantumMatrix(List.filled(1, state));
    QuantumMatrix finalState = matrix.dot(stateMatrix);

    // Return a new QubitState object with the updated state vector
    return QubitState._(finalState.rows.first.cast(), numQubits);
  }

  @override
  String toString() {
    // Implement formatting the state vector to a string (like your formatStateVector helper)
    String formatted = "[";
    for (int i = 0; i < state.length; i++) {
      String real = state[i].real.toStringAsFixed(2);
      String imag = state[i].imaginary.toStringAsFixed(2);
      String complexStr;
      if (state[i].imaginary == 0) {
        complexStr = real;
      } else if (state[i].real == 0) {
        complexStr = "${imag}i";
      } else if (state[i].imaginary > 0) {
        complexStr = "$real+$imag" + "i";
      } else {
        complexStr = "$real$imag" + "i"; // Imaginary part already has '-'
      }
      formatted += complexStr;
      if (i < state.length - 1) {
        formatted += ", ";
      }
    }
    formatted += "]";
    return formatted;
  }
}