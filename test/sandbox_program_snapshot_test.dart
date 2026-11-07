import 'dart:convert';
import 'dart:io';
import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';

class FaultStore extends InMemoryAppStorage {
  bool reject = false, corrupt = false;
  @override
  Future<void> writeString(String key, String value) async {
    if (reject) throw StateError('write rejected');
    return super.writeString(key, corrupt ? 'broken' : value);
  }
}

void main() {
  SandboxProgramSnapshot sample({bool measured = true}) =>
      SandboxProgramSnapshot(
          CircuitProgram(qubitCount: 2, classicalBitCount: 5, initialState: [
            Complex.one(),
            Complex.zero(),
            Complex.zero(),
            Complex.zero()
          ], operations: [
            UnitaryOperation(
                id: const GateId(8),
                column: 0,
                target: 0,
                gate: Gate.fromIdentifier(SelectedGateType.rx, angle: .37)),
            if (measured)
              const MeasureZOperation(
                  id: GateId(11), column: 2, qubit: 0, classicalBit: 3),
            UnitaryOperation(
                id: const GateId(15),
                column: 4,
                target: 1,
                control: 0,
                gate: Gate.fromIdentifier(SelectedGateType.cnot)),
            if (measured)
              const MeasureZOperation(
                  id: GateId(19), column: 6, qubit: 1, classicalBit: 3),
          ]),
          initialStateLabel: '00');
  for (final measured in [false, true]) {
    test('schema 2 round trip measured=$measured preserves entire definition',
        () {
      final s = sample(measured: measured);
      final restored =
          SandboxProgramSnapshot.decode(s.encode()).restoreCircuit();
      addTearDown(restored.dispose);
      expect(SandboxProgramSnapshot.capture(restored).encode(), s.encode());
      expect(restored.simulationRunCount, 0);
      expect(restored.currentState.stateVector, s.program.initialState);
      expect(CircuitProgram.fromCircuit(restored).classicalBitCount, 5);
      if (measured) {
        expect(restored.measurements.map((m) => m.classicalBit), [3, 3]);
        expect(
            restored
                .addMeasurement(column: 8, qubit: 0, classicalBit: 0)
                .id
                .value,
            greaterThan(19));
      }
    });
  }
  test('schema 1 fixture conversion deterministic and idempotent', () {
    final old = File('test/fixtures/operation_contract/unitary_schema1.json')
        .readAsStringSync();
    final a = SandboxProgramSnapshot.decode(old);
    final b = SandboxProgramSnapshot.decode(old);
    expect(a.encode(), b.encode());
    expect(SandboxProgramSnapshot.decode(a.encode()).encode(), a.encode());
    expect(a.program.isUnitary, true);
    expect(a.program.classicalBitCount, 0);
    final legacy = SandboxCircuitSnapshot.decode(old).restoreCircuit();
    addTearDown(legacy.dispose);
    expect(SandboxProgramSnapshot.capture(legacy).encode(), a.encode());
  });
  test('complex initial amplitudes and same-column order preserved', () {
    final s = SandboxProgramSnapshot(
        CircuitProgram(qubitCount: 2, classicalBitCount: 0, initialState: [
          Complex(.5, 0),
          Complex(0, .5),
          Complex(-.5, 0),
          Complex(0, -.5)
        ], operations: [
          UnitaryOperation(
              id: const GateId(9),
              column: 0,
              target: 1,
              gate: Gate.fromIdentifier(SelectedGateType.x)),
          UnitaryOperation(
              id: const GateId(2),
              column: 0,
              target: 0,
              gate: Gate.fromIdentifier(SelectedGateType.z)),
        ]),
        initialStateLabel: 'custom');
    final c = SandboxProgramSnapshot.decode(s.encode()).restoreCircuit();
    addTearDown(c.dispose);
    expect(SandboxProgramSnapshot.capture(c).encode(), s.encode());
  });
  test('malformed records rejected explicitly', () {
    final changes = <void Function(Map<String, dynamic>)>[
      (j) => j['schemaVersion'] = 3,
      (j) => j['operations'][0]['kind'] = 'future',
      (j) => j['operations'][0]['gateType'] = 'none',
      (j) => j['operations'][0].remove('target'),
      (j) => j['operations'][1]['id'] = 8,
      (j) => j['operations'][1]['qubit'] = 2,
      (j) => j['operations'][1]['classicalBit'] = 5,
      (j) => j['operations'][1]['column'] = 0,
      (j) => j['operations'][0]['angle'] = 'NaN',
      (j) => j['initialState'][0] = [2, 0],
      (j) => j['operations'][2].remove('control'),
      (j) => j['operations'][0]['id'] = -1,
    ];
    for (final change in changes) {
      final j = jsonDecode(sample().encode()) as Map<String, dynamic>;
      change(j);
      expect(() => SandboxProgramSnapshot.decode(jsonEncode(j)),
          throwsA(anyOf(isA<FormatException>(), isA<InvalidCircuitProgram>())));
    }
  });
  test('overlapping visual control footprints rejected', () {
    final j = jsonDecode(sample().encode()) as Map<String, dynamic>;
    j['operations'] = [
      {
        'kind': 'unitary',
        'id': 1,
        'column': 0,
        'gateType': 'cnot',
        'target': 1,
        'control': 0,
        'isDeletable': true
      },
      {
        'kind': 'unitary',
        'id': 2,
        'column': 0,
        'gateType': 'x',
        'target': 0,
        'isDeletable': true
      }
    ];
    expect(() => SandboxProgramSnapshot.decode(jsonEncode(j)),
        throwsA(isA<InvalidCircuitProgram>()));
  });
  test('staging isolated, verified and retryable without legacy mutation',
      () async {
    final store = FaultStore();
    await store.writeString('sandbox_circuit_snapshot_q2', 'legacy');
    final s = sample();
    store.reject = true;
    await expectLater(s.stage(store, stagingId: 'attempt1'), throwsStateError);
    expect(await store.readString('sandbox_circuit_snapshot_q2'), 'legacy');
    store.reject = false;
    final key = await s.stage(store, stagingId: 'attempt1');
    expect(await store.readString(key), s.encode());
    expect(await s.stage(store, stagingId: 'attempt1'), key);
    await expectLater(
        sample(measured: false).stage(store, stagingId: 'attempt1'),
        throwsStateError);
    expect(await store.readString(key), s.encode());
  });
  test('verification failure retains source and prior successful stage',
      () async {
    final store = FaultStore();
    await store.writeString('sandbox_circuit_snapshot_q2', 'legacy');
    final s = sample();
    final good = await s.stage(store, stagingId: 'good');
    store.corrupt = true;
    await expectLater(s.stage(store, stagingId: 'bad'), throwsStateError);
    expect(await store.readString(good), s.encode());
    expect(await store.readString('sandbox_circuit_snapshot_q2'), 'legacy');
    expect(
        () => SandboxProgramSnapshot.decode('broken'), throwsFormatException);
    expect(await store.readString(good), s.encode());
  });
}
