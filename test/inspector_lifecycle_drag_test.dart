import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_session_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

Future<void> mouseDrag(WidgetTester tester, Offset start) async {
  final gesture =
      await tester.startGesture(start, kind: PointerDeviceKind.mouse);
  await gesture.moveBy(const Offset(20, 8));
  await tester.pump();
  await gesture.moveBy(const Offset(40, 18));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  // v2.6 M6a: the shared Composer workspace (Sandbox, Notebook, Journey and
  // Mastery) keeps the Results tab and the learner's Bloch camera across
  // every responsive tier, and orbiting never edits the quantum state.
  testWidgets(
      'shared workspace keeps Results tab and camera across tiers; drag orbits',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1000);
    addTearDown(tester.view.reset);
    final level = createSandboxComposerLevel(1);
    final session = ComposerSession(
      circuit: QuantumCircuit(currentLevel: level),
      policy: ComposerPolicy.forMode(ComposerMode.notebookExample, level),
    );
    addTearDown(session.dispose);
    final layout = WorkspaceLayoutController();
    addTearDown(layout.dispose);
    final slot = ComposerWorkspaceSlot(session, status: '');
    final circuit = session.circuit;
    final state = circuit.currentState;
    final simulations = circuit.simulationRunCount;
    await tester.pumpWidget(MaterialApp(
      theme: QubitQuestTheme.web(),
      home: Scaffold(
        body: ComposerSessionWorkspace(
          slot: slot,
          layout: layout,
          shortcutsEnabled: true,
          contextLabel: 'Test',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final selectorFinder = find.byKey(
        const ValueKey('quantum-inspector-view-selector'),
        skipOffstage: false);
    Set<QuantumInspectorView> selected() => tester
        .widget<SegmentedButton<QuantumInspectorView>>(selectorFinder)
        .selected;
    Future<void> resize(double width) async {
      tester.view.physicalSize = Size(width, 1000);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.descendant(
        of: selectorFinder, matching: find.text('Bloch')));
    await tester.pumpAndSettle();
    // wide → narrow (stacked) → wide → medium (Results offstage) → wide.
    for (final width in [1200.0, 600.0, 1200.0, 800.0, 1200.0]) {
      final previousCamera = tester
          .widget<BlochSpherePanel>(
              find.byType(BlochSpherePanel, skipOffstage: false))
          .camera;
      await resize(width);
      expect(selected(), {QuantumInspectorView.bloch}, reason: 'at $width');
      var panel = tester.widget<BlochSpherePanel>(
          find.byType(BlochSpherePanel, skipOffstage: false));
      expect(panel.camera, previousCamera, reason: 'camera at $width');
      if (width == 800) continue; // Results is the hidden view here.
      final canvas = find.byKey(const ValueKey('bloch-sphere-canvas'));
      await tester.ensureVisible(canvas);
      await tester.pumpAndSettle();
      final before = panel.camera;
      final blochState = panel.state;
      final projection =
          BlochProjection(size: tester.getSize(canvas), camera: before);
      // Even dragging the vector tip orbits; it never edits the state.
      final tip = projection.project(blochState.x, blochState.y, blochState.z);
      await mouseDrag(tester, tester.getTopLeft(canvas) + tip);
      panel = tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
      expect(panel.camera.yaw, isNot(before.yaw));
      expect(panel.state.x, blochState.x);
      expect(panel.state.y, blochState.y);
      expect(panel.state.z, blochState.z);
      expect(circuit.currentState, same(state));
      expect(circuit.simulationRunCount, simulations);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.descendant(
        of: selectorFinder, matching: find.text('State')));
    await tester.pumpAndSettle();
    for (final w in [600.0, 1200.0]) {
      await resize(w);
      expect(selected(), {QuantumInspectorView.state});
    }
    expect(circuit.simulationRunCount, simulations);
    expect(tester.takeException(), isNull);
  });

  testWidgets('standalone Web Bloch Explorer still orbits with a mouse',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(QubitQuestWebApp(storage: InMemoryAppStorage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pumpAndSettle();
    final panelBefore =
        tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
    await mouseDrag(tester,
        tester.getCenter(find.byKey(const ValueKey('bloch-sphere-canvas'))));
    final panelAfter =
        tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
    expect(panelAfter.camera.yaw, isNot(panelBefore.camera.yaw));
    expect(panelAfter.state, same(panelBefore.state));
    // v2.6 M8: dragging edits the state only after opting in ("Drag
    // vector"), so an ordinary drag can never change the quantum state.
    expect(panelAfter.allowStateEditing, isFalse);
    await tester.tap(find.byKey(const ValueKey('bloch-drag-state-toggle')));
    await tester.pump();
    expect(tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel))
        .allowStateEditing, isTrue);
    expect(tester.takeException(), isNull);
  });
}
