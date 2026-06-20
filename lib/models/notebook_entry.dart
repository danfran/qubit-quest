class NotebookEntry {
  const NotebookEntry({
    required this.id,
    required this.discoveryTitle,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.title,
    required this.summary,
    required this.intuition,
    this.whatChanged,
    this.quantumView,
    this.advancedNotes,
    this.relatedDiscoveryTitles = const [],
  });

  final String id;
  final String discoveryTitle;
  final int chapterIndex;
  final String chapterTitle;
  final String title;
  final String summary;
  final NotebookSection intuition;
  final NotebookSection? whatChanged;
  final NotebookSection? quantumView;
  final NotebookSection? advancedNotes;
  final List<String> relatedDiscoveryTitles;
}

class NotebookSection {
  const NotebookSection({
    required this.title,
    required this.body,
    this.examples = const [],
  });

  final String title;
  final String body;
  final List<NotebookExample> examples;
}

class NotebookExample {
  const NotebookExample({
    required this.label,
    required this.notation,
    this.explanation,
  });

  final String label;
  final String notation;
  final String? explanation;
}
