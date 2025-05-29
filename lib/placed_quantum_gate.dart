import 'package:quantumquiz/selected_gate_type.dart';


class PlacedQuantumGate {
  final SelectedGateType type;
  final int? targetQubitIndex;
  final bool isTarget;

  static PlacedQuantumGate emptyGate() => PlacedQuantumGate(type: SelectedGateType.none);

  PlacedQuantumGate({
    required this.type,
    this.targetQubitIndex,
    this.isTarget = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PlacedQuantumGate &&
              runtimeType == other.runtimeType &&
              type == other.type &&
              isTarget == other.isTarget &&
              targetQubitIndex == other.targetQubitIndex;

  @override
  int get hashCode =>
      type.hashCode ^
      isTarget.hashCode ^
      targetQubitIndex.hashCode;
}
