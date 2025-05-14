// Define the abstract base class for quantum gates
import 'dart:math';

import 'package:complex/complex.dart';

abstract class QuantumGate {
  List<List<Complex>> getMatrix();
  int getNumberOfQubits(); // For multi-qubit gates
}

// Define the Hadamard Gate
class HadamardGate implements QuantumGate {
  final int targetQubit; // 0 or 1 for a 2-qubit system
  HadamardGate(this.targetQubit);

  @override
  List<List<Complex>> getMatrix() {
    // Return the 4x4 matrix for Hadamard on the targetQubit
    final h = Complex(1 / sqrt(2));
    final negH = Complex(-1 / sqrt(2));
    final zero = Complex.zero;
    final one = Complex(1.0);

    if (targetQubit == 0) {
      // H tensor I
      return [
        [h, h, zero, zero],
        [h, negH, zero, zero],
        [zero, zero, h, h],
        [zero, zero, h, negH],
      ];
    } else if (targetQubit == 1) {
      // I tensor H
      return [
        [h, zero, h, zero],
        [zero, h, zero, h],
        [h, zero, negH, zero],
        [zero, h, zero, negH],
      ];
    } else {
      throw ArgumentError("Target qubit must be 0 or 1 for a 2-qubit gate.");
    }
  }

  @override
  int getNumberOfQubits() => 2; // This gate acts on the 2-qubit system state
}

// Define the CNOT Gate
class CNOTGate implements QuantumGate {
  final int controlQubit;
  final int targetQubit;

  CNOTGate(this.controlQubit, this.targetQubit);

  @override
  List<List<Complex>> getMatrix() {
    final zero = Complex.zero;
    final one = Complex(1.0);

    if (controlQubit == 0 && targetQubit == 1) {
      // CNOT with control on qubit 0, target on qubit 1
      return [
        [one, zero, zero, zero],
        [zero, one, zero, zero],
        [zero, zero, zero, one],
        [zero, zero, one, zero],
      ];
    } else if (controlQubit == 1 && targetQubit == 0) {
      // CNOT with control on qubit 1, target on qubit 0
      return [
        [one, zero, zero, zero],
        [zero, zero, zero, one],
        [zero, zero, one, zero],
        [zero, one, zero, zero],
      ];
    } else {
      throw ArgumentError("Invalid control and target qubit for CNOT (must be 0 and 1).");
    }
  }

  @override
  int getNumberOfQubits() => 2;
}
