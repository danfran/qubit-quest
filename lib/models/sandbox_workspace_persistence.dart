import 'circuit_program.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../storage/app_storage.dart';
import 'sandbox_program_snapshot.dart';
import 'sandbox_circuit_persistence.dart';
import 'circuit_save_queue.dart';

/// Application-lifetime owner shared by both Sandbox presenters for one backend.
/// Pending revisions survive widget disposal. No cross-process locking is implied.
class SandboxWorkspacePersistence {
  SandboxWorkspacePersistence(this.storage);
  final AppStorage storage;
  static final _owners = Expando<SandboxWorkspacePersistence>();
  static SandboxWorkspacePersistence forStorage(AppStorage storage) =>
      _owners[storage] ??= SandboxWorkspacePersistence(storage);
  final _queues = <int, CircuitSaveQueue>{};
  final _recoveryAllowed = <int>{};
  int _sequence = 0;
  final String _session = createSessionId();

  /// Source of session randomness; replaceable only so tests can model
  /// initialization failures.
  @visibleForTesting
  static Random Function() secureRandom = Random.secure;

  /// Largest `nextInt` bound used for session IDs. It must stay a literal below
  /// 2^31: JavaScript-compiled Web evaluates `1 << 32` as 0, and
  /// `nextInt(0)` throws, which previously made Web Sandbox opening fail.
  @visibleForTesting
  static const int sessionChunkBound = 0x10000;

  /// Timestamp plus 64 random bits as four 16-bit chunks, using only
  /// operations whose results match on the Dart VM and on JavaScript.
  /// Matches the staging-ID alphabet `[A-Za-z0-9_-]`.
  @visibleForTesting
  static String createSessionId({Random? random, DateTime? now}) {
    final source = random ?? secureRandom();
    final buffer = StringBuffer()
      ..write((now ?? DateTime.now()).microsecondsSinceEpoch)
      ..write('_');
    for (var chunk = 0; chunk < 4; chunk++) {
      buffer.write(
          source.nextInt(sessionChunkBound).toRadixString(16).padLeft(4, '0'));
    }
    return buffer.toString();
  }

  static String activeKey(int n) => 'sandbox_circuit_v2_active_q$n';
  static String recoveryKey(int n) => 'sandbox_circuit_v2_previous_q$n';

  CircuitSaveQueue queue(int n) => _queues.putIfAbsent(
      n, () => CircuitSaveQueue.programs((snapshot) => _activate(snapshot)));

  Future<SandboxProgramSnapshot> _readCandidate(String key, int n) async {
    if (!key.startsWith('sandbox_circuit_v2_stage_q${n}_')) {
      throw const FormatException('Invalid active Sandbox reference');
    }
    final source = await storage.readString(key);
    if (source == null)
      throw const FormatException('Missing active Sandbox candidate');
    final snapshot = SandboxProgramSnapshot.decode(source);
    if (snapshot.program.qubitCount != n ||
        (jsonDecode(source) as Map)['schemaVersion'] != 2) {
      throw const FormatException('Invalid active Sandbox candidate');
    }
    return snapshot;
  }

  Future<SandboxProgramSnapshot?> load(int n) async {
    final queue = _queues[n];
    final pending = queue?.latestProgram;
    if (pending != null && queue!.status != CircuitSaveStatus.saved)
      return pending;
    final active = await storage.readString(activeKey(n));
    if (active != null) return _readCandidate(active, n);
    return _legacy(n);
  }

  Future<SandboxProgramSnapshot?> _legacy(int n) async {
    var source = await storage
        .readString(SandboxPersistenceStore.storageKeyForQubitCount(n));
    source ??= await storage.readString(SandboxPersistenceStore.storageKey);
    if (source == null) return null;
    final snapshot = SandboxProgramSnapshot.decode(source);
    return snapshot.program.qubitCount == n ? snapshot : null;
  }

  /// Explicit user-selected recovery; never invoked as an automatic fallback.
  Future<SandboxProgramSnapshot> recover(int n) async {
    SandboxProgramSnapshot? recovered;
    final previous = await storage.readString(recoveryKey(n));
    if (previous != null) {
      try {
        recovered = await _readCandidate(previous, n);
      } on FormatException {
        // Try the explicitly requested legacy source.
      } on InvalidCircuitProgram {
        // Invalid quantum definitions are corrupt candidates, not IO failures.
      }
    }
    recovered ??= await _legacy(n);
    if (recovered == null) throw StateError('No recoverable Sandbox record');
    _recoveryAllowed.add(n);
    await queue(n).saveProgram(recovered);
    // The definition remains available in memory even if saving recovery fails.
    return recovered;
  }

  Future<void> _activate(SandboxProgramSnapshot snapshot) async {
    final n = snapshot.program.qubitCount;
    final old = await storage.readString(activeKey(n));
    var validOld = false;
    if (old != null) {
      try {
        await _readCandidate(old, n);
        validOld = true;
      } catch (_) {
        if (!_recoveryAllowed.contains(n)) rethrow;
      }
    }
    final candidate =
        await snapshot.stage(storage, stagingId: '${_session}_${_sequence++}');
    if (validOld) {
      await storage.writeString(recoveryKey(n), old!);
      if (await storage.readString(recoveryKey(n)) != old)
        throw StateError('Recovery reference verification failed');
    }
    // If our activation is interrupted or corrupts its reference, the retained
    // pending definition can repair that reference on Retry in this process.
    _recoveryAllowed.add(n);
    await storage.writeString(activeKey(n), candidate);
    if (await storage.readString(activeKey(n)) != candidate)
      throw StateError('Activation verification failed');
    await _readCandidate(candidate, n);
    _recoveryAllowed.remove(n);
  }
}
