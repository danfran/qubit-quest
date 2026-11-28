import 'package:flutter/material.dart';
import 'package:quantumquiz/utils/probability_format.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

/// Shared scientific presentation primitives (v2.6 M11C.1).
///
/// The Composer's analysis uses them now; Journey, Mastery, the Notebook and
/// the Bloch Explorer are meant to compose the same pieces when they are
/// redesigned, so a table, a heading or a probability bar reads the same
/// everywhere. They own presentation only: every value is supplied by the
/// caller from the simulation.

/// Supporting metadata line (counts, basis order, provenance).
class QqMeta extends StatelessWidget {
  const QqMeta(this.text, {super.key, this.maxLines, this.color});
  final String text;
  final int? maxLines;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: color == null ? QqType.meta : QqType.meta.copyWith(color: color),
      );
}

/// A compact icon action for panel headers (Copy, filters), at least 36 px
/// square with a tooltip naming what it does.
class QqIconAction extends StatelessWidget {
  const QqIconAction({
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
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          color: selected
              ? QubitQuestColors.accentInteractive
              : QubitQuestColors.textMuted,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
}

/// A labelled toggle chip for a panel header ("Non-zero only"). Its whole
/// area toggles; the state is visible as a check and as colour.
class QqToggleChip extends StatelessWidget {
  const QqToggleChip({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.tooltip,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = Semantics(
      toggled: value,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value
                  ? QubitQuestColors.accentInteractive.withValues(alpha: .55)
                  : QubitQuestSurfaces.rule,
            ),
            color: value
                ? QubitQuestColors.accentInteractive.withValues(alpha: .10)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 16,
                color: value
                    ? QubitQuestColors.accentInteractive
                    : QubitQuestColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QqType.control.copyWith(
                    fontSize: 13,
                    color: value
                        ? QubitQuestColors.textPrimary
                        : QubitQuestColors.textBody,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// A column of a [QqDataTable]: fixed [width] or a [flex] share of what is
/// left, and how its cells align. Header and every row are laid out from
/// the same specification, so headings sit exactly over their data.
class QqColumn {
  const QqColumn(
    this.label, {
    this.width,
    this.flex = 1,
    this.align = Alignment.centerLeft,
  });

  final String label;
  final double? width;
  final int flex;
  final Alignment align;

  static const right = Alignment.centerRight;
}

class QqTableRow {
  const QqTableRow({required this.cells, this.key, this.semanticsLabel});
  final List<Widget> cells;
  final Key? key;

  /// One sentence for assistive technology; cells are then excluded.
  final String? semanticsLabel;
}

/// Scientific table: consistent column widths and padding, a muted header,
/// subtle rules between rows, tabular numerals in [QqType.table].
class QqDataTable extends StatelessWidget {
  const QqDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.headerKey,
    this.columnGap = 16,
    this.rowMinHeight = 36,
  });

  final List<QqColumn> columns;
  final List<QqTableRow> rows;
  final Key? headerKey;
  final double columnGap;
  final double rowMinHeight;

  Widget _line(List<Widget> cells) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final (i, column) in columns.indexed) ...[
            if (i > 0) SizedBox(width: columnGap),
            if (column.width case final w?)
              SizedBox(
                width: w,
                child: Align(alignment: column.align, child: cells[i]),
              )
            else
              Expanded(
                flex: column.flex,
                child: Align(alignment: column.align, child: cells[i]),
              ),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            key: headerKey,
            padding: const EdgeInsets.only(bottom: 6),
            child: _line([
              for (final column in columns)
                Text(column.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QqType.tableHeader),
            ]),
          ),
          const Divider(
              height: 1, thickness: 1, color: QubitQuestSurfaces.rule),
          for (final (i, row) in rows.indexed) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0x1F344A73)),
            Semantics(
              key: row.key,
              container: true,
              label: row.semanticsLabel,
              excludeSemantics: row.semanticsLabel != null,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: rowMinHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: DefaultTextStyle.merge(
                    style: QqType.table,
                    child: _line(row.cells),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
}

/// A probability on a fixed 0–100% track: the full width is certainty, so
/// bars are comparable across rows and panels (never auto-scaled).
class QqProbabilityBar extends StatelessWidget {
  const QqProbabilityBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color = QubitQuestColors.accentInteractive,
  });

  final double value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: CustomPaint(
          painter: _BarPainter(value.clamp(0.0, 1.0), color),
          size: Size.infinite,
        ),
      );
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = const Color(0x14FFFFFF),
    );
    // Zero within simulator noise draws nothing (M11G); a genuinely
    // non-zero value always shows at least a sliver.
    if (value <= probabilityZeroTolerance) return;
    final w = (size.width * value).clamp(2.0, size.width);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, size.height), radius),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.value != value || old.color != color;
}

/// Keyed facts in two aligned columns ("Measures  q0 → c0, q1 → c1").
class QqFactList extends StatelessWidget {
  const QqFactList({super.key, required this.facts, this.labelWidth = 104});

  final List<(String, Widget)> facts;
  final double labelWidth;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, (label, value)) in facts.indexed)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Text(label, style: QqType.meta),
                  ),
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: QqType.table.copyWith(height: 1.45),
                      child: value,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}
