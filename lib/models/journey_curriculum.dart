import 'package:flutter/foundation.dart';

import 'campaign_progress.dart';
import 'progression_rules.dart';
import 'qq_level.dart';
import 'qq_levels.dart';
import 'qq_levels_category.dart';

/// Read-only view of the Learning Journey curriculum for one progress state
/// (v2.6 M5). Every status and count is derived from the existing rules:
/// [ProgressionRules.isJourneyLessonUnlocked] for availability and
/// [CampaignProgressPolicy.chapterProgress] for chapter completion. Nothing
/// here changes progress, unlocks content or stores anything.
enum JourneyChapterStatus {
  /// Every lesson completed.
  completed,

  /// Unlocked with at least one lesson completed.
  inProgress,

  /// Unlocked, no lesson completed yet.
  available,

  /// Its first lesson is not unlocked yet.
  locked,
}

enum JourneyLessonStatus { completed, available, locked }

/// The chapter's context-sensitive primary action.
enum JourneyChapterActionKind { start, resume, review, locked }

@immutable
class JourneyChapterAction {
  const JourneyChapterAction(this.kind, this.lessonId);
  final JourneyChapterActionKind kind;

  /// The lesson the action opens; null when locked.
  final int? lessonId;
}

@immutable
class JourneyChapterSummary {
  const JourneyChapterSummary({
    required this.index,
    required this.category,
    required this.lessonIds,
    required this.completedLessons,
    required this.status,
    required this.isActive,
    required this.nextLessonId,
    required this.prerequisiteLessonId,
  });

  /// Zero-based position in [journeyChapters].
  final int index;
  final QQLevelsCategory category;
  final List<int> lessonIds;
  final int completedLessons;
  final JourneyChapterStatus status;

  /// The chapter holding the learner's next lesson (the frontier).
  final bool isActive;

  /// First unlocked, incomplete lesson; null when none.
  final int? nextLessonId;

  /// For a locked chapter: the lesson whose completion unlocks it (the
  /// previous chapter's last lesson, under the linear unlocking rule).
  final int? prerequisiteLessonId;

  int get number => index + 1;
  int get totalLessons => lessonIds.length;

  /// `Chapter 3 - Superposition` → `Superposition`.
  String get title {
    final name = category.groupName;
    final dash = name.indexOf(' - ');
    return dash < 0 ? name : name.substring(dash + 3);
  }

  JourneyChapterAction get primaryAction => switch (status) {
        JourneyChapterStatus.locked =>
          const JourneyChapterAction(JourneyChapterActionKind.locked, null),
        JourneyChapterStatus.completed => JourneyChapterAction(
            JourneyChapterActionKind.review, lessonIds.first),
        JourneyChapterStatus.available =>
          JourneyChapterAction(JourneyChapterActionKind.start, lessonIds.first),
        JourneyChapterStatus.inProgress => JourneyChapterAction(
            JourneyChapterActionKind.resume, nextLessonId ?? lessonIds.first),
      };
}

@immutable
class JourneyCurriculum {
  const JourneyCurriculum._(this.state, this.chapters);

  final CampaignProgressState state;
  final List<JourneyChapterSummary> chapters;

  factory JourneyCurriculum.of(CampaignProgressState state) {
    // The frontier: the first lesson in curriculum order that is unlocked
    // and not completed.
    int? frontier;
    for (var id = 1; id <= journeyLessons.length; id++) {
      if (lessonStatusFor(state, id) == JourneyLessonStatus.available) {
        frontier = id;
        break;
      }
    }
    final chapters = <JourneyChapterSummary>[];
    for (var i = 0; i < journeyChapters.length; i++) {
      final category = journeyChapters[i];
      final ids = [for (var n = category.from; n <= category.to; n++) n + 1];
      final snapshot = CampaignProgressPolicy.chapterProgress(
        state,
        firstLevel: ids.first,
        lastLevel: ids.last,
      );
      final status = snapshot.completed
          ? JourneyChapterStatus.completed
          : snapshot.locked
              ? JourneyChapterStatus.locked
              : snapshot.completedLevels > 0
                  ? JourneyChapterStatus.inProgress
                  : JourneyChapterStatus.available;
      int? next;
      for (final id in ids) {
        if (lessonStatusFor(state, id) == JourneyLessonStatus.available) {
          next = id;
          break;
        }
      }
      chapters.add(JourneyChapterSummary(
        index: i,
        category: category,
        lessonIds: List.unmodifiable(ids),
        completedLessons: snapshot.completedLevels,
        status: status,
        isActive: frontier != null && ids.contains(frontier),
        nextLessonId: next,
        prerequisiteLessonId:
            status == JourneyChapterStatus.locked && ids.first > 1
                ? ids.first - 1
                : null,
      ));
    }
    return JourneyCurriculum._(state, List.unmodifiable(chapters));
  }

  /// Existing rules only: completed, else unlocked (available), else locked.
  static JourneyLessonStatus lessonStatusFor(
      CampaignProgressState state, int lessonId) {
    if (CampaignProgressPolicy.isLessonCompleted(state, lessonId)) {
      return JourneyLessonStatus.completed;
    }
    return ProgressionRules.isJourneyLessonUnlocked(
      lessonId: lessonId,
      maxUnlockedLevel: state.maxUnlockedLevel,
    )
        ? JourneyLessonStatus.available
        : JourneyLessonStatus.locked;
  }

  int get totalLessons =>
      chapters.fold(0, (sum, chapter) => sum + chapter.totalLessons);
  int get completedLessons =>
      chapters.fold(0, (sum, chapter) => sum + chapter.completedLessons);
  int get completedChapters => chapters
      .where((chapter) => chapter.status == JourneyChapterStatus.completed)
      .length;
  bool get isComplete => completedChapters == chapters.length;

  /// Index of the chapter holding the learner's next lesson, if any.
  int? get activeChapterIndex {
    for (final chapter in chapters) {
      if (chapter.isActive) return chapter.index;
    }
    return null;
  }

  /// The chapter to show when the Journey opens: the active chapter; after
  /// completing everything, the final chapter; otherwise the first chapter.
  /// Derived from progress, never from a stored chapter identifier, so new
  /// or reordered chapters cannot leave a stale selection.
  int get initialSelection =>
      activeChapterIndex ?? (isComplete ? chapters.length - 1 : 0);

  /// Clamps a remembered selection to the current curriculum.
  int validSelection(int? index) =>
      index != null && index >= 0 && index < chapters.length
          ? index
          : initialSelection;

  /// Chapter index for [lessonId], or null.
  int? chapterIndexForLesson(int lessonId) {
    for (final chapter in chapters) {
      if (chapter.lessonIds.contains(lessonId)) return chapter.index;
    }
    return null;
  }
}

/// User-facing label for an existing lesson type.
String journeyLessonTypeLabel(QQLevel level) => switch (level) {
      ConceptCheckLevel() => 'Concept check',
      McqLevel() => 'Question',
      FillTheGateLevel() => 'Fill the gate',
      CircuitReadingLevel() => 'Circuit reading',
      MeasurementLabLevel() => 'Measurement lab',
      ComposerLevel() => 'Circuit',
    };
