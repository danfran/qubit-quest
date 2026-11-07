import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  QuantumCircuit make() =>
      QuantumCircuit(currentLevel: createSandboxComposerLevel(2));
  final x = Gate.fromIdentifier(SelectedGateType.x);
  test('measurement identity, ordering, mapping and notifications', () {
    final c = make();
    addTearDown(c.dispose);
    var changes = 0;
    c.addListener(() => changes++);
    final later = c.addMeasurement(column: 3, qubit: 1, classicalBit: 4);
    final first = c.addMeasurement(column: 1, qubit: 0, classicalBit: 4);
    expect(c.measurements.map((m) => m.id), [first.id, later.id]);
    expect(first.id, isNot(later.id));
    expect(c.maxCircuitDepth(), 4);
    expect(() => c.measurements.clear(), throwsUnsupportedError);
    expect(c.removeMeasurement(first.id), true);
    expect(c.removeMeasurement(first.id), false);
    // Measurements are grid cells: removal compacts like gate removal, while
    // the remaining measurement keeps its ID, qubit and destination.
    final remaining = c.measurements.single;
    expect((remaining.id, remaining.qubit, remaining.classicalBit),
        (later.id, 1, 4));
    expect(remaining.column, 0);
    expect(changes, 3);
    final next = c.addMeasurement(column: 1, qubit: 0, classicalBit: 0);
    expect(next.id, isNot(first.id));
  });
  test('measurements share columns; occupied slots and bad operands reject',
      () {
    final c = make();
    addTearDown(c.dispose);
    c.insertSingleGateWithOutcome(x, 0, 0);
    final shared = c.addMeasurement(column: 0, qubit: 1, classicalBit: 0);
    expect(shared.column, 0, reason: 'different qubits may share a column');
    expect(() => c.addMeasurement(column: 0, qubit: 0, classicalBit: 1),
        throwsA(isA<InvalidCircuitProgram>()));
    // Terminal measurement: q1 cannot receive a later gate.
    final rejected = c.insertSingleGateWithOutcome(x, 1, 1);
    expect(rejected.changed, false);
    expect(rejected.detail, QuantumCircuit.terminalMeasurementReason);
    for (final args in [(-1, 0, 0), (2, 2, 0), (2, 0, -1)]) {
      expect(
          () => c.addMeasurement(
              column: args.$1, qubit: args.$2, classicalBit: args.$3),
          throwsA(isA<InvalidCircuitProgram>()));
    }
    expect(c.measurements.length, 1);
    expect(c.logicalGates.length, 1);
  });
  test('measurements compact with gates; removal compacts like gates', () {
    final c = make();
    addTearDown(c.dispose);
    c.addMeasurement(column: 2, qubit: 0, classicalBit: 0);
    expect(c.measurements.single.column, 2, reason: 'raw placement is exact');
    final gate = c.insertSingleGateWithOutcome(x, 7, 1).affectedGateId!;
    expect(c.logicalGateById(gate)!.column, 0);
    expect(c.measurements.single.column, 0);
    c.removeMeasurement(c.measurements.single.id);
    expect(c.logicalGateById(gate)!.column, 0);
    expect(c.hasMeasurements, false);
  });
  test('mixed adaptation preserves IDs, columns, initial state and register',
      () {
    final c = make();
    addTearDown(c.dispose);
    final a = c.insertSingleGateWithOutcome(x, 0, 0).affectedGateId!;
    final b = c
        .insertDoubleGateWithOutcome(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0)
        .affectedGateId!;
    final m = c
        .insertMeasurementWithOutcome(qubit: 1, column: 2, classicalBit: 3)
        .affectedGateId!;
    final end = c
        .insertMeasurementWithOutcome(qubit: 0, column: 2, classicalBit: 2)
        .affectedGateId!;
    final p = CircuitProgram.fromCircuit(c);
    // Same-column operations are ordered by qubit, deterministically.
    expect(p.operations.map((o) => o.id), [a, b, end, m]);
    expect(p.operations.map((o) => o.column), [0, 1, 2, 2]);
    expect(p.classicalBitCount, 4);
    expect(p.initialState, c.initialState.stateVector);
    expect((p.operations[1] as UnitaryOperation).control, 0);
    expect((p.operations[1] as UnitaryOperation).target, 1);
  });
  test('matrix and simulation reject without changing prior state or run count',
      () {
    final c = make();
    addTearDown(c.dispose);
    final before = c.currentState;
    final runs = c.simulationRunCount;
    c.addMeasurement(column: 0, qubit: 0, classicalBit: 0);
    expect(c.getOverallCircuitMatrix, throwsA(isA<NonUnitaryProgram>()));
    expect(c.runSimulation, throwsA(isA<NonUnitaryProgram>()));
    expect(c.currentState, same(before));
    expect(c.simulationRunCount, runs);
  });
  test('schema one capture rejects and leaves prior snapshot intact', () {
    final c = make();
    addTearDown(c.dispose);
    c.insertSingleGateWithOutcome(x, 0, 0);
    final snapshot = SandboxCircuitSnapshot.capture(c);
    final encoded = snapshot.encode();
    c.addMeasurement(column: 1, qubit: 0, classicalBit: 0);
    expect(() => SandboxCircuitSnapshot.capture(c),
        throwsA(isA<NonUnitaryProgram>()));
    expect(snapshot.encode(), encoded);
    final restored = snapshot.restoreCircuit();
    addTearDown(restored.dispose);
    expect(restored.hasMeasurements, false);
    expect(restored.logicalGates.length, 1);
  });
  test('stale plans are cancelled; moves cannot pass a terminal measurement',
      () {
    final c = make();
    addTearDown(c.dispose);
    final id = c.insertSingleGateWithOutcome(x, 0, 0).affectedGateId!;
    final plan =
        c.planLogicalGateMove(id, const CircuitLocation(qubit: 1, column: 0));
    c.addMeasurement(column: 1, qubit: 0, classicalBit: 0);
    expect(c.commitLogicalGateMovePlan(plan).changed, false);
    final afterMeasurement =
        c.planLogicalGateMove(id, const CircuitLocation(qubit: 0, column: 2));
    expect(afterMeasurement.changed, false);
    expect(afterMeasurement.reason, QuantumCircuit.terminalMeasurementReason);
    expect(c.logicalGateById(id)!.column, 0);
    // Moving to an unmeasured qubit is a normal edit.
    expect(
        c
            .planLogicalGateMove(id, const CircuitLocation(qubit: 1, column: 0))
            .changed,
        true);
  });
  test(
      'clear removes measurements and unitary-only adaptation remains unchanged',
      () {
    final c = make();
    addTearDown(c.dispose);
    c.addMeasurement(column: 0, qubit: 1, classicalBit: 0);
    c.clearPlacedGates();
    expect(c.isCircuitEmpty(), true);
    expect(c.measurements, isEmpty);
    c.insertSingleGateWithOutcome(x, 8, 1);
    expect(c.logicalGates.single.column, 0);
    expect(CircuitProgram.fromCircuit(c).classicalBitCount, 0);
    c.runSimulation();
    expect(SandboxCircuitSnapshot.capture(c).operations.length, 1);
  });
}
