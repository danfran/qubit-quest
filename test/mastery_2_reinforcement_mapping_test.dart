import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_reinforcement.dart';
import 'package:quantumquiz/models/notebook_entries.dart';

void main() {
  test('every explicit reinforcement mapping resolves production content', () {
    final activeIds = mastery2Catalogue.orderedDefinitions
        .map((definition) => definition.semanticId)
        .toSet();

    expect(mastery2NotebookReinforcementEntryIds, isNotEmpty);
    expect(
      notebookEntriesById,
      hasLength(notebookEntries.length),
      reason: 'Stable Notebook entry IDs must be unique lookup keys.',
    );
    expect(
      mastery2NotebookReinforcementEntryIds.keys,
      everyElement(isIn(activeIds)),
    );
    expect(
      mastery2NotebookReinforcementEntryIds.values,
      everyElement(isIn(notebookEntriesById.keys)),
    );
    expect(mastery2NotebookReinforcementEntryIds, hasLength(34));
  });

  test('curriculum-gap mappings target the intended reusable entries', () {
    const expected = {
      'phase_state_uncomputation': 'reversibility',
      'bell_decoder_bug': 'bell_state',
      'phase_accumulation_prediction': 'hidden_information',
      'complex_y_phase_trace': 'hidden_information',
      'phase_sandwich_unitary': 'invisible_difference',
      'cnot_uncomputation': 'reversibility',
      'bell_phase_equivalence': 'bell_state',
      'ghz_phase_manipulation': 'ghz_state',
      'inverse_phase_synthesis': 'reversibility',
      'oracle_repair_uncompute': 'compute_encode_reveal',
      'clean_workspace_uncomputation': 'reversibility',
    };

    for (final mapping in expected.entries) {
      expect(
        mastery2NotebookReinforcementEntryIds[mapping.key],
        mapping.value,
      );
      expect(mastery2ReinforcementNotebookEntry(mapping.key), isNotNull);
    }
  });

  test('intentional synthesis challenges retain generic reinforcement', () {
    for (final semanticId in const {
      'phased_entanglement_uncomputation',
      'conditional_phase_decomposition',
    }) {
      expect(mastery2ReinforcementNotebookEntry(semanticId), isNull);
    }
  });

  test('extended Notebook entries contain reusable conceptual material', () {
    final reversibility = notebookEntriesById['reversibility']!;
    expect(reversibility.quantumView!.body, contains('inverse'));
    expect(reversibility.advancedNotes!.body, contains('workspace'));

    final globalPhase = notebookEntriesById['invisible_difference']!;
    expect(globalPhase.advancedNotes!.body, contains('same matrix'));

    final phase = notebookEntriesById['hidden_information']!;
    expect(phase.quantumView!.body, contains('accumulate'));
    expect(phase.advancedNotes!.body, contains('Y exchanges'));

    final bell = notebookEntriesById['bell_state']!;
    expect(bell.advancedNotes!.body, contains('reverse order'));

    final ghz = notebookEntriesById['ghz_state']!;
    expect(ghz.advancedNotes!.body, contains('relative phase'));

    final oracle = notebookEntriesById['compute_encode_reveal']!;
    expect(oracle.advancedNotes!.body, contains('compute → mark → uncompute'));
  });
}
