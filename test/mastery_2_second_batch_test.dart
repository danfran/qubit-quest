import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  McqLevel level(String id) =>
      mastery2Catalogue.requireBySemanticId(id).levelDefinition as McqLevel;

  QuantumCircuit runCircuit(
    String initialBasis,
    List<CanonicalCircuitStep> steps,
  ) {
    final types = steps.map((step) => step.gateType).toSet();
    final fixture = ComposerLevel.fromBinaryString(
      taskDescription: 'mathematical verification fixture',
      initialQubitsStateString: initialBasis,
      availableGates: [
        for (final type in types) Gate.fromIdentifier(type),
      ],
      solutionFinalVector: const [],
    );
    final circuit = QuantumCircuit(currentLevel: fixture);
    applyCanonicalCircuitSteps(circuit, steps);
    circuit.runSimulation();
    return circuit;
  }

  List<Complex> state(QuantumCircuit circuit) =>
      circuit.currentState.stateVector;

  void expectState(
    QuantumCircuit circuit,
    List<Complex> expected, {
    double tolerance = 1e-10,
  }) {
    expect(state(circuit), hasLength(expected.length));
    for (var index = 0; index < expected.length; index++) {
      expect(
          state(circuit)[index].real, closeTo(expected[index].real, tolerance),
          reason: 'real amplitude $index');
      expect(state(circuit)[index].imaginary,
          closeTo(expected[index].imaginary, tolerance),
          reason: 'imaginary amplitude $index');
    }
  }

  int basisOutput(QuantumCircuit circuit) {
    final probabilities = [
      for (final amplitude in state(circuit))
        (amplitude.real * amplitude.real +
                amplitude.imaginary * amplitude.imaginary)
            .toDouble(),
    ];
    final maximum = probabilities.reduce(math.max);
    expect(maximum, closeTo(1, 1e-10));
    return probabilities.indexOf(maximum);
  }

  CanonicalCircuitStep cnot(int control, int target) =>
      CanonicalCircuitStep.controlled(
        SelectedGateType.cnot,
        controlQubit: control,
        targetQubit: target,
      );

  const h0 = CanonicalCircuitStep.single(
    SelectedGateType.hadamard,
    targetQubit: 0,
  );
  const h1 = CanonicalCircuitStep.single(
    SelectedGateType.hadamard,
    targetQubit: 1,
  );
  const x0 = CanonicalCircuitStep.single(
    SelectedGateType.x,
    targetQubit: 0,
  );
  const x1 = CanonicalCircuitStep.single(
    SelectedGateType.x,
    targetQubit: 1,
  );
  const cz = CanonicalCircuitStep.controlled(
    SelectedGateType.cz,
    controlQubit: 0,
    targetQubit: 1,
  );

  group('CNOT topology evidence', () {
    test('all directed topologies are checked against both cases', () {
      final candidates = <(int, int)>[
        (2, 0),
        (0, 2),
        (1, 0),
        (2, 1),
        (0, 1),
        (1, 2),
      ];
      final matches = <(int, int)>[];
      for (final candidate in candidates) {
        final first = runCircuit('010', [cnot(candidate.$1, candidate.$2)]);
        final second = runCircuit('100', [cnot(candidate.$1, candidate.$2)]);
        if (basisOutput(first) == 2 && basisOutput(second) == 5) {
          matches.add(candidate);
        }
      }

      expect(matches, [(2, 0)]);
      expect(level('cnot_topology_inference').taskDescription,
          contains('q0, q1, q2 from top to bottom'));
      expect(level('cnot_topology_inference').taskDescription,
          contains('|q2 q1 q0⟩'));
    });

    test('first case is ambiguous and second makes the answer unique', () {
      final options = <(int, int)>[(2, 0), (0, 2), (1, 0), (2, 1)];
      final firstMatches = [
        for (final topology in options)
          if (basisOutput(
                  runCircuit('010', [cnot(topology.$1, topology.$2)])) ==
              2)
            topology,
      ];
      final bothMatches = [
        for (final topology in firstMatches)
          if (basisOutput(
                  runCircuit('100', [cnot(topology.$1, topology.$2)])) ==
              5)
            topology,
      ];

      expect(firstMatches.length, greaterThan(1));
      expect(bothMatches, [(2, 0)]);
      expect(level('cnot_topology_inference').correctOptionIndex, 0);
    });
  });

  group('Bell decoder diagnosis', () {
    final preparation = <CanonicalCircuitStep>[h0, cnot(0, 1)];

    test('correct inverse order decodes Phi+ to |00>', () {
      final decoded = runCircuit('00', [
        ...preparation,
        cnot(0, 1),
        h0,
      ]);
      expect(basisOutput(decoded), 0);
    });

    test('every offered buggy repair is distinguished by the input', () {
      final candidates = [
        [...preparation, cnot(1, 0), h0],
        [...preparation, h0, cnot(1, 0)],
        [...preparation, cnot(0, 1), h0],
        [...preparation, cnot(0, 1)],
      ];
      final reaches00 = [
        for (final steps in candidates)
          state(runCircuit('00', steps)).asMap().entries.every(
                (entry) => entry.key == 0
                    ? (entry.value.real - 1).abs() < 1e-10 &&
                        entry.value.imaginary.abs() < 1e-10
                    : entry.value.abs() < 1e-10,
              ),
      ];

      expect(reaches00, [false, false, true, false]);
      expect(level('bell_decoder_bug').correctOptionIndex, 2);
    });
  });

  group('phase kickback conditions', () {
    final half = 0.5;

    test('|+>|-> creates branch-relative phase on the control', () {
      final output = runCircuit('00', [h0, x1, h1, cnot(0, 1)]);
      expectState(output, [
        Complex(half),
        Complex(-half),
        Complex(-half),
        Complex(half),
      ]);
    });

    test('|+>|+> receives no relative sign', () {
      final output = runCircuit('00', [h0, h1, cnot(0, 1)]);
      expectState(output, List.filled(4, Complex(half)));
    });

    test('|1>|-> changes only by a whole-state global phase', () {
      final before = runCircuit('00', [x0, x1, h1]);
      final after = runCircuit('00', [x0, x1, h1, cnot(0, 1)]);
      for (var index = 0; index < 4; index++) {
        expect(state(after)[index].real,
            closeTo(-state(before)[index].real, 1e-10));
        expect(state(after)[index].imaginary,
            closeTo(-state(before)[index].imaginary, 1e-10));
      }
      final explanation =
          level('phase_kickback_conditions').solutionExplanation!;
      expect(explanation, contains('global phase'));
      expect(explanation, contains('branch-relative phase'));
    });
  });

  group('phase-oracle inference', () {
    test('uniform start and q0 wrapper mark exactly |10>', () {
      final uniform = runCircuit('00', [h0, h1]);
      expectState(uniform, List.filled(4, Complex(0.5)));

      final marked = runCircuit('00', [h0, h1, x0, cz, x0]);
      expectState(marked, [
        Complex(0.5),
        Complex(0.5),
        Complex(-0.5),
        Complex(0.5),
      ]);
    });

    test('each wrapper maps to its labelled basis state under Q0-LSB', () {
      final candidates = <String, List<CanonicalCircuitStep>>{
        '11': [h0, h1, cz],
        '10': [h0, h1, x0, cz, x0],
        '01': [h0, h1, x1, cz, x1],
        '00': [h0, h1, x0, x1, cz, x1, x0],
      };
      final negativeIndex = <String, int>{};
      for (final entry in candidates.entries) {
        final vector = state(runCircuit('00', entry.value));
        final negatives = [
          for (final indexed in vector.indexed)
            if (indexed.$2.real < 0) indexed.$1,
        ];
        expect(negatives, hasLength(1), reason: entry.key);
        negativeIndex[entry.key] = negatives.single;
      }

      expect(negativeIndex, {'11': 3, '10': 2, '01': 1, '00': 0});
      expect(level('oracle_marked_state_inference').taskDescription,
          contains('q0 above q1'));
      expect(level('oracle_marked_state_inference').taskDescription,
          contains('|q1 q0⟩'));
    });
  });

  group('algorithm architecture evidence', () {
    test('authored probability snapshots are mathematically consistent', () {
      const uniformAmplitude = 0.25;
      final phaseMarkedProbabilities = List.filled(
        16,
        uniformAmplitude * uniformAmplitude,
      );
      expect(
          phaseMarkedProbabilities.reduce((a, b) => a + b), closeTo(1, 1e-12));

      const markedAfterOneRound = 11 / 16;
      const unmarkedAfterOneRound = 3 / 16;
      final total = markedAfterOneRound * markedAfterOneRound +
          15 * unmarkedAfterOneRound * unmarkedAfterOneRound;
      expect(total, closeTo(1, 1e-12));
      expect(
          markedAfterOneRound * markedAfterOneRound, closeTo(121 / 256, 1e-12));
    });

    test('each symptom has one coherent diagnosis without universal claims',
        () {
      final candidate = level('algorithm_architecture_inspector');
      expect(candidate.correctOptionIndex, 1);
      expect(
          candidate.options[1], contains('amplification before measurement'));
      expect(candidate.options[1], contains('marked the wrong state'));
      expect(candidate.options[1], contains('another coherent search round'));
      final authoredText = [
        candidate.taskDescription,
        candidate.solutionExplanation!,
      ].join(' ');
      expect(authoredText, contains('search model used here'));
      expect(authoredText, isNot(contains('every quantum algorithm')));
      expect(authoredText, isNot(contains('all quantum algorithms')));
    });
  });

  test('catalogue retains the first eight and preserves progress', () {
    final ordered = mastery2Catalogue.orderedDefinitions;
    expect(ordered, hasLength(36));
    expect(
      ordered.take(8).map((item) => item.displayOrder),
      [1, 2, 3, 4, 5, 6, 7, 8],
    );

    final before = CampaignProgressState(
      maxUnlockedLevel: 5,
      completedLessonIds: const {1, 2, 3, 4},
      completedMasterySemanticIds: const {
        'global_phase_equivalence',
        'phase_state_uncomputation',
        'same_histogram_different_state',
      },
    );
    final after = CampaignProgressPolicy.completeMasteryChallenge(
      before,
      'oracle_marked_state_inference',
    );

    expect(
        after.completedMasterySemanticIds,
        containsAll([
          'global_phase_equivalence',
          'phase_state_uncomputation',
          'same_histogram_different_state',
          'oracle_marked_state_inference',
        ]));
    expect(after.completedLessonIds, before.completedLessonIds);
    expect(after.maxUnlockedLevel, before.maxUnlockedLevel);
  });
}
