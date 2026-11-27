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
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/screens/web_exercise_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart';
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

  /// Selects a challenge in the library, then starts it from its details
  /// (M6a: selection and starting are separate actions).
  Future<void> openChallenge(WidgetTester tester, String semanticId) async {
    final row = find.byKey(ValueKey('web-mastery-challenge-$semanticId'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-mastery-start')));
    await tester.pumpAndSettle();
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
    expect(find.text('0 / 48 complete'), findsOneWidget);
    expect(find.byKey(const ValueKey('web-mastery-continue')), findsNothing);
    // The library selects (shows details of) the first incomplete
    // challenge, but never starts an activity by itself.
    expect(find.byKey(const ValueKey('web-mastery-workspace-header')),
        findsNothing);
    expect(
        find.byKey(const ValueKey(
            'web-mastery-detail-global_phase_equivalence')),
        findsOneWidget);
    expect(find.text('Start challenge'), findsOneWidget);
    expect(
        find.byKey(
            const ValueKey('web-mastery-challenge-global_phase_equivalence')),
        findsOneWidget);
    await controller.completeMasteryChallenge('global_phase_equivalence');
    await tester.pumpAndSettle();
    expect(find.text('1 / 48 complete'), findsOneWidget);
  });

  testWidgets(
      'library lists every challenge in order and combines search with filters',
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
    final overview = find.byKey(const ValueKey('web-mastery-list'));
    for (var i = 0; i < 20 && seen.length < 48; i++) {
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
    expect(find.text('$expected of 48 challenges'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('web-mastery-filter-completed')));
    await tester.pumpAndSettle();
    expect(find.text('No matching challenges.'), findsOneWidget);
    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    expect(find.text('2 of 48 challenges'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('web-mastery-filter-incomplete')));
    await tester.pumpAndSettle();
    expect(find.text('46 of 48 challenges'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('web-mastery-filter-all')));
    await tester.pumpAndSettle();
    expect(find.text('48 of 48 challenges'), findsOneWidget);
    for (final width in [360.0, 1100.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      expect(find.text('2 / 48 complete'), findsOneWidget);
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
      // A compact list at every width (no grid of large cards).
      expect(second.top, greaterThan(first.bottom));
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
    await openChallenge(tester, 'global_phase_equivalence');
    final previous = find.byKey(const ValueKey('web-mastery-previous'));
    final next = find.byKey(const ValueKey('web-mastery-next'));
    expect(tester.widget<IconButton>(previous).onPressed, isNull);
    expect(find.text('Challenge 1 of 48'), findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Challenge 2 of 48'), findsOneWidget);
    final circuit = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
        .circuit;
    for (final width in [360.0, 1100.0]) {
      tester.view.physicalSize = Size(width, 1100);
      await tester.pumpAndSettle();
      expect(find.text('0 / 48 complete'), findsOneWidget);
      expect(find.byTooltip('Back to Mastery Challenges'), findsOneWidget);
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
    // The library keeps the open challenge selected and offers to continue.
    expect(find.text('Continue challenge'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('web-mastery-start')));
    await tester.pumpAndSettle();
    expect(find.text('Challenge 2 of 48'), findsOneWidget);
    expect(
        tester
            .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
            .circuit,
        same(circuit));
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(find.text('Challenge 1 of 48'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('web-mastery-back-overview')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('web-mastery-search')),
        'The Oracle That Left a Trace');
    await tester.pumpAndSettle();
    // The last challenge is 48 since v2.6 M10.
    await openChallenge(tester, 'oracle_left_a_trace');
    expect(find.text('Challenge 48 of 48'), findsOneWidget);
    expect(tester.widget<IconButton>(next).onPressed, isNull);
    expect(tester.widget<IconButton>(previous).onPressed, isNotNull);
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
    await openChallenge(tester, 'ghz_phase_manipulation');

    expect(find.text('A Hidden Sign Across Three Qubits'), findsWidgets);
    expect(find.byType(ComposerCircuitCanvas), findsOneWidget);
    expect(
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .surfaceTreatment,
      ComposerCircuitSurfaceTreatment.workbench,
    );
    final palette = tester.widget<ComposerGatePalettePanel>(
      find.byType(ComposerGatePalettePanel),
    );
    expect(palette.gates.map((gate) => gate.type), [SelectedGateType.z]);
    // The same desktop workspace as the Sandbox and Journey (M6a).
    final canvasRegion =
        tester.getRect(find.byKey(const ValueKey('composer-region-canvas')));
    final resultsRegion =
        tester.getRect(find.byKey(const ValueKey('composer-region-results')));
    final actions =
        tester.getRect(find.byKey(const ValueKey('web-exercise-actions')));
    expect(canvasRegion.right, lessThan(resultsRegion.left));
    expect(actions.top, greaterThanOrEqualTo(canvasRegion.bottom));
    final current = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-composer-current-state')),
    );
    final target = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-composer-target-state')),
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
      of: find.byKey(const ValueKey('web-composer-current-state'),
          skipOffstage: false),
      matching: find.byType(Checkbox, skipOffstage: false),
    );
    expect(tester.widget<Checkbox>(filter).value, isTrue);
    expect(circuit.simulationRunCount, simulationRuns);
    expect(controller.state.completedMasterySemanticIds,
        isNot(contains('ghz_phase_manipulation')));
    expect(find.byType(BlochSpherePanel), findsNothing);
    // Shared Results convention (M3.1): Bloch stays selectable and explains
    // that a three-qubit state has no single-qubit Bloch sphere.
    tester
        .widget<SegmentedButton<QuantumInspectorView>>(
            find.byKey(const ValueKey('quantum-inspector-view-selector')))
        .onSelectionChanged!({QuantumInspectorView.bloch});
    await tester.pump();
    expect(find.byType(BlochSpherePanel), findsNothing);
    expect(
      find.byKey(const ValueKey('quantum-inspector-bloch-unavailable-reason')),
      findsOneWidget,
    );
    tester
        .widget<SegmentedButton<QuantumInspectorView>>(
            find.byKey(const ValueKey('quantum-inspector-view-selector')))
        .onSelectionChanged!({QuantumInspectorView.state});
    await tester.pump();

    await setSize(tester, const Size(700, 1000));
    await tester.pump();
    expect(find.byKey(const ValueKey('web-mastery-workspace-header')),
        findsOneWidget);
    // Medium width: Results is the retained, offstage half of the
    // Circuit/Results switch.
    expect(
        find.byKey(const ValueKey('web-composer-current-state'),
            skipOffstage: false),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('web-composer-target-state'),
            skipOffstage: false),
        findsOneWidget);
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
            body: WebComposerExercise(
              level: level,
              mode: ComposerMode.masteryChallenge,
              contextLabel: 'Challenge 28',
              onCompleted: () async {},
              onNext: () {},
              onOpenNotebook: () {},
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
