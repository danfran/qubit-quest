import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/activity_behavior_contract.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/adaptive_learning_card.dart';
import 'package:quantumquiz/widgets/level_header_router.dart';
import 'package:quantumquiz/widgets/level_type_headers.dart';
import 'package:quantumquiz/widgets/qubit_quest_activity_shell.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';

void main() {
  Future<void> pumpLevel(
    WidgetTester tester,
    int levelId, {
    Size size = const Size(430, 900),
    double textScale = 1,
    List<int>? unlocked,
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
            padding: const EdgeInsets.only(top: 24, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
            textScaler: TextScaler.linear(textScale),
          ),
          child: LevelUIRouter.buildLevelUI(
            level: getQQLevelById(levelId)!,
            levelId: levelId,
            onLevelUnlocked: unlocked?.add,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  test('M14-M20 remain constructed Composer challenges in authored order', () {
    const titles = {
      74: 'CNOT Gate',
      75: 'CNOT: Swapping Control & Target',
      76: '3-Qubit CNOT',
      77: 'Uncomputing with CNOT',
      78: 'Toffoli Gate (CCX)',
      79: 'Toffoli: Choose Your Controls',
      80: 'Toffoli Self-Inverse',
    };

    for (final entry in titles.entries) {
      final level = getQQLevelById(entry.key)!;
      expect(level, isA<ComposerLevel>());
      expect(level.title, entry.value);
      expect(
        ActivityBehaviorContract.forLevel(level),
        ActivityInteractionKind.constructedSolution,
      );
    }
  });

  test('M14-M20 use canonical headers while M21 remains outside migration', () {
    for (var levelId = 74; levelId <= 80; levelId++) {
      expect(
        LevelHeaderRouter.headerFor(
          level: getQQLevelById(levelId)!,
          levelId: levelId,
          compact: false,
        ),
        isA<MasteryActivityHeader>(),
      );
    }
    expect(
      LevelHeaderRouter.headerFor(
        level: getQQLevelById(81)!,
        levelId: 81,
        compact: false,
      ),
      isNot(isA<MasteryActivityHeader>()),
    );
  });

  testWidgets('M14-M20 share canonical shell and explicit Check Result',
      (tester) async {
    for (var levelId = 74; levelId <= 80; levelId++) {
      await pumpLevel(tester, levelId, size: const Size(1000, 800));
      expect(find.byType(QubitQuestActivityShell), findsOneWidget);
      expect(find.byType(MasteryActivityHeader), findsOneWidget);
      final check = find.byKey(
        ValueKey('mastery-composer-check-$levelId'),
      );
      expect(check, findsOneWidget);
      final action = tester.widget<QubitQuestActionButton>(check);
      expect(action.label, 'Check Result');
      expect(action.role, QubitQuestActionRole.primary);
      expect(action.onPressed, isNotNull);
      expect(tester.takeException(), isNull, reason: 'M${levelId - 60}');
    }
  });

  testWidgets('M14 does not evaluate or unlock until Check Result is invoked',
      (tester) async {
    final unlocked = <int>[];
    await pumpLevel(
      tester,
      74,
      size: const Size(1000, 800),
      unlocked: unlocked,
    );
    expect(find.textContaining('Not yet'), findsNothing);
    expect(unlocked, isEmpty);

    final check = tester.widget<QubitQuestActionButton>(
      find.byKey(const ValueKey('mastery-composer-check-74')),
    );
    check.onPressed!();
    await tester.pump();
    expect(find.textContaining('Not yet'), findsOneWidget);
    expect(unlocked, isEmpty);
  });

  testWidgets('M14 retains existing adaptive threshold after wrong checks',
      (tester) async {
    await pumpLevel(tester, 74, size: const Size(1400, 1000));
    final check = tester.widget<QubitQuestActionButton>(
      find.byKey(const ValueKey('mastery-composer-check-74')),
    );
    for (var attempt = 0; attempt < 2; attempt++) {
      check.onPressed!();
      await tester.pump();
      expect(find.byType(AdaptiveLearningCard), findsNothing);
    }
    check.onPressed!();
    await tester.pump();
    expect(find.byType(AdaptiveLearningCard), findsOneWidget);
    expect(find.text('ADAPTIVE REINFORCEMENT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two- and three-qubit representatives remain usable when narrow',
      (tester) async {
    for (final levelId in const [74, 78]) {
      await pumpLevel(tester, levelId, textScale: 1.3);
      expect(find.byType(QubitQuestActivityShell), findsOneWidget);
      expect(find.text('Mastery Challenge ${levelId - 60}'), findsOneWidget);
      expect(
        find.byKey(ValueKey('mastery-composer-check-$levelId')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: 'M${levelId - 60}');
    }
  });

  testWidgets('M19 respects the canonical grid at representative Web width',
      (tester) async {
    await pumpLevel(tester, 79, size: const Size(1440, 900));
    final safe = tester.getRect(
      find.byKey(const ValueKey('lesson-content-safe-content')),
    );
    final grid = tester.getRect(
      find.byKey(const ValueKey('qubit-quest-activity-content-grid')),
    );
    expect(grid.width,
        lessThanOrEqualTo(QubitQuestLayout.activityMaxContentWidth));
    expect(grid.center.dx, closeTo(safe.center.dx, 0.01));
    expect(tester.takeException(), isNull);
  });
}
