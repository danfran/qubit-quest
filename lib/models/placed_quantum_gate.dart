import 'package:flutter/foundation.dart' show listEquals;
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/gate_id.dart';

class PlacedQuantumGate {
  final GateId? id;
  final Gate gate;
  final int? controlQubitIndex;
  final int? control2QubitIndex;
  final int? targetQubitIndex;

  /// Every control of a multi-controlled gate ([SelectedGateType.mcx]),
  /// ascending. Null for the other gates, whose controls live in
  /// [controlQubitIndex] and [control2QubitIndex] (unchanged since v2.5).
  final List<int>? controlQubitIndices;
  final bool isTarget;
  final bool isLink;
  final bool isControl;
  final bool isControl2;
  final bool isDeletable;

  /// Classical destination; set only on [SelectedGateType.measureZ] cells.
  final int? classicalBit;

  bool get isMeasurement => gate.type == SelectedGateType.measureZ;

  /// All control qubits, whatever the gate stores them in.
  List<int> get controlQubits =>
      controlQubitIndices ??
      [
        if (controlQubitIndex != null) controlQubitIndex!,
        if (control2QubitIndex != null) control2QubitIndex!,
      ];

  static PlacedQuantumGate emptyGate() =>
      PlacedQuantumGate(gate: Gate.fromIdentifier(SelectedGateType.none));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacedQuantumGate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          gate == other.gate &&
          isControl == other.isControl &&
          isControl2 == other.isControl2 &&
          isTarget == other.isTarget &&
          isLink == other.isLink &&
          controlQubitIndex == other.controlQubitIndex &&
          control2QubitIndex == other.control2QubitIndex &&
          targetQubitIndex == other.targetQubitIndex &&
          listEquals(controlQubitIndices, other.controlQubitIndices) &&
          isDeletable == other.isDeletable &&
          classicalBit == other.classicalBit;

  PlacedQuantumGate({
    required this.gate,
    this.id,
    this.controlQubitIndex,
    this.control2QubitIndex,
    this.targetQubitIndex,
    List<int>? controlQubitIndices,
    this.isControl = false,
    this.isControl2 = false,
    this.isTarget = false,
    this.isLink = false,
    this.isDeletable = true,
    this.classicalBit,
  }) : controlQubitIndices = controlQubitIndices == null
            ? null
            : List.unmodifiable(controlQubitIndices.toList()..sort());

  @override
  int get hashCode =>
      id.hashCode ^
      gate.hashCode ^
      isControl.hashCode ^
      isControl2.hashCode ^
      isTarget.hashCode ^
      isLink.hashCode ^
      controlQubitIndex.hashCode ^
      control2QubitIndex.hashCode ^
      targetQubitIndex.hashCode ^
      Object.hashAll(controlQubitIndices ?? const []) ^
      isDeletable.hashCode ^
      classicalBit.hashCode;
}
