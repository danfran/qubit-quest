import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/notebook_knowledge_base.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/circuit_preview.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart'
    show plainGateText;
import 'package:quantumquiz/widgets/composer_workspace/gate_inspector_panel.dart'
    show gateEducationalPreviewFootprint;
import 'package:quantumquiz/widgets/gate_educational_sections.dart';
import 'package:quantumquiz/widgets/gate_educational_visual.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/notebook_typography.dart';
import 'package:quantumquiz/widgets/qubit_quest_workspace_primitives.dart';
import 'package:quantumquiz/widgets/qq_scientific_primitives.dart';
import 'package:quantumquiz/widgets/state_amplitude_panel.dart'
    show QqStateExpression;

/// How a Notebook article is presented (v2.6 M11E). Both are views of the
/// same ordered [NotebookBlock] list, never separate copies of the content.
enum NotebookReadingMode { article, spread }

/// Which page of a spread a block belongs to. [explanation] is the left
/// page (concepts, intuition, links), [evidence] the right page
/// (mathematics, circuits, experiments). [footer] spans both.
enum NotebookPage { explanation, evidence, footer }

/// One unit of an article. Article mode shows every block in list order;
/// Spread mode shows the [NotebookPage.explanation] blocks on the left and
/// the [NotebookPage.evidence] blocks on the right, each in list order.
class NotebookBlock {
  const NotebookBlock({
    required this.id,
    required this.page,
    required this.child,
    this.tocTitle,
    this.spreadCaption,
    this.marginWhenAvailable = false,
    this.marginChild,
  });

  /// The block as the margin shows it (compact heading).
  final Widget? marginChild;

  /// Stable within an article (tests compare Article and Spread by it).
  final String id;
  final NotebookPage page;
  final Widget child;

  /// Entry in "On this page"; null for blocks that are not destinations.
  final String? tocTitle;

  /// In Spread, names the section an evidence block belongs to when it is
  /// no longer directly under that section's text.
  final String? spreadCaption;

  /// Moves into the contextual margin when one is shown (Article mode on
  /// wide screens), so the margin never repeats the main column.
  final bool marginWhenAvailable;
}

/// Article area width from which a two-page spread is offered.
const double notebookSpreadMinWidth = 1000;

/// Article area width from which the contextual margin column is shown.
const double notebookMarginMinWidth = 1040;

/// Whether [article] can be read as a spread in an area [width] wide. The
/// notation reference is a glossary and always reads as one column.
bool notebookSpreadAvailable(NotebookArticle article, double width) =>
    article.kind != NotebookArticleKind.reference &&
    width >= notebookSpreadMinWidth;

/// The reader: article or spread, with the contextual margin when there is
/// room. The scroll view carries `web-notebook-reader-<id>`.
class NotebookArticleView extends StatefulWidget {
  const NotebookArticleView({
    super.key,
    required this.kb,
    required this.article,
    required this.unlocked,
    required this.progress,
    required this.mode,
    required this.showBack,
    required this.onBack,
    required this.onSelect,
    required this.onExplore,
    required this.onOpenInBloch,
    required this.onOpenJourney,
    required this.onOpenLesson,
    required this.onOpenChallenge,
  });

  final NotebookKnowledgeBase kb;
  final NotebookArticle article;
  final Set<String> unlocked;
  final CampaignProgressState progress;

  /// The preferred mode; Spread falls back to Article where it does not fit.
  final NotebookReadingMode mode;
  final bool showBack;
  final VoidCallback onBack;
  final ValueChanged<String> onSelect;
  final ValueChanged<ExecutableNotebookExample> onExplore;
  final void Function(ExecutableNotebookExample, ExecutableNotebookResult)?
      onOpenInBloch;
  final VoidCallback onOpenJourney;
  final ValueChanged<int>? onOpenLesson;
  final ValueChanged<String>? onOpenChallenge;

  @override
  State<NotebookArticleView> createState() => _NotebookArticleViewState();
}

class _NotebookArticleViewState extends State<NotebookArticleView> {
  final Map<String, GlobalKey> _anchors = {};

  GlobalKey _anchor(String id) =>
      _anchors.putIfAbsent(id, () => GlobalKey(debugLabel: 'nb-$id'));

  void _jumpTo(String id) {
    final context = _anchors[id]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(context,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final composer = _ArticleComposer(
      kb: w.kb,
      article: w.article,
      unlocked: w.unlocked,
      progress: w.progress,
      onSelect: w.onSelect,
      onExplore: w.onExplore,
      onOpenInBloch: w.onOpenInBloch,
      onOpenJourney: w.onOpenJourney,
      onOpenLesson: w.onOpenLesson,
      onOpenChallenge: w.onOpenChallenge,
    );
    final blocks = composer.blocks();
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final narrow = width < 600;
      final gutter = narrow ? 16.0 : 32.0;
      final spread = w.mode == NotebookReadingMode.spread &&
          notebookSpreadAvailable(w.article, width) &&
          composer.available;
      final margin = !spread && width >= notebookMarginMinWidth;
      final back = w.showBack
          ? Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('web-notebook-back-index'),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4)),
                onPressed: w.onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Notebook index'),
              ),
            )
          : null;

      Widget anchored(NotebookBlock b, {bool caption = false}) => KeyedSubtree(
            key: _anchor(b.id),
            child: Column(
              key: ValueKey('notebook-block-${b.id}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (caption && b.spreadCaption != null) ...[
                  QqPanelLabel(b.spreadCaption!,
                      color: QubitQuestColors.textMuted),
                  const SizedBox(height: 6),
                ],
                b.child,
              ],
            ),
          );

      List<Widget> stack(Iterable<NotebookBlock> list, {bool caption = false}) {
        final out = <Widget>[];
        for (final (i, b) in list.indexed) {
          if (i > 0) out.add(const SizedBox(height: 36));
          out.add(anchored(b, caption: caption));
        }
        return out;
      }

      final Widget content;
      Widget? marginColumn;
      if (spread) {
        final left = blocks.where((b) => b.page == NotebookPage.explanation);
        final right = blocks.where((b) => b.page == NotebookPage.evidence);
        final footer = blocks.where((b) => b.page == NotebookPage.footer);
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Spread(
              left: [
                const _Folio('Explanation'),
                ...stack(left),
              ],
              right: [
                const _Folio('Mathematics and experiment'),
                ...stack(right, caption: true),
              ],
            ),
            for (final b in footer) ...[
              const SizedBox(height: 24),
              anchored(b),
            ],
          ],
        );
      } else {
        final shown =
            margin ? blocks.where((b) => !b.marginWhenAvailable) : blocks;
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: stack(shown),
        );
        if (margin) {
          marginColumn = _MarginColumn(
            key: const ValueKey('web-notebook-margin'),
            toc: [
              for (final b in blocks)
                if (b.tocTitle != null && !b.marginWhenAvailable)
                  (b.id, b.tocTitle!),
            ],
            onJump: _jumpTo,
            used: [
              for (final b in blocks)
                if (b.marginWhenAvailable) b.marginChild ?? b.child,
            ],
            showNotationLink: w.article.kind != NotebookArticleKind.reference,
            onOpenNotation: () => w.onSelect(notebookNotationArticleId),
          );
        }
      }

      // Layout: the reading column (or the book) is centred in the area;
      // with a margin, column and margin are centred together and the
      // margin stays in place while the article scrolls.
      const marginWidth = 248.0;
      const marginGap = 48.0;
      final columnWidth = spread
          ? math.min(1440.0, width - 2 * gutter)
          : math.min(QqReading.measure, width - 2 * gutter);
      final group = columnWidth + (margin ? marginGap + marginWidth : 0);
      final left = math.max(gutter, (width - group) / 2);
      final list = ListView(
        key: ValueKey('web-notebook-reader-${w.article.id}'),
        padding: EdgeInsets.fromLTRB(
            left, narrow ? 12 : 28, width - left - columnWidth, 56),
        children: [
          if (back != null) ...[back, const SizedBox(height: 6)],
          content,
        ],
      );
      if (marginColumn == null) return list;
      return Stack(
        children: [
          Positioned.fill(child: list),
          Positioned(
            left: left + columnWidth + marginGap,
            width: marginWidth,
            top: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 36, 0, 24),
              child: marginColumn,
            ),
          ),
        ],
      );
    });
  }
}

/// Builds an article's blocks from its authored content, in reading order.
class _ArticleComposer {
  _ArticleComposer({
    required this.kb,
    required this.article,
    required this.unlocked,
    required this.progress,
    required this.onSelect,
    required this.onExplore,
    required this.onOpenInBloch,
    required this.onOpenJourney,
    required this.onOpenLesson,
    required this.onOpenChallenge,
  });

  final NotebookKnowledgeBase kb;
  final NotebookArticle article;
  final Set<String> unlocked;
  final CampaignProgressState progress;
  final ValueChanged<String> onSelect;
  final ValueChanged<ExecutableNotebookExample> onExplore;
  final void Function(ExecutableNotebookExample, ExecutableNotebookResult)?
      onOpenInBloch;
  final VoidCallback onOpenJourney;
  final ValueChanged<int>? onOpenLesson;
  final ValueChanged<String>? onOpenChallenge;

  bool get available => kb.isAvailable(article, unlocked);

  bool _lessonUnlocked(int id) => ProgressionRules.isJourneyLessonUnlocked(
      lessonId: id, maxUnlockedLevel: progress.maxUnlockedLevel);

  List<NotebookBlock> blocks() {
    final header = NotebookBlock(
      id: 'header',
      page: NotebookPage.explanation,
      child: _header(),
    );
    if (!available) {
      return [
        header,
        NotebookBlock(
          id: 'locked',
          page: NotebookPage.explanation,
          child: _LockedPreview(
            link: kb.lessonFor(article),
            lessonUnlocked: _lessonUnlocked,
            onOpenLesson: onOpenLesson,
            onOpenJourney: onOpenJourney,
          ),
        ),
      ];
    }
    return [
      header,
      ...switch (article.kind) {
        NotebookArticleKind.reference => _referenceBlocks(),
        NotebookArticleKind.gate => _gateBlocks(article.gate!),
        NotebookArticleKind.discovery => _discoveryBlocks(article.entry!),
      },
      ..._experimentBlocks(),
      if (article.entry?.advancedNotes case final notes?)
        NotebookBlock(
          id: 'advanced',
          page: NotebookPage.explanation,
          tocTitle: notes.title,
          child: _AdvancedNotes(section: notes),
        ),
      if (_related() case final related?)
        NotebookBlock(
          id: 'related',
          page: NotebookPage.explanation,
          tocTitle: 'Related',
          child: related,
        ),
      if (_activities() case final activities?)
        NotebookBlock(
          id: 'activities',
          page: NotebookPage.explanation,
          tocTitle: 'Where it is used',
          marginWhenAvailable: true,
          marginChild: _activities(margin: true),
          child: activities,
        ),
      if (article.kind == NotebookArticleKind.discovery)
        if (_prevNext() case final nav?)
          NotebookBlock(id: 'prev-next', page: NotebookPage.footer, child: nav),
    ];
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _header() {
    final category = kb.categoryOf(article);
    final position = category.articles.indexOf(article) + 1;
    final context = switch (article.kind) {
      NotebookArticleKind.reference => 'Notebook · Notation and terminology',
      NotebookArticleKind.gate => 'Notebook · Gate reference',
      NotebookArticleKind.discovery => '${category.title} · Discovery '
          '$position of ${category.articles.length}',
    };
    final gate = article.gate;
    final lead = gate != null ? gate.intuition : article.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context,
            key: const ValueKey('web-notebook-article-category'),
            style: QqType.breadcrumb),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(article.title,
              key: const ValueKey('web-notebook-entry-title'),
              style: QqType.pageTitle),
        ),
        if (available) ...[
          const SizedBox(height: 12),
          _Prose(lead,
              key: const ValueKey('web-notebook-article-summary'),
              style: QqReading.lead),
        ],
      ],
    );
  }

  // ── Discoveries ────────────────────────────────────────────────────────

  List<NotebookBlock> _discoveryBlocks(NotebookEntry entry) {
    final sections = [
      entry.intuition,
      if (entry.whatChanged != null) entry.whatChanged!,
      if (entry.quantumView != null) entry.quantumView!,
    ];
    return [
      for (final section in sections) ...[
        NotebookBlock(
          id: 'section-${section.title}',
          // What changed? is the observed change: it sits with its
          // evidence on the right page of a spread (M11B §8).
          page: identical(section, entry.whatChanged)
              ? NotebookPage.evidence
              : NotebookPage.explanation,
          tocTitle: section.title,
          child: _Section(
            key: ValueKey('web-notebook-section-${section.title}'),
            title: section.title,
            body: section.body,
          ),
        ),
        if (section.examples.isNotEmpty)
          NotebookBlock(
            id: 'examples-${section.title}',
            page: NotebookPage.evidence,
            spreadCaption:
                identical(section, entry.whatChanged) ? null : section.title,
            child: NotebookExampleWell(
              key: ValueKey('web-notebook-examples-${section.title}'),
              examples: section.examples,
            ),
          ),
      ],
    ];
  }

  // ── Notation and terminology ───────────────────────────────────────────

  List<NotebookBlock> _referenceBlocks() {
    final entry = article.entry!;
    return [
      for (final section in [
        entry.intuition,
        if (entry.whatChanged != null) entry.whatChanged!,
        if (entry.quantumView != null) entry.quantumView!,
      ])
        NotebookBlock(
          id: 'section-${section.title}',
          page: NotebookPage.explanation,
          tocTitle: section.title,
          child: Column(
            key: ValueKey('web-notebook-section-${section.title}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Heading(section.title),
              const SizedBox(height: 8),
              _Prose(section.body),
              const SizedBox(height: 14),
              _Glossary(examples: section.examples),
            ],
          ),
        ),
      const NotebookBlock(
        id: 'conventions',
        page: NotebookPage.explanation,
        tocTitle: 'Conventions',
        child: _Conventions(),
      ),
    ];
  }

  // ── Gate reference ─────────────────────────────────────────────────────

  List<NotebookBlock> _gateBlocks(GateEducationalInfo info) {
    final controlled = isControlledEducationalVisual(info.visual.kind);
    final facts = <(String, Widget)>[
      ('Symbol', Text(gateSymbol(info.type), style: QqType.bodyStrong)),
      ('Qubits', Text(_qubitRoles(info.type))),
      if (_parameter(info.type) case final p?) ('Parameter', Text(p)),
      if (info.axis case final axis?) ('Rotation axis', Text(axis)),
    ];
    return [
      NotebookBlock(
        id: 'gate-overview',
        page: NotebookPage.explanation,
        tocTitle: 'Overview',
        child: Column(
          key: const ValueKey('web-notebook-gate-reference'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Heading('Overview'),
            const SizedBox(height: 12),
            QqFactList(facts: facts, labelWidth: 120),
            if (info.commonUse.isNotEmpty) ...[
              const SizedBox(height: 18),
              const _Subheading('Common use'),
              const SizedBox(height: 4),
              _Prose(info.commonUse),
            ],
          ],
        ),
      ),
      NotebookBlock(
        id: 'gate-behaviour',
        page: NotebookPage.explanation,
        tocTitle: 'Behaviour',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Heading('Behaviour'),
            const SizedBox(height: 10),
            if (info.physicalChange.isNotEmpty) ...[
              const _Subheading('What changes'),
              const SizedBox(height: 4),
              _Prose(info.physicalChange),
            ],
            if (info.keyIdeas.isNotEmpty) ...[
              const SizedBox(height: 18),
              const _Subheading('Key ideas'),
              const SizedBox(height: 6),
              _Bullets(
                  key: const ValueKey('web-notebook-gate-key-ideas'),
                  values: info.keyIdeas),
            ],
          ],
        ),
      ),
      NotebookBlock(
        id: 'gate-action',
        page: NotebookPage.evidence,
        spreadCaption: 'Behaviour',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (info.transformations.isNotEmpty) ...[
              const _Subheading('Action on basis states'),
              const SizedBox(height: 8),
              QqMathWell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, t) in info.transformations.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                        child: _DisplayMath(t,
                            key: ValueKey('web-notebook-gate-state-$i')),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const _Subheading('Circuit symbol'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: SizedBox(
                  width: double.infinity,
                  child: GateEducationalVisualView(
                    key: const ValueKey('web-notebook-gate-visual'),
                    visual: info.visual,
                    footprint: gateEducationalPreviewFootprint(info.type),
                    height: 170,
                  ),
                ),
              ),
            ),
            if (controlled) ...[
              const SizedBox(height: 6),
              const Text(controlledGateBlochNote, style: QqType.meta),
            ],
          ],
        ),
      ),
      NotebookBlock(
        id: 'gate-math',
        page: NotebookPage.evidence,
        tocTitle: 'Mathematics',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Heading('Mathematics'),
            const SizedBox(height: 12),
            _Subheading(_sentenceCase(mathDefinitionHeading(info.matrix))),
            const SizedBox(height: 8),
            QqMathWell(
              child: Align(
                alignment: Alignment.centerLeft,
                child: GateEducationalMatrix(
                  latexKey: const ValueKey('web-notebook-gate-matrix'),
                  matrix: info.matrix,
                  mathFontSize: 21,
                ),
              ),
            ),
            if (info.type == SelectedGateType.mcx) ...[
              const SizedBox(height: 6),
              const Text(
                'Written as the rule on the target; the controls are '
                'unchanged. The full matrix is 2ⁿ × 2ⁿ.',
                style: QqType.meta,
              ),
            ],
            if (info.properties.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _Subheading('Properties'),
              const SizedBox(height: 6),
              _Bullets(
                  key: const ValueKey('web-notebook-gate-properties'),
                  values: info.properties),
            ],
            if (info.identities.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _Subheading('Identities'),
              const SizedBox(height: 8),
              QqMathWell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, t) in info.identities.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                        child: _DisplayMath(t,
                            key: ValueKey('web-notebook-gate-identity-$i')),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  static String _sentenceCase(String upper) =>
      upper[0] + upper.substring(1).toLowerCase();

  /// The number and roles of participating qubits, from the gate's own
  /// definition (no new content: the same facts the catalogue states).
  static String _qubitRoles(SelectedGateType type) => switch (type) {
        SelectedGateType.cnot ||
        SelectedGateType.cy =>
          '2 · one control, one target',
        SelectedGateType.cz =>
          '2 · symmetric: either qubit can be read as the control',
        SelectedGateType.ccnot => '3 · two controls, one target',
        SelectedGateType.mcx => '4 or 5 · three or four controls, one target',
        _ => '1',
      };

  static String? _parameter(SelectedGateType type) => switch (type) {
        SelectedGateType.rx ||
        SelectedGateType.ry ||
        SelectedGateType.rz =>
          'Rotation angle θ',
        _ => null,
      };

  // ── Experiments ────────────────────────────────────────────────────────

  List<NotebookBlock> _experimentBlocks() {
    final examples = [
      for (final id in article.exampleIds)
        if (notebookExampleById(id) case final e?) e,
    ];
    if (examples.isEmpty) return const [];
    return [
      NotebookBlock(
        id: 'experiments',
        page: NotebookPage.evidence,
        tocTitle: examples.length == 1 ? 'Experiment' : 'Experiments',
        child: Column(
          key: const ValueKey('web-notebook-experiments'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Heading(examples.length == 1 ? 'Experiment' : 'Experiments'),
            const SizedBox(height: 12),
            for (final (i, example) in examples.indexed) ...[
              if (i > 0) const SizedBox(height: 16),
              NotebookExperimentFigure(
                key: ValueKey('notebook-example-card-${example.id}'),
                example: example,
                onExplore: () => onExplore(example),
                onOpenInBloch: onOpenInBloch,
              ),
            ],
          ],
        ),
      ),
    ];
  }

  // ── Related knowledge ──────────────────────────────────────────────────

  Widget? _related() {
    final related = kb.relatedArticles(article);
    final lesson = kb.lessonFor(article);
    final lessonGates = lesson == null
        ? const <NotebookArticle>[]
        : kb.gateArticlesFor(lesson.level);
    final articles = [
      ...related,
      for (final g in lessonGates)
        if (!related.contains(g)) g,
    ];
    if (articles.isEmpty) return null;
    return Column(
      key: const ValueKey('web-notebook-related'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Heading('Related'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in articles)
              _ReferenceChip(
                key: ValueKey('web-notebook-related-${a.id}'),
                article: a,
                available: kb.isAvailable(a, unlocked),
                onTap: () => onSelect(a.id),
              ),
          ],
        ),
      ],
    );
  }

  Widget? _activities({bool margin = false}) {
    final rows = <Widget>[];
    if (kb.lessonFor(article) case final lesson?) {
      final open = _lessonUnlocked(lesson.lessonId);
      final done = progress.completedLessonIds.contains(lesson.lessonId);
      rows.add(_ActivityRow(
        key: const ValueKey('web-notebook-activity-lesson'),
        icon: Icons.route_outlined,
        title: '${lesson.label} · ${lesson.level.title ?? ''}',
        status: done
            ? 'Completed'
            : open
                ? 'Available in the Journey'
                : 'Locked in the Journey',
        actionLabel: done ? 'Review' : 'Open',
        onAction: open && onOpenLesson != null
            ? () => onOpenLesson!(lesson.lessonId)
            : null,
      ));
    }
    if (article.gate case final info?) {
      final type = info.type;
      final lessons = kb.journeyLessonsUsing(type);
      if (lessons.isNotEmpty) {
        final first = lessons.first;
        final chapter = journeyChapterForLesson(first);
        final number = chapter == null
            ? ''
            : 'Lesson ${journeyChapters.indexOf(chapter) + 1}.'
                '${first - chapter.from}';
        final open = _lessonUnlocked(first);
        rows.add(_ActivityRow(
          key: const ValueKey('web-notebook-activity-journey-first'),
          icon: Icons.route_outlined,
          title: 'First used in $number · '
              '${getJourneyLessonById(first)?.title ?? ''}',
          status: '${lessons.length} Journey lesson'
              '${lessons.length == 1 ? ' uses' : 's use'} '
              '${gateSymbol(type)}${open ? '' : ' · locked'}',
          actionLabel: 'Open',
          onAction:
              open && onOpenLesson != null ? () => onOpenLesson!(first) : null,
        ));
      }
      for (final c in kb.masteryChallengesUsing(type).take(4)) {
        rows.add(_ActivityRow(
          key: ValueKey('web-notebook-activity-mastery-${c.semanticId}'),
          icon: Icons.workspace_premium_outlined,
          title: 'Mastery ${c.displayOrder} · ${c.title}',
          status: progress.completedMasterySemanticIds.contains(c.semanticId)
              ? 'Completed'
              : 'Open any time',
          actionLabel: 'Open',
          onAction: onOpenChallenge == null
              ? null
              : () => onOpenChallenge!(c.semanticId),
        ));
      }
    }
    if (rows.isEmpty) return null;
    return Column(
      key: const ValueKey('web-notebook-activities'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (margin)
          const QqPanelLabel('Where it is used',
              color: QubitQuestColors.textMuted)
        else
          const _Heading('Where it is used'),
        const SizedBox(height: 6),
        ...rows,
      ],
    );
  }

  Widget? _prevNext() {
    final list = kb.categoryOf(article).articles;
    final index = list.indexOf(article);
    NotebookArticle? find(int step) {
      for (var i = index + step; i >= 0 && i < list.length; i += step) {
        if (kb.isAvailable(list[i], unlocked)) return list[i];
      }
      return null;
    }

    final previous = find(-1);
    final next = find(1);
    if (previous == null && next == null) return null;
    Widget link(NotebookArticle a, {required bool forward}) => _PageLink(
          key:
              ValueKey(forward ? 'web-notebook-next' : 'web-notebook-previous'),
          label: forward ? 'Next' : 'Previous',
          title: a.title,
          forward: forward,
          onTap: () => onSelect(a.id),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, color: QubitQuestSurfaces.rule),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: previous == null
                    ? const SizedBox.shrink()
                    : link(previous, forward: false)),
            const SizedBox(width: 12),
            Expanded(
                child: next == null
                    ? const SizedBox.shrink()
                    : link(next, forward: true)),
          ],
        ),
      ],
    );
  }
}

/// The ID of the notation reference (margin link target).
const String notebookNotationArticleId = 'notation_and_terms';

// ── Reading primitives ───────────────────────────────────────────────────

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text, style: QqType.sectionTitle),
      );
}

class _Subheading extends StatelessWidget {
  const _Subheading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: QqType.subheading.copyWith(fontSize: 15));
}

/// Explanatory prose. Authored inline TeX (`\( … \)`, used by the gate
/// catalogue) is typeset; plain authored notation (|ψ⟩, √2, ⊗) is shown as
/// written, in Inter with the maths-symbol fallback.
class _Prose extends StatelessWidget {
  const _Prose(this.text, {super.key, this.style = QqReading.body});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (text.contains(r'\(') || text.contains(r'\[')) {
      return LatexText(
        math: text,
        textStyle: style,
        inlineMathColor: QubitQuestColors.textPrimary,
        mathFontSize: (style.fontSize ?? 16) + .5,
      );
    }
    return Text(formatQuantumNotationForPlainText(plainGateText(text)),
        style: style);
  }
}

/// A section: heading and paragraphs.
class _Section extends StatelessWidget {
  const _Section({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Heading(title),
          const SizedBox(height: 8),
          _Prose(body),
        ],
      );
}

class _Bullets extends StatelessWidget {
  const _Bullets({super.key, required this.values});
  final List<String> values;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, v) in values.indexed)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 11, right: 12),
                    child: SizedBox(
                      width: 5,
                      height: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: QubitQuestColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _Prose(v)),
                ],
              ),
            ),
        ],
      );
}

/// Displayed TeX from the gate catalogue (`\( … \)` or `\[ … \]`), at the
/// reading column's display size; wider than the column, it shrinks a
/// little and then scrolls inside its own region.
class _DisplayMath extends StatelessWidget {
  const _DisplayMath(this.tex, {super.key});
  final String tex;

  @override
  Widget build(BuildContext context) {
    var body = tex.trim();
    for (final (open, close) in const [(r'\(', r'\)'), (r'\[', r'\]')]) {
      if (body.startsWith(open) && body.endsWith(close)) {
        body = body.substring(2, body.length - 2);
      }
    }
    return LatexText(
      math: '\\[$body\\]',
      textStyle: QqType.math,
      mathFontSize: QqReading.displayMathSize,
      minimumDisplayMathScale: .85,
    );
  }
}

/// Authored examples of a section in one maths well: the label, the
/// expression (typeset by [NotebookMathEvidence]) or the authored text, and
/// the explanation. Comparison groups sit side by side when there is room.
class NotebookExampleWell extends StatelessWidget {
  const NotebookExampleWell({super.key, required this.examples});
  final List<NotebookExample> examples;

  @override
  Widget build(BuildContext context) {
    final groups = <List<NotebookExample>>[];
    for (final e in examples) {
      final group = e.comparisonGroup;
      if (group != null &&
          groups.isNotEmpty &&
          groups.last.first.comparisonGroup == group) {
        groups.last.add(e);
      } else {
        groups.add([e]);
      }
    }
    return QqMathWell(
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, group) in groups.indexed) ...[
              if (i > 0) const SizedBox(height: 16),
              if (group.length == 2 && constraints.maxWidth >= 460)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ExampleItem(example: group[0])),
                    const SizedBox(width: 24),
                    Expanded(child: _ExampleItem(example: group[1])),
                  ],
                )
              else
                for (final (j, e) in group.indexed) ...[
                  if (j > 0) const SizedBox(height: 16),
                  _ExampleItem(example: e),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ExampleItem extends StatelessWidget {
  const _ExampleItem({required this.example});
  final NotebookExample example;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(example.label,
              style: QqType.meta.copyWith(
                  color: QubitQuestColors.accentInteractive,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          if (example.presentation == NotebookExamplePresentation.math)
            NotebookMathEvidence(
              example: example,
              color: QubitQuestColors.textPrimary,
              mathFontSize: example.mathRole == NotebookMathRole.emphasis
                  ? QqReading.displayMathSize + 3
                  : QqReading.displayMathSize,
              alignStart: true,
            )
          else
            Text(formatQuantumNotationForPlainText(example.notation),
                style: QqType.math.copyWith(fontSize: 17)),
          if ((example.explanation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(formatQuantumNotationForPlainText(example.explanation!),
                style: QqType.meta
                    .copyWith(color: QubitQuestColors.textBody, fontSize: 14)),
          ],
        ],
      );
}

/// The notation reference as a glossary: the term, then its symbol and
/// definition. Two columns when there is room.
class _Glossary extends StatelessWidget {
  const _Glossary({required this.examples});
  final List<NotebookExample> examples;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 520;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in examples)
                _GlossaryRow(example: e, columns: columns),
            ],
          );
        },
      );
}

class _GlossaryRow extends StatelessWidget {
  const _GlossaryRow({required this.example, required this.columns});
  final NotebookExample example;
  final bool columns;

  @override
  Widget build(BuildContext context) {
    final math = example.presentation == NotebookExamplePresentation.math;
    final definition = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (math)
          NotebookMathEvidence(
            example: example,
            color: QubitQuestColors.textPrimary,
            mathFontSize: QqReading.displayMathSize,
            alignStart: true,
          )
        else
          Text(formatQuantumNotationForPlainText(example.notation),
              style: QqReading.body),
        if ((example.explanation ?? '').trim().isNotEmpty)
          Text(formatQuantumNotationForPlainText(example.explanation!),
              style: QqReading.body),
      ],
    );
    final term = Text(example.label, style: QqReading.term);
    return Container(
      key: ValueKey('web-notebook-term-${example.label}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: QubitQuestSurfaces.rule)),
      ),
      child: columns
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 168,
                    child: Padding(
                        padding: EdgeInsets.only(top: math ? 6 : 1),
                        child: term)),
                const SizedBox(width: 16),
                Expanded(child: definition),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [term, const SizedBox(height: 2), definition],
            ),
    );
  }
}

/// Conventions used throughout Qubit Quest that the glossary terms rely on:
/// qubit order in kets, and what is (and is not) observable.
class _Conventions extends StatelessWidget {
  const _Conventions();

  @override
  Widget build(BuildContext context) => const Column(
        key: ValueKey('web-notebook-conventions'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Heading('Conventions'),
          SizedBox(height: 8),
          Text(notebookBasisOrderNote, style: QqReading.body),
          SizedBox(height: 8),
          Text(notebookPhaseNote, style: QqReading.body),
        ],
      );
}

/// The app's basis order (named_state_recognition, circuit_executor).
const String notebookBasisOrderNote =
    'Kets list qubits from the highest number to q0: in |q2 q1 q0⟩, q0 is '
    'the rightmost symbol and the top wire of a circuit. Probabilities are '
    'listed in the same order, from |0…0⟩ upward.';

/// Phase wording shared by the notation reference.
const String notebookPhaseNote =
    'States are written exactly as the simulator prepares them, including '
    'any global phase. A global phase does not change any prediction; a '
    'relative phase between amplitudes can.';

class _AdvancedNotes extends StatelessWidget {
  const _AdvancedNotes({required this.section});
  final NotebookSection section;

  @override
  Widget build(BuildContext context) => QqDisclosure(
        key: const ValueKey('web-notebook-advanced-notes'),
        toggleKey: const ValueKey('web-notebook-advanced-toggle'),
        title: section.title,
        summary: section.examples.isEmpty
            ? 'Formal details'
            : 'Formal details and ${section.examples.length} '
                'example${section.examples.length == 1 ? '' : 's'}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Prose(section.body),
            if (section.examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              NotebookExampleWell(
                key: const ValueKey('web-notebook-examples-advanced'),
                examples: section.examples,
              ),
            ],
          ],
        ),
      );
}

class _Folio extends StatelessWidget {
  const _Folio(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: QqPanelLabel(text, color: QubitQuestColors.textMuted),
      );
}

/// Two pages on one book surface, with a fold between them. Each page has
/// its natural height; the pages scroll together.
class _Spread extends StatelessWidget {
  const _Spread({required this.left, required this.right});
  final List<Widget> left;
  final List<Widget> right;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('web-notebook-spread'),
        decoration: BoxDecoration(
          color: QubitQuestSurfaces.work2,
          borderRadius: QubitQuestRadii.panel,
          border: Border.all(color: QubitQuestSurfaces.rule),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final half = constraints.maxWidth / 2;
            Widget page(List<Widget> children, Key key) => Padding(
                  key: key,
                  padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                );
            return Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: page(
                            left, const ValueKey('web-notebook-page-left'))),
                    Expanded(
                        child: page(
                            right, const ValueKey('web-notebook-page-right'))),
                  ],
                ),
                Positioned(
                  left: half - .5,
                  top: 24,
                  bottom: 24,
                  child: const SizedBox(
                    width: 1,
                    child: ColoredBox(color: QubitQuestSurfaces.rule),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

/// The contextual margin: On this page, Where it is used (moved here from
/// the column) and the notation convention.
class _MarginColumn extends StatelessWidget {
  const _MarginColumn({
    super.key,
    required this.toc,
    required this.onJump,
    required this.used,
    required this.showNotationLink,
    required this.onOpenNotation,
  });

  final List<(String, String)> toc;
  final ValueChanged<String> onJump;
  final List<Widget> used;
  final bool showNotationLink;
  final VoidCallback onOpenNotation;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (toc.length > 1) ...[
            const QqPanelLabel('On this page',
                color: QubitQuestColors.textMuted),
            const SizedBox(height: 6),
            for (final (id, title) in toc)
              InkWell(
                key: ValueKey('web-notebook-toc-$id'),
                borderRadius: QubitQuestRadii.control,
                onTap: () => onJump(id),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Text(title,
                      style: QqType.navLabel.copyWith(
                          color: QubitQuestColors.textBody,
                          fontWeight: FontWeight.w400)),
                ),
              ),
            const SizedBox(height: 22),
          ],
          // "Where it is used" is the activities block itself, compact.
          for (final w in used) ...[
            DefaultTextStyle.merge(style: QqType.meta, child: w),
            const SizedBox(height: 22),
          ],
          if (showNotationLink) ...[
            const QqPanelLabel('Notation', color: QubitQuestColors.textMuted),
            const SizedBox(height: 6),
            const Text(notebookBasisOrderNote, style: QqType.meta),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('web-notebook-margin-notation'),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact),
                onPressed: onOpenNotation,
                child: const Text('Notation and terminology'),
              ),
            ),
          ],
        ],
      );
}

/// A related article as a reference link: gates, discoveries (locked ones
/// say so) and the notation guide each have their own mark.
class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({
    super.key,
    required this.article,
    required this.available,
    required this.onTap,
  });
  final NotebookArticle article;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gate = article.kind == NotebookArticleKind.gate;
    return Tooltip(
      message: available
          ? 'Open ${article.title}'
          : '${article.title} · not discovered yet',
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: QubitQuestSurfaces.work,
        shape: const StadiumBorder(
            side: BorderSide(color: QubitQuestColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  gate
                      ? Icons.memory_outlined
                      : available
                          ? Icons.auto_stories_outlined
                          : Icons.lock_outline,
                  size: 16,
                  color: gate
                      ? QubitQuestColors.accentInteractive
                      : available
                          ? QubitQuestColors.success
                          : QubitQuestColors.textMuted,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    gate ? 'Gate · ${article.title}' : article.title,
                    overflow: TextOverflow.ellipsis,
                    style: QqType.control.copyWith(
                        color: available
                            ? QubitQuestColors.textPrimary
                            : QubitQuestColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    required this.actionLabel,
    required this.onAction,
  });
  final IconData icon;
  final String title;
  final String status;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon,
                  size: 18,
                  color: onAction == null
                      ? QubitQuestColors.textMuted
                      : QubitQuestColors.accentInteractive),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: QqType.navLabel),
                  Text(status, style: QqType.navMeta),
                ],
              ),
            ),
            if (onAction != null)
              TextButton(
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: onAction,
                child: Text(actionLabel),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.lock_outline,
                    size: 16, color: QubitQuestColors.textMuted),
              ),
          ],
        ),
      );
}

class _PageLink extends StatelessWidget {
  const _PageLink({
    super.key,
    required this.label,
    required this.title,
    required this.forward,
    required this.onTap,
  });
  final String label;
  final String title;
  final bool forward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: QubitQuestRadii.control,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment:
                forward ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(forward ? '$label  ›' : '‹  $label', style: QqType.meta),
              const SizedBox(height: 2),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: forward ? TextAlign.right : TextAlign.left,
                  style: QqType.navLabel
                      .copyWith(color: QubitQuestColors.accentInteractive)),
            ],
          ),
        ),
      );
}

/// A discovery entry the learner has not reached: identity and how to reach
/// it, never its content.
class _LockedPreview extends StatelessWidget {
  const _LockedPreview({
    required this.link,
    required this.lessonUnlocked,
    required this.onOpenLesson,
    required this.onOpenJourney,
  });
  final NotebookLessonLink? link;
  final bool Function(int) lessonUnlocked;
  final ValueChanged<int>? onOpenLesson;
  final VoidCallback onOpenJourney;

  @override
  Widget build(BuildContext context) {
    final lesson = link;
    final open = lesson != null && lessonUnlocked(lesson.lessonId);
    return QqWorkspacePanel(
      key: const ValueKey('web-notebook-locked-preview'),
      label: 'Not discovered yet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson == null
                ? 'This entry is discovered in the Journey.'
                : 'This entry is discovered in ${lesson.label} · '
                    '${lesson.level.title}. '
                    '${open ? 'That lesson is open in your Journey.' : 'That lesson is still locked; continue the Journey to reach it.'}',
            style: QqReading.body,
          ),
          const SizedBox(height: 6),
          const Text(
            'Discovery entries describe what a lesson reveals, so they open '
            'once you make the discovery. The gate reference and notation are '
            'always available.',
            style: QqType.meta,
          ),
          const SizedBox(height: 14),
          if (open && onOpenLesson != null)
            FilledButton.icon(
              key: const ValueKey('web-notebook-locked-open-lesson'),
              onPressed: () => onOpenLesson!(lesson.lessonId),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text('Open ${lesson.label}'),
            )
          else
            OutlinedButton.icon(
              key: const ValueKey('web-notebook-go-journey'),
              onPressed: onOpenJourney,
              icon: const Icon(Icons.route_outlined, size: 18),
              label: const Text('Go to the Journey'),
            ),
        ],
      ),
    );
  }
}

/// An authored executable example as a figure: the circuit at its natural
/// size (long circuits scroll sideways), the state the real simulator
/// prepares, typeset like the Composer's current state, and Run in Composer.
class NotebookExperimentFigure extends StatefulWidget {
  const NotebookExperimentFigure({
    super.key,
    required this.example,
    required this.onExplore,
    required this.onOpenInBloch,
  });
  final ExecutableNotebookExample example;
  final VoidCallback onExplore;
  final void Function(ExecutableNotebookExample, ExecutableNotebookResult)?
      onOpenInBloch;

  @override
  State<NotebookExperimentFigure> createState() =>
      _NotebookExperimentFigureState();
}

class _NotebookExperimentFigureState extends State<NotebookExperimentFigure> {
  late QuantumCircuit _circuit = _build();

  QuantumCircuit _build() {
    final circuit =
        QuantumCircuit(currentLevel: widget.example.createExperimentLevel());
    circuit.runSimulation();
    return circuit;
  }

  @override
  void didUpdateWidget(covariant NotebookExperimentFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.example, widget.example)) {
      _circuit.dispose();
      _circuit = _build();
    }
  }

  @override
  void dispose() {
    _circuit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final example = widget.example;
    final vector = _circuit.currentState.stateVector;
    final n = example.qubitCount;
    final bloch = widget.onOpenInBloch != null &&
        example.supports(ExecutableNotebookCapability.blochExplorer);
    return Container(
      key: ValueKey('executable-example-${example.id}'),
      decoration: BoxDecoration(
        color: QubitQuestSurfaces.work,
        borderRadius: QubitQuestRadii.card,
        border: Border.all(color: QubitQuestSurfaces.rule),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(example.title, style: QqType.subjectTitle),
          const SizedBox(height: 4),
          Text(formatQuantumNotationForPlainText(example.description),
              style: QqType.body),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: QubitQuestSurfaces.inset,
              borderRadius: QubitQuestRadii.control,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              // Natural size: wires and gates keep the Composer's
              // geometry; a long circuit scrolls instead of shrinking.
              child: QubitQuestCircuitPreview(
                key: ValueKey('notebook-example-preview-${example.id}'),
                circuit: _circuit,
                minimumWidth: 200,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
              'Prepared state · $n qubit${n == 1 ? '' : 's'}, '
              'from |${example.initialBinaryState}⟩',
              style: QqType.meta),
          const SizedBox(height: 4),
          QqStateExpression(
            key: ValueKey('notebook-example-state-${example.id}'),
            terms: formatQuantumStateTerms(vector, numQubits: n),
            plainText: formatQuantumStateExpression(vector, numQubits: n),
            collapsedTermCount: 8,
            style: QqType.stateExpression.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tooltip(
                message: 'Opens this circuit in a Composer workspace of its '
                    'own. Your Sandbox circuit is not changed.',
                child: FilledButton.icon(
                  key: ValueKey('notebook-explore-${example.id}'),
                  onPressed: widget.onExplore,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Run in Composer'),
                ),
              ),
              if (bloch)
                OutlinedButton.icon(
                  key: ValueKey('bloch-example-${example.id}'),
                  onPressed: () =>
                      widget.onOpenInBloch!(example, example.execute()),
                  icon: const Icon(Icons.public, size: 18),
                  label: const Text('Open in Bloch Explorer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
