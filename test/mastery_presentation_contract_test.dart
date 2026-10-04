import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/widgets/activity_instruction_presentation.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/mastery_evidence_view.dart';

import 'support/mastery_math_test_platform.dart';

const migratedIds = [
  'phase_state_uncomputation',
  'cnot_uncomputation',
  'clean_workspace_uncomputation',
  'phased_entanglement_uncomputation',
  'conditional_phase_decomposition',
];

void main() {
  useMasteryMathTestPlatform();

  test('Mastery catalogue and typed presentations have identical semantic IDs',
      () {
    final catalogueIds = mastery2Catalogue.orderedDefinitions
        .map((challenge) => challenge.semanticId)
        .toSet();
    final presentationIds = mastery2Presentations.keys.toSet();
    final missing = catalogueIds.difference(presentationIds).toList()..sort();
    final extra = presentationIds.difference(catalogueIds).toList()..sort();
    expect(missing.isEmpty && extra.isEmpty, isTrue,
        reason:
            'Missing typed presentations: $missing; orphan presentations: $extra');
  });

  test('missing typed Mastery data fails explicitly instead of falling back',
      () {
    expect(
        () => requireMasteryPresentation('missing-example'),
        throwsA(isA<StateError>().having((error) => error.message, 'diagnostic',
            contains('missing-example'))));
  });

  test('five migrated instructions exactly preserve legacy content and roles',
      () {
    for (final id in migratedIds) {
      final challenge = mastery2Catalogue.requireBySemanticId(id);
      final level = challenge.levelDefinition;
      final presentation = requireMasteryPresentation(id);
      expect(presentation.instruction, level.taskDescription, reason: id);
      expect(presentation.question, isEmpty, reason: id);
      expect(level.mysteryTitle, isNull, reason: id);
      expect(level.mysteryText, isNull, reason: id);
      expect(presentation.intro, isNull,
          reason: 'Existing concept intro stays in its brief: $id');
      expect(presentation.helperText, isNull, reason: id);
      expect(presentation.evidence, isEmpty,
          reason: 'No invented evidence: $id');
      expect(level, isA<ComposerLevel>());
      expect(
          challenge.interactionType,
          id == 'conditional_phase_decomposition'
              ? MasteryInteractionType.construction
              : MasteryInteractionType.uncomputation);
      expect(
          normalizeActivityInstructions(
              task: presentation.instruction, question: presentation.question),
          normalizeActivityInstructions(
              task: level.taskDescription, question: level.mysteryTitle));
    }
  });

  testWidgets(
      'typed simple and concept-intro tasks keep shared rendering and Check Circuit',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);
    for (final id in [
      'phase_state_uncomputation',
      'conditional_phase_decomposition'
    ]) {
      final challenge = mastery2Catalogue.requireBySemanticId(id);
      final level = challenge.levelDefinition;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: WebLessonWorkspace(
        key: ValueKey(id),
        levelId: challenge.displayOrder,
        level: level,
        masteryChallenge: challenge,
        alreadyCompleted: false,
        onCompleted: () async {},
        onNextLesson: () {},
        onBackToChapter: () {},
        onOpenNotebook: () {},
      ))));
      await tester.pumpAndSettle();
      final instruction = find.byType(ActivityInstructionPresentation);
      expect(instruction, findsOneWidget);
      final widget =
          tester.widget<ActivityInstructionPresentation>(instruction);
      expect(widget.task, requireMasteryPresentation(id).instruction);
      expect(widget.question, isEmpty);
      expect(widget.evidence, isNull);
      final text = tester.widget<LatexText>(
          find.descendant(of: instruction, matching: find.byType(LatexText)));
      expect(text.math, level.taskDescription);
      expect(text.textStyle, ActivityInstructionPresentation.taskStyle);
      expect(
          find.byKey(const ValueKey('mastery-task-instruction')), findsNothing);
      expect(find.text('Task'), findsOneWidget);
      if (level.conceptIntro != null) {
        expect(find.text(level.conceptIntro!), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('web-lesson-check')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('standalone evidence consumer does not lose typed instructions',
      (tester) async {
    final presentation = requireMasteryPresentation('cnot_uncomputation');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MasteryEvidenceView(
                presentation: presentation, includeQuestion: true))));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ActivityInstructionPresentation>(
                find.byType(ActivityInstructionPresentation))
            .task,
        presentation.instruction);
    expect(find.byType(LatexText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
