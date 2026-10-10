import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/widgets/quantum_workspace_layout.dart';

/// Resolved once from the workbench's local constraints, never viewport width.
@immutable
class WebComposerLayoutInfo {
  const WebComposerLayoutInfo({
    required this.availableWidth,
    required this.wide,
    required this.enlargedText,
  });

  final double availableWidth;
  final bool wide;
  final bool enlargedText;
  // The learning policy allows a side-by-side workbench below the default
  // threshold. Its narrower Inspector needs whole-content scrolling so the
  // state heading/filter cannot consume a constrained panel's entire height.
  bool get contentDrivenInspector =>
      !wide ||
      enlargedText ||
      availableWidth < QuantumWorkspaceLayout.wideBreakpoint;
  bool get densePalette => wide;
  bool get inlineActions => wide && !enlargedText;
}

typedef WebComposerWorkbenchRegionBuilder = Widget Function(
    WebComposerLayoutInfo layout);

class WebComposerWorkbench extends StatefulWidget {
  const WebComposerWorkbench({
    super.key,
    required this.circuitBuilder,
    required this.gatesBuilder,
    required this.stateViewBuilder,
    required this.currentStateVector,
    required this.numQubits,
    required this.wideMainHeight,
    this.actionsBuilder,
    this.measureViewBuilder,
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
  final WebComposerWorkbenchRegionBuilder stateViewBuilder;
  final WebComposerWorkbenchRegionBuilder? actionsBuilder;
  final WebComposerWorkbenchRegionBuilder? measureViewBuilder;
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
  State<WebComposerWorkbench> createState() => _WebComposerWorkbenchState();
}

class _WebComposerWorkbenchState extends State<WebComposerWorkbench> {
  // Reparent the same Inspector element when layout/scroll wrappers change.
  final GlobalKey _inspectorLifecycleKey = GlobalKey();
  final _inspectorSelection = QuantumInspectorSelection();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final layout = WebComposerLayoutInfo(
            availableWidth: constraints.maxWidth,
            wide: constraints.maxWidth >= widget.wideLayoutBreakpoint,
            enlargedText: MediaQuery.textScalerOf(context).scale(14) > 14,
          );
          final inspector = _inspector(layout);
          return QuantumWorkspaceLayout(
            wide: layout.wide,
            circuit: _circuit(layout),
            inspection: layout.wide && layout.contentDrivenInspector
                ? SingleChildScrollView(child: inspector)
                : inspector,
            toolbar: _gates(layout),
            contextualActions: widget.actionsBuilder?.call(layout),
            wideMainHeight: widget.wideMainHeight,
          );
        },
      );

  Widget _circuit(WebComposerLayoutInfo layout) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: layout.wide ? MainAxisSize.max : MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = _RegionLabel(
                icon: Icons.account_tree_outlined,
                label: 'CIRCUIT WORKSPACE',
                style: widget.labelStyle,
              );
              final trailing = widget.circuitHeaderTrailing;
              if (trailing == null) return title;
              if (constraints.maxWidth < 560 || layout.enlargedText) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    Align(alignment: Alignment.centerRight, child: trailing),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  Flexible(child: trailing),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (layout.wide)
            Expanded(child: widget.circuitBuilder(layout))
          else
            widget.circuitBuilder(layout),
        ],
      );

  Widget _gates(WebComposerLayoutInfo layout) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _RegionLabel(
            icon: Icons.widgets_outlined,
            label: 'GATES',
            style: widget.labelStyle,
          ),
          const SizedBox(height: 8),
          widget.gatesBuilder(layout),
        ],
      );

  Widget _inspector(WebComposerLayoutInfo layout) => Column(
        key: widget.inspectorKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize:
            layout.contentDrivenInspector ? MainAxisSize.min : MainAxisSize.max,
        children: [
          _RegionLabel(
            icon: Icons.monitor_heart_outlined,
            label: 'INSPECTOR',
            style: widget.labelStyle,
          ),
          SizedBox(height: widget.inspectorContentSpacing),
          if (layout.contentDrivenInspector)
            _inspectorViews(layout)
          else
            Expanded(child: _inspectorViews(layout)),
        ],
      );

  Widget _inspectorViews(WebComposerLayoutInfo layout) => KeyedSubtree(
        key: _inspectorLifecycleKey,
        child: QuantumInspectorViews(
          selection: _inspectorSelection,
          key: widget.inspectorViewsKey,
          stateView: widget.stateViewBuilder(layout),
          measureView: widget.measureViewBuilder?.call(layout),
          currentStateVector: widget.currentStateVector,
          numQubits: widget.numQubits,
          contentDriven: layout.contentDrivenInspector,
          targetStateExpression: widget.targetStateExpression,
        ),
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
