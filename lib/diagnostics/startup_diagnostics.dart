import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Local startup breadcrumbs only; no storage, upload or application data payloads.
class StartupDiagnostics {
  StartupDiagnostics({void Function(String)? sink, int Function()? elapsedMs})
      : _sink = sink ?? debugPrint,
        _elapsedMs = elapsedMs {
    _clock.start();
  }

  static StartupDiagnostics instance = StartupDiagnostics();
  final void Function(String) _sink;
  final int Function()? _elapsedMs;
  final Stopwatch _clock = Stopwatch();
  bool _writing = false;

  void event(String name, {Object? error, StackTrace? stack}) {
    if (_writing) return;
    _writing = true;
    try {
      // FormatException.toString includes its source, which can be a saved record.
      // PlatformException details can contain arbitrary plugin payloads.
      final message = switch (error) {
        FormatException e => e.message,
        PlatformException e => '${e.code}: ${e.message ?? ''}',
        null => null,
        _ => error.toString(),
      };
      _sink(jsonEncode({
        'scope': 'qubitquest.startup',
        'event': name,
        'elapsed_ms': _elapsedMs?.call() ?? _clock.elapsedMilliseconds,
        if (error != null) 'error_type': error.runtimeType.toString(),
        if (message != null) 'message': message,
        if (stack != null) 'stack': stack.toString(),
      }));
    } catch (_) {
      // Diagnostics must not alter initialization or recursively report sink errors.
    } finally {
      _writing = false;
    }
  }

  /// Observe errors while preserving the previous handlers and handled/unhandled
  /// result. The returned cleanup is for tests/owners, and never replaces a later
  /// handler installed by another component.
  VoidCallback installErrorHandlers() {
    final previousFlutter = FlutterError.onError;
    final dispatcher = PlatformDispatcher.instance;
    final previousPlatform = dispatcher.onError;
    void flutterHandler(FlutterErrorDetails details) {
      event('flutter.error', error: details.exception, stack: details.stack);
      if (previousFlutter != null) {
        previousFlutter(details);
      } else {
        FlutterError.presentError(details);
      }
    }

    bool platformHandler(Object error, StackTrace stack) {
      event('platform.unhandled_error', error: error, stack: stack);
      return previousPlatform?.call(error, stack) ?? false;
    }

    FlutterError.onError = flutterHandler;
    dispatcher.onError = platformHandler;
    return () {
      if (identical(FlutterError.onError, flutterHandler)) {
        FlutterError.onError = previousFlutter;
      }
      if (identical(dispatcher.onError, platformHandler)) {
        dispatcher.onError = previousPlatform;
      }
    };
  }
}
