import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/screens/mcq_screen.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/validation/chapter_release_gate.dart';
import 'support/mastery_math_test_platform.dart';

ComposerLevel lesson(int id) => getJourneyLessonById(id)! as ComposerLevel;

void main() {
  useMasteryMathTestPlatform();
  test('61 reflects signed amplitudes, not probabilities', () {
    final level = getJourneyLessonById(61)! as ConceptCheckLevel;
    const amplitudes = [0.5, 0.5, -0.5, 0.5];
    final mean = amplitudes.reduce((a, b) => a + b) / 4;
    final reflected = amplitudes.map((a) => 2 * mean - a).toList();
    expect(mean, 0.25);
    expect(reflected, [0, 0, 1, 0]);
    expect(reflected.map((a) => a * a), [0, 0, 1, 0]);
    expect(level.options[level.correctOptionIndex], r'\([0,0,1,0]\)');
    expect(level.options, hasLength(5));
  });

  test('62 canonical circuit is exactly I minus twice the uniform projector',
      () {
    final level = lesson(62);
    final circuit = buildCanonicalSolutionCircuit(level);
    addTearDown(circuit.dispose);
    expect(level.validationMode, ValidationMode.unitary);
    expect(level.alternateTargetUnitaries, isEmpty);
    final matrix = circuit.getOverallCircuitMatrix().toComplexList();
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final expected = (r == c ? 1.0 : 0.0) - 0.5;
        expect(matrix[r][c].real.toDouble(), closeTo(expected, 1e-9));
        expect(matrix[r][c].imaginary.toDouble(), closeTo(0, 1e-9));
        expect(level.targetUnitary![r][c].real.toDouble(), expected);
      }
    }
    expect(level.validateCircuit(circuit), isTrue);
  });

  test(
      '63 fixed preparation and oracle mark index2 without changing probabilities',
      () {
    final circuit = QuantumCircuit(currentLevel: lesson(63));
    addTearDown(circuit.dispose);
    expect(circuit.logicalGates, hasLength(5));
    expect(circuit.logicalGates.every((g) => !g.isDeletable), isTrue);
    final state = circuit.currentState.stateVector;
    for (var i = 0; i < 4; i++) {
      expect(state[i].real.toDouble(), closeTo(i == 2 ? -0.5 : 0.5, 1e-9));
      expect(state[i].magnitude * state[i].magnitude, closeTo(0.25, 1e-9));
    }
    expect(lesson(63).validateCircuit(circuit), isFalse);
  });

  test('63 full operation has the independently calculated signed permutation',
      () {
    final level = lesson(63);
    final circuit = buildCanonicalSolutionCircuit(level);
    addTearDown(circuit.dispose);
    expect(level.validationMode, ValidationMode.unitary);
    expect(level.alternateTargetUnitaries, isEmpty);
    // Derived from (-D) O10 (H tensor H), not the authored target matrix.
    const outputRows = [2, 0, 3, 1];
    const signs = [-1, 1, -1, -1];
    final matrix = circuit.getOverallCircuitMatrix().toComplexList();
    for (var c = 0; c < 4; c++) {
      for (var r = 0; r < 4; r++) {
        final expected = r == outputRows[c] ? signs[c].toDouble() : 0.0;
        expect(matrix[r][c].real.toDouble(), closeTo(expected, 1e-9));
        expect(matrix[r][c].imaginary.toDouble(), closeTo(0, 1e-9));
        expect(level.targetUnitary![r][c].real.toDouble(), expected);
      }
    }
    expect(level.validateCircuit(circuit), isTrue);
    final state = circuit.currentState.stateVector;
    expect(state[2].real.toDouble(), closeTo(-1, 1e-9));
    for (var i = 0; i < 4; i++) {
      expect(state[i].magnitude * state[i].magnitude,
          closeTo(i == 2 ? 1 : 0, 1e-9));
    }
  });

  for (final id in [62, 63]) {
    test(
        '$id rejects a different operator even with exactly the correct final state',
        () {
      final level = lesson(id);
      final circuit = QuantumCircuit(currentLevel: level);
      addTearDown(circuit.dispose);
      const z0 = [
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
        CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
      ];
      // Z|00>=|00> before62; Z0|-10>=|-10> after63. Other inputs differ.
      if (id == 62) applyCanonicalCircuitSteps(circuit, z0);
      applyCanonicalCircuitSteps(circuit, level.canonicalSolution!.steps);
      if (id == 63) applyCanonicalCircuitSteps(circuit, z0);
      circuit.runSimulation();
      final result = level.evaluateCircuit(circuit);
      expect(result.stateMatches, isTrue);
      expect(result.success, isFalse);
    });
    test('$id rejects incomplete and extra-reflection circuits', () {
      final level = lesson(id);
      final circuit = QuantumCircuit(currentLevel: level);
      addTearDown(circuit.dispose);
      expect(level.validateCircuit(circuit), isFalse);
      applyCanonicalCircuitSteps(circuit, level.canonicalSolution!.steps);
      applyCanonicalCircuitSteps(circuit, level.canonicalSolution!.steps);
      circuit.runSimulation();
      expect(level.validateCircuit(circuit), isFalse);
    });
  }

  test('60/60 migrates to61, progresses through66 and stops with no67',
      () async {
    final controller = CampaignProgressController(
        store: SharedPreferencesCampaignProgressStore(
            storage: InMemoryAppStorage({
      'qq_progress_schema_version': 2,
      'qq_progress_max_unlocked_level': 115,
      'qq_progress_completed_lesson_ids': [for (var i = 1; i <= 60; i++) '$i'],
      'qq_progress_completed_challenge_ids': ['61', '114'],
    })));
    await controller.load();
    expect(controller.continueJourneyDestination.levelNumber, 61);
    for (final id in [61, 62, 63, 64, 65, 66]) {
      expect(controller.state.maxUnlockedLevel, id);
      expect(controller.state.completedLessonIds.contains(id), isFalse);
      await controller.completeLesson(id);
    }
    expect(controller.continueJourneyDestination.isJourneyComplete, isTrue);
    expect(getJourneyLessonById(67), isNull);
    expect(controller.state.completedChallengeIds, {61, 114});
    expect(
        controller.state.completedLessonIds, {for (var i = 1; i <= 66; i++) i});
  });

  test('native routes use real Journey content for61–66, not archived IDs', () {
    for (final id in [61, 62, 63, 64, 65, 66]) {
      final level = getJourneyLessonById(id)!;
      expect(level, same(journeyLessons[id - 1]));
      expect(level, same(numericActivityCatalogue.journey[id]));
      expect(identical(level, getHistoricalMasteryById(id)), isFalse);
      final route = LevelUIRouter.buildLevelUI(
          level: level, levelId: id, onLevelUnlocked: null);
      if (id == 61 || id >= 64) {
        expect(route, isA<McqScreen>());
        expect((route as McqScreen).level, same(level));
      } else {
        expect(route, isA<QuantumComposer>());
        expect((route as QuantumComposer).level, same(level));
      }
    }
  });

  for (final size in [
    const Size(800, 600),
    const Size(430, 900),
    const Size(1280, 900)
  ]) {
    testWidgets('real Web Journey opens and completes Chapter13 at $size',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final controller = CampaignProgressController(
          store: InMemoryCampaignProgressStore(
              CampaignProgressPolicy.completeLesson(
                  CampaignProgressState.fresh(), 60)));
      await controller.load();
      var mastery = 0;
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
              body: WebJourneyWorkspace(
                  progressController: controller,
                  onOpenNotebook: () {},
                  onOpenMastery: () {
                    mastery++;
                  }))));
      final node = find.byKey(const ValueKey('learning-map-chapter-13'));
      await tester.ensureVisible(node);
      await tester.pumpAndSettle();
      await tester.tap(node);
      await tester.pumpAndSettle();
      expect(mastery, 0);
      final workspace =
          tester.widget<WebLessonWorkspace>(find.byType(WebLessonWorkspace));
      expect(workspace.levelId, 61);
      expect(workspace.level, same(getJourneyLessonById(61)));
      expect(workspace.masteryChallenge, isNull);
      // Exercise the actual routing callbacks; quantum acceptance is tested above.
      for (final id in [61, 62, 63, 64, 65, 66]) {
        final active =
            tester.widget<WebLessonWorkspace>(find.byType(WebLessonWorkspace));
        expect(active.levelId, id);
        expect(active.level, same(getJourneyLessonById(id)));
        await active.onCompleted();
        await tester.pump();
        active.onNextLesson();
        await tester.pumpAndSettle();
      }
      expect(find.byType(WebLessonWorkspace), findsNothing);
      expect(find.byType(LearningMapScreen), findsOneWidget);
      expect(mastery, 0);
      expect(getJourneyLessonById(67), isNull);
    });
  }

  test('chapter grouping and Notebook release coverage are complete', () {
    final chapter = journeyChapterForLesson(61)!;
    expect(chapter.from, 60);
    expect(chapter.to, 65);
    expect(chapter.isMasteryPhase, isFalse);
    expect(journeyChapterForLesson(63), same(chapter));
    expect(journeyChapterForLesson(67), isNull);
    final release = ChapterReleaseGate.validateChapter(chapter);
    expect(release.passed, isTrue, reason: release.toReport());
    for (final (id, title) in [
      (61, 'Reflection About the Mean'),
      (62, 'Diffusion as a Circuit'),
      (63, 'Four-State Quantum Search')
    ]) {
      expect(CampaignProgressPolicy.discoveryIdForLevel(id), 'discovery_0$id');
      expect(
          CampaignProgressPolicy.discoveryTitleForId('discovery_0$id'), title);
    }
  });
}
