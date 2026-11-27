import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/composer_workspace/desktop_composer_workspace.dart'
    show handleComposerHistoryShortcut, textInputHasFocus;

/// Where the contextual inspector is placed for a host width.
enum LaboratoryInspectorPlacement {
  /// A column beside the circuit and analysis; nothing is covered.
  docked,

  /// A panel floating over the right edge of the workspace.
  overlay,

  /// A bottom sheet (phones).
  sheet;

  static LaboratoryInspectorPlacement forWidth(double width) =>
      width >= LaboratoryComposerWorkspace.dockInspectorFrom
          ? docked
          : width >= LaboratoryComposerWorkspace.sheetBelow
              ? overlay
              : sheet;
}

/// The laboratory Composer layout (v2.6 M11C; M11B prototypes 1–4).
///
/// From top to bottom: the workspace header, a horizontal categorised gate
/// palette, a circuit well sized to the register, and the analysis
/// workspace under it. The gate inspector exists only while [inspector] is
/// non-null and sits on the right (docked, overlay or sheet by width).
///
/// *Analysis* and *Focus circuit* ([focusCircuit]) are two arrangements of
/// the same widgets: the canvas and the analysis keep their state across a
/// switch (they are reparented, never rebuilt from scratch), and the session
/// is never touched. Presentation only, like [DesktopComposerWorkspace].
class LaboratoryComposerWorkspace extends StatefulWidget {
  const LaboratoryComposerWorkspace({
    super.key,
    required this.header,
    required this.palette,
    required this.narrowPalette,
    required this.canvas,
    required this.canvasHeight,
    required this.analysis,
    required this.inspector,
    required this.focusCircuit,
    required this.onCloseInspector,
    required this.onUndo,
    required this.onRedo,
    required this.shortcutsEnabled,
    this.naturalCanvasHeight = false,
    this.alignStart = false,
    this.intro,
  });

  /// Learning layout (v2.6 M11D.1): the circuit well always takes the
  /// height the drawing needs and the page scrolls, instead of capping the
  /// well (and scrolling the circuit inside it) to keep analysis above the
  /// fold. Every wire stays reachable without a nested vertical scroll.
  final bool naturalCanvasHeight;

  /// Content starts at the left edge of its maximum width rather than being
  /// centred, so it lines up with a left-aligned task header and actions.
  final bool alignStart;

  /// Scrolls with the work area above the palette and circuit (narrow
  /// lesson headers), so the task does not take a fixed share of the
  /// viewport.
  final Widget? intro;

  /// Workspace header; `compact` on phone widths, where it wraps.
  final Widget Function({required bool compact}) header;

  /// Horizontal strip palette (600 px and wider).
  final WidgetBuilder palette;

  /// Touch-friendly palette used below [sheetBelow].
  final WidgetBuilder narrowPalette;
  final WidgetBuilder canvas;

  /// Height the circuit region needs to show the whole drawing with its
  /// header and footer. The well never grows beyond it in Analysis mode.
  final double canvasHeight;
  final WidgetBuilder analysis;

  /// Null closes the inspector.
  final WidgetBuilder? inspector;
  final bool focusCircuit;
  final VoidCallback onCloseInspector;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool shortcutsEnabled;

  /// Host width from which the inspector docks beside the workspace.
  static const double dockInspectorFrom = 1100;

  /// Host width below which the inspector is a bottom sheet.
  static const double sheetBelow = 600;

  /// Analysis content never stretches wider than this (ultrawide screens).
  static const double maxContentWidth = 1760;

  static double inspectorWidthFor(double width) => width >= 1500 ? 380 : 340;

  @override
  State<LaboratoryComposerWorkspace> createState() =>
      _LaboratoryComposerWorkspaceState();
}

class _LaboratoryComposerWorkspaceState
    extends State<LaboratoryComposerWorkspace> {
  final GlobalKey _canvasKey = GlobalKey(debugLabel: 'composer-lab-canvas');
  final GlobalKey _analysisKey = GlobalKey(debugLabel: 'composer-lab-analysis');
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _scroll.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (!mounted) return false;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        widget.shortcutsEnabled &&
        widget.inspector != null &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        !textInputHasFocus()) {
      widget.onCloseInspector();
      return true;
    }
    return handleComposerHistoryShortcut(
      context,
      event,
      enabled: widget.shortcutsEnabled,
      onUndo: widget.onUndo,
      onRedo: widget.onRedo,
    );
  }

  Widget _well(Widget child) => DecoratedBox(
        key: const ValueKey('composer-region-canvas'),
        decoration: BoxDecoration(
          color: QubitQuestSurfaces.inset,
          borderRadius: QubitQuestRadii.card,
          border: Border.all(color: QubitQuestSurfaces.rule),
        ),
        child: ClipRRect(borderRadius: QubitQuestRadii.card, child: child),
      );

  Widget _capped(Widget child) => Align(
        alignment: widget.alignStart ? Alignment.topLeft : Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: LaboratoryComposerWorkspace.maxContentWidth),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final phone = width < LaboratoryComposerWorkspace.sheetBelow;
          final placement = LaboratoryInspectorPlacement.forWidth(width);
          final side = phone ? 12.0 : 20.0;
          final canvas = KeyedSubtree(
            key: _canvasKey,
            child: widget.canvas(context),
          );
          final analysis = KeyedSubtree(
            key: _analysisKey,
            child: widget.analysis(context),
          );
          final inspectorBuilder = widget.inspector;
          final docked = inspectorBuilder != null &&
              placement == LaboratoryInspectorPlacement.docked;

          // The palette strip is fixed above the work area from 600 px;
          // phones, and very short work areas (a tall lesson header, large
          // text), scroll it with the circuit so nothing overflows.
          final shortArea = height.isFinite && height < 380;
          final palette = phone || shortArea || widget.intro != null
              ? null
              : Container(
                  key: const ValueKey('composer-region-palette'),
                  width: double.infinity,
                  color: QubitQuestSurfaces.work2,
                  padding: EdgeInsets.fromLTRB(side, 10, side, 12),
                  child: _capped(SizedBox(
                    width: double.infinity,
                    child: widget.palette(context),
                  )),
                );

          final Widget body;
          if (widget.focusCircuit) {
            // Focus circuit: no analysis, and the well may use the whole
            // height (tall registers, 150% zoom, long circuits), but a short
            // circuit is never stretched: the well stays content-sized.
            final available = height.isFinite ? height - 28 : 900.0;
            body = Padding(
              key: const ValueKey('composer-lab-focus'),
              padding: EdgeInsets.fromLTRB(side, 14, side, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (phone) ...[
                    widget.narrowPalette(context),
                    const SizedBox(height: 10),
                  ],
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(
                            160.0, math.min(widget.canvasHeight, available)),
                      ),
                      child: _well(canvas),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Analysis is hidden while you focus on the circuit. The '
                    'state and results keep updating; choose Analysis to see '
                    'them.',
                    key: const ValueKey('composer-lab-focus-note'),
                    style:
                        QubitQuestTypography.supporting.copyWith(fontSize: 12),
                  ),
                  // Kept mounted (not painted) so results, filters and the
                  // Bloch camera survive the switch back to Analysis.
                  Offstage(child: TickerMode(enabled: false, child: analysis)),
                ],
              ),
            );
          } else {
            // Content-sized well: a one-qubit circuit stays a short strip
            // and the analysis gets the space; tall registers are capped
            // so the analysis always starts on screen, and the canvas
            // scrolls inside the well.
            final wellHeight = widget.naturalCanvasHeight
                ? widget.canvasHeight
                : math.min(
                    widget.canvasHeight,
                    math.max(220.0, (height.isFinite ? height : 900) * .62),
                  );
            body = Scrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                key: const ValueKey('composer-lab-scroll'),
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(
                  side,
                  14,
                  side,
                  placement == LaboratoryInspectorPlacement.sheet &&
                          inspectorBuilder != null
                      ? height * .55
                      : 28,
                ),
                child: _capped(Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.intro case final intro?) ...[
                      intro,
                      const SizedBox(height: 12),
                    ],
                    if (phone) ...[
                      widget.narrowPalette(context),
                      const SizedBox(height: 10),
                    ] else if (shortArea || widget.intro != null) ...[
                      widget.palette(context),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(height: wellHeight, child: _well(canvas)),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: const ValueKey('composer-region-results'),
                      child: analysis,
                    ),
                  ],
                )),
              ),
            );
          }

          Widget work = docked
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: body),
                    _inspectorFrame(
                      inspectorBuilder(context),
                      width:
                          LaboratoryComposerWorkspace.inspectorWidthFor(width),
                      placement: placement,
                    ),
                  ],
                )
              : body;
          if (inspectorBuilder != null && !docked) {
            work = Stack(
              children: [
                Positioned.fill(child: work),
                if (placement == LaboratoryInspectorPlacement.overlay)
                  Positioned(
                    top: 8,
                    right: 8,
                    bottom: 8,
                    width: math.min(380.0, width - 48),
                    child: _inspectorFrame(inspectorBuilder(context),
                        placement: placement),
                  )
                else
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: math.min(height * .6, 480),
                    child: _inspectorFrame(inspectorBuilder(context),
                        placement: placement),
                  ),
              ],
            );
          }
          return ColoredBox(
            key: ValueKey('composer-workspace-laboratory-'
                '${widget.focusCircuit ? 'focus' : 'analysis'}'),
            color: QubitQuestSurfaces.app,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget.header(compact: width < 900),
                if (palette != null) palette,
                Expanded(child: work),
              ],
            ),
          );
        },
      );

  Widget _inspectorFrame(
    Widget child, {
    required LaboratoryInspectorPlacement placement,
    double? width,
  }) {
    final decoration = switch (placement) {
      LaboratoryInspectorPlacement.docked => const BoxDecoration(
          color: QubitQuestSurfaces.inspector,
          border: Border(left: BorderSide(color: QubitQuestColors.border)),
        ),
      LaboratoryInspectorPlacement.overlay => BoxDecoration(
          color: QubitQuestSurfaces.inspector,
          borderRadius: QubitQuestRadii.callout,
          border: Border.all(color: QubitQuestColors.border),
          boxShadow: const [QubitQuestBorders.topLevelShadow],
        ),
      LaboratoryInspectorPlacement.sheet => const BoxDecoration(
          color: QubitQuestSurfaces.inspector,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(top: BorderSide(color: QubitQuestColors.border)),
          boxShadow: [QubitQuestBorders.topLevelShadow],
        ),
    };
    return Container(
      key: const ValueKey('composer-region-inspector'),
      width: width,
      decoration: decoration,
      clipBehavior: placement == LaboratoryInspectorPlacement.docked
          ? Clip.none
          : Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (placement == LaboratoryInspectorPlacement.sheet)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: QubitQuestColors.textMuted.withValues(alpha: .5),
                    borderRadius: QubitQuestRadii.pill,
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
