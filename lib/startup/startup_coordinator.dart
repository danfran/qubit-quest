import 'dart:async';

import 'package:quantumquiz/diagnostics/startup_diagnostics.dart';

import 'package:flutter/foundation.dart';

enum StartupPhase { loading, ready, error }

/// Owns readiness only. Timing out never cancels or duplicates plugin work.
class StartupCoordinator extends ChangeNotifier {
  StartupCoordinator({
    required this.initialize,
    this.configureOrientation,
    this.waitLimit = const Duration(seconds: 15),
  });

  final Future<void> Function() initialize;
  final Future<void> Function()? configureOrientation;
  final Duration waitLimit;
  StartupPhase phase = StartupPhase.loading;
  bool timedOut = false;
  bool _started = false;
  bool _pending = false;
  bool _disposed = false;
  Timer? _timer;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    StartupDiagnostics.instance.event('startup.gate_activated');
    final orientation = configureOrientation;
    if (orientation != null) {
      // Optional platform configuration must never hold the readiness gate.
      unawaited(Future<void>.sync(orientation).then<void>((_) {},
          onError: (Object error, StackTrace stack) {
        StartupDiagnostics.instance
            .event('orientation.failed', error: error, stack: stack);
      }));
    }
    _waitOrInitialize();
  }

  void retry() {
    if (_disposed || phase != StartupPhase.error) return;
    StartupDiagnostics.instance.event('startup.retry_requested');
    _waitOrInitialize();
  }

  void _waitOrInitialize() {
    phase = StartupPhase.loading;
    timedOut = false;
    _timer?.cancel();
    _timer = Timer(waitLimit, () {
      if (_disposed) return;
      StartupDiagnostics.instance.event('math.timeout');
      timedOut = true;
      phase = StartupPhase.error;
      notifyListeners();
    });
    notifyListeners();
    if (_pending) return;
    _pending = true;
    StartupDiagnostics.instance.event('math.begin');
    unawaited(Future<void>.sync(initialize).then<void>((_) {
      _pending = false;
      if (_disposed) return;
      _timer?.cancel();
      StartupDiagnostics.instance.event('math.succeeded');
      phase = StartupPhase.ready;
      StartupDiagnostics.instance.event('application.ready');
      notifyListeners();
    }, onError: (Object error, StackTrace stack) {
      _pending = false;
      _failed(error, stack);
    }));
  }

  void _failed(Object error, StackTrace stack) {
    if (_disposed) return;
    _timer?.cancel();
    timedOut = false;
    phase = StartupPhase.error;
    StartupDiagnostics.instance
        .event('math.failed', error: error, stack: stack);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
