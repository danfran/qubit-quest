import 'sandbox_program_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'sandbox_circuit_persistence.dart';

enum CircuitSaveStatus { idle, saved, pending, failed }

/// Serializes snapshots; pending edits replace obsolete queued snapshots.
/// Acknowledgement means the storage API succeeded, not a disk-flush guarantee.
class CircuitSaveQueue extends ChangeNotifier {
  CircuitSaveQueue(this.write) : writeProgram = null;
  CircuitSaveQueue.programs(this.writeProgram) : write = null;
  final Future<void> Function(SandboxProgramSnapshot)? writeProgram;
  SandboxProgramSnapshot? latestProgram;
  int revision = 0;
  int confirmedRevision = 0;
  final Map<int, int> _revisions = {};
  final Future<void> Function(SandboxCircuitSnapshot)? write;
  final Map<int, Object> _pending = {};
  Future<void>? _running;
  bool _disposed = false;
  CircuitSaveStatus status = CircuitSaveStatus.idle;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> save(SandboxCircuitSnapshot snapshot) {
    _revisions[snapshot.qubitCount] = ++revision;
    _pending[snapshot.qubitCount] = snapshot;
    return retry();
  }

  Future<void> saveProgram(SandboxProgramSnapshot snapshot) {
    if (writeProgram == null) throw StateError('Schema-2 writer unavailable');
    // Circuit notifications include simulation; identical definitions aren't edits.
    if (latestProgram?.encode() == snapshot.encode()) return retry();
    latestProgram = snapshot;
    final n = snapshot.program.qubitCount;
    _revisions[n] = ++revision;
    _pending[n] = snapshot;
    status = CircuitSaveStatus.pending;
    _notify();
    return retry();
  }

  Future<void> retry() {
    if (_running != null) return _running!;
    if (_pending.isEmpty) return Future<void>.value();
    // Schedule after assigning _running, including synchronously throwing stores.
    _running = Future<void>.microtask(_drain).whenComplete(() {
      _running = null;
      if (_pending.isNotEmpty && status != CircuitSaveStatus.failed) {
        return retry();
      }
    });
    status = CircuitSaveStatus.pending;
    _notify();
    return _running!;
  }

  Future<void> _drain() async {
    while (_pending.isNotEmpty) {
      final key = _pending.keys.first;
      final snapshot = _pending[key]!;
      final savingRevision = _revisions[key]!;
      try {
        if (snapshot is SandboxProgramSnapshot) {
          await writeProgram!(snapshot);
        } else {
          await write!(snapshot as SandboxCircuitSnapshot);
        }
        confirmedRevision = savingRevision;
      } catch (_) {
        status = CircuitSaveStatus.failed;
        _notify();
        return; // Retain the latest snapshot for explicit retry or a newer edit.
      }
      if (identical(_pending[key], snapshot)) _pending.remove(key);
    }
    status = CircuitSaveStatus.saved;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
