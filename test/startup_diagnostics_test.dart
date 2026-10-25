import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/diagnostics/startup_diagnostics.dart';
import 'package:quantumquiz/startup/startup_coordinator.dart';
import 'package:quantumquiz/startup/startup_gate.dart';

void main() {
  final events = <Map<String, dynamic>>[];
  late StartupDiagnostics previous;
  setUp(() {
    previous = StartupDiagnostics.instance;
    events.clear();
    StartupDiagnostics.instance = StartupDiagnostics(
      elapsedMs: () => 42,
      sink: (line) => events.add(jsonDecode(line) as Map<String, dynamic>),
    );
  });
  tearDown(() => StartupDiagnostics.instance = previous);
  List<String> names() => events.map((e) => e['event'] as String).toList();

  testWidgets('first frame, gate and readiness milestones are emitted once',
      (tester) async {
    final c = StartupCoordinator(initialize: () async {});
    await tester.pumpWidget(StartupGate(
        createCoordinator: () => c,
        theme: ThemeData(),
        readyBuilder: (_) => const MaterialApp(home: Text('Ready'))));
    await tester.pumpAndSettle();
    c.start();
    c.retry();
    expect(names(), [
      'flutter.first_frame',
      'startup.gate_activated',
      'math.begin',
      'math.succeeded',
      'application.ready'
    ]);
    expect(events.every((e) => e['elapsed_ms'] == 42), true);
  });

  testWidgets('failure preserves original error and stack; retry can succeed',
      (tester) async {
    final stack = StackTrace.fromString('original-initializer-stack');
    var calls = 0;
    final c = StartupCoordinator(initialize: () {
      if (++calls == 1) return Future.error(StateError('engine failed'), stack);
      return Future.value();
    });
    c.start();
    await tester.pump();
    final failed = events.singleWhere((e) => e['event'] == 'math.failed');
    expect(failed['error_type'], 'StateError');
    expect(failed['message'], contains('engine failed'));
    expect(failed['stack'], 'original-initializer-stack');
    c.retry();
    await tester.pump();
    expect(c.phase, StartupPhase.ready);
    expect(names().where((n) => n == 'math.begin'), hasLength(2));
    expect(names().where((n) => n == 'startup.retry_requested'), hasLength(1));
    c.dispose();
  });

  testWidgets('timeout retry waits on same attempt and accepts late success',
      (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    final c = StartupCoordinator(
        waitLimit: const Duration(seconds: 1),
        initialize: () {
          calls++;
          return pending.future;
        });
    c.start();
    await tester.pump(const Duration(seconds: 1));
    expect(names(), contains('math.timeout'));
    c.retry();
    c.retry();
    expect(calls, 1);
    expect(names().where((n) => n == 'math.begin'), hasLength(1));
    expect(names().where((n) => n == 'startup.retry_requested'), hasLength(1));
    pending.complete();
    await tester.pump();
    expect(c.phase, StartupPhase.ready);
    expect(names().last, 'application.ready');
    c.dispose();
  });

  testWidgets('disposal suppresses late readiness and timeout events',
      (tester) async {
    final pending = Completer<void>();
    final c = StartupCoordinator(initialize: () => pending.future);
    c.start();
    c.dispose();
    final before = names();
    pending.complete();
    await tester.pump(const Duration(seconds: 20));
    expect(names(), before);
  });

  test('record sources and plugin detail payloads are excluded', () {
    StartupDiagnostics.instance.event('home.progress.failed',
        error: const FormatException('Invalid record', 'PRIVATE RECORD'),
        stack: StackTrace.fromString('original-stack'));
    StartupDiagnostics.instance.event('plugin.failed',
        error: PlatformException(
            code: 'failed',
            message: 'Service unavailable',
            details: {'secret': 'PRIVATE DETAILS'}));
    final text = jsonEncode(events);
    expect(text, isNot(contains('PRIVATE')));
    expect(text, contains('Invalid record'));
    expect(text, contains('original-stack'));
    expect(text, contains('Service unavailable'));
  });

  test(
      'hooks preserve existing reports and handled result despite a broken sink',
      () {
    final oldFlutter = FlutterError.onError;
    final oldPlatform = PlatformDispatcher.instance.onError;
    var flutterCalls = 0, platformCalls = 0;
    final error = StateError('original');
    final stack = StackTrace.fromString('original-stack');
    FlutterError.onError = (details) {
      flutterCalls++;
      expect(identical(details.exception, error), true);
      expect(identical(details.stack, stack), true);
    };
    PlatformDispatcher.instance.onError = (e, s) {
      platformCalls++;
      expect(identical(e, error), true);
      expect(identical(s, stack), true);
      return true;
    };
    final d = StartupDiagnostics(sink: (_) => throw StateError('sink failed'));
    final restore = d.installErrorHandlers();
    try {
      FlutterError
          .onError!(FlutterErrorDetails(exception: error, stack: stack));
      expect(PlatformDispatcher.instance.onError!(error, stack), true);
      expect(flutterCalls, 1);
      expect(platformCalls, 1);
    } finally {
      restore();
      FlutterError.onError = oldFlutter;
      PlatformDispatcher.instance.onError = oldPlatform;
    }
  });

  test(
      'no prior platform handler leaves errors unhandled; recursive sink is bounded',
      () {
    final old = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = null;
    var calls = 0;
    late StartupDiagnostics d;
    d = StartupDiagnostics(sink: (_) {
      calls++;
      d.event('recursive');
    });
    final restore = d.installErrorHandlers();
    try {
      expect(
          PlatformDispatcher.instance.onError!(
              StateError('test'), StackTrace.current),
          false);
      expect(calls, 1);
    } finally {
      restore();
      PlatformDispatcher.instance.onError = old;
    }
  });
  test(
      'framework fallback reports normally and cleanup preserves later handlers',
      () {
    final oldFlutter = FlutterError.onError;
    final oldPresent = FlutterError.presentError;
    var reported = 0;
    FlutterError.onError = null;
    FlutterError.presentError = (_) => reported++;
    final restore = StartupDiagnostics.instance.installErrorHandlers();
    void later(FlutterErrorDetails _) {}
    try {
      FlutterError
          .onError!(FlutterErrorDetails(exception: StateError('failure')));
      expect(reported, 1);
      FlutterError.onError = later;
      restore();
      expect(identical(FlutterError.onError, later), true);
    } finally {
      restore();
      FlutterError.onError = oldFlutter;
      FlutterError.presentError = oldPresent;
    }
  });

  test('prior reporting handler exceptions are not swallowed', () {
    final old = FlutterError.onError;
    final reportingError = StateError('previous handler failed');
    FlutterError.onError = (_) => throw reportingError;
    final restore = StartupDiagnostics.instance.installErrorHandlers();
    try {
      expect(
          () => FlutterError
              .onError!(FlutterErrorDetails(exception: StateError('original'))),
          throwsA(same(reportingError)));
      expect(events.single['message'], contains('original'));
    } finally {
      restore();
      FlutterError.onError = old;
    }
  });
}
