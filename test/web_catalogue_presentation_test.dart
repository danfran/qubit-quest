import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/widgets/activity_instruction_presentation.dart';
import 'package:quantumquiz/widgets/web_activity_instruction_content.dart';
import 'package:quantumquiz/widgets/web_learning_text.dart';
import 'package:quantumquiz/widgets/mastery_evidence_view.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'support/mastery_math_test_platform.dart';

void main() {
  useMasteryMathTestPlatform();
  testWidgets(
      '66 Journey and 42 Mastery contexts preserve roles and order at both widths',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1800);
    addTearDown(tester.view.reset);
    final activities = [
      for (var id = 1; id <= 66; id++)
        (
          id: 'Journey $id',
          level: getJourneyLessonById(id)!,
          presentation: null as MasteryChallengePresentation?
        ),
      for (final c in mastery2Catalogue.orderedDefinitions)
        (
          id: 'Mastery ${c.semanticId}',
          level: c.levelDefinition,
          presentation: requireMasteryPresentation(c.semanticId)
        ),
    ];
    expect(activities.length, 108);
    for (final p in mastery2Presentations.values) {
      expect(p.question.isEmpty || p.question.trim().endsWith('?'), isTrue,
          reason:
              'Instruction continuations must not be classified as questions');
    }
    final embeddedInstruction =
        requireMasteryPresentation('ghz_phase_manipulation')
            .evidence
            .whereType<MasteryTextEvidence>()
            .single;
    expect(embeddedInstruction.isInstruction, isTrue);

    expect(mastery2Presentations.keys.toSet(),
        mastery2Catalogue.orderedDefinitions.map((c) => c.semanticId).toSet());
    for (final activity in activities) {
      final level = activity.level;
      final p = activity.presentation;
      final normalized = normalizeActivityInstructions(
          task: p?.instruction ?? level.taskDescription,
          question: p?.question ?? level.mysteryTitle);
      final expected = <(WebLearningTextRole, String)>[];
      void add(WebLearningTextRole role, String? text) {
        if (text != null && text.isNotEmpty) expected.add((role, text));
      }

      add(WebLearningTextRole.concept, level.conceptIntro);
      final hasEvidence = p != null &&
          (p.evidence.isNotEmpty || p.intro != null || p.helperText != null);
      if (!hasEvidence) add(WebLearningTextRole.question, normalized.question);
      add(WebLearningTextRole.task, normalized.task);
      if (p != null) {
        add(WebLearningTextRole.introduction, p.intro);
        for (final block in p.evidence) {
          add(WebLearningTextRole.evidenceLabel, block.label);
          if (block is MasteryTextEvidence) {
            add(
                block.isInstruction
                    ? WebLearningTextRole.task
                    : WebLearningTextRole.evidence,
                block.text);
          }
          if (block is MasteryPipelineEvidence) {
            for (final stage in block.stages)
              add(WebLearningTextRole.evidence, stage);
          }
        }
        add(WebLearningTextRole.supporting, p.helperText);
        add(WebLearningTextRole.task, p.instructionAfterEvidence);
      }
      if (hasEvidence) add(WebLearningTextRole.question, normalized.question);
      add(WebLearningTextRole.supporting, level.mysteryText);

      for (final width in [1000.0, 360.0]) {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
          body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(
                    child: WebActivityInstructionContent(
                  key: ValueKey(activity.id),
                  level: level,
                  presentation: p,
                )),
              )),
        )));
        await tester.pumpAndSettle();
        final texts = tester
            .widgetList<WebLearningText>(find.byType(WebLearningText))
            .toList();
        expect(texts.map((w) => (w.role!, w.text)).toList(), expected,
            reason:
                '${activity.id} at $width: exact roles/content/order, no duplicates');
        for (final text in texts) {
          final finder = find.byWidget(text);
          final latex =
              find.descendant(of: finder, matching: find.byType(LatexText));
          if (latex.evaluate().isEmpty) {
            expect(
                tester
                    .widget<Text>(find.descendant(
                        of: finder, matching: find.byType(Text)))
                    .style,
                text.role!.textStyle,
                reason: activity.id);
          } else {
            final actual = tester.widget<LatexText>(latex).textStyle!;
            final expectedStyle = text.role!.textStyle;
            expect([
              actual.fontSize,
              actual.fontWeight,
              actual.color,
              actual.height
            ], [
              expectedStyle.fontSize,
              expectedStyle.fontWeight,
              expectedStyle.color,
              expectedStyle.height
            ], reason: activity.id);
            expect(tester.widget<LatexText>(latex).math, text.text);
          }
        }
        if (p != null) {
          for (final (i, evidence) in p.evidence.indexed) {
            final block = find.byKey(ValueKey('mastery-evidence-block-$i'));
            expect(block, findsOneWidget);
            if (i > 0)
              expect(
                  tester.getTopLeft(block).dy,
                  greaterThan(tester
                      .getTopLeft(find
                          .byKey(ValueKey('mastery-evidence-block-${i - 1}')))
                      .dy));
            if (evidence is MasteryMathEvidence) {
              final latex = tester.widget<LatexText>(find
                  .descendant(of: block, matching: find.byType(LatexText))
                  .last);
              expect(latex.mathFontSize,
                  QubitQuestTypography.mathDisplay.fontSize);
              expect(latex.displayMathHeight, 18);
              expect(latex.textStyle, QubitQuestTypography.mathDisplay);
              expect(latex.math,
                  evidence.expression.replaceAll(r'\tfrac', r'\frac'));
            }
            if (evidence is MasteryCircuitEvidence) {
              expect(
                  tester
                      .widget<QubitQuestStaticCircuit>(find.descendant(
                          of: block,
                          matching: find.byType(QubitQuestStaticCircuit)))
                      .evidence,
                  same(evidence));
            }
          }
        }
        expect(tester.takeException(), isNull,
            reason: '${activity.id} at $width');
      }
    }
  });

  testWidgets(
      'MathJax em units balance integers fractions and vectors without native changes',
      (tester) async {
    // Geometry fixtures use MathJax's 1000 units/em contract. More vertical
    // structure changes total height, not the scale of each glyph.
    const heights = {'integer': 700, 'fraction': 2200, 'vector': 3200};
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
            body: Column(children: [
          for (final entry in heights.entries)
            LatexSvgPicture(
                key: ValueKey(entry.key),
                svg:
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 ${entry.value}"><path d="M0 0H1000V700H0Z"/></svg>',
                logicalHeight: 24,
                mathFontSize: 18,
                color: Colors.white),
          const LatexSvgPicture(
              key: ValueKey('legacy'),
              svg:
                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 2200"><path d="M0 0H1000V700H0Z"/></svg>',
              logicalHeight: 24,
              color: Colors.white),
        ])),
      )));
      for (final entry in heights.entries) {
        expect(
            tester.getSize(find.byKey(ValueKey(entry.key))).height /
                entry.value,
            closeTo(18 / 1000 * scale, .0001));
      }
      expect(tester.getSize(find.byKey(const ValueKey('legacy'))).height,
          24 * scale);
      expect(tester.takeException(), isNull);
    }
  });
}
