import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/sandbox_workspace_persistence.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/circuit_save_queue.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';

class FaultStorage extends InMemoryAppStorage {
  String? fail, corrupt;
  Completer<void>? blocked;
  int activeWrites = 0, maxWrites = 0;
  @override
  Future<void> writeString(String k, String v) async {
    activeWrites++;
    if (activeWrites > maxWrites) maxWrites = activeWrites;
    try {
      await blocked?.future;
      if (fail != null && k.contains(fail!)) throw StateError('write failed');
      await super.writeString(
          k, corrupt != null && k.contains(corrupt!) ? 'broken' : v);
    } finally {
      activeWrites--;
    }
  }
}

SandboxProgramSnapshot definition({int n = 2, int measurements = 1}) {
  final c = QuantumCircuit(currentLevel: createSandboxComposerLevel(n));
  c.insertSingleGateWithOutcome(
      Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
  for (var i = 0; i < measurements; i++) {
    c.addMeasurement(column: i + 1, qubit: 0, classicalBit: 3);
  }
  final s = SandboxProgramSnapshot.capture(c);
  c.dispose();
  return s;
}

void main() {
  test(
      'legacy conversion non destructive; activation takes precedence over older writers',
      () async {
    final store = FaultStorage();
    final c = QuantumCircuit(currentLevel: createSandboxComposerLevel(2));
    final legacy = SandboxCircuitSnapshot.capture(c).encode();
    c.dispose();
    final key = SandboxPersistenceStore.storageKeyForQubitCount(2);
    await store.writeString(key, legacy);
    final owner = SandboxWorkspacePersistence(store);
    expect((await owner.load(2))!.program.isUnitary, true);
    expect(await store.readString(key), legacy);
    final s = definition(measurements: 2);
    await owner.queue(2).saveProgram(s);
    await store.writeString(key, legacy);
    expect((await SandboxWorkspacePersistence(store).load(2))!.encode(),
        s.encode());
    expect(await store.readString(key), legacy);
  });
  for (final mode in [
    'stage-write',
    'stage-readback',
    'active-write',
    'active-readback'
  ]) {
    test(
        '$mode failure retains previous source and pending revision; retry succeeds',
        () async {
      final store = FaultStorage();
      final owner = SandboxWorkspacePersistence(store);
      final q = owner.queue(2);
      final old = definition();
      await q.saveProgram(old);
      final oldRef =
          await store.readString(SandboxWorkspacePersistence.activeKey(2));
      if (mode == 'stage-write') store.fail = '_stage_';
      if (mode == 'stage-readback') store.corrupt = '_stage_';
      if (mode == 'active-write') store.fail = '_active_';
      if (mode == 'active-readback') store.corrupt = '_active_';
      final next = definition(measurements: 2);
      await q.saveProgram(next);
      expect(q.status, CircuitSaveStatus.failed);
      expect(q.confirmedRevision, 1);
      expect(q.revision, 2);
      expect(await store.readString(oldRef!), old.encode());
      expect((await owner.load(2))!.encode(), next.encode());
      store.fail = null;
      store.corrupt = null;
      await q.retry();
      expect((await SandboxWorkspacePersistence(store).load(2))!.encode(),
          next.encode());
      expect(q.status, CircuitSaveStatus.saved);
    });
  }
  test(
      'rapid edits serialize; older completion does not acknowledge latest; navigation retains queue',
      () async {
    final store = FaultStorage();
    final owner = SandboxWorkspacePersistence.forStorage(store);
    final q = owner.queue(2);
    store.blocked = Completer<void>();
    final first = q.saveProgram(definition());
    await Future<void>.delayed(Duration.zero);
    q.saveProgram(definition(measurements: 2));
    q.saveProgram(definition(measurements: 3));
    expect(q.status, CircuitSaveStatus.pending);
    expect(q.confirmedRevision, 0);
    expect(q.revision, 3);
    expect(SandboxPersistenceStore(storage: store).programs.queue(2), same(q));
    expect((await owner.load(2))!.program.operations.length, 4);
    store.blocked!.complete();
    await first;
    expect(q.confirmedRevision, 3);
    expect(store.maxWrites, 1);
    expect(
        (await SandboxWorkspacePersistence(store).load(2))!
            .program
            .operations
            .length,
        4);
  });
  test('workspace isolation and clear/removal persist', () async {
    final store = FaultStorage();
    final owner = SandboxWorkspacePersistence(store);
    await owner.queue(1).saveProgram(definition(n: 1));
    await owner.queue(2).saveProgram(definition());
    final c = (await owner.load(2))!.restoreCircuit();
    c.removeMeasurement(c.measurements.single.id);
    await owner.queue(2).saveProgram(SandboxProgramSnapshot.capture(c));
    expect(
        (await SandboxWorkspacePersistence(store).load(2))!.program.isUnitary,
        true);
    c.clearPlacedGates();
    await owner.queue(2).saveProgram(SandboxProgramSnapshot.capture(c));
    c.dispose();
    expect(
        (await SandboxWorkspacePersistence(store).load(2))!.program.operations,
        isEmpty);
    expect(
        (await SandboxWorkspacePersistence(store).load(1))!.program.isUnitary,
        false);
  });
  test(
      'malformed active data rejects; explicit legacy recovery does not destroy bad candidate',
      () async {
    final store = FaultStorage();
    final c = QuantumCircuit(currentLevel: createSandboxComposerLevel(2));
    final legacy = SandboxCircuitSnapshot.capture(c).encode();
    c.dispose();
    await store.writeString(
        SandboxPersistenceStore.storageKeyForQubitCount(2), legacy);
    final key = 'sandbox_circuit_v2_stage_q2_bad';
    await store.writeString(key, '{"schemaVersion":99}');
    await store.writeString(SandboxWorkspacePersistence.activeKey(2), key);
    final invalidQuantum = definition().toJson();
    invalidQuantum['initialState'] = [
      [2, 0],
      [0, 0],
      [0, 0],
      [0, 0]
    ];
    const previous = 'sandbox_circuit_v2_stage_q2_invalid_quantum';
    await store.writeString(previous, jsonEncode(invalidQuantum));
    await store.writeString(
        SandboxWorkspacePersistence.recoveryKey(2), previous);
    final owner = SandboxWorkspacePersistence(store);
    await expectLater(owner.load(2), throwsFormatException);
    final recovered = await owner.recover(2);
    expect(recovered.program.operations, isEmpty);
    expect(await store.readString(key), '{"schemaVersion":99}');
    expect((await SandboxWorkspacePersistence(store).load(2))!.encode(),
        recovered.encode());
  });
  test(
      'revision submitted by a completion listener is saved, not falsely acknowledged',
      () async {
    final store = FaultStorage();
    final owner = SandboxWorkspacePersistence(store);
    final q = owner.queue(2);
    var appended = false;
    q.addListener(() {
      if (q.status == CircuitSaveStatus.saved && !appended) {
        appended = true;
        q.saveProgram(definition(measurements: 2));
        expect(q.status, CircuitSaveStatus.pending);
      }
    });
    await q.saveProgram(definition());
    expect(q.confirmedRevision, 2);
    expect(q.status, CircuitSaveStatus.saved);
    expect(
        (await SandboxWorkspacePersistence(store).load(2))!
            .program
            .operations
            .length,
        3);
  });
  test('confirmed in-memory snapshot does not hide a corrupt active reference',
      () async {
    final store = FaultStorage();
    final owner = SandboxWorkspacePersistence(store);
    await owner.queue(2).saveProgram(definition());
    await store.writeString(
        SandboxWorkspacePersistence.activeKey(2), 'invalid');
    await expectLater(owner.load(2), throwsFormatException);
  });
}
