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
  QuantumCircuit runCircuit(
    String initialBasis,
    List<CanonicalCircuitStep> steps,
  ) {
    final fixture = ComposerLevel.fromBinaryString(
      taskDescription: 'Mastery 2 third-batch verification fixture',
      initialQubitsStateString: initialBasis,
      availableGates: [
        for (final type in steps.map((step) => step.gateType).toSet())
          Gate.fromIdentifier(type),
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

  void expectVector(
    List<Complex> actual,
    List<Complex> expected, {
    double epsilon = 1e-10,
  }) {
    expect(actual, hasLength(expected.length));
    for (var index = 0; index < actual.length; index++) {
      expect(actual[index].real, closeTo(expected[index].real, epsilon));
      expect(
        actual[index].imaginary,
        closeTo(expected[index].imaginary, epsilon),
      );
    }
  }

  bool vectorsEquivalentUpToGlobalPhase(
    List<Complex> left,
    List<Complex> right, {
    double epsilon = 1e-9,
  }) {
    Complex? factor;
    for (var index = 0; index < left.length; index++) {
      if (right[index].abs() > epsilon) {
        factor = left[index] / right[index];
        break;
      }
      if (left[index].abs() > epsilon) return false;
    }
    if (factor == null) return true;
    for (var index = 0; index < left.length; index++) {
      final expected = right[index] * factor;
      if ((left[index] - expected).abs() > epsilon) return false;
    }
    return true;
  }

  CanonicalCircuitStep single(SelectedGateType type, [int target = 0]) =>
      CanonicalCircuitStep.single(type, targetQubit: target);

  CanonicalCircuitStep cnot(int control, int target) =>
      CanonicalCircuitStep.controlled(
        SelectedGateType.cnot,
        controlQubit: control,
        targetQubit: target,
      );

  int basisOutput(QuantumCircuit circuit) {
    final probabilities = [
      for (final amplitude in state(circuit))
        amplitude.real * amplitude.real +
            amplitude.imaginary * amplitude.imaginary,
    ];
    final maximum = probabilities.reduce(math.max);
    expect(maximum, closeTo(1, 1e-9));
    return probabilities.indexOf(maximum);
  }

  group('phase accumulation prediction', () {
    test('H then T then S accumulates exactly +3pi/4 relative phase', () {
      final output = state(runCircuit('0', [
        single(SelectedGateType.hadamard),
        single(SelectedGateType.t),
        single(SelectedGateType.s),
      ]));
      expectVector(output, [
        Complex(math.sqrt1_2),
        Complex(-0.5, 0.5),
      ]);

      final candidates = [
        [Complex(math.sqrt1_2), Complex(-0.5, 0.5)],
        [Complex(math.sqrt1_2), Complex(0.5, 0.5)],
        [Complex(math.sqrt1_2), Complex(0, math.sqrt1_2)],
        [Complex(math.sqrt1_2), Complex(-0.5, -0.5)],
      ];
      expect(
        candidates
            .map((candidate) =>
                vectorsEquivalentUpToGlobalPhase(output, candidate))
            .toList(),
        [true, false, false, false],
      );
      final level = mastery2Catalogue
          .requireBySemanticId('phase_accumulation_prediction')
          .levelDefinition as McqLevel;
      expect(level.correctOptionIndex, 0);
      expect(level.solutionExplanation, contains('relative phase'));
    });
  });

  group('complex Y phase trace', () {
    test('Y on |+> is raw -i|-> and physically |->', () {
      final output = state(runCircuit('0', [
        single(SelectedGateType.hadamard),
        single(SelectedGateType.y),
      ]));
      expectVector(output, [
        Complex(0, -math.sqrt1_2),
        Complex(0, math.sqrt1_2),
      ]);
      final minus = [Complex(math.sqrt1_2), Complex(-math.sqrt1_2)];
      final plus = [Complex(math.sqrt1_2), Complex(math.sqrt1_2)];
      expect(vectorsEquivalentUpToGlobalPhase(output, minus), isTrue);
      expect(vectorsEquivalentUpToGlobalPhase(output, plus), isFalse);
      final level = mastery2Catalogue
          .requireBySemanticId('complex_y_phase_trace')
          .levelDefinition as McqLevel;
      expect(level.correctOptionIndex, 2);
      expect(level.solutionExplanation, contains('−i|−⟩'));
    });
  });

  group('interferometer repair', () {
    test('only H reveals the marked phase as deterministic |1>', () {
      final prefix = [
        single(SelectedGateType.hadamard),
        single(SelectedGateType.z),
      ];
      final beforeRepair = state(runCircuit('0', prefix));
      expectVector(beforeRepair, [
        Complex(math.sqrt1_2),
        Complex(-math.sqrt1_2),
      ]);

      final candidates = [
        SelectedGateType.hadamard,
        SelectedGateType.z,
        SelectedGateType.s,
        SelectedGateType.x,
      ];
      final deterministicOne = <bool>[];
      for (final candidate in candidates) {
        final output = runCircuit('0', [...prefix, single(candidate)]);
        final probabilities = [
          for (final amplitude in state(output))
            amplitude.abs() * amplitude.abs(),
        ];
        deterministicOne.add(
          probabilities[0] < 1e-9 && (probabilities[1] - 1).abs() < 1e-9,
        );
      }
      expect(deterministicOne, [true, false, false, false]);
    });
  });

  group('phase sandwich unitary', () {
    test('XZX is exactly -Z, not Z, and is globally equivalent', () {
      final xzx = runCircuit('0', [
        single(SelectedGateType.x),
        single(SelectedGateType.z),
        single(SelectedGateType.x),
      ]).getOverallCircuitMatrix().toComplexList();
      final z = runCircuit('0', [
        single(SelectedGateType.z),
      ]).getOverallCircuitMatrix().toComplexList();

      expectVector(xzx.expand((row) => row).toList(), [
        Complex(-1),
        Complex.zero(),
        Complex.zero(),
        Complex.one(),
      ]);
      expect(xzx, isNot(equals(z)));
      expect(
        vectorsEquivalentUpToGlobalPhase(
          xzx.expand((row) => row).toList(),
          z.expand((row) => row).toList(),
        ),
        isTrue,
      );
      final explanation = (mastery2Catalogue
              .requireBySemanticId('phase_sandwich_unitary')
              .levelDefinition as McqLevel)
          .solutionExplanation!;
      expect(explanation, contains('not literal matrix equality'));
      expect(explanation, contains('global factor'));
    });
  });

  group('CNOT uncomputation', () {
    test('keeps validation prose out of the target-state expression', () {
      final level = mastery2Catalogue
          .requireBySemanticId('cnot_uncomputation')
          .levelDefinition as ComposerLevel;

      expect(level.targetStateExpression, '|11⟩');
      expect(level.targetStateExpression, isNot(contains('identity overall')));
      expect(level.validationMode, ValidationMode.unitary);
      expect(level.targetUnitary, isNotNull);
    });

    test('fixed topology changes |11> and identical inverse restores it', () {
      final definition = mastery2Catalogue.requireBySemanticId(
        'cnot_uncomputation',
      );
      final level = definition.levelDefinition as ComposerLevel;
      final fixed = QuantumCircuit(currentLevel: level)..runSimulation();
      expect(basisOutput(fixed), 1, reason: '|01> is statevector index 1');
      expect(fixed.logicalGates.single.isDeletable, isFalse);

      final solved = buildCanonicalSolutionCircuit(level);
      expect(basisOutput(solved), 3);
      expect(level.validateCircuit(solved), isTrue);
      expect(level.canonicalSolution!.steps.single.controlQubit, 0);
      expect(level.canonicalSolution!.steps.single.targetQubit, 1);
    });

    test('reversed topology and phase shortcut fail the unitary constraint',
        () {
      final level = mastery2Catalogue
          .requireBySemanticId('cnot_uncomputation')
          .levelDefinition as ComposerLevel;
      final reversed = QuantumCircuit(currentLevel: level);
      applyCanonicalCircuitSteps(reversed, [cnot(1, 0)]);
      reversed.runSimulation();
      expect(level.validateCircuit(reversed), isFalse);

      final phaseShortcut = QuantumCircuit(currentLevel: level);
      applyCanonicalCircuitSteps(phaseShortcut, [single(SelectedGateType.z)]);
      phaseShortcut.runSimulation();
      expect(level.validateCircuit(phaseShortcut), isFalse);
    });
  });

  group('fan-out is not cloning', () {
    test('basis propagation and superposed fan-out match authored evidence',
        () {
      final fanout = [cnot(0, 1), cnot(0, 2)];
      expect(basisOutput(runCircuit('001', fanout)), 7);

      final entangled = state(runCircuit('000', [
        single(SelectedGateType.hadamard),
        ...fanout,
      ]));
      expectVector(entangled, [
        Complex(math.sqrt1_2),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex(math.sqrt1_2),
      ]);
      final level = mastery2Catalogue
          .requireBySemanticId('fanout_is_not_cloning')
          .levelDefinition as McqLevel;
      final authoredText = [level.taskDescription, level.solutionExplanation!]
          .join(' ')
          .toLowerCase();
      expect(authoredText, isNot(contains('copies a qubit')));
      expect(authoredText, contains('not independent copies'));
    });
  });

  group('SWAP unitary diagnosis', () {
    final genuine = [cnot(0, 1), cnot(1, 0), cnot(0, 1)];
    final shortcut = [cnot(0, 1), cnot(1, 0)];

    test(
        'both candidates fit |01> but only three-CNOT circuit swaps all basis inputs',
        () {
      expect(basisOutput(runCircuit('01', genuine)), 2);
      expect(basisOutput(runCircuit('01', shortcut)), 2);

      final genuineOutputs = <int>[];
      final shortcutOutputs = <int>[];
      for (final input in ['00', '01', '10', '11']) {
        genuineOutputs.add(basisOutput(runCircuit(input, genuine)));
        shortcutOutputs.add(basisOutput(runCircuit(input, shortcut)));
      }
      expect(genuineOutputs, [0, 2, 1, 3]);
      expect(shortcutOutputs, [0, 2, 3, 1]);
    });

    test('three-CNOT matrix is the full SWAP unitary', () {
      final matrix = runCircuit('00', genuine)
          .getOverallCircuitMatrix()
          .toComplexList()
          .expand((row) => row)
          .toList();
      expectVector(matrix, [
        Complex.one(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.one(),
        Complex.zero(),
        Complex.zero(),
        Complex.one(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.one(),
      ]);
      final explanation = (mastery2Catalogue
              .requireBySemanticId('swap_unitary_diagnosis')
              .levelDefinition as McqLevel)
          .solutionExplanation!;
      expect(explanation, contains('state-specific shortcut—not SWAP'));
    });
  });

  test(
      'catalogue contains fifteen unique semantic challenges and preserves progress',
      () {
    final ordered = mastery2Catalogue.orderedDefinitions;
    expect(ordered, hasLength(36));
    expect(ordered.map((item) => item.displayOrder),
        List.generate(36, (i) => i + 1));
    expect(ordered.map((item) => item.semanticId).toSet(), hasLength(36));
    expect(
      ordered.where((item) => item.semanticId == 'phase_state_uncomputation'),
      hasLength(1),
    );

    final existingCompletion = mastery2Catalogue.orderedDefinitions
        .take(8)
        .map((item) => item.semanticId)
        .toSet();
    final before = CampaignProgressState(
      maxUnlockedLevel: 8,
      completedLessonIds: const {1, 2, 3, 4, 5, 6, 7},
      completedMasterySemanticIds: existingCompletion,
    );
    final after = CampaignProgressPolicy.completeMasteryChallenge(
      before,
      'swap_unitary_diagnosis',
    );
    expect(after.completedMasterySemanticIds, containsAll(existingCompletion));
    expect(
        after.completedMasterySemanticIds, contains('swap_unitary_diagnosis'));
    expect(after.completedLessonIds, before.completedLessonIds);
    expect(after.maxUnlockedLevel, before.maxUnlockedLevel);
  });
}
