import 'package:flutter/material.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

enum WebLearningTextRole {
  task,
  question,
  introduction,
  concept,
  hint,
  evidenceLabel,
  evidence,
  supporting,
}

abstract final class WebLearningTextStyles {
  static const task = TextStyle(
      color: QubitQuestColors.textBody,
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w400);
  static const question = TextStyle(
      color: QubitQuestColors.textPrimary,
      fontSize: 16.5,
      height: 1.38,
      fontWeight: FontWeight.w700);
}

extension WebLearningTextStyle on WebLearningTextRole {
  TextStyle get textStyle => switch (this) {
        WebLearningTextRole.task => WebLearningTextStyles.task,
        WebLearningTextRole.question => WebLearningTextStyles.question,
        WebLearningTextRole.evidenceLabel => QubitQuestTypography.label,
        WebLearningTextRole.supporting => QubitQuestTypography.supporting,
        _ => QubitQuestTypography.body,
      };
}

/// Authored Concept/Hint text. Delimiter parsing remains owned by LatexText.
class WebLearningText extends StatelessWidget {
  const WebLearningText(this.text, {super.key, this.style, this.role})
      : assert(
            style == null || role == null, 'Semantic roles own their style.');

  final String text;
  final TextStyle? style;
  final WebLearningTextRole? role;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = role?.textStyle ?? style;
    // This is only a routing hint, not another parser. Unmatched delimiters
    // remain ordinary text under LatexText's existing parsing rules.
    if (!text.contains(r'\(') &&
        !text.contains(r'\[') &&
        !text.contains(r'$')) {
      return Text(text, style: resolvedStyle);
    }
    final effectiveStyle =
        DefaultTextStyle.of(context).style.merge(resolvedStyle);
    final fontSize = effectiveStyle.fontSize ?? 14;
    return LatexText(
      math: text,
      mathFontSize: fontSize,
      minimumDisplayMathScale: 1,
      // LatexText's prose RichText does not apply MediaQuery scaling itself.
      // Its SVG renderer already scales math independently; do not scale the
      // supplied mathematical heights twice.
      textStyle: effectiveStyle.copyWith(
        fontSize: MediaQuery.textScalerOf(context).scale(fontSize),
      ),
      inlineMathHeight: fontSize,
    );
  }
}
