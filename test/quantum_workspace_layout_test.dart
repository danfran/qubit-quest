import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/widgets/composer_workspace/desktop_composer_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/quantum_workspace_layout.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';
import 'package:quantumquiz/widgets/quantum_state_inspector_content.dart';
import 'support/laboratory_composer_finders.dart';

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpApp(WidgetTester tester, Size size) async {
    await setSize(tester, size);
    await tester.pumpWidget(QubitQuestWebApp(storage: InMemoryAppStorage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> openComposer(WidgetTester tester, int qubits) async {
    if (find
        .byKey(const ValueKey('web-navigation-sidebar'))
        .evaluate()
        .isEmpty) {
      await tester.tap(find.byKey(const ValueKey('web-navigation-menu')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pumpAndSettle();
    await pumpUntilSandboxOpen(tester);
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(ValueKey('web-composer-qubits-$qubits')));
    await tester.pump();
  }

  Finder currentStateDisplay() => find.descendant(
        of: find.byKey(const ValueKey('web-composer-current-state')),
        matching: find.byType(StateVectorDisplay),
        matchRoot: true,
      );

  Finder currentStateCheckbox() => find.descendant(
        of: find.byKey(const ValueKey('web-composer-current-state')),
        matching: find.byType(Checkbox),
      );

  test('layout policy is presentation-only and uses a stable breakpoint', () {
    const layout = QuantumWorkspaceLayout(
      wide: false,
      circuit: SizedBox(),
      inspection: SizedBox(),
      toolbar: SizedBox(),
    );
    expect(layout, isA<StatelessWidget>());
    expect(
      QuantumWorkspaceLayout.usesWideLayout(
        QuantumWorkspaceLayout.wideBreakpoint - 1,
      ),
      isFalse,
    );
    expect(
      QuantumWorkspaceLayout.usesWideLayout(
        QuantumWorkspaceLayout.wideBreakpoint,
      ),
      isTrue,
    );
  });

  Finder region(String name) => find.byKey(ValueKey('composer-region-$name'));

  testWidgets('Sandbox chrome and selected controls stay inside workspace',
      (tester) async {
    await pumpApp(tester, const Size(1440, 1000));
    expect(find.text('Level 1'), findsNothing);
    await openComposer(tester, 1);
    expect(find.text('Level 1'), findsNothing);
    final toolbar = find.byKey(const ValueKey('composer-workspace-toolbar'));
    // M11C: the qubit choices are one visible selector in the header.
    final change = find.byKey(const ValueKey('web-composer-qubit-selector'));
    final clear = find.byKey(const ValueKey('web-clear-circuit'));
    final count = find.byKey(const ValueKey('web-composer-qubit-count'));
    for (final control in [change, clear, count]) {
      expect(find.descendant(of: toolbar, matching: control), findsOneWidget);
    }
    expect(tester.widget<Text>(count).semanticsLabel, '1 qubit');
    expect(find.text('State'), findsOneWidget);
    expect(find.text('Bloch'), findsOneWidget);
    expect(find.text('Measure'), findsOneWidget);
    final canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    await canvas.onDropRequested(ComposerCircuitDropIntent(
      data: CircuitDragData.palette(Gate.fromIdentifier(SelectedGateType.x)),
      destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0)),
    ));
    await tester.pumpAndSettle();
    canvas.onGateTap(canvas.circuit.logicalGates.single.toPlacedGateRef());
    await tester.pumpAndSettle();
    for (final scenario in [
      (const Size(1440, 1000), 1.0),
      (const Size(1200, 900), 1.0),
      (const Size(600, 900), 1.0),
      (const Size(600, 900), 1.5),
    ]) {
      tester.view.physicalSize = scenario.$1;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      final bar = tester.getRect(toolbar);
      for (final control in [change, clear]) {
        final rect = tester.getRect(control);
        expect(rect.left, greaterThanOrEqualTo(bar.left - .5));
        expect(rect.right, lessThanOrEqualTo(bar.right + .5));
      }
      final inspector = tester.getRect(region('inspector'));
      // M3.1: More details became the inspector's inline tabs.
      for (final name in ['replace', 'duplicate', 'delete']) {
        final control =
            find.byKey(ValueKey('web-composer-$name-selected-gate'));
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        final rect = tester.getRect(control);
        expect(rect.left, greaterThanOrEqualTo(inspector.left - .5));
        expect(rect.right, lessThanOrEqualTo(inspector.right + .5));
        expect(rect.width, greaterThan(0));
      }
      expect(
          tester
              .getRect(region('inspector'))
              .overlaps(tester.getRect(region('results'))),
          isFalse);
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(canvas.circuit.logicalGates, isEmpty);
    await tester.ensureVisible(change);
    await tester.pumpAndSettle();
    await tester.tap(change);
    await tester.pumpAndSettle();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-2')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(count).semanticsLabel, '2 qubits');
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide Web Sandbox presents Circuit and State together',
      (tester) async {
    await pumpApp(tester, const Size(1440, 1000));
    await openComposer(tester, 3);

    expect(find.byType(DesktopComposerWorkspace), findsOneWidget);
    expect(
        find.byKey(const ValueKey('composer-workspace-wide')), findsOneWidget);
    expect(find.byType(QuantumStateInspectorContent), findsOneWidget);
    expect(find.text('Current State'), findsOneWidget);
    expect(find.text('Target State'), findsNothing);
    expect(find.byKey(const ValueKey('web-composer-canvas')), findsOneWidget);
    expect(currentStateDisplay(), findsOneWidget);

    final palette = tester.getRect(region('palette'));
    final canvas = tester.getRect(region('canvas'));
    final inspector = tester.getRect(region('inspector'));
    final results = tester.getRect(region('results'));
    expect(palette.right, lessThan(canvas.left));
    expect(canvas.right, lessThan(results.left));
    expect(canvas.width, greaterThan(results.width));
    expect(inspector.top, greaterThanOrEqualTo(canvas.bottom));
    expect(inspector.right, lessThan(results.left));
    expect(results.top, closeTo(canvas.top, .5));
    expect(find.text('RESULTS'), findsOneWidget);
    expect(find.text('State'), findsOneWidget);
    expect(find.text('Bloch'), findsOneWidget);
    expect(find.text('LIVE INSPECTOR'), findsNothing);
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('Updates as you build'), findsNothing);
    expect(
        find.text('Current state · updated from this circuit'), findsNothing);
    expect(
      find.byKey(const ValueKey('web-composer-live-indicator')),
      findsNothing,
    );
    // The results column sizes the state to its content and scrolls itself.
    expect(
      tester.widget<StateVectorDisplay>(currentStateDisplay()).contentDriven,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow Web Sandbox stacks its regions in one page',
      (tester) async {
    await pumpApp(tester, const Size(600, 900));
    await openComposer(tester, 2);

    expect(find.byKey(const ValueKey('composer-workspace-narrow')),
        findsOneWidget);
    final canvas = tester.getRect(region('canvas'));
    final inspector = tester.getRect(region('inspector'));
    final results = tester.getRect(region('results'));
    expect(canvas.bottom, lessThanOrEqualTo(inspector.top));
    expect(inspector.bottom, lessThanOrEqualTo(results.top));
    expect(
      tester.widget<StateVectorDisplay>(currentStateDisplay()).contentDriven,
      isTrue,
    );
    expect(
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .surfaceTreatment,
      ComposerCircuitSurfaceTreatment.workbench,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('web-composer-current-state')),
        matching: find.byType(Scrollbar),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('one-qubit Sandbox Bloch view shares the live circuit result',
      (tester) async {
    await pumpApp(tester, const Size(1440, 1000));
    await openComposer(tester, 1);

    var canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    final circuit = canvas.circuit;
    final initialRuns = circuit.simulationRunCount;
    final selector = find.byKey(
      const ValueKey('quantum-inspector-view-selector'),
    );

    await tester
        .tap(find.descendant(of: selector, matching: find.text('Bloch')));
    await tester.pump();
    var bloch = tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
    expect(bloch.state.z, closeTo(1, 1e-9));
    expect(circuit.simulationRunCount, initialRuns);

    await canvas.onDropRequested(
      ComposerCircuitDropIntent(
        data: CircuitDragData.palette(
          Gate.fromIdentifier(SelectedGateType.hadamard),
        ),
        destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0),
        ),
      ),
    );
    await tester.pump();

    canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    bloch = tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
    expect(identical(canvas.circuit, circuit), isTrue);
    expect(circuit.simulationRunCount, initialRuns + 1);
    expect(bloch.state.x, closeTo(1, 1e-9));
    expect(bloch.state.y, closeTo(0, 1e-9));
    expect(bloch.state.z, closeTo(0, 1e-9));
  });

  testWidgets('1200 px Web Sandbox keeps three columns', (tester) async {
    await pumpApp(tester, const Size(1200, 900));
    await openComposer(tester, 3);

    // 1200 − 239 px navigation = 961 px workspace: still three columns.
    expect(find.byKey(const ValueKey('composer-workspace-compact')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-composer-canvas')), findsOneWidget);
    expect(currentStateDisplay(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'resize preserves one circuit, its live result, and explicit filter',
      (tester) async {
    await pumpApp(tester, const Size(1440, 1000));
    await openComposer(tester, 3);

    var canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    final QuantumCircuit circuit = canvas.circuit;
    final initialRuns = circuit.simulationRunCount;
    expect(tester.widget<Checkbox>(currentStateCheckbox()).value, isTrue);

    await canvas.onDropRequested(
      ComposerCircuitDropIntent(
        data: CircuitDragData.palette(
          Gate.fromIdentifier(SelectedGateType.hadamard),
        ),
        destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0),
        ),
      ),
    );
    await tester.pump();

    expect(circuit.simulationRunCount, initialRuns + 1);
    expect(circuit.logicalGates, hasLength(1));
    expect(
      circuit.currentState.stateVector[0].real,
      closeTo(1 / math.sqrt(2), 1e-9),
    );
    expect(
      circuit.currentState.stateVector[1].real,
      closeTo(1 / math.sqrt(2), 1e-9),
    );
    expect(
      identical(
        tester.widget<StateVectorDisplay>(currentStateDisplay()).stateVector,
        circuit.currentState.stateVector,
      ),
      isTrue,
    );

    await tester.tap(currentStateCheckbox());
    await tester.pump();
    expect(tester.widget<Checkbox>(currentStateCheckbox()).value, isFalse);

    await setSize(tester, const Size(600, 900));
    await tester.pump();
    canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    expect(identical(canvas.circuit, circuit), isTrue);
    expect(canvas.circuit.logicalGates, hasLength(1));
    expect(tester.widget<Checkbox>(currentStateCheckbox()).value, isFalse);
    expect(
      find.byKey(const ValueKey('composer-workspace-narrow')),
      findsOneWidget,
    );

    await setSize(tester, const Size(1440, 1000));
    await tester.pump();
    expect(
      identical(
        tester
            .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
            .circuit,
        circuit,
      ),
      isTrue,
    );
    expect(tester.widget<Checkbox>(currentStateCheckbox()).value, isFalse);
    expect(tester.takeException(), isNull);
  });
}
