import 'package:complex/complex.dart';
import 'package:quantumquiz/quantum_gate.dart';
import 'package:quantumquiz/qubit_state.dart';

import 'math_utils.dart';

class QuantumCircuit {
  List<QuantumGate> gates = [];
  QubitState currentState = QubitState();

  void addGate(QuantumGate gate) {
    // Basic validation
    if (gate.getNumberOfQubits() != 2) {
      // Handle error or different number of qubits
      return;
    }
    gates.add(gate);
  }

  void run() {
    currentState = QubitState();
    for (var gate in gates) {
      currentState.applyGate(gate.getMatrix());
    }
  }

  void clearCircuit() {
    gates.clear();
    currentState = QubitState();
  }

  // Method to get the overall unitary matrix for the circuit
  List<List<Complex>> getOverallMatrix() {
    List<List<Complex>> overallMatrix = identityMatrix; // Start with Identity

    // Multiply matrices in the order they are applied (left to right in circuit)
    // Accumulate product: Result = G_i * Result (pre-multiplication)
    for (var gate in gates) {
      overallMatrix = multiplyMatrices(gate.getMatrix(), overallMatrix);
    }

    return overallMatrix;
  }
}
