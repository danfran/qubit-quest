import 'dart:math' as math;

import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

/// Executable examples owned by Notebook *gate reference* articles (v2.6 M7).
///
/// Discovery-entry examples live in `executableNotebookExamples` and are
/// attached to Journey entries; these belong to the always-available gate
/// articles (CY, MCX), so they never alter authored lesson content. Same
/// class, same simulator validation (`resultMatchesExpected`).
///
/// Kets are written |q(n−1)…q0⟩: amplitude index bit k is qubit k, and
/// [ExecutableNotebookExample.initialBinaryState] is most significant first.
const _h0 =
    CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0);
const _cy01 = CanonicalCircuitStep.controlled(SelectedGateType.cy,
    controlQubit: 0, targetQubit: 1);
const _mcx012to3 = CanonicalCircuitStep.multiControlledX(
    controlQubits: [0, 1, 2], targetQubit: 3);

const _a0 = NotebookAmplitude(0);
List<NotebookAmplitude> _basis(int qubits, Map<int, NotebookAmplitude> amps) =>
    [for (var i = 0; i < 1 << qubits; i++) amps[i] ?? _a0];

final List<ExecutableNotebookExample> gateReferenceExamples = [
  // ---- T (v2.6 M8: a Bloch Explorer example for the T article) ----
  ExecutableNotebookExample(
    id: 't_on_plus',
    title: 'T turns |+⟩ by π/4 about Z',
    description: 'H then T: (|0⟩ + e^{iπ/4}|1⟩)/√2. The relative phase grows '
        'by π/4, so the Bloch vector turns an eighth of a circle around the '
        'equator; Z-basis probabilities stay 50/50.',
    qubitCount: 1,
    initialBinaryState: '0',
    operations: const [
      _h0,
      CanonicalCircuitStep.single(SelectedGateType.t, targetQubit: 0),
    ],
    expectedState: const [
      NotebookAmplitude(math.sqrt1_2),
      NotebookAmplitude(.5, .5),
    ],
    allowOpenInBlochExplorer: true,
  ),
  // ---- Controlled-Y ----
  ExecutableNotebookExample(
    id: 'cy_inactive_control',
    title: 'Inactive control: nothing happens',
    description: 'X prepares q1 in |1⟩ while the control q0 stays |0⟩. CY '
        'leaves |10⟩ exactly as it was: no flip and no phase.',
    qubitCount: 2,
    initialBinaryState: '00',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 1),
      _cy01,
    ],
    expectedState: _basis(2, {2: const NotebookAmplitude(1)}),
  ),
  ExecutableNotebookExample(
    id: 'cy_active_control',
    title: 'Active control: a flip with a phase',
    description: 'With the control q0 in |1⟩, CY applies Y to the target: '
        '|01⟩ → i|11⟩. The bit flips like CX, and the amplitude also gains '
        'the factor i.',
    qubitCount: 2,
    initialBinaryState: '00',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
      _cy01,
    ],
    expectedState: _basis(2, {3: const NotebookAmplitude(0, 1)}),
  ),
  ExecutableNotebookExample(
    id: 'cy_twice',
    title: 'CY twice restores the state',
    description: 'CY is its own inverse (CY² = I): after H on q0, two CY '
        'gates return (|00⟩ + |01⟩)/√2, the state before them.',
    qubitCount: 2,
    initialBinaryState: '00',
    operations: const [_h0, _cy01, _cy01],
    expectedState: _basis(2, {
      0: const NotebookAmplitude(math.sqrt1_2),
      1: const NotebookAmplitude(math.sqrt1_2),
    }),
  ),
  ExecutableNotebookExample(
    id: 'cy_reversed_nonadjacent',
    title: 'Control below the target, wires apart',
    description: 'Control q2, target q0 (q1 untouched): X on q2, then CY gives '
        'i|101⟩. Orientation and distance do not change the rule.',
    qubitCount: 3,
    initialBinaryState: '000',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 2),
      CanonicalCircuitStep.controlled(SelectedGateType.cy,
          controlQubit: 2, targetQubit: 0),
    ],
    expectedState: _basis(3, {5: const NotebookAmplitude(0, 1)}),
  ),
  // ---- Multi-controlled X ----
  ExecutableNotebookExample(
    id: 'mcx_four_controls',
    title: 'Four controls in a five-qubit register',
    description: 'Controls q0, q1, q3, q4 surround the target q2. All four '
        'are 1, so q2 flips: |11011⟩ → |11111⟩.',
    qubitCount: 5,
    initialBinaryState: '11011',
    operations: const [
      CanonicalCircuitStep.multiControlledX(
          controlQubits: [0, 1, 3, 4], targetQubit: 2),
    ],
    expectedState: _basis(5, {31: const NotebookAmplitude(1)}),
  ),
];

/// Chapter 14 experiments (v2.6 M10), owned by the Conditional Quantum
/// Logic discoveries (relatedConcept) and still shown in the CY and MCX gate
/// articles through `notebookGateExampleIds`. Included in
/// `executableNotebookExamples`, so they share its validation and audit.
final List<ExecutableNotebookExample> conditionalLogicExamples = [
  ExecutableNotebookExample(
    id: 'cy_superposed_control',
    title: 'Superposed control: an entangled state with phase i',
    description: 'H on q0, then CY from q0 to q1: (|00⟩ + i|11⟩)/√2. Its '
        'Z-basis probabilities match the CX Bell state (50% |00⟩, 50% |11⟩); '
        'the relative phase i is what differs.',
    qubitCount: 2,
    initialBinaryState: '00',
    operations: const [_h0, _cy01],
    expectedState: _basis(2, {
      0: const NotebookAmplitude(math.sqrt1_2),
      3: const NotebookAmplitude(0, math.sqrt1_2),
    }),
    relatedConcept: 'Conditional Phase',
  ),
  ExecutableNotebookExample(
    id: 'cy_interference_comparison',
    title: 'The phase is physical: interference tells CY from CX',
    description: 'H, CY, then CX and H on q0. With CX in place of CY this '
        'circuit returns |00⟩ with certainty; here the relative phase i '
        'leaves q0 in |+i⟩, so the final H gives 50% |0⟩ and 50% |1⟩: '
        '((1+i)|00⟩ + (1−i)|01⟩)/2.',
    qubitCount: 2,
    initialBinaryState: '00',
    operations: const [
      _h0,
      _cy01,
      CanonicalCircuitStep.controlled(SelectedGateType.cnot,
          controlQubit: 0, targetQubit: 1),
      _h0,
    ],
    expectedState: _basis(2, {
      0: const NotebookAmplitude(.5, .5),
      1: const NotebookAmplitude(.5, -.5),
    }),
    relatedConcept: 'Conditional Phase',
  ),
  ExecutableNotebookExample(
    id: 'mcx_all_controls_active',
    title: 'Three active controls flip the target',
    description: 'Controls q0, q1, q2 are all |1⟩, so the target q3 flips: '
        '|0111⟩ → |1111⟩.',
    qubitCount: 4,
    initialBinaryState: '0111',
    operations: const [_mcx012to3],
    expectedState: _basis(4, {15: const NotebookAmplitude(1)}),
    relatedConcept: 'Multi-Controlled Logic',
  ),
  ExecutableNotebookExample(
    id: 'mcx_one_inactive_control',
    title: 'One inactive control prevents the flip',
    description: 'q1 is |0⟩, so not every control is 1 and the target stays: '
        '|0101⟩ is unchanged.',
    qubitCount: 4,
    initialBinaryState: '0101',
    operations: const [_mcx012to3],
    expectedState: _basis(4, {5: const NotebookAmplitude(1)}),
    relatedConcept: 'Multi-Controlled Logic',
  ),
  ExecutableNotebookExample(
    id: 'mcx_twice',
    title: 'MCX twice restores the input',
    description: 'MCX is its own inverse (MCX² = I): |0111⟩ → |1111⟩ → '
        '|0111⟩.',
    qubitCount: 4,
    initialBinaryState: '0111',
    operations: const [_mcx012to3, _mcx012to3],
    expectedState: _basis(4, {7: const NotebookAmplitude(1)}),
    relatedConcept: 'Multi-Controlled Logic',
  ),
  ExecutableNotebookExample(
    id: 'mcx_superposed_control',
    title: 'A superposed control: coherent, not a decision',
    description: 'q0 and q1 are |1⟩ and H puts q2 in superposition. MCX flips '
        'the target only in the component where q2 is 1: (|0011⟩ + |1111⟩)/√2, '
        'an entangled superposition. Nothing is measured or decided.',
    qubitCount: 4,
    initialBinaryState: '0011',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 2),
      _mcx012to3,
    ],
    expectedState: _basis(4, {
      3: const NotebookAmplitude(math.sqrt1_2),
      15: const NotebookAmplitude(math.sqrt1_2),
    }),
    relatedConcept: 'Coherent Conditions',
  ),
  ExecutableNotebookExample(
    id: 'mcx_coherent_and',
    title: 'Coherent AND into a |0⟩ target',
    description: 'H on q0, q1, q2 makes all eight control patterns. The target '
        'q3 (starting in |0⟩) becomes 1 only alongside 111, so it holds the '
        'AND of the controls in every component, reversibly: the controls '
        'are unchanged. Measuring q3 gives 1 with probability 1/8.',
    qubitCount: 4,
    initialBinaryState: '0000',
    operations: const [
      _h0,
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 1),
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 2),
      _mcx012to3,
    ],
    expectedState: _basis(4, {
      for (var i = 0; i < 7; i++) i: NotebookAmplitude(math.sqrt(1 / 8)),
      15: NotebookAmplitude(math.sqrt(1 / 8)),
    }),
    relatedConcept: 'Coherent Conditions',
  ),
  ExecutableNotebookExample(
    id: 'mcx_phase_kickback',
    title: 'The condition becomes a sign',
    description: 'H on q0, q1, q2; the auxiliary q3 is prepared in |−⟩ with X '
        'then H. MCX(q0,q1,q2 → q3) leaves every label and the auxiliary '
        'unchanged and gives the component with q2 q1 q0 = 111 a minus sign. '
        'Amplitudes are ±1/4; the q3 = 1 terms carry the minus sign of |−⟩.',
    qubitCount: 4,
    initialBinaryState: '0000',
    operations: const [
      _h0,
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 1),
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 2),
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 3),
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 3),
      _mcx012to3,
    ],
    expectedState: [
      for (var b = 0; b < 16; b++)
        NotebookAmplitude(
            ((b & 7) == 7 ? -1.0 : 1.0) * ((b & 8) == 0 ? 1.0 : -1.0) / 4),
    ],
    relatedConcept: 'Condition Becomes Phase',
  ),
  ExecutableNotebookExample(
    id: 'oracle_pattern_1010',
    title: 'A phase oracle for 1010',
    description: 'The input q3 q2 q1 q0 = 1010 is prepared directly, with the '
        'auxiliary q4 in |−⟩. X on q0 and q2, MCX onto q4, then X on q0 and q2 '
        'again: the labels return to 1010, the auxiliary stays |−⟩, and the '
        'state gains a factor −1. On a single basis input that sign is a '
        'global phase; on a superposition of inputs it is a relative mark.',
    qubitCount: 5,
    initialBinaryState: '01010',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 4),
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 4),
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 2),
      CanonicalCircuitStep.multiControlledX(
          controlQubits: [0, 1, 2, 3], targetQubit: 4),
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 2),
    ],
    // −|−⟩ ⊗ |1010⟩ (q4 first) = −(1/√2)|01010⟩ + (1/√2)|11010⟩.
    expectedState: _basis(5, {
      0x0A: const NotebookAmplitude(-math.sqrt1_2),
      0x1A: const NotebookAmplitude(math.sqrt1_2),
    }),
    relatedConcept: 'Reusable Phase Oracle',
  ),
];

final Map<String, ExecutableNotebookExample> gateReferenceExamplesById = {
  for (final example in gateReferenceExamples) example.id: example,
};
