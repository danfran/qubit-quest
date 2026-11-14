import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

/// One action button in [ComposerSelectionToolbar].
@immutable
class ComposerSelectionAction {
  const ComposerSelectionAction({
    required this.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final Key key;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Shown last with a muted danger tint (Delete).
  final bool destructive;
}

/// Selected-component area of the Web Composer, shared by every gate type and
/// by measurements: header, the component's own tile, identity text and one
/// compact action group.
///
/// Wide layouts keep tile, identity and actions on one row. Narrower ones put
/// the actions on their own balanced grid of equal-width buttons, so no
/// action is ever left alone on a row and nothing overflows.
class ComposerSelectionToolbar extends StatelessWidget {
  const ComposerSelectionToolbar({
    super.key,
    required this.tile,
    required this.title,
    required this.titleKey,
    required this.position,
    required this.actions,
    this.positionKey,
    this.details = const [],
    this.editor,
  });

  /// The component's visual tile (gate tile or measurement glyph).
  final Widget tile;
  final String title;
  final Key titleKey;

  /// Qubit/column location shown in the header, for example `q0 · column 1`.
  final String position;
  final Key? positionKey;

  /// Short supporting lines under the title (description, angle, hint).
  final List<Widget> details;

  /// Optional inline editor below the identity (the classical-bit selector).
  final Widget? editor;
  final List<ComposerSelectionAction> actions;

  static const double tileSize = 44;
  static const double _gap = 8;

  /// Empty-selection line; deliberately one compact row.
  static Widget empty() => const Row(
        key: ValueKey('web-composer-selection-empty'),
        children: [
          Icon(Icons.touch_app_outlined,
              size: 16, color: QubitQuestColors.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Select a gate or measurement to inspect or edit it.',
              key: ValueKey('web-composer-no-selected-gate'),
              style: TextStyle(color: QubitQuestColors.textMuted),
            ),
          ),
        ],
      );

  /// Supporting-text line in the identity column.
  static Widget detail(String text, {Key? key, IconData? icon}) {
    final label = Text(text, key: key, style: QubitQuestTypography.supporting);
    if (icon == null) return label;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 6),
          child: Icon(icon, size: 14, color: QubitQuestColors.textMuted),
        ),
        Expanded(child: label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    // Equal-width button slot; grows with text scale so labels stay whole.
    final slot = 34 + scaler.scale(74);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final actionsWidth =
            actions.length * slot + math.max(0, actions.length - 1) * _gap;
        // Tile + a readable identity column + the whole action group.
        final oneRow = actions.isNotEmpty &&
            width >= tileSize + 12 + scaler.scale(220) + 20 + actionsWidth;
        final identity = _identity();
        return Column(
          key: const ValueKey('web-composer-selection-toolbar'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            const SizedBox(height: 8),
            if (oneRow)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: actionsWidth,
                    child: _actionRow(actions),
                  ),
                ],
              )
            else ...[
              identity,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 10),
                _actionGrid(width, slot),
              ],
            ],
          ],
        );
      },
    );
  }

  /// Label and position share a line when they fit, else position wraps.
  Widget _header() => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 2,
        children: [
          const Text('SELECTED COMPONENT', style: QubitQuestTypography.label),
          Text(
            position,
            key: positionKey ??
                const ValueKey('web-composer-selection-position'),
            style: QubitQuestTypography.supporting,
          ),
        ],
      );

  Widget _identity() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            key: const ValueKey('web-composer-selection-tile'),
            dimension: tileSize,
            child: tile,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  key: titleKey,
                  style: const TextStyle(
                    color: QubitQuestColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                for (final line in details) ...[
                  const SizedBox(height: 2),
                  line,
                ],
                if (editor != null) ...[
                  const SizedBox(height: 8),
                  editor!,
                ],
              ],
            ),
          ),
        ],
      );

  Widget _actionRow(List<ComposerSelectionAction> row) => Row(
        children: [
          for (var i = 0; i < row.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(child: _button(row[i])),
          ],
        ],
      );

  /// Rows of equal-width buttons. Counts differ by at most one and the
  /// fuller rows come last, so Delete always shares its row; a lone button
  /// can only be the first one, Inspect, at full width.
  Widget _actionGrid(double width, double slot) {
    final perRowMax = math.max(1, ((width + _gap) / (slot + _gap)).floor());
    final n = actions.length;
    final rows = (n / perRowMax).ceil();
    final base = n ~/ rows;
    final fuller = n % rows;
    final sizes = [
      for (var r = 0; r < rows; r++) base + (r >= rows - fuller ? 1 : 0),
    ];
    var start = 0;
    return Column(
      key: const ValueKey('web-composer-selection-actions'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final size in sizes) ...[
          if (start > 0) const SizedBox(height: _gap),
          _actionRow(actions.sublist(start, start += size)),
        ],
      ],
    );
  }

  Widget _button(ComposerSelectionAction action) {
    const danger = Color(0xFFFF8A80);
    return OutlinedButton.icon(
      key: action.key,
      onPressed: action.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: action.destructive ? danger : null,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        side: action.destructive
            ? const BorderSide(color: Color(0x66FF8A80))
            : null,
      ),
      icon: Icon(action.icon, size: 17),
      label: Text(
        action.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}
