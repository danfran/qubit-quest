import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

enum QubitQuestSurfaceLevel { panel, card, inset }

/// A semantic product surface. Domain visualisations should keep ownership of
/// their own geometry and colours rather than treating this as a generic box.
class QubitQuestPanel extends StatelessWidget {
  const QubitQuestPanel({
    super.key,
    required this.child,
    this.level = QubitQuestSurfaceLevel.panel,
    this.padding = const EdgeInsets.all(QubitQuestSpacing.component),
    this.showBorder = true,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final QubitQuestSurfaceLevel level;
  final EdgeInsetsGeometry padding;
  final bool showBorder;
  final Clip clipBehavior;

  Color get _background => switch (level) {
        QubitQuestSurfaceLevel.panel => QubitQuestColors.surface,
        QubitQuestSurfaceLevel.card => QubitQuestColors.surfaceRaised,
        QubitQuestSurfaceLevel.inset => QubitQuestColors.surfaceInset,
      };

  BorderRadius get _radius => switch (level) {
        QubitQuestSurfaceLevel.panel => QubitQuestRadii.panel,
        QubitQuestSurfaceLevel.card => QubitQuestRadii.card,
        QubitQuestSurfaceLevel.inset => QubitQuestRadii.card,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        clipBehavior: clipBehavior,
        decoration: BoxDecoration(
          color: _background,
          borderRadius: _radius,
          border:
              showBorder ? Border.fromBorderSide(QubitQuestBorders.soft) : null,
        ),
        child: child,
      );
}

enum QubitQuestCalloutVariant { info, insight, success, warning, error }

class QubitQuestCallout extends StatelessWidget {
  const QubitQuestCallout({
    super.key,
    required this.message,
    this.title,
    this.variant = QubitQuestCalloutVariant.info,
    this.icon,
  });

  final String? title;
  final String message;
  final QubitQuestCalloutVariant variant;
  final IconData? icon;

  static const backgroundTintOpacity = 0.025;
  static const borderOpacity = 0.28;

  Color get _accent => switch (variant) {
        QubitQuestCalloutVariant.info => QubitQuestColors.accentInteractive,
        QubitQuestCalloutVariant.insight => QubitQuestColors.accentStrong,
        QubitQuestCalloutVariant.success => QubitQuestColors.success,
        QubitQuestCalloutVariant.warning => QubitQuestColors.warning,
        QubitQuestCalloutVariant.error => QubitQuestColors.error,
      };

  IconData get _icon =>
      icon ??
      switch (variant) {
        QubitQuestCalloutVariant.info => Icons.info_outline_rounded,
        QubitQuestCalloutVariant.insight => Icons.lightbulb_outline_rounded,
        QubitQuestCalloutVariant.success => Icons.check_circle_outline_rounded,
        QubitQuestCalloutVariant.warning => Icons.warning_amber_rounded,
        QubitQuestCalloutVariant.error => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Semantics(
      liveRegion: variant == QubitQuestCalloutVariant.error,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            accent.withValues(alpha: backgroundTintOpacity),
            QubitQuestColors.surfaceInsetRaised,
          ),
          borderRadius: QubitQuestRadii.callout,
          border: Border.all(color: accent.withValues(alpha: borderOpacity)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(QubitQuestSpacing.regular),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, color: accent, size: 20),
              const SizedBox(width: QubitQuestSpacing.compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title case final title?) ...[
                      Text(title,
                          style: QubitQuestTypography.heading
                              .copyWith(fontSize: 15)),
                      const SizedBox(height: QubitQuestSpacing.micro),
                    ],
                    Text(message, style: QubitQuestTypography.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QubitQuestActivityQuestion extends StatelessWidget {
  const QubitQuestActivityQuestion({
    super.key,
    required this.question,
    this.activityLabel,
    this.supportingText,
  });

  final String? activityLabel;
  final Widget question;
  final String? supportingText;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activityLabel case final label?) ...[
            Text(label, style: QubitQuestTypography.label),
            const SizedBox(height: QubitQuestSpacing.compact),
          ],
          DefaultTextStyle(
            style: QubitQuestTypography.question,
            child: question,
          ),
          if (supportingText case final supporting?) ...[
            const SizedBox(height: QubitQuestSpacing.compact),
            Text(supporting, style: QubitQuestTypography.supporting),
          ],
        ],
      );
}

enum QubitQuestChoiceState {
  neutral,
  selected,
  correct,
  incorrect,
  disabled;

  static QubitQuestChoiceState forAnswer({
    required bool answered,
    required bool isSelected,
    required bool isCorrect,
  }) {
    if (!answered) {
      return isSelected
          ? QubitQuestChoiceState.selected
          : QubitQuestChoiceState.neutral;
    }
    if (isCorrect) return QubitQuestChoiceState.correct;
    if (isSelected) return QubitQuestChoiceState.incorrect;
    return QubitQuestChoiceState.disabled;
  }
}

class QubitQuestChoiceCard extends StatelessWidget {
  const QubitQuestChoiceCard({
    super.key,
    required this.child,
    required this.onPressed,
    this.state = QubitQuestChoiceState.neutral,
    this.indexLabel,
    this.leading,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final QubitQuestChoiceState state;
  final String? indexLabel;
  final Widget? leading;

  bool get _enabled =>
      state != QubitQuestChoiceState.disabled && onPressed != null;

  Color get _accent => switch (state) {
        QubitQuestChoiceState.selected => QubitQuestColors.accentInteractive,
        QubitQuestChoiceState.correct => QubitQuestColors.success,
        QubitQuestChoiceState.incorrect => QubitQuestColors.error,
        QubitQuestChoiceState.disabled => QubitQuestColors.textMuted,
        QubitQuestChoiceState.neutral => QubitQuestColors.borderSoft,
      };

  IconData? get _trailingIcon => switch (state) {
        QubitQuestChoiceState.selected => Icons.radio_button_checked_rounded,
        QubitQuestChoiceState.correct => Icons.check_circle_rounded,
        QubitQuestChoiceState.incorrect => Icons.cancel_rounded,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final highlighted = state == QubitQuestChoiceState.selected ||
        state == QubitQuestChoiceState.correct ||
        state == QubitQuestChoiceState.incorrect;
    final accent = _accent;

    return Semantics(
      button: true,
      enabled: _enabled,
      selected: state == QubitQuestChoiceState.selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          borderRadius: QubitQuestRadii.card,
          focusColor:
              QubitQuestColors.accentInteractive.withValues(alpha: 0.12),
          hoverColor:
              QubitQuestColors.accentInteractive.withValues(alpha: 0.07),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: QubitQuestSpacing.regular,
              vertical: QubitQuestSpacing.compact,
            ),
            decoration: BoxDecoration(
              color: highlighted
                  ? accent.withValues(alpha: 0.10)
                  : state == QubitQuestChoiceState.disabled
                      ? QubitQuestColors.disabled.withValues(alpha: 0.48)
                      : QubitQuestColors.surfaceRaised,
              borderRadius: QubitQuestRadii.card,
              border: Border.all(
                color: highlighted ? accent : QubitQuestColors.borderSoft,
                width: highlighted ? QubitQuestBorders.focus.width : 1,
              ),
            ),
            child: Row(
              children: [
                if (indexLabel case final label?) ...[
                  Text(
                    label,
                    style: QubitQuestTypography.action.copyWith(
                      color: state == QubitQuestChoiceState.disabled
                          ? QubitQuestColors.textMuted
                          : highlighted
                              ? accent
                              : QubitQuestColors.textBody,
                    ),
                  ),
                  const SizedBox(width: QubitQuestSpacing.compact),
                ],
                if (leading case final leading?) ...[
                  leading,
                  const SizedBox(width: QubitQuestSpacing.compact),
                ],
                Expanded(
                  child: DefaultTextStyle(
                    style: QubitQuestTypography.body.copyWith(
                      color: state == QubitQuestChoiceState.disabled
                          ? QubitQuestColors.textMuted
                          : QubitQuestColors.textPrimary,
                    ),
                    child: child,
                  ),
                ),
                if (_trailingIcon case final trailing?) ...[
                  const SizedBox(width: QubitQuestSpacing.compact),
                  Icon(trailing, color: accent, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum QubitQuestActionRole { primary, secondary, tertiary, destructive }

class QubitQuestActionButton extends StatelessWidget {
  const QubitQuestActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.role = QubitQuestActionRole.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final QubitQuestActionRole role;
  final IconData? icon;

  Color get _accent => switch (role) {
        QubitQuestActionRole.primary => QubitQuestColors.accentStrong,
        QubitQuestActionRole.secondary ||
        QubitQuestActionRole.tertiary =>
          QubitQuestColors.accentInteractive,
        QubitQuestActionRole.destructive => QubitQuestColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final enabled = onPressed != null;
    final foreground = enabled
        ? role == QubitQuestActionRole.tertiary
            ? accent
            : QubitQuestColors.textPrimary
        : QubitQuestColors.textMuted;
    final background = !enabled
        ? QubitQuestColors.disabled.withValues(alpha: 0.54)
        : role == QubitQuestActionRole.tertiary
            ? Colors.transparent
            : accent.withValues(
                alpha: role == QubitQuestActionRole.primary ? 0.22 : 0.10,
              );

    final style = TextButton.styleFrom(
      foregroundColor: foreground,
      backgroundColor: background,
      disabledForegroundColor: QubitQuestColors.textMuted,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(
        horizontal: QubitQuestSpacing.component,
        vertical: QubitQuestSpacing.compact,
      ),
      shape: const RoundedRectangleBorder(borderRadius: QubitQuestRadii.card),
      side: role == QubitQuestActionRole.tertiary
          ? BorderSide.none
          : BorderSide(
              color: enabled
                  ? accent.withValues(alpha: 0.48)
                  : QubitQuestColors.borderSoft,
            ),
      textStyle: QubitQuestTypography.action,
    );

    return icon == null
        ? TextButton(style: style, onPressed: onPressed, child: Text(label))
        : TextButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }
}

enum QubitQuestChipVariant { metadata, link, success, locked, count, category }

class QubitQuestChip extends StatelessWidget {
  const QubitQuestChip({
    super.key,
    required this.label,
    this.variant = QubitQuestChipVariant.metadata,
    this.icon,
    this.onPressed,
  });

  final String label;
  final QubitQuestChipVariant variant;
  final IconData? icon;
  final VoidCallback? onPressed;

  Color get _accent => switch (variant) {
        QubitQuestChipVariant.link => QubitQuestColors.accentInteractive,
        QubitQuestChipVariant.success => QubitQuestColors.success,
        QubitQuestChipVariant.category => QubitQuestColors.accentStrong,
        QubitQuestChipVariant.locked => QubitQuestColors.textMuted,
        QubitQuestChipVariant.metadata ||
        QubitQuestChipVariant.count =>
          QubitQuestColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final interactive = onPressed != null;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QubitQuestSpacing.regular,
        vertical: QubitQuestSpacing.compact,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final icon?) ...[
            Icon(icon, color: accent, size: 15),
            const SizedBox(width: QubitQuestSpacing.micro),
          ],
          Text(
            label,
            style: QubitQuestTypography.label.copyWith(color: accent),
          ),
        ],
      ),
    );

    return Semantics(
      button: interactive,
      enabled: interactive,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: QubitQuestRadii.pill,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: variant == QubitQuestChipVariant.metadata ||
                      variant == QubitQuestChipVariant.count ||
                      variant == QubitQuestChipVariant.locked
                  ? QubitQuestColors.surfaceInset
                  : accent.withValues(alpha: 0.08),
              borderRadius: QubitQuestRadii.pill,
              border: Border.all(
                color: interactive || variant == QubitQuestChipVariant.success
                    ? accent.withValues(alpha: 0.34)
                    : QubitQuestColors.borderSoft,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class QubitQuestIconAction extends StatelessWidget {
  const QubitQuestIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      visualDensity: VisualDensity.standard,
      padding: EdgeInsets.zero,
      splashRadius: 22,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: !enabled
            ? QubitQuestColors.textMuted
            : selected
                ? QubitQuestColors.accentInteractive
                : QubitQuestColors.textBody,
        disabledForegroundColor: QubitQuestColors.textMuted,
        backgroundColor: selected
            ? QubitQuestColors.accentInteractive.withValues(alpha: 0.10)
            : enabled
                ? QubitQuestColors.surfaceRaised
                : QubitQuestColors.disabled.withValues(alpha: 0.48),
        side: BorderSide(
          color: selected
              ? QubitQuestColors.accentInteractive
              : QubitQuestColors.borderSoft,
          width: selected ? QubitQuestBorders.focus.width : 1,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: QubitQuestRadii.control,
        ),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}
