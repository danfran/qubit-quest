import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:quantumquiz/widgets/web_learning_text.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'support/mastery_math_test_platform.dart';

void main() {
  useMasteryMathTestPlatform();

  testWidgets('ordinary authored prose stays Text, unchanged and scalable',
      (tester) async {
    const source = '  Compare |0⟩ and |1⟩.\nNo automatic ket conversion.  ';
    const style = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Scaffold(
          body: SizedBox(
              width: 260, child: WebLearningText(source, style: style))),
    )));
    expect(find.text(source), findsOneWidget);
    expect(find.byType(LatexText), findsNothing);
    expect(tester.widget<Text>(find.text(source)).style, style);
    expect(tester.getSize(find.byType(WebLearningText)).width, 260);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored inline and display delimiters use LatexText unchanged',
      (tester) async {
    const source = r'  Inline \(x\) and $y$. Display \[x+y\] and $$z$$.  ';
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Scaffold(
          body: SizedBox(
              width: 260,
              child: WebLearningText(source,
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w500)))),
    )));
    await tester.pumpAndSettle();
    final latex = tester.widget<LatexText>(find.byType(LatexText));
    expect(latex.math, source);
    expect(latex.textStyle!.fontSize, 30);
    expect(latex.textStyle!.fontWeight, FontWeight.w500);
    expect(latex.inlineMathHeight, 15);
    final math =
        tester.widgetList<TeX2SVG>(find.byType(TeX2SVG)).map((w) => w.math);
    expect(
        math,
        containsAll([
          r'\textstyle{x}',
          r'\textstyle{y}',
          r'\displaystyle{x+y}',
          r'\displaystyle{z}',
        ]));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Journey and Mastery Concept and revealed hints share the contract',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.reset);
    final mastery =
        mastery2Catalogue.bySemanticId('phase_state_uncomputation')!;
    for (final isMastery in [false, true]) {
      final level = isMastery
          ? mastery.levelDefinition
          : ComposerLevel.fromBinaryString(
              taskDescription: 'Prepare the state.',
              conceptIntro: r'Inspect \(x\).',
              hints: const [r'Compare \[x=1\].', 'Then check the circuit.'],
              initialQubitsStateString: '0',
              availableGates: const [],
              solutionFinalVector: const [],
            );
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: WebLessonWorkspace(
        key: ValueKey(isMastery),
        levelId: isMastery ? mastery.displayOrder : 1,
        level: level,
        masteryChallenge: isMastery ? mastery : null,
        journeyActivity: !isMastery,
        alreadyCompleted: false,
        onCompleted: () async {},
        onNextLesson: () {},
        onBackToChapter: () {},
        onOpenNotebook: () {},
      ))));
      await tester.pumpAndSettle();
      Iterable<String> authored() => tester
          .widgetList<WebLearningText>(find.byType(WebLearningText))
          .map((w) => w.text);
      expect(authored(), contains(level.conceptIntro));
      final hint = find.byKey(const ValueKey('web-lesson-hint'));
      expect(authored(), isNot(contains('Hint 1: ${level.hints!.first}')));
      await tester.ensureVisible(hint);
      await tester.pumpAndSettle();
      await tester.tap(hint);
      await tester.pumpAndSettle();
      expect(authored(), contains('Hint 1: ${level.hints!.first}'));
      if (level.hints!.length > 1) {
        expect(authored(), isNot(contains('Hint 2: ${level.hints![1]}')));
      }
    }
  });

  testWidgets('non-Composer Concept and expandable hints keep authored math',
      (tester) async {
    const concept = r'Consider \(x\).';
    const hint = r'Inspect \[x=1\].';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WebLessonWorkspace(
      levelId: 999,
      level: const McqLevel(
          taskDescription: 'Choose.',
          conceptIntro: concept,
          hints: [hint],
          options: ['One', 'Two'],
          correctOptionIndex: 0),
      alreadyCompleted: false,
      onCompleted: () async {},
      onNextLesson: () {},
      onBackToChapter: () {},
      onOpenNotebook: () {},
    ))));
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<WebLearningText>(find.byType(WebLearningText))
            .map((w) => w.text),
        contains(concept));
    expect(
        find.byWidgetPredicate((w) => w is WebLearningText && w.text == hint),
        findsNothing);
    await tester.tap(find.text('Reveal authored hints'));
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate((w) => w is WebLearningText && w.text == hint),
        findsOneWidget);
    expect(
        tester.widgetList<LatexText>(find.byType(LatexText)).map((w) => w.math),
        containsAll([concept, hint]));
    expect(tester.takeException(), isNull);
  });
}
