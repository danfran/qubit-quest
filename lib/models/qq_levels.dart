import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/qq_level.dart';


final List<QQLevel> allQQLevels = [
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Your first quantum challenge! Apply a gate to transform \( |0\rangle \) to \( |1\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.y],
    solutionFinalVector: [[Complex.zero()], [Complex.one()]], // Target: |1> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Let's change now only the phase of \( |1\rangle \) without flipping the bit. Transform \( |1\rangle \) to \( -|1\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "1", // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [SelectedGateType.z, SelectedGateType.x, SelectedGateType.y],
    solutionFinalVector: [[Complex.zero()], [Complex(-Complex.one().real, -Complex.one().imaginary)]], // Target: |1> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Let's change now the phase and flipping the bit from \( |1\rangle \) to \( |0\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "1", // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [SelectedGateType.hadamard, SelectedGateType.x, SelectedGateType.y],
    solutionFinalVector: [[Complex(-Complex.i().real, -Complex.i().imaginary)], [Complex.zero()]], // Target: |1> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |0\rangle \), reach \( |1\rangle \) with a phase of \( i \). This state is \( |i\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [SelectedGateType.x, SelectedGateType.y, SelectedGateType.z], // Provide a few to make them think
    solutionFinalVector: [[Complex.zero()], [Complex.i()]], // Target: |i> state (Y|0> = i|1>)
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Create a superposition! Turn \( |0\rangle \) into \( |+\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.z],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(sqrt1_2)]], // Target: |+> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Transform the initial state of the qubit from \( |0\rangle \) to the target state \( |+i\rangle = (|0\rangle + |i\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.s, SelectedGateType.z],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0, sqrt1_2)]], // Target: |+> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"You're at \( |0\rangle \). Apply gates to reach a state where the \( |1\rangle \) amplitude has a phase of \( e^{i\pi/4} \). This is \( (|0\rangle + e^{i\pi/4}|1\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [SelectedGateType.y, SelectedGateType.hadamard, SelectedGateType.t, SelectedGateType.z],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0.5, 0.5)]], // Target: |+> state
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Entangle two qubits! Create the Bell state \( |00\rangle + |11\rangle\).",
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
    taskDescription: r"Explore 3 qubits! Transform \( |101\rangle \) to \( |100\rangle \).", // Based on your previous 8x8 matrix
    numQubits: 3,
    initialQubitsStateString: "101", // |000> state
    availableGates: [SelectedGateType.hadamard, SelectedGateType.cnot, SelectedGateType.z, SelectedGateType.y],
    solutionFinalVector: [ // CNOT(Q0, Q2) applied to |000> results in |000>
      [Complex.zero()], [Complex.one()], [Complex.zero()], [Complex.zero()],
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.zero()],
    ],
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Turn \( |101\rangle \) into \( |111\rangle \).", // Based on your previous 8x8 matrix
    numQubits: 3,
    initialQubitsStateString: "101", // |000> state
    availableGates: [SelectedGateType.hadamard, SelectedGateType.ccnot, SelectedGateType.z,],
    solutionFinalVector: [
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.zero()],
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.one()],
    ],
  ),
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