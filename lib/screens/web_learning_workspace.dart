import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/widgets/progress_save_feedback.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
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
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/web_learning_text.dart';
import 'package:quantumquiz/widgets/web_activity_instruction_content.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';
import 'package:quantumquiz/screens/web_exercise_workspace.dart';
import 'package:quantumquiz/screens/web_mastery_browser.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

const _background = QubitQuestColors.background;
const _panel = QubitQuestColors.surface;
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
  });

  final CampaignProgressController progressController;

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

  void _selectLevel(int levelId) {
    if (!_isUnlocked(levelId, widget.progressController.state)) return;
    setState(() => _selectedLevelId = levelId);
  }

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
              curriculum: curriculum,
              selectedIndex: curriculum.validSelection(_overviewChapter),
              onSelectChapter: _selectChapter,
              onOpenLesson: _openLesson,
              onOpenMastery: widget.onOpenMastery,
              narrowShowsDetail: _narrowDetail,
              onNarrowBack: () => setState(() => _narrowDetail = false),
            );
          }
          return _ChapterWorkspace(
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
    this.layout,
    this.isActive = true,
  });

  final CampaignProgressController progressController;
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
  final TextEditingController _search = TextEditingController();
  final ScrollController _listScroll = ScrollController();

  List<MasteryChallengeDefinition> get _challenges =>
      mastery2Catalogue.orderedDefinitions;

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

  void _open(String id) => setState(() {
        _selectedSemanticId = id;
        _openSemanticId = id;
        _showOverview = false;
      });

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
      MasteryChallengeDefinition active, CampaignProgressState state) {
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
            key: const ValueKey('web-mastery-progress'),
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(done ? 'Completed' : 'Incomplete',
            key: const ValueKey('web-mastery-active-status'),
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WebActivityContextHeader(
          key: ValueKey('web-mastery-header-${active.semanticId}'),
          backKey: const ValueKey('web-mastery-back-overview'),
          backTooltip: 'Back to Mastery Challenges',
          onBack: _backToLibrary,
          breadcrumb: 'Mastery Challenges  /  Challenge ${active.displayOrder}',
          level: active.levelDefinition,
          presentation: requireMasteryPresentation(active.semanticId),
          // Question challenges present their full task and evidence in
          // the page body; circuit challenges keep it above the workspace.
          showInstruction: isCircuit,
          objectiveKey: const ValueKey('mastery-task-instruction'),
          status: done ? 'Completed · review' : null,
          trailing: trailing,
        ),
        const Divider(height: 1, color: _border),
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
          return Material(
            color: _background,
            // The open activity stays alive while browsing or resizing; only
            // starting a different challenge starts a new activity session.
            child: IndexedStack(
              index: _showOverview || active == null ? 0 : 1,
              sizing: StackFit.expand,
              children: [
                WebMasteryBrowser(
                  challenges: _challenges,
                  completedIds: completed,
                  selected: selected,
                  openSemanticId: _openSemanticId,
                  query: _query,
                  searchController: _search,
                  listController: _listScroll,
                  onQuery: (q) => setState(() => _query = q),
                  onSelect: _selectInLibrary,
                  onStart: _open,
                  onBackToJourney: widget.onBackToJourney,
                  narrowShowsDetail: _narrowDetail,
                  onNarrowBack: () => setState(() => _narrowDetail = false),
                ),
                if (active == null)
                  const SizedBox.shrink()
                else
                  _activity(active, state),
              ],
            ),
          );
        },
      );
}

class _ChapterWorkspace extends StatelessWidget {
  const _ChapterWorkspace({
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
    final header = WebActivityContextHeader(
      key: ValueKey('web-lesson-header-$selectedLevelId'),
      backKey: const ValueKey('web-journey-back-map'),
      backTooltip: 'Back to the chapter in the Journey',
      onBack: onBackToMap,
      breadcrumb: 'Journey  /  '
          '${category.groupName.replaceFirst(' - ', ' — ')}  /  '
          'Lesson $lessonNumber',
      breadcrumbInfo: category.categoryIntro,
      level: level,
      status: reviewing ? 'Completed · review' : null,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LessonChooser(
            levelIds: _levelIds,
            selectedLevelId: selectedLevelId,
            progressState: progressState,
            isUnlocked: isUnlocked,
            isCompleted: isCompleted,
            onSelected: onSelectLevel,
          ),
          const SizedBox(height: 5),
          Text(
            '$completedHere / ${_levelIds.length} complete',
            key: const ValueKey('web-chapter-progress'),
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
    final lesson = WebLessonWorkspace(
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
    );
    return ColoredBox(
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Divider(height: 1, color: _border),
          Expanded(
            key: const ValueKey('web-chapter-activity'),
            child: lesson,
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
            Text(
              'Lesson $selectedIndex of ${levelIds.length}',
              style: const TextStyle(fontWeight: FontWeight.w500),
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
  });

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
    // page; no Composer is created for them.
    return Align(
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
              const SizedBox(height: 14),
              _ContentCard(
                title: 'Hints',
                icon: Icons.lightbulb_outline,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Reveal authored hints'),
                  children: [
                    for (final (index, hint) in widget.level.hints!.indexed)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 13,
                          child: Text('${index + 1}'),
                        ),
                        title: WebLearningText(hint,
                            role: WebLearningTextRole.hint),
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
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: _cyan, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
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
    required this.options,
    required this.correctOptionIndex,
    required this.enabled,
    required this.onSolved,
  });
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

  Future<void> _confirm() async {
    if (_selected == widget.correctOptionIndex) {
      setState(() => _feedback = 'Correct.');
      await widget.onSolved();
    } else {
      setState(
          () => _feedback = 'Not quite. Review the concept and try again.');
    }
  }

  @override
  Widget build(BuildContext context) => _ContentCard(
        title: 'Choose an answer',
        icon: Icons.quiz_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RadioGroup<int>(
              groupValue: _selected,
              onChanged: widget.enabled
                  ? (value) => setState(() {
                        _selected = value;
                        _feedback = null;
                      })
                  : (_) {},
              child: Column(
                children: [
                  for (final (index, option) in widget.options.indexed)
                    RadioListTile<int>(
                      key: ValueKey('web-lesson-option-$index'),
                      value: index,
                      enabled: widget.enabled,
                      title: LatexText(
                        math: option,
                        textStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            if (_feedback != null)
              Text(
                _feedback!,
                key: const ValueKey('web-lesson-feedback'),
                style: TextStyle(
                  color: _feedback == 'Correct.'
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const ValueKey('web-lesson-confirm'),
                onPressed:
                    widget.enabled && _selected != null ? _confirm : null,
                child: const Text('Confirm Answer'),
              ),
            ),
          ],
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
