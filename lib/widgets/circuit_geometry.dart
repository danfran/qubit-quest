import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
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

  static PlacedGateRef? hitTestGate(QuantumCircuit circuit, Offset position) {
    for (final (qubit, row) in circuit.placedGates.indexed) {
      for (final (column, placedGate) in row.indexed) {
        if (placedGate.gate.type == SelectedGateType.none ||
            placedGate.id == null) {
          continue;
        }
        final location = CircuitLocation(qubit: qubit, column: column);
        final isSingle = !placedGate.isControl &&
            !placedGate.isControl2 &&
            !placedGate.isTarget &&
            !placedGate.isLink &&
            placedGate.gate.type != SelectedGateType.cnot &&
            placedGate.gate.type != SelectedGateType.cz &&
            placedGate.gate.type != SelectedGateType.ccnot;
        final bounds = isSingle
            ? singleGateBounds(location).inflate(3)
            : Rect.fromCircle(
                center: Offset(
                  QuantumCircuitPainter.padding +
                      column * QuantumCircuitPainter.gateSpacing +
                      QuantumCircuitPainter.gateSpacing / 2,
                  QuantumCircuitPainter.qubitCenterYFor(qubit),
                ),
                radius: QuantumCircuitPainter.targetRadius + 3,
              );
        if (!bounds.contains(position)) continue;
        return circuit.placedGateById(placedGate.id!);
      }
    }
    return null;
  }
}
