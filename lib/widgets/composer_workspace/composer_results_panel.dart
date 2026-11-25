import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';

/// Independent results column: the existing State / Bloch / Measure views
/// ([QuantumInspectorViews]) in their own scrolling panel. Results never
/// change the circuit region's size or position.
///
/// The selected tab lives in [selection], owned by the workspace, so layout
/// changes and session switches keep it. M4 adds exact-vs-observed views by
/// extending the State/Measure builders; this panel needs no new structure.
class ComposerResultsPanel extends StatelessWidget {
  const ComposerResultsPanel({
    super.key,
    required this.selection,
    required this.stateView,
    this.measureView,
    required this.currentStateVector,
    required this.numQubits,
    required this.allowBloch,
    this.blochCaption,
    this.blochNote,
    this.blochUnavailableMessage,
    this.blochHeader,
    this.targetStateExpression,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.scrollController,
  });

  final QuantumInspectorSelection selection;
  final Widget stateView;
  /// Null where the activity runs no sampled experiments (exercises).
  final Widget? measureView;
  final List<Complex> currentStateVector;
  final int numQubits;
  final bool allowBloch;
  final String? blochCaption;
  final String? blochNote;
  final String? blochUnavailableMessage;
  final Widget? blochHeader;
  final String? targetStateExpression;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Column(
        key: const ValueKey('composer-results-rail'),
        children: [
          const SizedBox(height: 6),
          IconButton(
            key: const ValueKey('composer-results-expand'),
            tooltip: 'Show results',
            onPressed: onToggleCollapsed,
            icon:
                const Icon(Icons.keyboard_double_arrow_left_rounded, size: 18),
            color: QubitQuestColors.textMuted,
          ),
          const SizedBox(height: 8),
          const RotatedBox(
            quarterTurns: 1,
            child: Text('RESULTS', style: workspacePanelTitle),
          ),
        ],
      );
    }
    return Column(
      key: const ValueKey('web-composer-inspector-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 2),
          child: Row(
            children: [
              const Expanded(
                child: Text('RESULTS', style: workspacePanelTitle),
              ),
              if (onToggleCollapsed != null)
                IconButton(
                  key: const ValueKey('composer-results-collapse'),
                  tooltip: 'Hide results',
                  onPressed: onToggleCollapsed,
                  icon: const Icon(Icons.keyboard_double_arrow_right_rounded,
                      size: 18),
                  color: QubitQuestColors.textMuted,
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Scrollbar(
              controller: scrollController,
              child: SingleChildScrollView(
                key: const ValueKey('web-composer-inspector-scroll'),
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                child: KeyedSubtree(
                  key: const ValueKey('web-composer-state-inspection'),
                  child: QuantumInspectorViews(
                    key: const ValueKey('web-composer-inspector-views'),
                    selection: selection,
                    stateView: stateView,
                    measureView: measureView,
                    currentStateVector: currentStateVector,
                    numQubits: numQubits,
                    allowBloch: allowBloch,
                    blochCaption: blochCaption,
                    blochNote: blochNote,
                    blochUnavailableMessage: blochUnavailableMessage,
                    blochHeader: blochHeader,
                    keepBlochTabSelectable: true,
                    contentDriven: true,
                    compactTabs: constraints.maxWidth < 330,
                    fitTabsToWidth: true,
                    targetStateExpression: targetStateExpression,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
