import 'package:quantumquiz/models/selected_gate_type.dart';


class PlacedQuantumGate {
  final SelectedGateType type;
  final int? controlQubitIndex;
  final int? targetQubitIndex;
  final bool isTarget;
  final bool isLink;
  final bool isControl;

  static PlacedQuantumGate emptyGate() => PlacedQuantumGate(type: SelectedGateType.none);

  PlacedQuantumGate({
    required this.type,
    this.controlQubitIndex,
    this.targetQubitIndex,
    this.isControl = false,
    this.isTarget = false,
    this.isLink = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PlacedQuantumGate &&
              runtimeType == other.runtimeType &&
              type == other.type &&
              isControl == other.isControl &&
              isTarget == other.isTarget &&
              isLink == other.isLink &&
              controlQubitIndex == other.controlQubitIndex &&
              targetQubitIndex == other.targetQubitIndex;

  @override
  int get hashCode =>
      type.hashCode ^
      isControl.hashCode ^
      isTarget.hashCode ^
      isLink.hashCode ^
      controlQubitIndex.hashCode ^
      targetQubitIndex.hashCode;
}
