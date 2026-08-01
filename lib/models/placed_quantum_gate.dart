import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/gate_id.dart';

class PlacedQuantumGate {
  final GateId? id;
  final Gate gate;
  final int? controlQubitIndex;
  final int? control2QubitIndex;
  final int? targetQubitIndex;
  final bool isTarget;
  final bool isLink;
  final bool isControl;
  final bool isControl2;
  final bool isDeletable;

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
          isDeletable == other.isDeletable;

  PlacedQuantumGate({
    required this.gate,
    this.id,
    this.controlQubitIndex,
    this.control2QubitIndex,
    this.targetQubitIndex,
    this.isControl = false,
    this.isControl2 = false,
    this.isTarget = false,
    this.isLink = false,
    this.isDeletable = true,
  });

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
      isDeletable.hashCode;
}
