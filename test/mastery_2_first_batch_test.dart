import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  MasteryChallengeDefinition challenge(String semanticId) =>
      mastery2Catalogue.requireBySemanticId(semanticId);

  List<double> probabilities(QuantumCircuit circuit) => [
        for (final amplitude in circuit.currentState.stateVector)
          (amplitude.real * amplitude.real +
                  amplitude.imaginary * amplitude.imaginary)
              .toDouble(),
      ];

  QuantumCircuit preparedState(String basis, List<SelectedGateType> gates) {
    final level = ComposerLevel.fromBinaryString(
      taskDescription: 'test fixture',
      initialQubitsStateString: basis,
      availableGates: [
        for (final gate in gates) Gate.fromIdentifier(gate),
      ],
      solutionFinalVector: const [],
    );
    final circuit = QuantumCircuit(currentLevel: level);
    for (final gate in gates) {
      circuit.insertSingleGateWithOutcome(
        Gate.fromIdentifier(gate),
        circuit.maxCircuitDepth(),
        0,
      );
    }
    circuit.runSimulation();
    return circuit;
  }

  group('production semantic catalogue', () {
    test('retains the first batch at the start of editorial order', () {
      expect(
          mastery2Catalogue.orderedDefinitions
              .take(8)
              .map((item) => item.semanticId),
          const [
            'global_phase_equivalence',
            'phase_state_uncomputation',
            'same_histogram_different_state',
            'cnot_topology_inference',
            'bell_decoder_bug',
            'phase_kickback_conditions',
            'oracle_marked_state_inference',
            'algorithm_architecture_inspector',
          ]);
      expect(
        mastery2Catalogue.orderedDefinitions.map((item) => item.displayOrder),
        List.generate(36, (index) => index + 1),
      );
    });

    test('semantic completion ignores legacy integer completion and Journey',
        () {
      final initial = CampaignProgressState(
        maxUnlockedLevel: 8,
        completedLessonIds: const {1, 2, 3, 4, 5, 6, 7},
        completedChallengeIds: const {61, 62, 63},
      );
      final completed = CampaignProgressPolicy.completeMasteryChallenge(
        initial,
        'global_phase_equivalence',
      );

      expect(
          completed.completedMasterySemanticIds, {'global_phase_equivalence'});
      expect(completed.completedLessonIds, initial.completedLessonIds);
      expect(completed.maxUnlockedLevel, initial.maxUnlockedLevel);
      expect(
        mastery2Catalogue.orderedDefinitions.where(
          (item) => CampaignProgressPolicy.isMasteryChallengeCompleted(
            initial,
            item.semanticId,
          ),
        ),
        isEmpty,
      );
    });
  });

  group('global phase equivalence', () {
    test('states physical equivalence without claiming vector equality', () {
      final definition = challenge('global_phase_equivalence');
      final level = definition.levelDefinition as McqLevel;

      expect(definition.difficulty, MasteryDifficulty.foundation);
      expect(level.correctOptionIndex, 1);
      expect(level.options[level.correctOptionIndex],
          contains('different statevector representatives'));
      expect(level.options[level.correctOptionIndex],
          contains('same physical pure state'));
      expect(level.solutionExplanation, contains('real mathematical'));
      expect(level.solutionExplanation, isNot(contains('equal vectors')));
    });

    test('global factors leave all basis probabilities unchanged', () {
      final representatives = [
        [Complex.zero(), Complex.one()],
        [Complex.zero(), Complex(-1)],
        [Complex.zero(), Complex(0, 1)],
      ];
      for (final vector in representatives) {
        expect(vector[0].abs() * vector[0].abs(), closeTo(0, 1e-12));
        expect(vector[1].abs() * vector[1].abs(), closeTo(1, 1e-12));
      }
      expect(representatives[0], isNot(representatives[1]));
    });
  });

  group('phase-state uncomputation', () {
    test('fixed prefix is immutable and prepares |-i>', () {
      final level = challenge('phase_state_uncomputation').levelDefinition
          as ComposerLevel;
      final circuit = QuantumCircuit(currentLevel: level);

      expect(circuit.logicalGates, hasLength(3));
      expect(circuit.logicalGates.every((gate) => !gate.isDeletable), isTrue);
      expect(circuit.logicalGates.map((gate) => gate.type), const [
        SelectedGateType.hadamard,
        SelectedGateType.s,
        SelectedGateType.z,
      ]);
      final vector = circuit.currentState.stateVector;
      expect(vector[0].real, closeTo(1 / sqrt(2), 1e-10));
      expect(vector[0].imaginary, closeTo(0, 1e-10));
      expect(vector[1].real, closeTo(0, 1e-10));
      expect(vector[1].imaginary, closeTo(-1 / sqrt(2), 1e-10));
    });

    test('S then H succeeds up to global phase', () {
      final level = challenge('phase_state_uncomputation').levelDefinition
          as ComposerLevel;
      final solution = buildCanonicalSolutionCircuit(level);

      expect(level.validationMode, ValidationMode.physicalState);
      expect(level.validateCircuit(solution), isTrue);
      expect(solution.logicalGates.skip(3).map((gate) => gate.type), const [
        SelectedGateType.s,
        SelectedGateType.hadamard,
      ]);
    });

    test('palette removes bit/phase shortcuts and no one-gate route succeeds',
        () {
      final level = challenge('phase_state_uncomputation').levelDefinition
          as ComposerLevel;
      expect(level.availableGates.map((gate) => gate.type).toSet(), {
        SelectedGateType.hadamard,
        SelectedGateType.s,
      });
      for (final gate in level.availableGates) {
        final circuit = QuantumCircuit(currentLevel: level);
        circuit.insertSingleGateWithOutcome(
          Gate.fromIdentifier(gate.type),
          circuit.maxCircuitDepth(),
          0,
        );
        circuit.runSimulation();
        expect(level.validateCircuit(circuit), isFalse, reason: gate.type.name);
      }
    });
  });

  group('same histogram, different state', () {
    test('Z evidence is 50/50 for plus, minus, and the labelled mixture', () {
      final plusZ =
          probabilities(preparedState('0', [SelectedGateType.hadamard]));
      final minusZ =
          probabilities(preparedState('1', [SelectedGateType.hadamard]));
      const mixtureZ = [0.5, 0.5];

      expect(plusZ, everyElement(closeTo(0.5, 1e-10)));
      expect(minusZ, everyElement(closeTo(0.5, 1e-10)));
      expect(mixtureZ, everyElement(closeTo(0.5, 1e-10)));
    });

    test('X evidence separates plus/minus while the mixture stays 50/50', () {
      final plusX = probabilities(preparedState('0', [
        SelectedGateType.hadamard,
        SelectedGateType.hadamard,
      ]));
      final minusX = probabilities(preparedState('1', [
        SelectedGateType.hadamard,
        SelectedGateType.hadamard,
      ]));
      final mixtureX = [
        (1.0 + 0.0) / 2,
        (0.0 + 1.0) / 2,
      ];

      expect(plusX[0], closeTo(1, 1e-10));
      expect(plusX[1], closeTo(0, 1e-10));
      expect(minusX[0], closeTo(0, 1e-10));
      expect(minusX[1], closeTo(1, 1e-10));
      expect(mixtureX, everyElement(closeTo(0.5, 1e-10)));
    });

    test('content labels an ensemble and never supplies it as a statevector',
        () {
      final level = challenge('same_histogram_different_state').levelDefinition
          as ConceptCheckLevel;
      final content = [
        level.taskDescription,
        ...level.options,
        level.solutionExplanation!,
      ].join(' ');

      expect(content, contains('half the preparations are |0⟩'));
      expect(content, contains('classical random preparation'));
      expect(level, isNot(isA<ComposerLevel>()));
      expect(
        level.options[level.correctOptionIndex],
        isNot(contains('pure state')),
      );
    });
  });
}
