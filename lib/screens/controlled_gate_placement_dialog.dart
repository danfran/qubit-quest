import 'package:flutter/material.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/three_qubits_gate_target_qubits_selection_dialog.dart';
import 'package:quantumquiz/screens/two_qubits_gate_target_qubit_selection_dialog.dart';

/// The qubit roles selected before inserting one logical controlled gate.
class ControlledGatePlacement {
  const ControlledGatePlacement({
    required this.targetQubit,
    required this.controlQubit,
    this.secondControlQubit,
  });

  final int targetQubit;
  final int controlQubit;
  final int? secondControlQubit;

  bool isValidFor({
    required SelectedGateType gateType,
    required int numQubits,
  }) {
    final roles = <int>{targetQubit, controlQubit};
    if (targetQubit < 0 ||
        controlQubit < 0 ||
        targetQubit >= numQubits ||
        controlQubit >= numQubits ||
        roles.length != 2) {
      return false;
    }
    if (gateType == SelectedGateType.ccnot) {
      final second = secondControlQubit;
      return second != null &&
          second >= 0 &&
          second < numQubits &&
          <int>{...roles, second}.length == 3;
    }
    return (gateType == SelectedGateType.cnot ||
            gateType == SelectedGateType.cz) &&
        secondControlQubit == null;
  }
}

/// Reuses the production Composer role pickers for controlled-gate insertion.
Future<ControlledGatePlacement?> showControlledGatePlacementDialog(
  BuildContext context, {
  required SelectedGateType gateType,
  required int targetQubit,
  required int numQubits,
}) async {
  if (gateType == SelectedGateType.cnot || gateType == SelectedGateType.cz) {
    if (numQubits < 2) return null;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TwoQubitsGateTargetQubitSelectionDialog(
        targetQubitIndex: targetQubit,
        numQubits: numQubits,
      ),
    );
    final control = result?['control1'] as int?;
    if (control == null) return null;
    final placement = ControlledGatePlacement(
      targetQubit: targetQubit,
      controlQubit: control,
    );
    return placement.isValidFor(gateType: gateType, numQubits: numQubits)
        ? placement
        : null;
  }

  if (gateType == SelectedGateType.ccnot) {
    if (numQubits < 3) return null;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ThreeQubitsGateTargetQubitsSelectionDialog(
        targetQubitIndex: targetQubit,
        numQubits: numQubits,
      ),
    );
    final control = result?['control1'] as int?;
    final secondControl = result?['control2'] as int?;
    if (control == null || secondControl == null) return null;
    final placement = ControlledGatePlacement(
      targetQubit: targetQubit,
      controlQubit: control,
      secondControlQubit: secondControl,
    );
    return placement.isValidFor(gateType: gateType, numQubits: numQubits)
        ? placement
        : null;
  }

  return null;
}
