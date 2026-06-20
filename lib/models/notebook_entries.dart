import 'package:quantumquiz/models/notebook_entry.dart';

const List<NotebookEntry> notebookEntries = [
  NotebookEntry(
    id: 'invisible_difference',
    discoveryTitle: 'Invisible Difference',
    chapterIndex: 2,
    chapterTitle: 'Chapter 2 - Hidden Change',
    title: 'Invisible Difference',
    summary:
        'A quantum state can change in a way measurement probabilities do not reveal yet.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Imagine two cards that both show "1" on the front. One card has a hidden mark on the back. If you only look at the front, they seem identical. But a later rule can use the hidden mark. The minus sign on -|1> works like that hidden mark.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The measured bit did not change. The amplitude gained a minus sign.',
      examples: [
        NotebookExample(label: 'Before', notation: '|1>'),
        NotebookExample(label: 'After', notation: '-|1>'),
        NotebookExample(
          label: 'Measurement',
          notation: 'P(|1>) = 100% before\nP(|1>) = 100% after',
        ),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'For a single basis state, this sign is not visible as a different probability. The important idea comes later: when a state has multiple parts, signs become relative phase, and relative phase can change interference.',
      examples: [
        NotebookExample(
          label: 'Z gate action',
          notation: 'Z|0> = |0>\nZ|1> = -|1>',
        ),
      ],
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'A global phase by itself is not directly observable. The useful lesson here is preparatory: signs become meaningful when compared between components of a superposition, such as |+> and |->.',
    ),
    relatedDiscoveryTitles: [
      'Relative Phase',
      'Phase Information',
      'Interference',
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
          'The possible outcomes stayed balanced, but the sign between the two amplitudes changed.',
      examples: [
        NotebookExample(label: 'Before', notation: '|+> = (|0> + |1>)/sqrt(2)'),
        NotebookExample(label: 'After', notation: '|-> = (|0> - |1>)/sqrt(2)'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'This sign relationship is relative phase. Relative phase does not show up as a simple probability bar, but later gates can turn it into a different measured result.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          '|+> and |-> form a useful pair of basis states. They look identical if you only compare measurement odds in the |0>, |1> basis, but they respond differently to a Hadamard gate.',
    ),
    relatedDiscoveryTitles: [
      'Invisible Difference',
      'Phase Information',
      'Phase',
    ],
  ),
  NotebookEntry(
    id: 'hidden_information',
    discoveryTitle: 'Phase Information',
    chapterIndex: 2,
    chapterTitle: 'Chapter 2 - Hidden Change',
    title: 'Hidden Information',
    summary:
        'Quantum information can live in relationships between amplitudes, not only in visible bit values.',
    intuition: NotebookSection(
      title: 'Intuition',
      body:
          'Think of phase as a private note inside the state. The probability bars tell you which outcomes may appear, but the private note tells the next gate how those outcomes should combine.',
    ),
    whatChanged: NotebookSection(
      title: 'What Changed?',
      body:
          'The same outcomes remained possible. The circuit restored the plus relationship between the two pieces.',
      examples: [
        NotebookExample(label: 'Before', notation: '|-> = (|0> - |1>)/sqrt(2)'),
        NotebookExample(label: 'After', notation: '|+> = (|0> + |1>)/sqrt(2)'),
      ],
    ),
    quantumView: NotebookSection(
      title: 'Quantum View',
      body:
          'Changing |-> back into |+> changes relative phase. This is information because future operations can react to the difference, even when direct measurement odds are unchanged.',
    ),
    advancedNotes: NotebookSection(
      title: 'Advanced Notes',
      body:
          'Many quantum algorithms first write useful information into phase. Later interference converts that stored relationship into changed measurement probabilities.',
    ),
    relatedDiscoveryTitles: [
      'Relative Phase',
      'Phase',
      'Interference',
    ],
  ),
];

final Map<String, NotebookEntry> notebookEntriesByDiscoveryTitle = {
  for (final entry in notebookEntries) entry.discoveryTitle: entry,
};
