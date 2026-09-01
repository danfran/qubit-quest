import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

final MasteryChallengeCatalogue mastery2Catalogue =
    MasteryChallengeCatalogue(_mastery2FirstBatch);

final List<MasteryChallengeDefinition> _mastery2FirstBatch = [
  MasteryChallengeDefinition(
    semanticId: 'global_phase_equivalence',
    displayOrder: 1,
    title: 'Different Vectors, Same Qubit',
    difficulty: MasteryDifficulty.foundation,
    conceptTags: const {
      MasteryConceptTag.globalPhase,
      MasteryConceptTag.physicalState,
      MasteryConceptTag.operatorAction,
    },
    interactionType: MasteryInteractionType.evidence,
    contentVersion: 1,
    levelDefinition: const McqLevel(
      title: 'Different Vectors, Same Qubit',
      taskDescription:
          r'Compare \( |1\rangle \), \( -|1\rangle \), and \( i|1\rangle \). Which statement is physically correct?',
      options: [
        'They are equal mathematical vectors and therefore describe the same gate action.',
        'They are different statevector representatives of the same physical pure state; the global factors can still record genuine operator actions.',
        'Only |1⟩ and −|1⟩ are physically equivalent; the factor i changes later measurements.',
        'A later gate can reveal which overall global factor was present.',
      ],
      correctOptionIndex: 1,
      hints: [
        'Ask whether the factor changes one amplitude relative to another or multiplies the entire vector.',
      ],
      solutionExplanation:
          '|1⟩, −|1⟩, and i|1⟩ are different mathematical vectors but representatives of the same physical pure state because each differs only by one global phase. An operator that produces such a factor still performs a real mathematical transformation.',
      conceptsUsed: ['Global phase', 'Physical state', 'Operator action'],
      difficulty: 'Foundation',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'phase_state_uncomputation',
    displayOrder: 2,
    title: 'Uncompute the Hidden Turn',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.inverseOrder,
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.reversibility,
    },
    interactionType: MasteryInteractionType.uncomputation,
    contentVersion: 1,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'Uncompute the Hidden Turn',
      taskDescription:
          r'The fixed H → S → Z prefix prepared \( |-i\rangle \) from \( |0\rangle \). Append the inverse continuation that restores \( |0\rangle \).',
      targetStateExpression: '|0⟩',
      conceptIntro:
          'The fixed prefix is part of the evidence. Work backward through what it did; the order of the undoing matters.',
      hints: const [
        'Undo the relative phase before undoing the superposition.',
        'For this state, S cancels the accumulated relative phase; then H returns |+⟩ to |0⟩.',
      ],
      solutionExplanation:
          'H→S→Z prepares |-i⟩. Appending S changes the relative factor −i to +1, producing |+⟩; H then returns |+⟩ to |0⟩. The fixed preparation remains intact and the continuation S→H uncomputes it.',
      conceptsUsed: const [
        'Inverse order',
        'Relative phase',
        'Uncomputation',
      ],
      difficulty: 'Integration',
      initialQubitsStateString: '0',
      availableGates: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.s),
      ],
      solutionFinalVector: [
        [Complex.one()],
        [Complex.zero()],
      ],
      validationMode: ValidationMode.physicalState,
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.single(
          SelectedGateType.s,
          targetQubit: 0,
        ),
        CanonicalCircuitStep.single(
          SelectedGateType.hadamard,
          targetQubit: 0,
        ),
      ]),
      preInsertedGates: (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard),
          0,
          0,
          isDeletable: false,
        );
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.s),
          1,
          0,
          isDeletable: false,
        );
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z),
          2,
          0,
          isDeletable: false,
        );
      },
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'same_histogram_different_state',
    displayOrder: 3,
    title: 'Same Data, Different Qubit',
    difficulty: MasteryDifficulty.foundation,
    conceptTags: const {
      MasteryConceptTag.superposition,
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.measurementBasis,
      MasteryConceptTag.classicalMixture,
    },
    interactionType: MasteryInteractionType.evidence,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'Same Data, Different Qubit',
      badgeLabel: 'Evidence Diagnosis',
      taskDescription:
          'Ideal evidence:\n\nIn the Z basis, |+⟩, |−⟩, and an ensemble where half the preparations are |0⟩ and half are |1⟩ all give P(0)=1/2 and P(1)=1/2.\n\nIn the X basis, |+⟩ always gives +, |−⟩ always gives −, while the random |0⟩/|1⟩ ensemble remains 50/50. What does this establish?',
      options: [
        'The identical Z-basis distributions prove that all three preparations are the same quantum state.',
        'Changing measurement basis changes which state was originally prepared.',
        'The random ensemble is the pure state (|0⟩+|1⟩)/√2, so it must always give + in the X basis.',
        'The X-basis evidence distinguishes |+⟩, |−⟩, and the random ensemble; one basis distribution was not a complete state description.',
      ],
      correctOptionIndex: 3,
      hints: [
        'The ensemble is a classical random preparation, not a coherent sum of amplitudes.',
      ],
      solutionExplanation:
          'Equal ideal Z-basis probabilities do not imply equal quantum states. Relative phase becomes visible in the X basis: |+⟩ and |−⟩ give opposite deterministic outcomes. The labelled 50/50 ensemble is a classical random preparation, not a pure superposition, and remains 50/50 in the X basis.',
      conceptsUsed: [
        'Measurement evidence',
        'Relative phase',
        'Classical mixture',
      ],
      difficulty: 'Foundation',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'cnot_topology_inference',
    displayOrder: 4,
    title: 'Which Wire Controls the Change?',
    difficulty: MasteryDifficulty.foundation,
    conceptTags: const {
      MasteryConceptTag.control,
      MasteryConceptTag.reversibility,
    },
    interactionType: MasteryInteractionType.evidence,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'Which Wire Controls the Change?',
      badgeLabel: 'Evidence Diagnosis',
      taskDescription:
          'Wires run q0, q1, q2 from top to bottom; kets read |q2 q1 q0⟩. One fixed CNOT produced both mappings:\n\n|010⟩ → |010⟩\n|100⟩ → |101⟩\n\nWhich topology fits both?',
      options: [
        'control q2 → target q0',
        'control q0 → target q2',
        'control q1 → target q0',
        'control q2 → target q1',
      ],
      correctOptionIndex: 0,
      hints: [
        'Compare which ket bit changed in the second mapping, then test the proposed control against both inputs.',
      ],
      solutionExplanation:
          'Only q2→q0 fits both cases. For |010⟩, q2=0 so the CNOT is inactive. For |100⟩, q2=1 and q0 flips from 0 to 1, producing |101⟩. The other topologies fail at least one mapping.',
      conceptsUsed: ['CNOT topology', 'Inactive controls', 'Q0-LSB'],
      difficulty: 'Foundation',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'bell_decoder_bug',
    displayOrder: 5,
    title: 'The Bell Decoder Bug',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.entanglement,
      MasteryConceptTag.inverseOrder,
      MasteryConceptTag.control,
    },
    interactionType: MasteryInteractionType.debugging,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'The Bell Decoder Bug',
      badgeLabel: 'Circuit Debugging',
      taskDescription:
          'Input: |Φ+⟩=(|00⟩+|11⟩)/√2.\n\nA proposed decoder applies H(q0), then CNOT(control q0, target q1), but its output is not a basis state. Which repair and output are correct?',
      options: [
        'Apply CNOT(q1→q0), then H(q0); output |00⟩.',
        'Keep the order but reverse the CNOT: H(q0), then CNOT(q1→q0); output |00⟩.',
        'Swap the gate order: CNOT(q0→q1), then H(q0); output |00⟩.',
        'Delete H and use CNOT(q0→q1) alone; output |00⟩.',
      ],
      correctOptionIndex: 2,
      hints: [
        'A decoder applies the inverse of the preparation sequence.',
      ],
      solutionExplanation:
          'The Bell preparation used H(q0) followed by CNOT(q0→q1), so decoding reverses that order: CNOT(q0→q1) disentangles |Φ+⟩ to |+0⟩, then H(q0) produces |00⟩. Wrong order or topology does not produce that basis output.',
      conceptsUsed: ['Bell decoding', 'Inverse order', 'Circuit diagnosis'],
      difficulty: 'Integration',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'phase_kickback_conditions',
    displayOrder: 6,
    title: 'When Does Kickback Happen?',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.kickback,
      MasteryConceptTag.control,
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.globalPhase,
      MasteryConceptTag.superposition,
    },
    interactionType: MasteryInteractionType.evidence,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'When Does Kickback Happen?',
      badgeLabel: 'Evidence Diagnosis',
      taskDescription:
          'A controlled-X uses the first state as control and the second as target. Which input creates a useful, observable phase change on the control while leaving the target state unchanged?',
      options: [
        '|+⟩control |+⟩target',
        '|+⟩control |−⟩target',
        '|1⟩control |−⟩target',
        '|+⟩control |0⟩target',
      ],
      correctOptionIndex: 1,
      hints: [
        'Look for a target that returns an eigenvalue −1 and a control with two coherent branches.',
      ],
      solutionExplanation:
          'For |+⟩|−⟩, X|−⟩=−|−⟩, so only the control=1 branch gains a minus sign: the control changes from |+⟩ to |−⟩ while the target remains |−⟩. With target |+⟩ the eigenvalue is +1, so no sign returns. For |1⟩|−⟩ the entire product gains −1, which is global phase rather than branch-relative phase on a superposed control. A |0⟩ target is changed and entangled rather than left unchanged.',
      conceptsUsed: ['Phase kickback', 'Eigenstates', 'Relative phase'],
      difficulty: 'Application',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'oracle_marked_state_inference',
    displayOrder: 7,
    title: 'Which State Did the Oracle Mark?',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.oracle,
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.control,
      MasteryConceptTag.superposition,
    },
    interactionType: MasteryInteractionType.prediction,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'Which State Did the Oracle Mark?',
      badgeLabel: 'Statevector Inference',
      taskDescription:
          'Wires are q0 above q1; kets read |q1 q0⟩. A phase oracle transforms the uniform state into\n\n( |00⟩ + |01⟩ − |10⟩ + |11⟩ ) / 2.\n\nWhich state and oracle structure match the evidence?',
      options: [
        '|00⟩; CZ(q0,q1) with no X wrappers',
        '|01⟩; X(q0) → CZ(q0,q1) → X(q0)',
        '|10⟩; X(q1) → CZ(q0,q1) → X(q1)',
        '|10⟩; X(q0) → CZ(q0,q1) → X(q0)',
      ],
      correctOptionIndex: 3,
      hints: [
        'The negative amplitude identifies the marked ket. An X wrapper makes CZ trigger when that wrapped qubit was initially 0.',
      ],
      solutionExplanation:
          'The only changed sign belongs to |10⟩, so that is the marked basis state. In |10⟩, q1=1 and q0=0. Wrapping q0 with X temporarily maps it to 1 so CZ marks that component, then the final X restores the computational label. Wrapping q1 would instead mark |01⟩.',
      conceptsUsed: ['Phase oracle', 'Amplitude signs', 'Q0-LSB'],
      difficulty: 'Integration',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'algorithm_architecture_inspector',
    displayOrder: 8,
    title: 'Algorithm Architecture Inspector',
    difficulty: MasteryDifficulty.advanced,
    conceptTags: const {
      MasteryConceptTag.oracle,
      MasteryConceptTag.amplification,
      MasteryConceptTag.iteration,
      MasteryConceptTag.algorithmStructure,
    },
    interactionType: MasteryInteractionType.algorithm,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'Algorithm Architecture Inspector',
      badgeLabel: 'Algorithm Diagnosis',
      taskDescription:
          'Inspect three traces from the search model used here.\n\nA. One amplitude is negative, but measurement remains uniform.\nB. After amplification, |01⟩ peaks although |10⟩ is the desired solution.\nC. For 16 candidates, one mark+amplify round gives the desired state probability 121/256—useful, but below the required confidence.\n\nWhich diagnosis set fits all three?',
      options: [
        'A needs a second oracle; B needs measurement before amplification; C proves iteration never helps.',
        'A needs amplification before measurement; B marked the wrong state; C needs another coherent search round before measurement.',
        'A already amplified successfully; B only needs more measurements; C needs the oracle removed.',
        'A needs measurement to convert phase into amplitude; B marked correctly; C should measure after every stage.',
      ],
      correctOptionIndex: 1,
      hints: [
        'Diagnose each symptom from the evidence: hidden sign, wrong peak, then insufficient peak.',
      ],
      solutionExplanation:
          'In this search pipeline, the oracle defines the marked state by phase, amplification converts that phase pattern into probability bias, and coherent repetition can strengthen the bias before measurement. Thus A lacks amplification, B used the wrong marking, and C needs further coherent iteration for the stated confidence—not intermediate measurement.',
      conceptsUsed: [
        'Search architecture',
        'Oracle',
        'Amplification',
        'Iteration',
      ],
      difficulty: 'Advanced',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'phase_accumulation_prediction',
    displayOrder: 9,
    title: 'Follow the Phase Around',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.superposition,
    },
    interactionType: MasteryInteractionType.prediction,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'Follow the Phase Around',
      badgeLabel: 'Circuit Prediction',
      taskDescription:
          'Starting from |0⟩, a fixed circuit applies H → T → S. Which final physical state leaves the circuit?',
      options: [
        r'\( (|0\rangle+e^{i3\pi/4}|1\rangle)/\sqrt{2} \)',
        r'\( (|0\rangle+e^{i\pi/4}|1\rangle)/\sqrt{2} \)',
        r'\( (|0\rangle+i|1\rangle)/\sqrt{2} \)',
        r'\( (|0\rangle+e^{-i3\pi/4}|1\rangle)/\sqrt{2} \)',
      ],
      correctOptionIndex: 0,
      hints: [
        'Track the phase of the |1⟩ amplitude through both phase gates.',
      ],
      solutionExplanation:
          'H prepares (|0⟩+|1⟩)/√2. T contributes +π/4 to the |1⟩ amplitude and S contributes another +π/2, so the accumulated relative phase is 3π/4. Neither phase is a common factor on the whole vector.',
      conceptsUsed: ['Accumulated relative phase', 'Circuit order'],
      difficulty: 'Application',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'complex_y_phase_trace',
    displayOrder: 10,
    title: 'Trace the Complex Flip',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.globalPhase,
      MasteryConceptTag.superposition,
    },
    interactionType: MasteryInteractionType.prediction,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'Trace the Complex Flip',
      badgeLabel: 'Circuit Prediction',
      taskDescription:
          'Starting from |0⟩, a circuit applies H → Y. Ignoring any common global factor, which physical state leaves the circuit?',
      options: [
        r'\( |+\rangle=(|0\rangle+|1\rangle)/\sqrt{2} \)',
        r'\( |+i\rangle=(|0\rangle+i|1\rangle)/\sqrt{2} \)',
        r'\( |-\rangle=(|0\rangle-|1\rangle)/\sqrt{2} \)',
        r'\( |-i\rangle=(|0\rangle-i|1\rangle)/\sqrt{2} \)',
      ],
      correctOptionIndex: 2,
      hints: [
        'Apply Y to both basis components before removing a common factor.',
      ],
      solutionExplanation:
          'Y|+⟩=(i|1⟩−i|0⟩)/√2=−i(|0⟩−|1⟩)/√2=−i|−⟩. The common −i is global; the relative minus sign remains, so the physical output is |−⟩.',
      conceptsUsed: ['Y gate', 'Complex amplitudes', 'Global phase'],
      difficulty: 'Application',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'interferometer_repair',
    displayOrder: 11,
    title: 'Repair the Interferometer',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.interference,
      MasteryConceptTag.measurementBasis,
    },
    interactionType: MasteryInteractionType.fillGate,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'Repair the Interferometer',
      badgeLabel: 'Fill the Gate',
      taskDescription:
          'The fixed circuit is |0⟩ → H → Z → [?] → Z-basis measurement. The phase mark is present, but the required result is deterministic |1⟩. Which repair fills the slot?',
      options: ['X', 'Z', 'S', 'H'],
      correctOptionIndex: 3,
      hints: [
        'Choose the operation that recombines the two phase-bearing paths.',
      ],
      solutionExplanation:
          'H→Z prepares |−⟩: its relative phase is hidden from a direct Z-basis histogram. A final H recombines the amplitudes and maps |−⟩ to |1⟩. Z, S, and X leave balanced Z-basis probabilities for this input.',
      conceptsUsed: ['Relative phase', 'Interference', 'Reveal basis'],
      difficulty: 'Application',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'phase_sandwich_unitary',
    displayOrder: 12,
    title: 'Phase Sandwich',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.operatorAction,
      MasteryConceptTag.globalPhase,
      MasteryConceptTag.reversibility,
    },
    interactionType: MasteryInteractionType.evidence,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'Phase Sandwich',
      badgeLabel: 'Unitary Diagnosis',
      taskDescription:
          'Compare the complete one-qubit operations XZX and Z—not their action on only one chosen input. Which statement is correct?',
      options: [
        'XZX = −Z as matrices, so their outputs differ only by one whole-state global factor for every input.',
        'XZX = Z as literal matrices; the minus sign appears only when the input is |0⟩.',
        'XZX agrees with Z only on computational-basis inputs and fails on superpositions.',
        'XZX and Z are physically different because any matrix sign is directly measurable.',
      ],
      correctOptionIndex: 0,
      hints: [
        'Multiply the complete matrices rather than checking one state.',
      ],
      solutionExplanation:
          'Direct multiplication gives XZX=−Z, not literal matrix equality with Z. For every input |ψ⟩, XZX|ψ⟩=−Z|ψ⟩, so the two output vectors differ by the same global factor −1 and represent the same isolated physical operation.',
      conceptsUsed: ['Conjugation', 'Unitary identity', 'Global phase'],
      difficulty: 'Integration',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'cnot_uncomputation',
    displayOrder: 13,
    title: 'Undo the Controlled Change',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.control,
      MasteryConceptTag.reversibility,
      MasteryConceptTag.inverseOrder,
    },
    interactionType: MasteryInteractionType.uncomputation,
    contentVersion: 1,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'Undo the Controlled Change',
      taskDescription:
          'A fixed CNOT(q0→q1) changed |11⟩ into |01⟩. Append the controlled operation that restores the original register and undoes the fixed operation for every input.',
      targetStateExpression: '|11⟩',
      hints: const [
        'The inverse must preserve both the gate type and its control/target roles.',
      ],
      solutionExplanation:
          'CNOT is self-inverse. Appending the same CNOT(q0→q1) restores |11⟩, and the complete fixed-plus-learner circuit is the identity on every two-qubit input. Reversing the topology or adding a single-qubit correction does not undo the authored operation.',
      conceptsUsed: const ['CNOT', 'Self-inverse', 'Uncomputation'],
      difficulty: 'Application',
      initialQubitsStateString: '11',
      availableGates: [
        Gate.fromIdentifier(SelectedGateType.cnot),
        Gate.fromIdentifier(SelectedGateType.z),
      ],
      solutionFinalVector: [
        [Complex.zero()],
        [Complex.zero()],
        [Complex.zero()],
        [Complex.one()],
      ],
      validationMode: ValidationMode.unitary,
      targetUnitary: [
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
      ],
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.controlled(
          SelectedGateType.cnot,
          controlQubit: 0,
          targetQubit: 1,
        ),
      ]),
      preInsertedGates: (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          0,
          1,
          0,
          isDeletable: false,
        );
      },
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'fanout_is_not_cloning',
    displayOrder: 14,
    title: 'Shared Control, Different Meaning',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.control,
      MasteryConceptTag.superposition,
      MasteryConceptTag.entanglement,
    },
    interactionType: MasteryInteractionType.evidence,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'Shared Control, Different Meaning',
      badgeLabel: 'Evidence Diagnosis',
      taskDescription:
          'The same fan-out uses CNOT(q0→q1), then CNOT(q0→q2).\n\nA. |001⟩ → |111⟩\nB. (|000⟩+|001⟩)/√2 → (|000⟩+|111⟩)/√2\n\nKets read |q2 q1 q0⟩. What does the comparison establish?',
      options: [
        'Both cases create three independent copies of q0, so any unknown qubit can be cloned with two CNOTs.',
        'B produces |+⟩ on each wire independently: |+⟩|+⟩|+⟩.',
        'A propagates a known basis value; B creates one entangled three-qubit state rather than independent copies of an unknown qubit.',
        'A is entangled while B is only a classical basis string.',
      ],
      correctOptionIndex: 2,
      hints: [
        'Compare a definite basis value with the two coherent branches of the second output.',
      ],
      solutionExplanation:
          'For A, the active q0 condition propagates the known basis value into q1 and q2. For B, the circuit correlates whole-register branches, producing the GHZ state (|000⟩+|111⟩)/√2. Its qubits are not independent copies of the unknown input state.',
      conceptsUsed: ['Controlled fan-out', 'Entanglement', 'No-cloning'],
      difficulty: 'Application',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'swap_unitary_diagnosis',
    displayOrder: 15,
    title: 'A Swap for Every Input',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.control,
      MasteryConceptTag.operatorAction,
      MasteryConceptTag.reversibility,
    },
    interactionType: MasteryInteractionType.debugging,
    contentVersion: 1,
    levelDefinition: const ConceptCheckLevel(
      title: 'A Swap for Every Input',
      badgeLabel: 'Circuit Diagnosis',
      taskDescription:
          'Both candidates map |01⟩→|10⟩.\n\nA: CNOT(q0→q1), CNOT(q1→q0), CNOT(q0→q1)\nB: CNOT(q0→q1), CNOT(q1→q0)\n\nWhich conclusion is justified for arbitrary inputs?',
      options: [
        'Both are SWAP because one successful basis mapping proves unitary equality.',
        'A is SWAP; B only matches the supplied example and fails other inputs such as |10⟩.',
        'B is SWAP because the shortest circuit matching one input is always the reusable operation.',
        'Neither can be SWAP because a SWAP operation cannot be decomposed into CNOTs.',
      ],
      correctOptionIndex: 1,
      hints: [
        'Test the claimed operation on more than the supplied input.',
      ],
      solutionExplanation:
          'A is the three-CNOT SWAP decomposition: it exchanges both qubits on every basis input and therefore on every superposition by linearity. B happens to map |01⟩ to |10⟩, but maps |10⟩ to |11⟩, so it is a state-specific shortcut—not SWAP.',
      conceptsUsed: ['SWAP', 'Unitary evidence', 'CNOT order'],
      difficulty: 'Application',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'reversible_cancellation_trace',
    displayOrder: 16,
    title: 'A Change That Cancels',
    difficulty: MasteryDifficulty.foundation,
    conceptTags: const {MasteryConceptTag.reversibility},
    interactionType: MasteryInteractionType.prediction,
    levelDefinition: const ConceptCheckLevel(
      title: 'A Change That Cancels',
      badgeLabel: 'Circuit Prediction',
      taskDescription:
          'Starting from |0⟩, a fixed circuit applies X → X. Which description of the output is correct?',
      options: [
        'The two X gates are mathematically absent because their combined action is identity.',
        'The output is |1⟩ because the first visible change determines the circuit result.',
        'The output is |+⟩ because two bit flips create a superposition.',
        'The output is |0⟩: each X is a real operation, and the second reverses the first.',
      ],
      correctOptionIndex: 3,
      hints: ['Trace both operations in order.'],
      solutionExplanation:
          'The first X maps |0⟩ to |1⟩ and the second maps |1⟩ back to |0⟩. Both transformations occur; their combined unitary is the identity because X is self-inverse.',
      conceptsUsed: ['Reversibility', 'Circuit reading'],
      difficulty: 'Foundation',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'hadamard_input_sign',
    displayOrder: 17,
    title: 'Same Balance, Different Sign',
    difficulty: MasteryDifficulty.foundation,
    conceptTags: const {
      MasteryConceptTag.superposition,
      MasteryConceptTag.relativePhase,
    },
    interactionType: MasteryInteractionType.prediction,
    levelDefinition: const ConceptCheckLevel(
      title: 'Same Balance, Different Sign',
      badgeLabel: 'Circuit Prediction',
      taskDescription:
          'A Hadamard gate acts on |1⟩. Which complete output state is correct?',
      options: [
        r'\( |-\rangle=(|0\rangle-|1\rangle)/\sqrt{2} \)',
        r'\( |+\rangle=(|0\rangle+|1\rangle)/\sqrt{2} \)',
        r'\( |+i\rangle=(|0\rangle+i|1\rangle)/\sqrt{2} \)',
        r'\( |1\rangle \)',
      ],
      correctOptionIndex: 0,
      hints: ['The input column of H determines the relative sign.'],
      solutionExplanation:
          'H|1⟩=(|0⟩−|1⟩)/√2=|−⟩. Its Z-basis probabilities match |+⟩, but its relative sign—and therefore its complete quantum state—is different.',
      conceptsUsed: ['Hadamard', 'Input sign', 'Relative phase'],
      difficulty: 'Foundation',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'product_or_entangled',
    displayOrder: 18,
    title: 'Together or Merely Side by Side?',
    difficulty: MasteryDifficulty.foundation,
    conceptTags: const {
      MasteryConceptTag.superposition,
      MasteryConceptTag.entanglement,
      MasteryConceptTag.measurementBasis,
    },
    interactionType: MasteryInteractionType.evidence,
    levelDefinition: const ConceptCheckLevel(
      title: 'Together or Merely Side by Side?',
      badgeLabel: 'Evidence Classification',
      taskDescription:
          'Compare three pieces of evidence:\n\nA. (|00⟩+|01⟩)/√2\nB. (|00⟩+|11⟩)/√2\nC. A Z-basis histogram containing only 00 and 11.\n\nWhich conclusion is justified?',
      options: [
        'A and B are both entangled because each contains two basis terms.',
        'A factors as |0⟩|+⟩; B is nonseparable; C alone does not prove entanglement.',
        'C alone proves the source emitted a Bell state.',
        'B factors as |+⟩|+⟩ because its two terms have equal magnitudes.',
      ],
      correctOptionIndex: 1,
      hints: [
        'Try to factor each state; treat the histogram as evidence, not a statevector.'
      ],
      solutionExplanation:
          'A=(|0⟩⊗(|0⟩+|1⟩))/√2 is a product state. B cannot be factored into two one-qubit states and is entangled. A 00/11-only Z histogram is compatible with B, but also with a classically correlated preparation, so that evidence alone is insufficient.',
      conceptsUsed: ['Separability', 'Bell state', 'Evidence limits'],
      difficulty: 'Foundation',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'bell_measurement_evidence',
    displayOrder: 19,
    title: 'What Bell Measurements Prove',
    difficulty: MasteryDifficulty.foundation,
    conceptTags: const {
      MasteryConceptTag.entanglement,
      MasteryConceptTag.measurementBasis,
    },
    interactionType: MasteryInteractionType.measurement,
    levelDefinition: const ConceptCheckLevel(
      title: 'What Bell Measurements Prove',
      badgeLabel: 'Measurement Evidence',
      taskDescription:
          'Ideal repeated Z-basis measurements of a supplied Φ+ preparation give P(00)=1/2, P(11)=1/2, and zero probability for 01 or 10. What is the strongest conclusion supported by this evidence alone?',
      options: [
        'Each qubit had a definite independent value before measurement.',
        'The histogram by itself proves Bell nonlocality and rules out every classical explanation.',
        'The two measured bits are perfectly correlated in the Z basis; this one-basis evidence alone does not exclude a classical correlated source.',
        'The source must produce exactly alternating 00 and 11 samples in finite runs.',
      ],
      correctOptionIndex: 2,
      hints: [
        'Separate the observed basis correlation from stronger state claims.'
      ],
      solutionExplanation:
          'The ideal distribution establishes perfect Z-basis correlation. It is consistent with Φ+, but the same one-basis histogram can arise from a classically correlated ensemble. Additional incompatible-basis evidence is needed for a stronger entanglement conclusion.',
      conceptsUsed: [
        'Bell correlations',
        'Born probabilities',
        'Evidence limits'
      ],
      difficulty: 'Foundation',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'quarter_turn_relative_phase',
    displayOrder: 20,
    title: 'A Quarter Turn',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.superposition,
    },
    interactionType: MasteryInteractionType.fillGate,
    levelDefinition: const ConceptCheckLevel(
      title: 'A Quarter Turn',
      badgeLabel: 'Fill the Gate',
      taskDescription:
          'The fixed H prepares |+⟩ from |0⟩. Which missing gate produces |+i⟩ while preserving both amplitude magnitudes?',
      options: ['S', 'T', 'Z', 'X'],
      correctOptionIndex: 0,
      hints: ['Compare the required relative phase turn.'],
      solutionExplanation:
          'S leaves the |0⟩ amplitude unchanged and multiplies the |1⟩ amplitude by i, producing (|0⟩+i|1⟩)/√2=|+i⟩. T supplies only π/4, Z supplies π, and X does not create the required relative phase.',
      conceptsUsed: ['S gate', 'Relative phase'],
      difficulty: 'Application',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'bell_input_sign_preparation',
    displayOrder: 21,
    title: 'The Sign Was Already There',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.entanglement,
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.control,
    },
    interactionType: MasteryInteractionType.construction,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'The Sign Was Already There',
      taskDescription:
          'Starting from |01⟩ (ket order |q1 q0⟩), prepare Φ−=(|00⟩−|11⟩)/√2 using the input-dependent sign and the available H/CNOT gates.',
      targetStateExpression: 'Φ−',
      hints: const ['Use H on the qubit that already begins in |1⟩.'],
      solutionExplanation:
          'H(q0)|1⟩=|−⟩, so CNOT(q0→q1) propagates its two branches into (|00⟩−|11⟩)/√2. The relative sign comes from the nonzero input; no extra phase gate is needed.',
      conceptsUsed: const ['Bell state', 'Input-dependent sign'],
      difficulty: 'Application',
      initialQubitsStateString: '01',
      availableGates: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.cnot),
      ],
      solutionFinalVector: [
        [Complex(math.sqrt1_2)],
        [Complex.zero()],
        [Complex.zero()],
        [Complex(-math.sqrt1_2)],
      ],
      validationMode: ValidationMode.physicalState,
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
        CanonicalCircuitStep.controlled(
          SelectedGateType.cnot,
          controlQubit: 0,
          targetQubit: 1,
        ),
      ]),
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'bell_phase_equivalence',
    displayOrder: 22,
    title: 'Where Can the Bell Phase Live?',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.entanglement,
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.physicalState,
    },
    interactionType: MasteryInteractionType.evidence,
    levelDefinition: const ConceptCheckLevel(
      title: 'Where Can the Bell Phase Live?',
      badgeLabel: 'Circuit Comparison',
      taskDescription:
          'Starting from Φ+=(|00⟩+|11⟩)/√2, compare applying Z to q0 with applying Z to q1. Which statement is correct?',
      options: [
        'Both placements add only a global phase and leave Φ+ physically unchanged.',
        'Only Z(q0) changes the Bell phase because q0 is the top wire.',
        'The two placements produce orthogonal Bell states.',
        'Either placement produces Φ−=(|00⟩−|11⟩)/√2; the two circuits agree on this entangled input.',
      ],
      correctOptionIndex: 3,
      hints: ['Apply each local Z to both correlated terms.'],
      solutionExplanation:
          'In Φ+, the |11⟩ branch has both q0=1 and q1=1. Z on either qubit changes that branch’s sign while leaving |00⟩ unchanged, producing Φ−. This equivalence depends on the correlated input and is not literal equality of the local operators.',
      conceptsUsed: ['Bell phase', 'Local Z', 'Equivalent constructions'],
      difficulty: 'Integration',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'ghz_outcome_constraint',
    displayOrder: 23,
    title: 'One System, Three Qubits',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.ghz,
      MasteryConceptTag.entanglement,
      MasteryConceptTag.measurementBasis,
    },
    interactionType: MasteryInteractionType.evidence,
    levelDefinition: const ConceptCheckLevel(
      title: 'One System, Three Qubits',
      badgeLabel: 'Evidence Diagnosis',
      taskDescription:
          'For GHZ+=(|000⟩+|111⟩)/√2, which Z-basis outcome rule is correct?',
      options: [
        'Each qubit is an independent fair bit, giving all eight strings equally.',
        'Any string with an even number of 1s can occur.',
        'Only 000 and 111 can occur; once one measured bit is known, the other two are fixed in that run.',
        'Only adjacent pairs are constrained; the third bit remains independent.',
      ],
      correctOptionIndex: 2,
      hints: ['Read the support of the complete three-qubit state.'],
      solutionExplanation:
          'The statevector has support only on the whole-register strings 000 and 111, each with ideal probability 1/2. This establishes the stated Z-basis constraint; that one basis alone is not a complete proof of genuine multipartite entanglement.',
      conceptsUsed: ['GHZ', 'Full-register constraint'],
      difficulty: 'Application',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'ghz_broken_link',
    displayOrder: 24,
    title: 'Find the Broken GHZ Link',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.ghz,
      MasteryConceptTag.control,
      MasteryConceptTag.entanglement,
    },
    interactionType: MasteryInteractionType.debugging,
    levelDefinition: const ConceptCheckLevel(
      title: 'Find the Broken GHZ Link',
      badgeLabel: 'Circuit Debugging',
      taskDescription:
          'A preparation applies H(q0), CNOT(q0→q1), then CNOT(q2→q1). Its output support is {000, 011}, not {000, 111}. Which replacement for the final link repairs GHZ preparation?',
      options: [
        'CNOT(q1→q0)',
        'CNOT(q1→q2)',
        'H(q2)',
        'X(q2)',
      ],
      correctOptionIndex: 1,
      hints: [
        'The existing correlation must propagate onto the still-zero q2 wire.'
      ],
      solutionExplanation:
          'After H(q0) and CNOT(q0→q1), the support is {000,011}. CNOT(q1→q2) uses the correlated q1 branch to flip q2, mapping 011 to 111 while leaving 000 unchanged. The authored q2→q1 link has an inactive control.',
      conceptsUsed: ['GHZ topology', 'Controlled propagation'],
      difficulty: 'Integration',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'ghz_phase_manipulation',
    displayOrder: 25,
    title: 'A Hidden Sign Across Three Qubits',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.ghz,
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.entanglement,
    },
    interactionType: MasteryInteractionType.construction,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'A Hidden Sign Across Three Qubits',
      taskDescription:
          'The fixed starting state is GHZ+=(|000⟩+|111⟩)/√2. Use one local Z operation to produce GHZ−=(|000⟩−|111⟩)/√2.',
      targetStateExpression: 'GHZ−',
      hints: const ['Any one GHZ wire is 1 in the |111⟩ branch only.'],
      solutionExplanation:
          'A local Z on any one qubit leaves |000⟩ unchanged and negates |111⟩, producing GHZ−. The local operation changes a relative sign belonging to the full entangled state.',
      conceptsUsed: const ['GHZ phase', 'Local Z'],
      difficulty: 'Integration',
      initialQubitsStateString: '000',
      availableGates: [Gate.fromIdentifier(SelectedGateType.z)],
      solutionFinalVector: [
        [Complex(math.sqrt1_2)],
        [Complex.zero()],
        [Complex.zero()],
        [Complex.zero()],
        [Complex.zero()],
        [Complex.zero()],
        [Complex.zero()],
        [Complex(-math.sqrt1_2)],
      ],
      validationMode: ValidationMode.physicalState,
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.single(SelectedGateType.z, targetQubit: 0),
      ]),
      preInsertedGates: (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard),
          0,
          0,
          isDeletable: false,
        );
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          1,
          1,
          0,
          isDeletable: false,
        );
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          2,
          2,
          1,
          isDeletable: false,
        );
      },
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'phase_kickback_reveal',
    displayOrder: 26,
    title: 'Reveal the Kicked-Back Bit',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.kickback,
      MasteryConceptTag.interference,
      MasteryConceptTag.relativePhase,
    },
    interactionType: MasteryInteractionType.fillGate,
    levelDefinition: const ConceptCheckLevel(
      title: 'Reveal the Kicked-Back Bit',
      badgeLabel: 'Fill the Gate',
      taskDescription:
          'After controlled-X acts on |+⟩control|−⟩target, the control is |−⟩ and the target is unchanged. Which gate on the control reveals a deterministic bit, and which bit appears?',
      options: [
        'H, revealing control |1⟩',
        'X, revealing control |0⟩',
        'Z, revealing control |1⟩',
        'S, revealing control |0⟩',
      ],
      correctOptionIndex: 0,
      hints: ['Choose the basis change that distinguishes |+⟩ from |−⟩.'],
      solutionExplanation:
          'Kickback changes the superposed control from |+⟩ to |−⟩. H converts that relative sign into population: H|−⟩=|1⟩. X, Z, and S do not perform this reveal-basis conversion.',
      conceptsUsed: ['Kickback', 'Interference', 'Phase-to-bit reveal'],
      difficulty: 'Integration',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'inverse_phase_synthesis',
    displayOrder: 27,
    title: 'Build the Missing Inverse',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.inverseOrder,
      MasteryConceptTag.superposition,
    },
    interactionType: MasteryInteractionType.construction,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'Build the Missing Inverse',
      taskDescription:
          'Prepare (|0⟩+e^(−iπ/4)|1⟩)/√2 from |0⟩ without a T† gate. Synthesize the negative eighth-turn using H, T, S, and Z.',
      targetStateExpression: '|phase −π/4⟩',
      hints: const ['Represent −π/4 as an equivalent positive turn modulo 2π.'],
      solutionExplanation:
          'H creates equal amplitudes. Z, S, and T contribute π+π/2+π/4=7π/4, which is equivalent to −π/4 modulo 2π. Thus H→Z→S→T prepares the target without T†.',
      conceptsUsed: const ['Inverse phase', 'Phase synthesis'],
      difficulty: 'Integration',
      initialQubitsStateString: '0',
      availableGates: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.t),
        Gate.fromIdentifier(SelectedGateType.s),
        Gate.fromIdentifier(SelectedGateType.z),
      ],
      solutionFinalVector: [
        [Complex(math.sqrt1_2)],
        [Complex(0.5, -0.5)],
      ],
      validationMode: ValidationMode.physicalState,
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
        CanonicalCircuitStep.single(SelectedGateType.z, targetQubit: 0),
        CanonicalCircuitStep.single(SelectedGateType.s, targetQubit: 0),
        CanonicalCircuitStep.single(SelectedGateType.t, targetQubit: 0),
      ]),
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'phased_entanglement_uncomputation',
    displayOrder: 28,
    title: 'Uncompute the Hidden Correlation',
    difficulty: MasteryDifficulty.advanced,
    conceptTags: const {
      MasteryConceptTag.entanglement,
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.reversibility,
      MasteryConceptTag.inverseOrder,
    },
    interactionType: MasteryInteractionType.uncomputation,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'Uncompute the Hidden Correlation',
      taskDescription:
          'A fixed H(q0)→CNOT(q0→q1)→Z(q0) prefix prepared Φ−. Append the inverse structure that returns the complete operation to identity.',
      targetStateExpression: '|00⟩ and identity overall',
      hints: const [
        'Undo the phase, then disentangle, then undo the superposition.'
      ],
      solutionExplanation:
          'Reverse the preparation with Z(q0)→CNOT(q0→q1)→H(q0). The first Z removes the Bell relative sign, CNOT disentangles Φ+, and H restores |00⟩. Across arbitrary inputs the fixed prefix and appended inverse multiply to identity.',
      conceptsUsed: const ['Bell phase', 'Inverse order', 'Cleanup'],
      difficulty: 'Advanced',
      initialQubitsStateString: '00',
      availableGates: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.cnot),
        Gate.fromIdentifier(SelectedGateType.z),
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
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
      ],
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.single(SelectedGateType.z, targetQubit: 0),
        CanonicalCircuitStep.controlled(
          SelectedGateType.cnot,
          controlQubit: 0,
          targetQubit: 1,
        ),
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
      ]),
      preInsertedGates: (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard),
          0,
          0,
          isDeletable: false,
        );
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          1,
          1,
          0,
          isDeletable: false,
        );
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z),
          2,
          0,
          isDeletable: false,
        );
      },
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'conditional_phase_decomposition',
    displayOrder: 29,
    title: 'Build a Conditional Sign',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.control,
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.operatorAction,
    },
    interactionType: MasteryInteractionType.construction,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'Build a Conditional Sign',
      taskDescription:
          'Implement the reusable CZ operation without a direct CZ gate, using H and CNOT. Validation covers the complete two-qubit unitary.',
      targetStateExpression: 'CZ unitary',
      hints: const ['Conjugate the CNOT target with H.'],
      solutionExplanation:
          'H(q1)→CNOT(q0→q1)→H(q1) changes the target basis so the conditional X becomes a conditional Z. The complete unitary is diag(1,1,1,−1), not merely a state-specific phase mark.',
      conceptsUsed: const ['CZ decomposition', 'Basis conjugation'],
      difficulty: 'Integration',
      initialQubitsStateString: '00',
      availableGates: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
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
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex(-1)],
      ],
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 1),
        CanonicalCircuitStep.controlled(
          SelectedGateType.cnot,
          controlQubit: 0,
          targetQubit: 1,
        ),
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 1),
      ]),
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'oracle_repair_uncompute',
    displayOrder: 30,
    title: 'Repair the Phase Oracle',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.oracle,
      MasteryConceptTag.reversibility,
      MasteryConceptTag.control,
    },
    interactionType: MasteryInteractionType.debugging,
    levelDefinition: const ConceptCheckLevel(
      title: 'Repair the Phase Oracle',
      badgeLabel: 'Circuit Debugging',
      taskDescription:
          'A supposed |10⟩ phase oracle applies X(q0)→CZ(q0,q1) but omits its final wrapper. It creates the intended sign during the middle step but does not restore computational labels. What is the smallest repair?',
      options: [
        'Measure q0 immediately.',
        'Append X(q1).',
        'Append a second CZ.',
        'Append X(q0).',
      ],
      correctOptionIndex: 3,
      hints: ['Uncompute the temporary basis relabelling on the same wire.'],
      solutionExplanation:
          'The leading X(q0) temporarily maps q0=0 components into CZ’s active q0=1 condition. Appending X(q0) restores every computational label while retaining the phase on |10⟩. A different wrapper or measurement does not implement the intended reusable oracle.',
      conceptsUsed: ['Oracle', 'Compute–mark–uncompute'],
      difficulty: 'Integration',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'marked_is_not_amplified',
    displayOrder: 31,
    title: 'Marked Is Not More Likely',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.oracle,
      MasteryConceptTag.amplification,
      MasteryConceptTag.measurementBasis,
    },
    interactionType: MasteryInteractionType.evidence,
    levelDefinition: const ConceptCheckLevel(
      title: 'Marked Is Not More Likely',
      badgeLabel: 'Evidence Diagnosis',
      taskDescription:
          'Four basis amplitudes begin at +1/2. An oracle changes only the marked amplitude to −1/2. A later amplification stage produces amplitude 1 on the marked state and 0 on the others. When does its Z-basis probability increase?',
      options: [
        'Before the oracle because uniform amplitudes already identify the marked state.',
        'Immediately after the oracle because a negative amplitude has larger probability.',
        'Only after amplification; the oracle sign alone leaves every probability at 1/4.',
        'Never; interference cannot change measurement probabilities.',
      ],
      correctOptionIndex: 2,
      hints: ['Compare squared magnitudes at each snapshot.'],
      solutionExplanation:
          'Changing +1/2 to −1/2 marks phase but keeps magnitude squared at 1/4. The amplification/interference stage redistributes amplitudes; in this four-state example it raises the marked magnitude to 1 and its probability to 1.',
      conceptsUsed: ['Phase marking', 'Amplitude amplification'],
      difficulty: 'Application',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'amplitude_flow_inference',
    displayOrder: 32,
    title: 'Where Did the Amplitude Go?',
    difficulty: MasteryDifficulty.advanced,
    conceptTags: const {
      MasteryConceptTag.interference,
      MasteryConceptTag.amplification,
      MasteryConceptTag.oracle,
    },
    interactionType: MasteryInteractionType.prediction,
    levelDefinition: const ConceptCheckLevel(
      title: 'Where Did the Amplitude Go?',
      badgeLabel: 'Amplitude Reasoning',
      taskDescription:
          'After marking one of four uniform states, the amplitudes are [1/2, 1/2, −1/2, 1/2]. The supplied amplifier reflects each amplitude a about their mean m=1/4 using a′=2m−a. What is the output?',
      options: [
        '[0, 0, 1, 0]',
        '[1/2, 1/2, −1/2, 1/2]',
        '[1/2, 1/2, 1/2, 1/2]',
        '[1, 0, 0, 0]',
      ],
      correctOptionIndex: 0,
      hints: [
        'Apply the supplied reflection to the negative and positive entries separately.'
      ],
      solutionExplanation:
          'For each unmarked +1/2 amplitude, 2(1/4)−1/2=0. For the marked −1/2 amplitude, 2(1/4)−(−1/2)=1. Destructive interference removes the unmarked paths while constructive interference concentrates amplitude on the marked state.',
      conceptsUsed: ['Amplitude flow', 'Interference'],
      difficulty: 'Advanced',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'grover_round_order',
    displayOrder: 33,
    title: 'One Round, Wrong Order',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.oracle,
      MasteryConceptTag.amplification,
      MasteryConceptTag.algorithmStructure,
    },
    interactionType: MasteryInteractionType.debugging,
    levelDefinition: const ConceptCheckLevel(
      title: 'One Round, Wrong Order',
      badgeLabel: 'Algorithm Debugging',
      taskDescription:
          'In the four-state search model used here, a broken round applies amplification to the uniform state, then applies the phase oracle, then measures. The final histogram remains uniform. Which repair explains the symptom?',
      options: [
        'Measure between amplification and the oracle to preserve coherence.',
        'Apply the oracle before amplification so the amplifier has a phase difference to convert into bias.',
        'Delete the oracle because amplification identifies a state without marking.',
        'Repeat only the oracle until the negative amplitude becomes larger.',
      ],
      correctOptionIndex: 1,
      hints: [
        'Ask what information the amplifier receives when its input is still uniform.'
      ],
      solutionExplanation:
          'In this search round, amplification leaves a completely uniform input unchanged. The later oracle adds a sign but measurement cannot see that sign directly, so probabilities remain flat. Oracle then amplifier supplies the phase pattern before interference converts it into bias.',
      conceptsUsed: ['Grover round', 'Stage order'],
      difficulty: 'Integration',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'retry_or_reshape',
    displayOrder: 34,
    title: 'Retry or Reshape?',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.iteration,
      MasteryConceptTag.amplification,
      MasteryConceptTag.oracle,
    },
    interactionType: MasteryInteractionType.algorithm,
    levelDefinition: const ConceptCheckLevel(
      title: 'Retry or Reshape?',
      badgeLabel: 'Process Diagnosis',
      taskDescription:
          'A search attempt has low success probability. Which next process coherently reshapes the distribution rather than merely trying the same measurement again?',
      options: [
        'Apply amplification to an unmarked uniform state, then measure after every block.',
        'Measure, discard the result, and repeat the identical unamplified preparation.',
        'Apply the phase oracle repeatedly without an interference stage.',
        'Reprepare, apply an oracle-plus-amplifier round, and keep the state coherent until the planned measurement.',
      ],
      correctOptionIndex: 3,
      hints: ['Look for a process that changes amplitudes before measurement.'],
      solutionExplanation:
          'In this search model, the oracle creates a phase distinction and amplification converts it into probability bias while coherence is preserved. Repeating an unchanged measurement is another classical-style attempt; oracle-only and unmarked amplification do not reshape the probabilities as required.',
      conceptsUsed: ['Coherent iteration', 'Probability shaping'],
      difficulty: 'Application',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'clean_workspace_uncomputation',
    displayOrder: 35,
    title: 'Clean the Workspace',
    difficulty: MasteryDifficulty.advanced,
    conceptTags: const {
      MasteryConceptTag.reversibility,
      MasteryConceptTag.control,
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.oracle,
    },
    interactionType: MasteryInteractionType.uncomputation,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'Clean the Workspace',
      taskDescription:
          'A fixed H(q0)→CNOT(q0→q1) computes q0 into work qubit q1, then fixed Z(q1) uses that predicate as phase. Append the cleanup that restores q1=0 while preserving the phase on q0.',
      targetStateExpression: '|−⟩q0|0⟩q1',
      hints: const ['Reverse the compute step after its phase has been used.'],
      solutionExplanation:
          'Appending the same CNOT(q0→q1) uncomputes the work bit. The work qubit returns to |0⟩, while the phase written between the correlated branches remains on q0 as |−⟩. This cleans temporary information without erasing the useful result.',
      conceptsUsed: const ['Compute–use–uncompute', 'Ancilla cleanup'],
      difficulty: 'Advanced',
      initialQubitsStateString: '00',
      availableGates: [Gate.fromIdentifier(SelectedGateType.cnot)],
      solutionFinalVector: [
        [Complex(math.sqrt1_2)],
        [Complex(-math.sqrt1_2)],
        [Complex.zero()],
        [Complex.zero()],
      ],
      validationMode: ValidationMode.physicalState,
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.controlled(
          SelectedGateType.cnot,
          controlQubit: 0,
          targetQubit: 1,
        ),
      ]),
      preInsertedGates: (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard),
          0,
          0,
          isDeletable: false,
        );
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          1,
          1,
          0,
          isDeletable: false,
        );
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z),
          2,
          1,
          isDeletable: false,
        );
      },
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'search_pipeline_forensics',
    displayOrder: 36,
    title: 'Search Pipeline Forensics',
    difficulty: MasteryDifficulty.advanced,
    conceptTags: const {
      MasteryConceptTag.oracle,
      MasteryConceptTag.amplification,
      MasteryConceptTag.iteration,
      MasteryConceptTag.algorithmStructure,
    },
    interactionType: MasteryInteractionType.algorithm,
    levelDefinition: const ConceptCheckLevel(
      title: 'Search Pipeline Forensics',
      badgeLabel: 'Multi-Concept Forensics',
      taskDescription:
          'An eight-state search trace begins uniform. Snapshot A changes only the |101⟩ amplitude from +1/√8 to −1/√8. Measurement is mistakenly placed immediately after A and remains uniform. In a corrected trace, the next coherent stage gives |101⟩ amplitude 5/(2√8) and every other amplitude 1/(2√8). What follows from all three clues?',
      options: [
        '|010⟩ was marked because kets must be read in reverse, and the next stage is another oracle.',
        '|101⟩ was already amplified at A; measurement erased an existing 25/32 bias.',
        '|101⟩ was phase-marked; A is an oracle; amplification must precede measurement and raises its probability to 25/32.',
        'No state was marked because a negative amplitude cannot carry searchable information.',
      ],
      correctOptionIndex: 2,
      hints: ['Track sign, squared magnitude, and stage placement separately.'],
      solutionExplanation:
          'The lone negative amplitude identifies |101⟩ as the oracle-marked state. Its magnitude is still 1/√8, so measuring at A remains uniform. The next coherent amplification stage raises its magnitude to 5/(2√8), giving probability 25/32, while each of seven alternatives has probability 1/32.',
      conceptsUsed: [
        'Oracle inference',
        'Amplification evidence',
        'Measurement placement'
      ],
      difficulty: 'Advanced',
    ),
  ),
];
