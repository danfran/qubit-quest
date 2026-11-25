import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/gate_educational_sections.dart';
import 'package:quantumquiz/widgets/gate_educational_visual.dart';
import 'package:quantumquiz/widgets/gate_inspector_theme.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

@immutable
class GateInspectorContext {
  const GateInspectorContext({required this.title, required this.description});

  final String title;
  final String description;
}

class GateInspectorDialog extends StatelessWidget {
  const GateInspectorDialog({
    super.key,
    required this.footprint,
    required this.info,
    this.onOpenNotebook,
    this.onOpenRelatedConcept,
    this.inspectionContext,
  });

  factory GateInspectorDialog.forGate({
    Key? key,
    required Gate gate,
    required GateEducationalInfo? info,
    VoidCallback? onOpenNotebook,
    ValueChanged<String>? onOpenRelatedConcept,
    GateInspectorContext? inspectionContext,
  }) {
    const id = GateId(-1);
    const location = CircuitLocation(qubit: 0, column: 0);
    final placed = PlacedQuantumGate(id: id, gate: gate);
    return GateInspectorDialog(
      key: key,
      footprint: LogicalGateFootprint(
        id: id,
        gate: gate,
        fragments: [
          LogicalGateFragment(location: location, placedGate: placed),
        ],
        anchor: location,
        controlQubit: null,
        secondControlQubit: null,
        targetQubit: null,
        isDeletable: true,
      ),
      info: info,
      onOpenNotebook: onOpenNotebook,
      onOpenRelatedConcept: onOpenRelatedConcept,
      inspectionContext: inspectionContext,
    );
  }

  final LogicalGateFootprint footprint;
  final GateEducationalInfo? info;
  final VoidCallback? onOpenNotebook;
  final ValueChanged<String>? onOpenRelatedConcept;
  final GateInspectorContext? inspectionContext;

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
          if (inspectionContext != null)
            _InspectorContextCard(context: inspectionContext!),
          _InspectorHero(
            info: educational,
            footprint: footprint,
            showCircuitLocation: inspectionContext == null,
          ),
          GateEducationalSummary(
            key: const ValueKey('gate-inspector-summary-card'),
            info: educational,
          ),
          if (educational.transformations.isNotEmpty)
            GateEducationalMathList(
              title: 'State action',
              values: educational.transformations,
              level: GateEducationalMathLevel.secondary,
              keyPrefix: 'gate-inspector-state-math',
            ),
          if (educational.matrix.isNotEmpty)
            _MatrixSection(matrix: educational.matrix),
          if (educational.properties.isNotEmpty)
            GateEducationalListSection(
                title: 'Properties', values: educational.properties),
          if (educational.identities.isNotEmpty)
            GateEducationalMathList(
              title: 'Important identities',
              values: educational.identities,
              level: GateEducationalMathLevel.tertiary,
              keyPrefix: 'gate-inspector-identity-math',
            ),
          if (educational.relatedConcepts.isNotEmpty)
            GateRelatedConceptsSection(
              concepts: educational.relatedConcepts,
              onOpen: onOpenRelatedConcept,
            ),
          if (isControlledEducationalVisual(educational.visual.kind))
            const GateEducationalTextSection(
              title: 'Why one Bloch sphere is not enough',
              body: controlledGateBlochNote,
            ),
        ],
      ),
    );
  }
}

class _InspectorContextCard extends StatelessWidget {
  const _InspectorContextCard({required this.context});

  final GateInspectorContext context;

  @override
  Widget build(BuildContext buildContext) => Container(
        key: const ValueKey('gate-inspector-context'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: QubitQuestDialog.innerColor,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: QubitQuestDialog.purple.withValues(alpha: .38)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.title, style: GateInspectorTheme.sectionTitle),
            const SizedBox(height: 4),
            Text(context.description, style: GateInspectorTheme.caption),
          ],
        ),
      );
}

class _InspectorHero extends StatelessWidget {
  const _InspectorHero({
    required this.info,
    required this.footprint,
    required this.showCircuitLocation,
  });
  final GateEducationalInfo info;
  final LogicalGateFootprint footprint;
  final bool showCircuitLocation;

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
        if (details.isNotEmpty || showCircuitLocation) ...[
          const SizedBox(height: 8),
          Text(
            details.isEmpty
                ? 'Logical gate at column ${footprint.column + 1}'
                : details.join('\n'),
            key: const ValueKey('gate-inspector-config'),
            textAlign: TextAlign.center,
            style: GateInspectorTheme.caption,
          ),
        ],
      ]),
    );
  }
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
              child: GateEducationalMatrix(
                latexKey: const ValueKey('gate-inspector-matrix-latex'),
                matrix: matrix,
              ),
            ),
          ],
        ),
      );
}
