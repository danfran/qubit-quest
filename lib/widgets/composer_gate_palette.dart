import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

class ComposerGatePalette extends StatefulWidget {
  const ComposerGatePalette({
    super.key,
    required this.gates,
    required this.onGateTap,
    required this.onInspectGate,
    this.dense = false,
  });

  final List<Gate> gates;
  final ValueChanged<Gate> onGateTap;
  final ValueChanged<Gate> onInspectGate;
  final bool dense;

  @override
  State<ComposerGatePalette> createState() => _ComposerGatePaletteState();
}

class _ComposerGatePaletteState extends State<ComposerGatePalette> {
  static const Color _cardColor = Color(0xFF111827);
  static const Color _borderColor = Color(0x66344A73);

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
                      for (final gate in widget.gates)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.dense ? 1 : 2,
                          ),
                          child: _draggableGate(gate),
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
          4,
          widget.dense ? 4 : 8,
          4,
          widget.dense ? 4 : 9,
        ),
        decoration: BoxDecoration(
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
            if (constraints.hasBoundedHeight)
              Flexible(fit: FlexFit.loose, child: gateRow)
            else
              gateRow,
          ],
        ),
      ),
    );
  }

  Widget _draggableGate(Gate gate) {
    final fontSize = gate.type == SelectedGateType.ccnot
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
