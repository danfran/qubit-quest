import 'package:flutter/widgets.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/screens/circuit_reading_screen.dart';
import 'package:quantumquiz/screens/fill_the_gate_screen.dart';
import 'package:quantumquiz/screens/mcq_screen.dart';
import 'package:quantumquiz/screens/measurement_lab_screen.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';

enum LevelUIRouteKind {
  composer,
  conceptCheck,
  fillGate,
  circuitReading,
  measurementLab,
}

class LevelUIRouter {
  const LevelUIRouter._();

  static LevelUIRouteKind routeKindFor(QQLevel level) {
    return switch (level) {
      ComposerLevel _ => LevelUIRouteKind.composer,
      ConceptCheckLevel _ || McqLevel _ => LevelUIRouteKind.conceptCheck,
      FillTheGateLevel _ => LevelUIRouteKind.fillGate,
      CircuitReadingLevel _ => LevelUIRouteKind.circuitReading,
      MeasurementLabLevel _ => LevelUIRouteKind.measurementLab,
    };
  }

  static Widget buildLevelUI({
    required QQLevel level,
    required int levelId,
    required Function(int)? onLevelUnlocked,
    bool isCompleted = false,
    MasteryChallengeDefinition? masteryChallenge,
  }) {
    return switch (level) {
      ComposerLevel l => QuantumComposer(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
          isCompleted: isCompleted,
          masteryChallenge: masteryChallenge,
        ),
      ConceptCheckLevel l => McqScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
          isCompleted: isCompleted,
          masteryChallenge: masteryChallenge,
        ),
      McqLevel l => McqScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
          isCompleted: isCompleted,
          masteryChallenge: masteryChallenge,
        ),
      FillTheGateLevel l => FillTheGateScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
          isCompleted: isCompleted,
        ),
      CircuitReadingLevel l => CircuitReadingScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
          isCompleted: isCompleted,
        ),
      MeasurementLabLevel l => MeasurementLabScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
          isCompleted: isCompleted,
        ),
    };
  }
}
