import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

sealed class MasteryEvidenceBlock {
  const MasteryEvidenceBlock({this.label});

  final String? label;
}

class MasteryMathEvidence extends MasteryEvidenceBlock {
  const MasteryMathEvidence({super.label, required this.expression});

  final String expression;
}

class MasteryTextEvidence extends MasteryEvidenceBlock {
  const MasteryTextEvidence(
      {super.label, required this.text, this.isInstruction = false});

  final String text;
  final bool isInstruction;
}

class MasteryCircuitEvidence extends MasteryEvidenceBlock {
  const MasteryCircuitEvidence({
    super.label,
    required this.qubitCount,
    required this.initialBasis,
    required this.operations,
    required this.semanticDescription,
    this.missingGateColumn,
    this.missingGateQubit = 0,
    this.showInitialValues = true,
  });

  final int qubitCount;
  final String initialBasis;
  final List<CanonicalCircuitStep> operations;
  final String semanticDescription;
  final int? missingGateColumn;
  final int missingGateQubit;
  final bool showInitialValues;
}

class MasteryPipelineEvidence extends MasteryEvidenceBlock {
  const MasteryPipelineEvidence({super.label, required this.stages});

  final List<String> stages;
}

class MasteryChallengePresentation {
  const MasteryChallengePresentation({
    required this.question,
    required this.evidence,
    this.instruction = '',
    this.instructionAfterEvidence = '',
    this.intro,
    this.helperText,
  });

  /// A task instruction, distinct from an optional concluding question.
  final String instruction;

  /// Continuation of the same instruction around specialised evidence.
  /// Sentence fragments here retain Task styling; questions belong in question.
  final String instructionAfterEvidence;
  final String? intro;
  final List<MasteryEvidenceBlock> evidence;
  final String question;
  final String? helperText;
}

/// Missing Mastery presentation data is a contract error, never a QQLevel fallback.
MasteryChallengePresentation requireMasteryPresentation(String semanticId) =>
    mastery2Presentations[semanticId] ??
    (throw StateError('Missing typed Mastery presentation: $semanticId'));

const _h0 = CanonicalCircuitStep.single(
  SelectedGateType.hadamard,
  targetQubit: 0,
);
const _x0 = CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0);
const _z0 = CanonicalCircuitStep.single(SelectedGateType.z, targetQubit: 0);
const _s0 = CanonicalCircuitStep.single(SelectedGateType.s, targetQubit: 0);
const _t0 = CanonicalCircuitStep.single(SelectedGateType.t, targetQubit: 0);
const _y0 = CanonicalCircuitStep.single(SelectedGateType.y, targetQubit: 0);
const _cnot01 = CanonicalCircuitStep.controlled(
  SelectedGateType.cnot,
  controlQubit: 0,
  targetQubit: 1,
);
const _cnot10 = CanonicalCircuitStep.controlled(
  SelectedGateType.cnot,
  controlQubit: 1,
  targetQubit: 0,
);
const _cnot02 = CanonicalCircuitStep.controlled(
  SelectedGateType.cnot,
  controlQubit: 0,
  targetQubit: 2,
);
const _cnot21 = CanonicalCircuitStep.controlled(
  SelectedGateType.cnot,
  controlQubit: 2,
  targetQubit: 1,
);
const _cz01 = CanonicalCircuitStep.controlled(
  SelectedGateType.cz,
  controlQubit: 0,
  targetQubit: 1,
);

final Map<String, MasteryChallengePresentation> mastery2Presentations =
    Map.unmodifiable({
  'phase_state_uncomputation': const MasteryChallengePresentation(
    instruction:
        r'The fixed H → S → Z prefix prepared \( |-i\rangle \) from \( |0\rangle \). Append the inverse continuation that restores \( |0\rangle \).',
    question: '',
    evidence: [],
  ),
  'cnot_uncomputation': const MasteryChallengePresentation(
    instruction:
        r'A fixed CNOT(q0→q1) changed \(|11\rangle\) into \(|01\rangle\). Append the controlled operation that restores the original register and undoes the fixed operation for every input.',
    question: '',
    evidence: [],
  ),
  'clean_workspace_uncomputation': const MasteryChallengePresentation(
    instruction:
        r'A fixed H(q0)→CNOT(q0→q1) computes q0 into work qubit q1, then fixed Z(q1) uses that predicate as phase. Append the cleanup that restores \(q_1=0\) while preserving the phase on q0.',
    question: '',
    evidence: [],
  ),
  'phased_entanglement_uncomputation': const MasteryChallengePresentation(
    instruction:
        r'A fixed H(q0)→CNOT(q0→q1)→Z(q0) prefix prepared \(\Phi^-\). Append the inverse structure that returns the complete operation to identity.',
    question: '',
    evidence: [],
  ),
  'conditional_phase_decomposition': const MasteryChallengePresentation(
    instruction:
        'Implement the reusable CZ operation without a direct CZ gate, using H and CNOT. Validation covers the complete two-qubit unitary.',
    question: '',
    evidence: [],
  ),
  'bell_input_sign_preparation': const MasteryChallengePresentation(
    instruction:
        r'Starting from \(|01\rangle\) (ket order \(|q_1\,q_0\rangle\)), prepare',
    evidence: [
      MasteryMathEvidence(
        label: 'TARGET',
        expression: r'\[\Phi^-=\frac{|00\rangle-|11\rangle}{\sqrt{2}}\]',
      ),
    ],
    question: '',
    instructionAfterEvidence:
        'using the input-dependent sign and the available H/CNOT gates.',
  ),
  'ghz_phase_manipulation': const MasteryChallengePresentation(
    intro: 'The fixed starting state is',
    evidence: [
      MasteryMathEvidence(
        label: 'FIXED STARTING STATE',
        expression: r'\[GHZ^+=\frac{|000\rangle+|111\rangle}{\sqrt{2}}\]',
      ),
      MasteryTextEvidence(
          text: 'Use one local Z operation to produce', isInstruction: true),
      MasteryMathEvidence(
        label: 'TARGET',
        expression: r'\[GHZ^-=\frac{|000\rangle-|111\rangle}{\sqrt{2}}\]',
      ),
    ],
    question: '',
  ),
  'inverse_phase_synthesis': const MasteryChallengePresentation(
    instruction: 'Prepare',
    evidence: [
      MasteryMathEvidence(
        expression: r'\[\frac{|0\rangle+e^{-i\pi/4}|1\rangle}{\sqrt{2}}\]',
      ),
    ],
    question: '',
    instructionAfterEvidence:
        r'from \(|0\rangle\) without a \(T^{\dagger}\) gate. Synthesize the negative eighth-turn using H, T, S, and Z.',
  ),
  'global_phase_equivalence': const MasteryChallengePresentation(
    evidence: [
      MasteryMathEvidence(
        label: 'STATEVECTOR REPRESENTATIVES',
        expression: r'\[|1\rangle\qquad -|1\rangle\qquad i|1\rangle\]',
      ),
    ],
    question: 'Which statement is physically correct?',
  ),
  'same_histogram_different_state': const MasteryChallengePresentation(
    intro: 'Three preparations share the same ideal Z-basis histogram.',
    evidence: [
      MasteryMathEvidence(
        label: 'Z BASIS — ALL THREE',
        expression: r'\[P(0)=\tfrac12\qquad P(1)=\tfrac12\]',
      ),
      MasteryTextEvidence(
        label: r'X BASIS — \(|+\rangle\)',
        text: 'Always +',
      ),
      MasteryTextEvidence(
        label: r'X BASIS — \(|-\rangle\)',
        text: 'Always −',
      ),
      MasteryTextEvidence(
        label: r'X BASIS — RANDOM \(|0\rangle\) / \(|1\rangle\) ENSEMBLE',
        text: '50% +, 50% −',
      ),
    ],
    question: 'What does the additional X-basis evidence establish?',
    helperText:
        r'The third preparation randomly chooses \(|0\rangle\) or \(|1\rangle\).',
  ),
  'cnot_topology_inference': const MasteryChallengePresentation(
    intro: 'One fixed CNOT produced both mappings.',
    evidence: [
      MasteryMathEvidence(
          label: 'CASE A', expression: r'\[|010\rangle\to|010\rangle\]'),
      MasteryMathEvidence(
          label: 'CASE B', expression: r'\[|100\rangle\to|101\rangle\]'),
    ],
    question: 'Which control/target topology fits both cases?',
    helperText: 'Wires: q0, q1, q2 top-to-bottom. Kets: |q2 q1 q0⟩.',
  ),
  'bell_decoder_bug': const MasteryChallengePresentation(
    intro: 'This proposed Bell decoder does not produce a basis state.',
    evidence: [
      MasteryMathEvidence(
        label: 'INPUT',
        expression: r'\[|\Phi^+\rangle=\tfrac{|00\rangle+|11\rangle}{\sqrt2}\]',
      ),
      MasteryCircuitEvidence(
        label: 'PROPOSED DECODER',
        qubitCount: 2,
        initialBasis: '00',
        operations: [_h0, _cnot01],
        semanticDescription:
            'Proposed decoder: H on q0, followed by CNOT with q0 control and q1 target.',
        showInitialValues: false,
      ),
    ],
    question: 'Which repair and resulting basis output are correct?',
  ),
  'phase_kickback_conditions': const MasteryChallengePresentation(
    evidence: [
      MasteryCircuitEvidence(
        label: 'CONTROLLED OPERATION',
        qubitCount: 2,
        initialBasis: '00',
        operations: [_cnot01],
        semanticDescription:
            'Controlled X with q0 as control and q1 as target.',
        showInitialValues: false,
      ),
    ],
    question:
        'Which input creates an observable phase change on the control while leaving the target state unchanged?',
    helperText: 'The first state in each option is the control.',
  ),
  'oracle_marked_state_inference': const MasteryChallengePresentation(
    intro: 'A phase oracle changes one sign in a uniform state.',
    evidence: [
      MasteryMathEvidence(
        label: 'OUTPUT STATEVECTOR',
        expression:
            r'\[\tfrac12\bigl(|00\rangle+|01\rangle-|10\rangle+|11\rangle\bigr)\]',
      ),
    ],
    question: 'Which marked state and oracle structure match the evidence?',
    helperText: 'Wires: q0 above q1. Kets: |q1 q0⟩.',
  ),
  'algorithm_architecture_inspector': const MasteryChallengePresentation(
    intro: 'Three traces from the search model show different failures.',
    evidence: [
      MasteryTextEvidence(
        label: 'CASE A',
        text: 'One amplitude is negative; measurement remains uniform.',
      ),
      MasteryTextEvidence(
        label: 'CASE B',
        text:
            r'After amplification, \(|01\rangle\) peaks instead of desired \(|10\rangle\).',
      ),
      MasteryMathEvidence(
        label: 'CASE C',
        expression: r'\[P(\text{desired after one round})=\tfrac{121}{256}\]',
      ),
    ],
    question: 'Which diagnosis set fits all three traces?',
  ),
  'phase_accumulation_prediction': const MasteryChallengePresentation(
    evidence: [
      MasteryCircuitEvidence(
        label: 'FIXED CIRCUIT',
        qubitCount: 1,
        initialBasis: '0',
        operations: [_h0, _t0, _s0],
        semanticDescription: 'Circuit: H, then T, then S on q0.',
      ),
    ],
    question: 'Which final physical state leaves the circuit?',
  ),
  'complex_y_phase_trace': const MasteryChallengePresentation(
    evidence: [
      MasteryCircuitEvidence(
        label: 'FIXED CIRCUIT',
        qubitCount: 1,
        initialBasis: '0',
        operations: [_h0, _y0],
        semanticDescription: 'Circuit: H followed by Y on q0.',
      ),
    ],
    question: 'Ignoring a common global factor, which physical state leaves?',
  ),
  'interferometer_repair': const MasteryChallengePresentation(
    intro:
        'A relative phase is present, but direct Z-basis measurement is not deterministic.',
    evidence: [
      MasteryCircuitEvidence(
        label: 'REPAIR THE MISSING GATE',
        qubitCount: 1,
        initialBasis: '0',
        operations: [_h0, _z0],
        missingGateColumn: 2,
        semanticDescription:
            'Circuit: H then Z on q0, followed by a missing gate and Z-basis measurement.',
      ),
    ],
    question: r'Which gate reveals deterministic \(|1\rangle\)?',
  ),
  'phase_sandwich_unitary': const MasteryChallengePresentation(
    evidence: [
      MasteryCircuitEvidence(
        label: 'OPERATION A',
        qubitCount: 1,
        initialBasis: '0',
        operations: [_x0, _z0, _x0],
        semanticDescription: 'Operation A: X, then Z, then X on q0.',
        showInitialValues: false,
      ),
      MasteryCircuitEvidence(
        label: 'OPERATION B',
        qubitCount: 1,
        initialBasis: '0',
        operations: [_z0],
        semanticDescription: 'Operation B: Z on q0.',
        showInitialValues: false,
      ),
    ],
    question: 'Across arbitrary inputs, which relationship is correct?',
  ),
  'fanout_is_not_cloning': const MasteryChallengePresentation(
    intro: 'Same circuit, two different inputs.',
    evidence: [
      MasteryCircuitEvidence(
        label: 'FAN-OUT TOPOLOGY',
        qubitCount: 3,
        initialBasis: '000',
        operations: [_cnot01, _cnot02],
        semanticDescription:
            'Fan-out circuit: CNOT from q0 to q1, then CNOT from q0 to q2.',
      ),
      MasteryMathEvidence(
          label: 'CASE A', expression: r'\[|001\rangle\to|111\rangle\]'),
      MasteryMathEvidence(
        label: 'CASE B',
        expression:
            r'\[\tfrac{|000\rangle+|001\rangle}{\sqrt2}\to\tfrac{|000\rangle+|111\rangle}{\sqrt2}\]',
      ),
    ],
    question: 'What does the comparison establish?',
    helperText: 'Kets: |q2 q1 q0⟩.',
  ),
  'swap_unitary_diagnosis': const MasteryChallengePresentation(
    intro: r'Both candidates map \(|01\rangle\) to \(|10\rangle\).',
    evidence: [
      MasteryCircuitEvidence(
        label: 'CANDIDATE A',
        qubitCount: 2,
        initialBasis: '01',
        operations: [_cnot01, _cnot10, _cnot01],
        semanticDescription:
            'Candidate A: CNOT q0 to q1, CNOT q1 to q0, CNOT q0 to q1.',
      ),
      MasteryCircuitEvidence(
        label: 'CANDIDATE B',
        qubitCount: 2,
        initialBasis: '01',
        operations: [_cnot01, _cnot10],
        semanticDescription: 'Candidate B: CNOT q0 to q1, then CNOT q1 to q0.',
      ),
    ],
    question: 'Which conclusion is justified for arbitrary inputs?',
  ),
  'reversible_cancellation_trace': const MasteryChallengePresentation(
    evidence: [
      MasteryCircuitEvidence(
        label: 'FIXED CIRCUIT',
        qubitCount: 1,
        initialBasis: '0',
        operations: [_x0, _x0],
        semanticDescription: 'Circuit: X followed by X on q0, starting at 0.',
      ),
    ],
    question: 'Which description of the output is correct?',
  ),
  'hadamard_input_sign': const MasteryChallengePresentation(
    evidence: [
      MasteryCircuitEvidence(
        label: 'FIXED CIRCUIT',
        qubitCount: 1,
        initialBasis: '1',
        operations: [_h0],
        semanticDescription: 'Circuit: H on q0, starting at 1.',
      ),
    ],
    question: 'Which complete output state is correct?',
  ),
  'product_or_entangled': const MasteryChallengePresentation(
    evidence: [
      MasteryMathEvidence(
        label: 'STATE A',
        expression: r'\[\tfrac{|00\rangle+|01\rangle}{\sqrt2}\]',
      ),
      MasteryMathEvidence(
        label: 'STATE B',
        expression: r'\[\tfrac{|00\rangle+|11\rangle}{\sqrt2}\]',
      ),
      MasteryTextEvidence(
        label: 'EVIDENCE C',
        text: 'A Z-basis histogram contains only 00 and 11.',
      ),
    ],
    question: 'Which conclusion is justified?',
  ),
  'bell_measurement_evidence': const MasteryChallengePresentation(
    evidence: [
      MasteryMathEvidence(
        label: 'IDEAL Z-BASIS EVIDENCE',
        expression:
            r'\[P(00)=\tfrac12\quad P(11)=\tfrac12\quad P(01)=P(10)=0\]',
      ),
    ],
    question:
        'What is the strongest conclusion supported by this evidence alone?',
  ),
  'quarter_turn_relative_phase': const MasteryChallengePresentation(
    evidence: [
      MasteryCircuitEvidence(
        label: 'FILL THE GATE',
        qubitCount: 1,
        initialBasis: '0',
        operations: [_h0],
        missingGateColumn: 1,
        semanticDescription: 'Circuit: H on q0 followed by a missing gate.',
      ),
      MasteryMathEvidence(
          label: 'TARGET',
          expression: r'\[|+i\rangle=\tfrac{|0\rangle+i|1\rangle}{\sqrt2}\]'),
    ],
    question: 'Which missing gate produces the target?',
  ),
  'bell_phase_equivalence': const MasteryChallengePresentation(
    evidence: [
      MasteryMathEvidence(
        label: 'INPUT',
        expression: r'\[|\Phi^+\rangle=\tfrac{|00\rangle+|11\rangle}{\sqrt2}\]',
      ),
      MasteryCircuitEvidence(
        label: 'PLACEMENT A',
        qubitCount: 2,
        initialBasis: '00',
        operations: [_z0],
        semanticDescription: 'Placement A: Z on q0.',
        showInitialValues: false,
      ),
      MasteryCircuitEvidence(
        label: 'PLACEMENT B',
        qubitCount: 2,
        initialBasis: '00',
        operations: [
          CanonicalCircuitStep.single(SelectedGateType.z, targetQubit: 1)
        ],
        semanticDescription: 'Placement B: Z on q1.',
        showInitialValues: false,
      ),
    ],
    question: 'Which statement about the two placements is correct?',
  ),
  'ghz_outcome_constraint': const MasteryChallengePresentation(
    evidence: [
      MasteryMathEvidence(
        label: 'SUPPLIED STATE',
        expression:
            r'\[|GHZ^+\rangle=\tfrac{|000\rangle+|111\rangle}{\sqrt2}\]',
      ),
    ],
    question: 'Which ideal Z-basis outcome rule is correct?',
  ),
  'ghz_broken_link': const MasteryChallengePresentation(
    intro: 'The final controlled link is wrong.',
    evidence: [
      MasteryCircuitEvidence(
        label: 'BROKEN PREPARATION',
        qubitCount: 3,
        initialBasis: '000',
        operations: [_h0, _cnot01, _cnot21],
        semanticDescription:
            'Broken GHZ circuit: H on q0, CNOT q0 to q1, then CNOT q2 to q1.',
      ),
      MasteryMathEvidence(
          label: 'OBSERVED SUPPORT', expression: r'\[\{000,011\}\]'),
      MasteryMathEvidence(
          label: 'REQUIRED SUPPORT', expression: r'\[\{000,111\}\]'),
    ],
    question: 'Which replacement for the final link repairs the preparation?',
  ),
  'phase_kickback_reveal': const MasteryChallengePresentation(
    evidence: [
      MasteryCircuitEvidence(
        label: 'AFTER KICKBACK',
        qubitCount: 2,
        initialBasis: '00',
        operations: [_cnot01],
        missingGateColumn: 1,
        semanticDescription:
            'Controlled X from q0 to q1, followed by a missing reveal gate on q0.',
        showInitialValues: false,
      ),
      MasteryMathEvidence(
        label: 'STATE BEFORE REVEAL',
        expression: r'\[|-\rangle_{q0}|-\rangle_{q1}\]',
      ),
    ],
    question: 'Which gate reveals a deterministic control bit, and which bit?',
  ),
  'oracle_repair_uncompute': const MasteryChallengePresentation(
    intro:
        'The oracle marks the right phase but leaves a temporary relabelling behind.',
    evidence: [
      MasteryCircuitEvidence(
        label: 'INCOMPLETE ORACLE',
        qubitCount: 2,
        initialBasis: '00',
        operations: [_x0, _cz01],
        missingGateColumn: 2,
        semanticDescription:
            'Incomplete oracle: X on q0, then controlled Z between q0 and q1, followed by a missing cleanup gate.',
      ),
    ],
    question: 'What is the smallest repair?',
  ),
  'marked_is_not_amplified': const MasteryChallengePresentation(
    evidence: [
      MasteryMathEvidence(
        label: 'UNIFORM',
        expression: r'\[\bigl[\tfrac12,\tfrac12,\tfrac12,\tfrac12\bigr]\]',
      ),
      MasteryMathEvidence(
        label: 'AFTER ORACLE',
        expression: r'\[\bigl[\tfrac12,\tfrac12,-\tfrac12,\tfrac12\bigr]\]',
      ),
      MasteryMathEvidence(
        label: 'AFTER AMPLIFICATION',
        expression: r'\[\bigl[0,0,1,0\bigr]\]',
      ),
    ],
    question: 'When does the marked state’s Z-basis probability increase?',
  ),
  'amplitude_flow_inference': const MasteryChallengePresentation(
    evidence: [
      MasteryMathEvidence(
        label: 'MARKED AMPLITUDES',
        expression: r'\[\bigl[\tfrac12,\tfrac12,-\tfrac12,\tfrac12\bigr]\]',
      ),
      MasteryMathEvidence(
        label: 'SUPPLIED REFLECTION',
        expression: r'\[m=\tfrac14\qquad a^{\prime}=2m-a\]',
      ),
    ],
    question: 'What is the output amplitude vector?',
  ),
  'grover_round_order': const MasteryChallengePresentation(
    intro: 'This search round produces a uniform final histogram.',
    evidence: [
      MasteryPipelineEvidence(
        label: 'BROKEN ROUND',
        stages: ['Uniform', 'Amplify', 'Oracle', 'Measure'],
      ),
    ],
    question: 'Which repair explains the symptom?',
  ),
  'retry_or_reshape': const MasteryChallengePresentation(
    evidence: [
      MasteryPipelineEvidence(
        label: 'CURRENT ATTEMPT',
        stages: ['Prepare', 'Low success', 'Measure'],
      ),
    ],
    question:
        'Which next process coherently reshapes the distribution instead of repeating the same measurement?',
  ),
  'search_pipeline_forensics': const MasteryChallengePresentation(
    intro: 'An eight-state search trace contains three clues.',
    evidence: [
      MasteryMathEvidence(
        label: 'SNAPSHOT A',
        expression: r'\[a_{101}:\ +\tfrac1{\sqrt8}\to-\tfrac1{\sqrt8}\]',
      ),
      MasteryTextEvidence(
        label: 'EARLY MEASUREMENT',
        text: 'The histogram remains uniform.',
      ),
      MasteryMathEvidence(
        label: 'NEXT COHERENT STAGE',
        expression:
            r'\[a_{101}=\tfrac5{2\sqrt8}\qquad a_{other}=\tfrac1{2\sqrt8}\]',
      ),
    ],
    question: 'What follows from all three clues?',
  ),
});
