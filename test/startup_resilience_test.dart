import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/main.dart';
import 'package:quantumquiz/startup/startup_coordinator.dart';
import 'package:quantumquiz/startup/startup_gate.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

void main() {
  Future<void> mount(WidgetTester tester, StartupCoordinator coordinator,
      {VoidCallback? onReady}) async {
    await tester.pumpWidget(StartupGate(
      createCoordinator: () => coordinator,
      theme: QubitQuestTheme.mobile(),
      readyBuilder: (_) {
        onReady?.call();
        return const MaterialApp(
            home: Scaffold(body: Text('Application ready')));
      },
    ));
  }

  testWidgets('Flutter screen precedes initialization; ready app built once',
      (tester) async {
    final pending = Completer<void>();
    var calls = 0, builds = 0;
    final c = StartupCoordinator(initialize: () {
      calls++;
      expect(find.text('Preparing Qubit Quest…'), findsOneWidget);
      return pending.future;
    });
    await mount(tester, c, onReady: () => builds++);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(builds, 0);
    c.start();
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Application ready'), findsOneWidget);
    c.retry();
    await tester.pump();
    expect(builds, 1);
    expect(calls, 1);
  });

  for (final synchronous in [true, false]) {
    testWidgets('${synchronous ? "sync" : "async"} failure is recoverable',
        (tester) async {
      var calls = 0;
      final c = StartupCoordinator(initialize: () {
        calls++;
        if (calls == 1) {
          if (synchronous) throw StateError('setup failed');
          return Future<void>.error(StateError('setup failed'));
        }
        return Future.value();
      });
      await mount(tester, c);
      await tester.pumpAndSettle();
      expect(find.text('Math setup could not finish.'), findsOneWidget);
      expect(find.text('Application ready'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Application ready'), findsOneWidget);
    });
  }

  testWidgets('never-completing init times out; retries cannot duplicate it',
      (tester) async {
    var calls = 0;
    final c = StartupCoordinator(
      waitLimit: const Duration(seconds: 1),
      initialize: () {
        calls++;
        return Completer<void>().future;
      },
    );
    await mount(tester, c);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Math setup is taking longer than expected.'),
          findsOneWidget);
      expect(find.text('Application ready'), findsNothing);
      await tester.tap(find.text('Retry'));
      c.retry(); // A second tap while loading must do nothing.
      await tester.pump();
      expect(calls, 1);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  for (final retry in [false, true]) {
    testWidgets('late success after timeout (retry=$retry) opens application',
        (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      final c = StartupCoordinator(
        waitLimit: const Duration(seconds: 1),
        initialize: () {
          calls++;
          return pending.future;
        },
      );
      await mount(tester, c);
      await tester.pump(const Duration(seconds: 2));
      if (retry) await tester.tap(find.text('Retry'));
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Application ready'), findsOneWidget);
      expect(calls, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(c.phase, StartupPhase.ready);
    });
  }

  testWidgets('late failure settles operation and permits a new attempt',
      (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    final c = StartupCoordinator(
      waitLimit: const Duration(seconds: 1),
      initialize: () => ++calls == 1 ? pending.future : Future.value(),
    );
    await mount(tester, c);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Retry'));
    pending.completeError(StateError('late failure'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(c.phase, StartupPhase.ready);
  });

  for (final fails in [false, true]) {
    testWidgets('disposed gate ignores late completion (failure=$fails)',
        (tester) async {
      final pending = Completer<void>();
      var builds = 0;
      final c = StartupCoordinator(initialize: () => pending.future);
      await mount(tester, c, onReady: () => builds++);
      await tester.pumpWidget(const SizedBox());
      if (fails) {
        pending.completeError(StateError('late'));
      } else {
        pending.complete();
      }
      await tester.pump(const Duration(seconds: 20));
      expect(builds, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'real orientation channel failure preserves four orientations and readiness',
      (tester) async {
    Object? requested;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          requested = call.arguments;
          throw PlatformException(code: 'orientation unavailable');
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final c = StartupCoordinator(
      initialize: () async {},
      configureOrientation: configureAppOrientation,
    );
    await mount(tester, c);
    await tester.pumpAndSettle();
    expect(requested, [
      'DeviceOrientation.portraitUp',
      'DeviceOrientation.portraitDown',
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(find.text('Application ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orientation that never completes cannot block readiness',
      (tester) async {
    await mount(
        tester,
        StartupCoordinator(
          initialize: () async {},
          configureOrientation: () => Completer<void>().future,
        ));
    await tester.pumpAndSettle();
    expect(find.text('Application ready'), findsOneWidget);
  });
}
