// placed_quantum_gate.dart

// You will need to import the enum that defines your gate types.
// Assuming it's in selected_gate_type.dart
import 'package:quantumquiz/selected_gate_type.dart';
import 'dart:math'; // Needed for min/max in getQubitIndices if you sort


// This class represents a gate as it is placed in the visual circuit grid
class PlacedQuantumGate {
  // What type of gate is this instance (Hadamard, CNOT, etc.)
  final SelectedGateType type;

  // The horizontal position (column index) where the gate is placed
  final int position;

  // Properties specific to single-qubit gates: the qubit line it's on
  final int? singleQubitIndex;

  // Properties specific to CNOT gates: the control and target qubit lines
  final int? controlQubitIndex;
  final int? targetQubitIndex;

  // Constructor
  PlacedQuantumGate({
    required this.type,
    required this.position,
    this.singleQubitIndex,
    this.controlQubitIndex,
    this.targetQubitIndex,
  }) : assert(
  // Assertion to ensure valid combinations of properties based on gate type
  (type != SelectedGateType.cnot && singleQubitIndex != null && controlQubitIndex == null && targetQubitIndex == null) || // Must be a single-qubit gate with a singleQubitIndex
      (type == SelectedGateType.cnot && singleQubitIndex == null && controlQubitIndex != null && targetQubitIndex != null), // Must be a CNOT with control and target indices
  'Placed gate must be either a single-qubit gate or a CNOT with valid qubit indices.',
  );

  // Helper getter to determine the primary qubit line for drawing this gate
  // This is typically the single qubit for H/X, or the control qubit for CNOT
  int get primaryDrawingQubit {
    if (type != SelectedGateType.cnot && singleQubitIndex != null) {
      return singleQubitIndex!;
    } else if (type == SelectedGateType.cnot && controlQubitIndex != null) {
      return controlQubitIndex!;
    }
    // This point should ideally not be reached if the constructor assertion is correct
    throw StateError("Placed gate has no primary drawing qubit defined.");
  }

  // Helper method to get a list of all qubit indices involved in this placed gate
  // Useful for simulation or drawing connection lines (like for CNOT)
  List<int> getQubitIndices() {
    if (type != SelectedGateType.cnot && singleQubitIndex != null) {
      return [singleQubitIndex!];
    } else if (type == SelectedGateType.cnot && controlQubitIndex != null && targetQubitIndex != null) {
      // Return sorted indices for consistency (e.g., [0, 1] vs [1, 0] for CNOT)
      final List<int> indices = [controlQubitIndex!, targetQubitIndex!];
      indices.sort(); // Sorts in place
      return indices;
    }
    // Should not happen due to constructor assertion
    return [];
  }
}
