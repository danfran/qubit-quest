import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_workspace_toolbar.dart';
import 'package:quantumquiz/widgets/composer_workspace/resizable_split.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';

/// Arrangement chosen from the workspace's *own* width (never the browser
/// width), so collapsing the app navigation directly buys a better tier.
enum ComposerWorkspaceTier {
  /// Palette, canvas and results at their preferred widths.
  wide,

  /// Three columns with palette/results shrunk towards their minimums so
  /// the canvas keeps [ComposerWorkspaceGeometry.minCanvasWidth].
  compact,

  /// Palette rail plus a Circuit/Results switch.
  medium,

  /// Stacked regions in one scrolling column.
  narrow,
}

/// Resolved panel sizes for one frame. Derived from preferences and space;
/// never written back to preferences.
@immutable
class ComposerWorkspaceGeometry {
  const ComposerWorkspaceGeometry({
    required this.tier,
    required this.paletteWidth,
    required this.resultsWidth,
  });

  final ComposerWorkspaceTier tier;
  final double paletteWidth;
  final double resultsWidth;

  /// Outer padding on each side of the workspace body.
  static const double gutter = 8;

  /// Width of each resize gap between panels.
  static const double gap = 8;
  static const double paletteRailWidth = 56;
  static const double resultsRailWidth = 40;

  /// The canvas never gets less than this in a three-column layout. While
  /// it has this much, the learner's preferred panel widths are shown
  /// exactly, so a resize drag always tracks the pointer.
  static const double minCanvasWidth = 440;

  /// Below this workspace width regions stack.
  static const double narrowBelow = 640;

  static ComposerWorkspaceGeometry resolve(
    double width,
    WorkspaceLayoutPreferences prefs,
  ) {
    if (width < narrowBelow) {
      return const ComposerWorkspaceGeometry(
        tier: ComposerWorkspaceTier.narrow,
        paletteWidth: 0,
        resultsWidth: 0,
      );
    }
    const chrome = gutter * 2 + gap * 2;
    final paletteMin = prefs.paletteCollapsed
        ? paletteRailWidth
        : WorkspaceLayoutPreferences.minPaletteWidth;
    final resultsMin = prefs.resultsCollapsed
        ? resultsRailWidth
        : WorkspaceLayoutPreferences.minResultsWidth;
    var palette =
        prefs.paletteCollapsed ? paletteRailWidth : prefs.paletteWidth;
    var results =
        prefs.resultsCollapsed ? resultsRailWidth : prefs.resultsWidth;
    var canvas = width - chrome - palette - results;
    if (canvas >= minCanvasWidth) {
      return ComposerWorkspaceGeometry(
        tier: ComposerWorkspaceTier.wide,
        paletteWidth: palette,
        resultsWidth: results,
      );
    }
    // Shrink both side panels in proportion to their slack.
    final need = minCanvasWidth - canvas;
    final slack = (palette - paletteMin) + (results - resultsMin);
    if (slack > 0) {
      final take = math.min(need, slack);
      palette -= take * (palette - paletteMin) / slack;
      results -= take * (results - resultsMin) / slack;
      canvas = width - chrome - palette - results;
    }
    if (canvas >= minCanvasWidth - 0.5) {
      return ComposerWorkspaceGeometry(
        tier: ComposerWorkspaceTier.compact,
        paletteWidth: palette,
        resultsWidth: results,
      );
    }
    return const ComposerWorkspaceGeometry(
      tier: ComposerWorkspaceTier.medium,
      paletteWidth: paletteRailWidth,
      resultsWidth: 0,
    );
  }

  /// Smallest workspace width that still shows three columns with expanded
  /// palette and results (908 px with the default minimums).
  static double get minimumThreeColumnWidth =>
      gutter * 2 +
      gap * 2 +
      WorkspaceLayoutPreferences.minPaletteWidth +
      WorkspaceLayoutPreferences.minResultsWidth +
      minCanvasWidth;
}

/// Undo: Ctrl/⌘+Z. Redo: Ctrl/⌘+Shift+Z or Ctrl+Y. Ignored while a text
/// field has focus (it keeps its own text undo), while a dialog or menu
/// covers the workspace, and while the Composer is not visible ([enabled]).
/// Returns true when the key was handled, so each press runs exactly one
/// command. Shared by every Composer layout.
bool handleComposerHistoryShortcut(
  BuildContext context,
  KeyEvent event, {
  required bool enabled,
  required VoidCallback onUndo,
  required VoidCallback onRedo,
}) {
  if (event is! KeyDownEvent || !enabled) return false;
  final keyboard = HardwareKeyboard.instance;
  final command = keyboard.isMetaPressed || keyboard.isControlPressed;
  if (!command || keyboard.isAltPressed) return false;
  final key = event.logicalKey;
  final undo = key == LogicalKeyboardKey.keyZ && !keyboard.isShiftPressed;
  final redo = (key == LogicalKeyboardKey.keyZ && keyboard.isShiftPressed) ||
      (key == LogicalKeyboardKey.keyY && keyboard.isControlPressed);
  if (!undo && !redo) return false;
  if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
  if (textInputHasFocus()) return false;
  undo ? onUndo() : onRedo();
  return true;
}

/// Whether an editable text field currently has keyboard focus.
bool textInputHasFocus() {
  final focused = FocusManager.instance.primaryFocus?.context;
  return focused != null &&
      (focused.widget is EditableText ||
          focused.findAncestorWidgetOfExactType<EditableText>() != null);
}

typedef WorkspaceToolbarBuilder = Widget Function({
  required bool compact,
  required List<WorkspacePanelToggle> toggles,
  required VoidCallback? onResetLayout,
  required ComposerWorkspaceView? view,
  required ValueChanged<ComposerWorkspaceView>? onViewChanged,
});

typedef WorkspaceCollapsibleBuilder = Widget Function(
  bool collapsed,
  VoidCallback? onToggleCollapsed,
);

/// Builds the gate inspector. [onToggleExpanded] is null where expanded
/// mode is unavailable (stacked layout).
typedef WorkspaceInspectorBuilder = Widget Function(
  bool collapsed,
  VoidCallback? onToggleCollapsed,
  bool expanded,
  VoidCallback? onToggleExpanded,
);

/// Desktop Composer composition: toolbar, categorised palette, circuit
/// canvas with the gate inspector below it, and an independent results
/// column. Presentation only. It owns layout and keyboard routing; every
/// circuit change goes through the host's session commands.
class DesktopComposerWorkspace extends StatefulWidget {
  const DesktopComposerWorkspace({
    super.key,
    required this.layout,
    required this.toolbar,
    required this.palette,
    required this.narrowPalette,
    required this.canvas,
    required this.canvasMinHeight,
    required this.inspector,
    required this.results,
    required this.onUndo,
    required this.onRedo,
    required this.shortcutsEnabled,
    this.inspectorIdle = false,
  });

  /// True when the inspector only shows its empty state; it then takes just
  /// the height it needs instead of the preferred height.
  final bool inspectorIdle;

  final WorkspaceLayoutController layout;
  final WorkspaceToolbarBuilder toolbar;
  final WorkspaceCollapsibleBuilder palette;

  /// Horizontal palette strip used when regions stack.
  final WidgetBuilder narrowPalette;
  final WidgetBuilder canvas;

  /// Height the circuit region needs to show the whole drawing (scaled
  /// drawing plus its header and footer). The canvas scrolls vertically
  /// when it gets less.
  final double canvasMinHeight;
  final WorkspaceInspectorBuilder inspector;
  final WorkspaceCollapsibleBuilder results;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  /// False while this workspace is not the visible destination.
  final bool shortcutsEnabled;

  static const double _minHeight = 520;

  @override
  State<DesktopComposerWorkspace> createState() =>
      _DesktopComposerWorkspaceState();
}

class _DesktopComposerWorkspaceState extends State<DesktopComposerWorkspace> {
  ComposerWorkspaceView _view = ComposerWorkspaceView.circuit;

  /// Expanded inspector mode. Transient (not persisted): it is a reading
  /// mode, not a layout preference.
  bool _inspectorExpanded = false;

  /// True during an inspector resize drag: height changes then follow the
  /// pointer directly instead of animating.
  bool _resizingInspector = false;

  /// Circuit height kept visible while the inspector is expanded.
  static const double _expandedCircuitPeek = 190;

  static const double _idleInspectorHeight = 112;

  /// Displayed size of the panel being resized, captured at drag start.
  double _dragBase = 0;

  WorkspaceLayoutController get _layout => widget.layout;
  WorkspaceLayoutPreferences get _prefs => _layout.preferences;

  @override
  void initState() {
    super.initState();
    _layout.addListener(_layoutChanged);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void didUpdateWidget(covariant DesktopComposerWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.layout, widget.layout)) {
      oldWidget.layout.removeListener(_layoutChanged);
      widget.layout.addListener(_layoutChanged);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _layout.removeListener(_layoutChanged);
    super.dispose();
  }

  void _layoutChanged() {
    if (mounted) setState(() {});
  }

  bool _handleKey(KeyEvent event) =>
      mounted &&
      handleComposerHistoryShortcut(
        context,
        event,
        enabled: widget.shortcutsEnabled,
        onUndo: widget.onUndo,
        onRedo: widget.onRedo,
      );

  void _toggle({bool? palette, bool? inspector, bool? results}) =>
      _layout.commit(_prefs.copyWith(
        paletteCollapsed: palette,
        inspectorCollapsed: inspector,
        resultsCollapsed: results,
      ));

  List<WorkspacePanelToggle> _toggles(ComposerWorkspaceTier tier) => [
        if (tier == ComposerWorkspaceTier.wide ||
            tier == ComposerWorkspaceTier.compact)
          WorkspacePanelToggle(
            id: 'palette',
            label: 'gate palette',
            icon: Icons.view_sidebar_outlined,
            visible: !_prefs.paletteCollapsed,
            onPressed: () => _toggle(palette: !_prefs.paletteCollapsed),
          ),
        WorkspacePanelToggle(
          id: 'inspector',
          label: 'gate inspector',
          icon: Icons.vertical_split_outlined,
          visible: !_prefs.inspectorCollapsed,
          onPressed: () => _toggle(inspector: !_prefs.inspectorCollapsed),
        ),
        if (tier == ComposerWorkspaceTier.wide ||
            tier == ComposerWorkspaceTier.compact)
          WorkspacePanelToggle(
            id: 'results',
            label: 'results',
            icon: Icons.analytics_outlined,
            visible: !_prefs.resultsCollapsed,
            onPressed: () => _toggle(results: !_prefs.resultsCollapsed),
          ),
        WorkspacePanelToggle(
          id: 'focus',
          label: 'side panels (focus the circuit)',
          icon: Icons.fit_screen_outlined,
          visible: !(_prefs.paletteCollapsed &&
              _prefs.resultsCollapsed &&
              _prefs.inspectorCollapsed),
          onPressed: () {
            final focus = !(_prefs.paletteCollapsed &&
                _prefs.resultsCollapsed &&
                _prefs.inspectorCollapsed);
            _toggle(palette: focus, inspector: focus, results: focus);
          },
        ),
      ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final geometry =
              ComposerWorkspaceGeometry.resolve(constraints.maxWidth, _prefs);
          final tier = geometry.tier;
          final toolbar = widget.toolbar(
            compact: tier == ComposerWorkspaceTier.narrow,
            toggles: tier == ComposerWorkspaceTier.narrow
                ? const []
                : _toggles(tier),
            onResetLayout: tier == ComposerWorkspaceTier.narrow
                ? null
                : _layout.resetWorkspace,
            view: tier == ComposerWorkspaceTier.medium ? _view : null,
            onViewChanged: tier == ComposerWorkspaceTier.medium
                ? (view) => setState(() => _view = view)
                : null,
          );
          if (tier == ComposerWorkspaceTier.narrow) {
            return _narrow(toolbar);
          }
          Widget body(double height) => Column(
                children: [
                  toolbar,
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(
                          ComposerWorkspaceGeometry.gutter),
                      child: tier == ComposerWorkspaceTier.medium
                          ? _medium()
                          : _threeColumns(geometry),
                    ),
                  ),
                ],
              );
          final tall =
              constraints.maxHeight >= DesktopComposerWorkspace._minHeight;
          return KeyedSubtree(
            key: ValueKey('composer-workspace-${tier.name}'),
            child: tall
                ? body(constraints.maxHeight)
                : SingleChildScrollView(
                    child: SizedBox(
                      height: DesktopComposerWorkspace._minHeight,
                      child: body(DesktopComposerWorkspace._minHeight),
                    ),
                  ),
          );
        },
      );

  Widget _panel({required Key key, required Widget child, Color? color}) =>
      DecoratedBox(
        key: key,
        decoration: BoxDecoration(
          color: color ?? QubitQuestColors.surface,
          borderRadius: QubitQuestRadii.card,
          border: Border.all(color: QubitQuestColors.borderSoft),
        ),
        child: ClipRRect(borderRadius: QubitQuestRadii.card, child: child),
      );

  Widget _threeColumns(ComposerWorkspaceGeometry g) {
    final palette = _panel(
      key: const ValueKey('composer-region-palette'),
      child: widget.palette(
        _prefs.paletteCollapsed,
        () => _toggle(palette: !_prefs.paletteCollapsed),
      ),
    );
    final results = _panel(
      key: const ValueKey('composer-region-results'),
      child: widget.results(
        _prefs.resultsCollapsed,
        () => _toggle(results: !_prefs.resultsCollapsed),
      ),
    );
    return Row(
      key: const ValueKey('composer-workspace-columns'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: g.paletteWidth, child: palette),
        _prefs.paletteCollapsed
            ? const SizedBox(width: ComposerWorkspaceGeometry.gap)
            : ResizeHandle(
                key: const ValueKey('composer-resize-palette'),
                axis: Axis.horizontal,
                semanticLabel: 'Resize gate palette',
                thickness: ComposerWorkspaceGeometry.gap,
                onDragStart: () => _dragBase = g.paletteWidth,
                onDrag: (dx) => _layout
                    .preview(_prefs.copyWith(paletteWidth: _dragBase + dx)),
                onDragEnd: _layout.commit,
                onReset: () => _layout.commit(_prefs.copyWith(
                    paletteWidth:
                        WorkspaceLayoutPreferences.defaultPaletteWidth)),
              ),
        Expanded(child: _centre()),
        _prefs.resultsCollapsed
            ? const SizedBox(width: ComposerWorkspaceGeometry.gap)
            : ResizeHandle(
                key: const ValueKey('composer-resize-results'),
                axis: Axis.horizontal,
                semanticLabel: 'Resize results panel',
                thickness: ComposerWorkspaceGeometry.gap,
                onDragStart: () => _dragBase = g.resultsWidth,
                onDrag: (dx) => _layout
                    .preview(_prefs.copyWith(resultsWidth: _dragBase - dx)),
                onDragEnd: _layout.commit,
                onReset: () => _layout.commit(_prefs.copyWith(
                    resultsWidth:
                        WorkspaceLayoutPreferences.defaultResultsWidth)),
              ),
        SizedBox(width: g.resultsWidth, child: results),
      ],
    );
  }

  Widget _medium() => Row(
        key: const ValueKey('composer-workspace-columns'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: ComposerWorkspaceGeometry.paletteRailWidth,
            child: _panel(
              key: const ValueKey('composer-region-palette'),
              child: widget.palette(true, null),
            ),
          ),
          const SizedBox(width: ComposerWorkspaceGeometry.gap),
          Expanded(
            // Both regions stay mounted so switching never rebuilds the
            // canvas or loses result scroll state.
            child: IndexedStack(
              index: _view == ComposerWorkspaceView.circuit ? 0 : 1,
              sizing: StackFit.expand,
              children: [
                _centre(),
                _panel(
                  key: const ValueKey('composer-region-results'),
                  child: widget.results(false, null),
                ),
              ],
            ),
          ),
        ],
      );

  /// Centre column: circuit above, inspector below.
  ///
  /// Vertical space policy (M3.1):
  /// * The circuit region is never taller than its content
  ///   ([DesktopComposerWorkspace.canvasMinHeight]) while an inspector is
  ///   showing a subject; the inspector takes the remaining height, so
  ///   the circuit stays at the top and no dead band opens between the last
  ///   wire and the circuit footer.
  /// * The learner's preferred inspector height still applies when it is
  ///   larger (dragging the handle up), and when the circuit needs more room
  ///   than is left (dense or scaled circuits).
  /// * With nothing selected the inspector stays compact.
  /// * Expanded mode gives the inspector everything except a
  ///   [_expandedCircuitPeek] strip of circuit.
  Widget _centre() => LayoutBuilder(
        builder: (context, constraints) {
          const collapsedInspector = 44.0;
          const gap = ComposerWorkspaceGeometry.gap;
          final height = constraints.maxHeight;
          // v2.6 M9: the whole circuit stays visible whenever the inspector
          // can still have its minimum height (it scrolls). A fixed 260 px
          // cap used to hide the last wires of 4- and 5-qubit circuits.
          final canvasNeed = math.min(
              widget.canvasMinHeight,
              math.max(
                  0.0,
                  height -
                      WorkspaceLayoutPreferences.minInspectorHeight -
                      gap));
          final maxInspector = math.max(
            WorkspaceLayoutPreferences.minInspectorHeight,
            height - canvasNeed - gap,
          );
          final expanded = _inspectorExpanded &&
              !_prefs.inspectorCollapsed &&
              !widget.inspectorIdle;
          final double inspectorHeight;
          if (_prefs.inspectorCollapsed) {
            inspectorHeight = collapsedInspector;
          } else if (widget.inspectorIdle) {
            inspectorHeight = _idleInspectorHeight;
          } else if (expanded) {
            inspectorHeight = math.max(
              WorkspaceLayoutPreferences.minInspectorHeight,
              height -
                  math.min(widget.canvasMinHeight, _expandedCircuitPeek) -
                  gap,
            );
          } else {
            final fill = height - widget.canvasMinHeight - gap;
            final preferred = math.min(_prefs.inspectorHeight, height * .6);
            inspectorHeight = fitWithin(
              math.max(preferred, fill),
              WorkspaceLayoutPreferences.minInspectorHeight,
              maxInspector,
            );
          }
          return Column(
            key: const ValueKey('composer-region-centre'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _panel(
                  key: const ValueKey('composer-region-canvas'),
                  color: QubitQuestColors.surfaceInset,
                  child: widget.canvas(context),
                ),
              ),
              _prefs.inspectorCollapsed || widget.inspectorIdle || expanded
                  ? const SizedBox(height: gap)
                  : ResizeHandle(
                      key: const ValueKey('composer-resize-inspector'),
                      axis: Axis.vertical,
                      semanticLabel: 'Resize gate inspector',
                      thickness: gap,
                      onDragStart: () {
                        _dragBase = inspectorHeight;
                        _resizingInspector = true;
                      },
                      onDrag: (dy) => _layout.preview(
                          _prefs.copyWith(inspectorHeight: _dragBase - dy)),
                      onDragEnd: () {
                        _resizingInspector = false;
                        _layout.commit();
                      },
                      onReset: () => _layout.commit(_prefs.copyWith(
                          inspectorHeight: WorkspaceLayoutPreferences
                              .defaultInspectorHeight)),
                    ),
              // The height animates, but never beyond the space the column
              // has now: when the available height drops suddenly (a window
              // resize, or an exercise footer growing), the animation starts
              // from the old, larger value and would otherwise overflow.
              ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: math.max(0.0, height - gap)),
                child: AnimatedContainer(
                  duration: _resizingInspector
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  height: inspectorHeight,
                  child: _panel(
                    key: const ValueKey('composer-region-inspector'),
                    child: widget.inspector(
                      _prefs.inspectorCollapsed,
                      () => _toggle(inspector: !_prefs.inspectorCollapsed),
                      expanded,
                      widget.inspectorIdle || _prefs.inspectorCollapsed
                          ? null
                          : () => setState(
                              () => _inspectorExpanded = !_inspectorExpanded),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

  // A Column (not a lazy ListView) keeps every region mounted, so the
  // results tab, run state and inspector drafts survive scrolling.
  Widget _narrow(Widget toolbar) => SingleChildScrollView(
        key: const ValueKey('composer-workspace-narrow'),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            toolbar,
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: widget.narrowPalette(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: SizedBox(
                // Header and footer text grow with the text scale.
                height: widget.canvasMinHeight +
                    MediaQuery.textScalerOf(context).scale(48) +
                    24,
                child: _panel(
                  key: const ValueKey('composer-region-canvas'),
                  color: QubitQuestColors.surfaceInset,
                  child: widget.canvas(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: SizedBox(
                height: _prefs.inspectorCollapsed ? 44 : 320,
                child: _panel(
                  key: const ValueKey('composer-region-inspector'),
                  child: widget.inspector(
                    _prefs.inspectorCollapsed,
                    () => _toggle(inspector: !_prefs.inspectorCollapsed),
                    false,
                    null,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: SizedBox(
                height: 560,
                child: _panel(
                  key: const ValueKey('composer-region-results'),
                  child: widget.results(false, null),
                ),
              ),
            ),
          ],
        ),
      );
}
