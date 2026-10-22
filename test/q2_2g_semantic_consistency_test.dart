import 'package:quantumquiz/models/progression_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/activity_behavior_contract.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/circuit_preview.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';

void main() {
  Future<void> pumpLevel(
    WidgetTester tester,
    int levelId, {
    Size size = const Size(430, 900),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: LevelUIRouter.buildLevelUI(
          activityDomain: NumericActivityDomain.historicalMastery,
          level: getHistoricalMasteryById(levelId)!,
          levelId: levelId,
          onLevelUnlocked: (_) {},
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

  test('M2 guidance uses precise mathematical and physical-state language', () {
    final m2 = getHistoricalMasteryById(62)!;
    expect(m2.conceptIntro, isNot(contains('vector written on the page')));
    expect(m2.conceptIntro, contains('mathematical state vector'));
    expect(m2.conceptIntro, contains('physical quantum state'));
    expect(m2.conceptIntro, contains('global phase'));
  });

  testWidgets('conceptual guidance uses a lightbulb, not sparkles',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: const Scaffold(
          body: QubitQuestCallout(
            variant: QubitQuestCalloutVariant.insight,
            message: 'Conceptual guidance',
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsNothing);
  });

  testWidgets('Composer Goal uses a flag distinct from conceptual Tip',
      (tester) async {
    await pumpLevel(tester, 72, size: const Size(1000, 800));
    expect(find.byIcon(Icons.flag_outlined), findsWidgets);
    expect(find.byIcon(Icons.lightbulb_outline_rounded), findsNothing);
  });

  testWidgets('M4 and M8 use the canonical graphical circuit vocabulary',
      (tester) async {
    for (final levelId in const [64, 68]) {
      await pumpLevel(tester, levelId, size: const Size(800, 1400));
      final preview = find.byKey(ValueKey('fill-gate-circuit-$levelId'));
      expect(preview, findsOneWidget);
      final paints = tester.widgetList<CustomPaint>(
        find.descendant(of: preview, matching: find.byType(CustomPaint)),
      );
      expect(
        paints.any((paint) => paint.painter is QuantumCircuitPainter),
        isTrue,
      );
      expect(find.byType(QubitQuestMissingGateSlot), findsOneWidget);
      expect(find.bySemanticsLabel('Missing gate'), findsOneWidget);
      expect(find.textContaining('[H]'), findsNothing);
      expect(find.textContaining('[?]'), findsNothing);

      final firstGate = find.byKey(const ValueKey('fill-gate-option-0'));
      await reveal(tester, firstGate);
      expect(
        find.descendant(
            of: firstGate, matching: find.byType(QubitQuestGateTile)),
        findsOneWidget,
      );
      final level = getHistoricalMasteryById(levelId)! as FillTheGateLevel;
      final tile = tester.widget<QubitQuestGateTile>(
        find.descendant(
            of: firstGate, matching: find.byType(QubitQuestGateTile)),
      );
      expect(tile.gate.color, level.options.first.color);

      await tester.tap(firstGate);
      await tester.pump();
      expect(
        find.byKey(ValueKey('mastery-fill-feedback-$levelId')),
        findsOneWidget,
        reason: 'Direct manipulation must still evaluate immediately.',
      );
    }
  });

  testWidgets('conceptual-choice presenters use canonical Confirm wording',
      (tester) async {
    for (final levelId in const [61, 62, 63, 66, 71]) {
      await pumpLevel(tester, levelId, size: const Size(800, 1400));
      final optionKey = levelId == 62
          ? const ValueKey('mcq-option-0')
          : const ValueKey('circuit-reading-option-0');
      final option = find.byKey(optionKey);
      await reveal(tester, option);
      await tester.tap(option);
      await tester.pump();
      final actionKey = switch (levelId) {
        61 => const ValueKey('m1-primary-action'),
        62 => const ValueKey('m2-primary-action'),
        _ => ValueKey('mastery-circuit-reading-action-$levelId'),
      };
      await reveal(tester, find.byKey(actionKey));
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Confirm Answer'), findsNothing);
    }
  });

  test('M1-M13 interaction classifications remain unchanged', () {
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
        ActivityBehaviorContract.forLevel(getHistoricalMasteryById(entry.key)!),
        entry.value,
      );
    }
  });
}
