import 'package:flutter/material.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/widgets/level_type_headers.dart';

enum LevelHeaderKind {
  composer,
  conceptCheck,
  fillGate,
  reading,
  experiment,
}

class LevelHeaderRouter {
  const LevelHeaderRouter._();

  static const int guidedDiscoveryLevelCount = 60;

  static bool isMasteryLevel(int levelId) {
    return levelId > guidedDiscoveryLevelCount;
  }

  static int masteryChallengeNumber(int levelId) {
    return levelId - guidedDiscoveryLevelCount;
  }

  static String displayLabel(int levelId, {bool compact = false}) {
    if (levelId == -1) return 'Composer';
    if (isMasteryLevel(levelId)) {
      final challengeNumber = masteryChallengeNumber(levelId);
      return compact
          ? 'Challenge $challengeNumber'
          : 'Mastery Challenge $challengeNumber';
    }
    return 'Lesson $levelId';
  }

  static LevelHeaderKind headerKindFor(QQLevel level) {
    return switch (level) {
      ComposerLevel _ => LevelHeaderKind.composer,
      ConceptCheckLevel _ || McqLevel _ => LevelHeaderKind.conceptCheck,
      FillTheGateLevel _ => LevelHeaderKind.fillGate,
      CircuitReadingLevel _ => LevelHeaderKind.reading,
      MeasurementLabLevel _ => LevelHeaderKind.experiment,
    };
  }

  static PreferredSizeWidget headerFor({
    required QQLevel level,
    required int levelId,
    required bool compact,
    List<Widget> actions = const [],
    String? title,
    String? subtitle,
    bool isCompleted = false,
    int? masteryDisplayOrder,
  }) {
    final resolvedTitle = _levelTitle(level, levelId);
    final displayLabel = masteryDisplayOrder == null
        ? LevelHeaderRouter.displayLabel(levelId)
        : 'Mastery Challenge $masteryDisplayOrder';
    final compactDisplayLabel = masteryDisplayOrder == null
        ? LevelHeaderRouter.displayLabel(levelId, compact: true)
        : 'Challenge $masteryDisplayOrder';
    final isMastery = masteryDisplayOrder != null ||
        LevelHeaderRouter.isMasteryLevel(levelId);

    if (isMastery &&
        (masteryDisplayOrder ?? masteryChallengeNumber(levelId)) <= 20) {
      return MasteryActivityHeader(
        title: title ?? displayLabel,
        subtitle: subtitle ?? resolvedTitle,
        isCompleted: isCompleted,
        actions: actions,
      );
    }

    return switch (level) {
      ComposerLevel _ => ComposerHeader(
          compact: compact,
          title: title ?? displayLabel,
          subtitle: subtitle ?? resolvedTitle,
          isMastery: isMastery,
          isCompleted: isCompleted && isMastery,
          actions: actions,
        ),
      ConceptCheckLevel _ || McqLevel _ => ConceptCheckHeader(
          compact: compact,
          displayLabel: displayLabel,
          title: resolvedTitle,
          isMastery: isMastery,
          isCompleted: isCompleted && isMastery,
          actions: actions,
        ),
      FillTheGateLevel _ => FillGateHeader(
          displayLabel: displayLabel,
          title: resolvedTitle,
          isMastery: isMastery,
          isCompleted: isCompleted && isMastery,
        ),
      CircuitReadingLevel _ => ReadingHeader(
          displayLabel: displayLabel,
          title: resolvedTitle,
          isMastery: isMastery,
          isCompleted: isCompleted && isMastery,
        ),
      MeasurementLabLevel _ => ExperimentHeader(
          displayLabel: compactDisplayLabel,
          title: resolvedTitle,
          isMastery: isMastery,
          isCompleted: isCompleted && isMastery,
        ),
    };
  }

  static String _levelTitle(QQLevel level, int levelId) {
    final title = level.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final task = level.taskDescription.trim();
    if (task.isNotEmpty) return task;
    return displayLabel(levelId);
  }
}
