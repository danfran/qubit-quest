// Chapter 14 — Conditional Quantum Logic (v2.6 M10).
//
// Register convention |q(n−1)…q0⟩: amplitude index bit k is qubit k; q0 is
// the top wire. Operator targets below are written from their definitions
// (permutations, diagonal signs, Kronecker products of 2×2 gates), not
// derived from learner circuits or from the simulator.
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

// ------------------------------------------------------------ matrices

typedef ComplexMatrix = List<List<Complex>>;

/// The permutation matrix sending basis |c⟩ to |f(c)⟩ (column c, row f(c)).
ComplexMatrix permutationMatrix(int qubits, int Function(int) f) {
  final n = 1 << qubits;
  return [
    for (var r = 0; r < n; r++)
      [for (var c = 0; c < n; c++) f(c) == r ? Complex.one() : Complex.zero()]
  ];
}

/// The diagonal matrix with ±1 on basis |c⟩.
ComplexMatrix signMatrix(int qubits, bool Function(int) negated) {
  final n = 1 << qubits;
  return [
    for (var r = 0; r < n; r++)
      [
        for (var c = 0; c < n; c++)
          r != c
              ? Complex.zero()
              : (negated(c) ? Complex(-1, 0) : Complex.one())
      ]
  ];
}

/// ⊗ of single-qubit 2×2 matrices; [perQubit][k] acts on qubit k.
ComplexMatrix kroneckerByQubit(List<List<List<double>>> perQubit) {
  final n = 1 << perQubit.length;
  return [
    for (var r = 0; r < n; r++)
      [
        for (var c = 0; c < n; c++)
          Complex(
              [
                for (var k = 0; k < perQubit.length; k++)
                  perQubit[k][(r >> k) & 1][(c >> k) & 1]
              ].fold<double>(1, (a, b) => a * b),
              0)
      ]
  ];
}

ComplexMatrix matrixProduct(ComplexMatrix a, ComplexMatrix b) => [
      for (var r = 0; r < a.length; r++)
        [
          for (var c = 0; c < b.first.length; c++)
            [for (var k = 0; k < b.length; k++) a[r][k] * b[k][c]]
                .fold<Complex>(Complex.zero(), (x, y) => x + y)
        ]
    ];

final double _h = math.sqrt1_2;
final List<List<double>> _hadamard = [
  [_h, _h],
  [_h, -_h]
];
// H·X: X first, then H (prepares |−⟩ from |0⟩).
final List<List<double>> _hadamardAfterX = [
  [_h, _h],
  [-_h, _h]
];

List<List<Complex>> _column(int qubits, Map<int, Complex> amplitudes) => [
      for (var i = 0; i < 1 << qubits; i++) [amplitudes[i] ?? Complex.zero()]
    ];

Gate _g(SelectedGateType t) => Gate.fromIdentifier(t);

// ------------------------------------------------------- lesson 14.2

/// MCX with controls q0, q2, q3 and target q1 (5 qubits).
final lesson142Target = permutationMatrix(
    5, (c) => (c & 0x0D) == 0x0D ? c ^ 0x02 : c); // 0x0D = q0,q2,q3

// ------------------------------------------------------- lesson 14.5

/// Oracle predicate on q3 q2 q1 q0: the pattern 1010 (q0=0, q1=1, q2=0,
/// q3=1). The auxiliary qubit is q4.
const int oraclePattern = 0x0A;

/// Bit oracle U_f: inputs x = q3…q0 unchanged, auxiliary y = q4 → y ⊕ f(x).
final oracleBitOperator =
    permutationMatrix(5, (c) => (c & 0x0F) == oraclePattern ? c ^ 0x10 : c);

/// Phase oracle on the input register only, auxiliary untouched.
final oraclePhaseOperator =
    signMatrix(5, (c) => (c & 0x0F) == oraclePattern);

/// The fixed preparation: H on q0–q3 (all inputs at once) and X then H on
/// q4 (auxiliary |−⟩).
final oraclePreparation = kroneckerByQubit(
    [_hadamard, _hadamard, _hadamard, _hadamard, _hadamardAfterX]);

/// Accepted chronological operators: preparation, then the oracle. With the
/// auxiliary prepared in |−⟩ both constructions mark exactly the pattern
/// with −1 and return the auxiliary to |−⟩. They differ only on inputs the
/// preparation never produces (auxiliary starting in |1⟩), so both are
/// accepted (the subspace contract, expressed as two exact operators).
final lesson145Target = matrixProduct(oracleBitOperator, oraclePreparation);
final lesson145Alternate =
    matrixProduct(oraclePhaseOperator, oraclePreparation);

// ------------------------------------------------------------- lessons

final List<QQLevel> chapter14Lessons = [
  // 14.1
  ComposerLevel.fromBinaryString(
    title: 'More Than a Controlled Flip',
    taskDescription:
        r'The fixed H and CY have prepared \((|00\rangle+i|11\rangle)/\sqrt{2}\). Add gates so that a Z-basis measurement gives \(|01\rangle\) with certainty. The same added gates applied to the CX state \((|00\rangle+|11\rangle)/\sqrt{2}\) would give 50/50.',
    conceptIntro:
        r'H on q0 then CX(q0→q1) gives \((|00\rangle+|11\rangle)/\sqrt{2}\); H then CY(q0→q1) gives \((|00\rangle+i|11\rangle)/\sqrt{2}\). Measured in the Z basis both give 50% |00⟩ and 50% |11⟩, yet they are different states: they differ by the relative phase i. Labels are |q1 q0⟩.',
    mysteryTitle: 'Can two states with the same odds behave differently?',
    mysteryText:
        'Equal measurement probabilities do not make two states equal. Interference can turn a relative phase into a certain outcome.',
    hints: [
      'First undo the correlation: a CX from q0 to q1 leaves q1 in |0⟩ and moves the phase onto q0 alone.',
      r'q0 is then (|0⟩ + i|1⟩)/√2. Which phase gate turns that i into −1, giving |−⟩?',
      'H turns |−⟩ into |1⟩.',
    ],
    solutionExplanation:
        r'CX(q0→q1) gives (|00⟩ + i|01⟩)/√2: q0 alone is (|0⟩ + i|1⟩)/√2. S multiplies |1⟩ by i, giving (|0⟩ − |1⟩)/√2 = |−⟩, and H turns |−⟩ into |1⟩: the result is |01⟩ with certainty. On the CX state the same three gates give ((1 + i)|00⟩ + (1 − i)|01⟩)/2: 50/50. CY is not just a controlled flip; its phase i is physical, and interference reveals it.',
    discoveryTitle: 'Conditional Phase',
    discoveryText:
        'CX and CY prepare states with identical Z-basis probabilities but different relative phases. A later circuit can make that phase decide the outcome.',
    keyInsight:
        'A conditional operation can change a phase, and a phase can be made observable.',
    whyItMatters:
        'Algorithms use conditional phases as information that only interference reads.',
    nextMystery: 'What if a condition depends on several qubits at once?',
    initialQubitsStateString: '00',
    preInsertedGates: (circuit) {
      circuit.insertSinglePlacedGateAt(
          _g(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
      circuit.insertDoublePlacedGateAt(_g(SelectedGateType.cy), 1, 1, 0,
          isDeletable: false);
    },
    availableGates: [
      _g(SelectedGateType.cnot),
      _g(SelectedGateType.s),
      _g(SelectedGateType.hadamard),
    ],
    solutionFinalVector: _column(2, {1: Complex.one()}),
    targetStateExpression: '|01⟩',
    validationMode: ValidationMode.physicalState,
    canonicalSolution: CanonicalComposerSolution(const [
      CanonicalCircuitStep.controlled(SelectedGateType.cnot,
          controlQubit: 0, targetQubit: 1),
      CanonicalCircuitStep.single(SelectedGateType.s, targetQubit: 0),
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
    ]),
    conceptsUsed: ['relative phase', 'controlled operations', 'interference'],
    relatedDiscoveryTitles: ['Relative Phase', 'Entanglement'],
  ),
  // 14.2
  ComposerLevel.fromBinaryString(
    title: 'When Every Condition Holds',
    taskDescription:
        'Build a multi-controlled X that flips q1 exactly when q0, q2 and q3 are all 1. q4 is not part of the condition. Check Result tests the complete operator on all 32 inputs.',
    conceptIntro:
        'CX has one control and CCX two; MCX generalises them: t → t ⊕ (c₁c₂…cₖ). The controls are never changed, and applying the same MCX twice restores every input. Labels are |q4 q3 q2 q1 q0⟩.',
    mysteryTitle: 'Does one missing condition really stop the flip?',
    mysteryText:
        'The displayed input |01101⟩ satisfies the condition, so q1 flips to |01111⟩. An X on q1 would give the same display, but not the same operation on the other 31 inputs.',
    hints: [
      'Drop the MCX on the target wire, q1, then choose the controls.',
      'The chooser starts with every other qubit selected. Which of them is not part of the condition?',
    ],
    solutionExplanation:
        'MCX(q0,q2,q3 → q1) maps |q4 q3 q2 q1 q0⟩ to the same label with q1 ⊕ (q0·q2·q3). For |01101⟩ all three controls are 1, so q1 flips: |01111⟩. With q2 = 0 instead (|01001⟩) nothing changes. Including q4 as a control would block the flip here, because q4 = 0. A second identical MCX undoes the first. This is reversible logic, not an AND that discards its inputs.',
    discoveryTitle: 'Multi-Controlled Logic',
    discoveryText:
        'A multi-controlled X flips its target only in the basis components where every control is 1, and leaves the controls unchanged.',
    keyInsight: 'Every control matters: one 0 among the controls blocks the flip.',
    whyItMatters:
        'Conditions over several bits are the building blocks of oracles and reversible arithmetic.',
    nextMystery: 'What happens if the controls are in superposition?',
    initialQubitsStateString: '01101',
    availableGates: [
      _g(SelectedGateType.mcx),
      _g(SelectedGateType.ccnot),
      _g(SelectedGateType.x),
    ],
    solutionFinalVector: _column(5, {0x0F: Complex.one()}),
    targetStateExpression: '|01111⟩',
    validationMode: ValidationMode.unitary,
    targetUnitary: lesson142Target,
    canonicalSolution: CanonicalComposerSolution(const [
      CanonicalCircuitStep.multiControlledX(
          controlQubits: [0, 2, 3], targetQubit: 1),
    ]),
    conceptsUsed: ['multi-controlled X', 'reversibility', 'controls'],
    relatedDiscoveryTitles: ['Control', 'Reversibility'],
  ),
  // 14.3
  ComposerLevel.fromBinaryString(
    title: 'Conditions in Superposition',
    taskDescription:
        r'Prepare q0, q1 and q2 each in \(|+\rangle\), then apply MCX(q0,q1,q2 → q3). The target q3 starts in |0⟩. Build the joint state \(\frac{1}{\sqrt{8}}\big(|0000\rangle+\dots+|0110\rangle+|1111\rangle\big)\).',
    conceptIntro:
        'With three controls in superposition, the register holds all eight control patterns at once. MCX acts on every component: it flips q3 only alongside 111. Nothing is measured, and no classical decision is made.',
    mysteryTitle: 'Who decides whether the target flips?',
    mysteryText:
        'No one does. The result is one coherent joint state in which q3 is 1 in exactly one of eight equally weighted components.',
    hints: [
      'H on each control prepares |+⟩ ⊗ |+⟩ ⊗ |+⟩: eight equal amplitudes.',
      'Drop the MCX on q3 and keep exactly q0, q1 and q2 as controls.',
    ],
    solutionExplanation:
        r'After the H gates every label |0 x⟩ (x = 000…111) has amplitude 1/√8. MCX changes only |0111⟩ into |1111⟩. Measured in the Z basis, q3 gives 0 with probability 7/8 = 87.5% and 1 with probability 1/8 = 12.5%, but those marginals do not describe the state: q3 is correlated with its controls, and the eight components keep their amplitudes. The target holds the AND of the controls in every component, reversibly.',
    discoveryTitle: 'Coherent Conditions',
    discoveryText:
        'Superposed controls make a controlled operation act on every component at once, producing one joint state, not a random decision.',
    keyInsight:
        'A condition evaluated in superposition creates correlation, not a measurement.',
    whyItMatters:
        'Oracles evaluate their predicate on every input component in a single pass.',
    nextMystery: 'Can the result of a condition be stored as a phase instead of a bit?',
    initialQubitsStateString: '0000',
    availableGates: [
      _g(SelectedGateType.hadamard),
      _g(SelectedGateType.mcx),
      _g(SelectedGateType.ccnot),
      _g(SelectedGateType.x),
    ],
    solutionFinalVector: _column(4, {
      for (var i = 0; i < 7; i++) i: Complex(1 / math.sqrt(8), 0),
      15: Complex(1 / math.sqrt(8), 0),
    }),
    targetStateExpression: '(|0000⟩ + |0001⟩ + … + |0110⟩ + |1111⟩)/√8',
    validationMode: ValidationMode.finalState,
    canonicalSolution: CanonicalComposerSolution(const [
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 1),
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 2),
      CanonicalCircuitStep.multiControlledX(
          controlQubits: [0, 1, 2], targetQubit: 3),
    ]),
    conceptsUsed: ['superposition', 'multi-controlled X', 'joint state'],
    relatedDiscoveryTitles: ['Superposition', 'Correlation'],
  ),
  // 14.4
  ComposerLevel.fromBinaryString(
    title: 'From Conditions to Phase',
    taskDescription:
        r'The fixed gates put q0–q2 in \(|+\rangle\) and the auxiliary q3 in \(|-\rangle\). Apply one MCX so that the component |111⟩ of the inputs gains a minus sign while every label and the auxiliary stay unchanged.',
    conceptIntro:
        r'X|−⟩ = −|−⟩. So when MCX targets an auxiliary in |−⟩, the target does not change; instead the components that satisfy every control gain a factor −1. This is phase kickback with several controls.',
    mysteryTitle: 'Can a condition leave a mark without flipping a bit?',
    mysteryText:
        'Look at the input labels after the MCX: none changes. Only one sign does, and the auxiliary is still |−⟩.',
    hints: [
      'Target the auxiliary wire, q3, and use q0, q1 and q2 as controls.',
      'Compare the amplitudes before and after: every |q3 = 0⟩ term and its |q3 = 1⟩ partner keep their sizes.',
    ],
    solutionExplanation:
        r'Before the MCX the state is |−⟩ ⊗ (1/√8) Σₓ |x⟩, with the auxiliary q3 written first as in |q3 q2 q1 q0⟩. MCX applies X to the auxiliary only in the |111⟩ component, and X|−⟩=−|−⟩, so the result is |−⟩ ⊗ (1/√8) Σₓ (−1)^[x=111] |x⟩. The input labels are unchanged and the auxiliary is still |−⟩, separate from the inputs, so it never needs to be measured. Z-basis probabilities are unchanged too: the mark is a relative phase that a later interference step can use.',
    discoveryTitle: 'Condition Becomes Phase',
    discoveryText:
        'An MCX aimed at an auxiliary in |−⟩ writes its condition as a minus sign on the satisfying inputs and leaves the auxiliary unchanged.',
    keyInsight:
        'Phase kickback turns "the condition holds" into a relative sign.',
    whyItMatters:
        'Phase oracles mark solutions this way so that amplitude amplification can find them.',
    nextMystery: 'How do you mark a pattern that contains zeros as well as ones?',
    initialQubitsStateString: '0000',
    preInsertedGates: (circuit) {
      for (final q in [0, 1, 2]) {
        circuit.insertSinglePlacedGateAt(
            _g(SelectedGateType.hadamard), 0, q,
            isDeletable: false);
      }
      circuit.insertSinglePlacedGateAt(_g(SelectedGateType.x), 0, 3,
          isDeletable: false);
      circuit.insertSinglePlacedGateAt(_g(SelectedGateType.hadamard), 1, 3,
          isDeletable: false);
    },
    availableGates: [
      _g(SelectedGateType.mcx),
      _g(SelectedGateType.ccnot),
      _g(SelectedGateType.x),
      _g(SelectedGateType.hadamard),
    ],
    // (1/√8)(−1)^[x=111]|x⟩ ⊗ (|0⟩−|1⟩)/√2: amplitude ±1/4.
    solutionFinalVector: _column(4, {
      for (var b = 0; b < 16; b++)
        b: Complex(
            ((b & 7) == 7 ? -1.0 : 1.0) * ((b & 8) == 0 ? 1.0 : -1.0) / 4,
            0),
    }),
    targetStateExpression: '|−⟩ ⊗ (|000⟩ + |001⟩ + … + |110⟩ − |111⟩)/√8',
    validationMode: ValidationMode.physicalState,
    canonicalSolution: CanonicalComposerSolution(const [
      CanonicalCircuitStep.multiControlledX(
          controlQubits: [0, 1, 2], targetQubit: 3),
    ]),
    conceptsUsed: ['phase kickback', 'auxiliary qubit', 'phase marking'],
    relatedDiscoveryTitles: ['Phase Marking', 'Invisible Mark'],
  ),
  // 14.5
  ComposerLevel.fromBinaryString(
    title: 'Building a Reusable Oracle',
    taskDescription:
        'The fixed gates prepare every input of q0–q3 at once and put the auxiliary q4 in |−⟩. Build a reusable phase oracle that negates exactly the input |q3 q2 q1 q0⟩ = |1010⟩, leaves every input label unchanged and returns the auxiliary to |−⟩. Check Result tests the complete operator.',
    conceptIntro:
        'MCX fires only when every control is 1, but the pattern 1010 has two zeros. Temporarily flip the zero-valued inputs with X, apply the multi-controlled construction onto the auxiliary, then undo the temporary flips. Preparing inputs, computing a condition, writing it as a phase, and removing temporary changes are separate steps.',
    mysteryTitle: 'Why must the temporary flips be undone?',
    mysteryText:
        'Without the final X gates the right sign is produced, but the inputs are relabelled: the operation is no longer an oracle another algorithm can reuse.',
    hints: [
      'Which input qubits are 0 in the pattern? Those need an X before the MCX.',
      'Aim the MCX at q4 with q0–q3 as controls.',
      'Repeat the X gates afterwards so every input label is restored.',
    ],
    solutionExplanation:
        'X on q0 and q2, MCX(q0,q1,q2,q3 → q4), then X on q0 and q2 again. The MCX now fires exactly for 1010; because the auxiliary is |−⟩ it kicks back −1 onto that input. The final X gates undo the relabelling, so the inputs are unchanged and the auxiliary stays |−⟩, separate from them. Matching probabilities is not enough here (a phase mark changes none); Check Result compares the whole operation. An equivalent construction that puts H around an input qubit (a multi-controlled Z) is also accepted: on the prepared |−⟩ auxiliary both act identically.',
    discoveryTitle: 'Reusable Phase Oracle',
    discoveryText:
        'Temporary X gates, a multi-controlled X onto an auxiliary |−⟩, and the uncomputing X gates make a phase oracle for any bit pattern.',
    keyInsight:
        'Compute the condition, write it as a phase, then uncompute everything temporary.',
    whyItMatters:
        'A search algorithm can call this oracle repeatedly only if it leaves no trace except the phase.',
    nextMystery:
        'How would amplitude amplification use this oracle on four input qubits?',
    initialQubitsStateString: '00000',
    preInsertedGates: (circuit) {
      for (final q in [0, 1, 2, 3]) {
        circuit.insertSinglePlacedGateAt(
            _g(SelectedGateType.hadamard), 0, q,
            isDeletable: false);
      }
      circuit.insertSinglePlacedGateAt(_g(SelectedGateType.x), 0, 4,
          isDeletable: false);
      circuit.insertSinglePlacedGateAt(_g(SelectedGateType.hadamard), 1, 4,
          isDeletable: false);
    },
    availableGates: [
      _g(SelectedGateType.x),
      _g(SelectedGateType.mcx),
      _g(SelectedGateType.hadamard),
    ],
    // |−⟩ ⊗ (1/4)Σ(−1)^[x=1010]|x⟩ (q4 first): amplitude ±1/√32.
    solutionFinalVector: _column(5, {
      for (var b = 0; b < 32; b++)
        b: Complex(
            ((b & 15) == oraclePattern ? -1.0 : 1.0) *
                ((b & 16) == 0 ? 1.0 : -1.0) /
                math.sqrt(32),
            0),
    }),
    targetStateExpression:
        '|−⟩ ⊗ (|0000⟩ + … + |1001⟩ − |1010⟩ + |1011⟩ + … + |1111⟩)/4',
    validationMode: ValidationMode.unitary,
    targetUnitary: lesson145Target,
    alternateTargetUnitaries: [lesson145Alternate],
    canonicalSolution: CanonicalComposerSolution(const [
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 2),
      CanonicalCircuitStep.multiControlledX(
          controlQubits: [0, 1, 2, 3], targetQubit: 4),
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 2),
    ]),
    conceptsUsed: ['oracle', 'uncomputation', 'phase kickback'],
    relatedDiscoveryTitles: ['Phase Marking', 'Oracle'],
  ),
];
