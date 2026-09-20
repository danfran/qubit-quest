import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
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

  testWidgets('fresh user can open Mastery from the sidebar', (tester) async {
    await setSize(tester, const Size(1440, 1000));
    final controller = await controllerWith(CampaignProgressState.fresh());
    await pumpShell(tester, controller);

    expect(find.byKey(const ValueKey('web-nav-mastery')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-nav-mastery-lock')), findsNothing);
    expect(
      find.byType(WebMasteryWorkspace, skipOffstage: false),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('web-nav-mastery')));
    await tester.pump();
    expect(find.byKey(const ValueKey('web-mastery-title')), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('web-mastery-activity-global_phase_equivalence'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mastery-evidence-view')),
      findsOneWidget,
    );
  });

  testWidgets('lesson completion does not control sidebar Mastery availability',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    final controller = await controllerWith(
      CampaignProgressState(maxUnlockedLevel: 60),
    );
    await pumpShell(tester, controller);
    expect(find.byKey(const ValueKey('web-nav-mastery-lock')), findsNothing);

    await controller.completeLesson(60);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('web-nav-mastery-lock')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('web-nav-mastery')));
    await tester.pump();

    expect(find.byKey(const ValueKey('web-mastery-title')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('web-mastery-wide-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-mastery-challenge-list-wide')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('web-mastery-challenge-chooser')),
        findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('web-mastery-activity-global_phase_equivalence'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Journey and sidebar retain one Mastery workspace selection',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    final controller = await controllerWith(unlockedState());
    await pumpShell(tester, controller);

    await tester.tap(find.byKey(const ValueKey('web-nav-mastery')));
    await tester.pump();
    await tester
        .tap(find.byKey(const ValueKey('web-mastery-challenge-chooser')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(
      const ValueKey('web-mastery-choice-phase_state_uncomputation'),
    ));
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('web-mastery-activity-phase_state_uncomputation'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('web-mastery-back-journey')));
    await tester.pump();

    final journeyMastery = find.descendant(
      of: find.byType(LearningMapScreen),
      matching: find.text('Mastery Challenges'),
    );
    expect(journeyMastery, findsOneWidget);
    final journeyScroll = find.descendant(
      of: find.byType(LearningMapScreen),
      matching: find.byType(Scrollable),
    );
    await tester.drag(journeyScroll, const Offset(0, -2200));
    await tester.pumpAndSettle();
    await tester.tap(journeyMastery);
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('web-mastery-activity-phase_state_uncomputation'),
      ),
      findsOneWidget,
    );
    expect(
      find.byType(WebMasteryWorkspace, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('fresh workspace exposes challenge content', (tester) async {
    await setSize(tester, const Size(1100, 900));
    final controller = await controllerWith(CampaignProgressState.fresh());
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

    expect(
      find.byKey(const ValueKey('web-mastery-locked-workspace')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('web-mastery-activity-global_phase_equivalence'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Mastery workspace uses canonical order and responsive list',
      (tester) async {
    final controller = await controllerWith(unlockedState());
    await setSize(tester, const Size(1200, 900));
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
    expect(
      find.byKey(const ValueKey('web-mastery-challenge-chooser')),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('web-mastery-wide-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-mastery-challenge-list-wide')),
        findsNothing);
    await tester
        .tap(find.byKey(const ValueKey('web-mastery-challenge-chooser')));
    await tester.pumpAndSettle();
    expect(
      find.text('1. ${mastery2Catalogue.orderedDefinitions.first.title}'),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await setSize(tester, const Size(700, 900));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('web-mastery-stacked-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-mastery-challenge-list-narrow')),
      findsOneWidget,
    );
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
    await tester
        .tap(find.byKey(const ValueKey('web-mastery-challenge-chooser')));
    await tester.pumpAndSettle();
    final challenge25 = find.byKey(
      const ValueKey('web-mastery-choice-ghz_phase_manipulation'),
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
    expect(find.byKey(const ValueKey('web-mastery-stacked-layout')),
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
