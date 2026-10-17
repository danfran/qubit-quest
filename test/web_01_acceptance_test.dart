import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/bloch_explorer_panels.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';

void main() {
  Future<CampaignProgressController> loadedController(
    CampaignProgressState state,
  ) async {
    final controller = CampaignProgressController(
      store: InMemoryCampaignProgressStore(state),
    );
    await controller.load();
    return controller;
  }

  CampaignProgressState masteryUnlockedState() => CampaignProgressState(
        maxUnlockedLevel: ProgressionRules.guidedDiscoveryLevelCount + 1,
        completedLessonIds: {
          for (var id = 1;
              id <= ProgressionRules.guidedDiscoveryLevelCount;
              id++)
            id,
        },
      );

  Future<void> setViewport(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );
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

  test('release scope consumes the complete canonical feature catalogues', () {
    expect(allQQLevels, hasLength(ProgressionRules.journeyLevelCount));
    expect(
      allQQLevels.map((level) => level.runtimeType).toSet(),
      {
        ComposerLevel,
        ConceptCheckLevel,
        McqLevel,
        FillTheGateLevel,
        CircuitReadingLevel,
        MeasurementLabLevel,
      },
    );
    expect(groupedLevels.last.isMasteryPhase, isTrue);
    expect(groupedLevels.last.from + 1,
        ProgressionRules.guidedDiscoveryLevelCount + 1);
    expect(groupedLevels.last.to + 1, ProgressionRules.journeyLevelCount);
    expect(
      createSandboxComposerLevel(3).availableGates.map((gate) => gate.type),
      orderedEquals(sandboxGatePaletteTypes),
    );
    expect(
      sandboxGatePaletteTypes.map(GateEducationalCatalog.forType),
      everyElement(isNotNull),
    );
    expect(
      blochExplorerGateTypes.map(GateEducationalCatalog.forType),
      everyElement(isNotNull),
    );
  });

  testWidgets(
      'wide reduced-height shell reaches every release workspace at large text',
      (tester) async {
    await setViewport(
      tester,
      const Size(1280, 650),
      textScale: 1.25,
    );
    final controller = await loadedController(masteryUnlockedState());
    await pumpShell(tester, controller);

    expect(find.byType(LearningMapScreen), findsOneWidget);
    expect(
        find.byKey(const ValueKey('web-navigation-sidebar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('web-qubit-quest-wordmark')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
    await tester.pump();
    expect(find.byType(WebNotebookWorkspace), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('web-nav-mastery')));
    await tester.pump();
    expect(find.byType(WebMasteryWorkspace), findsOneWidget);
    expect(find.byKey(const ValueKey('web-mastery-overview')), findsOneWidget);
    expect(
        find.byKey(
            const ValueKey('web-mastery-activity-global_phase_equivalence')),
        findsNothing);
    await tester.tap(find.byKey(
        const ValueKey('web-mastery-challenge-global_phase_equivalence')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(
          const ValueKey('web-mastery-activity-global_phase_equivalence'),
        ),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-3')));
    await tester.pump();
    expect(find.byType(ComposerGatePalette), findsOneWidget);
    expect(find.byType(ComposerCircuitCanvas), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();
    expect(find.byType(BlochSpherePanel), findsOneWidget);
    expect(find.byType(BlochGatePanel), findsOneWidget);
    expect(find.byType(BlochPlaybackControls), findsOneWidget);
    expect(find.byType(BlochHistoryPanel), findsOneWidget);
    expect(find.byKey(const ValueKey('web-bloch-status')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390px Web keeps compact navigation available at large text',
      (tester) async {
    await setViewport(
      tester,
      const Size(390, 700),
      textScale: 1.25,
    );
    final controller = await loadedController(CampaignProgressState.fresh());
    await pumpShell(tester, controller);

    expect(find.byKey(const ValueKey('web-navigation-sidebar')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('web-navigation-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('web-navigation-drawer')), findsOneWidget);
    for (final destination in WebDestination.values) {
      expect(
          find.byKey(ValueKey('web-nav-${destination.name}')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
