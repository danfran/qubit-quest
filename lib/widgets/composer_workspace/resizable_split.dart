import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

/// A thin drag strip between two workspace regions.
///
/// [onDragStart] fires once when a gesture begins; [onDrag] then receives
/// the *cumulative* offset along [axis] since that start (preview only), so
/// callers apply it to the size captured at the start and no pointer update
/// is lost between frames; [onDragEnd] fires once per gesture so callers
/// persist at a commit point.
/// Double-click restores the default via [onReset]. No docking framework:
/// callers own the sizes and clamp them.
class ResizeHandle extends StatefulWidget {
  const ResizeHandle({
    super.key,
    required this.axis,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
    this.onReset,
    this.semanticLabel,
    this.thickness = 8,
  });

  /// [Axis.horizontal] resizes widths (a vertical strip); [Axis.vertical]
  /// resizes heights (a horizontal strip).
  final Axis axis;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDrag;
  final VoidCallback onDragEnd;
  final VoidCallback? onReset;
  final String? semanticLabel;
  final double thickness;

  @override
  State<ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<ResizeHandle> {
  bool _hovered = false;
  bool _dragging = false;
  double _offset = 0;

  void _start() {
    _offset = 0;
    setState(() => _dragging = true);
    widget.onDragStart();
  }

  void _update(double delta) {
    _offset += delta;
    widget.onDrag(_offset);
  }

  bool get _horizontal => widget.axis == Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _dragging;
    final grip = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: _horizontal ? (active ? 3 : 2) : (active ? 36 : 28),
      height: _horizontal ? (active ? 36 : 28) : (active ? 3 : 2),
      decoration: BoxDecoration(
        color: active
            ? QubitQuestColors.accentInteractive.withValues(alpha: .8)
            : QubitQuestColors.border,
        borderRadius: QubitQuestRadii.pill,
      ),
    );
    return Semantics(
      label: widget.semanticLabel,
      hint: 'Drag to resize. Double-click to restore the default size.',
      child: MouseRegion(
        cursor: _horizontal
            ? SystemMouseCursors.resizeColumn
            : SystemMouseCursors.resizeRow,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: widget.onReset,
          onHorizontalDragStart: _horizontal ? (_) => _start() : null,
          onHorizontalDragUpdate:
              _horizontal ? (d) => _update(d.delta.dx) : null,
          onHorizontalDragEnd: _horizontal ? (_) => _end() : null,
          onHorizontalDragCancel: _horizontal ? _end : null,
          onVerticalDragStart: _horizontal ? null : (_) => _start(),
          onVerticalDragUpdate: _horizontal ? null : (d) => _update(d.delta.dy),
          onVerticalDragEnd: _horizontal ? null : (_) => _end(),
          onVerticalDragCancel: _horizontal ? null : _end,
          child: SizedBox(
            width: _horizontal ? widget.thickness : double.infinity,
            height: _horizontal ? double.infinity : widget.thickness,
            child: Center(child: grip),
          ),
        ),
      ),
    );
  }

  void _end() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    widget.onDragEnd();
  }
}
