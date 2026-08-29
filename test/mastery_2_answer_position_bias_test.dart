import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';

void main() {
  final expectedCorrectAnswerMarker = <String, String>{
    'global_phase_equivalence': 'different statevector representatives',
    'same_histogram_different_state': 'one basis distribution',
    'cnot_topology_inference': 'control q2 → target q0',
    'bell_decoder_bug': 'Swap the gate order',
    'phase_kickback_conditions': '|+⟩control |−⟩target',
    'oracle_marked_state_inference': '|10⟩; X(q0) → CZ(q0,q1) → X(q0)',
    'algorithm_architecture_inspector': 'A needs amplification',
    'phase_accumulation_prediction': r'e^{i3\pi/4}',
    'complex_y_phase_trace': r'|-\rangle',
    'interferometer_repair': 'H',
    'phase_sandwich_unitary': 'XZX = −Z as matrices',
    'fanout_is_not_cloning': 'propagates a known basis value',
    'swap_unitary_diagnosis': 'A is SWAP',
    'reversible_cancellation_trace': 'each X is a real operation',
    'hadamard_input_sign': r'|-\rangle',
    'product_or_entangled': 'A factors as |0⟩|+⟩',
    'bell_measurement_evidence':
        'does not exclude a classical correlated source',
    'quarter_turn_relative_phase': 'S',
    'bell_phase_equivalence': 'Either placement produces Φ−',
    'ghz_outcome_constraint': 'Only 000 and 111',
    'ghz_broken_link': 'CNOT(q1→q2)',
    'phase_kickback_reveal': 'H, revealing control |1⟩',
    'oracle_repair_uncompute': 'Append X(q0).',
    'marked_is_not_amplified': 'Only after amplification',
    'amplitude_flow_inference': '[0, 0, 1, 0]',
    'grover_round_order': 'Apply the oracle before amplification',
    'retry_or_reshape': 'Reprepare, apply an oracle-plus-amplifier round',
    'search_pipeline_forensics': '|101⟩ was phase-marked',
  };

  final selectable = mastery2Catalogue.orderedDefinitions.where(
    (definition) => definition.levelDefinition is McqLevel,
  );

  test('selectable challenge answers use stable balanced authored positions',
      () {
    final definitions = selectable.toList(growable: false);
    final positions = [
      for (final definition in definitions)
        (definition.levelDefinition as McqLevel).correctOptionIndex,
    ];

    expect(definitions, hasLength(28));
    expect(positions.toSet(), {0, 1, 2, 3});

    final counts = <int, int>{};
    for (final position in positions) {
      counts.update(position, (count) => count + 1, ifAbsent: () => 1);
    }
    final sortedCounts = counts.values.toList()..sort();
    expect(sortedCounts.last - sortedCounts.first, lessThanOrEqualTo(1));

    var currentRun = 0;
    var longestRun = 0;
    int? previous;
    for (final position in positions) {
      currentRun = position == previous ? currentRun + 1 : 1;
      longestRun = currentRun > longestRun ? currentRun : longestRun;
      previous = position;
    }
    expect(longestRun, lessThanOrEqualTo(2));

    expect(
      [
        for (final definition in selectable)
          (definition.levelDefinition as McqLevel).correctOptionIndex,
      ],
      positions,
      reason: 'Authored ordering must be deterministic between reads.',
    );
  });

  test('reordered indices retain every intended semantic answer', () {
    expect(selectable, hasLength(expectedCorrectAnswerMarker.length));

    for (final definition in selectable) {
      final level = definition.levelDefinition as McqLevel;
      final marker = expectedCorrectAnswerMarker[definition.semanticId];
      expect(marker, isNotNull, reason: definition.semanticId);
      expect(level.options, hasLength(4), reason: definition.semanticId);
      expect(
        level.options[level.correctOptionIndex],
        contains(marker!),
        reason: '${definition.semanticId} must retain its semantic answer',
      );
    }
  });
}
