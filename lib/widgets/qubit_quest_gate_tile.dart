import 'package:flutter/material.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/gate_visual_style.dart';

/// Shared visual and button treatment for Qubit Quest gate controls.
///
/// Composer supplies drag behavior around this tile; each surface supplies its
/// normal tap action and may opt into the shared long-press inspection action.
class QubitQuestGateTile extends StatelessWidget {
  const QubitQuestGateTile({
    super.key,
    required this.gate,
    required this.onPressed,
    this.onInspect,
    this.size = 52,
    this.fontSize,
    this.tooltip,
  });

  final Gate gate;
  final VoidCallback? onPressed;
  final VoidCallback? onInspect;
  final double size;
  final double? fontSize;
  final String? tooltip;

  static BoxDecoration decorationFor(Gate gate) {
    final visual = QubitQuestGateStyle.forGate(gate);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: visual.colors,
      ),
      borderRadius: BorderRadius.circular(QubitQuestGateStyle.buttonRadius),
      border: Border.all(
        color: QubitQuestGateStyle.border,
        width: QubitQuestGateStyle.borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .45),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelSize = fontSize ??
        (gate.type == SelectedGateType.ccnot
            ? 14
            : gate.requiresAngle && gate.angle != null
                ? 10
                : 18);
    final button = DecoratedBox(
      decoration: decorationFor(gate),
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            onLongPress: onInspect,
            borderRadius:
                BorderRadius.circular(QubitQuestGateStyle.buttonRadius),
            child: Center(
              child: Text(
                gate.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .95),
                  fontSize: labelSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
