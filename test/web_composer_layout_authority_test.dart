import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/screens/web_exercise_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/desktop_composer_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';
import 'web_sandbox_measurement_test.dart' as sandbox;
import 'support/mastery_math_test_platform.dart';
import 'package:quantumquiz/screens/web_app.dart' show debugClassicSandboxLayout;
import 'support/laboratory_composer_finders.dart';

void main() {
  // These tests verify the classic three-column exercise layout, kept as a
  // test seam after M11D moved lessons and challenges to the learning layout.
  setUpAll(() => debugClassicExerciseLayout = true);
  tearDownAll(() => debugClassicExerciseLayout = false);
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  useMasteryMathTestPlatform();
  testWidgets(
      'Sandbox transitions retain circuit, filter, measurement and contained controls',
      (tester) async {
    await sandbox.openSandbox(tester, InMemoryAppStorage(), qubits: 1);
    var canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    final circuit = canvas.circuit;
    await canvas.onDropRequested(ComposerCircuitDropIntent(
      data: CircuitDragData.palette(Gate.fromIdentifier(SelectedGateType.x)),
      destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0)),
    ));
    await tester.pumpAndSettle();
    canvas.onGateTap(circuit.logicalGates.single.toPlacedGateRef());
    await tester.pumpAndSettle();
    await sandbox.tapVisible(tester, find.byType(Checkbox));
    await sandbox.tapVisible(tester, sandbox.run);
    final result = sandbox.shotsResult(tester);
    final runs = circuit.simulationRunCount;
    final state = circuit.currentState;
    // M3: cross every workspace tier boundary (compact/medium at 908 px,
    // medium/narrow at 640 px), judged by the workspace's own width.
    final workspace = find.byType(DesktopComposerWorkspace);
    final view = find.byKey(const ValueKey('composer-workspace-view'));
    Future<void> showView(String name) async {
      final segment = find.descendant(of: view, matching: find.text(name));
      if (segment.evaluate().isNotEmpty) {
        await tester.tap(segment);
        await tester.pumpAndSettle();
      }
    }

    for (final viewport in [
      1147.0,
      1149.0,
      1148.0,
      1440.0,
      900.0,
      641.0,
      639.0,
      1440.0
    ]) {
      tester.view.physicalSize = Size(viewport, 1000);
      await tester.pumpAndSettle();
      final width = tester.getSize(workspace).width;
      final tier = ComposerWorkspaceGeometry.resolve(
              width, WorkspaceLayoutPreferences.defaults)
          .tier;
      expect(find.byKey(ValueKey('composer-workspace-${tier.name}')),
          findsOneWidget,
          reason: 'viewport $viewport → workspace $width');
      canvas = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
      expect(canvas.circuit, same(circuit));
      expect(circuit.currentState, same(state));
      await showView('Results');
      expect(
          tester
              .widget<SegmentedButton<QuantumInspectorView>>(
                  find.byKey(const ValueKey('quantum-inspector-view-selector')))
              .selected,
          {QuantumInspectorView.measure});
      expect(sandbox.shotsResult(tester), same(result));
      await sandbox.tapVisible(tester, find.text('State'));
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await sandbox.tapVisible(tester, find.text('Bloch'));
      await sandbox.tapVisible(tester, find.text('Measure'));
      expect(sandbox.shotsResult(tester), same(result));
      await showView('Circuit');
      final inspector = find.byKey(const ValueKey('composer-region-inspector'));
      // M3.1: More details became the inspector's inline tabs.
      for (final action in ['replace', 'duplicate', 'delete']) {
        final control =
            find.byKey(ValueKey('web-composer-$action-selected-gate'));
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        final bounds = tester.getRect(inspector);
        final rect = tester.getRect(control);
        expect(rect.left, greaterThanOrEqualTo(bounds.left - .5));
        expect(rect.right, lessThanOrEqualTo(bounds.right + .5));
      }
      final tabs = find.byKey(const ValueKey('composer-inspector-tabs'));
      final tabRect = tester.getRect(tabs);
      final inspectorRect = tester.getRect(inspector);
      expect(tabRect.left, greaterThanOrEqualTo(inspectorRect.left - .5));
      expect(tabRect.right, lessThanOrEqualTo(inspectorRect.right + .5));
      expect(find.byKey(const ValueKey('web-clear-circuit')), findsOneWidget);
      expect(circuit.simulationRunCount, runs,
          reason: 'layout changes never re-simulate');
      expect(tester.takeException(), isNull);
    }
    await showView('Results');
    await sandbox.tapVisible(tester, find.text('State'));
    await sandbox.tapVisible(tester, find.byType(Checkbox));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    // M11C: the qubit choices are always visible in the header.
    await pumpUntilSandboxOpen(tester);
    await sandbox.tapVisible(
        tester, find.byKey(const ValueKey('web-composer-qubits-3')));
    expect(
        tester
            .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
            .circuit
            .currentLevel
            .numQubits,
        3);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final mastery in [false, true]) {
    testWidgets(
        '${mastery ? 'Mastery' : 'Journey'} exercise tier transitions retain '
        'circuit/filter', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 1000);
      addTearDown(tester.view.reset);
      final level = mastery
          ? mastery2Catalogue
              .requireBySemanticId('inverse_phase_synthesis')
              .levelDefinition as ComposerLevel
          : getQQLevelById(2)! as ComposerLevel;
      final width = ValueNotifier<double>(1200);
      addTearDown(width.dispose);
      await tester.pumpWidget(MaterialApp(
          theme: QubitQuestTheme.web(),
          home: Scaffold(
              body: Align(
            alignment: Alignment.topLeft,
            child: ValueListenableBuilder<double>(
                valueListenable: width,
                builder: (_, value, child) =>
                    SizedBox(width: value, height: 1000, child: child),
                child: WebComposerExercise(
                    level: level,
                    mode: mastery
                        ? ComposerMode.masteryChallenge
                        : ComposerMode.journeyExercise,
                    contextLabel: 'Exercise',
                    onCompleted: () async {},
                    onNext: () {},
                    onOpenNotebook: () {})),
          ))));
      await tester.pumpAndSettle();
      final circuit = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .circuit;
      final state = circuit.currentState;
      final runs = circuit.simulationRunCount;
      final checkbox = find.byType(Checkbox, skipOffstage: false);
      final before = tester.widget<Checkbox>(checkbox).value;
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      // Shared tier boundaries: compact/medium at 908, medium/narrow at 640.
      for (final value in [909.0, 907.0, 641.0, 639.0, 1200.0]) {
        width.value = value;
        await tester.pumpAndSettle();
        final tier = ComposerWorkspaceGeometry.resolve(
                value, WorkspaceLayoutPreferences.defaults)
            .tier;
        expect(find.byKey(ValueKey('composer-workspace-${tier.name}')),
            findsOneWidget,
            reason: 'width $value');
        expect(
            tester
                .widget<ComposerCircuitCanvas>(
                    find.byType(ComposerCircuitCanvas))
                .circuit,
            same(circuit));
        expect(tester.widget<Checkbox>(checkbox).value, isNot(before));
        expect(circuit.currentState, same(state));
        expect(circuit.simulationRunCount, runs);
        // Check stays reachable at every tier.
        expect(find.byKey(const ValueKey('web-lesson-check')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
