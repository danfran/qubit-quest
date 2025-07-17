import 'package:quantumquiz/models/selected_gate_type.dart';


class PlacedQuantumGate {
  final SelectedGateType type;
  final int? controlQubitIndex;
  final int? control2QubitIndex;
  final int? targetQubitIndex;
  final bool isTarget;
  final bool isLink;
  final bool isControl;
  final bool isControl2;

  static PlacedQuantumGate emptyGate() => PlacedQuantumGate(type: SelectedGateType.none);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PlacedQuantumGate &&
              runtimeType == other.runtimeType &&
              type == other.type &&
              isControl == other.isControl &&
              isControl2 == other.isControl2 &&
              isTarget == other.isTarget &&
              isLink == other.isLink &&
              controlQubitIndex == other.controlQubitIndex &&
              control2QubitIndex == other.control2QubitIndex &&
              targetQubitIndex == other.targetQubitIndex;

  PlacedQuantumGate({
    required this.type,
    this.controlQubitIndex,
    this.control2QubitIndex,
    this.targetQubitIndex,
    this.isControl = false,
    this.isControl2 = false,
    this.isTarget = false,
    this.isLink = false,
  });

  @override
  int get hashCode =>
      type.hashCode ^
      isControl.hashCode ^
      isControl2.hashCode ^
      isTarget.hashCode ^
      isLink.hashCode ^
      controlQubitIndex.hashCode ^
      control2QubitIndex.hashCode ^
      targetQubitIndex.hashCode;
}
