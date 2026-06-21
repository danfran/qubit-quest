import 'package:quantumquiz/models/notebook_entry.dart';

const List<NotebookEntry> notebookEntries = [
  NotebookEntry(
    id: 'information',
    discoveryTitle: 'Information',
    chapterIndex: 1,
    chapterTitle: 'Chapter 1 - The Quantum Bit',
    title: 'The First Qubit',
    summary: 'A qubit can hold a state, and a circuit can change that state.',
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
        NotebookExample(label: 'Before', notation: '|0⟩'),
        NotebookExample(label: 'After', notation: '|1⟩'),
        NotebookExample(label: 'Gate action', notation: 'X|0⟩ = |1⟩'),
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
          'Imagine walking one step to the right, then one step to the left. You moved, but you ended where you started. The X gate works similarly here: one X flips the qubit, and another X flips it back.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The visible state changed twice: first from |0⟩ to |1⟩, then back from |1⟩ to |0⟩. What stayed the same is the information trail: the second X reverses the first X instead of erasing it.',
      examples: [
        NotebookExample(label: 'Start', notation: '|0⟩'),
        NotebookExample(label: 'After first X', notation: '|1⟩'),
        NotebookExample(label: 'After second X', notation: '|0⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'X flips both basis states. Because it works in both directions, applying X twice brings the qubit back to where it began.',
      examples: [
        NotebookExample(
            label: 'X on basis states', notation: 'X|0⟩ = |1⟩\nX|1⟩ = |0⟩'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Reversibility is one reason quantum circuits are built differently from ordinary one-way calculations. Later, circuits will often do work and then undo part of that work. This is called uncomputation.',
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
        NotebookExample(label: 'Short path', notation: '|0⟩ → X → |1⟩'),
        NotebookExample(
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
        NotebookExample(label: 'Two X gates', notation: 'XX|0⟩ = |0⟩'),
        NotebookExample(label: 'Three X gates', notation: 'XXX|0⟩ = |1⟩'),
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
        NotebookExample(label: 'Before', notation: '|00⟩'),
        NotebookExample(label: 'After', notation: '|11⟩'),
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
        NotebookExample(label: 'Before', notation: '|01⟩'),
        NotebookExample(label: 'After', notation: '|10⟩'),
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
        NotebookExample(label: 'Pattern change', notation: '|01⟩ → |10⟩'),
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
        NotebookExample(label: 'Before', notation: '|0⟩'),
        NotebookExample(label: 'After Z', notation: '|0⟩'),
        NotebookExample(
            label: 'Visible measurement', notation: 'P(|0⟩) = 100%'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Z leaves |0⟩ unchanged, but that does not mean Z does nothing. The same gate will behave differently on |1⟩. This separates "nothing visible changed" from "nothing happened."',
      examples: [
        NotebookExample(label: 'Z on |0⟩', notation: 'Z|0⟩ = |0⟩'),
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
        'Two states can give the same measurement result while still being different quantum states.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Imagine two cards that both show "1" on the front. One card has a hidden mark on the back. If you only look at the front, they seem identical. But a later rule can use the hidden mark. The minus sign on −|1⟩ works like that hidden mark.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The measured bit stayed 1. The state description changed by gaining a minus sign.',
      examples: [
        NotebookExample(label: 'Before', notation: '|1⟩'),
        NotebookExample(label: 'After', notation: '−|1⟩'),
        NotebookExample(
          label: 'Measurement',
          notation: 'P(|1⟩) = 100% before\nP(|1⟩) = 100% after',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Z leaves |0⟩ alone and gives |1⟩ a minus sign. For a single basis state, that sign does not change the measurement probability. Later, when there are multiple parts to compare, signs can affect how the state behaves.',
      examples: [
        NotebookExample(
          label: 'Z gate action',
          notation: 'Z|0⟩ = |0⟩\nZ|1⟩ = −|1⟩',
        ),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'A single overall sign is not directly visible as a different measurement result. The useful lesson here is preparatory: signs become meaningful when they become relationships between parts of a state.',
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
        NotebookExample(label: 'Before', notation: '|+⟩ = (|0⟩ + |1⟩)/√2'),
        NotebookExample(label: 'After', notation: '|−⟩ = (|0⟩ − |1⟩)/√2'),
        NotebookExample(
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
        NotebookExample(label: 'Before', notation: '|−⟩ = (|0⟩ − |1⟩)/√2'),
        NotebookExample(label: 'After', notation: '|+⟩ = (|0⟩ + |1⟩)/√2'),
        NotebookExample(
            label: 'Measurement before',
            notation: 'P(|0⟩) = 50%\nP(|1⟩) = 50%'),
        NotebookExample(
            label: 'Measurement after', notation: 'P(|0⟩) = 50%\nP(|1⟩) = 50%'),
        NotebookExample(
            label: 'Key difference',
            notation:
                'The probabilities stayed the same, but the phase relationship changed.'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          '|+⟩ and |−⟩ contain the same possible measurement outcomes with the same probabilities. Their difference is the sign relationship between |0⟩ and |1⟩. That relationship is information because later gates can react to it.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Many quantum algorithms first place useful information into phase. Later, interference converts that stored relationship into changed measurement probabilities. This is why hidden information can still be useful.',
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
        NotebookExample(label: 'Before', notation: '|0⟩'),
        NotebookExample(label: 'After', notation: '|+⟩ = (|0⟩ + |1⟩)/√2'),
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
        NotebookExample(label: 'Hadamard action', notation: 'H|0⟩ = |+⟩'),
        NotebookExample(label: 'Plus state', notation: '|+⟩ = (|0⟩ + |1⟩)/√2'),
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
        NotebookExample(
          label: 'Possible outcomes',
          notation: '|0⟩\n|1⟩',
        ),
        NotebookExample(
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
        NotebookExample(
          label: 'Balanced state',
          notation: '(|0⟩ − |1⟩)/√2',
        ),
        NotebookExample(
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
        NotebookExample(label: 'Before', notation: '|+⟩'),
        NotebookExample(label: 'After', notation: '|0⟩'),
        NotebookExample(
          label: 'Measurement before',
          notation: 'P(|0⟩) = 50%\nP(|1⟩) = 50%',
        ),
        NotebookExample(
          label: 'Measurement after',
          notation: 'P(|0⟩) = 100%\nP(|1⟩) = 0%',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The H gate is reversible. It can create |+⟩ from |0⟩, and it can also turn |+⟩ back into |0⟩. This is why superposition should not be confused with ordinary randomness.',
      examples: [
        NotebookExample(label: 'Create superposition', notation: 'H|0⟩ = |+⟩'),
        NotebookExample(label: 'Reverse superposition', notation: 'H|+⟩ = |0⟩'),
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
        NotebookExample(label: 'Start', notation: '|1⟩'),
        NotebookExample(label: 'Prepare input', notation: 'X|1⟩ = |0⟩'),
        NotebookExample(label: 'Create superposition', notation: 'H|0⟩ = |+⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The final state depends on the input to H. Preparing the input first lets the circuit create the intended superposition.',
      examples: [
        NotebookExample(
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
        NotebookExample(label: 'Start', notation: '|10⟩'),
        NotebookExample(label: 'Prepare register', notation: '|10⟩ → |00⟩'),
        NotebookExample(label: 'Place superposition', notation: '|00⟩ → |+0⟩'),
        NotebookExample(
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
        NotebookExample(
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
];

final Map<String, NotebookEntry> notebookEntriesByDiscoveryTitle = {
  for (final entry in notebookEntries) entry.discoveryTitle: entry,
};
