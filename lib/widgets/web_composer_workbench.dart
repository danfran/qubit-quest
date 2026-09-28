import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/widgets/quantum_workspace_layout.dart';

typedef WebComposerWorkbenchRegionBuilder = Widget Function(bool wide);
typedef WebComposerWorkbenchStateBuilder = Widget Function(
  bool contentDriven,
);

class WebComposerWorkbench extends StatelessWidget {
  const WebComposerWorkbench({
    super.key,
    required this.circuitBuilder,
    required this.gatesBuilder,
    required this.stateViewBuilder,
    required this.currentStateVector,
    required this.numQubits,
    required this.wideMainHeight,
    this.actionsBuilder,
    this.targetStateExpression,
    this.circuitHeaderTrailing,
    this.wideLayoutBreakpoint = QuantumWorkspaceLayout.wideBreakpoint,
    this.labelStyle = const TextStyle(
      color: QubitQuestColors.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: .75,
    ),
    this.inspectorKey,
    this.inspectorViewsKey,
    this.inspectorContentSpacing = 10,
  });

  final WebComposerWorkbenchRegionBuilder circuitBuilder;
  final WebComposerWorkbenchRegionBuilder gatesBuilder;
  final WebComposerWorkbenchStateBuilder stateViewBuilder;
  final WebComposerWorkbenchRegionBuilder? actionsBuilder;
  final List<Complex> currentStateVector;
  final int numQubits;
  final String? targetStateExpression;
  final Widget? circuitHeaderTrailing;
  final double wideLayoutBreakpoint;
  final double wideMainHeight;
  final TextStyle labelStyle;
  final Key? inspectorKey;
  final Key? inspectorViewsKey;
  final double inspectorContentSpacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= wideLayoutBreakpoint;
          final accessibilityConstrained =
              wide && MediaQuery.textScalerOf(context).scale(14) > 14;
          final contentDriven = !wide || accessibilityConstrained;
          final inspector = _inspector(
            contentDriven: contentDriven,
          );
          return QuantumWorkspaceLayout(
            circuit: _circuit(wide),
            inspection: accessibilityConstrained
                ? SingleChildScrollView(child: inspector)
                : inspector,
            toolbar: _gates(wide),
            contextualActions: actionsBuilder?.call(wide),
            wideLayoutBreakpoint: wideLayoutBreakpoint,
            wideMainHeight: wideMainHeight,
          );
        },
      );

  Widget _circuit(bool wide) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _RegionLabel(
                  icon: Icons.account_tree_outlined,
                  label: 'CIRCUIT WORKSPACE',
                  style: labelStyle,
                ),
              ),
              if (circuitHeaderTrailing case final trailing?) trailing,
            ],
          ),
          const SizedBox(height: 12),
          if (wide)
            Expanded(child: circuitBuilder(true))
          else
            circuitBuilder(false),
        ],
      );

  Widget _gates(bool wide) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _RegionLabel(
            icon: Icons.widgets_outlined,
            label: 'GATES',
            style: labelStyle,
          ),
          const SizedBox(height: 8),
          gatesBuilder(wide),
        ],
      );

  Widget _inspector({required bool contentDriven}) => Column(
        key: inspectorKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: contentDriven ? MainAxisSize.min : MainAxisSize.max,
        children: [
          _RegionLabel(
            icon: Icons.monitor_heart_outlined,
            label: 'INSPECTOR',
            style: labelStyle,
          ),
          SizedBox(height: inspectorContentSpacing),
          if (contentDriven)
            _inspectorViews(contentDriven: true)
          else
            Expanded(child: _inspectorViews(contentDriven: false)),
        ],
      );

  Widget _inspectorViews({required bool contentDriven}) =>
      QuantumInspectorViews(
        key: inspectorViewsKey,
        stateView: stateViewBuilder(contentDriven),
        currentStateVector: currentStateVector,
        numQubits: numQubits,
        contentDriven: contentDriven,
        targetStateExpression: targetStateExpression,
      );
}

class _RegionLabel extends StatelessWidget {
  const _RegionLabel({
    required this.icon,
    required this.label,
    required this.style,
  });

  final IconData icon;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: QubitQuestColors.accentInteractive,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      );
}
