import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/widgets/progress_save_feedback.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/qq_levels_category.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/journey_curriculum.dart';
import 'package:quantumquiz/screens/web_journey_overview.dart';
import 'package:quantumquiz/screens/journey_navigation.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/web_learning_text.dart';
import 'package:quantumquiz/widgets/web_activity_instruction_content.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';
import 'package:quantumquiz/screens/web_exercise_workspace.dart';
import 'package:quantumquiz/screens/web_mastery_browser.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/qubit_quest_workspace_primitives.dart';

const _border = QubitQuestColors.border;
const _cyan = QubitQuestColors.accentInteractive;
const _purple = QubitQuestColors.accentStrong;

enum _JourneyView { map, chapter }

class WebJourneyWorkspace extends StatefulWidget {
  const WebJourneyWorkspace({
    super.key,
    required this.progressController,
    required this.onOpenNotebook,
    this.onOpenNotebookEntry,
    this.onOpenMastery,
    this.initialChapterIndex,
    this.onChapterShown,
    this.layout,
    this.isActive = true,
    this.requestedLessonId,
    this.lessonRequestSerial = 0,
  });

  final CampaignProgressController progressController;

  /// A lesson another destination asked to open (e.g. a Notebook "related
  /// activity"); opened only when the progression rules unlock it.
  final int? requestedLessonId;
  final int lessonRequestSerial;

  /// Shared Composer workspace layout preferences (circuit lessons).
  final WorkspaceLayoutController? layout;

  /// Whether the Journey is the visible destination (keyboard shortcuts).
  final bool isActive;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;
  final VoidCallback? onOpenMastery;

  /// A chapter to select first (for example from a `#/journey/chapter-3`
  /// link). Selecting never unlocks anything; invalid values fall back to
  /// the learner's current chapter.
  final int? initialChapterIndex;

  /// Reports the selected chapter (zero-based) so the shell can reflect it
  /// in the browser address.
  final ValueChanged<int>? onChapterShown;

  @override
  State<WebJourneyWorkspace> createState() => _WebJourneyWorkspaceState();
}

class _WebJourneyWorkspaceState extends State<WebJourneyWorkspace> {
  _JourneyView _view = _JourneyView.map;
  QQLevelsCategory? _chapter;
  int? _selectedLevelId;

  /// Selected chapter in the overview (presentation only); null means "the
  /// learner's current chapter", resolved from progress on every build.
  late int? _overviewChapter = widget.initialChapterIndex;

  /// Narrow layout: the overview shows the chapter detail, not the list.
  late bool _narrowDetail = widget.initialChapterIndex != null;

  /// The learner's choice to collapse the curriculum beside a lesson; null
  /// follows the width.
  bool? _navCollapsed;

  /// Keeps the open lesson (session, circuit, hints, header state) alive
  /// when a resize moves it between the navigation and strip layouts.
  final GlobalKey _lessonKey = GlobalKey(debugLabel: 'journey-lesson');

  @override
  void initState() {
    super.initState();
    if (widget.requestedLessonId != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openRequestedLesson());
    }
  }

  @override
  void didUpdateWidget(covariant WebJourneyWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonRequestSerial != widget.lessonRequestSerial) {
      _openRequestedLesson();
    }
  }

  void _openRequestedLesson() {
    final id = widget.requestedLessonId;
    if (!mounted || id == null || !widget.progressController.isLoaded) return;
    _openLesson(id);
  }

  void _selectChapter(int index) {
    setState(() {
      _overviewChapter = index;
      _narrowDetail = true;
    });
    widget.onChapterShown?.call(index);
  }

  /// Opens an existing lesson host, but only for a lesson the existing
  /// progression rules have unlocked.
  void _openLesson(int levelId) {
    if (!_isUnlocked(levelId, widget.progressController.state)) return;
    final category = _categoryForLevel(levelId);
    if (category == null) return;
    setState(() {
      _chapter = category;
      _selectedLevelId = levelId;
      _view = _JourneyView.chapter;
    });
  }

  QQLevelsCategory? _categoryForLevel(int levelId) {
    return journeyChapterForLesson(levelId);
  }

  /// Returns to the overview with the lesson's chapter selected; its
  /// progress is re-read from the controller on the next build.
  void _showMap() {
    final lesson = _selectedLevelId;
    final index = lesson == null
        ? null
        : journeyChapters
            .indexWhere((c) => lesson >= c.from + 1 && lesson <= c.to + 1);
    setState(() {
      _view = _JourneyView.map;
      _chapter = null;
      _selectedLevelId = null;
      if (index != null && index >= 0) {
        _overviewChapter = index;
        _narrowDetail = true;
      }
    });
  }

  /// A chapter chosen in the curriculum beside a lesson: its overview.
  void _selectChapterFromLesson(int index) {
    setState(() {
      _view = _JourneyView.map;
      _chapter = null;
      _selectedLevelId = null;
      _overviewChapter = index;
      _narrowDetail = true;
    });
    widget.onChapterShown?.call(index);
  }

  void _selectLevel(int levelId) {
    if (!_isUnlocked(levelId, widget.progressController.state)) return;
    setState(() => _selectedLevelId = levelId);
  }

  int get _masteryCompleted => mastery2Catalogue.orderedDefinitions
      .where((c) => widget.progressController.state.completedMasterySemanticIds
          .contains(c.semanticId))
      .length;

  bool _isUnlocked(int levelId, CampaignProgressState state) =>
      ProgressionRules.isJourneyLessonUnlocked(
        lessonId: levelId,
        maxUnlockedLevel: state.maxUnlockedLevel,
      );

  bool _isCompleted(int levelId, CampaignProgressState state) =>
      state.completedLessonIds.contains(levelId);

  Future<void> _complete(int levelId) async {
    if (!await saveProgressWithFeedback(
        context, () => widget.progressController.completeLesson(levelId))) {
      return;
    }
    if (!mounted) return;
    setState(() {});
  }

  void _nextLesson() {
    final chapter = _chapter;
    final current = _selectedLevelId;
    if (chapter == null || current == null) return;
    final next = current + 1;
    if (next - 1 <= chapter.to &&
        _isUnlocked(next, widget.progressController.state)) {
      setState(() => _selectedLevelId = next);
    } else {
      _showMap();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.progressController,
        builder: (context, _) {
          if (!widget.progressController.isLoaded) {
            return const Center(
              key: ValueKey('web-workspace-journey-loading'),
              child: CircularProgressIndicator(),
            );
          }
          if (_view == _JourneyView.map || _chapter == null) {
            final curriculum =
                JourneyCurriculum.of(widget.progressController.state);
            return WebJourneyOverview(
              masteryCompleted: _masteryCompleted,
              masteryTotal: mastery2Catalogue.orderedDefinitions.length,
              curriculum: curriculum,
              selectedIndex: curriculum.validSelection(_overviewChapter),
              onSelectChapter: _selectChapter,
              onOpenLesson: _openLesson,
              onOpenMastery: widget.onOpenMastery,
              narrowShowsDetail: _narrowDetail,
              onNarrowBack: () => setState(() => _narrowDetail = false),
            );
          }
          final curriculum =
              JourneyCurriculum.of(widget.progressController.state);
          return _ChapterWorkspace(
            lessonKey: _lessonKey,
            curriculum: curriculum,
            navCollapsed: _navCollapsed,
            onNavCollapsed: (v) => setState(() => _navCollapsed = v),
            onSelectChapter: _selectChapterFromLesson,
            onOpenLesson: _openLesson,
            onOpenMastery: widget.onOpenMastery,
            masteryCompleted: _masteryCompleted,
            category: _chapter!,
            progressState: widget.progressController.state,
            selectedLevelId: _selectedLevelId!,
            isUnlocked: _isUnlocked,
            isCompleted: _isCompleted,
            onBackToMap: _showMap,
            onSelectLevel: _selectLevel,
            onCompleted: _complete,
            onNextLesson: _nextLesson,
            onOpenNotebook: widget.onOpenNotebook,
            onOpenNotebookEntry: widget.onOpenNotebookEntry,
            layout: widget.layout,
            isActive: widget.isActive,
          );
        },
      );
}

class WebMasteryWorkspace extends StatefulWidget {
  const WebMasteryWorkspace({
    super.key,
    required this.progressController,
    required this.onBackToJourney,
    required this.onOpenNotebook,
    this.onOpenNotebookEntry,
    this.onOpenNotebookArticle,
    this.layout,
    this.isActive = true,
    this.requestedChallengeId,
    this.challengeRequestSerial = 0,
  });

  final CampaignProgressController progressController;

  /// Opens a Notebook article (gate reference) by its stable ID.
  final ValueChanged<String>? onOpenNotebookArticle;

  /// A challenge another destination asked to open.
  final String? requestedChallengeId;
  final int challengeRequestSerial;
  final VoidCallback onBackToJourney;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;

  /// Shared Composer workspace layout preferences (circuit challenges).
  final WorkspaceLayoutController? layout;

  /// Whether Mastery is the visible destination (keyboard shortcuts).
  final bool isActive;

  @override
  State<WebMasteryWorkspace> createState() => _WebMasteryWorkspaceState();
}

/// Mastery destination: the challenge library and the open challenge.
///
/// Browser state (selection, search, filters, list scroll) and the open
/// activity are independent: returning from a challenge restores the
/// library exactly as it was left, and browsing never resets the open
/// activity. Mastery has no required order; every challenge is open.
class _WebMasteryWorkspaceState extends State<WebMasteryWorkspace> {
  /// Selected in the library (details shown); presentation only.
  String? _selectedSemanticId;

  /// The challenge whose activity is open (kept alive while browsing).
  String? _openSemanticId;
  bool _showOverview = true;
  bool _narrowDetail = false;
  MasteryLibraryQuery _query = const MasteryLibraryQuery();

  /// The learner's choice to show the full list beside an open challenge;
  /// null: the rail for circuit challenges, the list for questions (when
  /// there is room).
  bool? _paneExpanded;

  /// Keeps the open activity (its session, circuit and hints) alive when a
  /// resize moves it between the narrow and the wide arrangement.
  final GlobalKey _activityKey = GlobalKey(debugLabel: 'mastery-activity');
  final TextEditingController _search = TextEditingController();
  final ScrollController _listScroll = ScrollController();

  List<MasteryChallengeDefinition> get _challenges =>
      mastery2Catalogue.orderedDefinitions;

  @override
  void initState() {
    super.initState();
    _openRequested();
  }

  @override
  void didUpdateWidget(covariant WebMasteryWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challengeRequestSerial != widget.challengeRequestSerial) {
      _openRequested();
    }
  }

  void _openRequested() {
    final id = widget.requestedChallengeId;
    if (id == null || mastery2Catalogue.bySemanticId(id) == null) return;
    _selectedSemanticId = id;
    _openSemanticId = id;
    _showOverview = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _search.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  void _selectInLibrary(String id) => setState(() {
        _selectedSemanticId = id;
        _narrowDetail = true;
      });

  void _open(String id) {
    setState(() {
      _selectedSemanticId = id;
      _openSemanticId = id;
      _showOverview = false;
    });
    _revealInList(id);
  }

  /// Keeps the open challenge's row in view in the persistent list.
  void _revealInList(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listScroll.hasClients) return;
      final completed =
          widget.progressController.state.completedMasterySemanticIds;
      final visible = _challenges
          .where((c) => _query.matches(c, completed))
          .map((c) => c.semanticId)
          .toList();
      final index = visible.indexOf(id);
      if (index < 0) return;
      final position = _listScroll.position;
      final top = WebMasteryBrowser.listTopPadding +
          index * WebMasteryBrowser.rowExtent;
      final bottom = top + WebMasteryBrowser.rowExtent;
      if (top >= position.pixels &&
          bottom <= position.pixels + position.viewportDimension) {
        return;
      }
      _listScroll.jumpTo((top - position.viewportDimension * .3)
          .clamp(0.0, position.maxScrollExtent));
    });
  }

  void _backToLibrary() => setState(() => _showOverview = true);

  Future<void> _complete(String semanticId) async {
    if (!await saveProgressWithFeedback(context,
        () => widget.progressController.completeMasteryChallenge(semanticId))) {
      return;
    }
    if (mounted) setState(() {});
  }

  void _move(int offset) {
    final index =
        _challenges.indexWhere((c) => c.semanticId == _openSemanticId);
    final next = index + offset;
    if (index >= 0 && next >= 0 && next < _challenges.length) {
      _open(_challenges[next].semanticId);
    }
  }

  /// Initial library selection: the first incomplete challenge, else the
  /// first one.
  MasteryChallengeDefinition? _defaultSelection(Set<String> completed) =>
      _challenges.firstWhere((c) => !completed.contains(c.semanticId),
          orElse: () => _challenges.first);

  Widget _activity(
      MasteryChallengeDefinition active, CampaignProgressState state,
      {bool compact = false}) {
    final index =
        _challenges.indexWhere((c) => c.semanticId == active.semanticId);
    final completedCount = _challenges
        .where((c) => state.completedMasterySemanticIds.contains(c.semanticId))
        .length;
    final done = state.completedMasterySemanticIds.contains(active.semanticId);
    final isCircuit = active.levelDefinition is ComposerLevel;
    final trailing = Column(
      key: const ValueKey('web-mastery-workspace-header'),
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('web-mastery-previous'),
              tooltip: 'Previous challenge',
              onPressed: index > 0 ? () => _move(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Challenge ${index + 1} of ${_challenges.length}',
                key: const ValueKey('web-mastery-position')),
            IconButton(
              key: const ValueKey('web-mastery-next'),
              tooltip: 'Next challenge',
              onPressed: index + 1 < _challenges.length ? () => _move(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Text('$completedCount / ${_challenges.length} complete',
            key: const ValueKey('web-mastery-progress'), style: QqType.navMeta),
        Text(done ? 'Completed' : 'Incomplete',
            key: const ValueKey('web-mastery-active-status'),
            style: QqType.navMeta),
      ],
    );
    // Narrow (M11D.1): one row with back, previous/next and the position;
    // the counts follow on the same line. The header scrolls with the work.
    final compactNavigation = Wrap(
      key: const ValueKey('web-mastery-workspace-header'),
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        IconButton(
          key: const ValueKey('web-mastery-previous'),
          tooltip: 'Previous challenge',
          visualDensity: VisualDensity.compact,
          onPressed: index > 0 ? () => _move(-1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Challenge ${index + 1} of ${_challenges.length}',
            key: const ValueKey('web-mastery-position'),
            style: QqType.navLabel),
        IconButton(
          key: const ValueKey('web-mastery-next'),
          tooltip: 'Next challenge',
          visualDensity: VisualDensity.compact,
          onPressed: index + 1 < _challenges.length ? () => _move(1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        Text('$completedCount / ${_challenges.length} complete',
            key: const ValueKey('web-mastery-progress'), style: QqType.navMeta),
        const Text(' · ', style: QqType.navMeta),
        Text(done ? 'Completed' : 'Incomplete',
            key: const ValueKey('web-mastery-active-status'),
            style: QqType.navMeta),
      ],
    );
    WebActivityContextHeader header({required bool compact}) =>
        WebActivityContextHeader(
          key: ValueKey('web-mastery-header-${active.semanticId}'),
          backKey: const ValueKey('web-mastery-back-overview'),
          backTooltip: 'Back to Mastery Challenges',
          onBack: _backToLibrary,
          breadcrumb: 'Mastery Challenges  /  Challenge ${active.displayOrder}',
          level: active.levelDefinition,
          presentation: requireMasteryPresentation(active.semanticId),
          // Question challenges present their full task and evidence in
          // the page body; circuit challenges keep it with the workspace.
          showInstruction: isCircuit,
          objectiveKey: const ValueKey('mastery-task-instruction'),
          status: done ? 'Completed · review' : null,
          compact: compact,
          compactNavigation: compact ? compactNavigation : null,
          trailing: compact ? null : trailing,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          header(compact: false),
          const Divider(height: 1, color: _border),
        ],
        Expanded(
          key: const ValueKey('web-mastery-activity'),
          child: WebLessonWorkspace(
            key: ValueKey('web-mastery-activity-${active.semanticId}'),
            levelId: active.displayOrder,
            masteryChallenge: active,
            level: active.levelDefinition,
            alreadyCompleted: done,
            onCompleted: () => _complete(active.semanticId),
            onNextLesson: () => _move(1),
            onBackToChapter: _backToLibrary,
            backLabel: 'Back to Mastery',
            onOpenNotebook: widget.onOpenNotebook,
            onOpenNotebookEntry: widget.onOpenNotebookEntry,
            compactJourneyHeader: true,
            layout: widget.layout,
            shortcutsEnabled: widget.isActive && !_showOverview,
            contextLabel: 'Challenge ${active.displayOrder}',
            scrollingHeader: compact ? header(compact: true) : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.progressController,
        builder: (context, _) {
          if (!widget.progressController.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final state = widget.progressController.state;
          final completed = state.completedMasterySemanticIds;
          final selected =
              mastery2Catalogue.bySemanticId(_selectedSemanticId ?? '') ??
                  _defaultSelection(completed);
          final active = mastery2Catalogue.bySemanticId(_openSemanticId ?? '');
          final activity = !_showOverview && active != null;
          WebMasteryBrowser browser(MasteryBrowserPart part,
                  {VoidCallback? onCollapse}) =>
              WebMasteryBrowser(
                key: part == MasteryBrowserPart.pane
                    ? const ValueKey('web-mastery-browser-pane')
                    : null,
                part: part,
                challenges: _challenges,
                completedIds: completed,
                selected: selected,
                openSemanticId: _openSemanticId,
                query: _query,
                searchController: _search,
                listController: _listScroll,
                onQuery: (q) => setState(() => _query = q),
                // Beside an open challenge the list is navigation: a row
                // opens that challenge, like previous and next.
                onSelect: activity ? _open : _selectInLibrary,
                onStart: _open,
                onOpenNotebookArticle: widget.onOpenNotebookArticle,
                onBackToJourney: widget.onBackToJourney,
                narrowShowsDetail: _narrowDetail,
                onNarrowBack: () => setState(() => _narrowDetail = false),
                onCollapsePane: onCollapse,
              );
          return Material(
            color: QubitQuestSurfaces.page,
            child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width < WebMasteryBrowser.masterDetailWidth) {
                // Narrow: the library and the open activity alternate; the
                // activity stays alive while browsing.
                return IndexedStack(
                  index: activity ? 1 : 0,
                  sizing: StackFit.expand,
                  children: [
                    browser(MasteryBrowserPart.full),
                    if (active == null)
                      const SizedBox.shrink()
                    else
                      KeyedSubtree(
                          key: _activityKey,
                          child: _activity(active, state, compact: true)),
                  ],
                );
              }
              // Wide (M11B prototypes 9 and 10): one list pane stays mounted
              // beside the details or the open challenge, so its search,
              // filters and scroll position survive starting a challenge. A
              // circuit challenge collapses it to a numbered rail by default
              // so the circuit gets the width.
              final circuit = active?.levelDefinition is ComposerLevel;
              final roomForPane = width >= (circuit ? 1180 : 1100);
              final rail =
                  activity && !(_paneExpanded ?? (!circuit && roomForPane));
              final paneWidth = width >= 1400 ? 360.0 : 320.0;
              return Row(
                key: const ValueKey('web-mastery-master-detail'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (rail)
                    _MasteryRail(
                      challenges: _challenges
                          .where((c) => _query.matches(c, completed))
                          .toList(),
                      completed: completed,
                      openId: _openSemanticId,
                      onOpen: _open,
                      onExpand: () => setState(() => _paneExpanded = true),
                    ),
                  Offstage(
                    offstage: rail,
                    child: SizedBox(
                      width: paneWidth,
                      child: browser(MasteryBrowserPart.pane,
                          onCollapse: activity
                              ? () => setState(() => _paneExpanded = false)
                              : null),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: _border),
                  Expanded(
                    child: IndexedStack(
                      index: activity ? 1 : 0,
                      sizing: StackFit.expand,
                      children: [
                        browser(MasteryBrowserPart.detail),
                        if (active == null)
                          const SizedBox.shrink()
                        else
                          KeyedSubtree(
                              key: _activityKey,
                              child: _activity(active, state)),
                      ],
                    ),
                  ),
                ],
              );
            }),
          );
        },
      );
}

/// A circuit challenge's compact challenge navigation (M11B prototype 10):
/// the numbers of the challenges in the current results, their status and
/// the open one, with a control to bring the full list back.
class _MasteryRail extends StatelessWidget {
  const _MasteryRail({
    required this.challenges,
    required this.completed,
    required this.openId,
    required this.onOpen,
    required this.onExpand,
  });

  final List<MasteryChallengeDefinition> challenges;
  final Set<String> completed;
  final String? openId;
  final ValueChanged<String> onOpen;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('web-mastery-rail'),
        width: 64,
        color: QubitQuestSurfaces.section,
        child: Column(
          children: [
            const SizedBox(height: 8),
            IconButton(
              key: const ValueKey('web-mastery-rail-expand'),
              tooltip: 'Show the challenge list',
              onPressed: onExpand,
              icon: const Icon(Icons.menu_rounded, size: 20),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: challenges.length,
                itemExtent: 40,
                itemBuilder: (context, i) {
                  final c = challenges[i];
                  final open = c.semanticId == openId;
                  final done = completed.contains(c.semanticId);
                  return Tooltip(
                    message: '${c.displayOrder}. ${c.title}'
                        '${done ? ' · completed' : ''}',
                    child: InkWell(
                      key: ValueKey('web-mastery-rail-${c.semanticId}'),
                      borderRadius: QubitQuestRadii.control,
                      onTap: () => onOpen(c.semanticId),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: QubitQuestRadii.control,
                          color: open
                              ? QubitQuestColors.accentInteractive
                                  .withValues(alpha: .16)
                              : null,
                        ),
                        child: Text(
                          '${c.displayOrder}',
                          style: QqType.navMeta.copyWith(
                            fontSize: 13.5,
                            fontWeight:
                                open ? FontWeight.w600 : FontWeight.w500,
                            color: open
                                ? QubitQuestColors.accentInteractive
                                : done
                                    ? QubitQuestColors.success
                                    : QubitQuestColors.textBody,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _ChapterWorkspace extends StatelessWidget {
  const _ChapterWorkspace({
    required this.lessonKey,
    required this.curriculum,
    required this.navCollapsed,
    required this.onNavCollapsed,
    required this.onSelectChapter,
    required this.onOpenLesson,
    this.onOpenMastery,
    this.masteryCompleted,
    required this.category,
    required this.progressState,
    required this.selectedLevelId,
    required this.isUnlocked,
    required this.isCompleted,
    required this.onBackToMap,
    required this.onSelectLevel,
    required this.onCompleted,
    required this.onNextLesson,
    required this.onOpenNotebook,
    this.onOpenNotebookEntry,
    this.layout,
    this.isActive = true,
  });

  final GlobalKey lessonKey;
  final JourneyCurriculum curriculum;
  final bool? navCollapsed;
  final ValueChanged<bool> onNavCollapsed;
  final ValueChanged<int> onSelectChapter;
  final ValueChanged<int> onOpenLesson;
  final VoidCallback? onOpenMastery;
  final int? masteryCompleted;

  /// Host widths: the curriculum sits beside the lesson from [_navFrom];
  /// it starts as a rail below [_navAutoCollapseBelow] unless the learner
  /// chose otherwise. Narrower hosts get the chapter strip.
  static const double _navFrom = 900;
  static const double _navAutoCollapseBelow = 1200;

  final QQLevelsCategory category;
  final CampaignProgressState progressState;
  final int selectedLevelId;
  final bool Function(int, CampaignProgressState) isUnlocked;
  final bool Function(int, CampaignProgressState) isCompleted;
  final VoidCallback onBackToMap;
  final ValueChanged<int> onSelectLevel;
  final Future<void> Function(int) onCompleted;
  final VoidCallback onNextLesson;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;
  final WorkspaceLayoutController? layout;
  final bool isActive;

  List<int> get _levelIds => [
        for (int index = category.from; index <= category.to; index++)
          index + 1,
      ];

  @override
  Widget build(BuildContext context) {
    final level = getJourneyLessonById(selectedLevelId)!;
    final chapterNumber = journeyChapters.indexOf(category) + 1;
    final lessonNumber = '$chapterNumber.${selectedLevelId - category.from}';
    final completedHere =
        _levelIds.where((id) => isCompleted(id, progressState)).length;
    final reviewing = isCompleted(selectedLevelId, progressState);
    final chooser = _LessonChooser(
      levelIds: _levelIds,
      selectedLevelId: selectedLevelId,
      progressState: progressState,
      isUnlocked: isUnlocked,
      isCompleted: isCompleted,
      onSelected: onSelectLevel,
    );
    WebActivityContextHeader header({required bool compact}) =>
        WebActivityContextHeader(
          key: ValueKey('web-lesson-header-$selectedLevelId'),
          backKey: const ValueKey('web-journey-back-map'),
          backTooltip: 'Back to the chapter in the Journey',
          onBack: onBackToMap,
          breadcrumb: 'Journey  /  Ch $chapterNumber '
              '${journeyChapterTitle(category)}  /  $lessonNumber',
          breadcrumbInfo: category.categoryIntro,
          level: level,
          status: reviewing ? 'Completed · review' : null,
          compact: compact,
          // Narrow: the chapter strip carries chapter, progress and the
          // lesson chooser, so the header names only the lesson.
          compactNavigation: compact
              ? Text('Lesson $lessonNumber',
                  key: const ValueKey('web-activity-breadcrumb'),
                  style: QqType.breadcrumb)
              : null,
          trailing: compact
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    chooser,
                    const SizedBox(height: 5),
                    Text(
                      '$completedHere / ${_levelIds.length} complete',
                      key: const ValueKey('web-chapter-progress'),
                      style: QqType.navMeta,
                    ),
                  ],
                ),
        );
    WebLessonWorkspace lesson({Widget? scrollingHeader}) => WebLessonWorkspace(
          key: ValueKey('web-lesson-$selectedLevelId'),
          levelId: selectedLevelId,
          level: level,
          alreadyCompleted: reviewing,
          onCompleted: () => onCompleted(selectedLevelId),
          onNextLesson: onNextLesson,
          onBackToChapter: onBackToMap,
          backLabel: 'Back to chapter',
          onOpenNotebook: onOpenNotebook,
          onOpenNotebookEntry: onOpenNotebookEntry,
          compactJourneyHeader: true,
          journeyActivity: true,
          layout: layout,
          shortcutsEnabled: isActive,
          contextLabel: 'Lesson $lessonNumber',
          scrollingHeader: scrollingHeader,
        );
    final chapterIndex = journeyChapters.indexOf(category);
    // One keyed subtree in both arrangements: wide hosts fix the header
    // above the work, narrow hosts scroll it with the work so the task and
    // circuit come first (M11D.1).
    Widget body({required bool compact}) => KeyedSubtree(
          key: lessonKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact) ...[
                header(compact: false),
                const Divider(height: 1, color: _border),
              ],
              Expanded(
                key: const ValueKey('web-chapter-activity'),
                child: compact
                    ? lesson(scrollingHeader: header(compact: true))
                    : lesson(),
              ),
            ],
          ),
        );
    Widget main({Widget? strip}) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (strip != null) strip,
            Expanded(child: body(compact: strip != null)),
          ],
        );
    return ColoredBox(
      color: QubitQuestSurfaces.page,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < _navFrom) {
          return main(
            strip: _ChapterStrip(
              chapterNumber: chapterNumber,
              chapterTitle: curriculum.chapters[chapterIndex].title,
              levelIds: _levelIds,
              selectedLevelId: selectedLevelId,
              isCompleted: (id) => isCompleted(id, progressState),
              onChapters: onBackToMap,
              chooser: chooser,
              completedHere: completedHere,
            ),
          );
        }
        final collapsed = navCollapsed ?? width < _navAutoCollapseBelow;
        return Row(
          key: const ValueKey('journey-lesson-with-nav'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: collapsed
                  ? JourneyCurriculumNav.railWidth
                  : JourneyCurriculumNav.width,
              color: QubitQuestSurfaces.section,
              child: JourneyCurriculumNav(
                curriculum: curriculum,
                selectedIndex: chapterIndex,
                expandedIndex: chapterIndex,
                currentLessonId: selectedLevelId,
                onSelectChapter: onSelectChapter,
                onOpenLesson: onOpenLesson,
                collapsed: collapsed,
                onToggleCollapsed: () => onNavCollapsed(!collapsed),
                masteryCompleted: masteryCompleted,
                masteryTotal: mastery2Catalogue.orderedDefinitions.length,
                onOpenMastery: onOpenMastery,
              ),
            ),
            const VerticalDivider(width: 1, color: _border),
            Expanded(child: main()),
          ],
        );
      }),
    );
  }
}

/// Narrow hosts: where the learner is in the chapter, compactly (M11B
/// prototype 6, "Ch 14 · ▮▮▮▯▯ · Viewing 14.1 of 5"), with a way back to
/// the chapters. The lesson chooser in the header switches lessons.
class _ChapterStrip extends StatelessWidget {
  const _ChapterStrip({
    required this.chapterNumber,
    required this.chapterTitle,
    required this.levelIds,
    required this.selectedLevelId,
    required this.isCompleted,
    required this.onChapters,
    required this.chooser,
    required this.completedHere,
  });

  final Widget chooser;
  final int completedHere;
  final int chapterNumber;
  final String chapterTitle;
  final List<int> levelIds;
  final int selectedLevelId;
  final bool Function(int) isCompleted;
  final VoidCallback onChapters;

  @override
  Widget build(BuildContext context) {
    final position = levelIds.indexOf(selectedLevelId) + 1;
    return Container(
      key: const ValueKey('journey-chapter-strip'),
      color: QubitQuestSurfaces.section,
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      child: Row(
        children: [
          TextButton.icon(
            key: const ValueKey('journey-strip-chapters'),
            onPressed: onChapters,
            icon: const Icon(Icons.list_rounded, size: 18),
            label: const Text('Chapters'),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Ch $chapterNumber $chapterTitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: QqType.navLabel,
            ),
          ),
          const SizedBox(width: 10),
          if (MediaQuery.sizeOf(context).width >= 460)
            Semantics(
              label: 'Lesson $position of ${levelIds.length}',
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final id in levelIds)
                    Container(
                      width: 14,
                      height: 6,
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: id == selectedLevelId
                            ? QubitQuestColors.accentInteractive
                            : isCompleted(id)
                                ? QubitQuestColors.success.withValues(alpha: .7)
                                : QubitQuestColors.surfaceRaised,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Tooltip(
              message: '$completedHere of ${levelIds.length} complete',
              child: chooser,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonChooser extends StatelessWidget {
  const _LessonChooser({
    required this.levelIds,
    required this.selectedLevelId,
    required this.progressState,
    required this.isUnlocked,
    required this.isCompleted,
    required this.onSelected,
  });

  final List<int> levelIds;
  final int selectedLevelId;
  final CampaignProgressState progressState;
  final bool Function(int, CampaignProgressState) isUnlocked;
  final bool Function(int, CampaignProgressState) isCompleted;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = levelIds.indexOf(selectedLevelId) + 1;
    return PopupMenuButton<int>(
      key: const ValueKey('web-lesson-chooser'),
      tooltip: 'Open chapter lessons',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final (index, id) in levelIds.indexed)
          PopupMenuItem<int>(
            key: ValueKey('web-lesson-choice-$id'),
            value: id,
            enabled: isUnlocked(id, progressState),
            child: Row(
              children: [
                Icon(
                  isCompleted(id, progressState)
                      ? Icons.check_circle
                      : id == selectedLevelId
                          ? Icons.radio_button_checked
                          : isUnlocked(id, progressState)
                              ? Icons.radio_button_unchecked
                              : Icons.lock_outline,
                  size: 18,
                  color: isCompleted(id, progressState)
                      ? Colors.greenAccent
                      : isUnlocked(id, progressState)
                          ? _cyan
                          : Colors.white38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${index + 1}. ${getJourneyLessonById(id)!.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        key: const ValueKey('web-current-lesson-position'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: QubitQuestRadii.control,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                MediaQuery.sizeOf(context).width < 480
                    ? '$selectedIndex of ${levelIds.length}'
                    : 'Lesson $selectedIndex of ${levelIds.length}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QqType.control.copyWith(fontSize: 13.5),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18),
          ],
        ),
      ),
    );
  }
}

class WebLessonWorkspace extends StatefulWidget {
  const WebLessonWorkspace({
    super.key,
    required this.levelId,
    this.activityDomain = NumericActivityDomain.journey,
    required this.level,
    required this.alreadyCompleted,
    required this.onCompleted,
    required this.onNextLesson,
    required this.onBackToChapter,
    required this.onOpenNotebook,
    this.onOpenNotebookEntry,
    this.masteryChallenge,
    this.compactJourneyHeader = false,
    this.journeyActivity = false,
    this.layout,
    this.shortcutsEnabled = true,
    this.contextLabel,
    this.backLabel,
    this.scrollingHeader,
  });

  /// The activity header placed inside the page's scroll (narrow hosts).
  final Widget? scrollingHeader;

  final NumericActivityDomain activityDomain;
  final int levelId;
  final QQLevel level;
  final bool alreadyCompleted;
  final Future<void> Function() onCompleted;
  final VoidCallback onNextLesson;
  final VoidCallback onBackToChapter;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;
  final MasteryChallengeDefinition? masteryChallenge;

  /// The host shows the lesson's identity and instruction in its own
  /// context header, so the page body does not repeat them.
  final bool compactJourneyHeader;

  /// A Journey lesson (rather than a standalone activity page).
  final bool journeyActivity;

  /// Shared Composer workspace layout preferences (circuit activities).
  final WorkspaceLayoutController? layout;

  /// Whether the activity's workspace takes undo/redo shortcuts (it is the
  /// visible destination).
  final bool shortcutsEnabled;

  /// Context shown in the workspace toolbar, e.g. "Lesson 3.3".
  final String? contextLabel;
  final String? backLabel;

  @override
  State<WebLessonWorkspace> createState() => _WebLessonWorkspaceState();
}

class _WebLessonWorkspaceState extends State<WebLessonWorkspace> {
  bool _solved = false;
  final _choiceKey = GlobalKey<_WebChoiceLessonState>();

  /// Whether the sticky Check Answer may run (an answer is selected).
  final _canCheck = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _canCheck.dispose();
    super.dispose();
  }

  bool _saving = false;

  bool get _isMastery =>
      widget.masteryChallenge != null ||
      widget.activityDomain == NumericActivityDomain.historicalMastery;

  Future<void> _complete() async {
    if (_solved || _saving) return;
    setState(() => _saving = true);
    await widget.onCompleted();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _solved = true;
    });
  }

  MasteryChallengePresentation? get _masteryPresentation {
    final challenge = widget.masteryChallenge;
    return challenge == null
        ? null
        : requireMasteryPresentation(challenge.semanticId);
  }

  String get _identity => widget.masteryChallenge != null
      ? 'Mastery Challenge ${widget.masteryChallenge!.displayOrder}'
      : widget.activityDomain == NumericActivityDomain.historicalMastery
          ? 'Mastery Challenge ${ProgressionRules.masteryChallengeNumber(widget.levelId)}'
          : 'Lesson ${widget.levelId}';

  /// Circuit activities use the shared desktop Composer workspace (M6a);
  /// the host above it carries the lesson identity and objective.
  Widget _circuitExercise(ComposerLevel level) => WebComposerExercise(
        key: ValueKey('web-composer-exercise-${widget.levelId}'),
        level: level,
        mode: widget.masteryChallenge != null
            ? ComposerMode.masteryChallenge
            : ComposerMode.journeyExercise,
        contextLabel: widget.contextLabel ?? _identity,
        layout: widget.layout,
        shortcutsEnabled: widget.shortcutsEnabled,
        onCompleted: widget.onCompleted,
        onNext: widget.onNextLesson,
        onBack: widget.onBackToChapter,
        backLabel: widget.backLabel,
        onOpenNotebook: widget.onOpenNotebook,
        onOpenNotebookEntry: widget.onOpenNotebookEntry,
        header: widget.compactJourneyHeader ? null : _standaloneHeader(),
        scrollingHeader: widget.scrollingHeader,
      );

  /// Identity and objective when no host header provides them.
  Widget _standaloneHeader() => Padding(
        key: ValueKey('web-lesson-content-${widget.levelId}'),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_identity,
                style: const TextStyle(
                    color: _purple,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .7,
                    fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              widget.level.title ?? 'Quantum Challenge',
              key: const ValueKey('web-lesson-title'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 14),
            // Mastery tasks share one outer Task panel across all challenge
            // types; Journey lessons present the brief directly.
            if (widget.masteryChallenge != null)
              _ContentCard(
                key: const ValueKey('web-lesson-1-learning-brief'),
                title: 'Task',
                icon: Icons.flag_outlined,
                child: WebActivityInstructionContent(
                  level: widget.level,
                  presentation: _masteryPresentation,
                  questionKey: const ValueKey('mastery-task-instruction'),
                ),
              )
            else
              WebActivityInstructionContent(
                key: const ValueKey('web-lesson-1-learning-brief'),
                level: widget.level,
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    if (level is ComposerLevel) return _circuitExercise(level);
    // Non-circuit activities (concept checks, questions): a reading-width
    // page; no Composer is created for them. Questions get the same sticky
    // action bar as circuit activities (M11D.1), so Check is always in one
    // place: bottom right.
    final page = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          key: ValueKey('web-lesson-content-${widget.levelId}'),
          padding: EdgeInsets.fromLTRB(
            22,
            widget.compactJourneyHeader ? 12 : 22,
            22,
            22,
          ),
          children: [
            if (widget.scrollingHeader case final h?) ...[
              h,
              const SizedBox(height: 8),
            ],
            if (!widget.compactJourneyHeader) ...[
              Text(
                _identity,
                style: const TextStyle(
                  color: _purple,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.level.title ?? 'Quantum Challenge',
                key: const ValueKey('web-lesson-title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
            if (!widget.compactJourneyHeader ||
                widget.masteryChallenge != null) ...[
              const SizedBox(height: 14),
              _ContentCard(
                title: 'Task',
                icon: Icons.flag_outlined,
                child: WebActivityInstructionContent(
                  level: widget.level,
                  presentation: _masteryPresentation,
                  questionKey: widget.masteryChallenge != null
                      ? const ValueKey('mastery-task-instruction')
                      : null,
                ),
              ),
            ],
            if (!widget.compactJourneyHeader &&
                ((widget.level.targetStateLabel ?? '').trim().isNotEmpty ||
                    (widget.level.targetStateExpression ?? '')
                        .trim()
                        .isNotEmpty)) ...[
              const SizedBox(height: 10),
              Text(
                [
                  widget.level.targetStateLabel,
                  widget.level.targetStateExpression,
                ]
                    .whereType<String>()
                    .where((value) => value.trim().isNotEmpty)
                    .join('  '),
                style:
                    const TextStyle(color: _cyan, fontWeight: FontWeight.w800),
              ),
            ],
            if (widget.level.hints?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              // A compact disclosure, like More context and the Composer's
              // precision note; it reveals every authored hint at once.
              QqDisclosure(
                key: const ValueKey('web-lesson-hints'),
                title: 'Hints (${widget.level.hints!.length})',
                summary: 'Reveal authored hints',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, hint) in widget.level.hints!.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 22,
                              child:
                                  Text('${index + 1}.', style: QqType.navMeta),
                            ),
                            Expanded(
                              child: WebLearningText(hint,
                                  role: WebLearningTextRole.hint),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _lessonInteraction(widget.level),
            if (_saving) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
            if (_solved) ...[
              const SizedBox(height: 16),
              WebActivitySuccessPanel(
                level: widget.level,
                isMastery: _isMastery,
                onOpenNotebook: widget.onOpenNotebook,
                onOpenNotebookEntry: widget.onOpenNotebookEntry,
                onNext: widget.onNextLesson,
                onBack: widget.onBackToChapter,
                backLabel: widget.backLabel,
              ),
            ],
          ],
        ),
      ),
    );
    if (level is! McqLevel) return page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: page),
        _AnswerActionBar(
          canCheck: _canCheck,
          onCheck: () => _choiceKey.currentState?.confirm(),
        ),
      ],
    );
  }

  Widget _lessonInteraction(QQLevel level) => switch (level) {
        ComposerLevel composer => _circuitExercise(composer),
        FillTheGateLevel fill => _WebFillGateLesson(
            level: fill,
            enabled: !_solved,
            onSolved: _complete,
          ),
        CircuitReadingLevel reading => _WebCircuitReadingLesson(
            level: reading,
            enabled: !_solved,
            onSolved: _complete,
          ),
        MeasurementLabLevel lab => _WebMeasurementLesson(
            level: lab,
            enabled: !_solved,
            onSolved: _complete,
          ),
        McqLevel mcq => _WebChoiceLesson(
            key: _choiceKey,
            canCheck: _canCheck,
            options: mcq.options,
            correctOptionIndex: mcq.correctOptionIndex,
            enabled: !_solved,
            onSolved: _complete,
          ),
      };
}

class _ContentCard extends StatelessWidget {
  const _ContentCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => QqWorkspacePanel(
        label: title,
        child: child,
      );
}

/// The evaluator the explicit Check uses: the level's own strategy (exact
/// final state, state up to global phase, or circuit unitary). Never a
/// probability comparison.
@visibleForTesting
ComposerValidationResult validateWebComposerLesson(
  ComposerLevel level,
  QuantumCircuit circuit,
) =>
    level.evaluateCircuit(circuit);

class _WebChoiceLesson extends StatefulWidget {
  const _WebChoiceLesson({
    super.key,
    this.canCheck,
    required this.options,
    required this.correctOptionIndex,
    required this.enabled,
    required this.onSolved,
  });

  /// Drives an external Check Answer (the sticky bar); null renders the
  /// action inline under the answers (circuit-reading lessons).
  final ValueNotifier<bool>? canCheck;
  final List<String> options;
  final int correctOptionIndex;
  final bool enabled;
  final Future<void> Function() onSolved;

  @override
  State<_WebChoiceLesson> createState() => _WebChoiceLessonState();
}

class _WebChoiceLessonState extends State<_WebChoiceLesson> {
  int? _selected;
  String? _feedback;

  void _syncCanCheck() =>
      widget.canCheck?.value = widget.enabled && _selected != null;

  @override
  void didUpdateWidget(covariant _WebChoiceLesson oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCanCheck();
    });
  }

  /// The explicit Check Answer (from the sticky action bar).
  Future<void> confirm() async {
    if (!widget.enabled || _selected == null) return;
    if (_selected == widget.correctOptionIndex) {
      setState(() => _feedback = 'Correct.');
      await widget.onSolved();
    } else {
      setState(
          () => _feedback = 'Not quite. Review the concept and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final correct = _feedback == 'Correct.';
    return Column(
      key: const ValueKey('web-choice-answers'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Choose an answer',
            style: QqType.panelHeading
                .copyWith(color: QubitQuestColors.textMuted)),
        const SizedBox(height: 10),
        // Lettered answer cards (M11B prototype 9). Selection is shown by
        // the card's outline and letter only; correctness appears solely
        // after the explicit Check, below the answers.
        for (final (index, option) in widget.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AnswerCard(
              key: ValueKey('web-lesson-option-$index'),
              letter: String.fromCharCode(65 + index),
              option: option,
              selected: _selected == index,
              enabled: widget.enabled,
              onTap: () {
                setState(() {
                  _selected = index;
                  _feedback = null;
                });
                _syncCanCheck();
              },
            ),
          ),
        if (_feedback != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: QubitQuestRadii.control,
              border: Border.all(
                  color: (correct
                          ? QubitQuestColors.success
                          : QubitQuestColors.warning)
                      .withValues(alpha: .5)),
            ),
            child: Row(
              children: [
                Icon(correct ? Icons.check_circle : Icons.info_outline,
                    size: 18,
                    color: correct
                        ? QubitQuestColors.success
                        : QubitQuestColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _feedback!,
                    key: const ValueKey('web-lesson-feedback'),
                    style: QqType.body.copyWith(
                        color: correct
                            ? QubitQuestColors.success
                            : QubitQuestColors.warning),
                  ),
                ),
              ],
            ),
          ),
        if (widget.canCheck == null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const ValueKey('web-lesson-confirm'),
              onPressed: widget.enabled && _selected != null ? confirm : null,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Check Answer'),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    super.key,
    required this.letter,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String letter;
  final String option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        enabled: enabled,
        label: 'Answer $letter',
        child: Material(
          color: selected
              ? QubitQuestColors.accentInteractive.withValues(alpha: .08)
              : QubitQuestSurfaces.work,
          borderRadius: QubitQuestRadii.card,
          child: InkWell(
            borderRadius: QubitQuestRadii.card,
            onTap: enabled ? onTap : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              decoration: BoxDecoration(
                borderRadius: QubitQuestRadii.card,
                border: Border.all(
                  color: selected
                      ? QubitQuestColors.accentInteractive
                      : QubitQuestSurfaces.rule,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          selected ? QubitQuestColors.accentInteractive : null,
                      border: Border.all(
                          color: selected
                              ? QubitQuestColors.accentInteractive
                              : QubitQuestColors.textMuted),
                    ),
                    child: Text(letter,
                        style: QqType.control.copyWith(
                            fontSize: 13,
                            color: selected
                                ? QubitQuestColors.background
                                : QubitQuestColors.textBody)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: LatexText(
                        math: option,
                        // Answers that are mostly mathematics stay as
                        // legible as prose answers (M11D.1).
                        mathFontSize: 18,
                        inlineMathHeight: 18,
                        textStyle: QqType.body
                            .copyWith(color: QubitQuestColors.textPrimary),
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

class _WebFillGateLesson extends StatefulWidget {
  const _WebFillGateLesson({
    required this.level,
    required this.enabled,
    required this.onSolved,
  });
  final FillTheGateLevel level;
  final bool enabled;
  final Future<void> Function() onSolved;

  @override
  State<_WebFillGateLesson> createState() => _WebFillGateLessonState();
}

class _WebFillGateLessonState extends State<_WebFillGateLesson> {
  String? _feedback;

  Future<void> _select(Gate gate) async {
    final composerLevel = widget.level.toComposerLevelWith(gate);
    final circuit = QuantumCircuit(currentLevel: composerLevel);
    final correct = circuit.currentState.state
        .almostEqualTo(QuantumMatrix(widget.level.solutionFinalVector));
    circuit.dispose();
    if (correct) {
      setState(() => _feedback = 'Correct gate.');
      await widget.onSolved();
    } else {
      setState(
          () => _feedback = 'That gate does not produce the target state.');
    }
  }

  @override
  Widget build(BuildContext context) => _ContentCard(
        title: 'Fill the Gate',
        icon: Icons.extension_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (index, gate) in widget.level.options.indexed)
                  QubitQuestGateTile(
                    key: ValueKey('web-fill-gate-option-$index'),
                    gate: gate,
                    size: 48,
                    onPressed: widget.enabled ? () => _select(gate) : null,
                    onInspect: null,
                  ),
              ],
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 10),
              Text(_feedback!, key: const ValueKey('web-lesson-feedback')),
            ],
          ],
        ),
      );
}

class _WebCircuitReadingLesson extends StatefulWidget {
  const _WebCircuitReadingLesson({
    required this.level,
    required this.enabled,
    required this.onSolved,
  });
  final CircuitReadingLevel level;
  final bool enabled;
  final Future<void> Function() onSolved;

  @override
  State<_WebCircuitReadingLesson> createState() =>
      _WebCircuitReadingLessonState();
}

class _WebCircuitReadingLessonState extends State<_WebCircuitReadingLesson> {
  late final QuantumCircuit _circuit;

  @override
  void initState() {
    super.initState();
    _circuit = QuantumCircuit(currentLevel: widget.level.toComposerLevel());
  }

  @override
  void dispose() {
    _circuit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ContentCard(
            title: 'Read the Circuit',
            icon: Icons.visibility_outlined,
            child: SizedBox(
              height: math.max(140, widget.level.numQubits * 42 + 42),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(620, _circuit.maxCircuitDepth() * 62 + 100),
                  child: CustomPaint(
                    painter: QuantumCircuitPainter(_circuit),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _WebChoiceLesson(
            options: widget.level.options,
            correctOptionIndex: widget.level.correctOptionIndex,
            enabled: widget.enabled,
            onSolved: widget.onSolved,
          ),
        ],
      );
}

class _WebMeasurementLesson extends StatefulWidget {
  const _WebMeasurementLesson({
    required this.level,
    required this.enabled,
    required this.onSolved,
  });
  final MeasurementLabLevel level;
  final bool enabled;
  final Future<void> Function() onSolved;

  @override
  State<_WebMeasurementLesson> createState() => _WebMeasurementLessonState();
}

class _WebMeasurementLessonState extends State<_WebMeasurementLesson> {
  late final QuantumCircuit _circuit;
  final math.Random _random = math.Random();
  final Map<String, int> _counts = {};
  int _total = 0;
  bool _completionSent = false;

  @override
  void initState() {
    super.initState();
    _circuit = QuantumCircuit(currentLevel: widget.level.toComposerLevel());
  }

  @override
  void dispose() {
    _circuit.dispose();
    super.dispose();
  }

  String _measure() {
    final List<Complex> state = _circuit.currentState.stateVector;
    final random = _random.nextDouble();
    double cumulative = 0;
    for (int index = 0; index < state.length; index++) {
      cumulative += math.pow(state[index].magnitude, 2).toDouble();
      if (random <= cumulative) {
        return '|${index.toRadixString(2).padLeft(widget.level.numQubits, '0')}⟩';
      }
    }
    return '|${'0' * widget.level.numQubits}⟩';
  }

  Future<void> _takeMeasurement() async {
    final outcome = _measure();
    setState(() {
      _counts[outcome] = (_counts[outcome] ?? 0) + 1;
      _total++;
    });
    if (_total >= widget.level.requiredMeasurements && !_completionSent) {
      _completionSent = true;
      await widget.onSolved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return _ContentCard(
      title: 'Measurement Lab',
      icon: Icons.science_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                  'Measurements: $_total / ${widget.level.requiredMeasurements}'),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: (_total / widget.level.requiredMeasurements)
                      .clamp(0.0, 1.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const Text('Measure repeatedly to reveal the distribution.',
                style: TextStyle(color: Colors.white70))
          else
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    SizedBox(width: 70, child: Text(entry.key)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value / _total,
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}'),
                  ],
                ),
              ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const ValueKey('web-lesson-measure'),
              onPressed: widget.enabled ? _takeMeasurement : null,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Measure'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The question's sticky action bar: the same place, style and reminder as
/// the circuit activities' bar, with Check Answer.
class _AnswerActionBar extends StatelessWidget {
  const _AnswerActionBar({required this.canCheck, required this.onCheck});
  final ValueListenable<bool> canCheck;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        key: const ValueKey('web-answer-actions'),
        decoration: const BoxDecoration(
          color: QubitQuestSurfaces.nav,
          border: Border(top: BorderSide(color: QubitQuestColors.border)),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            // The reading column's width (M11D.1): Check Answer sits at the
            // right edge of the answers, not in a far corner.
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    Expanded(
                      child: constraints.maxWidth >= 480
                          ? const Align(
                              alignment: Alignment.centerRight,
                              child: Text('Nothing is checked until you ask',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: QqType.meta),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 16),
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth * .6),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: canCheck,
                        builder: (context, enabled, _) => FilledButton.icon(
                          key: const ValueKey('web-lesson-confirm'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            textStyle: QqType.control.copyWith(fontSize: 15),
                          ),
                          onPressed: enabled ? onCheck : null,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Check Answer',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
