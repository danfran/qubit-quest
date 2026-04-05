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
    title: 'Bit Flip',
    taskDescription: r"Your first quantum challenge! Apply a gate to transform \( |0\rangle \) to \( |1\rangle \).",
    conceptIntro:
        'Quantum gates are the elementary operations that transform qubit states. '
        'Just as classical computers have logic gates (AND, OR, NOT), quantum computers have '
        'single-qubit gates that flip or rotate a qubit state. '
        'The simplest kind of transformation maps one basis state directly to the other — '
        'your job is to find which gate in your toolbar achieves the required flip.',
    hints: [
      'Think of a classical NOT gate — what does it do to a 0 bit?',
      'The X gate swaps the two basis states: X|0⟩ = |1⟩ and X|1⟩ = |0⟩.',
    ],
    solutionExplanation:
        'Applying the X (Pauli-X) gate flips the qubit: X|0⟩ = |1⟩. '
        'This is the quantum equivalent of a classical NOT. '
        'Notice that applying X twice returns to the original state — every quantum gate is unitary and therefore invertible — X happens to be its own inverse (X² = I), a property called being self-inverse.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex.zero()], [Complex.one()]], // Target: |1> state
  ),
  // Z
  ComposerLevel.fromBinaryString(
    title: 'Phase Flip',
    taskDescription: r"Let's change now only the phase of \( |1\rangle \) without flipping the bit. Transform \( |1\rangle \) to \( -|1\rangle \).",
    conceptIntro:
        'Not every quantum operation changes which basis state a qubit occupies. '
        'Some gates leave the bit value completely unchanged while introducing a phase factor '
        '(a complex multiplier) to one of the amplitudes. '
        'A phase change is invisible in a single measurement — |−1|² = 1 — '
        'but has real physical consequences when qubits interfere with each other. '
        'Look at the target state and the available gates: which one changes only the phase?',
    hints: [
      'Z does not change which state you are in — it only changes the sign of |1⟩.',
      'Z|0⟩ = |0⟩ and Z|1⟩ = −|1⟩. You are already in |1⟩, so apply Z directly.',
    ],
    solutionExplanation:
        'Z|1⟩ = −|1⟩. The Z gate flips the phase of the |1⟩ component without touching |0⟩. '
        'This is called a phase flip — it changes the sign (phase) of the amplitude but not the measurement probability.',
    numQubits: 1,
    initialQubitsStateString: "1",
    availableGates: [Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex.zero()], [negOne]], // Target: |1> state
  ),
  // Y
  ComposerLevel.fromBinaryString(
    title: 'Bit & Phase Flip',
    taskDescription: r"Let's change now the phase and flipping the bit from \( |1\rangle \) to \( |0\rangle \).",
    conceptIntro:
        'The three Pauli gates — X, Y, and Z — form a family of fundamental single-qubit operations. '
        'You have already met two of them: X is a pure bit flip, and Z is a pure phase flip. '
        'The third Pauli gate combines both effects in a single step: it flips the bit '
        'and simultaneously introduces an imaginary phase factor of ±i. '
        'Examine the target state carefully — the required combination of bit flip and phase '
        'will tell you which gate to use.',
    hints: [
      'Y both flips the qubit AND adds a complex phase of ±i.',
      'Y|1⟩ = −i|0⟩. The result is |0⟩ with a phase of −i.',
    ],
    solutionExplanation:
        'Y|1⟩ = −i|0⟩. The Y gate flips the qubit from |1⟩ to |0⟩ and simultaneously '
        'attaches a phase of −i to the amplitude. '
        'Pauli matrices X, Y, Z all satisfy Y = iXZ.',
    numQubits: 1,
    initialQubitsStateString: "1",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[negI], [Complex.zero()]], // Target: |1> state
  ),
  // Y
  ComposerLevel.fromBinaryString(
    title: 'The i-State',
    taskDescription: r"From \( |0\rangle \), reach \( |1\rangle \) with a phase of \( i \). This state is \( |i\rangle \).",
    conceptIntro:
        'A quantum state can have any complex amplitude. '
        'The imaginary unit i appears naturally as a phase factor in quantum mechanics — '
        'states like i|1⟩ are physically distinct from |1⟩ because the phase matters '
        'when states combine through interference. '
        'Not every gate produces complex phases: some map basis states to states with only real amplitudes, '
        'while others introduce factors of i or −i. '
        'Inspect each available gate to reason about what phase it produces.',
    hints: [
      'The X gate gives |1⟩ but without the phase i. You need a gate that also adds the imaginary phase.',
      'Y|0⟩ = i|1⟩. The Y gate is the only single gate here that produces the required phase.',
    ],
    solutionExplanation:
        'Y|0⟩ = i|1⟩. The Y gate maps |0⟩ to i|1⟩, producing the so-called |i⟩ state. '
        'This is a 180° rotation around the Y-axis of the Bloch sphere (Y = i·Ry(π)).',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [[Complex.zero()], [Complex.i()]], // Target: |i> state (Y|0> = i|1>)
  ),
  // X + Z + X
  ComposerLevel.fromBinaryString( // 5
    title: 'Phase Sandwich',
    taskDescription: r"Starting from \( |0\rangle \), achieve \( -|0\rangle \).",
    conceptIntro:
        'Gates compose: applying multiple gates in sequence multiplies their matrices. '
        'Some operations cannot be applied directly to the current state — '
        'but they can be applied indirectly by first transforming into a convenient basis. '
        'A recurring quantum circuit pattern is to (1) transform the state into a useful form, '
        '(2) apply the desired operation, and (3) transform back. '
        'This "conjugation" trick — wrapping one gate inside two others — '
        'is a fundamental building block in quantum algorithm design.',
    hints: [
      'Z|0⟩ = |0⟩ — Z alone cannot phase-flip |0⟩. You need to flip the qubit to |1⟩ first.',
      'Sequence: X turns |0⟩→|1⟩, Z turns |1⟩→−|1⟩, X turns −|1⟩→−|0⟩.',
    ],
    solutionExplanation:
        'XZX|0⟩ = −|0⟩. '
        'Step by step: X|0⟩ = |1⟩, then Z|1⟩ = −|1⟩, then X(−|1⟩) = −|0⟩. '
        'This is the canonical example of gate composition and the "conjugation" pattern: '
        'UGU† applies gate G in the basis defined by U.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[negOne], [Complex.zero()]], // Target: -|0> state (e.g., XZX)
  ),
  // H
  ComposerLevel.fromBinaryString(
    title: 'Superposition',
    taskDescription: r"Create a superposition! Turn \( |0\rangle \) into \( |+\rangle \).",
    conceptIntro:
        'Superposition is a defining feature of quantum computing. '
        'Unlike a classical bit that is always exactly 0 or 1, a qubit can exist in a '
        'combination of both states at once — described by complex probability amplitudes. '
        'When you measure a qubit in superposition, the outcome is probabilistic: '
        'the chance of each result equals the squared magnitude of its amplitude (Born rule: P = |amplitude|²). '
        'The notation |+⟩ is the standard label for the equal-weight superposition that is your target here.',
    hints: [
      'There is exactly one gate in your toolbar that creates an equal superposition from a basis state.',
      'It is the H (Hadamard) gate. H|0⟩ = (|0⟩+|1⟩)/√2 = |+⟩.',
    ],
    solutionExplanation:
        'H|0⟩ = (|0⟩+|1⟩)/√2 = |+⟩. '
        'Both amplitudes are 1/√2, so |1/√2|² = 0.5 — a 50% chance of measuring either outcome. '
        'H is its own inverse: H² = I, so applying H twice returns to |0⟩.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(sqrt1_2)]], // Target: |+> state
  ),
  // H + T
  ComposerLevel.fromBinaryString(
    title: 'T Gate Phase',
    taskDescription: r"You're at \( |0\rangle \). Apply gates to reach a state where the \( |1\rangle \) amplitude has a phase of \( e^{i\pi/4} \). This is \( (|0\rangle + e^{i\pi/4}|1\rangle)/\sqrt{2} \).",
    conceptIntro:
        'Phase gates rotate only the phase of the |1⟩ amplitude by a fixed angle, leaving |0⟩ unchanged. '
        'On their own, phase gates are invisible to a single measurement — |e^(iφ)|² = 1 regardless of φ. '
        'Their power emerges when a qubit is first placed in superposition: '
        'the relative phase between |0⟩ and |1⟩ then affects how amplitudes interfere in subsequent steps. '
        'The target state has a specific phase on the |1⟩ component — '
        'use the target amplitudes to reason about which gate and angle you need.',
    hints: [
      'First use H to put the qubit in superposition (|0⟩+|1⟩)/√2 — this gives both amplitudes.',
      'Then apply T: it leaves |0⟩ alone and multiplies |1⟩ by e^(iπ/4), rotating its phase by 45°.',
    ],
    solutionExplanation:
        'H creates (|0⟩+|1⟩)/√2. T then multiplies the |1⟩ amplitude by e^(iπ/4), '
        'giving (|0⟩ + e^(iπ/4)|1⟩)/√2. '
        'T is fundamental to quantum computing — it is one of the gates needed for universal quantum computation.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.t), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0.5, 0.5)]], // Target: |+> state
  ),
  // H + S
  ComposerLevel.fromBinaryString(
    title: 'S Gate — 90° Phase',
    taskDescription: r"Transform the initial state of the qubit from \( |0\rangle \) to the target state \( |+i\rangle = (|0\rangle + |i\rangle)/\sqrt{2} \).",
    conceptIntro:
        'The S gate is a phase gate that applies a 90° rotation to the |1⟩ amplitude: S|1⟩ = i|1⟩. '
        'Like all phase gates, S cannot create superposition on its own — '
        'it only affects the phase of an existing |1⟩ amplitude. '
        'The four cardinal equatorial states |+⟩, |−⟩, |+i⟩, |−i⟩ are related to each other '
        'by 90° phase steps on the Bloch sphere. '
        'Think about which sequence of gates takes you from |0⟩ to the target state.',
    hints: [
      'First create superposition with H so both amplitudes are active.',
      'S multiplies only the |1⟩ amplitude by i, rotating its phase by 90°: (|0⟩+|1⟩)/√2 → (|0⟩+i|1⟩)/√2.',
    ],
    solutionExplanation:
        'H|0⟩ = (|0⟩+|1⟩)/√2. '
        'S then rotates |1⟩ by 90°: S(|0⟩+|1⟩)/√2 = (|0⟩+i|1⟩)/√2 = |+i⟩. '
        'This state is also called |R⟩ (right circular polarisation) on the Bloch sphere.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.z)],
    solutionFinalVector: [[Complex(sqrt1_2)], [Complex(0, sqrt1_2)]], // Target: |+> state
  ),
  // H + Z
  ComposerLevel.fromBinaryString(
    title: 'The Minus State',
    taskDescription: r"Transform \( |+\rangle \) to \( |-\rangle \).",
    conceptIntro:
        'The |-⟩ state is (|0⟩−|1⟩)/√2 — a superposition where the |1⟩ amplitude carries a negative sign. '
        'Together with |+⟩, |+i⟩, and |−i⟩, it forms the four cardinal "compass points" '
        'on the equatorial plane of the Bloch sphere. '
        'Think about what kind of operation selectively adjusts the relative phase between '
        'the |0⟩ and |1⟩ amplitudes without changing their magnitudes.',
    hints: [
      'Start by creating |+⟩ with H, then you need to flip the sign of |1⟩.',
      'Z|1⟩ = −|1⟩ and Z|0⟩ = |0⟩, so Z turns (|0⟩+|1⟩)/√2 into (|0⟩−|1⟩)/√2 = |-⟩.',
    ],
    solutionExplanation:
        'H|0⟩ = (|0⟩+|1⟩)/√2 = |+⟩. '
        'Z then flips the sign of |1⟩: Z|+⟩ = (|0⟩−|1⟩)/√2 = |−⟩. '
        '|+⟩ and |−⟩ are called the Hadamard basis (or X-basis) states — they are the eigenstates of the X gate.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y), Gate.fromIdentifier(SelectedGateType.x)],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(-sqrt1_2, 0)]], // Target: |-> state (H then Z)
  ),
  // H(1) + X(0)
  ComposerLevel.fromBinaryString( // 10
    title: '2-Qubit Product State',
    taskDescription: r"From \( |00\rangle \), create the product state \( |+\rangle \otimes |1\rangle = (|01\rangle + |11\rangle)/\sqrt{2} \).",
    conceptIntro:
        'Two-qubit systems are described by tensor products. '
        'When no controlled gate connects them, each qubit can be operated independently. '
        'The full state vector has 2² = 4 entries: |00⟩, |01⟩, |10⟩, |11⟩. '
        'A product (non-entangled) state like |+⟩⊗|1⟩ factors into separate single-qubit states.',
    hints: [
      'You need to act on both qubits separately — no controlled gate is required here.',
      'Apply H to Q0 (qubit 0) to create superposition, and X to Q1 (qubit 1) to flip it to |1⟩. The result is |+⟩⊗|1⟩.',
    ],
    solutionExplanation:
        'H on Q0 gives (|0⟩+|1⟩)/√2 on qubit 0. X on Q1 flips qubit 1 to |1⟩. '
        'Combining via tensor product: (|0⟩+|1⟩)/√2 ⊗ |1⟩ = (|01⟩+|11⟩)/√2. '
        'This is a product state — the two qubits are independent and not entangled.',
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
    title: 'The −i State',
    taskDescription: r"From \( |+\rangle \), achieve \( |-i\rangle = (|0\rangle - i|1\rangle)/\sqrt{2} \).",
    conceptIntro:
        'You have seen |+i⟩ = (|0⟩+i|1⟩)/√2 — now aim for its mirror: |-i⟩ = (|0⟩−i|1⟩)/√2. '
        'The four cardinal equatorial states |+⟩, |−⟩, |+i⟩, |−i⟩ each differ by a 90° phase step on |1⟩. '
        'To reach |−i⟩ you need a net phase of −i on the |1⟩ component. '
        'Phase angles add when gates are applied in sequence — '
        'think about which combination of available phase gates accumulates to that total rotation.',
    hints: [
      'Start with H to create superposition |+⟩. Then you need to rotate |1⟩\'s phase to −i.',
      'Apply Z first (flips |1⟩ sign), then S (multiplies by i): together they give −i on |1⟩. '
          'Sequence: H → Z → S.',
    ],
    solutionExplanation:
        'H|0⟩ = (|0⟩+|1⟩)/√2. '
        'Z flips |1⟩: (|0⟩−|1⟩)/√2. '
        'S multiplies |1⟩ by i: (|0⟩ − i|1⟩)/√2 = |-i⟩. '
        '|-i⟩ is also called the |L⟩ (left circular) state on the Bloch sphere.',
    numQubits: 1,
    initialQubitsStateString: "0", // Requires H and ZS or YS or something
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(0, -sqrt1_2)]], // Target: |-i> state (e.g., HZ then S)
  ),
  // (H + S + Z) + S + H + X
  ComposerLevel.fromBinaryString(
    title: 'Uncomputing a Phase State',
    taskDescription: r"You're at \( (|0\rangle - i|1\rangle)/\sqrt{2} \). Transform this state back to \( |1\rangle \).",
    conceptIntro:
        'Quantum circuits are reversible — every operation can be undone. '
        'The pre-inserted gates H→S→Z have already transformed |0⟩ into |-i⟩ = (|0⟩−i|1⟩)/√2. '
        'Your task is to find the continuation that drives this state all the way to |1⟩. '
        'This "uncomputation" pattern is essential in quantum algorithms to clean up ancilla qubits.',
    hints: [
      'You start from |-i⟩ = (|0⟩−i|1⟩)/√2 (the output of the pre-inserted H, S, Z). '
          'Think about what gate maps −i|1⟩ → +|1⟩.',
      'S·(−i|1⟩) = i·(−i)|1⟩ = |1⟩ — so S collapses the |1⟩ phase. '
          'After S you have |+⟩. H then maps |+⟩→|0⟩, and X flips to |1⟩.',
    ],
    solutionExplanation:
        'Starting from |-i⟩: S converts −i phase to 1 (S·(−i)=−i·i=1), giving |+⟩. '
        'H|+⟩ = |0⟩. X|0⟩ = |1⟩. '
        'Sequence to add: S → H → X. '
        'Together with the pre-inserted H→S→Z, the full 6-gate circuit maps |0⟩ → |1⟩.',
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
    title: 'T† — Inverse Phase Gate',
    taskDescription: r"From \( |0\rangle \), reach \( (|0\rangle + e^{-i\pi/4}|1\rangle)/\sqrt{2} \).",
    conceptIntro:
        'T† (T-dagger, also written T⁻¹) is the inverse of the T gate. '
        'Where T rotates the |1⟩ phase by +π/4, T† rotates by −π/4. '
        'T† is not directly available in your toolbar, but like many quantum gates '
        'it can be constructed by combining simpler gates whose phase rotations add up correctly. '
        'Finding such decompositions is a core quantum computing skill.',
    hints: [
      'Start with H to create |+⟩. Then you need a net phase of −π/4 on |1⟩.',
      'T adds +π/4, S adds +π/2, Z adds +π. Total T+S+Z = π/4+π/2+π = 7π/4 ≡ −π/4 (mod 2π). '
          'Sequence: H → T → S → Z.',
    ],
    solutionExplanation:
        'H gives (|0⟩+|1⟩)/√2. '
        'T adds phase +π/4 → e^(iπ/4). '
        'S adds +π/2 → e^(i3π/4). '
        'Z adds +π → e^(i7π/4) = e^(−iπ/4). '
        'Final state: (|0⟩ + e^(−iπ/4)|1⟩)/√2. '
        'This is exactly what T†|+⟩ produces — constructed from T, S, Z.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.t), Gate.fromIdentifier(SelectedGateType.s), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [[Complex(sqrt1_2, 0)], [Complex(0.5, -0.5)]], // Target: HZ T |0> (HT then Z) or (H then T.conjugate())
  ),
  // CX(0,1)
  ComposerLevel.fromBinaryString(
    title: 'CNOT Gate',
    taskDescription: r"From \( |10\rangle \), create a circuit where Qubit 1 will 'mirror' the state of Qubit 0. The final state should be \( |11\rangle \).",
    conceptIntro:
        'The CNOT (Controlled-NOT, CX) gate is the fundamental two-qubit gate. '
        'It has a "control" qubit and a "target" qubit: the target flips if and only if the control is |1⟩, '
        'and is left unchanged if the control is |0⟩. '
        'CNOT is the quantum equivalent of classical XOR: target_out = target ⊕ control. '
        'Before applying it, identify which qubit should be the control and which the target '
        'based on the current state and the desired outcome.',
    hints: [
      'In |10⟩, Q0=1 and Q1=0. You want Q1 to flip to 1. Which qubit should be the control?',
      'Use CNOT with Q0 as control and Q1 as target. Q0=1 satisfies the condition, so Q1 flips: 0→1, giving |11⟩.',
    ],
    solutionExplanation:
        'CNOT(Q0→Q1)|10⟩ = |11⟩. '
        'Q0=1 triggers the flip: Q1 goes from 0 to 1. '
        'Equivalently: Q1_new = Q1 ⊕ Q0 = 0 ⊕ 1 = 1. '
        'CNOT combined with single-qubit gates forms a universal gate set for quantum computing.',
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
    title: 'CNOT: Swapping Control & Target',
    taskDescription: r"Transform \( |01\rangle \) to \( |11\rangle \).",
    conceptIntro:
        'CNOT is not symmetric — swapping the roles of the control and target qubit '
        'produces a completely different operation. '
        'The key question before applying CNOT is always: which qubit is in |1⟩ and should act '
        'as the "condition", and which qubit needs to be flipped? '
        'Getting the control and target assignment wrong means the condition is never met '
        'and the circuit leaves the state unchanged.',
    hints: [
      'In |01⟩, Q0=0 and Q1=1. You need Q0 to flip to 1.',
      'Use CNOT with Q1 as control (Q1=1 triggers the condition) and Q0 as target. '
          'CNOT(Q1→Q0)|01⟩ = |11⟩.',
    ],
    solutionExplanation:
        'CNOT(Q1→Q0)|01⟩ = |11⟩. '
        'Q1=1 is the control, so Q0 flips: 0→1. '
        'Compare with level 14 where the roles were reversed. '
        'Note: CNOT(Q0→Q1) on |01⟩ would give |01⟩ unchanged (Q0=0 does not trigger).',
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
    title: '3-Qubit CNOT',
    taskDescription: r"Explore 3 qubits! Transform \( |101\rangle \) to \( |100\rangle \).",
    conceptIntro:
        'CNOT can connect any two qubits in a multi-qubit register — they do not need to be adjacent. '
        'A 3-qubit system has a state vector with 2³=8 entries. '
        'Here |101⟩ means Q0=1, Q1=0, Q2=1. '
        'Applying CNOT to non-adjacent qubits is a key building block for multi-qubit algorithms.',
    hints: [
      'Q0=1 and Q2=1 in |101⟩. You want to flip Q2 from 1 to 0. Which qubit is active enough to be the control?',
      'Use CNOT with Q0 as control and Q2 as target. Q0=1 triggers the flip: Q2 goes 1→0, giving |100⟩.',
    ],
    solutionExplanation:
        'CNOT(Q0→Q2)|101⟩ = |100⟩. '
        'Q0=1 is the control, so Q2 flips: 1→0. Q1 is untouched. '
        'In the 8-entry state vector (|000⟩…|111⟩), |100⟩ is index 4 (big-endian). '
        'This level shows that CNOT works over any qubit distance.',
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
    title: 'Uncomputing with CNOT',
    taskDescription: r"From \( |11\rangle \), transform the state to \( |00\rangle \).",
    conceptIntro:
        'Reaching any two-qubit basis state from any other requires the right combination of gates '
        'applied in the correct order. '
        'Unlike single-qubit gates, the order in which you apply two-qubit and single-qubit operations '
        'generally matters — different orderings produce different results. '
        'Think carefully about which qubit needs to change first and what the intermediate '
        'state looks like after each gate.',
    hints: [
      'Try CNOT(Q0→Q1) on |11⟩ first: Q0=1 flips Q1: 1→0, giving |10⟩. Now you only need to fix Q0.',
      'After CNOT gives |10⟩, apply X on Q0: 1→0. Final state: |00⟩. Total: CNOT(Q0→Q1) then X on Q0.',
    ],
    solutionExplanation:
        'CNOT(Q0→Q1)|11⟩ = |10⟩ (Q0=1 flips Q1: 1→0). '
        'X on Q0: |10⟩ → |00⟩. '
        'Two gates are sufficient. Note the alternative order does NOT work: '
        'X on Q0 first gives |01⟩, then CNOT(Q0→Q1) leaves it as |01⟩ (Q0=0, condition never triggers — wrong!). '
        'So CNOT first is the correct order here.',
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
    title: 'Toffoli Gate (CCX)',
    taskDescription: r"Turn \( |101\rangle \) into \( |111\rangle \).",
    conceptIntro:
        'The Toffoli gate (CCX, CCNOT) has two control qubits and one target. '
        'It flips the target only when BOTH controls are |1⟩ — making it a quantum AND gate. '
        'Truth table for the target bit: target_out = target ⊕ (ctrl1 AND ctrl2). '
        'Toffoli is universal for classical reversible computation.',
    hints: [
      'In |101⟩: Q0=1, Q1=0, Q2=1. You want Q1 to flip to 1. '
          'Which two qubits are both |1⟩ and can serve as the AND condition?',
      'Q0=1 AND Q2=1 satisfies the Toffoli condition. Set Q0 and Q2 as controls, Q1 as target. '
          'CCX(ctrl:Q0,Q2; target:Q1)|101⟩ = |111⟩.',
    ],
    solutionExplanation:
        'CCX with controls Q0,Q2 and target Q1: Q0=1 AND Q2=1 → Q1 flips: 0→1. '
        'Result: |111⟩. '
        'This is equivalent to Q1_new = Q1 ⊕ (Q0 AND Q2) = 0 ⊕ (1 AND 1) = 1. '
        'Toffoli (CCX) combined with the Hadamard gate forms a universal gate set for '
        'quantum computation, and on its own it is universal for classical reversible logic.',
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
    title: 'Toffoli: Choose Your Controls',
    taskDescription: r"From \( |011\rangle \), transform the state to \( |111\rangle \).",
    conceptIntro:
        'The Toffoli gate is flexible — any two qubits can be the controls and '
        'any distinct third qubit can be the target. '
        'Before applying CCX, identify which two qubits satisfy the AND condition '
        '(both must be |1⟩) and which qubit needs to be flipped. '
        'Compare the initial state with the target to determine the correct qubit assignments.',
    hints: [
      'In |011⟩: Q0=0, Q1=1, Q2=1. The two |1⟩ qubits are Q1 and Q2. Q0 needs to flip to 1.',
      'Set Q1 and Q2 as controls, Q0 as target. Both controls are 1, so Q0 flips: 0→1. '
          'CCX(ctrl:Q1,Q2; target:Q0)|011⟩ = |111⟩.',
    ],
    solutionExplanation:
        'CCX(ctrl:Q1,Q2; target:Q0)|011⟩ = |111⟩. '
        'Q1=1 AND Q2=1 → Q0 flips: 0→1. '
        'Compare with level 18 (controls Q0,Q2; target Q1) — same gate type, different qubit assignment. '
        'Choosing controls flexibly is essential for implementing quantum arithmetic circuits.',
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
    title: 'Toffoli Self-Inverse',
    taskDescription: r"You are given a 3-qubit circuit already in the state \( |111\rangle \). Transform this state back to \( |110\rangle \).",
    conceptIntro:
        'Like X and CNOT, the Toffoli gate is its own inverse: CCX·CCX = I. '
        'Applying CCX twice in a row restores the original state, because flipping a bit twice returns it to its start. '
        'The pre-inserted CCX has already taken |110⟩ → |111⟩. '
        'Your task demonstrates a fundamental property: every quantum gate is unitary and reversible.',
    hints: [
      'The pre-inserted CCX(Q0,Q1→Q2) flipped Q2: 0→1, giving |111⟩. You start from |111⟩.',
      'Since CCX is self-inverse, applying the same CCX once more will flip Q2 back: 1→0. Result: |110⟩.',
    ],
    solutionExplanation:
        'CCX is self-inverse: applying it again with the same qubit assignment undoes the previous flip. '
        'CCX(ctrl:Q0,Q1; target:Q2)|111⟩ = |110⟩ (Q0=1 AND Q1=1 → Q2 flips: 1→0). '
        'This reversibility is not optional in quantum computing — all gates must be unitary (reversible). '
        'It distinguishes quantum from classical computation, where AND and OR are irreversible.',
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
    title: 'Toffoli as AND Gate',
    taskDescription: r"From \( |010\rangle \), transform the state to \( |111\rangle \).",
    conceptIntro:
        'The Toffoli gate computes a quantum AND: CCX(ctrl₁,ctrl₂→tgt) sets '
        'tgt ← tgt ⊕ (ctrl₁ AND ctrl₂). '
        'For the AND to fire, BOTH control qubits must be |1⟩. '
        'Inspect the initial state carefully: if any intended control qubit is |0⟩, '
        'the Toffoli condition will never be satisfied and the target will not flip. '
        'You may need to prepare one or more qubits before applying CCX.',
    hints: [
      'CCX flips the target only when BOTH controls are |1⟩. '
          'In |010⟩ only Q1=1 — you need a second qubit to also be |1⟩ first.',
      'Apply X on Q0: |010⟩ → |110⟩. Now CCX with Q0 and Q1 as controls, Q2 as target: '
          'both controls are 1, so Q2 flips: 0→1, giving |111⟩.',
    ],
    solutionExplanation:
        'X flips Q0: |010⟩ → |110⟩. '
        'CCX(ctrl:Q0,Q1; target:Q2): Q0∧Q1 = 1∧1 = 1, so Q2 flips: 0→1. '
        'Result: |111⟩. '
        'This is the quantum AND circuit: Q2 stores Q0 AND Q1, '
        'while Q0 and Q1 are left unchanged (reversibility).',
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
    title: 'First Bell State Φ⁺',
    taskDescription: r"Entangle two qubits! Create the Bell state \( |00\rangle + |11\rangle\).",
    conceptIntro:
        'Entanglement is the defining feature of quantum mechanics. '
        'The Bell state Φ⁺ = (|00⟩+|11⟩)/√2 cannot be written as (state of Q0)⊗(state of Q1). '
        'After creating it, measuring either qubit instantly determines the other — '
        'both are always 0 or always 1, with 50% probability each. '
        'This perfect correlation persists regardless of the distance between the qubits.',
    hints: [
      'H on Q0 creates (|0⟩+|1⟩)/√2 ⊗ |0⟩ = (|00⟩+|10⟩)/√2. '
          'This is still a product state — the qubits are not yet entangled.',
      'Apply CNOT(Q0→Q1) next: |00⟩→|00⟩ (Q0=0, no flip), |10⟩→|11⟩ (Q0=1, flip Q1). '
          'Result: (|00⟩+|11⟩)/√2 = Φ⁺. The two qubits are now entangled.',
    ],
    solutionExplanation:
        'H on Q0 followed by CNOT(Q0→Q1) creates Φ⁺ = (|00⟩+|11⟩)/√2. '
        'The CNOT correlates Q1 with Q0: when Q0 is |1⟩, Q1 flips too. '
        'The result is inseparable — this is the canonical Bell state creation circuit, '
        'used as the first step in quantum teleportation and superdense coding.',
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
    title: 'Bell State Ψ⁺',
    taskDescription: r"From \( |01\rangle \), create the Bell state \( |\Psi^+\rangle = (|01\rangle + |10\rangle)/\sqrt{2} \).",
    conceptIntro:
        'There are four Bell states, each a maximally-entangled two-qubit state. '
        'Ψ⁺ = (|01⟩+|10⟩)/√2 is anti-correlated: measuring one qubit always gives the '
        'opposite result on the other. '
        'The Bell states differ from each other by local single-qubit operations — '
        'the initial state before entangling determines which Bell state the circuit produces. '
        'Compare the target Ψ⁺ to Φ⁺ from level 22 and think about what is different.',
    hints: [
      'The initial state has one qubit as |1⟩ and one as |0⟩. '
          'Apply H to the qubit that is in |0⟩ to create a superposition without a minus sign.',
      'H on the |0⟩ qubit gives (|0⟩+|1⟩)/√2. '
          'Then apply CNOT with the superposed qubit as control — it will flip the |1⟩ qubit '
          'only for the |1⟩ component of the superposition. Result: (|01⟩+|10⟩)/√2 = Ψ⁺.',
    ],
    solutionExplanation:
        'H on the |0⟩ qubit creates superposition: |1⟩⊗(|0⟩+|1⟩)/√2 = (|10⟩+|11⟩)/√2. '
        'CNOT with that qubit as control: |11⟩ → |01⟩ (control=1, flip the other qubit). '
        'Result: (|10⟩+|01⟩)/√2 = Ψ⁺. '
        'Every Bell state differs from the others by a local X or Z applied to one qubit.',
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
    title: 'Disentangling a Bell State',
    taskDescription: r"Time for disentangling Bell State. Can you reverse the process to get back to \( |00\rangle \)?",
    conceptIntro:
        'Quantum circuits are reversible — every entangling operation can be undone. '
        'The pre-inserted circuit created the Bell state Φ⁺. '
        'Since each gate used is self-inverse (applying the same gate twice returns to the start), '
        'the reversal follows a simple principle: apply the same gates, but in the opposite order. '
        'This "Bell measurement" circuit is the decoder in quantum teleportation.',
    hints: [
      'To reverse a sequence of self-inverse gates, apply them in reverse order. '
          'The pre-inserted circuit was H→CNOT, so the reversal is CNOT→H.',
      'Apply CNOT(Q0→Q1) to Φ⁺: it un-entangles the state back to (|00⟩+|10⟩)/√2. '
          'Then H on Q0 maps |+⟩=|0⟩+|1⟩/√2 → |0⟩. Final state: |00⟩.',
    ],
    solutionExplanation:
        'CNOT(Q0→Q1) on Φ⁺=(|00⟩+|11⟩)/√2: |11⟩→|10⟩, giving (|00⟩+|10⟩)/√2. '
        'H on Q0: (|0⟩+|1⟩)/√2 → |0⟩. Final: |00⟩. '
        'The reverse circuit (CNOT→H) is the Bell-basis measurement used in '
        'quantum teleportation to decode the transmitted qubit.',
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
    title: 'Bell State Ψ⁻',
    taskDescription: r"From \( |10\rangle \), create the Bell state \( |\Psi^-\rangle = (|01\rangle - |10\rangle)/\sqrt{2} \).",
    conceptIntro:
        'Ψ⁻ = (|01⟩−|10⟩)/√2 is the only Bell state antisymmetric under qubit swap '
        '(swapping the two qubits gives −Ψ⁻). It is known as the "singlet" state in physics. '
        'Ψ⁻ and Ψ⁺ differ only by a relative sign between their two terms. '
        'The four Bell states are all related to each other by simple local single-qubit operations — '
        'think about what kind of operation introduces a sign change to one of the two terms.',
    hints: [
      'First create Ψ⁺: apply H to Q0 (the top qubit, which starts as |0⟩), then CNOT with '
          'Q0 as control and Q1 as target (same approach as level 23). '
          'You will have (|01⟩+|10⟩)/√2.',
      'Now apply Z to Q1 (the bottom qubit, which starts as |1⟩). '
          'Z flips the sign of the |1⟩ component only. '
          'In the |10⟩ term Q1=1, so Z gives −|10⟩; in the |01⟩ term Q1=0, so it is unchanged. '
          'Result: (|01⟩−|10⟩)/√2 = Ψ⁻. '
          'Important: Z on Q0 flips the |01⟩ term instead, giving −Ψ⁻ which does NOT match.',
    ],
    solutionExplanation:
        'H on Q0 (top, starts as |0⟩) + CNOT (Q0 control → Q1 target) gives Ψ⁺=(|01⟩+|10⟩)/√2. '
        'Z on Q1 flips the phase of the |10⟩ term (Q1=1 there) while leaving the |01⟩ term unchanged (Q1=0): Ψ⁺ → Ψ⁻. '
        'Only Z on Q1 works — Z on Q0 flips the |01⟩ term (Q0=1 there), producing −Ψ⁻ instead.',
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard), Gate.fromIdentifier(SelectedGateType.cnot), Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.y)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
      [Complex(-sqrt1_2, 0)],
      [Complex.zero()],
    ], // Target: (1/sqrt(2))|01> - (1/sqrt(2))|10> (Solution: H on Q0, CNOT(Q0→Q1), Z on Q1)
  ),
  // H + CX + Z(0) (or Z(1)). It can have 2 solution potentially, with Z(0) + Z(1)
  ComposerLevel.fromBinaryString(
    title: 'Bell State Φ⁻',
    taskDescription: r"From \( |00\rangle \), prepare the Bell state \( |\Phi^-\rangle = (|00\rangle - |11\rangle)/\sqrt{2} \). You need only one solution although it can have 2 solutions potenially, due to entanglement.",
    conceptIntro:
        'The four Bell states — Φ⁺, Φ⁻, Ψ⁺, Ψ⁻ — form a complete orthonormal basis for '
        'two-qubit space. Any two-qubit state can be expanded in the Bell basis. '
        'Φ⁻ = (|00⟩−|11⟩)/√2 differs from Φ⁺ only by the sign of the |11⟩ term. '
        'Due to the entanglement symmetry of Bell states, more than one local single-qubit operation '
        'can achieve this sign change — two solutions are accepted here.',
    hints: [
      'Start as in level 22: H on Q0, then CNOT(Q0→Q1). This gives Φ⁺=(|00⟩+|11⟩)/√2.',
      'Now flip the sign of |11⟩. Z on any qubit flips the sign when that qubit is |1⟩ — '
          'since both qubits are |1⟩ in the |11⟩ term, Z on either one converts Φ⁺ to Φ⁻.',
    ],
    solutionExplanation:
        'H+CNOT from |00⟩ gives Φ⁺=(|00⟩+|11⟩)/√2. '
        'Z on Q0 flips the |11⟩ sign (Q0=1): (|00⟩−|11⟩)/√2 = Φ⁻. '
        'Alternatively Z on Q1 achieves the same result — '
        'both are valid because in an entangled state local operations can have global effects.',
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
    title: 'Uncomputing Φ⁻',
    taskDescription: r"This circuit is pre-configured. Your task is to transform this state back to \( |00\rangle \).",
    conceptIntro:
        'The pre-inserted H→CNOT→Z sequence has created Φ⁻=(|00⟩−|11⟩)/√2. '
        'To reverse an entangled state, apply the inverse operations in reverse order. '
        'Since all three gates here are self-inverse, their inverses are the gates themselves — '
        'the only question is what order to apply them. '
        'Work backwards through the pre-inserted sequence to determine what to add. '
        'This reversal pattern — called "uncomputation" — is essential in quantum algorithms '
        'for resetting ancilla qubits without measurement.',
    hints: [
      'The pre-inserted circuit is H→CNOT→Z. '
          'To undo it, apply the inverse in reverse order: Z, then CNOT, then H.',
      'Z on Q0 undoes the pre-inserted Z: Φ⁻→Φ⁺=(|00⟩+|11⟩)/√2. '
          'CNOT(Q0→Q1) disentangles: (|00⟩+|10⟩)/√2. '
          'H on Q0 maps |+⟩→|0⟩. Final: |00⟩.',
    ],
    solutionExplanation:
        'Z on Q0: Φ⁻ → Φ⁺. '
        'CNOT(Q0→Q1): Φ⁺ → (|00⟩+|10⟩)/√2. '
        'H on Q0: |+⟩ → |0⟩. Final: |00⟩. '
        'Total: Z→CNOT→H — the exact reverse of the pre-inserted H→CNOT→Z. '
        'Uncomputation is essential in quantum algorithms to reset ancilla qubits without measurement.',
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
    title: 'SWAP via Three CNOTs',
    taskDescription: r"From \( |10\rangle \), swap the states of the two qubits to achieve \( |01\rangle \). This can be done using only CX gates.",
    conceptIntro:
        'A SWAP gate exchanges the states of two qubits: SWAP|ab⟩ = |ba⟩. '
        'There is no SWAP gate in your toolbar, but it can be constructed from gates you already know. '
        'Think about how to use CNOT to transfer information between qubits step by step: '
        'each CNOT propagates part of one qubit\'s value into the other. '
        'A sequence of CNOTs in the right order and direction can implement a complete qubit exchange. '
        'This identity holds for any input state, including superpositions and entangled states.',
    hints: [
      'Three CNOTs are needed for a general SWAP. '
          'Step 1: CNOT(Q0→Q1) on |10⟩: Q0=1, flip Q1: 0→1 → |11⟩.',
      'Step 2: CNOT(Q1→Q0) on |11⟩: Q1=1, flip Q0: 1→0 → |01⟩. '
          'At this point |01⟩ is already the target — one more CNOT(Q0→Q1) completes '
          'the full SWAP decomposition (Q0=0, no flip, stays |01⟩).',
    ],
    solutionExplanation:
        'CNOT(Q0→Q1)|10⟩=|11⟩. CNOT(Q1→Q0)|11⟩=|01⟩. '
        'The third CNOT(Q0→Q1) leaves |01⟩ unchanged (Q0=0). '
        'The general SWAP identity SWAP = CNOT(0→1)·CNOT(1→0)·CNOT(0→1) '
        'works for any input, including superpositions — '
        'this is how SWAP is implemented in real quantum hardware.',
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
    title: 'Conditional Phase Flip',
    taskDescription: r"From \( |00\rangle \), flip the phase of \( |11\rangle \).",
    conceptIntro:
        'Flipping only the phase of |11⟩ while leaving all other basis states unchanged '
        'is called a Controlled-Z (CZ) operation. '
        'CZ is not directly available in your toolbar, but it can be constructed from '
        'Hadamard and CNOT gates. '
        'The Hadamard gate changes the basis in which an operation acts — a technique called '
        '"basis conjugation" — which can convert a bit flip into a phase flip. '
        'This technique appears throughout Grover\'s algorithm and quantum error correction.',
    hints: [
      'First create the uniform superposition (|00⟩+|01⟩+|10⟩+|11⟩)/2 '
          'by applying H to both qubits. Now all four states have equal amplitude.',
      'To flip only |11⟩, sandwich a CNOT between H gates on one qubit: '
          'H(one qubit) → CNOT → H(same qubit). '
          'This implements CZ, which maps (|00⟩+|01⟩+|10⟩+|11⟩)/2 '
          'to (|00⟩+|01⟩+|10⟩−|11⟩)/2.',
    ],
    solutionExplanation:
        'H on both qubits gives (|00⟩+|01⟩+|10⟩+|11⟩)/2. '
        'The decomposition CZ = H(tgt)·CNOT·H(tgt) then flips only |11⟩. '
        'The explicit decomposition CZ = H(Q1)·CNOT·H(Q1), applied after the uniform '
        'superposition H(Q0)·H(Q1), gives a 5-gate sequence that simplifies (H·H=I) '
        'to: H(Q0), CNOT, H(Q1) from |00⟩. '
        'Result: (|00⟩+|01⟩+|10⟩−|11⟩)/2. '
        'The CZ decomposition via H·CNOT·H is fundamental in quantum computing.',
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
    title: 'Bell Ψ⁺ from |00⟩',
    taskDescription: r"From \( |00\rangle \), create the Bell state \( |\Psi^+\rangle = (|01\rangle + |10\rangle)/\sqrt{2} \).",
    conceptIntro:
        'All four Bell states can be prepared from |00⟩ by adjusting what you do '
        'before or after the standard entangling circuit. '
        'Ψ⁺ = (|01⟩+|10⟩)/√2 is anti-correlated: the two qubits are always opposite when measured. '
        'Compare this to Φ⁺ from level 22, where both qubits always agree. '
        'Think about what initial or final adjustment produces anti-correlation instead of correlation.',
    hints: [
      'To reach Ψ⁺=(|01⟩+|10⟩)/√2 from |00⟩, you need one qubit to be |1⟩ before the '
          'H+CNOT circuit. Apply X to one qubit first.',
      'X on Q1: |00⟩→|01⟩. H on Q0: (|0⟩+|1⟩)/√2 ⊗ |1⟩ = (|01⟩+|11⟩)/√2. '
          'CNOT(Q0→Q1): |01⟩→|01⟩ (Q0=0), |11⟩→|10⟩ (Q0=1, flip Q1). '
          'Result: (|01⟩+|10⟩)/√2 = Ψ⁺.',
    ],
    solutionExplanation:
        'X on Q1 flips it to |1⟩. H on Q0 creates superposition. '
        'CNOT(Q0→Q1) entangles: (|01⟩+|10⟩)/√2 = Ψ⁺. '
        'The four Bell states and their preparation circuits are: '
        'Φ⁺: H+CNOT from |00⟩; Φ⁻: H+CNOT+Z from |00⟩; '
        'Ψ⁺: X+H+CNOT from |00⟩; Ψ⁻: X+H+CNOT+Z from |00⟩.',
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
    title: 'Bell Φ⁻ from |10⟩',
    taskDescription: r"From \( |10\rangle \), create the Bell state \( |\Phi^-\rangle = (|00\rangle - |11\rangle)/\sqrt{2} \).",
    conceptIntro:
        'H|1⟩ = (|0⟩−|1⟩)/√2 = |−⟩ — when applied to a qubit that is already |1⟩, '
        'the Hadamard gate produces a superposition with a built-in minus sign. '
        'This negative sign in the initial superposition propagates differently through '
        'subsequent gates than the positive superposition H|0⟩ produces. '
        'Compare the starting state here to level 22 — notice what is different and reason '
        'about whether a simpler or different circuit is possible.',
    hints: [
      'From |10⟩, Q1=1 (bottom row). H on Q1 maps |1⟩ → (|0⟩−|1⟩)/√2 — '
          'note the minus sign! The state is now (|00⟩−|10⟩)/√2.',
      'CNOT(Q1→Q0) on (|00⟩−|10⟩)/√2: in the |10⟩ term Q1=1 (control), so Q0 flips 0→1 → |11⟩. '
          'Result: (|00⟩−|11⟩)/√2 = Φ⁻. '
          'Only two gates needed — the minus sign from H|1⟩ does the job.',
    ],
    solutionExplanation:
        'H on Q1 (which is |1⟩, the bottom qubit) gives (|0⟩−|1⟩)/√2. '
        'State: (|00⟩−|10⟩)/√2. '
        'CNOT(Q1→Q0): in |10⟩, Q1=1 (control) flips Q0 0→1 → |11⟩. Result: (|00⟩−|11⟩)/√2 = Φ⁻. '
        'Two solutions exist: H(Q1)+CNOT(Q1→Q0) in 2 gates, or X(Q1)+H(Q0)+CNOT(Q0→Q1)+Z(Q0) in 4 gates. '
        'The initial qubit state — |0⟩ or |1⟩ — determines the sign of the superposition after H.',
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
    title: 'Complete the SWAP',
    taskDescription: r"This circuit is pre-configured with the first CNOT of a qubit swap. Complete the swap of qubits 0 and 1, so \( |01\rangle \) becomes \( |10\rangle \).",
    conceptIntro:
        'A SWAP gate exchanges the states of two qubits and can be built from CNOT gates alone '
        '(as you discovered in level 28). Here the first CNOT of the decomposition is already pre-inserted. '
        'Your task is to complete the SWAP by adding only the remaining gates. '
        'Think back to the full SWAP decomposition you worked out before and identify '
        'which steps are still needed to finish the exchange.',
    hints: [
      'In the ket |01⟩, Q0 is the right-hand bit, so Q0=1 and Q1=0. '
          'The pre-inserted CNOT(Q0→Q1) therefore DOES trigger and flips Q1: 0→1 → |11⟩.',
      'From |11⟩, add CNOT(Q1→Q0): Q1=1 triggers, flipping Q0: 1→0 → |10⟩. '
          'That is the target — just one gate to add.',
    ],
    solutionExplanation:
        'In |01⟩, Q0 is the rightmost bit, so Q0=1 and Q1=0. '
        'Pre-inserted CNOT(Q0→Q1): Q0=1 triggers, flipping Q1: 0→1 → |11⟩. '
        'CNOT(Q1→Q0): Q1=1 triggers, flipping Q0: 1→0 → |10⟩. Done. '
        'The third CNOT of the full decomposition would be a no-op here (Q0=0 after the second step), '
        'so only one gate needs to be added.',
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
    ], // Target: |10⟩ — Solution: add CNOT(Q1→Q0) after the pre-inserted CNOT(Q0→Q1)
  ),
  // CNOT(2,0) + CNOT(2,1)
  ComposerLevel.fromBinaryString(
    title: 'Long-Range CNOT',
    taskDescription: r"From \( |001\rangle \), transform the state to \( |101\rangle \).",
    conceptIntro:
        'In a 3-qubit register CNOT can connect any two qubits — '
        'they do not need to be adjacent. '
        'Here Q2=1 is the only available control. '
        'Using it to flip Q0 (skipping Q1 entirely) is called a "long-range" CNOT. '
        'On real hardware non-adjacent CNOTs are compiled into a sequence of '
        'adjacent gates, but logically they work the same way.',
    hints: [
      'In |001⟩: Q0=0, Q1=0, Q2=1. Only Q2 is |1⟩ and can serve as a control. '
          'Which qubit needs to flip to reach |101⟩?',
      'Q0 must flip from 0→1. Use CNOT with Q2 as control and Q0 as target. '
          'Q2=1 → flip Q0: 0→1 → |101⟩. One gate is enough.',
    ],
    solutionExplanation:
        'CNOT(Q2→Q0)|001⟩ = |101⟩. '
        'Q2=1 is the control; Q0 flips: 0→1. Q1 is untouched. '
        'In the 8-entry state vector, |101⟩ is index 5. '
        'This long-range CNOT is the basic building block for '
        'multi-qubit fan-out and quantum error-correction circuits.',
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
    title: 'CNOT Fan-Out',
    taskDescription: r"Transform \( |010\rangle \) to \( |111\rangle \). This requires a careful sequence of gates.",
    conceptIntro:
        'CNOT "fans out" (copies) a |1⟩ value from a control qubit into a |0⟩ target qubit. '
        'Note: this copying only works for classical basis states — '
        'for superpositions, CNOT creates entanglement instead of copying. '
        'CNOT can only trigger a flip when its control is |1⟩; if the intended control is |0⟩, '
        'no flip will occur. Look at the initial state and plan the correct sequence '
        'to get every qubit into the required value.',
    hints: [
      'In |010⟩: Q0=0, Q1=1, Q2=0. Q1 is already |1⟩. '
          'You need Q0 and Q2 to also become |1⟩. '
          'Start by flipping Q0 with X.',
      'X on Q0: |010⟩ → |110⟩. '
          'Now Q0=1 can act as control: CNOT(Q0→Q2) flips Q2: 0→1 → |111⟩. '
          'Two gates, no Toffoli needed.',
    ],
    solutionExplanation:
        'X flips Q0: |010⟩ → |110⟩. '
        'CNOT(Q0→Q2): Q0=1 → Q2 flips: 0→1 → |111⟩. '
        'Q1 was already |1⟩ and is left untouched. '
        'This fan-out pattern — X to set a control, then CNOT to copy its value — '
        'appears in quantum adder circuits and quantum error correction encoders.',
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
    title: 'GHZ State Manipulation',
    taskDescription: r"This circuit is pre-configured to the GHZ state \( (|000\rangle + |111\rangle)/\sqrt{2} \). Transform this state to \( (|001\rangle + |110\rangle)/\sqrt{2} \).",
    conceptIntro:
        'The GHZ (Greenberger–Horne–Zeilinger) state (|000⟩+|111⟩)/√2 is '
        'maximally entangled across all three qubits. '
        'A striking property of maximally entangled states is that a local operation '
        'on a single qubit affects all terms of the superposition simultaneously — '
        'the qubits are perfectly correlated. '
        'Compare the target state term by term with the GHZ state: identify which bit position '
        'has changed in each term, and reason about which single-qubit operation causes that change.',
    hints: [
      'The GHZ state has exactly two terms: |000⟩ and |111⟩. '
          'The target (|001⟩+|110⟩)/√2 also has two terms, '
          'differing from the original in exactly one bit position per term.',
      'X on any single qubit flips that bit in both |000⟩ and |111⟩. '
          'Find the qubit position where "000"→"001" and "111"→"110" — '
          'the rightmost bit in the ket string changes, which is Q0 (top row in the circuit).',
    ],
    solutionExplanation:
        'X on Q0 (top row): |000⟩→|001⟩ and |111⟩→|110⟩. '
        'Result: (|001⟩+|110⟩)/√2. '
        'This demonstrates the all-or-nothing nature of GHZ entanglement: '
        'a single local X on Q0 flips the rightmost bit in every term simultaneously. '
        'GHZ states are used in quantum secret sharing and quantum communication protocols.',
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
    ], // Target: (1/sqrt(2))(|001> + |110>)
    // Solution: X on Q0
  ),
  // H(0) + H(1)
  ComposerLevel.fromBinaryString(
    title: 'Uniform 2-Qubit Superposition',
    taskDescription: r"From \( |00\rangle \), create a uniform superposition of all possible 2-qubit states: \( (|00\rangle + |01\rangle + |10\rangle + |11\rangle)/2 \).",
    conceptIntro:
        'A uniform superposition over all 2ⁿ basis states gives each state equal amplitude '
        'and equal measurement probability 1/2ⁿ. '
        'For n=2, the target (|00⟩+|01⟩+|10⟩+|11⟩)/2 spans all four basis states at once. '
        'This "quantum parallelism" initialisation is the first step in Grover\'s search '
        'and the quantum Fourier transform. '
        'Think about how to independently prepare each qubit in superposition '
        'so their combined state covers every basis string equally.',
    hints: [
      'H on one qubit creates superposition over 2 states. '
          'What happens when you apply H to both qubits independently?',
      'H on Q0 gives (|00⟩+|10⟩)/√2 (Q1 stays |0⟩). '
          'Then H on Q1 spreads each term: |x0⟩ → (|x0⟩+|x1⟩)/√2. '
          'All four basis states get amplitude 1/2. The order doesn\'t matter.',
    ],
    solutionExplanation:
        'H on Q0 then H on Q1 (or vice versa — they commute on different qubits). '
        'H⊗H|00⟩ = (|0⟩+|1⟩)/√2 ⊗ (|0⟩+|1⟩)/√2 = (|00⟩+|01⟩+|10⟩+|11⟩)/2. '
        'Each state has probability |1/2|² = 1/4. '
        'In general, n Hadamards on |0…0⟩ create a uniform superposition '
        'over all 2ⁿ bit strings — the starting state for most quantum search algorithms.',
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
    title: 'GHZ State with Phase',
    taskDescription: r"From \( |001\rangle \), transform the state to \( (|000\rangle - |111\rangle)/\sqrt{2} \).",
    conceptIntro:
        'The GHZ state (|000⟩+|111⟩)/√2 is a maximally entangled 3-qubit state. '
        'Building it requires creating a single-qubit superposition and then spreading '
        'the entanglement step by step to the remaining qubits. '
        'The target (|000⟩−|111⟩)/√2 is the "anti-GHZ" state — orthogonal to GHZ '
        'and used in quantum error correction. '
        'It differs from GHZ only by a relative sign between the two terms. '
        'Think about how to construct the GHZ state first, then how to introduce that sign change.',
    hints: [
      'First undo the |1⟩ in the initial state with X. '
          'Then build GHZ: H on one qubit to create superposition, '
          'followed by two CNOTs in a chain to spread entanglement to all three qubits.',
      'X→H(one qubit)→CNOT(Q0→Q1)→CNOT(Q1→Q2) gives (|000⟩+|111⟩)/√2. '
          'Now add Z on any qubit to flip the |111⟩ sign — '
          'all three qubits are |1⟩ in that term, so Z on any of them works.',
    ],
    solutionExplanation:
        'X clears the initial |1⟩. '
        'H creates superposition on one qubit. '
        'CNOT(Q0→Q1) then CNOT(Q1→Q2) cascade the entanglement: (|000⟩+|111⟩)/√2. '
        'Z on any qubit flips the sign of |111⟩ → (|000⟩−|111⟩)/√2. '
        'This "GHZ with a phase" state is one of the 8 maximally-entangled 3-qubit states. '
        'GHZ-class states form a complete, maximally-entangled basis for 3-qubit Hilbert '
        'space and appear in quantum secret sharing and quantum communication protocols.',
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
    title: 'CZ Gate — Controlled Phase',
    taskDescription: r"This is about Conditional Phase Shift (Shor's Principle Hint). From \( |00\rangle \), create a uniform superposition where the \( |11\rangle \) component has its phase flipped to \(-1\). The target state is \( (|00\rangle + |01\rangle + |10\rangle - |11\rangle)/2 \).",
    conceptIntro:
        'The Controlled-Z (CZ) gate applies a phase of −1 to |11⟩ and '
        'leaves all other basis states unchanged. '
        'Unlike CNOT which changes bit values, CZ only changes phases — '
        'it is a "phase oracle". '
        'CZ is symmetric: CZ(Q0,Q1) = CZ(Q1,Q0). '
        'Conditional phase shifts like CZ are central to '
        'Shor\'s algorithm and quantum phase estimation.',
    hints: [
      'First create the uniform superposition (|00⟩+|01⟩+|10⟩+|11⟩)/2 '
          'by applying H to both qubits.',
      'Then apply CZ directly — it flips only the |11⟩ phase. '
          'CZ is symmetric, so either qubit can be listed as control. '
          'Compare with level 29: the same target state was reached via H·CNOT·H '
          'because CZ = H(tgt)·CNOT·H(tgt).',
    ],
    solutionExplanation:
        'H⊗H gives (|00⟩+|01⟩+|10⟩+|11⟩)/2. '
        'CZ flips the phase of |11⟩: (|00⟩+|01⟩+|10⟩−|11⟩)/2. '
        'CZ is self-inverse (CZ²=I) and symmetric. '
        'This is the same target state as level 29, reached in fewer gates '
        'because CZ is available here directly. '
        'In Shor\'s algorithm, repeated controlled phase shifts accumulate phase '
        'information that the QFT then converts into a period.',
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
    title: 'Uncomputing CZ Entanglement',
    taskDescription: r"This circuit is pre-configured to an entangled state where the \( |11\rangle \) component has a negative phase. Your task is to transform this state back to \( |00\rangle \).",
    conceptIntro:
        'The pre-inserted H→H→CZ sequence has created the state (|00⟩+|01⟩+|10⟩−|11⟩)/2. '
        'To return to |00⟩, you must reverse the pre-inserted circuit. '
        'All three gates used are self-inverse, so each gate is its own undo operation. '
        'Apply the reversal principle: the undo of a sequence A→B→C is C→B→A — '
        'the same gates in the opposite order. '
        'Uncomputation of phase-entangled states is a key subroutine in Grover\'s oracle circuits.',
    hints: [
      'The pre-inserted H→H→CZ created the state with negative |11⟩ phase. '
          'To undo it, apply CZ first (it is self-inverse), then H on both qubits.',
      'CZ on (|00⟩+|01⟩+|10⟩−|11⟩)/2 restores the uniform superposition '
          '(|00⟩+|01⟩+|10⟩+|11⟩)/2. '
          'Then H on Q0 and H on Q1 collapse it back to |00⟩.',
    ],
    solutionExplanation:
        'CZ removes the −1 phase on |11⟩: → (|00⟩+|01⟩+|10⟩+|11⟩)/2. '
        'H on Q0: collapses the Q0 superposition. '
        'H on Q1: collapses the Q1 superposition. Final: |00⟩. '
        'Alternatively, use H·CNOT·H as the CZ decomposition, giving the same result. '
        'Total circuit: pre-inserted (H,H,CZ) + added (CZ,H,H) = identity.',
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
    title: 'Rx Rotation Gate',
    taskDescription: r"Transform the initial state \( |0\rangle \) to the 'plus' state \( |+\rangle \). This can be achieved with a single rotation gate.",
    conceptIntro:
        'Rotation gates rotate a qubit around a Bloch sphere axis by a specific angle θ. '
        'Rx(θ) rotates around the X-axis: Rx(θ)|0⟩ = cos(θ/2)|0⟩ − i·sin(θ/2)|1⟩. '
        'Ry(θ) rotates around the Y-axis: Ry(θ)|0⟩ = cos(θ/2)|0⟩ + sin(θ/2)|1⟩. '
        'The key difference: Rx introduces an imaginary phase factor on |1⟩, '
        'while Ry keeps all amplitudes real. '
        'Examine the target state — pay attention to both magnitudes and any imaginary components '
        'to identify the correct axis and angle.',
    hints: [
      'Both Rx(π/2) and Ry(π/2) produce equatorial states. '
          'Look at the target amplitudes: the |1⟩ component has a specific sign and phase.',
      'The target has amplitude 1/√2 on |0⟩ and −i/√2 on |1⟩. '
          'Rx(π/2)|0⟩ = cos(π/4)|0⟩ − i·sin(π/4)|1⟩ = (|0⟩−i|1⟩)/√2. '
          'That matches — use Rx(π/2).',
    ],
    solutionExplanation:
        'Rx(π/2)|0⟩ = (|0⟩−i|1⟩)/√2. '
        'The amplitude on |1⟩ is −i/√2, giving probability |−i/√2|²=1/2 — '
        'equal to |+⟩, but the phase of |1⟩ differs. '
        'Rx, Ry, Rz together can represent any single-qubit unitary. '
        'This is the Euler angle decomposition, fundamental to variational quantum circuits.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.x), Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2)],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(0, -sqrt1_2)],
    ], // Target: |+>
  ),
  ComposerLevel.fromBinaryString(
    title: 'Ry Rotation Gate',
    taskDescription: r"Rotate the initial state \( |0\rangle \) to a new state on the equatorial plane of the Bloch sphere. Try to find the correct rotation.",
    conceptIntro:
        'Ry(θ) rotates around the Y-axis of the Bloch sphere: '
        'Ry(θ)|0⟩ = cos(θ/2)|0⟩ + sin(θ/2)|1⟩. '
        'Unlike Rx, the Y-axis rotation keeps all amplitudes real — no imaginary phase on |1⟩. '
        'The target state has specific real amplitudes on both |0⟩ and |1⟩ — '
        'use the Ry formula to work out which angle θ produces equal magnitudes with no imaginary part.',
    hints: [
      'Compare the two available gates: Rx(π/4) and Ry(π/2). '
          'The target has both amplitudes real and equal — no imaginary part.',
      'Ry(θ)|0⟩ = cos(θ/2)|0⟩ + sin(θ/2)|1⟩. '
          'For equal real amplitudes, cos(θ/2) = sin(θ/2), so θ/2 = π/4, θ = π/2. '
          'Use Ry(π/2).',
    ],
    solutionExplanation:
        'Ry(π/2)|0⟩ = cos(π/4)|0⟩ + sin(π/4)|1⟩ = (|0⟩+|1⟩)/√2. '
        'Both amplitudes are real 1/√2 — no phase on |1⟩. '
        'Compare with level 40: Rx(π/2)|0⟩ = (|0⟩−i|1⟩)/√2 has a phase. '
        'Ry and Rx reach different equatorial points despite equal measurement probabilities.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4), Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2)],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(sqrt1_2, 0)],
    ], // Target: (1/sqrt(2))(|0> + i|1>)
  ),
  ComposerLevel.fromBinaryString(
    title: 'Rz — Phase Rotation',
    taskDescription: r"Apply a phase shift to the state \( |1\rangle \) to transform it to \( |i\rangle \). This requires an Rz gate.",
    conceptIntro:
        'Rz(θ) rotates around the Z-axis: Rz(θ)|0⟩ = e^(−iθ/2)|0⟩ and Rz(θ)|1⟩ = e^(iθ/2)|1⟩. '
        'Since |0⟩ and |1⟩ get opposite phases, Rz only creates a relative phase — '
        'it does not mix them. '
        'Z, S, and T are all special cases of Rz: '
        'Z = Rz(π), S = Rz(π/2), T = Rz(π/4) (up to global phase). '
        'Here you start in |1⟩ and need to rotate its phase by π/4.',
    hints: [
      'You only need to add a phase to |1⟩. Rz(θ)|1⟩ = e^(iθ/2)|1⟩. '
          'Look at the target amplitude on |1⟩ and work out what θ gives that phase.',
      'Target |1⟩ amplitude: (1+i)/√2 = e^(iπ/4). '
          'So e^(iθ/2) = e^(iπ/4) → θ/2 = π/4 → θ = π/2. '
          'Use Rz(π/2). This is equivalent to the S gate.',
    ],
    solutionExplanation:
        'Rz(π/2)|1⟩ = e^(iπ/4)|1⟩ = (cos(π/4)+i·sin(π/4))|1⟩ = (1+i)/√2·|1⟩. '
        'Rz(π/2) is the continuous-angle equivalent of the S gate (S = Rz(π/2) up to global phase). '
        'The Z-rotation family: T = Rz(π/4), S = Rz(π/2), Z = Rz(π). '
        'All add phase exclusively to the |1⟩ component without touching |0⟩.',
    numQubits: 1,
    initialQubitsStateString: "1",
    availableGates: [Gate.fromIdentifier(SelectedGateType.z), Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), Gate.fromIdentifier(SelectedGateType.ry)],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, sqrt1_2)],
    ], // Target: |i>
  ),
  ComposerLevel.fromBinaryString(
    title: 'Inverse Rotation',
    taskDescription: r"You start with a pre-configured superposition. Use a rotation gate to return to the \( |0\rangle \) state.",
    conceptIntro:
        'Every rotation gate has an inverse: Rx(−θ) = Rx(θ)†, Ry(−θ) = Ry(θ)†, Rz(−θ) = Rz(θ)†. '
        'Applying a rotation followed by its inverse cancels to the identity: R(θ)·R(−θ) = I. '
        'The pre-inserted Ry(π/2) has rotated the state away from |0⟩. '
        'Uncomputing rotations this way is central to quantum circuit optimization '
        'and ancilla qubit reset.',
    hints: [
      'The pre-inserted Ry(π/2) produced (|0⟩+|1⟩)/√2. '
          'You need to undo this rotation to return to |0⟩.',
      'The inverse of Ry(θ) is Ry(−θ). '
          'Apply Ry(−π/2): Ry(−π/2)·Ry(π/2)|0⟩ = Ry(0)|0⟩ = |0⟩. '
          'The negative-angle gate is in your toolbar.',
    ],
    solutionExplanation:
        'Ry(π/2)|0⟩ = (|0⟩+|1⟩)/√2 (pre-inserted). '
        'Ry(−π/2) reverses the rotation: '
        'Ry(−π/2)·(|0⟩+|1⟩)/√2 = |0⟩. '
        'Net rotation angle: π/2 + (−π/2) = 0. '
        'This cancellation principle generalises: for any rotation angle θ, '
        'applying Ry(θ) then Ry(−θ) is a no-op.',
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
    title: 'Composing Rx and Ry',
    taskDescription: r"Combine two different rotation gates to get a specific final state. The first rotation is given.",
    conceptIntro:
        'Combining rotations around different axes creates states unreachable by either axis alone. '
        'The Bloch sphere shows why: a single axis can only reach a circle of states, '
        'but two axes together can reach any point. '
        'This is the basis of the Euler angle decomposition: '
        'any single-qubit gate U = Rz(α)·Ry(β)·Rz(γ) — '
        'a universal building block for variational quantum circuits.',
    hints: [
      'The pre-inserted Rx(π/2) has produced (|0⟩−i|1⟩)/√2. '
          'The target [0.5+0.5i, 0.5−0.5i] has equal-magnitude amplitudes '
          'with a specific mix of real and imaginary parts.',
      'Apply Ry(π/2) after the pre-inserted Rx(π/2). '
          'The Y-rotation mixes the real and imaginary parts from the Rx result, '
          'yielding exactly [0.5+0.5i, 0.5−0.5i].',
    ],
    solutionExplanation:
        'Rx(π/2)|0⟩ = (|0⟩−i|1⟩)/√2. '
        'Ry(π/2) on (|0⟩−i|1⟩)/√2: the Y-rotation mixes components, '
        'giving [0.5+0.5i, 0.5−0.5i]. '
        'Each amplitude has magnitude 1/√2 (50/50 measurement probability), '
        'but the Bloch sphere point and relative phase differ from any single-axis result. '
        'This is the power of multi-axis composition.',
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
    title: 'Rz on an Entangled State',
    taskDescription: r"Use a rotation gate to apply a very specific phase shift on a multi-qubit state. The initial state is a superposition.",
    conceptIntro:
        'Rotation gates can be applied to individual qubits of an entangled state. '
        'Rz(θ) on Q0 of Φ⁺=(|00⟩+|11⟩)/√2 adds e^(−iθ/2) when Q0=0 '
        'and e^(iθ/2) when Q0=1 — introducing a relative phase between the two entangled terms. '
        'This "phase kickback" is the core mechanism of quantum phase estimation '
        'and the quantum Fourier transform.',
    hints: [
      'The pre-inserted H+CNOT created Φ⁺=(|00⟩+|11⟩)/√2. '
          'Rz(θ) on Q0 adds phase e^(−iθ/2) to the |00⟩ component '
          'and e^(iθ/2) to the |11⟩ component.',
      'Target: |00⟩ gets phase e^(−iπ/8) and |11⟩ gets e^(iπ/8). '
          'So e^(iθ/2) = e^(iπ/8) → θ/2 = π/8 → θ = π/4. '
          'Apply Rz(π/4) on Q0.',
    ],
    solutionExplanation:
        'Rz(π/4) on Q0 applied to Φ⁺=(|00⟩+|11⟩)/√2: '
        '|00⟩ → e^(−iπ/8)|00⟩, |11⟩ → e^(iπ/8)|11⟩. '
        'Result: (e^(−iπ/8)|00⟩ + e^(iπ/8)|11⟩)/√2 — a "phased Bell state". '
        'The entanglement is preserved but a relative phase π/4 has been introduced. '
        'In quantum phase estimation, repeated Rz rotations accumulate phase '
        'that encodes eigenvalue information.',
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
    title: 'Precise Bloch Sphere Navigation',
    taskDescription: r"Transform the initial state to a specific point on the Bloch sphere. This requires precise rotations.",
    conceptIntro:
        'Any point on the Bloch sphere can be reached with at most two rotations around different axes — '
        'the Euler angle decomposition. '
        'The target state has equal-magnitude amplitudes with a specific complex phase: '
        'it lives on the equatorial plane but offset from the X and Y axes. '
        'Two rotations are needed to reach it from |0⟩: one to create the superposition '
        'and another to introduce the right phase mix. '
        'Inspect the available gates and think about what each axis of rotation contributes.',
    hints: [
      'The target has both amplitudes equal in magnitude (1/√2) with a specific phase. '
          'Start with Rx(π/2) to create the superposition (|0⟩ − i|1⟩)/√2, '
          'then Ry(π/4) rotates the amplitudes, '
          'and finally Rz(π/2) equalises the phases.',
      'Rx(π/2)|0⟩ = (|0⟩ − i|1⟩)/√2. '
          'Ry(π/4) then gives amplitudes e^(iπ/8)/√2 and −i·e^(iπ/8)/√2. '
          'Rz(π/2) applies phases e^(−iπ/4) and e^(iπ/4): '
          'both components become e^(−iπ/8)/√2. '
          'Three gates: Rx(π/2) → Ry(π/4) → Rz(π/2).',
    ],
    solutionExplanation:
        'Rx(π/2)|0⟩ = (|0⟩ − i|1⟩)/√2. '
        'Ry(π/4) rotates further: component 0 → e^(iπ/8)/√2, component 1 → −i·e^(iπ/8)/√2. '
        'Rz(π/2) applies phases e^(−iπ/4) and e^(iπ/4), making both components equal: '
        'e^(−iπ/8)/√2 = (cos(π/8) − i·sin(π/8))/√2. '
        'The three-gate sequence Rx → Ry → Rz navigates the Bloch sphere along three axes; '
        'any single-qubit gate has an Euler decomposition Rz(α)·Ry(β)·Rz(γ), '
        'and Rx → Ry → Rz here is an alternative three-axis factorisation for this target. '
        'VQE and QAOA circuits use exactly this parameterised gate structure.',
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
    conceptIntro:
        'You have applied the Hadamard gate many times. '
        'Let\'s check the concept behind it.\n\n'
        'Classical bits are always exactly 0 or 1. '
        'Qubits can exist in a combination of both states at once — '
        'described by complex probability amplitudes — until they are measured.',
    options: [
      'Always |0⟩ when measured',
      'In both |0⟩ and |1⟩ simultaneously — collapsing to one upon measurement with some probability',
      'A qubit permanently stuck between two classical values',
      'The same as a classical bit that is randomly 0 or 1',
    ],
    correctOptionIndex: 1,
    hints: [
      'Think about what makes quantum computing fundamentally different from classical computing.',
      'A qubit carries a complex amplitude for |0⟩ and a separate amplitude for |1⟩ — '
          'both are "real" until measurement forces a definite outcome.',
      'A random classical bit is determined before you look at it; '
          'a superposed qubit is genuinely in both states until you measure — '
          'that is why option 4 is wrong.',
    ],
    solutionExplanation:
        'Superposition means the qubit has a probability amplitude for each basis state. '
        'The Born rule says the probability of each outcome equals the squared magnitude '
        'of its amplitude. Only measurement collapses the superposition — '
        'before that, the qubit is truly in both states at once.',
  ),

  // Index 47 — Level 48
  McqLevel(
    title: 'What is Entanglement?',
    taskDescription: 'Two qubits are entangled when...',
    conceptIntro:
        'You have created and disentangled Bell states. What makes entanglement special?\n\n'
        'A "product state" is one where each qubit can be described independently. '
        'For example |0⟩⊗|1⟩ = |01⟩ is a product state — qubit A is |0⟩ and qubit B is |1⟩. '
        'An entangled state is one where no such separation is possible.',
    options: [
      'Both qubits are in state |0⟩',
      'They are physically close to each other',
      'Their joint state cannot be written as a product of two individual qubit states',
      'One qubit controls the other via a wire',
    ],
    correctOptionIndex: 2,
    hints: [
      'Try to write the Bell state (|00⟩+|11⟩)/√2 as (a|0⟩+b|1⟩)⊗(c|0⟩+d|1⟩) and see what goes wrong.',
      'Expanding the product gives ac|00⟩ + ad|01⟩ + bc|10⟩ + bd|11⟩. '
          'To match the Bell state we need ad = 0 and bc = 0, '
          'but then ac and bd can\'t both be non-zero at the same time.',
      'Physical proximity has nothing to do with entanglement — '
          'entangled particles can be light-years apart and still share quantum correlations.',
    ],
    solutionExplanation:
        'Entanglement is a purely quantum correlation. For the Bell state (|00⟩+|11⟩)/√2, '
        'there is no way to write it as (a|0⟩+b|1⟩)⊗(c|0⟩+d|1⟩). '
        'Measuring one qubit instantly tells you the state of the other — '
        'this is the defining feature that Einstein called "spooky action at a distance".',
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
    hints: [
      'There is nothing to solve here — just observe. '
          'Press Measure and watch the bar chart update with each outcome.',
      'The H gate gives both |0⟩ and |1⟩ the same amplitude 1/√2. '
          'What does the Born rule say about the probability of each outcome?',
      '|1/√2|² = 0.5, so you expect roughly 50 % |0⟩ and 50 % |1⟩. '
          'With 20 measurements you won\'t get exactly 10 each — randomness is real!',
    ],
    solutionExplanation:
        'You should see roughly 50 % |0⟩ and 50 % |1⟩. '
        'The H gate gives both amplitudes equal magnitude 1/√2, so |amplitude|² = 0.5 for each. '
        'The more measurements you take, the closer the histogram gets to the true 50/50 split.',
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
    hints: [
      'Press Measure several times and note which two-qubit outcomes appear in the histogram.',
      'The Bell state has zero amplitude for |01⟩ and |10⟩. '
          'The Born rule says zero amplitude means zero probability — '
          'those outcomes can never occur.',
      'Compare with two independent 50/50 coins: you\'d sometimes get "heads-tails" or "tails-heads". '
          'Entanglement forbids those mixed outcomes — both qubits are always perfectly correlated.',
    ],
    solutionExplanation:
        'The Bell state has zero amplitude for |01⟩ and |10⟩, so you can never measure those. '
        'The two qubits are entangled — their outcomes are always correlated. '
        'Each outcome |00⟩ and |11⟩ has probability |1/√2|² = 0.5.',
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
    hints: [
      'Start with |0⟩ and apply H. The H gate maps each basis state to an equal superposition.',
      'H|0⟩ creates equal amplitudes for |0⟩ and |1⟩, both with a positive sign.',
      'The "plus" state |+⟩ = (|0⟩+|1⟩)/√2 has equal positive amplitudes. '
          'The "minus" state |−⟩ = (|0⟩−|1⟩)/√2 has one negative amplitude — '
          'that only appears when H acts on |1⟩.',
    ],
    solutionExplanation:
        'H|0⟩ = (|0⟩+|1⟩)/√2 = |+⟩. The Hadamard maps |0⟩ to the "plus" state '
        'and |1⟩ to the "minus" state. '
        'The key difference is the sign of the |1⟩ amplitude: + for H|0⟩, − for H|1⟩.',
  ),

  // Index 53 — Level 54
  CircuitReadingLevel(
    title: 'Read: Bell State',
    taskDescription:
        r'The circuit applies H to qubit 0, then CNOT(0→1), starting from \( |00\rangle \). What is the output?',
    conceptIntro:
        'You have built this exact circuit before in the Entanglement category. '
        'Now read it analytically — trace the state through each gate step by step '
        'without touching any controls.\n\n'
        'This skill is essential for understanding larger quantum algorithms: '
        'you need to be able to read a circuit diagram and predict its output at a glance.',
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