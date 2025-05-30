import 'package:advance_math/advance_math.dart';

abstract class QuantumGate {
  int getNumberOfQubits(); // For multi-qubit gates
}

// Define the Hadamard Gate
class HadamardGate implements QuantumGate {
  final int targetQubit; // 0 or 1 for a 2-qubit system
  HadamardGate(this.targetQubit);

  @override
  int getNumberOfQubits() => 2; // This gate acts on the 2-qubit system state
}

// Define the CNOT Gate
class CNOTGate implements QuantumGate {
  final int controlQubit;
  final int targetQubit;

  CNOTGate(this.controlQubit, this.targetQubit);

  @override
  int getNumberOfQubits() => 2;
}
