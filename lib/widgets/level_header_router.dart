import 'package:flutter/material.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/widgets/level_type_headers.dart';

class LevelHeaderRouter {
  const LevelHeaderRouter._();

  static PreferredSizeWidget headerFor({
    required QQLevel level,
    required int levelId,
    required bool compact,
    List<Widget> actions = const [],
    String? title,
    String? subtitle,
  }) {
    final resolvedTitle = _levelTitle(level, levelId);

    return switch (level) {
      ComposerLevel _ => ComposerHeader(
          compact: compact,
          title: title ?? 'Level $levelId',
          subtitle: subtitle ?? resolvedTitle,
          actions: actions,
        ),
      ConceptCheckLevel _ || McqLevel _ => ConceptCheckHeader(
          compact: compact,
          levelId: levelId,
          title: resolvedTitle,
          actions: actions,
        ),
      FillTheGateLevel _ => FillGateHeader(
          levelId: levelId,
          title: resolvedTitle,
        ),
      CircuitReadingLevel _ => ReadingHeader(
          levelId: levelId,
          title: resolvedTitle,
        ),
      MeasurementLabLevel _ => ExperimentHeader(
          levelId: levelId,
          title: resolvedTitle,
        ),
    };
  }

  static String _levelTitle(QQLevel level, int levelId) {
    final title = level.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final task = level.taskDescription.trim();
    if (task.isNotEmpty) return task;
    return 'Level $levelId';
  }
}
