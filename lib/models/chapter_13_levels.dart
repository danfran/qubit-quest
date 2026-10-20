import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

// Basis order |q1 q0>: q0 is the least-significant/top wire.
// I - 2|s><s| = -D. These targets are authored, not derived from learner circuits.
List<List<Complex>> _matrix(List<List<num>> values) => [
      for (final row in values)
        [for (final value in row) Complex(value.toDouble(), 0)],
    ];

final _negativeDiffuser = _matrix([
  [0.5, -0.5, -0.5, -0.5],
  [-0.5, 0.5, -0.5, -0.5],
  [-0.5, -0.5, 0.5, -0.5],
  [-0.5, -0.5, -0.5, 0.5],
]);

// Column vectors are images of |00>, |01>, |10>, |11>, respectively.
// Chronological U -> O10 -> (-D); matrix multiplication is (-D) O10 U.
final _fourStateSearch = _matrix([
  [0, 1, 0, 0],
  [0, 0, 0, -1],
  [-1, 0, 0, 0],
  [0, 0, -1, 0],
]);

final _reflectionSolution = CanonicalComposerSolution(const [
  CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
  CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 1),
  CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
  CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 1),
  CanonicalCircuitStep.controlled(SelectedGateType.cz,
      controlQubit: 0, targetQubit: 1),
  CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
  CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 1),
  CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
  CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 1),
]);

List<Gate> _gates() => [
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.cz),
    ];

/// Chapter 13: construction followed by guided order/stopping reasoning.
final List<QQLevel> chapter13Lessons = [
  const ConceptCheckLevel(
    title: 'Amplitudes Around the Mean',
    conceptIntro:
        r'For N real signed amplitudes, the mean is \(m=(a_0+a_1+\cdots+a_{N-1})/N\). Reflection about this mean replaces each amplitude by \(a_i^{\prime}=2m-a_i\). Calculate amplitudes first; probabilities are their squared magnitudes.',
    taskDescription:
        r'Reflect the signed amplitudes \([1/2,1/2,-1/2,1/2]\) about their mean. In basis order \(|00\rangle,|01\rangle,|10\rangle,|11\rangle\), which amplitude vector results?',
    mysteryTitle: 'Can an invisible sign become a certain outcome?',
    mysteryText:
        'Before reflection, all four outcomes have probability 1/4. Track the negative amplitude rather than replacing it with a probability.',
    options: [
      r'\([0,0,1,0]\)',
      r'\([1/4,1/4,1/4,1/4]\)',
      r'\([1/2,1/2,1/2,1/2]\)',
      r'\([3/2,3/2,5/2,3/2]\)',
      r'\([1,1,0,1]\)',
    ],
    correctOptionIndex: 0,
    hints: [
      'Add all four signed amplitudes, including the negative one. Then divide by four.',
      'Subtract each original amplitude from twice the mean. Only then square the new amplitudes.',
    ],
    solutionExplanation:
        r'The signed sum is 1, so \(m=1/4\) and \(2m=1/2\). Each positive 1/2 becomes 0; the negative -1/2 becomes 1. The vector is [0,0,1,0], so this input gives P(|10⟩)=1. Reflecting the probabilities leaves four quarters; ignoring the sign leaves four halves. Using the sum as the mean gives [3/2,3/2,5/2,3/2]. Adding twice the mean instead of reflecting gives [1,1,0,1]. Those last two are not normalized states. Reflection can decrease amplitudes: it does not always increase a marked outcome’s probability.',
    discoveryTitle: 'Reflection About the Mean',
    discoveryText:
        'For these four amplitudes, reflection turns the marked negative amplitude into 1 while the others cancel. Signs, not just probabilities, determine the interference.',
    keyInsight: 'Reflect signed amplitudes before calculating probabilities.',
    whyItMatters:
        'A phase mark can become observable through interference, but amplification depends on the input and when you stop.',
    nextMystery: 'Can gates perform this reflection for every input?',
    conceptsUsed: ['relative phase', 'interference', 'amplitudes'],
  ),
  ComposerLevel.fromBinaryString(
    title: 'Build the Reflection',
    taskDescription:
        r'Build a reusable two-qubit reflection using H, X and CZ. With \(U=H(q0)H(q1)\), \(|s\rangle=U|00\rangle\) and \(D=2|s\rangle\langle s|-I\), the required exact operator is \(-D=I-2|s\rangle\langle s|\). It must work on every input, not just the displayed |00⟩.',
    conceptIntro:
        'CZ changes the sign of |11⟩ only. How could you redirect that sign to |00⟩, then change basis so that it acts on the uniform superposition instead?',
    mysteryTitle: 'Can a basis change turn a phase mark into a reflection?',
    mysteryText:
        'The Inspector shows one test input. Check Result tests the whole operation, including its exact overall sign.',
    hints: [
      'Think of X gates as relabeling which basis state reaches CZ. Undo the relabeling afterward.',
      'H on both qubits maps |00⟩ to the uniform superposition, and is its own inverse. Surround your single-state sign change with that basis change.',
      'The required operation negates |s⟩ and leaves states orthogonal to it unchanged. This is -D; D differs by an overall minus sign.',
    ],
    solutionExplanation:
        'Apply H to both wires, then X to both, CZ, X to both again, and H to both again. The middle operation changes only the sign of |00⟩. Changing basis gives I−2|s⟩⟨s|, exactly -D. Its global minus sign makes the same measurement predictions as D, but this full-unitary task specifies -D exactly.',
    discoveryTitle: 'Diffusion as a Circuit',
    discoveryText:
        'A basis-state phase flip becomes a reflection about a superposition when enclosed by a basis change and its inverse. The constructed operator is -D, globally opposite to reflection about the mean D.',
    keyInsight:
        'Changing basis turns a single-state phase mark into a reusable reflection.',
    whyItMatters:
        'A reusable operator must have the right action on every input, not only one convenient starting state.',
    nextMystery: 'What happens when this reflection follows an oracle?',
    initialQubitsStateString: '00',
    availableGates: _gates(),
    solutionFinalVector: _matrix([
      [0.5],
      [-0.5],
      [-0.5],
      [-0.5]
    ]),
    targetStateExpression:
        r'\(\frac{1}{2}(|00\rangle-|01\rangle-|10\rangle-|11\rangle)\)',
    validationMode: ValidationMode.unitary,
    targetUnitary: _negativeDiffuser,
    canonicalSolution: _reflectionSolution,
    conceptsUsed: ['basis change', 'phase marking', 'reflection'],
  ),
  ComposerLevel.fromBinaryString(
    title: 'Make the Mark Observable',
    taskDescription:
        r'The fixed gates prepare a uniform superposition and mark |10⟩. Complete the amplifier with your reflection \(-D\). Build the full chronological operation \(U\to O_{10}\to(-D)\), not a shortcut for the displayed starting state.',
    conceptIntro:
        r'Here \(U=H(q0)H(q1)\) and \(O_{10}=X(q0)\,CZ\,X(q0)\). q0 is the top, least-significant wire; labels read |q1 q0⟩. Preparation, phase marking and amplitude amplification play different roles.',
    mysteryTitle:
        'Why is the marked state still only one of four possibilities?',
    mysteryText:
        'Inspect the fixed circuit before adding gates: marking alone leaves all probabilities at 1/4. The negative amplitude identifies |10⟩, but a Z-basis measurement cannot yet reveal that sign.',
    hints: [
      'Leave the preparation and oracle fixed. Append the reusable reflection from the previous lesson.',
      'The oracle has changed a sign, not a probability. Your amplifier must mix amplitudes so that the other three outcomes cancel.',
      'Certainty for this starting state is necessary but not sufficient: Check Result compares the complete unitary operation.',
    ],
    solutionExplanation:
        'The fixed preparation and oracle produce [1/2,1/2,−1/2,1/2]. Appending -D gives [0,0,−1,0], so P(|10⟩)=1. The overall minus sign does not change this distribution. The full matrix is (-D)O10U; merely flipping q1 on |00⟩ would give the same outcome but is a different operation and is rejected. Certainty here is special to this four-state input, not a promise that more reflections always help.',
    discoveryTitle: 'Four-State Quantum Search',
    discoveryText:
        'Preparation supplies equal amplitudes, the oracle marks a sign, and the diffuser converts that sign into a certain |10⟩ outcome in this four-state example.',
    keyInsight:
        'An oracle marks phase; interference makes the mark observable.',
    whyItMatters:
        'Search is a composition of distinct operations. Matching a single output does not prove that composition is correct.',
    nextMystery:
        'Would changing the order, or repeating the reflection, still help?',
    initialQubitsStateString: '00',
    preInsertedGates: (circuit) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1,
          isDeletable: false);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 1, 0,
          isDeletable: false);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 2, 1, 0,
          isDeletable: false);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 3, 0,
          isDeletable: false);
    },
    availableGates: _gates(),
    solutionFinalVector: _matrix([
      [0],
      [0],
      [-1],
      [0]
    ]),
    targetStateExpression: r'\(-|10\rangle\)',
    validationMode: ValidationMode.unitary,
    targetUnitary: _fourStateSearch,
    canonicalSolution: _reflectionSolution,
    conceptsUsed: ['preparation', 'oracle', 'amplitude amplification'],
  ),
  const ConceptCheckLevel(
    title: 'Order Is Part of the Algorithm',
    conceptIntro:
        r'Let \(U=H(q0)H(q1)\), \(|s\rangle=U|00\rangle\), and let \(O_{10}\) flip only the sign of |10⟩. The circuit reflection is -D. Compare operations in chronological order, from left to right.',
    taskDescription:
        'Which order makes |10⟩ certain, and why: A, U → O10 → (-D), or B, U → (-D) → O10?',
    mysteryTitle: 'Can the same operations give different outcomes?',
    mysteryText:
        r'Basis order: 00, 01, 10, 11; q0 is the top, least-significant wire. Preparation gives [1/2,1/2,1/2,1/2]. In A, the oracle gives [1/2,1/2,-1/2,1/2] before reflection. In B, \((-D)|s\rangle=-|s\rangle\), so reflection first gives [-1/2,-1/2,-1/2,-1/2]. Now apply the remaining operation to each sequence.',
    options: [
      'A: the oracle creates a relative sign, then reflection turns it into interference that cancels the other outcomes.',
      'Both: the same gates can be reordered without changing their effect.',
      'B: reflection always increases success, so it should come before marking.',
      'Neither: a phase mark is invisible to measurement, even after reflection.',
    ],
    correctOptionIndex: 0,
    hints: [
      'For A, reuse reflection about the mean from Lesson 61, then include the overall minus sign of -D.',
      'For B, the final oracle changes only one sign. Do any squared magnitudes change?',
    ],
    solutionExplanation:
        'A ends at [0,0,-1,0], so P(|10⟩)=1. B ends at [-1/2,-1/2,1/2,-1/2], so every probability is 1/4. Acting on the uniform state, -D only adds a global minus; that changes no probabilities. Marking afterward still changes only a sign. The oracle and reflection do not commute here: the relative sign must be present when amplitudes interfere. Diffusion does not automatically increase success on every input.',
    discoveryTitle: 'Search Round Order',
    discoveryText:
        'The oracle must create the relative phase before the reflection can turn it into unequal probabilities. The same operations in a different order can do different work.',
    keyInsight:
        'Order is part of a quantum algorithm, not just a way to draw it.',
    whyItMatters:
        'Reason about the state entering each operation rather than assuming that a list of useful gates guarantees success.',
    nextMystery:
        'If one search round succeeds, would another make it even better?',
    conceptsUsed: ['operation order', 'relative phase', 'interference'],
  ),
  const ConceptCheckLevel(
    title: 'One More Round Can Be Worse',
    conceptIntro:
        r'A round is oracle then reflection. For this calculation use \(D=2|s\rangle\langle s|-I\) and \(a_i^{\prime}=2m-a_i\). The circuit from Lesson 62 uses -D instead: after r complete rounds its vector is \((-1)^r\) times this D trace, with identical probabilities.',
    taskDescription:
        'For four states and one marked state |10⟩, when should you stop among zero, one and two rounds to obtain the greatest success probability?',
    mysteryTitle: 'Can another correct search round undo success?',
    mysteryText:
        'Signed D trace in order 00, 01, 10, 11:\nInitial: [1/2,1/2,1/2,1/2]\nFirst oracle: [1/2,1/2,-1/2,1/2]\nFirst D: [0,0,1,0]\nSecond oracle: [0,0,-1,0]\nSecond D: [-1/2,-1/2,1/2,-1/2]\nCompare the squared magnitude at index 2 after zero, one and two complete rounds.',
    options: [
      'Two rounds: repeating the amplifier must improve success.',
      'One round: success reaches certainty, then drops when another round moves amplitudes past that point.',
      'Zero rounds: equal amplitudes already make the marked state certain.',
      'One or two rounds equally: all the sign changes shown are just a global phase.',
    ],
    correctOptionIndex: 1,
    hints: [
      'The marked amplitude is the third entry. Square it at the three round boundaries, not immediately after an oracle alone.',
      'After the second oracle the mean is -1/4. Use twice that mean minus each amplitude to check the final row.',
    ],
    solutionExplanation:
        'The success probabilities are 1/4 → 1 → 1/4. Stop after one round for this input. Before the first D, m=1/4, yielding [0,0,1,0]. Before the second D, m=-1/4, yielding [-1/2,-1/2,1/2,-1/2]. With the physical -D circuit, the first-round vector is [0,0,-1,0]; the second oracle gives [0,0,1,0]; the second -D gives [-1/2,-1/2,1/2,-1/2]. Thus D and -D agree on probabilities, although their exact intermediate signs differ. One- and two-round states are not related by only a global phase: their magnitudes differ. Another round continues coherent evolution beyond the optimum, rather than accumulating irreversible progress. Other search sizes or marked-state counts can need a different stopping point.',
    discoveryTitle: 'Search Stopping Point',
    discoveryText:
        'For four states with one marked state, one round gives certainty but two rounds return success to 1/4. Amplification is coherent evolution and can overshoot.',
    keyInsight:
        'Choose when to stop from the amplitudes; more rounds need not mean more success.',
    whyItMatters:
        'A quantum algorithm needs a stopping rule as well as a repeated operation.',
    nextMystery:
        'How does the stopping point change when there are eight possibilities?',
    conceptsUsed: ['amplitude amplification', 'overshoot', 'global phase'],
  ),
  const ConceptCheckLevel(
    title: 'Choose a Stopping Point',
    conceptIntro:
        r'Now search eight states with one marked state |110⟩, in basis order |q2 q1 q0⟩. Write the marked amplitude as \(b/\sqrt{8}\) and each of the seven equal unmarked amplitudes as \(c/\sqrt{8}\). Start with b=c=1. These signed coefficients use D; -D gives the same success probabilities.',
    taskDescription:
        'Among zero, one, two and three rounds, what is the fewest number of rounds that gives greater than 90% success for eight states and one marked state?',
    mysteryTitle: 'Can you calculate a stopping point instead of guessing?',
    mysteryText:
        r'For each oracle-then-D round, compute the mean coefficient after marking: \(\mu=(7c-b)/8\). Then update both coefficients from that same old pair: \(b_{next}=2\mu+b\), \(c_{next}=2\mu-c\). Success is \(P=b^2/8\); normalization requires \((b^2+7c^2)/8=1\). The first round gives (b,c)=(5/2,1/2). Work out the next two pairs before choosing.',
    options: [
      'Zero rounds: uniform preparation is sufficient.',
      'One round: the four-state stopping point also applies to eight states.',
      'Two rounds: this is the first round count whose marked probability exceeds 90%.',
      'Three rounds: the largest available round count must have the highest success.',
    ],
    correctOptionIndex: 2,
    hints: [
      'From (5/2,1/2), calculate μ=(7/2-5/2)/8. Update b and c together; do not use the new b while computing c.',
      'Square b and divide by eight after each round. Check both the threshold and whether an earlier round already exceeded it.',
    ],
    solutionExplanation:
        'The coefficient pairs for rounds 0–3 are (1,1), (5/2,1/2), (11/4,-1/4), and (13/8,-7/8). Their marked probabilities are 1/8=12.5%, 25/32=78.125%, 121/128=94.53125%, and 169/512=33.0078125%. Two is therefore the fewest rounds exceeding 90% among 0–3; the third round overshoots. Each pair satisfies b²+7c²=8. The seven in the mean comes from seven unmarked states, not a universal constant. Changing the search-space size or the number of marked solutions changes the amplitude evolution and stopping point. Two rounds are not universally optimal, and the threshold need not be reached in every problem.',
    discoveryTitle: 'Quantitative Search',
    discoveryText:
        'For eight states with one marked state, a recurrence predicts 12.5%, 78.125%, 94.53125% and 33.0078125% success after zero through three rounds. A numerical threshold selects the stopping point.',
    keyInsight:
        'Calculate the first round count that meets the goal; do not assume that more is better.',
    whyItMatters:
        'Search-space size and marked-solution count determine how quickly amplification approaches and passes its optimum.',
    nextMystery:
        'How would you adapt the calculation if more than one state were marked?',
    conceptsUsed: ['amplitude recurrence', 'normalization', 'quantum search'],
  ),
];
