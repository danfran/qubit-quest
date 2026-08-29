import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/screens/home_page.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Qubit Quest',
      packageName: 'com.example.qubitquest',
      version: '2.3.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<CampaignProgressController> controllerWith(
    CampaignProgressState state,
  ) async {
    final controller = CampaignProgressController(
      store: InMemoryCampaignProgressStore(state),
    );
    await controller.load();
    return controller;
  }

  Future<void> pumpHome(
    WidgetTester tester,
    CampaignProgressState state,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final controller = await controllerWith(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: HomePage(progressController: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home exposes independent Journey and Mastery destinations',
      (tester) async {
    await pumpHome(tester, CampaignProgressState.fresh());

    expect(find.byKey(const ValueKey('home-action-Continue Journey')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('home-action-Mastery Challenges')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('home-action-Quantum Notebook')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('home-action-Learning Map')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-action-Bloch Explorer')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('home-action-Sandbox Composer')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('journey-lesson-1')), findsNothing);
    expect(
      find.byKey(
        const ValueKey('mastery-challenge-global_phase_equivalence'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Notebook follows primary destinations and opens existing screen',
      (tester) async {
    await pumpHome(tester, CampaignProgressState.fresh());

    final journey = find.byKey(const ValueKey('home-action-Continue Journey'));
    final mastery =
        find.byKey(const ValueKey('home-action-Mastery Challenges'));
    final notebook = find.byKey(const ValueKey('home-action-Quantum Notebook'));
    final learningMap = find.byKey(const ValueKey('home-action-Learning Map'));

    expect(
        tester.getTopLeft(journey).dy, lessThan(tester.getTopLeft(mastery).dy));
    expect(tester.getTopLeft(mastery).dy,
        lessThan(tester.getTopLeft(notebook).dy));
    expect(tester.getTopLeft(notebook).dy,
        lessThan(tester.getTopLeft(learningMap).dy));

    await tester.ensureVisible(notebook);
    await tester.tap(notebook);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DiscoveriesScreen), findsOneWidget);
    expect(find.text('Quantum Notebook'), findsWidgets);
  });

  testWidgets('utility menu contains only secondary app actions',
      (tester) async {
    await pumpHome(tester, CampaignProgressState.fresh());

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    final menuItems = find.byType(PopupMenuItem<String>);
    Finder menuLabel(String label) => find.descendant(
          of: menuItems,
          matching: find.text(label),
        );

    expect(menuLabel('Quantum Notebook'), findsNothing);
    expect(menuLabel('Solution Videos'), findsOneWidget);
    expect(menuLabel('Rate Us'), findsOneWidget);
    expect(menuLabel('Privacy Policy'), findsOneWidget);
    expect(menuLabel('About'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Journey contains lessons but no Mastery catalogue',
      (tester) async {
    await pumpHome(
      tester,
      CampaignProgressState(
        maxUnlockedLevel: 2,
        completedLessonIds: const {1},
      ),
    );

    await tester
        .tap(find.byKey(const ValueKey('home-action-Continue Journey')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('learning-journey-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey-lesson-1')), findsOneWidget);
    expect(find.text('Mastery Challenges'), findsNothing);

    final lesson1 = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('journey-lesson-1')),
    );
    final lesson2 = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('journey-lesson-2')),
    );
    final lesson3 = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('journey-lesson-3')),
    );
    expect(lesson1.onPressed, isNotNull);
    expect(lesson2.onPressed, isNotNull);
    expect(lesson3.onPressed, isNull);
  });

  testWidgets('fresh user can browse and open Challenge 2 independently',
      (tester) async {
    await pumpHome(tester, CampaignProgressState.fresh());

    await tester
        .tap(find.byKey(const ValueKey('home-action-Mastery Challenges')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('mastery-challenges-page')), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('mastery-challenge-global_phase_equivalence'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('mastery-challenge-phase_state_uncomputation'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('mastery-challenge-same_histogram_different_state'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('journey-lesson-1')), findsNothing);
    expect(find.textContaining('Phase 2'), findsNothing);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(
      const ValueKey('mastery-challenge-phase_state_uncomputation'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mastery Challenge 2'), findsOneWidget);

    await tester.tap(find.text('Start Challenge'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('canonical-mastery-header')), findsOneWidget);
  });

  testWidgets('Mastery completion state survives catalogue separation',
      (tester) async {
    await pumpHome(
      tester,
      CampaignProgressState(
        maxUnlockedLevel: 1,
        completedChallengeIds: const {62},
        completedMasterySemanticIds: const {'global_phase_equivalence'},
      ),
    );

    expect(find.textContaining('1 / 36 completed'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('home-action-Mastery Challenges')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Completed: 1 / 36'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('mastery-completed-global_phase_equivalence'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mastery-completed-62')),
      findsNothing,
    );
  });
}
