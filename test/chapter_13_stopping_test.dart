import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';

const preparation = [
  CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
  CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 1),
];
const oracle = [
  CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
  CanonicalCircuitStep.controlled(SelectedGateType.cz,
      controlQubit: 0, targetQubit: 1),
  CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
];
void expectVector(List<double> actual, List<double> expected) {
  expect(actual.length, expected.length);
  for (var i = 0; i < actual.length; i++)
    expect(actual[i], closeTo(expected[i], 1e-9));
  expect(actual.fold<double>(0, (sum, a) => sum + a * a), closeTo(1, 1e-9));
}

List<double> reflect(List<double> a) {
  final mean = a.reduce((a, b) => a + b) / a.length;
  return a.map((value) => 2 * mean - value).toList();
}

void main() {
  test('64 chronological order produces the two stated signed distributions',
      () {
    final level = getJourneyLessonById(62)! as ComposerLevel;
    for (final oracleFirst in [true, false]) {
      final circuit = QuantumCircuit(currentLevel: level);
      addTearDown(circuit.dispose);
      applyCanonicalCircuitSteps(circuit, preparation);
      if (oracleFirst) applyCanonicalCircuitSteps(circuit, oracle);
      applyCanonicalCircuitSteps(circuit, level.canonicalSolution!.steps);
      if (!oracleFirst) {
        circuit.runSimulation();
        expectVector(
            circuit.currentState.stateVector
                .map((a) => a.real.toDouble())
                .toList(),
            [-.5, -.5, -.5, -.5]);
        applyCanonicalCircuitSteps(circuit, oracle);
      }
      circuit.runSimulation();
      final state = circuit.currentState.stateVector;
      expectVector(state.map((a) => a.real.toDouble()).toList(),
          oracleFirst ? [0, 0, -1, 0] : [-.5, -.5, .5, -.5]);
      expect(state.every((a) => a.imaginary.abs() < 1e-9), isTrue);
      expect(state[2].magnitude * state[2].magnitude,
          closeTo(oracleFirst ? 1 : .25, 1e-9));
    }
  });

  test('65 every D trace is normalized; physical -D differs by (-1)^round', () {
    final level = getJourneyLessonById(62)! as ComposerLevel;
    final circuit = QuantumCircuit(currentLevel: level);
    addTearDown(circuit.dispose);
    applyCanonicalCircuitSteps(circuit, preparation);
    var amplitudes = <double>[.5, .5, .5, .5];
    expectVector(amplitudes, [.5, .5, .5, .5]);
    const afterOracle = [
      [.5, .5, -.5, .5],
      [0.0, 0.0, -1.0, 0.0]
    ];
    const afterD = [
      [0.0, 0.0, 1.0, 0.0],
      [-.5, -.5, .5, -.5]
    ];
    for (var round = 1; round <= 2; round++) {
      amplitudes[2] = -amplitudes[2];
      expectVector(amplitudes, afterOracle[round - 1]);
      applyCanonicalCircuitSteps(circuit, oracle);
      circuit.runSimulation();
      expectVector(
          circuit.currentState.stateVector
              .map((a) => a.real.toDouble())
              .toList(),
          amplitudes.map((a) => a * (round == 1 ? 1 : -1)).toList());
      amplitudes = reflect(amplitudes);
      expectVector(amplitudes, afterD[round - 1]);
      applyCanonicalCircuitSteps(circuit, level.canonicalSolution!.steps);
      circuit.runSimulation();
      expectVector(
          circuit.currentState.stateVector
              .map((a) => a.real.toDouble())
              .toList(),
          amplitudes.map((a) => a * (round.isOdd ? -1 : 1)).toList());
      expect(amplitudes[2] * amplitudes[2], round == 1 ? 1 : .25);
    }
  });

  test(
      '66 eight-amplitude recurrence independently verifies fractions and threshold',
      () {
    var amplitudes = List<double>.filled(8, 1 / math.sqrt(8));
    var b = 1.0, c = 1.0;
    const expectedProbabilities = [1 / 8, 25 / 32, 121 / 128, 169 / 512];
    const pairs = [
      [1.0, 1.0],
      [2.5, .5],
      [2.75, -.25],
      [1.625, -.875]
    ];
    final successful = <int>[];
    for (var round = 0; round <= 3; round++) {
      expect(b, closeTo(pairs[round][0], 1e-9));
      expect(c, closeTo(pairs[round][1], 1e-9));
      expectVector(amplitudes,
          [for (var i = 0; i < 8; i++) (i == 6 ? b : c) / math.sqrt(8)]);
      expect(amplitudes[6] * amplitudes[6],
          closeTo(expectedProbabilities[round], 1e-9));
      expect((b * b + 7 * c * c) / 8, closeTo(1, 1e-9));
      if (b * b / 8 > .9) successful.add(round);
      // Full signed-amplitude calculation, separate from the grouped recurrence.
      amplitudes[6] = -amplitudes[6];
      amplitudes = reflect(amplitudes);
      final mean = (7 * c - b) / 8;
      final nextB = 2 * mean + b;
      c = 2 * mean - c;
      b = nextB;
    }
    expect(successful, [2]);
  });

  test('authored questions, answers, distractors and discoveries are distinct',
      () {
    const titles = [
      'Order Is Part of the Algorithm',
      'One More Round Can Be Worse',
      'Choose a Stopping Point'
    ];
    const discoveries = [
      'Search Round Order',
      'Search Stopping Point',
      'Quantitative Search'
    ];
    const questions = [
      'Which order makes |10⟩ certain, and why: A, U → O10 → (-D), or B, U → (-D) → O10?',
      'For four states and one marked state |10⟩, when should you stop among zero, one and two rounds to obtain the greatest success probability?',
      'Among zero, one, two and three rounds, what is the fewest number of rounds that gives greater than 90% success for eight states and one marked state?',
    ];
    const answers = [
      'A: the oracle creates a relative sign, then reflection turns it into interference that cancels the other outcomes.',
      'One round: success reaches certainty, then drops when another round moves amplitudes past that point.',
      'Two rounds: this is the first round count whose marked probability exceeds 90%.',
    ];
    for (var i = 0; i < 3; i++) {
      final id = 64 + i;
      final level = getJourneyLessonById(id)! as ConceptCheckLevel;
      expect(level.title, titles[i]);
      expect(level.taskDescription, questions[i]);
      expect(level.options[level.correctOptionIndex], answers[i]);
      expect(level.options.toSet(), hasLength(4));
      expect(level.hints, hasLength(2));
      expect(level.conceptIntro, isNotEmpty);
      expect(level.mysteryText, isNotEmpty);
      expect(level.solutionExplanation, isNotEmpty);
      expect(CampaignProgressPolicy.discoveryIdForLevel(id), 'discovery_0$id');
      expect(CampaignProgressPolicy.discoveryTitleForId('discovery_0$id'),
          discoveries[i]);
      expect(identical(getHistoricalMasteryById(id), level), isFalse);
    }
    expect(journeyLessons, hasLength(66));
    expect(journeyChapters, hasLength(13));
    expect(journeyChapterForLesson(66)!.to, 65);
    expect(getJourneyLessonById(67), isNull);
    expect(mastery2Catalogue.length, 42);
  });

  for (final count in [60, 63]) {
    test(
        'existing $count completions do not grant later lessons or discoveries',
        () async {
      final storage = InMemoryAppStorage();
      final store = SharedPreferencesCampaignProgressStore(storage: storage);
      if (count == 60) {
        await storage.writeInt('qq_progress_schema_version', 2);
        await storage.writeInt('qq_progress_max_unlocked_level', 115);
        await storage.writeStringList('qq_progress_completed_lesson_ids',
            [for (var i = 1; i <= 60; i++) '$i']);
        await storage.writeStringList(
            'qq_progress_completed_challenge_ids', ['61', '64', '114']);
      } else {
        await store.save(CampaignProgressPolicy.completeLesson(
            CampaignProgressState(
                maxUnlockedLevel: 1, completedChallengeIds: {61, 64, 114}),
            63));
      }
      final state = await store.load();
      expect(state.completedLessonIds, {for (var i = 1; i <= count; i++) i});
      expect(state.maxUnlockedLevel, count + 1);
      expect(state.completedChallengeIds, {61, 64, 114});
      expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(state), {
        for (var i = 1; i <= count; i++)
          'discovery_${i.toString().padLeft(3, '0')}'
      });
      expect(
          CampaignProgressPolicy.continueJourneyDestination(state).levelNumber,
          count + 1);
      final controller = CampaignProgressController(store: store);
      await controller.load();
      for (var id = count + 1; id <= 66; id++) {
        expect(controller.state.completedLessonIds.contains(id), isFalse);
        expect(controller.state.maxUnlockedLevel, id);
        await controller.completeLesson(id);
      }
      final restarted = await store.load();
      expect(restarted.completedLessonIds, {for (var i = 1; i <= 66; i++) i});
      expect(
          CampaignProgressPolicy.continueJourneyDestination(restarted)
              .isJourneyComplete,
          isTrue);
      expect(restarted.completedChallengeIds, {61, 64, 114});
    });
  }
}
