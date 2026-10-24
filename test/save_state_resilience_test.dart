import 'package:quantumquiz/screens/home_page.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_save_queue.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/circuit_save_status.dart';
import 'package:quantumquiz/widgets/progress_save_feedback.dart';

class ControlledProgressStore extends InMemoryCampaignProgressStore {
  bool fail = false;
  Completer<void>? wait;
  int active = 0;
  int peak = 0;
  @override
  Future<void> save(CampaignProgressState state) async {
    active++;
    if (active > peak) peak = active;
    try {
      await wait?.future;
      if (fail) throw StateError('write rejected');
      await super.save(state);
    } finally {
      active--;
    }
  }
}

SandboxCircuitSnapshot snapshot(int count) {
  final circuit = QuantumCircuit(currentLevel: createSandboxComposerLevel(1));
  for (var i = 0; i < count; i++) {
    circuit.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x), i, 0);
  }
  final result = SandboxCircuitSnapshot.capture(circuit);
  circuit.dispose();
  return result;
}

void main() {
  test(
      'progress publishes only after acknowledgement; concurrent edits serialize',
      () async {
    final store = ControlledProgressStore()..wait = Completer<void>();
    final controller = CampaignProgressController(store: store);
    await controller.load();
    final first = controller.completeLesson(1);
    final second = controller.completeLesson(2);
    await Future<void>.delayed(Duration.zero);
    expect(controller.saveStatus, ProgressSaveStatus.pending);
    expect(controller.state.completedLessonIds, isEmpty);
    expect((await store.load()).completedLessonIds, isEmpty);
    store.wait!.complete();
    await Future.wait([first, second]);
    expect(controller.state.completedLessonIds, {1, 2});
    expect(controller.saveStatus, ProgressSaveStatus.saved);
    expect(store.peak, 1);
  });

  test(
      'failed progress retains confirmed state; retry is idempotent with newer completion',
      () async {
    final store = ControlledProgressStore();
    final controller = CampaignProgressController(store: store);
    await controller.load();
    await controller.completeLesson(1);
    final before = controller.state;
    store.fail = true;
    await expectLater(controller.completeLesson(2), throwsStateError);
    expect(identical(controller.state, before), true);
    expect(controller.saveStatus, ProgressSaveStatus.failed);
    expect((await store.load()).completedLessonIds, {1});
    store.fail = false;
    await controller.completeLesson(2);
    await controller.retrySave();
    expect(controller.state.completedLessonIds, {1, 2});
    expect(controller.unlockedDiscoveryTitles(), hasLength(2));
    expect((await store.load()).completedLessonIds, {1, 2});
  });

  test('late progress completion after controller disposal is safe', () async {
    final store = ControlledProgressStore()..wait = Completer<void>();
    final controller = CampaignProgressController(store: store);
    final save = controller.completeLesson(1);
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    store.wait!.complete();
    await save;
    expect((await store.load()).completedLessonIds, {1});
  });

  test('rapid snapshots coalesce and never overlap; latest wins', () async {
    final blocker = Completer<void>();
    final writes = <int>[];
    final queue = CircuitSaveQueue((value) async {
      writes.add(value.operations.length);
      if (writes.length == 1) await blocker.future;
    });
    final first = queue.save(snapshot(1));
    await Future<void>.delayed(Duration.zero);
    queue.save(snapshot(2));
    queue.save(snapshot(3));
    expect(writes, [1]);
    expect(queue.status, CircuitSaveStatus.pending);
    blocker.complete();
    await first;
    expect(writes, [1, 3]);
    expect(queue.status, CircuitSaveStatus.saved);
  });

  test('failed in-flight write retains newer snapshot for retry', () async {
    final blocker = Completer<void>();
    var fail = true;
    SandboxCircuitSnapshot? persisted;
    final queue = CircuitSaveQueue((value) async {
      await blocker.future;
      if (fail) throw StateError('disk');
      persisted = value;
    });
    final save = queue.save(snapshot(1));
    await Future<void>.delayed(Duration.zero);
    queue.save(snapshot(3));
    blocker.complete();
    await save;
    expect(queue.status, CircuitSaveStatus.failed);
    expect(persisted, isNull);
    fail = false;
    await queue.retry();
    expect(persisted!.operations, hasLength(3));
    expect(queue.status, CircuitSaveStatus.saved);
  });

  testWidgets(
      'circuit status exposes failure and retry; disposal during save is safe',
      (tester) async {
    var fail = true;
    Completer<void>? blocker;
    final queue = CircuitSaveQueue((_) async {
      await blocker?.future;
      if (fail) throw StateError('disk');
    });
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CircuitSaveStatusView(queue: queue))));
    await queue.save(snapshot(1));
    await tester.pump();
    expect(find.text('Circuit not saved. Please retry.'), findsOneWidget);
    expect(find.text('Circuit saved'), findsNothing);
    fail = false;
    blocker = Completer<void>();
    await tester.tap(find.text('Retry save'));
    await tester.pump();
    expect(find.text('Saving circuit…'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    queue.dispose();
    blocker.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(queue.status, CircuitSaveStatus.saved);
  });

  testWidgets('progress error feedback retries without a false saved state',
      (tester) async {
    final store = ControlledProgressStore()..fail = true;
    final controller = CampaignProgressController(store: store);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ProgressSaveStatusView(controller: controller))));
    await expectLater(controller.completeLesson(1), throwsStateError);
    await tester.pump();
    expect(find.text('Progress not saved. Please retry.'), findsOneWidget);
    store.fail = false;
    await tester.tap(find.text('Retry save'));
    await tester.pumpAndSettle();
    expect(controller.state.completedLessonIds, {1});
    expect(find.text('Progress not saved. Please retry.'), findsNothing);
  });
  testWidgets(
      'Home reflects confirmed retry without displaying uncommitted progress',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final store = ControlledProgressStore();
    final controller = CampaignProgressController(store: store);
    await tester.pumpWidget(
        MaterialApp(home: HomePage(progressController: controller)));
    await tester.pumpAndSettle();
    expect(find.text('Next: Lesson 1'), findsOneWidget);
    store.fail = true;
    await expectLater(controller.completeLesson(1), throwsStateError);
    await tester.pump();
    expect(find.text('Next: Lesson 1'), findsOneWidget);
    store.fail = false;
    await tester.tap(find.text('Retry save'));
    await tester.pumpAndSettle();
    expect(find.text('Next: Lesson 2'), findsOneWidget);
    expect(find.text('Progress not saved. Please retry.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
