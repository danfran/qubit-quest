import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/storage/shared_preferences_app_storage.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';

class MigrationStorage extends InMemoryAppStorage {
  MigrationStorage(super.values);
  bool failWrite = false;
  bool loseWrite = false;
  bool failRead = false;
  int writes = 0;
  int deletes = 0;
  @override
  Future<void> writeString(String key, String value) async {
    writes++;
    if (failWrite) throw StateError('write');
    if (!loseWrite) await super.writeString(key, value);
  }

  @override
  Future<String?> readString(String key) async {
    if (failRead && writes > 0) throw StateError('read');
    return super.readString(key);
  }

  @override
  Future<void> delete(String key) async {
    deletes++;
    await super.delete(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');
  const adapter = SharedPreferencesAppStorage();
  final disk = <String, Object>{};
  String? failure;
  setUp(() {
    SharedPreferences.resetStatic();
    disk.clear();
    failure = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method.startsWith('getAll')) {
        return Map<String, Object>.from(disk);
      }
      if (failure == 'throw') throw PlatformException(code: 'storage');
      if (failure == 'false') return false;
      final args = call.arguments as Map;
      if (call.method == 'remove') {
        disk.remove(args['key']);
      } else {
        disk[args['key'] as String] = args['value'] as Object;
      }
      return true;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    SharedPreferences.resetStatic();
  });
  final operations = <String, Future<void> Function()>{
    'string': () => adapter.writeString('key', 'new'),
    'bool': () => adapter.writeBool('key', true),
    'int': () => adapter.writeInt('key', 3),
    'list': () => adapter.writeStringList('key', ['new']),
    'remove': () => adapter.delete('key'),
  };
  for (final mode in ['false', 'throw']) {
    for (final entry in operations.entries) {
      test('${entry.key} $mode propagates and cannot poison subsequent reads',
          () async {
        disk['flutter.key'] = 'original';
        failure = mode;
        await expectLater(entry.value(), throwsA(anything));
        expect(disk['flutter.key'], 'original');
        expect(await adapter.readString('key'), 'original');
      });
    }
  }
  test('successful operations survive cache recreation', () async {
    await adapter.writeString('s', 'value');
    await adapter.writeBool('b', true);
    await adapter.writeInt('i', 7);
    await adapter.writeStringList('l', ['value']);
    SharedPreferences.resetStatic();
    expect(await adapter.readString('s'), 'value');
    expect(await adapter.readBool('b'), true);
    expect(await adapter.readInt('i'), 7);
    expect(await adapter.readStringList('l'), ['value']);
    await adapter.delete('s');
    SharedPreferences.resetStatic();
    expect(await adapter.readString('s'), isNull);
  });

  for (final mode in ['write', 'verification', 'read', 'success']) {
    test('migration $mode retains recovery source and retries safely',
        () async {
      final encoded = SandboxCircuitSnapshot.capture(
              QuantumCircuit(currentLevel: createSandboxComposerLevel(2)))
          .encode();
      final storage =
          MigrationStorage({SandboxPersistenceStore.storageKey: encoded});
      final store = SandboxPersistenceStore(storage: storage);
      storage.failWrite = mode == 'write';
      storage.loseWrite = mode == 'verification';
      storage.failRead = mode == 'read';
      if (mode == 'success') {
        expect((await store.loadSnapshot(2))!.encode(), encoded);
      } else {
        await expectLater(store.loadSnapshot(2), throwsStateError);
      }
      storage.failRead = false;
      expect(await storage.readString(SandboxPersistenceStore.storageKey),
          encoded);
      expect(storage.deletes, 0);
      storage.failWrite = false;
      storage.loseWrite = false;
      expect((await store.loadSnapshot(2))!.encode(), encoded);
      final writes = storage.writes;
      expect((await store.loadSnapshot(2))!.encode(), encoded);
      expect(storage.writes, writes,
          reason: 'Destination wins; no duplicate migration');
      expect(storage.deletes, 0,
          reason: 'No durable-flush contract permits source cleanup');
    });
  }
}
