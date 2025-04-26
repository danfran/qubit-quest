import 'dart:math';

import 'package:complex/complex.dart'; // You might need a complex number library

class QubitState {
  // Represents the state vector for 2 qubits (|00>, |01>, |10>, |11>)
  List<Complex> state;

  QubitState() : state = [Complex(1.0), Complex(0.0), Complex(0.0), Complex(0.0)]; // Initialize to |00>

  // Method to apply a 2-qubit gate (represented by a 4x4 matrix)
  void applyGate(List<List<Complex>> gateMatrix) {
    if (gateMatrix.length != 4 || gateMatrix[0].length != 4) {
      throw ArgumentError("Gate matrix must be 4x4 for 2 qubits.");
    }

    List<Complex> newState = [];
    for (int i = 0; i < 4; i++) {
      Complex sum = Complex.zero;
      for (int j = 0; j < 4; j++) {
        sum += gateMatrix[i][j] * state[j];
      }
      newState.add(sum);
    }
    state = newState;
  }

  @override
  String toString() {
    return state.map((c) => "${c.real.toStringAsFixed(2)} + ${c.imaginary.toStringAsFixed(2)}i").join(", ");
  }
}

// Example Gate (Hadamard on the first qubit, Identity on the second)
// This is a 4x4 matrix representing H tensor I
List<List<Complex>> hGateTwoQubits = [
  [Complex(1 / sqrt(2)), Complex(1 / sqrt(2)), Complex(0), Complex(0)],
  [Complex(1 / sqrt(2)), Complex(-1 / sqrt(2)), Complex(0), Complex(0)],
  [Complex(0), Complex(0), Complex(1 / sqrt(2)), Complex(1 / sqrt(2))],
  [Complex(0), Complex(0), Complex(1 / sqrt(2)), Complex(-1 / sqrt(2))],
];

// Define other gates as needed (e.g., CNOT)