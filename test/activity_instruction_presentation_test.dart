import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:quantumquiz/widgets/activity_instruction_presentation.dart';
import 'package:quantumquiz/widgets/latex_text.dart';

import 'support/mastery_math_test_platform.dart';

void main() {
  useMasteryMathTestPlatform();

  test('normalizes labels and repeated questions without rewriting content',
      () {
    expect(
      normalizeActivityInstructions(
        question: 'QUESTION: Which state?',
        task: 'TASK\nWhich state? TASK: Prepare \\( |1\\rangle \\).',
      ),
      (question: 'Which state?', task: r'Prepare \( |1\rangle \).'),
    );
    expect(normalizeActivityInstructions(question: 'Q: Why?', task: 'Why?'),
        (question: 'Why?', task: ''));
    for (final text in [
      'Task scheduling matters.',
      'Question everything.',
      r'\(Q: x\)',
      'TASKS: two'
    ]) {
      expect(normalizeActivityInstructions(task: text).task, text);
    }
    expect(
        normalizeActivityInstructions(task: 'What next?', question: 'What')
            .task,
        'next?');
    expect(
        normalizeActivityInstructions(task: 'Whatever next?', question: 'What')
            .task,
        'Whatever next?');
    expect(
        normalizeActivityInstructions(task: 'Prepare', question: ' ').question,
        '');
  });

  for (final compact in [false, true]) {
    testWidgets('shared roles preserve prose and math, compact=$compact',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
        body: ActivityInstructionPresentation(
          compact: compact,
          question: 'Q: Which state?',
          task: r'TASK: Prepare \(|1\rangle\).',
        ),
      )));
      await tester.pumpAndSettle();
      final texts =
          tester.widgetList<LatexText>(find.byType(LatexText)).toList();
      expect(texts.map((w) => w.math),
          ['Which state?', r'Prepare \(|1\rangle\).']);
      expect(
          texts.first.textStyle, ActivityInstructionPresentation.questionStyle);
      expect(texts.last.textStyle, ActivityInstructionPresentation.taskStyle);
      expect(find.byType(TeX2SVG), findsOneWidget,
          reason:
              'Only the authored math span enters TeX, not ordinary prose.');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'evidence stays between instruction and question; empty question adds nothing',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: ActivityInstructionPresentation(
        task: 'Prepare the input.',
        evidence: SizedBox(key: ValueKey('specialised-evidence'), height: 40),
        question: 'What happens?',
        taskKey: ValueKey('task'),
        questionKey: ValueKey('question'),
      ),
    )));
    expect(
        tester.getRect(find.byKey(const ValueKey('task'))).bottom,
        lessThan(tester
            .getRect(find.byKey(const ValueKey('specialised-evidence')))
            .top));
    expect(
        tester
            .getRect(find.byKey(const ValueKey('specialised-evidence')))
            .bottom,
        lessThan(tester.getRect(find.byKey(const ValueKey('question'))).top));
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: ActivityInstructionPresentation(
          task: 'Prepare the input.', question: ''),
    )));
    expect(find.byType(LatexText), findsOneWidget);
  });

  for (final compact in [false, true]) {
    testWidgets('instruction roles fit 320px at 2x scale, compact=$compact',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
            body: SingleChildScrollView(
                child: Padding(
          padding: const EdgeInsets.all(20),
          child: ActivityInstructionPresentation(
            compact: compact,
            question: 'Which operation prepares the requested state?',
            task:
                r'Prepare \(|1\rangle\). Then inspect \[\frac{|00\rangle+|11\rangle}{\sqrt{2}}\]',
          ),
        ))),
      )));
      await tester.pumpAndSettle();
      for (final element in find.byType(LatexText).evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        expect(rect.left, greaterThanOrEqualTo(20));
        expect(rect.right, lessThanOrEqualTo(300));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
