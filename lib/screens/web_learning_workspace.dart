import 'dart:async';
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/qq_levels_category.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/controlled_gate_placement_dialog.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';
import 'package:quantumquiz/widgets/circuit_canvas_metrics.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/activity_instruction_presentation.dart';
import 'package:quantumquiz/widgets/mastery_evidence_view.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart'
    show defaultNonZeroOnlyForQubitCount;
import 'package:quantumquiz/widgets/quantum_state_inspector_content.dart';
import 'package:quantumquiz/widgets/web_composer_workbench.dart';
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
  });

  final CampaignProgressController progressController;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;
  final VoidCallback? onOpenMastery;

  @override
  State<WebJourneyWorkspace> createState() => _WebJourneyWorkspaceState();
}

class _WebJourneyWorkspaceState extends State<WebJourneyWorkspace> {
  _JourneyView _view = _JourneyView.map;
  QQLevelsCategory? _chapter;
  int? _selectedLevelId;

  QQLevelsCategory? _categoryForLevel(int levelId) {
    final index = levelId - 1;
    for (final category in groupedLevels) {
      if (index >= category.from && index <= category.to) return category;
    }
    return null;
  }

  Future<void> _openChapter(int firstLevelId) async {
    final category = _categoryForLevel(firstLevelId);
    if (category == null) return;
    if (category.isMasteryPhase && widget.onOpenMastery != null) {
      widget.onOpenMastery!();
      return;
    }
    setState(() {
      _chapter = category;
      _selectedLevelId = firstLevelId;
      _view = _JourneyView.chapter;
    });
  }

  void _showMap() => setState(() {
        _view = _JourneyView.map;
        _chapter = null;
        _selectedLevelId = null;
      });

  void _selectLevel(int levelId) {
    if (!_isUnlocked(levelId, widget.progressController.state)) return;
    setState(() => _selectedLevelId = levelId);
  }

  bool _isUnlocked(int levelId, CampaignProgressState state) =>
      ProgressionRules.isLevelUnlocked(
        levelNumber: levelId,
        maxUnlockedLevel: state.maxUnlockedLevel,
      );

  bool _isCompleted(int levelId, CampaignProgressState state) =>
      ProgressionRules.isMasteryLevel(levelId)
          ? state.completedChallengeIds.contains(levelId)
          : state.completedLessonIds.contains(levelId);

  Future<void> _complete(int levelId) async {
    await widget.progressController.completeLevel(levelId);
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
            return LearningMapScreen(
              key: const ValueKey('web-workspace-journey'),
              progressState: widget.progressController.state,
              onStartChapter: _openChapter,
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
  });

  final CampaignProgressController progressController;
  final VoidCallback onBackToJourney;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;

  @override
  State<WebMasteryWorkspace> createState() => _WebMasteryWorkspaceState();
}

class _WebMasteryWorkspaceState extends State<WebMasteryWorkspace> {
  String? _selectedSemanticId;

  List<MasteryChallengeDefinition> get _challenges =>
      mastery2Catalogue.orderedDefinitions;

  MasteryChallengeDefinition _preferredChallenge(
    CampaignProgressState state,
  ) =>
      _challenges.firstWhere(
        (challenge) =>
            !state.completedMasterySemanticIds.contains(challenge.semanticId),
        orElse: () => _challenges.first,
      );

  Future<void> _complete(String semanticId) async {
    await widget.progressController.completeMasteryChallenge(semanticId);
    if (mounted) setState(() {});
  }

  void _nextChallenge(CampaignProgressState state) {
    final current = _selectedSemanticId;
    if (current == null) return;
    final index =
        _challenges.indexWhere((challenge) => challenge.semanticId == current);
    if (index >= 0 && index + 1 < _challenges.length) {
      setState(() => _selectedSemanticId = _challenges[index + 1].semanticId);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.progressController,
        builder: (context, _) {
          if (!widget.progressController.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final state = widget.progressController.state;
          final selected =
              mastery2Catalogue.bySemanticId(_selectedSemanticId ?? '') ??
                  _preferredChallenge(state);
          _selectedSemanticId = selected.semanticId;
          final activity = WebLessonWorkspace(
            key: ValueKey('web-mastery-activity-${selected.semanticId}'),
            levelId: selected.displayOrder,
            masteryChallenge: selected,
            level: selected.levelDefinition,
            alreadyCompleted:
                state.completedMasterySemanticIds.contains(selected.semanticId),
            onCompleted: () => _complete(selected.semanticId),
            onNextLesson: () => _nextChallenge(
              widget.progressController.state,
            ),
            onBackToChapter: () {},
            onOpenNotebook: widget.onOpenNotebook,
            onOpenNotebookEntry: widget.onOpenNotebookEntry,
          );
          return Material(
            color: _background,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 940;
                final challengeList = _MasteryChallengeList(
                  challenges: _challenges,
                  selectedSemanticId: selected.semanticId,
                  currentSemanticId: _preferredChallenge(state).semanticId,
                  progressState: state,
                  horizontal: !wide,
                  onSelected: (id) => setState(() => _selectedSemanticId = id),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      key: ValueKey(wide
                          ? 'web-mastery-wide-layout'
                          : 'web-mastery-stacked-layout'),
                      height: wide ? 126 : 148,
                      child: _MasteryHeader(
                        completed: state.completedMasterySemanticIds.length,
                        total: _challenges.length,
                        onBackToJourney: widget.onBackToJourney,
                        challenges: _challenges,
                        selected: selected,
                        progressState: state,
                        showChallengeChooser: wide,
                        onSelected: (id) =>
                            setState(() => _selectedSemanticId = id),
                      ),
                    ),
                    const Divider(height: 1, color: _border),
                    // Keep the activity in one slot when header navigation changes.
                    if (!wide) SizedBox(height: 92, child: challengeList),
                    if (!wide) const Divider(height: 1, color: _border),
                    Expanded(
                      key: const ValueKey('web-mastery-activity'),
                      child: activity,
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
}

class _MasteryHeader extends StatelessWidget {
  const _MasteryHeader({
    required this.completed,
    required this.total,
    required this.onBackToJourney,
    required this.challenges,
    required this.selected,
    required this.progressState,
    required this.showChallengeChooser,
    required this.onSelected,
  });

  final int completed;
  final int total;
  final VoidCallback onBackToJourney;
  final List<MasteryChallengeDefinition> challenges;
  final MasteryChallengeDefinition selected;
  final CampaignProgressState progressState;
  final bool showChallengeChooser;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final heading = Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Journey  >  Mastery Challenges',
                    style: TextStyle(color: _cyan, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mastery Challenges',
                    key: const ValueKey('web-mastery-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Independent quantum reasoning challenges.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(20, compact ? 10 : 14, 24, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  key: const ValueKey('web-mastery-back-journey'),
                  tooltip: 'Back to Journey',
                  onPressed: onBackToJourney,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                heading,
                if (!compact) ...[
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showChallengeChooser)
                        _MasteryChallengeChooser(
                          challenges: challenges,
                          selected: selected,
                          progressState: progressState,
                          onSelected: onSelected,
                        ),
                      const SizedBox(height: 5),
                      Text('$completed / $total complete'),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      );
}

class _MasteryChallengeChooser extends StatelessWidget {
  const _MasteryChallengeChooser({
    required this.challenges,
    required this.selected,
    required this.progressState,
    required this.onSelected,
  });

  final List<MasteryChallengeDefinition> challenges;
  final MasteryChallengeDefinition selected;
  final CampaignProgressState progressState;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        key: const ValueKey('web-mastery-challenge-chooser'),
        tooltip: 'Open Mastery challenges',
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final challenge in challenges)
            PopupMenuItem<String>(
              key: ValueKey('web-mastery-choice-${challenge.semanticId}'),
              value: challenge.semanticId,
              child: Row(
                children: [
                  Icon(
                    progressState.completedMasterySemanticIds
                            .contains(challenge.semanticId)
                        ? Icons.check_circle
                        : challenge.semanticId == selected.semanticId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                    size: 18,
                    color: progressState.completedMasterySemanticIds
                            .contains(challenge.semanticId)
                        ? Colors.greenAccent
                        : _cyan,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${challenge.displayOrder}. ${challenge.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: QubitQuestRadii.control,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Challenge ${selected.displayOrder} of ${challenges.length}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
      );
}

class _MasteryChallengeList extends StatelessWidget {
  const _MasteryChallengeList({
    required this.challenges,
    required this.selectedSemanticId,
    required this.currentSemanticId,
    required this.progressState,
    required this.horizontal,
    required this.onSelected,
  });

  final List<MasteryChallengeDefinition> challenges;
  final String selectedSemanticId;
  final String currentSemanticId;
  final CampaignProgressState progressState;
  final bool horizontal;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final challenge in challenges)
        _MasteryChallengeItem(
          challenge: challenge,
          selected: challenge.semanticId == selectedSemanticId,
          current: challenge.semanticId == currentSemanticId,
          completed: progressState.completedMasterySemanticIds
              .contains(challenge.semanticId),
          onSelected: onSelected,
        ),
    ];
    if (horizontal) {
      return ListView(
        key: const ValueKey('web-mastery-challenge-list-narrow'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        children: children,
      );
    }
    return ListView(
      key: const ValueKey('web-mastery-challenge-list-wide'),
      padding: const EdgeInsets.all(14),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Text(
            'CHALLENGES',
            style: TextStyle(
              color: _purple,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _MasteryChallengeItem extends StatelessWidget {
  const _MasteryChallengeItem({
    required this.challenge,
    required this.selected,
    required this.current,
    required this.completed,
    required this.onSelected,
  });

  final MasteryChallengeDefinition challenge;
  final bool selected;
  final bool current;
  final bool completed;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final level = challenge.levelDefinition;
    final number = challenge.displayOrder;
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: Material(
        color: selected ? const Color(0x2222D3EE) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          key: ValueKey('web-mastery-challenge-${challenge.semanticId}'),
          onTap: () => onSelected(challenge.semanticId),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            constraints: const BoxConstraints(minWidth: 190, maxWidth: 258),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: selected ? _cyan : _border),
            ),
            child: Row(
              children: [
                Icon(
                  completed
                      ? Icons.check_circle
                      : current
                          ? Icons.play_circle_outline
                          : Icons.circle_outlined,
                  size: 20,
                  color: completed ? Colors.greenAccent : _cyan,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$number. ${level.title ?? 'Challenge $number'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

  List<int> get _levelIds => [
        for (int index = category.from; index <= category.to; index++)
          index + 1,
      ];

  @override
  Widget build(BuildContext context) {
    final level = getQQLevelById(selectedLevelId)!;
    return ColoredBox(
      color: _background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          final compactActivityHeader = wide;
          final header = _ChapterHeader(
            category: category,
            level: level,
            levelIds: _levelIds,
            selectedLevelId: selectedLevelId,
            progressState: progressState,
            completed:
                _levelIds.where((id) => isCompleted(id, progressState)).length,
            total: _levelIds.length,
            showLessonChooser: wide,
            compactActivityHeader: compactActivityHeader,
            isUnlocked: isUnlocked,
            isCompleted: isCompleted,
            onBack: onBackToMap,
            onSelectLevel: onSelectLevel,
          );
          final lessons = _LessonList(
            levelIds: _levelIds,
            selectedLevelId: selectedLevelId,
            progressState: progressState,
            horizontal: !wide,
            isUnlocked: isUnlocked,
            isCompleted: isCompleted,
            onSelected: onSelectLevel,
          );
          final lesson = WebLessonWorkspace(
            key: ValueKey('web-lesson-$selectedLevelId'),
            levelId: selectedLevelId,
            level: level,
            alreadyCompleted: isCompleted(selectedLevelId, progressState),
            onCompleted: () => onCompleted(selectedLevelId),
            onNextLesson: onNextLesson,
            onBackToChapter: () => onSelectLevel(selectedLevelId),
            onOpenNotebook: onOpenNotebook,
            onOpenNotebookEntry: onOpenNotebookEntry,
            compactJourneyHeader: compactActivityHeader,
            journeyActivity: true,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const Divider(height: 1, color: _border),
              // Only navigation changes; the lesson and its circuit keep their lifetime.
              if (!wide) lessons,
              if (!wide) const Divider(height: 1, color: _border),
              Expanded(
                key: const ValueKey('web-chapter-activity'),
                child: lesson,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({
    required this.category,
    required this.level,
    required this.levelIds,
    required this.selectedLevelId,
    required this.progressState,
    required this.completed,
    required this.total,
    required this.showLessonChooser,
    required this.compactActivityHeader,
    required this.isUnlocked,
    required this.isCompleted,
    required this.onBack,
    required this.onSelectLevel,
  });

  final QQLevelsCategory category;
  final QQLevel level;
  final List<int> levelIds;
  final int selectedLevelId;
  final CampaignProgressState progressState;
  final int completed;
  final int total;
  final bool showLessonChooser;
  final bool compactActivityHeader;
  final bool Function(int, CampaignProgressState) isUnlocked;
  final bool Function(int, CampaignProgressState) isCompleted;
  final VoidCallback onBack;
  final ValueChanged<int> onSelectLevel;

  @override
  Widget build(BuildContext context) => Padding(
        key: ValueKey(compactActivityHeader
            ? 'web-compact-activity-header'
            : 'web-chapter-header'),
        padding: EdgeInsets.fromLTRB(
          20,
          compactActivityHeader ? 10 : 16,
          24,
          compactActivityHeader ? 11 : 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              key: const ValueKey('web-journey-back-map'),
              tooltip: 'Back to Journey',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: compactActivityHeader
                  ? _CompactActivityContext(
                      category: category,
                      level: level,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journey  >  ${category.groupName.replaceFirst(' - ', ' — ')}',
                          style: const TextStyle(color: _cyan, fontSize: 13),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          category.groupName,
                          key: const ValueKey('web-chapter-title'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (category.categoryIntro != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            category.categoryIntro!,
                            style: const TextStyle(
                                color: Colors.white70, height: 1.35),
                          ),
                        ],
                      ],
                    ),
            ),
            if (showLessonChooser)
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _LessonChooser(
                      levelIds: levelIds,
                      selectedLevelId: selectedLevelId,
                      progressState: progressState,
                      isUnlocked: isUnlocked,
                      isCompleted: isCompleted,
                      onSelected: onSelectLevel,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$completed / $total complete',
                      key: const ValueKey('web-chapter-progress'),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text('$completed / $total complete'),
          ],
        ),
      );
}

class _CompactActivityContext extends StatelessWidget {
  const _CompactActivityContext({
    required this.category,
    required this.level,
  });

  final QQLevelsCategory category;
  final QQLevel level;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('web-compact-activity-context'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Journey  /  ${category.groupName.replaceFirst(' - ', ' — ')}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _cyan, fontSize: 12.5),
                ),
              ),
              if ((category.categoryIntro ?? '').trim().isNotEmpty)
                Tooltip(
                  key: const ValueKey('web-chapter-description'),
                  message: category.categoryIntro!,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            level.title ?? 'Quantum Challenge',
            key: const ValueKey('web-lesson-title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 3),
          ActivityInstructionPresentation(
            task: level.taskDescription,
            question: level.mysteryTitle,
            compact: true,
            taskKey: const ValueKey('web-compact-task'),
            questionKey: const ValueKey('web-compact-question'),
          ),
        ],
      );
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
                    '${index + 1}. ${getQQLevelById(id)!.title}',
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

class _LessonList extends StatelessWidget {
  const _LessonList({
    required this.levelIds,
    required this.selectedLevelId,
    required this.progressState,
    required this.horizontal,
    required this.isUnlocked,
    required this.isCompleted,
    required this.onSelected,
  });

  final List<int> levelIds;
  final int selectedLevelId;
  final CampaignProgressState progressState;
  final bool horizontal;
  final bool Function(int, CampaignProgressState) isUnlocked;
  final bool Function(int, CampaignProgressState) isCompleted;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final (index, id) in levelIds.indexed)
        _LessonItem(
          index: index + 1,
          levelId: id,
          level: getQQLevelById(id)!,
          selected: id == selectedLevelId,
          unlocked: isUnlocked(id, progressState),
          completed: isCompleted(id, progressState),
          onTap: () => onSelected(id),
        ),
    ];
    if (horizontal) {
      return SizedBox(
        height: 82,
        child: ListView(
          key: const ValueKey('web-lesson-list-narrow'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(10),
          children: children,
        ),
      );
    }
    return ListView(
      key: const ValueKey('web-lesson-list-wide'),
      padding: const EdgeInsets.all(14),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Text(
            'LESSONS',
            style: TextStyle(
              color: _purple,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _LessonItem extends StatelessWidget {
  const _LessonItem({
    required this.index,
    required this.levelId,
    required this.level,
    required this.selected,
    required this.unlocked,
    required this.completed,
    required this.onTap,
  });

  final int index;
  final int levelId;
  final QQLevel level;
  final bool selected;
  final bool unlocked;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 6),
        child: Material(
          color: selected ? const Color(0x2222D3EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            key: ValueKey('web-lesson-item-$levelId'),
            onTap: unlocked ? onTap : null,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              constraints: BoxConstraints(minWidth: 170, maxWidth: 250),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: selected ? _cyan : _border),
              ),
              child: Row(
                children: [
                  Icon(
                    completed
                        ? Icons.check_circle
                        : unlocked
                            ? Icons.play_circle_outline
                            : Icons.lock_outline,
                    size: 20,
                    color: completed
                        ? Colors.greenAccent
                        : unlocked
                            ? _cyan
                            : Colors.white30,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$index. ${level.title ?? 'Lesson $levelId'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white38,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
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

class WebLessonWorkspace extends StatefulWidget {
  const WebLessonWorkspace({
    super.key,
    required this.levelId,
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
  });

  final int levelId;
  final QQLevel level;
  final bool alreadyCompleted;
  final Future<void> Function() onCompleted;
  final VoidCallback onNextLesson;
  final VoidCallback onBackToChapter;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;
  final MasteryChallengeDefinition? masteryChallenge;
  final bool compactJourneyHeader;
  final bool journeyActivity;

  @override
  State<WebLessonWorkspace> createState() => _WebLessonWorkspaceState();
}

class _WebLessonWorkspaceState extends State<WebLessonWorkspace> {
  bool _solved = false;
  bool _saving = false;

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

  Widget _taskContent({bool showQuestion = true, bool showLabels = false}) {
    final presentation = _masteryPresentation;
    return ActivityInstructionPresentation(
      task: presentation?.instruction ?? widget.level.taskDescription,
      question: presentation?.question ?? widget.level.mysteryTitle,
      showQuestion: showQuestion,
      showLabels: showLabels,
      questionKey: presentation == null
          ? null
          : const ValueKey('mastery-task-instruction'),
      evidence: presentation == null ||
              (presentation.evidence.isEmpty &&
                  presentation.intro == null &&
                  presentation.helperText == null)
          ? null
          : MasteryEvidenceView(
              presentation: presentation,
              includeInstruction: false,
              compactSpacing: widget.level is ComposerLevel,
            ),
    );
  }

  bool get _usesDesktopComposerWorkspace =>
      (widget.journeyActivity || widget.masteryChallenge != null) &&
      widget.level is ComposerLevel;

  Widget _desktopComposerLearningBrief() {
    final isMastery = widget.masteryChallenge != null;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if ((widget.level.conceptIntro ?? '').trim().isNotEmpty) ...[
          Text(
            widget.level.conceptIntro!,
            style: QubitQuestTypography.body,
          ),
          const SizedBox(height: 8),
        ],
        _taskContent(showLabels: !isMastery),
        if ((widget.level.mysteryText ?? '').trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              widget.level.mysteryText!,
              style: const TextStyle(
                color: QubitQuestColors.textMuted,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
    return Padding(
      key: const ValueKey('web-lesson-1-learning-brief'),
      padding:
          isMastery ? EdgeInsets.zero : const EdgeInsets.fromLTRB(2, 8, 2, 6),
      child: isMastery
          ? _ContentCard(
              title: 'Task',
              icon: Icons.flag_outlined,
              child: content,
            )
          : content,
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
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
              widget.masteryChallenge != null
                  ? 'Mastery Challenge ${widget.masteryChallenge!.displayOrder}'
                  : ProgressionRules.isMasteryLevel(widget.levelId)
                      ? 'Mastery Challenge ${ProgressionRules.masteryChallengeNumber(widget.levelId)}'
                      : 'Lesson ${widget.levelId}',
              style: TextStyle(
                color: _purple,
                fontWeight: _usesDesktopComposerWorkspace
                    ? FontWeight.w500
                    : FontWeight.w900,
                letterSpacing: _usesDesktopComposerWorkspace ? .7 : 1.1,
                fontSize: _usesDesktopComposerWorkspace ? 12 : null,
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
            if (_usesDesktopComposerWorkspace) ...[
              const SizedBox(height: 14),
              _desktopComposerLearningBrief(),
            ],
          ],
          if (!_usesDesktopComposerWorkspace && widget.level.hasMystery) ...[
            const SizedBox(height: 16),
            _ContentCard(
              title: widget.level.mysteryTitle ?? 'Mystery',
              titleContent: ActivityInstructionPresentation(
                question: widget.level.mysteryTitle ?? 'Mystery',
              ),
              icon: Icons.travel_explore_outlined,
              child: Text(
                widget.level.mysteryText ?? '',
                style: const TextStyle(height: 1.5, color: Colors.white70),
              ),
            ),
          ],
          if (!_usesDesktopComposerWorkspace &&
              (widget.level.conceptIntro ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _ContentCard(
              title: 'Concept',
              icon: Icons.lightbulb_outline,
              child: Text(
                widget.level.conceptIntro!,
                style: const TextStyle(height: 1.5, color: Colors.white70),
              ),
            ),
          ],
          if (!_usesDesktopComposerWorkspace) ...[
            const SizedBox(height: 14),
            _ContentCard(
              title: 'Task',
              icon: Icons.flag_outlined,
              child: _taskContent(
                showQuestion:
                    _masteryPresentation != null || !widget.level.hasMystery,
              ),
            ),
          ],
          if (!_usesDesktopComposerWorkspace &&
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
              style: const TextStyle(color: _cyan, fontWeight: FontWeight.w800),
            ),
          ],
          if (widget.level is! ComposerLevel &&
              (widget.level.hints?.isNotEmpty ?? false)) ...[
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
                      title: Text(hint),
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
            _SuccessPanel(
              level: widget.level,
              isMastery: widget.masteryChallenge != null ||
                  ProgressionRules.isMasteryLevel(widget.levelId),
              onOpenNotebook: widget.onOpenNotebook,
              onOpenNotebookEntry: widget.onOpenNotebookEntry,
              onNext: widget.onNextLesson,
            ),
          ],
        ],
      );

  Widget _lessonInteraction(QQLevel level) => switch (level) {
        ComposerLevel composer => WebComposerLesson(
            key: ValueKey('web-composer-lesson-${widget.levelId}'),
            level: composer,
            enabled: !_solved,
            onSolved: _complete,
            desktopWorkspace: _usesDesktopComposerWorkspace,
          ),
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
      {required this.title,
      required this.icon,
      required this.child,
      this.titleContent});
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? titleContent;

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
                    child: titleContent ??
                        Text(
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

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({
    required this.level,
    required this.isMastery,
    required this.onOpenNotebook,
    this.onOpenNotebookEntry,
    required this.onNext,
  });
  final QQLevel level;
  final bool isMastery;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final notebook = (level.discoveryTitle ?? '').trim().isNotEmpty &&
        notebookEntriesByDiscoveryTitle.containsKey(level.discoveryTitle);
    return Container(
      key: const ValueKey('web-lesson-success'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10251F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent),
              const SizedBox(width: 9),
              Text(
                isMastery ? 'Challenge Complete' : 'Lesson Complete',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if ((level.solutionExplanation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(level.solutionExplanation!,
                style: const TextStyle(height: 1.45)),
          ],
          if (level.hasDiscovery) ...[
            const SizedBox(height: 16),
            Text(
              level.discoveryTitle ?? 'Discovery',
              style: const TextStyle(color: _cyan, fontWeight: FontWeight.w900),
            ),
            if ((level.discoveryText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(level.discoveryText!, style: const TextStyle(height: 1.45)),
            ],
            if ((level.keyInsight ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Key takeaway: ${level.keyInsight!}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ],
          if ((level.whyItMatters ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(level.whyItMatters!,
                style: const TextStyle(color: Colors.white70)),
          ],
          if ((level.nextMystery ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Next mystery: ${level.nextMystery!}',
              style:
                  const TextStyle(color: _purple, fontWeight: FontWeight.w700),
            ),
          ],
          if (notebook) ...[
            const SizedBox(height: 12),
            Text('Notebook updated: ${level.discoveryTitle}',
                key: const ValueKey('web-notebook-updated')),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            children: [
              if (notebook)
                OutlinedButton.icon(
                  key: const ValueKey('web-open-notebook'),
                  onPressed: () {
                    final discoveryTitle = level.discoveryTitle;
                    if (discoveryTitle != null && onOpenNotebookEntry != null) {
                      onOpenNotebookEntry!(discoveryTitle);
                    } else {
                      onOpenNotebook();
                    }
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Open Notebook'),
                ),
              FilledButton.icon(
                key: const ValueKey('web-next-lesson'),
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward),
                label: Text(isMastery ? 'Next Challenge' : 'Next Lesson'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
ComposerValidationResult validateWebComposerLesson(
  ComposerLevel level,
  QuantumCircuit circuit,
) =>
    level.evaluateCircuit(circuit);

class WebComposerLesson extends StatefulWidget {
  const WebComposerLesson({
    super.key,
    required this.level,
    required this.enabled,
    required this.onSolved,
    this.desktopWorkspace = false,
  });

  final ComposerLevel level;
  final bool enabled;
  final Future<void> Function() onSolved;
  final bool desktopWorkspace;

  @override
  State<WebComposerLesson> createState() => _WebComposerLessonState();
}

class _WebComposerLessonState extends State<WebComposerLesson>
    with AutomaticKeepAliveClientMixin {
  // The lesson ListView may evict offscreen children during responsive reflow.
  // A Composer is an active session: its circuit and Inspector belong to the
  // selected lesson, not to the current scroll/cache extent.
  @override
  bool get wantKeepAlive => true;

  static const double _journeyWideBreakpoint = 760;

  late QuantumCircuit _circuit;
  GateId? _selectedGateId;
  double _rotationAngle = math.pi / 2;
  String? _feedback;
  int _visibleHints = 0;
  late bool _nonZeroOnly;

  List<Gate> get _gates => [
        for (final gate in widget.level.availableGates)
          Gate.fromIdentifier(
            gate.type,
            angle: _isRotation(gate.type)
                ? (gate.angle ?? _rotationAngle)
                : gate.angle,
          ),
      ];

  @override
  void initState() {
    super.initState();
    _circuit = QuantumCircuit(currentLevel: widget.level);
    _nonZeroOnly = defaultNonZeroOnlyForQubitCount(widget.level.numQubits);
  }

  @override
  void didUpdateWidget(covariant WebComposerLesson oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.level, widget.level)) {
      _circuit.dispose();
      _circuit = QuantumCircuit(currentLevel: widget.level);
      _selectedGateId = null;
      _feedback = null;
      _visibleHints = 0;
      _nonZeroOnly = defaultNonZeroOnlyForQubitCount(widget.level.numQubits);
    }
  }

  @override
  void dispose() {
    _circuit.dispose();
    super.dispose();
  }

  bool _isRotation(SelectedGateType type) =>
      type == SelectedGateType.rx ||
      type == SelectedGateType.ry ||
      type == SelectedGateType.rz;

  void _commit(CircuitEditOutcome outcome) {
    if (outcome.changed) _circuit.runSimulation();
    setState(() {
      _selectedGateId = outcome.affectedGateId ?? _selectedGateId;
      _feedback = null;
    });
  }

  Future<void> _drop(ComposerCircuitDropIntent intent) async {
    if (!widget.enabled) return;
    final location = intent.destination.location;
    final gate = intent.data.gate;
    if (intent.data.isPlaced) {
      _commit(
        _circuit.commitLogicalGateMovePlan(
          intent.movePlan ??
              _circuit.planLogicalGateMove(intent.data.sourceId!, location),
        ),
      );
      return;
    }
    ControlledGatePlacement? controlledPlacement;
    if (gate.type == SelectedGateType.cnot ||
        gate.type == SelectedGateType.cz ||
        gate.type == SelectedGateType.ccnot) {
      controlledPlacement = await showControlledGatePlacementDialog(
        context,
        gateType: gate.type,
        targetQubit: location.qubit,
        numQubits: widget.level.numQubits,
      );
      if (!mounted || controlledPlacement == null) return;
    }
    final outcome = switch (gate.type) {
      SelectedGateType.cnot ||
      SelectedGateType.cz =>
        _circuit.insertDoubleGateWithOutcome(
          gate,
          location.column,
          location.qubit,
          controlledPlacement!.controlQubit,
        ),
      SelectedGateType.ccnot => _circuit.insertTripleGateWithOutcome(
          gate,
          location.column,
          location.qubit,
          controlledPlacement!.controlQubit,
          controlledPlacement.secondControlQubit!,
        ),
      _ => _circuit.insertSingleGateWithOutcome(
          gate,
          location.column,
          location.qubit,
        ),
    };
    _commit(outcome);
  }

  Future<void> _check() async {
    _circuit.runSimulation();
    final result = validateWebComposerLesson(widget.level, _circuit);
    if (!result.success) {
      setState(() => _feedback =
          'Not quite yet. Keep editing your circuit and try again.');
      return;
    }
    setState(() => _feedback = 'Correct circuit.');
    await widget.onSolved();
  }

  void _reset() {
    _circuit.dispose();
    setState(() {
      _circuit = QuantumCircuit(currentLevel: widget.level);
      _selectedGateId = null;
      _feedback = null;
    });
  }

  Future<void> _inspect(Gate gate) => showDialog<void>(
        context: context,
        builder: (_) => GateInspectorDialog.forGate(
          gate: gate,
          info: GateEducationalCatalog.forType(gate.type),
        ),
      );

  WebCircuitWorkbenchMetrics get _workbenchMetrics =>
      WebCircuitWorkbenchMetrics.calculate(
        qubitCount: widget.level.numQubits,
        hasTargetState: widget.level.solutionFinalVector.isNotEmpty,
      );

  double get _workspaceCanvasHeight => _workbenchMetrics.canvasHeight;

  double get _workspaceMainHeight => _workbenchMetrics.mainRowHeight;

  Widget _workspaceCanvas(bool wide) => wide
      ? _centeredWorkspaceCanvas(integratedWorkbench: true)
      : ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: _workspaceCanvasHeight + 12,
          ),
          child: _centeredWorkspaceCanvas(integratedWorkbench: false),
        );

  Widget _centeredWorkspaceCanvas({required bool integratedWorkbench}) => Align(
        key: const ValueKey('web-lesson-circuit-stage'),
        alignment: Alignment.center,
        child: SizedBox(
          key: const ValueKey('web-lesson-composer-canvas'),
          height: _workspaceCanvasHeight,
          child: IgnorePointer(
            ignoring: !widget.enabled,
            child: ComposerCircuitCanvas(
              circuit: _circuit,
              enableDesktopHorizontalScrolling: true,
              surfaceTreatment: integratedWorkbench
                  ? ComposerCircuitSurfaceTreatment.workbench
                  : ComposerCircuitSurfaceTreatment.inset,
              selectedGateId: _selectedGateId,
              onGateTap: (gate) => setState(() => _selectedGateId = gate?.id),
              onDropRequested: _drop,
              onPlacedGateDragStarted: (gate) =>
                  setState(() => _selectedGateId = gate.id),
              onDeletePlacedGateRequested: (gate) => _commit(
                _circuit.removeLogicalGateByIdWithOutcome(gate.id),
              ),
            ),
          ),
        ),
      );

  Widget _stateDisplays({required bool contentDriven}) =>
      QuantumStateInspectorContent(
        currentPanelKey: const ValueKey('web-lesson-current-state'),
        targetPanelKey: const ValueKey('web-lesson-target-state'),
        currentStateVector: _circuit.currentState.stateVector,
        numQubits: widget.level.numQubits,
        targetStateVector: widget.level.solutionFinalVector
            .map((column) => column.first)
            .toList(),
        targetStateLabel: widget.level.targetStateLabel,
        targetStateExpression: widget.level.targetStateExpression,
        contentDriven: contentDriven,
        nonZeroOnly: _nonZeroOnly,
        onNonZeroOnlyChanged: (value) => setState(() => _nonZeroOnly = value),
      );

  Widget _workspaceToolbar(bool wide) {
    final hasRotationGate = _gates.any((gate) => _isRotation(gate.type));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        IgnorePointer(
          ignoring: !widget.enabled,
          child: ComposerGatePalette(
            gates: _gates,
            dense: wide,
            embedded: true,
            onGateTap: (_) {},
            onInspectGate: _inspect,
          ),
        ),
        if (hasRotationGate)
          Row(
            children: [
              const Text('Rotation angle'),
              Expanded(
                child: Slider(
                  key: const ValueKey('web-lesson-rotation-angle'),
                  value: _rotationAngle,
                  min: 0,
                  max: 2 * math.pi,
                  divisions: 16,
                  onChanged: widget.enabled
                      ? (value) => setState(() => _rotationAngle = value)
                      : null,
                ),
              ),
              Text('${(_rotationAngle / math.pi).toStringAsFixed(2)}π'),
            ],
          ),
      ],
    );
  }

  Widget _workspaceActions({required bool wide}) {
    final hints = widget.level.hints ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_feedback != null)
          Text(
            _feedback!,
            key: const ValueKey('web-lesson-feedback'),
            style: TextStyle(
              color: _feedback == 'Correct circuit.'
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (_visibleHints > 0) ...[
          if (_feedback != null) const SizedBox(height: 8),
          for (int index = 0; index < _visibleHints; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Hint ${index + 1}: ${hints[index]}'),
            ),
        ],
        if (_feedback != null || _visibleHints > 0) const SizedBox(height: 8),
        if (wide)
          Row(
            children: [
              if (_visibleHints < hints.length)
                OutlinedButton.icon(
                  key: const ValueKey('web-lesson-hint'),
                  onPressed: widget.enabled
                      ? () => setState(() => _visibleHints++)
                      : null,
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: const Text('Hint'),
                ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const ValueKey('web-lesson-reset'),
                onPressed: widget.enabled ? _reset : null,
                child: const Text('Reset'),
              ),
              const Spacer(),
              FilledButton.icon(
                key: const ValueKey('web-lesson-check'),
                onPressed: widget.enabled ? _check : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Check Circuit'),
              ),
            ],
          )
        else
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 9,
            runSpacing: 8,
            children: [
              if (_visibleHints < hints.length)
                OutlinedButton.icon(
                  key: const ValueKey('web-lesson-hint'),
                  onPressed: widget.enabled
                      ? () => setState(() => _visibleHints++)
                      : null,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Hint'),
                ),
              OutlinedButton(
                key: const ValueKey('web-lesson-reset'),
                onPressed: widget.enabled ? _reset : null,
                child: const Text('Reset'),
              ),
              FilledButton.icon(
                key: const ValueKey('web-lesson-check'),
                onPressed: widget.enabled ? _check : null,
                icon: const Icon(Icons.check),
                label: const Text('Check Circuit'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDesktopWorkspace() => WebComposerWorkbench(
        key: const ValueKey('web-lesson-1-quantum-workspace'),
        circuitBuilder: (layout) => _workspaceCanvas(layout.wide),
        gatesBuilder: (layout) => _workspaceToolbar(layout.densePalette),
        stateViewBuilder: (layout) =>
            _stateDisplays(contentDriven: layout.contentDrivenInspector),
        actionsBuilder: (layout) =>
            _workspaceActions(wide: layout.inlineActions),
        currentStateVector: _circuit.currentState.stateVector,
        numQubits: widget.level.numQubits,
        targetStateExpression: widget.level.targetStateExpression,
        inspectorKey: const ValueKey('web-lesson-live-inspector'),
        inspectorViewsKey: const ValueKey('web-lesson-inspector-views'),
        wideLayoutBreakpoint: _journeyWideBreakpoint,
        wideMainHeight: _workspaceMainHeight,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.desktopWorkspace) return _buildDesktopWorkspace();
    final hints = widget.level.hints ?? const <String>[];
    final hasRotationGate = _gates.any((gate) => _isRotation(gate.type));
    return _ContentCard(
      title: 'Interactive Composer',
      icon: Icons.account_tree_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: const ValueKey('web-lesson-composer-canvas'),
            height: math.max(150, widget.level.numQubits * 42 + 58),
            child: IgnorePointer(
              ignoring: !widget.enabled,
              child: ComposerCircuitCanvas(
                circuit: _circuit,
                enableDesktopHorizontalScrolling: true,
                selectedGateId: _selectedGateId,
                onGateTap: (gate) => setState(() => _selectedGateId = gate?.id),
                onDropRequested: _drop,
                onPlacedGateDragStarted: (gate) =>
                    setState(() => _selectedGateId = gate.id),
                onDeletePlacedGateRequested: (gate) =>
                    _commit(_circuit.removeLogicalGateByIdWithOutcome(gate.id)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          IgnorePointer(
            ignoring: !widget.enabled,
            child: ComposerGatePalette(
              gates: _gates,
              onGateTap: (_) {},
              onInspectGate: _inspect,
            ),
          ),
          if (hasRotationGate)
            Row(
              children: [
                const Text('Rotation angle'),
                Expanded(
                  child: Slider(
                    key: const ValueKey('web-lesson-rotation-angle'),
                    value: _rotationAngle,
                    min: 0,
                    max: 2 * math.pi,
                    divisions: 16,
                    onChanged: widget.enabled
                        ? (value) => setState(() => _rotationAngle = value)
                        : null,
                  ),
                ),
                Text('${(_rotationAngle / math.pi).toStringAsFixed(2)}π'),
              ],
            ),
          if (_feedback != null) ...[
            const SizedBox(height: 8),
            Text(
              _feedback!,
              key: const ValueKey('web-lesson-feedback'),
              style: TextStyle(
                color: _feedback == 'Correct circuit.'
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_visibleHints > 0) ...[
            const SizedBox(height: 10),
            for (int index = 0; index < _visibleHints; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Hint ${index + 1}: ${hints[index]}'),
              ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 9,
            children: [
              if (_visibleHints < hints.length)
                OutlinedButton.icon(
                  key: const ValueKey('web-lesson-hint'),
                  onPressed: widget.enabled
                      ? () => setState(() => _visibleHints++)
                      : null,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Hint'),
                ),
              OutlinedButton(
                key: const ValueKey('web-lesson-reset'),
                onPressed: widget.enabled ? _reset : null,
                child: const Text('Reset'),
              ),
              FilledButton.icon(
                key: const ValueKey('web-lesson-check'),
                onPressed: widget.enabled ? _check : null,
                icon: const Icon(Icons.check),
                label: const Text('Check Circuit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
