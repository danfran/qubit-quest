import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
import 'gate_id.dart';
import 'quantum_circuit.dart';
import 'quantum_matrix.dart';
import 'selected_gate_type.dart';

class InvalidCircuitProgram implements Exception {
  const InvalidCircuitProgram(this.message);
  final String message;
  @override
  String toString() => 'InvalidCircuitProgram: $message';
}

class NonUnitaryProgram implements Exception {
  const NonUnitaryProgram();
  @override
  String toString() =>
      'Measurement cannot be represented by one unitary matrix.';
}

@immutable
sealed class CircuitOperation {
  const CircuitOperation({required this.id, required this.column});
  final GateId id;
  final int column;
  bool get isOrderingBarrier => this is MeasureZOperation;
}

@immutable
final class UnitaryOperation extends CircuitOperation {
  const UnitaryOperation(
      {required super.id,
      required super.column,
      required this.gate,
      required this.target,
      this.control,
      this.secondControl,
      this.multiControls,
      this.isDeletable = true});
  final Gate gate;
  final int target;
  final int? control;
  final int? secondControl;

  /// Every control of a multi-controlled X (v2.6 M7); null otherwise.
  final List<int>? multiControls;

  /// All controls of this operation, however they are stored.
  List<int> get controls =>
      multiControls ??
      [
        if (control != null) control!,
        if (secondControl != null) secondControl!
      ];
  final bool isDeletable;
}

@immutable
final class MeasureZOperation extends CircuitOperation {
  const MeasureZOperation(
      {required super.id,
      required super.column,
      required this.qubit,
      required this.classicalBit});
  final int qubit;
  final int classicalBit;
}

/// Immutable execution snapshot, never a second editable circuit.
/// List order is execution order; columns must be nondecreasing. Operations in
/// one column act on disjoint qubits (measurements included), so they commute
/// and any order within the column is equivalent.
@immutable
class CircuitProgram {
  CircuitProgram(
      {required this.qubitCount,
      required this.classicalBitCount,
      required Iterable<Complex> initialState,
      required Iterable<CircuitOperation> operations})
      : _initial = List.unmodifiable(initialState
            .map((a) => (a.real.toDouble(), a.imaginary.toDouble()))),
        operations = List.unmodifiable(operations) {
    _validate();
  }
  final int qubitCount;
  final int classicalBitCount;
  final List<(double, double)> _initial;
  final List<CircuitOperation> operations;
  List<Complex> get initialState =>
      List.unmodifiable(_initial.map((a) => Complex(a.$1, a.$2)));
  bool get isUnitary => operations.every((o) => o is UnitaryOperation);

  /// Matrix construction remains the existing unitary engine's responsibility.
  /// Guard before calling it; no measurement is dropped or assigned a fake matrix.
  QuantumMatrix getUnitaryMatrix(
      QuantumMatrix Function(List<UnitaryOperation>) build) {
    if (!isUnitary) throw const NonUnitaryProgram();
    return build(List.unmodifiable(operations.cast<UnitaryOperation>()));
  }

  factory CircuitProgram.fromCircuit(QuantumCircuit circuit) {
    final gates = [...circuit.logicalGates]..sort((a, b) {
        final column = a.column.compareTo(b.column);
        if (column != 0) return column;
        final first = circuit.restoredOrderFor(a.id);
        final second = circuit.restoredOrderFor(b.id);
        return first != null && second != null
            ? first.compareTo(second)
            : a.anchor.qubit.compareTo(b.anchor.qubit);
      });
    if (gates.any((g) => !g.hasValidTopology(circuit.currentLevel.numQubits))) {
      throw const InvalidCircuitProgram('Malformed logical gate footprint');
    }
    return CircuitProgram(
        qubitCount: circuit.currentLevel.numQubits,
        classicalBitCount: circuit.classicalBitCount,
        initialState: circuit.initialState.stateVector,
        operations: (<CircuitOperation>[
          ...circuit.measurements,
          ...gates.map((g) => UnitaryOperation(
              id: g.id,
              column: g.column,
              gate: g.gate,
              target: g.targetQubit ?? g.anchor.qubit,
              control: g.controlQubit,
              secondControl: g.secondControlQubit,
              multiControls:
                  g.type == SelectedGateType.mcx ? g.controlQubits : null,
              isDeletable: g.isDeletable))
        ]..sort((a, b) {
            final column = a.column.compareTo(b.column);
            if (column != 0) return column;
            if (a is UnitaryOperation && b is UnitaryOperation) {
              return gates
                  .indexWhere((g) => g.id == a.id)
                  .compareTo(gates.indexWhere((g) => g.id == b.id));
            }
            // Same-column operations occupy disjoint qubit ranges, so the
            // topmost occupied qubit gives a deterministic total order.
            int topRow(CircuitOperation op) => switch (op) {
                  MeasureZOperation() => op.qubit,
                  UnitaryOperation() =>
                    [op.target, ...op.controls].reduce((x, y) => x < y ? x : y),
                };
            return topRow(a).compareTo(topRow(b));
          })));
  }

  void _validate() {
    Never invalid(String reason) => throw InvalidCircuitProgram(reason);
    // Vector length itself bounds dimensions without an unbounded bit shift.
    if (qubitCount < 1 ||
        classicalBitCount < 0 ||
        _initial.isEmpty ||
        _initial.length.bitLength - 1 != qubitCount ||
        (_initial.length & (_initial.length - 1)) != 0) {
      invalid('Invalid dimensions');
    }
    var norm = 0.0;
    for (final a in _initial) {
      if (!a.$1.isFinite || !a.$2.isFinite) invalid('Nonfinite amplitude');
      norm += a.$1 * a.$1 + a.$2 * a.$2;
    }
    if (!norm.isFinite || (norm - 1).abs() > 1e-6)
      invalid('Invalid state norm');
    final ids = <GateId>{};
    var previousColumn = -1;
    final occupied = <int>{};
    for (final op in operations) {
      if (!ids.add(op.id)) invalid('Duplicate operation identity');
      if (op.column < 0 || op.column < previousColumn)
        invalid('Invalid chronology');
      if (op.column != previousColumn) occupied.clear();
      final List<int> wires;
      switch (op) {
        case MeasureZOperation():
          if (op.classicalBit < 0 || op.classicalBit >= classicalBitCount) {
            invalid('Invalid classical destination');
          }
          wires = [op.qubit];
        case UnitaryOperation():
          if (const {
            SelectedGateType.none,
            SelectedGateType.delete,
            SelectedGateType.draggedGate,
            SelectedGateType.measureZ
          }.contains(op.gate.type)) invalid('Not a unitary gate');
          final validControls = switch (op.gate.type) {
            SelectedGateType.cnot ||
            SelectedGateType.cz ||
            SelectedGateType.cy =>
              op.control != null &&
                  op.secondControl == null &&
                  op.multiControls == null,
            SelectedGateType.ccnot => op.control != null &&
                op.secondControl != null &&
                op.multiControls == null,
            SelectedGateType.mcx => op.control == null &&
                op.secondControl == null &&
                (op.multiControls?.length ?? 0) >= 3,
            _ => op.control == null &&
                op.secondControl == null &&
                op.multiControls == null,
          };
          if (!validControls) invalid('Invalid controls');
          if (!op.gate.hasValidRequiredParameters ||
              (!op.gate.requiresAngle && op.gate.angle != null))
            invalid('Invalid angle');
          wires = [op.target, ...op.controls];
      }
      if (wires.toSet().length != wires.length ||
          wires.any((q) => q < 0 || q >= qubitCount || occupied.contains(q))) {
        invalid('Invalid or overlapping quantum operands');
      }
      occupied.addAll(wires);
      previousColumn = op.column;
    }
  }
}

@immutable
class ClassicalState {
  ClassicalState(int width)
      : this.fromBits(List<int?>.filled(
            width < 0
                ? throw const InvalidCircuitProgram('Negative register width')
                : width,
            null));
  ClassicalState.fromBits(Iterable<int?> bits)
      : bits = List.unmodifiable(bits) {
    if (this.bits.any((b) => b != null && b != 0 && b != 1)) {
      throw const InvalidCircuitProgram(
          'Classical values must be null, 0 or 1');
    }
  }
  final List<int?> bits;
  int get width => bits.length;
  String get label => bits.reversed.map((b) => b?.toString() ?? '?').join();
  ClassicalState write(int index, int value) {
    if (index < 0 || index >= width || (value != 0 && value != 1)) {
      throw const InvalidCircuitProgram('Invalid classical write');
    }
    return ClassicalState.fromBits([...bits]..[index] = value);
  }
}
