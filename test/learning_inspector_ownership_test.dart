import 'package:quantumquiz/screens/web_exercise_workspace.dart' show debugClassicExerciseLayout;
import 'dart:ui' show PointerDeviceKind;
import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'support/journey_navigation.dart';

void main() {
  // These tests verify the classic three-column exercise layout, kept as a
  // test seam after M11D moved lessons and challenges to the learning layout.
  setUpAll(() => debugClassicExerciseLayout = true);
  tearDownAll(() => debugClassicExerciseLayout = false);
  testWidgets(
      'mode owner outlives Inspector element and reconciles availability',
      (tester) async {
    final selection = QuantumInspectorSelection();
    Future<void> mount(int identity, {int qubits = 1}) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
        body: QuantumInspectorViews(
          key: ValueKey(identity),
          selection: selection,
          stateView: const Text('ideal state'),
          currentStateVector: [Complex.one(), Complex.zero()],
          numQubits: qubits,
          contentDriven: true,
        ),
      )));
      await tester.pumpAndSettle();
    }

    await mount(1);
    await tester.tap(find.text('Bloch'));
    await tester.pumpAndSettle();
    final previous = tester.state(find.byType(QuantumInspectorViews));
    await mount(2);
    expect(tester.state(find.byType(QuantumInspectorViews)),
        isNot(same(previous)));
    expect(selection.selected, QuantumInspectorView.bloch);
    expect(find.byType(BlochSpherePanel), findsOneWidget);
    await mount(3, qubits: 2);
    expect(selection.selected, QuantumInspectorView.state);
  });

  for (final mastery in [false, true]) {
    testWidgets(
        '${mastery ? "Mastery" : "Journey"} real hierarchy preserves Inspector and circuit',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 1400);
      addTearDown(tester.view.reset);
      final progress =
          CampaignProgressController(store: InMemoryCampaignProgressStore());
      await progress.load();
      addTearDown(progress.dispose);
      final width = ValueNotifier<double>(1000);
      addTearDown(width.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: QubitQuestTheme.web(),
        home: Scaffold(
            body: Align(
          alignment: Alignment.topLeft,
          child: ValueListenableBuilder<double>(
            valueListenable: width,
            builder: (_, value, __) => SizedBox(
                width: value,
                height: 1400,
                child: mastery
                    ? WebMasteryWorkspace(
                        progressController: progress,
                        onBackToJourney: () {},
                        onOpenNotebook: () {})
                    : WebJourneyWorkspace(
                        progressController: progress, onOpenNotebook: () {})),
          ),
        )),
      ));
      await tester.pumpAndSettle();
      if (mastery) {
        // M6a: select in the library, then start from the details.
        await tester.tap(find.byKey(
            const ValueKey('web-mastery-challenge-phase_state_uncomputation')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('web-mastery-start')));
      } else {
        await openJourneyChapter(tester, 1);
      }
      await tester.pumpAndSettle();
      final circuit = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .circuit;
      final state = circuit.currentState;
      final simulations = circuit.simulationRunCount;
      final progressState = progress.state;
      final selector = find.byKey(
          const ValueKey('quantum-inspector-view-selector'),
          skipOffstage: false);
      final sphere = find.byType(BlochSpherePanel, skipOffstage: false);
      // Medium tier: Results is the other half of the Circuit/Results
      // switch; a learner switches to it before orbiting the sphere.
      Future<void> showResults() async {
        final view = find.byKey(const ValueKey('composer-workspace-view'));
        if (view.evaluate().isEmpty) return;
        await tester.tap(find.descendant(of: view, matching: find.text('Results')));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(selector);
      await tester.tap(find.text('Bloch'));
      await tester.pumpAndSettle();
      final boundary = mastery ? 940.0 : 960.0;
      for (final next in [boundary - 1, boundary + 1, 803.0, 805.0, 1000.0]) {
        final cameraBeforeResize =
            tester.widget<BlochSpherePanel>(sphere).camera;
        width.value = next;
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<SegmentedButton<QuantumInspectorView>>(selector)
                .selected,
            {QuantumInspectorView.bloch});
        expect(
            tester
                .widget<ComposerCircuitCanvas>(find.byType(
                    ComposerCircuitCanvas,
                    skipOffstage: false))
                .circuit,
            same(circuit));
        expect(tester.widget<BlochSpherePanel>(sphere).camera,
            same(cameraBeforeResize));
        await showResults();
        await tester.ensureVisible(find.byType(BlochSpherePanel));
        await tester.pumpAndSettle();
        final panel =
            tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
        final gesture = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey('bloch-sphere-canvas'))),
            kind: PointerDeviceKind.mouse);
        await gesture.moveBy(const Offset(20, 8));
        await tester.pump();
        await gesture.moveBy(const Offset(40, 18));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<BlochSpherePanel>(find.byType(BlochSpherePanel))
                .camera
                .yaw,
            isNot(panel.camera.yaw));
        expect(circuit.currentState, same(state));
        expect(circuit.simulationRunCount, simulations);
        expect(progress.state, same(progressState));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
