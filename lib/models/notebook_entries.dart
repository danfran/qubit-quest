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
        NotebookExample(label: 'Before', notation: '|+⟩ = (|0⟩ + |1⟩)/√2'),
        NotebookExample(label: 'After', notation: '|−⟩ = (|0⟩ − |1⟩)/√2'),
        NotebookExample(
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
        NotebookExample(label: 'Phase change', notation: 'Z|+⟩ = |−⟩'),
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
        NotebookExample(label: 'Start', notation: '|0⟩'),
        NotebookExample(label: 'Create paths', notation: '|0⟩ → H → |+⟩'),
        NotebookExample(
            label: 'Reveal phase', notation: '|+⟩ → Z → |−⟩ → H → |1⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The identity HZH = X supports the discovery, but the discovery is the mechanism: H changes basis, Z changes phase, and the final H makes that phase visible as a bit flip.',
      examples: [
        NotebookExample(label: 'Gate identity', notation: 'HZH = X'),
        NotebookExample(
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
        NotebookExample(label: 'Start', notation: '|+⟩'),
        NotebookExample(label: 'Change basis', notation: '|+⟩ → H → |0⟩'),
        NotebookExample(
            label: 'Return with phase', notation: '|0⟩ → X → |1⟩ → H → |−⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The identity HXH = Z is useful because it shows that gate meaning depends on basis. The equation is not just something to memorize; it says that surrounding an operation with a basis change can alter what feature it affects.',
      examples: [
        NotebookExample(label: 'Gate identity', notation: 'HXH = Z'),
        NotebookExample(
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
        NotebookExample(
            label: 'Before reveal', notation: '|−⟩ = (|0⟩ − |1⟩)/√2'),
        NotebookExample(label: 'After reveal', notation: 'H|−⟩ = |1⟩'),
        NotebookExample(
          label: 'Probability change',
          notation:
              'Before H: P(|0⟩) = 50%, P(|1⟩) = 50%\nAfter H: P(|0⟩) = 0%, P(|1⟩) = 100%',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Amplitudes add with signs. When two contributions to the same outcome have equal size and opposite sign, the sum is zero. The outcome is not erased; it receives zero final amplitude.',
      examples: [
        NotebookExample(label: 'Cancellation', notation: '1/2 − 1/2 = 0'),
        NotebookExample(label: 'Reinforcement', notation: '1/2 + 1/2 = 1'),
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
        NotebookExample(
            label: 'Destructive result', notation: 'P(|0⟩): 50% → 0%'),
        NotebookExample(
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
        NotebookExample(label: 'One qubit', notation: '|0⟩ or |1⟩'),
        NotebookExample(label: 'Two-qubit register', notation: '|00⟩'),
        NotebookExample(label: 'Independent changes', notation: '|00⟩ → |11⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'A two-qubit register uses basis states with two labels. The first label belongs to q0 and the second label belongs to q1. If the qubits are independent, the register can still be understood as one qubit state together with another qubit state.',
      examples: [
        NotebookExample(
            label: 'Basis states', notation: '|00⟩, |01⟩, |10⟩, |11⟩'),
        NotebookExample(label: 'Product example', notation: '|1⟩|1⟩ = |11⟩'),
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
        NotebookExample(label: 'Control off', notation: 'CNOT|00⟩ = |00⟩'),
        NotebookExample(label: 'Control on', notation: 'CNOT|10⟩ = |11⟩'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'CNOT has two parts: a control and a target. It copies the control condition into an action on the target when the control is a definite |1⟩. If the control is in superposition, the same gate can connect different branches of the state.',
      examples: [
        NotebookExample(label: 'Rule', notation: '|control,target⟩'),
        NotebookExample(label: 'Conditional flip', notation: '|10⟩ → |11⟩'),
        NotebookExample(label: 'No flip', notation: '|00⟩ → |00⟩'),
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
        NotebookExample(
            label: 'Prepare possibilities',
            notation: '|00⟩ → H on q0 → (|00⟩ + |10⟩)/√2'),
        NotebookExample(
            label: 'Connect branches', notation: 'CNOT → (|00⟩ + |11⟩)/√2'),
        NotebookExample(
            label: 'Measurements', notation: 'Only |00⟩ or |11⟩ can appear'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'The Bell state Φ+ is a superposition of two two-qubit basis states. It cannot be treated as one independent state for q0 and a separate independent state for q1.',
      examples: [
        NotebookExample(
            label: 'Bell state', notation: '|Φ+⟩ = (|00⟩ + |11⟩)/√2'),
        NotebookExample(
            label: 'Not independent', notation: 'not q0 state × q1 state'),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Bell states are examples of entanglement, not the definition of entanglement. They are useful because they are small, symmetric, and easy to test. Looking Ahead: Bell states become building blocks for quantum teleportation.',
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
        NotebookExample(label: 'Separable example', notation: '|+0⟩ = |+⟩|0⟩'),
        NotebookExample(
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
        NotebookExample(
            label: 'Entangled state', notation: '|Φ−⟩ = (|00⟩ − |11⟩)/√2'),
        NotebookExample(label: 'Possible outcomes', notation: '|00⟩ or |11⟩'),
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
        NotebookExample(label: 'Bell example', notation: '(|00⟩ − |11⟩)/√2'),
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
];

final Map<String, NotebookEntry> notebookEntriesByDiscoveryTitle = {
  for (final entry in notebookEntries) entry.discoveryTitle: entry,
};
