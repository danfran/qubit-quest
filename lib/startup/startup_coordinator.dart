import 'dart:async';

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
    final orientation = configureOrientation;
    if (orientation != null) {
      // Optional platform configuration must never hold the readiness gate.
      unawaited(Future<void>.sync(orientation).then<void>((_) {},
          onError: (Object error, StackTrace stack) {
        debugPrint('Startup orientation configuration failed: $error');
      }));
    }
    _waitOrInitialize();
  }

  void retry() {
    if (_disposed || phase != StartupPhase.error) return;
    _waitOrInitialize();
  }

  void _waitOrInitialize() {
    phase = StartupPhase.loading;
    timedOut = false;
    _timer?.cancel();
    _timer = Timer(waitLimit, () {
      if (_disposed) return;
      timedOut = true;
      phase = StartupPhase.error;
      notifyListeners();
    });
    notifyListeners();
    if (_pending) return;
    _pending = true;
    unawaited(Future<void>.sync(initialize).then<void>((_) {
      _pending = false;
      if (_disposed) return;
      _timer?.cancel();
      phase = StartupPhase.ready;
      notifyListeners();
    }, onError: (Object error, StackTrace stack) {
      _pending = false;
      _failed(error);
    }));
  }

  void _failed(Object error) {
    if (_disposed) return;
    _timer?.cancel();
    timedOut = false;
    phase = StartupPhase.error;
    debugPrint('Startup math initialization failed: $error');
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
