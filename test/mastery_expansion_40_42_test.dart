import 'dart:math' as math;
import 'package:quantumquiz/models/canonical_composer_solution.dart';
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

const ids = [
  'half_marked_search',
  'search_overshoot_forensics',
  'nonuniform_reference_reflection'
];
void main() {
  useMasteryMathTestPlatform();
  List<double> round(List<double> input, Set<int> marked) {
    final oracle = [
      for (var i = 0; i < input.length; i++)
        marked.contains(i) ? -input[i] : input[i]
    ];
    final mean = oracle.reduce((a, b) => a + b) / oracle.length;
    return [for (final a in oracle) 2 * mean - a];
  }

  void vector(List<double> actual, List<double> expected) {
    expect(actual.length, expected.length);
    for (var i = 0; i < actual.length; i++) {
      expect(actual[i], closeTo(expected[i], 1e-12));
    }
    expect(actual.fold<double>(0, (sum, a) => sum + a * a), closeTo(1, 1e-12));
  }

  test(
      '42 identities, presentation parity, and independent historical namespace',
      () {
    expect(mastery2Catalogue.length, 42);
    expect(mastery2Catalogue.semanticIds.toSet(),
        mastery2Presentations.keys.toSet());
    expect(
        mastery2Catalogue.orderedDefinitions.skip(39).map((d) => d.semanticId),
        ids);
    for (var i = 61; i <= 114; i++) {
      expect(getHistoricalMasteryById(i), isNotNull);
    }
  });
  test('half-marked signed cycle proves constant success, not monotonic growth',
      () {
    var state = [0.5, 0.5, 0.5, 0.5];
    final cycle = [
      [0.5, 0.5, 0.5, 0.5],
      [-0.5, 0.5, 0.5, -0.5],
      [-0.5, -0.5, -0.5, -0.5],
      [0.5, -0.5, -0.5, 0.5]
    ];
    for (var r = 0; r < 12; r++) {
      vector(state, cycle[r % 4]);
      expect(state[1] * state[1] + state[2] * state[2], closeTo(0.5, 1e-12));
      state = round(state, {1, 2});
    }
    final level = mastery2Catalogue.requireBySemanticId(ids[0]).levelDefinition
        as ConceptCheckLevel;
    expect(level.correctOptionIndex, 0);
    expect(level.options[0], contains('remains 1/2'));
    expect(level.options.toSet(), hasLength(4));
    expect(level.hints, hasLength(2));
    expect(level.solutionExplanation, contains('(DO)^2 s=−s'));
  });
  test(
      'forensic snapshots follow independent eight-amplitude evolution and recurrence',
      () {
    var state = List<double>.filled(8, 1 / math.sqrt(8));
    var b = 1.0, c = 1.0;
    final pairs = [
      [1.0, 1.0],
      [2.5, 0.5],
      [2.75, -0.25],
      [1.625, -0.875]
    ];
    final probabilities = [1 / 8, 25 / 32, 121 / 128, 169 / 512];
    final measured = <double>[];
    for (var r = 0; r < 4; r++) {
      vector(state, [
        for (var i = 0; i < 8; i++)
          (i == 6 ? pairs[r][0] : pairs[r][1]) / math.sqrt(8)
      ]);
      expect(b, closeTo(pairs[r][0], 1e-12));
      expect(c, closeTo(pairs[r][1], 1e-12));
      measured.add(state[6] * state[6]);
      expect(measured.last, closeTo(probabilities[r], 1e-12));
      expect((b * b + 7 * c * c) / 8, closeTo(1, 1e-12));
      final mean = (7 * c - b) / 8;
      final nextB = 2 * mean + b;
      c = 2 * mean - c;
      b = nextB;
      state = round(state, {6});
    }
    expect(measured.indexOf(measured.reduce(math.max)), 2);
    expect(probabilities[3], lessThan(probabilities[2]));
    final level = mastery2Catalogue.requireBySemanticId(ids[1]).levelDefinition
        as ConceptCheckLevel;
    expect(level.correctOptionIndex, 3);
    expect(level.options[3], contains('121/128 to 169/512'));
    expect(level.options.toSet(), hasLength(4));
    expect(level.hints, hasLength(2));
    // The other diagnoses respectively assert monotonicity, equal magnitudes,
    // and that scaled b is a probability; the computed values refute all three.
    expect(pairs[2][0].abs(), isNot(pairs[3][0].abs()));
    expect(pairs[2][0], greaterThan(1));
    expect(probabilities[2], lessThan(1));
  });
  test(
      'reference reflection exact matrix equals I-2rr† and canonical simulator columns',
      () {
    final level = mastery2Catalogue.requireBySemanticId(ids[2]).levelDefinition
        as ComposerLevel;
    expect(level.validationMode, ValidationMode.unitary);
    expect(level.alternateTargetUnitaries, isEmpty);
    final circuit = buildCanonicalSolutionCircuit(level);
    expect(level.validateCircuit(circuit), isTrue);
    final matrix = circuit.getOverallCircuitMatrix().toComplexList();
    final reference = [math.sqrt1_2, math.sqrt1_2, 0.0, 0.0];
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        final expected =
            (row == col ? 1 : 0) - 2 * reference[row] * reference[col];
        expect(matrix[row][col].real, closeTo(expected, 1e-12));
        expect(matrix[row][col].imaginary, closeTo(0, 1e-12));
        expect(level.targetUnitary![row][col].real, closeTo(expected, 1e-12));
      }
    }
    // Actual simulator evolution for each computational-basis input.
    for (var input = 0; input < 4; input++) {
      final fixture = ComposerLevel.fromBinaryString(
          taskDescription: 'Verification fixture',
          initialQubitsStateString: input.toRadixString(2).padLeft(2, '0'),
          availableGates: level.availableGates,
          solutionFinalVector: const []);
      final actual = QuantumCircuit(currentLevel: fixture);
      applyCanonicalCircuitSteps(actual, level.canonicalSolution!.steps);
      actual.runSimulation();
      for (var row = 0; row < 4; row++) {
        expect(actual.currentState.stateVector[row].real,
            closeTo(matrix[row][input].real, 1e-12));
        expect(
            actual.currentState.stateVector[row].imaginary, closeTo(0, 1e-12));
      }
    }
  });
  test(
      'empty, preparation-only, wrong-basis reflection and preview shortcut fail',
      () {
    final level = mastery2Catalogue.requireBySemanticId(ids[2]).levelDefinition
        as ComposerLevel;
    const h0 =
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0);
    const h1 =
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 1);
    const x0 = CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0);
    const z0 = CanonicalCircuitStep.single(SelectedGateType.z, targetQubit: 0);
    final canonical = level.canonicalSolution!.steps;
    final wrongUniform = [h1, ...canonical, h1];
    for (final steps in <List<CanonicalCircuitStep>>[
      [],
      [h0],
      wrongUniform,
      [x0, z0]
    ]) {
      final circuit = QuantumCircuit(currentLevel: level);
      applyCanonicalCircuitSteps(circuit, steps);
      circuit.runSimulation();
      expect(level.validateCircuit(circuit), isFalse);
    }
    // Z X maps the preview 00 to -01, yet does not implement the reflection.
    // X Z X Z = -I. Append it to canonical R to reject the opposite sign (-R).
    final opposite = QuantumCircuit(currentLevel: level);
    applyCanonicalCircuitSteps(opposite, [...canonical, x0, z0, x0, z0]);
    opposite.runSimulation();
    expect(level.validateCircuit(opposite), isFalse);
  });
  test('semantic completions persist without Journey/discovery/archive awards',
      () async {
    final storage = InMemoryAppStorage();
    await SharedPreferencesCampaignProgressStore(storage: storage).save(
        CampaignProgressState(
            maxUnlockedLevel: 2,
            completedLessonIds: {1},
            completedChallengeIds: {61, 114},
            explicitlyUnlockedDiscoveryIds: {'discovery_001'},
            legacyUnlockedDiscoveryTitles: {'Historical discovery title'}));
    final controller = CampaignProgressController(
        store: SharedPreferencesCampaignProgressStore(storage: storage));
    await controller.load();
    for (final definition in mastery2Catalogue.orderedDefinitions.take(39)) {
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
    expect(reload.state.maxUnlockedLevel, before.maxUnlockedLevel);
    expect(reload.state.legacyUnlockedDiscoveryTitles,
        before.legacyUnlockedDiscoveryTitles);
    expect(
        reload.unlockedDiscoveryTitles(), controller.unlockedDiscoveryTitles());
    expect(reload.state.completedMasterySemanticIds, hasLength(42));
  });
  testWidgets('new activities route through real Web and native presenters',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final id in ids) {
      final d = mastery2Catalogue.requireBySemanticId(id);
      expect(d.levelDefinition,
          id != ids[2] ? isA<ConceptCheckLevel>() : isA<ComposerLevel>());
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
      expect(find.text(id != ids[2] ? 'Confirm Answer' : 'Check Circuit'),
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
