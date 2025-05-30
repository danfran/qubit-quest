import 'package:advance_math/advance_math.dart';

class QubitState {
  // The list of complex amplitudes representing the state vector
  List<Complex> state;
  final int numQubits; // Store the number of qubits this state corresponds to

  // Private constructor
  QubitState._(this.state, this.numQubits);

  // ** Static factory method or constructor to create the initial state **
  static QubitState initial(int numQubits) {
    final int size = 1 << numQubits; // Calculate 2^numQubits
    // Create a list of complex numbers, initialized to zero
    List<Complex> initialStateVector = List.generate(size, (_) => Complex.zero());

    // Set the amplitude for the |00...0> state (index 0) to 1.0 + 0.0i
    initialStateVector[0] = Complex(1.0);

    // Return a new QubitState instance with this initial state vector
    return QubitState._(initialStateVector, numQubits);
  }

  // You'll also need methods like:
  // - applyMatrix(List<List<Complex>> matrix): To multiply the state vector by a matrix
  // - toString(): For displaying the state vector (like you have)
  // - Maybe methods to get probabilities, etc.

  QubitState applyMatrix(List<List<Complex>> matrix) {
    // Implement matrix-vector multiplication: matrix * this.state
    // This involves iterating through the rows of the matrix
    // and calculating the dot product with the state vector.
    // The result is a new state vector.

    if (matrix.length != state.length || matrix.isEmpty || matrix[0].length != state.length) {
      throw ArgumentError("Matrix dimensions do not match state vector size.");
    }

    List<Complex> newStateVector = List.generate(state.length, (_) => Complex.zero());

    for (int i = 0; i < matrix.length; i++) { // Iterate through rows of the matrix
      Complex sum = Complex.zero();
      for (int j = 0; j < matrix[i].length; j++) { // Iterate through elements in the row
        sum += matrix[i][j] * state[j]; // Multiply matrix element by state element and add
      }
      newStateVector[i] = sum; // The result is the new amplitude for state |i>
    }

    // Return a new QubitState object with the updated state vector
    return QubitState._(newStateVector, numQubits);
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