import 'dart:io';
import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  CircuitProgram program(List<CircuitOperation> ops, {int classical = 1}) =>
      CircuitProgram(
          qubitCount: 1,
          classicalBitCount: classical,
          initialState: [Complex.one(), Complex.zero()],
          operations: ops);
  UnitaryOperation x(int id, int column, {int target = 0}) => UnitaryOperation(
      id: GateId(id),
      column: column,
      target: target,
      gate: Gate.fromIdentifier(SelectedGateType.x));
  const m =
      MeasureZOperation(id: GateId(2), column: 1, qubit: 0, classicalBit: 0);
  test(
      'schema 1 fixture adapts losslessly with stable identity and no simulation',
      () {
    // Current repository schema evidence, not a claimed exported release artifact.
    final encoded =
        File('test/fixtures/operation_contract/unitary_schema1.json')
            .readAsStringSync();
    final snapshot = SandboxCircuitSnapshot.decode(encoded);
    final circuit = snapshot.restoreCircuit();
    final runs = circuit.simulationRunCount;
    final p = CircuitProgram.fromCircuit(circuit);
    final ops = p.operations.cast<UnitaryOperation>();
    expect(ops.map((o) => o.id.value), [1, 2, 3, 4]);
    expect(ops.map((o) => o.column), [0, 1, 2, 3]);
    expect(ops.map((o) => o.gate.type), [
      SelectedGateType.hadamard,
      SelectedGateType.rx,
      SelectedGateType.cnot,
      SelectedGateType.ccnot
    ]);
    expect(ops.map((o) => o.target), [0, 0, 1, 2]);
    expect(ops.map((o) => o.control), [null, null, 0, 0]);
    expect(ops.map((o) => o.secondControl), [null, null, null, 1]);
    expect(ops.elementAt(1).gate.angle, 0.375);
    expect(p.classicalBitCount, 0);
    expect(p.initialState.first, Complex.one());
    expect(
        p
            .getUnitaryMatrix((_) => circuit.getOverallCircuitMatrix())
            .toComplexList(),
        circuit.getOverallCircuitMatrix().toComplexList());
    expect(circuit.simulationRunCount, runs);
    expect(SandboxCircuitSnapshot.capture(circuit).toJson(), snapshot.toJson());
    final again = CircuitProgram.fromCircuit(circuit);
    expect(again.operations.map((o) => o.id), ops.map((o) => o.id));
    circuit.dispose();
  });
  test('snapshots own lists and protect initial amplitudes', () {
    final state = [Complex.one(), Complex.zero()];
    final ops = <CircuitOperation>[x(1, 0)];
    final p = CircuitProgram(
        qubitCount: 1,
        classicalBitCount: 0,
        initialState: state,
        operations: ops);
    state[0] = Complex.zero();
    ops.clear();
    expect(p.initialState.first, Complex.one());
    expect(p.operations, hasLength(1));
    expect(() => p.operations.clear(), throwsUnsupportedError);
    expect(() => p.initialState.clear(), throwsUnsupportedError);
  });
  test('measurement is barrier and unitary builder is never invoked', () {
    final p = program([x(1, 0), m, x(3, 2)]);
    expect(p.isUnitary, false);
    expect(m.isOrderingBarrier, true);
    expect(() => p.getUnitaryMatrix((_) => fail('must not execute')),
        throwsA(isA<NonUnitaryProgram>()));
    expect(
        program([])
            .getUnitaryMatrix((_) => QuantumMatrix.identity(2))
            .toComplexList(),
        QuantumMatrix.identity(2).toComplexList());
  });
  test(
      'invalid chronology, barriers, overlapping operands and duplicate ids rejected',
      () {
    for (final ops in [
      [m, x(1, 0)],
      [x(1, 0), x(1, 2)],
      [x(1, 0), x(3, 0)],
      [m, x(3, 1)],
      [x(1, 1), m],
      [x(1, -1)],
      [x(1, 0, target: 1)]
    ]) {
      expect(() => program(ops), throwsA(isA<InvalidCircuitProgram>()));
    }
  });
  test('invalid state dimensions and normalization rejected', () {
    for (final state in [
      <Complex>[],
      [Complex.one()],
      [Complex.zero(), Complex.zero()],
      [Complex(double.nan), Complex.zero()]
    ]) {
      expect(
          () => CircuitProgram(
              qubitCount: 1,
              classicalBitCount: 0,
              initialState: state,
              operations: []),
          throwsA(isA<InvalidCircuitProgram>()));
    }
    expect(() => program([], classical: -1),
        throwsA(isA<InvalidCircuitProgram>()));
  });
  test('invalid gate metadata and measurement mapping rejected', () {
    for (final op in [
      UnitaryOperation(
          id: const GateId(1),
          column: 0,
          target: 0,
          gate: Gate.fromIdentifier(SelectedGateType.cnot)),
      UnitaryOperation(
          id: const GateId(1),
          column: 0,
          target: 0,
          gate: Gate.fromIdentifier(SelectedGateType.rx)),
      UnitaryOperation(
          id: const GateId(1),
          column: 0,
          target: 0,
          gate: Gate.fromIdentifier(SelectedGateType.none)),
      const MeasureZOperation(
          id: GateId(1), column: 0, qubit: 0, classicalBit: 1)
    ]) {
      expect(() => program([op]), throwsA(isA<InvalidCircuitProgram>()));
    }
  });
  test('register nulls, labels, immutable writes and overwrite semantics', () {
    final initial = ClassicalState(3);
    final written = initial.write(0, 1).write(2, 0);
    expect(initial.label, '???');
    expect(written.label, '0?1');
    expect(written.write(0, 0).label, '0?0');
    expect(() => written.bits.clear(), throwsUnsupportedError);
    for (final action in [
      () => ClassicalState(-1),
      () => ClassicalState.fromBits([2]),
      () => written.write(3, 1),
      () => written.write(0, 2)
    ]) {
      expect(action, throwsA(isA<InvalidCircuitProgram>()));
    }
  });
  test(
      'repeated classical writes remain in explicit order without quantum wires',
      () {
    final p = program([
      m,
      const MeasureZOperation(
          id: GateId(3), column: 2, qubit: 0, classicalBit: 0)
    ]);
    expect(p.operations.map((o) => o.id.value), [2, 3]);
    expect(p.qubitCount, 1);
    expect(p.classicalBitCount, 1);
    expect(x(9, 0).id, x(9, 8).id);
  });
}
