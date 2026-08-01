import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

@immutable
class CircuitLocation {
  final int qubit;
  final int column;

  const CircuitLocation({required this.qubit, required this.column});

  @override
  bool operator ==(Object other) =>
      other is CircuitLocation &&
      other.qubit == qubit &&
      other.column == column;

  @override
  int get hashCode => Object.hash(qubit, column);
}

@immutable
class PlacedGateRef {
  final GateId id;
  final Gate gate;
  final CircuitLocation location;
  final bool isDeletable;
  final bool isSingleQubit;

  const PlacedGateRef({
    required this.id,
    required this.gate,
    required this.location,
    required this.isDeletable,
    required this.isSingleQubit,
  });

  bool get isMovable => isSingleQubit && isDeletable;
}

enum MoveResult { moved, sameSlot, invalid, notFound, notMovable }

enum RemoveGateResult { removed, notFound, notDeletable, notSingleQubit }

enum CircuitDragSource { palette, placed }

@immutable
class CircuitDragData {
  final CircuitDragSource source;
  final Gate gate;
  final GateId? sourceId;

  const CircuitDragData.palette(this.gate)
      : source = CircuitDragSource.palette,
        sourceId = null;

  const CircuitDragData.placed({required this.sourceId, required this.gate})
      : source = CircuitDragSource.placed;

  bool get isPlaced => source == CircuitDragSource.placed;
}
