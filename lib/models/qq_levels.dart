import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/selected_gate_type.dart';
import 'package:quantumquiz/models/qq_level.dart';


final List<QQLevel> allQQLevels = [
  QQLevel(
    id: 1,
    taskDescription: "Your first quantum challenge! Apply a gate to transform |0> to |1>.",
    numQubits: 1,
    initialQubitsState: QQLevel.getZeroStateVector(1), // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.y],
    solutionFinalVector: [Complex.zero(), Complex.one()], // Target: |1> state
  ),
  QQLevel(
    id: 2,
    taskDescription: "Create a superposition! Turn |0> into |+>.",
    numQubits: 1,
    initialQubitsState: QQLevel.getZeroStateVector(1), // |0> state
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.z],
    solutionFinalVector: [Complex(1 / sqrt(2)), Complex(1 / sqrt(2))], // Target: |+> state
  ),
  QQLevel(
    id: 3,
    taskDescription: "Entangle two qubits! Create the Bell state |00>+|11>.",
    numQubits: 2,
    initialQubitsState: QQLevel.getZeroStateVector(2), // |00> state
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.cnot, SelectedGateType.z],
    solutionFinalVector: [
      Complex(1 / sqrt(2)),
      Complex.zero(),
      Complex.zero(),
      Complex(1 / sqrt(2)),
    ], // Target: (|00> + |11>)/sqrt(2)
  ),
  QQLevel(
    id: 4,
    taskDescription: "Explore 3 qubits! Apply CNOT(Q0, Q2) to |000>.", // Based on your previous 8x8 matrix
    numQubits: 3,
    initialQubitsState: QQLevel.getZeroStateVector(3), // |000> state
    availableGates: [
      SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.cnot,
      SelectedGateType.z, SelectedGateType.y // Example more gates
    ],
    solutionFinalVector: [ // CNOT(Q0, Q2) applied to |000> results in |000>
      Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(),
      Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(),
    ],
  ),
  // Add more levels here...
];

// Helper to get a level by ID
QQLevel? getQQLevelById(int id) {
  try {
    return allQQLevels.firstWhere((level) => level.id == id);
  } catch (e) {
    print('QQLevel with ID $id not found: $e');
    return null;
  }
}