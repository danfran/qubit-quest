// Web Bloch Explorer: an interactive single-qubit state laboratory (v2.6 M8,
// refined in M11F).
//
// The Composer answers "what does this circuit do?"; this workspace answers
// "how and why does this state change?". All state comes from
// [BlochLabSession] (simulator matrices); the sphere, amplitudes,
// coordinates and probabilities always describe the same displayed state.
//
// Layout (M11F, from the M11B prototype): Prepare & transform | the sphere
// stage with its transport and timeline | State & measurement. Five
// interactions are kept apart (M11B D7):
//   Preview   selecting a gate: dashed path, nothing recorded;
//   Apply     commits exactly one step;
//   Animate when applying   how an Apply is shown (a setting);
//   Inspect   select a timeline step: read-only view of a past state;
//   Play steps  replays the recorded steps from Start, with Pause/Resume,
//             Step back/forward and a speed (never records anything).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/bloch_lab.dart';
import 'package:quantumquiz/models/canonical_qubit_state.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/complex_amplitude_plane.dart';
import 'package:quantumquiz/widgets/journey_chapter_illustration.dart'
    show keepKetsTogether;
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/qq_scientific_primitives.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';
import 'package:quantumquiz/widgets/qubit_quest_workspace_primitives.dart';
import 'package:quantumquiz/widgets/state_amplitude_panel.dart'
    show QqCurrentStatePanel, qqAmplitudePrecisionNote;
import 'package:advance_math/advance_math.dart' show Complex;
import 'package:quantumquiz/models/measured_circuit_runner.dart'
    show formatCount;
import 'package:quantumquiz/utils/probability_format.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart'
    show
        formatQuantumAmplitude,
        formatQuantumStateExpression,
        quantumAmplitudeIsApproximate;
import 'package:quantumquiz/widgets/measured_circuit_run_panel.dart'
    show ComparisonBar, MeasurementComparisonLegend;

const _alphaColor = Color(0xFF4FD8FF);
const _betaColor = Color(0xFFC08BFF);

/// The scope of the laboratory (M11F wording, consistent with the
/// Composer's M11E multi-qubit note).
const String blochScopeNote =
    'The surface of the Bloch sphere represents pure single-qubit states. '
    'Mixed single-qubit states are represented by points inside the sphere. '
    'An individual qubit in an entangled system may have a mixed reduced '
    'state, while the complete joint state cannot generally be represented '
    'by a single Bloch sphere.';

/// Guided comparisons for global and relative phase (M8).
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

/// How a transformation leaves the Bloch vector, for the preview card
/// (M11F): it moves; it returns after whole turns; or it does not move.
/// For the last two the exact factor e^{iγ} between the state vectors is
/// reported, because equal Bloch vectors do not mean equal state vectors.
@immutable
class BlochStepOutcome {
  const BlochStepOutcome({
    required this.moves,
    required this.fullTurns,
    required this.globalPhase,
  });

  /// The Bloch vector ends somewhere else.
  final bool moves;

  /// Whole turns travelled by a vector that returns to its start (0 when it
  /// lies on the axis and never moves).
  final int fullTurns;

  /// γ in (−π, π] with after = e^{iγ}·before, when the vector ends where it
  /// started; null when it moves.
  final double? globalPhase;

  factory BlochStepOutcome.of(BlochLabStep step) {
    final b = step.before, a = step.after;
    final same = (b.x - a.x).abs() < 1e-9 &&
        (b.y - a.y).abs() < 1e-9 &&
        (b.z - a.z).abs() < 1e-9;
    if (!same) {
      return const BlochStepOutcome(
          moves: true, fullTurns: 0, globalPhase: null);
    }
    // Compare the larger amplitude (the other may be zero).
    final useAlpha = b.alphaMagnitude >= b.betaMagnitude;
    final before = useAlpha ? b.alpha : b.beta;
    final after = useAlpha ? a.alpha : a.beta;
    var gamma = math.atan2(after.imaginary.toDouble(), after.real.toDouble()) -
        math.atan2(before.imaginary.toDouble(), before.real.toDouble());
    while (gamma <= -math.pi) {
      gamma += 2 * math.pi;
    }
    while (gamma > math.pi) {
      gamma -= 2 * math.pi;
    }
    if (gamma.abs() < 1e-9) gamma = 0;
    final rotation = step.rotation;
    final turns = rotation.isOnAxis(b.vector)
        ? 0
        : (rotation.angle.abs() / (2 * math.pi)).round();
    return BlochStepOutcome(moves: false, fullTurns: turns, globalPhase: gamma);
  }
}

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

  /// One animated step at 1× speed.
  static const Duration stepDuration = Duration(milliseconds: 900);

  @override
  State<WebBlochWorkspace> createState() => WebBlochWorkspaceState();
}

enum _Side { act, read }

@visibleForTesting
class WebBlochWorkspaceState extends State<WebBlochWorkspace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  /// The step being drawn along its path (an Apply, a replayed step, or a
  /// step back); null when the sphere shows the displayed state.
  BlochLabStep? _animating;

  /// Drawn backwards (Step back): from the step's result to its input.
  bool _reverse = false;

  /// The 1-based step index Play steps is animating, or null.
  int? _playStep;
  bool _playing = false;
  bool _paused = false;
  double _speed = 1;

  BlochCamera _camera = const BlochCamera(zoom: 1.05);
  SelectedGateType? _selected;
  double _angle = math.pi / 2;
  bool _animate = true;
  bool _dragState = false;
  bool _customOpen = false;
  double _customTheta = math.pi / 3;
  double _customPhi = math.pi / 4;
  BlochBasis _basis = BlochBasis.z;

  /// The measured axis is highlighted only while the learner is working
  /// with measurement (chose a basis or measured), so it does not compete
  /// with previews.
  bool _basisShown = false;
  BlochSingleMeasurement? _single;
  BlochShotsMeasurement? _shots;
  int _shotCount = 1000;
  final BlochMeasurer _measurer = BlochMeasurer();
  _Side _side = _Side.act;
  BlochState? _dragPreview;

  BlochLabSession get session => widget.exploration ?? widget.standalone;
  SelectedGateType? get selectedGate => _selected;
  BlochCamera get camera => _camera;

  /// Playback state (tests): playing, paused, the step being replayed.
  bool get isPlaying => _playing;
  bool get isPaused => _paused;
  int? get playbackStep => _playStep;
  double get speed => _speed;

  /// The vector the sphere draws now (tests): animated, dragged or the
  /// displayed state.
  BlochState get sphereState => _sphereState;

  @override
  void initState() {
    super.initState();
    // Created eagerly: a lazy controller would be first built in dispose().
    _motion = AnimationController(
        vsync: this, duration: WebBlochWorkspace.stepDuration)
      ..addListener(() => setState(() {}))
      ..addStatusListener(_onMotionStatus);
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
    _stopMotion();
    _selected = null;
    _single = null;
    _shots = null;
    _customOpen = false;
    _dragPreview = null;
  }

  // ------------------------------------------------------------ motion

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Stops any animation or playback. Nothing in the session changes.
  void _stopMotion() {
    _motion.stop();
    _animating = null;
    _reverse = false;
    _playStep = null;
    _playing = false;
    _paused = false;
  }

  void _run(BlochLabStep step, {bool reverse = false}) {
    _animating = step;
    _reverse = reverse;
    _motion.duration = _durationForSpeed;
    _motion.forward(from: 0);
  }

  Duration get _durationForSpeed => Duration(
      milliseconds:
          (WebBlochWorkspace.stepDuration.inMilliseconds / _speed).round());

  void _onMotionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final k = _playStep;
    if (_playing && k != null && k < session.appliedCount) {
      _playNext(k + 1);
      return;
    }
    setState(() {
      _animating = null;
      _reverse = false;
      _playStep = null;
      _playing = false;
      _paused = false;
    });
  }

  /// Animates step [k] of Play steps; the panels show its result (the
  /// session inspects it, read-only), so the numbers always name the step
  /// on screen.
  void _playNext(int k) {
    session.inspect(k);
    setState(() => _playStep = k);
    _run(session.allSteps[k - 1]);
  }

  /// Play steps (M11B D7): replays the recorded steps from Start (or, when
  /// an earlier step is being inspected, from there) to the current state.
  /// Only inspection is used: the history is never changed.
  void playSteps() {
    if (session.appliedCount == 0) return;
    if (_paused) return resumePlayback();
    final from = session.inspectedIndex ?? 0;
    _stopMotion();
    setState(() {
      _selected = null;
      _playing = true;
    });
    _playNext(from >= session.appliedCount ? 1 : from + 1);
  }

  void pausePlayback() {
    if (!_playing) return;
    _motion.stop();
    setState(() {
      _playing = false;
      _paused = true;
    });
  }

  void resumePlayback() {
    if (!_paused) return;
    setState(() {
      _playing = true;
      _paused = false;
    });
    _motion.duration = _durationForSpeed;
    _motion.forward();
  }

  /// The step index on screen: inspected, or the current position.
  int get _focus => session.inspectedIndex ?? session.appliedCount;

  void stepForward() {
    final focus = _focus;
    if (focus >= session.appliedCount) return;
    _stopMotion();
    session.inspect(focus + 1);
    if (_reducedMotion) return setState(() {});
    _run(session.allSteps[focus]);
  }

  void stepBack() {
    final focus = _focus;
    if (focus <= 0) return;
    _stopMotion();
    final step = session.allSteps[focus - 1];
    session.inspect(focus - 1);
    if (_reducedMotion) return setState(() {});
    _run(step, reverse: true);
  }

  void toStart() {
    _stopMotion();
    session.inspect(0);
    setState(() {});
  }

  void toCurrent() {
    _stopMotion();
    session.returnToCurrent();
    setState(() {});
  }

  /// Changing the speed changes only how long the drawing takes.
  void setSpeed(double speed) {
    setState(() => _speed = speed);
    if (_motion.isAnimating) {
      _motion.duration = _durationForSpeed;
      _motion.forward();
    }
  }

  // ------------------------------------------------------------- actions

  final GlobalKey _previewKey = GlobalKey(debugLabel: 'bloch-preview');

  void selectGate(SelectedGateType? type) {
    setState(() {
      _selected = _selected == type ? null : type;
      _basisShown = false;
      _customOpen = false;
      _side = _Side.act;
    });
    // The preview card (with Apply) is brought into view in its column.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _previewKey.currentContext;
      if (context == null || !mounted) return;
      // Only the nearest scroll view moves (M11G): in short landscape
      // windows the controls scroll beside the sphere, which stays put.
      final object = context.findRenderObject();
      final scrollable = Scrollable.maybeOf(context);
      if (object == null || scrollable == null) return;
      scrollable.position.ensureVisible(object,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          duration: const Duration(milliseconds: 200));
    });
  }

  void setAngle(double angle) => setState(() => _angle = angle);

  /// Applies the previewed gate: exactly one history step.
  void applySelected() {
    final type = _selected;
    if (type == null || session.isInspecting) return;
    _stopMotion();
    final step =
        session.commit(type, angle: blochLabIsRotation(type) ? _angle : null);
    if (step == null) return;
    setState(() => _selected = null);
    if (_animate && !_reducedMotion) _run(step);
  }

  void _prepare(BlochState state, String label) {
    _stopMotion();
    session.prepare(state, label);
    setState(() {
      _selected = null;
      _customOpen = false;
    });
  }

  void _reset() {
    _stopMotion();
    session.reset();
    setState(() {});
  }

  void _measureOnce() => setState(() {
        _basisShown = true;
        _single = _measurer.once(session.displayed, _basis);
      });

  void _measureShots() => setState(() {
        _basisShown = true;
        _shots = _measurer.shots(session.displayed, _basis, _shotCount);
      });

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

  /// The vector drawn on the sphere: along the animated path, dragged, or
  /// the displayed state. Numbers elsewhere use [BlochLabSession.displayed].
  /// The path is the step's own rotation through its full angle, so 3π/2,
  /// 2π and 4π are drawn as such (never a shortest path).
  BlochState get _sphereState {
    final step = _animating;
    if (step != null) {
      final f = _reducedMotion
          ? 1.0
          : Curves.easeInOut.transform(_motion.value.clamp(0.0, 1.0));
      final (x, y, z) =
          step.rotation.apply(step.before.vector, _reverse ? 1 - f : f);
      return BlochState.fromCartesian(x, y, z);
    }
    return _dragPreview ?? session.displayed;
  }

  BlochSphereOverlay get _overlay {
    final basis = _basisShown ? _basis : null;
    final outcome = _single?.postMeasurementState.vector;
    final step = _animating;
    if (step != null) {
      return BlochSphereOverlay(
        basis: basis,
        startVector: step.before.vector,
        rotation: step.rotation,
        applied: true,
      );
    }
    if (_customOpen) {
      return BlochSphereOverlay(
          basis: basis, previewVector: _customState.vector);
    }
    final type = _selected;
    if (type != null && !session.isInspecting) {
      final preview = session.preview(type,
          angle: blochLabIsRotation(type) ? _angle : null);
      return BlochSphereOverlay(
        basis: basis,
        startVector: preview.before.vector,
        previewVector: preview.after.vector,
        rotation: preview.rotation,
      );
    }
    final index = _focus;
    if (index > 0 && _dragPreview == null) {
      final last = session.allSteps[index - 1];
      return BlochSphereOverlay(
        basis: basis,
        startVector: last.before.vector,
        rotation: last.rotation,
        applied: true,
        outcomeVector: outcome,
      );
    }
    return BlochSphereOverlay(basis: basis, outcomeVector: outcome);
  }

  BlochState get _customState =>
      BlochState.fromAngles(theta: _customTheta, phi: _customPhi);

  // ------------------------------------------------------------- layout

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final Widget body;
          if (width >= 1180 && constraints.maxHeight >= 600) {
            body = _wide(constraints);
          } else if (width >= 760 && constraints.maxHeight >= 560) {
            body = _medium(constraints);
          } else {
            body = _stacked(constraints);
          }
          return ColoredBox(color: QubitQuestSurfaces.app, child: body);
        },
      );

  Widget _header({bool compact = false}) {
    final exploration = widget.exploration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Icon(Icons.language,
              color: QubitQuestColors.accentInteractive, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text('Bloch Explorer',
                key: const ValueKey('web-bloch-title'),
                overflow: TextOverflow.ellipsis,
                style: QqType.sectionTitle),
          ),
          if (!compact) ...[
            const SizedBox(width: 14),
            const Flexible(
              child: Text(
                'Prepare a state, preview a transformation, apply it and '
                'watch the geometry',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QqType.meta,
              ),
            ),
          ],
        ]),
        if (exploration != null) ...[
          const SizedBox(height: 10),
          _ExplorationBanner(
            seed: exploration.seed,
            compact: compact,
            onReturn: widget.onReturnFromExploration,
            onReset: _reset,
            onClose: widget.onCloseExploration,
          ),
        ],
      ],
    );
  }

  /// Wide: Prepare & transform | sphere stage (largest) | State & measure.
  Widget _wide(BoxConstraints c) {
    final roomy = c.maxWidth >= 1500;
    return Padding(
      key: const ValueKey('web-bloch-wide-layout'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
                  width: roomy ? 310 : 284,
                  child: _Pane(
                    key: const ValueKey('web-bloch-left'),
                    label: 'Prepare and transform',
                    child: _actColumn(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: _stage()),
                const SizedBox(width: 14),
                SizedBox(
                  width: roomy ? 380 : 330,
                  child: _Pane(
                    key: const ValueKey('web-bloch-right'),
                    label: 'State and measurement',
                    child: _readColumn(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact desktop and tablet: the stage keeps most of the width; one
  /// side panel switches between Act and Read.
  Widget _medium(BoxConstraints c) => Padding(
        key: const ValueKey('web-bloch-medium-layout'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _stage()),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: math.min(360, c.maxWidth * .4),
                    child: DecoratedBox(
                      key: const ValueKey('web-bloch-side'),
                      decoration: _paneDecoration,
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: SegmentedButton<_Side>(
                            key: const ValueKey('web-bloch-tabs'),
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              textStyle: QqType.control,
                            ),
                            segments: const [
                              ButtonSegment(
                                  value: _Side.act,
                                  label: Text('Prepare & gates',
                                      key: ValueKey('web-bloch-tab-act'))),
                              ButtonSegment(
                                  value: _Side.read,
                                  label: Text('State & measure',
                                      key: ValueKey('web-bloch-tab-read'))),
                            ],
                            selected: {_side},
                            onSelectionChanged: (s) =>
                                setState(() => _side = s.single),
                          ),
                        ),
                        Expanded(
                          child:
                              _side == _Side.act ? _actColumn() : _readColumn(),
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

  /// Phones and short windows: one natural scroll. Portrait: preparation,
  /// then the sphere with the gates directly under it. Short landscape
  /// windows: the whole sphere beside preparation, playback and gates.
  /// The detailed panels follow in both.
  Widget _stacked(BoxConstraints c) {
    final width = c.maxWidth;
    final landscape = width >= 640 && width > c.maxHeight;
    final pane = DecoratedBox(
      key: const ValueKey('web-bloch-side'),
      decoration: _paneDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stateSection(),
            const SizedBox(height: 18),
            _measureSection(),
            const SizedBox(height: 20),
            _stateDetails(),
            const SizedBox(height: 14),
            _customAndComparisons(custom: false),
            const SizedBox(height: 16),
            const QqMeta(blochScopeNote,
                key: ValueKey('bloch-single-qubit-boundary')),
          ],
        ),
      ),
    );
    final timeline = DecoratedBox(
      decoration: _paneDecoration,
      child: Padding(padding: const EdgeInsets.all(12), child: _timeline()),
    );
    final gates = KeyedSubtree(
        key: const ValueKey('web-bloch-narrow-gates'),
        child: _gateSection(compact: true));
    if (landscape) {
      // Uses the height as well as the width (M11G): the sphere is as tall
      // as the window allows, so it is seen whole without scrolling.
      final side = (c.maxHeight - 20).clamp(220.0, 440.0);
      // The controls scroll beside the sphere (a preview card can be
      // taller than the window), so the whole sphere stays in view while
      // a transformation is previewed.
      return _Scroll(
        key: const ValueKey('web-bloch-stacked-layout'),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
        children: [
          SizedBox(
            height: side,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  key: const ValueKey('web-bloch-stage'),
                  width: side,
                  height: side,
                  child: DecoratedBox(
                    decoration: _paneDecoration,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _sphere(compactControls: true),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('web-bloch-landscape-scroll'),
                    child: Column(
                      key: const ValueKey('web-bloch-landscape-controls'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(compact: true),
                        const SizedBox(height: 6),
                        _canonicalStates(compact: true),
                        if (_customOpen) ...[
                          const SizedBox(height: 8),
                          _customCard(),
                        ],
                        const SizedBox(height: 6),
                        _transport(compact: true),
                        const SizedBox(height: 4),
                        gates,
                        const SizedBox(height: 6),
                        _legend(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          timeline,
          const SizedBox(height: 10),
          pane,
        ],
      );
    }
    final sphereSize = math.min(width - 24, 400.0);
    final sphere = SizedBox(
      key: const ValueKey('web-bloch-stage'),
      height: sphereSize + 36,
      child: _sphere(top: 36),
    );
    return _Scroll(
      key: const ValueKey('web-bloch-stacked-layout'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
      children: [
        _header(compact: true),
        const SizedBox(height: 8),
        _canonicalStates(compact: true),
        if (_customOpen) ...[
          const SizedBox(height: 8),
          _customCard(),
        ],
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: _paneDecoration,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sphere,
                const SizedBox(height: 6),
                // Gates directly under the sphere; the legend and playback
                // after them, so the gates never move when a step adds
                // legend lines or the full transport (M11G).
                gates,
                const SizedBox(height: 8),
                _legend(),
                const Divider(height: 18, color: QubitQuestSurfaces.rule),
                _transport(compact: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        timeline,
        const SizedBox(height: 10),
        pane,
      ],
    );
  }

  static final _paneDecoration = BoxDecoration(
    color: QubitQuestSurfaces.work,
    borderRadius: QubitQuestRadii.card,
    border: Border.all(color: QubitQuestSurfaces.rule),
  );

  // Side columns and the phone layout are built eagerly (short content), so
  // every section exists for focus, reveal and assistive technology.
  Widget _actColumn() => _Scroll(
        key: const ValueKey('bloch-act'),
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
        children: [
          _canonicalStates(),
          const SizedBox(height: 6),
          _customAndComparisons(),
          const SizedBox(height: 18),
          _gateSection(),
        ],
      );

  Widget _readColumn() => _Scroll(
        key: const ValueKey('bloch-read'),
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
        children: [
          _stateSection(),
          const SizedBox(height: 18),
          _measureSection(),
          const SizedBox(height: 20),
          _stateDetails(),
          const SizedBox(height: 14),
          const QqMeta(blochScopeNote,
              key: ValueKey('bloch-single-qubit-boundary')),
        ],
      );

  /// The sphere stage: the sphere (largest element), its legend, the
  /// playback transport and the timeline.
  Widget _stage() => Column(
        key: const ValueKey('web-bloch-stage'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: _paneDecoration,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(children: [
                  Expanded(child: _sphere()),
                  _legend(),
                  const SizedBox(height: 8),
                  _transport(),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: _paneDecoration,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: _timeline()),
          ),
        ],
      );

  /// [top] reserves room for the view controls above the sphere where the
  /// stage is small (phones), so they never cover the |0⟩ label.
  Widget _sphere({double top = 0, bool compactControls = false}) =>
      Stack(children: [
        Positioned.fill(
          top: top,
          child: MouseRegion(
            cursor: _dragState
                ? SystemMouseCursors.precise
                : SystemMouseCursors.grab,
            child: BlochSpherePanel(
              key: const ValueKey('web-bloch-sphere'),
              showAnnotations: false,
              // Projected, collision-avoiding pole labels (M11D, shared
              // with the Composer's Bloch summary).
              showStateLabels: true,
              allowStateEditing:
                  _dragState && !session.isInspecting && _animating == null,
              overlay: _overlay,
              state: _sphereState,
              camera: _camera,
              onCameraChanged: (camera) => setState(() => _camera = camera),
              onStatePreview: (state) => setState(() => _dragPreview = state),
              onStateCommitted: (state) {
                setState(() => _dragPreview = null);
                _prepare(state, 'Custom');
              },
              onGestureStarted: () {},
              onStateGestureStarted: () => session.displayed,
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: Row(children: [
            if (compactControls)
              IconButton(
                key: const ValueKey('bloch-drag-state-toggle'),
                tooltip: _dragState
                    ? 'Drag vector is on: dragging the tip prepares a state'
                    : 'Drag vector is off: every drag turns the view',
                isSelected: _dragState,
                icon: const Icon(Icons.pan_tool_alt_outlined, size: 20),
                selectedIcon: const Icon(Icons.pan_tool_alt, size: 20),
                onPressed: () => setState(() => _dragState = !_dragState),
              )
            else
              Tooltip(
                message: 'When on, dragging the vector tip prepares a new '
                    'state. When off, every drag only turns the view.',
                child: FilterChip(
                  key: const ValueKey('bloch-drag-state-toggle'),
                  label: const Text('Drag vector', style: QqType.control),
                  selected: _dragState,
                  visualDensity: VisualDensity.compact,
                  onSelected: (v) => setState(() => _dragState = v),
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              key: const ValueKey('bloch-reset-view'),
              tooltip: 'Reset view',
              icon: const Icon(Icons.center_focus_strong, size: 20),
              onPressed: () =>
                  setState(() => _camera = const BlochCamera(zoom: 1.05)),
            ),
          ]),
        ),
        if (!compactControls)
          Positioned(
            left: 4,
            bottom: 2,
            child: IgnorePointer(
              child: Text(
                _dragState
                    ? 'Drag the tip to set a state · drag elsewhere to turn'
                    : 'Drag to turn the view · the state never changes',
                key: const ValueKey('bloch-sphere-hint'),
                style: QqType.meta.copyWith(fontSize: 12),
              ),
            ),
          ),
      ]);

  /// Legend: each element is told apart by shape and line style as well as
  /// colour.
  Widget _legend() {
    final o = _overlay;
    Widget item(Widget mark, String text, {Key? key}) => Row(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(width: 6),
            Flexible(child: Text(text, style: QqType.meta)),
          ],
        );
    Widget dot(Color c, {bool ring = false, bool centre = false}) => SizedBox(
          width: 14,
          height: 14,
          child:
              CustomPaint(painter: _MarkPainter(c, ring: ring, centre: centre)),
        );
    Widget line(Color c, {bool dashed = false}) => SizedBox(
          width: 22,
          height: 10,
          child: CustomPaint(painter: _LineMarkPainter(c, dashed: dashed)),
        );
    final playing = _animating != null;
    return Wrap(
      key: const ValueKey('bloch-legend'),
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 4,
      children: [
        item(
            dot(BlochOverlayColors.current),
            playing
                ? 'Vector on its path'
                : session.isInspecting
                    ? 'Inspected state'
                    : 'Current state'),
        if (o.startVector != null)
          item(dot(BlochOverlayColors.start, ring: true), 'Input state'),
        if (o.rotation != null &&
            o.startVector != null &&
            !o.rotation!.isOnAxis(o.startVector!) &&
            o.rotation!.angle.abs() > 1e-9)
          item(
              line(
                  o.applied
                      ? BlochOverlayColors.path
                      : BlochOverlayColors.preview,
                  dashed: !o.applied),
              o.applied ? 'Path taken' : 'Predicted path',
              key: const ValueKey('bloch-legend-path')),
        if (o.previewVector != null)
          item(
              dot(BlochOverlayColors.preview, ring: true, centre: true),
              _customOpen
                  ? 'Custom state (not prepared)'
                  : 'Preview: not applied',
              key: const ValueKey('bloch-legend-preview')),
        if (o.rotation != null)
          item(line(BlochOverlayColors.axis, dashed: true),
              _rotationCaption(o.rotation!)),
        if (o.basis != null)
          item(line(BlochOverlayColors.basis),
              '${o.basis!.label} measurement axis'),
        if (o.outcomeVector != null)
          item(dot(BlochOverlayColors.basis, ring: true),
              'State after the measurement'),
      ],
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

  /// Playback transport, next to the sphere. Every control does what it
  /// says: Play steps replays recorded steps, Apply (in the preview card)
  /// records one, and Animate when applying only changes how Apply looks.
  Widget _transport({bool compact = false}) {
    final applied = session.appliedCount;
    final focus = _focus;
    final hasSteps = applied > 0;
    final playLabel = _playing
        ? 'Pause'
        : _paused
            ? 'Resume'
            : 'Play steps';
    final status = _playing || _paused
        ? '${_paused ? 'Paused in' : 'Playing'} step $_playStep of $applied · '
            '${session.allSteps[_playStep! - 1].label}'
        : session.isInspecting
            ? focus == 0
                ? 'Showing Start ${session.initialLabel} · step 0 of $applied'
                : 'Showing step $focus of $applied · '
                    '${session.allSteps[focus - 1].label}'
            : applied == 0
                ? 'No steps yet · apply a gate to record one'
                : 'Showing the current state · $applied '
                    'step${applied == 1 ? '' : 's'}';
    final speed = SegmentedButton<double>(
      key: const ValueKey('bloch-speed'),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: QqType.control.copyWith(fontSize: 12.5),
      ),
      segments: const [
        ButtonSegment(value: .5, label: Text('0.5×')),
        ButtonSegment(value: 1, label: Text('1×')),
        ButtonSegment(value: 2, label: Text('2×')),
      ],
      selected: {_speed},
      onSelectionChanged: (s) => setSpeed(s.single),
    );
    final animate = Tooltip(
      message: 'How Apply is shown: along the rotation path, or at '
          'once. It never changes the result.',
      child: FilterChip(
        key: const ValueKey('bloch-animate-toggle'),
        label: Text(compact ? 'Animate' : 'Animate when applying',
            style: QqType.control),
        selected: _animate,
        visualDensity: VisualDensity.compact,
        onSelected: (v) => setState(() => _animate = v),
      ),
    );
    // Phones before any step (M11G): playback has nothing to replay, so
    // only the animation preferences stay, on one line, and the gates
    // stay close to the sphere. The full transport appears with the
    // first step.
    if (compact && !hasSteps) {
      return Wrap(
        key: const ValueKey('bloch-transport'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          animate,
          speed,
          Text('No steps yet',
              key: const ValueKey('bloch-playback-status'), style: QqType.meta),
        ],
      );
    }
    IconButton icon(String key, IconData data, String tip, VoidCallback? on) =>
        IconButton(
          key: ValueKey(key),
          tooltip: tip,
          onPressed: on,
          icon: Icon(data, size: 22),
        );
    return Column(
      key: const ValueKey('bloch-transport'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            icon('bloch-to-start', Icons.skip_previous_rounded, 'Show Start',
                hasSteps && focus > 0 ? toStart : null),
            icon(
                'bloch-step-back',
                Icons.chevron_left_rounded,
                'Step back (animated)',
                hasSteps && focus > 0 ? stepBack : null),
            FilledButton.icon(
              key: const ValueKey('bloch-play'),
              onPressed: !hasSteps
                  ? null
                  : _playing
                      ? pausePlayback
                      : playSteps,
              icon: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 20),
              label: Text(playLabel),
            ),
            icon(
                'bloch-step-forward',
                Icons.chevron_right_rounded,
                'Step forward (animated)',
                hasSteps && focus < applied ? stepForward : null),
            icon(
                'bloch-to-current',
                Icons.skip_next_rounded,
                'Show the current state',
                session.isInspecting || _playing || _paused ? toCurrent : null),
            const SizedBox(width: 8),
            speed,
            animate,
          ],
        ),
        const SizedBox(height: 2),
        Text(
          status,
          key: const ValueKey('bloch-playback-status'),
          textAlign: TextAlign.center,
          style: QqType.meta.copyWith(
              color: _playing || _paused || session.isInspecting
                  ? BlochOverlayColors.preview
                  : null),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ sections

  /// The six canonical states, arranged by the axis they sit on.
  Widget _canonicalStates({bool compact = false}) {
    final current = CanonicalQubitState.matching(session.initial);
    Widget state(CanonicalQubitState preset) => ChoiceChip(
          key: ValueKey('bloch-prep-${preset.name}'),
          label: Text(preset.label,
              style: QqType.math.copyWith(fontSize: 16, height: 1.1)),
          selected: current == preset &&
              session.appliedCount == 0 &&
              session.initialLabel == preset.label,
          visualDensity: VisualDensity.compact,
          onSelected: (_) => _prepare(preset.blochState, preset.label),
        );
    const rows = [
      ('Z', CanonicalQubitState.zero, CanonicalQubitState.one),
      ('X', CanonicalQubitState.plus, CanonicalQubitState.minus),
      ('Y', CanonicalQubitState.plusI, CanonicalQubitState.minusI),
    ];
    if (compact) {
      return Wrap(
        key: const ValueKey('bloch-prepare'),
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Prepare', style: QqType.subheading),
          for (final (_, plus, minus) in rows) ...[state(plus), state(minus)],
          // Custom preparation from the preparation area (M11G).
          FilterChip(
            key: const ValueKey('bloch-custom-chip'),
            label: const Text('Custom θ, φ', style: QqType.control),
            selected: _customOpen,
            visualDensity: VisualDensity.compact,
            onSelected: (open) => setState(() {
              _customOpen = open;
              if (open) _selected = null;
            }),
          ),
        ],
      );
    }
    return Column(
      key: const ValueKey('bloch-prepare'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('Prepare'),
        const QqMeta('Preparing a state starts a new exploration and clears '
            'the steps.'),
        const SizedBox(height: 8),
        for (final (axis, plus, minus) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(
                width: 56,
                child: Text('$axis axis', style: QqType.meta),
              ),
              Expanded(
                  child: Align(
                      alignment: Alignment.centerLeft, child: state(plus))),
              Expanded(
                  child: Align(
                      alignment: Alignment.centerLeft, child: state(minus))),
            ]),
          ),
      ],
    );
  }

  /// The custom state editor in its own frame (phones and short landscape
  /// windows, opened from the preparation chips).
  Widget _customCard() => Container(
        key: const ValueKey('bloch-custom-card'),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: QubitQuestSurfaces.work,
          borderRadius: QubitQuestRadii.card,
          border: Border.all(
              color: BlochOverlayColors.preview.withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Expanded(
                  child: Text('Custom state', style: QqType.subheading)),
              IconButton(
                key: const ValueKey('bloch-custom-close'),
                tooltip: 'Close the custom state',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() => _customOpen = false),
              ),
            ]),
            _customEditor(),
          ],
        ),
      );

  Widget _customAndComparisons({bool custom = true}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (custom)
            QqDisclosure(
              key: ValueKey('bloch-custom-$_customOpen'),
              toggleKey: const ValueKey('bloch-custom-toggle'),
              title: 'Custom state',
              summary: 'polar θ and azimuthal φ',
              initiallyExpanded: _customOpen,
              onChanged: (open) => setState(() {
                _customOpen = open;
                if (open) _selected = null;
              }),
              child: _customEditor(),
            ),
          QqDisclosure(
            toggleKey: const ValueKey('bloch-comparisons-toggle'),
            title: 'Phase comparisons',
            summary: '${blochPhaseComparisons().length} guided explorations',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final seed in blochPhaseComparisons())
                  TextButton.icon(
                    key: ValueKey('bloch-compare-${seed.sourceId}'),
                    onPressed: widget.onStartComparison == null
                        ? null
                        : () => widget.onStartComparison!(seed),
                    icon: const Icon(Icons.compare_arrows, size: 16),
                    label: Text(keepKetsTogether(seed.title),
                        style: QqType.control),
                  ),
              ],
            ),
          ),
        ],
      );

  Widget _customEditor() {
    final pole = _customTheta < 1e-9 || (math.pi - _customTheta) < 1e-9;
    return Column(
      key: const ValueKey('bloch-custom-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LatexText(
          math: r'\[\lvert\psi\rangle = \cos\tfrac{\theta}{2}\,\lvert0\rangle'
              r' + e^{i\varphi}\sin\tfrac{\theta}{2}\,\lvert1\rangle\]',
          textStyle: QqType.math,
          mathFontSize: 17,
          minimumDisplayMathScale: .8,
        ),
        _AngleControl(
          key: const ValueKey('bloch-custom-theta'),
          label: 'θ · polar angle from |0⟩',
          range: '0 to π',
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
          label: 'φ · azimuthal angle around Z, from +X',
          range: '0 to 2π',
          value: _customPhi,
          min: 0,
          max: 2 * math.pi,
          presets: const [0, math.pi / 2, math.pi, 3 * math.pi / 2],
          enabled: !pole,
          onChanged: (v) => setState(() => _customPhi = v % (2 * math.pi)),
        ),
        if (pole)
          const QqMeta(
            'At a pole one amplitude is zero, so φ is undefined and has no '
            'physical effect.',
            key: ValueKey('bloch-custom-pole-note'),
          ),
        const SizedBox(height: 4),
        QqCurrentStatePanel(
          key: ObjectKey(_customState),
          stateVector: [_customState.alpha, _customState.beta],
          numQubits: 1,
          expressionOnly: true,
          expressionStyle: QqType.stateExpression.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            key: const ValueKey('bloch-prep-custom-apply'),
            onPressed: () => _prepare(
                _customState,
                'θ=${blochAngle(_customTheta).split(' (').first}, '
                'φ=${blochAngle(_customPhi).split(' (').first}'),
            child: const Text('Prepare this state'),
          ),
        ),
      ],
    );
  }

  Widget _gateSection({bool compact = false}) {
    final selected = _selected;
    final locked = session.isInspecting || _animating != null;
    return Column(
      key: const ValueKey('bloch-gates'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('Transform'),
        if (!compact) ...[
          const QqMeta('Choose a gate to preview its effect; nothing changes '
              'until you apply it.'),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 2),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final type in blochLabGateTypes)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected == type && !locked
                      ? BlochOverlayColors.preview
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              // Dimmed and disabled while an earlier step is shown.
              child: Opacity(
                opacity: locked ? .35 : 1,
                child: QubitQuestGateTile(
                  key: ValueKey('bloch-gate-${type.name}'),
                  gate: Gate.fromIdentifier(type),
                  size: compact ? 42 : 46,
                  fontSize: 15,
                  tooltip: locked
                      ? 'Return to the current state to apply gates'
                      : GateEducationalCatalog.forType(type)?.name,
                  onPressed: locked ? null : () => selectGate(type),
                ),
              ),
            ),
        ]),
        if (session.isInspecting) ...[
          const SizedBox(height: 8),
          Text(
            'You are viewing an earlier step. Return to the current state '
            'to apply gates.',
            key: const ValueKey('bloch-gates-inspecting'),
            style: QqType.meta.copyWith(color: BlochOverlayColors.preview),
          ),
        ],
        if (selected != null && !locked) ...[
          const SizedBox(height: 12),
          KeyedSubtree(key: _previewKey, child: _previewCard(selected)),
        ],
      ],
    );
  }

  Widget _previewCard(SelectedGateType type) {
    final rotation = blochLabIsRotation(type);
    final preview = session.preview(type, angle: rotation ? _angle : null);
    final outcome = BlochStepOutcome.of(preview);
    final info = GateEducationalCatalog.forType(type);
    final gamma = outcome.globalPhase;
    final String? stationary = outcome.moves
        ? null
        : outcome.fullTurns > 0
            ? 'The vector travels ${outcome.fullTurns == 1 ? 'one full turn' : '${outcome.fullTurns} full turns'} '
                'around the axis and returns to where it started.'
            : 'The state lies on the rotation axis, so the Bloch vector does '
                'not move.';
    final String? phase = gamma == null
        ? null
        : gamma == 0
            ? 'The state vector is unchanged as well.'
            : 'The state vector is multiplied by '
                '${_phaseFactor(gamma)}: a global phase. The sphere cannot '
                'show it and no measurement of this qubit can detect it; '
                'the amplitudes keep it.';
    return Container(
      key: const ValueKey('bloch-preview-card'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        borderRadius: QubitQuestRadii.card,
        border:
            Border.all(color: BlochOverlayColors.preview.withValues(alpha: .5)),
        color: BlochOverlayColors.preview.withValues(alpha: .05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Preview · ${info?.name ?? preview.label}',
              style: QqType.subjectTitle.copyWith(fontSize: 15.5)),
          const SizedBox(height: 4),
          Text(
            '${_rotationCaption(preview.rotation)}.',
            key: const ValueKey('bloch-preview-rotation'),
            style: QqType.meta,
          ),
          if (rotation)
            _AngleControl(
              key: const ValueKey('bloch-rotation-angle'),
              label: 'Rotation angle θ',
              range: '−2π to 4π',
              value: _angle,
              min: -2 * math.pi,
              max: 4 * math.pi,
              presets: const [
                math.pi / 4,
                math.pi / 2,
                math.pi,
                3 * math.pi / 2,
                2 * math.pi,
                4 * math.pi,
              ],
              onChanged: setAngle,
            ),
          const SizedBox(height: 8),
          const Text('Result if applied', style: QqType.meta),
          const SizedBox(height: 2),
          // The shared expression (M11G): exact coefficients, ≈ only when
          // rounded, and a recognised state with its global phase.
          KeyedSubtree(
            key: const ValueKey('bloch-preview-result'),
            child: QqCurrentStatePanel(
              key: ObjectKey(preview.after),
              stateVector: [preview.after.alpha, preview.after.beta],
              numQubits: 1,
              stateLabel: '|ψ′⟩',
              expressionOnly: true,
              expressionStyle: QqType.stateExpression.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 10),
          // Actions before the longer explanations, so Apply and Cancel
          // stay in reach (M11G).
          Wrap(spacing: 8, runSpacing: 6, children: [
            FilledButton.icon(
              key: const ValueKey('bloch-apply'),
              onPressed: applySelected,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text('Apply ${preview.label}'),
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
          if (stationary != null) ...[
            const SizedBox(height: 8),
            Text('$stationary ${phase ?? ''}'.trim(),
                key: const ValueKey('bloch-preview-on-axis'),
                style: QqType.meta.copyWith(color: QubitQuestColors.textBody)),
          ],
          if (!rotation) ...[
            const SizedBox(height: 6),
            const QqMeta(
              'One equivalent rotation (up to global phase) is drawn; the '
              'gate itself is defined by its matrix, and the result above '
              'keeps its exact phase.',
              key: ValueKey('bloch-preview-equivalent-note'),
            ),
          ],
        ],
      ),
    );
  }

  /// e^{iγ} in readable form: −1, i, −i, or e^{i·angle}.
  static String _phaseFactor(double gamma) {
    if ((gamma.abs() - math.pi).abs() < 1e-9) return '−1';
    if ((gamma - math.pi / 2).abs() < 1e-9) return 'i';
    if ((gamma + math.pi / 2).abs() < 1e-9) return '−i';
    return 'e^(i·${blochAngle(gamma).split(' (').first})';
  }

  /// The timeline of applied steps: each step shows its position, gate and
  /// angle, and the state it produced; the step on screen is highlighted.
  Widget _timeline() {
    final steps = session.allSteps;
    final applied = session.appliedCount;
    final focus = _focus;
    Widget node(int index) {
      final redo = index > applied;
      final isFocus = index == focus;
      final s = session.stateAt(index);
      final named = blochCanonicalName(s);
      final title = index == 0 ? 'Start' : '$index · ${steps[index - 1].label}';
      final result = index == 0
          ? session.initialLabel
          : named ??
              'θ ${blochAngle(s.theta).split(' (').first}, '
                  'φ ${s.hasDefinedRelativePhase ? blochAngle(s.phi).split(' (').first : '—'}';
      return Tooltip(
        message: '${index == 0 ? 'Start' : 'After step $index'}: '
            '${formatQuantumStateExpression([s.alpha, s.beta], numQubits: 1)}',
        waitDuration: const Duration(milliseconds: 500),
        child: Material(
          color: isFocus
              ? QubitQuestColors.navigationSelected
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: QubitQuestRadii.control,
            side: BorderSide(
                color: isFocus
                    ? QubitQuestColors.accentInteractive
                    : QubitQuestSurfaces.rule),
          ),
          child: InkWell(
            key: ValueKey('bloch-step-$index'),
            borderRadius: QubitQuestRadii.control,
            onTap: redo
                ? null
                : () {
                    _stopMotion();
                    session.inspect(index);
                    setState(() {});
                  },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: QqType.navLabel.copyWith(
                          fontWeight: FontWeight.w600,
                          color: redo
                              ? QubitQuestColors.textMuted
                              : isFocus
                                  ? QubitQuestColors.accentInteractive
                                  : null)),
                  Text(redo ? 'undone · redo to restore' : result,
                      style: QqType.navMeta),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final nodes = <Widget>[node(0)];
    for (var i = 0; i < steps.length; i++) {
      nodes
        ..add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.arrow_forward_rounded,
              size: 16, color: QubitQuestColors.textMuted),
        ))
        ..add(node(i + 1));
    }
    return Column(
      key: const ValueKey('bloch-evolution'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              const _Label('Steps'),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  session.isInspecting
                      ? 'Viewing step $focus of $applied (read-only)'
                      : '$applied step${applied == 1 ? '' : 's'} recorded',
                  key: const ValueKey('bloch-evolution-status'),
                  overflow: TextOverflow.ellipsis,
                  style: QqType.meta.copyWith(
                      color: session.isInspecting
                          ? BlochOverlayColors.preview
                          : null),
                ),
              ),
              if (session.isInspecting && !_playing)
                TextButton(
                  key: const ValueKey('bloch-return-current'),
                  onPressed: toCurrent,
                  child: const Text('Return to current'),
                ),
              IconButton(
                key: const ValueKey('bloch-undo'),
                tooltip: 'Undo the last step',
                onPressed: session.canUndo
                    ? () {
                        _stopMotion();
                        session.undo();
                      }
                    : null,
                icon: const Icon(Icons.undo, size: 20),
              ),
              IconButton(
                key: const ValueKey('bloch-redo'),
                tooltip: 'Redo',
                onPressed: session.canRedo
                    ? () {
                        _stopMotion();
                        session.redo();
                      }
                    : null,
                icon: const Icon(Icons.redo, size: 20),
              ),
              TextButton.icon(
                key: const ValueKey('bloch-reset'),
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(widget.exploration == null
                    ? 'Reset to ${session.initialLabel}'
                    : widget.exploration!.seed.origin == BlochLabOrigin.notebook
                        ? 'Reset to example'
                        : 'Reset'),
              ),
            ]),
        const SizedBox(height: 4),
        SingleChildScrollView(
          key: const ValueKey('bloch-timeline-scroll'),
          scrollDirection: Axis.horizontal,
          child: Row(children: nodes),
        ),
      ],
    );
  }

  /// How the sphere and the numbers relate right now (M11G): the numbers
  /// always show a completed, recorded state; a moving vector is an
  /// illustration of the step's rotation path; an earlier step is history.
  /// Null when the sphere simply shows the current state.
  String? get _presentationNote {
    final applied = session.appliedCount;
    final k = _playStep;
    if (_playing && k != null) {
      return 'Replaying step $k of $applied: the vector traces the step’s '
          'rotation path as an illustration. The numbers show the state '
          'after step $k, where the path ends.';
    }
    if (_paused && k != null) {
      return 'Paused part-way along step $k: the vector’s position is '
          'illustrative only. The numbers show the state after step $k.';
    }
    final inspected = session.inspectedIndex;
    if (_animating != null && inspected != null) {
      return 'The vector is drawing a step’s rotation path. The numbers '
          'show ${inspected == 0 ? 'the Start state' : 'the state after step $inspected'}, '
          'where the path ends.';
    }
    if (_animating != null) {
      return 'Applied. The vector is drawing the rotation path as an '
          'illustration; the numbers already show the completed step.';
    }
    if (inspected != null) {
      return 'History: ${inspected == 0 ? 'the Start state' : 'the state after step $inspected of $applied'}. '
          'Your current state is unchanged; Show current returns to it.';
    }
    return null;
  }

  /// State summary, first in the State and measurement panel (M11G): the
  /// expression, then a compact geometry summary. The detailed mathematics
  /// follows the measurement experiment ([_stateDetails]).
  Widget _stateSection() {
    final s = session.displayed;
    final defined = s.hasDefinedRelativePhase;
    final label = _playing || _paused
        ? 'State after step $_playStep (replay)'
        : session.isInspecting
            ? session.inspectedIndex == 0
                ? 'Start state'
                : 'State after step ${session.inspectedIndex}'
            : 'Current state';
    final note = _presentationNote;
    return Column(
      key: const ValueKey('bloch-state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              note,
              key: const ValueKey('bloch-presentation-note'),
              style: QqType.meta.copyWith(color: BlochOverlayColors.preview),
            ),
          ),
        // The Composer's own expression: exact coefficients (≈ when any is
        // rounded) and a recognised state with its global phase.
        KeyedSubtree(
          key: const ValueKey('bloch-state-expression'),
          child: QqCurrentStatePanel(
            key: ObjectKey(s),
            stateVector: [s.alpha, s.beta],
            numQubits: 1,
            expressionOnly: true,
          ),
        ),
        const SizedBox(height: 8),
        QqFactList(
          key: const ValueKey('bloch-geometry'),
          labelWidth: 92,
          facts: [
            (
              'Bloch vector',
              Text(
                  '(${blochNumber(s.x)}, ${blochNumber(s.y)}, '
                  '${blochNumber(s.z)})',
                  key: const ValueKey('bloch-cartesian')),
            ),
            (
              'Angles',
              Wrap(spacing: 14, runSpacing: 2, children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(
                        text: 'θ ', style: TextStyle(color: _alphaColor)),
                    TextSpan(text: blochAngle(s.theta).split(' (').first),
                  ]),
                  key: const ValueKey('bloch-theta'),
                ),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(
                        text: 'φ ', style: TextStyle(color: _betaColor)),
                    TextSpan(
                        text: defined
                            ? blochAngle(s.phi).split(' (').first
                            : 'undefined at the pole'),
                  ]),
                  key: const ValueKey('bloch-phi'),
                ),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  /// The detailed mathematics, after the measurement experiment: exact and
  /// decimal amplitudes with the complex plane, phase, the Bloch-vector
  /// derivation and the precision note.
  Widget _stateDetails() {
    final s = session.displayed;
    final defined = s.hasDefinedRelativePhase;
    final globalAngle = s.alphaMagnitude > blochAmplitudeEpsilon
        ? math.atan2(s.alpha.imaginary.toDouble(), s.alpha.real.toDouble())
        : math.atan2(s.beta.imaginary.toDouble(), s.beta.real.toDouble());
    String short(double a) => blochAngle(a).split(' (').first;
    String exact(Complex c) => formatQuantumAmplitude(c);
    String approx(Complex c) {
      final e = exact(c);
      final d = blochComplex(c);
      return e == d || quantumAmplitudeIsApproximate(e) ? e : '$e ≈ $d';
    }

    return Column(
      key: const ValueKey('bloch-state-details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('Mathematical details'),
        QqDisclosure(
          toggleKey: const ValueKey('bloch-amplitudes-toggle'),
          title: 'Complex amplitudes',
          summary: 'α = ${exact(s.alpha)} · β = ${exact(s.beta)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                ComplexAmplitudePlane(
                  size: 132,
                  amplitudes: [
                    PlottedAmplitude('α', s.alpha, _alphaColor),
                    PlottedAmplitude('β', s.beta, _betaColor),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    key: const ValueKey('bloch-amplitudes'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Value('α', approx(s.alpha), color: _alphaColor),
                      _Value('|α|²', formatProbability(s.probabilityZero)),
                      const SizedBox(height: 4),
                      _Value('β', approx(s.beta), color: _betaColor),
                      _Value('|β|²', formatProbability(s.probabilityOne)),
                      const SizedBox(height: 4),
                      _Value(
                          '|α|² + |β|²',
                          formatProbability(
                              s.probabilityZero + s.probabilityOne)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              const QqMeta('Arrows show the actual amplitudes, including the '
                  'global phase. The sphere ignores global phase. |α|² and '
                  '|β|² are the Z-basis probabilities.'),
            ],
          ),
        ),
        QqDisclosure(
          toggleKey: const ValueKey('bloch-phase-toggle'),
          title: 'Phase',
          summary: defined
              ? 'relative ${short(s.phi)} · global ${short(globalAngle)}'
              : 'relative undefined · global ${short(globalAngle)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                defined
                    ? 'Relative phase arg(β) − arg(α) = ${blochAngle(s.phi)}. '
                        'It sets the direction around the Z axis and is '
                        'physical.'
                    : 'Relative phase is undefined: one amplitude is zero, so '
                        'the state sits at a pole and φ has no physical '
                        'meaning.',
                key: const ValueKey('bloch-relative-phase'),
              ),
              const SizedBox(height: 6),
              Text(
                'Global phase as written: ${blochAngle(globalAngle)} (the '
                'phase of the first non-zero amplitude). Multiplying the '
                'whole state by e^(iγ) changes neither the sphere nor any '
                'measurement of this qubit: a global phase is not an '
                'observable on its own, so it is kept in the amplitudes '
                'only.',
                key: const ValueKey('bloch-global-phase'),
                style: QqType.meta,
              ),
            ],
          ),
        ),
        const QqDisclosure(
          toggleKey: ValueKey('bloch-relations-toggle'),
          title: 'From amplitudes to the Bloch vector',
          summary: 'x, y, z and θ, φ',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LatexText(
                math: r'\[x = 2\,\mathrm{Re}(\alpha^{*}\beta),\quad'
                    r' y = 2\,\mathrm{Im}(\alpha^{*}\beta),\quad'
                    r' z = |\alpha|^{2} - |\beta|^{2}\]',
                textStyle: QqType.math,
                mathFontSize: 16,
                minimumDisplayMathScale: .75,
              ),
              LatexText(
                math: r'\[|\psi\rangle = e^{i\gamma}\left(\cos\tfrac{\theta}{2}'
                    r'\,|0\rangle + e^{i\varphi}\sin\tfrac{\theta}{2}\,'
                    r'|1\rangle\right)\]',
                textStyle: QqType.math,
                mathFontSize: 16,
                minimumDisplayMathScale: .75,
              ),
            ],
          ),
        ),
        const QqDisclosure(
          toggleKey: ValueKey('bloch-precision-toggle'),
          title: 'About amplitude precision',
          summary: 'exact values and rounding',
          child: Text(qqAmplitudePrecisionNote,
              key: ValueKey('bloch-precision-note')),
        ),
      ],
    );
  }

  /// The measurement experiment (M11G order): basis, controls, exact and
  /// observed outcomes, the result, and the Z basis for comparison when
  /// another basis is measured.
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
    final deterministic =
        plus <= probabilityZeroTolerance || minus <= probabilityZeroTolerance;
    String count(int n) => formatCount(n);
    return Column(
      key: const ValueKey('bloch-measure'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('Measure'),
        SegmentedButton<BlochBasis>(
          key: const ValueKey('bloch-basis'),
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact, textStyle: QqType.control),
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
            _basisShown = true;
            _single = null;
            _shots = null;
          }),
        ),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonal(
                key: const ValueKey('bloch-run-once'),
                onPressed: _measureOnce,
                child: const Text('Measure once'),
              ),
              FilledButton(
                key: const ValueKey('bloch-run-shots'),
                onPressed: _measureShots,
                child: Text('Run ${count(_shotCount)} shots'),
              ),
            ]),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Shots', style: QqType.meta),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SegmentedButton<int>(
                key: const ValueKey('bloch-shot-count'),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity:
                      const VisualDensity(horizontal: -2, vertical: -2),
                  textStyle: QqType.control.copyWith(fontSize: 13),
                ),
                segments: [
                  for (final n in const [100, 1000, 10000])
                    ButtonSegment(
                        value: n,
                        label: Text(count(n),
                            key: ValueKey('bloch-shot-count-$n'))),
                ],
                selected: {_shotCount},
                onSelectionChanged: (v) => setState(() {
                  _shotCount = v.single;
                  _shots = null;
                }),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        QqMeta(session.isInspecting
            ? 'Measures the state shown (step ${session.inspectedIndex}). '
                'The steps are not changed.'
            : 'Each run prepares the state again, so the state above is '
                'never collapsed.'),
        const SizedBox(height: 10),
        Text(
          shots == null
              ? 'Exact probabilities · ${_basis.label} basis'
              : 'Exact and observed · ${_basis.label} basis',
          key: const ValueKey('bloch-measure-heading'),
          style: QqType.subheading,
        ),
        const SizedBox(height: 4),
        Column(key: const ValueKey('bloch-exact'), children: [
          _OutcomeRow(_basis.plusLabel, plus,
              observed: shots == null ? null : shots.plusCount / shots.shots,
              count: shots?.plusCount),
          _OutcomeRow(_basis.minusLabel, minus,
              observed: shots == null ? null : shots.minusCount / shots.shots,
              count: shots?.minusCount),
        ]),
        const SizedBox(height: 4),
        MeasurementComparisonLegend(
            key: const ValueKey('bloch-measure-legend'),
            observed: shots != null,
            exact: true),
        const SizedBox(height: 2),
        QqMeta('$formula · ${switch (_basis) {
          BlochBasis.z => 'measured directly',
          BlochBasis.x => 'H, then measure in Z',
          BlochBasis.y => 'S†, then H, then measure in Z',
        }} · the ${_basis.label} axis is highlighted on the sphere'),
        if (single != null) ...[
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('bloch-single-result'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: QubitQuestRadii.control,
              border: Border.all(
                  color: BlochOverlayColors.basis.withValues(alpha: .5)),
            ),
            child: Text(
              deterministic
                  ? 'Outcome: ${single.label}. This outcome was certain '
                      '(probability 100%): the state lies on the '
                      '${_basis.label} axis, so every run gives '
                      '${single.label}. The prepared state is unchanged.'
                  : 'Outcome: ${single.label} (probability '
                      '${formatProbability(single.plus ? plus : minus)}). '
                      'The outcome is random; only its probabilities are '
                      'fixed by the state. Just after this measurement the '
                      'qubit is in ${single.label} (green ring on the '
                      'sphere). The prepared state is unchanged: each run '
                      'prepares it again.',
              style: QqType.body.copyWith(fontSize: 14),
            ),
          ),
        ],
        if (shots != null) ...[
          const SizedBox(height: 8),
          Text(
            deterministic
                ? '${count(shots.shots)} independent preparations, each '
                    'measured once: all ${count(shots.shots)} gave '
                    '${shots.plusCount == shots.shots ? _basis.plusLabel : _basis.minusLabel}, '
                    'as the exact probability of 100% predicts.'
                : '${count(shots.shots)} independent preparations, each '
                    'measured once: ${count(shots.plusCount)} × '
                    '${_basis.plusLabel}, ${count(shots.minusCount)} × '
                    '${_basis.minusLabel}. Observed frequencies vary from '
                    'run to run around the exact probabilities.',
            key: const ValueKey('bloch-shots-result'),
            style: QqType.body.copyWith(fontSize: 14),
          ),
        ],
        if (_basis != BlochBasis.z) ...[
          const SizedBox(height: 14),
          Text('Z basis, for comparison (not measured here)',
              key: const ValueKey('bloch-z-reference'),
              style: QqType.subheading.copyWith(fontSize: 13.5)),
          const SizedBox(height: 2),
          _OutcomeRow('|0⟩', s.probabilityZero),
          _OutcomeRow('|1⟩', s.probabilityOne),
          const QqMeta('The same state gives a different distribution in '
              'each basis.'),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------ small parts

class _Pane extends StatelessWidget {
  const _Pane({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: WebBlochWorkspaceState._paneDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: QqPanelLabel(label),
            ),
            Expanded(child: child),
          ],
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Semantics(
            header: true, child: Text(text, style: QqType.subjectTitle)),
      );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color, {this.ring = false, this.centre = false});
  final Color color;
  final bool ring;
  final bool centre;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (ring) {
      canvas.drawCircle(
          c,
          5.5,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      if (centre) canvas.drawCircle(c, 2, Paint()..color = color);
    } else {
      canvas.drawCircle(c, 5.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) =>
      old.color != color || old.ring != ring || old.centre != centre;
}

class _LineMarkPainter extends CustomPainter {
  const _LineMarkPainter(this.color, {this.dashed = false});
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(1, y), Offset(size.width - 1, y), paint);
      return;
    }
    for (var x = 1.0; x < size.width; x += 8) {
      canvas.drawLine(
          Offset(x, y), Offset(math.min(x + 4, size.width - 1), y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineMarkPainter old) =>
      old.color != color || old.dashed != dashed;
}

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
    final n = seed.gates.length;
    return Container(
      key: const ValueKey('bloch-exploration-banner'),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: QubitQuestColors.accentInteractive.withValues(alpha: .06),
        borderRadius: QubitQuestRadii.card,
        border: Border.all(
            color: QubitQuestColors.accentInteractive.withValues(alpha: .3)),
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
                  style: QqType.bodyStrong),
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
          // What was transferred, exactly.
          Text(
            'Loaded: start ${seed.initialLabel}'
            '${n == 0 ? '' : ' and $n step${n == 1 ? '' : 's'} '
                '(${seed.gates.map((g) => g.label.split('\n').first).join(', ')})'}, '
            'with exact amplitudes. Isolated: nothing here changes your '
            'Sandbox, progress or own lab.',
            key: const ValueKey('bloch-exploration-transfer'),
            style: QqType.meta,
          ),
          if (seed.note != null)
            Text(
              seed.note!,
              key: const ValueKey('bloch-exploration-note'),
              maxLines: compact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: QqType.meta.copyWith(color: QubitQuestColors.textBody),
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
    required this.range,
    required this.value,
    required this.min,
    required this.max,
    required this.presets,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final String range;
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
          const SizedBox(height: 8),
          Text('${widget.label} · ${widget.range}', style: QqType.meta),
          Row(children: [
            Expanded(
              // The exact value, with its π form where it has one.
              child: Text(blochAngle(widget.value),
                  style: QqType.bodyStrong.copyWith(
                      color:
                          widget.enabled ? null : QubitQuestColors.textMuted)),
            ),
            SizedBox(
              width: 112,
              child: TextField(
                key: const ValueKey('angle-entry'),
                controller: _text,
                enabled: widget.enabled,
                style: QqType.table.copyWith(fontSize: 15),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'π/3 or 1.05',
                  labelText: 'Radians',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    style: QqType.control.copyWith(fontSize: 13)),
                onPressed: widget.enabled ? () => widget.onChanged(p) : null,
              ),
          ]),
          if (_error != null)
            Text(_error!,
                style: QqType.meta.copyWith(color: QubitQuestColors.error)),
        ],
      );
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value, {this.color});
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
                      color: color ?? QubitQuestColors.textMuted,
                      fontWeight: FontWeight.w500)),
              TextSpan(text: value),
            ]),
            style: QqType.table.copyWith(fontSize: 13.5)),
      );
}

/// One outcome: its ket, the shared exact/observed bar (exact probability
/// as a cyan outline, observed frequency filled purple, as in the
/// Composer's Measure view), and the values in the same two colours.
class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow(this.label, this.exact, {this.observed, this.count});
  final String label;
  final double exact;
  final double? observed;
  final int? count;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: [
          'P($label) exact ${formatProbability(exact)}',
          if (observed != null)
            'observed ${formatProbability(observed!)}'
                '${count == null ? '' : ' (${formatCount(count!)})'}',
        ].join(' · '),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(
              width: 46,
              child: Text(label,
                  style: QqType.table.copyWith(
                      color: QqType.ketColor, fontWeight: FontWeight.w500)),
            ),
            Expanded(child: ComparisonBar(exact: exact, observed: observed)),
            SizedBox(
              width: 62,
              child: Text(
                formatProbability(exact),
                textAlign: TextAlign.right,
                style: QqType.table.copyWith(
                    fontSize: 13.5,
                    color: QubitQuestColors.accentInteractive,
                    fontWeight: FontWeight.w500),
              ),
            ),
            if (observed != null)
              SizedBox(
                width: 62,
                child: Text(
                  formatProbability(observed!),
                  textAlign: TextAlign.right,
                  style: QqType.table.copyWith(
                      fontSize: 13.5,
                      color: const Color(0xFFB794F6),
                      fontWeight: FontWeight.w500),
                ),
              ),
          ]),
        ),
      );
}

class _Scroll extends StatelessWidget {
  const _Scroll({super.key, required this.padding, required this.children});
  final EdgeInsets padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
}

/// The state as one of the six canonical states with its exact phase
/// factor: "|1⟩", "−|0⟩", "i|1⟩", "e^(i·π/4)|+⟩"; null for other states.
/// Equal Bloch vectors with different factors are named differently.
String? blochCanonicalName(BlochState s) {
  final c = CanonicalQubitState.matching(s, tolerance: 1e-7);
  if (c == null) return null;
  final ref = c.amplitudes;
  final useAlpha = ref[0].abs() >= ref[1].abs();
  final a = useAlpha ? s.alpha : s.beta;
  final r = useAlpha ? ref[0] : ref[1];
  var gamma = math.atan2(a.imaginary.toDouble(), a.real.toDouble()) -
      math.atan2(r.imaginary.toDouble(), r.real.toDouble());
  while (gamma <= -math.pi) {
    gamma += 2 * math.pi;
  }
  while (gamma > math.pi) {
    gamma -= 2 * math.pi;
  }
  bool near(double x, double y) => (x - y).abs() < 1e-7;
  final prefix = near(gamma, 0)
      ? ''
      : near(gamma.abs(), math.pi)
          ? '−'
          : near(gamma, math.pi / 2)
              ? 'i'
              : near(gamma, -math.pi / 2)
                  ? '−i'
                  : 'e^(i·${blochAngle(gamma).split(' (').first})';
  return '$prefix${c.label}';
}
