import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
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
  final bool canMoveHorizontally;

  const PlacedGateRef({
    required this.id,
    required this.gate,
    required this.location,
    required this.isDeletable,
    required this.isSingleQubit,
    required this.canMoveHorizontally,
  });

  bool get isMovable => canMoveHorizontally && isDeletable;
}

enum CircuitEditStatus {
  changed,
  same,
  invalid,
  notFound,
  protected,
  unsupported,
  cancelled,
}

@immutable
class CircuitEditOutcome {
  final CircuitEditStatus status;
  final GateId? affectedGateId;
  final CircuitLocation? resultingLocation;
  final String? detail;

  const CircuitEditOutcome(
    this.status, {
    this.affectedGateId,
    this.resultingLocation,
    this.detail,
  });

  bool get changed => status == CircuitEditStatus.changed;

  static const same = CircuitEditOutcome(CircuitEditStatus.same);
  static const invalid = CircuitEditOutcome(CircuitEditStatus.invalid);
  static const notFound = CircuitEditOutcome(CircuitEditStatus.notFound);
  static const protected = CircuitEditOutcome(CircuitEditStatus.protected);
  static const unsupported = CircuitEditOutcome(CircuitEditStatus.unsupported);
  static const cancelled = CircuitEditOutcome(CircuitEditStatus.cancelled);
}

@immutable
class LogicalMovePlan {
  final CircuitEditStatus status;
  final GateId sourceId;
  final CircuitLocation? resultingLocation;
  final List<List<PlacedQuantumGate>> baseRows;
  final List<List<PlacedQuantumGate>>? proposedRows;
  final String? reason;

  const LogicalMovePlan({
    required this.status,
    required this.sourceId,
    required this.baseRows,
    this.resultingLocation,
    this.proposedRows,
    this.reason,
  });

  bool get changed => status == CircuitEditStatus.changed;

  CircuitEditOutcome get outcome => CircuitEditOutcome(
        status,
        affectedGateId: sourceId,
        resultingLocation: resultingLocation,
        detail: reason,
      );
}

@immutable
class LogicalDuplicationPlan {
  final CircuitEditStatus status;
  final GateId sourceId;
  final GateId? duplicateId;
  final CircuitLocation? resultingLocation;
  final List<List<PlacedQuantumGate>> baseRows;
  final List<List<PlacedQuantumGate>>? proposedRows;
  final String? reason;

  const LogicalDuplicationPlan({
    required this.status,
    required this.sourceId,
    required this.baseRows,
    this.duplicateId,
    this.resultingLocation,
    this.proposedRows,
    this.reason,
  });

  bool get changed => status == CircuitEditStatus.changed;

  CircuitEditOutcome get outcome => CircuitEditOutcome(
        status,
        affectedGateId: changed ? duplicateId : sourceId,
        resultingLocation: resultingLocation,
        detail: reason,
      );
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
