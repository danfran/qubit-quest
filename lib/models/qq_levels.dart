import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
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
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.y],
    solutionFinalVector: [[Complex.zero()], [Complex.one()]], // Target: |1> state
  ),
  // Z
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Let's change now only the phase of \( |1\rangle \) without flipping the bit. Transform \( |1\rangle \) to \( -|1\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "1", // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [SelectedGateType.z, SelectedGateType.x, SelectedGateType.y],
    solutionFinalVector: [[Complex.zero()], [negOne]], // Target: |1> state
  ),
  // Y
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Let's change now the phase and flipping the bit from \( |1\rangle \) to \( |0\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "1", // |0> state: [Complex.one(), Complex.zero()]
    availableGates: [SelectedGateType.hadamard, SelectedGateType.x, SelectedGateType.y],
    solutionFinalVector: [[negI], [Complex.zero()]], // Target: |1> state
  ),
  // Y
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |0\rangle \), reach \( |1\rangle \) with a phase of \( i \). This state is \( |i\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [SelectedGateType.x, SelectedGateType.y, SelectedGateType.z], // Provide a few to make them think
    solutionFinalVector: [[Complex.zero()], [Complex.i()]], // Target: |i> state (Y|0> = i|1>)
  ),
  // X + Z + X
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Starting from \( |0\rangle \), achieve \( -|0\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [SelectedGateType.x, SelectedGateType.z, SelectedGateType.y],
    solutionFinalVector: [[negOne], [Complex.zero()]], // Target: -|0> state (e.g., XZX)
  ),
  // H
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Create a superposition! Turn \( |0\rangle \) into \( |+\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.z],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(sqrt1_2)]], // Target: |+> state
  ),
  // H + T
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"You're at \( |0\rangle \). Apply gates to reach a state where the \( |1\rangle \) amplitude has a phase of \( e^{i\pi/4} \). This is \( (|0\rangle + e^{i\pi/4}|1\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [SelectedGateType.y, SelectedGateType.hadamard, SelectedGateType.t, SelectedGateType.z],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0.5, 0.5)]], // Target: |+> state
  ),
  // H + S
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Transform the initial state of the qubit from \( |0\rangle \) to the target state \( |+i\rangle = (|0\rangle + |i\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0", // |0> state
    availableGates: [SelectedGateType.x, SelectedGateType.hadamard, SelectedGateType.s, SelectedGateType.z],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0, sqrt1_2)]], // Target: |+> state
  ),
  // H + Z
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Transform \( |+\rangle \) to \( |-\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0", // Requires creating |+> first
    availableGates: [SelectedGateType.hadamard, SelectedGateType.z, SelectedGateType.y, SelectedGateType.x],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(-sqrt1_2, 0)]], // Target: |-> state (H then Z)
  ),
  // H(1) + X(0)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |00\rangle \), create the product state \( |+\rangle \otimes |1\rangle = (|01\rangle + |11\rangle)/\sqrt{2} \).",
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [SelectedGateType.hadamard, SelectedGateType.cnot, SelectedGateType.x, SelectedGateType.z],
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
    availableGates: [SelectedGateType.hadamard, SelectedGateType.s, SelectedGateType.z, SelectedGateType.x, SelectedGateType.y],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(0, -sqrt1_2)]], // Target: |-i> state (e.g., HZ then S)
  ),
  // (H + S + Z) + S + H + X
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"You're at \( (|0\rangle - i|1\rangle) \)/\sqrt{2}. Transform this state back to \( |1\rangle \).",
    numQubits: 1,
    initialQubitsStateString: "0", // User must reach the initial state first, then transform.
    availableGates: [SelectedGateType.hadamard, SelectedGateType.s, SelectedGateType.x, SelectedGateType.z, SelectedGateType.y],
    solutionFinalVector: [[Complex.zero()], [Complex.one()]], // Target: |1> state (e.g., first create initial state with H S Z, then apply S H X)
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0, isDeletable: false);
      circuit.insertSinglePlacedGateAt(SelectedGateType.s, 1, 0, isDeletable: false);
      circuit.insertSinglePlacedGateAt(SelectedGateType.z, 2, 0, isDeletable: false);
    },
  ),
  // H + S + T + Z
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |0\rangle \), reach \( (|0\rangle + e^{-i\pi/4}|1\rangle)/\sqrt{2} \).",
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [SelectedGateType.hadamard, SelectedGateType.t, SelectedGateType.s, SelectedGateType.z, SelectedGateType.y],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(0.5, -0.5)]], // Target: HZ T |0> (HT then Z) or (H then T.conjugate())
  ),
  // CX(1,0)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"Transform \( |01\rangle \) to \( |11\rangle \).",
    numQubits: 2,
    initialQubitsStateString: "01",
    availableGates: [SelectedGateType.cnot, SelectedGateType.y],
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
    availableGates: [SelectedGateType.hadamard, SelectedGateType.cnot, SelectedGateType.z, SelectedGateType.y],
    solutionFinalVector: [ // CNOT(Q0, Q2) applied to |000> results in |000>
      [Complex.zero()], [Complex.one()], [Complex.zero()], [Complex.zero()],
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.zero()],
    ],
  ),
  // CX(0,1) + X(0)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |11\rangle \), transform the state to \( |00\rangle \).",
    numQubits: 2,
    initialQubitsStateString: "11",
    availableGates: [SelectedGateType.cnot, SelectedGateType.x],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ], // Target: |01>
  ),
  // CCX (1,0,2)
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
  // CCX(0,1,2)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |011\rangle \), transform the state to \( |111\rangle \).",
    numQubits: 3,
    initialQubitsStateString: "110",
    availableGates: [SelectedGateType.ccnot, SelectedGateType.y, SelectedGateType.z],
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
  // H + CX
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
  // H + CX
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |01\rangle \), create the Bell state \( |\Psi^+\rangle = (|01\rangle + |10\rangle)/\sqrt{2} \).",
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [SelectedGateType.hadamard, SelectedGateType.cnot, SelectedGateType.x],
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
    availableGates: [SelectedGateType.hadamard, SelectedGateType.x, SelectedGateType.y, SelectedGateType.cnot],
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0, isDeletable: false);
      circuit.insertDoublePlacedGateAt(SelectedGateType.cnot, 1, 1, 0, isDeletable: false);
    },
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |00>
  ),
  // H + CX + Z(1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |00\rangle \), create the Bell state \( |\Psi^-\rangle = (|01\rangle - |10\rangle)/\sqrt{2} \).",
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [SelectedGateType.hadamard, SelectedGateType.cnot, SelectedGateType.z, SelectedGateType.y],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
      [Complex(-sqrt1_2, 0)],
      [Complex.zero()],
    ], // Target: (1/sqrt(2))|01> - (1/sqrt(2))|10> (Solution: H on Q0, CNOT(0,1), Z on Q0)
  ),
  // (H + CX + Z) + Z + CX + H
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"This circuit is pre-configured to \( |\Psi^-\rangle \). Your task is to transform this state back to \( |00\rangle \).",
    numQubits: 2,
    initialQubitsStateString: "00", // The simulation starts from |00>
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(SelectedGateType.hadamard, 0, 0, isDeletable: false);
      circuit.insertDoublePlacedGateAt(SelectedGateType.cnot, 1, 1, 0, isDeletable: false);
      circuit.insertSinglePlacedGateAt(SelectedGateType.z, 2, 0, isDeletable: false);
    },
    availableGates: [SelectedGateType.hadamard, SelectedGateType.cnot, SelectedGateType.z, SelectedGateType.x],
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |00> (Solution: Z on Q0, CNOT(0,1), H on Q0 to reverse)
  ),
  // CX(0,1) +  CX(1,0) + CX(0,1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |10\rangle \), swap the states of the two qubits to achieve \( |01\rangle \). This can be done using only CX gates.",
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [SelectedGateType.cnot], // Only CNOTs
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
    availableGates: [SelectedGateType.hadamard, SelectedGateType.cnot, SelectedGateType.y],
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |00> (CZ|00> = |00>) (Solution: H on Q1, CNOT(0,1), H on Q1)
  ),
  // H(0) + X(1) + CX(0,1)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |00\rangle \), create the Bell state \( |\Psi^+\rangle = (|01\rangle + |10\rangle)/\sqrt{2} \).",
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [SelectedGateType.hadamard, SelectedGateType.x, SelectedGateType.y, SelectedGateType.cnot],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
      [Complex(sqrt1_2, 0)],
      [Complex.zero()],
    ], // Target: (1/sqrt(2))|01> + (1/sqrt(2))|10> (Psi+ Bell state)
  ),
  // X(1) + H(0) + CX(0,1) + Z(0)
  QQLevel.fromBinaryString(
    type: "composer",
    taskDescription: r"From \( |10\rangle \), create the Bell state \( |\Phi^-\rangle = (|00\rangle - |11\rangle) \)/\sqrt{2}.",
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [SelectedGateType.hadamard, SelectedGateType.cnot, SelectedGateType.x, SelectedGateType.z],
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
      circuit.insertDoublePlacedGateAt(SelectedGateType.cnot, 0, 1, 0, isDeletable: false);
    },
    availableGates: [SelectedGateType.cnot,SelectedGateType.y, SelectedGateType.z],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
      [Complex.zero()],
    ], // Target: |10> (Solution: CNOT(1,0), CNOT(0,1) after pre-inserted CNOT(0,1))
  ),

  // // --- Start of Phase 3: Three-Qubit & Toffoli (CCNOT) ---
  //


  // // Level 32: Building AND gate (classical logic)
  // QQLevel.fromBinaryString(
  //   type: "composer",
  //   taskDescription: r"You have two input qubits (Q0, Q1) and an ancilla qubit (Q2) initialized to \( |0\rangle \). Use a Toffoli gate to compute the logical AND of Q0 and Q1, storing the result on Q2. Start with \( |110\rangle \).",
  //   numQubits: 3,
  //   initialQubitsStateString: "110",
  //   availableGates: [SelectedGateType.ccnot],
  //   solutionFinalVector: [
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.one()],
  //   ], // Target: |111> (1 AND 1 = 1, stored on Q2)
  // ),
  //
  // // Level 33: Building XOR gate (classical logic with CNOT)
  // QQLevel.fromBinaryString(
  //   type: "composer",
  //   taskDescription: r"You have two input qubits (Q0, Q1) and an ancilla qubit (Q2) initialized to \( |0\rangle \). Use CNOT gates to compute the logical XOR of Q0 and Q1, storing the result on Q2. Start with \( |100\rangle \).",
  //   numQubits: 3,
  //   initialQubitsStateString: "100",
  //   availableGates: [SelectedGateType.cnot],
  //   solutionFinalVector: [
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.one()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //   ], // Target: |101> (1 XOR 0 = 1, stored on Q2)
  //   // Solution: CNOT(0,2), CNOT(1,2)
  // ),
  //
  // // Level 34: 3-qubit state transformation (complex)
  // QQLevel.fromBinaryString(
  //   type: "composer",
  //   taskDescription: r"Transform \( |010\rangle \) to \( |111\rangle \). This requires a careful sequence of gates.",
  //   numQubits: 3,
  //   initialQubitsStateString: "010",
  //   availableGates: [SelectedGateType.x, SelectedGateType.cnot, SelectedGateType.ccnot, SelectedGateType.hadamard],
  //   solutionFinalVector: [
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.one()],
  //   ], // Target: |111>
  //   // Solution: X on Q0, CNOT(0,1), CNOT(1,2)
  // ),
  //
  // // Level 35: GHZ state manipulation (applying X)
  // QQLevel.fromBinaryString(
  //   type: "composer",
  //   taskDescription: r"This circuit is pre-configured to the GHZ state \( \frac{1}{\sqrt{2}}(|000\rangle + |111\rangle) \). Apply a single X gate to Qubit 0. What is the final state?",
  //   numQubits: 3,
  //   initialQubitsStateString: "000", // Base for pre-inserted gates
  //   preInsertedGates: [
  //     [ // Qubit 0 line
  //       PlacedQuantumGate(type: SelectedGateType.hadamard, qubitIndex: 0, column: 0),
  //       PlacedQuantumGate(type: SelectedGateType.cnot, qubitIndex: 0, column: 1, controlQubitIndex: 0, targetQubitIndex: 1),
  //     ],
  //     [ // Qubit 1 line
  //       PlacedQuantumGate(type: SelectedGateType.cnot, qubitIndex: 1, column: 1, controlQubitIndex: 0, targetQubitIndex: 1),
  //       PlacedQuantumGate(type: SelectedGateType.cnot, qubitIndex: 1, column: 2, controlQubitIndex: 1, targetQubitIndex: 2),
  //     ],
  //     [ // Qubit 2 line
  //       PlacedQuantumGate(type: SelectedGateType.cnot, qubitIndex: 2, column: 2, controlQubitIndex: 1, targetQubitIndex: 2),
  //     ]
  //   ],
  //   availableGates: [SelectedGateType.x],
  //   solutionFinalVector: [
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex(sqrt1_2, 0)],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex(sqrt1_2, 0)],
  //   ], // Target: (1/sqrt(2))(|100> + |011>)
  //   // Solution: X on Q0
  // ),
  //
  // // Level 36: Reversing CCNOT operation
  // QQLevel.fromBinaryString(
  //   type: "composer",
  //   taskDescription: r"This circuit is pre-configured with a state that resulted from applying a Toffoli gate to \( |110\rangle \). Transform this state back to \( |110\rangle \).",
  //   numQubits: 3,
  //   initialQubitsStateString: "110", // Base for pre-inserted gates
  //   preInsertedGates: [
  //     [ // Qubit 0 line
  //       PlacedQuantumGate(type: SelectedGateType.ccnot, qubitIndex: 0, column: 0, controlQubitIndex: 0, control2QubitIndex: 1, targetQubitIndex: 2),
  //     ],
  //     [ // Qubit 1 line
  //       PlacedQuantumGate(type: SelectedGateType.ccnot, qubitIndex: 1, column: 0, controlQubitIndex: 0, control2QubitIndex: 1, targetQubitIndex: 2),
  //     ],
  //     [ // Qubit 2 line
  //       PlacedQuantumGate(type: SelectedGateType.ccnot, qubitIndex: 2, column: 0, controlQubitIndex: 0, control2QubitIndex: 1, targetQubitIndex: 2),
  //     ]
  //   ],
  //   availableGates: [SelectedGateType.ccnot],
  //   solutionFinalVector: [
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.zero()],
  //     [Complex.one()],
  //     [Complex.zero()],
  //   ], // Target: |110> (Solution: Apply CCNOT again)
  // ),
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