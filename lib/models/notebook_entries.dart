import 'package:quantumquiz/models/notebook_entry.dart';

const List<NotebookEntry> notebookEntries = [
  NotebookEntry(
    id: 'information',
    discoveryTitle: 'Information',
    chapterIndex: 1,
    chapterTitle: 'Chapter 1 - The Quantum Bit',
    title: 'The First Qubit',
    summary: 'A qubit can hold a state, and a circuit can change that state.',
    executableExampleIds: ['x_from_zero'],
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Think of a qubit as a tiny piece of information with a current state. At the start, it is |0⟩. The X gate acts like a switch: it changes the qubit into |1⟩. This is the first idea behind a quantum circuit: gates transform states.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The qubit changed from one basis state to another. Before the gate, measuring gives 0. After the gate, measuring gives 1.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|0⟩'),
        NotebookExample.math(label: 'After', notation: '|1⟩'),
        NotebookExample.math(label: 'Gate action', notation: 'X|0⟩ = |1⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The symbols |0⟩ and |1⟩ are state labels. They describe the state of the qubit before measurement. In this first chapter, the important move is simple: a gate changes one state label into another.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          '|0⟩ and |1⟩ are called basis states. The X gate is often called the Pauli-X gate. In these first levels, it behaves like a reversible bit flip: it changes which basis state the qubit is in, but it does not destroy the qubit.',
    ),
    relatedDiscoveryTitles: [
      'Reversibility',
      'State Transformations',
      'The Quantum Bit',
    ],
  ),
  NotebookEntry(
    id: 'reversibility',
    discoveryTitle: 'Reversibility',
    chapterIndex: 1,
    chapterTitle: 'Chapter 1 - The Quantum Bit',
    title: 'Undo The Change',
    summary: 'A quantum change can be undone by applying another operation.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Every quantum gate has an operation that undoes it. We write that inverse as U† (“U dagger”). Imagine retracing a route home: undo the last turn first, then continue backward. A circuit is undone by reversing its order and replacing each operation with its inverse.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The visible state changed and then returned. X and CNOT are self-inverse, so the same operation undoes them. Phase gates need their inverse partner: S is undone by S†, and T by T†.',
      examples: [
        NotebookExample.math(
          label: 'X progression',
          notation: '|0⟩ → X → |1⟩ → X → |0⟩',
          mathRole: NotebookMathRole.emphasis,
        ),
        NotebookExample.math(
          label: 'Reverse a sequence',
          notation: 'A → B → C  is undone by  C† → B† → A†',
          latexLines: [
            r'A \rightarrow B \rightarrow C',
            r'C^{\dagger} \rightarrow B^{\dagger} \rightarrow A^{\dagger}',
          ],
          mathRole: NotebookMathRole.emphasis,
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'An inverse satisfies U†U = I, where I is the identity: the operation that leaves the state unchanged. For a circuit U = CBA, its inverse is U† = A†B†C†. This restores every input, not only one convenient basis state.',
      examples: [
        NotebookExample.math(
          label: 'Inverse identity',
          notation: 'U†U = I',
        ),
        NotebookExample.math(
            label: 'X on basis states', notation: 'X|0⟩ = |1⟩\nX|1⟩ = |0⟩'),
        NotebookExample.math(
            label: 'Self-inverse gates', notation: 'X² = I\nCNOT² = I'),
        NotebookExample.math(
            label: 'Phase inverses', notation: 'S†S = I\nT†T = I'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Mathematically, U† is the conjugate transpose of U. Quantum gates are unitary, so U† is also U⁻¹. Uncomputation reverses temporary work after its useful effect has been transferred or encoded. It can return workspace qubits to their starting state without erasing the result preserved elsewhere.',
    ),
    relatedDiscoveryTitles: [
      'Information',
      'Equivalent Results',
      'The Quantum Bit',
    ],
  ),
  NotebookEntry(
    id: 'equivalent_results',
    discoveryTitle: 'Equivalent Results',
    chapterIndex: 1,
    chapterTitle: 'Chapter 1 - The Quantum Bit',
    title: 'Different Paths',
    summary: 'Different gate sequences can produce the same final state.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'There can be more than one route to the same place. A short route might use one X gate. A longer route might use three X gates. Since two X gates cancel, three X gates behave like one X overall.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The path changed, but the destination stayed the same. One X and three X gates both end at |1⟩, because two of the flips cancel each other.',
      examples: [
        NotebookExample.math(label: 'Short path', notation: '|0⟩ → X → |1⟩'),
        NotebookExample.math(
          label: 'Long path',
          notation: '|0⟩ → X → |1⟩ → X → |0⟩ → X → |1⟩',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Two X gates cancel. Three X gates act like one X because one pair cancels and one flip remains.',
      examples: [
        NotebookExample.math(label: 'Two X gates', notation: 'XX|0⟩ = |0⟩'),
        NotebookExample.math(label: 'Three X gates', notation: 'XXX|0⟩ = |1⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This is an early example of circuit equivalence. Later, two circuits may look different but have the same useful effect. Sometimes the route matters because it reveals, hides, or prepares information for a later step.',
    ),
    relatedDiscoveryTitles: [
      'Reversibility',
      'State Transformations',
      'Hidden Change',
    ],
  ),
  NotebookEntry(
    id: 'state_transformations',
    discoveryTitle: 'State Transformations',
    chapterIndex: 1,
    chapterTitle: 'Chapter 1 - The Quantum Bit',
    title: 'Information Patterns',
    summary:
        'A multi-qubit state is an information pattern, and gates can transform selected parts of that pattern.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'One qubit can hold one piece of information. Two qubits form a pattern, such as |00⟩ or |11⟩. To change |00⟩ into |11⟩, each qubit must be flipped.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The circuit transformed a whole register, not just a single symbol. Each wire carried one part of the pattern.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|00⟩'),
        NotebookExample.math(label: 'After', notation: '|11⟩'),
        NotebookExample(
            label: 'Each part changed',
            notation: 'first qubit: 0 → 1\nsecond qubit: 0 → 1'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'For two qubits, the state label has two positions. Each position belongs to one qubit. Applying X to each qubit changes both parts of the state label while keeping the register as one combined state.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'A group of qubits is often called a register. Quantum algorithms operate on registers, transforming whole patterns of information rather than isolated values.',
    ),
    relatedDiscoveryTitles: [
      'Information',
      'Equivalent Results',
      'The Quantum Bit',
    ],
  ),
  NotebookEntry(
    id: 'the_quantum_bit',
    discoveryTitle: 'The Quantum Bit',
    chapterIndex: 1,
    chapterTitle: 'Chapter 1 - The Quantum Bit',
    title: 'What Have We Learned?',
    summary:
        'A qubit is the object that stores quantum information and responds to gates.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A qubit is not just the symbol 0 or 1 on the screen. It is the thing being transformed. When the circuit changes |01⟩ into |10⟩, each qubit keeps its place in the register while its state changes. This makes the qubit the basic unit that gates act on.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'Both qubits changed state, but the register structure stayed the same: there were still two qubits, and each position still mattered.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|01⟩'),
        NotebookExample.math(label: 'After', notation: '|10⟩'),
        NotebookExample(
            label: 'Each part changed',
            notation: 'first qubit: 0 → 1\nsecond qubit: 1 → 0'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'A two-qubit state such as |01⟩ describes an ordered register. The first position and second position are different qubits. Applying X to each qubit changes the pattern from |01⟩ to |10⟩.',
      examples: [
        NotebookExample.math(label: 'Pattern change', notation: '|01⟩ → |10⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'The word qubit means quantum bit. Chapter 1 treated qubits like reversible bits so the basic language is clear. Chapter 2 begins the next step: a qubit can change in ways that are not always visible as a changed 0 or 1.',
    ),
    relatedDiscoveryTitles: [
      'Information',
      'Reversibility',
      'State Transformations',
      'Hidden Change',
      'Invisible Difference',
    ],
  ),
  NotebookEntry(
    id: 'hidden_change',
    discoveryTitle: 'Hidden Change',
    chapterIndex: 2,
    chapterTitle: 'Chapter 2 - Hidden Change',
    title: 'Hidden Change',
    summary:
        'A gate can have a real action even when this input does not visibly change.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Imagine testing a stamp on a dark card where the mark is hard to see. The stamp still touched the card; this card simply does not reveal the mark. Z on |0⟩ is like that. The output still looks like |0⟩, but the circuit has used a real operation.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The visible state stayed |0⟩. What changed is the player\'s model: a gate can matter even when the measured result does not change.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|0⟩'),
        NotebookExample.math(label: 'After Z', notation: '|0⟩'),
        NotebookExample.math(
            label: 'Visible measurement', notation: 'P(|0⟩) = 100%'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Z leaves |0⟩ unchanged, but that does not mean Z does nothing. The same gate will behave differently on |1⟩. This separates "nothing visible changed" from "nothing happened."',
      examples: [
        NotebookExample.math(label: 'Z on |0⟩', notation: 'Z|0⟩ = |0⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'To understand a gate, one input is not always enough. Some effects only appear on other states or when the state has multiple parts. This is the doorway into phase.',
    ),
    relatedDiscoveryTitles: [
      'Equivalent Results',
      'The Quantum Bit',
      'Invisible Difference',
    ],
  ),
  NotebookEntry(
    id: 'invisible_difference',
    discoveryTitle: 'Invisible Difference',
    chapterIndex: 2,
    chapterTitle: 'Chapter 2 - Hidden Change',
    title: 'Invisible Difference',
    summary:
        'Different state vectors can represent exactly the same physical pure state when they differ only by global phase.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Think of writing the same direction arrow at two different scales or with one overall sign. '
          'Quantum mechanics identifies vectors that differ only by one common phase. The minus sign '
          'on −|1⟩ is not hidden physical information: it is another representation of |1⟩.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The displayed vector gained a minus sign. The physical state, its Bloch-sphere point, '
          'and every possible experimental prediction stayed unchanged.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|1⟩'),
        NotebookExample.math(label: 'After', notation: '−|1⟩'),
        NotebookExample.math(
          label: 'Measurement',
          notation: 'P(|1⟩) = 100% before\nP(|1⟩) = 100% after',
          latexLines: [
            r'P(\lvert1\rangle)_{\mathrm{before}}=100\%',
            r'P(\lvert1\rangle)_{\mathrm{after}}=100\%',
          ],
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Z leaves |0⟩ alone and writes |1⟩ as −|1⟩. For this basis-state input, the sign '
          'multiplies the whole vector and is global phase. With multiple nonzero amplitudes, Z can '
          'instead change one component relative to another, and that relative phase is physical.',
      examples: [
        NotebookExample.math(
          label: 'Z gate action',
          notation: 'Z|0⟩ = |0⟩\nZ|1⟩ = −|1⟩',
        ),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'More generally, |ψ⟩ and e^(iφ)|ψ⟩ represent the same pure state for every φ. '
          'Global phase multiplies all amplitudes equally, changes no probability or later prediction, '
          'and maps to the same Bloch-sphere point. The same distinction applies to operations: U and '
          'e^(iφ)U are not literally the same matrix, but on an isolated pure state their outputs differ '
          'only by one common global phase. Relative phase changes ratios between amplitudes and can alter interference.',
      examples: [
        NotebookExample.math(
          label: 'Operation equivalence',
          notation: 'V = e^(iφ)U  does not mean  V = U',
          latex: r'V=e^{i\phi}U \not\Rightarrow V=U',
          explanation:
              'The matrices differ, while their output pure states are physically equivalent up to global phase.',
        ),
      ],
    ),
    relatedDiscoveryTitles: [
      'Hidden Change',
      'The Quantum Bit',
      'Relative Phase',
      'Phase Information',
    ],
  ),
  NotebookEntry(
    id: 'the_minus_sign',
    discoveryTitle: 'Relative Phase',
    chapterIndex: 2,
    chapterTitle: 'Chapter 2 - Hidden Change',
    title: 'The Minus Sign',
    executableExampleIds: ['z_on_plus'],
    summary:
        'A minus sign becomes meaningful when it changes the relationship between parts of a state.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A lone sign can be hard to notice. In a balanced state, there are two pieces to compare. Changing one piece from plus to minus changes how the pieces relate, even when the visible odds still look even.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The probabilities stayed balanced. What changed was the relationship between the |0⟩ part and the |1⟩ part: plus became minus.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|+⟩ = (|0⟩ + |1⟩)/√2'),
        NotebookExample.math(label: 'After', notation: '|−⟩ = (|0⟩ − |1⟩)/√2'),
        NotebookExample.math(
            label: 'Measurement', notation: 'P(|0⟩) = 50%\nP(|1⟩) = 50%'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'This sign relationship is relative phase. Relative phase does not show up as a simple probability bar, but a later gate can make the difference visible.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          '|+⟩ and |−⟩ look identical if you only compare measurement odds in the |0⟩, |1⟩ basis. They are not the same state. Their different phase relationship gives later gates something to respond to.',
    ),
    relatedDiscoveryTitles: [
      'Invisible Difference',
      'Equivalent Results',
      'Phase Information',
    ],
  ),
  NotebookEntry(
    id: 'hidden_information',
    discoveryTitle: 'Phase Information',
    chapterIndex: 2,
    chapterTitle: 'Chapter 2 - Hidden Change',
    title: 'Hidden Information',
    executableExampleIds: ['s_on_plus'],
    summary:
        'Quantum information can be stored in relationships that measurement probabilities do not directly show.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Think of phase as a private instruction inside the state. The probability bars say which outcomes may appear. The phase relationship says how the parts of the state should combine when another gate acts on them.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The possible measurement outcomes stayed the same, but the relationship between the two parts changed. The circuit changed |−⟩ back into |+⟩, turning a minus relationship into a plus relationship.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|−⟩ = (|0⟩ − |1⟩)/√2'),
        NotebookExample.math(label: 'After', notation: '|+⟩ = (|0⟩ + |1⟩)/√2'),
        NotebookExample.math(
            label: 'Measurement before',
            notation: 'P(|0⟩) = 50%\nP(|1⟩) = 50%',
            comparisonGroup: 'hidden-information-measurement'),
        NotebookExample.math(
            label: 'Measurement after',
            notation: 'P(|0⟩) = 50%\nP(|1⟩) = 50%',
            comparisonGroup: 'hidden-information-measurement'),
        NotebookExample(
            label: 'Key difference',
            notation:
                'The probabilities stayed the same, but the phase relationship changed.'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          '|+⟩ and |−⟩ contain the same possible measurement outcomes with the same probabilities. Their difference is the phase relationship between |0⟩ and |1⟩. Successive phase operations multiply the |1⟩ amplitude by successive phase factors, so their turns accumulate.',
      examples: [
        NotebookExample.math(
          label: 'Accumulated phase',
          notation: 'e^(iα)e^(iβ) = e^(i(α+β))',
          latex: r'e^{i\alpha}e^{i\beta}=e^{i(\alpha+\beta)}',
        ),
        NotebookExample.math(
          label: 'Quarter turns',
          notation: 'i² = −1\n(−i)i = 1',
          latexLines: [r'i^{2}=-1', r'(-i)i=1'],
        ),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Complex factors are part of gate action, not decoration. For example, Y exchanges |0⟩ and |1⟩ while attaching ±i factors. A common factor can be global phase; unequal factors between occupied amplitudes change relative phase. Later interference can reveal that relationship.',
      examples: [
        NotebookExample.math(
          label: 'Y on basis states',
          notation: 'Y|0⟩ = i|1⟩\nY|1⟩ = −i|0⟩',
        ),
      ],
    ),
    relatedDiscoveryTitles: [
      'Invisible Difference',
      'Relative Phase',
      'State Transformations',
    ],
  ),
  NotebookEntry(
    id: 'the_third_state',
    discoveryTitle: 'The Third State',
    chapterIndex: 3,
    chapterTitle: 'Chapter 3 - Superposition',
    title: 'The Third State',
    summary:
        'A qubit can be transformed into a state that is not simply |0⟩ or |1⟩.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A qubit is not limited to behaving like a switch that is only left or right. It can be prepared in a state with both possibilities available before measurement. That does not make |+⟩ a third classical value. It means the quantum state has changed while the possible measurement labels are still 0 and 1.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'Before the gate, the qubit was definitely in |0⟩. After the gate, the state had both |0⟩ and |1⟩ parts. The possible measurement labels stayed the same, but the state before measurement changed.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|0⟩'),
        NotebookExample.math(label: 'After', notation: '|+⟩ = (|0⟩ + |1⟩)/√2'),
        NotebookExample(
          label: 'Measurement labels',
          notation: 'Measurement still returns 0 or 1.',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The H gate maps |0⟩ into the balanced state |+⟩. The symbols |0⟩ and |1⟩ are still the basis states that can appear as measurement outcomes. The symbol |+⟩ describes the qubit before measurement.',
      examples: [
        NotebookExample.math(label: 'Hadamard action', notation: 'H|0⟩ = |+⟩'),
        NotebookExample.math(
            label: 'Plus state', notation: '|+⟩ = (|0⟩ + |1⟩)/√2'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'The phrase "third state" is a useful mystery, but it should not be taken literally as a third measurement result. In this chapter, the important distinction is state versus measurement outcome.',
    ),
    relatedDiscoveryTitles: [
      'The Quantum Bit',
      'Two Possibilities',
      'Precise Superposition',
    ],
  ),
  NotebookEntry(
    id: 'two_possibilities',
    discoveryTitle: 'Two Possibilities',
    chapterIndex: 3,
    chapterTitle: 'Chapter 3 - Superposition',
    title: 'Fifty Fifty',
    summary:
        'A superposition can produce multiple measurement outcomes with precise probabilities.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A fair coin toss feels random because you do not control which side appears. A superposition is different. The state before measurement is prepared in a precise way, and measurement samples from the possibilities in that state.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The state before measurement supported two possible outcomes. The measurement still returns one result, but it is no longer guaranteed to be only 0 or only 1.',
      examples: [
        NotebookExample.math(
          label: 'Possible outcomes',
          notation: '|0⟩\n|1⟩',
        ),
        NotebookExample.math(
          label: 'Measurement probabilities',
          notation: 'P(|0⟩) = 50%\nP(|1⟩) = 50%',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'A balanced superposition has equal-sized |0⟩ and |1⟩ parts, so measurement gives equal probabilities. The minus sign in this level is not the main lesson; the key idea is that one quantum state can support more than one possible measurement result.',
      examples: [
        NotebookExample.math(
          label: 'Balanced state',
          notation: '(|0⟩ − |1⟩)/√2',
        ),
        NotebookExample.math(
          label: 'Measurement',
          notation: 'P(|0⟩) = 50%\nP(|1⟩) = 50%',
        ),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Quantum theory separates the state from the measurement outcome. The state can contain several possible outcomes. Measurement returns one of them. Later circuits can transform the state before measurement happens.',
    ),
    relatedDiscoveryTitles: [
      'The Third State',
      'Precise Superposition',
      'Phase Information',
    ],
  ),
  NotebookEntry(
    id: 'precise_superposition',
    discoveryTitle: 'Precise Superposition',
    chapterIndex: 3,
    chapterTitle: 'Chapter 3 - Superposition',
    title: 'Precise, Not Random',
    executableExampleIds: ['ry_rotation'],
    summary:
        'A superposition is controllable and reversible, not random noise.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'If a superposition were just random noise, one gate could not reliably turn it back into a definite state. But |+⟩ can be turned back into |0⟩. That means the state was precise all along.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The qubit moved from a balanced superposition back to a definite basis state. The probabilities changed from uncertain to certain, but the operation itself was controlled.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|+⟩'),
        NotebookExample.math(label: 'After', notation: '|0⟩'),
        NotebookExample.math(
          label: 'Measurement before',
          notation: 'P(|0⟩) = 50%\nP(|1⟩) = 50%',
          comparisonGroup: 'precise-superposition-measurement',
        ),
        NotebookExample.math(
          label: 'Measurement after',
          notation: 'P(|0⟩) = 100%\nP(|1⟩) = 0%',
          comparisonGroup: 'precise-superposition-measurement',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The H gate is reversible. It can create |+⟩ from |0⟩, and it can also turn |+⟩ back into |0⟩. This is why superposition should not be confused with ordinary randomness.',
      examples: [
        NotebookExample.math(
            label: 'Create superposition', notation: 'H|0⟩ = |+⟩'),
        NotebookExample.math(
            label: 'Reverse superposition', notation: 'H|+⟩ = |0⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This is an early example of changing how a state is viewed. The same operation can create a superposition or read it back into a definite basis state. Chapter 4 will build on this without needing to treat superposition as randomness.',
    ),
    relatedDiscoveryTitles: [
      'The Third State',
      'Two Possibilities',
      'Prepared Possibilities',
      'Interference',
    ],
  ),
  NotebookEntry(
    id: 'prepared_possibilities',
    discoveryTitle: 'Prepared Possibilities',
    chapterIndex: 3,
    chapterTitle: 'Chapter 3 - Superposition',
    title: 'Build The Balance',
    summary: 'A circuit can intentionally prepare the superposition it needs.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Superposition is not something that merely happens to a qubit. A circuit can prepare it on purpose. Sometimes the circuit first changes the starting state, then applies the gate that creates the desired balanced state.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The circuit used planning. It first prepared the correct input, then created the balanced state. The final superposition was the result of a sequence, not a lucky observation.',
      examples: [
        NotebookExample.math(label: 'Start', notation: '|1⟩'),
        NotebookExample.math(label: 'Prepare input', notation: 'X|1⟩ = |0⟩'),
        NotebookExample.math(
            label: 'Create superposition', notation: 'H|0⟩ = |+⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The final state depends on the input to H. Preparing the input first lets the circuit create the intended superposition.',
      examples: [
        NotebookExample.math(
          label: 'Planned path',
          notation: '|1⟩ → X → |0⟩ → H → |+⟩',
        ),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Quantum algorithms often begin with state preparation. The goal is to set up a useful starting state before the more interesting part of the algorithm begins. This entry is the beginner version of that idea.',
    ),
    relatedDiscoveryTitles: [
      'Precise Superposition',
      'The Quantum Bit',
      'Superposition',
    ],
  ),
  NotebookEntry(
    id: 'superposition',
    discoveryTitle: 'Superposition',
    chapterIndex: 3,
    chapterTitle: 'Chapter 3 - Superposition',
    title: 'What Is Superposition?',
    executableExampleIds: ['h_superposition'],
    summary:
        'Superposition is a precise, controllable combination of possibilities inside a quantum state.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A register can contain more than one qubit. Superposition does not have to affect every qubit at once. One qubit can be placed into superposition while another qubit remains definite. This makes superposition a precise resource, not a vague blur over the whole system.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The circuit prepared a two-qubit register where one qubit became superposed and the other stayed fixed. The register gained two possible basis states, but not every basis state became possible.',
      examples: [
        NotebookExample.math(label: 'Start', notation: '|10⟩'),
        NotebookExample.math(
            label: 'Prepare register', notation: '|10⟩ → |00⟩'),
        NotebookExample.math(
            label: 'Place superposition', notation: '|00⟩ → |+0⟩'),
        NotebookExample.math(
          label: 'Measurement',
          notation: 'P(|00⟩) = 50%\nP(|01⟩) = 0%\nP(|10⟩) = 50%\nP(|11⟩) = 0%',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The state |+0⟩ means the first qubit is in the plus state while the second qubit remains 0. This is not entanglement. The important idea is that superposition can be placed precisely within a larger register.',
      examples: [
        NotebookExample.math(
          label: 'Two-qubit superposition',
          notation: '|+0⟩ = (|00⟩ + |10⟩)/√2',
        ),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Superposition gives later circuits something to work with. A later chapter will show how operations can change which possibilities become more likely or less likely. For now, the key idea is preparation: the circuit can choose where superposition exists.',
    ),
    relatedDiscoveryTitles: [
      'Prepared Possibilities',
      'Precise Superposition',
      'The Quantum Bit',
      'Interference',
    ],
  ),
  NotebookEntry(
    id: 'phase_is_hidden',
    discoveryTitle: 'Phase Is Hidden',
    chapterIndex: 4,
    chapterTitle: 'Chapter 4 - Interference',
    title: 'Phase Is Hidden',
    summary:
        'Phase can stay invisible to direct measurement, but later operations can make it matter.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'This entry is a bridge. Chapter 2 showed that signs and phase relationships can hide from ordinary measurement. Chapter 4 asks the next question: what kind of circuit can make that hidden difference show up?',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The state changed from |+⟩ to |−⟩. The measurement odds stayed balanced, but the phase relationship is now different and ready to be revealed by another gate.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|+⟩ = (|0⟩ + |1⟩)/√2'),
        NotebookExample.math(label: 'After', notation: '|−⟩ = (|0⟩ − |1⟩)/√2'),
        NotebookExample.math(
          label: 'Measurement',
          notation: 'P(|0⟩) = 50%\nP(|1⟩) = 50%',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Z changes the sign of the |1⟩ part of |+⟩. The result is |−⟩, a state with the same probabilities but a different phase relationship.',
      examples: [
        NotebookExample.math(label: 'Phase change', notation: 'Z|+⟩ = |−⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'The important point is not that phase exists; you already know that. The important point is that Chapter 4 will use later gates to turn phase into changed probabilities. Looking Ahead: interference becomes the tool that makes hidden phase observable.',
    ),
    relatedDiscoveryTitles: [
      'Phase Information',
      'Superposition',
      'Phase Becomes Bit',
    ],
  ),
  NotebookEntry(
    id: 'phase_becomes_bit',
    discoveryTitle: 'Phase Becomes Bit',
    chapterIndex: 4,
    chapterTitle: 'Chapter 4 - Interference',
    title: 'Phase Becomes Bit',
    summary:
        'A hidden phase difference can become a visible bit difference after a basis change.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Imagine writing a note in invisible ink, then shining the right light on it. The phase difference was already in the state, but the final H gate changed the viewing angle so the hidden difference became visible as |1⟩.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The circuit first created a superposition, then changed the phase relationship, then changed basis again. The final result was no longer hidden: the measured bit changed from the |0⟩ target to |1⟩.',
      examples: [
        NotebookExample.math(label: 'Start', notation: '|0⟩'),
        NotebookExample.math(label: 'Create paths', notation: '|0⟩ → H → |+⟩'),
        NotebookExample.math(
            label: 'Reveal phase', notation: '|+⟩ → Z → |−⟩ → H → |1⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The identity HZH = X supports the discovery, but the discovery is the mechanism: H changes basis, Z changes phase, and the final H makes that phase visible as a bit flip.',
      examples: [
        NotebookExample.math(label: 'Gate identity', notation: 'HZH = X'),
        NotebookExample.math(
            label: 'State path',
            notation: 'H|0⟩ = |+⟩\nZ|+⟩ = |−⟩\nH|−⟩ = |1⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'A basis change decides which features of a state are visible to measurement. In this case, the plus/minus phase relationship becomes a normal 0/1 difference. Looking Ahead: quantum algorithms use basis changes to reveal hidden structure.',
    ),
    relatedDiscoveryTitles: [
      'Phase Is Hidden',
      'Bit Becomes Phase',
      'Destructive Interference',
    ],
  ),
  NotebookEntry(
    id: 'bit_becomes_phase',
    discoveryTitle: 'Bit Becomes Phase',
    chapterIndex: 4,
    chapterTitle: 'Chapter 4 - Interference',
    title: 'Bit Becomes Phase',
    summary: 'Changing basis changes what an operation appears to do.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The same move can look different from another angle. X is a bit flip in the |0⟩/|1⟩ view, but when the circuit changes perspective with H gates, that same operation creates a phase change instead.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The circuit used H gates around X. That changed the perspective before and after the operation, so the final effect on the original state was the same as a phase flip.',
      examples: [
        NotebookExample.math(label: 'Start', notation: '|+⟩'),
        NotebookExample.math(label: 'Change basis', notation: '|+⟩ → H → |0⟩'),
        NotebookExample.math(
            label: 'Return with phase', notation: '|0⟩ → X → |1⟩ → H → |−⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The identity HXH = Z is useful because it shows that gate meaning depends on basis. The equation is not just something to memorize; it says that surrounding an operation with a basis change can alter what feature it affects.',
      examples: [
        NotebookExample.math(label: 'Gate identity', notation: 'HXH = Z'),
        NotebookExample.math(
            label: 'State path',
            notation: 'H|+⟩ = |0⟩\nX|0⟩ = |1⟩\nH|1⟩ = |−⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Quantum circuits often move information between different viewpoints. A gate that changes one kind of information in one basis may change another kind in a different basis. Looking Ahead: later circuits will use this perspective shift with multiple qubits.',
    ),
    relatedDiscoveryTitles: [
      'Phase Becomes Bit',
      'Relative Phase',
      'Interference',
    ],
  ),
  NotebookEntry(
    id: 'destructive_interference',
    discoveryTitle: 'Destructive Interference',
    chapterIndex: 4,
    chapterTitle: 'Chapter 4 - Interference',
    title: 'Make Zero Impossible',
    summary:
        'Opposite amplitudes can cancel, making a measurement outcome impossible.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Think of two equal waves meeting out of step: one pushes up while the other pushes down. They do not delete each other from history, but their combined effect at that point is zero. Quantum amplitudes can combine in the same cancelling way.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'Before the final H, the state carried a minus relationship between its two parts. After the final H, the |0⟩ contributions cancelled and the |1⟩ contributions reinforced.',
      examples: [
        NotebookExample.math(
            label: 'Before reveal', notation: '|−⟩ = (|0⟩ − |1⟩)/√2'),
        NotebookExample.math(label: 'After reveal', notation: 'H|−⟩ = |1⟩'),
        NotebookExample.math(
          label: 'Probability change',
          notation:
              'Before H: P(|0⟩) = 50%, P(|1⟩) = 50%\nAfter H: P(|0⟩) = 0%, P(|1⟩) = 100%',
          latexLines: [
            r'\mathrm{Before}\ H:\ P(\lvert0\rangle)=50\%,\ P(\lvert1\rangle)=50\%',
            r'\mathrm{After}\ H:\ P(\lvert0\rangle)=0\%,\ P(\lvert1\rangle)=100\%',
          ],
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Amplitudes add with signs. When two contributions to the same outcome have equal size and opposite sign, the sum is zero. The outcome is not erased; it receives zero final amplitude.',
      examples: [
        NotebookExample.math(label: 'Cancellation', notation: '1/2 − 1/2 = 0'),
        NotebookExample.math(label: 'Reinforcement', notation: '1/2 + 1/2 = 1'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Destructive interference is about how paths combine, not about deleting possibilities by force. The circuit redirects probability by making some amplitudes cancel and others add. Looking Ahead: later algorithms deliberately arrange cancellation around wrong answers.',
    ),
    relatedDiscoveryTitles: [
      'Interference',
      'Prepared Possibilities',
      'Phase Information',
    ],
  ),
  NotebookEntry(
    id: 'interference',
    discoveryTitle: 'Interference',
    chapterIndex: 4,
    chapterTitle: 'Chapter 4 - Interference',
    title: 'What Is Interference?',
    executableExampleIds: ['interference_hzh'],
    summary:
        'Interference converts phase relationships inside a superposition into changed measurement probabilities.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Chapter 2 gave you hidden phase. Chapter 3 gave you controlled superposition. Chapter 4 combines them: prepare possibilities, change their relationship, then let them meet again so the final probabilities change.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The hidden phase did not stay hidden. When the paths recombined, one outcome lost amplitude while another gained it. The measurement probabilities changed because the amplitudes interfered.',
      examples: [
        NotebookExample(
            label: 'Story',
            notation:
                'Hidden phase → Superposition → Interference → Changed probabilities'),
        NotebookExample.math(
            label: 'Destructive result', notation: 'P(|0⟩): 50% → 0%'),
        NotebookExample.math(
            label: 'Constructive result', notation: 'P(|1⟩): 50% → 100%'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Constructive interference means contributions add and make an outcome more likely. Destructive interference means contributions cancel and make an outcome less likely or impossible. Phase controls whether contributions add or cancel.',
      examples: [
        NotebookExample(
            label: 'Constructive', notation: 'same sign → amplitudes add'),
        NotebookExample(
            label: 'Destructive',
            notation: 'opposite signs → amplitudes cancel'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Interference is not separate from phase and superposition; it is what happens when phase relationships inside a superposition are recombined. Looking Ahead: interference becomes one of the main tools used by quantum algorithms.',
    ),
    relatedDiscoveryTitles: [
      'Destructive Interference',
      'Superposition',
      'Phase Information',
      'Prepared Possibilities',
    ],
  ),
  NotebookEntry(
    id: 'two_qubits',
    discoveryTitle: 'Two Qubits',
    chapterIndex: 5,
    chapterTitle: 'Chapter 5 - Entanglement',
    title: 'Two Qubits',
    summary:
        'A two-qubit register describes a pair of qubits as one combined system.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Adding a second qubit is like widening the workspace. The system can now describe two positions at once, such as |00⟩, |01⟩, |10⟩, or |11⟩. That alone is not entanglement; it is the starting point that makes entanglement possible.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The circuit no longer describes only one qubit. It describes a register with two qubits. Each qubit can still be changed independently, and the pair can still be in an ordinary unentangled state.',
      examples: [
        NotebookExample.math(
          label: 'One qubit',
          notation: '|0⟩ or |1⟩',
          latex: r'\lvert0\rangle\ \text{or}\ \lvert1\rangle',
        ),
        NotebookExample.math(label: 'Two-qubit register', notation: '|00⟩'),
        NotebookExample.math(
            label: 'Independent changes', notation: '|00⟩ → |11⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'A two-qubit register uses basis states with two labels. The first label belongs to q0 and the second label belongs to q1. If the qubits are independent, the register can still be understood as one qubit state together with another qubit state.',
      examples: [
        NotebookExample.math(
            label: 'Basis states', notation: '|00⟩, |01⟩, |10⟩, |11⟩'),
        NotebookExample.math(
            label: 'Product example', notation: '|1⟩|1⟩ = |11⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'The word register means a collection of qubits treated as one system. A register can be unentangled, partially connected by operations, or entangled depending on the state. Looking Ahead: larger registers make states like GHZ possible.',
    ),
    relatedDiscoveryTitles: [
      'The Quantum Bit',
      'State Transformations',
      'Correlation',
      'Bell State',
    ],
  ),
  NotebookEntry(
    id: 'correlation',
    discoveryTitle: 'Correlation',
    chapterIndex: 5,
    chapterTitle: 'Chapter 5 - Entanglement',
    title: 'Controlled Change',
    summary:
        'A controlled operation changes one qubit only when another qubit has the right value.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'CNOT acts like a conditional rule: if the control is 1, flip the target; otherwise leave the target alone. This creates a connection between the roles of the two qubits, but it does not automatically create entanglement.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The target qubit changed because the control qubit was |1⟩. The action depended on the joint register state, not on the target alone. The result here is still a definite two-qubit state, so it is controlled behavior without entanglement.',
      examples: [
        NotebookExample.math(label: 'Control off', notation: 'CNOT|00⟩ = |00⟩'),
        NotebookExample.math(label: 'Control on', notation: 'CNOT|10⟩ = |11⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'CNOT has two parts: a control and a target. It copies the control condition into an action on the target when the control is a definite |1⟩. If the control is in superposition, the same gate can connect different branches of the state.',
      examples: [
        NotebookExample.math(label: 'Rule', notation: '|control,target⟩'),
        NotebookExample.math(
            label: 'Conditional flip', notation: '|10⟩ → |11⟩'),
        NotebookExample.math(label: 'No flip', notation: '|00⟩ → |00⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'A CNOT gate can create entanglement, but using CNOT does not automatically create an entangled state. The input state matters. Looking Ahead: future circuits use controlled operations to move information through larger systems.',
    ),
    relatedDiscoveryTitles: [
      'Two Qubits',
      'The Quantum Bit',
      'Prepared Possibilities',
      'Bell State',
    ],
  ),
  NotebookEntry(
    id: 'bell_state',
    discoveryTitle: 'Bell State',
    chapterIndex: 5,
    chapterTitle: 'Chapter 5 - Entanglement',
    title: 'Bell State',
    executableExampleIds: ['bell_phi_plus'],
    summary:
        'A Bell state is a simple example where two qubits behave as one shared quantum state.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Start with a superposition, then use a controlled operation to link the branches. The pair is no longer just q0 doing one thing and q1 doing another. The possibilities belong to the two-qubit system together.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The circuit created two shared possibilities: both qubits are 0 together, or both qubits are 1 together. The individual qubits do not have separate definite values, but the pair has a precise joint state.',
      examples: [
        NotebookExample.math(
            label: 'Prepare possibilities',
            notation: '|00⟩ → H on q0 → (|00⟩ + |10⟩)/√2',
            latex:
                r'\lvert00\rangle\xrightarrow{H\ \mathrm{on}\ q_0}\frac{\lvert00\rangle+\lvert10\rangle}{\sqrt{2}}'),
        NotebookExample.math(
            label: 'Connect branches',
            notation: 'CNOT → (|00⟩ + |11⟩)/√2',
            latex:
                r'\operatorname{CNOT}\rightarrow\frac{\lvert00\rangle+\lvert11\rangle}{\sqrt{2}}'),
        NotebookExample(
            label: 'Measurements', notation: 'Only |00⟩ or |11⟩ can appear'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The Bell state Φ⁺ is a superposition of two two-qubit basis states. It cannot be treated as one independent state for q0 and a separate independent state for q1.',
      examples: [
        NotebookExample.math(
            label: 'Bell state', notation: '|Φ⁺⟩ = (|00⟩ + |11⟩)/√2'),
        NotebookExample(
            label: 'Not independent', notation: 'not q0 state × q1 state'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'A preparation circuit is decoded by applying its inverse operations in reverse order. A local Z on either qubit changes the sign of the Bell branch containing |1⟩ on that wire, turning Φ⁺ into Φ⁻. The sign belongs to the shared state even though one local gate wrote it.',
      examples: [
        NotebookExample(
          label: 'Decode preparation',
          notation: 'prepare: H then CNOT\ndecode: CNOT then H',
        ),
        NotebookExample.math(
          label: 'Shared relative phase',
          notation: 'Φ⁺ = (|00⟩ + |11⟩)/√2\nΦ⁻ = (|00⟩ − |11⟩)/√2',
        ),
      ],
    ),
    relatedDiscoveryTitles: [
      'Correlation',
      'Superposition',
      'Prepared Possibilities',
      'One Quantum System',
      'Entanglement',
    ],
  ),
  NotebookEntry(
    id: 'one_quantum_system',
    discoveryTitle: 'One Quantum System',
    chapterIndex: 5,
    chapterTitle: 'Chapter 5 - Entanglement',
    title: 'One Quantum System',
    summary:
        'Entangled qubits can belong to one shared state instead of two separate qubit states.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Ordinary correlation is like two cards that happen to match. Entanglement is different: before measurement, the pair is described by one shared quantum state. The useful description belongs to the whole system.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The pair gained a relationship that cannot be explained by assigning a complete independent state to each qubit. Measurement outcomes are correlated, but the deeper point is that the state itself is shared.',
      examples: [
        NotebookExample(
            label: 'Ordinary pair',
            notation: '|10⟩ describes definite q0 and q1 values'),
        NotebookExample(
            label: 'Shared state',
            notation: '(|01⟩ + |10⟩)/√2 belongs to the pair'),
        NotebookExample(
            label: 'Prediction',
            notation: 'If one result is 0, the other is 1'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Some two-qubit states can be factored into separate one-qubit states. Entangled states cannot. That is what makes them more than ordinary correlation.',
      examples: [
        NotebookExample.math(
            label: 'Separable example', notation: '|+0⟩ = |+⟩|0⟩'),
        NotebookExample.math(
            label: 'Entangled example', notation: '(|01⟩ + |10⟩)/√2'),
        NotebookExample(
            label: 'Key distinction',
            notation: 'shared state, not separate states'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Correlation describes patterns in outcomes. Entanglement describes a structure of the quantum state before outcomes are produced. Looking Ahead: this whole-system view becomes more important in multi-qubit algorithms.',
    ),
    relatedDiscoveryTitles: [
      'Bell State',
      'Two Qubits',
      'Interference',
      'Entanglement',
    ],
  ),
  NotebookEntry(
    id: 'entanglement',
    discoveryTitle: 'Entanglement',
    chapterIndex: 5,
    chapterTitle: 'Chapter 5 - Entanglement',
    title: 'What Is Entanglement?',
    summary:
        'Entanglement is a property of the whole quantum system that cannot always be split into separate qubit descriptions.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'If two ordinary objects are correlated, you can still describe each object separately. Entangled qubits are different: the clean description belongs to the pair. Measuring one qubit changes what you can predict about the other because the state was shared.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The final state is not just two qubits sitting next to each other, and it is not merely a CNOT circuit. It is a state of the two-qubit system as a whole. The individual measurement labels are still 0 and 1, but the state cannot be broken into independent pieces.',
      examples: [
        NotebookExample.math(
            label: 'Entangled state', notation: '|Φ−⟩ = (|00⟩ − |11⟩)/√2'),
        NotebookExample.math(
            label: 'Possible outcomes', notation: '|00⟩ or |11⟩'),
        NotebookExample(
            label: 'Impossible outcomes',
            notation: '|01⟩ and |10⟩ have zero probability'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'A two-qubit state is entangled when it cannot be written as a product of one state for q0 and one state for q1. Bell states are the simplest examples, but entanglement is the broader idea.',
      examples: [
        NotebookExample(
            label: 'Separate form', notation: '(q0 state) × (q1 state)'),
        NotebookExample.math(
            label: 'Bell example', notation: '(|00⟩ − |11⟩)/√2'),
        NotebookExample(
            label: 'Misconception check',
            notation: 'Bell states are examples, not the definition'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Entanglement depends on the state, not just on the gate list. A CNOT can create entanglement from the right input, but it can also act on definite states without entangling them. Looking Ahead: entanglement will later support teleportation, GHZ states, and quantum algorithms.',
    ),
    relatedDiscoveryTitles: [
      'One Quantum System',
      'Bell State',
      'Superposition',
      'Interference',
      'Prepared Possibilities',
    ],
  ),
  NotebookEntry(
    id: 'control',
    discoveryTitle: 'Control',
    chapterIndex: 6,
    chapterTitle: 'Chapter 6 - Information Flow',
    title: 'The Control Qubit',
    summary:
        'One qubit can conditionally influence another qubit through a controlled operation.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A controlled gate is like a rule with a condition. The target qubit changes only when the control qubit carries the active value. The action is still one circuit step, but it depends on information stored on another wire.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The target changed because the control was active. The circuit did not flip a qubit in isolation; it used information on one qubit to decide what happened to another.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|01⟩'),
        NotebookExample.math(label: 'After CX', notation: '|11⟩'),
        NotebookExample(
            label: 'Condition', notation: 'active control -> target flips'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'CX is a two-qubit gate. One qubit is the control and the other is the target. When the control is active, the target receives an X action. When the control is inactive, the target is left alone.',
      examples: [
        NotebookExample.math(
            label: 'Control active', notation: 'CX|01⟩ = |11⟩'),
        NotebookExample.math(
            label: 'Control inactive', notation: 'CX|00⟩ = |00⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Control is the first step toward information flow. A controlled operation lets one part of a register influence another without treating the two wires as separate puzzles. Looking Ahead: the next discoveries use this conditional action to transfer and route information.',
    ),
    relatedDiscoveryTitles: [
      'Two Qubits',
      'Correlation',
      'Conditional Action',
      'Information Transfer',
    ],
  ),
  NotebookEntry(
    id: 'conditional_action',
    discoveryTitle: 'Conditional Action',
    chapterIndex: 6,
    chapterTitle: 'Chapter 6 - Information Flow',
    title: 'Conditional Action',
    summary:
        'The same CX gate can visibly change or not change the register depending on the control qubit.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A conditional rule can be checked even when it does not fire. CX on an inactive control is like asking a question and getting "no": the target stays put, but the circuit still applied a meaningful rule.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The visible state stayed |00⟩ because the control was inactive. What changed is the explanation: the target did not stay fixed by accident; it stayed fixed because the condition was not met.',
      examples: [
        NotebookExample.math(label: 'Before', notation: '|00⟩'),
        NotebookExample.math(label: 'After CX', notation: '|00⟩'),
        NotebookExample(
            label: 'Reason', notation: 'control = 0, so target does not flip'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'A controlled gate is defined by its full behavior, not just by one visible input. On some inputs CX changes the register. On others it leaves the displayed state unchanged because the control condition is false.',
      examples: [
        NotebookExample.math(label: 'No flip', notation: 'CX|00⟩ = |00⟩'),
        NotebookExample.math(label: 'Flip', notation: 'CX|01⟩ = |11⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This repeats a lesson from hidden change in a two-qubit setting: unchanged output does not always mean unused operation. The full circuit behavior explains why the output stayed fixed. Looking Ahead: useful circuits combine these conditional actions to move information across a register.',
    ),
    relatedDiscoveryTitles: [
      'Hidden Change',
      'Control',
      'Information Transfer',
      'State Transformations',
    ],
  ),
  NotebookEntry(
    id: 'information_transfer',
    discoveryTitle: 'Information Transfer',
    chapterIndex: 6,
    chapterTitle: 'Chapter 6 - Information Flow',
    title: 'Information Transfer',
    summary:
        'A circuit can create information on one qubit and propagate it to another with CX.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'First make one qubit active. Then use that qubit as the control for CX. The second qubit changes because the first qubit now carries the information that triggers the controlled action.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The circuit did two different jobs. X created an active qubit. CX then used that active qubit to change the other qubit, spreading the information through the two-qubit register.',
      examples: [
        NotebookExample.math(label: 'Create', notation: '|00⟩ -> X -> |10⟩'),
        NotebookExample.math(
            label: 'Propagate', notation: '|10⟩ -> CX -> |11⟩'),
        NotebookExample.math(label: 'Result', notation: '|00⟩ -> |11⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Information transfer here means conditional propagation through a register. CX does not copy an arbitrary quantum state; in this beginner basis-state setting, it lets the active control determine whether the target flips.',
      examples: [
        NotebookExample(label: 'Gate sequence', notation: 'X then CX'),
        NotebookExample(
            label: 'Conditional transfer',
            notation: 'control active -> target becomes active'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'The order matters: create the active control first, then use CX to propagate it. This is the simplest form of information flow in the chapter. Looking Ahead: routing uses controlled actions in both directions, not just one transfer step.',
    ),
    relatedDiscoveryTitles: [
      'Information',
      'Control',
      'Conditional Action',
      'Swap',
    ],
  ),
  NotebookEntry(
    id: 'swap',
    discoveryTitle: 'Swap',
    chapterIndex: 6,
    chapterTitle: 'Chapter 6 - Information Flow',
    title: 'Swap Places',
    summary:
        'A three-CX pattern builds a reusable SWAP operation that exchanges both qubits in the register.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Swapping is more than making one example come out correctly. A true SWAP is a reusable route: whatever information starts on the first qubit ends on the second, and whatever starts on the second ends on the first.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The goal changed from matching a single visible input to building a full-register operation. Two CX gates may solve one displayed case, but the three-CX construction is what exchanges the qubits for every input.',
      examples: [
        NotebookExample.math(label: 'Example input', notation: '|10⟩ -> |01⟩'),
        NotebookExample.math(
            label: 'Other direction', notation: '|01⟩ -> |10⟩'),
        NotebookExample(label: 'SWAP pattern', notation: 'CX -> CX back -> CX'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The SWAP gate is a full-register operation. It leaves |00⟩ and |11⟩ unchanged, and exchanges |01⟩ with |10⟩. That behavior over all basis inputs is what makes it a SWAP, not just one final state.',
      examples: [
        NotebookExample.math(
            label: 'No change', notation: '|00⟩ -> |00⟩\n|11⟩ -> |11⟩'),
        NotebookExample.math(
            label: 'Exchange', notation: '|01⟩ -> |10⟩\n|10⟩ -> |01⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'A circuit can work for one input without being the intended reusable operation. Checking full circuit behavior matters when the lesson is a gate construction. Looking Ahead: the same routing pattern can be combined with information creation to show flow in either direction.',
    ),
    relatedDiscoveryTitles: [
      'Information Transfer',
      'Conditional Action',
      'State Transformations',
      'Information Flow',
    ],
  ),
  NotebookEntry(
    id: 'information_flow',
    discoveryTitle: 'Information Flow',
    chapterIndex: 6,
    chapterTitle: 'Chapter 6 - Information Flow',
    title: 'Information Flow',
    summary:
        'Quantum circuits can create information and route it through interactions between qubits.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Start by creating information on one qubit with X. Then use the three-CX routing pattern to move that information across the register. The important idea is the flow, not a required left-to-right direction.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The circuit combined creation and routing. X made one qubit active, and the controlled routing pattern moved that activity to the other qubit. Mirroring the direction still demonstrates the same information-flow idea.',
      examples: [
        NotebookExample(
            label: 'One direction', notation: 'X(Q0), then route Q0 -> Q1'),
        NotebookExample(
            label: 'Mirrored direction',
            notation: 'X(Q1), then route Q1 -> Q0'),
        NotebookExample(
            label: 'Shared concept', notation: 'create, then route'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Routing can have direction in a specific circuit, but the lesson here is symmetric: either mirrored construction creates information on one qubit and routes it to the other using the same three-CX idea.',
      examples: [
        NotebookExample(
            label: 'Original route',
            notation: 'X(Q0) -> CX(Q0->Q1) -> CX(Q1->Q0) -> CX(Q0->Q1)'),
        NotebookExample(
            label: 'Mirrored route',
            notation: 'X(Q1) -> CX(Q1->Q0) -> CX(Q0->Q1) -> CX(Q1->Q0)'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Some lessons require a specific direction, but this one is about the general pattern of information routing. Direction matters only when the level says which qubit must receive information first or where it must end. Looking Ahead: larger systems use the same ideas to coordinate information across more than two qubits.',
    ),
    relatedDiscoveryTitles: [
      'Information Transfer',
      'Swap',
      'Control',
      'Entanglement',
      'Three Qubits',
    ],
  ),
  NotebookEntry(
    id: 'three_qubits',
    discoveryTitle: 'Three Qubits',
    chapterIndex: 7,
    chapterTitle: 'Chapter 7 - GHZ States',
    title: 'Three Qubits',
    summary:
        'A three-qubit register is described by complete outcomes such as |000⟩ and |111⟩.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'With three qubits, the state label is no longer just a pair. A result like |111⟩ is one full-register outcome. Chapter 7 starts by treating the complete register as the object being described.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The register now has three positions, so the possible outcomes are full patterns such as |000⟩, |001⟩, and |111⟩. The important habit is to read the entire pattern at once.',
      examples: [
        NotebookExample.math(label: 'Start', notation: '|000⟩'),
        NotebookExample.math(label: 'Prepared outcome', notation: '|111⟩'),
        NotebookExample(
            label: 'Mental unit', notation: 'one full three-qubit register'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'A three-qubit register has eight basis outcomes. GHZ will later restrict which of those full-register outcomes can appear, so this first step makes the register-level viewpoint explicit.',
      examples: [
        NotebookExample.math(
            label: 'Examples', notation: '|000⟩\n|010⟩\n|111⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This entry is not yet the GHZ state. It prepares the vocabulary for GHZ by making the complete register the object of attention. Looking Ahead: the next entries narrow the allowed full-register outcomes until the state becomes a global constraint.',
    ),
    relatedDiscoveryTitles: [
      'State Transformations',
      'Two Qubits',
      'Shared Information',
    ],
  ),
  NotebookEntry(
    id: 'shared_information',
    discoveryTitle: 'Shared Information',
    chapterIndex: 7,
    chapterTitle: 'Chapter 7 - GHZ States',
    title: 'Shared Information',
    summary:
        'A three-qubit register can be prepared so one observed part agrees with the whole outcome.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'If the register is definitely |111⟩, then checking any one qubit is enough to know the rest in this case. The lesson is that the full outcome can constrain every part together.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The final state is a globally consistent pattern. Every position agrees with the same full-register outcome, so the register is read as one coordinated object.',
      examples: [
        NotebookExample.math(label: 'Full outcome', notation: '|111⟩'),
        NotebookExample(
            label: 'Consistency', notation: 'measuring one 1 matches all 1s'),
        NotebookExample(
            label: 'Whole-register view',
            notation: 'the complete pattern is fixed'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'This is still a definite basis state, not a GHZ superposition. Its purpose is to establish three-qubit correlation language before the allowed vs forbidden global outcomes become a state-space restriction interpretation.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'A full-register outcome can make every local measurement consistent without yet being entangled. Looking Ahead: GHZ keeps local uncertainty but preserves global consistency.',
    ),
    relatedDiscoveryTitles: [
      'Three Qubits',
      'Correlation',
      'All Together',
    ],
  ),
  NotebookEntry(
    id: 'all_together',
    discoveryTitle: 'All Together',
    chapterIndex: 7,
    chapterTitle: 'Chapter 7 - GHZ States',
    title: 'All Together',
    summary:
        'A GHZ-like state allows only globally consistent outcomes while each qubit can remain locally uncertain.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The register can be uncertain without becoming unstructured. In (|000⟩ + |111⟩)/√2, the individual result is not known ahead of time, but the whole register is constrained: all three outcomes must agree.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The state now has two allowed full-register outcomes. |000⟩ and |111⟩ have non-zero amplitude; mixed outcomes such as |001⟩, |010⟩, and |101⟩ are forbidden global outcomes.',
      examples: [
        NotebookExample.math(label: 'Allowed', notation: '|000⟩\n|111⟩'),
        NotebookExample.math(
            label: 'Forbidden', notation: '|001⟩\n|010⟩\n|101⟩'),
        NotebookExample(
            label: 'Measurement rule',
            notation: 'local uncertainty, global consistency'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'This is the state space restriction interpretation: the three-qubit state occupies only the part of the full basis where all qubits agree. The full register has eight basis outcomes, but only two have non-zero amplitude.',
      examples: [
        NotebookExample.math(
            label: 'GHZ-like state', notation: '(|000⟩ + |111⟩)/√2'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'The important structure is not a pair relationship. The state restricts the complete register. Looking Ahead: the next discovery makes explicit why pairwise explanations miss this whole-system structure.',
    ),
    relatedDiscoveryTitles: [
      'Shared Information',
      'Entanglement',
      'GHZ State',
    ],
  ),
  NotebookEntry(
    id: 'ghz_state',
    discoveryTitle: 'GHZ State',
    chapterIndex: 7,
    chapterTitle: 'Chapter 7 - GHZ States',
    title: 'Beyond Bell States',
    summary:
        'A GHZ state is a whole-register structure that cannot be described as separate entangled pairs.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Pair thinking is too small for GHZ. The state is not Q0 paired with Q1 plus Q1 paired with Q2. The correct object is the entire three-qubit register and the global rule over its outcomes.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The explanation changed. Bell-state intuition says a pair can be one system. GHZ says the full register is the system, and pair-only descriptions do not capture the allowed vs forbidden global outcomes.',
      examples: [
        NotebookExample(
            label: 'Not enough', notation: 'pair descriptions alone'),
        NotebookExample(
            label: 'Correct unit', notation: 'the full three-qubit register'),
        NotebookExample(label: 'Allowed', notation: '|000⟩ and |111⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'GHZ is multi-qubit entanglement with collective structure. The non-zero amplitudes belong to complete register outcomes. That whole-system amplitude pattern is not the same as a collection of Bell pairs.',
      examples: [
        NotebookExample(
            label: 'GHZ pattern', notation: 'non-zero: |000⟩, |111⟩'),
        NotebookExample(
            label: 'Forbidden pattern',
            notation: 'zero amplitude: every mixed outcome'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'GHZ can keep the same allowed outcomes while changing the relative phase between its two global branches. A local Z on any one qubit multiplies the |111⟩ branch by −1 and leaves |000⟩ unchanged. The operation is local, but the changed phase relationship belongs to the whole register.',
      examples: [
        NotebookExample.math(
          label: 'Global branch phase',
          notation: '(|000⟩ + |111⟩)/√2 → Z on one wire → (|000⟩ − |111⟩)/√2',
          latexLines: [
            r'\frac{\lvert000\rangle+\lvert111\rangle}{\sqrt{2}}',
            r'\xrightarrow{Z\ \mathrm{on\ one\ wire}}',
            r'\frac{\lvert000\rangle-\lvert111\rangle}{\sqrt{2}}',
          ],
          mathRole: NotebookMathRole.emphasis,
        ),
      ],
    ),
    relatedDiscoveryTitles: [
      'All Together',
      'One Quantum System',
      'One System, Three Qubits',
    ],
  ),
  NotebookEntry(
    id: 'one_system_three_qubits',
    discoveryTitle: 'One System, Three Qubits',
    chapterIndex: 7,
    chapterTitle: 'Chapter 7 - GHZ States',
    title: 'One System, Three Qubits',
    summary:
        'GHZ is a global constraint system over the full register: only selected complete outcomes have non-zero amplitude.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Think of GHZ as a rule over the whole register. The rule does not describe one qubit, and it does not describe a pair. It says which full outcomes are allowed and which full outcomes are forbidden.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The complete register is now the mental unit. |000⟩ and |111⟩ are allowed global outcomes. The six mixed outcomes are forbidden global outcomes because their amplitudes are zero.',
      examples: [
        NotebookExample.math(label: 'Allowed', notation: '|000⟩\n|111⟩'),
        NotebookExample.math(
            label: 'Forbidden',
            notation: '|001⟩\n|010⟩\n|011⟩\n|100⟩\n|101⟩\n|110⟩'),
        NotebookExample(
            label: 'Core idea',
            notation: 'global constraint over the register'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'In a GHZ-style state, the amplitude pattern is a restriction on the full state space. The system is not explained by individual qubits or pair links; it is explained by the complete register state.',
      examples: [
        NotebookExample(
            label: 'State space restriction interpretation',
            notation: '8 possible basis outcomes -> 2 allowed outcomes'),
        NotebookExample.math(
            label: 'GHZ-style state', notation: '(|000⟩ - |111⟩)/√2'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'The minus sign changes the state, but the Chapter 7 lesson is the global constraint: only |000⟩ and |111⟩ have non-zero amplitude. Looking Ahead: later chapters can use whole-register constraints as resources for larger quantum procedures.',
    ),
    relatedDiscoveryTitles: [
      'GHZ State',
      'All Together',
      'Entanglement',
      'Phase Information',
    ],
  ),
  NotebookEntry(
    id: 'phase_kickback_hidden_mark',
    discoveryTitle: 'Hidden Information',
    chapterIndex: 8,
    chapterTitle: 'Chapter 8 - Phase Kickback',
    title: 'Hidden Mark',
    summary:
        'A controlled operation can mark a quantum state without changing what measurement probabilities immediately show.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The circuit appears to leave the visible bit pattern alone, but the state has still been changed. Chapter 8 uses this as the starting point: useful quantum information can be written into phase before it becomes visible.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The visible measurement outcomes did not change, but the internal phase description did. This is not measurement and not entanglement as the goal; it is a hidden mark created by a controlled operation.',
      examples: [
        NotebookExample(
            label: 'Visible result', notation: 'same probability bars'),
        NotebookExample(label: 'Hidden result', notation: 'phase changed'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Phase kickback begins with the idea that a controlled gate can alter phase while leaving the computational-basis readout unchanged. The change is real even when direct measurement does not reveal it yet.',
      examples: [
        NotebookExample(label: 'Before', notation: 'no phase mark'),
        NotebookExample(
            label: 'After', notation: 'phase mark stored invisibly'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This differs from Chapter 4: interference reveals phase, while Chapter 8 focuses on how controlled operations create phase marks that can be decoded later.',
    ),
    relatedDiscoveryTitles: [
      'Hidden Change',
      'Phase Is Hidden',
      'Phase Carrier',
    ],
  ),
  NotebookEntry(
    id: 'phase_on_the_control',
    discoveryTitle: 'Phase Carrier',
    chapterIndex: 8,
    chapterTitle: 'Chapter 8 - Phase Kickback',
    title: 'Phase On The Control',
    summary:
        'Phase kickback happens when a controlled operation gives different control branches a relative phase because of how the target is prepared.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The target qubit may look like the place where the gate acts, but its eigenvalue can become a phase factor on a control branch. '
          'If the control is fixed at |1⟩, that factor multiplies the whole state and is only global phase. '
          'If the control is in superposition, the |1⟩ branch receives the factor relative to the |0⟩ branch, so the control carries useful information.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The fixed-control example first exposes the target eigenvalue without creating a new physical state. '
          'The superposed-control example turns the same factor into a relative phase on the control, rather than a visible flip of the target.',
      examples: [
        NotebookExample(label: 'Gate shape', notation: 'control -> target'),
        NotebookExample(
            label: 'Kickback result', notation: 'phase stored on control'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'For a target |−⟩, X|−⟩ = −|−⟩. Controlled-X therefore multiplies the control-|1⟩ branch by −1. '
          'A common factor on the only occupied branch is global phase; a factor that differs between occupied control branches is relative phase and can be decoded later.',
      examples: [
        NotebookExample(
            label: 'Visual cue', notation: 'phase highlight on control wire'),
        NotebookExample(
            label: 'Not the goal', notation: 'creating entanglement'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Entanglement can appear in some controlled-gate circuits, but it is not the Chapter 8 objective. The objective is phase encoding on the control.',
    ),
    relatedDiscoveryTitles: [
      'Control',
      'Conditional Action',
      'Phase Kickback',
    ],
  ),
  NotebookEntry(
    id: 'the_kickback_effect',
    discoveryTitle: 'Phase Kickback',
    chapterIndex: 8,
    chapterTitle: 'Chapter 8 - Phase Kickback',
    title: 'The Kickback Effect',
    summary:
        'Phase kickback means information from a controlled operation is stored as phase on the control qubit.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The surprising part is that the qubit that is not directly targeted can carry the important change. The controlled operation pushes the information backward into phase on the control.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'Phase is now treated as stored information. The visible bit value may stay the same, but the control qubit has been marked in a way later circuit steps can use.',
      examples: [
        NotebookExample(
            label: 'Kickback indicator', notation: 'gate -> control phase'),
        NotebookExample(
            label: 'Stored information', notation: 'phase on control'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The controlled operation applies a conditional effect whose eigenvalue becomes a phase on the control branch. That phase is the computational record of the condition.',
      examples: [
        NotebookExample(
            label: 'Core mechanism',
            notation: 'controlled operation writes phase'),
        NotebookExample(
            label: 'Not routing', notation: 'no SWAP or message passing'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This is not GHZ-style global constraint logic. Chapter 8 is local phase encoding into a control qubit, not a full-register allowed-outcome rule.',
    ),
    relatedDiscoveryTitles: [
      'Phase Carrier',
      'Phase Is Hidden',
      'Hidden Communication',
    ],
  ),
  NotebookEntry(
    id: 'setup_matters',
    discoveryTitle: 'Hidden Communication',
    chapterIndex: 8,
    chapterTitle: 'Chapter 8 - Phase Kickback',
    title: 'Setup Matters',
    summary:
        'Phase kickback depends on target preparation; the same controlled gate can behave differently with a different target state.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The gate alone is not the whole story. A controlled operation writes phase only when the target has been prepared so the conditional action can return a phase mark to the control.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The same visible circuit shape can produce different hidden effects depending on the target state. Setup determines whether there is kickback to store.',
      examples: [
        NotebookExample(label: 'Same gate', notation: 'CX'),
        NotebookExample(
            label: 'Different setup', notation: 'different target state'),
        NotebookExample(
            label: 'Different result', notation: 'phase or no phase'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Kickback relies on the target being in a phase-sensitive state for the controlled action. Without that preparation, the operation may behave like an ordinary controlled bit action instead of encoding phase.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This boundary case prevents the misconception that every controlled gate automatically creates useful kickback. The preparation and the controlled operation work together.',
    ),
    relatedDiscoveryTitles: [
      'Prepared Possibilities',
      'Phase Kickback',
      'The Language of Quantum Algorithms',
    ],
  ),
  NotebookEntry(
    id: 'compute_encode_reveal',
    discoveryTitle: 'The Language of Quantum Algorithms',
    chapterIndex: 8,
    chapterTitle: 'Chapter 8 - Phase Kickback',
    title: 'Compute → Encode → Reveal',
    summary:
        'A quantum circuit can compute a condition, encode the result into phase, and later reveal that phase using interference.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Chapter 8 ends by separating the jobs. The controlled operation writes the phase mark. Interference is used afterward as a decoding step so the hidden mark can affect visible outcomes.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'Interference is no longer the main discovery; it is downstream of computation. The new idea is that controlled operations can write computational information into phase first.',
      examples: [
        NotebookExample(label: 'Step 1', notation: 'compute condition'),
        NotebookExample(label: 'Step 2', notation: 'encode into phase'),
        NotebookExample(label: 'Step 3', notation: 'reveal with interference'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Phase kickback is a way for a circuit to store a logical result as a relative phase on a control state. Later basis changes can convert that phase difference into a measurement difference.',
      examples: [
        NotebookExample(label: 'Written by', notation: 'controlled operation'),
        NotebookExample(label: 'Revealed by', notation: 'interference step'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'A reversible oracle can compute a temporary condition, use it to write a phase mark, then apply the inverse computation. The phase effect remains on the candidate branch while temporary workspace returns to its starting state. This compute → mark → uncompute pattern prevents leftover workspace from carrying unwanted correlations.',
      examples: [
        NotebookExample(
          label: 'Clean phase marking',
          notation: 'compute → phase mark → uncompute',
        ),
      ],
    ),
    relatedDiscoveryTitles: [
      'Interference',
      'Phase Kickback',
      'Oracle',
    ],
  ),
  NotebookEntry(
    id: 'oracle_intuition',
    discoveryTitle: 'A Special State',
    chapterIndex: 9,
    chapterTitle: 'Chapter 9 - Oracle Thinking',
    title: 'Oracle Intuition',
    summary:
        'An oracle is a black-box function that classifies inputs as valid or invalid without directly revealing the answer.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Think of an oracle as a sealed rule checker. You provide possible inputs, and the rule separates accepted inputs from rejected inputs without opening the box.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The focus moved from individual operations to the function being queried. The important question is now: which inputs does f(x) accept?',
      examples: [
        NotebookExample.math(label: 'Accepted', notation: 'f(x) = 1'),
        NotebookExample.math(label: 'Rejected', notation: 'f(x) = 0'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The oracle is modeled by its input-output rule. It classifies candidates while keeping the answer encoded inside the query result rather than displaying it directly.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This chapter treats the oracle as an abstraction. Internal implementation details are deliberately hidden so the learner reasons about function access.',
    ),
    relatedDiscoveryTitles: [
      'Prepared Possibilities',
      'The Language of Quantum Algorithms',
      'Oracle',
    ],
  ),
  NotebookEntry(
    id: 'simple_marking_rule',
    discoveryTitle: 'Hidden Mark',
    chapterIndex: 9,
    chapterTitle: 'Chapter 9 - Oracle Thinking',
    title: 'Simple Marking Rule',
    summary:
        'A simple oracle rule marks accepted inputs and leaves rejected inputs unmarked.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The rule behaves like a yes-or-no classifier. It does not explain itself and it does not list the answer; it only classifies the input according to f(x).',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'Marked and unmarked are now abstract rule outputs. They mean accepted and rejected, not a visible answer display.',
      examples: [
        NotebookExample(label: 'Rule output', notation: 'marked = valid'),
        NotebookExample(label: 'Rule output', notation: 'unmarked = invalid'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The oracle query applies one consistent classification rule across the candidate space. The learner tracks the rule table, not the internal machinery.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This is different from mechanism-level reasoning. Chapter 9 asks what function is encoded, not how the mark is physically produced.',
    ),
    relatedDiscoveryTitles: [
      'A Special State',
      'Oracle',
      'Invisible Mark',
    ],
  ),
  NotebookEntry(
    id: 'hidden_structure_effect',
    discoveryTitle: 'Oracle',
    chapterIndex: 9,
    chapterTitle: 'Chapter 9 - Oracle Thinking',
    title: 'Hidden Structure Effect',
    summary:
        'An oracle can encode useful structure as a hidden rule before the answer becomes directly available.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The oracle has organized the candidates into valid and invalid classes. That structure matters even when it is not yet a directly readable answer.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The useful object is the hidden function table. The query tells the algorithm which class each candidate belongs to without becoming a final answer step.',
      examples: [
        NotebookExample.math(label: 'Hidden rule', notation: 'f(10) = 1'),
        NotebookExample.math(label: 'Other candidates', notation: 'f(x) = 0'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Oracle access means structured access to f(x). The circuit is treated as a black box that evaluates the rule consistently for the candidate space.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'The abstraction is intentionally higher than Chapter 8. The oracle is the hidden function being queried, not the mechanism that produces a mark.',
    ),
    relatedDiscoveryTitles: [
      'Hidden Mark',
      'The Language of Quantum Algorithms',
      'Phase Marking',
    ],
  ),
  NotebookEntry(
    id: 'why_classical_fails',
    discoveryTitle: 'Invisible Mark',
    chapterIndex: 9,
    chapterTitle: 'Chapter 9 - Oracle Thinking',
    title: 'Why Classical Fails',
    summary:
        'Oracle access is not the same as checking each possible answer manually.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Classical brute force asks one candidate at a time. Oracle thinking asks how an algorithm can use a hidden rule as a reusable query.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The mental model changed from answer inspection to rule access. The oracle gives structured access to f(x), but it still does not hand over the final answer.',
      examples: [
        NotebookExample(label: 'Brute force', notation: 'try x, then try y'),
        NotebookExample(label: 'Oracle model', notation: 'query f(x)'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The oracle is a query primitive. It defines how candidates are classified while leaving later algorithmic steps responsible for extracting a useful result.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This is the central abstraction shift of Chapter 9: the algorithm is given access to a rule, not direct access to the answer.',
    ),
    relatedDiscoveryTitles: [
      'Oracle',
      'Superposition',
      'A Special State',
    ],
  ),
  NotebookEntry(
    id: 'oracle_as_computation_primitive',
    discoveryTitle: 'Phase Marking',
    chapterIndex: 9,
    chapterTitle: 'Chapter 9 - Oracle Thinking',
    title: 'Oracle as Computation Primitive',
    summary:
        'An oracle is a reusable computation primitive that represents the hidden rule of a problem.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The oracle is not the whole algorithm. It is the problem-specific black box that says which candidates satisfy the rule.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The learner now treats the oracle as a module: define f(x), query it, then let later algorithm steps use that structured result.',
      examples: [
        NotebookExample(label: 'Oracle role', notation: 'problem rule'),
        NotebookExample(label: 'Algorithm role', notation: 'use rule output'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The oracle abstracts the problem into a queryable function. It classifies valid and invalid candidates while preserving the separation between rule evaluation and answer extraction.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Chapter 10 can build on this primitive, but Chapter 9 ends at the abstraction boundary: oracle means hidden function access.',
    ),
    relatedDiscoveryTitles: [
      'Invisible Mark',
      'Oracle',
      'Amplitude Amplification',
    ],
  ),
  NotebookEntry(
    id: 'why_marking_is_not_enough',
    discoveryTitle: 'Marked But Hidden',
    chapterIndex: 10,
    chapterTitle: 'Chapter 10 - Amplitude Amplification',
    title: 'Why Marking Is Not Enough',
    summary:
        'Knowing which state is valid does not automatically make that state more likely to appear.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A valid answer can still be buried in an even distribution. If every candidate has the same chance, measurement is still just a low-odds sample.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The chapter focus moves from identifying validity to changing likelihood. The useful question becomes: did the valid state become more probable?',
      examples: [
        NotebookExample(label: 'Before', notation: 'all candidates equal'),
        NotebookExample(label: 'Goal', notation: 'valid candidate favored'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Amplitude amplification is viewed here as probability redistribution. It starts from a known valid state and asks whether the distribution now favors that state.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This is not just finding the answer. Finding names the valid state; amplification changes how likely that state is to be observed.',
    ),
    relatedDiscoveryTitles: [
      'Prepared Possibilities',
      'A Special State',
      'Mark Becomes Probability',
    ],
  ),
  NotebookEntry(
    id: 'first_bias_toward_solution',
    discoveryTitle: 'Mark Becomes Probability',
    chapterIndex: 10,
    chapterTitle: 'Chapter 10 - Amplitude Amplification',
    title: 'First Sign of Bias',
    summary:
        'Before amplification, learners first see that a balanced probability distribution can become uneven.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Think of the distribution as attention. A balanced distribution gives every answer equal attention; the first sign of bias is simply that some outcomes now receive more attention than others.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The learner now tracks probability before and after the step. The important change is not a final answer, but the first uneven distribution.',
      examples: [
        NotebookExample(label: 'Balanced', notation: 'equal likelihood'),
        NotebookExample(label: 'Biased', notation: 'valid state higher'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The distribution is reshaped so probability is no longer spread equally across every candidate. Chapter 10 keeps attention on that visible probability change.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'The internal construction is not the learner-facing model here. The abstraction is likelihood moving toward the valid candidate.',
    ),
    relatedDiscoveryTitles: [
      'Marked But Hidden',
      'Amplitude Amplification',
      'Prepared Possibilities',
    ],
  ),
  NotebookEntry(
    id: 'reinforcement_of_probability',
    discoveryTitle: 'Amplitude Amplification',
    chapterIndex: 10,
    chapterTitle: 'Chapter 10 - Amplitude Amplification',
    title: 'Reinforcement of Probability',
    summary:
        'Amplitude amplification begins as incremental reinforcement: the valid state becomes more likely, but not guaranteed.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Instead of jumping from equal odds to certainty, reinforcement makes the valid candidate more likely than it was before.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The valid state moved from one equal possibility to a stronger possibility. The chapter model is gradual probability concentration.',
      examples: [
        NotebookExample(label: 'Before', notation: 'spread distribution'),
        NotebookExample(label: 'After', notation: 'weak bias'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The state is understood through its measurement probabilities. A successful reinforcement step increases the valid state probability while other outcomes can still remain possible.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This is a computation layer about reshaping likelihood. It deliberately avoids explaining the hidden construction that produced the redistribution.',
    ),
    relatedDiscoveryTitles: [
      'Mark Becomes Probability',
      'Bias Becomes Amplification',
      'Superposition',
    ],
  ),
  NotebookEntry(
    id: 'classical_vs_quantum_search_difference',
    discoveryTitle: 'Bias Becomes Amplification',
    chapterIndex: 10,
    chapterTitle: 'Chapter 10 - Amplitude Amplification',
    title: 'Bias Becomes Amplification',
    summary:
        'A small probability bias becomes amplification when the distribution is strengthened toward the valid candidate.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'After a weak bias appears, the next idea is repetition of the same kind of distribution shift. Amplification means the valid answer becomes easier to observe because the bias becomes stronger.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The learner connects weak bias to a stronger pattern. The advantage is not that the answer is handed over, but that the odds are improved.',
      examples: [
        NotebookExample(label: 'Weak bias', notation: 'slightly higher'),
        NotebookExample(label: 'Amplified', notation: 'much higher'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The register is interpreted as a probability distribution over candidates. Amplification changes that distribution so a valid state is measured more often.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This protects the key misconception: amplification is not just finding the answer. It is changing the likelihood of observing the answer through a stronger distribution shift.',
    ),
    relatedDiscoveryTitles: [
      'Amplitude Amplification',
      'Marked But Hidden',
      'Prepared Possibilities',
    ],
  ),
  NotebookEntry(
    id: 'amplification_as_computational_advantage',
    discoveryTitle: 'Amplification as Computational Advantage',
    chapterIndex: 10,
    chapterTitle: 'Chapter 10 - Amplitude Amplification',
    title: 'Amplification as Computational Advantage',
    summary:
        'Amplitude amplification becomes useful when a small probability advantage becomes a stronger bias toward a valid state.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The final chapter idea is simple: make the correct answer easier to see. The distribution shifts so the valid outcome is more likely, while still remaining a probability-based result.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The full abstraction is now useful probability advantage. The learner should describe the result as a stronger bias toward the valid state, not as certainty.',
      examples: [
        NotebookExample(label: 'Input view', notation: 'many candidates'),
        NotebookExample(label: 'Output view', notation: 'valid state likely'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Chapter 10 treats computation as reshaping measurement probabilities. The success condition is improved likelihood on the valid state.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'The notebook intentionally stays at the probability layer. Internal construction details belong below this learner-facing abstraction.',
    ),
    relatedDiscoveryTitles: [
      'Bias Becomes Amplification',
      'Amplitude Amplification',
      'Superposition',
    ],
  ),
  NotebookEntry(
    id: 'why_one_step_is_not_enough',
    discoveryTitle: 'Why One Step Is Not Enough',
    chapterIndex: 11,
    chapterTitle: 'Chapter 11 - Grover Loop Intuition',
    title: 'Why One Step Is Not Enough',
    summary:
        'One oracle plus amplification pass can improve success probability without making success likely enough.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A small advantage helps, but it may still leave too much probability on other candidates. Chapter 11 starts from the gap between improvement and reliable success.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The focus moves from a single probability improvement to the need for repeated strengthening.',
      examples: [
        NotebookExample(label: 'One pass', notation: 'better odds'),
        NotebookExample(label: 'Need', notation: 'stronger odds'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The learner tracks whether the probability distribution is strong enough to make the valid answer likely, not merely improved.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This entry prevents the misconception that amplification means instant success. It can be useful before it is strong.',
    ),
    relatedDiscoveryTitles: [
      'Oracle',
      'Amplitude Amplification',
      'Bias Becomes Amplification',
    ],
  ),
  NotebookEntry(
    id: 'iteration_improves_likelihood',
    discoveryTitle: 'Iteration Improves Likelihood',
    chapterIndex: 11,
    chapterTitle: 'Chapter 11 - Grover Loop Intuition',
    title: 'Iteration Improves Likelihood',
    summary:
        'Repeating the abstract oracle plus amplification pattern can increase the likelihood of success.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Iteration means the same high-level pattern is used again so the existing advantage can become stronger.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The new idea is repetition as computation. The learner now thinks across rounds, not just one transformation.',
      examples: [
        NotebookExample(label: 'Round 1', notation: 'small advantage'),
        NotebookExample(label: 'Later rounds', notation: 'stronger advantage'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The probability distribution is interpreted across repeated abstract rounds. The valid answer should become more likely over useful rounds.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This chapter treats oracle and amplification as named abstractions. It does not reopen how either abstraction is built.',
    ),
    relatedDiscoveryTitles: [
      'Why One Step Is Not Enough',
      'Amplification as Computational Advantage',
      'Oracle',
    ],
  ),
  NotebookEntry(
    id: 'convergence_toward_solution',
    discoveryTitle: 'Convergence Toward Solution',
    chapterIndex: 11,
    chapterTitle: 'Chapter 11 - Grover Loop Intuition',
    title: 'Convergence Toward Solution',
    summary:
        'Useful repeated rounds can move the probability distribution toward valid answers.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Convergence is the feeling that the distribution is leaning more and more toward success. It is a trend, not a one-step guarantee.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The learner now watches the direction of probability change across repeated rounds: flat at first, then slightly lifted, then visibly biased.',
      examples: [
        NotebookExample(label: 'Iteration 0', notation: 'flat distribution'),
        NotebookExample(label: 'Iteration 1', notation: 'slight lift'),
        NotebookExample(label: 'Iteration 2', notation: 'visible bias'),
        NotebookExample(
            label: 'Later useful rounds', notation: 'stronger bias'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The valid region receives increasing likelihood across useful rounds. The chapter remains focused on probability behaviour.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Convergence should not be read as unlimited repetition. The beginner-level idea is simply that structured rounds can build success probability.',
    ),
    relatedDiscoveryTitles: [
      'Iteration Improves Likelihood',
      'Bias Becomes Amplification',
      'Amplification as Computational Advantage',
    ],
  ),
  NotebookEntry(
    id: 'classical_vs_quantum_iteration',
    discoveryTitle: 'Classical vs Quantum Iteration',
    chapterIndex: 11,
    chapterTitle: 'Chapter 11 - Grover Loop Intuition',
    title: 'Classical vs Quantum Iteration',
    summary:
        'Classical repetition retries; Grover-style iteration repeatedly improves the probability distribution.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Guessing again is not the same as making the correct answer more likely. Chapter 11 separates retrying from reshaping likelihood.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The comparison shifts from number of attempts to whether the probability distribution changes between attempts.',
      examples: [
        NotebookExample(label: 'Classical retry', notation: 'sample again'),
        NotebookExample(label: 'Grover-style round', notation: 'improve odds'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The important object is the distribution over candidates. Useful iteration changes that distribution before the answer is observed.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This protects the core abstraction: Grover intuition is repeated probability improvement, not brute-force checking.',
    ),
    relatedDiscoveryTitles: [
      'Convergence Toward Solution',
      'Why One Step Is Not Enough',
      'Oracle',
    ],
  ),
  NotebookEntry(
    id: 'cognitive_transfer_of_iteration_thinking',
    discoveryTitle: 'Cognitive Transfer of Iteration Thinking',
    chapterIndex: 11,
    chapterTitle: 'Chapter 11 - Grover Loop Intuition',
    title: 'Cognitive Transfer of Iteration Thinking',
    summary:
        'Iteration thinking transfers to structured problems where weak preferences can be reinforced into better selection.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Many hard choices start with too many candidates and only a weak signal. The transferable idea is to use structured repetition to make valid choices easier to select.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The learner now applies the chapter pattern to reasoning tasks: candidate sets, weak bias, repeated refinement, and improved selection.',
      examples: [
        NotebookExample(label: 'Candidate set', notation: 'many choices'),
        NotebookExample(label: 'Weak signal', notation: 'slight preference'),
        NotebookExample(label: 'Refinement', notation: 'stronger selection'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'At this abstraction level, the useful object is the distribution over choices. Repeated refinement makes valid choices more likely without checking every option one by one.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This entry deliberately focuses on transfer: the learner should recognize iteration as a structured reasoning pattern, not as a construction recipe.',
    ),
    relatedDiscoveryTitles: [
      'Classical vs Quantum Iteration',
      'Iteration Improves Likelihood',
      'Amplification as Computational Advantage',
    ],
  ),
  NotebookEntry(
    id: 'quantum_algorithm_structure',
    discoveryTitle: 'Quantum Algorithm Structure',
    chapterIndex: 12,
    chapterTitle: 'Chapter 12 - Quantum Algorithm Structure',
    title: 'Quantum Algorithm Structure',
    summary:
        'A quantum algorithm can be understood as a structured process, not a single isolated trick.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Step back from the parts. The algorithm is a plan with roles: define what counts as valid, make valid choices more likely, and use organized repetition to build advantage.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The learner now sees the earlier abstractions as one algorithm structure rather than separate chapter ideas.',
      examples: [
        NotebookExample(label: 'Define', notation: 'valid solutions'),
        NotebookExample(label: 'Bias', notation: 'higher likelihood'),
        NotebookExample(label: 'Iterate', notation: 'stronger advantage'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'At this meta level, the useful object is the probability distribution over possible choices. The algorithm structure organizes how valid choices become easier to select.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This is a synthesis layer only. It names the abstract process without explaining how the parts are built.',
    ),
    relatedDiscoveryTitles: [
      'Oracle',
      'Amplification as Computational Advantage',
      'Cognitive Transfer of Iteration Thinking',
    ],
  ),
  NotebookEntry(
    id: 'role_separation_in_quantum_algorithms',
    discoveryTitle: 'Role Separation in Quantum Algorithms',
    chapterIndex: 12,
    chapterTitle: 'Chapter 12 - Quantum Algorithm Structure',
    title: 'Role Separation in Quantum Algorithms',
    summary:
        'Oracle, amplification, and iteration each contribute a distinct role to the abstract algorithm model.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A good process is easier to understand when each part has one job. One role defines valid solutions, one role increases likelihood, and one role organizes repeated use.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The learner separates definition, bias, and repetition instead of blending them into one vague algorithm word.',
      examples: [
        NotebookExample(label: 'Oracle', notation: 'defines valid'),
        NotebookExample(
            label: 'Amplification', notation: 'increases likelihood'),
        NotebookExample(label: 'Iteration', notation: 'repeats structure'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Role separation keeps the probability-shaping story clear: validity gives direction, likelihood gives preference, and iteration gives organized continuation.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This entry treats the roles as black-box abstractions. It does not revisit their internal design.',
    ),
    relatedDiscoveryTitles: [
      'Quantum Algorithm Structure',
      'Oracle',
      'Amplitude Amplification',
    ],
  ),
  NotebookEntry(
    id: 'why_composition_creates_advantage',
    discoveryTitle: 'Why Composition Creates Advantage',
    chapterIndex: 12,
    chapterTitle: 'Chapter 12 - Quantum Algorithm Structure',
    title: 'Why Composition Creates Advantage',
    summary:
        'Advantage comes from composing distinct roles into one organized process.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'A label by itself is not enough. Validity gives the process direction, increased likelihood gives it pressure, and repeated structure lets that pressure become useful.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The learner now focuses on composition: the value appears when separate abstractions are arranged into a layered process.',
      examples: [
        NotebookExample(label: 'Separate parts', notation: 'roles'),
        NotebookExample(label: 'Combined parts', notation: 'process'),
        NotebookExample(label: 'Result', notation: 'advantage'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The probability distribution becomes useful because the process has both direction and repeated likelihood improvement.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Composition is the main meta-level lesson. The chapter does not add a new primitive; it shows why the previous abstractions matter together.',
    ),
    relatedDiscoveryTitles: [
      'Role Separation in Quantum Algorithms',
      'Bias Becomes Amplification',
      'Iteration Improves Likelihood',
    ],
  ),
  NotebookEntry(
    id: 'classical_vs_quantum_structural_difference',
    discoveryTitle: 'Classical vs Quantum Structural Difference',
    chapterIndex: 12,
    chapterTitle: 'Chapter 12 - Quantum Algorithm Structure',
    title: 'Classical vs Quantum Structural Difference',
    summary:
        'Classical repeated search checks again; the quantum model is structured probability shaping around valid solutions.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Trying again is not the same as organizing the whole process around making valid choices more likely. The structural difference is retrying versus shaping the selection landscape.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The learner compares processes, not hardware: repeated checking on one side, layered probability shaping on the other.',
      examples: [
        NotebookExample(label: 'Classical', notation: 'repeated checks'),
        NotebookExample(label: 'Quantum model', notation: 'structured shaping'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The quantum algorithm model treats the distribution over candidates as something the process can organize toward valid solutions.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This comparison stays at the structural level. It does not claim every quantum algorithm has the same pipeline.',
    ),
    relatedDiscoveryTitles: [
      'Classical vs Quantum Iteration',
      'Why Composition Creates Advantage',
      'Quantum Algorithm Structure',
    ],
  ),
  NotebookEntry(
    id: 'unified_quantum_algorithm_model',
    discoveryTitle: 'Unified Quantum Algorithm Model',
    chapterIndex: 12,
    chapterTitle: 'Chapter 12 - Quantum Algorithm Structure',
    title: 'Unified Quantum Algorithm Model',
    summary:
        'The unified beginner model is a layered pipeline: define, bias, iterate.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'The chapter compresses the last three abstractions into one portable model: define valid solutions, bias the distribution toward them, then iterate the structure.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The learner leaves with a compact mental pipeline instead of a list of separate terms.',
      examples: [
        NotebookExample(label: 'Step 1', notation: 'define'),
        NotebookExample(label: 'Step 2', notation: 'bias'),
        NotebookExample(label: 'Step 3', notation: 'iterate'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The unified model describes an abstract probability-shaping pipeline over candidate solutions.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'This is deliberately a high-level model. It prepares future algorithm chapters without reopening lower-level explanations.',
    ),
    relatedDiscoveryTitles: [
      'Quantum Algorithm Structure',
      'Role Separation in Quantum Algorithms',
      'Why Composition Creates Advantage',
    ],
  ),
  NotebookEntry(
    id: 'reflection_about_mean',
    discoveryTitle: 'Reflection About the Mean',
    chapterIndex: 13,
    chapterTitle: 'Chapter 13 - Building and Stopping Quantum Search',
    title: 'Amplitudes Around the Mean',
    summary:
        'Reflect signed amplitudes before calculating search probabilities.',
    executableExampleIds: ['search_marked_input'],
    intuition: NotebookSection(
        title: 'Intuition',
        body:
            'A phase mark can change a sign without changing a probability. Reflection uses the mean of signed amplitudes, not the mean of probabilities.'),
    whatChanged: NotebookSection(
        title: 'What Changed?',
        body:
            'In basis order 00,01,10,11, [1/2,1/2,−1/2,1/2] has mean 1/4. Applying a′=2m−a gives [0,0,1,0]. Only then square amplitudes: outcome 10 is certain for this input.'),
    quantumView: NotebookSection(
        title: 'Quantum View',
        body:
            'D=2|s⟩⟨s|−I reflects about the uniform reference. It preserves normalization, but does not always increase marked probability. The executable example prepares the marked input; the reflection calculation here uses mathematical D.',
        examples: [
          NotebookExample.math(
              label: 'Search mathematics',
              notation:
                  'm=\\frac14,\\qquad [\\frac12,\\frac12,-\\frac12,\\frac12]\\xrightarrow{D}[0,0,1,0]',
              latexLines: [
                'm=\\frac14,\\qquad [\\frac12,\\frac12,-\\frac12,\\frac12]\\xrightarrow{D}[0,0,1,0]'
              ]),
        ]),
    relatedDiscoveryTitles: ['Diffusion as a Circuit'],
  ),
  NotebookEntry(
    id: 'diffusion_as_circuit',
    discoveryTitle: 'Diffusion as a Circuit',
    chapterIndex: 13,
    chapterTitle: 'Chapter 13 - Building and Stopping Quantum Search',
    title: 'A Reusable Reflection',
    summary:
        'Change basis to turn one phase mark into a reusable search reflection.',
    executableExampleIds: ['search_reflection'],
    intuition: NotebookSection(
        title: 'Intuition',
        body:
            'Prepare the reference, apply a phase operation in its original basis, and undo the basis change. This changes an operator, not just one convenient output.'),
    whatChanged: NotebookSection(
        title: 'What Changed?',
        body:
            'Let U=H(q0)H(q1). X on both wires around CZ negates only 00. Chronologically U → X(q0)X(q1) → CZ → X(q0)X(q1) → U implements I−2|s⟩⟨s|=−D.'),
    quantumView: NotebookSection(
        title: 'Quantum View',
        body:
            'The exact sign matters for the authored operator contract. On 00, −D produces [1/2,−1/2,−1/2,−1/2]. On |s⟩ it produces −|s⟩. D and −D have identical probabilities on the same input, but their exact matrices differ.',
        examples: [
          NotebookExample.math(
              label: 'Search mathematics',
              notation: '-D=I-2|s\\rangle\\langle s|',
              latexLines: ['-D=I-2|s\\rangle\\langle s|']),
        ]),
    relatedDiscoveryTitles: [
      'Reflection About the Mean',
      'Four-State Quantum Search'
    ],
  ),
  NotebookEntry(
    id: 'four_state_search',
    discoveryTitle: 'Four-State Quantum Search',
    chapterIndex: 13,
    chapterTitle: 'Chapter 13 - Building and Stopping Quantum Search',
    title: 'From a Mark to a Measurable Answer',
    summary: 'Preparation, phase marking and interference have distinct jobs.',
    executableExampleIds: ['search_correct_order'],
    intuition: NotebookSection(
        title: 'Intuition',
        body:
            'The oracle identifies a branch by sign; interference makes the mark observable. Measuring immediately after marking still gives a uniform distribution.'),
    whatChanged: NotebookSection(
        title: 'What Changed?',
        body:
            'Prepare U=H(q0)H(q1), then O10=X(q0) CZ X(q0), then −D. With q0 top/least-significant and labels |q1 q0⟩, this marks 10. The final vector is [0,0,−1,0], so P(10)=1.'),
    quantumView: NotebookSection(
        title: 'Quantum View',
        body:
            'The global minus does not change the certain outcome. A shortcut that merely prepares 10 is not the complete search operator; the Journey construction checks the full unitary.',
        examples: [
          NotebookExample.math(
              label: 'Search mathematics',
              notation:
                  '|00\\rangle\\xrightarrow{U}|s\\rangle\\xrightarrow{O_{10}}\\frac12[1,1,-1,1]\\xrightarrow{-D}-|10\\rangle',
              latexLines: [
                '|00\\rangle\\xrightarrow{U}|s\\rangle\\xrightarrow{O_{10}}\\frac12[1,1,-1,1]\\xrightarrow{-D}-|10\\rangle'
              ]),
        ]),
    relatedDiscoveryTitles: ['Diffusion as a Circuit', 'Search Round Order'],
  ),
  NotebookEntry(
    id: 'search_round_order',
    discoveryTitle: 'Search Round Order',
    chapterIndex: 13,
    chapterTitle: 'Chapter 13 - Building and Stopping Quantum Search',
    title: 'Order Is Part of Search',
    summary:
        'The same search blocks in a different order need not produce the same distribution.',
    executableExampleIds: ['search_reordered'],
    intuition: NotebookSection(
        title: 'Intuition',
        body:
            'Operations compose chronologically from left to right in these examples. An oracle and a reflection do not generally commute.'),
    whatChanged: NotebookSection(
        title: 'What Changed?',
        body:
            'U → O10 → (−D) yields [0,0,−1,0], with P(10)=1. U → (−D) → O10 first gives −|s⟩, then [−1/2,−1/2,1/2,−1/2]. All four probabilities remain 1/4.'),
    quantumView: NotebookSection(
        title: 'Quantum View',
        body:
            'Because (−D)|s⟩=−|s⟩, applying reflection before marking cannot create a probability bias here. The oracle then changes relative signs, but without subsequent interference those signs do not change measurement probabilities. Compare this executable reordered circuit with the preceding discovery.',
        examples: [
          NotebookExample.math(
              label: 'Search mathematics',
              notation:
                  '(-D)|s\\rangle=-|s\\rangle,\\qquad P_{\\mathrm{reordered}}(x)=\\frac14',
              latexLines: [
                '(-D)|s\\rangle=-|s\\rangle,\\qquad P_{\\mathrm{reordered}}(x)=\\frac14'
              ]),
        ]),
    relatedDiscoveryTitles: [
      'Four-State Quantum Search',
      'Search Stopping Point'
    ],
  ),
  NotebookEntry(
    id: 'search_stopping_point',
    discoveryTitle: 'Search Stopping Point',
    chapterIndex: 13,
    chapterTitle: 'Chapter 13 - Building and Stopping Quantum Search',
    title: 'One More Round Can Be Worse',
    summary: 'Coherent search can move past the best stopping point.',
    executableExampleIds: ['search_two_rounds'],
    intuition: NotebookSection(
        title: 'Intuition',
        body:
            'Amplification is a reversible evolution, not an irreversible accumulation of success. Repeat the complete oracle-plus-reflection round and track signed amplitudes.'),
    whatChanged: NotebookSection(
        title: 'What Changed?',
        body:
            'For mathematical D: [1/2,1/2,1/2,1/2] → oracle [1/2,1/2,−1/2,1/2] → D [0,0,1,0] → oracle [0,0,−1,0] → D [−1/2,−1/2,1/2,−1/2]. Success at rounds 0,1,2 is 1/4,1,1/4.'),
    quantumView: NotebookSection(
        title: 'Quantum View',
        body:
            'The physical −D circuit gives −|10⟩ after one round; the second oracle gives +|10⟩, then the second −D gives [−1/2,−1/2,1/2,−1/2]. At the same round count r, the −D result is (−1)^r times the D result. That is a global sign between conventions, not an explanation for the probability drop between rounds.',
        examples: [
          NotebookExample.math(
              label: 'Search mathematics',
              notation: 'P_0=\\frac14,\\qquad P_1=1,\\qquad P_2=\\frac14',
              latexLines: ['P_0=\\frac14,\\qquad P_1=1,\\qquad P_2=\\frac14']),
        ]),
    relatedDiscoveryTitles: ['Search Round Order', 'Quantitative Search'],
  ),
  NotebookEntry(
    id: 'quantitative_search',
    discoveryTitle: 'Quantitative Search',
    chapterIndex: 13,
    chapterTitle: 'Chapter 13 - Building and Stopping Quantum Search',
    title: 'Calculate When to Stop',
    summary:
        'Search-space size and marked count determine the useful number of rounds.',
    executableExampleIds: [
      'search_eight_1',
      'search_eight_2',
      'search_eight_3'
    ],
    intuition: NotebookSection(
        title: 'Intuition',
        body:
            'For eight states with one marked outcome, use b/√8 for the marked amplitude and c/√8 for each of the seven unmarked amplitudes. Start with b=c=1.'),
    whatChanged: NotebookSection(
        title: 'What Changed?',
        body:
            'After the oracle μ=(7c−b)/8. Simultaneously update b′=2μ+b and c′=2μ−c. The pairs at rounds 0–3 are (1,1), (5/2,1/2), (11/4,−1/4), (13/8,−7/8). P=b²/8 gives 1/8,25/32,121/128,169/512, or 12.5%,78.125%,94.53125%,33.0078125%.'),
    quantumView: NotebookSection(
        title: 'Quantum View',
        body:
            'Each pair obeys (b²+7c²)/8=1. Round 2 is the first above 90% and the best among 0–3; it is not universally optimal. More marked solutions change the mean and initial marked weight. The examples mark 110 in |q2 q1 q0⟩ order and implement −D with existing gates, so round r has global factor (−1)^r relative to this D recurrence. H(q2) around Toffoli implements the three-bit phase mark.',
        examples: [
          NotebookExample.math(
              label: 'Search mathematics',
              notation:
                  '\\mu=\\frac{7c-b}{8},\\quad b^{\\prime}=2\\mu+b,\\quad c^{\\prime}=2\\mu-c,\\quad P=\\frac{b^2}{8}',
              latexLines: [
                '\\mu=\\frac{7c-b}{8},\\quad b^{\\prime}=2\\mu+b,\\quad c^{\\prime}=2\\mu-c,\\quad P=\\frac{b^2}{8}'
              ]),
        ]),
    relatedDiscoveryTitles: ['Search Stopping Point'],
  ),
  NotebookEntry(
    id: 'notation_and_terms',
    discoveryTitle: 'Notation & Terms',
    chapterIndex: 0,
    chapterTitle: 'Reference',
    title: 'Notation & Terms',
    summary:
        'A compact reference for the symbols and recurring language used in Qubit Quest.',
    intuition: NotebookSection(
      title: 'State notation',
      body:
          'Quantum notation is compact so a circuit and its state can be read together. Use this page as a reference; the Journey introduces each idea through examples.',
      examples: [
        NotebookExample.math(
          label: 'Ket',
          notation: '|ψ⟩',
          latex: r'\lvert\psi\rangle',
          explanation:
              'A label for a quantum state. ψ (“psi”) stands for any state.',
        ),
        NotebookExample(
          label: 'Amplitude',
          notation:
              'A complex number attached to a basis state. Its magnitude squared gives that outcome’s probability.',
        ),
        NotebookExample.math(
          label: 'Imaginary unit',
          notation: 'i² = −1',
          latex: r'i^{2}=-1',
          explanation: 'The complex number whose square is negative one.',
        ),
      ],
    ),
    whatChanged: NotebookSection(
      title: 'Operations',
      body:
          'These symbols describe what gates do and how circuits are reversed.',
      examples: [
        NotebookExample.math(
          label: 'Dagger',
          notation: 'U† = U⁻¹',
          latex: r'U^{\dagger}=U^{-1}',
          explanation:
              'The inverse of a quantum gate. Mathematically it is the conjugate transpose.',
        ),
        NotebookExample.math(
          label: 'Identity',
          notation: 'I',
          explanation: 'The operation that leaves the quantum state unchanged.',
        ),
        NotebookExample.math(
          label: 'Tensor product',
          notation: '⊗',
          latex: r'\otimes',
          explanation:
              'Combines state descriptions into one larger multi-qubit state.',
        ),
        NotebookExample(
          label: 'Uncomputation',
          notation:
              'Reversing temporary circuit work so workspace returns to its starting state.',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'State relationships',
      body:
          'These terms distinguish information stored in one amplitude from relationships across a state or register.',
      examples: [
        NotebookExample(
          label: 'Global phase',
          notation:
              'One common phase factor multiplying the whole state; it does not change physical predictions.',
        ),
        NotebookExample(
          label: 'Relative phase',
          notation:
              'A phase difference between amplitudes that can change later interference.',
        ),
        NotebookExample(
          label: 'Superposition',
          notation:
              'A state with more than one basis-state amplitude available before measurement.',
        ),
        NotebookExample(
          label: 'Entanglement',
          notation:
              'A shared multi-qubit state that cannot be separated into independent qubit states.',
        ),
        NotebookExample(
          label: 'Ancilla',
          notation:
              'A helper qubit used as temporary workspace inside a computation.',
        ),
        NotebookExample(
          label: 'Oracle',
          notation:
              'A reversible operation that encodes or evaluates a problem-specific rule.',
        ),
      ],
    ),
  ),
];

final Map<String, NotebookEntry> notebookEntriesByDiscoveryTitle = {
  for (final entry in notebookEntries) entry.discoveryTitle: entry,
};

final Map<String, NotebookEntry> notebookEntriesById = {
  for (final entry in notebookEntries) entry.id: entry,
};

const String notebookReferenceEntryId = 'notation_and_terms';

bool isNotebookEntryAvailable(
  NotebookEntry entry,
  Set<String> unlockedDiscoveryTitles,
) =>
    entry.id == notebookReferenceEntryId ||
    unlockedDiscoveryTitles.contains(entry.discoveryTitle);
