import 'dart:ui' show PointerDeviceKind;
import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/widgets/web_composer_workbench.dart';
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
  for (final breakpoint in [960.0, 760.0]) {
    testWidgets(
        'Inspector persists tabs and camera drag across $breakpoint layouts',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1500, 1100);
      addTearDown(tester.view.reset);
      final circuit =
          QuantumCircuit(currentLevel: createSandboxComposerLevel(1));
      addTearDown(circuit.dispose);
      final vector = circuit.currentState.stateVector;
      final state = circuit.currentState;
      final simulations = circuit.simulationRunCount;
      final revision = ValueNotifier<int>(0);
      addTearDown(revision.dispose);
      var width = breakpoint + 1;
      var qubits = 1;
      var measure = breakpoint == 960;
      var scale = 1.0;
      await tester.pumpWidget(MaterialApp(
          theme: QubitQuestTheme.web(),
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: revision,
              builder: (_, __, ___) => MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: SingleChildScrollView(
                        child: SizedBox(
                      width: width,
                      child: WebComposerWorkbench(
                        wideLayoutBreakpoint: breakpoint,
                        wideMainHeight: 480,
                        circuitBuilder: (_) => const SizedBox(height: 80),
                        gatesBuilder: (_) => const SizedBox(height: 40),
                        stateViewBuilder: (_) => const Text('ideal state'),
                        measureViewBuilder:
                            measure ? (_) => const Text('observations') : null,
                        currentStateVector: qubits == 1
                            ? vector
                            : [
                                Complex.one(),
                                Complex.zero(),
                                Complex.zero(),
                                Complex.zero()
                              ],
                        numQubits: qubits,
                      ),
                    ))),
              ),
            ),
          )));
      await tester.pumpAndSettle();
      Set<QuantumInspectorView> selected() => tester
          .widget<SegmentedButton<QuantumInspectorView>>(
              find.byKey(const ValueKey('quantum-inspector-view-selector')))
          .selected;
      Future<void> resize(double nextWidth, {double textScale = 1}) async {
        width = nextWidth;
        scale = textScale;
        revision.value++;
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Bloch'));
      await tester.pumpAndSettle();
      final inspectorState = tester.state(find.byType(QuantumInspectorViews));
      for (final nextWidth in [
        breakpoint + 1,
        breakpoint - 1,
        breakpoint,
        breakpoint + 1
      ]) {
        final previousCamera = tester
            .widget<BlochSpherePanel>(find.byType(BlochSpherePanel))
            .camera;
        await resize(nextWidth);
        expect(selected(), {QuantumInspectorView.bloch});
        expect(tester.state(find.byType(QuantumInspectorViews)),
            same(inspectorState));
        var panel =
            tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
        expect(panel.camera, same(previousCamera));
        final before = panel.camera;
        final blochState = panel.state;
        final canvas = find.byKey(const ValueKey('bloch-sphere-canvas'));
        final projection =
            BlochProjection(size: tester.getSize(canvas), camera: before);
        // Even dragging the vector tip must orbit, never edit state in Inspector.
        final tip =
            projection.project(blochState.x, blochState.y, blochState.z);
        await mouseDrag(tester, tester.getTopLeft(canvas) + tip);
        panel = tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
        expect(panel.camera.yaw, isNot(before.yaw));
        expect(panel.camera.pitch, isNot(before.pitch));
        expect(panel.state.x, blochState.x);
        expect(panel.state.y, blochState.y);
        expect(panel.state.z, blochState.z);
        expect(circuit.currentState, same(state));
        expect(circuit.currentState.stateVector, same(vector));
        expect(circuit.simulationRunCount, simulations);
        expect(tester.takeException(), isNull);
      }
      await resize(breakpoint + 1, textScale: 1.5);
      expect(selected(), {QuantumInspectorView.bloch});
      await resize(breakpoint + 1);
      expect(selected(), {QuantumInspectorView.bloch});
      await tester.tap(find.text('State'));
      await tester.pumpAndSettle();
      for (final w in [breakpoint - 1, breakpoint + 1]) {
        await resize(w);
        expect(selected(), {QuantumInspectorView.state});
      }
      if (measure) {
        await tester.tap(find.text('Measure'));
        await tester.pumpAndSettle();
        for (final w in [breakpoint - 1, breakpoint + 1]) {
          await resize(w);
          expect(selected(), {QuantumInspectorView.measure});
          expect(find.text('observations'), findsOneWidget);
        }
        measure = false;
        revision.value++;
        await tester.pumpAndSettle();
        expect(selected(), {QuantumInspectorView.state});
      }
      await tester.tap(find.text('Bloch'));
      await tester.pumpAndSettle();
      qubits = 2;
      revision.value++;
      await tester.pumpAndSettle();
      expect(selected(), {QuantumInspectorView.state});
      expect(circuit.simulationRunCount, simulations);
      expect(tester.takeException(), isNull);
    });
  }

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
    expect(panelAfter.allowStateEditing, isTrue);
    expect(tester.takeException(), isNull);
  });
}
