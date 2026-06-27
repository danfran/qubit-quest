import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/qq_levels_category.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/qq_level.dart';

Complex get negOne => Complex(-1.0, 0.0); // -1
Complex get negI => Complex(0.0, -1.0); // -i

final List<QQLevel> _authoredQQLevels = [
  // X
  ComposerLevel.fromBinaryString(
    title: 'Bit Flip',
    taskDescription:
        r"Your first quantum challenge! Apply a gate to transform \( |0\rangle \) to \( |1\rangle \).",
    targetStateExpression: "|1⟩",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()]
    ], // Target: |1> state
  ),
  // Z
  ComposerLevel.fromBinaryString(
    title: 'Phase Flip',
    taskDescription:
        r"Let's change now only the phase of \( |1\rangle \) without flipping the bit. Transform \( |1\rangle \) to \( -|1\rangle \).",
    targetStateLabel: "-|1⟩",
    targetStateExpression: "-|1⟩",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [negOne]
    ], // Target: |1> state
  ),
  // Y
  ComposerLevel.fromBinaryString(
    title: 'Bit & Phase Flip',
    taskDescription:
        r"Let's change now the phase and flipping the bit from \( |1\rangle \) to \( |0\rangle \).",
    targetStateLabel: "-i|0⟩",
    targetStateExpression: "-i|0⟩",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
    solutionFinalVector: [
      [negI],
      [Complex.zero()]
    ], // Target: |1> state
  ),
  // Y
  ComposerLevel.fromBinaryString(
    title: 'The i-State',
    taskDescription:
        r"From \( |0\rangle \), reach \( |1\rangle \) with a phase of \( i \). This state is \( |i\rangle \).",
    targetStateLabel: "|i⟩",
    targetStateExpression: "|i⟩ = i|1⟩",
    conceptIntro: 'A quantum state can have any complex amplitude. '
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.i()]
    ], // Target: |i> state (Y|0> = i|1>)
  ),
  // X + Z + X
  ComposerLevel.fromBinaryString(
    // 5
    title: 'Phase Sandwich',
    taskDescription:
        r"Starting from \( |0\rangle \), achieve \( -|0\rangle \).",
    targetStateLabel: "-|0⟩",
    targetStateExpression: "-|0⟩",
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
    solutionExplanation: 'XZX|0⟩ = −|0⟩. '
        'Step by step: X|0⟩ = |1⟩, then Z|1⟩ = −|1⟩, then X(−|1⟩) = −|0⟩. '
        'This is the canonical example of gate composition and the "conjugation" pattern: '
        'UGU† applies gate G in the basis defined by U.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
    solutionFinalVector: [
      [negOne],
      [Complex.zero()]
    ], // Target: -|0> state (e.g., XZX)
  ),
  // H
  ComposerLevel.fromBinaryString(
    title: 'Superposition',
    taskDescription:
        r"Create a superposition! Turn \( |0\rangle \) into \( |+\rangle \).",
    targetStateLabel: "|+⟩",
    targetStateExpression: "|+⟩ = (|0⟩ + |1⟩)/√2",
    conceptIntro: 'Superposition is a defining feature of quantum computing. '
        'Unlike a classical bit that is always exactly 0 or 1, a qubit can exist in a '
        'combination of both states at once — described by complex probability amplitudes. '
        'When you measure a qubit in superposition, the outcome is probabilistic: '
        'the chance of each result equals the squared magnitude of its amplitude (Born rule: P = |amplitude|²). '
        'The notation |+⟩ is the standard label for the equal-weight superposition that is your target here.',
    hints: [
      'There is exactly one gate in your toolbar that creates an equal superposition from a basis state.',
      'It is the H (Hadamard) gate. H|0⟩ = (|0⟩+|1⟩)/√2 = |+⟩.',
    ],
    solutionExplanation: 'H|0⟩ = (|0⟩+|1⟩)/√2 = |+⟩. '
        'Both amplitudes are 1/√2, so |1/√2|² = 0.5 — a 50% chance of measuring either outcome. '
        'H is its own inverse: H² = I, so applying H twice returns to |0⟩.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
    solutionFinalVector: [
      [Complex(sqrt1_2)],
      [Complex(sqrt1_2)]
    ], // Target: |+> state
  ),
  // H + T
  ComposerLevel.fromBinaryString(
    title: 'T Gate Phase',
    taskDescription:
        r"You're at \( |0\rangle \). Apply gates to reach a state where the \( |1\rangle \) amplitude has a phase of \( e^{i\pi/4} \). This is \( (|0\rangle + e^{i\pi/4}|1\rangle)/\sqrt{2} \).",
    targetStateLabel: "T|+⟩",
    targetStateExpression: "T|+⟩ = (|0⟩ + e^{iπ/4}|1⟩)/√2",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.t),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
    solutionFinalVector: [
      [Complex(sqrt1_2)],
      [Complex(0.5, 0.5)]
    ], // Target: |+> state
  ),
  // H + S
  ComposerLevel.fromBinaryString(
    title: 'S Gate — 90° Phase',
    taskDescription:
        r"Transform the initial state of the qubit from \( |0\rangle \) to the target state \( |+i\rangle = (|0\rangle + |i\rangle)/\sqrt{2} \).",
    targetStateLabel: "|+i⟩",
    targetStateExpression: "|+i⟩ = (|0⟩ + i|1⟩)/√2",
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
    solutionExplanation: 'H|0⟩ = (|0⟩+|1⟩)/√2. '
        'S then rotates |1⟩ by 90°: S(|0⟩+|1⟩)/√2 = (|0⟩+i|1⟩)/√2 = |+i⟩. '
        'This state is also called |R⟩ (right circular polarisation) on the Bloch sphere.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.s),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
    solutionFinalVector: [
      [Complex(sqrt1_2)],
      [Complex(0, sqrt1_2)]
    ], // Target: |+> state
  ),
  // H + Z
  ComposerLevel.fromBinaryString(
    title: 'The Minus State',
    taskDescription: r"Transform \( |+\rangle \) to \( |-\rangle \).",
    targetStateLabel: "|-⟩",
    targetStateExpression: "|-⟩ = (|0⟩ - |1⟩)/√2",
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
    solutionExplanation: 'H|0⟩ = (|0⟩+|1⟩)/√2 = |+⟩. '
        'Z then flips the sign of |1⟩: Z|+⟩ = (|0⟩−|1⟩)/√2 = |−⟩. '
        '|+⟩ and |−⟩ are called the Hadamard basis (or X-basis) states — they are the eigenstates of the X gate.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.x)
    ],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(-sqrt1_2, 0)]
    ], // Target: |-> state (H then Z)
  ),
  // H(1) + X(0)
  ComposerLevel.fromBinaryString(
    // 10
    title: '2-Qubit Product State',
    taskDescription:
        r"From \( |00\rangle \), create the product state \( |+\rangle \otimes |1\rangle = (|01\rangle + |11\rangle)/\sqrt{2} \).",
    targetStateLabel: "|+⟩⊗|1⟩",
    targetStateExpression: "|+⟩⊗|1⟩ = (|01⟩ + |11⟩)/√2",
    conceptIntro: 'Two-qubit systems are described by tensor products. '
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
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
    taskDescription:
        r"From \( |+\rangle \), achieve \( |-i\rangle = (|0\rangle - i|1\rangle)/\sqrt{2} \).",
    targetStateLabel: "|-i⟩",
    targetStateExpression: "|-i⟩ = (|0⟩ - i|1⟩)/√2",
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
    solutionExplanation: 'H|0⟩ = (|0⟩+|1⟩)/√2. '
        'Z flips |1⟩: (|0⟩−|1⟩)/√2. '
        'S multiplies |1⟩ by i: (|0⟩ − i|1⟩)/√2 = |-i⟩. '
        '|-i⟩ is also called the |L⟩ (left circular) state on the Bloch sphere.',
    numQubits: 1,
    initialQubitsStateString: "0", // Requires H and ZS or YS or something
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.s),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(0, -sqrt1_2)]
    ], // Target: |-i> state (e.g., HZ then S)
  ),
  // (H + S + Z) + S + H + X
  ComposerLevel.fromBinaryString(
    title: 'Uncomputing a Phase State',
    taskDescription:
        r"You're at \( (|0\rangle - i|1\rangle)/\sqrt{2} \). Transform this state back to \( |1\rangle \).",
    targetStateExpression: "|1⟩",
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
    initialQubitsStateString:
        "0", // User must reach the initial state first, then transform.
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.s),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()]
    ], // Target: |1> state (e.g., first create initial state with H S Z, then apply S H X)
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.s), 1, 0,
          isDeletable: false);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 2, 0,
          isDeletable: false);
    },
  ),
  // H + S + T + Z
  ComposerLevel.fromBinaryString(
    title: 'T† — Inverse Phase Gate',
    taskDescription:
        r"From \( |0\rangle \), reach \( (|0\rangle + e^{-i\pi/4}|1\rangle)/\sqrt{2} \).",
    targetStateLabel: "T†|+⟩",
    targetStateExpression: "T†|+⟩ = (|0⟩ + e^{-iπ/4}|1⟩)/√2",
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
    solutionExplanation: 'H gives (|0⟩+|1⟩)/√2. '
        'T adds phase +π/4 → e^(iπ/4). '
        'S adds +π/2 → e^(i3π/4). '
        'Z adds +π → e^(i7π/4) = e^(−iπ/4). '
        'Final state: (|0⟩ + e^(−iπ/4)|1⟩)/√2. '
        'This is exactly what T†|+⟩ produces — constructed from T, S, Z.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.t),
      Gate.fromIdentifier(SelectedGateType.s),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(0.5, -0.5)]
    ], // Target: HZ T |0> (HT then Z) or (H then T.conjugate())
  ),
  // CX(0,1)
  ComposerLevel.fromBinaryString(
    title: 'CNOT Gate',
    taskDescription:
        r"From \( |10\rangle \), create a circuit where Qubit 1 will 'mirror' the state of Qubit 0. The final state should be \( |11\rangle \).",
    targetStateExpression: "|11⟩",
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
    solutionExplanation: 'CNOT(Q0→Q1)|10⟩ = |11⟩. '
        'Q0=1 triggers the flip: Q1 goes from 0 to 1. '
        'Equivalently: Q1_new = Q1 ⊕ Q0 = 0 ⊕ 1 = 1. '
        'CNOT combined with single-qubit gates forms a universal gate set for quantum computing.',
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ], // Target: |00>
  ),
  // CX(1,0)
  ComposerLevel.fromBinaryString(
    // 15
    title: 'CNOT: Swapping Control & Target',
    taskDescription: r"Transform \( |01\rangle \) to \( |11\rangle \).",
    targetStateExpression: "|11⟩",
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
    solutionExplanation: 'CNOT(Q1→Q0)|01⟩ = |11⟩. '
        'Q1=1 is the control, so Q0 flips: 0→1. '
        'Compare with level 14 where the roles were reversed. '
        'Note: CNOT(Q0→Q1) on |01⟩ would give |01⟩ unchanged (Q0=0 does not trigger).',
    numQubits: 2,
    initialQubitsStateString: "01",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
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
    taskDescription:
        r"Explore 3 qubits! Transform \( |101\rangle \) to \( |100\rangle \).",
    targetStateExpression: "|100⟩",
    conceptIntro:
        'CNOT can connect any two qubits in a multi-qubit register — they do not need to be adjacent. '
        'A 3-qubit system has a state vector with 2³=8 entries. '
        'Here |101⟩ means Q0=1, Q1=0, Q2=1. '
        'Applying CNOT to non-adjacent qubits is a key building block for multi-qubit algorithms.',
    hints: [
      'Q0=1 and Q2=1 in |101⟩. You want to flip Q2 from 1 to 0. Which qubit is active enough to be the control?',
      'Use CNOT with Q0 as control and Q2 as target. Q0=1 triggers the flip: Q2 goes 1→0, giving |100⟩.',
    ],
    solutionExplanation: 'CNOT(Q0→Q2)|101⟩ = |100⟩. '
        'Q0=1 is the control, so Q2 flips: 1→0. Q1 is untouched. '
        'In the 8-entry state vector (|000⟩…|111⟩), |100⟩ is index 4 (big-endian). '
        'This level shows that CNOT works over any qubit distance.',
    numQubits: 3,
    initialQubitsStateString: "101", // |000> state
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
    solutionFinalVector: [
      // CNOT(Q0, Q2) applied to |000> results in |000>
      [Complex.zero()], [Complex.zero()], [Complex.zero()], [Complex.zero()],
      [Complex.one()], [Complex.zero()], [Complex.zero()], [Complex.zero()],
    ],
  ),
  // CX(0,1) + X(0)
  ComposerLevel.fromBinaryString(
    title: 'Uncomputing with CNOT',
    taskDescription:
        r"From \( |11\rangle \), transform the state to \( |00\rangle \).",
    targetStateExpression: "|00⟩",
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
    solutionExplanation: 'CNOT(Q0→Q1)|11⟩ = |10⟩ (Q0=1 flips Q1: 1→0). '
        'X on Q0: |10⟩ → |00⟩. '
        'Two gates are sufficient. Note the alternative order does NOT work: '
        'X on Q0 first gives |01⟩, then CNOT(Q0→Q1) leaves it as |01⟩ (Q0=0, condition never triggers — wrong!). '
        'So CNOT first is the correct order here.',
    numQubits: 2,
    initialQubitsStateString: "11",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
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
    targetStateExpression: "|111⟩",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.ccnot),
      Gate.fromIdentifier(SelectedGateType.z),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ],
  ),
  // CCX(0,1,2)
  ComposerLevel.fromBinaryString(
    title: 'Toffoli: Choose Your Controls',
    taskDescription:
        r"From \( |011\rangle \), transform the state to \( |111\rangle \).",
    targetStateExpression: "|111⟩",
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
    solutionExplanation: 'CCX(ctrl:Q1,Q2; target:Q0)|011⟩ = |111⟩. '
        'Q1=1 AND Q2=1 → Q0 flips: 0→1. '
        'Compare with level 18 (controls Q0,Q2; target Q1) — same gate type, different qubit assignment. '
        'Choosing controls flexibly is essential for implementing quantum arithmetic circuits.',
    numQubits: 3,
    initialQubitsStateString: "011",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.ccnot),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
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
  ComposerLevel.fromBinaryString(
    // LEVEL 20
    title: 'Toffoli Self-Inverse',
    taskDescription:
        r"You are given a 3-qubit circuit already in the state \( |111\rangle \). Transform this state back to \( |110\rangle \).",
    targetStateExpression: "|110⟩",
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
      circuit.insertTriplePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.ccnot), 0, 0, 1, 2,
          isDeletable: false);
    },
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.ccnot),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
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
    taskDescription:
        r"From \( |010\rangle \), transform the state to \( |111\rangle \).",
    targetStateExpression: "|111⟩",
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
    solutionExplanation: 'X flips Q0: |010⟩ → |110⟩. '
        'CCX(ctrl:Q0,Q1; target:Q2): Q0∧Q1 = 1∧1 = 1, so Q2 flips: 0→1. '
        'Result: |111⟩. '
        'This is the quantum AND circuit: Q2 stores Q0 AND Q1, '
        'while Q0 and Q1 are left unchanged (reversibility).',
    numQubits: 3,
    initialQubitsStateString: "010",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.ccnot),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
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
    taskDescription:
        r"Entangle two qubits! Create the Bell state \( |00\rangle + |11\rangle\).",
    targetStateLabel: "|Φ⁺⟩",
    targetStateExpression: "|Φ⁺⟩ = (|00⟩ + |11⟩)/√2",
    conceptIntro: 'Entanglement is the defining feature of quantum mechanics. '
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
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
    taskDescription:
        r"From \( |01\rangle \), create the Bell state \( |\Psi^+\rangle = (|01\rangle + |10\rangle)/\sqrt{2} \).",
    targetStateLabel: "|Ψ⁺⟩",
    targetStateExpression: "|Ψ⁺⟩ = (|01⟩ + |10⟩)/√2",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.x)
    ],
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
    taskDescription:
        r"Time for disentangling Bell State. Can you reverse the process to get back to \( |00\rangle \)?",
    targetStateExpression: "|00⟩",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.cnot)
    ],
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0,
          isDeletable: false);
    },
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |00>
  ),
  // H + CX + Z(1)
  ComposerLevel.fromBinaryString(
    // 25
    title: 'Bell State Ψ⁻',
    taskDescription:
        r"From \( |10\rangle \), create the Bell state \( |\Psi^-\rangle = (|01\rangle - |10\rangle)/\sqrt{2} \).",
    targetStateLabel: "|Ψ⁻⟩",
    targetStateExpression: "|Ψ⁻⟩ = (|01⟩ - |10⟩)/√2",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
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
    taskDescription:
        r"From \( |00\rangle \), prepare the Bell state \( |\Phi^-\rangle = (|00\rangle - |11\rangle)/\sqrt{2} \). You need only one solution although it can have 2 solutions potenially, due to entanglement.",
    targetStateLabel: "|Φ⁻⟩",
    targetStateExpression: "|Φ⁻⟩ = (|00⟩ - |11⟩)/√2",
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
    solutionExplanation: 'H+CNOT from |00⟩ gives Φ⁺=(|00⟩+|11⟩)/√2. '
        'Z on Q0 flips the |11⟩ sign (Q0=1): (|00⟩−|11⟩)/√2 = Φ⁻. '
        'Alternatively Z on Q1 achieves the same result — '
        'both are valid because in an entangled state local operations can have global effects.',
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.s),
      Gate.fromIdentifier(SelectedGateType.t)
    ], // Wide range of gates
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
    taskDescription:
        r"This circuit is pre-configured. Your task is to transform this state back to \( |00\rangle \).",
    targetStateExpression: "|00⟩",
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
    solutionExplanation: 'Z on Q0: Φ⁻ → Φ⁺. '
        'CNOT(Q0→Q1): Φ⁺ → (|00⟩+|10⟩)/√2. '
        'H on Q0: |+⟩ → |0⟩. Final: |00⟩. '
        'Total: Z→CNOT→H — the exact reverse of the pre-inserted H→CNOT→Z. '
        'Uncomputation is essential in quantum algorithms to reset ancilla qubits without measurement.',
    numQubits: 2,
    initialQubitsStateString: "00", // The simulation starts from |00>
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0,
          isDeletable: false);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 2, 0,
          isDeletable: false);
    },
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.x)
    ],
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
    taskDescription:
        r"From \( |10\rangle \), swap the states of the two qubits to achieve \( |01\rangle \). This can be done using only CX gates.",
    targetStateExpression: "|01⟩",
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
    solutionExplanation: 'CNOT(Q0→Q1)|10⟩=|11⟩. CNOT(Q1→Q0)|11⟩=|01⟩. '
        'The third CNOT(Q0→Q1) leaves |01⟩ unchanged (Q0=0). '
        'The general SWAP identity SWAP = CNOT(0→1)·CNOT(1→0)·CNOT(0→1) '
        'works for any input, including superpositions — '
        'this is how SWAP is implemented in real quantum hardware.',
    numQubits: 2,
    initialQubitsStateString: "10",
    availableGates: [Gate.fromIdentifier(SelectedGateType.cnot)], // Only CNOTs
    validationMode: ValidationMode.unitary,
    targetUnitary: [
      [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
      [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
      [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
      [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
    ],
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
    taskDescription:
        r"From \( |00\rangle \), flip the phase of \( |11\rangle \).",
    targetStateLabel: "CZ|++⟩",
    targetStateExpression: "CZ|++⟩ = (|00⟩ + |01⟩ + |10⟩ - |11⟩)/2",
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
    solutionExplanation: 'H on both qubits gives (|00⟩+|01⟩+|10⟩+|11⟩)/2. '
        'The decomposition CZ = H(tgt)·CNOT·H(tgt) then flips only |11⟩. '
        'The explicit decomposition CZ = H(Q1)·CNOT·H(Q1), applied after the uniform '
        'superposition H(Q0)·H(Q1), gives a 5-gate sequence that simplifies (H·H=I) '
        'to: H(Q0), CNOT, H(Q1) from |00⟩. '
        'Result: (|00⟩+|01⟩+|10⟩−|11⟩)/2. '
        'The CZ decomposition via H·CNOT·H is fundamental in quantum computing.',
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
    solutionFinalVector: [
      [Complex(0.5, 0)], // Amplitude for |00>
      [Complex(0.5, 0)], // Amplitude for |01>
      [Complex(0.5, 0)], // Amplitude for |10>
      [Complex(-0.5, 0)], // Amplitude for |11> (phase flipped)
    ], // Target: (1/2)(|00> + |01> + |10> - |11>)
  ),
  // H(0) + X(1) + CX(0,1)
  ComposerLevel.fromBinaryString(
    title: 'Bell Ψ⁺ from |00⟩',
    taskDescription:
        r"From \( |00\rangle \), create the Bell state \( |\Psi^+\rangle = (|01\rangle + |10\rangle)/\sqrt{2} \).",
    targetStateLabel: "|Ψ⁺⟩",
    targetStateExpression: "|Ψ⁺⟩ = (|01⟩ + |10⟩)/√2",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.cnot)
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, 0)],
      [Complex(sqrt1_2, 0)],
      [Complex.zero()],
    ], // Target: (1/sqrt(2))|01> + (1/sqrt(2))|10> (Psi+ Bell state)
  ),
  // X(1) + H(0) + CX(0,1) + Z(0)
  ComposerLevel.fromBinaryString(
    // multiple solutions, for example H(0) + CX(0,1) + H(0) + H(1)
    title: 'Bell Φ⁻ from |10⟩',
    taskDescription:
        r"From \( |10\rangle \), create the Bell state \( |\Phi^-\rangle = (|00\rangle - |11\rangle)/\sqrt{2} \).",
    targetStateLabel: "|Φ⁻⟩",
    targetStateExpression: "|Φ⁻⟩ = (|00⟩ - |11⟩)/√2",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
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
    taskDescription:
        r"This circuit is pre-configured with the first CNOT of a qubit swap. Complete the swap of qubits 0 and 1, so \( |01\rangle \) becomes \( |10\rangle \).",
    targetStateExpression: "|10⟩",
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
    solutionExplanation: 'In |01⟩, Q0 is the rightmost bit, so Q0=1 and Q1=0. '
        'Pre-inserted CNOT(Q0→Q1): Q0=1 triggers, flipping Q1: 0→1 → |11⟩. '
        'CNOT(Q1→Q0): Q1=1 triggers, flipping Q0: 1→0 → |10⟩. Done. '
        'The third CNOT of the full decomposition would be a no-op here (Q0=0 after the second step), '
        'so only one gate needs to be added.',
    numQubits: 2,
    initialQubitsStateString: "01",
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0,
          isDeletable: false);
    },
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.z)
    ],
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
    taskDescription:
        r"From \( |001\rangle \), transform the state to \( |101\rangle \).",
    targetStateExpression: "|101⟩",
    conceptIntro: 'In a 3-qubit register CNOT can connect any two qubits — '
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
    solutionExplanation: 'CNOT(Q2→Q0)|001⟩ = |101⟩. '
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
      [Complex.one()], // Amplitude for |101>
      [Complex.zero()],
      [Complex.zero()],
    ], // Target: |101>
  ),
  // X(0) + CX(0,2)
  ComposerLevel.fromBinaryString(
    title: 'CNOT Fan-Out',
    taskDescription:
        r"Transform \( |010\rangle \) to \( |111\rangle \). This requires a careful sequence of gates.",
    targetStateExpression: "|111⟩",
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
    solutionExplanation: 'X flips Q0: |010⟩ → |110⟩. '
        'CNOT(Q0→Q2): Q0=1 → Q2 flips: 0→1 → |111⟩. '
        'Q1 was already |1⟩ and is left untouched. '
        'This fan-out pattern — X to set a control, then CNOT to copy its value — '
        'appears in quantum adder circuits and quantum error correction encoders.',
    numQubits: 3,
    initialQubitsStateString: "010",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.ccnot),
      Gate.fromIdentifier(SelectedGateType.hadamard)
    ],
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
    taskDescription:
        r"This circuit is pre-configured to the GHZ state \( (|000\rangle + |111\rangle)/\sqrt{2} \). Transform this state to \( (|001\rangle + |110\rangle)/\sqrt{2} \).",
    targetStateLabel: "X-target GHZ",
    targetStateExpression: "(|001⟩ + |110⟩)/√2",
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
    solutionExplanation: 'X on Q0 (top row): |000⟩→|001⟩ and |111⟩→|110⟩. '
        'Result: (|001⟩+|110⟩)/√2. '
        'This demonstrates the all-or-nothing nature of GHZ entanglement: '
        'a single local X on Q0 flips the rightmost bit in every term simultaneously. '
        'GHZ states are used in quantum secret sharing and quantum communication protocols.',
    numQubits: 3,
    initialQubitsStateString: "000", // Base for pre-inserted gates
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0,
          isDeletable: false);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 1,
          isDeletable: false);
    },
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
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
    taskDescription:
        r"From \( |00\rangle \), create a uniform superposition of all possible 2-qubit states: \( (|00\rangle + |01\rangle + |10\rangle + |11\rangle)/2 \).",
    targetStateLabel: "|++⟩",
    targetStateExpression: "|++⟩ = (|00⟩ + |01⟩ + |10⟩ + |11⟩)/2",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.t),
      Gate.fromIdentifier(SelectedGateType.s)
    ], // Only Hadamard needed
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
    taskDescription:
        r"From \( |001\rangle \), transform the state to \( (|000\rangle - |111\rangle)/\sqrt{2} \).",
    targetStateLabel: "GHZ⁻",
    targetStateExpression: "GHZ⁻ = (|000⟩ - |111⟩)/√2",
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
    solutionExplanation: 'X clears the initial |1⟩. '
        'H creates superposition on one qubit. '
        'CNOT(Q0→Q1) then CNOT(Q1→Q2) cascade the entanglement: (|000⟩+|111⟩)/√2. '
        'Z on any qubit flips the sign of |111⟩ → (|000⟩−|111⟩)/√2. '
        'This "GHZ with a phase" state is one of the 8 maximally-entangled 3-qubit states. '
        'GHZ-class states form a complete, maximally-entangled basis for 3-qubit Hilbert '
        'space and appear in quantum secret sharing and quantum communication protocols.',
    numQubits: 3,
    initialQubitsStateString: "001",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.ccnot),
      Gate.fromIdentifier(SelectedGateType.s),
      Gate.fromIdentifier(SelectedGateType.t)
    ],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)], // Index 0: |000>
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(-sqrt1_2, 0)], // Index 7: |111>
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
    taskDescription:
        r"This is about Conditional Phase Shift (Shor's Principle Hint). From \( |00\rangle \), create a uniform superposition where the \( |11\rangle \) component has its phase flipped to \(-1\). The target state is \( (|00\rangle + |01\rangle + |10\rangle - |11\rangle)/2 \).",
    targetStateLabel: "CZ|++⟩",
    targetStateExpression: "CZ|++⟩ = (|00⟩ + |01⟩ + |10⟩ - |11⟩)/2",
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
    solutionExplanation: 'H⊗H gives (|00⟩+|01⟩+|10⟩+|11⟩)/2. '
        'CZ flips the phase of |11⟩: (|00⟩+|01⟩+|10⟩−|11⟩)/2. '
        'CZ is self-inverse (CZ²=I) and symmetric. '
        'This is the same target state as level 29, reached in fewer gates '
        'because CZ is available here directly. '
        'In Shor\'s algorithm, repeated controlled phase shifts accumulate phase '
        'information that the QFT then converts into a period.',
    numQubits: 2,
    initialQubitsStateString: "00",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cz),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.t),
      Gate.fromIdentifier(SelectedGateType.y)
    ],
    solutionFinalVector: [
      [Complex(0.5, 0)], // Amplitude for |00>
      [Complex(0.5, 0)], // Amplitude for |01>
      [Complex(0.5, 0)], // Amplitude for |10>
      [Complex(-0.5, 0)], // Amplitude for |11> (phase flipped)
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
    taskDescription:
        r"This circuit is pre-configured to an entangled state where the \( |11\rangle \) component has a negative phase. Your task is to transform this state back to \( |00\rangle \).",
    targetStateExpression: "|00⟩",
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
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 1, 1,
          isDeletable: false);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 2, 1, 0,
          isDeletable: false);
    },
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.cz)
    ], // Provide gates for reversal
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
    taskDescription:
        r"Transform the initial state \( |0\rangle \) to the 'plus' state \( |+\rangle \). This can be achieved with a single rotation gate.",
    targetStateLabel: "Rx(π/2)|0⟩",
    targetStateExpression: "Rx(π/2)|0⟩ = (|0⟩ - i|1⟩)/√2",
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
    solutionExplanation: 'Rx(π/2)|0⟩ = (|0⟩−i|1⟩)/√2. '
        'The amplitude on |1⟩ is −i/√2, giving probability |−i/√2|²=1/2 — '
        'equal to |+⟩, but the phase of |1⟩ differs. '
        'Rx, Ry, Rz together can represent any single-qubit unitary. '
        'This is the Euler angle decomposition, fundamental to variational quantum circuits.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2),
      Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2)
    ],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(0, -sqrt1_2)],
    ], // Target: |+>
  ),
  ComposerLevel.fromBinaryString(
    title: 'Ry Rotation Gate',
    taskDescription:
        r"Rotate the initial state \( |0\rangle \) to a new state on the equatorial plane of the Bloch sphere. Try to find the correct rotation.",
    targetStateLabel: "|+⟩",
    targetStateExpression: "|+⟩ = (|0⟩ + |1⟩)/√2",
    conceptIntro: 'Ry(θ) rotates around the Y-axis of the Bloch sphere: '
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
      Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2)
    ],
    solutionFinalVector: [
      [Complex(sqrt1_2, 0)],
      [Complex(sqrt1_2, 0)],
    ], // Target: (1/sqrt(2))(|0> + i|1>)
  ),
  ComposerLevel.fromBinaryString(
    title: 'Rz — Phase Rotation',
    taskDescription:
        r"Apply a phase shift to the state \( |1\rangle \) to transform it to \( |i\rangle \). This requires an Rz gate.",
    targetStateLabel: "e^{iπ/4}|1⟩",
    targetStateExpression: "e^{iπ/4}|1⟩",
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
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2),
      Gate.fromIdentifier(SelectedGateType.ry)
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(sqrt1_2, sqrt1_2)],
    ], // Target: |i>
  ),
  ComposerLevel.fromBinaryString(
    title: 'Inverse Rotation',
    taskDescription:
        r"You start with a pre-configured superposition. Use a rotation gate to return to the \( |0\rangle \) state.",
    targetStateExpression: "|0⟩",
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
    solutionExplanation: 'Ry(π/2)|0⟩ = (|0⟩+|1⟩)/√2 (pre-inserted). '
        'Ry(−π/2) reverses the rotation: '
        'Ry(−π/2)·(|0⟩+|1⟩)/√2 = |0⟩. '
        'Net rotation angle: π/2 + (−π/2) = 0. '
        'This cancellation principle generalises: for any rotation angle θ, '
        'applying Ry(θ) then Ry(−θ) is a no-op.',
    numQubits: 1,
    initialQubitsStateString: "0",
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2), 0, 0,
          isDeletable: false);
    },
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.ry, angle: -math.pi / 2),
      Gate.fromIdentifier(SelectedGateType.hadamard)
    ],
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
    ], // Target: |0>
  ),
  ComposerLevel.fromBinaryString(
    title: 'Composing Rx and Ry',
    taskDescription:
        r"Combine two different rotation gates to get a specific final state. The first rotation is given.",
    targetStateLabel: "Complex equator state",
    targetStateExpression: "((1+i)|0⟩ + (1-i)|1⟩)/2",
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
    solutionExplanation: 'Rx(π/2)|0⟩ = (|0⟩−i|1⟩)/√2. '
        'Ry(π/2) on (|0⟩−i|1⟩)/√2: the Y-rotation mixes components, '
        'giving [0.5+0.5i, 0.5−0.5i]. '
        'Each amplitude has magnitude 1/√2 (50/50 measurement probability), '
        'but the Bloch sphere point and relative phase differ from any single-axis result. '
        'This is the power of multi-axis composition.',
    numQubits: 1,
    initialQubitsStateString: "0",
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), 0, 0,
          isDeletable: false);
    },
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2),
      Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 4),
      Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 8)
    ],
    solutionFinalVector: [
      [Complex(0.5, 0.5)],
      [Complex(0.5, -0.5)],
    ], // Target: a state on the Bloch sphere
  ),
  ComposerLevel.fromBinaryString(
    title: 'Rz on an Entangled State',
    taskDescription:
        r"Use a rotation gate to apply a very specific phase shift on a multi-qubit state. The initial state is a superposition.",
    targetStateLabel: "Phased Bell pair",
    targetStateExpression: "(e^{-iπ/8}|00⟩ + e^{iπ/8}|11⟩)/√2",
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
    solutionExplanation: 'Rz(π/4) on Q0 applied to Φ⁺=(|00⟩+|11⟩)/√2: '
        '|00⟩ → e^(−iπ/8)|00⟩, |11⟩ → e^(iπ/8)|11⟩. '
        'Result: (e^(−iπ/8)|00⟩ + e^(iπ/8)|11⟩)/√2 — a "phased Bell state". '
        'The entanglement is preserved but a relative phase π/4 has been introduced. '
        'In quantum phase estimation, repeated Rz rotations accumulate phase '
        'that encodes eigenvalue information.',
    numQubits: 2,
    initialQubitsStateString: "00",
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0,
          isDeletable: false);
    },
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2),
      Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 4),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.x)
    ],
    solutionFinalVector: [
      [
        Complex(
            sqrt1_2 * math.cos(math.pi / 8), -sqrt1_2 * math.sin(math.pi / 8))
      ],
      [Complex.zero()],
      [Complex.zero()],
      [
        Complex(
            sqrt1_2 * math.cos(math.pi / 8), sqrt1_2 * math.sin(math.pi / 8))
      ],
    ], // Target: (1/sqrt(2))|00> + (e^(i*pi/4)/sqrt(2))|11>
  ),
  ComposerLevel.fromBinaryString(
    title: 'Precise Bloch Sphere Navigation',
    taskDescription:
        r"Transform the initial state to a specific point on the Bloch sphere. This requires precise rotations.",
    targetStateLabel: "Precise phase state",
    targetStateExpression: "e^{-iπ/8}(|0⟩ + |1⟩)/√2",
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
    solutionExplanation: 'Rx(π/2)|0⟩ = (|0⟩ − i|1⟩)/√2. '
        'Ry(π/4) rotates further: component 0 → e^(iπ/8)/√2, component 1 → −i·e^(iπ/8)/√2. '
        'Rz(π/2) applies phases e^(−iπ/4) and e^(iπ/4), making both components equal: '
        'e^(−iπ/8)/√2 = (cos(π/8) − i·sin(π/8))/√2. '
        'The three-gate sequence Rx → Ry → Rz navigates the Bloch sphere along three axes; '
        'any single-qubit gate has an Euler decomposition Rz(α)·Ry(β)·Rz(γ), '
        'and Rx → Ry → Rz here is an alternative three-axis factorisation for this target. '
        'VQE and QAOA circuits use exactly this parameterised gate structure.',
    numQubits: 1,
    initialQubitsStateString: "0",
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2),
      Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 8),
      Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 4),
      Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2)
    ],
    solutionFinalVector: [
      [
        Complex(
            sqrt1_2 * math.cos(math.pi / 8), -sqrt1_2 * math.sin(math.pi / 8))
      ],
      [
        Complex(
            sqrt1_2 * math.cos(math.pi / 8), -sqrt1_2 * math.sin(math.pi / 8))
      ],
    ], // Target: a complex superposition
  ),

  // ── Concept Checks (MCQ) ──────────────────────────────────────────────────
  // Index 46 — Level 47
  McqLevel(
    title: 'What is Superposition?',
    taskDescription: 'A qubit in superposition is...',
    conceptIntro: 'You have applied the Hadamard gate many times. '
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
    conceptIntro: 'Each measurement randomly collapses the superposition. '
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
    solutionExplanation: 'You should see roughly 50 % |0⟩ and 50 % |1⟩. '
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
    solutionFinalVector: [
      [Complex(sqrt1_2)],
      [Complex(sqrt1_2)]
    ],
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
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()]
    ],
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
    conceptIntro: 'Reading circuits is just as important as building them. '
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
    solutionExplanation: 'H creates superposition on Q0 giving (|00⟩+|10⟩)/√2. '
        'CNOT(0→1) then flips Q1 when Q0=1, producing (|00⟩+|11⟩)/√2 — the Bell state Φ⁺.',
  ),

  ComposerLevel(
    title: 'Phase Is Hidden',
    taskDescription:
        r'Can something change without changing what we measure? Transform \( |+\rangle \) into \( |-\rangle \).',
    targetStateLabel: '|-⟩',
    targetStateExpression: '|-⟩ = (|0⟩ - |1⟩)/√2',
    mysteryTitle: 'Can something change without changing what we measure?',
    mysteryText:
        'You have seen this kind of hidden change before. Make the same 50/50 state carry the opposite phase so the next puzzles can reveal it.',
    discoveryTitle: 'Phase Is Hidden',
    discoveryText:
        'The Z gate changed |+⟩ into |−⟩. Nothing visible happened to the measurement odds yet, but the state is now ready to behave differently.',
    keyInsight: 'Hidden phase becomes useful when another gate reveals it.',
    whyItMatters:
        'This is the bridge into interference: first phase changes quietly, then later gates make its effects visible.',
    nextMystery:
        'If phase can hide from measurement, can we make it show up as a bit we can see?',
    hints: [
      'The two states have the same probabilities. Look for a gate that changes a sign, not a bit value.',
      'Z leaves |0⟩ unchanged and gives |1⟩ a minus sign.',
    ],
    solutionExplanation:
        'Z(|0⟩ + |1⟩)/√2 = (|0⟩ - |1⟩)/√2. The probabilities are still 50/50, but the phase changed.',
    numQubits: 1,
    initialQubitsStateStr: '|+⟩',
    initialQubitsState: [
      Complex(math.sqrt1_2, 0),
      Complex(math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex(-math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'HZH = X',
    taskDescription:
        r'Can a phase flip become a bit flip? Starting from \( |0\rangle \), reach \( |1\rangle \) using only H and Z.',
    targetStateExpression: '|1⟩',
    mysteryTitle: 'Can a phase flip become a bit flip?',
    mysteryText:
        'Z only changes phase, so it should not flip |0⟩ into |1⟩ directly. But what if you change the basis before and after the phase flip?',
    discoveryTitle: 'Phase Becomes Bit',
    discoveryText:
        'The first H created two paths. Z changed their phase relationship, and the final H converted that hidden difference into the visible state |1⟩.',
    keyInsight: 'HZH behaves exactly like X.',
    whyItMatters:
        'This is the payoff for hidden phase: a basis change can turn it into something measurement can see.',
    nextMystery:
        'If phase can become a bit, can a bit flip become a phase flip?',
    hints: [
      'Use H to move from the computational basis into the plus/minus basis.',
      'Try placing Z between two H gates.',
    ],
    solutionExplanation:
        'H maps |0⟩ to |+⟩. Z maps |+⟩ to |-⟩. H maps |-⟩ to |1⟩, so HZH acts like X.',
    numQubits: 1,
    initialQubitsStateString: '0',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.z),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel(
    title: 'HXH = Z',
    taskDescription:
        r'Can a bit flip become a phase flip? Starting from \( |+\rangle \), reach \( |-\rangle \) using only H and X.',
    targetStateLabel: '|-⟩',
    targetStateExpression: '|-⟩ = (|0⟩ - |1⟩)/√2',
    mysteryTitle: 'Can a bit flip become a phase flip?',
    mysteryText:
        'X is a bit flip in the normal |0⟩/|1⟩ basis. But in a different basis, the same operation can change phase instead.',
    discoveryTitle: 'Bit Becomes Phase',
    discoveryText:
        'The Hadamard gates changed the perspective around X. In that perspective, a bit flip produced the same final effect as a phase flip.',
    keyInsight: 'HXH behaves exactly like Z.',
    whyItMatters:
        'Interference depends on perspective. Basis changes decide whether a hidden phase stays hidden or becomes visible.',
    nextMystery:
        'If signs can be moved around, can two paths cancel so completely that an outcome becomes impossible?',
    hints: [
      'Use H to change basis before applying X.',
      'Mirror the previous pattern: H, then X, then H.',
    ],
    solutionExplanation:
        'H maps |+⟩ to |0⟩. X maps |0⟩ to |1⟩. H maps |1⟩ to |-⟩, so HXH acts like Z.',
    numQubits: 1,
    initialQubitsStateStr: '|+⟩',
    initialQubitsState: [
      Complex(math.sqrt1_2, 0),
      Complex(math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.x),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex(-math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel(
    title: 'Make Zero Impossible',
    taskDescription:
        r'The first H is already placed. Complete the circuit so \( P(|0\rangle)=0 \).',
    targetStateExpression: '|1⟩',
    mysteryTitle: 'Can you completely eliminate one outcome?',
    mysteryText:
        'The pre-built H has created two possible paths. Can you arrange them so the |0⟩ outcome cancels away completely?',
    discoveryTitle: 'Destructive Interference',
    discoveryText:
        'The completed circuit made the |0⟩ paths cancel and the |1⟩ paths reinforce. The result is P(|0⟩) = 0: an outcome disappeared.',
    keyInsight: 'Destructive interference can make an outcome impossible.',
    whyItMatters:
        'Quantum algorithms use this kind of cancellation to suppress wrong answers and make useful outcomes stand out.',
    nextMystery:
        'What is the general rule behind this cancellation and reinforcement?',
    hints: [
      'The pre-built H already created |+⟩. First change it into |−⟩.',
      'After creating |-⟩, use H to turn cancellation into a visible |1⟩ outcome.',
    ],
    solutionExplanation:
        'The pre-built H creates |+⟩. Z changes |+⟩ into |−⟩. H maps |−⟩ to |1⟩, so P(|0⟩)=0.',
    numQubits: 1,
    initialQubitsStateStr: '0',
    initialQubitsState: [
      Complex.one(),
      Complex.zero(),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()],
    ],
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
        isDeletable: false,
      );
    },
  ),

  ComposerLevel(
    title: 'Something Changed',
    taskDescription:
        r'Can a circuit change information without changing the measured bit? Apply one controlled operation to \( |1\rangle|-\rangle \).',
    targetStateExpression: '-|1⟩|−⟩',
    mysteryTitle:
        'Can a circuit change information without changing the measured bit?',
    mysteryText:
        'The measured bits can look exactly the same before and after a circuit. Try the controlled operation and watch for information that measurement probabilities alone do not reveal.',
    discoveryTitle: 'Hidden Information',
    discoveryText:
        'The target bit still behaves like |−⟩ and the control still measures as 1. Yet the state gained a phase. Something changed, even though the visible bit values did not.',
    keyInsight: 'Not all quantum information is visible through measurement.',
    whyItMatters:
        'Quantum algorithms can move information into signs and phases before anything changes in the measurement probabilities. If you only watch measured bits, you miss most of the computation.',
    nextMystery:
        'What kind of state can carry this hidden information without visibly changing?',
    hints: [
      'Use the controlled gate with the first qubit as control and the second qubit as target.',
      'The target is |−⟩, so flipping it can create a phase instead of an obvious bit change.',
    ],
    solutionExplanation:
        'CNOT with control q0 and target q1 maps |1⟩|−⟩ to -|1⟩|−⟩. The measured bit values are unchanged, but the phase changed.',
    numQubits: 2,
    initialQubitsStateStr: '|1⟩|−⟩',
    initialQubitsState: [
      Complex.zero(),
      Complex(math.sqrt1_2, 0),
      Complex.zero(),
      Complex(-math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(-math.sqrt1_2, 0)],
      [Complex.zero()],
      [Complex(math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel(
    title: 'The Hidden Passenger',
    taskDescription:
        r'Where did the information go? Turn the target from \( |+\rangle \) into the phase-sensitive \( |-\rangle \).',
    targetStateExpression: '|1⟩|−⟩',
    mysteryTitle: 'Where did the information go?',
    mysteryText:
        'The second qubit can hide information in phase. Prepare it as |−⟩ while the first qubit remains |1⟩.',
    discoveryTitle: 'Phase Carrier',
    discoveryText:
        '|−⟩ has the same 50/50 measurement probabilities as |+⟩, but its minus sign makes it respond differently to controlled operations.',
    keyInsight: 'Phase can carry information.',
    whyItMatters:
        'Phase-sensitive states let a circuit store information without needing a visible bit flip. They are the hidden passengers that make kickback possible.',
    nextMystery:
        'If the target carries phase, can a controlled gate send that phase back to the control?',
    hints: [
      'Only the target qubit needs to change.',
      'Z changes |+⟩ into |−⟩ without changing the target measurement probabilities.',
    ],
    solutionExplanation:
        'Applying Z to q1 changes |+⟩ into |−⟩. The target probabilities stay 50/50, but the phase is now different.',
    numQubits: 2,
    initialQubitsStateStr: '|1⟩|+⟩',
    initialQubitsState: [
      Complex.zero(),
      Complex(math.sqrt1_2, 0),
      Complex.zero(),
      Complex(math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
      [Complex(-math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel(
    title: 'First Kickback',
    taskDescription:
        r'How did the control affect something it never touched? Use one controlled operation on \( |+\rangle|-\rangle \).',
    targetStateExpression: '|−⟩|−⟩',
    mysteryTitle: 'How did the control affect something it never touched?',
    mysteryText:
        'The target qubit is set up as |−⟩. Use a controlled operation and look carefully at which qubit changes phase.',
    discoveryTitle: 'Phase Kickback',
    discoveryText:
        'The CNOT acted on the target, but because the target was |−⟩, the phase kicked back onto the control. The control changed from |+⟩ to |−⟩.',
    keyInsight: 'Controlled operations can modify phase.',
    whyItMatters:
        'Phase kickback is one of the core mechanisms behind quantum algorithms. It lets a circuit write information into phase without directly flipping the qubit that will later reveal the answer.',
    nextMystery:
        'Can this hidden communication happen without changing any visible bit value?',
    hints: [
      'Use the first qubit as the control and the second qubit as the target.',
      'The target stays |−⟩, but the control can gain a phase.',
    ],
    solutionExplanation:
        'CNOT maps |+⟩|−⟩ to |−⟩|−⟩. The target was flipped conditionally, but the visible change appears as phase on the control.',
    numQubits: 2,
    initialQubitsStateStr: '|+⟩|−⟩',
    initialQubitsState: [
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(-0.5, 0),
      Complex(-0.5, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex(0.5, 0)],
      [Complex(-0.5, 0)],
      [Complex(-0.5, 0)],
      [Complex(0.5, 0)],
    ],
  ),

  ComposerLevel(
    title: 'Information Without Flips',
    taskDescription:
        r'Can information be transferred without changing any visible bit value? Use one controlled phase operation on \( |+\rangle|1\rangle \).',
    targetStateExpression: '|−⟩|1⟩',
    mysteryTitle:
        'Can information be transferred without changing any visible bit value?',
    mysteryText:
        'The second qubit is fixed at |1⟩. Use a controlled phase operation and watch the first qubit: no bit flip is needed for information to move.',
    discoveryTitle: 'Hidden Communication',
    discoveryText:
        'CZ did not flip either bit. It only changed the sign of the |11⟩ path, which turned the control from |+⟩ into |−⟩.',
    keyInsight: 'Quantum circuits often manipulate phase instead of bits.',
    whyItMatters:
        'Many quantum subroutines communicate by marking phases. The measured bit values may stand still while the useful information moves through the circuit.',
    nextMystery:
        'How do phase, interference, and kickback combine into the language of algorithms?',
    hints: [
      'Use the controlled phase gate.',
      'The second qubit remains |1⟩; the first qubit receives the phase change.',
    ],
    solutionExplanation:
        'CZ maps (|01⟩ + |11⟩)/√2 to (|01⟩ - |11⟩)/√2, which is |−⟩|1⟩. No bit values were flipped.',
    numQubits: 2,
    initialQubitsStateStr: '|+⟩|1⟩',
    initialQubitsState: [
      Complex.zero(),
      Complex(math.sqrt1_2, 0),
      Complex.zero(),
      Complex(math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cz),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
      [Complex(-math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel(
    title: 'The Quantum Secret',
    taskDescription:
        r'What have we really learned? Kick phase back onto the control, then reveal it as \( |1\rangle \).',
    targetStateExpression: '|1⟩|−⟩',
    mysteryTitle: 'What have we really learned?',
    mysteryText:
        'A controlled operation can write information into phase. Interference can later turn that phase into a measured outcome. Combine both ideas.',
    discoveryTitle: 'The Language of Quantum Algorithms',
    discoveryText:
        'The CNOT kicked phase back from the |−⟩ target onto the control. The final H converted that phase into the visible outcome |1⟩.',
    keyInsight:
        'Quantum algorithms frequently store information in phase and later reveal it through interference.',
    whyItMatters:
        'Grover, Phase Estimation, Shor, and QAOA all rely on this principle: mark information in phase, then use interference to make the useful answers observable.',
    nextMystery:
        'Next, an oracle can mark an answer in phase so interference can amplify it.',
    hints: [
      'First kick phase back with a controlled operation.',
      'Then use H on the control qubit to reveal the kicked phase as |1⟩.',
    ],
    solutionExplanation:
        'CNOT changes |+⟩|−⟩ into |−⟩|−⟩. H on the control maps |−⟩ to |1⟩, revealing the phase as a measurable bit.',
    numQubits: 2,
    initialQubitsStateStr: '|+⟩|−⟩',
    initialQubitsState: [
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(-0.5, 0),
      Complex(-0.5, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
      [Complex(-math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel(
    title: 'The Special State',
    taskDescription:
        r'Can one state be treated differently from all the others? Apply the phase-marking operation to \( |++\rangle \).',
    targetStateExpression: 'O|++⟩ = (|00⟩ + |01⟩ + |10⟩ - |11⟩)/2',
    mysteryTitle: 'Can one state be treated differently from all the others?',
    mysteryText:
        'A superposition contains several possible states at once. Try one controlled phase operation and look for the single basis state that receives special treatment.',
    discoveryTitle: 'A Special State',
    discoveryText:
        'Only the |11⟩ part changed sign. The circuit did not choose an answer yet, but it did distinguish one state from the rest.',
    keyInsight: 'Quantum circuits can distinguish one state from many.',
    whyItMatters:
        'Search algorithms begin by identifying which state matters. Before an answer can be amplified, it must be treated differently from the other possibilities.',
    nextMystery:
        'Can that special treatment happen without measuring the state?',
    hints: [
      'Use the controlled phase gate.',
      'CZ changes the sign only when both qubits are |1⟩.',
    ],
    solutionExplanation:
        'CZ leaves |00⟩, |01⟩, and |10⟩ unchanged, but adds a minus sign to |11⟩. That single sign change is the beginning of oracle thinking.',
    numQubits: 2,
    initialQubitsStateStr: '|++⟩',
    initialQubitsState: [
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cz),
    ],
    solutionFinalVector: [
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
      [Complex(-0.5, 0)],
    ],
  ),

  ComposerLevel(
    title: 'Mark Without Measuring',
    taskDescription:
        r'Can we mark a state without observing it? Mark \( |1\rangle \) inside \( |+\rangle \) using phase.',
    targetStateLabel: '|−⟩',
    targetStateExpression: '|−⟩ = (|0⟩ - |1⟩)/√2',
    mysteryTitle: 'Can we mark a state without observing it?',
    mysteryText:
        'A measurement would collapse the state. Instead, try changing only the sign attached to one outcome.',
    discoveryTitle: 'Hidden Mark',
    discoveryText:
        'The probabilities stayed 50/50, but |1⟩ received a minus sign. The mark is real even though measurement probabilities do not reveal it yet.',
    keyInsight:
        'A phase mark does not immediately change measurement outcomes.',
    whyItMatters:
        'Quantum algorithms often hide information in phase first. Interference later turns that hidden mark into something measurable.',
    nextMystery:
        'If a single qubit can be marked, can you build a two-qubit oracle that marks a chosen solution?',
    hints: [
      'Use the phase flip gate.',
      'Z marks the |1⟩ component of |+⟩ with a minus sign.',
    ],
    solutionExplanation:
        'Z maps |+⟩ to |−⟩. It marks the |1⟩ component with a phase while leaving the measurement probabilities unchanged.',
    numQubits: 1,
    initialQubitsStateStr: '|+⟩',
    initialQubitsState: [
      Complex(math.sqrt1_2, 0),
      Complex(math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex(-math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel(
    title: 'Build An Oracle',
    taskDescription:
        r'Can you create the marking yourself? Build a circuit that marks \( |10\rangle \) inside \( |++\rangle \).',
    targetStateExpression: 'O|++⟩ = (|00⟩ + |01⟩ - |10⟩ + |11⟩)/2',
    mysteryTitle: 'Can you create the marking yourself?',
    mysteryText:
        'CZ naturally marks |11⟩. To mark a different solution, temporarily move the desired state into the place CZ can see.',
    discoveryTitle: 'Oracle',
    discoveryText:
        'The X gates changed which state the controlled phase gate recognized. Together, they made an oracle that marks |10⟩.',
    keyInsight: 'An oracle marks a solution rather than revealing it.',
    whyItMatters:
        'The oracle is the first step of Grover\'s algorithm. It does not find the answer by itself; it labels the answer in phase.',
    nextMystery:
        'If marks can be hidden in phase, can you tell which state was marked?',
    hints: [
      'Use X to temporarily turn |10⟩ into |11⟩.',
      'Apply CZ, then undo the temporary X.',
    ],
    solutionExplanation:
        'X on q0 maps the desired |10⟩ state to |11⟩. CZ marks it, then X on q0 restores the original labels, leaving only |10⟩ with a minus sign.',
    numQubits: 2,
    initialQubitsStateStr: '|++⟩',
    initialQubitsState: [
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.cz),
    ],
    solutionFinalVector: [
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
      [Complex(-0.5, 0)],
      [Complex(0.5, 0)],
    ],
  ),

  ComposerLevel(
    title: 'Which State Was Marked?',
    taskDescription:
        r'Can you determine which state received the mark? Build a circuit that marks \( |01\rangle \) inside \( |++\rangle \).',
    targetStateExpression: 'O|++⟩ = (|00⟩ - |01⟩ + |10⟩ + |11⟩)/2',
    mysteryTitle: 'Can you determine which state received the mark?',
    mysteryText:
        'The probability bars may look unchanged after a phase mark. The clue is the sign attached to exactly one basis state.',
    discoveryTitle: 'Invisible Mark',
    discoveryText:
        'The marked state has the same probability as the others, but its amplitude has the opposite sign. Measurement alone would hide the mark.',
    keyInsight:
        'A solution can be marked in phase while measurement probabilities stay unchanged.',
    whyItMatters:
        'Quantum algorithms can store useful labels in phase before interference turns those labels into visible probability changes.',
    nextMystery:
        'What have we actually built when we can mark any desired solution?',
    hints: [
      'Move |01⟩ into the |11⟩ position before applying CZ.',
      'Undo the move after the mark is applied.',
    ],
    solutionExplanation:
        'X on q1 maps |01⟩ to |11⟩. CZ marks that temporary |11⟩ state, then X on q1 restores the basis labels, leaving |01⟩ marked.',
    numQubits: 2,
    initialQubitsStateStr: '|++⟩',
    initialQubitsState: [
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.cz),
    ],
    solutionFinalVector: [
      [Complex(0.5, 0)],
      [Complex(-0.5, 0)],
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
    ],
  ),

  ComposerLevel(
    title: 'Preparing For Grover',
    taskDescription:
        r'What have we actually built? Build a phase oracle that marks \( |00\rangle \) inside \( |++\rangle \).',
    targetStateExpression: 'O|++⟩ = (-|00⟩ + |01⟩ + |10⟩ + |11⟩)/2',
    mysteryTitle: 'What have we actually built?',
    mysteryText:
        'You can now choose which solution receives the hidden sign. Mark |00⟩ and think about what a later interference step could do with that mark.',
    discoveryTitle: 'Phase Marking',
    discoveryText:
        'You built an oracle: a circuit that leaves every state alone except the chosen solution, which receives a phase mark.',
    keyInsight: 'The oracle creates a hidden label on the desired solution.',
    whyItMatters:
        'Grover\'s algorithm will use interference to amplify this marked state. The oracle does not find the solution; it gives interference something to work with.',
    nextMystery:
        'If a solution is marked, can we make it more likely to appear?',
    hints: [
      'CZ marks |11⟩, so first move |00⟩ into |11⟩.',
      'Use X on both qubits before CZ, then undo both X gates.',
    ],
    solutionExplanation:
        'X on both qubits maps |00⟩ to |11⟩. CZ applies the phase mark, and the final X gates restore the labels, leaving |00⟩ marked.',
    numQubits: 2,
    initialQubitsStateStr: '|++⟩',
    initialQubitsState: [
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.cz),
    ],
    solutionFinalVector: [
      [Complex(-0.5, 0)],
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
    ],
  ),

  ComposerLevel(
    title: 'The Mark Is Still Hidden',
    taskDescription:
        r'If the solution is marked, why can’t we see it yet? Mark \( |11\rangle \) inside \( |++\rangle \).',
    targetStateExpression: 'O|++⟩ = (|00⟩ + |01⟩ + |10⟩ - |11⟩)/2',
    mysteryTitle: 'If the solution is marked, why can’t we see it yet?',
    mysteryText:
        'The oracle can mark a solution with a minus sign. But if all probabilities stay equal, the marked answer is still hidden from measurement.',
    discoveryTitle: 'Marked But Hidden',
    discoveryText:
        'The oracle marked |11⟩ with phase, but the probability of each state stayed 25%. Marking alone is not the same as finding.',
    keyInsight: 'An oracle marks the solution, but it does not amplify it.',
    whyItMatters:
        'Grover needs both marking and amplification. The oracle creates the hidden sign; a later interference step makes that sign useful.',
    nextMystery: 'Can interference make the hidden mark visible?',
    hints: [
      'Use the controlled phase gate.',
      'CZ marks |11⟩ by changing only its sign.',
    ],
    solutionExplanation:
        'CZ applies a -1 phase to |11⟩ while leaving the other basis states unchanged. The probabilities remain equal.',
    numQubits: 2,
    initialQubitsStateStr: '|++⟩',
    initialQubitsState: [
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cz),
    ],
    solutionFinalVector: [
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
      [Complex(0.5, 0)],
      [Complex(-0.5, 0)],
    ],
  ),

  ComposerLevel(
    title: 'Interference Reveals the Mark',
    taskDescription:
        r'Can interference make the hidden mark visible? Convert \( |-\rangle \) into a measurable \( |1\rangle \).',
    targetStateExpression: '|1⟩',
    mysteryTitle: 'Can interference make the hidden mark visible?',
    mysteryText:
        'The minus sign in |−⟩ is a hidden phase mark. Use interference to turn that phase difference into a bit you can measure.',
    discoveryTitle: 'Mark Becomes Probability',
    discoveryText:
        'The H gate made the positive and negative paths interfere. The hidden phase became the visible state |1⟩.',
    keyInsight:
        'Interference can convert phase information into measurement probability.',
    whyItMatters:
        'This is the basic mechanism behind amplitude amplification: phase information becomes probability through interference.',
    nextMystery: 'Can one marked state become more likely than all the others?',
    hints: [
      'Use the basis-changing gate.',
      'H maps |−⟩ to |1⟩.',
    ],
    solutionExplanation:
        'H converts |−⟩ = (|0⟩ - |1⟩)/√2 into |1⟩. The phase mark becomes measurement probability.',
    numQubits: 1,
    initialQubitsStateStr: '|−⟩',
    initialQubitsState: [
      Complex(math.sqrt1_2, 0),
      Complex(-math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel(
    title: 'Amplify One State',
    taskDescription:
        r'Can one marked state become more likely than the others? Mark \( |11\rangle \), then amplify it.',
    targetStateExpression: '|11⟩',
    mysteryTitle: 'Can one marked state become more likely than the others?',
    mysteryText:
        'Start with every state equally likely. Mark |11⟩ in phase, then use the amplification pattern to make the marked state stand out.',
    discoveryTitle: 'Amplitude Amplification',
    discoveryText:
        'The marked state became the dominant outcome. The circuit used reflections and interference to move amplitude toward the marked answer.',
    keyInsight:
        'A marked state can be amplified by reflecting/interfering amplitudes.',
    whyItMatters:
        'Grover’s algorithm uses this idea to make the correct answer appear more often instead of checking every possibility one by one.',
    nextMystery: 'Can we search by marking, then amplifying?',
    hints: [
      'First mark |11⟩ with CZ.',
      'Then use the diffuser pattern: H on both, X on both, CZ, X on both, H on both.',
    ],
    solutionExplanation:
        'CZ marks |11⟩. The diffuser H,H,X,X,CZ,X,X,H,H reflects amplitudes so the marked |11⟩ state is amplified.',
    numQubits: 2,
    initialQubitsStateStr: '|++⟩',
    initialQubitsState: [
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cz),
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.x),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(-1, 0)],
    ],
  ),

  ComposerLevel(
    title: 'Mini Grover',
    taskDescription:
        r'Can we search by marking, then amplifying? Mark \( |10\rangle \), then amplify it.',
    targetStateExpression: '|10⟩',
    mysteryTitle: 'Can we search by marking, then amplifying?',
    mysteryText:
        'This is a tiny Grover search: prepare all answers, mark the desired one, then amplify the mark.',
    discoveryTitle: 'Mini Grover',
    discoveryText:
        'The circuit did not inspect each answer separately. It marked |10⟩, then interference pushed probability into that marked state.',
    keyInsight: 'Grover search is mark, then amplify.',
    whyItMatters:
        'This is the first complete quantum algorithm intuition in Qubit Quest 2.0: superposition, oracle mark, then amplitude amplification.',
    nextMystery: 'What did the algorithm actually do?',
    hints: [
      'Use X on q0 to make CZ mark |10⟩, then undo that X.',
      'After the oracle, apply the diffuser pattern: H,H,X,X,CZ,X,X,H,H.',
    ],
    solutionExplanation:
        'The X,CZ,X oracle marks |10⟩. The diffuser then converts the hidden phase mark into high probability on |10⟩.',
    numQubits: 2,
    initialQubitsStateStr: '|++⟩',
    initialQubitsState: [
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.cz),
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex(-1, 0)],
      [Complex.zero()],
    ],
  ),

  ComposerLevel(
    title: 'Why Search Can Be Faster',
    taskDescription:
        r'What did the algorithm actually do? Mark \( |00\rangle \), then amplify it.',
    targetStateExpression: '|00⟩',
    mysteryTitle: 'What did the algorithm actually do?',
    mysteryText:
        'Connect the full chain: start with all answers, mark the desired one in phase, then use interference to reshape the probabilities.',
    discoveryTitle: 'Search Through Interference',
    discoveryText:
        'The oracle marked |00⟩ invisibly. The amplification step used interference to concentrate probability on that marked state.',
    keyInsight:
        'Quantum search does not check every answer one by one. It reshapes amplitudes so the answer becomes more likely.',
    whyItMatters:
        'This is why Grover’s algorithm can provide a quadratic speedup: it turns a hidden phase label into an increased chance of measuring the answer.',
    nextMystery:
        'If we can tune amplitudes for search, can we tune quantum circuits for optimization?',
    hints: [
      'Use X on both qubits to make CZ mark |00⟩, then undo both X gates.',
      'After the oracle, apply the diffuser pattern: H,H,X,X,CZ,X,X,H,H.',
    ],
    solutionExplanation:
        'The X,X,CZ,X,X oracle marks |00⟩. The diffuser turns that phase mark into amplitude concentrated on |00⟩.',
    numQubits: 2,
    initialQubitsStateStr: '|++⟩',
    initialQubitsState: [
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
      Complex(0.5, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.cz),
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex(-1, 0)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'The First Qubit',
    taskDescription:
        r'Can a quantum bit store information? Transform \( |0\rangle \) into \( |1\rangle \).',
    targetStateExpression: '|1⟩',
    mysteryTitle: 'Can a quantum bit store information?',
    mysteryText:
        'Start with the simplest possible quantum register: one qubit showing |0⟩. Can a gate make it carry a different value?',
    discoveryTitle: 'Information',
    discoveryText:
        'The X gate changed |0⟩ into |1⟩. The qubit is not just a label on a wire; it is a state a circuit can transform.',
    keyInsight: 'A qubit can store a state that a circuit changes.',
    whyItMatters:
        'Every later puzzle starts from this move: prepare information, transform it, then inspect what changed.',
    nextMystery: 'Can a quantum change be undone?',
    hints: [
      'There is only one gate available.',
      'Use X to flip |0⟩ into |1⟩.',
    ],
    solutionExplanation:
        'X flips the qubit from |0⟩ to |1⟩. This is the first information transformation.',
    numQubits: 1,
    initialQubitsStateString: '0',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Undo The Change',
    taskDescription:
        r'Can a change be reversed? The qubit has already been flipped. Return it to \( |0\rangle \).',
    targetStateExpression: '|0⟩',
    mysteryTitle: 'Can a change be reversed?',
    mysteryText:
        'The circuit has already flipped the qubit. Instead of erasing the circuit, try to use another operation to retrace the change.',
    discoveryTitle: 'Reversibility',
    discoveryText:
        'A second X brought the qubit back to |0⟩. The first gate did not destroy the original information; its effect could be reversed.',
    keyInsight: 'Quantum gates act like reversible transformations.',
    whyItMatters:
        'Quantum circuits are built from operations that preserve enough structure to be undone or combined with other operations.',
    nextMystery: 'Can extra moves cancel out?',
    hints: [
      'The first X has already been placed.',
      'X followed by X returns the qubit to its starting state.',
    ],
    solutionExplanation:
        'The pre-built X flips |0⟩ to |1⟩. A second X flips |1⟩ back to |0⟩, so X followed by X restores the original state.',
    numQubits: 1,
    initialQubitsStateString: '0',
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0,
          isDeletable: false);
    },
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
    ],
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Different Paths',
    taskDescription:
        r'Can extra moves cancel out? Reach \( |1\rangle \) from \( |0\rangle \) after adding more than one gate.',
    targetStateExpression: '|1⟩',
    mysteryTitle: 'Can extra moves cancel out?',
    mysteryText:
        'A circuit is not judged by how many gates it contains. Try making a longer route where part of the route erases itself.',
    discoveryTitle: 'Equivalent Results',
    discoveryText:
        'Three X gates still ended at |1⟩ because two of them canceled as a pair. The whole circuit matters more than any single step.',
    keyInsight: 'A circuit has an overall effect, and some steps can cancel.',
    whyItMatters:
        'Later puzzles use the same idea with less obvious gates: build a useful transformation by combining pieces that may undo, redirect, or reveal each other.',
    nextMystery: 'Can one circuit transform a whole pattern?',
    hints: [
      'Build a route with more gates than the direct answer needs.',
      'Two neighboring X gates cancel; the remaining X sets the final state.',
    ],
    solutionExplanation:
        'X then X then X reaches |1⟩ because one pair of flips cancels. The circuit is longer, but its net effect is still a single flip.',
    numQubits: 1,
    initialQubitsStateString: '0',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Information Patterns',
    taskDescription:
        r'Can information move through multiple states? Transform \( |00\rangle \) into \( |11\rangle \).',
    targetStateExpression: '|11⟩',
    mysteryTitle: 'Can information move through multiple states?',
    mysteryText:
        'One qubit can change, but useful registers contain patterns. Can you transform both parts of the pattern without treating them as one big switch?',
    discoveryTitle: 'State Transformations',
    discoveryText:
        'Each wire carried one piece of the pattern. Changing both pieces transformed the register from |00⟩ into |11⟩.',
    keyInsight: 'Multi-qubit states are information patterns.',
    whyItMatters:
        'Quantum algorithms work on registers, not isolated symbols. Even simple gates can reshape a complete pattern.',
    nextMystery: 'What is the thing being transformed?',
    hints: [
      'Each qubit needs to change from 0 to 1.',
      'Use one X on each qubit.',
    ],
    solutionExplanation:
        'X on each qubit flips both bits of information, changing |00⟩ into |11⟩.',
    numQubits: 2,
    initialQubitsStateString: '00',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'What Have We Learned?',
    taskDescription:
        r'What is a qubit really? Transform the information pattern \( |01\rangle \) into \( |10\rangle \).',
    targetStateExpression: '|10⟩',
    mysteryTitle: 'What is a qubit really?',
    mysteryText:
        'You have flipped, undone, canceled, and changed patterns. Use one final pattern change to name what the circuit has been acting on.',
    discoveryTitle: 'The Quantum Bit',
    discoveryText:
        'The circuit changed |01⟩ into |10⟩ by transforming each qubit. A qubit is the basic piece of information inside the register.',
    keyInsight: 'Qubits are the transformable units of quantum information.',
    whyItMatters:
        'Everything next asks a sharper question: if a qubit can change, will measurement always show that change?',
    nextMystery: 'Can a circuit change something we cannot see yet?',
    hints: [
      'Both qubits need to change.',
      'Use X on each qubit to swap the pattern from |01⟩ to |10⟩.',
    ],
    solutionExplanation:
        'X flips each qubit: the 0 becomes 1 and the 1 becomes 0. The information pattern changes from |01⟩ to |10⟩.',
    numQubits: 2,
    initialQubitsStateString: '01',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
      [Complex.zero()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Nothing Happened?',
    taskDescription:
        r'Can a quantum state change without changing its measurement? Use Z on \( |0\rangle \).',
    targetStateExpression: 'Z|0⟩ = |0⟩',
    mysteryTitle:
        'Can a quantum state change without changing its measurement?',
    mysteryText:
        'So far, every useful change moved a visible 0 or 1. Try a gate whose action is real, even though this starting state still measures the same way.',
    discoveryTitle: 'Hidden Change',
    discoveryText:
        'Z was applied, but |0⟩ still measured as |0⟩. The surprise is that a gate can be part of the circuit even when this particular input hides its effect.',
    keyInsight:
        'A gate can have a real action without changing every visible outcome.',
    whyItMatters:
        'This separates “nothing visible happened” from “nothing happened.” Quantum puzzles often depend on that difference.',
    nextMystery: 'Where can an invisible effect leave a trace?',
    hints: [
      'There is only one gate available.',
      'Use Z and notice that this input hides the gate in the measured result.',
    ],
    solutionExplanation:
        'Z leaves |0⟩ unchanged for this input. The operation is still part of the circuit; this state simply does not expose its sign-changing side.',
    numQubits: 1,
    initialQubitsStateString: '0',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
    ],
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
    ],
    validationMode: ValidationMode.unitary,
    targetUnitary: [
      [Complex.one(), Complex.zero()],
      [Complex.zero(), Complex(-1, 0)],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'The Invisible Difference',
    taskDescription:
        r'How can two states look identical but behave differently later? Change \( |1\rangle \) without changing its measurement.',
    targetStateExpression: '-|1⟩',
    mysteryTitle:
        'How can two states look identical but behave differently later?',
    mysteryText:
        'Now try the same gate on |1⟩. The measured bit will not flip, but watch the state expression for a trace that was missing before.',
    discoveryTitle: 'Invisible Difference',
    discoveryText:
        'The bit value stayed 1, but the state picked up a minus sign. Measurement of this single basis state hides the sign; the state display reveals it.',
    keyInsight:
        'Quantum state descriptions can contain signs that measurement probabilities ignore.',
    whyItMatters:
        'This is the first visible trace of phase. By itself it is quiet, but in a state with multiple pieces a sign can change what happens next.',
    nextMystery: 'What happens when only one piece gets the sign?',
    hints: [
      'Use the same gate as before, but start from the state where its sign effect appears.',
      'Z does not flip |1⟩ into |0⟩; it attaches a minus sign to |1⟩.',
    ],
    solutionExplanation:
        'Z changes |1⟩ into -|1⟩. The measured bit stays fixed, while the state expression exposes the sign.',
    numQubits: 1,
    initialQubitsStateString: '1',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(-1, 0)],
    ],
  ),

  ComposerLevel(
    title: 'The Minus Sign',
    taskDescription:
        r'Why does a minus sign matter? Create the phase-flipped \( |-\rangle \) state.',
    targetStateLabel: '|-⟩',
    targetStateExpression: '(|0⟩ - |1⟩)/√2',
    mysteryTitle: 'Why does a minus sign matter?',
    mysteryText:
        'A balanced state has two pieces. If only one piece receives the minus sign, the odds still look balanced, but the relationship between the pieces changes.',
    discoveryTitle: 'Relative Phase',
    discoveryText:
        'The state still gives equal chances of |0⟩ and |1⟩, but the sign between the two pieces changed. That relationship is relative phase.',
    keyInsight: 'Relative phase is a sign relationship inside a state.',
    whyItMatters:
        'Relative phase is where the hidden sign becomes useful: later gates can make different relationships produce different outcomes.',
    nextMystery: 'Can phase act like memory?',
    hints: [
      'You are already balanced between |0⟩ and |1⟩.',
      'Use Z to change the relationship between the two pieces.',
    ],
    solutionExplanation:
        'Z changes |+⟩ into |−⟩ by giving only the |1⟩ part a minus sign. The important change is the relationship between the two amplitudes.',
    numQubits: 1,
    initialQubitsStateStr: '|+⟩',
    initialQubitsState: [
      Complex(math.sqrt1_2, 0),
      Complex(math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex(-math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel(
    title: 'Hidden Information',
    taskDescription:
        r'Can information be stored in phase? Change \( |-\rangle \) back into \( |+\rangle \).',
    targetStateLabel: '|+⟩',
    targetStateExpression: '(|0⟩ + |1⟩)/√2',
    mysteryTitle: 'Can information be stored in phase?',
    mysteryText:
        'The possible outcomes are unchanged. The puzzle is whether changing only the relationship between them can still count as changing information.',
    discoveryTitle: 'Phase Information',
    discoveryText:
        'Z changed |−⟩ back into |+⟩. Nothing about the 50/50 odds changed, but the phase relationship did.',
    keyInsight:
        'Quantum information can live in relationships, not only values.',
    whyItMatters:
        'Future algorithms mark and guide answers by changing relationships first, then making those changes visible later.',
    nextMystery: 'Can a hidden relationship become a visible result?',
    hints: [
      'The target restores the plus relationship between the two pieces.',
      'Use the same gate again; phase changes can be reversible too.',
    ],
    solutionExplanation:
        'Z changes |−⟩ back into |+⟩. The outcome options stay the same, but the phase relationship is restored.',
    numQubits: 1,
    initialQubitsStateStr: '|−⟩',
    initialQubitsState: [
      Complex(math.sqrt1_2, 0),
      Complex(-math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex(math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel(
    title: 'What Did We Actually Discover?',
    taskDescription:
        r'What was changing all along? Turn the hidden change in \( |+\rangle \) into the visible state \( |1\rangle \).',
    targetStateExpression: '|1⟩',
    mysteryTitle: 'What was changing all along?',
    mysteryText:
        'You have changed values, signs, and relationships. Now build the reveal: make phase affect the measured bit.',
    discoveryTitle: 'Phase',
    discoveryText:
        'Z created the phase relationship, then H changed how the state was read. The hidden phase became the visible outcome |1⟩.',
    keyInsight: 'Phase is hidden until another operation makes it observable.',
    whyItMatters:
        'This is the bridge into the next chapters: quantum circuits can store useful structure in phase, then reveal it through later transformations.',
    nextMystery: 'Can a qubit be more than 0 or 1?',
    hints: [
      'First create the phase relationship with Z.',
      'Then use H to read that relationship as a definite bit value.',
    ],
    solutionExplanation:
        'Z changes |+⟩ into |−⟩. H then maps |−⟩ to |1⟩, turning phase into a visible result.',
    numQubits: 1,
    initialQubitsStateStr: '|+⟩',
    initialQubitsState: [
      Complex(math.sqrt1_2, 0),
      Complex(math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'The Third State',
    taskDescription:
        r'Must a qubit always be 0 or 1? Create a state that is neither \( |0\rangle \) nor \( |1\rangle \).',
    targetStateLabel: '|+⟩',
    targetStateExpression: '(|0⟩ + |1⟩)/√2',
    mysteryTitle: 'Must a qubit always be 0 or 1?',
    mysteryText:
        'You have changed qubits between 0 and 1, and you have seen hidden phase. Now try making a state that does not look like either classical option.',
    discoveryTitle: 'The Third State',
    discoveryText:
        'The qubit is no longer just |0⟩ or just |1⟩. It has become a balanced combination of both possibilities.',
    keyInsight: 'A qubit can exist in a combination of possibilities.',
    whyItMatters:
        'Quantum computing becomes powerful because qubits are not restricted to classical states.',
    nextMystery: 'What happens if we measure this strange state?',
    hints: [
      'There is only one gate available.',
      'Use the gate and watch the probability bars split evenly.',
    ],
    solutionExplanation:
        'The circuit creates |+⟩, a state with both |0⟩ and |1⟩ present at the same time.',
    numQubits: 1,
    initialQubitsStateString: '0',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex(math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Fifty Fifty',
    taskDescription:
        r'What outcome will appear when we measure a superposition? Create a state with equal probability of \( |0\rangle \) and \( |1\rangle \).',
    targetStateLabel: '|-⟩',
    targetStateExpression: '(|0⟩ - |1⟩)/√2',
    mysteryTitle: 'What outcome will appear when we measure a superposition?',
    mysteryText:
        'A qubit can hold more than one possibility before measurement. Make a state where neither outcome has all the probability.',
    discoveryTitle: 'Two Possibilities',
    discoveryText:
        'The state now gives |0⟩ half the time and |1⟩ half the time. The outcome is uncertain, but the probabilities are precise.',
    keyInsight: 'A superposition can create precise measurement odds.',
    whyItMatters:
        'Quantum algorithms use exact probability patterns, not vague randomness.',
    nextMystery: 'If measurement is uncertain, is the state just random?',
    hints: [
      'Start from |1⟩ and use the only available gate.',
      'The goal is equal probabilities, not a single certain outcome.',
    ],
    solutionExplanation:
        'The circuit turns |1⟩ into a balanced state. Measurement can now produce either |0⟩ or |1⟩ with equal probability.',
    numQubits: 1,
    initialQubitsStateString: '1',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex(-math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel(
    title: 'Precise, Not Random',
    taskDescription:
        r'If measurement is uncertain, is the state just random? Turn \( |+\rangle \) back into \( |0\rangle \).',
    targetStateExpression: '|0⟩',
    mysteryTitle: 'If measurement is uncertain, is the state just random?',
    mysteryText:
        'A balanced state can look like a coin toss when measured. Test whether it is still a precise state that a gate can control.',
    discoveryTitle: 'Precise Superposition',
    discoveryText:
        'The balanced state returned cleanly to |0⟩. Superposition is not uncontrolled randomness; it is a precise state.',
    keyInsight: 'A superposition can be reversed by the right operation.',
    whyItMatters:
        'This makes superposition useful in circuits: gates can create it, transform it, and turn it back into certainty.',
    nextMystery: 'Can we prepare a balanced state on purpose?',
    hints: [
      'Use the gate that created |+⟩ from |0⟩.',
      'The same operation can also turn |+⟩ back into |0⟩.',
    ],
    solutionExplanation:
        'H turns |+⟩ back into |0⟩. The state had uncertain measurement outcomes, but it was still exactly controllable.',
    numQubits: 1,
    initialQubitsStateStr: '|+⟩',
    initialQubitsState: [
      Complex(math.sqrt1_2, 0),
      Complex(math.sqrt1_2, 0),
    ],
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Build The Balance',
    taskDescription:
        r'Can we prepare uncertainty on purpose? Transform \( |1\rangle \) into the balanced \( |+\rangle \) state.',
    targetStateLabel: '|+⟩',
    targetStateExpression: '(|0⟩ + |1⟩)/√2',
    mysteryTitle: 'Can we prepare uncertainty on purpose?',
    mysteryText:
        'Superposition is not something that only happens by accident. Set up the input, then create the balanced state deliberately.',
    discoveryTitle: 'Prepared Possibilities',
    discoveryText:
        'You first prepared the right starting value, then created the balanced state. Superposition can be built intentionally.',
    keyInsight: 'Superposition can be prepared as part of a planned circuit.',
    whyItMatters:
        'Useful quantum circuits prepare the state they need before using it.',
    nextMystery: 'Can a superposition be only one step in a larger plan?',
    hints: [
      'Using H immediately from |1⟩ gives the wrong balanced state.',
      'First flip |1⟩ to |0⟩, then create |+⟩.',
    ],
    solutionExplanation:
        'X changes |1⟩ to |0⟩. H then creates |+⟩, the balanced superposition with equal |0⟩ and |1⟩ parts.',
    numQubits: 1,
    initialQubitsStateString: '1',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex(math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'What Is Superposition?',
    taskDescription:
        r'Can superposition be placed on one qubit inside a larger register? Transform \( |10\rangle \) into \( |+0\rangle \).',
    targetStateLabel: '|+0⟩',
    targetStateExpression: '(|00⟩ + |10⟩)/√2',
    mysteryTitle: 'Can only one qubit become superposed?',
    mysteryText:
        'A register can contain more than one qubit. Prepare the register, then place superposition only where it is needed.',
    discoveryTitle: 'Superposition',
    discoveryText:
        'Only one qubit became superposed while the other stayed definite. Superposition can be placed precisely inside a larger register.',
    keyInsight:
        'Superposition is a controllable resource; it does not have to affect every qubit.',
    whyItMatters:
        'Larger quantum circuits prepare specific qubits in superposition while keeping other qubits fixed for the next step.',
    nextMystery: 'Can prepared possibilities change what we measure next?',
    hints: [
      'The second qubit should stay 0 in the final state.',
      'First change |10⟩ to |00⟩, then apply H only to the first qubit.',
    ],
    solutionExplanation:
        'X changes the first ket position from 1 to 0, giving |00⟩. H on that same position then creates |+0⟩ = (|00⟩ + |10⟩)/√2 while the other qubit stays |0⟩.',
    numQubits: 2,
    initialQubitsStateString: '10',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Together',
    taskDescription:
        r'Can two qubits be prepared together? Transform \( |00\rangle \) into \( |11\rangle \).',
    targetStateExpression: '|11⟩',
    mysteryTitle: 'Can two qubits be prepared together?',
    mysteryText:
        'So far, one qubit has carried the story. Now there are two. Can you prepare a state that describes both qubits at once?',
    discoveryTitle: 'Two Qubits',
    discoveryText:
        'The state now describes a pair of qubits together. A quantum system can contain more than one qubit.',
    keyInsight: 'A quantum system can contain multiple qubits.',
    whyItMatters: 'Real quantum algorithms use many qubits at once.',
    nextMystery: 'Can two qubits become connected?',
    hints: [
      'Both qubits need to change from 0 to 1.',
      'Use one X on each qubit.',
    ],
    solutionExplanation:
        'Each X flips one qubit, preparing the combined two-qubit state |11⟩.',
    numQubits: 2,
    initialQubitsStateString: '00',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Connected',
    taskDescription:
        r'Can changing one qubit affect another? Use the controlled operation to transform \( |10\rangle \) into \( |11\rangle \).',
    targetStateExpression: '|11⟩',
    mysteryTitle: 'Can changing one qubit affect another?',
    mysteryText:
        'One qubit is already active. Can it act as a condition that changes the other qubit?',
    discoveryTitle: 'Correlation',
    discoveryText:
        'The second qubit changed only because the first qubit was set to 1. CNOT made one qubit control whether another qubit flipped.',
    keyInsight: 'The state of one qubit can influence another.',
    whyItMatters: 'Correlation is the first step toward entanglement.',
    nextMystery: 'Is correlation the same as entanglement?',
    hints: [
      'Use the qubit that is already 1 as the control.',
      'CNOT flips the target only when the control is 1.',
    ],
    solutionExplanation:
        'CNOT(Q0→Q1)|10⟩ = |11⟩. The first qubit is 1, so it triggers a flip on the second qubit.',
    numQubits: 2,
    initialQubitsStateString: '10',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'The Bell State',
    taskDescription:
        r'Can two qubits become one quantum system? Transform \( |00\rangle \) into Bell State \( \Phi^+ \).',
    targetStateLabel: '|Φ+⟩',
    targetStateExpression: '(|00⟩ + |11⟩)/√2',
    mysteryTitle: 'Can two qubits become one quantum system?',
    mysteryText:
        'A superposition can hold more than one possibility. A controlled operation can connect qubits. What happens when those ideas meet?',
    discoveryTitle: 'Bell State',
    discoveryText:
        'The result is not two independent qubits. The state belongs to the pair as a whole.',
    keyInsight: 'The two qubits can no longer be described independently.',
    whyItMatters:
        'Entanglement is one of the defining features of quantum computing.',
    nextMystery: 'What makes entanglement different from ordinary correlation?',
    hints: [
      'First create a split possibility on q0.',
      'Then connect q1 to q0 with CX.',
    ],
    solutionExplanation:
        'The circuit creates a state where the pair is either |00⟩ or |11⟩ together. That shared state is the Bell state Φ+.',
    numQubits: 2,
    initialQubitsStateString: '00',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'More Than Correlation',
    taskDescription:
        r'Why is entanglement special? Create a Bell state from \( |10\rangle \).',
    targetStateLabel: '|Ψ+⟩',
    targetStateExpression: '(|01⟩ + |10⟩)/√2',
    mysteryTitle: 'Why is entanglement special?',
    mysteryText:
        'Ordinary correlation says two values match. Entanglement is deeper: the whole pair has a state that cannot be assigned to each qubit separately.',
    discoveryTitle: 'One Quantum System',
    discoveryText:
        'The pair is now described as one shared quantum state. Looking for a separate state of each qubit is no longer enough.',
    keyInsight: 'Entangled qubits form a single quantum state.',
    whyItMatters:
        'Quantum communication and quantum algorithms rely on entanglement.',
    nextMystery: 'Can entanglement survive if we look at only one qubit?',
    hints: [
      'Start by splitting the first qubit into two possibilities.',
      'Then use CX to connect the second qubit to those possibilities.',
    ],
    solutionExplanation:
        'The circuit creates a Bell state with a hidden sign difference. The state belongs to the two-qubit system, not to either qubit alone.',
    numQubits: 2,
    initialQubitsStateString: '10',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex(math.sqrt1_2, 0)],
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'What Is Entanglement?',
    taskDescription:
        r'What have we actually discovered? Prepare the entangled state \( (|00\rangle - |11\rangle)/\sqrt{2} \).',
    targetStateLabel: '|Φ-⟩',
    targetStateExpression: '(|00⟩ - |11⟩)/√2',
    mysteryTitle: 'What have we actually discovered?',
    mysteryText:
        'You have seen two qubits act as one shared system. Prepare one more entangled state and focus on what cannot be described separately.',
    discoveryTitle: 'Entanglement',
    discoveryText:
        'The final state is a property of the pair. It cannot be explained as one independent state for q0 and another independent state for q1.',
    keyInsight:
        'Some quantum states cannot be broken into separate qubit descriptions.',
    whyItMatters:
        'Entanglement enables quantum communication, teleportation, and many quantum algorithms.',
    nextMystery:
        'If qubits can become one system, how does information move through that system?',
    hints: [
      'Begin with q1 set to 1.',
      'Create a split possibility on q0, then connect the qubits with CX.',
    ],
    solutionExplanation:
        'The circuit prepares an entangled pair where the possibilities |01⟩ and |10⟩ belong to the whole system.',
    numQubits: 2,
    initialQubitsStateString: '01',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(-math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'The Control Qubit',
    taskDescription:
        r'Can one qubit decide what happens to another? Use CX to transform \( |01\rangle \) into \( |11\rangle \).',
    targetStateExpression: '|11⟩',
    mysteryTitle: 'Can one qubit decide what happens to another?',
    mysteryText:
        'A two-qubit circuit can contain a decision: one qubit can determine whether another qubit changes.',
    discoveryTitle: 'Control',
    discoveryText:
        'The target changed only because the control was active. The operation was not just on one wire; it depended on information in another qubit.',
    keyInsight: 'One qubit can conditionally influence another.',
    whyItMatters: 'Quantum algorithms rely heavily on controlled operations.',
    nextMystery: 'Can information travel between qubits?',
    hints: [
      'The active qubit should control the other one.',
      'Use CX so the second qubit changes only when the control is active.',
    ],
    solutionExplanation:
        'CX used the active qubit as a condition and flipped the other qubit, producing |11⟩.',
    numQubits: 2,
    initialQubitsStateString: '01',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Conditional Action',
    taskDescription:
        r'Can the same gate behave differently depending on the input? Use CX on \( |00\rangle \).',
    targetStateExpression: 'CX|00⟩ = |00⟩',
    mysteryTitle:
        'Can the same gate behave differently depending on the input?',
    mysteryText:
        'A controlled operation does not always visibly change the bits. Its effect depends on the information already present.',
    discoveryTitle: 'Conditional Action',
    discoveryText:
        'The controlled operation was applied, but the target did not flip because the control was inactive.',
    keyInsight:
        'The effect of a gate can depend on the state of another qubit.',
    whyItMatters: 'Conditional logic is fundamental to quantum circuits.',
    nextMystery: 'Can information move from one qubit to another?',
    hints: [
      'There is only one gate available.',
      'Use CX and notice that the state can stay the same for a meaningful reason.',
    ],
    solutionExplanation:
        'CX checks the control. When the control is 0, the target is left alone.',
    numQubits: 2,
    initialQubitsStateString: '00',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
    ],
    validationMode: ValidationMode.unitary,
    targetUnitary: [
      [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
      [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
      [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
      [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Information Transfer',
    taskDescription:
        r'Can information be transferred between qubits? Create information on one qubit, then propagate it to the other.',
    targetStateExpression: '|11⟩',
    mysteryTitle: 'Can information be transferred between qubits?',
    mysteryText:
        'A circuit can create information on one qubit and then let that information affect another qubit.',
    discoveryTitle: 'Information Transfer',
    discoveryText:
        'The first change made one qubit active. The controlled step propagated that information across the two-qubit system.',
    keyInsight: 'Information can be propagated through a quantum circuit.',
    whyItMatters: 'Large algorithms coordinate information across many qubits.',
    nextMystery: 'Can information move in both directions?',
    hints: [
      'First create an active control.',
      'Then use CX to pass that information to the other qubit.',
    ],
    solutionExplanation:
        'X creates the active qubit. CX then uses that information to flip the other qubit, producing |11⟩.',
    numQubits: 2,
    initialQubitsStateString: '00',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Swap Places',
    taskDescription:
        r'Can two qubits exchange their information? Build a reusable SWAP circuit using only CX. It should swap any two-qubit input, including \( |10\rangle \rightarrow |01\rangle \).',
    targetStateExpression: 'SWAP gate',
    mysteryTitle: 'Can two qubits exchange their information?',
    mysteryText:
        'A shortcut can solve one displayed input. A true SWAP circuit must exchange the two qubits for every possible input.',
    discoveryTitle: 'Swap',
    discoveryText:
        'Three controlled steps build a reusable SWAP. Two CX gates can solve this one visible input, but the third step is what makes the exchange work as a general operation.',
    keyInsight:
        'A circuit can match one example without being the correct reusable operation.',
    whyItMatters:
        'Real quantum hardware often requires routing information between qubits.',
    nextMystery: 'What happens when many qubits share information?',
    hints: [
      'Do not only solve |10⟩ → |01⟩. Build the operation that swaps both qubits for any input.',
      'A full SWAP uses three CX gates: one direction, the other direction, then the first direction again.',
    ],
    solutionExplanation:
        'The three-CX pattern performs the SWAP operation for the whole two-qubit register: |00⟩ stays |00⟩, |01⟩ becomes |10⟩, |10⟩ becomes |01⟩, and |11⟩ stays |11⟩.',
    numQubits: 2,
    initialQubitsStateString: '10',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()],
      [Complex.zero()],
      [Complex.zero()],
    ],
    validationMode: ValidationMode.unitary,
    targetUnitary: [
      [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
      [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
      [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
      [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Information Flow',
    taskDescription:
        r'What have we actually learned? Create information on either qubit, then route it across the two-qubit system with the three-CX pattern.',
    targetStateExpression: 'Information routed',
    mysteryTitle: 'What have we actually learned?',
    mysteryText:
        'Controlled operations can move, redirect, and reshape information. Build a small circuit where information is created, then routed to the other qubit.',
    discoveryTitle: 'Information Flow',
    discoveryText:
        'The circuit did more than place gates in a row. It created information, then directed it through interactions between qubits. Either mirrored direction shows the same idea.',
    keyInsight:
        'Quantum circuits direct information through interactions between qubits.',
    whyItMatters:
        'Entanglement, GHZ states, phase kickback, and quantum algorithms all depend on information flow.',
    nextMystery: 'Can three qubits become one shared quantum system?',
    hints: [
      'First create information with X on either qubit.',
      'Then use the three-CX routing pattern to move that information to the other qubit. The mirrored direction is valid too.',
    ],
    solutionExplanation:
        'X creates the information, and the three-CX routing pattern moves it across the two-qubit system. The same routing idea works in either direction.',
    numQubits: 2,
    initialQubitsStateString: '00',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
      [Complex.zero()],
    ],
    validationMode: ValidationMode.unitary,
    targetUnitary: [
      [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
      [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
      [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
      [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
    ],
    alternateTargetUnitaries: [
      [
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
      ],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Three Qubits',
    taskDescription:
        r'What changes when we add a third qubit? Prepare the three-qubit state \( |111\rangle \).',
    targetStateExpression: '|111⟩',
    mysteryTitle: 'What changes when we add a third qubit?',
    mysteryText:
        'A third qubit widens the system. Start simply: prepare a clear three-qubit pattern and notice that the circuit now describes the whole register.',
    discoveryTitle: 'Three Qubits',
    discoveryText:
        'The system now contains more than a pair. Each qubit contributes to the shared state that the circuit transforms.',
    keyInsight: 'Quantum systems can contain many interacting qubits.',
    whyItMatters: 'Useful quantum algorithms require many qubits.',
    nextMystery: 'Can three qubits become connected?',
    hints: [
      'Each inactive qubit needs the same simple change.',
      'Use X on all three wires.',
    ],
    solutionExplanation:
        'Each X gate flips one qubit, preparing the three-qubit state |111⟩.',
    numQubits: 3,
    initialQubitsStateString: '000',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Shared Information',
    taskDescription:
        r'Can information flow across an entire system? Create one active qubit, then spread it to reach \( |111\rangle \).',
    targetStateExpression: '|111⟩',
    mysteryTitle: 'Can information flow across an entire system?',
    mysteryText:
        'Information does not have to stay local. A controlled step can pass it along, then another can extend it across the register.',
    discoveryTitle: 'Shared Information',
    discoveryText:
        'One active qubit became a source for the rest of the system. Controlled operations spread that information across multiple qubits.',
    keyInsight: 'Information can spread through multiple qubits.',
    whyItMatters: 'Large quantum states emerge from connected interactions.',
    nextMystery: 'Can all three qubits share the same state?',
    hints: [
      'First create one active control.',
      'Use CX twice so the active information reaches the other two qubits.',
    ],
    solutionExplanation:
        'X creates the first active qubit, then two CX gates propagate that information through the three-qubit system.',
    numQubits: 3,
    initialQubitsStateString: '000',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.one()],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'All Together',
    taskDescription:
        r'Can three qubits become one shared system? Prepare \( (|000\rangle + |111\rangle)/\sqrt{2} \).',
    targetStateLabel: '|GHZ+⟩',
    targetStateExpression: '(|000⟩ + |111⟩)/√2',
    mysteryTitle: 'Can three qubits become one shared system?',
    mysteryText:
        'A Bell pair showed two qubits acting as one. Now ask whether a whole three-qubit register can share one quantum state.',
    discoveryTitle: 'All Together',
    discoveryText:
        'The final state is not one qubit plus another plus another. The possibilities belong to the full three-qubit system.',
    keyInsight: 'The entire system now behaves as one quantum state.',
    whyItMatters: 'This is the first example of large-scale entanglement.',
    nextMystery: 'Is this just a bigger Bell State?',
    hints: [
      'Start by creating a split possibility on one qubit.',
      'Use controlled operations to connect that split to the other two qubits.',
    ],
    solutionExplanation:
        'The first qubit enters a superposition, then CX gates connect the other qubits so the whole register shares |000⟩ and |111⟩.',
    numQubits: 3,
    initialQubitsStateString: '000',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'Beyond Bell States',
    taskDescription:
        r'How is a GHZ state different from a Bell State? Prepare \( (|000\rangle + |111\rangle)/\sqrt{2} \).',
    targetStateLabel: '|GHZ+⟩',
    targetStateExpression: '(|000⟩ + |111⟩)/√2',
    mysteryTitle: 'How is a GHZ state different from a Bell State?',
    mysteryText:
        'A Bell state connects a pair. A GHZ state asks you to think wider: the shared state can involve an entire system.',
    discoveryTitle: 'GHZ State',
    discoveryText:
        'This is not just pairwise correlation copied one more time. The three-qubit register is described as one shared quantum state.',
    keyInsight: 'Entanglement can involve an entire system, not just a pair.',
    whyItMatters: 'Real quantum algorithms manipulate large entangled systems.',
    nextMystery: 'What happens if hidden phase enters a shared state?',
    hints: [
      'Create a superposition first.',
      'Then use control to make the other two qubits share the same alternatives.',
    ],
    solutionExplanation:
        'A superposition on one qubit is spread through two CX gates, producing the three-qubit GHZ state.',
    numQubits: 3,
    initialQubitsStateString: '000',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(math.sqrt1_2, 0)],
    ],
  ),

  ComposerLevel.fromBinaryString(
    title: 'One System, Three Qubits',
    taskDescription:
        r'What have we actually discovered? Prepare \( (|000\rangle - |111\rangle)/\sqrt{2} \).',
    targetStateLabel: '|GHZ-⟩',
    targetStateExpression: '(|000⟩ - |111⟩)/√2',
    mysteryTitle: 'What have we actually discovered?',
    mysteryText:
        'One final shared state includes hidden phase. Prepare it and focus on the whole register rather than any individual qubit.',
    discoveryTitle: 'One System, Three Qubits',
    discoveryText:
        'The three qubits form a single state. Even the phase belongs to the shared system, not to one isolated wire.',
    keyInsight: 'Multiple qubits can form a single shared quantum state.',
    whyItMatters:
        'Phase kickback, quantum algorithms, and large-scale quantum computation rely on thinking about systems rather than individual qubits.',
    nextMystery:
        'Can information be stored in phase and spread across a quantum system?',
    hints: [
      'Use the same shared-state idea as before.',
      'The minus sign can be introduced before the information is shared.',
    ],
    solutionExplanation:
        'A phase-marked superposition is spread across the register, creating a GHZ-style state with a relative minus sign.',
    numQubits: 3,
    initialQubitsStateString: '000',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.cnot),
    ],
    solutionFinalVector: [
      [Complex(math.sqrt1_2, 0)],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex.zero()],
      [Complex(-math.sqrt1_2, 0)],
    ],
  ),
];

ComposerLevel _chapter4InterferenceFinale() {
  return ComposerLevel.fromBinaryString(
    title: 'What Is Interference?',
    taskDescription:
        r'The circuit already created and phase-marked two paths. Add the final gate that turns the hidden phase into \( |1\rangle \).',
    targetStateExpression: '|1⟩',
    mysteryTitle: 'What have we actually discovered?',
    mysteryText:
        'The pre-built H→Z has prepared |−⟩. One final basis change can make that hidden phase show up as a visible measurement result.',
    discoveryTitle: 'Interference',
    discoveryText:
        'Interference happened when the final H recombined the phase-marked paths. The |0⟩ outcome cancelled, the |1⟩ outcome reinforced, and the hidden phase became visible.',
    keyInsight:
        'Interference turns hidden phase differences into visible probability changes.',
    whyItMatters:
        'Quantum algorithms use this pattern to make useful hidden structure measurable.',
    nextMystery: 'Can two qubits become one quantum system?',
    hints: [
      'The pre-built gates already created |−⟩.',
      'Use H to recombine the paths and reveal the phase as |1⟩.',
    ],
    solutionExplanation:
        'The pre-built H creates two paths and Z changes their relative phase. The final H recombines them, making |0⟩ cancel and |1⟩ survive.',
    numQubits: 1,
    initialQubitsStateString: '0',
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.hadamard),
    ],
    solutionFinalVector: [
      [Complex.zero()],
      [Complex.one()],
    ],
    preInsertedGates: (QuantumCircuit circuit) {
      circuit.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
        isDeletable: false,
      );
      circuit.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.z),
        1,
        0,
        isDeletable: false,
      );
    },
  );
}

final List<QQLevel> allQQLevels = _consolidatedQQLevels();

List<QQLevel> _consolidatedQQLevels() {
  final chapter1Information = _authoredQQLevels.sublist(73, 78);
  final chapter2HiddenChange = _authoredQQLevels.sublist(78, 83);
  final chapter3Superposition = _authoredQQLevels.sublist(83, 88);
  final chapter4Interference = [
    ..._authoredQQLevels.sublist(54, 58),
    _chapter4InterferenceFinale(),
  ];
  final chapter5Entanglement = _authoredQQLevels.sublist(88, 93);
  final chapter6InformationFlow = _authoredQQLevels.sublist(93, 98);
  // TODO Chapter 7 readiness check:
  // Validate GHZ introduction does not reuse SWAP routing mechanics.
  // Ensure entanglement scaling is conceptually distinct from Chapter 5.
  // Avoid overlapping incorrectly with Chapter 3 superposition foundations and
  // Chapter 4 interference concepts.
  final chapter7GhzStates = _authoredQQLevels.sublist(98, 103);
  final chapter8PhaseKickback = _authoredQQLevels.sublist(58, 63);
  final chapter9OracleThinking = _authoredQQLevels.sublist(63, 68);
  final chapter10AmplitudeAmplification = _authoredQQLevels.sublist(68, 73);
  final legacyChallenges = _authoredQQLevels.sublist(0, 54);

  return [
    ...chapter1Information,
    ...chapter2HiddenChange,
    ...chapter3Superposition,
    ...chapter4Interference,
    ...chapter5Entanglement,
    ...chapter6InformationFlow,
    ...chapter7GhzStates,
    ...chapter8PhaseKickback,
    ...chapter9OracleThinking,
    ...chapter10AmplitudeAmplification,
    ...legacyChallenges,
  ];
}

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
    taskDescription:
        r"Experiment with any combination of gates on your chosen number of qubits. Build circuits, visualize the resulting quantum state, and generate the overall unitary operator matrix for your circuit.",
    numQubits: numQubits,
    initialQubitsStateString: "0" * numQubits,
    availableGates: [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.y),
      Gate.fromIdentifier(SelectedGateType.z),
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.s),
      Gate.fromIdentifier(SelectedGateType.t),
      Gate.fromIdentifier(SelectedGateType.cz),
      Gate.fromIdentifier(SelectedGateType.cnot),
      Gate.fromIdentifier(SelectedGateType.ccnot),
      Gate.fromIdentifier(SelectedGateType.rx),
      Gate.fromIdentifier(SelectedGateType.ry),
      Gate.fromIdentifier(SelectedGateType.rz),
    ],
    solutionFinalVector: List.empty(),
  );
}

final List<QQLevelsCategory> groupedLevels = [
  QQLevelsCategory(
    groupName: 'Chapter 1 - Information',
    from: 0,
    to: 4,
    categoryIntro:
        'Begin with the first mystery: what is a qubit? This chapter treats gates as tools for investigating information, not as vocabulary to memorize.',
  ),
  QQLevelsCategory(
    groupName: 'Chapter 2 - Hidden Change',
    from: 5,
    to: 9,
    categoryIntro:
        'Not every quantum change shows up in measurement right away. This chapter follows the first hidden trail from invisible changes to phase.',
  ),
  QQLevelsCategory(
    groupName: 'Chapter 3 - Superposition',
    from: 10,
    to: 14,
    categoryIntro:
        'A qubit is not limited to ordinary 0-or-1 behavior. This chapter lets players discover states that hold multiple possibilities at once.',
  ),
  QQLevelsCategory(
    groupName: 'Chapter 4 - Interference',
    from: 15,
    to: 19,
    categoryIntro:
        'Phase can feel invisible because measurement probabilities do not always change right away. This chapter follows the trail from hidden phase to interference.',
  ),
  QQLevelsCategory(
    groupName: 'Chapter 5 - Entanglement',
    from: 20,
    to: 24,
    categoryIntro:
        'Two qubits can be more than two independent objects. This chapter introduces correlation, Bell states, and the first true multi-qubit quantum phenomenon.',
  ),
  QQLevelsCategory(
    groupName: 'Chapter 6 - Information Flow',
    from: 25,
    to: 29,
    categoryIntro:
        'Controlled operations let information influence, transfer, and route through a quantum system. This chapter prepares players for larger shared states.',
  ),
  QQLevelsCategory(
    groupName: 'Chapter 7 - GHZ States',
    from: 30,
    to: 34,
    categoryIntro:
        'Entanglement is not limited to pairs. This chapter widens the player\'s view from two-qubit connections to a shared three-qubit quantum system.',
  ),
  QQLevelsCategory(
    groupName: 'Chapter 8 - Phase Kickback',
    from: 35,
    to: 39,
    categoryIntro:
        'Phase kickback is the hidden mechanism that lets controlled operations write information into phase, then reveal it through interference.',
  ),
  QQLevelsCategory(
    groupName: 'Chapter 9 - Oracle Thinking',
    from: 40,
    to: 44,
    categoryIntro:
        'An oracle does not search for an answer directly. It marks the desired solution in phase, creating the hidden label that interference can later amplify.',
  ),
  QQLevelsCategory(
    groupName: 'Chapter 10 - Amplitude Amplification',
    from: 45,
    to: 49,
    categoryIntro:
        'Amplitude amplification turns an oracle phase mark into a higher chance of measuring the marked answer. This chapter builds the first Mini Grover intuition: mark, then amplify.',
  ),
  QQLevelsCategory(
    groupName: 'Legacy Challenges',
    from: 50,
    to: 103,
    categoryIntro:
        'Optional earlier Qubit Quest challenges preserved for practice and reference. These levels are playable but are not part of the main discovery campaign.',
  ),
];
