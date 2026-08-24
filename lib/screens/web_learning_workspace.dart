import 'dart:async';
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/gate_id.dart';
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
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

const _background = Color(0xFF00030A);
const _panel = Color(0xFF111827);
const _border = Color(0x66344A73);
const _cyan = Color(0xFF22D3EE);
const _purple = Color(0xFF9B7BFF);

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
  static final QQLevelsCategory _category = groupedLevels.firstWhere(
    (category) => category.isMasteryPhase,
  );

  int? _selectedLevelId;

  List<int> get _challengeIds => [
        for (var index = _category.from; index <= _category.to; index++)
          index + 1,
      ];

  int _preferredChallenge(CampaignProgressState state) =>
      _challengeIds.firstWhere(
        (id) => !state.completedChallengeIds.contains(id),
        orElse: () => _challengeIds.first,
      );

  bool _isUnlocked(int levelId, CampaignProgressState state) =>
      CampaignProgressPolicy.isLevelUnlocked(state, levelId);

  void _selectChallenge(int levelId, CampaignProgressState state) {
    if (!_isUnlocked(levelId, state)) return;
    setState(() => _selectedLevelId = levelId);
  }

  Future<void> _complete(int levelId) async {
    await widget.progressController.completeChallenge(levelId);
    if (mounted) setState(() {});
  }

  void _nextChallenge(CampaignProgressState state) {
    final current = _selectedLevelId;
    if (current == null) return;
    final next = current + 1;
    if (_challengeIds.contains(next) && _isUnlocked(next, state)) {
      setState(() => _selectedLevelId = next);
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
          final unlocked =
              CampaignProgressPolicy.getMasteryChallengesUnlocked(state);
          if (!unlocked) {
            return _MasteryLockedWorkspace(
              onBackToJourney: widget.onBackToJourney,
            );
          }
          final selected = _selectedLevelId != null &&
                  _challengeIds.contains(_selectedLevelId) &&
                  _isUnlocked(_selectedLevelId!, state)
              ? _selectedLevelId!
              : _preferredChallenge(state);
          _selectedLevelId = selected;
          final activity = WebLessonWorkspace(
            key: ValueKey('web-mastery-activity-$selected'),
            levelId: selected,
            level: getQQLevelById(selected)!,
            alreadyCompleted: state.completedChallengeIds.contains(selected),
            onCompleted: () => _complete(selected),
            onNextLesson: () => _nextChallenge(
              widget.progressController.state,
            ),
            onBackToChapter: () {},
            onOpenNotebook: widget.onOpenNotebook,
            onOpenNotebookEntry: widget.onOpenNotebookEntry,
          );
          return ColoredBox(
            color: _background,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 940;
                final challengeList = _MasteryChallengeList(
                  challengeIds: _challengeIds,
                  selectedLevelId: selected,
                  currentLevelId: _preferredChallenge(state),
                  progressState: state,
                  horizontal: !wide,
                  onSelected: (id) => _selectChallenge(id, state),
                );
                return Column(
                  key: ValueKey(
                    wide
                        ? 'web-mastery-wide-layout'
                        : 'web-mastery-stacked-layout',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: wide ? 126 : 148,
                      child: _MasteryHeader(
                        completed: state.completedChallengeIds.length,
                        total: _challengeIds.length,
                        onBackToJourney: widget.onBackToJourney,
                      ),
                    ),
                    const Divider(height: 1, color: _border),
                    Expanded(
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(width: 286, child: challengeList),
                                const VerticalDivider(
                                  width: 1,
                                  color: _border,
                                ),
                                Expanded(child: activity),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 92, child: challengeList),
                                const Divider(height: 1, color: _border),
                                Expanded(child: activity),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
}

class _MasteryLockedWorkspace extends StatelessWidget {
  const _MasteryLockedWorkspace({required this.onBackToJourney});

  final VoidCallback onBackToJourney;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        key: const ValueKey('web-mastery-locked-workspace'),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _ContentCard(
              title: 'Mastery Challenges Locked',
              icon: Icons.lock_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Complete Guided Discovery to unlock Mastery Challenges. '
                    'They apply combined concepts after Chapter 12 Level 5.',
                    style: TextStyle(height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: onBackToJourney,
                      icon: const Icon(Icons.route_outlined),
                      label: const Text('Continue Journey'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _MasteryHeader extends StatelessWidget {
  const _MasteryHeader({
    required this.completed,
    required this.total,
    required this.onBackToJourney,
  });

  final int completed;
  final int total;
  final VoidCallback onBackToJourney;

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
                    _WebMasteryWorkspaceState._category.categoryIntro ?? '',
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
                  Text('$completed / $total complete'),
                ],
              ],
            ),
          );
        },
      );
}

class _MasteryChallengeList extends StatelessWidget {
  const _MasteryChallengeList({
    required this.challengeIds,
    required this.selectedLevelId,
    required this.currentLevelId,
    required this.progressState,
    required this.horizontal,
    required this.onSelected,
  });

  final List<int> challengeIds;
  final int selectedLevelId;
  final int currentLevelId;
  final CampaignProgressState progressState;
  final bool horizontal;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final id in challengeIds)
        _MasteryChallengeItem(
          levelId: id,
          selected: id == selectedLevelId,
          current: id == currentLevelId,
          completed: progressState.completedChallengeIds.contains(id),
          unlocked: CampaignProgressPolicy.isLevelUnlocked(progressState, id),
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
    required this.levelId,
    required this.selected,
    required this.current,
    required this.completed,
    required this.unlocked,
    required this.onSelected,
  });

  final int levelId;
  final bool selected;
  final bool current;
  final bool completed;
  final bool unlocked;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final level = getQQLevelById(levelId)!;
    final number = ProgressionRules.masteryChallengeNumber(levelId);
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: Material(
        color: selected ? const Color(0x2222D3EE) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          key: ValueKey('web-mastery-challenge-$number'),
          onTap: unlocked ? () => onSelected(levelId) : null,
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
                      : unlocked
                          ? current
                              ? Icons.play_circle_outline
                              : Icons.circle_outlined
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
                    '$number. ${level.title ?? 'Challenge $number'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unlocked ? Colors.white : Colors.white38,
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
          final header = _ChapterHeader(
            category: category,
            completed:
                _levelIds.where((id) => isCompleted(id, progressState)).length,
            total: _levelIds.length,
            onBack: onBackToMap,
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
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const Divider(height: 1, color: _border),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 286, child: lessons),
                          const VerticalDivider(width: 1, color: _border),
                          Expanded(child: lesson),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          lessons,
                          const Divider(height: 1, color: _border),
                          Expanded(child: lesson),
                        ],
                      ),
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
    required this.completed,
    required this.total,
    required this.onBack,
  });

  final QQLevelsCategory category;
  final int completed;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 24, 16),
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
              child: Column(
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (category.categoryIntro != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      category.categoryIntro!,
                      style:
                          const TextStyle(color: Colors.white70, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
            Text('$completed / $total complete'),
          ],
        ),
      );
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
  });

  final int levelId;
  final QQLevel level;
  final bool alreadyCompleted;
  final Future<void> Function() onCompleted;
  final VoidCallback onNextLesson;
  final VoidCallback onBackToChapter;
  final VoidCallback onOpenNotebook;
  final ValueChanged<String>? onOpenNotebookEntry;

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

  @override
  Widget build(BuildContext context) => ListView(
        key: ValueKey('web-lesson-content-${widget.levelId}'),
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            ProgressionRules.isMasteryLevel(widget.levelId)
                ? 'Mastery Challenge ${ProgressionRules.masteryChallengeNumber(widget.levelId)}'
                : 'Lesson ${widget.levelId}',
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
          if (widget.level.hasMystery) ...[
            const SizedBox(height: 16),
            _ContentCard(
              title: widget.level.mysteryTitle ?? 'Mystery',
              icon: Icons.travel_explore_outlined,
              child: Text(
                widget.level.mysteryText ?? '',
                style: const TextStyle(height: 1.5, color: Colors.white70),
              ),
            ),
          ],
          if ((widget.level.conceptIntro ?? '').trim().isNotEmpty) ...[
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
          const SizedBox(height: 14),
          _ContentCard(
            title: 'Task',
            icon: Icons.flag_outlined,
            child: LatexText(
              math: widget.level.taskDescription,
              textStyle: const TextStyle(color: Colors.white, height: 1.5),
              inlineMathHeight: 18,
            ),
          ),
          if ((widget.level.targetStateLabel ?? '').trim().isNotEmpty ||
              (widget.level.targetStateExpression ?? '').trim().isNotEmpty) ...[
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
              isMastery: ProgressionRules.isMasteryLevel(widget.levelId),
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
      {required this.title, required this.icon, required this.child});
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
  });

  final ComposerLevel level;
  final bool enabled;
  final Future<void> Function() onSolved;

  @override
  State<WebComposerLesson> createState() => _WebComposerLessonState();
}

class _WebComposerLessonState extends State<WebComposerLesson> {
  late QuantumCircuit _circuit;
  GateId? _selectedGateId;
  double _rotationAngle = math.pi / 2;
  String? _feedback;
  int _visibleHints = 0;

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

  @override
  Widget build(BuildContext context) {
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
