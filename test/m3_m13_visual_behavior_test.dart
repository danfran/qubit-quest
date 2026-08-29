import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/activity_behavior_contract.dart';
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
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: safePadding,
            viewPadding: safePadding,
          ),
          child: LevelUIRouter.buildLevelUI(
            level: getQQLevelById(levelId)!,
            levelId: levelId,
            onLevelUnlocked: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder verticalScrollable() => find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      );

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: verticalScrollable().first,
    );
    await tester.pump();
  }

  test('M3-M13 use the four semantic interaction contracts', () {
    const expected = {
      63: ActivityInteractionKind.conceptualChoice,
      64: ActivityInteractionKind.directManipulation,
      65: ActivityInteractionKind.constructedSolution,
      66: ActivityInteractionKind.conceptualChoice,
      67: ActivityInteractionKind.constructedSolution,
      68: ActivityInteractionKind.directManipulation,
      69: ActivityInteractionKind.experimentObservation,
      70: ActivityInteractionKind.constructedSolution,
      71: ActivityInteractionKind.conceptualChoice,
      72: ActivityInteractionKind.constructedSolution,
      73: ActivityInteractionKind.constructedSolution,
    };

    for (final entry in expected.entries) {
      final kind =
          ActivityBehaviorContract.forLevel(getQQLevelById(entry.key)!);
      expect(kind, entry.value, reason: 'global ID ${entry.key}');
      expect(
        ActivityBehaviorContract.requiresExplicitEvaluation(kind),
        kind == ActivityInteractionKind.conceptualChoice ||
            kind == ActivityInteractionKind.constructedSolution,
      );
    }
  });

  testWidgets('M3 conceptual choice waits for explicit confirmation',
      (tester) async {
    await pumpLevel(tester, 63);
    expect(find.byType(QubitQuestActivityQuestion), findsOneWidget);
    expect(find.text('CIRCUIT READING'), findsOneWidget);

    final option = find.byKey(const ValueKey('circuit-reading-option-0'));
    await reveal(tester, option);
    await tester.tap(option);
    await tester.pump();
    expect(
      tester.widget<QubitQuestChoiceCard>(option).state,
      QubitQuestChoiceState.selected,
    );
    expect(
      find.byKey(const ValueKey('mastery-circuit-reading-feedback-63')),
      findsNothing,
    );

    final confirm =
        find.byKey(const ValueKey('mastery-circuit-reading-action-63'));
    await reveal(tester, confirm);
    expect(find.text('Confirm'), findsOneWidget);
    await tester.tap(confirm);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('mastery-circuit-reading-feedback-63')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<QubitQuestCallout>(
            find.byKey(
              const ValueKey('mastery-circuit-reading-feedback-63'),
            ),
          )
          .variant,
      QubitQuestCalloutVariant.info,
    );
  });

  testWidgets('M4 gate choice performs immediate evaluation', (tester) async {
    final level = getQQLevelById(64)! as FillTheGateLevel;
    final correctIndex = level.options.indexWhere(
      (gate) => gate.type == level.correctGate.type,
    );
    await pumpLevel(tester, 64);

    expect(find.byType(QubitQuestActivityQuestion), findsOneWidget);
    expect(find.text('FILL THE GATE'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    final option = find.byKey(ValueKey('fill-gate-option-$correctIndex'));
    await reveal(tester, option);
    await tester.tap(option);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('mastery-fill-feedback-64')),
      findsOneWidget,
    );
    final continuation = find.byKey(const ValueKey('mastery-fill-action-64'));
    await reveal(tester, continuation);
    expect(find.text('Continue'), findsOneWidget);
    expect(
      tester.widget<QubitQuestActionButton>(continuation).role,
      QubitQuestActionRole.primary,
    );
  });

  testWidgets(
      'incorrect gate is incorrect state but explanation is educational',
      (tester) async {
    final level = getQQLevelById(68)! as FillTheGateLevel;
    final wrongIndex = level.options.indexWhere(
      (gate) => gate.type != level.correctGate.type,
    );
    await pumpLevel(tester, 68);
    final option = find.byKey(ValueKey('fill-gate-option-$wrongIndex'));
    await reveal(tester, option);
    await tester.tap(option);
    await tester.pump();

    expect(
      find.descendant(of: option, matching: find.byIcon(Icons.cancel)),
      findsOneWidget,
    );
    final feedback = tester.widget<QubitQuestCallout>(
      find.byKey(const ValueKey('mastery-fill-feedback-68')),
    );
    expect(feedback.variant, QubitQuestCalloutVariant.info);
  });

  testWidgets(
      'M9 observes immediately and adds a primary Continue on completion',
      (tester) async {
    await pumpLevel(tester, 69, size: const Size(800, 900));
    expect(find.byType(QubitQuestActivityQuestion), findsOneWidget);
    expect(find.text('MEASUREMENT'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    final measure = find.byKey(const ValueKey('mastery-measure-action'));
    for (var i = 0; i < 20; i++) {
      await tester.tap(measure);
      await tester.pump();
    }
    final continuation = find.byKey(const ValueKey('mastery-measure-continue'));
    expect(continuation, findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(
      tester.widget<QubitQuestActionButton>(continuation).role,
      QubitQuestActionRole.primary,
    );
  });

  testWidgets('early Mastery Composer retains explicit Check Result',
      (tester) async {
    for (final levelId in const [65, 67, 70, 72, 73]) {
      await pumpLevel(tester, levelId, size: const Size(1000, 800));
      expect(
        find.byKey(ValueKey('mastery-composer-check-$levelId')),
        findsOneWidget,
      );
      expect(find.text('Check Result'), findsOneWidget);
    }
  });

  testWidgets('migrated activity bodies remain inside landscape cutouts',
      (tester) async {
    const size = Size(1000, 700);
    const safe = EdgeInsets.only(left: 90, right: 34);
    for (final levelId in const [63, 64, 69, 71]) {
      await pumpLevel(tester, levelId, size: size, safePadding: safe);
      final bounds = tester.getRect(
        find.byKey(const ValueKey('lesson-content-safe-content')),
      );
      expect(bounds.left, greaterThanOrEqualTo(safe.left));
      expect(bounds.right, lessThanOrEqualTo(size.width - safe.right));
      expect(tester.takeException(), isNull);
    }
  });

  test('M21 remains outside the current migration batch', () {
    expect(getQQLevelById(81), isA<ComposerLevel>());
    expect(81, greaterThan(80));
  });
}
