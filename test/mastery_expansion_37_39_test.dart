import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'support/mastery_math_test_platform.dart';

const ids = ['finite_shot_evidence', 'four_bell_decoder', 'odd_parity_oracle'];
void main() {
  useMasteryMathTestPlatform();
  ComposerLevel composer(String id) =>
      mastery2Catalogue.requireBySemanticId(id).levelDefinition
          as ComposerLevel;
  test(
      '42 catalogue identities exactly match presentations; archive remains independent',
      () {
    expect(mastery2Catalogue.length, 42);
    expect(mastery2Catalogue.semanticIds.toSet(),
        mastery2Presentations.keys.toSet());
    expect(
        mastery2Catalogue.orderedDefinitions
            .skip(36)
            .take(3)
            .map((d) => d.semanticId),
        ids);
    for (var id = 61; id <= 114; id++) {
      expect(getHistoricalMasteryById(id), isNotNull);
    }
  });
  test(
      'finite-shot evidence distinguishes fluctuations, zero support and classical correlation',
      () {
    final level = mastery2Catalogue.requireBySemanticId(ids[0]).levelDefinition
        as ConceptCheckLevel;
    expect(level.correctOptionIndex, 2);
    expect(level.options[2], contains('alone do not certify entanglement'));
    // Binomial probability for precisely 53 of 100 allowed outcomes.
    var choose = 1.0;
    for (var i = 1; i <= 47; i++) {
      choose *= (101 - i) / i;
    }
    final probability = choose * math.pow(0.5, 100);
    expect(probability, inExclusiveRange(0.06, 0.08));
    final bell = [math.sqrt1_2, 0.0, 0.0, math.sqrt1_2];
    final probabilities = bell.map((a) => a * a).toList();
    for (var i = 0; i < 4; i++) {
      expect(probabilities[i], closeTo([0.5, 0, 0, 0.5][i], 1e-12));
    }
    // A separable 50/50 mixture has exactly the same diagonal probabilities.
    final mixture = [
      for (var i = 0; i < 4; i++)
        0.5 * (i == 0 ? 1 : 0) + 0.5 * (i == 3 ? 1 : 0)
    ];
    for (var i = 0; i < 4; i++) {
      expect(probabilities[i], closeTo(mixture[i], 1e-12));
    }
    expect(level.solutionExplanation, contains('classical equal mixture'));
  });
  test('decoder exact full unitary maps four signed Bell inputs independently',
      () {
    final level = composer(ids[1]);
    final circuit = buildCanonicalSolutionCircuit(level);
    expect(level.validationMode, ValidationMode.unitary);
    expect(level.validateCircuit(circuit), isTrue);
    final matrix = circuit.getOverallCircuitMatrix().toComplexList();
    final inputs = [
      [1, 0, 0, 1],
      [1, 0, 0, -1],
      [0, 1, 1, 0],
      [0, 1, -1, 0]
    ];
    for (var input = 0; input < 4; input++) {
      for (var row = 0; row < 4; row++) {
        var real = 0.0;
        var imaginary = 0.0;
        for (var col = 0; col < 4; col++) {
          real += matrix[row][col].real * inputs[input][col] * math.sqrt1_2;
          imaginary +=
              matrix[row][col].imaginary * inputs[input][col] * math.sqrt1_2;
          expect(matrix[row][col].real,
              closeTo(level.targetUnitary![row][col].real, 1e-12));
        }
        expect(real, closeTo(row == input ? (input == 3 ? -1 : 1) : 0, 1e-12));
        expect(imaginary, closeTo(0, 1e-12));
      }
    }
    final shortcut = QuantumCircuit(currentLevel: level);
    shortcut.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
    shortcut.runSimulation(); // Same output for preview |00>, wrong operator.
    expect(level.validateCircuit(shortcut), isFalse);
    expect(
        level.validateCircuit(
            QuantumCircuit(currentLevel: level)..runSimulation()),
        isFalse);
  });
  test('parity oracle exact eight columns; unchanged preview cannot pass', () {
    final level = composer(ids[2]);
    final circuit = buildCanonicalSolutionCircuit(level);
    expect(level.validateCircuit(circuit), isTrue);
    final matrix = circuit.getOverallCircuitMatrix().toComplexList();
    for (var col = 0; col < 8; col++) {
      final odd =
          col.toRadixString(2).split('').where((b) => b == '1').length.isOdd;
      for (var row = 0; row < 8; row++) {
        expect(matrix[row][col].real,
            closeTo(row == col ? (odd ? -1 : 1) : 0, 1e-12));
        expect(matrix[row][col].imaginary, closeTo(0, 1e-12));
      }
    }
    final wrong = QuantumCircuit(currentLevel: level)..runSimulation();
    expect(level.validateCircuit(wrong), isFalse);
    wrong.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.z), 0, 0);
    wrong.runSimulation();
    expect(level.validateCircuit(wrong), isFalse);
  });
  test('semantic completions persist without Journey/discovery/archive awards',
      () async {
    final storage = InMemoryAppStorage();
    final controller = CampaignProgressController(
        store: SharedPreferencesCampaignProgressStore(storage: storage));
    await controller.load();
    for (final definition in mastery2Catalogue.orderedDefinitions.take(36)) {
      await controller.completeMasteryChallenge(definition.semanticId);
    }
    final before = controller.state;
    for (final id in ids) {
      await controller.completeMasteryChallenge(id);
    }
    final reload = CampaignProgressController(
        store: SharedPreferencesCampaignProgressStore(storage: storage));
    await reload.load();
    expect(reload.state.completedMasterySemanticIds,
        {...before.completedMasterySemanticIds, ...ids});
    expect(reload.state.completedLessonIds, before.completedLessonIds);
    expect(reload.state.completedChallengeIds, before.completedChallengeIds);
    expect(reload.state.explicitlyUnlockedDiscoveryIds,
        before.explicitlyUnlockedDiscoveryIds);
  });
  testWidgets('new activities route through real Web and native presenters',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final id in ids) {
      final d = mastery2Catalogue.requireBySemanticId(id);
      expect(d.levelDefinition,
          id == ids[0] ? isA<ConceptCheckLevel>() : isA<ComposerLevel>());
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: WebLessonWorkspace(
                  key: ValueKey(id),
                  levelId: d.displayOrder,
                  level: d.levelDefinition,
                  masteryChallenge: d,
                  alreadyCompleted: false,
                  onCompleted: () async {},
                  onNextLesson: () {},
                  onBackToChapter: () {},
                  onOpenNotebook: () {}))));
      await tester.pumpAndSettle();
      expect(find.text(id == ids[0] ? 'Confirm Answer' : 'Check Circuit'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(MaterialApp(
          home: LevelUIRouter.buildLevelUI(
              level: d.levelDefinition,
              levelId: d.displayOrder,
              masteryChallenge: d,
              onLevelUnlocked: null)));
      await tester.pumpAndSettle();
      expect(find.text('Mastery Challenge ${d.displayOrder}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
