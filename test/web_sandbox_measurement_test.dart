import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/measurement_results_view.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';

class DelayedStorage extends InMemoryAppStorage {
  Completer<void>? pendingSave;
  @override
  Future<void> writeString(String key, String value) async {
    if (pendingSave != null) await pendingSave!.future;
    await super.writeString(key, value);
  }
}

final run = find.byKey(const ValueKey('web-sandbox-run-measure'));
final results = find.byType(MeasurementResultsView);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openSandbox(WidgetTester tester, InMemoryAppStorage storage,
    {Size size = const Size(1440, 1000),
    double scale = 1,
    int qubits = 2}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(QubitQuestWebApp(storage: storage));
  await tester.pumpAndSettle();
  if (find.byKey(const ValueKey('web-navigation-menu')).evaluate().isNotEmpty) {
    await tapVisible(tester, find.byKey(const ValueKey('web-navigation-menu')));
  }
  await tapVisible(tester, find.byKey(const ValueKey('web-nav-composer')));
  await tapVisible(tester, find.byKey(ValueKey('web-composer-qubits-$qubits')));
  // Override scale at the existing MediaQuery boundary without changing app code.
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'no-op, rejected edits and Inspector interactions retain result; simulation error refuses run',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
    expect(find.text('Run 100 shots'), findsOneWidget);
    await tapVisible(tester, run);
    final result = tester.widget<MeasurementResultsView>(results).result;
    final canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    // Clearing an already empty circuit is a no-op.
    await tapVisible(tester, find.byKey(const ValueKey('web-clear-circuit')));
    expect(tester.widget<MeasurementResultsView>(results).result, same(result));
    await canvas.onDropRequested(ComposerCircuitDropIntent(
      data: CircuitDragData.palette(Gate.fromIdentifier(SelectedGateType.x)),
      destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 99, column: 0)),
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<MeasurementResultsView>(results).result, same(result));
    await tapVisible(tester, find.text('Bloch'));
    expect(tester.widget<MeasurementResultsView>(results).result, same(result));
    await tapVisible(tester, find.text('State'));
    final stateDisplay = tester.widget<StateVectorDisplay>(
        find.byKey(const ValueKey('web-composer-current-state')));
    stateDisplay.onNonZeroOnlyChanged!(false);
    await tester.pumpAndSettle();
    expect(tester.widget<MeasurementResultsView>(results).result, same(result));
    final ideal = canvas.circuit.currentState;
    canvas.circuit.lastSimulationError = const MalformedCircuitException(
      gateType: SelectedGateType.rx,
      columnIndex: 0,
      qubitIndex: 0,
      parameterName: 'angle',
    );
    await tapVisible(tester, run);
    expect(results, findsNothing);
    expect(canvas.circuit.currentState, same(ideal));
  });

  testWidgets(
      'fresh zero and X measure without affecting progress or edit simulation',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
    final app = tester.widget<QubitQuestWebApp>(find.byType(QubitQuestWebApp));
    final progress = app.progressController.state;
    var progressNotifications = 0;
    void onProgress() => progressNotifications++;
    app.progressController.addListener(onProgress);
    addTearDown(() => app.progressController.removeListener(onProgress));
    final canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    final initialState = canvas.circuit.currentState;
    final initialRuns = canvas.circuit.simulationRunCount;
    await tapVisible(tester, run);
    expect(tester.widget<MeasurementResultsView>(results).result.counts,
        {'0': 100});
    expect(canvas.circuit.currentState, same(initialState));
    expect(canvas.circuit.simulationRunCount, initialRuns);
    await canvas.onDropRequested(ComposerCircuitDropIntent(
      data: CircuitDragData.palette(Gate.fromIdentifier(SelectedGateType.x)),
      destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0)),
    ));
    await tester.pumpAndSettle();
    expect(results, findsNothing);
    expect(canvas.circuit.simulationRunCount, initialRuns + 1);
    expect(canvas.circuit.currentState.stateVector[1].magnitude, 1);
    final preparedState = canvas.circuit.currentState;
    await tapVisible(tester, run);
    expect(tester.widget<MeasurementResultsView>(results).result.counts,
        {'1': 100});
    expect(canvas.circuit.currentState, same(preparedState));
    expect(canvas.circuit.simulationRunCount, initialRuns + 1);
    expect(app.progressController.state, same(progress));
    expect(progressNotifications, 0);
  });

  testWidgets(
      'run observes state; insert clears; persistence restores only circuit',
      (tester) async {
    final storage = InMemoryAppStorage();
    final seed = QuantumCircuit(
        currentLevel: createSandboxComposerLevel(2, initialBinaryState: '01'));
    await SandboxPersistenceStore(storage: storage).saveCircuit(seed);
    seed.dispose();
    await openSandbox(tester, storage);
    final canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    final state = canvas.circuit.currentState;
    final simulations = canvas.circuit.simulationRunCount;
    final key = SandboxPersistenceStore.storageKeyForQubitCount(2);
    final before = await storage.readString(key);
    expect(results, findsNothing);
    await tapVisible(tester, run);
    expect(results, findsOneWidget);
    expect(tester.widget<MeasurementResultsView>(results).result.counts,
        {'01': 100});
    expect(canvas.circuit.currentState, same(state));
    expect(canvas.circuit.simulationRunCount, simulations);
    expect(await storage.readString(key), before);
    expect(
        tester
            .widget<StateVectorDisplay>(
                find.byKey(const ValueKey('web-composer-current-state')))
            .stateVector,
        same(state.stateVector));
    await tapVisible(tester, run);
    expect(tester.widget<MeasurementResultsView>(results).result.shots, 100);
    await canvas.onDropRequested(ComposerCircuitDropIntent(
      data: CircuitDragData.palette(Gate.fromIdentifier(SelectedGateType.x)),
      destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0)),
    ));
    await tester.pumpAndSettle();
    expect(results, findsNothing);
    await tapVisible(tester, run);
    expect(tester.widget<MeasurementResultsView>(results).result.counts,
        {'00': 100});
    await tapVisible(
        tester, find.byKey(const ValueKey('web-composer-change-qubits')));
    await tapVisible(
        tester, find.byKey(const ValueKey('web-composer-qubits-2')));
    expect(results, findsNothing);
    expect(
        tester
            .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
            .circuit
            .logicalGates,
        hasLength(1));
    await tapVisible(tester, run);
    await tapVisible(tester, find.byKey(const ValueKey('web-clear-circuit')));
    expect(results, findsNothing);
  });

  testWidgets(
      'clears before saving; selection keeps results; leaving discards results',
      (tester) async {
    final storage = DelayedStorage();
    await openSandbox(tester, storage);
    await tapVisible(tester, run);
    var canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    canvas.onGateTap(null);
    await tester.pump();
    expect(results, findsOneWidget);
    storage.pendingSave = Completer<void>();
    final edit = canvas.onDropRequested(ComposerCircuitDropIntent(
      data: CircuitDragData.palette(Gate.fromIdentifier(SelectedGateType.x)),
      destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0)),
    ));
    await tester.pump();
    expect(results, findsNothing);
    storage.pendingSave!.complete();
    await edit;
    storage.pendingSave = null;
    await tester.pumpAndSettle();
    canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    canvas.onGateTap(canvas.circuit.logicalGates.single.toPlacedGateRef());
    await tester.pumpAndSettle();
    await tapVisible(tester, run);
    await tapVisible(tester,
        find.byKey(const ValueKey('web-composer-duplicate-selected-gate')));
    expect(results, findsNothing);
    await tapVisible(tester, run);
    await tapVisible(tester,
        find.byKey(const ValueKey('web-composer-delete-selected-gate')));
    expect(results, findsNothing);
    await tapVisible(tester, run);
    await tapVisible(tester, find.byKey(const ValueKey('web-nav-journey')));
    await tapVisible(tester, find.byKey(const ValueKey('web-nav-composer')));
    expect(results, findsNothing);
    await tapVisible(tester, run);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await openSandbox(tester, storage);
    expect(results, findsNothing);
    expect(
        tester
            .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
            .circuit
            .logicalGates,
        hasLength(1));
  });

  for (final scenario in [
    (const Size(1440, 1000), 1.0),
    (const Size(600, 900), 1.0),
    (const Size(1440, 500), 1.0),
    (const Size(600, 900), 1.5),
    (const Size(1440, 900), 1.5),
  ]) {
    testWidgets(
        'results remain reachable at ${scenario.$1}, scale ${scenario.$2}',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(),
          size: scenario.$1, scale: scenario.$2, qubits: 5);
      await tapVisible(tester, run);
      await tester.ensureVisible(results);
      await tester.pumpAndSettle();
      expect(find.descendant(of: results, matching: find.text('00000')),
          findsOneWidget);
      expect(
          find.descendant(
              of: results, matching: find.text('100/100 · 100.0% observed')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final activity in ['Journey', 'Mastery']) {
    testWidgets('$activity Composer keeps Check and has no measurement',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1000);
      addTearDown(tester.view.reset);
      final level = activity == 'Journey'
          ? getQQLevelById(1)! as ComposerLevel
          : mastery2Catalogue
              .requireBySemanticId('phase_state_uncomputation')
              .levelDefinition as ComposerLevel;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: WebComposerLesson(
        level: level,
        enabled: true,
        onSolved: () async {},
        desktopWorkspace: true,
      ))));
      await tester.pumpAndSettle();
      expect(find.text('Check Circuit'), findsOneWidget);
      expect(run, findsNothing);
      expect(results, findsNothing);
    });
  }
}
