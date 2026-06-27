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

  String get chapterIdentity {
    switch (chapterIndex) {
      case 1:
        return 'How quantum information is stored and transformed';
      case 2:
        return 'How hidden properties affect states without visible change';
      case 3:
        return 'How quantum states are prepared and interpreted';
      case 4:
        return 'How hidden phase becomes visible through interference';
      case 5:
        return 'When quantum systems become inseparable';
      case 6:
        return 'How information is created, controlled, and routed';
      default:
        return '';
    }
  }
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
