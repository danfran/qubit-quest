import 'package:flutter/material.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/activity_instruction_presentation.dart';
import 'package:quantumquiz/widgets/mastery_evidence_view.dart';
import 'package:quantumquiz/widgets/web_learning_text.dart';

/// Complete educational context, independent of interaction type and width.
/// Page owners choose placement/cards, never reconstruct its semantic fields.
class WebActivityInstructionContent extends StatelessWidget {
  const WebActivityInstructionContent({
    super.key,
    required this.level,
    this.presentation,
    this.taskKey,
    this.questionKey,
  });
  final QQLevel level;
  final MasteryChallengePresentation? presentation;
  final Key? taskKey;
  final Key? questionKey;

  @override
  Widget build(BuildContext context) {
    final p = presentation;
    final hasEvidence = p != null &&
        (p.evidence.isNotEmpty || p.intro != null || p.helperText != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if ((level.conceptIntro ?? '').trim().isNotEmpty) ...[
          const Text('Concept', style: QubitQuestTypography.label),
          const SizedBox(height: QubitQuestSpacing.micro),
          WebLearningText(level.conceptIntro!,
              role: WebLearningTextRole.concept),
          const SizedBox(height: QubitQuestSpacing.compact),
        ],
        ActivityInstructionPresentation(
          webLearning: true,
          task: p?.instruction ?? level.taskDescription,
          question: p?.question ?? level.mysteryTitle,
          taskContinuation: p?.instructionAfterEvidence ?? '',
          taskKey: taskKey,
          questionKey: questionKey,
          evidence: hasEvidence
              ? MasteryEvidenceView(
                  presentation: p,
                  includeInstruction: false,
                  webLearning: true,
                )
              : null,
        ),
        if ((level.mysteryText ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: QubitQuestSpacing.compact),
          WebLearningText(level.mysteryText!,
              role: WebLearningTextRole.supporting),
        ],
      ],
    );
  }
}
