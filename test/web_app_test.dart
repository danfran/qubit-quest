import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/rotation_gate_dialog.dart';
import 'package:quantumquiz/screens/two_qubits_gate_target_qubit_selection_dialog.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/bloch_explorer_panels.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';
import 'package:quantumquiz/widgets/circuit_canvas_metrics.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';

void main() {
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
      expect(tester.widget<AppBar>(find.byType(AppBar)).actions, isNull);
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
    expect(find.byType(LearningMapScreen), findsOneWidget);

    await tester.tap(find.text('Chapter 1 — Information'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1 of 5'), findsOneWidget);
    expect(find.text('0 / 5 complete'), findsOneWidget);
    expectNoGlobalLevel();

    await tester.tap(find.byKey(const ValueKey('web-nav-mastery')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('web-mastery-title')), findsOneWidget);
    expect(
        find.byKey(
            const ValueKey('web-mastery-activity-global_phase_equivalence')),
        findsOneWidget);
    expectNoGlobalLevel();

    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    expect(find.text('Choose Number of Qubits'), findsOneWidget);
    expectNoGlobalLevel();
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-3')));
    await tester.pump();
    expect(find.byType(ComposerGatePalette), findsOneWidget);
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
    expect(find.byType(BlochGatePanel), findsOneWidget);
    expect(find.byType(BlochPlaybackControls), findsOneWidget);
    expect(find.byType(BlochHistoryPanel), findsOneWidget);
    expect(find.byType(BlochStateMathPanel), findsOneWidget);

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
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-2')));
    await tester.pump();
    expect(find.byType(ComposerCircuitCanvas), findsOneWidget);
    expect(find.byKey(const ValueKey('web-navigation-drawer')), findsNothing);
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
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-3')));
    await tester.pump();

    expect(find.text('Restored 1 saved operation(s).'), findsOneWidget);
  });

  testWidgets('wide Composer prioritises the shared circuit above its tools',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-3')));
    await tester.pump();

    final canvas = find.byKey(const ValueKey('web-composer-canvas'));
    final stage = find.byKey(const ValueKey('web-composer-circuit-stage'));
    final palette = find.byType(ComposerGatePalette);
    expect(
        tester.getTopLeft(canvas).dy, lessThan(tester.getTopLeft(palette).dy));
    expect(
      tester.getSize(canvas).height,
      WebCircuitWorkbenchMetrics.calculate(
        qubitCount: 3,
        hasTargetState: false,
      ).canvasHeight,
    );
    expect(
        find.byKey(const ValueKey('web-composer-canvas-frame')), findsNothing);
    expect(tester.getCenter(canvas).dy, closeTo(tester.getCenter(stage).dy, 1));
    final mainRow = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-main-row')),
    );
    final primaryPane = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-primary-pane')),
    );
    final inspectorPane = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-inspection-pane')),
    );
    final toolbar = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-toolbar')),
    );
    expect(toolbar.left, greaterThanOrEqualTo(primaryPane.left));
    expect(toolbar.right, lessThanOrEqualTo(primaryPane.right));
    expect(toolbar.right, lessThan(inspectorPane.left));
    expect(toolbar.bottom, lessThanOrEqualTo(mainRow.bottom));

    final paletteWidget = tester.widget<ComposerGatePalette>(palette);
    expect(
      paletteWidget.gates.map((gate) => gate.type),
      orderedEquals(sandboxGatePaletteTypes),
    );
    expect(paletteWidget.dense, isTrue);
    expect(paletteWidget.embedded, isTrue);

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
      find.byKey(const ValueKey('circuit-workbench-surface')),
      findsOneWidget,
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
      'Web Composer canvas height follows qubit count and not circuit content',
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
      await tester.tap(
        find.byKey(ValueKey('web-composer-qubits-$qubitCount')),
      );
      await tester.pump();
      return tester
          .getSize(find.byKey(const ValueKey('web-composer-canvas')))
          .height;
    }

    final populatedFiveQubitHeight = await openAndMeasure(5);
    expect(
      populatedFiveQubitHeight,
      WebCircuitWorkbenchMetrics.calculate(
        qubitCount: 5,
        hasTargetState: false,
      ).canvasHeight,
    );
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

    await tester.tap(find.byKey(const ValueKey('web-composer-change-qubits')));
    await tester.pump();
    expect(
      await openAndMeasure(1),
      WebCircuitWorkbenchMetrics.calculate(
        qubitCount: 1,
        hasTargetState: false,
      ).canvasHeight,
    );

    await tester.tap(find.byKey(const ValueKey('web-composer-change-qubits')));
    await tester.pump();
    expect(
      await openAndMeasure(2),
      WebCircuitWorkbenchMetrics.calculate(
        qubitCount: 2,
        hasTargetState: false,
      ).canvasHeight,
    );
  });

  testWidgets('Web Composer keeps canonical gate inspection available',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-3')));
    await tester.pump();

    final palette = tester.widget<ComposerGatePalette>(
      find.byType(ComposerGatePalette),
    );
    palette.onInspectGate(palette.gates.first);
    await tester.pumpAndSettle();

    expect(find.byType(GateInspectorDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gate-inspector-content')),
      findsOneWidget,
    );
  });

  testWidgets('Web Composer uses precise rotation insertion and editing flow',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-1')));
    await tester.pump();

    var canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    final insertion = canvas.onDropRequested(
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
    await tester.pump();

    expect(find.byType(RotationGateDialog), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('fractional-angle-numerator')),
      '1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('fractional-angle-denominator')),
      '4',
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    await insertion;

    canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    final placed = canvas.circuit.logicalGates.single.toPlacedGateRef();
    expect(placed.gate.angle, closeTo(math.pi / 4, 1e-9));
    canvas.onGateTap(placed);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('web-composer-selected-rotation-angle')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('web-composer-edit-selected-angle')),
    );
    await tester.pump();
    expect(find.byType(RotationGateDialog), findsOneWidget);
    expect(
        find.byKey(const ValueKey('fractional-angle-input')), findsOneWidget);
  });

  testWidgets(
      'controlled selection exposes active desktop actions and topology',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
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

    expect(find.text('CX: control Q0 → target Q1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('web-composer-inspect-selected-gate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-composer-duplicate-selected-gate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-composer-move-selected-gate')),
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
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('web-composer-duplicate-selected-gate')),
    );
    await tester.pump();
    expect(circuit.simulationRunCount, initialRuns + 2);
    expect(circuit.logicalGates, hasLength(2));

    await tester.tap(
      find.byKey(const ValueKey('web-composer-replace-selected-gate')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('replacement-gate-x')),
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
    await tester.pump();
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
    await tester.tap(find.byKey(const ValueKey('web-notebook-contents')));
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

  testWidgets('Notebook X example routes through Web Composer and Bloch hosts',
      (tester) async {
    await setSize(tester, const Size(1440, 1100));
    await pumpApp(tester);
    final entry = notebookEntries.first;
    await CampaignProgressController.instance
        .unlockDiscovery(entry.discoveryTitle);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-notebook-contents')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('web-notebook-entry-${entry.id}')));
    await tester.pumpAndSettle();

    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('composer-example-x_from_zero')),
        )
        .onPressed!();
    await tester.pump();
    expect(find.text('Notebook example: Run the X gate'), findsOneWidget);
    expect(find.byKey(const ValueKey('web-sandbox-run-measure')), findsNothing);
    expect(find.byKey(const ValueKey('web-sandbox-measurement-results')),
        findsNothing);
    expect(
      find.byKey(const ValueKey('web-composer-target-state')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('run-example-x_from_zero')),
        )
        .onPressed!();
    await tester.pump();
    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('bloch-example-x_from_zero')),
        )
        .onPressed!();
    await tester.pump();

    final canvas = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    expect((canvas.painter! as BlochSpherePainter).state.z, closeTo(-1, .001));
  });

  testWidgets('Bloch Instant off animates to the gate endpoint',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    final initial = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    expect((initial.painter! as BlochSpherePainter).state.z, closeTo(1, .001));

    await tester.pump(const Duration(milliseconds: 325));
    final midwayPaint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    final midwayState = (midwayPaint.painter! as BlochSpherePainter).state;
    expect(midwayState.x, greaterThan(.01));
    expect(midwayState.x, lessThan(.99));
    expect(midwayState.z, greaterThan(.01));
    expect(midwayState.z, lessThan(.99));

    await tester.pump(const Duration(milliseconds: 400));
    final finished = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    expect((finished.painter! as BlochSpherePainter).state.x, closeTo(1, .001));
  });

  testWidgets('Bloch Instant on applies the endpoint without a tween',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();

    final canvas = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    expect((canvas.painter! as BlochSpherePainter).state.x, closeTo(1, .001));
  });

  testWidgets('Web Bloch uses the shared production gate order and Inspector',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();

    expect(
      blochExplorerGateTypes,
      orderedEquals(const [
        SelectedGateType.x,
        SelectedGateType.y,
        SelectedGateType.z,
        SelectedGateType.hadamard,
        SelectedGateType.s,
        SelectedGateType.t,
        SelectedGateType.rx,
        SelectedGateType.ry,
        SelectedGateType.rz,
      ]),
    );
    for (final type in blochExplorerGateTypes) {
      expect(find.byKey(ValueKey('bloch-gate-${type.name}')), findsOneWidget);
    }

    await tester.longPress(
      find.byKey(const ValueKey('bloch-gate-hadamard')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GateInspectorDialog), findsOneWidget);
    expect(find.text('Hadamard gate'), findsOneWidget);
    expect(find.text('Open Notebook'), findsOneWidget);
  });

  testWidgets('Web Bloch history preview toggles and Undo clears stale start',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bloch-history-step-1')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('bloch-history-marker-selected')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('bloch-history-step-1')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('bloch-history-marker-selected')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('bloch-history-step-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-undo')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('bloch-history-marker-selected')),
      findsNothing,
    );
  });

  testWidgets('Web Bloch rotation and replay retain production semantics',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('bloch-rotation-slider')),
    );
    slider.onChanged!(math.pi / 4);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-ry')));
    await tester.pump();

    final rotated = (tester
            .widget<CustomPaint>(
              find.byKey(const ValueKey('bloch-sphere-canvas')),
            )
            .painter! as BlochSpherePainter)
        .state;
    final inverseSqrtTwo = 1 / math.sqrt(2);
    expect(rotated.x, closeTo(inverseSqrtTwo, .001));
    expect(rotated.z, closeTo(inverseSqrtTwo, .001));

    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bloch-history-step-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-replay')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('bloch-history-marker-active')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    final replayed = (tester
            .widget<CustomPaint>(
              find.byKey(const ValueKey('bloch-sphere-canvas')),
            )
            .painter! as BlochSpherePainter)
        .state;
    expect(replayed.x, closeTo(inverseSqrtTwo, .001));
    expect(replayed.z, closeTo(-inverseSqrtTwo, .001));
  });

  testWidgets('Web Bloch uses wide and stacked constraint-driven layouts',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();
    expect(find.byKey(const ValueKey('web-bloch-wide-layout')), findsOneWidget);
    final sphere = tester.getRect(
      find.byKey(const ValueKey('web-bloch-sphere')),
    );
    expect(sphere.height, inInclusiveRange(470, 610));
    expect(
      tester
          .widget<MouseRegion>(
            find.byKey(const ValueKey('web-bloch-sphere-pointer-area')),
          )
          .cursor,
      SystemMouseCursors.grab,
    );

    await setSize(tester, const Size(700, 1000));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('web-bloch-stacked-layout')),
      findsOneWidget,
    );
    final webBlochScroll = find.descendant(
      of: find.byKey(const ValueKey('web-bloch-workspace-scroll')),
      matching: find.byType(Scrollable),
    );
    tester.state<ScrollableState>(webBlochScroll.first).position.jumpTo(tester
        .state<ScrollableState>(webBlochScroll.first)
        .position
        .maxScrollExtent);
    await tester.pump();
    expect(find.byType(BlochStateMathPanel), findsOneWidget);
  });
}
