import 'dart:io';
import 'dart:math' as math;
import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_executor.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';

CircuitProgram p(List<CircuitOperation> ops,
        {int n = 1, int c = 1, List<Complex>? state}) =>
    CircuitProgram(
        qubitCount: n,
        classicalBitCount: c,
        initialState:
            state ?? List.generate(1 << n, (i) => Complex(i == 0 ? 1 : 0, 0)),
        operations: ops);
MeasureZOperation m(int col, {int q = 0, int c = 0}) => MeasureZOperation(
    id: GateId(col + 1), column: col, qubit: q, classicalBit: c);
UnitaryOperation g(int col, SelectedGateType type,
        {int q = 0, int? control, int? second, double? angle}) =>
    UnitaryOperation(
        id: GateId(col + 1),
        column: col,
        target: q,
        control: control,
        secondControl: second,
        gate: Gate.fromIdentifier(type, angle: angle));
void vector(List<Complex> actual, List<Complex> expected) {
  expect(actual.length, expected.length);
  for (var i = 0; i < actual.length; i++) {
    expect(actual[i].real, closeTo(expected[i].real, 1e-10));
    expect(actual[i].imaginary, closeTo(expected[i].imaginary, 1e-10));
  }
}

void main() {
  for (final bit in [0, 1]) {
    test('basis $bit never samples impossible outcome', () {
      final r = CircuitExecutor(
              nextDouble: () => throw StateError('unnecessary draw'))
          .runShot(p([m(0)], state: [Complex(1 - bit, 0), Complex(bit, 0)]));
      expect(r.classicalState.label, '$bit');
      vector(r.quantumState, [Complex(1 - bit, 0), Complex(bit, 0)]);
    });
  }
  for (final sample in [0.0, 0.9]) {
    test('plus collapse for sample $sample', () {
      final r = CircuitExecutor(nextDouble: () => sample)
          .runShot(p([g(0, SelectedGateType.hadamard), m(1)]));
      final b = sample < 0.5 ? 0 : 1;
      expect(r.classicalState.label, '$b');
      vector(r.quantumState, [Complex(1 - b, 0), Complex(b, 0)]);
    });
  }
  test('repeat measurement consumes no new random draw', () {
    var draws = 0;
    final r = CircuitExecutor(nextDouble: () {
      draws++;
      return .8;
    }).runShot(p([g(0, SelectedGateType.hadamard), m(1), m(2, c: 1)], c: 2));
    expect(r.classicalState.label, '11');
    expect(draws, 1);
  });
  test('H measure H measure uses collapsed state', () {
    final samples = [.9, .1].iterator;
    final r = CircuitExecutor(nextDouble: () {
      samples.moveNext();
      return samples.current;
    }).runShot(p([
      g(0, SelectedGateType.hadamard),
      m(1),
      g(2, SelectedGateType.hadamard),
      m(3, c: 1)
    ], c: 2));
    expect(r.classicalState.label, '01');
    vector(r.quantumState, [Complex.one(), Complex.zero()]);
  });
  test('Bell measurement projects entire joint state', () {
    final r = CircuitExecutor(nextDouble: () => .9).runShot(p([
      g(0, SelectedGateType.hadamard),
      g(1, SelectedGateType.cnot, q: 1, control: 0),
      m(2)
    ], n: 2));
    vector(r.quantumState,
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()]);
  });
  test('Bell shots only correlate and start fresh', () {
    var draw = 0;
    final r =
        CircuitExecutor(nextDouble: () => draw++ % 2 == 0 ? 0.1 : 0.9).runShots(
            p([
              g(0, SelectedGateType.hadamard),
              g(1, SelectedGateType.cnot, q: 1, control: 0),
              m(2),
              m(3, q: 1, c: 1)
            ], n: 2, c: 2),
            shots: 20);
    expect(r.counts, {'00': 10, '11': 10});
    expect(r.shots, 20);
  });
  test('unitary after measurement and last write wins', () {
    final r =
        CircuitExecutor().runShot(p([m(0), g(1, SelectedGateType.x), m(2)]));
    expect(r.classicalState.label, '1');
  });
  test('unwritten bits and ordering are explicit', () {
    final r = CircuitExecutor().runShot(p(
        [g(0, SelectedGateType.x, q: 1), m(1, q: 1, c: 2), m(2, q: 0, c: 0)],
        n: 2, c: 3));
    expect(r.classicalState.label, '1?0');
    expect(r.classicalState.bits, [0, null, 1]);
  });
  test('surviving relative complex phase is preserved', () {
    final s = 1 / math.sqrt(2);
    final state = [
      Complex(s, 0),
      Complex.zero(),
      Complex(0, s),
      Complex.zero()
    ];
    final r = CircuitExecutor().runShot(p([m(0)], n: 2, state: state));
    vector(r.quantumState, state);
  });
  test('fixture execution matches existing complete operator', () {
    final circuit = SandboxCircuitSnapshot.decode(
            File('test/fixtures/operation_contract/unitary_schema1.json')
                .readAsStringSync())
        .restoreCircuit();
    final program = CircuitProgram.fromCircuit(circuit);
    final matrix = circuit.getOverallCircuitMatrix().toComplexList();
    final expected = List.generate(matrix.length, (i) {
      var a = Complex.zero();
      for (var j = 0; j < matrix.length; j++) {
        a += matrix[i][j] * program.initialState[j];
      }
      return a;
    });
    vector(CircuitExecutor().runShot(program).quantumState, expected);
    circuit.dispose();
  });
  for (final type in [
    SelectedGateType.rx,
    SelectedGateType.ry,
    SelectedGateType.rz
  ]) {
    test('$type inverse survives measurement boundary', () {
      final r = CircuitExecutor()
          .runShot(p([m(0), g(1, type, angle: .71), g(2, type, angle: -.71)]));
      vector(r.quantumState, [Complex.one(), Complex.zero()]);
    });
  }
  test('reversed and double controls use actual operand indices', () {
    final r = CircuitExecutor().runShot(p([
      g(0, SelectedGateType.x, q: 2),
      g(1, SelectedGateType.cnot, q: 0, control: 2),
      g(2, SelectedGateType.ccnot, q: 1, control: 2, second: 0),
      g(3, SelectedGateType.cz, q: 0, control: 1)
    ], n: 3));
    vector(
        r.quantumState, List.generate(8, (i) => Complex(i == 7 ? -1 : 0, 0)));
  });
  test('seeded counts reproducible with explicit unwritten bits', () {
    final program = p([g(0, SelectedGateType.hadamard), m(1)], c: 2);
    final a = CircuitExecutor(nextDouble: math.Random(42).nextDouble)
        .runShots(program, shots: 100);
    final b = CircuitExecutor(nextDouble: math.Random(42).nextDouble)
        .runShots(program, shots: 100);
    expect(a.counts, b.counts);
    expect(a.counts.values.reduce((a, b) => a + b), 100);
    expect(a.counts.keys, unorderedEquals(['?0', '?1']));
  });
  test('invalid dimensions and nonfinite/materially invalid states rejected',
      () {
    for (final s in [
      [Complex(double.nan, 0), Complex.zero()],
      [Complex(2, 0), Complex.zero()],
      [Complex.one()]
    ]) {
      expect(() => p([], state: s), throwsA(isA<InvalidCircuitProgram>()));
    }
  });
  test('invalid random output is controlled failure', () {
    for (final u in [double.nan, double.infinity, -.1, 1.0]) {
      expect(
          () => CircuitExecutor(nextDouble: () => u)
              .runShot(p([g(0, SelectedGateType.hadamard), m(1)])),
          throwsA(isA<CircuitExecutionException>()));
    }
  });
  test('small normalization drift tolerated but tiny nonzero branch retained',
      () {
    final r = CircuitExecutor(nextDouble: () => 0)
        .runShot(p([m(0)], state: [Complex(1e-12, 0), Complex(1, 0)]));
    expect(r.classicalState.label, '0');
    vector(r.quantumState, [Complex.one(), Complex.zero()]);
    final drift = CircuitExecutor().runShot(
        p([], state: [Complex(math.sqrt(1 + 1e-8), 0), Complex.zero()]));
    vector(drift.quantumState, [Complex.one(), Complex.zero()]);
  });
  test('execution limits are explicit', () {
    for (final count in [0, -1, 10001]) {
      expect(() => CircuitExecutor().runShots(p([]), shots: count),
          throwsA(isA<CircuitExecutionException>()));
    }
    expect(() => CircuitExecutor().runShot(p([], n: 11)),
        throwsA(isA<CircuitExecutionException>()));
    expect(() => CircuitExecutor().runShots(p([m(0)], n: 10), shots: 10000),
        throwsA(isA<CircuitExecutionException>()));
  });
  test('result snapshots and counts immutable; matrix boundary preserved', () {
    final program = p([m(0)]);
    final r = CircuitExecutor().runShot(program);
    expect(() => r.quantumState.add(Complex.one()), throwsUnsupportedError);
    expect(() => CircuitExecutor().runShots(program, shots: 1).counts['0'] = 2,
        throwsUnsupportedError);
    expect(
        () => program.getUnitaryMatrix((_) => throw StateError('must not run')),
        throwsA(isA<NonUnitaryProgram>()));
  });
}
