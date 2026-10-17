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

  Widget _wideLayout() => Column(
        key: const ValueKey('quantum-workspace-wide-layout'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: wideMainHeight,
            child: Row(
              key: const ValueKey('quantum-workspace-main-row'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: circuitFlex.toInt(),
                  child: Padding(
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
                  ),
                ),
                Container(
                  key: const ValueKey('quantum-workspace-inspection-divider'),
                  width: 1,
                  color: QubitQuestColors.borderSoft,
                ),
                Expanded(
                  flex: inspectionFlex.toInt(),
                  child: ColoredBox(
                    color: QubitQuestColors.surfaceInset.withValues(alpha: .52),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: KeyedSubtree(
                        key:
                            const ValueKey('quantum-workspace-inspection-pane'),
                        child: inspection,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
