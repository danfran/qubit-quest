import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/activity_instruction_presentation.dart';
import 'package:quantumquiz/widgets/mastery_evidence_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/mastery_math_test_platform.dart';
import 'support/mastery_semantic_snapshot.dart';

void main() {
  useMasteryMathTestPlatform();

  test(
      'all 36 identities, answers and quantum data match the pre-pass baseline',
      () {
    final expected = jsonDecode(
        File('test/fixtures/mastery_presentation_semantics.json')
            .readAsStringSync());
    expect(masterySemanticSnapshot(mastery2Catalogue), expected);
  });

  Future<void> pumpTask(WidgetTester tester, String id, Size size, double scale,
      bool native) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final d = mastery2Catalogue.requireBySemanticId(id);
    await tester.pumpWidget(MaterialApp(
      theme: native ? QubitQuestTheme.mobile() : QubitQuestTheme.web(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: native
          ? LevelUIRouter.buildLevelUI(
              level: d.levelDefinition,
              levelId: d.displayOrder,
              masteryChallenge: d,
              onLevelUnlocked: null)
          : Scaffold(
              body: WebLessonWorkspace(
              levelId: d.displayOrder,
              level: d.levelDefinition,
              masteryChallenge: d,
              alreadyCompleted: false,
              onCompleted: () async {},
              onNextLesson: () {},
              onBackToChapter: () {},
              onOpenNotebook: () {},
            )),
    ));
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(1440, 1000), const Size(600, 900)]) {
    testWidgets('Mastery Task outer panel is shared at $size', (tester) async {
      Decoration? taskDecoration;
      for (final id in [
        'phase_kickback_reveal',
        'inverse_phase_synthesis',
        'phased_entanglement_uncomputation',
        'search_pipeline_forensics',
      ]) {
        await pumpTask(tester, id, size, 1, false);
        final heading = find.text('Task');
        expect(heading, findsOneWidget);
        expect(find.text('TASK'), findsNothing);
        final panel = find
            .ancestor(
              of: heading,
              matching: find.byType(DecoratedBox),
            )
            .first;
        final decoration = tester.widget<DecoratedBox>(panel).decoration;
        taskDecoration ??= decoration;
        expect(decoration, taskDecoration, reason: id);
        expect(
            find.descendant(
                of: panel, matching: find.byIcon(Icons.flag_outlined)),
            findsOneWidget);
        final title = find.byKey(const ValueKey('web-lesson-title'));
        expect(tester.getRect(panel).top - tester.getRect(title).bottom, 14);
        if (id == 'phased_entanglement_uncomputation') {
          expect(
              find.descendant(
                  of: panel, matching: find.byType(MasteryEvidenceView)),
              findsNothing);
          expect(find.descendant(of: panel, matching: find.byType(LatexText)),
              findsOneWidget);
          expect(tester.getSize(panel).height,
              lessThan(size.width > 1000 ? 160 : 200));
        } else {
          final evidence = find.descendant(
              of: panel, matching: find.byType(MasteryEvidenceView));
          expect(evidence, findsOneWidget);
          expect(tester.widget<MasteryEvidenceView>(evidence).compactSpacing,
              id == 'inverse_phase_synthesis');
        }
        final instruction = find.descendant(
            of: panel, matching: find.byType(ActivityInstructionPresentation));
        expect(instruction, findsOneWidget);
        final semantic =
            tester.widget<ActivityInstructionPresentation>(instruction);
        final presentation = requireMasteryPresentation(id);
        expect(semantic.task, presentation.instruction);
        expect(semantic.question, presentation.question);
        if (presentation.question.isNotEmpty) {
          final question = tester.widget<LatexText>(
              find.byKey(const ValueKey('mastery-task-instruction')));
          expect(question.textStyle,
              ActivityInstructionPresentation.questionStyle);
          expect(
              question.math,
              normalizeActivityInstructions(question: presentation.question)
                  .question);
        }
        if (id == 'inverse_phase_synthesis') {
          final math = find.byKey(const ValueKey('mastery-math-evidence'));
          final intro = find.byKey(const ValueKey('mastery-evidence-intro'));
          final instruction =
              find.byKey(const ValueKey('mastery-task-instruction'));
          expect(tester.getRect(math).top - tester.getRect(intro).bottom,
              QubitQuestSpacing.micro);
          expect(tester.getRect(instruction).top - tester.getRect(math).bottom,
              QubitQuestSpacing.micro);
          final equation = tester.widget<LatexText>(
              find.descendant(of: math, matching: find.byType(LatexText)));
          expect(equation.displayMathHeight,
              MasteryEvidenceView.stackedMathDisplayHeight);
        }
        expect(tester.takeException(), isNull, reason: id);
      }
    });
  }

  testWidgets('all 36 Web Mastery tasks share the outer panel', (tester) async {
    expect(mastery2Catalogue.length, 36);
    Decoration? sharedDecoration;
    for (final challenge in mastery2Catalogue.orderedDefinitions) {
      await pumpTask(
          tester, challenge.semanticId, const Size(1440, 1000), 1, false);
      final heading = find.text('Task');
      expect(heading, findsOneWidget, reason: challenge.semanticId);
      final panel =
          find.ancestor(of: heading, matching: find.byType(DecoratedBox)).first;
      final decoration = tester.widget<DecoratedBox>(panel).decoration;
      sharedDecoration ??= decoration;
      expect(decoration, sharedDecoration, reason: challenge.semanticId);
      expect(
          find.descendant(
              of: panel, matching: find.byIcon(Icons.flag_outlined)),
          findsOneWidget);
      expect(find.text('TASK'), findsNothing);
      expect(tester.takeException(), isNull, reason: challenge.semanticId);
    }
  });

  const composers = {
    'bell_input_sign_preparation': 1,
    'ghz_phase_manipulation': 2,
    'inverse_phase_synthesis': 1,
  };
  for (final native in [false, true]) {
    for (final view in [
      (const Size(1440, 1000), 1.0),
      (const Size(768, 1024), 1.0),
      (const Size(390, 844), 1.0),
      (const Size(320, 700), 1.0),
      (const Size(390, 844), 1.3)
    ]) {
      for (final entry in composers.entries) {
        testWidgets(
            '${entry.key}: ${native ? 'native' : 'web'} ${view.$1} at ${view.$2}x',
            (tester) async {
          await pumpTask(tester, entry.key, view.$1, view.$2, native);
          final evidence = find.byType(MasteryEvidenceView);
          expect(evidence, findsOneWidget);
          final widget = tester.widget<MasteryEvidenceView>(evidence);
          expect(
              identical(widget.presentation, mastery2Presentations[entry.key]),
              isTrue);
          expect(widget.includeQuestion, native);
          expect(
              find.descendant(
                  of: evidence, matching: find.byType(QubitQuestStaticCircuit)),
              findsNothing,
              reason:
                  'No canonical solution circuit may be supplied as task evidence.');
          final math = find.descendant(
              of: evidence,
              matching: find.byKey(const ValueKey('mastery-math-evidence')));
          expect(math, findsNWidgets(entry.value));
          final latex = tester.widgetList<LatexText>(
              find.descendant(of: math, matching: find.byType(LatexText)));
          for (final item in latex) {
            expect(item.math, contains(r'\frac'));
            expect(item.math, isNot(contains('e^(')));
            expect(item.displayMathHeight,
                MasteryEvidenceView.stackedMathDisplayHeight);
          }
          final end = entry.key == 'ghz_phase_manipulation'
              ? math.last
              : find.byKey(const ValueKey('mastery-task-instruction'));
          await tester.ensureVisible(end);
          await tester.pumpAndSettle();
          final rect = tester.getRect(end);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(view.$1.width));
          expect(rect.bottom, lessThanOrEqualTo(view.$1.height));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final id in composers.keys) {
    testWidgets('$id task content at 320px and 2x scale', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: MasteryEvidenceView(
                    presentation: mastery2Presentations[id]!,
                    includeQuestion: true))),
      )));
      await tester.pumpAndSettle();
      final end = id == 'ghz_phase_manipulation'
          ? find.byKey(const ValueKey('mastery-math-evidence')).last
          : find.byKey(const ValueKey('mastery-task-instruction'));
      await tester.ensureVisible(end);
      await tester.pumpAndSettle();
      expect(tester.getRect(end).right, lessThanOrEqualTo(320));
      expect(tester.getRect(end).bottom, lessThanOrEqualTo(700));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'kickback circuit, state and question remain distinct; options use inline math',
      (tester) async {
    await pumpTask(
        tester, 'phase_kickback_reveal', const Size(1440, 1000), 1, false);
    final p = mastery2Presentations['phase_kickback_reveal']!;
    final c = p.evidence.whereType<MasteryCircuitEvidence>().single;
    expect(c.label, 'AFTER KICKBACK');
    expect(c.missingGateColumn, 1);
    expect(c.missingGateQubit, 0);
    expect(c.showInitialValues, isFalse);
    expect(c.operations.single.controlQubit, 0);
    expect(c.operations.single.targetQubit, 1);
    expect(find.byType(QubitQuestStaticCircuit), findsOneWidget);
    expect(find.text('STATE BEFORE REVEAL'), findsOneWidget);
    expect(p.evidence.whereType<MasteryMathEvidence>().single.expression,
        r'\[|-\rangle_{q0}|-\rangle_{q1}\]');
    final level = mastery2Catalogue
        .requireBySemanticId('phase_kickback_reveal')
        .levelDefinition as McqLevel;
    for (var i = 0; i < 4; i++) {
      final choice = find.byKey(ValueKey('web-lesson-option-$i'));
      final rendered = tester.widget<LatexText>(
          find.descendant(of: choice, matching: find.byType(LatexText)));
      expect(rendered.math, level.options[i]);
      expect(find.descendant(of: choice, matching: find.byType(TeX2SVG)),
          findsOneWidget);
    }
    expect(level.correctOptionIndex, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'GHZ support sets are mathematical evidence; broken circuit stays intact',
      (tester) async {
    await pumpTask(tester, 'ghz_broken_link', const Size(768, 1024), 1, false);
    final p = mastery2Presentations['ghz_broken_link']!;
    final supports = p.evidence.whereType<MasteryMathEvidence>().toList();
    expect(
        supports.map((b) => b.label), ['OBSERVED SUPPORT', 'REQUIRED SUPPORT']);
    expect(supports.map((b) => b.expression),
        [r'\[\{000,011\}\]', r'\[\{000,111\}\]']);
    final broken =
        p.evidence.whereType<MasteryCircuitEvidence>().single.operations.last;
    expect(broken.controlQubit, 2);
    expect(broken.targetQubit, 1);
    expect(
        find.byKey(const ValueKey('mastery-math-evidence')), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('amplitude choices preserve every vector and route through TeX',
      (tester) async {
    await pumpTask(
        tester, 'amplitude_flow_inference', const Size(768, 1024), 1, false);
    final level = mastery2Catalogue
        .requireBySemanticId('amplitude_flow_inference')
        .levelDefinition as McqLevel;
    expect(level.correctOptionIndex, 0);
    expect(level.options.map(normalizeMasteryNotation),
        ['[0,0,1,0]', '[1/2,1/2,-1/2,1/2]', '[1/2,1/2,1/2,1/2]', '[1,0,0,0]']);
    for (var i = 0; i < 4; i++) {
      final choice = find.byKey(ValueKey('web-lesson-option-$i'));
      expect(find.descendant(of: choice, matching: find.byType(TeX2SVG)),
          findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  for (final id in [
    'same_histogram_different_state',
    'algorithm_architecture_inspector',
    'swap_unitary_diagnosis',
    'phase_accumulation_prediction',
    'bell_measurement_evidence',
    'quarter_turn_relative_phase',
    'grover_round_order',
    'retry_or_reshape'
  ]) {
    testWidgets(
        '$id evidence remains usable at narrow width and increased text scale',
        (tester) async {
      await pumpTask(tester, id, const Size(320, 700), 1.5, false);
      expect(find.byType(MasteryEvidenceView), findsOneWidget);
      final question = mastery2Presentations[id]!.question;
      expect(
          find.byWidgetPredicate((w) => w is LatexText && w.math == question),
          findsOneWidget);
      if (id == 'same_histogram_different_state' ||
          id == 'algorithm_architecture_inspector' ||
          id == 'swap_unitary_diagnosis') {
        expect(
            find.descendant(
                of: find.byType(MasteryEvidenceView),
                matching: find.byType(TeX2SVG)),
            findsWidgets);
      }
      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('web-lesson-option-3')), 180,
          scrollable: find
              .byWidgetPredicate((w) =>
                  w is Scrollable && w.axisDirection == AxisDirection.down)
              .first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
