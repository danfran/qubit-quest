import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';
import 'package:quantumquiz/widgets/measurement_results_view.dart';
import 'package:quantumquiz/widgets/quantum_state_inspector_content.dart';
import 'package:quantumquiz/widgets/quantum_workspace_layout.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/widgets/web_composer_workbench.dart';
import 'web_sandbox_measurement_test.dart' as sandbox;
import 'support/mastery_math_test_platform.dart';

void main() {
  useMasteryMathTestPlatform();
  for (final breakpoint in [960.0, 760.0]) {
    testWidgets('one local layout at $breakpoint, including text scale',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1500, 1000);
      addTearDown(tester.view.reset);
      for (final width in [breakpoint - 1, breakpoint, breakpoint + 1]) {
        for (final scale in [1.0, 1.5]) {
          final seen = <WebComposerLayoutInfo>[];
          Widget region(WebComposerLayoutInfo layout) {
            seen.add(layout);
            return const SizedBox(height: 30);
          }

          await tester.pumpWidget(MaterialApp(
              home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
                body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                  width: width,
                  child: WebComposerWorkbench(
                    wideLayoutBreakpoint: breakpoint,
                    wideMainHeight: 400,
                    circuitBuilder: region,
                    gatesBuilder: region,
                    stateViewBuilder: region,
                    measureViewBuilder: region,
                    actionsBuilder: region,
                    currentStateVector: [Complex.one(), Complex.zero()],
                    numQubits: 1,
                  )),
            )),
          )));
          await tester.pumpAndSettle();
          expect(seen, hasLength(5));
          expect(seen.every((layout) => identical(layout, seen.first)), isTrue);
          final layout = seen.first;
          expect(layout.availableWidth, width);
          expect(layout.wide, width >= breakpoint);
          expect(layout.densePalette, layout.wide);
          expect(layout.contentDrivenInspector,
              !layout.wide || scale > 1 || width < 960);
          expect(layout.inlineActions, layout.wide && scale == 1);
          expect(
              tester
                  .widget<QuantumWorkspaceLayout>(
                      find.byType(QuantumWorkspaceLayout))
                  .wide,
              layout.wide);
          expect(tester.takeException(), isNull);
        }
      }
    });
  }

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
    final result =
        tester.widget<MeasurementResultsView>(sandbox.results).result;
    final runs = circuit.simulationRunCount;
    final state = circuit.currentState;
    // Derive surrounding chrome from measured local width, not assumed viewport offsets.
    final chrome = tester.view.physicalSize.width -
        tester.getSize(find.byType(WebComposerWorkbench)).width;
    for (final width in [959.0, 961.0, 960.0, 959.0, 961.0]) {
      tester.view.physicalSize = Size(width + chrome, 1000);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(WebComposerWorkbench)).width, width);
      final wide = width >= 960;
      expect(
          tester
              .widget<QuantumWorkspaceLayout>(
                  find.byType(QuantumWorkspaceLayout))
              .wide,
          wide);
      expect(
          tester
              .widget<ComposerGatePalette>(find.byType(ComposerGatePalette))
              .dense,
          wide);
      canvas = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
      expect(
          canvas.surfaceTreatment,
          wide
              ? ComposerCircuitSurfaceTreatment.workbench
              : ComposerCircuitSurfaceTreatment.inset);
      expect(canvas.circuit, same(circuit));
      expect(circuit.currentState, same(state));
      expect(
          tester
              .widget<SegmentedButton<QuantumInspectorView>>(
                  find.byKey(const ValueKey('quantum-inspector-view-selector')))
              .selected,
          {QuantumInspectorView.measure});
      expect(tester.widget<MeasurementResultsView>(sandbox.results).result,
          same(result));
      if (find.text('Current State').evaluate().isEmpty)
        await sandbox.tapVisible(tester, find.text('State'));
      expect(
          tester
              .widget<QuantumStateInspectorContent>(
                  find.byType(QuantumStateInspectorContent))
              .contentDriven,
          !wide);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await sandbox.tapVisible(tester, find.text('Bloch'));
      await sandbox.tapVisible(tester, find.text('Measure'));
      expect(tester.widget<MeasurementResultsView>(sandbox.results).result,
          same(result));
      final primary =
          find.byKey(const ValueKey('quantum-workspace-primary-pane'));
      expect(
          find.descendant(
              of: primary,
              matching: find.byKey(const ValueKey('web-clear-circuit'))),
          findsOneWidget);
      final footer =
          find.byKey(const ValueKey('quantum-workspace-contextual-actions'));
      for (final action in [
        'inspect',
        'replace',
        'duplicate',
        'move',
        'delete'
      ]) {
        final control =
            find.byKey(ValueKey('web-composer-$action-selected-gate'));
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        final bounds = tester.getRect(footer);
        final rect = tester.getRect(control);
        expect(rect.left, greaterThanOrEqualTo(bounds.left));
        expect(rect.right, lessThanOrEqualTo(bounds.right));
      }
      expect(circuit.simulationRunCount, runs);
      expect(tester.takeException(), isNull);
    }
    await sandbox.tapVisible(tester, find.text('State'));
    await sandbox.tapVisible(tester, find.byType(Checkbox));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await sandbox.tapVisible(
        tester, find.byKey(const ValueKey('web-composer-change-qubits')));
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
        '${mastery ? 'Mastery' : 'Journey'} local 760 transitions retain circuit/filter',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 1000);
      addTearDown(tester.view.reset);
      final level = mastery
          ? mastery2Catalogue
              .requireBySemanticId('inverse_phase_synthesis')
              .levelDefinition as ComposerLevel
          : getQQLevelById(2)! as ComposerLevel;
      final width = ValueNotifier<double>(761);
      addTearDown(width.dispose);
      await tester.pumpWidget(MaterialApp(
          theme: QubitQuestTheme.web(),
          home: Scaffold(
              body: Align(
            alignment: Alignment.topLeft,
            child: ValueListenableBuilder<double>(
                valueListenable: width,
                builder: (_, value, child) => SizedBox(
                    width: value, child: SingleChildScrollView(child: child)),
                child: WebComposerLesson(
                    level: level,
                    enabled: true,
                    desktopWorkspace: true,
                    onSolved: () async {})),
          ))));
      await tester.pumpAndSettle();
      final circuit = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .circuit;
      final state = circuit.currentState;
      final runs = circuit.simulationRunCount;
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      for (final value in [759.0, 760.0, 761.0, 759.0]) {
        width.value = value;
        await tester.pumpAndSettle();
        final wide = value >= 760;
        expect(
            tester
                .widget<WebComposerWorkbench>(find.byType(WebComposerWorkbench))
                .wideLayoutBreakpoint,
            760);
        expect(
            tester
                .widget<QuantumWorkspaceLayout>(
                    find.byType(QuantumWorkspaceLayout))
                .wide,
            wide);
        expect(
            tester
                .widget<ComposerGatePalette>(find.byType(ComposerGatePalette))
                .dense,
            wide);
        expect(
            tester
                .widget<QuantumStateInspectorContent>(
                    find.byType(QuantumStateInspectorContent))
                .contentDriven,
            isTrue);
        expect(
            tester
                .widget<ComposerCircuitCanvas>(
                    find.byType(ComposerCircuitCanvas))
                .circuit,
            same(circuit));
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
        expect(circuit.currentState, same(state));
        expect(circuit.simulationRunCount, runs);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
