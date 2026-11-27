// Web Bloch Explorer: an interactive single-qubit state laboratory (v2.6 M8).
//
// The Composer answers "what does this circuit do?"; this workspace answers
// "how and why does this state change?". All state comes from
// [BlochLabSession] (simulator matrices); the sphere, amplitudes,
// coordinates and probabilities always describe the same displayed state.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/bloch_lab.dart';
import 'package:quantumquiz/models/canonical_qubit_state.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/complex_amplitude_plane.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

const _surface = Color(0xFF0B1324);
const _border = Color(0x66344A73);
const _muted = QubitQuestDialog.mutedText;
const _cyan = QubitQuestDialog.cyan;
const _alphaColor = Color(0xFF4FD8FF);
const _betaColor = Color(0xFFC08BFF);

/// Guided comparisons for global and relative phase (§12 of the brief).
List<BlochLabSeed> blochPhaseComparisons() => [
      BlochLabSeed(
        origin: BlochLabOrigin.comparison,
        title: 'Global phase: |0⟩ and −|0⟩',
        initial: BlochState.zero,
        initialLabel: '|0⟩',
        gates: [
          blochLabGate(SelectedGateType.x),
          blochLabGate(SelectedGateType.z),
          blochLabGate(SelectedGateType.x),
        ],
        note: 'X, Z, X turns |0⟩ into −|0⟩. Step through: the vector returns '
            'to the same point on the sphere, but α changes sign in the '
            'complex plane. A global phase cannot be detected by measuring '
            'this qubit on its own.',
        sourceId: 'global-phase',
      ),
      BlochLabSeed(
        origin: BlochLabOrigin.comparison,
        title: 'Rz(2π): a full turn flips the sign',
        initial: CanonicalQubitState.plus.blochState,
        initialLabel: '|+⟩',
        gates: [blochLabGate(SelectedGateType.rz, angle: 2 * math.pi)],
        note: 'Rz(2π) = −I: the vector goes once around the Z axis and '
            'returns to |+⟩ on the sphere, while the state vector becomes '
            '−|+⟩ (both amplitudes change sign). Same physical state.',
        sourceId: 'rz-2pi',
      ),
      BlochLabSeed(
        origin: BlochLabOrigin.comparison,
        title: 'Relative phase: |+⟩ and |−⟩',
        initial: CanonicalQubitState.plus.blochState,
        initialLabel: '|+⟩',
        gates: [blochLabGate(SelectedGateType.z)],
        note: 'Z turns |+⟩ into |−⟩: opposite points on the sphere, yet the '
            'Z-basis probabilities are both 50/50. Measure in the X basis to '
            'tell them apart.',
        sourceId: 'plus-minus',
      ),
      BlochLabSeed(
        origin: BlochLabOrigin.comparison,
        title: 'Relative phase: |+⟩ and |+i⟩',
        initial: CanonicalQubitState.plus.blochState,
        initialLabel: '|+⟩',
        gates: [blochLabGate(SelectedGateType.s)],
        note: 'S turns |+⟩ into |+i⟩: a quarter turn around Z. Z-basis '
            'probabilities stay 50/50; the relative phase changes from 0 '
            'to π/2, which the Y basis reveals.',
        sourceId: 'plus-plus-i',
      ),
    ];

class WebBlochWorkspace extends StatefulWidget {
  const WebBlochWorkspace({
    super.key,
    required this.standalone,
    this.exploration,
    this.onReturnFromExploration,
    this.onCloseExploration,
    this.onStartComparison,
    this.onOpenNotebookEntry,
  });

  /// The learner's own laboratory (kept by the shell across destinations).
  final BlochLabSession standalone;

  /// An isolated exploration (Notebook, Composer or comparison), shown
  /// instead of [standalone] while present; it never modifies it.
  final BlochLabSession? exploration;
  final VoidCallback? onReturnFromExploration;
  final VoidCallback? onCloseExploration;
  final ValueChanged<BlochLabSeed>? onStartComparison;
  final ValueChanged<String>? onOpenNotebookEntry;

  @override
  State<WebBlochWorkspace> createState() => WebBlochWorkspaceState();
}

enum _SideTab { prepare, gates, state, measure }

@visibleForTesting
class WebBlochWorkspaceState extends State<WebBlochWorkspace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  BlochLabStep? _animating;

  BlochCamera _camera = const BlochCamera(zoom: 1.05);
  SelectedGateType? _selected;
  double _angle = math.pi / 2;
  bool _animate = true;
  bool _dragState = false;
  bool _customOpen = false;
  double _customTheta = math.pi / 3;
  double _customPhi = math.pi / 4;
  BlochBasis _basis = BlochBasis.z;
  BlochSingleMeasurement? _single;
  BlochShotsMeasurement? _shots;
  int _shotCount = 1000;
  final BlochMeasurer _measurer = BlochMeasurer();
  _SideTab _tab = _SideTab.gates;
  _SideTab _wideRightTab = _SideTab.state;
  _SideTab _wideLeftTab = _SideTab.gates;
  BlochState? _dragPreview;

  BlochLabSession get session => widget.exploration ?? widget.standalone;
  SelectedGateType? get selectedGate => _selected;
  BlochCamera get camera => _camera;

  @override
  void initState() {
    super.initState();
    // Created eagerly: a lazy controller would be first built in dispose().
    _motion = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750))
      ..addListener(() => setState(() {}));
    widget.standalone.addListener(_changed);
    widget.exploration?.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant WebBlochWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.exploration, widget.exploration)) {
      oldWidget.exploration?.removeListener(_changed);
      widget.exploration?.addListener(_changed);
      _resetTransient();
    }
  }

  @override
  void dispose() {
    widget.standalone.removeListener(_changed);
    widget.exploration?.removeListener(_changed);
    _motion.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      // Measurement results belong to the state they were taken from.
      _single = null;
      _shots = null;
    });
  }

  void _resetTransient() {
    _motion.stop();
    _animating = null;
    _selected = null;
    _single = null;
    _shots = null;
    _customOpen = false;
    _dragPreview = null;
  }

  // ------------------------------------------------------------- actions

  void selectGate(SelectedGateType? type) => setState(() {
        _selected = _selected == type ? null : type;
        _customOpen = false;
        _wideLeftTab = _SideTab.gates;
      });

  void setAngle(double angle) => setState(() => _angle = angle);

  /// Applies the previewed gate: exactly one history step.
  void applySelected() {
    final type = _selected;
    if (type == null || session.isInspecting) return;
    final step =
        session.commit(type, angle: blochLabIsRotation(type) ? _angle : null);
    if (step == null) return;
    setState(() => _selected = null);
    if (_animate) {
      _animating = step;
      unawaited(_motion.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _animating = null);
      }));
    }
  }

  void _prepare(BlochState state, String label) {
    _motion.stop();
    _animating = null;
    session.prepare(state, label);
    setState(() {
      _selected = null;
      _customOpen = false;
    });
  }

  void _measureOnce() =>
      setState(() => _single = _measurer.once(session.displayed, _basis));

  void _measureShots() => setState(
      () => _shots = _measurer.shots(session.displayed, _basis, _shotCount));

  Future<void> _aboutGate(SelectedGateType type) async {
    final info = GateEducationalCatalog.forType(type);
    final title = info?.notebookDiscoveryTitle;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => GateInspectorDialog.forGate(
        gate: blochLabGate(type, angle: _angle),
        info: info,
        onOpenNotebook: title == null || widget.onOpenNotebookEntry == null
            ? null
            : () {
                Navigator.of(dialogContext).pop();
                widget.onOpenNotebookEntry!(title);
              },
      ),
    );
  }

  // ------------------------------------------------------ sphere content

  /// The vector drawn on the sphere: animated, dragged, or the displayed
  /// state. Numbers elsewhere always use [BlochLabSession.displayed].
  BlochState get _sphereState {
    final step = _animating;
    if (step != null && _motion.isAnimating) {
      final (x, y, z) = step.rotation
          .apply(step.before.vector, Curves.easeInOut.transform(_motion.value));
      return BlochState.fromCartesian(x, y, z);
    }
    return _dragPreview ?? session.displayed;
  }

  BlochSphereOverlay get _overlay {
    final measuring = _visibleTabs.contains(_SideTab.measure);
    final basis = measuring ? _basis : null;
    if (_customOpen) {
      return BlochSphereOverlay(
        basisLabels: true,
        basis: basis,
        previewVector: _customState.vector,
      );
    }
    final type = _selected;
    if (type != null && !session.isInspecting) {
      final preview = session.preview(type,
          angle: blochLabIsRotation(type) ? _angle : null);
      return BlochSphereOverlay(
        basisLabels: true,
        basis: basis,
        startVector: preview.before.vector,
        previewVector: preview.after.vector,
        rotation: preview.rotation,
      );
    }
    final index = session.inspectedIndex ?? session.appliedCount;
    if (index > 0 && _dragPreview == null) {
      final step = session.allSteps[index - 1];
      return BlochSphereOverlay(
        basisLabels: true,
        basis: basis,
        startVector: step.before.vector,
        rotation: step.rotation,
      );
    }
    return BlochSphereOverlay(basisLabels: true, basis: basis);
  }

  BlochState get _customState =>
      BlochState.fromAngles(theta: _customTheta, phi: _customPhi);

  // ------------------------------------------------------------- layout

  // Which side tabs are on screen in the current layout (set during build).
  Set<_SideTab> _visibleTabs = {};
  bool _compactGates = false;
  _SideTab _narrowTab = _SideTab.state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final Widget body;
          _compactGates = false;
          if (width >= 1180 && constraints.maxHeight >= 560) {
            _visibleTabs = {_wideLeftTab, _wideRightTab};
            body = _wide(constraints);
          } else if (width >= 760 && constraints.maxHeight >= 520) {
            _visibleTabs = {_tab};
            body = _medium(constraints);
          } else {
            _compactGates = true;
            _visibleTabs = {_SideTab.gates, _narrowTab};
            body = _narrow(constraints);
          }
          return ColoredBox(
            color: const Color(0xFF050A14),
            child: body,
          );
        },
      );

  Widget _header({bool compact = false}) {
    final exploration = widget.exploration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Icon(Icons.language, color: _cyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bloch Explorer',
                    key: const ValueKey('web-bloch-title'),
                    style: TextStyle(
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const Text('How and why a single-qubit state changes',
                    style: TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
        ]),
        if (exploration != null) ...[
          const SizedBox(height: 10),
          _ExplorationBanner(
            seed: exploration.seed,
            compact: compact,
            onReturn: widget.onReturnFromExploration,
            onReset: exploration.reset,
            onClose: widget.onCloseExploration,
          ),
        ],
      ],
    );
  }

  Widget _wide(BoxConstraints c) => Padding(
        key: const ValueKey('web-bloch-wide-layout'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 300,
                    child: _Card(
                      key: const ValueKey('web-bloch-left'),
                      child: Column(children: [
                        _tabBar(
                            const [_SideTab.prepare, _SideTab.gates],
                            _wideLeftTab,
                            (t) => setState(() => _wideLeftTab = t)),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(14),
                            children: [_tabContent(_wideLeftTab)],
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _sphereColumn()),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 360,
                    child: _Card(
                      key: const ValueKey('web-bloch-right'),
                      child: Column(children: [
                        _tabBar(
                            const [_SideTab.state, _SideTab.measure],
                            _wideRightTab,
                            (t) => setState(() => _wideRightTab = t)),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(14),
                            children: [
                              _wideRightTab == _SideTab.state
                                  ? _stateSection()
                                  : _measureSection(),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _medium(BoxConstraints c) => Padding(
        key: const ValueKey('web-bloch-medium-layout'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _sphereColumn()),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: math.min(360, c.maxWidth * .42),
                    child: _Card(
                      key: const ValueKey('web-bloch-side'),
                      child: Column(children: [
                        _tabBar(_SideTab.values, _tab,
                            (t) => setState(() => _tab = t)),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: [_tabContent(_tab)],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// Narrow layout (v2.6 M9): the gate strip and its preview sit directly
  /// under the sphere, so a transformation can be previewed and applied
  /// without scrolling away from it; the remaining panels are tabs.
  Widget _narrow(BoxConstraints c) {
    final sphereHeight = math.min(c.maxWidth - 24, 380.0);
    return ListView(
      key: const ValueKey('web-bloch-stacked-layout'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _header(compact: true),
        const SizedBox(height: 10),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              SizedBox(height: sphereHeight, child: _sphere()),
              _legend(),
              const Divider(height: 18),
              KeyedSubtree(
                  key: const ValueKey('web-bloch-narrow-gates'),
                  child: _gateSection()),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        _Card(
            child: Padding(
                padding: const EdgeInsets.all(10), child: _evolution())),
        const SizedBox(height: 10),
        _Card(
          key: const ValueKey('web-bloch-side'),
          child: Column(children: [
            _tabBar(const [_SideTab.prepare, _SideTab.state, _SideTab.measure],
                _narrowTab, (t) => setState(() => _narrowTab = t)),
            Padding(
                padding: const EdgeInsets.all(12),
                child: _tabContent(_narrowTab)),
          ]),
        ),
      ],
    );
  }

  Widget _tabContent(_SideTab tab) => switch (tab) {
        _SideTab.prepare => _prepareSection(),
        _SideTab.gates => _gateSection(),
        _SideTab.state => _stateSection(),
        _SideTab.measure => _measureSection(),
      };

  Widget _tabBar(List<_SideTab> tabs, _SideTab selected,
          ValueChanged<_SideTab> onChanged) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: SegmentedButton<_SideTab>(
          key: const ValueKey('web-bloch-tabs'),
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            textStyle: const TextStyle(fontSize: 12.5),
          ),
          segments: [
            for (final t in tabs)
              ButtonSegment(
                value: t,
                label: Text(
                  switch (t) {
                    _SideTab.prepare => 'Prepare',
                    _SideTab.gates => 'Gates',
                    _SideTab.state => 'State',
                    _SideTab.measure => 'Measure',
                  },
                  key: ValueKey('web-bloch-tab-${t.name}'),
                ),
              ),
          ],
          selected: {selected},
          onSelectionChanged: (s) => onChanged(s.single),
        ),
      );

  Widget _sphereColumn() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  Expanded(child: _sphere()),
                  _legend(),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
              child: Padding(
                  padding: const EdgeInsets.all(12), child: _evolution())),
        ],
      );

  Widget _sphere() => Stack(children: [
        Positioned.fill(
          child: MouseRegion(
            cursor: _dragState
                ? SystemMouseCursors.precise
                : SystemMouseCursors.grab,
            child: BlochSpherePanel(
              key: const ValueKey('web-bloch-sphere'),
              showAnnotations: false,
              allowStateEditing: _dragState && !session.isInspecting,
              overlay: _overlay,
              state: _sphereState,
              camera: _camera,
              onCameraChanged: (camera) => setState(() => _camera = camera),
              onStatePreview: (state) => setState(() => _dragPreview = state),
              onStateCommitted: (state) {
                setState(() => _dragPreview = null);
                _prepare(state, 'Custom');
              },
              onGestureStarted: () {
                _motion.stop();
                _animating = null;
              },
              onStateGestureStarted: () => session.displayed,
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Row(children: [
            Tooltip(
              message: 'When on, dragging the vector tip prepares a new '
                  'state. When off, every drag only turns the view.',
              child: FilterChip(
                key: const ValueKey('bloch-drag-state-toggle'),
                label:
                    const Text('Drag vector', style: TextStyle(fontSize: 12)),
                selected: _dragState,
                visualDensity: VisualDensity.compact,
                onSelected: (v) => setState(() => _dragState = v),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              key: const ValueKey('bloch-reset-view'),
              tooltip: 'Reset view',
              icon: const Icon(Icons.center_focus_strong, size: 20),
              onPressed: () =>
                  setState(() => _camera = const BlochCamera(zoom: 1.05)),
            ),
          ]),
        ),
        Positioned(
          left: 6,
          bottom: 4,
          child: Text(
            _dragState
                ? 'Drag the vector tip to set a state · drag elsewhere to turn'
                : 'Drag to turn the view · the state never changes',
            key: const ValueKey('bloch-sphere-hint'),
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ),
      ]);

  Widget _legend() {
    final overlay = _overlay;
    Widget item(Color color, String text, {bool hollow = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: hollow ? null : color,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
            const SizedBox(width: 5),
            Text(text, style: const TextStyle(fontSize: 11.5, color: _muted)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        key: const ValueKey('bloch-legend'),
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 4,
        children: [
          item(BlochOverlayColors.current,
              session.isInspecting ? 'Inspected state' : 'Current state'),
          if (overlay.startVector != null)
            item(BlochOverlayColors.start, 'Input state', hollow: true),
          if (overlay.previewVector != null)
            item(BlochOverlayColors.preview,
                _customOpen ? 'Custom state (not yet prepared)' : 'Preview'),
          if (overlay.rotation != null)
            item(BlochOverlayColors.axis, _rotationCaption(overlay.rotation!)),
          if (overlay.basis != null)
            item(BlochOverlayColors.basis, '${overlay.basis!.label} basis'),
          if (_animating != null && _motion.isAnimating)
            const Text(
              'Animating the rotation · the numbers already show the result',
              key: ValueKey('bloch-animating-note'),
              style:
                  TextStyle(fontSize: 11.5, color: BlochOverlayColors.preview),
            ),
        ],
      ),
    );
  }

  String _rotationCaption(BlochRotation r) {
    final (x, y, z) = r.axis;
    final axis =
        (x - math.sqrt1_2).abs() < 1e-9 && (z - math.sqrt1_2).abs() < 1e-9
            ? '(X+Z)/√2'
            : x == 1
                ? 'X'
                : y == 1
                    ? 'Y'
                    : 'Z';
    return 'Rotation ${blochAngle(r.angle).split(' (').first} about $axis';
  }

  // ------------------------------------------------------------ sections

  Widget _prepareSection() {
    final current = CanonicalQubitState.matching(session.initial);
    return Column(
      key: const ValueKey('bloch-prepare'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Prepare a state'),
        const Text('Starting a new state clears the history.',
            style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final preset in CanonicalQubitState.values)
            ChoiceChip(
              key: ValueKey('bloch-prep-${preset.name}'),
              label: Text(preset.label),
              selected: current == preset &&
                  session.appliedCount == 0 &&
                  session.initialLabel == preset.label,
              onSelected: (_) => _prepare(preset.blochState, preset.label),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Expanded(
            child: Text('Custom θ, φ',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          Switch(
            key: const ValueKey('bloch-custom-toggle'),
            value: _customOpen,
            onChanged: (v) => setState(() {
              _customOpen = v;
              if (v) _selected = null;
            }),
          ),
        ]),
        if (_customOpen) _customEditor(),
        const SizedBox(height: 10),
        const _Heading('Phase comparisons'),
        for (final seed in blochPhaseComparisons())
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ValueKey('bloch-compare-${seed.sourceId}'),
              onPressed: widget.onStartComparison == null
                  ? null
                  : () => widget.onStartComparison!(seed),
              icon: const Icon(Icons.compare_arrows, size: 16),
              label: Text(seed.title, style: const TextStyle(fontSize: 12.5)),
            ),
          ),
      ],
    );
  }

  Widget _customEditor() {
    final pole = _customTheta < 1e-9 || (math.pi - _customTheta) < 1e-9;
    return Column(
      key: const ValueKey('bloch-custom-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('|ψ⟩ = cos(θ/2)|0⟩ + e^(iφ) sin(θ/2)|1⟩',
            style: TextStyle(color: _cyan, fontSize: 12.5)),
        _AngleControl(
          key: const ValueKey('bloch-custom-theta'),
          label: 'θ (polar, 0 to π)',
          value: _customTheta,
          min: 0,
          max: math.pi,
          presets: const [
            0,
            math.pi / 4,
            math.pi / 2,
            3 * math.pi / 4,
            math.pi
          ],
          onChanged: (v) => setState(() => _customTheta = v),
        ),
        _AngleControl(
          key: const ValueKey('bloch-custom-phi'),
          label: 'φ (azimuthal, 0 to 2π)',
          value: _customPhi,
          min: 0,
          max: 2 * math.pi,
          presets: const [0, math.pi / 2, math.pi, 3 * math.pi / 2],
          enabled: !pole,
          onChanged: (v) => setState(() => _customPhi = v % (2 * math.pi)),
        ),
        if (pole)
          const Text(
            'At a pole one amplitude is zero, so φ has no physical effect.',
            key: ValueKey('bloch-custom-pole-note'),
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        Text(blochStateExpression(_customState),
            style: const TextStyle(fontSize: 12.5)),
        const SizedBox(height: 6),
        FilledButton(
          key: const ValueKey('bloch-prep-custom-apply'),
          onPressed: () => _prepare(
              _customState,
              'θ=${blochAngle(_customTheta).split(' (').first}, '
              'φ=${blochAngle(_customPhi).split(' (').first}'),
          child: const Text('Prepare this state'),
        ),
      ],
    );
  }

  Widget _gateSection() {
    final selected = _selected;
    final inspecting = session.isInspecting;
    return Column(
      key: const ValueKey('bloch-gates'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Apply a gate'),
        const Text('Choose a gate to preview it, then apply it.',
            style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final type in blochLabGateTypes)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected == type && !inspecting
                      ? BlochOverlayColors.preview
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              // Dimmed and disabled while an earlier step is inspected.
              child: Opacity(
                opacity: inspecting ? .35 : 1,
                child: QubitQuestGateTile(
                  key: ValueKey('bloch-gate-${type.name}'),
                  gate: Gate.fromIdentifier(type),
                  size: _compactGates ? 40 : 46,
                  fontSize: 15,
                  tooltip: inspecting
                      ? 'Return to the current state to apply gates'
                      : GateEducationalCatalog.forType(type)?.name,
                  onPressed: inspecting ? null : () => selectGate(type),
                ),
              ),
            ),
        ]),
        if (inspecting) ...[
          const SizedBox(height: 8),
          const Text(
            'You are inspecting an earlier step. Return to the current state '
            'to apply gates.',
            key: ValueKey('bloch-gates-inspecting'),
            style: TextStyle(color: BlochOverlayColors.preview, fontSize: 12),
          ),
        ],
        if (selected != null && !inspecting) ...[
          const SizedBox(height: 12),
          _previewCard(selected),
        ],
      ],
    );
  }

  Widget _previewCard(SelectedGateType type) {
    final rotation = blochLabIsRotation(type);
    final preview = session.preview(type, angle: rotation ? _angle : null);
    final info = GateEducationalCatalog.forType(type);
    return Container(
      key: const ValueKey('bloch-preview-card'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: BlochOverlayColors.preview.withValues(alpha: .5)),
        color: BlochOverlayColors.preview.withValues(alpha: .06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Preview: ${info?.name ?? preview.label}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            'Bloch action: ${_rotationCaption(preview.rotation)}'
            '${rotation ? '' : ' (an equivalent rotation, up to global phase)'}.',
            key: const ValueKey('bloch-preview-rotation'),
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          if (preview.rotation.fixes(preview.before.vector))
            const Text(
              'The state lies on the rotation axis: its Bloch position does '
              'not move. The state vector may gain a global phase (compare '
              'the amplitudes), but it does not have to.',
              key: ValueKey('bloch-preview-on-axis'),
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          if (rotation)
            _AngleControl(
              key: const ValueKey('bloch-rotation-angle'),
              label: 'Angle θ',
              value: _angle,
              min: -2 * math.pi,
              max: 4 * math.pi,
              presets: const [
                math.pi / 4,
                math.pi / 2,
                math.pi,
                3 * math.pi / 2,
                2 * math.pi
              ],
              onChanged: setAngle,
            ),
          const SizedBox(height: 4),
          Text('Result: ${blochStateExpression(preview.after)}',
              key: const ValueKey('bloch-preview-result'),
              style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            FilledButton(
              key: const ValueKey('bloch-apply'),
              onPressed: applySelected,
              child: Text('Apply ${preview.label}'),
            ),
            TextButton(
              key: const ValueKey('bloch-cancel-preview'),
              onPressed: () => setState(() => _selected = null),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const ValueKey('bloch-about-gate'),
              onPressed: () => _aboutGate(type),
              child: const Text('About this gate'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _evolution() {
    final steps = session.allSteps;
    final inspected = session.inspectedIndex;
    final applied = session.appliedCount;
    final focus = inspected ?? applied;
    Widget chip(int index, String label) {
      final redo = index > applied;
      final isFocus = index == focus;
      return ChoiceChip(
        key: ValueKey('bloch-step-$index'),
        label: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                color: redo ? _muted.withValues(alpha: .6) : null)),
        selected: isFocus,
        onSelected: redo
            ? null
            : (_) {
                _motion.stop();
                _animating = null;
                session.inspect(index);
              },
      );
    }

    final nodes = <Widget>[chip(0, 'Start ${session.initialLabel}')];
    for (var i = 0; i < steps.length; i++) {
      nodes
        ..add(const Icon(Icons.arrow_forward, size: 14, color: _muted))
        ..add(chip(i + 1, steps[i].label));
    }
    return Column(
      key: const ValueKey('bloch-evolution'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Text('State evolution',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              inspected == null
                  ? '$applied step${applied == 1 ? '' : 's'} · showing the current state'
                  : 'Inspecting step $inspected of $applied (read-only)',
              key: const ValueKey('bloch-evolution-status'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color:
                      inspected == null ? _muted : BlochOverlayColors.preview,
                  fontSize: 12),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final n in nodes)
              Padding(padding: const EdgeInsets.only(right: 4), child: n),
          ]),
        ),
        const SizedBox(height: 6),
        Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (inspected != null)
                FilledButton.tonal(
                  key: const ValueKey('bloch-return-current'),
                  onPressed: session.returnToCurrent,
                  child: const Text('Return to current'),
                ),
              IconButton(
                key: const ValueKey('bloch-undo'),
                tooltip: 'Undo',
                onPressed: session.canUndo ? session.undo : null,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                key: const ValueKey('bloch-redo'),
                tooltip: 'Redo',
                onPressed: session.canRedo ? session.redo : null,
                icon: const Icon(Icons.redo),
              ),
              TextButton.icon(
                key: const ValueKey('bloch-reset'),
                onPressed: () {
                  _motion.stop();
                  _animating = null;
                  session.reset();
                },
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(widget.exploration == null
                    ? 'Reset to start ${session.initialLabel}'
                    : widget.exploration!.seed.origin == BlochLabOrigin.notebook
                        ? 'Reset to example'
                        : 'Reset'),
              ),
              FilterChip(
                key: const ValueKey('bloch-animate-toggle'),
                label: const Text('Animate', style: TextStyle(fontSize: 12)),
                selected: _animate,
                visualDensity: VisualDensity.compact,
                onSelected: (v) => setState(() => _animate = v),
              ),
            ]),
      ],
    );
  }

  Widget _stateSection() {
    final s = session.displayed;
    final defined = s.hasDefinedRelativePhase;
    final norm = s.probabilityZero + s.probabilityOne;
    final globalAngle = s.alphaMagnitude > blochAmplitudeEpsilon
        ? math.atan2(s.alpha.imaginary.toDouble(), s.alpha.real.toDouble())
        : math.atan2(s.beta.imaginary.toDouble(), s.beta.real.toDouble());
    return Column(
      key: const ValueKey('bloch-state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(session.isInspecting
            ? 'State after step ${session.inspectedIndex}'
            : 'Current state'),
        SelectableText('|ψ⟩ = ${blochStateExpression(s)}',
            key: const ValueKey('bloch-state-expression'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const _Subheading('Complex amplitudes'),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          ComplexAmplitudePlane(
            size: 132,
            amplitudes: [
              PlottedAmplitude('α', s.alpha, _alphaColor),
              PlottedAmplitude('β', s.beta, _betaColor),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              key: const ValueKey('bloch-amplitudes'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Value('α', blochComplex(s.alpha), color: _alphaColor),
                _Value('|α|²', blochNumber(s.probabilityZero)),
                const SizedBox(height: 4),
                _Value('β', blochComplex(s.beta), color: _betaColor),
                _Value('|β|²', blochNumber(s.probabilityOne)),
                const SizedBox(height: 4),
                _Value('|α|² + |β|²', blochNumber(norm)),
              ],
            ),
          ),
        ]),
        const Text(
          'Arrows show the actual amplitudes, including the global phase. '
          'The sphere ignores global phase.',
          style: TextStyle(color: _muted, fontSize: 11.5),
        ),
        const SizedBox(height: 12),
        const _Subheading('Bloch vector'),
        Wrap(key: const ValueKey('bloch-cartesian'), spacing: 14, children: [
          _Value('x', blochNumber(s.x)),
          _Value('y', blochNumber(s.y)),
          _Value('z', blochNumber(s.z)),
          _Value(
              '|r|', blochNumber(math.sqrt(s.x * s.x + s.y * s.y + s.z * s.z))),
        ]),
        const Text('x = 2 Re(α*β),  y = 2 Im(α*β),  z = |α|² − |β|²',
            style: TextStyle(color: _muted, fontSize: 11.5)),
        const SizedBox(height: 8),
        _Value('θ (polar)', blochAngle(s.theta),
            key: const ValueKey('bloch-theta')),
        _Value(
          'φ (azimuthal)',
          defined ? blochAngle(s.phi) : 'undefined at the pole',
          key: const ValueKey('bloch-phi'),
        ),
        const SizedBox(height: 10),
        const _Subheading('Phase'),
        Text(
          defined
              ? 'Relative phase arg(β) − arg(α) = ${blochAngle(s.phi)}. It sets '
                  'the direction around the Z axis and is physical.'
              : 'Relative phase is undefined: one amplitude is zero, so the '
                  'state sits at a pole and φ has no physical meaning.',
          key: const ValueKey('bloch-relative-phase'),
          style: const TextStyle(fontSize: 12.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Global phase as written: ${blochAngle(globalAngle)} (the phase of the '
          'first non-zero amplitude). This is a convention of the state-vector '
          'notation, not an observable: multiplying the whole state by e^(iγ) '
          'changes neither the sphere nor any measurement of this qubit.',
          key: const ValueKey('bloch-global-phase'),
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        const _Subheading('Z-basis probabilities'),
        _ProbabilityBar('P(|0⟩)', s.probabilityZero),
        _ProbabilityBar('P(|1⟩)', s.probabilityOne),
        const SizedBox(height: 12),
        const Text(
          'Single-qubit laboratory. A qubit entangled with others has no '
          'state vector of its own: its reduced state lies inside the sphere '
          '(for (|00⟩ + |11⟩)/√2 it is the centre). Reduced states are not '
          'shown here.',
          key: ValueKey('bloch-single-qubit-boundary'),
          style: TextStyle(color: _muted, fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _measureSection() {
    final s = session.displayed;
    final (plus, minus) = _basis.probabilities(s);
    final formula = switch (_basis) {
      BlochBasis.z => 'P(|0⟩) = (1 + z)/2',
      BlochBasis.x => 'P(|+⟩) = (1 + x)/2',
      BlochBasis.y => 'P(|+i⟩) = (1 + y)/2',
    };
    final single = _single;
    final shots = _shots;
    return Column(
      key: const ValueKey('bloch-measure'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Measure'),
        Text(
          session.isInspecting
              ? 'Measuring the state after step ${session.inspectedIndex}.'
              : 'Measuring the current state.',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SegmentedButton<BlochBasis>(
          key: const ValueKey('bloch-basis'),
          showSelectedIcon: false,
          segments: [
            for (final b in BlochBasis.values)
              ButtonSegment(
                  value: b,
                  label: Text('${b.label} basis',
                      key: ValueKey('bloch-basis-${b.name}'))),
          ],
          selected: {_basis},
          onSelectionChanged: (v) => setState(() {
            _basis = v.single;
            _single = null;
            _shots = null;
          }),
        ),
        const SizedBox(height: 10),
        _Subheading(shots == null
            ? 'Exact probabilities'
            : 'Exact probability (outline) · observed frequency (filled)'),
        Column(key: const ValueKey('bloch-exact'), children: [
          _ProbabilityBar('P(${_basis.plusLabel})', plus,
              observed: shots == null ? null : shots.plusCount / shots.shots),
          _ProbabilityBar('P(${_basis.minusLabel})', minus,
              observed: shots == null ? null : shots.minusCount / shots.shots),
        ]),
        Text(
          '$formula · ${switch (_basis) {
            BlochBasis.z => 'measured directly',
            BlochBasis.x => 'H, then measure in Z',
            BlochBasis.y => 'S†, then H, then measure in Z',
          }}',
          style: const TextStyle(color: _muted, fontSize: 11.5),
        ),
        const SizedBox(height: 10),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonal(
                key: const ValueKey('bloch-run-once'),
                onPressed: _measureOnce,
                child: const Text('Run once'),
              ),
              FilledButton(
                key: const ValueKey('bloch-run-shots'),
                onPressed: _measureShots,
                child: Text('Run $_shotCount shots'),
              ),
              DropdownButton<int>(
                key: const ValueKey('bloch-shot-count'),
                value: _shotCount,
                items: [
                  for (final n in const [100, 1000, 10000])
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (v) => setState(() {
                  _shotCount = v ?? 1000;
                  _shots = null;
                }),
              ),
            ]),
        if (single != null) ...[
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('bloch-single-result'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Text(
              'Outcome: ${single.label}. Just after this measurement the '
              'qubit would be in ${single.label}. The prepared state above is '
              'unchanged: each run prepares it again.',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
        if (shots != null) ...[
          const SizedBox(height: 8),
          Text(
            '${shots.shots} independent preparations, each measured once: '
            '${shots.plusCount} × ${_basis.plusLabel}, '
            '${shots.minusCount} × ${_basis.minusLabel}. Filled bars are the '
            'observed frequencies; outlines are exact.',
            key: const ValueKey('bloch-shots-result'),
            style: const TextStyle(fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------ small parts

class _ExplorationBanner extends StatelessWidget {
  const _ExplorationBanner({
    required this.seed,
    required this.compact,
    required this.onReturn,
    required this.onReset,
    required this.onClose,
  });
  final BlochLabSeed seed;
  final bool compact;
  final VoidCallback? onReturn;
  final VoidCallback onReset;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final kind = switch (seed.origin) {
      BlochLabOrigin.notebook => 'Notebook example',
      BlochLabOrigin.composer => 'From the Composer',
      BlochLabOrigin.comparison => 'Phase comparison',
      BlochLabOrigin.standalone => 'Exploration',
    };
    return Container(
      key: const ValueKey('bloch-exploration-banner'),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: _cyan.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('$kind · ${seed.title}',
                  key: const ValueKey('bloch-exploration-title'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (onReturn != null && seed.returnLabel != null)
                OutlinedButton.icon(
                  key: const ValueKey('bloch-exploration-return'),
                  onPressed: onReturn,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(seed.returnLabel!),
                ),
              TextButton(
                key: const ValueKey('bloch-exploration-close'),
                onPressed: onClose,
                child: const Text('Leave and open my lab'),
              ),
            ],
          ),
          if (seed.note != null)
            Text(
              seed.note!,
              key: const ValueKey('bloch-exploration-note'),
              maxLines: compact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          const Text(
            'Isolated: nothing here changes your Sandbox, progress or own lab.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AngleControl extends StatefulWidget {
  const _AngleControl({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.presets,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final List<double> presets;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  State<_AngleControl> createState() => _AngleControlState();
}

class _AngleControlState extends State<_AngleControl> {
  late final TextEditingController _text =
      TextEditingController(text: blochNumber(widget.value));
  String? _error;

  @override
  void didUpdateWidget(covariant _AngleControl old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value &&
        parseBlochAngle(_text.text) != widget.value) {
      _text.text = blochNumber(widget.value);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit(String input) {
    final v = parseBlochAngle(input);
    setState(() => _error = v == null
        ? 'Use radians (1.57) or π multiples (π/2, 3pi/4).'
        : v < widget.min || v > widget.max
            ? 'Between ${blochAngle(widget.min).split(' (').first} and '
                '${blochAngle(widget.max).split(' (').first}.'
            : null);
    if (_error == null && v != null) widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: Text('${widget.label}: ${blochAngle(widget.value)}',
                  style: const TextStyle(fontSize: 12.5)),
            ),
            SizedBox(
              width: 82,
              child: TextField(
                key: const ValueKey('angle-entry'),
                controller: _text,
                enabled: widget.enabled,
                style: const TextStyle(fontSize: 12.5),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onSubmitted: _submit,
              ),
            ),
          ]),
          Slider(
            key: const ValueKey('angle-slider'),
            value: widget.value.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            onChanged: widget.enabled
                ? (v) {
                    _error = null;
                    widget.onChanged(v);
                  }
                : null,
          ),
          Wrap(spacing: 4, runSpacing: 4, children: [
            for (final p in widget.presets)
              ActionChip(
                key: ValueKey('angle-preset-${p.toStringAsFixed(4)}'),
                visualDensity: VisualDensity.compact,
                label: Text(blochAngle(p).split(' (').first,
                    style: const TextStyle(fontSize: 12)),
                onPressed: widget.enabled ? () => widget.onChanged(p) : null,
              ),
          ]),
          if (_error != null)
            Text(_error!,
                style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12)),
        ],
      );
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: child,
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
      );
}

class _Subheading extends StatelessWidget {
  const _Subheading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                letterSpacing: .6,
                fontWeight: FontWeight.w800,
                color: QubitQuestDialog.purple)),
      );
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value, {super.key, this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: '$label = ',
                  style: TextStyle(
                      color: color ?? _muted, fontWeight: FontWeight.w700)),
              TextSpan(text: value),
            ]),
            style: const TextStyle(fontSize: 12.5)),
      );
}

class _ProbabilityBar extends StatelessWidget {
  const _ProbabilityBar(this.label, this.exact, {this.observed});
  final String label;
  final double exact;
  final double? observed;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 74,
              child: Text(label, style: const TextStyle(fontSize: 12.5))),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => Stack(children: [
                Container(
                    height: 12,
                    decoration: BoxDecoration(
                        color: const Color(0xFF13203A),
                        borderRadius: BorderRadius.circular(4))),
                if (observed != null)
                  Container(
                      height: 12,
                      width: c.maxWidth * observed!.clamp(0, 1),
                      decoration: BoxDecoration(
                          color: QubitQuestDialog.purple.withValues(alpha: .75),
                          borderRadius: BorderRadius.circular(4))),
                Container(
                    height: 12,
                    width: c.maxWidth * exact.clamp(0, 1),
                    decoration: BoxDecoration(
                        border: Border.all(color: _cyan, width: 1.5),
                        borderRadius: BorderRadius.circular(4))),
              ]),
            ),
          ),
          SizedBox(
            width: observed == null ? 56 : 110,
            child: Text(
              observed == null
                  ? '${(exact * 100).toStringAsFixed(1)}%'
                  : '${(exact * 100).toStringAsFixed(1)}% · '
                      '${(observed! * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ]),
      );
}
