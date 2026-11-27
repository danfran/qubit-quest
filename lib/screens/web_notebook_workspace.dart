import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/notebook_knowledge_base.dart';
import 'package:quantumquiz/models/notebook_search.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart'
    show plainGateText;
import 'package:quantumquiz/widgets/circuit_preview.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_session_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/gate_inspector_panel.dart'
    show gateEducationalPreviewFootprint;
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';
import 'package:quantumquiz/widgets/gate_educational_sections.dart';
import 'package:quantumquiz/widgets/gate_educational_visual.dart';
import 'package:quantumquiz/widgets/notebook_typography.dart';

const _background = QubitQuestColors.background;
const _surface = QubitQuestColors.surface;
const _inner = Color(0xFF07101F);
const _border = QubitQuestColors.border;
const _cyan = QubitQuestColors.accentInteractive;
const _purple = QubitQuestColors.accentStrong;
const _muted = Color(0xFF9BAAC4);
const _body = Color(0xFFD6E3F8);

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
  WorkspaceLayoutController? _ownLayout;

  /// The open experiment's session (tests).
  ComposerSession? get experimentSession => _experiment?.session;
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
            color: _background,
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
          final article = selected == null
              ? const SizedBox.shrink()
              : _ArticleView(
                  key: PageStorageKey('notebook-article-${selected.id}'),
                  kb: _kb,
                  article: selected,
                  unlocked: unlocked,
                  progress: widget.progressController.state,
                  showBack: !wide,
                  onBack: () => setState(() => _narrowDetail = false),
                  onSelect: select,
                  onSelectDiscovery: _selectDiscoveryTitle,
                  onExplore: (example) => openExperiment(example, selected.id),
                  onOpenInBloch: widget.onOpenExampleInBlochExplorer,
                  onOpenJourney: widget.onOpenJourney,
                  onOpenLesson: widget.onOpenJourneyLesson,
                  onOpenChallenge: widget.onOpenMasteryChallenge,
                );
          final header = _NotebookHeader(
            controller: _search,
            compact: !wide,
            onChanged: (value) => setState(() {
              _query = value;
              if (!wide && value.trim().isNotEmpty) _narrowDetail = false;
            }),
            onClear: _clearSearch,
          );
          final indexWidth = constraints.maxWidth >= 1200 ? 320.0 : 280.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const Divider(height: 1, color: _border),
              Expanded(
                child: wide
                    ? Row(
                        key: const ValueKey('web-notebook-master-detail'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: indexWidth, child: index),
                          const VerticalDivider(width: 1, color: _border),
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
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool compact;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      key: const ValueKey('web-notebook-search-field'),
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search concepts, gates and notation',
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
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
      ),
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Notebook',
            key: const ValueKey('web-notebook-title'),
            style: NotebookTypography.text(NotebookTextRole.pageTitle,
                color: Colors.white)),
        const Text('Quantum knowledge base',
            style: TextStyle(color: _muted, fontSize: 12.5)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [title, const SizedBox(height: 10), field],
            )
          : Row(
              children: [
                const Icon(Icons.menu_book_outlined, color: _cyan, size: 24),
                const SizedBox(width: 10),
                Expanded(child: title),
                SizedBox(width: 360, child: field),
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
                  style: const TextStyle(color: Colors.white, height: 1.4)),
              const SizedBox(height: 6),
              const Text(
                'Search covers the gate reference, notation and the entries '
                'you have discovered. Undiscovered Journey entries are not '
                'searched.',
                style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
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
                  style: const TextStyle(color: _muted, fontSize: 12)),
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
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(kb.categoryOf(hit.article).title,
                        style: const TextStyle(color: _cyan, fontSize: 11.5)),
                    const SizedBox(height: 2),
                    Text(
                        formatQuantumNotationForPlainText(
                            plainGateText(hit.snippet)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _muted, fontSize: 12, height: 1.35)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    return ListView(
      key: const ValueKey('web-notebook-index'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 24),
      children: [
        for (final category in kb.categories) ...[
          _CategoryHeading(
            category: category,
            available: category.articles
                .where((a) => kb.isAvailable(a, unlocked))
                .length,
            expanded: expanded.contains(category.id),
            onToggle: () => onToggle(category.id),
          ),
          if (expanded.contains(category.id))
            for (final article in category.articles)
              _ArticleRow(
                article: article,
                available: kb.isAvailable(article, unlocked),
                selected: article.id == selectedId,
                onTap: () => onSelect(article.id),
              ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading({
    required this.category,
    required this.available,
    required this.expanded,
    required this.onToggle,
  });
  final NotebookCategory category;
  final int available;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final total = category.articles.length;
    final chapter = category.id.startsWith('chapter-');
    return InkWell(
      key: ValueKey('web-notebook-category-${category.id}'),
      borderRadius: QubitQuestRadii.control,
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 6, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title.toUpperCase(),
                    style: const TextStyle(
                      color: _purple,
                      fontSize: 11,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chapter
                        ? '$available / $total discovered'
                        : '$total article${total == 1 ? '' : 's'}',
                    key: ValueKey('web-notebook-category-count-${category.id}'),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(expanded ? Icons.expand_less : Icons.expand_more,
                size: 18, color: _muted),
          ],
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
    return Padding(
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
              children: [
                Icon(icon,
                    size: 16,
                    color: !available
                        ? Colors.white30
                        : article.kind == NotebookArticleKind.discovery
                            ? QubitQuestColors.success
                            : _cyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: available ? Colors.white : Colors.white38,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
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

class _ArticleView extends StatelessWidget {
  const _ArticleView({
    super.key,
    required this.kb,
    required this.article,
    required this.unlocked,
    required this.progress,
    required this.showBack,
    required this.onBack,
    required this.onSelect,
    required this.onSelectDiscovery,
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
  final bool showBack;
  final VoidCallback onBack;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onSelectDiscovery;
  final ValueChanged<ExecutableNotebookExample> onExplore;
  final void Function(ExecutableNotebookExample, ExecutableNotebookResult)?
      onOpenInBloch;
  final VoidCallback onOpenJourney;
  final ValueChanged<int>? onOpenLesson;
  final ValueChanged<String>? onOpenChallenge;

  bool _lessonUnlocked(int id) => ProgressionRules.isJourneyLessonUnlocked(
      lessonId: id, maxUnlockedLevel: progress.maxUnlockedLevel);

  @override
  Widget build(BuildContext context) {
    final available = kb.isAvailable(article, unlocked);
    final category = kb.categoryOf(article);
    final children = <Widget>[
      if (showBack)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('web-notebook-back-index'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Notebook index'),
          ),
        ),
      Text(category.title,
          key: const ValueKey('web-notebook-article-category'),
          style:
              NotebookTypography.text(NotebookTextRole.context, color: _cyan)),
      const SizedBox(height: 6),
      Text(article.title,
          key: const ValueKey('web-notebook-entry-title'),
          style: NotebookTypography.text(NotebookTextRole.entryTitle,
              color: Colors.white)),
      const SizedBox(height: 10),
      if (!available)
        _LockedPreview(
          link: kb.lessonFor(article),
          lessonUnlocked: _lessonUnlocked,
          onOpenLesson: onOpenLesson,
          onOpenJourney: onOpenJourney,
        )
      else ...[
        Text(formatQuantumNotationForPlainText(plainGateText(article.summary)),
            key: const ValueKey('web-notebook-article-summary'),
            style:
                NotebookTypography.text(NotebookTextRole.lead, color: _body)),
        ..._articleSections(context),
      ],
    ];
    return ListView(
      key: ValueKey('web-notebook-reader-${article.id}'),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _gap(Widget child) => [const SizedBox(height: 20), child];

  List<Widget> _articleSections(BuildContext context) {
    final examples = [
      for (final id in article.exampleIds)
        if (notebookExampleById(id) case final e?) e,
    ];
    final related = kb.relatedArticles(article);
    final entry = article.entry;
    final gate = article.gate;
    final lesson = kb.lessonFor(article);
    final lessonGates = lesson == null
        ? const <NotebookArticle>[]
        : kb.gateArticlesFor(lesson.level);
    final relatedConcepts = [
      ...related,
      for (final g in lessonGates)
        if (!related.contains(g)) g,
    ];
    return [
      if (entry != null) ...[
        if ([
          ...entry.intuition.examples,
          ...?entry.whatChanged?.examples,
          ...?entry.quantumView?.examples,
        ]
            case final keyExamples when keyExamples.isNotEmpty)
          ..._gap(_ExamplesCard(examples: keyExamples)),
        for (final section in [
          entry.intuition,
          if (entry.whatChanged != null) entry.whatChanged!,
          if (entry.quantumView != null) entry.quantumView!,
        ])
          ..._gap(_SectionCard(section: section)),
      ],
      if (gate != null) ..._gap(_GateReference(info: gate)),
      if (examples.isNotEmpty)
        ..._gap(Column(
          key: const ValueKey('web-notebook-experiments'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(
                examples.length == 1 ? 'Circuit example' : 'Circuit examples'),
            const SizedBox(height: 8),
            for (final example in examples) ...[
              _ExperimentCard(
                key: ValueKey('notebook-example-card-${example.id}'),
                example: example,
                onExplore: () => onExplore(example),
                onOpenInBloch: onOpenInBloch,
              ),
              const SizedBox(height: 10),
            ],
          ],
        )),
      if (entry?.advancedNotes != null)
        ..._gap(_AdvancedSection(section: entry!.advancedNotes!)),
      if (relatedConcepts.isNotEmpty)
        ..._gap(_RelatedConcepts(
          articles: relatedConcepts,
          isAvailable: (a) => kb.isAvailable(a, unlocked),
          onSelect: onSelect,
        )),
      if (lesson != null || gate != null)
        if (_activities(lesson, gate) case final activities?)
          ..._gap(activities),
      if (entry != null) ..._gap(_prevNext()),
    ];
  }

  Widget? _activities(NotebookLessonLink? lesson, GateEducationalInfo? gate) {
    final rows = <Widget>[];
    if (lesson != null) {
      final unlockedLesson = _lessonUnlocked(lesson.lessonId);
      final done = progress.completedLessonIds.contains(lesson.lessonId);
      rows.add(_ActivityRow(
        key: const ValueKey('web-notebook-activity-lesson'),
        icon: Icons.route_outlined,
        title: '${lesson.label} · ${lesson.level.title ?? ''}',
        status: done
            ? 'Completed'
            : unlockedLesson
                ? 'Available in the Journey'
                : 'Locked in the Journey',
        actionLabel: done ? 'Review lesson' : 'Open lesson',
        onAction: unlockedLesson && onOpenLesson != null
            ? () => onOpenLesson!(lesson.lessonId)
            : null,
      ));
    }
    if (article.gate case final info?) {
      final type = info.type;
      final challenges = kb.masteryChallengesUsing(type);
      for (final c in challenges.take(4)) {
        rows.add(_ActivityRow(
          key: ValueKey('web-notebook-activity-mastery-${c.semanticId}'),
          icon: Icons.workspace_premium_outlined,
          title: 'Mastery ${c.displayOrder} · ${c.title}',
          status: progress.completedMasterySemanticIds.contains(c.semanticId)
              ? 'Completed'
              : 'Open any time',
          actionLabel: 'Open challenge',
          onAction: onOpenChallenge == null
              ? null
              : () => onOpenChallenge!(c.semanticId),
        ));
      }
      final lessons = kb.journeyLessonsUsing(type);
      if (lessons.isNotEmpty) {
        final first = lessons.first;
        final chapter = journeyChapterForLesson(first);
        final number = chapter == null
            ? ''
            : 'Lesson ${journeyChapters.indexOf(chapter) + 1}.${first - chapter.from}';
        final unlockedFirst = _lessonUnlocked(first);
        rows.add(_ActivityRow(
          key: const ValueKey('web-notebook-activity-journey-first'),
          icon: Icons.route_outlined,
          title: 'First used in $number · '
              '${getJourneyLessonById(first)?.title ?? ''}',
          status: '${lessons.length} Journey lesson'
              '${lessons.length == 1 ? ' uses' : 's use'} '
              '${gateSymbol(type)}'
              '${unlockedFirst ? '' : ' · locked'}',
          actionLabel: 'Open lesson',
          onAction: unlockedFirst && onOpenLesson != null
              ? () => onOpenLesson!(first)
              : null,
        ));
      }
    }
    if (rows.isEmpty) return null;
    return Column(
      key: const ValueKey('web-notebook-activities'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Related activities'),
        const SizedBox(height: 6),
        for (final row in rows) row,
      ],
    );
  }

  Widget _prevNext() {
    final category = kb.categoryOf(article);
    final list = category.articles;
    final index = list.indexOf(article);
    NotebookArticle? find(int step) {
      for (var i = index + step; i >= 0 && i < list.length; i += step) {
        if (kb.isAvailable(list[i], unlocked)) return list[i];
      }
      return null;
    }

    final previous = find(-1);
    final next = find(1);
    if (previous == null && next == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: previous == null
              ? const SizedBox.shrink()
              : OutlinedButton.icon(
                  key: const ValueKey('web-notebook-previous'),
                  onPressed: () => onSelect(previous.id),
                  icon: const Icon(Icons.chevron_left),
                  label: Text(previous.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: next == null
              ? const SizedBox.shrink()
              : OutlinedButton.icon(
                  key: const ValueKey('web-notebook-next'),
                  onPressed: () => onSelect(next.id),
                  icon: const Icon(Icons.chevron_right),
                  label: Text(next.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: NotebookTypography.text(NotebookTextRole.sectionHeading,
          color: Colors.white));
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
    return Container(
      key: const ValueKey('web-notebook-locked-preview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _inner,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.lock_outline, size: 18, color: _muted),
            SizedBox(width: 8),
            Text('Not discovered yet',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          Text(
            lesson == null
                ? 'This entry is discovered in the Journey.'
                : 'This entry is discovered in ${lesson.label} · '
                    '${lesson.level.title}. '
                    '${open ? 'That lesson is open in your Journey.' : 'That lesson is still locked; continue the Journey to reach it.'}',
            style: const TextStyle(color: _body, height: 1.45),
          ),
          const SizedBox(height: 4),
          const Text(
            'Discovery entries describe what a lesson reveals, so they open '
            'once you make the discovery. The gate reference and notation are '
            'always available.',
            style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 10),
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

/// Gate reference: the same catalogue and section widgets as the
/// Composer's gate inspector, laid out as an article.
class _GateReference extends StatelessWidget {
  const _GateReference({required this.info});
  final GateEducationalInfo info;

  @override
  Widget build(BuildContext context) {
    final controlled = isControlledEducationalVisual(info.visual.kind);
    return Column(
      key: const ValueKey('web-notebook-gate-reference'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GateEducationalSummary(
            info: info, decorated: false, includeIntuition: false),
        if (info.keyIdeas.isNotEmpty) ...[
          const SizedBox(height: 6),
          GateEducationalListSection(
            key: const ValueKey('web-notebook-gate-key-ideas'),
            title: 'Key ideas',
            values: info.keyIdeas,
          ),
        ],
        const SizedBox(height: 18),
        const _Heading('Visual explanation'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 380,
            child: GateEducationalVisualView(
              key: const ValueKey('web-notebook-gate-visual'),
              visual: info.visual,
              footprint: gateEducationalPreviewFootprint(info.type),
              height: 170,
            ),
          ),
        ),
        if (controlled) ...[
          const SizedBox(height: 6),
          const Text(controlledGateBlochNote,
              style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4)),
        ],
        const SizedBox(height: 18),
        const _Heading('Mathematical representation'),
        const SizedBox(height: 8),
        Text(mathDefinitionHeading(info.matrix),
            style: const TextStyle(
                color: _purple,
                fontSize: 11,
                letterSpacing: .7,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: GateEducationalMatrix(
            latexKey: const ValueKey('web-notebook-gate-matrix'),
            matrix: info.matrix,
            mathFontSize: 21,
          ),
        ),
        if (info.transformations.isNotEmpty) ...[
          const SizedBox(height: 12),
          GateEducationalMathList(
            title: 'State action',
            values: info.transformations,
            level: GateEducationalMathLevel.secondary,
            keyPrefix: 'web-notebook-gate-state',
            decorated: false,
            large: true,
          ),
        ],
        if (info.identities.isNotEmpty) ...[
          const SizedBox(height: 12),
          GateEducationalMathList(
            title: 'Important identities',
            values: info.identities,
            level: GateEducationalMathLevel.secondary,
            keyPrefix: 'web-notebook-gate-identity',
            decorated: false,
          ),
        ],
        if (info.properties.isNotEmpty) ...[
          const SizedBox(height: 12),
          GateEducationalListSection(
              title: 'Properties', values: info.properties),
        ],
      ],
    );
  }
}

/// An authored executable example: its circuit (Composer painter) and the
/// state the real simulator prepares, with the way into an experiment.
class _ExperimentCard extends StatefulWidget {
  const _ExperimentCard({
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
  State<_ExperimentCard> createState() => _ExperimentCardState();
}

class _ExperimentCardState extends State<_ExperimentCard> {
  late QuantumCircuit _circuit = _build();

  QuantumCircuit _build() {
    final circuit =
        QuantumCircuit(currentLevel: widget.example.createExperimentLevel());
    circuit.runSimulation();
    return circuit;
  }

  @override
  void didUpdateWidget(covariant _ExperimentCard oldWidget) {
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
    final state = formatQuantumStateExpression(
      _circuit.currentState.stateVector,
      numQubits: example.qubitCount,
    );
    return Container(
      key: ValueKey('executable-example-${example.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _inner,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(example.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 3),
          Text(formatQuantumNotationForPlainText(example.description),
              style: const TextStyle(color: _body, height: 1.4)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 62.0 * example.qubitCount + 10,
              child: FittedBox(
                alignment: Alignment.centerLeft,
                child: QubitQuestCircuitPreview(
                  key: ValueKey('notebook-example-preview-${example.id}'),
                  circuit: _circuit,
                  minimumWidth: 180,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(state,
              key: ValueKey('notebook-example-state-${example.id}'),
              style: const TextStyle(
                  color: _cyan, fontWeight: FontWeight.w700, height: 1.4)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: ValueKey('notebook-explore-${example.id}'),
                onPressed: widget.onExplore,
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text('Explore circuit'),
              ),
              if (widget.onOpenInBloch != null &&
                  example.supports(ExecutableNotebookCapability.blochExplorer))
                OutlinedButton.icon(
                  key: ValueKey('bloch-example-${example.id}'),
                  onPressed: () =>
                      widget.onOpenInBloch!(example, example.execute()),
                  icon: const Icon(Icons.public, size: 18),
                  label: const Text('Explore in Bloch'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelatedConcepts extends StatelessWidget {
  const _RelatedConcepts({
    required this.articles,
    required this.isAvailable,
    required this.onSelect,
  });
  final List<NotebookArticle> articles;
  final bool Function(NotebookArticle) isAvailable;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('web-notebook-related'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading('Related concepts'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in articles)
                ActionChip(
                  key: ValueKey('web-notebook-related-${a.id}'),
                  avatar: Icon(
                    a.kind == NotebookArticleKind.gate
                        ? Icons.memory_outlined
                        : isAvailable(a)
                            ? Icons.auto_stories_outlined
                            : Icons.lock_outline,
                    size: 16,
                  ),
                  label: Text(a.kind == NotebookArticleKind.gate
                      ? 'Gate: ${a.title}'
                      : a.title),
                  onPressed: () => onSelect(a.id),
                ),
            ],
          ),
        ],
      );
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: onAction == null ? _muted : _cyan),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(status,
                      style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
            if (onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel))
            else
              const Icon(Icons.lock_outline, size: 16, color: _muted),
          ],
        ),
      );
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final NotebookSection section;

  @override
  Widget build(BuildContext context) => Padding(
        key: ValueKey('web-notebook-section-${section.title}'),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              section.title,
              style: NotebookTypography.text(
                NotebookTextRole.sectionHeading,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatQuantumNotationForPlainText(section.body),
              style: NotebookTypography.text(
                NotebookTextRole.body,
                color: const Color(0xFFD6E3F8),
              ),
            ),
          ],
        ),
      );
}

class _ExamplesCard extends StatelessWidget {
  const _ExamplesCard({required this.examples});
  final List<NotebookExample> examples;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    var index = 0;
    while (index < examples.length) {
      final example = examples[index];
      if (example.comparisonGroup case final group?) {
        final grouped = <NotebookExample>[];
        while (index < examples.length &&
            examples[index].comparisonGroup == group) {
          grouped.add(examples[index]);
          index++;
        }
        blocks.add(_WebNotebookComparison(examples: grouped));
      } else {
        blocks.add(_WebNotebookExampleBlock(example: example));
        index++;
      }
    }
    return Padding(
      key: const ValueKey('web-notebook-key-examples'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Key Examples',
            style: NotebookTypography.text(
              NotebookTextRole.sectionHeading,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < blocks.length; index++) ...[
            blocks[index],
            if (index != blocks.length - 1)
              const Divider(height: 18, color: _border),
          ],
        ],
      ),
    );
  }
}

class _WebNotebookExampleBlock extends StatelessWidget {
  const _WebNotebookExampleBlock({required this.example});

  final NotebookExample example;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            example.label,
            style: NotebookTypography.text(
              NotebookTextRole.subsection,
              color: _cyan,
            ),
          ),
          const SizedBox(height: 4),
          if (example.presentation == NotebookExamplePresentation.math)
            NotebookMathEvidence(example: example)
          else
            Text(
              formatQuantumNotationForPlainText(example.notation),
              style: NotebookTypography.text(
                NotebookTextRole.lead,
                color: Colors.white,
              ),
            ),
          if ((example.explanation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(example.explanation!,
                style: NotebookTypography.text(
                  NotebookTextRole.supporting,
                  color: _muted,
                )),
          ],
        ],
      );
}

class _WebNotebookComparison extends StatelessWidget {
  const _WebNotebookComparison({required this.examples});

  final List<NotebookExample> examples;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final useColumns =
              constraints.maxWidth >= 430 && examples.length == 2;
          if (!useColumns) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < examples.length; index++) ...[
                  _WebNotebookExampleBlock(example: examples[index]),
                  if (index != examples.length - 1) const SizedBox(height: 8),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < examples.length; index++) ...[
                Expanded(
                    child: _WebNotebookExampleBlock(example: examples[index])),
                if (index != examples.length - 1) const SizedBox(width: 20),
              ],
            ],
          );
        },
      );
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({required this.section});
  final NotebookSection section;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('web-notebook-advanced-notes'),
        decoration: BoxDecoration(
          color: _inner,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            section.title,
            style: NotebookTypography.text(
              NotebookTextRole.sectionHeading,
              color: Colors.white,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              formatQuantumNotationForPlainText(section.body),
              style: NotebookTypography.text(
                NotebookTextRole.body,
                color: const Color(0xFFD6E3F8),
              ),
            ),
          ],
        ),
      );
}
