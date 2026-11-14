import 'dart:math' as math;

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
    this.independentCards = false,
  });

  final double availableWidth;
  final bool wide;
  final bool enlargedText;

  /// Circuit Workspace and Inspector are separate cards with independent
  /// sizing; the Inspector always sizes to its content (scrolling inside its
  /// own card on wide layouts).
  final bool independentCards;
  // The learning policy allows a side-by-side workbench below the default
  // threshold. Its narrower Inspector needs whole-content scrolling so the
  // state heading/filter cannot consume a constrained panel's entire height.
  bool get contentDrivenInspector =>
      independentCards ||
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
    this.allowBloch = true,
    this.blochCaption,
    this.blochNote,
    this.blochUnavailableMessage,
    this.independentCards = false,
    this.keepBlochTabSelectable = false,
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
  final bool allowBloch;
  final String? blochCaption;
  final String? blochNote;
  final String? blochUnavailableMessage;

  /// Opt-in Composer layout: two independent cards (see [WebComposerLayoutInfo.independentCards]).
  /// The contextual actions then live inside the Circuit Workspace card.
  final bool independentCards;
  final bool keepBlochTabSelectable;
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
  final _inspectorScroll = ScrollController();

  @override
  void dispose() {
    _inspectorScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final layout = WebComposerLayoutInfo(
            availableWidth: constraints.maxWidth,
            wide: constraints.maxWidth >= widget.wideLayoutBreakpoint,
            enlargedText: MediaQuery.textScalerOf(context).scale(14) > 14,
            independentCards: widget.independentCards,
          );
          final inspector = _inspector(layout);
          if (layout.independentCards) {
            return _cards(context, layout, inspector);
          }
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

  /// Independent cards. Wide: side by side, top-aligned, each sized by its
  /// own content, so nothing in the Inspector can move or resize the circuit.
  /// The Inspector card is capped to the window height and scrolls inside
  /// itself. Narrow: stacked, both content-sized; the page scrolls.
  Widget _cards(
    BuildContext context,
    WebComposerLayoutInfo layout,
    Widget inspector,
  ) {
    final actions = widget.actionsBuilder?.call(layout);
    final circuitCard = _Card(
      key: const ValueKey('quantum-workspace-surface'),
      child: Padding(
        key: const ValueKey('quantum-workspace-primary-pane'),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _circuit(layout),
            const SizedBox(height: 12),
            const Divider(height: 1, color: QubitQuestColors.borderSoft),
            Padding(
              key: const ValueKey('quantum-workspace-toolbar'),
              padding: const EdgeInsets.only(top: 12),
              child: _gates(layout),
            ),
            if (actions != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: QubitQuestColors.borderSoft),
              Padding(
                key: const ValueKey('quantum-workspace-contextual-actions'),
                padding: const EdgeInsets.only(top: 12),
                child: actions,
              ),
            ],
          ],
        ),
      ),
    );
    final pane = Padding(
      key: const ValueKey('quantum-workspace-inspection-pane'),
      padding: const EdgeInsets.all(18),
      child: inspector,
    );
    if (!layout.wide) {
      return Column(
        key: const ValueKey('quantum-workspace-narrow-layout'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          circuitCard,
          const SizedBox(height: 16),
          _Card(
            key: const ValueKey('web-composer-inspector-card'),
            inset: true,
            child: pane,
          ),
        ],
      );
    }
    // Leaves room for the page heading above the cards, so at the top of the
    // page the whole Inspector card (and its scrollbar) fits in the window.
    final maxInspectorHeight =
        math.max(360.0, MediaQuery.sizeOf(context).height - 200);
    return KeyedSubtree(
      key: const ValueKey('quantum-workspace-wide-layout'),
      child: Row(
        key: const ValueKey('quantum-workspace-main-row'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: QuantumWorkspaceLayout.circuitFlex.toInt(),
            child: circuitCard,
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: QuantumWorkspaceLayout.inspectionFlex.toInt(),
            child: _Card(
              key: const ValueKey('web-composer-inspector-card'),
              inset: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxInspectorHeight),
                child: Scrollbar(
                  controller: _inspectorScroll,
                  child: SingleChildScrollView(
                    key: const ValueKey('web-composer-inspector-scroll'),
                    controller: _inspectorScroll,
                    child: pane,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circuit(WebComposerLayoutInfo layout) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: layout.wide && !layout.independentCards
            ? MainAxisSize.max
            : MainAxisSize.min,
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
          if (layout.wide && !layout.independentCards)
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
          allowBloch: widget.allowBloch,
          blochCaption: widget.blochCaption,
          blochNote: widget.blochNote,
          blochUnavailableMessage: widget.blochUnavailableMessage,
          keepBlochTabSelectable: widget.keepBlochTabSelectable,
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

class _Card extends StatelessWidget {
  const _Card({super.key, required this.child, this.inset = false});
  final Widget child;
  final bool inset;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: inset
              ? Color.alphaBlend(
                  QubitQuestColors.surfaceInset.withValues(alpha: .52),
                  QubitQuestColors.surface,
                )
              : QubitQuestColors.surface,
          borderRadius: QubitQuestRadii.panel,
          border: Border.all(color: QubitQuestColors.border),
        ),
        child: ClipRRect(borderRadius: QubitQuestRadii.panel, child: child),
      );
}
