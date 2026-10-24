import 'package:flutter/foundation.dart';
import 'sandbox_circuit_persistence.dart';

enum CircuitSaveStatus { idle, saved, pending, failed }

/// Serializes snapshots; pending edits replace obsolete queued snapshots.
/// Acknowledgement means the storage API succeeded, not a disk-flush guarantee.
class CircuitSaveQueue extends ChangeNotifier {
  CircuitSaveQueue(this.write);
  final Future<void> Function(SandboxCircuitSnapshot) write;
  final Map<int, SandboxCircuitSnapshot> _pending = {};
  Future<void>? _running;
  bool _disposed = false;
  CircuitSaveStatus status = CircuitSaveStatus.idle;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> save(SandboxCircuitSnapshot snapshot) {
    _pending[snapshot.qubitCount] = snapshot;
    return retry();
  }

  Future<void> retry() {
    if (_running != null) return _running!;
    if (_pending.isEmpty) return Future<void>.value();
    // Schedule after assigning _running, including synchronously throwing stores.
    _running =
        Future<void>.microtask(_drain).whenComplete(() => _running = null);
    status = CircuitSaveStatus.pending;
    _notify();
    return _running!;
  }

  Future<void> _drain() async {
    while (_pending.isNotEmpty) {
      final key = _pending.keys.first;
      final snapshot = _pending[key]!;
      try {
        await write(snapshot);
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
