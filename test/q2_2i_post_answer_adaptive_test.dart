import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/adaptive_learning.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/adaptive_learning_card.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';

const insight = AdaptiveLearningInsight(
  confusionType: AdaptiveConfusionType.repeatedMcqConceptMiss,
  misconceptionCategory: AdaptiveMisconceptionCategory.conceptualInterpretation,
  notebookReinforcement: 'Revisit the distinction between the two states.',
  minimalHint: 'Compare the physical state, not only the vector.',
  keyInsight: 'Key Insight Revisited',
  visualEmphasis: AdaptiveVisualEmphasis.phaseLocation,
);

void main() {
  Future<void> pumpLevel(
    WidgetTester tester,
    int levelId, {
    Size size = const Size(412, 892),
    double textScale = 1,
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
            onLevelUnlocked: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.pump();
  }

  testWidgets('adaptive reinforcement uses canonical semantic foundation',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: AdaptiveLearningCard(
                insight: insight,
                compact: false,
              ),
            ),
          ),
        ),
      ),
    );

    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('adaptive-reinforcement-surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.color, QubitQuestColors.surfaceRaised);
    expect(decoration.borderRadius, QubitQuestRadii.callout);
    expect(
        decoration.border,
        const Border.fromBorderSide(
          QubitQuestBorders.standard,
        ));
    expect(
      find.byKey(const ValueKey('adaptive-reinforcement-icon')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsNothing);
    expect(find.text('ADAPTIVE REINFORCEMENT'), findsOneWidget);
    expect(find.text('Key Insight Revisited'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AdaptiveLearningCard)),
      matchesSemantics(label: AdaptiveLearningCard.semanticLabel),
    );

    final title = tester.widget<Text>(
      find.byKey(const ValueKey('adaptive-reinforcement-title')),
    );
    final concept = tester.widget<Text>(
      find.byKey(const ValueKey('adaptive-reinforcement-concept')),
    );
    expect(title.style, QubitQuestTypography.heading);
    expect(concept.style, QubitQuestTypography.body);
    semantics.dispose();
  });

  test('adaptive component source contains no raw product colour literals', () {
    final source =
        File('lib/widgets/adaptive_learning_card.dart').readAsStringSync();
    expect(source, isNot(contains('Color(0x')));
    expect(source, isNot(contains('QubitQuestDialog.')));
    expect(source, isNot(contains('auto_awesome')));
  });

  testWidgets('adaptive reinforcement wraps at narrow and scaled layouts',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(QubitQuestSpacing.component),
              child: AdaptiveLearningCard(
                insight: insight,
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('adaptive-reinforcement-surface')),
          )
          .width,
      greaterThan(0),
    );
  });

  testWidgets('adaptive reinforcement remains readable at Web width',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.web(),
        home: Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const AdaptiveLearningCard(
                insight: insight,
                compact: false,
              ),
            ),
          ),
        ),
      ),
    );
    final rect = tester.getRect(
      find.byKey(const ValueKey('adaptive-reinforcement-surface')),
    );
    expect(rect.width, lessThanOrEqualTo(720));
    expect(rect.height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('M2 correct path is result, explanation, then primary Continue',
      (tester) async {
    await pumpLevel(tester, 62);
    await reveal(tester, find.byKey(const ValueKey('mcq-option-1')));
    await tester.tap(find.byKey(const ValueKey('mcq-option-1')));
    await reveal(tester, find.byKey(const ValueKey('m2-primary-action')));
    await tester.tap(find.byKey(const ValueKey('m2-primary-action')));
    await tester.pump();

    expect(
      tester
          .widget<QubitQuestChoiceCard>(
            find.byKey(const ValueKey('mcq-option-1')),
          )
          .state,
      QubitQuestChoiceState.correct,
    );
    final explanation = tester.widget<QubitQuestCallout>(
      find.byKey(const ValueKey('m2-answer-feedback')),
    );
    expect(explanation.variant, QubitQuestCalloutVariant.info);
    expect(find.byType(AdaptiveLearningCard), findsNothing);
    await reveal(tester, find.byKey(const ValueKey('m2-primary-action')));
    final action = tester.widget<QubitQuestActionButton>(
      find.byKey(const ValueKey('m2-primary-action')),
    );
    expect(action.label, 'Continue');
    expect(action.role, QubitQuestActionRole.primary);
    expect(QubitQuestColors.accentStrong, isNot(QubitQuestColors.success));
  });

  testWidgets('M2 incorrect path teaches calmly and triggers adaptive logic',
      (tester) async {
    await pumpLevel(tester, 62);
    await reveal(tester, find.byKey(const ValueKey('mcq-option-0')));
    await tester.tap(find.byKey(const ValueKey('mcq-option-0')));
    await reveal(tester, find.byKey(const ValueKey('m2-primary-action')));
    await tester.tap(find.byKey(const ValueKey('m2-primary-action')));
    await tester.pump();

    expect(
      tester
          .widget<QubitQuestChoiceCard>(
            find.byKey(const ValueKey('mcq-option-0')),
          )
          .state,
      QubitQuestChoiceState.incorrect,
    );
    final explanation = tester.widget<QubitQuestCallout>(
      find.byKey(const ValueKey('m2-answer-feedback')),
    );
    expect(explanation.variant, QubitQuestCalloutVariant.info);
    expect(explanation.variant, isNot(QubitQuestCalloutVariant.error));
    await reveal(tester, find.byType(AdaptiveLearningCard));
    expect(find.text('Key Insight Revisited'), findsOneWidget);
  });

  testWidgets('M12 preserves constructed result and adaptive trigger threshold',
      (tester) async {
    await pumpLevel(tester, 72, size: const Size(1400, 1000));
    final check = find.byKey(const ValueKey('mastery-composer-check-72'));
    final button = tester.widget<QubitQuestActionButton>(check);
    for (var attempt = 0; attempt < 2; attempt++) {
      button.onPressed!();
      await tester.pump();
      expect(find.byType(AdaptiveLearningCard), findsNothing);
    }
    button.onPressed!();
    await tester.pump();
    expect(find.textContaining('Not yet'), findsOneWidget);
    expect(find.byType(AdaptiveLearningCard), findsOneWidget);
  });
}
