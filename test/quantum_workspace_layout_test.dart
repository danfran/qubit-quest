import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/quantum_workspace_layout.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';

void main() {
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

  testWidgets('wide Web Sandbox presents Circuit and State together',
      (tester) async {
    await pumpApp(tester, const Size(1440, 1000));
    await openComposer(tester, 3);

    expect(
      find.byKey(const ValueKey('quantum-workspace-wide-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quantum-workspace-primary-pane')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quantum-workspace-inspection-pane')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quantum-workspace-main-row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quantum-workspace-toolbar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quantum-workspace-contextual-actions')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('web-composer-canvas')), findsOneWidget);
    expect(currentStateDisplay(), findsOneWidget);

    final primary = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-primary-pane')),
    );
    final inspection = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-inspection-pane')),
    );
    expect(primary.right, lessThan(inspection.left));
    expect(primary.width, greaterThan(inspection.width));
    final mainRow = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-main-row')),
    );
    final toolbar = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-toolbar')),
    );
    final contextual = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-contextual-actions')),
    );
    expect(toolbar.left, greaterThanOrEqualTo(primary.left));
    expect(toolbar.right, lessThanOrEqualTo(primary.right));
    expect(toolbar.bottom, lessThanOrEqualTo(primary.bottom));
    expect(toolbar.right, lessThan(inspection.left));
    expect(contextual.top, greaterThanOrEqualTo(mainRow.bottom));
    expect(find.text('LIVE INSPECTOR'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('web-composer-live-indicator')),
      findsOneWidget,
    );
    expect(
      tester.widget<StateVectorDisplay>(currentStateDisplay()).contentDriven,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow Web Sandbox reflows and uses page-driven state height',
      (tester) async {
    await pumpApp(tester, const Size(600, 900));
    await openComposer(tester, 2);

    expect(
      find.byKey(const ValueKey('quantum-workspace-narrow-layout')),
      findsOneWidget,
    );
    final primary = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-primary-pane')),
    );
    final inspection = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-inspection-pane')),
    );
    final toolbar = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-toolbar')),
    );
    final contextual = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-contextual-actions')),
    );
    expect(primary.bottom, lessThanOrEqualTo(toolbar.top));
    expect(toolbar.bottom, lessThanOrEqualTo(inspection.top));
    expect(inspection.bottom, lessThanOrEqualTo(contextual.top));
    expect(
      tester.widget<StateVectorDisplay>(currentStateDisplay()).contentDriven,
      isTrue,
    );
    expect(
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .surfaceTreatment,
      ComposerCircuitSurfaceTreatment.inset,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('web-composer-current-state')),
        matching: find.byType(Scrollbar),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('web-composer-workspace-scroll')),
        matching: find.byType(Scrollable),
      ),
      findsWidgets,
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

  testWidgets('intermediate Web Sandbox tightens into the vertical workspace',
      (tester) async {
    await pumpApp(tester, const Size(1200, 900));
    await openComposer(tester, 3);

    expect(
      find.byKey(const ValueKey('quantum-workspace-narrow-layout')),
      findsOneWidget,
    );
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
      find.byKey(const ValueKey('quantum-workspace-narrow-layout')),
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
