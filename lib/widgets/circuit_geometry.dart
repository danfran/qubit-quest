import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/widgets/circuit_layout_metrics.dart';

@immutable
class CircuitDropDestination {
  final Offset contentPoint;
  final CircuitLocation location;

  const CircuitDropDestination({
    required this.contentPoint,
    required this.location,
  });
}

class CircuitCoordinateMapper {
  const CircuitCoordinateMapper._();

  static Offset viewportToContent(
    Offset viewportPoint, {
    required double horizontalScrollOffset,
  }) {
    assert(horizontalScrollOffset >= 0);
    return Offset(
      viewportPoint.dx + horizontalScrollOffset,
      viewportPoint.dy,
    );
  }
}

class CircuitGeometry {
  const CircuitGeometry._();

  static bool isClearlyOutsideCircuitForDeletion({
    required Rect circuitBounds,
    required Offset pointerPosition,
    double safetyMargin = 12,
  }) {
    assert(safetyMargin >= 0);
    return !circuitBounds.inflate(safetyMargin).contains(pointerPosition);
  }

  static Rect singleGateBounds(CircuitLocation location) {
    final center = CircuitLayoutMetrics.slotCenter(location);
    return Rect.fromCenter(
      center: center,
      width: CircuitLayoutMetrics.gateSize,
      height: CircuitLayoutMetrics.gateSize,
    );
  }

  static int? qubitForPoint(Offset point, int qubitCount) {
    for (int qubit = 0; qubit < qubitCount; qubit++) {
      final center = CircuitLayoutMetrics.wireCenterY(qubit);
      if (point.dy >= center - CircuitLayoutMetrics.hitTolerance &&
          point.dy <= center + CircuitLayoutMetrics.hitTolerance) {
        return qubit;
      }
    }
    return null;
  }

  static int insertionColumnForPoint(Offset point) {
    final relativeX = point.dx - CircuitLayoutMetrics.padding;
    return (relativeX / CircuitLayoutMetrics.gateSpacing)
        .floor()
        .clamp(0, 1 << 30);
  }

  static CircuitDropDestination? dropDestinationForPoint({
    required QuantumCircuit circuit,
    required Offset contentPoint,
  }) {
    final qubit = qubitForPoint(
      contentPoint,
      circuit.currentLevel.numQubits,
    );
    if (qubit == null) return null;
    final column = circuit.isCircuitEmpty()
        ? 0
        : insertionColumnForPoint(contentPoint)
            .clamp(0, circuit.maxCircuitDepth());
    return CircuitDropDestination(
      contentPoint: contentPoint,
      location: CircuitLocation(qubit: qubit, column: column),
    );
  }

  static double contentWidth(QuantumCircuit circuit,
      {int trailingColumns = 3}) {
    if (circuit.isCircuitEmpty()) {
      return CircuitLayoutMetrics.contentWidthForDepth(0, trailingColumns: 2);
    }
    final depth = circuit.maxCircuitDepth();
    return CircuitLayoutMetrics.contentWidthForDepth(
      depth,
      trailingColumns: trailingColumns,
    );
  }

  static List<List<PlacedQuantumGate>> insertionPreview({
    required QuantumCircuit circuit,
    required CircuitDropDestination destination,
    required Gate gate,
  }) {
    final preview = circuit.placedGates
        .map((row) => List<PlacedQuantumGate>.from(row))
        .toList();
    final qubit = destination.location.qubit;
    final column = destination.location.column;
    final marker = PlacedQuantumGate(
      gate: Gate.fromIdentifier(SelectedGateType.draggedGate),
    );
    if (gate.type == SelectedGateType.cnot ||
        gate.type == SelectedGateType.cz ||
        gate.type == SelectedGateType.ccnot) {
      for (final row in preview) {
        while (row.length < column) {
          row.add(PlacedQuantumGate.emptyGate());
        }
        row.insert(column.clamp(0, row.length), marker);
      }
      return preview;
    }
    final row = preview[qubit];
    while (row.length < column) {
      row.add(PlacedQuantumGate.emptyGate());
    }
    if (column < row.length && row[column].gate.type == SelectedGateType.none) {
      row[column] = marker;
    } else {
      row.insert(column.clamp(0, row.length), marker);
    }
    return preview;
  }

  static List<List<PlacedQuantumGate>>? logicalGateMovePreview({
    required QuantumCircuit circuit,
    required GateId gateId,
    required int destinationColumn,
  }) {
    return circuit.previewLogicalGateHorizontalMove(
      gateId,
      destinationColumn,
    );
  }

  static Rect? logicalGateBounds(QuantumCircuit circuit, GateId id) {
    final footprint = circuit.logicalGateById(id);
    if (footprint == null) return null;
    if (footprint.isSingleQubit) return singleGateBounds(footprint.anchor);
    final locations = footprint.occupiedLocations;

    final centerX = CircuitLayoutMetrics.slotCenter(locations.first).dx;
    final centersY = locations
        .map((location) => CircuitLayoutMetrics.wireCenterY(location.qubit))
        .toList();
    final extent = CircuitLayoutMetrics.targetRadius + 4;
    return Rect.fromLTRB(
      centerX - extent,
      centersY.reduce((a, b) => a < b ? a : b) - extent,
      centerX + extent,
      centersY.reduce((a, b) => a > b ? a : b) + extent,
    );
  }

  static PlacedGateRef? hitTestGate(QuantumCircuit circuit, Offset position) {
    for (final footprint in circuit.logicalGates) {
      final bounds = logicalGateBounds(circuit, footprint.id)?.inflate(3);
      if (bounds != null && bounds.contains(position)) {
        return footprint.toPlacedGateRef();
      }
    }
    return null;
  }
}
