import 'package:quantumquiz/models/progression_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';

void main() {
  Future<void> pumpLevel(
    WidgetTester tester,
    int levelId, {
    Size size = const Size(430, 900),
    EdgeInsets safePadding = EdgeInsets.zero,
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: safePadding,
            viewPadding: safePadding,
            textScaler: TextScaler.linear(textScale),
          ),
          child: LevelUIRouter.buildLevelUI(
            level: getQQLevelById(levelId)!,
            levelId: levelId,
            activityDomain: levelId >= ProgressionRules.legacyMasteryFirstId
                ? NumericActivityDomain.historicalMastery
                : NumericActivityDomain.journey,
            onLevelUnlocked: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  QubitQuestChoiceCard choice(WidgetTester tester, String key) =>
      tester.widget<QubitQuestChoiceCard>(find.byKey(ValueKey(key)));

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final verticalScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: verticalScrollable.first,
    );
    await tester.pump();
  }

  testWidgets('M1 uses shared grammar while retaining its circuit and answer',
      (tester) async {
    final level = getQQLevelById(61)! as CircuitReadingLevel;
    expect(level.correctOptionIndex, 0);

    await pumpLevel(tester, 61);

    expect(find.byType(QubitQuestActivityQuestion), findsOneWidget);
    expect(find.byKey(const ValueKey('m1-supporting-callout')), findsOneWidget);
    expect(find.text('CIRCUIT READING'), findsOneWidget);
    await reveal(
      tester,
      find.byKey(const ValueKey('circuit-reading-circuit')),
    );
    expect(
        find.byKey(const ValueKey('circuit-reading-circuit')), findsOneWidget);

    await reveal(
      tester,
      find.byKey(const ValueKey('circuit-reading-option-0')),
    );
    expect(
      tester.widget(find.byKey(const ValueKey('circuit-reading-option-0'))),
      isA<QubitQuestChoiceCard>(),
    );
    await tester.tap(find.byKey(const ValueKey('circuit-reading-option-0')));
    await tester.pump();
    expect(
      choice(tester, 'circuit-reading-option-0').state,
      QubitQuestChoiceState.selected,
    );
    await reveal(tester, find.byKey(const ValueKey('m1-primary-action')));
    expect(find.byType(QubitQuestActionButton), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('m1-primary-action')));
    await tester.pump();
    expect(find.byKey(const ValueKey('m1-answer-feedback')), findsOneWidget);
    await reveal(tester, find.byKey(const ValueKey('m1-primary-action')));
    expect(find.text('Continue'), findsOneWidget);
    expect(
      tester
          .widget<QubitQuestActionButton>(
            find.byKey(const ValueKey('m1-primary-action')),
          )
          .role,
      QubitQuestActionRole.primary,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('M2 removes duplicate title and uses shared visual semantics',
      (tester) async {
    final level = getQQLevelById(62)! as McqLevel;
    expect(level.correctOptionIndex, 1);

    await pumpLevel(tester, 62);

    expect(find.text('Different Vectors, Same Qubit'), findsOneWidget,
        reason: 'The outer lesson header is the only title owner.');
    expect(find.byType(QubitQuestActivityQuestion), findsOneWidget);
    expect(find.byType(QubitQuestCallout), findsOneWidget);
    expect(find.text('CONCEPT CHECK'), findsOneWidget);

    for (var index = 0; index < level.options.length; index++) {
      final finder = find.byKey(ValueKey('mcq-option-$index'));
      await reveal(tester, finder);
      expect(tester.widget(finder), isA<QubitQuestChoiceCard>());
    }
    await reveal(tester, find.byKey(const ValueKey('mcq-option-1')));
    await tester.tap(find.byKey(const ValueKey('mcq-option-1')));
    await tester.pump();
    expect(
        choice(tester, 'mcq-option-1').state, QubitQuestChoiceState.selected);
    await reveal(tester, find.byKey(const ValueKey('m2-primary-action')));
    expect(find.byType(QubitQuestActionButton), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('m2-primary-action')));
    await tester.pump();
    expect(choice(tester, 'mcq-option-1').state, QubitQuestChoiceState.correct);
    expect(find.byKey(const ValueKey('m2-answer-feedback')), findsOneWidget);
    await reveal(tester, find.byKey(const ValueKey('m2-primary-action')));
    expect(find.text('Continue'), findsOneWidget);
    expect(
      tester
          .widget<QubitQuestActionButton>(
            find.byKey(const ValueKey('m2-primary-action')),
          )
          .role,
      QubitQuestActionRole.primary,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('M1 and M2 retain aligned safe bounds in landscape cutouts',
      (tester) async {
    const size = Size(1000, 700);
    const safe = EdgeInsets.only(left: 90, right: 34);

    for (final entry in const [
      (61, 'circuit-reading-option-0'),
      (62, 'mcq-option-0'),
    ]) {
      await pumpLevel(tester, entry.$1, size: size, safePadding: safe);
      final content = tester.getRect(
        find.byKey(const ValueKey('lesson-content-safe-content')),
      );
      final optionFinder = find.byKey(ValueKey(entry.$2));
      await reveal(tester, optionFinder);
      final option = tester.getRect(optionFinder);
      expect(content.left, greaterThanOrEqualTo(safe.left));
      expect(content.right, lessThanOrEqualTo(size.width - safe.right));
      expect(option.left, greaterThan(safe.left));
      expect(option.right, lessThan(size.width - safe.right));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('M1 and M2 remain usable in portrait at larger text',
      (tester) async {
    for (final levelId in const [61, 62]) {
      await pumpLevel(tester, levelId, textScale: 1.3);
      expect(find.byType(QubitQuestActivityQuestion), findsOneWidget);
      final action = find.byKey(
        ValueKey(levelId == 61 ? 'm1-primary-action' : 'm2-primary-action'),
      );
      await reveal(tester, action);
      expect(find.byType(QubitQuestActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('M3 now joins the shared Circuit Reading visual composition',
      (tester) async {
    await pumpLevel(tester, 63);
    expect(find.byType(QubitQuestActivityQuestion), findsOneWidget);
    expect(find.text('CIRCUIT READING'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('shared answer state resolver is identical for both presenters', () {
    expect(
      QubitQuestChoiceState.forAnswer(
        answered: false,
        isSelected: true,
        isCorrect: false,
      ),
      QubitQuestChoiceState.selected,
    );
    expect(
      QubitQuestChoiceState.forAnswer(
        answered: true,
        isSelected: false,
        isCorrect: true,
      ),
      QubitQuestChoiceState.correct,
    );
    expect(
      QubitQuestChoiceState.forAnswer(
        answered: true,
        isSelected: true,
        isCorrect: false,
      ),
      QubitQuestChoiceState.incorrect,
    );
    expect(
      QubitQuestChoiceState.forAnswer(
        answered: true,
        isSelected: false,
        isCorrect: false,
      ),
      QubitQuestChoiceState.disabled,
    );
  });

  test('callout semantic identity now relies on a quieter common fill', () {
    expect(QubitQuestCallout.backgroundTintOpacity, lessThanOrEqualTo(0.03));
    expect(QubitQuestCallout.borderOpacity,
        greaterThan(QubitQuestCallout.backgroundTintOpacity));
  });
}
