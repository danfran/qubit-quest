// Mastery challenges 43–48: conditional quantum logic (v2.6 M10).
//
// Register convention |q(n−1)…q0⟩; q0 is the top wire. Operator targets
// are written from their definitions (see chapter_14_levels.dart).
import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/chapter_14_levels.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

Gate _g(SelectedGateType t) => Gate.fromIdentifier(t);

List<List<Complex>> _basisColumn(int qubits, int index) => [
      for (var i = 0; i < 1 << qubits; i++)
        [i == index ? Complex.one() : Complex.zero()]
    ];

/// Pattern 0110 on q3 q2 q1 q0 (q0=0, q1=1, q2=1, q3=0), auxiliary q4.
const int _tracePattern = 0x06;

final List<MasteryChallengeDefinition> masteryConditionalLogicBatch = [
  MasteryChallengeDefinition(
    semanticId: 'same_odds_different_phase',
    displayOrder: 43,
    title: 'Same Odds, Different Phase',
    difficulty: MasteryDifficulty.application,
    conceptTags: const {
      MasteryConceptTag.relativePhase,
      MasteryConceptTag.interference,
      MasteryConceptTag.control,
    },
    interactionType: MasteryInteractionType.evidence,
    levelDefinition: const ConceptCheckLevel(
      title: 'Same Odds, Different Phase',
      conceptIntro:
          'Circuit A applies H(q0) then CX(q0→q1); circuit B applies H(q0) then CY(q0→q1). Both start from |00⟩. Labels are |q1 q0⟩.',
      taskDescription:
          'Both circuits give 50% |00⟩ and 50% |11⟩ when measured in the Z basis. Which evidence shows that they prepared different states?',
      options: [
        'Repeat the Z-basis measurement many more times: the frequencies will eventually differ.',
        'Append CX(q0→q1), S(q0) and H(q0): A then gives 50/50 on q0, while B gives |01⟩ every time.',
        'None: equal Z-basis probabilities mean the two states are the same physical state.',
        'Measure q1 first: in B, the result decides what CY did to q0.',
      ],
      correctOptionIndex: 1,
      hints: [
        r'Write both states: (|00⟩ + |11⟩)/√2 and (|00⟩ + i|11⟩)/√2. What differs?',
        'A difference in relative phase needs interference to become visible. Track each state through CX, then S and H on q0.',
      ],
      solutionExplanation:
          r'A prepares (|00⟩ + |11⟩)/√2, B prepares (|00⟩ + i|11⟩)/√2. Their Z-basis statistics are identical, so more Z-basis shots cannot separate them. After CX(q0→q1), q0 is |+⟩ in A and (|0⟩ + i|1⟩)/√2 in B. S then H gives 50/50 for A and |1⟩ for B: the relative phase i becomes a certain outcome. Equal probabilities do not establish equal states, and CY acts coherently: nothing is decided by measuring first.',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'undo_complex_control',
    displayOrder: 44,
    title: 'Undo the Complex Control',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.inverseOrder,
      MasteryConceptTag.control,
      MasteryConceptTag.operatorAction,
    },
    interactionType: MasteryInteractionType.uncomputation,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'Undo the Complex Control',
      taskDescription:
          'The fixed gates apply S(q0) and then CY(q1→q0). Append gates so the whole circuit is the identity on every input: the fixed operation followed by its exact inverse. Labels are |q1 q0⟩.',
      conceptIntro:
          r'The inverse of a product reverses its order: \((\mathrm{CY}\,S)^{-1}=S^{\dagger}\,\mathrm{CY}^{\dagger}\). CY is its own inverse; S is not, and \(S^{\dagger}=ZS\).',
      initialQubitsStateString: '10',
      preInsertedGates: (circuit) {
        circuit.insertSinglePlacedGateAt(_g(SelectedGateType.s), 0, 0,
            isDeletable: false);
        circuit.insertDoublePlacedGateAt(_g(SelectedGateType.cy), 1, 0, 1,
            isDeletable: false);
      },
      availableGates: [
        _g(SelectedGateType.cy),
        _g(SelectedGateType.cnot),
        _g(SelectedGateType.s),
        _g(SelectedGateType.z),
      ],
      solutionFinalVector: _basisColumn(2, 0x02),
      targetStateExpression: '|10⟩',
      validationMode: ValidationMode.unitary,
      targetUnitary: permutationMatrix(2, (c) => c),
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.controlled(SelectedGateType.cy,
            controlQubit: 1, targetQubit: 0),
        CanonicalCircuitStep.single(SelectedGateType.z, targetQubit: 0),
        CanonicalCircuitStep.single(SelectedGateType.s, targetQubit: 0),
      ]),
      hints: const [
        'Undo the last fixed gate first.',
        'After CY is undone, only S remains. Which gates on q0 multiply |1⟩ by −i?',
      ],
      solutionExplanation:
          'Append CY(q1→q0), then Z and S on q0. CY·CY = I removes the controlled operation; ZS = S† removes S. The order matters: S† before CY gives CY·S†·CY·S, which is not the identity because S does not commute with Y. CX in place of CY leaves the phases of the controlled branch wrong. The |10⟩ preview alone cannot certify the inverse; the check compares the whole operator.',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'every_control_matters',
    displayOrder: 45,
    title: 'Every Control Matters',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.control,
      MasteryConceptTag.operatorAction,
      MasteryConceptTag.reversibility,
    },
    interactionType: MasteryInteractionType.construction,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'Every Control Matters',
      taskDescription:
          'In a five-qubit register, flip q3 exactly when q0 = 1, q2 = 1 and q4 = 0. q1 is not part of the condition. Every input label other than q3 must be unchanged. Check Result tests all 32 inputs.',
      conceptIntro:
          'MCX fires when every control is 1. A condition that needs a 0 can be met by flipping that qubit with X before the MCX and flipping it back afterwards. Labels are |q4 q3 q2 q1 q0⟩.',
      initialQubitsStateString: '00101',
      availableGates: [
        _g(SelectedGateType.mcx),
        _g(SelectedGateType.x),
      ],
      solutionFinalVector: _basisColumn(5, 0x0D),
      targetStateExpression: '|01101⟩',
      validationMode: ValidationMode.unitary,
      targetUnitary: permutationMatrix(
          5, (c) => (c & 0x15) == 0x05 ? c ^ 0x08 : c), // q0=1,q2=1,q4=0
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 4),
        CanonicalCircuitStep.multiControlledX(
            controlQubits: [0, 2, 4], targetQubit: 3),
        CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 4),
      ]),
      hints: const [
        'Which qubits take part in the condition, and which of them must be 0?',
        'Temporarily flip q4, use it as a control with q0 and q2, then flip it back.',
      ],
      solutionExplanation:
          'X(q4), MCX(q0,q2,q4 → q3), X(q4). After the first X, q4 = 1 exactly when it was 0, so the MCX fires for q0 = q2 = 1 and original q4 = 0; the last X restores q4. Including q1 as a control, or forgetting to restore q4, produces a different operator even when the displayed |00101⟩ → |01101⟩ looks right.',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'condition_without_decision',
    displayOrder: 46,
    title: 'A Condition Without a Decision',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {
      MasteryConceptTag.superposition,
      MasteryConceptTag.control,
      MasteryConceptTag.classicalMixture,
    },
    interactionType: MasteryInteractionType.prediction,
    levelDefinition: const ConceptCheckLevel(
      title: 'A Condition Without a Decision',
      conceptIntro:
          'q0, q1 and q2 are each prepared in |+⟩ with H; the target q3 starts in |0⟩. Then MCX(q0,q1,q2 → q3) is applied. Labels are |q3 q2 q1 q0⟩.',
      taskDescription:
          'Which description of the result is correct?',
      options: [
        'One joint state, (1/√8)(|0 000⟩ + |0 001⟩ + … + |0 110⟩ + |1 111⟩): q3 is 1 only alongside 111, and measuring q3 gives 1 with probability 1/8.',
        'The MCX first checks the controls; with probability 1/8 it finds 111 and flips q3, otherwise it does nothing.',
        'q3 ends in its own state √(7/8)|0⟩ + √(1/8)|1⟩, independent of the controls.',
        'The controls collapse to 111 because a controlled gate needs definite control values.',
      ],
      correctOptionIndex: 0,
      hints: [
        'After the H gates there are eight components with equal amplitude. Apply the MCX to each component separately.',
        'Is q3 correlated with the controls afterwards? A separate state for q3 would mean it is not.',
      ],
      solutionExplanation:
          r'MCX acts on every component of the superposition: only |0111⟩ becomes |1111⟩. The result is one coherent joint state with amplitude 1/√8 on eight labels. Measured in the Z basis, q3 gives 1 with probability 1/8 = 12.5% and 0 with probability 87.5%, but q3 has no separate state: it is entangled with the controls. No control is measured and no classical check happens; describing it as a 1/8 chance of "firing" confuses the measurement statistics with the operation.',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'mark_the_condition',
    displayOrder: 47,
    title: 'Mark the Condition',
    difficulty: MasteryDifficulty.advanced,
    conceptTags: const {
      MasteryConceptTag.oracle,
      MasteryConceptTag.kickback,
      MasteryConceptTag.relativePhase,
    },
    interactionType: MasteryInteractionType.evidence,
    levelDefinition: const ConceptCheckLevel(
      title: 'Mark the Condition',
      conceptIntro:
          'Two candidate phase oracles should mark the input 101 (q2 q1 q0) on a uniform superposition of q0–q2, with an auxiliary q3 prepared in |−⟩. Candidate A: X(q1), MCX(q0,q1,q2 → q3), X(q1). Candidate B: nothing at all.',
      taskDescription:
          'Both candidates give the same Z-basis probabilities on the inputs (1/8 each). Which statement is correct?',
      options: [
        'B is a valid oracle: equal output probabilities show it behaves like A.',
        'A is invalid: its MCX would flip the auxiliary to |1⟩, so the auxiliary must be measured afterwards.',
        'Only A marks 101: it gives that component a factor −1 and leaves every label and the |−⟩ auxiliary unchanged. Probabilities cannot show the difference; amplitudes or a later interference step can.',
        'A marks every input whose q1 is 0, because X(q1) flips the condition for all inputs.',
      ],
      correctOptionIndex: 2,
      hints: [
        'A phase oracle changes signs, not magnitudes. What does that mean for Z-basis probabilities?',
        'Track the auxiliary: X|−⟩ = −|−⟩. Does its state change?',
      ],
      solutionExplanation:
          'X(q1) turns the pattern 101 into 111 for the MCX, which kicks back −1 onto that component only, and the second X(q1) restores the label. The auxiliary stays |−⟩ and never needs measuring. A phase oracle cannot change Z-basis probabilities, so B looks identical in that test. Matching probabilities is insufficient: compare amplitudes, the full operator, or the outcome after interference (for example amplitude amplification).',
    ),
  ),
  MasteryChallengeDefinition(
    semanticId: 'oracle_left_a_trace',
    displayOrder: 48,
    title: 'The Oracle That Left a Trace',
    difficulty: MasteryDifficulty.advanced,
    conceptTags: const {
      MasteryConceptTag.oracle,
      MasteryConceptTag.reversibility,
      MasteryConceptTag.algorithmStructure,
    },
    interactionType: MasteryInteractionType.debugging,
    levelDefinition: ComposerLevel.fromBinaryString(
      title: 'The Oracle That Left a Trace',
      taskDescription:
          'This oracle should leave the input x = q3 q2 q1 q0 unchanged and replace the auxiliary y = q4 by y ⊕ f(x), with f(x) = 1 only for x = 0110. Its fixed gates contain a bug. Repair it by adding gates so the complete operator is correct on all 32 inputs.',
      conceptIntro:
          'An oracle may change inputs temporarily, but everything temporary must be undone. A left-over change corrupts every later step that uses the inputs, even when the auxiliary result is right. Labels are |q4 q3 q2 q1 q0⟩.',
      initialQubitsStateString: '00110',
      preInsertedGates: (circuit) {
        circuit.insertSinglePlacedGateAt(_g(SelectedGateType.x), 0, 0,
            isDeletable: false);
        circuit.insertSinglePlacedGateAt(_g(SelectedGateType.x), 0, 3,
            isDeletable: false);
        circuit.insertMultiControlledGateWithOutcome(
            _g(SelectedGateType.mcx), 1, 4, [0, 1, 2, 3],
            isDeletable: false);
        circuit.insertSinglePlacedGateAt(_g(SelectedGateType.x), 2, 0,
            isDeletable: false);
      },
      availableGates: [
        _g(SelectedGateType.x),
        _g(SelectedGateType.mcx),
      ],
      solutionFinalVector: _basisColumn(5, 0x16),
      targetStateExpression: '|10110⟩',
      validationMode: ValidationMode.unitary,
      targetUnitary: permutationMatrix(
          5, (c) => (c & 0x0F) == _tracePattern ? c ^ 0x10 : c),
      canonicalSolution: CanonicalComposerSolution(const [
        CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 3),
      ]),
      hints: const [
        'Run the displayed input 0110 through the fixed gates. Which input qubit does not return to its original value?',
        'Every temporary X needs a matching X after the MCX.',
      ],
      solutionExplanation:
          'The fixed circuit flips q0 and q3 so that the MCX recognises 0110, but only q0 is flipped back. For the displayed input the auxiliary is right (it becomes 1) yet q3 is left at 1: the output is |11110⟩ instead of |10110⟩. Adding X(q3) after the MCX uncomputes the trace. With the auxiliary in |−⟩, the unrepaired version would still produce the right sign on 0110, but on an input register that has been permanently relabelled, so interference in a search algorithm would act on the wrong states.',
    ),
  ),
];
