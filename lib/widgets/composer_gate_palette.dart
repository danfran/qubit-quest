import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/composer_session.dart' show minimumQubitsFor;
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart' show orderedPaletteGates;
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/measurement_glyph.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

class ComposerGatePalette extends StatefulWidget {
  const ComposerGatePalette({
    super.key,
    required this.gates,
    required this.onGateTap,
    required this.onInspectGate,
    this.dense = false,
    this.onMeasurementTap,
    this.measurementDraggable = false,
    this.embedded = false,
    this.numQubits,
  });

  /// Web hosts pass the register size: tiles then follow the shared
  /// palette order, and gates that need more qubits are shown disabled
  /// and cannot be dragged (v2.6 M11D). Null keeps the native behaviour.
  final int? numQubits;

  /// Legacy tap-to-place measurement button (native host).
  final VoidCallback? onMeasurementTap;

  /// Shows a draggable measurement tile that behaves like the gate tiles and
  /// produces [CircuitDragData.measurement] (Web host).
  final bool measurementDraggable;
  final List<Gate> gates;
  final ValueChanged<Gate> onGateTap;
  final ValueChanged<Gate> onInspectGate;
  final bool dense;
  final bool embedded;

  @override
  State<ComposerGatePalette> createState() => _ComposerGatePaletteState();
}

class _ComposerGatePaletteState extends State<ComposerGatePalette> {
  static const Color _cardColor = QubitQuestColors.surface;
  static const Color _borderColor = QubitQuestColors.border;

  late final ScrollController _scrollController;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollButtons();
    });
  }

  @override
  void didUpdateWidget(covariant ComposerGatePalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gates != widget.gates || oldWidget.dense != widget.dense) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateScrollButtons();
      });
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateScrollButtons)
      ..dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canScrollLeft = position.extentBefore > 0.1;
    final canScrollRight = position.extentAfter > 0.1;
    if (_canScrollLeft == canScrollLeft && _canScrollRight == canScrollRight) {
      return;
    }
    setState(() {
      _canScrollLeft = canScrollLeft;
      _canScrollRight = canScrollRight;
    });
  }

  void _scroll(double offset) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (position.pixels + offset).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollLeft() {
    if (!_scrollController.hasClients) return;
    _scroll(-_scrollController.position.viewportDimension);
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;
    _scroll(_scrollController.position.viewportDimension);
  }

  Widget _utilityButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final foreground = onPressed == null
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.78);
    return IconButton(
      key: key,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: widget.dense ? 18 : 24,
        height: widget.dense ? 20 : 24,
      ),
      iconSize: widget.dense ? 15 : 17,
      color: foreground.withValues(alpha: widget.dense ? 0.70 : 0.84),
      disabledColor: Colors.white.withValues(alpha: 0.28),
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: widget.dense ? 15 : 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gateRow = Row(
      children: [
        _utilityButton(
          key: const ValueKey('palette-scroll-left'),
          icon: Icons.chevron_left_rounded,
          tooltip: 'Scroll gates left',
          onPressed: _canScrollLeft ? _scrollLeft : null,
        ),
        SizedBox(width: widget.dense ? 0 : 1),
        Expanded(
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: 0.24),
              ),
              trackVisibility: const WidgetStatePropertyAll(false),
            ),
            child: Scrollbar(
              key: const ValueKey('gate-palette-scrollbar'),
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 2,
              radius: const Radius.circular(99),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (widget.onMeasurementTap != null)
                        Tooltip(
                            message:
                                'Measure Z: select, then tap a circuit slot',
                            child: OutlinedButton(
                                key: const ValueKey('measurement-palette'),
                                onPressed: widget.onMeasurementTap,
                                child: const Text('M'))),
                      for (final gate in widget.numQubits == null
                          ? widget.gates
                          : orderedPaletteGates(widget.gates))
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.dense ? 1 : 2,
                          ),
                          child: _draggableGate(gate),
                        ),
                      if (widget.measurementDraggable)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.dense ? 1 : 2,
                          ),
                          child: _draggableMeasurement(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: widget.dense ? 0 : 1),
        _utilityButton(
          key: const ValueKey('palette-scroll-right'),
          icon: Icons.chevron_right_rounded,
          tooltip: 'Scroll gates right',
          onPressed: _canScrollRight ? _scrollRight : null,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) => Container(
        padding: EdgeInsets.fromLTRB(
          widget.embedded ? 0 : 4,
          widget.embedded ? 0 : (widget.dense ? 4 : 8),
          widget.embedded ? 0 : 4,
          widget.embedded ? 0 : (widget.dense ? 4 : 9),
        ),
        decoration: widget.embedded
            ? null
            : BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(widget.dense ? 12 : 14),
                border: Border.all(color: _borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.embedded) ...[
              SizedBox(
                height: widget.dense ? 18 : 34,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Gates',
                    style: TextStyle(
                      fontSize: widget.dense ? 11.5 : 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: widget.dense ? 0 : 3),
            ],
            if (constraints.hasBoundedHeight)
              Flexible(fit: FlexFit.loose, child: gateRow)
            else
              gateRow,
          ],
        ),
      ),
    );
  }

  Widget _draggableMeasurement() {
    final size = widget.dense ? 38.0 : 52.0;
    return Draggable<CircuitDragData>(
      key: const ValueKey('measurement-palette'),
      data: const CircuitDragData.measurement(),
      feedback: Material(
        color: Colors.transparent,
        child: MeasurementGlyph(size: size),
      ),
      childWhenDragging: Opacity(
        opacity: 0.46,
        child: MeasurementGlyph(size: size),
      ),
      child: Tooltip(
        message: 'Measure (Z basis): drag onto a qubit wire',
        child: Semantics(
          button: true,
          label: 'Measurement',
          hint: 'Drag onto a qubit wire',
          child: MeasurementGlyph(size: size),
        ),
      ),
    );
  }

  Widget _draggableGate(Gate gate) {
    final fontSize =
        gate.type == SelectedGateType.ccnot || gate.type == SelectedGateType.mcx
            ? (widget.dense ? 11.0 : 14.0)
            : gate.requiresAngle && gate.angle != null
                ? (widget.dense ? 8.5 : 10.0)
                : (widget.dense ? 14.0 : 18.0);
    final buttonSize = widget.dense ? 38.0 : 52.0;
    QubitQuestGateTile tile() => QubitQuestGateTile(
          gate: gate,
          size: buttonSize,
          fontSize: fontSize,
          onPressed: () => widget.onGateTap(gate),
          onInspect: () => widget.onInspectGate(gate),
        );
    final needed = minimumQubitsFor(gate.type);
    final unavailable =
        widget.numQubits != null && needed > widget.numQubits!;
    if (unavailable) {
      return Tooltip(
        message: 'Needs at least $needed qubits; this circuit has '
            '${widget.numQubits}.',
        child: Semantics(
          enabled: false,
          child: Opacity(
            key: ValueKey('palette-gate-unavailable-${gate.type.name}'),
            opacity: .35,
            child: IgnorePointer(child: tile()),
          ),
        ),
      );
    }
    return Draggable<CircuitDragData>(
      data: CircuitDragData.palette(gate),
      feedback: Material(
        color: Colors.transparent,
        child: QubitQuestGateTile(
          gate: gate,
          size: buttonSize,
          fontSize: fontSize,
          onPressed: null,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.46, child: tile()),
      child: tile(),
    );
  }
}
