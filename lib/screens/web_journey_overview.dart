import 'package:flutter/material.dart';
import 'package:quantumquiz/models/journey_curriculum.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/journey_chapter_illustration.dart';

/// The web Learning Journey (v2.6 M5): a master–detail curriculum. The
/// left region lists every chapter in order with one status glyph each; the
/// right region introduces the selected chapter, lists its lessons and
/// offers one context-sensitive action.
///
/// Presentation only. Statuses and actions come from [JourneyCurriculum]
/// (the existing progression rules); opening a lesson goes through
/// [onOpenLesson], which the host guards again. Selecting or previewing a
/// chapter never changes progress.
///
/// Layouts by available width: master–detail from [masterDetailWidth];
/// below it, a sequential list → chapter flow with an explicit return.
class WebJourneyOverview extends StatelessWidget {
  const WebJourneyOverview({
    super.key,
    required this.curriculum,
    required this.selectedIndex,
    required this.onSelectChapter,
    required this.onOpenLesson,
    this.onOpenMastery,
    this.narrowShowsDetail = false,
    this.onNarrowBack,
  });

  final JourneyCurriculum curriculum;
  final int selectedIndex;
  final ValueChanged<int> onSelectChapter;
  final ValueChanged<int> onOpenLesson;
  final VoidCallback? onOpenMastery;

  /// Narrow layout only: show the selected chapter instead of the list.
  final bool narrowShowsDetail;
  final VoidCallback? onNarrowBack;

  static const double masterDetailWidth = 720;

  @override
  Widget build(BuildContext context) => ColoredBox(
        key: const ValueKey('web-workspace-journey'),
        color: QubitQuestColors.background,
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final selected = curriculum.chapters[selectedIndex];
          final header = _JourneyHeader(
            curriculum: curriculum,
            compact: width < masterDetailWidth,
            onOpenMastery: onOpenMastery,
          );
          final detail = _ChapterDetail(
            key: ValueKey('journey-detail-${selected.number}'),
            curriculum: curriculum,
            chapter: selected,
            onOpenLesson: onOpenLesson,
            onSelectChapter: onSelectChapter,
            onOpenMastery: onOpenMastery,
            narrow: width < masterDetailWidth,
          );
          if (width >= masterDetailWidth) {
            final listWidth = width >= 1200
                ? 300.0
                : width >= 960
                    ? 268.0
                    : 236.0;
            return Column(
              key: const ValueKey('journey-master-detail'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const Divider(height: 1, color: QubitQuestColors.borderSoft),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: listWidth,
                        child: _CurriculumList(
                          curriculum: curriculum,
                          selectedIndex: selectedIndex,
                          onSelect: onSelectChapter,
                        ),
                      ),
                      const VerticalDivider(
                          width: 1, color: QubitQuestColors.borderSoft),
                      Expanded(child: detail),
                    ],
                  ),
                ),
              ],
            );
          }
          if (narrowShowsDetail) {
            return Column(
              key: const ValueKey('journey-narrow-detail'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('journey-back-to-curriculum'),
                      onPressed: onNarrowBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('All chapters'),
                    ),
                  ),
                ),
                Expanded(child: detail),
              ],
            );
          }
          return Column(
            key: const ValueKey('journey-narrow-list'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const Divider(height: 1, color: QubitQuestColors.borderSoft),
              Expanded(
                child: _CurriculumList(
                  curriculum: curriculum,
                  selectedIndex: selectedIndex,
                  onSelect: onSelectChapter,
                ),
              ),
            ],
          );
        }),
      );
}

String _statusWord(JourneyChapterStatus status) => switch (status) {
      JourneyChapterStatus.completed => 'Completed',
      JourneyChapterStatus.inProgress => 'In progress',
      JourneyChapterStatus.available => 'Not started',
      JourneyChapterStatus.locked => 'Locked',
    };

String _two(int n) => n.toString().padLeft(2, '0');

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({
    required this.curriculum,
    required this.compact,
    this.onOpenMastery,
  });

  final JourneyCurriculum curriculum;
  final bool compact;
  final VoidCallback? onOpenMastery;

  @override
  Widget build(BuildContext context) {
    final fraction = curriculum.totalLessons == 0
        ? 0.0
        : curriculum.completedLessons / curriculum.totalLessons;
    final summary = '${curriculum.completedChapters} of '
        '${curriculum.chapters.length} chapters completed · '
        '${curriculum.completedLessons} of ${curriculum.totalLessons} lessons';
    return Padding(
      key: const ValueKey('journey-header'),
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, compact ? 14 : 20,
          compact ? 16 : 28, compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Learning Journey',
                      style: QubitQuestTypography.title
                          .copyWith(fontSize: compact ? 20 : 24)),
                  const SizedBox(height: 4),
                  Text(summary,
                      key: const ValueKey('journey-overall-progress'),
                      style: QubitQuestTypography.supporting),
                ],
              ),
              if (onOpenMastery != null)
                Tooltip(
                  message: 'Mastery Challenges are open at any time; they '
                      'are independent practice, not a later chapter.',
                  child: OutlinedButton.icon(
                    key: const ValueKey('journey-open-mastery'),
                    onPressed: onOpenMastery,
                    icon:
                        const Icon(Icons.workspace_premium_outlined, size: 18),
                    label: const Text('Mastery Challenges'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Overall progress: $summary',
            child: ClipRRect(
              borderRadius: QubitQuestRadii.pill,
              child: LinearProgressIndicator(
                key: const ValueKey('journey-overall-bar'),
                value: fraction,
                minHeight: 6,
                color: QubitQuestColors.accentInteractive,
                backgroundColor: QubitQuestColors.surfaceRaised,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurriculumList extends StatelessWidget {
  const _CurriculumList({
    required this.curriculum,
    required this.selectedIndex,
    required this.onSelect,
  });

  final JourneyCurriculum curriculum;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  // A non-lazy column: the curriculum is short and every row stays
  // reachable (and testable) without scrolling it into existence.
  Widget build(BuildContext context) => SingleChildScrollView(
        key: const ValueKey('journey-curriculum'),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text('CURRICULUM', style: QubitQuestTypography.label),
            ),
            for (final chapter in curriculum.chapters)
              _ChapterRow(
                chapter: chapter,
                selected: chapter.index == selectedIndex,
                onTap: () => onSelect(chapter.index),
              ),
          ],
        ),
      );
}

/// One status glyph per chapter: completed ✓, the active chapter ▶, an
/// available chapter ○, a locked chapter 🔒. Selection is a separate,
/// background highlight.
Widget _statusGlyph(JourneyChapterSummary chapter, {double size = 20}) {
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
        _statusWord(chapter.status)
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
            '${_statusWord(chapter.status)}'
            '${chapter.isActive ? ', current chapter' : ''}, '
            '${chapter.completedLessons} of ${chapter.totalLessons} lessons',
        child: ExcludeSemantics(
          child: Material(
            color:
                selected ? QubitQuestColors.surfaceRaised : Colors.transparent,
            borderRadius: QubitQuestRadii.control,
            child: InkWell(
              key: ValueKey('journey-chapter-${chapter.number}'),
              borderRadius: QubitQuestRadii.control,
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                decoration: BoxDecoration(
                  borderRadius: QubitQuestRadii.control,
                  border: Border(
                    left: BorderSide(
                      color: selected
                          ? QubitQuestColors.accentInteractive
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _statusGlyph(chapter),
                    const SizedBox(width: 10),
                    Text(
                      _two(chapter.number),
                      style: const TextStyle(
                        color: QubitQuestColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        chapter.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: locked
                              ? QubitQuestColors.textMuted
                              : QubitQuestColors.textPrimary,
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (showCount) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${chapter.completedLessons}/${chapter.totalLessons}',
                        style: const TextStyle(
                          color: QubitQuestColors.textMuted,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
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

class _ChapterDetail extends StatelessWidget {
  const _ChapterDetail({
    super.key,
    required this.curriculum,
    required this.chapter,
    required this.onOpenLesson,
    required this.onSelectChapter,
    required this.narrow,
    this.onOpenMastery,
  });

  final JourneyCurriculum curriculum;
  final JourneyChapterSummary chapter;
  final ValueChanged<int> onOpenLesson;
  final ValueChanged<int> onSelectChapter;
  final VoidCallback? onOpenMastery;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final action = chapter.primaryAction;
    final locked = chapter.status == JourneyChapterStatus.locked;
    final active = curriculum.activeChapterIndex;
    final prerequisite = chapter.prerequisiteLessonId == null
        ? null
        : getJourneyLessonById(chapter.prerequisiteLessonId!);
    final lessons = [
      for (final id in chapter.lessonIds) (id, getJourneyLessonById(id)!)
    ];
    final buildsOn = [
      for (final link in LearningMapScreen.conceptLinks)
        if (!link.targetsMastery && link.toChapter == chapter.number) link
    ];
    final preparesFor = [
      for (final link in LearningMapScreen.conceptLinks)
        if (link.fromChapter == chapter.number) link
    ];

    final actionLabel = switch (action.kind) {
      JourneyChapterActionKind.start => 'Start chapter',
      JourneyChapterActionKind.resume => 'Continue · Lesson ${chapter.number}.'
          '${chapter.lessonIds.indexOf(action.lessonId!) + 1}',
      JourneyChapterActionKind.review => 'Review chapter',
      JourneyChapterActionKind.locked => 'Locked',
    };

    return SingleChildScrollView(
      key: const ValueKey('journey-detail-scroll'),
      padding: EdgeInsets.fromLTRB(
          narrow ? 16 : 36, narrow ? 12 : 28, narrow ? 16 : 36, 32),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _statusGlyph(chapter, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'CHAPTER ${_two(chapter.number)} · '
                      '${_statusWord(chapter.status).toUpperCase()}'
                      '${chapter.isActive ? ' · YOUR CURRENT CHAPTER' : ''}',
                      key: const ValueKey('journey-detail-status'),
                      style: QubitQuestTypography.label,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                chapter.title,
                key: const ValueKey('journey-detail-title'),
                style: QubitQuestTypography.display
                    .copyWith(fontSize: narrow ? 24 : 30),
              ),
              const SizedBox(height: 10),
              if (chapter.category.categoryIntro case final intro?)
                Text(
                  intro,
                  key: const ValueKey('journey-detail-intro'),
                  style: QubitQuestTypography.body
                      .copyWith(fontSize: 15.5, height: 1.5),
                ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('journey-primary-action'),
                    onPressed: action.lessonId == null
                        ? null
                        : () => onOpenLesson(action.lessonId!),
                    icon: Icon(
                      switch (action.kind) {
                        JourneyChapterActionKind.review => Icons.replay_rounded,
                        JourneyChapterActionKind.locked =>
                          Icons.lock_outline_rounded,
                        _ => Icons.play_arrow_rounded,
                      },
                      size: 18,
                    ),
                    label: Text(actionLabel),
                  ),
                  Text(
                    '${chapter.completedLessons} of ${chapter.totalLessons} '
                    'lessons completed',
                    key: const ValueKey('journey-chapter-progress'),
                    style: QubitQuestTypography.supporting,
                  ),
                ],
              ),
              if (locked && prerequisite != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Opens when you complete “${prerequisite.title}”, the final '
                  'lesson of Chapter ${chapter.number - 1}. You can read '
                  'this chapter’s introduction now.',
                  key: const ValueKey('journey-prerequisite'),
                  style: QubitQuestTypography.supporting,
                ),
              ],
              if (!chapter.isActive && active != null && !narrow) ...[
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('journey-go-to-current'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => onSelectChapter(active),
                  child: Text('Your current chapter is '
                      '${curriculum.chapters[active].number}: '
                      '${curriculum.chapters[active].title}'),
                ),
              ],
              if (curriculum.isComplete) ...[
                const SizedBox(height: 10),
                Text(
                  'You have completed the whole Journey. Every chapter stays '
                  'open for review.',
                  key: const ValueKey('journey-complete-note'),
                  style: QubitQuestTypography.supporting
                      .copyWith(color: QubitQuestColors.success),
                ),
              ],
              const SizedBox(height: 24),
              JourneyChapterIllustration(chapterNumber: chapter.number),
              if (journeyChapterIllustrations.containsKey(chapter.number))
                const SizedBox(height: 24),
              const Text('WHAT YOU WILL LEARN',
                  style: QubitQuestTypography.label),
              const SizedBox(height: 8),
              for (final (id, lesson) in lessons)
                if (lesson.keyInsight case final insight?)
                  Padding(
                    key: ValueKey('journey-insight-$id'),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7, right: 10),
                          child: Icon(Icons.circle,
                              size: 5, color: QubitQuestColors.accentStrong),
                        ),
                        Expanded(
                          child:
                              Text(insight, style: QubitQuestTypography.body),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 22),
              const Text('LESSONS', style: QubitQuestTypography.label),
              const SizedBox(height: 6),
              for (final (position, (id, lesson)) in lessons.indexed)
                _LessonRow(
                  chapterNumber: chapter.number,
                  position: position + 1,
                  lessonId: id,
                  title: lesson.title ?? 'Lesson ${position + 1}',
                  type: journeyLessonTypeLabel(lesson),
                  status:
                      JourneyCurriculum.lessonStatusFor(curriculum.state, id),
                  isNext: id == chapter.nextLessonId,
                  onOpen: () => onOpenLesson(id),
                ),
              if (buildsOn.isNotEmpty || preparesFor.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text('CONNECTIONS', style: QubitQuestTypography.label),
                const SizedBox(height: 6),
                for (final link in buildsOn)
                  _Connection(
                    key: ValueKey('journey-builds-on-${link.fromChapter}'),
                    label: 'Builds on',
                    target: 'Chapter ${link.fromChapter}: '
                        '${curriculum.chapters[link.fromChapter - 1].title}',
                    detail: link.description,
                    onTap: () => onSelectChapter(link.fromChapter - 1),
                  ),
                for (final link in preparesFor)
                  link.targetsMastery
                      ? _Connection(
                          key: const ValueKey('journey-prepares-mastery'),
                          label: 'Prepares you for',
                          target: 'Mastery Challenges',
                          detail: '${link.description}. Mastery is open at '
                              'any time.',
                          onTap: onOpenMastery,
                        )
                      : _Connection(
                          key: ValueKey('journey-prepares-${link.toChapter}'),
                          label: 'Prepares you for',
                          target: 'Chapter ${link.toChapter}: '
                              '${curriculum.chapters[link.toChapter - 1].title}',
                          detail: link.description,
                          onTap: () => onSelectChapter(link.toChapter - 1),
                        ),
                const SizedBox(height: 4),
                const Text(
                  'Connections are conceptual; chapters still open in '
                  'order.',
                  style: QubitQuestTypography.supporting,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.chapterNumber,
    required this.position,
    required this.lessonId,
    required this.title,
    required this.type,
    required this.status,
    required this.isNext,
    required this.onOpen,
  });

  final int chapterNumber;
  final int position;
  final int lessonId;
  final String title;
  final String type;
  final JourneyLessonStatus status;
  final bool isNext;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final locked = status == JourneyLessonStatus.locked;
    final (icon, color) = switch (status) {
      JourneyLessonStatus.completed => (
          Icons.check_circle_rounded,
          QubitQuestColors.success
        ),
      JourneyLessonStatus.available when isNext => (
          Icons.play_circle_fill_rounded,
          QubitQuestColors.accentInteractive
        ),
      JourneyLessonStatus.available => (
          Icons.radio_button_unchecked_rounded,
          QubitQuestColors.textBody
        ),
      JourneyLessonStatus.locked => (
          Icons.lock_outline_rounded,
          QubitQuestColors.textMuted
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isNext ? QubitQuestColors.surfaceRaised : Colors.transparent,
        borderRadius: QubitQuestRadii.control,
        child: InkWell(
          key: ValueKey('journey-lesson-$lessonId'),
          borderRadius: QubitQuestRadii.control,
          onTap: locked ? null : onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                SizedBox(
                  width: 34,
                  child: Text(
                    '$chapterNumber.$position',
                    style: const TextStyle(
                      color: QubitQuestColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: locked
                          ? QubitQuestColors.textMuted
                          : QubitQuestColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(type, style: QubitQuestTypography.supporting),
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: Text(
                    switch (status) {
                      JourneyLessonStatus.completed => 'Review',
                      JourneyLessonStatus.available => isNext ? 'Next' : 'Open',
                      JourneyLessonStatus.locked => 'Locked',
                    },
                    key: ValueKey('journey-lesson-action-$lessonId'),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: locked
                          ? QubitQuestColors.textMuted
                          : QubitQuestColors.accentInteractive,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

class _Connection extends StatelessWidget {
  const _Connection({
    super.key,
    required this.label,
    required this.target,
    required this.detail,
    this.onTap,
  });

  final String label;
  final String target;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: QubitQuestRadii.control,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Text.rich(TextSpan(children: [
            TextSpan(
              text: '$label  ',
              style: QubitQuestTypography.supporting,
            ),
            TextSpan(
              text: target,
              style: const TextStyle(
                color: QubitQuestColors.accentInteractive,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: ' — $detail',
              style: QubitQuestTypography.body,
            ),
          ])),
        ),
      );
}
