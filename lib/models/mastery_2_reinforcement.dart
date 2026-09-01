import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';

/// Explicit, editorially reviewed Mastery-to-learning-resource relationships.
/// Concept tags are deliberately not used to infer recommendations.
const Map<String, String> mastery2NotebookReinforcementEntryIds = {
  'global_phase_equivalence': 'invisible_difference',
  'phase_state_uncomputation': 'reversibility',
  'same_histogram_different_state': 'phase_is_hidden',
  'cnot_topology_inference': 'control',
  'bell_decoder_bug': 'bell_state',
  'phase_kickback_conditions': 'the_kickback_effect',
  'oracle_marked_state_inference': 'simple_marking_rule',
  'algorithm_architecture_inspector': 'role_separation_in_quantum_algorithms',
  'phase_accumulation_prediction': 'hidden_information',
  'complex_y_phase_trace': 'hidden_information',
  'interferometer_repair': 'phase_becomes_bit',
  'phase_sandwich_unitary': 'invisible_difference',
  'cnot_uncomputation': 'reversibility',
  'fanout_is_not_cloning': 'information_transfer',
  'swap_unitary_diagnosis': 'swap',
  'reversible_cancellation_trace': 'reversibility',
  'hadamard_input_sign': 'bit_becomes_phase',
  'product_or_entangled': 'entanglement',
  'bell_measurement_evidence': 'one_quantum_system',
  'quarter_turn_relative_phase': 'hidden_information',
  'bell_input_sign_preparation': 'bell_state',
  'bell_phase_equivalence': 'bell_state',
  'ghz_outcome_constraint': 'ghz_state',
  'ghz_broken_link': 'all_together',
  'ghz_phase_manipulation': 'ghz_state',
  'phase_kickback_reveal': 'compute_encode_reveal',
  'inverse_phase_synthesis': 'reversibility',
  'oracle_repair_uncompute': 'compute_encode_reveal',
  'marked_is_not_amplified': 'why_marking_is_not_enough',
  'amplitude_flow_inference': 'reinforcement_of_probability',
  'grover_round_order': 'quantum_algorithm_structure',
  'retry_or_reshape': 'cognitive_transfer_of_iteration_thinking',
  'clean_workspace_uncomputation': 'reversibility',
  'search_pipeline_forensics': 'unified_quantum_algorithm_model',
};

NotebookEntry? mastery2ReinforcementNotebookEntry(String semanticId) {
  final entryId = mastery2NotebookReinforcementEntryIds[semanticId];
  return entryId == null ? null : notebookEntriesById[entryId];
}
