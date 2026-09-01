import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';

void main() {
  QQLevel mastery(int challenge) => getQQLevelById(60 + challenge)!;

  QuantumCircuit simulate(ComposerLevel level) {
    final circuit = QuantumCircuit(currentLevel: level);
    circuit.runSimulation();
    return circuit;
  }

  group('Q2.2 early Mastery canonical structure', () {
    test('M1-M13 retain IDs, order, and approved activity variety', () {
      final expectedTypes = <Type>[
        CircuitReadingLevel,
        McqLevel,
        CircuitReadingLevel,
        FillTheGateLevel,
        ComposerLevel,
        CircuitReadingLevel,
        ComposerLevel,
        FillTheGateLevel,
        MeasurementLabLevel,
        ComposerLevel,
        CircuitReadingLevel,
        ComposerLevel,
        ComposerLevel,
      ];

      for (var challenge = 1; challenge <= 13; challenge++) {
        final level = mastery(challenge);
        expect(level.runtimeType, expectedTypes[challenge - 1],
            reason:
                'Unexpected activity type for M$challenge / ID ${60 + challenge}');
        expect(allQQLevels[59 + challenge], same(level));
      }
      expect(getQQLevelById(74)!.title, 'CNOT Gate',
          reason: 'M14 is outside Q2.2');
    });

    test('solution-oriented titles no longer leak early gate answers', () {
      final titles = [1, 2, 3, 4, 6, 7, 8, 9, 10, 11]
          .map((challenge) => mastery(challenge).title!)
          .join('\n');
      expect(titles, isNot(contains('T Gate')));
      expect(titles, isNot(contains('S Gate')));
      expect(titles, isNot(contains('Apply Z')));
      expect(titles, isNot(contains('Use H')));
    });

    test('mobile router supports every activity used by M1-M13', () {
      expect(LevelUIRouter.routeKindFor(mastery(1)),
          LevelUIRouteKind.circuitReading);
      expect(LevelUIRouter.routeKindFor(mastery(2)),
          LevelUIRouteKind.conceptCheck);
      expect(LevelUIRouter.routeKindFor(mastery(4)), LevelUIRouteKind.fillGate);
      expect(LevelUIRouter.routeKindFor(mastery(5)), LevelUIRouteKind.composer);
      expect(LevelUIRouter.routeKindFor(mastery(9)),
          LevelUIRouteKind.measurementLab);
    });
  });

  group('prediction and phase semantics', () {
    test('M1, M3, M6, and M11 have plausible equatorial/basis options', () {
      final expectedCorrectIndices = {1: 0, 3: 1, 6: 1, 11: 3};
      for (final entry in expectedCorrectIndices.entries) {
        final level = mastery(entry.key) as CircuitReadingLevel;
        expect(level.options, hasLength(4));
        expect(level.options.toSet(), hasLength(4));
        expect(level.correctOptionIndex, entry.value);
      }
    });

    test('M2 preserves operator action while identifying global equivalence',
        () {
      final level = mastery(2) as McqLevel;
      expect(
          level.options[level.correctOptionIndex], contains('same physical'));
      expect(level.options[level.correctOptionIndex],
          contains('operator actions'));
      expect(level.solutionExplanation, contains('global phase'));
      expect(
          level.solutionExplanation, isNot(contains('later gates can reveal')));
    });

    test('M3 separates its global factor from its relative sign', () {
      final level = mastery(3) as CircuitReadingLevel;
      expect(level.solutionExplanation, contains('factor −i is global'));
      expect(level.solutionExplanation, contains('minus sign between'));

      final circuit = simulate(level.toComposerLevel());
      final expectedVector = QuantumMatrix([
        [Complex(0, -0.7071067811865476)],
        [Complex(0, 0.7071067811865476)],
      ]);
      expect(circuit.currentState.state.almostEqualTo(expectedVector), isTrue);
    });

    test('M4 and M8 use S among four plausible phase choices', () {
      for (final challenge in [4, 8]) {
        final level = mastery(challenge) as FillTheGateLevel;
        expect(level.correctGate.type, SelectedGateType.s);
        expect(level.options, hasLength(4));
        expect(level.options.map((gate) => gate.type).toSet(), hasLength(4));

        final circuit = simulate(level.toComposerLevelWith(level.correctGate));
        expect(
          circuit.currentState.state
              .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
          isTrue,
        );
        for (final wrong in level.options
            .where((gate) => gate.type != level.correctGate.type)) {
          final wrongCircuit = simulate(level.toComposerLevelWith(wrong));
          expect(
            wrongCircuit.currentState.state
                .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
            isFalse,
            reason: '${wrong.type} must not solve M$challenge',
          );
        }
      }
      expect(mastery(4).taskDescription, contains('|+i'));
      expect(mastery(8).taskDescription, contains('|-i'));
    });

    test('M9 honestly uses sample-count completion for a basis limitation', () {
      final level = mastery(9) as MeasurementLabLevel;
      expect(level.requiredMeasurements, 20);
      expect(level.taskDescription, isNot(contains('same histogram as')));
      expect(level.solutionExplanation, contains('same histogram as |+⟩'));
      expect(level.solutionExplanation, contains('basis cannot distinguish'));

      final circuit = simulate(level.toComposerLevel());
      final expectedVector = QuantumMatrix([
        [Complex(0.7071067811865476)],
        [Complex(-0.7071067811865476)],
      ]);
      expect(circuit.currentState.state.almostEqualTo(expectedVector), isTrue);
    });
  });

  group('quality anchors and canonical validation', () {
    test('M5, M12, and M13 canonical solutions still self-verify', () {
      for (final challenge in [5, 12, 13]) {
        final level = mastery(challenge) as ComposerLevel;
        expect(level.canonicalSolution, isNotNull);
        final circuit = buildCanonicalSolutionCircuit(level);
        expect(level.validateCircuit(circuit), isTrue,
            reason: 'Canonical solution failed for M$challenge');
      }
    });

    test('M5 retains Q1 unitary/global-equivalence semantics', () {
      final level = mastery(5) as ComposerLevel;
      expect(level.validationMode, ValidationMode.unitary);
      expect(level.targetStateExpression, contains('XZX = -Z ~ Z'));
      expect(level.solutionExplanation, contains('global phase'));
    });

    test('M10 remains an independently prepared product-state Composer task',
        () {
      final level = mastery(10) as ComposerLevel;
      expect(level.title, 'Independent, Not Entangled');
      expect(level.taskDescription, contains('independent single-qubit'));
      expect(level.hints!.first, contains('Factor the target'));
      expect(level.hints!.first, isNot(contains('Apply H')));
      expect(level.hints!.last, contains('H on Q1'));
      expect(level.hints!.last, contains('X on Q0'));
      expect(level.canonicalSolution, isNotNull);
      expect(
          level.validateCircuit(buildCanonicalSolutionCircuit(level)), isTrue);
    });
  });
}
