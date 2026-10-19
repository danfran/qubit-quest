import 'package:quantumquiz/models/progression_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/activity_behavior_contract.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/level_header_router.dart';
import 'package:quantumquiz/widgets/level_type_headers.dart';
import 'package:quantumquiz/widgets/qubit_quest_activity_shell.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';

void main() {
  Future<void> pumpLevel(
    WidgetTester tester,
    int levelId, {
    Size size = const Size(800, 1000),
    EdgeInsets safePadding = EdgeInsets.zero,
    double textScale = 1,
    bool isCompleted = false,
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
            textScaler: TextScaler.linear(textScale),
          ),
          child: LevelUIRouter.buildLevelUI(
            level: getQQLevelById(levelId)!,
            levelId: levelId,
            activityDomain: levelId >= ProgressionRules.legacyMasteryFirstId
                ? NumericActivityDomain.historicalMastery
                : NumericActivityDomain.journey,
            onLevelUnlocked: (_) {},
            isCompleted: isCompleted,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  test('M1-M13 retain canonical headers after the M14-M20 migration', () {
    for (var levelId = 61; levelId <= 73; levelId++) {
      expect(
        LevelHeaderRouter.headerFor(
          level: getQQLevelById(levelId)!,
          levelId: levelId,
          activityDomain: levelId >= ProgressionRules.legacyMasteryFirstId
              ? NumericActivityDomain.historicalMastery
              : NumericActivityDomain.journey,
          compact: false,
        ),
        isA<MasteryActivityHeader>(),
        reason: 'Expected canonical Mastery header for global ID $levelId',
      );
    }
    expect(
      LevelHeaderRouter.headerFor(
        level: getQQLevelById(81)!,
        levelId: 81,
        activityDomain: 81 >= ProgressionRules.legacyMasteryFirstId
            ? NumericActivityDomain.historicalMastery
            : NumericActivityDomain.journey,
        compact: false,
      ),
      isNot(isA<MasteryActivityHeader>()),
    );
  });

  testWidgets('M1-M13 presenters use the canonical activity shell',
      (tester) async {
    for (var levelId = 61; levelId <= 73; levelId++) {
      await pumpLevel(tester, levelId);
      expect(
        find.byType(QubitQuestActivityShell),
        findsOneWidget,
        reason: 'Expected canonical activity shell for global ID $levelId',
      );
      expect(find.byType(MasteryActivityHeader), findsOneWidget);
      expect(find.byKey(const ValueKey('lesson-content-safe-content')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('canonical-mastery-identity')),
          findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'global ID $levelId');
    }
  });

  testWidgets('header roles and completed status use canonical semantics',
      (tester) async {
    await pumpLevel(tester, 61, isCompleted: true);
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('canonical-mastery-title')),
    );
    final subtitle = tester.widget<Text>(
      find.byKey(const ValueKey('canonical-mastery-subtitle')),
    );
    expect(title.data, 'Mastery Challenge 1');
    expect(title.style, QubitQuestTypography.heading);
    expect(subtitle.data, 'A Change That Cancels');
    expect(subtitle.style, QubitQuestTypography.supporting);
    expect(subtitle.style?.color, QubitQuestColors.textMuted);
    expect(find.text('✓ Completed'), findsOneWidget);
    final completed = tester.widget<Text>(find.text('✓ Completed'));
    expect(completed.style?.color, QubitQuestColors.success);
  });

  testWidgets('header actions use the shared 44px treatment where available',
      (tester) async {
    await pumpLevel(tester, 62);
    expect(find.byType(LevelHeaderActionShell), findsNWidgets(2));
    for (final shell in tester.widgetList<LevelHeaderActionShell>(find.byType(
      LevelHeaderActionShell,
    ))) {
      expect(shell.size, 44);
    }
    expect(find.byTooltip('Quantum Notebook'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsOneWidget);
  });

  testWidgets('shared grid is centred, bounded, and respects landscape insets',
      (tester) async {
    const size = Size(1400, 800);
    const safe = EdgeInsets.only(left: 90, right: 34);
    await pumpLevel(tester, 64, size: size, safePadding: safe);
    final safeRect = tester.getRect(
      find.byKey(const ValueKey('lesson-content-safe-content')),
    );
    final gridRect = tester.getRect(
      find.byKey(const ValueKey('qubit-quest-activity-content-grid')),
    );
    expect(safeRect.left, greaterThanOrEqualTo(safe.left));
    expect(safeRect.right, lessThanOrEqualTo(size.width - safe.right));
    expect(gridRect.width,
        lessThanOrEqualTo(QubitQuestLayout.activityMaxContentWidth));
    expect(gridRect.center.dx, closeTo(safeRect.center.dx, 0.01));
  });

  testWidgets('long scaled header content remains usable on narrow portrait',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 760);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 760),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            appBar: MasteryActivityHeader(
              title: 'Mastery Challenge 12 with a deliberately long title',
              subtitle:
                  'A long challenge-specific subtitle that must wrap without colliding',
              isCompleted: true,
              actions: [
                QubitQuestIconAction(
                  icon: Icons.school_outlined,
                  tooltip: 'Quantum Notebook',
                  onPressed: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
        find.byKey(const ValueKey('canonical-mastery-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('canonical-mastery-subtitle')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shell bottom action stays above the device safe inset',
      (tester) async {
    const size = Size(430, 900);
    const safe = EdgeInsets.only(bottom: 34);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: size,
            padding: safe,
            viewPadding: safe,
          ),
          child: QubitQuestActivityShell(
            header: const MasteryActivityHeader(
              title: 'Mastery Challenge 9',
              subtitle: 'Observation',
              isCompleted: false,
              actions: [],
            ),
            body: const SizedBox.expand(),
            bottomAction: QubitQuestActionButton(
              label: 'Continue',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final action = tester.getRect(
      find.byKey(const ValueKey('qubit-quest-activity-bottom-action')),
    );
    expect(action.bottom, lessThanOrEqualTo(size.height - safe.bottom));
    expect(tester.takeException(), isNull);
  });

  test('M1-M13 ActivityBehaviorContract semantics remain unchanged', () {
    const expected = {
      61: ActivityInteractionKind.conceptualChoice,
      62: ActivityInteractionKind.conceptualChoice,
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
      expect(
        ActivityBehaviorContract.forLevel(getQQLevelById(entry.key)!),
        entry.value,
      );
    }
  });
}
