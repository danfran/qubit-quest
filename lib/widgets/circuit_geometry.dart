import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';

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
    final center = Offset(
      QuantumCircuitPainter.padding +
          location.column * QuantumCircuitPainter.gateSpacing +
          QuantumCircuitPainter.gateSpacing / 2,
      QuantumCircuitPainter.qubitCenterYFor(location.qubit),
    );
    return Rect.fromCenter(
      center: center,
      width: QuantumCircuitPainter.gateSize,
      height: QuantumCircuitPainter.gateSize,
    );
  }

  static Rect? logicalGateBounds(QuantumCircuit circuit, GateId id) {
    final source = circuit.placedGateById(id);
    if (source == null) return null;
    if (source.isSingleQubit) return singleGateBounds(source.location);

    final locations = <CircuitLocation>[];
    for (final (qubit, row) in circuit.placedGates.indexed) {
      for (final (column, gate) in row.indexed) {
        if (gate.id == id) {
          locations.add(CircuitLocation(qubit: qubit, column: column));
        }
      }
    }
    if (locations.isEmpty) return null;

    final centerX = QuantumCircuitPainter.padding +
        locations.first.column * QuantumCircuitPainter.gateSpacing +
        QuantumCircuitPainter.gateSpacing / 2;
    final centersY = locations
        .map(
            (location) => QuantumCircuitPainter.qubitCenterYFor(location.qubit))
        .toList();
    final extent = QuantumCircuitPainter.targetRadius + 4;
    return Rect.fromLTRB(
      centerX - extent,
      centersY.reduce((a, b) => a < b ? a : b) - extent,
      centerX + extent,
      centersY.reduce((a, b) => a > b ? a : b) + extent,
    );
  }

  static PlacedGateRef? hitTestGate(QuantumCircuit circuit, Offset position) {
    final seenIds = <GateId>{};
    for (final row in circuit.placedGates) {
      for (final placedGate in row) {
        if (placedGate.gate.type == SelectedGateType.none ||
            placedGate.id == null ||
            !seenIds.add(placedGate.id!)) {
          continue;
        }
        final bounds = logicalGateBounds(circuit, placedGate.id!)?.inflate(3);
        if (bounds == null) continue;
        if (!bounds.contains(position)) continue;
        return circuit.placedGateById(placedGate.id!);
      }
    }
    return null;
  }
}
