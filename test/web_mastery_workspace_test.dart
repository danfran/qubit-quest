import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_levels.dart';
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

  testWidgets('sidebar shows locked Mastery and explains canonical requirement',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    final controller = await controllerWith(CampaignProgressState.fresh());
    await pumpShell(tester, controller);

    expect(find.byKey(const ValueKey('web-nav-mastery')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('web-nav-mastery-lock')),
      findsOneWidget,
    );
    expect(
      find.byType(WebMasteryWorkspace, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-nav-mastery-1')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('web-nav-mastery')));
    await tester.pumpAndSettle();
    expect(find.text('Mastery Challenges Locked'), findsOneWidget);
    expect(
      find.textContaining('Complete Guided Discovery'),
      findsOneWidget,
    );
    expect(find.byType(LearningMapScreen), findsOneWidget);
  });

  testWidgets('canonical progress unlocks the same sidebar Mastery workspace',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    final controller = await controllerWith(
      CampaignProgressState(maxUnlockedLevel: 60),
    );
    await pumpShell(tester, controller);
    expect(
      find.byKey(const ValueKey('web-nav-mastery-lock')),
      findsOneWidget,
    );

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
      find.byKey(const ValueKey('web-mastery-activity-61')),
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
    await tester.tap(find.byKey(const ValueKey('web-mastery-challenge-2')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('web-mastery-activity-62')),
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
      find.byKey(const ValueKey('web-mastery-activity-62')),
      findsOneWidget,
    );
    expect(
      find.byType(WebMasteryWorkspace, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('locked workspace exposes no challenge content', (tester) async {
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
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('web-mastery-activity-61')), findsNothing);
    expect(find.text(getQQLevelById(61)!.title!), findsNothing);
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
    expect(find.text('1. ${getQQLevelById(61)!.title}'), findsOneWidget);
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
    await first.completeChallenge(61);

    final restored = CampaignProgressController(
      store: SharedPreferencesCampaignProgressStore(storage: storage),
    );
    await restored.load();
    expect(restored.masteryChallengesUnlocked, isTrue);
    expect(restored.state.completedChallengeIds, contains(61));
    expect(restored.isLevelUnlocked(114), isTrue);
  });
}
