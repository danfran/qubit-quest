import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/screens/web_exercise_workspace.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/widgets/measured_circuit_run_panel.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';
import 'support/laboratory_composer_finders.dart';

class DelayedStorage extends InMemoryAppStorage {
  Completer<void>? pendingSave;
  @override
  Future<void> writeString(String key, String value) async {
    if (pendingSave != null) await pendingSave!.future;
    await super.writeString(key, value);
  }
}

// W4.2: the unified Measure tab. Without M gates, Run shots samples the
// final state (default 1,000 shots).
final run = find.byKey(const ValueKey('web-sandbox-run-shots'));
final results = find.byKey(const ValueKey('web-sandbox-shots-result'));

ShotsOutcome shotsResult(WidgetTester tester) => tester
    .widget<MeasuredCircuitRunPanel>(find.byType(MeasuredCircuitRunPanel))
    .shotsResult!;

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  // Medium workspaces show Circuit or Results; reveal Results when the
  // target is not on screen (the hidden view stays mounted offstage).
  final resultsSegment = find.descendant(
      of: find.byKey(const ValueKey('composer-workspace-view')),
      matching: find.text('Results'));
  if (finder.evaluate().isEmpty && resultsSegment.evaluate().isNotEmpty) {
    await tester.tap(resultsSegment);
    await tester.pumpAndSettle();
  }
  // Run controls live in the Inspector's Measure tab: open it when needed.
  final measureTab = anyMeasureTab;
  if (finder.evaluate().isEmpty && measureTab.evaluate().isNotEmpty) {
    await tapVisible(tester, measureTab);
  }
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
  await pumpUntilSandboxOpen(tester);
  await pumpUntilSandboxOpen(tester);
  await tapVisible(tester, find.byKey(ValueKey('web-composer-qubits-$qubits')));
  // Override scale at the existing MediaQuery boundary without changing app code.
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpAndSettle();
}

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  testWidgets(
      'no-op, rejected edits and Inspector interactions retain result; simulation error refuses run',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
    expect(find.text('State'), findsOneWidget);
    expect(find.text('Bloch'), findsOneWidget);
    expect(find.text('Measure'), findsOneWidget);
    expect(run, findsNothing);
    await tapVisible(tester, find.text('Measure'));
    expect(results, findsNothing);
    expect(find.text('Run shots'), findsOneWidget);
    await tapVisible(tester, run);
    final result = shotsResult(tester);
    final inspector =
        find.byKey(const ValueKey('web-composer-state-inspection'));
    expect(find.descendant(of: inspector, matching: run), findsOneWidget);
    expect(find.descendant(of: inspector, matching: results), findsOneWidget);
    // Run controls and results live together in the Results region.
    final resultsRegion = find.byKey(const ValueKey('composer-region-results'));
    expect(find.descendant(of: resultsRegion, matching: run), findsOneWidget);
    expect(result.readout.isFinalState, isTrue);
    expect(result.counts.values.reduce((a, b) => a + b), 1000);
    final canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    // Clearing an already empty circuit is a no-op.
    await tapVisible(tester, find.byKey(const ValueKey('web-clear-circuit')));
    expect(shotsResult(tester), same(result));
    await canvas.onDropRequested(ComposerCircuitDropIntent(
      data: CircuitDragData.palette(Gate.fromIdentifier(SelectedGateType.x)),
      destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 99, column: 0)),
    ));
    await tester.pumpAndSettle();
    expect(shotsResult(tester), same(result));
    await tapVisible(tester, find.text('Bloch'));
    expect(find.byKey(const ValueKey('quantum-inspector-bloch-view')),
        findsOneWidget);
    expect(results, findsNothing);
    await tapVisible(tester, find.text('Measure'));
    expect(shotsResult(tester), same(result));
    await tapVisible(tester, find.text('State'));
    final stateDisplay = tester.widget<StateVectorDisplay>(
        find.byKey(const ValueKey('web-composer-current-state')));
    stateDisplay.onNonZeroOnlyChanged!(false);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Measure'));
    expect(shotsResult(tester), same(result));
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
    expect(shotsResult(tester).counts, {'0': 1000});
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
    expect(shotsResult(tester).counts, {'1': 1000});
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
    expect(shotsResult(tester).counts, {'01': 1000});
    expect(canvas.circuit.currentState, same(state));
    expect(canvas.circuit.simulationRunCount, simulations);
    expect(await storage.readString(key), before);
    await tapVisible(tester, find.text('State'));
    expect(
        tester
            .widget<StateVectorDisplay>(
                find.byKey(const ValueKey('web-composer-current-state')))
            .stateVector,
        same(state.stateVector));
    await tapVisible(tester, run);
    expect(shotsResult(tester).shots, 1000);
    await canvas.onDropRequested(ComposerCircuitDropIntent(
      data: CircuitDragData.palette(Gate.fromIdentifier(SelectedGateType.x)),
      destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0)),
    ));
    await tester.pumpAndSettle();
    expect(results, findsNothing);
    await tapVisible(tester, run);
    expect(shotsResult(tester).counts, {'00': 1000});
    // M11C: reopen the 2-qubit Sandbox from storage via another size.
    await tapVisible(
        tester, find.byKey(const ValueKey('web-composer-qubits-1')));
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
      'clears before saving; selection keeps results; leaving keeps them '
      '(M6a); a fresh app start has none',
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
    // v2.6 M6a: results belong to the retained session, so another
    // destination does not discard them.
    expect(results, findsOneWidget);
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
    (const Size(1200, 900), 1.0),
    (const Size(1200, 900), 1.5),
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
      final inspectorRect = tester
          .getRect(find.byKey(const ValueKey('web-composer-state-inspection')));
      final selectorRect = tester.getRect(
          find.byKey(const ValueKey('quantum-inspector-view-selector')));
      expect(selectorRect.left, greaterThanOrEqualTo(inspectorRect.left));
      expect(selectorRect.right, lessThanOrEqualTo(inspectorRect.right));
      await tester.ensureVisible(results);
      await tester.pumpAndSettle();
      expect(find.descendant(of: results, matching: find.text('|00000⟩')),
          findsOneWidget);
      // M4: exact, observed and count columns (was "1,000 · 100.0%").
      expect(
          find.descendant(
              of: results,
              matching: find.byKey(
                  const ValueKey('web-sandbox-outcome-count-00000'))),
          findsOneWidget);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('web-sandbox-outcome-count-00000')))
              .data,
          '1,000');
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('measure-observed-00000')))
              .data,
          '100%');
      expect(tester.takeException(), isNull);
      final canvas = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
      for (var qubit = 0; qubit < 5; qubit++) {
        await canvas.onDropRequested(ComposerCircuitDropIntent(
          data: CircuitDragData.palette(
              Gate.fromIdentifier(SelectedGateType.hadamard)),
          destination: CircuitDropDestination(
              contentPoint: const Offset(40, 20),
              location: CircuitLocation(qubit: qubit, column: 0)),
        ));
      }
      await tester.pumpAndSettle();
      final surface = find.byKey(const ValueKey('composer-region-canvas'));
      final heightBeforeRun = tester.getSize(surface).height;
      await tapVisible(tester, run);
      final result = shotsResult(tester);
      expect(result.counts.values.reduce((a, b) => a + b), 1000);
      // Rows beyond 8 live in the histogram's own scrolling list.
      expect(find.byKey(const ValueKey('web-sandbox-outcomes-scroll')),
          findsOneWidget);
      await tester.ensureVisible(results);
      await tester.pumpAndSettle();
      // The circuit card never resizes for Inspector results.
      expect(tester.getSize(surface).height, heightBeforeRun);
      for (final region in [
        'composer-region-canvas',
        'composer-region-inspector'
      ]) {
        expect(find.descendant(of: find.byKey(ValueKey(region)), matching: run),
            findsNothing,
            reason: 'Run controls are never duplicated outside Results');
      }
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
              body: WebComposerExercise(
        level: level,
        mode: activity == 'Journey'
            ? ComposerMode.journeyExercise
            : ComposerMode.masteryChallenge,
        contextLabel: activity,
        onCompleted: () async {},
        onNext: () {},
        onOpenNotebook: () {},
      ))));
      await tester.pumpAndSettle();
      expect(find.text('Check Circuit'), findsOneWidget);
      // No Measure view and no M in the palette for exercises.
      expect(find.text('Measure'), findsNothing);
      expect(run, findsNothing);
      expect(results, findsNothing);
    });
  }
}
