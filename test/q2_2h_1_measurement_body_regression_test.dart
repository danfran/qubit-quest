import 'package:quantumquiz/models/progression_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/activity_behavior_contract.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/level_type_headers.dart';

void main() {
  Future<void> pumpLevel(WidgetTester tester, int levelId) async {
    const size = Size(412, 892);
    const safePadding = EdgeInsets.only(top: 24, bottom: 34);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: size,
            padding: safePadding,
            viewPadding: safePadding,
            textScaler: TextScaler.linear(1.1),
          ),
          child: LevelUIRouter.buildLevelUI(
            activityDomain: NumericActivityDomain.historicalMastery,
            level: getHistoricalMasteryById(levelId)!,
            levelId: levelId,
            onLevelUnlocked: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void expectVisibleSize(WidgetTester tester, Finder finder) {
    expect(finder, findsOneWidget);
    final rect = tester.getRect(finder);
    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
    expect(rect.bottom, greaterThan(0));
    expect(rect.top, lessThan(tester.view.physicalSize.height));
  }

  testWidgets('M9 initially paints the complete activity above Measure',
      (tester) async {
    await pumpLevel(tester, 69);

    expect(find.byType(MasteryActivityHeader), findsOneWidget);
    expectVisibleSize(
      tester,
      find.byKey(const ValueKey('qubit-quest-activity-body')),
    );
    expectVisibleSize(tester, find.byType(ListView));
    expectVisibleSize(
      tester,
      find.byKey(const ValueKey('mastery-measure-support')),
    );
    expectVisibleSize(tester, find.text('MEASUREMENT'));
    expectVisibleSize(
      tester,
      find.byKey(const ValueKey('mastery-measure-question')),
    );
    expectVisibleSize(
      tester,
      find.byKey(const ValueKey('mastery-measure-progress')),
    );
    expect(find.text('Measurements: 0 / 20'), findsOneWidget);
    expectVisibleSize(
      tester,
      find.byKey(const ValueKey('mastery-measure-histogram')),
    );
    expect(find.text('Press Measure to start'), findsOneWidget);
    expectVisibleSize(
      tester,
      find.byKey(const ValueKey('mastery-measure-action')),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('M9 observation completion retains histogram and adds Continue',
      (tester) async {
    await pumpLevel(tester, 69);
    final measure = find.byKey(const ValueKey('mastery-measure-action'));
    for (var index = 0; index < 20; index++) {
      await tester.tap(measure);
      await tester.pump();
    }

    expect(find.text('Measurements: 20 / 20'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mastery-measure-histogram')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mastery-measure-feedback')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('mastery-measure-feedback')),
      findsOneWidget,
    );
    expectVisibleSize(
      tester,
      find.byKey(const ValueKey('mastery-measure-continue')),
    );
    expect(tester.takeException(), isNull);
  });

  test('M9 remains experiment observation', () {
    expect(
      ActivityBehaviorContract.forLevel(getHistoricalMasteryById(69)!),
      ActivityInteractionKind.experimentObservation,
    );
  });
}
