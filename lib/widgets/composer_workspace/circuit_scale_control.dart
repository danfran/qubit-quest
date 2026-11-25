import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';

/// Compact circuit-scale selector for the circuit header: the discrete
/// steps of [WorkspaceLayoutPreferences.circuitScales] (100 / 125 / 150%).
///
/// Presentation only. Changing scale never mutates the circuit, never
/// enters undo history, never invalidates results and never autosaves the
/// circuit; the host persists it with the workspace layout preferences.
class CircuitScaleControl extends StatelessWidget {
  const CircuitScaleControl({
    super.key,
    required this.scale,
    required this.onChanged,
  });

  final double scale;
  final ValueChanged<double> onChanged;

  static String label(double scale) => '${(scale * 100).round()}%';

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Circuit scale',
        child: Row(
          key: const ValueKey('composer-circuit-scale'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.zoom_in_rounded,
                  size: 16, color: QubitQuestColors.textMuted),
            ),
            for (final value in WorkspaceLayoutPreferences.circuitScales)
              _ScaleStep(
                value: value,
                selected: value == scale,
                onPressed: () => onChanged(value),
              ),
          ],
        ),
      );
}

class _ScaleStep extends StatelessWidget {
  const _ScaleStep({
    required this.value,
    required this.selected,
    required this.onPressed,
  });

  final double value;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = CircuitScaleControl.label(value);
    return Tooltip(
      message: selected ? 'Circuit shown at $text' : 'Show circuit at $text',
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Circuit scale $text',
        child: ExcludeSemantics(
          child: InkWell(
            key: ValueKey('composer-circuit-scale-${(value * 100).round()}'),
            onTap: selected ? null : onPressed,
            borderRadius: QubitQuestRadii.control,
            child: Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 28),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: selected
                    ? QubitQuestColors.accentInteractive.withValues(alpha: .16)
                    : null,
                borderRadius: QubitQuestRadii.control,
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: selected
                      ? QubitQuestColors.accentInteractive
                      : QubitQuestColors.textMuted,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
