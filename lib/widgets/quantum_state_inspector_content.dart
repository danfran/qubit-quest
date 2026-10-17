import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';

/// Presents supplied live and authored vectors. Owns no circuit or filter state.
class QuantumStateInspectorContent extends StatelessWidget {
  const QuantumStateInspectorContent({
    super.key,
    required this.currentStateVector,
    required this.numQubits,
    required this.contentDriven,
    required this.nonZeroOnly,
    required this.onNonZeroOnlyChanged,
    this.targetStateVector,
    this.targetStateLabel,
    this.targetStateExpression,
    this.currentPanelKey,
    this.targetPanelKey,
  });

  final List<Complex> currentStateVector;
  final int numQubits;
  // Authored target only: an expression alone does not create a target panel.
  final List<Complex>? targetStateVector;
  final String? targetStateLabel;
  final String? targetStateExpression;
  final bool contentDriven;
  // Null retains StateVectorDisplay's existing adaptive default.
  final bool? nonZeroOnly;
  final ValueChanged<bool> onNonZeroOnlyChanged;
  final Key? currentPanelKey;
  final Key? targetPanelKey;

  @override
  Widget build(BuildContext context) {
    final current = StateVectorDisplay(
      key: currentPanelKey,
      stateVector: currentStateVector,
      numQubits: numQubits,
      summaryTitleOverride: 'Current State',
      tone: StateVectorDisplayTone.current,
      showHeader: false,
      showToggleInSummary: true,
      showSummarySubtitle: false,
      dense: true,
      contentDriven: contentDriven,
      lightweightTypography: true,
      nonZeroOnlyOverride: nonZeroOnly,
      onNonZeroOnlyChanged: onNonZeroOnlyChanged,
    );
    final targetVector = targetStateVector;
    if (targetVector == null || targetVector.isEmpty) return current;
    final target = StateVectorDisplay(
      key: targetPanelKey,
      stateVector: targetVector,
      numQubits: numQubits,
      summaryTitleOverride: 'Target State',
      stateExpressionLabel: targetStateLabel,
      stateExpression: targetStateExpression,
      tone: StateVectorDisplayTone.target,
      showHeader: false,
      showToggleInSummary: true,
      showSummarySubtitle: false,
      showVisibilityControl: false,
      dense: true,
      contentDriven: contentDriven,
      lightweightTypography: true,
      nonZeroOnlyOverride: nonZeroOnly,
    );
    return Column(
      mainAxisSize: contentDriven ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (contentDriven) current else Expanded(child: current),
        const SizedBox(height: 10),
        if (contentDriven) target else Expanded(child: target),
      ],
    );
  }
}
