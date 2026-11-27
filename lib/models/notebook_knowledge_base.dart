import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/gate_reference_examples.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/notebook_search.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

/// What a Notebook article is built from. The knowledge base composes the
/// existing content; it never copies it (v2.6 M6b).
enum NotebookArticleKind {
  /// The always-available notation reference (`notation_and_terms`).
  reference,

  /// A gate from [GateEducationalCatalog]: general reference, the same
  /// material the Composer's gate inspector shows everywhere.
  gate,

  /// A discovery entry earned in a Journey lesson (`NotebookEntry`).
  discovery,
}

/// One article of the knowledge base.
@immutable
class NotebookArticle {
  const NotebookArticle._({
    required this.id,
    required this.kind,
    required this.title,
    required this.categoryId,
    required this.summary,
    required this.exampleIds,
    this.entry,
    this.gate,
  });

  /// Stable identifier, used by routes (`#/notebook/<id>`) and links:
  /// the entry ID for entries, `gate-<type>` for gates.
  final String id;
  final NotebookArticleKind kind;
  final String title;
  final String categoryId;
  final String summary;

  /// Executable examples shown as experiments in this article.
  final List<String> exampleIds;
  final NotebookEntry? entry;
  final GateEducationalInfo? gate;

  static String gateId(SelectedGateType type) => 'gate-${type.name}';
}

@immutable
class NotebookCategory {
  const NotebookCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.articles,
  });
  final String id;
  final String title;
  final String description;
  final List<NotebookArticle> articles;
}

/// A search hit over articles available to the learner.
@immutable
class NotebookSearchHit {
  const NotebookSearchHit(this.article, this.snippet, this.score);
  final NotebookArticle article;
  final String snippet;
  final int score;
}

/// The Journey lesson an article's discovery comes from.
@immutable
class NotebookLessonLink {
  const NotebookLessonLink({
    required this.lessonId,
    required this.chapterNumber,
    required this.position,
    required this.level,
  });
  final int lessonId;
  final int chapterNumber;

  /// 1-based position within the chapter ("Lesson 3.2").
  final int position;
  final QQLevel level;
  String get label => 'Lesson $chapterNumber.$position';
}

/// Optional video reference for a future release (architecture only: no UI,
/// no network). Articles have none in v2.6.
@immutable
class NotebookVideoReference {
  const NotebookVideoReference({
    required this.articleId,
    required this.title,
    required this.provider,
    this.videoId,
    this.url,
    this.purpose,
  }) : assert(videoId != null || url != null);
  final String articleId;
  final String title;
  final NotebookVideoProvider provider;
  final String? videoId;
  final String? url;

  /// E.g. "visual intuition", "worked derivation".
  final String? purpose;
}

enum NotebookVideoProvider { youtube, other }

/// Video references by article ID. Intentionally empty in v2.6.
const Map<String, List<NotebookVideoReference>> notebookVideoReferences = {};

/// Any Notebook example: a discovery-entry example or a gate-reference
/// example (v2.6 M7). IDs are unique across both catalogues (tested).
ExecutableNotebookExample? notebookExampleById(String id) =>
    executableNotebookExamplesById[id] ?? gateReferenceExamplesById[id];

/// Gate → the curated executable experiments that demonstrate it. Each ID
/// must resolve through [notebookExampleById] (tested).
const Map<SelectedGateType, List<String>> notebookGateExampleIds = {
  SelectedGateType.x: ['x_from_zero'],
  SelectedGateType.hadamard: ['h_superposition', 'hh_reversibility'],
  SelectedGateType.z: ['z_on_plus', 'interference_hzh'],
  SelectedGateType.s: ['s_on_plus'],
  SelectedGateType.t: ['t_on_plus'],
  SelectedGateType.ry: ['ry_rotation'],
  SelectedGateType.rz: ['rz_interference'],
  SelectedGateType.cnot: ['bell_phi_plus', 'ghz_three'],
  SelectedGateType.cy: [
    'cy_inactive_control',
    'cy_active_control',
    'cy_superposed_control',
    'cy_interference_comparison',
    'cy_twice',
    'cy_reversed_nonadjacent',
  ],
  SelectedGateType.mcx: [
    'mcx_all_controls_active',
    'mcx_one_inactive_control',
    'mcx_superposed_control',
    'mcx_coherent_and',
    'mcx_four_controls',
    'mcx_twice',
  ],
};

/// The Notebook as a knowledge base: categories, articles, availability,
/// search and relationships, all derived from existing content.
class NotebookKnowledgeBase {
  NotebookKnowledgeBase._(this.categories)
      : _byId = {
          for (final c in categories)
            for (final a in c.articles) a.id: a,
        };

  static final NotebookKnowledgeBase instance = NotebookKnowledgeBase._build();

  final List<NotebookCategory> categories;
  final Map<String, NotebookArticle> _byId;

  late final NotebookSearchIndex _entryIndex = NotebookSearchIndex.build(
    entries: notebookEntries,
    executableExamples: executableNotebookExamples,
  );

  factory NotebookKnowledgeBase._build() {
    NotebookArticle fromEntry(NotebookEntry e, String category) =>
        NotebookArticle._(
          id: e.id,
          kind: e.id == notebookReferenceEntryId
              ? NotebookArticleKind.reference
              : NotebookArticleKind.discovery,
          title: e.title,
          categoryId: category,
          summary: e.summary,
          exampleIds: e.executableExampleIds,
          entry: e,
        );
    final reference = notebookEntries
        .where((e) => e.id == notebookReferenceEntryId)
        .map((e) => fromEntry(e, 'reference'))
        .toList();
    final gates = [
      for (final type in GateEducationalCatalog.productionGateTypes)
        if (GateEducationalCatalog.forType(type) case final info?)
          NotebookArticle._(
            id: NotebookArticle.gateId(type),
            kind: NotebookArticleKind.gate,
            title: info.name,
            categoryId: 'gates',
            summary: info.intuition,
            exampleIds: notebookGateExampleIds[type] ?? const [],
            gate: info,
          ),
    ];
    final chapters = <int, List<NotebookEntry>>{};
    for (final e in notebookEntries) {
      if (e.id == notebookReferenceEntryId) continue;
      chapters.putIfAbsent(e.chapterIndex, () => []).add(e);
    }
    return NotebookKnowledgeBase._([
      if (reference.isNotEmpty)
        NotebookCategory(
          id: 'reference',
          title: 'Notation & terms',
          description: 'Recurring notation used throughout Qubit Quest.',
          articles: reference,
        ),
      NotebookCategory(
        id: 'gates',
        title: 'Gate reference',
        description: 'Every Composer gate: action, matrix and identities.',
        articles: gates,
      ),
      for (final MapEntry(key: index, value: entries) in chapters.entries)
        NotebookCategory(
          id: 'chapter-$index',
          title: entries.first.chapterTitle.replaceFirst(' - ', ' · '),
          description: entries.first.chapterIdentity,
          articles: [for (final e in entries) fromEntry(e, 'chapter-$index')],
        ),
    ]);
  }

  Iterable<NotebookArticle> get articles => _byId.values;
  NotebookArticle? byId(String id) => _byId[id];

  NotebookArticle? byDiscoveryTitle(String title) {
    final entry = notebookEntriesByDiscoveryTitle[title];
    return entry == null ? null : _byId[entry.id];
  }

  NotebookCategory categoryOf(NotebookArticle article) =>
      categories.firstWhere((c) => c.id == article.categoryId);

  /// Reference and gate articles are always readable. Discovery entries
  /// keep the existing rule: readable once discovered in the Journey (they
  /// describe a lesson's result, so opening them early would reveal it).
  bool isAvailable(NotebookArticle article, Set<String> unlockedTitles) =>
      article.kind != NotebookArticleKind.discovery ||
      isNotebookEntryAvailable(article.entry!, unlockedTitles);

  /// The Journey lesson whose discovery this entry is (stable link: the
  /// lesson's `discoveryTitle`).
  NotebookLessonLink? lessonFor(NotebookArticle article) {
    final entry = article.entry;
    if (article.kind != NotebookArticleKind.discovery || entry == null) {
      return null;
    }
    for (final (index, level) in journeyLessons.indexed) {
      if (level.discoveryTitle != entry.discoveryTitle) continue;
      final lessonId = index + 1;
      final chapter = journeyChapterForLesson(lessonId);
      if (chapter == null) return null;
      return NotebookLessonLink(
        lessonId: lessonId,
        chapterNumber: journeyChapters.indexOf(chapter) + 1,
        position: lessonId - chapter.from,
        level: level,
      );
    }
    return null;
  }

  /// Gate articles for the gates a lesson's circuit uses (its palette).
  List<NotebookArticle> gateArticlesFor(QQLevel level) => [
        if (level is ComposerLevel)
          for (final type in {
            for (final g in level.availableGates) g.type,
          })
            if (_byId[NotebookArticle.gateId(type)] case final a?) a,
      ];

  /// Other articles this one explicitly relates to (authored links).
  List<NotebookArticle> relatedArticles(NotebookArticle article) {
    final titles = <String>[
      ...?article.entry?.relatedDiscoveryTitles,
      if (article.gate?.notebookDiscoveryTitle case final t?) t,
      for (final c in article.gate?.relatedConcepts ?? const [])
        if (c.notebookDiscoveryTitle case final t?) t,
    ];
    final seen = <String>{article.id};
    return [
      for (final title in titles)
        if (byDiscoveryTitle(title) case final a? when seen.add(a.id)) a,
    ];
  }

  /// Circuit Mastery challenges whose palette uses [type] (independently
  /// accessible; showing the palette reveals nothing the challenge does not
  /// show on opening).
  List<MasteryChallengeDefinition> masteryChallengesUsing(
          SelectedGateType type) =>
      [
        for (final c in mastery2Catalogue.orderedDefinitions)
          if (c.levelDefinition case final ComposerLevel level
              when level.availableGates.any((g) => g.type == type))
            c,
      ];

  /// Journey lessons whose palette uses [type], or whose discovery the
  /// gate's catalogue names as a related concept (v2.6 M10: a lesson can
  /// feature a gate as a fixed operation, as Lesson 14.1 does with CY).
  List<int> journeyLessonsUsing(SelectedGateType type) {
    final info = GateEducationalCatalog.forType(type);
    final related = {
      for (final c in info?.relatedConcepts ?? const <GateRelatedConcept>[])
        if (c.notebookDiscoveryTitle case final t?) t,
    };
    return [
      for (final (index, level) in journeyLessons.indexed)
        if ((level is ComposerLevel &&
                level.availableGates.any((g) => g.type == type)) ||
            (related.contains(level.discoveryTitle) &&
                _isConditionalLogicDiscovery(level.discoveryTitle!)))
          index + 1,
    ];
  }

  static bool _isConditionalLogicDiscovery(String title) =>
      notebookEntriesByDiscoveryTitle[title]?.chapterIndex == 14;

  /// Search over the learner's available articles. Entries use the existing
  /// Notebook index (unlocked entries only); gate articles match their name,
  /// symbol and authored reference text.
  List<NotebookSearchHit> search(String query, Set<String> unlockedTitles) {
    final normalized = normalizeNotebookSearchText(query);
    if (normalized.isEmpty) return const [];
    final tokens = normalized.split(' ').where((t) => t.isNotEmpty).toList();
    final hits = <NotebookSearchHit>[
      for (final r in _entryIndex.search(query,
          allowedEntryIds: notebookSearchAllowedEntryIds(
              entries: notebookEntries,
              unlockedDiscoveryTitles: unlockedTitles)))
        if (_byId[r.entry.id] case final a?)
          NotebookSearchHit(a, r.snippet, r.score),
    ];
    for (final c in categories.where((c) => c.id == 'gates')) {
      for (final a in c.articles) {
        final info = a.gate!;
        final title = normalizeNotebookSearchText(
            '${info.name} ${info.type.name} ${gateSymbol(info.type)}');
        final body = normalizeNotebookSearchText([
          info.intuition,
          info.physicalChange,
          info.commonUse,
          ...info.properties,
          ...info.identities,
          ...info.transformations,
          for (final r in info.relatedConcepts) r.label,
        ].join(' '));
        if (!tokens.every((t) => title.contains(t) || body.contains(t))) {
          continue;
        }
        final score = tokens.every(title.contains) ? 1000 : 100;
        hits.add(NotebookSearchHit(a, info.intuition, score));
      }
    }
    hits.sort((x, y) => y.score.compareTo(x.score));
    return hits;
  }
}

/// Palette symbol of a gate type (X, H, CX, …), for search and labels.
String gateSymbol(SelectedGateType type) => switch (type) {
      SelectedGateType.hadamard => 'H',
      SelectedGateType.cnot => 'CX',
      SelectedGateType.ccnot => 'CCX',
      SelectedGateType.cz => 'CZ',
      SelectedGateType.rx => 'Rx',
      SelectedGateType.ry => 'Ry',
      SelectedGateType.rz => 'Rz',
      _ => type.name.toUpperCase(),
    };
