import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

class QubitQuestDialog extends StatelessWidget {
  const QubitQuestDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.maxWidth = 520,
    this.titleAlign = TextAlign.left,
    this.titleStyle,
  });

  // Compatibility aliases. QubitQuestColors is the canonical authority.
  static const Color panelColor = QubitQuestColors.surface;
  static const Color innerColor = QubitQuestColors.surfaceInset;
  static const Color cardColor = QubitQuestColors.surfaceRaised;
  static const Color borderColor = QubitQuestColors.border;
  static const Color borderSoftColor = QubitQuestColors.borderSoft;
  static const Color cyan = QubitQuestColors.accentInteractive;
  static const Color purple = QubitQuestColors.accentStrong;
  static const Color disabledColor = QubitQuestColors.disabled;
  static const Color mutedText = QubitQuestColors.textMuted;

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final TextAlign titleAlign;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double resolvedMaxWidth = math.min(
            constraints.maxWidth,
            maxWidth,
          );
          final double resolvedMaxHeight = math.min(
            constraints.maxHeight,
            screenSize.height * 0.84,
          );

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: resolvedMaxWidth,
              maxHeight: resolvedMaxHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.36),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: titleAlign,
                    style: titleStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      child: child,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 8,
                    children: actions,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class QubitQuestDialogButton extends StatelessWidget {
  const QubitQuestDialogButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
  }) : primary = false;

  const QubitQuestDialogButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
  }) : primary = true;

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color accent =
        primary ? QubitQuestDialog.purple : QubitQuestDialog.cyan;

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor:
            enabled ? Colors.white : Colors.white.withValues(alpha: 0.42),
        backgroundColor: enabled
            ? accent.withValues(alpha: primary ? 0.22 : 0.10)
            : QubitQuestDialog.disabledColor.withValues(alpha: 0.54),
        side: BorderSide(
          color: enabled
              ? accent.withValues(alpha: primary ? 0.60 : 0.38)
              : QubitQuestDialog.borderSoftColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class QubitQuestQubitButton extends StatelessWidget {
  const QubitQuestQubitButton({
    super.key,
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color border = selected
        ? QubitQuestDialog.purple.withValues(alpha: 0.82)
        : disabled
            ? QubitQuestDialog.borderSoftColor
            : QubitQuestDialog.cyan.withValues(alpha: 0.46);
    final Color background = selected
        ? QubitQuestDialog.purple.withValues(alpha: 0.24)
        : disabled
            ? QubitQuestDialog.disabledColor.withValues(alpha: 0.48)
            : QubitQuestDialog.cardColor;
    final Color foreground = disabled
        ? Colors.white.withValues(alpha: 0.38)
        : selected
            ? Colors.white
            : const Color(0xFFD6E3F8);

    return InkWell(
      onTap: disabled ? null : onPressed,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 58,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: QubitQuestDialog.purple.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
