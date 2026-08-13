import 'package:flutter/material.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/widgets/gate_educational_visual.dart';
import 'package:quantumquiz/widgets/gate_inspector_theme.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/native_math_text.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

class GateInspectorDialog extends StatelessWidget {
  const GateInspectorDialog({
    super.key,
    required this.footprint,
    required this.info,
    this.onOpenNotebook,
    this.onOpenRelatedConcept,
  });

  final LogicalGateFootprint footprint;
  final GateEducationalInfo? info;
  final VoidCallback? onOpenNotebook;
  final ValueChanged<String>? onOpenRelatedConcept;

  @override
  Widget build(BuildContext context) {
    final educational = info;
    if (educational == null) {
      return QubitQuestDialog(
        title: 'Gate Inspector',
        titleStyle: GateInspectorTheme.title,
        actions: [
          QubitQuestDialogButton.primary(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: const Text(
          'Educational information is not available for this gate yet.',
          key: ValueKey('gate-inspector-unsupported'),
          style: GateInspectorTheme.body,
        ),
      );
    }

    return QubitQuestDialog(
      title: educational.name,
      titleStyle: GateInspectorTheme.title,
      maxWidth: 600,
      actions: [
        if (onOpenNotebook != null)
          QubitQuestDialogButton.secondary(
            label: 'Open Notebook',
            onPressed: onOpenNotebook,
          ),
        QubitQuestDialogButton.primary(
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        key: const ValueKey('gate-inspector-content'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InspectorHero(info: educational, footprint: footprint),
          _InspectorCard(
            key: const ValueKey('gate-inspector-summary-card'),
            children: [
              if (educational.intuition.isNotEmpty)
                _Section(title: 'Intuition', body: educational.intuition),
              if (educational.physicalChange.isNotEmpty)
                _Section(
                    title: 'What changes', body: educational.physicalChange),
              if (educational.commonUse.isNotEmpty)
                _Section(title: 'Common use', body: educational.commonUse),
            ],
          ),
          if (educational.transformations.isNotEmpty)
            _MathListSection(
              title: 'State action',
              values: educational.transformations,
              level: _InspectorMathLevel.secondary,
              keyPrefix: 'gate-inspector-state-math',
            ),
          if (educational.matrix.isNotEmpty)
            _MatrixSection(matrix: educational.matrix),
          if (educational.properties.isNotEmpty)
            _ListSection(title: 'Properties', values: educational.properties),
          if (educational.identities.isNotEmpty)
            _MathListSection(
              title: 'Important identities',
              values: educational.identities,
              level: _InspectorMathLevel.tertiary,
              keyPrefix: 'gate-inspector-identity-math',
            ),
          if (educational.relatedConcepts.isNotEmpty)
            _RelatedConceptsSection(
              concepts: educational.relatedConcepts,
              onOpen: onOpenRelatedConcept,
            ),
          if (_isControlled(educational.visual.kind))
            const _Section(
              title: 'Why one Bloch sphere is not enough',
              body:
                  'A Bloch sphere describes one isolated qubit. Controlled gates act on joint basis states and can create entanglement, so their full behavior belongs to the multi-qubit state space.',
            ),
        ],
      ),
    );
  }

  bool _isControlled(GateEducationalVisualKind kind) => switch (kind) {
        GateEducationalVisualKind.controlledX ||
        GateEducationalVisualKind.controlledPhase ||
        GateEducationalVisualKind.multiControlledX =>
          true,
        _ => false,
      };
}

class _InspectorHero extends StatelessWidget {
  const _InspectorHero({required this.info, required this.footprint});
  final GateEducationalInfo info;
  final LogicalGateFootprint footprint;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (footprint.gate.requiresAngle && info.axis != null)
        'Axis: ${info.axis}',
      if (footprint.gate.requiresAngle)
        'Configured angle: ${footprint.gate.label.replaceAll('\n', ' ')}',
      if (footprint.controlQubit != null) 'Control: Q${footprint.controlQubit}',
      if (footprint.secondControlQubit != null)
        'Second control: Q${footprint.secondControlQubit}',
      if (footprint.targetQubit != null) 'Target: Q${footprint.targetQubit}',
    ];
    return Container(
      key: const ValueKey('gate-inspector-visual-slot'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QubitQuestDialog.cyan.withValues(alpha: .32)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GateEducationalVisualView(
          visual: info.visual,
          footprint: footprint,
        ),
        const SizedBox(height: 8),
        Text(
          details.isEmpty
              ? 'Logical gate at column ${footprint.column + 1}'
              : details.join('\n'),
          key: const ValueKey('gate-inspector-config'),
          textAlign: TextAlign.center,
          style: GateInspectorTheme.caption,
        ),
      ]),
    );
  }
}

class _InspectorCard extends StatelessWidget {
  const _InspectorCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
        decoration: BoxDecoration(
          color: QubitQuestDialog.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: QubitQuestDialog.borderSoftColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GateInspectorTheme.sectionTitle),
          const SizedBox(height: 5),
          LatexText(
            math: body,
            textStyle: GateInspectorTheme.body,
            inlineMathColor: Colors.white,
            inlineMathHeight: GateInspectorTheme.mathSecondaryInlineHeight,
            displayMathHeight: GateInspectorTheme.mathSecondaryDisplayHeight,
          ),
        ]),
      );
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.values});
  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) => _Section(
        title: title,
        body: values.map((value) => '• $value').join('\n'),
      );
}

enum _InspectorMathLevel { secondary, tertiary }

class _MathListSection extends StatelessWidget {
  const _MathListSection({
    required this.title,
    required this.values,
    required this.level,
    required this.keyPrefix,
  });
  final String title;
  final List<String> values;
  final _InspectorMathLevel level;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => _InspectorCard(children: [
        Text(title, style: GateInspectorTheme.sectionTitle),
        const SizedBox(height: 8),
        for (final entry in values.asMap().entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _InspectorMathExpression(
              key: ValueKey('$keyPrefix-${entry.key}'),
              math: entry.value,
              level: level,
            ),
          ),
      ]);
}

class _InspectorMathExpression extends StatelessWidget {
  const _InspectorMathExpression({
    super.key,
    required this.math,
    required this.level,
  });

  final String math;
  final _InspectorMathLevel level;

  @override
  Widget build(BuildContext context) {
    final style = level == _InspectorMathLevel.secondary
        ? GateInspectorTheme.mathSecondary
        : GateInspectorTheme.mathTertiary;
    if (NativeMathText.supports(math)) {
      return NativeMathText(math: math, style: style);
    }
    return LatexText(
      math: math,
      textStyle: style,
      inlineMathColor: Colors.white,
      inlineMathHeight: level == _InspectorMathLevel.secondary
          ? GateInspectorTheme.mathSecondaryInlineHeight
          : GateInspectorTheme.mathTertiaryInlineHeight,
      displayMathHeight: level == _InspectorMathLevel.secondary
          ? GateInspectorTheme.mathSecondaryDisplayHeight
          : GateInspectorTheme.mathTertiaryDisplayHeight,
    );
  }
}

class _RelatedConceptsSection extends StatelessWidget {
  const _RelatedConceptsSection({required this.concepts, this.onOpen});
  final List<GateRelatedConcept> concepts;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) => _InspectorCard(children: [
        const Text('Related concepts', style: GateInspectorTheme.sectionTitle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final concept in concepts)
              ActionChip(
                key: ValueKey('gate-concept-${concept.label}'),
                avatar: concept.notebookDiscoveryTitle == null
                    ? null
                    : const Icon(Icons.menu_book_outlined, size: 15),
                label: Text(concept.label),
                tooltip: concept.notebookDiscoveryTitle == null
                    ? concept.label
                    : 'Open ${concept.label} in Notebook',
                onPressed:
                    concept.notebookDiscoveryTitle == null || onOpen == null
                        ? null
                        : () => onOpen!(concept.notebookDiscoveryTitle!),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ]);
}

class _MatrixSection extends StatelessWidget {
  const _MatrixSection({required this.matrix});
  final String matrix;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: QubitQuestDialog.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QubitQuestDialog.borderSoftColor),
        ),
        child: ExpansionTile(
          key: const ValueKey('gate-inspector-matrix'),
          collapsedIconColor: QubitQuestDialog.cyan,
          iconColor: QubitQuestDialog.cyan,
          title: const Text('Mathematical definition',
              style: GateInspectorTheme.sectionTitle),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: LatexText(
                key: const ValueKey('gate-inspector-matrix-latex'),
                math: matrix,
                textStyle: GateInspectorTheme.mathPrimary,
                inlineMathHeight: GateInspectorTheme.mathPrimaryInlineHeight,
                displayMathHeight: GateInspectorTheme.mathPrimaryDisplayHeight,
              ),
            ),
          ],
        ),
      );
}
