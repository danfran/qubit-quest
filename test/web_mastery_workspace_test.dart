import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/two_qubits_gate_target_qubit_selection_dialog.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';

void main() {
  Future<CampaignProgressController> controllerWith(
    CampaignProgressState state,
  ) async {
    final controller = CampaignProgressController(
      store: InMemoryCampaignProgressStore(state),
    );
    await controller.load();
    return controller;
  }

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpShell(
    WidgetTester tester,
    CampaignProgressController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: QubitQuestWebShell(
          progressController: controller,
          sandboxPersistenceStore: SandboxPersistenceStore(
            storage: InMemoryAppStorage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  CampaignProgressState unlockedState({Set<int> completed = const {}}) =>
      CampaignProgressState(
        maxUnlockedLevel: ProgressionRules.guidedDiscoveryLevelCount + 1,
        completedLessonIds: {
          for (var id = 1;
              id <= ProgressionRules.guidedDiscoveryLevelCount;
              id++)
            id,
        },
        completedChallengeIds: completed,
      );

  testWidgets(
      'Mastery opens overview from the shell without an automatic selection',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    final controller = await controllerWith(CampaignProgressState.fresh());
    await pumpShell(tester, controller);
    await tester.tap(find.byKey(const ValueKey('web-nav-mastery')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('web-mastery-overview')), findsOneWidget);
    expect(find.text('0 / 42 complete'), findsOneWidget);
    expect(find.byKey(const ValueKey('web-mastery-continue')), findsNothing);
    expect(find.byKey(const ValueKey('web-mastery-workspace-header')),
        findsNothing);
    expect(
        find.byKey(
            const ValueKey('web-mastery-challenge-global_phase_equivalence')),
        findsOneWidget);
    await controller.completeMasteryChallenge('global_phase_equivalence');
    await tester.pumpAndSettle();
    expect(find.text('1 / 42 complete'), findsOneWidget);
  });

  testWidgets(
      'browser exposes all cards in order and combines title search with filters',
      (tester) async {
    await setSize(tester, const Size(1100, 900));
    final challenges = mastery2Catalogue.orderedDefinitions;
    final controller = await controllerWith(CampaignProgressState(
      maxUnlockedLevel: 1,
      completedMasterySemanticIds: {
        challenges.first.semanticId,
        challenges.last.semanticId
      },
    ));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WebMasteryWorkspace(
      progressController: controller,
      onBackToJourney: () {},
      onOpenNotebook: () {},
    ))));
    await tester.pumpAndSettle();
    final seen = <String>{};
    final overview = find.byKey(const ValueKey('web-mastery-overview'));
    for (var i = 0; i < 20 && seen.length < 42; i++) {
      for (final c in challenges) {
        if (find
            .byKey(ValueKey('web-mastery-challenge-${c.semanticId}'))
            .evaluate()
            .isNotEmpty) {
          seen.add(c.semanticId);
        }
      }
      await tester.drag(overview, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(seen.toList(), challenges.map((c) => c.semanticId).toList());
    final scroll =
        find.descendant(of: overview, matching: find.byType(Scrollable)).first;
    tester.state<ScrollableState>(scroll).position.jumpTo(0);
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('web-mastery-search'));
    await tester.enterText(search, 'hIdDeN');
    await tester.pumpAndSettle();
    final expected = challenges
        .where((c) => c.title.toLowerCase().contains('hidden'))
        .length;
    expect(find.text('$expected challenges'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('web-mastery-filter-completed')));
    await tester.pumpAndSettle();
    expect(find.text('No matching challenges.'), findsOneWidget);
    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    expect(find.text('2 challenges'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('web-mastery-filter-incomplete')));
    await tester.pumpAndSettle();
    expect(find.text('40 challenges'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('web-mastery-filter-all')));
    await tester.pumpAndSettle();
    expect(find.text('42 challenges'), findsOneWidget);
    for (final width in [360.0, 1100.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      expect(find.text('2 / 42 complete'), findsOneWidget);
      expect(find.byKey(const ValueKey('web-mastery-challenge-chooser')),
          findsNothing);
      expect(find.byKey(const ValueKey('web-mastery-challenge-list-narrow')),
          findsNothing);
      for (final scroller
          in tester.widgetList<Scrollable>(find.byType(Scrollable))) {
        // The search field has its own horizontal text-edit viewport.
        if (scroller.axisDirection == AxisDirection.right) continue;
        expect(scroller.axisDirection, AxisDirection.down);
      }
      final first = tester.getRect(find.byKey(
          ValueKey('web-mastery-challenge-${challenges.first.semanticId}')));
      final second = tester.getRect(find.byKey(
          ValueKey('web-mastery-challenge-${challenges[1].semanticId}')));
      if (width == 360)
        expect(second.top, greaterThan(first.bottom));
      else
        expect(second.top, first.top);
      expect(first.right, lessThanOrEqualTo(width));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'workspace navigation has ordered boundaries, Back and Continue at every width',
      (tester) async {
    await setSize(tester, const Size(1100, 1100));
    final controller = await controllerWith(CampaignProgressState.fresh());
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WebMasteryWorkspace(
      progressController: controller,
      onBackToJourney: () {},
      onOpenNotebook: () {},
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(
        const ValueKey('web-mastery-challenge-global_phase_equivalence')));
    await tester.pumpAndSettle();
    final previous = find.byKey(const ValueKey('web-mastery-previous'));
    final next = find.byKey(const ValueKey('web-mastery-next'));
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
    expect(find.text('Challenge 1 of 42'), findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Challenge 2 of 42'), findsOneWidget);
    final circuit = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
        .circuit;
    for (final width in [360.0, 1100.0]) {
      tester.view.physicalSize = Size(width, 1100);
      await tester.pumpAndSettle();
      expect(find.text('0 / 42 complete'), findsOneWidget);
      expect(find.text('Back to Mastery'), findsOneWidget);
      expect(previous.hitTestable(), findsOneWidget);
      expect(next.hitTestable(), findsOneWidget);
      expect(find.byKey(const ValueKey('web-mastery-active-status')),
          findsOneWidget);
      if (find.byType(ComposerCircuitCanvas).evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.byType(ComposerCircuitCanvas),
          300,
          scrollable: find
              .descendant(
                of: find.byType(WebLessonWorkspace),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      expect(
          tester
              .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
              .circuit,
          same(circuit));
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(const ValueKey('web-mastery-back-overview')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-mastery-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Challenge 2 of 42'), findsOneWidget);
    expect(
        tester
            .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
            .circuit,
        same(circuit));
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(find.text('Challenge 1 of 42'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('web-mastery-back-overview')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('web-mastery-search')),
        'Reflect About a Different State');
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(const ValueKey('web-mastery-challenge-nonuniform_reference_reflection')));
    await tester.pumpAndSettle();
    expect(find.text('Challenge 42 of 42'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(next).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNotNull);
  });

  testWidgets('Challenge 25 shows live Current and authored Target State',
      (tester) async {
    final controller = await controllerWith(unlockedState());
    await setSize(tester, const Size(1280, 1000));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: WebMasteryWorkspace(
          progressController: controller,
          onBackToJourney: () {},
          onOpenNotebook: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('web-mastery-search')),
        'A Hidden Sign Across Three Qubits');
    await tester.pumpAndSettle();
    final challenge25 = find.byKey(
      const ValueKey('web-mastery-challenge-ghz_phase_manipulation'),
    );
    await tester.ensureVisible(challenge25);
    await tester.pumpAndSettle();
    await tester.tap(challenge25);
    await tester.pumpAndSettle();

    expect(find.text('A Hidden Sign Across Three Qubits'), findsWidgets);
    expect(find.byType(ComposerCircuitCanvas), findsOneWidget);
    expect(
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .surfaceTreatment,
      ComposerCircuitSurfaceTreatment.workbench,
    );
    final palette = tester.widget<ComposerGatePalette>(
      find.byType(ComposerGatePalette),
    );
    expect(palette.gates.map((gate) => gate.type), [SelectedGateType.z]);
    final primaryPane = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-primary-pane')),
    );
    final inspectorPane = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-inspection-pane')),
    );
    final toolbar = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-toolbar')),
    );
    final actions = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-contextual-actions')),
    );
    expect(toolbar.left, greaterThanOrEqualTo(primaryPane.left));
    expect(toolbar.right, lessThanOrEqualTo(primaryPane.right));
    expect(toolbar.right, lessThan(inspectorPane.left));
    expect(actions.top, greaterThanOrEqualTo(primaryPane.bottom));
    final current = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-lesson-current-state')),
    );
    final target = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-lesson-target-state')),
    );
    final circuit = tester
        .widget<ComposerCircuitCanvas>(
          find.byType(ComposerCircuitCanvas),
        )
        .circuit;
    final simulationRuns = circuit.simulationRunCount;
    expect(identical(current.stateVector, circuit.currentState.stateVector),
        isTrue);
    expect(current.stateVector[0].real, closeTo(0.7071067812, 1e-9));
    expect(current.stateVector[7].real, closeTo(0.7071067812, 1e-9));
    expect(target.stateVector[0].real, closeTo(0.7071067812, 1e-9));
    expect(target.stateVector[7].real, closeTo(-0.7071067812, 1e-9));
    final filter = find.descendant(
      of: find.byKey(const ValueKey('web-lesson-current-state')),
      matching: find.byType(Checkbox),
    );
    expect(tester.widget<Checkbox>(filter).value, isTrue);
    expect(circuit.simulationRunCount, simulationRuns);
    expect(controller.state.completedMasterySemanticIds,
        isNot(contains('ghz_phase_manipulation')));
    expect(find.byType(BlochSpherePanel), findsNothing);
    expect(
      find.byKey(const ValueKey('quantum-inspector-bloch-unavailable')),
      findsOneWidget,
    );
    final selector = tester.widget<SegmentedButton<QuantumInspectorView>>(
      find.byKey(const ValueKey('quantum-inspector-view-selector')),
    );
    expect(
      selector.segments
          .singleWhere((segment) => segment.value == QuantumInspectorView.bloch)
          .enabled,
      isFalse,
    );

    await setSize(tester, const Size(700, 1000));
    await tester.pump();
    expect(
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .surfaceTreatment,
      ComposerCircuitSurfaceTreatment.inset,
    );
    expect(find.byKey(const ValueKey('web-mastery-workspace-header')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('web-lesson-current-state')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('web-lesson-target-state')), findsOneWidget);
    expect(tester.widget<Checkbox>(filter).value, isTrue);
  });

  for (final targetQubit in [0, 1]) {
    testWidgets(
        'Challenge 28 CX targeting q$targetQubit auto-selects its control',
        (tester) async {
      await setSize(tester, const Size(1280, 1000));
      final challenge = mastery2Catalogue.orderedDefinitions.singleWhere(
        (challenge) => challenge.displayOrder == 28,
      );
      final level = challenge.levelDefinition as ComposerLevel;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: WebComposerLesson(
              level: level,
              enabled: true,
              onSolved: () async {},
              desktopWorkspace: true,
            ),
          ),
        ),
      );
      await tester.pump();

      var canvas = tester.widget<ComposerCircuitCanvas>(
        find.byType(ComposerCircuitCanvas),
      );
      await canvas.onDropRequested(
        ComposerCircuitDropIntent(
          data: CircuitDragData.palette(
            Gate.fromIdentifier(SelectedGateType.cnot),
          ),
          destination: CircuitDropDestination(
            contentPoint: const Offset(160, 20),
            location: CircuitLocation(qubit: targetQubit, column: 4),
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
      final inserted = canvas.circuit.logicalGates.last;
      expect(inserted.type, SelectedGateType.cnot);
      expect(inserted.targetQubit, targetQubit);
      expect(inserted.controlQubit, 1 - targetQubit);
      expect(inserted.fragments, hasLength(2));
      expect(
        inserted.fragments.map((fragment) => fragment.placedGate.id).toSet(),
        {inserted.id},
      );
      expect(inserted.hasValidTopology(2), isTrue);
    });
  }

  test('Mastery completion persists through the canonical campaign store',
      () async {
    final storage = InMemoryAppStorage();
    final store = SharedPreferencesCampaignProgressStore(storage: storage);
    final first = CampaignProgressController(store: store);
    await first.load();
    await first.completeLesson(60);
    await first.completeMasteryChallenge('global_phase_equivalence');

    final restored = CampaignProgressController(
      store: SharedPreferencesCampaignProgressStore(storage: storage),
    );
    await restored.load();
    expect(restored.masteryChallengesUnlocked, isTrue);
    expect(
      restored.state.completedMasterySemanticIds,
      contains('global_phase_equivalence'),
    );
    expect(restored.state.completedChallengeIds, isEmpty);
    expect(restored.isLevelUnlocked(114), isTrue);
  });
}
