import 'package:flutter/material.dart';
import 'package:quantumquiz/models/adaptive_learning.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

class AdaptiveLearningCard extends StatelessWidget {
  const AdaptiveLearningCard({
    super.key,
    required this.insight,
    required this.compact,
    this.onReviewNotebook,
  });

  final AdaptiveLearningInsight insight;
  final bool compact;
  final VoidCallback? onReviewNotebook;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: QubitQuestDialog.purple.withValues(alpha: 0.36),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: QubitQuestDialog.purple,
                  size: compact ? 17 : 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.keyInsight,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AdaptiveMetadataLine(
              label: 'Detected',
              value: insight.confusionLabel,
              compact: compact,
            ),
            const SizedBox(height: 4),
            _AdaptiveMetadataLine(
              label: 'Likely issue',
              value: insight.misconceptionLabel,
              compact: compact,
            ),
            if (insight.visualEmphasis != AdaptiveVisualEmphasis.none) ...[
              const SizedBox(height: 4),
              _AdaptiveMetadataLine(
                label: 'Visual focus',
                value: _visualEmphasisLabel(insight.visualEmphasis),
                compact: compact,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              insight.notebookReinforcement,
              style: TextStyle(
                color: const Color(0xFFD6E3F8),
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              insight.minimalHint,
              style: TextStyle(
                color: QubitQuestDialog.mutedText,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            if (onReviewNotebook != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onReviewNotebook,
                  style: TextButton.styleFrom(
                    foregroundColor: QubitQuestDialog.cyan,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.school_outlined, size: 16),
                  label: const Text(
                    'Review notebook entry',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _visualEmphasisLabel(AdaptiveVisualEmphasis emphasis) {
    return switch (emphasis) {
      AdaptiveVisualEmphasis.none => 'None',
      AdaptiveVisualEmphasis.controlRole => 'control qubit role',
      AdaptiveVisualEmphasis.targetRole => 'target qubit role',
      AdaptiveVisualEmphasis.phaseLocation => 'where phase is stored',
      AdaptiveVisualEmphasis.transformationDirection =>
        'transformation direction',
    };
  }
}

class _AdaptiveMetadataLine extends StatelessWidget {
  const _AdaptiveMetadataLine({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: QubitQuestDialog.purple),
          ),
          TextSpan(text: value),
        ],
      ),
      style: TextStyle(
        color: const Color(0xFFD6E3F8),
        fontSize: compact ? 10.5 : 11.5,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
    );
  }
}
