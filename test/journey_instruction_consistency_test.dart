import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/widgets/web_learning_text.dart';
import 'support/mastery_math_test_platform.dart';
import 'support/journey_navigation.dart';

void main() {
  useMasteryMathTestPlatform();
  for (final id in [7, 35]) {
    testWidgets('Journey $id keeps all instructional roles on resize',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1200);
      addTearDown(tester.view.reset);
      final progress = CampaignProgressController(
          store: InMemoryCampaignProgressStore(
        CampaignProgressState(
            maxUnlockedLevel: 60,
            completedLessonIds: {for (var i = 1; i <= 60; i++) i}),
      ));
      await progress.load();
      addTearDown(progress.dispose);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: WebJourneyWorkspace(
        progressController: progress,
        onOpenNotebook: () {},
      ))));
      await tester.pumpAndSettle();
      await openJourneyChapter(tester, id == 7 ? 2 : 7);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('web-lesson-chooser')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('web-lesson-choice-$id')));
      await tester.pumpAndSettle();
      final level = getQQLevelById(id)!;
      expect(find.text(level.title!), findsOneWidget);
      // M6a: longer context (mystery text) is one tap away so the objective
      // stays compact; once opened it stays open across resizes.
      expect(find.text(level.mysteryText!), findsNothing);
      await tester.tap(find.byKey(const ValueKey('web-activity-details-toggle')));
      await tester.pumpAndSettle();
      final snapshots = <List<Object?>>[];
      for (final width in [1200.0, 959.0, 961.0]) {
        tester.view.physicalSize = Size(width, 1200);
        await tester.pumpAndSettle();
        // M11D: the header presents the question and a labelled Task
        // callout itself; both keep their authored text at every width.
        expect(find.text('QUESTION'), findsNothing);
        expect(find.text('TASK'), findsOneWidget);
        expect(find.text(level.mysteryText!), findsOneWidget);
        final texts = [
          for (final key in const ['web-compact-question', 'web-compact-task'])
            if (find.byKey(ValueKey(key)).evaluate().isNotEmpty)
              tester.widget<WebLearningText>(find.byKey(ValueKey(key))).text,
        ];
        expect(texts, isNotEmpty);
        snapshots.add(texts);
        expect(snapshots.last, snapshots.first);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
