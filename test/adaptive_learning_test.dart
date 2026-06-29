import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/adaptive_learning.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  group('AdaptiveLearningSession', () {
    test('detects repeated incorrect gate sequences', () {
      final level = getQQLevelById(38)!;
      final session = AdaptiveLearningSession(
        level: level,
        notebookEntry: notebookEntriesByDiscoveryTitle[level.discoveryTitle],
      );

      expect(
        session.recordComposerAttempt(
          signature: 'cx:q0-q1',
          gateCounts: const {SelectedGateType.cnot: 1},
          correct: false,
        ),
        isNull,
      );

      expect(
        session.recordComposerAttempt(
          signature: 'cx:q0-q1',
          gateCounts: const {SelectedGateType.cnot: 1},
          correct: false,
        ),
        isNull,
      );

      final insight = session.recordComposerAttempt(
        signature: 'cx:q0-q1',
        gateCounts: const {SelectedGateType.cnot: 1},
        correct: false,
      );

      expect(insight, isNotNull);
      expect(
        insight!.confusionType,
        AdaptiveConfusionType.repeatedIncorrectGateSequence,
      );
      expect(
        insight.misconceptionCategory,
        AdaptiveMisconceptionCategory.mechanismMisunderstanding,
      );
      expect(insight.notebookReinforcement, contains('Phase Kickback'));
    });

    test('detects gate overuse without solving for the player', () {
      final level = getQQLevelById(38)!;
      final session = AdaptiveLearningSession(level: level);

      final insight = session.recordComposerAttempt(
        signature: 'many-h',
        gateCounts: const {SelectedGateType.hadamard: 4},
        correct: false,
      );

      expect(insight, isNotNull);
      expect(insight!.confusionType, AdaptiveConfusionType.repeatedGateOveruse);
      expect(insight.minimalHint, isNot(contains('solution')));
    });

    test('detects oscillation between incorrect states', () {
      final level = getQQLevelById(30)!;
      final session = AdaptiveLearningSession(level: level);

      for (final signature in ['a', 'b', 'a']) {
        expect(
          session.recordComposerAttempt(
            signature: signature,
            gateCounts: const {SelectedGateType.x: 1},
            correct: false,
          ),
          isNull,
        );
      }

      final insight = session.recordComposerAttempt(
        signature: 'b',
        gateCounts: const {SelectedGateType.x: 1},
        correct: false,
      );

      expect(insight, isNotNull);
      expect(
        insight!.confusionType,
        AdaptiveConfusionType.oscillatingIncorrectStates,
      );
    });

    test('detects MCQ conceptual misses', () {
      final level = getQQLevelById(35)!;
      final session = AdaptiveLearningSession(
        level: level,
        notebookEntry: notebookEntriesByDiscoveryTitle[level.discoveryTitle],
      );

      final insight = session.recordMcqAnswer(
        selectedIndex: 0,
        correctIndex: 1,
      );

      expect(insight, isNotNull);
      expect(
        insight!.misconceptionCategory,
        AdaptiveMisconceptionCategory.conceptualInterpretation,
      );
      expect(insight.minimalHint, contains('concept check'));
    });

    test('notebook opening prevents notebook-performance misalignment trigger',
        () {
      final level = getQQLevelById(38)!;
      final session = AdaptiveLearningSession(
        level: level,
        notebookEntry: notebookEntriesByDiscoveryTitle[level.discoveryTitle],
      )..recordNotebookOpened();

      AdaptiveLearningInsight? insight;
      for (int i = 0; i < 3; i++) {
        insight = session.recordComposerAttempt(
          signature: 'unique-$i',
          gateCounts: const {SelectedGateType.cnot: 1},
          correct: false,
        );
      }

      expect(insight, isNull);
    });
  });
}
