import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/web_composer_workbench.dart';

void main() {
  testWidgets(
      'Journey shell resize preserves Inspector mode and rotated camera',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1000);
    addTearDown(tester.view.reset);
    final progress =
        CampaignProgressController(store: InMemoryCampaignProgressStore());
    await progress.load();
    addTearDown(progress.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: QubitQuestTheme.web(),
      home: QubitQuestWebShell(
        progressController: progress,
        sandboxPersistenceStore:
            SandboxPersistenceStore(storage: InMemoryAppStorage()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chapter 1 — Information'));
    await tester.pumpAndSettle();
    final journey = find.byType(WebJourneyWorkspace);
    Finder within(Type type) =>
        find.descendant(of: journey, matching: find.byType(type));
    final selector = find.descendant(
        of: journey,
        matching:
            find.byKey(const ValueKey('quantum-inspector-view-selector')));
    await tester.ensureVisible(selector);
    await tester.pumpAndSettle();
    await tester
        .tap(find.descendant(of: selector, matching: find.text('Bloch')));
    await tester.pumpAndSettle();
    final sphere = within(BlochSpherePanel);
    await tester.ensureVisible(sphere);
    await tester.pumpAndSettle();
    final initialCamera = tester.widget<BlochSpherePanel>(sphere).camera;
    final canvas = find.descendant(
        of: sphere,
        matching: find.byKey(const ValueKey('bloch-sphere-canvas')));
    final drag = await tester.startGesture(tester.getCenter(canvas),
        kind: PointerDeviceKind.mouse);
    await drag.moveBy(const Offset(20, 8));
    await tester.pump();
    await drag.moveBy(const Offset(40, 18));
    await drag.up();
    await tester.pumpAndSettle();
    final camera = tester.widget<BlochSpherePanel>(sphere).camera;
    expect(camera.yaw, isNot(initialCamera.yaw));
    final states = {
      for (final type in [
        WebJourneyWorkspace,
        WebLessonWorkspace,
        WebComposerLesson,
        WebComposerWorkbench,
        QuantumInspectorViews
      ])
        type:
            tester.state(type == WebJourneyWorkspace ? journey : within(type)),
    };
    final circuit = tester
        .widget<ComposerCircuitCanvas>(within(ComposerCircuitCanvas))
        .circuit;
    final quantumState = circuit.currentState;
    final simulations = circuit.simulationRunCount;
    final progressState = progress.state;
    for (final width in [1198.0, 1200.0, 899.0, 901.0, 803.0, 805.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 1000);
      await tester.pumpAndSettle();
      final lessonList = find.descendant(
          of: journey,
          matching: find.byKey(const ValueKey('web-lesson-content-1')));
      final scroll = tester.state<ScrollableState>(find
          .descendant(of: lessonList, matching: find.byType(Scrollable))
          .first);
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      if (selector.evaluate().isEmpty) {
        await tester.scrollUntilVisible(selector, 100,
            scrollable: find
                .descendant(of: lessonList, matching: find.byType(Scrollable))
                .first);
      }
      await tester.ensureVisible(selector);
      await tester.pumpAndSettle();
      final selected = tester
          .widget<SegmentedButton<QuantumInspectorView>>(selector)
          .selected;
      // If the tab was lost, reopen it so this single failure diagnoses camera loss too.
      if (!selected.contains(QuantumInspectorView.bloch)) {
        await tester
            .tap(find.descendant(of: selector, matching: find.text('Bloch')));
        await tester.pumpAndSettle();
      }
      expect({
        'mode': selected,
        'cameraYaw': tester.widget<BlochSpherePanel>(sphere).camera.yaw,
        'cameraPitch': tester.widget<BlochSpherePanel>(sphere).camera.pitch,
      }, {
        'mode': {QuantumInspectorView.bloch},
        'cameraYaw': camera.yaw,
        'cameraPitch': camera.pitch,
      }, reason: 'mode and rotated camera at width $width');
      for (final entry in states.entries) {
        final current = tester.state(
            entry.key == WebJourneyWorkspace ? journey : within(entry.key));
        expect(current, same(entry.value),
            reason: '${entry.key} lifetime at $width');
      }
      expect(
          tester
              .widget<ComposerCircuitCanvas>(within(ComposerCircuitCanvas))
              .circuit,
          same(circuit));
      expect(circuit.currentState, same(quantumState));
      expect(circuit.simulationRunCount, simulations);
      expect(progress.state, same(progressState));
    }
    for (final label in ['State', 'Bloch', 'State', 'Bloch']) {
      await tester.ensureVisible(selector);
      await tester.pumpAndSettle();
      await tester
          .tap(find.descendant(of: selector, matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<SegmentedButton<QuantumInspectorView>>(selector)
              .selected,
          {
            label == 'Bloch'
                ? QuantumInspectorView.bloch
                : QuantumInspectorView.state
          });
      if (label == 'Bloch')
        expect(tester.widget<BlochSpherePanel>(sphere).camera, same(camera));
    }
    expect(tester.takeException(), isNull);
  });
}
