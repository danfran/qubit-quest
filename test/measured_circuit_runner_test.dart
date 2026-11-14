// Phase W4: quantum correctness of measured-circuit execution and readout.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_executor.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

final _h = Gate.fromIdentifier(SelectedGateType.hadamard);
final _x = Gate.fromIdentifier(SelectedGateType.x);
final _cnot = Gate.fromIdentifier(SelectedGateType.cnot);

QuantumCircuit _make(int n) =>
    QuantumCircuit(currentLevel: createSandboxComposerLevel(n));

MeasuredCircuitRunner _seeded([int seed = 7]) => MeasuredCircuitRunner(
    executor: CircuitExecutor(nextDouble: Random(seed).nextDouble));

void main() {
  test('X then M is deterministically 1', () {
    final c = _make(1)..insertSingleGateWithOutcome(_x, 0, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    final program = CircuitProgram.fromCircuit(c);
    final runner = _seeded();
    for (var i = 0; i < 20; i++) {
      final once = runner.runOnce(program);
      expect(once.outcome, '1');
      expect(once.register, 'c0=1');
      expect(once.readings.single.value, 1);
    }
    expect(runner.runShots(program, shots: 1000).counts, {'1': 1000});
    c.dispose();
  });

  test('H then M is approximately 50/50 over many shots', () {
    final c = _make(1)..insertSingleGateWithOutcome(_h, 0, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    final result =
        _seeded(42).runShots(CircuitProgram.fromCircuit(c), shots: 10000);
    expect(result.shots, 10000);
    expect(result.counts.keys, ['0', '1']);
    expect(result.counts.values.reduce((a, b) => a + b), 10000);
    for (final count in result.counts.values) {
      expect(count / 10000, closeTo(.5, .03));
    }
    c.dispose();
  });

  test('Bell state outcomes are perfectly correlated', () {
    final c = _make(2)
      ..insertSingleGateWithOutcome(_h, 0, 0)
      ..insertDoubleGateWithOutcome(_cnot, 1, 1, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 2);
    c.insertMeasurementWithOutcome(qubit: 1, column: 2);
    final result =
        _seeded(3).runShots(CircuitProgram.fromCircuit(c), shots: 2000);
    expect(result.readout.orderLabel, 'c1 c0');
    expect(result.counts.keys.toSet(), {'00', '11'});
    for (final count in result.counts.values) {
      expect(count / 2000, closeTo(.5, .05));
    }
    c.dispose();
  });

  test('classical destinations drive the readout and label order', () {
    final c = _make(2)..insertSingleGateWithOutcome(_x, 0, 1);
    c.insertMeasurementWithOutcome(qubit: 1, column: 1, classicalBit: 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 1, classicalBit: 2);
    final program = CircuitProgram.fromCircuit(c);
    final once = _seeded().runOnce(program);
    // Highest classical bit on the left; c1 is never written and omitted.
    expect(once.readout.bits, [2, 0]);
    expect(once.outcome, '01');
    expect(once.register, 'c2=0, c0=1');
    expect(once.readings.map((r) => (r.measurement.qubit, r.value)).toSet(),
        {(0, 0), (1, 1)});
    expect(_seeded().runShots(program, shots: 100).counts, {'01': 100});
    c.dispose();
  });

  test('independent measurements sharing a column execute correctly', () {
    final c = _make(2)..insertSingleGateWithOutcome(_x, 0, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    c.insertMeasurementWithOutcome(qubit: 1, column: 0);
    final program = CircuitProgram.fromCircuit(c);
    final columns = {
      for (final op in program.operations.whereType<MeasureZOperation>())
        op.qubit: op.column,
    };
    expect(columns[1], 0, reason: 'q1 measurement shares column 0 with X');
    expect(_seeded().runShots(program, shots: 500).counts, {'01': 500});
    c.dispose();
  });

  test('same-column operation ordering is deterministic', () {
    final c = _make(3)..insertSingleGateWithOutcome(_h, 0, 1);
    c.insertMeasurementWithOutcome(qubit: 2, column: 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 0);
    final first = CircuitProgram.fromCircuit(c).operations.map((o) => o.id);
    for (var i = 0; i < 10; i++) {
      expect(CircuitProgram.fromCircuit(c).operations.map((o) => o.id), first);
    }
    final restored = SandboxProgramSnapshot.decode(
            SandboxProgramSnapshot.capture(c).encode())
        .restoreCircuit();
    expect(CircuitProgram.fromCircuit(restored).operations.map((o) => o.id),
        first);
    restored.dispose();
    c.dispose();
  });

  test('running never mutates or notifies the circuit', () {
    final c = _make(2)..insertSingleGateWithOutcome(_h, 0, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    final encoded = SandboxProgramSnapshot.capture(c).encode();
    var notifications = 0;
    c.addListener(() => notifications++);
    final runner = _seeded();
    runner.runOnce(CircuitProgram.fromCircuit(c));
    runner.runShots(CircuitProgram.fromCircuit(c), shots: 1000);
    expect(SandboxProgramSnapshot.capture(c).encode(), encoded);
    expect(notifications, 0);
    c.dispose();
  });

  test('readout rejects malformed labels; shared legacy bits are flagged', () {
    final c = _make(2)..insertSingleGateWithOutcome(_x, 0, 0);
    c.addMeasurement(column: 1, qubit: 0, classicalBit: 0);
    c.addMeasurement(column: 2, qubit: 1, classicalBit: 0);
    final program = CircuitProgram.fromCircuit(c);
    final readout = ClassicalReadout.forProgram(program);
    expect(() => readout.outcomeOf('101'), throwsArgumentError);
    final once = _seeded().runOnce(program);
    expect(once.sharedBits, {0});
    expect(once.register, 'c0=0', reason: 'last writer (q1 = 0) wins');
    expect(formatCount(10000), '10,000');
    c.dispose();
  });

  test('shot counts parse exactly, without rounding or substitution', () {
    for (final (input, expected) in [
      ('876', 876),
      (' 42 ', 42),
      ('1', 1),
      ('10000', 10000),
      ('10,000', 10000),
      ('2,500', 2500),
      ('00876', 876),
    ]) {
      expect(MeasuredCircuitRunner.parseShots(input),
          (shots: expected, error: null),
          reason: input);
    }
    for (final input in [
      '',
      '  ',
      'abc',
      '87.6',
      '876.0',
      '1e3',
      '-5',
      '+5',
      '0',
      '10001',
      '10,001',
      '1,00',
      '99999999999999999999',
    ]) {
      final parsed = MeasuredCircuitRunner.parseShots(input);
      expect(parsed.shots, isNull, reason: input);
      expect(parsed.error, isNotNull, reason: input);
    }
  });

  test('custom shot counts run exactly that many shots', () {
    final c = _make(1)..insertSingleGateWithOutcome(_h, 0, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    final result =
        _seeded().runShots(CircuitProgram.fromCircuit(c), shots: 876);
    expect(result.shots, 876);
    expect(result.counts.values.reduce((a, b) => a + b), 876);
    c.dispose();
  });

  group('pre-measurement state', () {
    PreMeasurementState of(QuantumCircuit c) =>
        PreMeasurementState.of(() => CircuitProgram.fromCircuit(c));

    test('X → M is |1⟩ and H → M is |+⟩, deterministically', () {
      final x = _make(1)..insertSingleGateWithOutcome(_x, 0, 0);
      x.insertMeasurementWithOutcome(qubit: 0, column: 1);
      final h = _make(1)..insertSingleGateWithOutcome(_h, 0, 0);
      h.insertMeasurementWithOutcome(qubit: 0, column: 1);
      for (var i = 0; i < 5; i++) {
        final one = of(x).stateVector!;
        expect(one[0].real, closeTo(0, 1e-12));
        expect(one[1].real, closeTo(1, 1e-12));
        final plus = of(h).stateVector!;
        expect(plus[0].real, closeTo(1 / sqrt2, 1e-12));
        expect(plus[1].real, closeTo(1 / sqrt2, 1e-12));
      }
      x.dispose();
      h.dispose();
    });

    test('measurement alone gives the initial state; circuit untouched', () {
      final c = _make(1)..insertMeasurementWithOutcome(qubit: 0, column: 0);
      final encoded = SandboxProgramSnapshot.capture(c).encode();
      final state = of(c).stateVector!;
      expect(state[0].real, closeTo(1, 1e-12));
      expect(c.measurements, hasLength(1));
      expect(SandboxProgramSnapshot.capture(c).encode(), encoded);
      c.dispose();
    });

    test('multi-qubit terminal measurements: Bell state before M', () {
      final c = _make(2)
        ..insertSingleGateWithOutcome(_h, 0, 0)
        ..insertDoubleGateWithOutcome(_cnot, 1, 1, 0);
      c.insertMeasurementWithOutcome(qubit: 0, column: 2);
      c.insertMeasurementWithOutcome(qubit: 1, column: 2);
      final state = of(c).stateVector!;
      expect(state.map((a) => a.real.toDouble()).toList(),
          [closeTo(1 / sqrt2, 1e-12), 0, 0, closeTo(1 / sqrt2, 1e-12)]);
      c.dispose();
    });

    test('a gate after M on another qubit commutes: still supported', () {
      // q0 measured at column 0; X on q1 afterwards acts on another qubit.
      final c = _make(2)..insertMeasurementWithOutcome(qubit: 0, column: 0);
      c.insertSingleGateWithOutcome(_x, 1, 1);
      final ops = CircuitProgram.fromCircuit(c).operations;
      expect(ops.first, isA<MeasureZOperation>());
      final state = of(c).stateVector!;
      expect(state[2].real, closeTo(1, 1e-12), reason: '|10⟩: q1 = 1');
      c.dispose();
    });

    test('non-terminal measurements are guarded with a reason', () {
      final twice = _make(1)
        ..addMeasurement(column: 0, qubit: 0, classicalBit: 0)
        ..addMeasurement(column: 1, qubit: 0, classicalBit: 1);
      expect(of(twice).isAvailable, isFalse);
      expect(of(twice).unavailableReason, PreMeasurementState.notTerminal(0));

      // A legacy program with a gate after the measurement.
      final measure = _make(1)
        ..insertMeasurementWithOutcome(qubit: 0, column: 0);
      final m = CircuitProgram.fromCircuit(measure).operations.single;
      final gate = _make(1)..insertSingleGateWithOutcome(_x, 0, 0);
      final x = CircuitProgram.fromCircuit(gate).operations.single;
      final legacy = CircuitProgram(
        qubitCount: 1,
        classicalBitCount: 1,
        initialState: CircuitProgram.fromCircuit(gate).initialState,
        operations: [
          m,
          UnitaryOperation(
              id: GateId(m.id.value + 1000),
              column: 1,
              gate: (x as UnitaryOperation).gate,
              target: 0,
              isDeletable: true),
        ],
      );
      expect(PreMeasurementState.of(() => legacy).unavailableReason,
          PreMeasurementState.notTerminal(0));
      expect(
          PreMeasurementState.of(() => throw StateError('bad'))
              .unavailableReason,
          PreMeasurementState.failed);
      for (final c in [twice, measure, gate]) {
        c.dispose();
      }
    });
  });

  group('final-state sampling (no M gates)', () {
    test('uses the existing sampler with exact custom shot counts', () {
      final c = _make(2)..insertSingleGateWithOutcome(_x, 0, 0);
      c.runSimulation();
      final sampler = FinalStateSampler(random: Random(5));
      final shots = sampler.runShots(c.currentState.stateVector, 2, shots: 876);
      expect(shots.shots, 876);
      expect(shots.counts, {'01': 876});
      expect(shots.readout.orderLabel, 'q1 q0');
      expect(shots.readout.describe('01'), 'q1=0, q0=1');
      final once = sampler.runOnce(c.currentState.stateVector, 2);
      expect(once.outcome, '01');
      expect(once.register, 'q1=0, q0=1');
      expect(once.readout.isFinalState, isTrue);
      expect(() => sampler.runShots(c.currentState.stateVector, 2, shots: 0),
          throwsArgumentError);
      expect(
          () => sampler.runShots(c.currentState.stateVector, 2, shots: 10001),
          throwsArgumentError);
      c.dispose();
    });

    test('H gives about 50/50 over 10,000 final-state shots', () {
      final c = _make(1)..insertSingleGateWithOutcome(_h, 0, 0);
      c.runSimulation();
      final result = FinalStateSampler(random: Random(11))
          .runShots(c.currentState.stateVector, 1, shots: 10000);
      expect(result.counts.values.reduce((a, b) => a + b), 10000);
      for (final count in result.counts.values) {
        expect(count / 10000, closeTo(.5, .03));
      }
      c.dispose();
    });
  });
}
