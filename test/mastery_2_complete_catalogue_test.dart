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

const approvedActiveIds = <String>[
  'reversible_cancellation_trace',
  'global_phase_equivalence',
  'hadamard_input_sign',
  'same_histogram_different_state',
  'cnot_topology_inference',
  'product_or_entangled',
  'bell_measurement_evidence',
  'quarter_turn_relative_phase',
  'phase_accumulation_prediction',
  'complex_y_phase_trace',
  'interferometer_repair',
  'phase_sandwich_unitary',
  'phase_state_uncomputation',
  'cnot_uncomputation',
  'fanout_is_not_cloning',
  'swap_unitary_diagnosis',
  'bell_input_sign_preparation',
  'bell_decoder_bug',
  'bell_phase_equivalence',
  'ghz_outcome_constraint',
  'ghz_broken_link',
  'ghz_phase_manipulation',
  'phase_kickback_conditions',
  'phase_kickback_reveal',
  'inverse_phase_synthesis',
  'phased_entanglement_uncomputation',
  'conditional_phase_decomposition',
  'oracle_marked_state_inference',
  'oracle_repair_uncompute',
  'marked_is_not_amplified',
  'amplitude_flow_inference',
  'grover_round_order',
  'retry_or_reshape',
  'clean_workspace_uncomputation',
  'algorithm_architecture_inspector',
  'search_pipeline_forensics',
  'finite_shot_evidence',
  'four_bell_decoder',
  'odd_parity_oracle',
  'half_marked_search',
  'search_overshoot_forensics',
  'nonuniform_reference_reflection',
];

void main() {
  CanonicalCircuitStep single(SelectedGateType type, [int target = 0]) =>
      CanonicalCircuitStep.single(type, targetQubit: target);

  CanonicalCircuitStep cnot(int control, int target) =>
      CanonicalCircuitStep.controlled(
        SelectedGateType.cnot,
        controlQubit: control,
        targetQubit: target,
      );

  QuantumCircuit runCircuit(
    String initialBasis,
    List<CanonicalCircuitStep> steps,
  ) {
    final fixture = ComposerLevel.fromBinaryString(
      taskDescription: 'Complete-catalogue mathematical fixture',
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

  void expectVector(List<Complex> actual, List<Complex> expected) {
    expect(actual, hasLength(expected.length));
    for (var index = 0; index < actual.length; index++) {
      expect(actual[index].real, closeTo(expected[index].real, 1e-9));
      expect(actual[index].imaginary, closeTo(expected[index].imaginary, 1e-9));
    }
  }

  int basisOutput(QuantumCircuit circuit) {
    final probabilities = [
      for (final amplitude in state(circuit))
        amplitude.real * amplitude.real +
            amplitude.imaginary * amplitude.imaginary,
    ];
    final maxProbability = probabilities.reduce(math.max);
    expect(maxProbability, closeTo(1, 1e-9));
    return probabilities.indexOf(maxProbability);
  }

  group('semantic catalogue completeness', () {
    test('contains every approved active semantic ID exactly once', () {
      final actual = mastery2Catalogue.semanticIds.toSet();
      expect(actual, approvedActiveIds.toSet());
      expect(actual, hasLength(approvedActiveIds.length));
      expect(mastery2Catalogue.length, 42);
      expect(
        mastery2Catalogue.orderedDefinitions.map((item) => item.displayOrder),
        List.generate(42, (index) => index + 1),
      );
    });

    test('reserve content and legacy integer identity are not active', () {
      final searchable = mastery2Catalogue.orderedDefinitions
          .map((item) => '${item.semanticId} ${item.title}'.toLowerCase())
          .join(' ');
      expect(searchable, isNot(contains('toffoli')));
      expect(searchable, isNot(contains('ccx')));
      expect(searchable, isNot(contains('rotation')));
      final activeGateTypes = mastery2Catalogue.orderedDefinitions
          .map((item) => item.levelDefinition)
          .whereType<ComposerLevel>()
          .expand((level) => level.availableGates)
          .map((gate) => gate.type)
          .toSet();
      expect(activeGateTypes, isNot(contains(SelectedGateType.ccnot)));
      expect(activeGateTypes, isNot(contains(SelectedGateType.rx)));
      expect(activeGateTypes, isNot(contains(SelectedGateType.ry)));
      expect(activeGateTypes, isNot(contains(SelectedGateType.rz)));
      expect(
        mastery2Catalogue.orderedDefinitions
            .any((item) => item.displayOrder >= 61),
        isFalse,
      );
    });
  });

  group('foundation predictions and evidence', () {
    test('X then X restores |0> after two real operations', () {
      expect(
        basisOutput(runCircuit('0', [
          single(SelectedGateType.x),
          single(SelectedGateType.x),
        ])),
        0,
      );
    });

    test('H on |1> produces the relative-sign state |->', () {
      expectVector(
        state(runCircuit('1', [single(SelectedGateType.hadamard)])),
        [Complex(math.sqrt1_2), Complex(-math.sqrt1_2)],
      );
    });

    test('product state factors while Bell coefficient matrix does not', () {
      // For a two-qubit pure state, determinant zero of its 2x2 coefficient
      // matrix is the separability condition.
      final productDeterminant = math.sqrt1_2 * 0 - math.sqrt1_2 * 0;
      final bellDeterminant = math.sqrt1_2 * math.sqrt1_2 - 0 * 0;
      expect(productDeterminant, closeTo(0, 1e-12));
      expect(bellDeterminant.abs(), greaterThan(0.49));
      final text = (mastery2Catalogue
              .requireBySemanticId('product_or_entangled')
              .levelDefinition as McqLevel)
          .solutionExplanation!;
      expect(text, contains('evidence alone is insufficient'));
    });

    test('Bell Z evidence contains only 00 and 11 but limits its claim', () {
      final bell = state(runCircuit('00', [
        single(SelectedGateType.hadamard),
        cnot(0, 1),
      ]));
      expectVector(bell, [
        Complex(math.sqrt1_2),
        Complex.zero(),
        Complex.zero(),
        Complex(math.sqrt1_2),
      ]);
      final level = mastery2Catalogue
          .requireBySemanticId('bell_measurement_evidence')
          .levelDefinition as McqLevel;
      expect(level.solutionExplanation, contains('classically correlated'));
      expect(level.taskDescription, contains('Ideal'));
    });

    test('S is the unique authored quarter-turn repair', () {
      final types = [
        SelectedGateType.s,
        SelectedGateType.t,
        SelectedGateType.z,
        SelectedGateType.x,
      ];
      final target = [Complex(math.sqrt1_2), Complex(0, math.sqrt1_2)];
      final matches = <SelectedGateType>[];
      for (final type in types) {
        final output = state(runCircuit('0', [
          single(SelectedGateType.hadamard),
          single(type),
        ]));
        if ((output[0] - target[0]).abs() < 1e-9 &&
            (output[1] - target[1]).abs() < 1e-9) {
          matches.add(type);
        }
      }
      expect(matches, [SelectedGateType.s]);
    });
  });

  group('Bell and GHZ mathematics', () {
    test('nonzero Bell preparation canonical solution reaches Phi-minus', () {
      final level = mastery2Catalogue
          .requireBySemanticId('bell_input_sign_preparation')
          .levelDefinition as ComposerLevel;
      final circuit = buildCanonicalSolutionCircuit(level);
      expect(level.validateCircuit(circuit), isTrue);
      expectVector(state(circuit), [
        Complex(math.sqrt1_2),
        Complex.zero(),
        Complex.zero(),
        Complex(-math.sqrt1_2),
      ]);
    });

    test('local Z on either Bell wire produces the same Phi-minus state', () {
      final prefix = [single(SelectedGateType.hadamard), cnot(0, 1)];
      final z0 =
          state(runCircuit('00', [...prefix, single(SelectedGateType.z)]));
      final z1 = state(runCircuit('00', [
        ...prefix,
        single(SelectedGateType.z, 1),
      ]));
      expectVector(z0, z1);
      expectVector(z0, [
        Complex(math.sqrt1_2),
        Complex.zero(),
        Complex.zero(),
        Complex(-math.sqrt1_2),
      ]);
    });

    test('GHZ support and broken-link evidence are exact under Q0-LSB', () {
      final correct = state(runCircuit('000', [
        single(SelectedGateType.hadamard),
        cnot(0, 1),
        cnot(1, 2),
      ]));
      expectVector(correct, [
        Complex(math.sqrt1_2),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex(math.sqrt1_2),
      ]);
      final broken = state(runCircuit('000', [
        single(SelectedGateType.hadamard),
        cnot(0, 1),
        cnot(2, 1),
      ]));
      expectVector(broken, [
        Complex(math.sqrt1_2),
        Complex.zero(),
        Complex.zero(),
        Complex(math.sqrt1_2),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
      ]);
    });

    test('one local Z creates the signed GHZ target', () {
      final level = mastery2Catalogue
          .requireBySemanticId('ghz_phase_manipulation')
          .levelDefinition as ComposerLevel;
      final circuit = buildCanonicalSolutionCircuit(level);
      expect(level.validateCircuit(circuit), isTrue);
      expectVector(
          state(circuit), level.solutionFinalVector.expand((e) => e).toList());
    });
  });

  group('kickback, synthesis, and uncomputation', () {
    test('H reveals kicked-back |-> control as |1>', () {
      final output = runCircuit('00', [
        single(SelectedGateType.hadamard),
        single(SelectedGateType.x, 1),
        single(SelectedGateType.hadamard, 1),
        cnot(0, 1),
        single(SelectedGateType.hadamard),
      ]);
      // q0 is deterministically 1; q1 remains |->, so indices 1 and 3
      // have equal probability.
      final probabilities = state(output)
          .map((a) => a.real * a.real + a.imaginary * a.imaginary)
          .toList();
      expect(probabilities[0] + probabilities[2], closeTo(0, 1e-9));
      expect(probabilities[1] + probabilities[3], closeTo(1, 1e-9));
    });

    test('all new Composer canonical solutions satisfy authored validation',
        () {
      const ids = [
        'bell_input_sign_preparation',
        'ghz_phase_manipulation',
        'inverse_phase_synthesis',
        'phased_entanglement_uncomputation',
        'conditional_phase_decomposition',
        'clean_workspace_uncomputation',
      ];
      for (final id in ids) {
        final level = mastery2Catalogue.requireBySemanticId(id).levelDefinition
            as ComposerLevel;
        final circuit = buildCanonicalSolutionCircuit(level);
        expect(level.validateCircuit(circuit), isTrue, reason: id);
      }
    });

    test('inverse phase synthesis realizes e^-ipi/4 without T-dagger', () {
      final level = mastery2Catalogue
          .requireBySemanticId('inverse_phase_synthesis')
          .levelDefinition as ComposerLevel;
      final circuit = buildCanonicalSolutionCircuit(level);
      expectVector(state(circuit), [
        Complex(math.sqrt1_2),
        Complex(0.5, -0.5),
      ]);
      expect(level.availableGates.map((gate) => gate.type),
          isNot(contains(SelectedGateType.rz)));
    });

    test('phased Bell inverse and CZ decomposition are full-unitary claims',
        () {
      for (final id in [
        'phased_entanglement_uncomputation',
        'conditional_phase_decomposition',
      ]) {
        final level = mastery2Catalogue.requireBySemanticId(id).levelDefinition
            as ComposerLevel;
        expect(level.validationMode, ValidationMode.unitary);
        expect(level.validateCircuit(buildCanonicalSolutionCircuit(level)),
            isTrue);
      }
    });

    test('workspace cleanup restores work q1 while preserving phase on q0', () {
      final level = mastery2Catalogue
          .requireBySemanticId('clean_workspace_uncomputation')
          .levelDefinition as ComposerLevel;
      final solved = buildCanonicalSolutionCircuit(level);
      expectVector(state(solved), [
        Complex(math.sqrt1_2),
        Complex(-math.sqrt1_2),
        Complex.zero(),
        Complex.zero(),
      ]);
    });
  });

  group('oracle and amplification evidence', () {
    test('repaired X-wrapped oracle marks only |10> and restores labels', () {
      const cz = CanonicalCircuitStep.controlled(
        SelectedGateType.cz,
        controlQubit: 0,
        targetQubit: 1,
      );
      final repaired = runCircuit('00', [
        single(SelectedGateType.hadamard),
        single(SelectedGateType.hadamard, 1),
        single(SelectedGateType.x),
        cz,
        single(SelectedGateType.x),
      ]);
      expectVector(state(repaired), [
        Complex(0.5),
        Complex(0.5),
        Complex(-0.5),
        Complex(0.5),
      ]);
      final oracleMatrix = runCircuit('00', [
        single(SelectedGateType.x),
        cz,
        single(SelectedGateType.x),
      ]).getOverallCircuitMatrix().toComplexList();
      expectVector(oracleMatrix.expand((row) => row).toList(), [
        Complex.one(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.one(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex(-1),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.zero(),
        Complex.one(),
      ]);
    });

    test('marking changes sign but not probability', () {
      const amplitudes = [0.5, 0.5, -0.5, 0.5];
      final probabilities = amplitudes.map((value) => value * value).toList();
      expect(probabilities, [0.25, 0.25, 0.25, 0.25]);
      expect(probabilities.reduce((a, b) => a + b), 1);
    });

    test('supplied diffusion reflection concentrates four-state amplitude', () {
      const marked = [0.5, 0.5, -0.5, 0.5];
      final mean = marked.reduce((a, b) => a + b) / marked.length;
      final reflected = marked.map((a) => 2 * mean - a).toList();
      expect(reflected, [0, 0, 1, 0]);
    });

    test('wrong Grover order remains flat before the useful interference', () {
      const uniform = [0.5, 0.5, 0.5, 0.5];
      final mean = uniform.reduce((a, b) => a + b) / uniform.length;
      final amplifiedFirst = uniform.map((a) => 2 * mean - a).toList();
      expect(amplifiedFirst, uniform);
      final oracleAfter = [...amplifiedFirst]..[2] = -amplifiedFirst[2];
      expect(oracleAfter.map((a) => a * a), everyElement(0.25));
    });

    test('eight-state forensic snapshots normalize and imply 25/32', () {
      final initial = 1 / math.sqrt(8);
      final afterOracle = List.filled(8, initial)..[5] = -initial;
      expect(afterOracle.map((a) => a * a).reduce((a, b) => a + b),
          closeTo(1, 1e-12));
      final afterAmplifier = List.filled(8, 1 / (2 * math.sqrt(8)))
        ..[5] = 5 / (2 * math.sqrt(8));
      expect(afterAmplifier[5] * afterAmplifier[5], closeTo(25 / 32, 1e-12));
      expect(afterAmplifier.map((a) => a * a).reduce((a, b) => a + b),
          closeTo(1, 1e-12));
    });

    test('algorithm wording stays scoped to the taught search model', () {
      for (final id in [
        'grover_round_order',
        'retry_or_reshape',
        'search_pipeline_forensics',
      ]) {
        final level = mastery2Catalogue.requireBySemanticId(id).levelDefinition
            as McqLevel;
        final text = '${level.taskDescription} ${level.solutionExplanation}'
            .toLowerCase();
        expect(text, isNot(contains('all quantum algorithms')), reason: id);
      }
    });
  });

  test('semantic completion retains prior completion and Journey progress', () {
    final priorIds = mastery2Catalogue.orderedDefinitions
        .take(15)
        .map((item) => item.semanticId)
        .toSet();
    final before = CampaignProgressState(
      maxUnlockedLevel: 12,
      completedLessonIds: const {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11},
      completedMasterySemanticIds: priorIds,
      completedChallengeIds: const {61, 62},
    );
    final after = CampaignProgressPolicy.completeMasteryChallenge(
      before,
      'search_pipeline_forensics',
    );
    expect(after.completedMasterySemanticIds, containsAll(priorIds));
    expect(after.completedMasterySemanticIds,
        contains('search_pipeline_forensics'));
    expect(after.completedLessonIds, before.completedLessonIds);
    expect(after.maxUnlockedLevel, before.maxUnlockedLevel);
    expect(after.completedChallengeIds, before.completedChallengeIds);
  });
}
