import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/notebook_knowledge_base.dart';
import 'package:quantumquiz/models/notebook_search.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/screens/journey_navigation.dart'
    show RevealWhenCurrent;
import 'package:quantumquiz/screens/notebook_article_view.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart'
    show plainGateText;
import 'package:quantumquiz/widgets/composer_workspace/composer_session_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';

const _border = QubitQuestColors.border;
const _cyan = QubitQuestColors.accentInteractive;
const _muted = QubitQuestColors.textMuted;
const _body = QubitQuestColors.textBody;

/// The web Notebook as an interactive quantum knowledge base (v2.6 M6b).
///
/// ```text
/// header (title, search)
/// ├─ index: categories (Notation, Gate reference, Journey chapters)
/// └─ article: sections · math · experiments · related concepts/activities
/// experiment: the shared ComposerSessionWorkspace (notebookExample policy)
/// ```
///
/// The browser and an open experiment live in an [IndexedStack], so leaving
/// and returning from an experiment keeps the article, its selection and its
/// scroll position. Experiments are ephemeral sessions of their own: they
/// never touch the Sandbox, Journey or Mastery sessions, or progress.
class WebNotebookWorkspace extends StatefulWidget {
  const WebNotebookWorkspace({
    super.key,
    required this.progressController,
    required this.onOpenJourney,
    this.requestedDiscoveryTitle,
    this.requestedArticleId,
    this.requestSerial = 0,
    this.onOpenExampleInBlochExplorer,
    this.onOpenJourneyLesson,
    this.onOpenMasteryChallenge,
    this.layout,
    this.isActive = true,
    this.onArticleShown,
  });

  final CampaignProgressController progressController;
  final VoidCallback onOpenJourney;

  /// A discovery to show (from a lesson's "Open Notebook" or an inspector's
  /// related concept).
  final String? requestedDiscoveryTitle;

  /// An article to show, by stable ID (routes, cross-links).
  final String? requestedArticleId;

  /// Changes with every request, so a repeated request acts again.
  final int requestSerial;
  final void Function(
    ExecutableNotebookExample example,
    ExecutableNotebookResult result,
  )? onOpenExampleInBlochExplorer;

  /// Opens a Journey lesson; the Journey still enforces its locks.
  final ValueChanged<int>? onOpenJourneyLesson;

  /// Opens a Mastery challenge (always accessible).
  final ValueChanged<String>? onOpenMasteryChallenge;

  /// Shared Composer workspace layout preferences (experiments).
  final WorkspaceLayoutController? layout;

  /// Whether the Notebook is the visible destination (shortcuts).
  final bool isActive;

  /// Reports the shown article ID (null for none), for the address bar.
  final ValueChanged<String?>? onArticleShown;

  /// Index width at wide sizes.
  static const double masterDetailWidth = 760;

  @override
  State<WebNotebookWorkspace> createState() => WebNotebookWorkspaceState();
}

class _Experiment {
  _Experiment(this.example, this.originArticleId, this.slot)
      : authored = _structure(slot.session.circuit);
  final ExecutableNotebookExample example;
  final String originArticleId;
  final ComposerWorkspaceSlot slot;

  /// The authored circuit's structure, to tell whether the learner has
  /// changed it. Structural (types, positions, controls, angles,
  /// measurements), not by gate identity: Reset re-inserts the authored
  /// gates with new identities.
  final String authored;
  ComposerSession get session => slot.session;
  bool get modified => _structure(session.circuit) != authored;

  static String _structure(QuantumCircuit c) => [
        for (final g in c.logicalGates)
          '${g.type.name}@${g.column}:${g.targetQubit ?? g.anchor.qubit}'
              '<${g.controlQubits.join(',')}>${g.gate.angle}',
        for (final m in c.measurements)
          'M@${m.column}:${m.qubit}>${m.classicalBit}',
      ].join('|');
}

@visibleForTesting
class WebNotebookWorkspaceState extends State<WebNotebookWorkspace> {
  final NotebookKnowledgeBase _kb = NotebookKnowledgeBase.instance;
  final TextEditingController _search = TextEditingController();
  final ScrollController _indexScroll = ScrollController();
  String? _selectedId;
  String _query = '';
  final Set<String> _expanded = {'reference', 'gates'};
  bool _narrowDetail = false;
  _Experiment? _experiment;

  /// The learner's preferred presentation (M11E). Kept when the window is
  /// too narrow for a spread, and used again once it fits.
  NotebookReadingMode _mode = NotebookReadingMode.article;
  WorkspaceLayoutController? _ownLayout;

  /// The open experiment's session (tests).
  ComposerSession? get experimentSession => _experiment?.session;
  NotebookReadingMode get readingMode => _mode;
  String? get selectedArticleId => _selectedId;

  WorkspaceLayoutController get _layout =>
      widget.layout ?? (_ownLayout ??= WorkspaceLayoutController());

  Set<String> get _unlocked =>
      widget.progressController.unlockedDiscoveryTitles();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _honorRequests());
  }

  @override
  void didUpdateWidget(covariant WebNotebookWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestSerial != widget.requestSerial ||
        oldWidget.requestedDiscoveryTitle != widget.requestedDiscoveryTitle ||
        oldWidget.requestedArticleId != widget.requestedArticleId) {
      _handledSerial = null;
      _honorRequests();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _indexScroll.dispose();
    _experiment?.session.dispose();
    _ownLayout?.dispose();
    super.dispose();
  }

  /// The request serial already honoured. A request that arrives before
  /// progress has loaded (e.g. a startup route) is honoured once it loads.
  int? _handledSerial;

  bool get _hasPendingRequest =>
      _handledSerial != widget.requestSerial &&
      (widget.requestedArticleId != null ||
          widget.requestedDiscoveryTitle != null);

  void _honorRequests() {
    if (!mounted || !widget.progressController.isLoaded) return;
    _handledSerial = widget.requestSerial;
    final byTitle = widget.requestedDiscoveryTitle == null
        ? null
        : _kb.byDiscoveryTitle(widget.requestedDiscoveryTitle!);
    final byId = widget.requestedArticleId == null
        ? null
        : _kb.byId(widget.requestedArticleId!);
    final article = byId ?? byTitle;
    if (article == null) return;
    _closeExperiment();
    _clearSearch(rebuild: false);
    select(article.id);
  }

  /// Selects an article. Locked discoveries show a preview without content;
  /// reading never completes lessons or unlocks anything.
  void select(String id) {
    final article = _kb.byId(id);
    if (article == null) return;
    setState(() {
      _selectedId = id;
      _narrowDetail = true;
      _expanded.add(article.categoryId);
    });
    if (article.kind != NotebookArticleKind.gate &&
        _kb.isAvailable(article, _unlocked)) {
      unawaited(widget.progressController
          .markNotebookEntryOpened(article.entry!.discoveryTitle));
    }
    widget.onArticleShown?.call(id);
  }

  void _selectDiscoveryTitle(String title) {
    final article = _kb.byDiscoveryTitle(title);
    if (article != null) select(article.id);
  }

  void _clearSearch({bool rebuild = true}) {
    _search.clear();
    if (rebuild) {
      setState(() => _query = '');
    } else {
      _query = '';
    }
  }

  static Future<void> _endOfFrame() => WidgetsBinding.instance.endOfFrame;

  /// Opens [example] as a fresh experiment session: always the authored
  /// circuit, never a previous experiment's state.
  void openExperiment(ExecutableNotebookExample example, String originId) {
    final level = example.createExperimentLevel();
    final circuit = QuantumCircuit(currentLevel: level);
    if (!circuit.hasMeasurements) circuit.runSimulation();
    final session = ComposerSession(
      circuit: circuit,
      policy: ComposerPolicy.forMode(ComposerMode.notebookExample, level),
      beforeRun: _endOfFrame,
    );
    final old = _experiment;
    setState(() => _experiment = _Experiment(
          example,
          originId,
          ComposerWorkspaceSlot(session, status: ''),
        ));
    if (old != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => old.session.dispose());
    }
  }

  /// Returns to the originating article (kept mounted with its scroll).
  void _closeExperiment() {
    final old = _experiment;
    if (old == null) return;
    setState(() {
      _experiment = null;
      _selectedId = old.originArticleId;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.session.dispose());
  }

  NotebookArticle? get _selected =>
      _selectedId == null ? null : _kb.byId(_selectedId!);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.progressController,
        builder: (context, _) {
          if (!widget.progressController.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_hasPendingRequest) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _honorRequests());
          }
          final experiment = _experiment;
          return ColoredBox(
            color: QubitQuestSurfaces.app,
            child: IndexedStack(
              index: experiment == null ? 0 : 1,
              sizing: StackFit.expand,
              children: [
                _browser(context),
                if (experiment == null)
                  const SizedBox.shrink()
                else
                  _experimentView(experiment),
              ],
            ),
          );
        },
      );

  Widget _browser(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= WebNotebookWorkspace.masterDetailWidth;
          final unlocked = _unlocked;
          // Wide: the notation reference is a sensible starting article.
          final selected =
              _selected ?? (wide ? _kb.byId(notebookDefaultArticleId) : null);
          final index = _NotebookIndex(
            kb: _kb,
            unlocked: unlocked,
            selectedId: selected?.id,
            query: _query,
            expanded: _expanded,
            scrollController: _indexScroll,
            onToggle: (id) => setState(() => _expanded.contains(id)
                ? _expanded.remove(id)
                : _expanded.add(id)),
            onSelect: select,
            onSelectResult: (id) {
              // Opening a result returns to the index (as before M6b).
              _clearSearch(rebuild: false);
              select(id);
            },
            onClearSearch: _clearSearch,
          );
          final indexWidth = constraints.maxWidth >= 1200 ? 320.0 : 280.0;
          final articleWidth = wide
              ? constraints.maxWidth - indexWidth - 1
              : constraints.maxWidth;
          final article = selected == null
              ? const SizedBox.shrink()
              : NotebookArticleView(
                  key: PageStorageKey('notebook-article-${selected.id}'),
                  kb: _kb,
                  article: selected,
                  unlocked: unlocked,
                  progress: widget.progressController.state,
                  mode: _mode,
                  showBack: !wide,
                  onBack: () => setState(() => _narrowDetail = false),
                  onSelect: select,
                  onExplore: (example) => openExperiment(example, selected.id),
                  onOpenInBloch: widget.onOpenExampleInBlochExplorer,
                  onOpenJourney: widget.onOpenJourney,
                  onOpenLesson: widget.onOpenJourneyLesson,
                  onOpenChallenge: widget.onOpenMasteryChallenge,
                );
          final header = _NotebookHeader(
            controller: _search,
            compact: !wide,
            mode: _mode,
            // Offered only where it fits and the article has two pages
            // (the notation glossary reads as one column).
            spreadAvailable: wide &&
                selected != null &&
                notebookSpreadAvailable(selected, articleWidth),
            onModeChanged: (mode) => setState(() => _mode = mode),
            onChanged: (value) => setState(() {
              _query = value;
              if (!wide && value.trim().isNotEmpty) _narrowDetail = false;
            }),
            onClear: _clearSearch,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const Divider(height: 1, color: QubitQuestSurfaces.rule),
              Expanded(
                child: wide
                    ? Row(
                        key: const ValueKey('web-notebook-master-detail'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: indexWidth,
                            child: ColoredBox(
                                color: QubitQuestSurfaces.section,
                                child: index),
                          ),
                          const VerticalDivider(
                              width: 1, color: QubitQuestSurfaces.rule),
                          Expanded(child: article),
                        ],
                      )
                    : _narrowDetail &&
                            selected != null &&
                            normalizeNotebookSearchText(_query).isEmpty
                        ? KeyedSubtree(
                            key: const ValueKey('web-notebook-reader-narrow'),
                            child: article)
                        : KeyedSubtree(
                            key: const ValueKey('web-notebook-index-narrow'),
                            child: index),
              ),
            ],
          );
        },
      );

  Widget _experimentView(_Experiment experiment) {
    final origin = _kb.byId(experiment.originArticleId);
    return ComposerSessionWorkspace(
      key: ObjectKey(experiment.session),
      slot: experiment.slot,
      layout: _layout,
      shortcutsEnabled: widget.isActive,
      contextLabel: 'Notebook experiment',
      workspaceKey: const ValueKey('notebook-experiment-workspace'),
      clearLabel: 'Reset example',
      clearedStatus: 'Example restored to its authored circuit.',
      onOpenNotebookEntry: (title) {
        _closeExperiment();
        _selectDiscoveryTitle(title);
      },
      header: ListenableBuilder(
        listenable: experiment.session,
        builder: (context, _) => _ExperimentHeader(
          example: experiment.example,
          originTitle: origin?.title ?? 'Notebook',
          onBack: _closeExperiment,
          modified: experiment.modified,
        ),
      ),
    );
  }
}

/// The article shown first on wide layouts when nothing is selected.
const String notebookDefaultArticleId = 'notation_and_terms';

class _NotebookHeader extends StatelessWidget {
  const _NotebookHeader({
    required this.controller,
    required this.compact,
    required this.mode,
    required this.spreadAvailable,
    required this.onModeChanged,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool compact;
  final NotebookReadingMode mode;
  final bool spreadAvailable;
  final ValueChanged<NotebookReadingMode> onModeChanged;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      key: const ValueKey('web-notebook-search-field'),
      controller: controller,
      onChanged: onChanged,
      style: QqType.body,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search concepts, gates and notation',
        hintStyle: QqType.body.copyWith(color: _muted),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                key: const ValueKey('web-notebook-clear-search'),
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.clear, size: 19),
              ),
        filled: true,
        fillColor: QubitQuestSurfaces.work,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
      ),
    );
    final title = Text('Notebook',
        key: const ValueKey('web-notebook-title'), style: QqType.sectionTitle);
    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [title, const SizedBox(height: 8), field],
        ),
      );
    }
    // Spread keeps its place when it does not fit, disabled and saying why;
    // the preference is kept (M11E).
    final toggle = SegmentedButton<NotebookReadingMode>(
      key: const ValueKey('web-notebook-mode'),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: QqType.control,
      ),
      segments: [
        const ButtonSegment(
          value: NotebookReadingMode.article,
          icon: Icon(Icons.article_outlined, size: 18),
          label: Text('Article', key: ValueKey('web-notebook-mode-article')),
          tooltip: 'One reading column',
        ),
        ButtonSegment(
          value: NotebookReadingMode.spread,
          enabled: spreadAvailable,
          icon: const Icon(Icons.menu_book_outlined, size: 18),
          label:
              const Text('Spread', key: ValueKey('web-notebook-mode-spread')),
          tooltip: spreadAvailable
              ? 'Two pages: explanation, and mathematics with experiments'
              : 'Needs a wider window; the notation reference is always '
                  'one column',
        ),
      ],
      selected: {
        spreadAvailable ? mode : NotebookReadingMode.article,
      },
      onSelectionChanged: (s) => onModeChanged(s.single),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined, color: _cyan, size: 22),
          const SizedBox(width: 10),
          title,
          const SizedBox(width: 16),
          // The controls sit at the right edge; the search field takes
          // what is left, up to 360 px.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                toggle,
                const SizedBox(width: 16),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: field,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookIndex extends StatelessWidget {
  const _NotebookIndex({
    required this.kb,
    required this.unlocked,
    required this.selectedId,
    required this.query,
    required this.expanded,
    required this.scrollController,
    required this.onToggle,
    required this.onSelect,
    required this.onSelectResult,
    required this.onClearSearch,
  });

  final ValueChanged<String> onSelectResult;
  final NotebookKnowledgeBase kb;
  final Set<String> unlocked;
  final String? selectedId;
  final String query;
  final Set<String> expanded;
  final ScrollController scrollController;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onSelect;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    if (normalizeNotebookSearchText(query).isNotEmpty) {
      final hits = kb.search(query, unlocked);
      if (hits.isEmpty) {
        return Padding(
          key: const ValueKey('web-notebook-search-empty'),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No available articles match “${query.trim()}”.',
                  style: QqType.bodyStrong),
              const SizedBox(height: 6),
              const Text(
                'Search covers the gate reference, notation and the entries '
                'you have discovered. Undiscovered Journey entries are not '
                'searched.',
                style: QqType.meta,
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const ValueKey('web-notebook-search-reset'),
                onPressed: onClearSearch,
                child: const Text('Clear search'),
              ),
            ],
          ),
        );
      }
      return ListView.separated(
        key: const ValueKey('web-notebook-search-results'),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
        itemCount: hits.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
              child: Text('${hits.length} result${hits.length == 1 ? '' : 's'}',
                  key: const ValueKey('web-notebook-search-count'),
                  style: QqType.navMeta),
            );
          }
          final hit = hits[index - 1];
          final selected = hit.article.id == selectedId;
          return Material(
            color: selected
                ? QubitQuestColors.navigationSelected
                : Colors.transparent,
            borderRadius: QubitQuestRadii.control,
            child: InkWell(
              key: ValueKey('web-notebook-search-${hit.article.id}'),
              borderRadius: QubitQuestRadii.control,
              onTap: () => onSelectResult(hit.article.id),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hit.article.title,
                        style: QqType.navLabel
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_groupTitle(kb, hit.article),
                        style: QqType.navMeta.copyWith(color: _cyan)),
                    const SizedBox(height: 2),
                    Text(
                        formatQuantumNotationForPlainText(
                            plainGateText(hit.snippet)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: QqType.navMeta),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    final reference = kb.categories.where((c) => c.id == 'reference').toList();
    final gates = kb.categories.where((c) => c.id == 'gates').toList();
    final chapters =
        kb.categories.where((c) => c.id.startsWith('chapter-')).toList();
    final discovered = [
      for (final c in chapters)
        for (final a in c.articles)
          if (kb.isAvailable(a, unlocked)) a,
    ].length;
    final totalDiscoveries =
        chapters.fold<int>(0, (n, c) => n + c.articles.length);
    Widget rows(NotebookCategory category) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final article in category.articles)
              _ArticleRow(
                article: article,
                available: kb.isAvailable(article, unlocked),
                selected: article.id == selectedId,
                onTap: () => onSelect(article.id),
              ),
          ],
        );
    // Built eagerly (about a hundred rows) so the selected entry can always
    // scroll itself into view, even at the end of the index (M11E).
    return SingleChildScrollView(
      key: const ValueKey('web-notebook-index'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Notation and terminology: one article, always shown.
          for (final category in reference) ...[
            const _GroupHeading(
              key: ValueKey('web-notebook-group-notation'),
              icon: Icons.functions,
              title: 'Notation and terminology',
            ),
            rows(category),
            const SizedBox(height: 14),
          ],
          // 2. Gate reference.
          for (final category in gates) ...[
            _GroupHeading(
              key: const ValueKey('web-notebook-group-gates'),
              icon: Icons.memory_outlined,
              title: 'Gate reference',
              countKey: ValueKey('web-notebook-category-count-${category.id}'),
              count: '${category.articles.length} gates',
              expanded: expanded.contains(category.id),
              toggleKey: ValueKey('web-notebook-category-${category.id}'),
              onToggle: () => onToggle(category.id),
            ),
            if (expanded.contains(category.id)) rows(category),
            const SizedBox(height: 14),
          ],
          // 3. Discoveries, by Journey chapter.
          _GroupHeading(
            key: const ValueKey('web-notebook-group-discoveries'),
            icon: Icons.auto_stories_outlined,
            title: 'Discoveries',
            count: '$discovered / $totalDiscoveries discovered',
          ),
          for (final category in chapters) ...[
            _ChapterHeading(
              category: category,
              available: category.articles
                  .where((a) => kb.isAvailable(a, unlocked))
                  .length,
              expanded: expanded.contains(category.id),
              containsSelection:
                  category.articles.any((a) => a.id == selectedId),
              onToggle: () => onToggle(category.id),
            ),
            if (expanded.contains(category.id))
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: rows(category),
              ),
          ],
        ],
      ),
    );
  }
}

/// The group an article belongs to, as the index names it.
String _groupTitle(NotebookKnowledgeBase kb, NotebookArticle article) =>
    switch (article.kind) {
      NotebookArticleKind.reference => 'Notation and terminology',
      NotebookArticleKind.gate => 'Gate reference',
      NotebookArticleKind.discovery =>
        'Discoveries · ${kb.categoryOf(article).title}',
    };

/// One of the Notebook's three groups: notation, gates, discoveries.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading({
    super.key,
    required this.icon,
    required this.title,
    this.count,
    this.countKey,
    this.expanded,
    this.toggleKey,
    this.onToggle,
  });
  final IconData icon;
  final String title;
  final String? count;
  final Key? countKey;
  final bool? expanded;
  final Key? toggleKey;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: QubitQuestColors.accentStrong),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(title.toUpperCase(),
                    style: QqType.panelHeading
                        .copyWith(color: QubitQuestColors.accentStrong)),
                if (count != null)
                  Text(count!, key: countKey, style: QqType.navMeta),
              ],
            ),
          ),
          if (expanded != null)
            Icon(expanded! ? Icons.expand_less : Icons.expand_more,
                size: 18, color: _muted),
        ],
      ),
    );
    return Semantics(
      header: true,
      child: onToggle == null
          ? row
          : InkWell(
              key: toggleKey,
              borderRadius: QubitQuestRadii.control,
              onTap: onToggle,
              child: row,
            ),
    );
  }
}

class _ChapterHeading extends StatelessWidget {
  const _ChapterHeading({
    required this.category,
    required this.available,
    required this.expanded,
    required this.containsSelection,
    required this.onToggle,
  });
  final NotebookCategory category;
  final int available;
  final bool expanded;
  final bool containsSelection;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final total = category.articles.length;
    return Tooltip(
      message: category.title,
      waitDuration: const Duration(milliseconds: 700),
      child: InkWell(
        key: ValueKey('web-notebook-category-${category.id}'),
        borderRadius: QubitQuestRadii.control,
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 6, 7),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: QqType.navLabel.copyWith(
                        color: containsSelection
                            ? QubitQuestColors.accentInteractive
                            : QubitQuestColors.textPrimary,
                        fontWeight: containsSelection
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$available / $total discovered',
                      key: ValueKey(
                          'web-notebook-category-count-${category.id}'),
                      style: QqType.navMeta,
                    ),
                  ],
                ),
              ),
              Icon(expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({
    required this.article,
    required this.available,
    required this.selected,
    required this.onTap,
  });
  final NotebookArticle article;
  final bool available;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (article.kind) {
      NotebookArticleKind.gate => Icons.memory_outlined,
      NotebookArticleKind.reference => Icons.functions,
      NotebookArticleKind.discovery =>
        available ? Icons.check_circle_outline : Icons.lock_outline,
    };
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Material(
        color:
            selected ? QubitQuestColors.navigationSelected : Colors.transparent,
        borderRadius: QubitQuestRadii.control,
        child: InkWell(
          key: ValueKey('web-notebook-entry-${article.id}'),
          borderRadius: QubitQuestRadii.control,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
            decoration: BoxDecoration(
              borderRadius: QubitQuestRadii.control,
              border: Border(
                left: BorderSide(
                    width: 3, color: selected ? _cyan : Colors.transparent),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon,
                      size: 16,
                      color: !available
                          ? QubitQuestColors.textMuted
                          : article.kind == NotebookArticleKind.discovery
                              ? QubitQuestColors.success
                              : _cyan),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: QqType.navLabel.copyWith(
                      color: !available
                          ? QubitQuestColors.textMuted
                          : selected
                              ? _cyan
                              : QubitQuestColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final tooltipped = Tooltip(
      message: available ? article.title : '${article.title} · not discovered',
      waitDuration: const Duration(milliseconds: 700),
      child: row,
    );
    // The selected article is scrolled into view when it changes (M11E,
    // as in the Journey curriculum); manual scrolling is otherwise kept.
    return selected
        ? RevealWhenCurrent(token: article.id, child: tooltipped)
        : tooltipped;
  }
}

/// Experiment context above the shared workspace: where it came from and the
/// way back. Exploratory: no Check, hints or completion.
class _ExperimentHeader extends StatefulWidget {
  const _ExperimentHeader({
    required this.example,
    required this.originTitle,
    required this.onBack,
    required this.modified,
  });
  final ExecutableNotebookExample example;
  final String originTitle;
  final VoidCallback onBack;

  /// The learner changed the authored circuit (v2.6 M9).
  final bool modified;

  @override
  State<_ExperimentHeader> createState() => _ExperimentHeaderState();
}

class _ExperimentHeaderState extends State<_ExperimentHeader> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          // Narrow screens show two lines of the description, with More.
          final compact = constraints.maxWidth < 760;
          final description =
              formatQuantumNotationForPlainText(widget.example.description);
          final back = OutlinedButton.icon(
            key: const ValueKey('notebook-experiment-back-article'),
            onPressed: widget.onBack,
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text('Back to article'),
          );
          return Padding(
            key: const ValueKey('notebook-experiment-header'),
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  key: const ValueKey('notebook-experiment-back'),
                  tooltip: 'Back to the article',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notebook  /  ${widget.originTitle}  /  Experiment',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _cyan, fontSize: 12.5)),
                      const SizedBox(height: 2),
                      Text(widget.example.title,
                          key: const ValueKey('notebook-experiment-title'),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      if (widget.modified)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            'You have changed the circuit. The description '
                            'below is about the original example; Reset '
                            'example restores it.',
                            key: ValueKey('notebook-experiment-modified'),
                            style: TextStyle(
                                color: Color(0xFFFFC857), fontSize: 12.5),
                          ),
                        ),
                      Text(
                        widget.modified
                            ? 'Original example: $description'
                            : description,
                        key: const ValueKey('notebook-experiment-description'),
                        maxLines: compact && !_expanded ? 2 : null,
                        overflow: compact && !_expanded
                            ? TextOverflow.ellipsis
                            : null,
                        style: const TextStyle(color: _body, height: 1.4),
                      ),
                      if (compact && description.length > 90)
                        TextButton(
                          key: const ValueKey('notebook-experiment-more'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 28),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          child: Text(_expanded ? 'Less' : 'More'),
                        ),
                      const SizedBox(height: 2),
                      const Text(
                        'Exploration only: change, measure and reset freely. '
                        'Nothing here is checked, saved or counted as '
                        'progress, and your Sandbox is untouched.',
                        key: ValueKey('notebook-experiment-note'),
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[const SizedBox(width: 12), back],
              ],
            ),
          );
        },
      );
}
