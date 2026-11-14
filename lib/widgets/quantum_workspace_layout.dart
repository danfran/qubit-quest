import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

/// Presentation-only composition for the web circuit workspace.
///
/// Callers retain ownership of the circuit, derived state, controls,
/// persistence, and activity semantics.
class QuantumWorkspaceLayout extends StatelessWidget {
  const QuantumWorkspaceLayout({
    super.key,
    required this.circuit,
    required this.inspection,
    required this.toolbar,
    this.contextualActions,
    required this.wide,
    this.wideMainHeight = 448,
    this.wideMainHeightGrowsWithInspection = false,
  });

  static const double wideBreakpoint = 960;
  static const double circuitFlex = 7;
  static const double inspectionFlex = 3;

  final Widget circuit;
  final Widget inspection;
  final Widget toolbar;
  final Widget? contextualActions;
  final bool wide;
  final double wideMainHeight;

  /// When true, [wideMainHeight] is a minimum: the wide main row grows to the
  /// inspection pane's natural height (which must then size to its content),
  /// so the Inspector never scrolls inside a fixed box and the contextual
  /// actions always sit below it. The page scrolls instead.
  final bool wideMainHeightGrowsWithInspection;

  static bool usesWideLayout(double availableWidth) =>
      availableWidth >= wideBreakpoint;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        key: const ValueKey('quantum-workspace-surface'),
        decoration: BoxDecoration(
          color: QubitQuestColors.surface,
          borderRadius: QubitQuestRadii.panel,
          border: Border.all(color: QubitQuestColors.border),
        ),
        child: ClipRRect(
          borderRadius: QubitQuestRadii.panel,
          child: wide ? _wideLayout() : _narrowLayout(),
        ),
      );

  Widget _primaryPane() => Padding(
        padding: const EdgeInsets.all(20),
        child: KeyedSubtree(
          key: const ValueKey('quantum-workspace-primary-pane'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: circuit),
              const SizedBox(height: 12),
              _divider(),
              Padding(
                key: const ValueKey('quantum-workspace-toolbar'),
                padding: const EdgeInsets.only(top: 12),
                child: toolbar,
              ),
            ],
          ),
        ),
      );

  Widget _inspectionPane() => Padding(
        padding: const EdgeInsets.all(18),
        child: KeyedSubtree(
          key: const ValueKey('quantum-workspace-inspection-pane'),
          child: inspection,
        ),
      );

  Widget _inspectionBackground({Widget? child}) => ColoredBox(
        color: QubitQuestColors.surfaceInset.withValues(alpha: .52),
        child: child,
      );

  Widget _inspectionDivider() => Container(
        key: const ValueKey('quantum-workspace-inspection-divider'),
        width: 1,
        color: QubitQuestColors.borderSoft,
      );

  Widget _fixedMainRow() => SizedBox(
        height: wideMainHeight,
        child: Row(
          key: const ValueKey('quantum-workspace-main-row'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: circuitFlex.toInt(), child: _primaryPane()),
            _inspectionDivider(),
            Expanded(
              flex: inspectionFlex.toInt(),
              child: _inspectionBackground(child: _inspectionPane()),
            ),
          ],
        ),
      );

  /// The only non-positioned child (the inspection pane at its natural
  /// height, beside a [wideMainHeight] strut) sizes the stack; the
  /// background and primary pane then fill that height.
  Widget _growingMainRow() => Stack(
        key: const ValueKey('quantum-workspace-main-row'),
        children: [
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: _circuitFlexInt),
                _inspectionDivider(),
                Expanded(
                  flex: _inspectionFlexInt,
                  child: _inspectionBackground(),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: _circuitFlexInt,
                child: SizedBox(height: wideMainHeight),
              ),
              const SizedBox(width: 1),
              Expanded(flex: _inspectionFlexInt, child: _inspectionPane()),
            ],
          ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: _circuitFlexInt, child: _primaryPane()),
                const SizedBox(width: 1),
                // Transparent to hit tests: the inspection pane stays usable.
                const Spacer(flex: _inspectionFlexInt),
              ],
            ),
          ),
        ],
      );

  static const int _circuitFlexInt = 7;
  static const int _inspectionFlexInt = 3;

  Widget _wideLayout() => Column(
        key: const ValueKey('quantum-workspace-wide-layout'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (wideMainHeightGrowsWithInspection)
            _growingMainRow()
          else
            _fixedMainRow(),
          if (contextualActions case final actions?) ...[
            _divider(),
            ColoredBox(
              color: QubitQuestColors.surfaceInsetRaised.withValues(alpha: .5),
              child: _region(
                key: const ValueKey('quantum-workspace-contextual-actions'),
                child: actions,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              ),
            ),
          ],
        ],
      );

  Widget _narrowLayout() => Column(
        key: const ValueKey('quantum-workspace-narrow-layout'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _region(
            key: const ValueKey('quantum-workspace-primary-pane'),
            child: circuit,
          ),
          _divider(),
          _region(
            key: const ValueKey('quantum-workspace-toolbar'),
            child: toolbar,
          ),
          _divider(),
          ColoredBox(
            color: QubitQuestColors.surfaceInset.withValues(alpha: .38),
            child: _region(
              key: const ValueKey('quantum-workspace-inspection-pane'),
              child: inspection,
            ),
          ),
          if (contextualActions case final actions?) ...[
            _divider(),
            _region(
              key: const ValueKey('quantum-workspace-contextual-actions'),
              child: actions,
            ),
          ],
        ],
      );

  Widget _region({
    required Key key,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) =>
      Padding(
        key: key,
        padding: padding,
        child: child,
      );

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: QubitQuestColors.borderSoft,
      );
}
