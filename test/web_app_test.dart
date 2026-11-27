import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/bloch_lab.dart';
import 'package:quantumquiz/screens/web_bloch_workspace.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/sandbox_workspace_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/rotation_gate_dialog.dart';
import 'package:quantumquiz/screens/two_qubits_gate_target_qubit_selection_dialog.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/circuit_layout_metrics.dart';
import 'support/journey_navigation.dart';
import 'package:quantumquiz/screens/web_journey_overview.dart';
import 'support/laboratory_composer_finders.dart';

// The metrics request a preferred height; the shared workbench can constrain it.
// Check the actual constraint contract AND complete drawing/hit-area containment.
/// The M3 canvas fills its workspace region; whatever the region size,
/// every wire, gate and hit area of [qubits] must fit inside it.
void expectCanvasFits(WidgetTester tester, int qubits) {
  final canvas = find.byKey(const ValueKey('web-composer-canvas'));
  final rect = tester.getRect(canvas);
  expect(rect.height,
      greaterThanOrEqualTo(CircuitLayoutMetrics.drawingHeight(qubits)),
      reason: 'All wires, gates and shadows must fit, even under constraints.');
  final hitArea =
      tester.getRect(find.byKey(const ValueKey('circuit-interaction-surface')));
  expect(hitArea.top, greaterThanOrEqualTo(rect.top));
  expect(hitArea.bottom, lessThanOrEqualTo(rect.bottom));
  final lastWireHitBottom = hitArea.top +
      CircuitLayoutMetrics.wireCenterY(qubits - 1) +
      CircuitLayoutMetrics.hitTolerance;
  expect(lastWireHitBottom, lessThanOrEqualTo(rect.bottom),
      reason: 'The last qubit must retain its complete interaction area.');
  expect(tester.takeException(), isNull);
}

class _FailingCircuitStorage extends InMemoryAppStorage {
  bool fail = false;
  @override
  Future<void> writeString(String key, String value) async {
    // Covers legacy schema-1 keys and schema-2 staging/active/recovery keys.
    if (fail && key.startsWith('sandbox_circuit')) {
      throw StateError('save rejected');
    }
    await super.writeString(key, value);
  }
}

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  Future<void> setSize(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(QubitQuestWebApp(storage: InMemoryAppStorage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('wide shell defaults to Journey and switches workspaces',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);

    void expectNoGlobalLevel() {
      // M11C shell v2: wide layouts have no top bar; the brand heads the
      // navigation instead.
      expect(find.byType(AppBar), findsNothing);
      expect(
          find.descendant(
              of: find.byType(AppBar),
              matching: find.textContaining(RegExp(r'Level \d+'))),
          findsNothing);
      expect(find.text('Loading journey…'), findsNothing);
    }

    expectNoGlobalLevel();

    expect(
        find.byKey(const ValueKey('web-navigation-sidebar')), findsOneWidget);
    expect(find.byType(WebJourneyOverview), findsOneWidget);

    await openJourneyChapter(tester, 1);
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1 of 5'), findsOneWidget);
    expect(find.text('0 / 5 complete'), findsOneWidget);
    expectNoGlobalLevel();

    await tester.tap(find.byKey(const ValueKey('web-nav-mastery')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('web-mastery-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-mastery-overview')), findsOneWidget);
    expect(
        find.byKey(
            const ValueKey('web-mastery-activity-global_phase_equivalence')),
        findsNothing);
    // M6a: a library row selects; the details' Start opens the challenge.
    await tester.tap(find.byKey(
        const ValueKey('web-mastery-challenge-global_phase_equivalence')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(
            const ValueKey('web-mastery-activity-global_phase_equivalence')),
        findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('web-mastery-start')));
    await tester.tap(find.byKey(const ValueKey('web-mastery-start')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(
            const ValueKey('web-mastery-activity-global_phase_equivalence')),
        findsOneWidget);
    expectNoGlobalLevel();

    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    // M11C: the Composer opens straight into the Sandbox.
    expect(find.byKey(const ValueKey('web-composer-opening')), findsOneWidget);
    expectNoGlobalLevel();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-3')));
    await tester.pump();
    expect(find.byType(ComposerGatePalettePanel), findsOneWidget);
    expect(find.byType(ComposerCircuitCanvas), findsOneWidget);
    expect(
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .enableDesktopHorizontalScrolling,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();
    expectNoGlobalLevel();
    expect(find.byType(BlochSpherePanel), findsOneWidget);
    expect(find.byType(WebBlochWorkspace), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-evolution')), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-state')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
    await tester.pump();
    expect(find.byType(WebNotebookWorkspace), findsOneWidget);
    expectNoGlobalLevel();
  });

  testWidgets('narrow shell uses a drawer instead of permanent navigation',
      (tester) async {
    await setSize(tester, const Size(600, 900));
    await pumpApp(tester);

    expect(find.byKey(const ValueKey('web-navigation-sidebar')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('web-navigation-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('web-navigation-drawer')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pumpAndSettle();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-2')));
    await tester.pump();
    expect(find.byType(ComposerCircuitCanvas), findsOneWidget);
    expect(find.byKey(const ValueKey('web-navigation-drawer')), findsNothing);
  });

  testWidgets(
      'Web Sandbox exposes failed clear and retries without losing saved data',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    final storage = _FailingCircuitStorage();
    final store = SandboxPersistenceStore(storage: storage);
    final circuit = QuantumCircuit(currentLevel: createSandboxComposerLevel(1));
    circuit.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x), 0, 0);
    await store.saveCircuit(circuit);
    storage.fail = true;
    await tester.pumpWidget(QubitQuestWebApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pumpAndSettle();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Circuit not saved. Please retry.'), findsOneWidget);
    // Schema 2 owns Sandbox saves; a fresh reader still sees the saved gate.
    expect(
        (await SandboxWorkspacePersistence(storage).load(1))!
            .program
            .operations,
        hasLength(1));
    storage.fail = false;
    await tester.ensureVisible(find.text('Retry save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry save'));
    await tester.pumpAndSettle();
    expect(
        (await SandboxWorkspacePersistence(storage).load(1))!
            .program
            .operations,
        isEmpty);
    expect(find.text('Circuit saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Composer restores the existing Sandbox workspace',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    final storage = InMemoryAppStorage();
    final circuit = QuantumCircuit(currentLevel: createSandboxComposerLevel(3));
    circuit.insertSingleGateWithOutcome(
      Gate.fromIdentifier(SelectedGateType.hadamard),
      0,
      1,
    );
    await SandboxPersistenceStore(storage: storage).saveCircuit(circuit);

    await tester.pumpWidget(QubitQuestWebApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-3')));
    await tester.pump();

    expect(find.text('Restored 1 saved operation(s).'), findsOneWidget);
  });

  testWidgets('wide Composer gives the circuit the largest region',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-3')));
    await tester.pump();

    final palette =
        tester.getRect(find.byKey(const ValueKey('composer-region-palette')));
    final canvas =
        tester.getRect(find.byKey(const ValueKey('composer-region-canvas')));
    final results =
        tester.getRect(find.byKey(const ValueKey('composer-region-results')));
    final inspector =
        tester.getRect(find.byKey(const ValueKey('composer-region-inspector')));
    expect(palette.right, lessThan(canvas.left));
    expect(canvas.right, lessThan(results.left));
    expect(inspector.top, greaterThan(canvas.bottom - 1));
    expect((inspector.left, inspector.right), (canvas.left, canvas.right));
    expect(canvas.width, greaterThan(palette.width));
    expect(canvas.width, greaterThan(results.width));
    expectCanvasFits(tester, 3);

    final paletteWidget = tester.widget<ComposerGatePalettePanel>(
        find.byType(ComposerGatePalettePanel));
    expect(
      paletteWidget.gates.map((gate) => gate.type),
      orderedEquals(sandboxGatePaletteTypes),
    );
    expect(paletteWidget.allowsMeasurement, isTrue);

    final pointerArea = tester.widget<MouseRegion>(
      find.byKey(const ValueKey('web-composer-canvas-pointer-area')),
    );
    expect(pointerArea.cursor, SystemMouseCursors.precise);
    expect(
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .surfaceTreatment,
      ComposerCircuitSurfaceTreatment.workbench,
    );
    expect(
      find.byKey(const ValueKey('circuit-horizontal-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-composer-current-state')),
      findsOneWidget,
    );
  });

  testWidgets(
      'Web Composer canvas fits every qubit count and ignores circuit content',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    final storage = InMemoryAppStorage();
    final populated =
        QuantumCircuit(currentLevel: createSandboxComposerLevel(5));
    populated.insertDoubleGateWithOutcome(
      Gate.fromIdentifier(SelectedGateType.cnot),
      0,
      4,
      0,
    );
    populated.insertTripleGateWithOutcome(
      Gate.fromIdentifier(SelectedGateType.ccnot),
      1,
      3,
      0,
      1,
    );
    await SandboxPersistenceStore(storage: storage).saveCircuit(populated);
    populated.dispose();

    await tester.pumpWidget(QubitQuestWebApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();

    Future<double> openAndMeasure(int qubitCount) async {
      await pumpUntilSandboxOpen(tester);
      await tester.tap(
        find.byKey(ValueKey('web-composer-qubits-$qubitCount')),
      );
      await tester.pump();
      return tester
          .getSize(find.byKey(const ValueKey('web-composer-canvas')))
          .height;
    }

    final populatedFiveQubitHeight = await openAndMeasure(5);
    expectCanvasFits(tester, 5);
    final canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    expect(canvas.circuit.logicalGates, hasLength(2));
    expect(
      canvas.circuit.logicalGates.every((gate) => gate.hasValidTopology(5)),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('web-clear-circuit')));
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey('web-composer-canvas'))).height,
      populatedFiveQubitHeight,
    );
    expect(
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .circuit
          .isCircuitEmpty(),
      isTrue,
    );

    final oneQubitHeight = await openAndMeasure(1);
    expectCanvasFits(tester, 1);

    final twoQubitHeight = await openAndMeasure(2);
    expectCanvasFits(tester, 2);
    // The canvas is content-sized (M3.1): it grows with the qubit count.
    // (Before M11C this test measured the previous session's canvas one
    // frame after the switch, so the heights looked equal.)
    expect(twoQubitHeight, greaterThan(oneQubitHeight));
    expect(populatedFiveQubitHeight, greaterThan(twoQubitHeight));
    expect(CircuitLayoutMetrics.drawingHeight(5),
        greaterThan(CircuitLayoutMetrics.drawingHeight(2)));
  });

  testWidgets('Web Composer keeps canonical gate inspection available',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-3')));
    await tester.pump();

    // Palette click previews the gate; the canonical educational content
    // (shared with GateInspectorDialog) is available inline, in the
    // inspector's Mathematics and Learn sections, without placing anything
    // or opening a modal (M3.1).
    await tester.tap(find.byKey(const ValueKey('composer-palette-gate-x')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('composer-inspector-preview')),
        findsOneWidget);
    await tester.tap(
        find.byKey(const ValueKey('composer-inspector-tab-mathematics')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('composer-math-matrix')), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('composer-inspector-tab-learn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('composer-learn-visual')), findsOneWidget);

    expect(find.byType(GateInspectorDialog), findsNothing);
    final circuit = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
        .circuit;
    expect(circuit.isCircuitEmpty(), isTrue, reason: 'preview never places');
  });

  testWidgets('Web Composer places rotations at π/2 and edits them inline',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-1')));
    await tester.pump();

    var canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    await canvas.onDropRequested(
      ComposerCircuitDropIntent(
        data: CircuitDragData.palette(
          Gate.fromIdentifier(SelectedGateType.rx),
        ),
        destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RotationGateDialog), findsNothing);

    canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    expect(canvas.circuit.logicalGates.single.gate.angle,
        closeTo(math.pi / 2, 1e-12));
    expect(
      find.byKey(const ValueKey('web-composer-selected-rotation-angle')),
      findsOneWidget,
    );
    final field = find.byKey(const ValueKey('composer-angle-field'));
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, '1/4 π');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(canvas.circuit.logicalGates.single.gate.angle,
        closeTo(math.pi / 4, 1e-12));
  });

  testWidgets(
      'controlled selection exposes active desktop actions and topology',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-2')));
    await tester.pump();

    var canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    await canvas.onDropRequested(
      ComposerCircuitDropIntent(
        data: CircuitDragData.palette(
          Gate.fromIdentifier(SelectedGateType.cnot),
        ),
        destination: const CircuitDropDestination(
          contentPoint: Offset(40, 60),
          location: CircuitLocation(qubit: 1, column: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(TwoQubitsGateTargetQubitSelectionDialog),
      findsNothing,
    );

    canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    final controlled = canvas.circuit.logicalGates.single;
    expect(controlled.hasValidTopology(2), isTrue);
    canvas.onGateTap(controlled.toPlacedGateRef());
    await tester.pump();

    expect(find.text('Control q0 → target q1'), findsOneWidget);
    // M3.1: educational inspection is the inspector's inline tabs.
    expect(
      find.byKey(const ValueKey('composer-inspector-tabs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-composer-duplicate-selected-gate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-composer-delete-selected-gate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-composer-replace-selected-gate')),
      findsNothing,
    );
  });

  testWidgets('Sandbox commands commit once through the live circuit',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-2')));
    await tester.pump();

    var canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    final circuit = canvas.circuit;
    final initialRuns = circuit.simulationRunCount;
    await canvas.onDropRequested(
      ComposerCircuitDropIntent(
        data: CircuitDragData.palette(
          Gate.fromIdentifier(SelectedGateType.hadamard),
        ),
        destination: const CircuitDropDestination(
          contentPoint: Offset(240, 20),
          location: CircuitLocation(qubit: 0, column: 5),
        ),
      ),
    );
    await tester.pump();
    expect(circuit.simulationRunCount, initialRuns + 1);
    expect(circuit.logicalGates.single.column, 0);

    var selected = circuit.logicalGates.single;
    canvas.onGateTap(selected.toPlacedGateRef());
    // The inspector eases from its compact idle height (M3.1).
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('web-composer-duplicate-selected-gate')),
    );
    await tester.pump();
    expect(circuit.simulationRunCount, initialRuns + 2);
    expect(circuit.logicalGates, hasLength(2));

    // M3.1: replacement is the inspector's anchored menu.
    await tester.tap(
      find.byKey(const ValueKey('web-composer-replace-selected-gate')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('composer-replace-with-x')),
    );
    await tester.pumpAndSettle();
    expect(circuit.simulationRunCount, initialRuns + 3);
    expect(
      circuit.logicalGates.map((gate) => gate.type),
      containsAll([SelectedGateType.hadamard, SelectedGateType.x]),
    );

    selected = circuit.logicalGates.singleWhere(
      (gate) => gate.type == SelectedGateType.x,
    );
    canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    await canvas.onDropRequested(
      ComposerCircuitDropIntent(
        data: CircuitDragData.placed(
          sourceId: selected.id,
          gate: selected.gate,
        ),
        destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0),
        ),
      ),
    );
    await tester.pump();
    expect(circuit.simulationRunCount, initialRuns + 4);
    expect(circuit.logicalGateById(selected.id)!.column, 0);

    canvas.onGateTap(circuit.logicalGateById(selected.id)!.toPlacedGateRef());
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('web-composer-delete-selected-gate')),
    );
    await tester.pump();
    expect(circuit.simulationRunCount, initialRuns + 5);
    expect(circuit.logicalGateById(selected.id), isNull);
    expect(circuit.logicalGates, hasLength(1));
  });

  testWidgets('Notebook selection survives switching Web workspaces',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    final entry = notebookEntries.first;
    final second = notebookEntries[1];
    await CampaignProgressController.instance
        .unlockDiscovery(entry.discoveryTitle);
    await CampaignProgressController.instance
        .unlockDiscovery(second.discoveryTitle);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
    await tester.pump();
    // M6b: the index is persistent; chapters expand in place.
    await tester.tap(find.byKey(
        ValueKey('web-notebook-category-chapter-${entry.chapterIndex}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('web-notebook-entry-${entry.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('web-notebook-reader-${entry.id}')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
    await tester.pump();

    expect(find.byKey(ValueKey('web-notebook-reader-${entry.id}')),
        findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('web-notebook-search-field')),
      second.title,
    );
    await tester.pump();
    expect(find.byKey(ValueKey('web-notebook-search-${second.id}')),
        findsOneWidget);
  });

  testWidgets(
      'Notebook X example opens an in-Notebook experiment and the Bloch host',
      (tester) async {
    await setSize(tester, const Size(1440, 1100));
    await pumpApp(tester);
    final entry = notebookEntries.first;
    await CampaignProgressController.instance
        .unlockDiscovery(entry.discoveryTitle);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
    await tester.pump();
    await tester.tap(find.byKey(
        ValueKey('web-notebook-category-chapter-${entry.chapterIndex}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('web-notebook-entry-${entry.id}')));
    await tester.pumpAndSettle();

    // M6b: Explore circuit opens the shared workspace inside the Notebook;
    // the Composer destination (Sandbox) is not involved.
    final explore = find.byKey(const ValueKey('notebook-explore-x_from_zero'));
    await tester.ensureVisible(explore);
    await tester.pumpAndSettle();
    await tester.tap(explore);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notebook-experiment-workspace')),
        findsOneWidget);
    expect(find.text('Choose Number of Qubits', skipOffstage: false),
        findsOneWidget,
        reason: 'the Sandbox was never opened or replaced');
    expect(find.byKey(const ValueKey('web-lesson-check')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('notebook-experiment-back')));
    await tester.pumpAndSettle();
    final bloch = find.byKey(const ValueKey('bloch-example-x_from_zero'));
    await tester.ensureVisible(bloch);
    await tester.pumpAndSettle();
    await tester.tap(bloch);
    await tester.pumpAndSettle();
    final canvas = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    expect((canvas.painter! as BlochSpherePainter).state.z, closeTo(-1, .001));
  });

  // v2.6 M8: the Bloch Explorer is a state laboratory. Its behaviour is
  // covered in depth by test/v26_m8_bloch_lab_test.dart; these keep the
  // shell-level guarantees of the earlier tests.
  testWidgets('Bloch: preview then Apply commits exactly one step',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pumpAndSettle();
    final lab = tester.state<WebBlochWorkspaceState>(
        find.byType(WebBlochWorkspace));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    expect(find.byKey(const ValueKey('bloch-preview-card')), findsOneWidget);
    expect(lab.session.appliedCount, 0, reason: 'a preview records nothing');
    await tester.tap(find.byKey(const ValueKey('bloch-apply')));
    await tester.pumpAndSettle();
    expect(lab.session.appliedCount, 1);
    expect(lab.session.current.x, closeTo(1, 1e-9));
    final canvas = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    expect((canvas.painter! as BlochSpherePainter).state.x, closeTo(1, 1e-9));
  });

  testWidgets('Bloch: gates use the shared production order and inspector',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pumpAndSettle();
    for (final type in blochLabGateTypes) {
      expect(find.byKey(ValueKey('bloch-gate-${type.name}')), findsOneWidget);
      expect(GateEducationalCatalog.forType(type), isNotNull);
    }
    await tester.tap(find.byKey(const ValueKey('bloch-gate-s')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-about-gate')));
    await tester.pumpAndSettle();
    expect(find.byType(GateInspectorDialog), findsOneWidget);
  });

  testWidgets('Bloch: wide, medium and stacked layouts', (tester) async {
    final lab = BlochLabSession.standalone();
    addTearDown(lab.dispose);
    for (final (size, key) in const [
      (Size(1600, 1000), 'web-bloch-wide-layout'),
      (Size(900, 800), 'web-bloch-medium-layout'),
      (Size(500, 900), 'web-bloch-stacked-layout'),
    ]) {
      await setSize(tester, size);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: WebBlochWorkspace(standalone: lab))));
      await tester.pump();
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: '$size');
      expect(tester.takeException(), isNull);
    }
  });
}
