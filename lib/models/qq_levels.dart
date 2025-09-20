import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/qq_levels_category.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/qq_level.dart';

Complex get negOne => Complex(-1.0, 0.0); // -1
Complex get negI => Complex(0.0, -1.0); // -i


final List<QQLevel> allQQLevels = [
  // X
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Your first quantum challenge! Apply a gate to transform \( |0\rangle \) to \( |1\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex.zero()], [Complex.one()]], // Target: |1> state
  ),
  // Z
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Let's change now only the phase of \( |1\rangle \) without flipping the bit. Transform \( |1\rangle \) to \( -|1\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "1", // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex.zero()], [negOne]], // Target: |1> state
  ),
  // Y
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Let's change now the phase and flipping the bit from \( |1\rangle \) to \( |0\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "1", // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[negI], [Complex.zero()]], // Target: |1> state
  ),
  // Y
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |0\rangle \), reach \( |1\rangle \) with a phase of \( i \). This state is \( |i\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.z)], // Provide a few to make them think
    solutionFinalVector: [[Complex.zero()], [Complex.i()]], // Target: |i> state (Y|0> = i|1>)
  ),
  // X + Z + X
  QQLevel.fromBinaryString( // 5
    type: "composer",
    taskDescription: r"Starting from \( |0\rangle \), achieve \( -|0\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[negOne], [Complex.zero()]], // Target: -|0> state (e.g., XZX)
  ),
  // H
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Create a superposition! Turn \( |0\rangle \) into \( |+\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(sqrt1_2)]], // Target: |+> state
  ),
  // H + T
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"You're at \( |0\rangle \). Apply gates to reach a state where the \( |1\rangle \) amplitude has a phase of \( e^{i\pi/4} \). This is \( (|0\rangle + e^{i\pi/4}|1\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.t), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0.5, 0.5)]], // Target: |+> state
  ),
  // H + S
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Transform the initial state of the qubit from \( |0\rangle \) to the target state \( |+i\rangle = (|0\rangle + |i\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0, sqrt1_2)]], // Target: |+> state
  ),
  // H + Z
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Transform \( |+\rangle \) to \( |-\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0", // Requires creating |+> first
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.x)],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(-sqrt1_2, 0)]], // Target: |-> state (H then Z)
  ),
  // H(1) + X(0)
  QQLevel.fromBinaryString( // 10
    type: "composer",
    taskDescription: r"From \( |00\rangle \), create the product state \( |+\rangle \otimes |1\rangle = (|01\rangle + |11\rangle)/\sqrt{2} \).",
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
    ], // Target: (1/sqrt(2))|01> + (1/sqrt(2))|11> (Solution: H on Q0, X on Q1, CNOT(0,1))
  ),
  // H + S + Z
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |+\rangle \), achieve \( |-i\rangle = (|0\rangle - i|1\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0", // Requires H and ZS or YS or something
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(0, -sqrt1_2)]], // Target: |-i> state (e.g., HZ then S)
  ),
  // (H + S + Z) + S + H + X
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"You're at \( (|0\rangle - i|1\rangle) \)/\sqrt{2}. Transform this state back to \( |1\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0", // User must reach the initial state first, then transform.
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex.zero()], [Complex.one()]], // Target: |1> state (e.g., first create initial state with H S Z, then apply S H X)
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0, isDeletable: false);
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.s), 1, 0, isDeletable: false);
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 2, 0, isDeletable: false);
    },
  ),
  // H + S + T + Z
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |0\rangle \), reach \( (|0\rangle + e^{-i\pi/4}|1\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.t), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(0.5, -0.5)]], // Target: HZ T |0> (HT then Z) or (H then T.conjugate())
  ),
  // CX(0,1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |10\rangle \), create a circuit where Qubit 1 will 'mirror' the state of Qubit 0. The final state should be \( |11\rangle \).",
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ], // Target: |00>
  ),
  // CX(1,0)
  QQLevel.fromBinaryString( // 15
    type: "composer",
    taskDescription: r"Transform \( |01\rangle \) to \( |11\rangle \).",
    numQubits: 2,
    initialQubitsStateString: "01",
    availableGates: [Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()], // |11>
      [Complex.one()],
    ], // Target: |11> (CNOT_10 |01> = |11>)
  ),
  // CX (0,2)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Explore 3 qubits! Transform \( |101\rangle \) to \( |100\rangle \).", // Based on your previous 8x8 matrix
    numQubits: 3,
    initialQubitsStateString: "101", // |000> state
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [ // CNOT(Q0, Q2) applied to |000> results in |000>
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.zero()],
      [Complex.one()], [Complex.zero()], [Complex.zero()], [Complex.zero()],
    ],
  ),
  // CX(0,1) + X(0)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |11\rangle \), transform the state to \( |00\rangle \).",
    numQubits: 2,
    initialQubitsStateString: "11",
    availableGates: [Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.x),  Gate.fromIdentifier(SelectedGateType.z),  Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |01>
  ),
  // CCX (1,0,2)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Turn \( |101\rangle \) into \( |111\rangle \).", // Based on your previous 8x8 matrix
    numQubits: 3,
    initialQubitsStateString: "101", // |000> state
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.ccnot), Gate.fromIdentifier(SelectedGateType.z),],
    solutionFinalVector: [
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.zero()],
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.one()],
    ],
  ),
  // CCX(0,1,2)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |011\rangle \), transform the state to \( |111\rangle \).",
    numQubits: 3,
    initialQubitsStateString: "011",
    availableGates: [Gate.fromIdentifier(SelectedGateType.ccnot), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ], // Target: |111>
    // Solution (for your internal reference):
    // Apply CCNOT with Qubit 1 as Control 1, Qubit 2 as Control 2, and Qubit 0 as Target.
    // |011> --(CCNOT_{1,2;0})--> |111>
  ),
  // (CCNOT(0,1,2)) + CCNOT(0,1,2)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"You are given a 3-qubit circuit already in the state \( |111\rangle \). Transform this state back to \( |110\rangle \).",
    numQubits: 3,
    initialQubitsStateString: "110", // Base for pre-inserted gates
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertTriplePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ccnot), 0, 0, 1, 2, isDeletable: false);
    },
    availableGates: [Gate.fromIdentifier(SelectedGateType.ccnot), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
      [Complex.zero()],
    ], // Target: |110> (Solution: Apply CCNOT again)
  ),
  // X(2) + CCNOT(0,1,2)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |010\rangle \), transform the state to \( |111\rangle \).",
    numQubits: 3,
    initialQubitsStateString: "010",
    availableGates: [Gate.fromIdentifier(SelectedGateType.ccnot), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ], // Target: |111> (1 AND 1 = 1, stored on Q2)
  ),
  // H + CX
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Entangle two qubits! Create the Bell state \( |00\rangle + |11\rangle\).",
    numQubits: 2,
    initialQubitsStateString: "00", // |00> state
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [
      [Complex(sqrt1_2)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(sqrt1_2)],
    ], // Target: (|00> + |11>)/sqrt(2)
  ),
  // H + CX
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |01\rangle \), create the Bell state \( |\Psi^+\rangle = (|01\rangle + |10\rangle)/\sqrt{2} \).",
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.x)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
      [Complex(sqrt1_2, 0)],
      [Complex.zero()],
    ], // Target: (1/sqrt(2))|01> + (1/sqrt(2))|10>
  ),
  // (H + CX) + H + CX
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Time for disentangling Bell State. Can you reverse the process to get back to \( |00\rangle \)?",
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.cnot)],
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0, isDeletable: false);
      circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0, isDeletable: false);
    },
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |00>
  ),
  // H + CX + Z(1)
  QQLevel.fromBinaryString( // 25
    type: "composer",
    taskDescription: r"From \( |10\rangle \), create the Bell state \( |\Psi^-\rangle = (|01\rangle - |10\rangle)/\sqrt{2} \).",
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
      [Complex(-sqrt1_2, 0)],
      [Complex.zero()],
    ], // Target: (1/sqrt(2))|01> - (1/sqrt(2))|10> (Solution: H on Q0, CNOT(0,1), Z on Q0)
  ),
  // H + CX + Z(0) (or Z(1)). It can have 2 solution potentially, with Z(0) + Z(1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |00\rangle \), prepare the Bell state \( |\Phi^-\rangle = (|00\rangle - |11\rangle)/\sqrt{2} \). You need only one solution although it can have 2 solutions potenially, due to entanglement.",
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.t)], // Wide range of gates
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(-sqrt1_2, 0)],
    ], // Target: (1/sqrt(2))|00> - (1/sqrt(2))|11>
  ),
  // (H + CX + Z) + Z + CX + H
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"This circuit is pre-configured. Your task is to transform this state back to \( |00\rangle \).",
    numQubits: 2,
    initialQubitsStateString: "00", // The simulation starts from |00>
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0, isDeletable: false);
      circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0, isDeletable: false);
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 2, 0, isDeletable: false);
    },
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.x)],
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |00> (Solution: Z on Q0, CNOT(0,1), H on Q0 to reverse)
  ),
  // CX(0,1) +  CX(1,0)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |10\rangle \), swap the states of the two qubits to achieve \( |01\rangle \). This can be done using only CX gates.",
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [Gate.fromIdentifier(SelectedGateType.cnot)], // Only CNOTs
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |01> (Solution: CNOT(0,1), CNOT(1,0), CNOT(0,1))
  ),
  // H(1) + CX(0,1) + H(1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |00\rangle \), flip the phase of \( |11\rangle \).",
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [
      [Complex(0.5, 0)],           // Amplitude for |00>
      [Complex(0.5, 0)],           // Amplitude for |01>
      [Complex(0.5, 0)],           // Amplitude for |10>
      [Complex(-0.5, 0)],          // Amplitude for |11> (phase flipped)
    ], // Target: (1/2)(|00> + |01> + |10> - |11>)
  ),
  // H(0) + X(1) + CX(0,1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |00\rangle \), create the Bell state \( |\Psi^+\rangle = (|01\rangle + |10\rangle)/\sqrt{2} \).",
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.cnot)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
      [Complex(sqrt1_2, 0)],
      [Complex.zero()],
    ], // Target: (1/sqrt(2))|01> + (1/sqrt(2))|10> (Psi+ Bell state)
  ),
  // X(1) + H(0) + CX(0,1) + Z(0)
  QQLevel.fromBinaryString( // multiple solutions, for example H(0) + CX(0,1) + H(0) + H(1)
    type: "composer",
    taskDescription: r"From \( |10\rangle \), create the Bell state \( |\Phi^-\rangle = (|00\rangle - |11\rangle)/\sqrt{2} \).",
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(-sqrt1_2, 0)],
    ], // Target: (1/sqrt(2))|00> - (1/sqrt(2))|11>
    // Solution: X on Q0, H on Q0, CNOT(0,1), Z on Q0. Or simpler: H on Q1, CNOT(0,1), Z on Q1, X on Q0
  ),
  // (CNOT(0,1)) + CNOT(1,0) + CNOT(0,1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"This circuit is pre-configured with the first CNOT of a qubit swap. Complete the swap of qubits 0 and 1, so \( |01\rangle \) becomes \( |10\rangle \).",
    numQubits: 2,
    initialQubitsStateString: "01",
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0, isDeletable: false);
    },
    availableGates: [Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
      [Complex.zero()],
    ], // Target: |10> (Solution: CNOT(1,0), CNOT(0,1) after pre-inserted CNOT(0,1))
  ),
  // CNOT(2,0) + CNOT(2,1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |001\rangle \), transform the state to \( |101\rangle \).",
    numQubits: 3,
    initialQubitsStateString: "001",
    availableGates: [Gate.fromIdentifier(SelectedGateType.cnot)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],   // Amplitude for |101>
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |101>
  ),
  // X(0) + CX(0,2)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Transform \( |010\rangle \) to \( |111\rangle \). This requires a careful sequence of gates.",
    numQubits: 3,
    initialQubitsStateString: "010",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.ccnot), Gate.fromIdentifier(SelectedGateType.hadamard)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ], // Target: |111>
  ),
  // X(0)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"This circuit is pre-configured to the GHZ state \( (|000\rangle + |111\rangle)/\sqrt{2} \). Transform this state to \( (|001\rangle + |110\rangle)/\sqrt{2} \).",
    numQubits: 3,
    initialQubitsStateString: "000", // Base for pre-inserted gates
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0, isDeletable: false);
      circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0, isDeletable: false);
      circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 1, isDeletable: false);
    },
    availableGates: [Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
      [Complex.zero()],
    ], // Target: (1/sqrt(2))(|100> + |011>)
    // Solution: X on Q0
  ),
  // H(0) + H(1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |00\rangle \), create a uniform superposition of all possible 2-qubit states: \( (|00\rangle + |01\rangle + |10\rangle + |11\rangle)/2 \).",
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.t), Gate.fromIdentifier(SelectedGateType.s)], // Only Hadamard needed
    solutionFinalVector: [
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
    ], // Target: (1/2)(|00>+|01>+|10>+|11>)
    // Solution (for your internal reference): H on Q0, H on Q1
  ),
  // X(0) + H(0) + CX(0,1) + CX(1,2) + Z(2)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |001\rangle \), transform the state to \( (|000\rangle - |111\rangle)/\sqrt{2} \).",
    numQubits: 3,
    initialQubitsStateString: "001",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.ccnot), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.t)],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],      // Index 0: |000>
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(-sqrt1_2, 0)],     // Index 7: |111>
    ], // Target: (1/sqrt(2))(|000> - |111>)
    // Solution:
    // 1. X on Q0 (to get |000>)
    // 2. H on Q0
    // 3. CNOT (Q0 control, Q1 target)
    // 4. CNOT (Q1 control, Q2 target) - This sequence creates GHZ from |000>
    // 5. Z on Q2 (to apply the minus phase to |111> component)
  ),

  // H(0) + H(1) + CZ(0,1) (or CZ(1,0)) - double solution
  // This level introduces the concept of a Controlled-Z gate's effect,
  // which is key to Quantum Phase Estimation and Shor's algorithm.
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"This is about Conditional Phase Shift (Shor's Principle Hint). From \( |00\rangle \), create a uniform superposition where the \( |11\rangle \) component has its phase flipped to \(-1\). The target state is \( (|00\rangle + |01\rangle + |10\rangle - |11\rangle)/2 \).",
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cz), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.t), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [
      [Complex(0.5, 0)],           // Amplitude for |00>
      [Complex(0.5, 0)],           // Amplitude for |01>
      [Complex(0.5, 0)],           // Amplitude for |10>
      [Complex(-0.5, 0)],          // Amplitude for |11> (phase flipped)
    ], // Target: (1/2)(|00> + |01> + |10> - |11>)
    // Solution:
    // 1. Hadamard (H) on Qubit 0
    // 2. Hadamard (H) on Qubit 1
    //    (At this point, state is 1/2(|00> + |01> + |10> + |11>))
    // 3. Apply the Controlled-Z (CZ) gate.
    //    CZ can be decomposed into: H on Qubit 1, CNOT (Qubit 0 control, Qubit 1 target), H on Qubit 1.
    //    So, the sequence would be: H_0, H_1, H_1, CNOT_{01}, H_1.
  ),

  // (H(0) + H(1) + CZ(0,1)) + CZ(0,1) + H(0) + H(1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"This circuit is pre-configured to an entangled state where the \( |11\rangle \) component has a negative phase. Your task is to transform this state back to \( |00\rangle \).",
    numQubits: 2,
    initialQubitsStateString: "00", // Base for pre-inserted gates
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0, isDeletable: false);
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 1, 1, isDeletable: false);
      circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cz), 2, 1, 0, isDeletable: false);
    },
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.cz)], // Provide gates for reversal
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |00>
    // Solution (for your internal reference):
    // Apply the same CZ decomposition sequence again (H_1, CNOT_01, H_1)
    // Then apply H_0, H_1 to return to |00>
    // Total solution: H_1, CNOT_01, H_1, H_0, H_1 (5 gates)
  ),

  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Transform the initial state \( |0\rangle \) to the 'plus' state \( |+\rangle \). This can be achieved with a single rotation gate.",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2)],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(0, -sqrt1_2)],
    ], // Target: |+>
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Rotate the initial state \( |0\rangle \) to a new state on the equatorial plane of the Bloch sphere. Try to find the correct rotation.",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4), Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2)],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(sqrt1_2, 0)],
    ], // Target: (1/sqrt(2))(|0> + i|1>)
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Apply a phase shift to the state \( |1\rangle \) to transform it to \( |i\rangle \). This requires an Rz gate.",
    numQubits: 1,
    initialQubitsStateString: "1",
    availableGates: [Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), Gate.fromIdentifier(SelectedGateType.ry)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, sqrt1_2)],
    ], // Target: |i>
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"You start with a pre-configured superposition. Use a rotation gate to return to the \( |0\rangle \) state.",
    numQubits: 1,
    initialQubitsStateString: "0",
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2), 0, 0, isDeletable: false);
    },
    availableGates: [Gate.fromIdentifier(SelectedGateType.ry, angle: -math.pi / 2), Gate.fromIdentifier(SelectedGateType.hadamard)],
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
    ], // Target: |0>
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Combine two different rotation gates to get a specific final state. The first rotation is given.",
    numQubits: 1,
    initialQubitsStateString: "0",
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), 0, 0, isDeletable: false);
    },
    availableGates: [Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2), Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 4), Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 8)],
    solutionFinalVector: [
      [Complex(0.5, 0.5)],
      [Complex(0.5, -0.5)],
    ], // Target: a state on the Bloch sphere
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Use a rotation gate to apply a very specific phase shift on a multi-qubit state. The initial state is a superposition.",
    numQubits: 2,
    initialQubitsStateString: "00",
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0, isDeletable: false);
      circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0, isDeletable: false);
    },
    availableGates: [Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 4), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.x)],
    solutionFinalVector: [
      [Complex(sqrt1_2 * math.cos(math.pi / 8), -sqrt1_2 * math.sin(math.pi / 8))],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(sqrt1_2 * math.cos(math.pi / 8), sqrt1_2 * math.sin(math.pi / 8))],
    ], // Target: (1/sqrt(2))|00> + (e^(i*pi/4)/sqrt(2))|11>
  ),
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Transform the initial state to a specific point on the Bloch sphere. This requires precise rotations.",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 8), Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 4), Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2)],
    solutionFinalVector: [
      [Complex(sqrt1_2 * math.cos(math.pi / 8), -sqrt1_2 * math.sin(math.pi / 8))],
      [Complex(sqrt1_2 * math.cos(math.pi / 8), -sqrt1_2 * math.sin(math.pi / 8))],
    ], // Target: a complex superposition
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

QQLevel getComposerAsLevel(numQubits) {
  return QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Experiment with any combination of gates on your chosen number of qubits. Build circuits, visualize the resulting quantum state, and generate the overall unitary operator matrix for your circuit.",
    numQubits: numQubits,
    initialQubitsStateString: "0" * numQubits,
    availableGates: [ // should include full list of gates
      Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.t),
      Gate.fromIdentifier(SelectedGateType.cz), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.ccnot),
    ],
    solutionFinalVector: List.empty(),
  );
}

final List<QQLevelsCategory> groupedLevels = [
  QQLevelsCategory(groupName: 'Basic Gate Operations', from: 0, to: 4),
  QQLevelsCategory(groupName: 'Superposition and Phase Gates', from: 5, to: 12),
  QQLevelsCategory(groupName: 'Controlled Gates', from: 13, to: 20),
  QQLevelsCategory(groupName: 'Entanglement & Disentanglement', from: 21, to: 26),
  QQLevelsCategory(groupName: 'Advanced 2-Qubit Puzzles', from: 27, to: 31),
  QQLevelsCategory(groupName: 'Toffoli Gate Logic', from: 32, to: 34),
  QQLevelsCategory(groupName: 'Advanced Entanglement and Algorithms', from: 35, to: 38),
  QQLevelsCategory(groupName: 'Rotation Gates', from: 39, to: 45),
];