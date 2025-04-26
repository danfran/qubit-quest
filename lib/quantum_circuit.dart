import 'package:quantumquiz/quantum_gate.dart';
import 'package:quantumquiz/qubit_state.dart';

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
    currentState = QubitState(); // Reset to initial state
    for (var gate in gates) {
      currentState.applyGate(gate.getMatrix());
    }
  }
}