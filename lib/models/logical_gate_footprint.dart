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
      targetQubit == null;
  bool get isControlled => !isSingleQubit;
  bool get isMovable => isSingleQubit && isDeletable;

  PlacedGateRef toPlacedGateRef() => PlacedGateRef(
        id: id,
        gate: gate,
        location: anchor,
        isDeletable: isDeletable,
        isSingleQubit: isSingleQubit,
      );
}
