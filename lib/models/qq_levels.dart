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
  ComposerLevel.fromBinaryString(
    taskDescription: r"Your first quantum challenge! Apply a gate to transform \( |0\rangle \) to \( |1\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex.zero()], [Complex.one()]], // Target: |1> state
  ),
  // Z
  ComposerLevel.fromBinaryString(
    taskDescription: r"Let's change now only the phase of \( |1\rangle \) without flipping the bit. Transform \( |1\rangle \) to \( -|1\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "1", // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex.zero()], [negOne]], // Target: |1> state
  ),
  // Y
  ComposerLevel.fromBinaryString(
    taskDescription: r"Let's change now the phase and flipping the bit from \( |1\rangle \) to \( |0\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "1", // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[negI], [Complex.zero()]], // Target: |1> state
  ),
  // Y
  ComposerLevel.fromBinaryString(
    taskDescription: r"From \( |0\rangle \), reach \( |1\rangle \) with a phase of \( i \). This state is \( |i\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.z)], // Provide a few to make them think
    solutionFinalVector: [[Complex.zero()], [Complex.i()]], // Target: |i> state (Y|0> = i|1>)
  ),
  // X + Z + X
  ComposerLevel.fromBinaryString( // 5
    taskDescription: r"Starting from \( |0\rangle \), achieve \( -|0\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[negOne], [Complex.zero()]], // Target: -|0> state (e.g., XZX)
  ),
  // H
  ComposerLevel.fromBinaryString(
    taskDescription: r"Create a superposition! Turn \( |0\rangle \) into \( |+\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(sqrt1_2)]], // Target: |+> state
  ),
  // H + T
  ComposerLevel.fromBinaryString(
    taskDescription: r"You're at \( |0\rangle \). Apply gates to reach a state where the \( |1\rangle \) amplitude has a phase of \( e^{i\pi/4} \). This is \( (|0\rangle + e^{i\pi/4}|1\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.t), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0.5, 0.5)]], // Target: |+> state
  ),
  // H + S
  ComposerLevel.fromBinaryString(
    taskDescription: r"Transform the initial state of the qubit from \( |0\rangle \) to the target state \( |+i\rangle = (|0\rangle + |i\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0, sqrt1_2)]], // Target: |+> state
  ),
  // H + Z
  ComposerLevel.fromBinaryString(
    taskDescription: r"Transform \( |+\rangle \) to \( |-\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0", // Requires creating |+> first
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.x)],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(-sqrt1_2, 0)]], // Target: |-> state (H then Z)
  ),
  // H(1) + X(0)
  ComposerLevel.fromBinaryString( // 10
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
  ComposerLevel.fromBinaryString(
    taskDescription: r"From \( |+\rangle \), achieve \( |-i\rangle = (|0\rangle - i|1\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0", // Requires H and ZS or YS or something
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(0, -sqrt1_2)]], // Target: |-i> state (e.g., HZ then S)
  ),
  // (H + S + Z) + S + H + X
  ComposerLevel.fromBinaryString(
    taskDescription: r"You're at \( (|0\rangle - i|1\rangle)/\sqrt{2} \). Transform this state back to \( |1\rangle \).",
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
  ComposerLevel.fromBinaryString(
    taskDescription: r"From \( |0\rangle \), reach \( (|0\rangle + e^{-i\pi/4}|1\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.t), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(0.5, -0.5)]], // Target: HZ T |0> (HT then Z) or (H then T.conjugate())
  ),
  // CX(0,1)
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString( // 15
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString( // LEVEL 20
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString( // 25
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString( // multiple solutions, for example H(0) + CX(0,1) + H(0) + H(1)
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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

  ComposerLevel.fromBinaryString(
    taskDescription: r"Transform the initial state \( |0\rangle \) to the 'plus' state \( |+\rangle \). This can be achieved with a single rotation gate.",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2)],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(0, -sqrt1_2)],
    ], // Target: |+>
  ),
  ComposerLevel.fromBinaryString(
    taskDescription: r"Rotate the initial state \( |0\rangle \) to a new state on the equatorial plane of the Bloch sphere. Try to find the correct rotation.",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4), Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2)],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(sqrt1_2, 0)],
    ], // Target: (1/sqrt(2))(|0> + i|1>)
  ),
  ComposerLevel.fromBinaryString(
    taskDescription: r"Apply a phase shift to the state \( |1\rangle \) to transform it to \( |i\rangle \). This requires an Rz gate.",
    numQubits: 1,
    initialQubitsStateString: "1",
    availableGates: [Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), Gate.fromIdentifier(SelectedGateType.ry)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, sqrt1_2)],
    ], // Target: |i>
  ),
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
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
  ComposerLevel.fromBinaryString(
    taskDescription: r"Transform the initial state to a specific point on the Bloch sphere. This requires precise rotations.",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 8), Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 4), Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2)],
    solutionFinalVector: [
      [Complex(sqrt1_2 * math.cos(math.pi / 8), -sqrt1_2 * math.sin(math.pi / 8))],
      [Complex(sqrt1_2 * math.cos(math.pi / 8), -sqrt1_2 * math.sin(math.pi / 8))],
    ], // Target: a complex superposition
  ),

  // ── Concept Checks (MCQ) ──────────────────────────────────────────────────
  // Index 46 — Level 47
  McqLevel(
    title: 'What is Superposition?',
    taskDescription: 'A qubit in superposition is...',
    conceptIntro: 'You have applied the Hadamard gate many times. Let\'s check the concept behind it.',
    options: [
      'Always |0⟩ when measured',
      'In both |0⟩ and |1⟩ simultaneously — collapsing to one upon measurement with some probability',
      'A qubit permanently stuck between two classical values',
      'The same as a classical bit that is randomly 0 or 1',
    ],
    correctOptionIndex: 1,
    solutionExplanation:
        'Superposition means the qubit has a probability amplitude for each basis state. '
        'The Born rule says the probability of each outcome equals the squared magnitude of its amplitude. '
        'Only measurement collapses the superposition.',
  ),

  // Index 47 — Level 48
  McqLevel(
    title: 'What is Entanglement?',
    taskDescription: 'Two qubits are entangled when...',
    conceptIntro: 'You have created and disentangled Bell states. What makes entanglement special?',
    options: [
      'Both qubits are in state |0⟩',
      'They are physically close to each other',
      'Their joint state cannot be written as a product of two individual qubit states',
      'One qubit controls the other via a wire',
    ],
    correctOptionIndex: 2,
    solutionExplanation:
        'Entanglement is a purely quantum correlation. For the Bell state (|00⟩+|11⟩)/√2, '
        'there is no way to write it as (a|0⟩+b|1⟩)⊗(c|0⟩+d|1⟩). '
        'Measuring one qubit instantly tells you the state of the other.',
  ),

  // ── Measurement Lab ───────────────────────────────────────────────────────
  // Index 48 — Level 49
  MeasurementLabLevel(
    title: 'Measure |+⟩',
    taskDescription:
        r'This qubit is prepared in the superposition state \( |+\rangle = (|0\rangle + |1\rangle)/\sqrt{2} \). '
        r'Press Measure at least 20 times and watch the outcome distribution.',
    conceptIntro:
        'Each measurement randomly collapses the superposition. '
        'After many repetitions the histogram converges to the true probabilities — this is the Born rule.',
    numQubits: 1,
    initialQubitsStateString: '0',
    preBuiltCircuit: (circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
    },
    requiredMeasurements: 20,
    solutionExplanation:
        'You should see roughly 50 % |0⟩ and 50 % |1⟩. '
        'The H gate gives both amplitudes equal magnitude 1/√2, so |amplitude|² = 0.5 for each.',
  ),

  // Index 49 — Level 50
  MeasurementLabLevel(
    title: 'Measure Bell State',
    taskDescription:
        r'This 2-qubit circuit is prepared in the Bell state \( |\Phi^+\rangle = (|00\rangle + |11\rangle)/\sqrt{2} \). '
        r'Press Measure at least 20 times. Notice that you only ever see |00⟩ or |11⟩ — never |01⟩ or |10⟩.',
    conceptIntro:
        'Entangled qubits are perfectly correlated. No matter how many times you measure, '
        'the two qubits always agree — both 0 or both 1. This cannot happen with classical random bits.',
    numQubits: 2,
    initialQubitsStateString: '00',
    preBuiltCircuit: (circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0,
          isDeletable: false);
    },
    requiredMeasurements: 20,
    solutionExplanation:
        'The Bell state has zero amplitude for |01⟩ and |10⟩, so you can never measure those. '
        'The two qubits are entangled — their outcomes are always correlated.',
  ),

  // ── Fill the Gate ─────────────────────────────────────────────────────────
  // Index 50 — Level 51
  FillTheGateLevel(
    title: 'Fill: Create |+⟩',
    taskDescription:
        r'The circuit starts at \( |0\rangle \). Which single gate transforms it to the superposition state \( |+\rangle \)?',
    conceptIntro:
        'You know several gates by now. Think about which one splits the amplitude equally between |0⟩ and |1⟩.',
    numQubits: 1,
    initialQubitsStateString: '0',
    preBuiltGates: (circuit) {
      // Nothing before the blank — the blank IS the first (and only) gate
    },
    correctGate: Gate.fromIdentifier(SelectedGateType.hadamard),
    options: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.s),
    ],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(sqrt1_2)]],
    hints: [
      'This gate is named after a French mathematician and creates equal superposition.',
      'It\'s the H (Hadamard) gate.',
    ],
    solutionExplanation:
        'H|0⟩ = (|0⟩+|1⟩)/√2. The Hadamard gate is the canonical "superposition creator" — '
        'it maps every basis state to an equal-weight superposition.',
  ),

  // Index 51 — Level 52
  FillTheGateLevel(
    title: 'Fill: Flip the Bit',
    taskDescription:
        r'The circuit starts at \( |1\rangle \). Which gate transforms it back to \( |0\rangle \)?',
    conceptIntro:
        'Some gates simply swap |0⟩ and |1⟩, just like a classical NOT gate.',
    numQubits: 1,
    initialQubitsStateString: '1',
    preBuiltGates: (circuit) {
      // blank is the only gate
    },
    correctGate: Gate.fromIdentifier(SelectedGateType.x),
    options: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.y),
    ],
    solutionFinalVector: [[Complex.one()], [Complex.zero()]],
    hints: [
      'This gate is the quantum equivalent of a classical NOT gate.',
      'It\'s the X (Pauli-X) gate.',
    ],
    solutionExplanation:
        'X|1⟩ = |0⟩. The Pauli-X gate flips the qubit just like a classical NOT. '
        'It\'s one of the most fundamental single-qubit gates.',
  ),

  // ── Circuit Reading ───────────────────────────────────────────────────────
  // Index 52 — Level 53
  CircuitReadingLevel(
    title: 'Read: H Gate',
    taskDescription:
        r'The circuit below applies a single H gate to \( |0\rangle \). What is the output state?',
    conceptIntro:
        'Reading circuits is just as important as building them. '
        'Trace through each gate from left to right to find the final state.',
    numQubits: 1,
    initialQubitsStateString: '0',
    circuit: (circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
    },
    options: [
      r'\( |0\rangle \)',
      r'\( |1\rangle \)',
      r'\( |+\rangle = (|0\rangle + |1\rangle)/\sqrt{2} \)',
      r'\( |-\rangle = (|0\rangle - |1\rangle)/\sqrt{2} \)',
    ],
    correctOptionIndex: 2,
    solutionExplanation:
        'H|0⟩ = (|0⟩+|1⟩)/√2 = |+⟩. The Hadamard maps |0⟩ to the "plus" state '
        'and |1⟩ to the "minus" state.',
  ),

  // Index 53 — Level 54
  CircuitReadingLevel(
    title: 'Read: Bell State',
    taskDescription:
        r'The circuit applies H to qubit 0, then CNOT(0→1), starting from \( |00\rangle \). What is the output?',
    numQubits: 2,
    initialQubitsStateString: '00',
    circuit: (circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0,
          isDeletable: false);
    },
    options: [
      r'\( |00\rangle \)',
      r'\( (|00\rangle + |11\rangle)/\sqrt{2} \)',
      r'\( (|01\rangle + |10\rangle)/\sqrt{2} \)',
      r'\( |11\rangle \)',
    ],
    correctOptionIndex: 1,
    hints: [
      'After H on Q0 the state is (|00⟩+|10⟩)/√2. What does CNOT do to each term?',
      'CNOT flips Q1 only when Q0=1. So |10⟩ → |11⟩ and |00⟩ → |00⟩.',
    ],
    solutionExplanation:
        'H creates superposition on Q0 giving (|00⟩+|10⟩)/√2. '
        'CNOT(0→1) then flips Q1 when Q0=1, producing (|00⟩+|11⟩)/√2 — the Bell state Φ⁺.',
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

ComposerLevel getComposerAsLevel(int numQubits) {
  return ComposerLevel.fromBinaryString(
    taskDescription: r"Experiment with any combination of gates on your chosen number of qubits. Build circuits, visualize the resulting quantum state, and generate the overall unitary operator matrix for your circuit.",
    numQubits: numQubits,
    initialQubitsStateString: "0" * numQubits,
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.t),
      Gate.fromIdentifier(SelectedGateType.cz), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.ccnot),
      Gate.fromIdentifier(SelectedGateType.rx), Gate.fromIdentifier(SelectedGateType.ry), Gate.fromIdentifier(SelectedGateType.rz),
    ],
    solutionFinalVector: List.empty(),
  );
}

final List<QQLevelsCategory> groupedLevels = [
  QQLevelsCategory(
    groupName: 'Basic Gate Operations',
    from: 0, to: 4,
    categoryIntro:
        'Quantum gates are reversible operations that transform qubit states. '
        'Unlike classical logic gates, every quantum gate has an inverse — '
        'applying the same gate twice returns to the original state.',
  ),
  QQLevelsCategory(
    groupName: 'Superposition and Phase Gates',
    from: 5, to: 12,
    categoryIntro:
        'The Hadamard gate puts a qubit in superposition — existing as both |0⟩ and |1⟩ '
        'simultaneously until measured. Phase gates (S, T) rotate the |1⟩ amplitude on the '
        'complex unit circle, changing the "angle" of the state without affecting measurement probabilities.',
  ),
  QQLevelsCategory(
    groupName: 'Controlled Gates',
    from: 13, to: 20,
    categoryIntro:
        'Controlled gates apply an operation to a target qubit only when a control qubit is |1⟩. '
        'The CNOT (Controlled-NOT) is the most important two-qubit gate and is universal '
        'for quantum computing when combined with single-qubit gates.',
  ),
  QQLevelsCategory(
    groupName: 'Entanglement & Disentanglement',
    from: 21, to: 26,
    categoryIntro:
        'Entanglement is a uniquely quantum correlation where the state of two qubits '
        'cannot be described independently. Bell states are the simplest maximally-entangled states. '
        'Measuring one qubit of an entangled pair instantly determines the other.',
  ),
  QQLevelsCategory(
    groupName: 'Advanced 2-Qubit Puzzles',
    from: 27, to: 31,
    categoryIntro:
        'These puzzles combine multiple two-qubit operations. '
        'Pay attention to which qubit is the control and which is the target — '
        'the order matters.',
  ),
  QQLevelsCategory(
    groupName: 'Toffoli Gate Logic',
    from: 32, to: 34,
    categoryIntro:
        'The Toffoli gate (CCX) has two control qubits: it flips the target only when BOTH '
        'controls are |1⟩. This makes it a quantum AND gate and means it can simulate '
        'any classical reversible computation.',
  ),
  QQLevelsCategory(
    groupName: 'Advanced Entanglement and Algorithms',
    from: 35, to: 38,
    categoryIntro:
        'These levels build circuits that are stepping stones to real quantum algorithms. '
        'The GHZ state, conditional phase shifts, and multi-qubit entanglement all appear '
        'in Shor\'s algorithm, Grover\'s search, and quantum teleportation.',
  ),
  QQLevelsCategory(
    groupName: 'Rotation Gates',
    from: 39, to: 45,
    categoryIntro:
        'Rx, Ry, and Rz rotate a qubit by an angle on the Bloch sphere around each axis. '
        'Any single-qubit gate can be expressed as a combination of rotations. '
        'These gates are essential for variational quantum algorithms.',
  ),
  QQLevelsCategory(
    groupName: 'Concept Checks',
    from: 46, to: 47,
    categoryIntro:
        'Quick questions to consolidate the key ideas you have encountered. '
        'No circuits — just concepts.',
  ),
  QQLevelsCategory(
    groupName: 'Measurement Labs',
    from: 48, to: 49,
    categoryIntro:
        'Quantum measurement is probabilistic. Press Measure repeatedly and watch '
        'the outcome distribution converge — this is the Born rule in action.',
  ),
  QQLevelsCategory(
    groupName: 'Fill the Gate',
    from: 50, to: 51,
    categoryIntro:
        'A circuit is shown with one gate missing. Choose the correct gate to complete it. '
        'This tests your ability to reason about gate effects without building from scratch.',
  ),
  QQLevelsCategory(
    groupName: 'Circuit Reading',
    from: 52, to: 53,
    categoryIntro:
        'Read a pre-built circuit and identify its output state. '
        'Being able to analyse circuits is as important as building them.',
  ),
];