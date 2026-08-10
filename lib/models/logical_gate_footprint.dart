import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

@immutable
class LogicalGateFragment {
  final CircuitLocation location;
  final PlacedQuantumGate placedGate;

  const LogicalGateFragment({
    required this.location,
    required this.placedGate,
  });
}

@immutable
class LogicalGateFootprint {
  final GateId id;
  final Gate gate;
  final List<LogicalGateFragment> fragments;
  final CircuitLocation anchor;
  final int? controlQubit;
  final int? secondControlQubit;
  final int? targetQubit;
  final bool isDeletable;

  const LogicalGateFootprint({
    required this.id,
    required this.gate,
    required this.fragments,
    required this.anchor,
    required this.controlQubit,
    required this.secondControlQubit,
    required this.targetQubit,
    required this.isDeletable,
  });

  SelectedGateType get type => gate.type;
  int get column => anchor.column;
  List<CircuitLocation> get occupiedLocations =>
      fragments.map((fragment) => fragment.location).toList(growable: false);
  bool get isSingleQubit =>
      fragments.length == 1 &&
      controlQubit == null &&
      secondControlQubit == null &&
      targetQubit == null &&
      const {
        SelectedGateType.hadamard,
        SelectedGateType.s,
        SelectedGateType.t,
        SelectedGateType.x,
        SelectedGateType.y,
        SelectedGateType.z,
        SelectedGateType.rx,
        SelectedGateType.ry,
        SelectedGateType.rz,
      }.contains(type);
  bool get isControlled => !isSingleQubit;
  bool get isEditable => isSingleQubit && isDeletable;
  bool get supportsControlledHorizontalMovement =>
      type == SelectedGateType.cnot ||
      type == SelectedGateType.cz ||
      type == SelectedGateType.ccnot;
  bool get canMoveHorizontally =>
      isSingleQubit || supportsControlledHorizontalMovement;
  bool get canTranslateRigidly => canMoveHorizontally;
  bool get isMovable => canMoveHorizontally && isDeletable;
  bool get supportsParameterEditing => isSingleQubit && gate.requiresAngle;
  bool get isParameterEditable => supportsParameterEditing && isEditable;

  bool hasValidTopology(int qubitCount) {
    if (fragments.isEmpty ||
        fragments.any((fragment) =>
            fragment.placedGate.id != id ||
            fragment.placedGate.gate.type != type ||
            fragment.location.qubit < 0 ||
            fragment.location.qubit >= qubitCount) ||
        fragments.map((fragment) => fragment.location.column).toSet().length !=
            1 ||
        fragments.map((fragment) => fragment.location.qubit).toSet().length !=
            fragments.length) {
      return false;
    }
    if (isSingleQubit) return true;

    bool metadataMatches(PlacedQuantumGate fragment) =>
        fragment.controlQubitIndex == controlQubit &&
        fragment.control2QubitIndex == secondControlQubit &&
        fragment.targetQubitIndex == targetQubit;

    if (type == SelectedGateType.cnot || type == SelectedGateType.cz) {
      final control = controlQubit;
      final target = targetQubit;
      if (control == null ||
          target == null ||
          control == target ||
          control < 0 ||
          target < 0 ||
          control >= qubitCount ||
          target >= qubitCount) {
        return false;
      }
      final from = control < target ? control : target;
      final to = control > target ? control : target;
      if (fragments.length != to - from + 1) return false;
      for (final fragment in fragments) {
        final row = fragment.location.qubit;
        final placed = fragment.placedGate;
        if (!metadataMatches(placed)) return false;
        if (row == control) {
          if (!placed.isControl ||
              placed.isControl2 ||
              placed.isTarget ||
              placed.isLink) {
            return false;
          }
        } else if (row == target) {
          if (!placed.isTarget ||
              placed.isControl ||
              placed.isControl2 ||
              placed.isLink) {
            return false;
          }
        } else if (!placed.isLink ||
            placed.isControl ||
            placed.isControl2 ||
            placed.isTarget) {
          return false;
        }
      }
      return fragments
          .map((fragment) => fragment.location.qubit)
          .toSet()
          .containsAll([for (var row = from; row <= to; row++) row]);
    }

    if (type == SelectedGateType.ccnot) {
      final control = controlQubit;
      final control2 = secondControlQubit;
      final target = targetQubit;
      if (control == null ||
          control2 == null ||
          target == null ||
          {control, control2, target}.length != 3 ||
          [control, control2, target]
              .any((row) => row < 0 || row >= qubitCount)) {
        return false;
      }
      final rows = [control, control2, target]..sort();
      final from = rows.first;
      final to = rows.last;
      if (fragments.length != to - from + 1) return false;
      for (final fragment in fragments) {
        final row = fragment.location.qubit;
        final placed = fragment.placedGate;
        if (!metadataMatches(placed)) return false;
        if (row == control) {
          if (!placed.isControl ||
              placed.isControl2 ||
              placed.isTarget ||
              placed.isLink) {
            return false;
          }
        } else if (row == control2) {
          if (!placed.isControl2 ||
              placed.isControl ||
              placed.isTarget ||
              placed.isLink) {
            return false;
          }
        } else if (row == target) {
          if (!placed.isTarget ||
              placed.isControl ||
              placed.isControl2 ||
              placed.isLink) {
            return false;
          }
        } else if (!placed.isLink ||
            placed.isControl ||
            placed.isControl2 ||
            placed.isTarget) {
          return false;
        }
      }
      return fragments
          .map((fragment) => fragment.location.qubit)
          .toSet()
          .containsAll([for (var row = from; row <= to; row++) row]);
    }
    return false;
  }

  PlacedGateRef toPlacedGateRef() => PlacedGateRef(
        id: id,
        gate: gate,
        location: anchor,
        isDeletable: isDeletable,
        isSingleQubit: isSingleQubit,
        canMoveHorizontally: canMoveHorizontally,
      );
}
