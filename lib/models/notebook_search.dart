import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

enum NotebookSearchMatchKind {
  title,
  chapter,
  section,
  concept,
  example,
  body,
}

Set<String> notebookSearchAllowedEntryIds({
  required Iterable<NotebookEntry> entries,
  required Set<String> unlockedDiscoveryTitles,
}) =>
    {
      for (final entry in entries)
        if (unlockedDiscoveryTitles.contains(entry.discoveryTitle)) entry.id,
    };

class NotebookSearchDocument {
  NotebookSearchDocument({
    required this.entry,
    required this.titleText,
    required this.chapterText,
    required this.sectionText,
    required this.conceptText,
    required this.exampleText,
    required this.bodyText,
    required this.snippetSources,
  })  : normalizedTitle = normalizeNotebookSearchText(titleText),
        normalizedChapter = normalizeNotebookSearchText(chapterText),
        normalizedSection = normalizeNotebookSearchText(sectionText),
        normalizedConcept = normalizeNotebookSearchText(conceptText),
        normalizedExample = normalizeNotebookSearchText(exampleText),
        normalizedBody = normalizeNotebookSearchText(bodyText);

  final NotebookEntry entry;
  final String titleText;
  final String chapterText;
  final String sectionText;
  final String conceptText;
  final String exampleText;
  final String bodyText;
  final List<String> snippetSources;
  final String normalizedTitle;
  final String normalizedChapter;
  final String normalizedSection;
  final String normalizedConcept;
  final String normalizedExample;
  final String normalizedBody;
}

class NotebookSearchResult {
  const NotebookSearchResult({
    required this.document,
    required this.score,
    required this.matchKind,
    required this.snippet,
  });

  final NotebookSearchDocument document;
  final int score;
  final NotebookSearchMatchKind matchKind;
  final String snippet;

  NotebookEntry get entry => document.entry;
}

class NotebookSearchAuditReport {
  const NotebookSearchAuditReport({required this.errors});

  final List<String> errors;
  bool get isValid => errors.isEmpty;
}

class NotebookSearchIndex {
  NotebookSearchIndex._(this.documents);

  final List<NotebookSearchDocument> documents;

  factory NotebookSearchIndex.build({
    required Iterable<NotebookEntry> entries,
    required Iterable<ExecutableNotebookExample> executableExamples,
  }) {
    final examplesById = {
      for (final example in executableExamples) example.id: example,
    };
    return NotebookSearchIndex._([
      for (final entry in entries)
        _buildDocument(
          entry,
          [
            for (final id in entry.executableExampleIds)
              if (examplesById[id] case final example?) example,
          ],
        ),
    ]);
  }

  static NotebookSearchDocument _buildDocument(
    NotebookEntry entry,
    List<ExecutableNotebookExample> examples,
  ) {
    final sections = [
      entry.intuition,
      if (entry.whatChanged != null) entry.whatChanged!,
      if (entry.quantumView != null) entry.quantumView!,
      if (entry.advancedNotes != null) entry.advancedNotes!,
    ];
    final exampleText = <String>[];
    for (final example in examples) {
      exampleText.addAll([
        example.title,
        example.description,
        if (example.relatedConcept != null) example.relatedConcept!,
        ...example.operations.map((operation) => operation.gateType.name),
        if (example.operations
            .any((operation) => _isRotation(operation.gateType)))
          'rotation rotations Rx Ry Rz',
      ]);
    }
    final body = <String>[
      entry.summary,
      for (final section in sections) section.body,
      for (final section in sections)
        for (final example in section.examples) ...[
          example.label,
          example.notation,
          if (example.explanation != null) example.explanation!,
        ],
    ];
    return NotebookSearchDocument(
      entry: entry,
      titleText: '${entry.title} ${entry.discoveryTitle}',
      chapterText: '${entry.chapterTitle} ${entry.chapterIdentity}',
      sectionText: sections.map((section) => section.title).join(' '),
      conceptText: entry.relatedDiscoveryTitles.join(' '),
      exampleText: exampleText.join(' '),
      bodyText: body.join(' '),
      snippetSources: [
        entry.summary,
        ...sections.map((section) => section.body)
      ],
    );
  }

  List<NotebookSearchResult> search(
    String query, {
    Set<String>? allowedEntryIds,
  }) {
    final normalized = normalizeNotebookSearchText(query);
    if (normalized.isEmpty) return const [];
    final tokens =
        normalized.split(' ').where((token) => token.isNotEmpty).toList();
    final results = <NotebookSearchResult>[];
    for (final document in documents) {
      if (allowedEntryIds != null &&
          !allowedEntryIds.contains(document.entry.id)) {
        continue;
      }
      final fields = <NotebookSearchMatchKind, String>{
        NotebookSearchMatchKind.title: document.normalizedTitle,
        NotebookSearchMatchKind.chapter: document.normalizedChapter,
        NotebookSearchMatchKind.section: document.normalizedSection,
        NotebookSearchMatchKind.concept: document.normalizedConcept,
        NotebookSearchMatchKind.example: document.normalizedExample,
        NotebookSearchMatchKind.body: document.normalizedBody,
      };
      final combined = fields.values.join(' ');
      final matchedCount = tokens.where(combined.contains).length;
      final minimumTokenMatches =
          tokens.length == 1 ? 1 : (tokens.length + 1) ~/ 2;
      if (matchedCount < minimumTokenMatches) continue;
      final allTokens = matchedCount == tokens.length;
      final (kind, baseScore) = _bestMatch(document, normalized, tokens);
      final score = baseScore + (allTokens ? 500 : matchedCount * 15);
      results.add(NotebookSearchResult(
        document: document,
        score: score,
        matchKind: kind,
        snippet: _snippet(document, tokens),
      ));
    }
    results.sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score != 0 ? score : a.entry.title.compareTo(b.entry.title);
    });
    return results;
  }

  static (NotebookSearchMatchKind, int) _bestMatch(
    NotebookSearchDocument document,
    String query,
    List<String> tokens,
  ) {
    final title = document.normalizedTitle;
    if (title == query ||
        normalizeNotebookSearchText(document.entry.title) == query ||
        normalizeNotebookSearchText(document.entry.discoveryTitle) == query) {
      return (NotebookSearchMatchKind.title, 1000);
    }
    if (title.startsWith(query)) return (NotebookSearchMatchKind.title, 900);
    if (title.contains(query)) return (NotebookSearchMatchKind.title, 800);
    final ranked = [
      (NotebookSearchMatchKind.chapter, document.normalizedChapter, 620),
      (NotebookSearchMatchKind.section, document.normalizedSection, 600),
      (NotebookSearchMatchKind.concept, document.normalizedConcept, 580),
      (NotebookSearchMatchKind.example, document.normalizedExample, 560),
      (NotebookSearchMatchKind.body, document.normalizedBody, 300),
    ];
    for (final field in ranked) {
      if (field.$2.contains(query)) return (field.$1, field.$3);
    }
    final titleTokenCount = tokens.where(title.contains).length;
    if (titleTokenCount > 0) {
      return (NotebookSearchMatchKind.title, 700 + titleTokenCount * 10);
    }
    for (final field in ranked) {
      final count = tokens.where(field.$2.contains).length;
      if (count > 0) return (field.$1, field.$3 - 100 + count * 10);
    }
    return (NotebookSearchMatchKind.body, 1);
  }

  static String _snippet(NotebookSearchDocument document, List<String> tokens) {
    final source = document.snippetSources
        .firstWhere(
          (candidate) {
            final normalized = normalizeNotebookSearchText(candidate);
            return tokens.any(normalized.contains);
          },
          orElse: () => document.entry.summary,
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (source.length <= 150) return source;
    final normalizedSource = normalizeNotebookSearchText(source);
    final firstMatch = tokens
        .map(normalizedSource.indexOf)
        .where((index) => index >= 0)
        .fold<int>(source.length, (best, index) => index < best ? index : best);
    final start = (firstMatch - 35).clamp(0, source.length - 1);
    final end = (start + 145).clamp(0, source.length);
    return '${start > 0 ? '…' : ''}${source.substring(start, end).trim()}'
        '${end < source.length ? '…' : ''}';
  }

  static bool _isRotation(SelectedGateType type) =>
      type == SelectedGateType.rx ||
      type == SelectedGateType.ry ||
      type == SelectedGateType.rz;

  static NotebookSearchAuditReport audit({
    required Iterable<NotebookEntry> entries,
    required Iterable<ExecutableNotebookExample> executableExamples,
  }) {
    final errors = <String>[];
    final entryList = entries.toList();
    final exampleList = executableExamples.toList();
    final ids = <String>{};
    final discoveryIds = <String>{};
    final discoveries = {for (final entry in entryList) entry.discoveryTitle};
    final exampleIds = {for (final example in exampleList) example.id};
    for (final entry in entryList) {
      if (!ids.add(entry.id)) {
        errors.add('Duplicate Notebook search ID: ${entry.id}');
      }
      if (!discoveryIds.add(entry.discoveryTitle)) {
        errors
            .add('Duplicate Notebook discovery title: ${entry.discoveryTitle}');
      }
      if (entry.id.trim().isEmpty) {
        errors.add('Notebook entry has an empty search ID.');
      }
      if (entry.title.trim().isEmpty) {
        errors.add('${entry.id} has an empty title.');
      }
      for (final reference in entry.executableExampleIds) {
        if (!exampleIds.contains(reference)) {
          errors.add(
              '${entry.id} references unknown executable example $reference.');
        }
      }
      for (final reference in entry.relatedDiscoveryTitles) {
        if (!discoveries.contains(reference)) {
          errors
              .add('${entry.id} references unknown Notebook entry $reference.');
        }
      }
    }
    final seenExamples = <String>{};
    for (final example in exampleList) {
      if (!seenExamples.add(example.id)) {
        errors.add('Duplicate executable example ID: ${example.id}');
      }
      final concept = example.relatedConcept;
      if (concept == null || !discoveries.contains(concept)) {
        errors
            .add('${example.id} references unknown Notebook concept $concept.');
      }
      if (!entryList
          .any((entry) => entry.executableExampleIds.contains(example.id))) {
        errors.add('${example.id} is not attached to a Notebook entry.');
      }
    }
    try {
      final index = NotebookSearchIndex.build(
        entries: entryList,
        executableExamples: exampleList,
      );
      if (index.documents.length != entryList.length) {
        errors.add('Not every Notebook entry was indexed.');
      }
    } catch (error) {
      errors.add('Notebook indexing failed: $error');
    }
    return NotebookSearchAuditReport(errors: List.unmodifiable(errors));
  }
}

String normalizeNotebookSearchText(String value) => value
    .toLowerCase()
    .replaceAll('⟩', '>')
    .replaceAll('⟨', '<')
    .replaceAll(RegExp(r'[^a-z0-9+<>]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
