import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/circuit_layout_metrics.dart';
import 'package:quantumquiz/widgets/gate_visual_style.dart';
import 'package:quantumquiz/widgets/measurement_glyph.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

/// Palette groups in display order. New gate types join a group through
/// [gatePaletteCategoryFor] (for example a future CY or multi-controlled X
/// belongs to [multiQubit]).
enum GatePaletteCategory {
  basic('Basic'),
  phase('Phase'),
  rotations('Rotations'),
  multiQubit('Multi-qubit'),
  measurement('Measurement');

  const GatePaletteCategory(this.label);
  final String label;
}

GatePaletteCategory gatePaletteCategoryFor(SelectedGateType type) =>
    switch (type) {
      SelectedGateType.s || SelectedGateType.t => GatePaletteCategory.phase,
      SelectedGateType.rx ||
      SelectedGateType.ry ||
      SelectedGateType.rz =>
        GatePaletteCategory.rotations,
      SelectedGateType.cnot ||
      SelectedGateType.cz ||
      SelectedGateType.ccnot =>
        GatePaletteCategory.multiQubit,
      SelectedGateType.measureZ => GatePaletteCategory.measurement,
      _ => GatePaletteCategory.basic,
    };

/// Compact label shown on palette tiles.
String gatePaletteLabel(SelectedGateType type) => switch (type) {
      SelectedGateType.hadamard => 'H',
      SelectedGateType.x => 'X',
      SelectedGateType.y => 'Y',
      SelectedGateType.z => 'Z',
      SelectedGateType.s => 'S',
      SelectedGateType.t => 'T',
      SelectedGateType.rx => 'Rx',
      SelectedGateType.ry => 'Ry',
      SelectedGateType.rz => 'Rz',
      SelectedGateType.cnot => 'CX',
      SelectedGateType.cz => 'CZ',
      SelectedGateType.ccnot => 'CCX',
      SelectedGateType.measureZ => 'M',
      _ => type.name.toUpperCase(),
    };

/// Plain-text version of the catalogue's inline LaTeX for tooltips.
String plainGateText(String latex) => latex
    .replaceAllMapped(RegExp(r'\\mathrm\{([^}]*)\}'), (m) => m[1]!)
    .replaceAllMapped(RegExp(r'\^\{([^}]*)\}'), (m) => '^(${m[1]})')
    .replaceAll(r'\oplus', '⊕')
    .replaceAll(r'\otimes', '⊗')
    .replaceAll(r'\cdot', '·')
    .replaceAll(r'\dagger', '†')
    .replaceAll(r'\mapsto', '↦')
    .replaceAll(r'\quad', ' ')
    .replaceAll(r'\(', '')
    .replaceAll(r'\)', '')
    .replaceAll(r'\[', '')
    .replaceAll(r'\]', '')
    .replaceAll(r'\rangle', '⟩')
    .replaceAll(r'\rightarrow', '→')
    .replaceAll(r'\pi', 'π')
    .replaceAll(r'\theta', 'θ')
    .replaceAll(r'\,', ' ');

String gateTooltip(SelectedGateType type) {
  if (type == SelectedGateType.measureZ) {
    return 'Measure (Z basis): drag onto a qubit wire';
  }
  final info = GateEducationalCatalog.forType(type);
  if (info == null) return gatePaletteLabel(type);
  return '${info.name}\n${plainGateText(info.intuition)}\n'
      'Click to preview · drag onto a qubit wire';
}

/// Size of the drag feedback tile, which is painted centred on the pointer:
/// the displayed gate size at [scale] plus a small lift margin (34 px at
/// 100%), so the dragged gate matches what will be placed.
double paletteFeedbackSize(double scale) =>
    CircuitLayoutMetrics.gateSize * scale + 4;

/// The pointer itself is the drop hot spot: the feedback's anchor is the
/// pointer and the tile is painted centred on it, so the slot under the
/// pointer is the slot that receives the gate.
Offset _pointerAnchor(Draggable<Object> _, BuildContext __, Offset ___) =>
    Offset.zero;

Widget _centredFeedback(Widget tile, double size) => Material(
      color: Colors.transparent,
      child: Transform.translate(
        offset: Offset(-size / 2, -size / 2),
        child: tile,
      ),
    );

/// Persistent, categorised, vertical gate palette for the desktop workspace.
///
/// Gates come from the session policy ([gates], plus a measurement tile when
/// [allowsMeasurement]); empty categories are hidden. Dragging a tile places
/// a gate through the canvas; clicking it only previews the gate type in the
/// inspector ([onPreview]) and never edits the circuit.
class ComposerGatePalettePanel extends StatefulWidget {
  const ComposerGatePalettePanel({
    super.key,
    required this.gates,
    required this.allowsMeasurement,
    required this.onPreview,
    this.previewedType,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.circuitScale = 1.0,
  });

  /// The canvas's display scale; drag feedback is drawn at that size.
  final double circuitScale;

  final List<Gate> gates;
  final bool allowsMeasurement;
  final ValueChanged<SelectedGateType> onPreview;
  final SelectedGateType? previewedType;

  /// Shows a narrow single-column rail of tiles instead of the full panel.
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  @override
  State<ComposerGatePalettePanel> createState() =>
      _ComposerGatePalettePanelState();
}

class _ComposerGatePalettePanelState extends State<ComposerGatePalettePanel> {
  final Set<GatePaletteCategory> _folded = {};
  final _scroll = ScrollController();

  static const _displayOrder = [
    SelectedGateType.hadamard,
    SelectedGateType.x,
    SelectedGateType.y,
    SelectedGateType.z,
    SelectedGateType.s,
    SelectedGateType.t,
    SelectedGateType.rx,
    SelectedGateType.ry,
    SelectedGateType.rz,
    SelectedGateType.cnot,
    SelectedGateType.cz,
    SelectedGateType.ccnot,
  ];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Map<GatePaletteCategory, List<Gate>> get _groups {
    final seen = <SelectedGateType>{};
    final gates = [
      for (final gate in widget.gates)
        if (seen.add(gate.type)) gate,
    ]..sort((a, b) {
        int rank(SelectedGateType t) {
          final i = _displayOrder.indexOf(t);
          return i < 0 ? _displayOrder.length : i;
        }

        return rank(a.type).compareTo(rank(b.type));
      });
    final groups = <GatePaletteCategory, List<Gate>>{};
    for (final category in GatePaletteCategory.values) {
      final members =
          gates.where((g) => gatePaletteCategoryFor(g.type) == category);
      if (members.isNotEmpty) groups[category] = members.toList();
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) => widget.collapsed ? _rail() : _panel();

  Widget _panel() {
    final groups = _groups;
    return Column(
      key: const ValueKey('composer-gate-palette-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(
          title: 'Gates',
          trailing: widget.onToggleCollapsed == null
              ? null
              : _IconAction(
                  key: const ValueKey('composer-palette-collapse'),
                  icon: Icons.keyboard_double_arrow_left_rounded,
                  tooltip: 'Collapse gate palette',
                  onPressed: widget.onToggleCollapsed!,
                ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scroll,
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
              children: [
                for (final entry in groups.entries)
                  _category(entry.key, entry.value),
                if (widget.allowsMeasurement)
                  _category(GatePaletteCategory.measurement, const []),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _category(GatePaletteCategory category, List<Gate> gates) {
    final folded = _folded.contains(category);
    final measurement = category == GatePaletteCategory.measurement;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('composer-palette-category-${category.name}'),
            borderRadius: QubitQuestRadii.control,
            onTap: () => setState(() =>
                folded ? _folded.remove(category) : _folded.add(category)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(category.label,
                        style: QubitQuestTypography.supporting),
                  ),
                  Icon(
                    folded
                        ? Icons.chevron_right_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: QubitQuestColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (!folded)
            LayoutBuilder(builder: (context, constraints) {
              const gap = 6.0;
              final twoColumns = constraints.maxWidth >= 120;
              final width = twoColumns
                  ? (constraints.maxWidth - gap) / 2
                  : constraints.maxWidth;
              final tiles = measurement
                  ? [_measurementTile(width: width)]
                  : [for (final gate in gates) _gateTile(gate, width: width)];
              return Wrap(spacing: gap, runSpacing: gap, children: tiles);
            }),
        ],
      ),
    );
  }

  Widget _rail() {
    final groups = _groups;
    return Column(
      key: const ValueKey('composer-gate-palette-rail'),
      children: [
        const SizedBox(height: 6),
        if (widget.onToggleCollapsed != null)
          _IconAction(
            key: const ValueKey('composer-palette-expand'),
            icon: Icons.keyboard_double_arrow_right_rounded,
            tooltip: 'Expand gate palette',
            onPressed: widget.onToggleCollapsed!,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              for (final (index, gates) in groups.values.indexed) ...[
                if (index > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                    child:
                        Divider(height: 1, color: QubitQuestColors.borderSoft),
                  ),
                for (final gate in gates)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: _gateTile(gate, width: 38, square: true),
                    ),
                  ),
              ],
              if (widget.allowsMeasurement) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                  child: Divider(height: 1, color: QubitQuestColors.borderSoft),
                ),
                Center(child: _measurementTile(width: 38, square: true)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _gateTile(Gate gate, {required double width, bool square = false}) {
    final previewed = widget.previewedType == gate.type;
    final style = QubitQuestGateStyle.forGate(gate);
    final label = gatePaletteLabel(gate.type);
    Widget face({bool dimmed = false}) => _PaletteTileFace(
          width: width,
          height: square ? width : 38,
          colors: style.colors,
          label: label,
          subLabel: square || !gate.requiresAngle ? null : 'θ',
          selected: previewed,
          dimmed: dimmed,
        );
    return Tooltip(
      message: gateTooltip(gate.type),
      waitDuration: const Duration(milliseconds: 450),
      child: Semantics(
        button: true,
        selected: previewed,
        label: GateEducationalCatalog.forType(gate.type)?.name ?? label,
        hint: 'Drag onto a qubit wire, or activate to preview',
        child: Draggable<CircuitDragData>(
          key: ValueKey('composer-palette-gate-${gate.type.name}'),
          data: CircuitDragData.palette(gate),
          dragAnchorStrategy: _pointerAnchor,
          feedback: _centredFeedback(
            QubitQuestGateTile(
              key: const ValueKey('composer-palette-drag-feedback'),
              gate: gate,
              size: paletteFeedbackSize(widget.circuitScale),
              fontSize: (gate.type == SelectedGateType.ccnot ? 10 : 13) *
                  widget.circuitScale,
              onPressed: null,
            ),
            paletteFeedbackSize(widget.circuitScale),
          ),
          childWhenDragging: face(dimmed: true),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: GestureDetector(
              onTap: () => widget.onPreview(gate.type),
              child: face(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _measurementTile({required double width, bool square = false}) {
    final previewed = widget.previewedType == SelectedGateType.measureZ;
    Widget face({bool dimmed = false}) => _PaletteTileFace(
          width: width,
          height: square ? width : 38,
          colors: MeasurementGlyph.gradient,
          label: square ? null : 'M',
          glyph: true,
          selected: previewed,
          dimmed: dimmed,
        );
    return Tooltip(
      message: gateTooltip(SelectedGateType.measureZ),
      waitDuration: const Duration(milliseconds: 450),
      child: Semantics(
        button: true,
        label: 'Measurement',
        hint: 'Drag onto a qubit wire',
        child: Draggable<CircuitDragData>(
          key: const ValueKey('measurement-palette'),
          data: const CircuitDragData.measurement(),
          dragAnchorStrategy: _pointerAnchor,
          feedback: _centredFeedback(
            MeasurementGlyph(
              key: const ValueKey('composer-palette-drag-feedback'),
              size: paletteFeedbackSize(widget.circuitScale),
            ),
            paletteFeedbackSize(widget.circuitScale),
          ),
          childWhenDragging: face(dimmed: true),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: GestureDetector(
              onTap: () => widget.onPreview(SelectedGateType.measureZ),
              child: face(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteTileFace extends StatelessWidget {
  const _PaletteTileFace({
    required this.width,
    required this.height,
    required this.colors,
    this.label,
    this.subLabel,
    this.glyph = false,
    this.selected = false,
    this.dimmed = false,
  });

  final double width;
  final double height;
  final List<Color> colors;
  final String? label;
  final String? subLabel;
  final bool glyph;
  final bool selected;
  final bool dimmed;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: dimmed ? .45 : 1,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                for (final c in colors) Color.lerp(c, Colors.black, .22)!,
              ],
            ),
            borderRadius: QubitQuestRadii.control,
            border: Border.all(
              color: selected
                  ? QubitQuestColors.accentInteractive
                  : Colors.white.withValues(alpha: .08),
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          // Scales down (never up) so narrow rail tiles and large text
          // can't overflow the tile.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (glyph)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: CustomPaint(
                      size: Size(18, 12),
                      painter: _MeterPainter(),
                    ),
                  ),
                if (label case final text?)
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                if (subLabel case final sub?) ...[
                  const SizedBox(width: 3),
                  Text(
                    sub,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(1, 1, size.width - 2, (size.height - 1) * 2);
    canvas.drawArc(rect, 3.14159, 3.14159, false, paint);
    canvas.drawLine(Offset(size.width / 2, size.height),
        Offset(size.width * .78, 2), paint);
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) => false;
}

/// Small uppercase heading used by every workspace panel.
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(title.toUpperCase(), style: workspacePanelTitle),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Panel title style shared by the workspace regions.
const TextStyle workspacePanelTitle = TextStyle(
  color: QubitQuestColors.accentInteractive,
  fontSize: 11.5,
  fontWeight: FontWeight.w800,
  letterSpacing: 1.1,
);

class _IconAction extends StatelessWidget {
  const _IconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: QubitQuestColors.textMuted,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        padding: EdgeInsets.zero,
      );
}
