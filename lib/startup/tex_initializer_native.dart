import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tex/flutter_tex.dart';

/// Keeps the singleton server's cached URL valid across settled controller failures.
Future<void> initializeMathService() {
  // Bridge into the caller's error zone. Some WebView setup futures are not
  // returned by flutter_tex. An error from those does NOT mean its initialization
  // has stopped: leave it pending so the coordinator can time out without overlap.
  final result = Completer<void>();
  runZonedGuarded(() async {
    try {
      if (TeXRenderingServer.port == null) {
        await TeXRenderingServer.start();
      } else {
        await TeXRenderingServer.teXRenderingController.initController();
      }
      result.complete();
    } catch (error, stack) {
      result.completeError(error, stack);
    }
  }, (error, stack) {
    debugPrint('Math service plugin setup error: $error');
  });
  return result.future;
}
