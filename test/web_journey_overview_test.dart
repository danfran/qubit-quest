// v2.6 M5: the web Learning Journey (master–detail curriculum), Mastery
// availability, shell navigation and route parsing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_journey_overview.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';

ValueKey<String> _k(String key) => ValueKey(key);

CampaignProgressState _after(int lessons) => lessons == 0
    ? CampaignProgressState.fresh()
    : CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(), lessons);

Future<CampaignProgressController> _controller(
    CampaignProgressState state) async {
  final c =
      CampaignProgressController(store: InMemoryCampaignProgressStore(state));
  await c.load();
  return c;
}

Future<void> _pump(
  WidgetTester tester,
  CampaignProgressController controller, {
  Size size = const Size(1440, 900),
  VoidCallback? onOpenMastery,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    home: Scaffold(
      body: WebJourneyWorkspace(
        progressController: controller,
        onOpenNotebook: () {},
        onOpenMastery: onOpenMastery,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

String? _text(WidgetTester tester, String key) {
  final f = find.byKey(_k(key));
  return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
}

Future<void> _select(WidgetTester tester, int chapter) async {
  final row = find.byKey(_k('journey-chapter-$chapter'));
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('fresh user: chapter 1 selected, start action, rest locked',
      (tester) async {
    await _pump(tester, await _controller(_after(0)));
    expect(find.byKey(_k('journey-master-detail')), findsOneWidget);
    expect(_text(tester, 'journey-detail-title'), 'Information');
    expect(
        _text(tester, 'journey-overall-progress'),
        '0 of ${journeyChapters.length} chapters completed · '
        '0 of ${journeyLessons.length} lessons');
    expect(find.text('Start chapter'), findsOneWidget);
    expect(find.byKey(_k('journey-status-2-locked')), findsOneWidget);
    // One status glyph per chapter row: no duplicate indicators.
    for (var n = 1; n <= journeyChapters.length; n++) {
      expect(
          find.descendant(
              of: find.byKey(_k('journey-chapter-$n')),
              matching: find.byWidgetPredicate((w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>)
                      .value
                      .startsWith('journey-status-$n-'))),
          findsOneWidget);
    }
    // M6a: chapter 1 is text-first (any X circuit would be its answer).
    expect(find.byKey(_k('journey-illustration-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial progress: current chapter, review, locked preview',
      (tester) async {
    final controller = await _controller(_after(12));
    await _pump(tester, controller);
    expect(_text(tester, 'journey-detail-title'), 'Superposition');
    expect(_text(tester, 'journey-detail-status'),
        'Chapter 3 · In progress · Your current chapter');
    expect(find.text('Continue · Lesson 3.3'), findsOneWidget);
    expect(
        _text(tester, 'journey-chapter-progress'), '2 of 5 lessons completed');
    expect(_text(tester, 'journey-lesson-action-13'), 'Continue');

    // A completed chapter is reviewable; the current one stays one tap away.
    await _select(tester, 1);
    expect(find.text('Review chapter'), findsOneWidget);
    expect(find.byKey(_k('journey-go-to-current')), findsOneWidget);
    await tester.tap(find.byKey(_k('journey-go-to-current')));
    await tester.pumpAndSettle();
    expect(_text(tester, 'journey-detail-title'), 'Superposition');

    // Locked preview: prerequisite named, nothing opens, nothing changes.
    final before = controller.state;
    await _select(tester, 4);
    expect(_text(tester, 'journey-detail-title'), 'Interference');
    expect(_text(tester, 'journey-prerequisite'),
        contains('“${getJourneyLessonById(15)!.title}”'));
    final action =
        tester.widget<FilledButton>(find.byKey(_k('journey-primary-action')));
    expect(action.onPressed, isNull);
    await tester.ensureVisible(find.byKey(_k('journey-lesson-16')));
    await tester.tap(find.byKey(_k('journey-lesson-16')));
    await tester.pumpAndSettle();
    expect(find.byType(WebLessonWorkspace), findsNothing);
    expect(controller.state.completedLessonIds, before.completedLessonIds);
    expect(controller.state.maxUnlockedLevel, before.maxUnlockedLevel);
  });

  testWidgets(
      'continue opens the next lesson; completing it updates the '
      'Journey on return', (tester) async {
    final controller = await _controller(_after(12));
    await _pump(tester, controller);
    await tester.tap(find.byKey(_k('journey-primary-action')));
    await tester.pumpAndSettle();
    final lesson =
        tester.widget<WebLessonWorkspace>(find.byType(WebLessonWorkspace));
    expect(lesson.levelId, 13);
    await lesson.onCompleted();
    await tester.pump();
    await tester.tap(find.byKey(_k('web-journey-back-map')));
    await tester.pumpAndSettle();
    expect(_text(tester, 'journey-detail-title'), 'Superposition');
    expect(
        _text(tester, 'journey-chapter-progress'), '3 of 5 lessons completed');
    expect(_text(tester, 'journey-lesson-action-14'), 'Continue');
    expect(controller.state.completedLessonIds, contains(13));
  });

  testWidgets('completed curriculum stays a review environment',
      (tester) async {
    await _pump(tester, await _controller(_after(journeyLessons.length)));
    // v2.6 M10: Chapter 14 is now the final chapter.
    expect(_text(tester, 'journey-detail-title'), 'Conditional Quantum Logic');
    expect(find.text('Review chapter'), findsOneWidget);
    expect(find.byKey(_k('journey-complete-note')), findsOneWidget);
    expect(find.byKey(_k('journey-go-to-current')), findsNothing);
    expect(_text(tester, 'journey-overall-progress'),
        startsWith('${journeyChapters.length} of ${journeyChapters.length}'));
  });

  testWidgets('Mastery is offered without any lock, from a fresh start',
      (tester) async {
    var mastery = 0;
    await _pump(tester, await _controller(_after(0)),
        onOpenMastery: () => mastery++);
    await tester.tap(find.byKey(_k('journey-open-mastery')));
    expect(mastery, 1);
    await _select(tester, 12);
    expect(find.byKey(_k('journey-prepares-mastery')), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing,
        reason: 'no Mastery lock glyph anywhere in the Journey');
  });

  testWidgets('native map: the Mastery node is open on a fresh install',
      (tester) async {
    var mastery = 0;
    await tester.pumpWidget(MaterialApp(
        home: LearningMapScreen(
      progressState: CampaignProgressState.fresh(),
      onStartChapter: (_) async {},
      onOpenMastery: () => mastery++,
    )));
    final node = find.byKey(_k('learning-map-chapter-15')) /* Mastery follows 14 chapters (v2.6 M10) */;
    await tester.ensureVisible(node);
    await tester.pumpAndSettle();
    await tester.tap(node);
    await tester.pump();
    expect(mastery, 1);
  });

  for (final (size, layout) in [
    (const Size(1920, 1080), 'journey-master-detail'),
    (const Size(1024, 768), 'journey-master-detail'),
    (const Size(760, 700), 'journey-master-detail'),
    (const Size(500, 900), 'journey-narrow-list'),
  ]) {
    testWidgets('layout at $size', (tester) async {
      await _pump(tester, await _controller(_after(12)), size: size);
      expect(find.byKey(_k(layout)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('narrow: list → chapter → back keeps the selection',
      (tester) async {
    final controller = await _controller(_after(12));
    await _pump(tester, controller, size: const Size(480, 900));
    expect(find.byKey(_k('journey-narrow-list')), findsOneWidget);
    await _select(tester, 2);
    expect(find.byKey(_k('journey-narrow-detail')), findsOneWidget);
    expect(_text(tester, 'journey-detail-title'), 'Hidden Change');
    await tester.tap(find.byKey(_k('journey-back-to-curriculum')));
    await tester.pumpAndSettle();
    expect(find.byKey(_k('journey-narrow-list')), findsOneWidget);
    // Widening keeps the chosen chapter and changes no progress.
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(_text(tester, 'journey-detail-title'), 'Hidden Change');
    expect(controller.state.completedLessonIds.length, 12);
    expect(tester.takeException(), isNull);
  });

  group('shell', () {
    testWidgets('sidebar has no Mastery lock; collapse keeps the Journey',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(QubitQuestWebApp(storage: InMemoryAppStorage()));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-nav-mastery-lock')), findsNothing);
      expect(find.byType(WebJourneyOverview), findsOneWidget);
      await tester.tap(find.byKey(_k('web-navigation-collapse')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-navigation-rail')), findsOneWidget);
      expect(find.byType(WebJourneyOverview), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('startup route selects the destination and chapter',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(QubitQuestWebApp(
          storage: InMemoryAppStorage(), startupRoute: '/journey/chapter-5'));
      await tester.pumpAndSettle();
      // Locked for a fresh user: the link previews it and unlocks nothing.
      expect(_text(tester, 'journey-detail-title'), 'Entanglement');
      expect(find.byKey(_k('journey-prerequisite')), findsOneWidget);
    });

    test('route parsing', () {
      expect(parseWebRoute(''), isNull);
      expect(parseWebRoute('/'), isNull);
      expect(parseWebRoute('/unknown'), isNull);
      expect(parseWebRoute('/composer')!.destination, WebDestination.composer);
      final chapter = parseWebRoute('/journey/chapter-3')!;
      expect(chapter.destination, WebDestination.journey);
      expect(chapter.chapterIndex, 2);
      expect(parseWebRoute('/journey/chapter-99')!.chapterIndex, isNull,
          reason: 'unknown chapters fall back to the current chapter');
      expect(parseWebRoute('/journey/lesson-5')!.chapterIndex, isNull);
    });
  });
}
