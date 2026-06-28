import 'package:flutter/widgets.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/screens/circuit_reading_screen.dart';
import 'package:quantumquiz/screens/fill_the_gate_screen.dart';
import 'package:quantumquiz/screens/mcq_screen.dart';
import 'package:quantumquiz/screens/measurement_lab_screen.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';

class LevelUIRouter {
  const LevelUIRouter._();

  static Widget buildLevelUI({
    required QQLevel level,
    required int levelId,
    required Function(int)? onLevelUnlocked,
  }) {
    return switch (level) {
      ComposerLevel l => QuantumComposer(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
        ),
      ConceptCheckLevel l => McqScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
        ),
      McqLevel l => McqScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
        ),
      FillTheGateLevel l => FillTheGateScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
        ),
      CircuitReadingLevel l => CircuitReadingScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
        ),
      MeasurementLabLevel l => MeasurementLabScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: onLevelUnlocked,
        ),
    };
  }
}
