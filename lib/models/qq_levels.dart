import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/qq_level.dart';


final List<QQLevel> allQQLevels = [
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: "Your first quantum challenge! Apply a gate to transform |0> to |1>.",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.y],
    solutionFinalVector: [[Complex.zero()], [Complex.one()]], // Target: |1> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: "Good, you made the first step! Let's change now only the phase of |1> without flipping the bit.",
    numQubits: 1,
    initialQubitsStateString: "1", // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [SelectedGateType.z, SelectedGateType.x, SelectedGateType.y],
    solutionFinalVector: [[Complex.zero()], [Complex(-Complex.one().real, -Complex.one().imaginary)]], // Target: |1> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: "Great job! Let's change now the phase and flipping the bit from |1> to |0>.",
    numQubits: 1,
    initialQubitsStateString: "1", // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [SelectedGateType.hadamard, SelectedGateType.x, SelectedGateType.y],
    solutionFinalVector: [[Complex(-Complex.i().real, -Complex.i().imaginary)], [Complex.zero()]], // Target: |1> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: "Create a superposition! Turn |0> into |+>.",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.z],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(sqrt1_2)]], // Target: |+> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: "Transform the initial state of the qubit from ∣0⟩ to the target state ∣+i⟩=2​1​(∣0⟩+i∣1⟩).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.s, SelectedGateType.z],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0, sqrt1_2)]], // Target: |+> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: "You're at ∣0⟩. Your goal is a specific phase that's between the X and Y axes on the sphere. Which gate makes a precise quarter turn?.",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [SelectedGateType.y, SelectedGateType.hadamard, SelectedGateType.t, SelectedGateType.z],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0.5, 0.5)]], // Target: |+> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: "Entangle two qubits! Create the Bell state |00>+|11>.",
    numQubits: 2,
    initialQubitsStateString: "00", // |00> state
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.cnot, SelectedGateType.z],
    solutionFinalVector: [
      [Complex(sqrt1_2)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(sqrt1_2)],
    ], // Target: (|00> + |11>)/sqrt(2)
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: "Explore 3 qubits! Apply CNOT(Q0, Q2) to |101>.", // Based on your previous 8x8 matrix
    numQubits: 3,
    initialQubitsStateString: "101", // |000> state
    availableGates: [
      SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.cnot,
      SelectedGateType.z, SelectedGateType.y // Example more gates
    ],
    solutionFinalVector: [ // CNOT(Q0, Q2) applied to |000> results in |000>
      [Complex.zero()], [Complex.one()], [Complex.zero()], [Complex.zero()],
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.zero()],
    ],
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: "Turn |101> into |111>.", // Based on your previous 8x8 matrix
    numQubits: 3,
    initialQubitsStateString: "101", // |000> state
    availableGates: [
      SelectedGateType.hadamard, SelectedGateType.ccnot,
      SelectedGateType.z, // Example more gates
    ],
    solutionFinalVector: [
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.zero()],
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.one()],
    ],
  ),
  // Add more levels here...
];

int numberOfLevels = allQQLevels.length;

// Helper to get a level by ID
QQLevel? getQQLevelById(int id) {
  try {
    return allQQLevels[id - 1];
  } catch (e) {
    debugPrint('QQLevel with ID $id not found: $e');
    return null;
  }
}