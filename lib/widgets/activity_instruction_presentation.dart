import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/latex_text.dart';

/// Removes presentation labels only at the start of an authored field.
/// A colon or standalone label line is required, so ordinary prose is retained.
String _withoutPresentationPrefix(String value) => value
    .trim()
    .replaceFirst(
      RegExp(r'^(?:TASK|QUESTION|Q)(?:[ \t]*:[ \t]*|[ \t]*\r?\n|$)',
          caseSensitive: false),
      '',
    )
    .trim();

/// Adapts existing authored fields; this is not a second activity data model.
({String task, String question}) normalizeActivityInstructions({
  String task = '',
  String? question,
}) {
  final normalizedQuestion = _withoutPresentationPrefix(question ?? '');
  var normalizedTask = _withoutPresentationPrefix(task);
  // Legacy tasks sometimes repeat their separately authored question first.
  // Require a complete prefix boundary, never a partial word match.
  if (normalizedQuestion.isNotEmpty &&
      normalizedTask.startsWith(normalizedQuestion) &&
      (normalizedTask.length == normalizedQuestion.length ||
          RegExp(r'\s').hasMatch(normalizedTask.substring(
              normalizedQuestion.length, normalizedQuestion.length + 1)))) {
    normalizedTask = _withoutPresentationPrefix(
        normalizedTask.substring(normalizedQuestion.length));
  }
  return (task: normalizedTask, question: normalizedQuestion);
}

/// Instructional content only. Callers retain cards, context and interactions.
/// Evidence is opaque here: circuits, math and pipelines keep their own views.
class ActivityInstructionPresentation extends StatelessWidget {
  const ActivityInstructionPresentation({
    super.key,
    this.task = '',
    this.question,
    this.evidence,
    this.compact = false,
    this.showLabels = false,
    this.showQuestion = true,
    this.taskKey,
    this.questionKey,
  });

  final String task;
  final String? question;
  final Widget? evidence;
  final bool compact;
  final bool showLabels;
  // A question may already occupy the existing context/card heading.
  final bool showQuestion;
  final Key? taskKey;
  final Key? questionKey;

  static const taskStyle = TextStyle(
    color: QubitQuestColors.textBody,
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );
  static const questionStyle = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 16.5,
    height: 1.38,
    fontWeight: FontWeight.w700,
  );

  Widget _text(String text, {required bool isQuestion, Key? key}) {
    // LatexText leaves ordinary prose in text spans. Only authored delimiters
    // opt into TeX; inline/display math and overflow use its existing policy.
    final content = LatexText(
      key: key,
      math: text,
      textStyle: isQuestion ? questionStyle : taskStyle,
      inlineMathHeight: 18,
      displayMathHeight: 24,
    );
    if (!showLabels) return content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(isQuestion ? 'QUESTION' : 'TASK',
            style: QubitQuestTypography.label),
        const SizedBox(height: 4),
        content,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalized =
        normalizeActivityInstructions(task: task, question: question);
    final questionView = showQuestion && normalized.question.isNotEmpty
        ? _text(normalized.question, isQuestion: true, key: questionKey)
        : null;
    final taskView = normalized.task.isNotEmpty
        ? _text(normalized.task, isQuestion: false, key: taskKey)
        : null;
    final children = <Widget>[
      if (evidence == null && questionView != null) questionView,
      if (taskView != null) taskView,
      if (evidence != null) evidence!,
      if (evidence != null && questionView != null) questionView,
    ];
    if (compact) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 7,
        runSpacing: 2,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Text('·', style: TextStyle(color: Colors.white38)),
            children[i],
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: QubitQuestSpacing.micro),
          children[i],
        ],
      ],
    );
  }
}
