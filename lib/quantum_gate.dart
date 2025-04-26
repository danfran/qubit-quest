import 'package:complex/complex.dart';

abstract class QuantumGate {
  List<List<Complex>> getMatrix();
  int getNumberOfQubits(); // For multi-qubit gates
}

class HadamardGate implements QuantumGate {
  final int targetQubit; // 0 or 1 for a 2-qubit system

  HadamardGate(this.targetQubit);

  @override
  List<List<Complex>> getMatrix() {
    // Return the 4x4 matrix for Hadamard on the targetQubit
    // This requires constructing the matrix based on the targetQubit
    // For H on qubit 0: H tensor I
    // For H on qubit 1: I tensor H
    // ... (matrix construction logic)
    return []; // Placeholder
  }

  @override
  int getNumberOfQubits() => 2; // This gate acts on the 2-qubit system state
}

// Define CNOTGate, PauliXGate, etc.