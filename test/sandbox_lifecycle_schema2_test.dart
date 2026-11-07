import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/sandbox_workspace_persistence.dart';
import 'package:quantumquiz/models/circuit_save_queue.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';
import 'package:quantumquiz/widgets/sandbox_load_recovery.dart';
import 'sandbox_activation_test.dart' show FaultStorage, definition;
import 'web_sandbox_measurement_test.dart' show openSandbox, tapVisible;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
      'native measured edits persist after disposal; no misleading state',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final storage = FaultStorage();
    final store = SandboxPersistenceStore(storage: storage);
    final s = definition();
    final controller = QuantumComposerController();
    await tester.pumpWidget(MaterialApp(
        home: QuantumComposer(
            levelId: -1,
            level: createSandboxComposerLevel(2),
            onLevelUnlocked: null,
            sessionOwnership: ComposerSessionOwnership.sandbox,
            initialSandboxProgram: s,
            sandboxPersistenceStore: store,
            controller: controller)));
    await tester.pumpAndSettle();
    if (find.text('Start Composing').evaluate().isNotEmpty) {
      await tester.tap(find.text('Start Composing'));
      await tester.pumpAndSettle();
    }
    expect(find.byType(UnexecutedMeasuredCircuit), findsWidgets);
    expect(find.byType(StateVectorDisplay), findsNothing);
    storage.blocked = Completer<void>();
    // q0 is measured (terminal), so the post-measurement edit targets q1.
    expect(
        controller
            .insertGate(
                gate: Gate.fromIdentifier(SelectedGateType.x),
                location: const CircuitLocation(qubit: 1, column: 2))
            .changed,
        true);
    await tester.pump();
    final q = store.programs.queue(2);
    expect(q.status, CircuitSaveStatus.pending);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    storage.blocked!.complete();
    await q.retry();
    await tester.pumpAndSettle();
    expect(q.status, CircuitSaveStatus.saved);
    expect(tester.takeException(), isNull);
    final loaded = (await SandboxWorkspacePersistence(storage).load(2))!;
    expect(loaded.program.operations.length, 3);
    expect(loaded.program.isUnitary, false);
  });
  testWidgets(
      'Web model measurements save, safe Inspector, switching preserves failed edits',
      (tester) async {
    final store = FaultStorage();
    await openSandbox(tester, store, qubits: 1);
    final canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    canvas.circuit.addMeasurement(column: 0, qubit: 0, classicalBit: 2);
    await tester.pumpAndSettle();
    expect(find.byType(UnexecutedMeasuredCircuit), findsOneWidget);
    expect(find.byType(StateVectorDisplay), findsNothing);
    expect(find.text('Run 100 shots'), findsNothing);
    store.fail = '_stage_';
    canvas.circuit.addMeasurement(column: 1, qubit: 0, classicalBit: 2);
    await tester.pumpAndSettle();
    expect(find.text('Circuit not saved. Please retry.'), findsOneWidget);
    await tapVisible(
        tester, find.byKey(const ValueKey('web-composer-change-qubits')));
    await tapVisible(
        tester, find.byKey(const ValueKey('web-composer-qubits-1')));
    final reopened = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
        .circuit;
    expect(reopened.measurements.length, 2);
    expect(reopened.simulationRunCount, 0);
    store.fail = null;
    await tapVisible(tester, find.text('Retry save'));
    expect(
        (await SandboxWorkspacePersistence(store).load(1))!
            .program
            .operations
            .length,
        2);
    // Terminal measurement: X after q0's measurements is rejected, while X
    // before them is inserted and shifts both measurements right.
    expect(
        reopened
            .insertSingleGateWithOutcome(
                Gate.fromIdentifier(SelectedGateType.x), 2, 0)
            .changed,
        false);
    expect(
        reopened
            .insertSingleGateWithOutcome(
                Gate.fromIdentifier(SelectedGateType.x), 0, 0)
            .changed,
        true);
    expect(reopened.measurements.map((m) => m.column), [1, 2]);
    for (final measurement in reopened.measurements) {
      reopened.removeMeasurement(measurement.id);
    }
    await tester.pumpAndSettle();
    expect(reopened.currentState.stateVector[1].real, closeTo(1, 1e-10));
    await tapVisible(tester, find.byKey(const ValueKey('web-clear-circuit')));
    expect(
        (await SandboxWorkspacePersistence(store).load(1))!.program.operations,
        isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('load error remains explicit and recoverable', (tester) async {
    final storage = FaultStorage();
    await storage.writeString(
        SandboxWorkspacePersistence.activeKey(1), 'invalid');
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () => loadSandboxWithRecovery(
                    context, SandboxWorkspacePersistence(storage), 1),
                child: const Text('Open')))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Sandbox could not be restored'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await storage.readString(SandboxWorkspacePersistence.activeKey(1)),
        'invalid');
  });
}
