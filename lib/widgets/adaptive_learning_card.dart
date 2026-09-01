import 'package:flutter/material.dart';
import 'package:quantumquiz/models/adaptive_learning.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

/// A specialised teaching surface shown only when adaptive-learning logic
/// decides that a concept is worth revisiting.
class AdaptiveLearningCard extends StatelessWidget {
  const AdaptiveLearningCard({
    super.key,
    required this.insight,
    required this.compact,
    this.onReviewNotebook,
    this.onDismiss,
  });

  static const semanticLabel = 'Adaptive reinforcement';
  static const semanticIcon = Icons.school_outlined;

  final AdaptiveLearningInsight insight;
  final bool compact;
  final VoidCallback? onReviewNotebook;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final padding =
        compact ? QubitQuestSpacing.regular : QubitQuestSpacing.component;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        key: const ValueKey('adaptive-reinforcement-surface'),
        decoration: const BoxDecoration(
          color: QubitQuestColors.surfaceRaised,
          borderRadius: QubitQuestRadii.callout,
          border: Border.fromBorderSide(QubitQuestBorders.standard),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ExcludeSemantics(
                    child: Icon(
                      semanticIcon,
                      key: ValueKey('adaptive-reinforcement-icon'),
                      color: QubitQuestColors.accentInteractive,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: QubitQuestSpacing.compact),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          semanticLabel.toUpperCase(),
                          key: const ValueKey('adaptive-reinforcement-label'),
                          style: QubitQuestTypography.label.copyWith(
                            color: QubitQuestColors.accentInteractive,
                          ),
                        ),
                        const SizedBox(height: QubitQuestSpacing.micro),
                        Text(
                          insight.keyInsight,
                          key: const ValueKey('adaptive-reinforcement-title'),
                          style: QubitQuestTypography.heading,
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null) ...[
                    const SizedBox(width: QubitQuestSpacing.compact),
                    IconButton(
                      onPressed: onDismiss,
                      tooltip: 'Dismiss adaptive reinforcement',
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: QubitQuestColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: QubitQuestSpacing.regular),
              Text(
                insight.notebookReinforcement,
                key: const ValueKey('adaptive-reinforcement-concept'),
                style: QubitQuestTypography.body,
              ),
              const SizedBox(height: QubitQuestSpacing.compact),
              Text(
                insight.minimalHint,
                key: const ValueKey('adaptive-reinforcement-hint'),
                style: QubitQuestTypography.supporting,
              ),
              const SizedBox(height: QubitQuestSpacing.regular),
              _AdaptiveMetadataLine(
                label: 'Detected',
                value: insight.confusionLabel,
              ),
              const SizedBox(height: QubitQuestSpacing.micro),
              _AdaptiveMetadataLine(
                label: 'Likely issue',
                value: insight.misconceptionLabel,
              ),
              if (insight.visualEmphasis != AdaptiveVisualEmphasis.none) ...[
                const SizedBox(height: QubitQuestSpacing.micro),
                _AdaptiveMetadataLine(
                  label: 'Visual focus',
                  value: _visualEmphasisLabel(insight.visualEmphasis),
                ),
              ],
              if (onReviewNotebook != null) ...[
                const SizedBox(height: QubitQuestSpacing.regular),
                TextButton.icon(
                  onPressed: onReviewNotebook,
                  style: TextButton.styleFrom(
                    foregroundColor: QubitQuestColors.accentInteractive,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: QubitQuestSpacing.compact,
                    ),
                    textStyle: QubitQuestTypography.action,
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text('Review notebook entry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _visualEmphasisLabel(AdaptiveVisualEmphasis emphasis) {
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
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: QubitQuestColors.accentInteractive,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
      style: QubitQuestTypography.supporting,
    );
  }
}
