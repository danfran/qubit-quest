import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';

void main() {
  Future<CampaignProgressController> controllerWith(
      [CampaignProgressState? state]) async {
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

  Future<void> pumpJourney(
    WidgetTester tester,
    CampaignProgressController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebJourneyWorkspace(
            progressController: controller,
            onOpenNotebook: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Journey opens a chapter and keeps locked lessons inaccessible',
      (tester) async {
    await setSize(tester, const Size(1280, 900));
    final controller = await controllerWith();
    await pumpJourney(tester, controller);

    await tester.tap(find.text('Chapter 1 — Information'));
    await tester.pump();

    expect(find.byKey(const ValueKey('web-chapter-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-list-wide')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-1')), findsOneWidget);
    expect(find.text(getQQLevelById(1)!.title!), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('web-lesson-item-2')),
        warnIfMissed: false);
    await tester.pump();
    expect(find.byKey(const ValueKey('web-lesson-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-journey-back-map')));
    await tester.pump();
    expect(find.text('Chapter 1 — Information'), findsOneWidget);
  });

  testWidgets('narrow chapter uses stacked lesson navigation', (tester) async {
    await setSize(tester, const Size(700, 900));
    final controller = await controllerWith();
    await pumpJourney(tester, controller);
    await tester.tap(find.text('Chapter 1 — Information'));
    await tester.pump();

    expect(
        find.byKey(const ValueKey('web-lesson-list-narrow')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-composer-canvas')),
        findsOneWidget);
  });

  test('Composer Web validation delegates to the canonical level validator',
      () {
    final level = allQQLevels.whereType<ComposerLevel>().first;
    final canonical = buildCanonicalSolutionCircuit(level);
    final wrong = QuantumCircuit(currentLevel: level);

    expect(validateWebComposerLesson(level, canonical).success, isTrue);
    expect(validateWebComposerLesson(level, wrong).success, isFalse);

    canonical.dispose();
    wrong.dispose();
  });

  testWidgets('wrong Composer circuit stays editable and does not complete',
      (tester) async {
    await setSize(tester, const Size(1100, 1400));
    final level = allQQLevels.whereType<ComposerLevel>().first;
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebComposerLesson(
            level: level,
            enabled: true,
            onSolved: () async => completed = true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('web-lesson-check')));
    await tester.pump();

    expect(completed, isFalse);
    expect(find.textContaining('Not quite yet'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('web-lesson-check')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
      'wrong answer does not progress; correct answer persists progress',
      (tester) async {
    await setSize(tester, const Size(1100, 1400));
    final indexed = allQQLevels.indexed.firstWhere(
      (entry) => entry.$2 is McqLevel && entry.$2.discoveryTitle != null,
    );
    final levelId = indexed.$1 + 1;
    final level = indexed.$2 as McqLevel;
    final controller = await controllerWith(
      CampaignProgressState(maxUnlockedLevel: levelId),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebLessonWorkspace(
            levelId: levelId,
            level: level,
            alreadyCompleted: false,
            onCompleted: () => controller.completeLevel(levelId),
            onNextLesson: () {},
            onBackToChapter: () {},
            onOpenNotebook: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final wrongIndex = level.correctOptionIndex == 0 ? 1 : 0;
    await tester
        .ensureVisible(find.byKey(ValueKey('web-lesson-option-$wrongIndex')));
    await tester.tap(find.byKey(ValueKey('web-lesson-option-$wrongIndex')));
    await tester.pump();
    await tester
        .ensureVisible(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.tap(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.pump();
    expect(controller.state.completedLessonIds.contains(levelId), isFalse);
    expect(find.byKey(const ValueKey('web-lesson-success')), findsNothing);

    await tester.ensureVisible(
      find.byKey(ValueKey('web-lesson-option-${level.correctOptionIndex}')),
    );
    await tester.tap(
        find.byKey(ValueKey('web-lesson-option-${level.correctOptionIndex}')));
    await tester.pump();
    await tester
        .ensureVisible(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.tap(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.pump();

    expect(controller.state.completedLessonIds.contains(levelId), isTrue);
    expect(controller.state.maxUnlockedLevel, greaterThan(levelId));
    expect(
      CampaignProgressPolicy.unlockedDiscoveryTitles(controller.state),
      contains(level.discoveryTitle),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('web-lesson-success'), skipOffstage: false),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('web-lesson-success'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-notebook-updated'), skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('Mastery answer uses shared challenge completion state',
      (tester) async {
    await setSize(tester, const Size(1100, 1400));
    final indexed = allQQLevels.indexed.firstWhere(
      (entry) =>
          ProgressionRules.isMasteryLevel(entry.$1 + 1) && entry.$2 is McqLevel,
    );
    final levelId = indexed.$1 + 1;
    final level = indexed.$2 as McqLevel;
    final controller = await controllerWith(
      CampaignProgressState(
        maxUnlockedLevel: ProgressionRules.guidedDiscoveryLevelCount + 1,
        completedLessonIds: {
          for (int id = 1;
              id <= ProgressionRules.guidedDiscoveryLevelCount;
              id++)
            id,
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebLessonWorkspace(
            levelId: levelId,
            level: level,
            alreadyCompleted: false,
            onCompleted: () => controller.completeLevel(levelId),
            onNextLesson: () {},
            onBackToChapter: () {},
            onOpenNotebook: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(ValueKey('web-lesson-option-${level.correctOptionIndex}')),
    );
    await tester.tap(
        find.byKey(ValueKey('web-lesson-option-${level.correctOptionIndex}')));
    await tester.pump();
    await tester
        .ensureVisible(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.tap(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.pump();

    expect(controller.state.completedChallengeIds, contains(levelId));
    expect(
      find.byKey(const ValueKey('web-lesson-success'), skipOffstage: false),
      findsOneWidget,
    );
  });
}
