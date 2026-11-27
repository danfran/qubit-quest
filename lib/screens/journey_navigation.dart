import 'package:flutter/material.dart';
import 'package:quantumquiz/models/journey_curriculum.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/qq_levels_category.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

/// Journey section navigation (v2.6 M11D, M11B prototypes 5 and 6).
///
/// One curriculum list shared by the chapter overview and the lesson
/// workspace, so opening a lesson keeps the learner inside the Journey:
/// the chapter being studied expands to show its lessons, the lesson on
/// screen is highlighted, and completed, current, available and locked
/// lessons are told apart. [collapsed] narrows it to a rail of chapter
/// numbers when the circuit needs the width.
///
/// Presentation only: statuses come from [JourneyCurriculum] (the existing
/// progression rules) and every open goes through the host, which guards
/// unlocks again.
class JourneyCurriculumNav extends StatelessWidget {
  const JourneyCurriculumNav({
    super.key,
    required this.curriculum,
    required this.selectedIndex,
    required this.onSelectChapter,
    this.expandedIndex,
    this.currentLessonId,
    this.onOpenLesson,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.masteryCompleted,
    this.masteryTotal,
    this.onOpenMastery,
  });

  final JourneyCurriculum curriculum;

  /// Highlighted chapter row.
  final int selectedIndex;
  final ValueChanged<int> onSelectChapter;

  /// Chapter whose lessons are listed under it (the lesson workspace).
  final int? expandedIndex;

  /// The lesson on screen, highlighted in the expanded chapter.
  final int? currentLessonId;
  final ValueChanged<int>? onOpenLesson;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;
  final int? masteryCompleted;
  final int? masteryTotal;
  final VoidCallback? onOpenMastery;

  static const double width = 292;
  static const double railWidth = 60;

  @override
  Widget build(BuildContext context) =>
      collapsed ? _rail(context) : _full(context);

  Widget _full(BuildContext context) => SingleChildScrollView(
        key: const ValueKey('journey-curriculum'),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'CURRICULUM · ${curriculum.completedLessons} OF '
                      '${curriculum.totalLessons}',
                      key: const ValueKey('journey-nav-heading'),
                      style: QqType.panelHeading
                          .copyWith(color: QubitQuestColors.textMuted),
                    ),
                  ),
                  if (onToggleCollapsed != null)
                    IconButton(
                      key: const ValueKey('journey-nav-collapse'),
                      tooltip: 'Collapse the curriculum',
                      visualDensity: VisualDensity.compact,
                      onPressed: onToggleCollapsed,
                      icon: const Icon(Icons.keyboard_double_arrow_left_rounded,
                          size: 18),
                    ),
                ],
              ),
            ),
            for (final chapter in curriculum.chapters) ...[
              if (chapter.index == selectedIndex)
                RevealWhenCurrent(
                  token: selectedIndex,
                  child: _ChapterRow(
                    chapter: chapter,
                    selected: true,
                    onTap: () => onSelectChapter(chapter.index),
                  ),
                )
              else
                _ChapterRow(
                  chapter: chapter,
                  selected: false,
                  onTap: () => onSelectChapter(chapter.index),
                ),
              if (chapter.index == expandedIndex)
                _LessonList(
                  chapter: chapter,
                  curriculum: curriculum,
                  currentLessonId: currentLessonId,
                  onOpenLesson: onOpenLesson,
                ),
            ],
            if (onOpenMastery != null && masteryTotal != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: QubitQuestSurfaces.rule),
              const SizedBox(height: 6),
              TextButton.icon(
                key: const ValueKey('journey-nav-mastery'),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: QubitQuestColors.accentStrong,
                  textStyle: QqType.navLabel,
                ),
                onPressed: onOpenMastery,
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: Text('Mastery Challenges · '
                    '${masteryCompleted ?? 0} / $masteryTotal'),
              ),
            ],
          ],
        ),
      );

  Widget _rail(BuildContext context) => SingleChildScrollView(
        key: const ValueKey('journey-curriculum-rail'),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            IconButton(
              key: const ValueKey('journey-nav-expand'),
              tooltip: 'Show the curriculum',
              onPressed: onToggleCollapsed,
              icon: const Icon(Icons.menu_rounded, size: 20),
            ),
            const SizedBox(height: 4),
            for (final chapter in curriculum.chapters)
              Tooltip(
                message: 'Chapter ${chapter.number}: ${chapter.title} · '
                    '${journeyStatusWord(chapter.status)}',
                child: InkWell(
                  key: ValueKey('journey-rail-chapter-${chapter.number}'),
                  borderRadius: QubitQuestRadii.control,
                  onTap: () => onSelectChapter(chapter.index),
                  child: Container(
                    width: 44,
                    height: 36,
                    margin: const EdgeInsets.only(bottom: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: QubitQuestRadii.control,
                      color: chapter.index == selectedIndex
                          ? QubitQuestColors.surfaceRaised
                          : null,
                    ),
                    child: Text(
                      '${chapter.number}',
                      style: QqType.navMeta.copyWith(
                        fontSize: 13.5,
                        fontWeight: chapter.index == selectedIndex
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: switch (chapter.status) {
                          JourneyChapterStatus.completed =>
                            QubitQuestColors.success,
                          JourneyChapterStatus.locked =>
                            QubitQuestColors.textMuted,
                          _ => QubitQuestColors.accentInteractive,
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

String journeyStatusWord(JourneyChapterStatus status) => switch (status) {
      JourneyChapterStatus.completed => 'Completed',
      JourneyChapterStatus.inProgress => 'In progress',
      JourneyChapterStatus.available => 'Not started',
      JourneyChapterStatus.locked => 'Locked',
    };

/// One status glyph per chapter: completed ✓, the active chapter ▶, an
/// available chapter ○, a locked chapter 🔒.
Widget journeyStatusGlyph(JourneyChapterSummary chapter, {double size = 20}) {
  final (icon, color, tooltip) = switch (chapter.status) {
    JourneyChapterStatus.completed => (
        Icons.check_circle_rounded,
        QubitQuestColors.success,
        'Completed'
      ),
    JourneyChapterStatus.locked => (
        Icons.lock_outline_rounded,
        QubitQuestColors.textMuted,
        'Locked'
      ),
    _ when chapter.isActive => (
        Icons.play_circle_fill_rounded,
        QubitQuestColors.accentInteractive,
        'Your current chapter'
      ),
    _ => (
        Icons.radio_button_unchecked_rounded,
        QubitQuestColors.textBody,
        journeyStatusWord(chapter.status)
      ),
  };
  return Tooltip(
    message: tooltip,
    child: Icon(icon,
        key:
            ValueKey('journey-status-${chapter.number}-${chapter.status.name}'),
        size: size,
        color: color),
  );
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.selected,
    required this.onTap,
  });

  final JourneyChapterSummary chapter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = chapter.status == JourneyChapterStatus.locked;
    final showCount = chapter.status == JourneyChapterStatus.inProgress;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: selected,
        button: true,
        label: 'Chapter ${chapter.number}, ${chapter.title}, '
            '${journeyStatusWord(chapter.status)}'
            '${chapter.isActive ? ', current chapter' : ''}, '
            '${chapter.completedLessons} of ${chapter.totalLessons} lessons',
        child: ExcludeSemantics(
          child: Material(
            color: selected
                ? QubitQuestColors.navigationSelected
                : Colors.transparent,
            borderRadius: QubitQuestRadii.control,
            child: InkWell(
              key: ValueKey('journey-chapter-${chapter.number}'),
              borderRadius: QubitQuestRadii.control,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                child: Row(
                  children: [
                    journeyStatusGlyph(chapter, size: 18),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 22,
                      child: Text('${chapter.number}',
                          textAlign: TextAlign.right, style: QqType.navMeta),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        chapter.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: QqType.navLabel.copyWith(
                          color: locked
                              ? QubitQuestColors.textMuted
                              : selected
                                  ? QubitQuestColors.accentInteractive
                                  : QubitQuestColors.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (showCount) ...[
                      const SizedBox(width: 8),
                      Text(
                          '${chapter.completedLessons}/${chapter.totalLessons}',
                          style: QqType.navMeta),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The expanded chapter's lessons under its row: the lesson on screen is
/// highlighted; locked lessons cannot be opened.
class _LessonList extends StatelessWidget {
  const _LessonList({
    required this.chapter,
    required this.curriculum,
    required this.currentLessonId,
    required this.onOpenLesson,
  });

  final JourneyChapterSummary chapter;
  final JourneyCurriculum curriculum;
  final int? currentLessonId;
  final ValueChanged<int>? onOpenLesson;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('journey-nav-lessons-${chapter.number}'),
        margin: const EdgeInsets.fromLTRB(28, 2, 0, 8),
        padding: const EdgeInsets.only(left: 8),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: QubitQuestSurfaces.rule)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (position, id) in chapter.lessonIds.indexed)
              _lesson(position + 1, id),
          ],
        ),
      );

  Widget _lesson(int position, int id) {
    final status = JourneyCurriculum.lessonStatusFor(curriculum.state, id);
    final current = id == currentLessonId;
    final locked = status == JourneyLessonStatus.locked;
    final (icon, color, word) = switch (status) {
      _ when current => (
          Icons.radio_button_checked_rounded,
          QubitQuestColors.accentInteractive,
          'viewing'
        ),
      JourneyLessonStatus.completed => (
          Icons.check_circle_rounded,
          QubitQuestColors.success,
          'completed'
        ),
      JourneyLessonStatus.available => (
          Icons.radio_button_unchecked_rounded,
          QubitQuestColors.textBody,
          'available'
        ),
      JourneyLessonStatus.locked => (
          Icons.lock_outline_rounded,
          QubitQuestColors.textMuted,
          'locked'
        ),
    };
    final title = getJourneyLessonById(id)?.title ?? 'Lesson $position';
    final row = Semantics(
      selected: current,
      button: !locked,
      label: 'Lesson ${chapter.number}.$position, $title, $word',
      child: ExcludeSemantics(
        child: Material(
          color: current
              ? QubitQuestColors.accentInteractive.withValues(alpha: .10)
              : Colors.transparent,
          borderRadius: QubitQuestRadii.control,
          child: InkWell(
            key: ValueKey('journey-nav-lesson-$id'),
            borderRadius: QubitQuestRadii.control,
            onTap:
                locked || onOpenLesson == null ? null : () => onOpenLesson!(id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  Icon(icon,
                      key: ValueKey('journey-nav-lesson-status-$id-$word'),
                      size: 16,
                      color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${chapter.number}.$position  $title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: QqType.navLabel.copyWith(
                        fontSize: 13.5,
                        color: locked
                            ? QubitQuestColors.textMuted
                            : current
                                ? QubitQuestColors.accentInteractive
                                : QubitQuestColors.textBody,
                        fontWeight: current ? FontWeight.w600 : FontWeight.w400,
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
    final tooltipped = Tooltip(
      message: '${chapter.number}.$position $title',
      waitDuration: const Duration(milliseconds: 600),
      child: row,
    );
    return current
        ? RevealWhenCurrent(token: id, child: tooltipped)
        : tooltipped;
  }
}

/// A chapter's title without its "Chapter N - " prefix.
String journeyChapterTitle(QQLevelsCategory category) {
  final name = category.groupName;
  final dash = name.indexOf(' - ');
  return dash < 0 ? name : name.substring(dash + 3);
}

/// Scrolls its child into view when [token] changes (and on first build),
/// so the selected chapter, lesson or challenge never sits off-screen in a
/// long navigation list (v2.6 M11D.1). Manual scrolling is left alone
/// until the selection changes again.
class RevealWhenCurrent extends StatefulWidget {
  const RevealWhenCurrent(
      {super.key, required this.token, required this.child});
  final Object token;
  final Widget child;

  @override
  State<RevealWhenCurrent> createState() => _RevealWhenCurrentState();
}

class _RevealWhenCurrentState extends State<RevealWhenCurrent> {
  @override
  void initState() {
    super.initState();
    _reveal();
  }

  @override
  void didUpdateWidget(covariant RevealWhenCurrent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) _reveal();
  }

  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || Scrollable.maybeOf(context) == null) return;
        Scrollable.ensureVisible(
          context,
          alignment: .3,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          duration: Duration.zero,
        );
      });

  @override
  Widget build(BuildContext context) => widget.child;
}
