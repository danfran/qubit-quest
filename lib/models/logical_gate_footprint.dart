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

  /// Stored control list of a multi-controlled gate (MCX); see
  /// [controlQubits] for every gate's controls.
  final List<int>? _controlQubitList;

  const LogicalGateFootprint({
    required this.id,
    required this.gate,
    required this.fragments,
    required this.anchor,
    required this.controlQubit,
    required this.secondControlQubit,
    required this.targetQubit,
    required this.isDeletable,
    List<int>? controlQubits,
  }) : _controlQubitList = controlQubits;

  /// All control qubits in their stored order (empty when uncontrolled).
  List<int> get controlQubits =>
      _controlQubitList ??
      [
        if (controlQubit != null) controlQubit!,
        if (secondControlQubit != null) secondControlQubit!,
      ];

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
  bool get isMeasurement =>
      type == SelectedGateType.measureZ && fragments.length == 1;
  bool get isControlled => !isSingleQubit && !isMeasurement;
  bool get isEditable => isSingleQubit && isDeletable;
  bool get supportsControlledHorizontalMovement => const {
        SelectedGateType.cnot,
        SelectedGateType.cz,
        SelectedGateType.ccnot,
        SelectedGateType.cy,
        SelectedGateType.mcx,
      }.contains(type);
  bool get canMoveHorizontally =>
      isSingleQubit || isMeasurement || supportsControlledHorizontalMovement;
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
    if (isSingleQubit || isMeasurement) return true;

    bool metadataMatches(PlacedQuantumGate fragment) =>
        fragment.controlQubitIndex == controlQubit &&
        fragment.control2QubitIndex == secondControlQubit &&
        listEquals(fragment.controlQubitIndices, _controlQubitList) &&
        fragment.targetQubitIndex == targetQubit;

    // How each gate type stores its controls (v2.6 M7: one rule for all).
    final controls = controlQubits;
    final validShape = switch (type) {
      SelectedGateType.cnot ||
      SelectedGateType.cz ||
      SelectedGateType.cy =>
        controls.length == 1 &&
            secondControlQubit == null &&
            _controlQubitList == null,
      SelectedGateType.ccnot => controls.length == 2 &&
          secondControlQubit != null &&
          _controlQubitList == null,
      SelectedGateType.mcx => controlQubit == null &&
          secondControlQubit == null &&
          (_controlQubitList?.length ?? 0) >= 3,
      _ => false,
    };
    final target = targetQubit;
    if (!validShape || target == null) return false;
    final operands = [...controls, target];
    if (operands.toSet().length != operands.length ||
        operands.any((row) => row < 0 || row >= qubitCount)) {
      return false;
    }
    final from = operands.reduce((a, b) => a < b ? a : b);
    final to = operands.reduce((a, b) => a > b ? a : b);
    if (fragments.length != to - from + 1) return false;
    for (final fragment in fragments) {
      final row = fragment.location.qubit;
      final placed = fragment.placedGate;
      if (!metadataMatches(placed)) return false;
      // CCX keeps its historical role for the second control.
      final isSecond = type == SelectedGateType.ccnot && row == controls[1];
      final isFirst = !isSecond && controls.contains(row);
      if (placed.isControl != isFirst ||
          placed.isControl2 != isSecond ||
          placed.isTarget != (row == target) ||
          placed.isLink != !operands.contains(row)) {
        return false;
      }
    }
    return fragments
        .map((fragment) => fragment.location.qubit)
        .toSet()
        .containsAll([for (var row = from; row <= to; row++) row]);
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
