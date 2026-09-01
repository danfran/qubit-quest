import 'package:quantumquiz/models/qq_level.dart';

/// The learner intent that governs when an activity evaluates an answer.
///
/// Presenter layout is deliberately excluded: mobile and Web can compose the
/// same interaction differently while preserving this semantic trigger.
enum ActivityInteractionKind {
  conceptualChoice,
  directManipulation,
  constructedSolution,
  experimentObservation,
}

abstract final class ActivityBehaviorContract {
  static ActivityInteractionKind forLevel(QQLevel level) => switch (level) {
        ConceptCheckLevel _ ||
        McqLevel _ ||
        CircuitReadingLevel _ =>
          ActivityInteractionKind.conceptualChoice,
        FillTheGateLevel _ => ActivityInteractionKind.directManipulation,
        ComposerLevel _ => ActivityInteractionKind.constructedSolution,
        MeasurementLabLevel _ => ActivityInteractionKind.experimentObservation,
      };

  static bool requiresExplicitEvaluation(ActivityInteractionKind kind) =>
      switch (kind) {
        ActivityInteractionKind.conceptualChoice ||
        ActivityInteractionKind.constructedSolution =>
          true,
        ActivityInteractionKind.directManipulation ||
        ActivityInteractionKind.experimentObservation =>
          false,
      };
}
