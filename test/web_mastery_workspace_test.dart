import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';

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
      findsOneWidget,
    );
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
    await tester.tap(find.byKey(
      const ValueKey('web-mastery-challenge-phase_state_uncomputation'),
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
      find.text(
        '1. ${mastery2Catalogue.orderedDefinitions.first.title}',
      ),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('web-mastery-wide-layout')), findsOneWidget);

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
