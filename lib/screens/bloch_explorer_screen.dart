import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

class BlochExplorerScreen extends StatefulWidget {
  const BlochExplorerScreen({super.key});

  @override
  State<BlochExplorerScreen> createState() => _BlochExplorerScreenState();
}

class _BlochExplorerScreenState extends State<BlochExplorerScreen>
    with SingleTickerProviderStateMixin {
  static const _gateTransitionDuration = Duration(milliseconds: 650);
  static const _replayTransitionDuration = Duration(milliseconds: 420);
  static const _replayStepGap = Duration(milliseconds: 90);

  late final BlochExplorerHistory _history;
  late final AnimationController _animation;
  BlochState _displayState = BlochState.zero;
  BlochState? _animationStart;
  BlochState? _animationEnd;
  BlochCamera _camera = const BlochCamera();
  double _rotationAngle = math.pi / 2;
  double _globalPhase = 0;
  bool _instant = false;
  bool _isReplaying = false;
  int _replayGeneration = 0;

  @override
  void initState() {
    super.initState();
    _history = BlochExplorerHistory()..addListener(_historyChanged);
    _animation = AnimationController(
      vsync: this,
      duration: _gateTransitionDuration,
    )
      ..addListener(_tickAnimation)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _displayState = _animationEnd ?? _displayState);
        }
      });
  }

  @override
  void dispose() {
    _replayGeneration++;
    _animation.stop();
    _history
      ..removeListener(_historyChanged)
      ..dispose();
    _animation.dispose();
    super.dispose();
  }

  void _historyChanged() {
    _animation.stop();
    setState(() {
      _displayState = _history.state;
      _globalPhase = _history.state.globalPhase;
    });
  }

  void _tickAnimation() {
    final start = _animationStart;
    final end = _animationEnd;
    if (start == null || end == null) return;
    final t = Curves.easeInOut.transform(_animation.value);
    setState(() => _displayState = BlochState.interpolate(start, end, t));
  }

  void _applyGate(SelectedGateType type) {
    _cancelReplay();
    final source = _history.state;
    final angle = switch (type) {
      SelectedGateType.rx ||
      SelectedGateType.ry ||
      SelectedGateType.rz =>
        _rotationAngle,
      _ => 0.0,
    };
    final target = source.applyGate(type, angle: angle);
    final gate = Gate.fromIdentifier(type,
        angle: type == SelectedGateType.rx ||
                type == SelectedGateType.ry ||
                type == SelectedGateType.rz
            ? angle
            : null);
    _history.commit(gate.label.replaceAll('\n', ' '), target);
    if (_instant) return;
    _animation.duration = _gateTransitionDuration;
    _animationStart = source;
    _animationEnd = target;
    _displayState = _animationStart!;
    _animation.forward(from: 0);
  }

  Future<void> _replay() async {
    final sequence = _history.replaySequence;
    if (sequence.isEmpty || _isReplaying) return;
    _animation.stop();
    final generation = ++_replayGeneration;
    setState(() {
      _isReplaying = true;
      _displayState = sequence.first.source;
    });

    try {
      for (var index = 0; index < sequence.length; index++) {
        if (!mounted || generation != _replayGeneration) return;
        final transition = sequence[index];
        _animationStart = transition.source;
        _animationEnd = transition.destination;
        _animation.duration = _replayTransitionDuration;
        setState(() => _displayState = transition.source);
        await _animation.forward(from: 0).orCancel;
        if (index + 1 < sequence.length) {
          await Future<void>.delayed(_replayStepGap);
        }
      }
    } on TickerCanceled {
      return;
    } finally {
      if (mounted && generation == _replayGeneration) {
        _animation.duration = _gateTransitionDuration;
        setState(() {
          _isReplaying = false;
          _displayState = _history.state;
        });
      }
    }
  }

  void _cancelReplay({bool restoreCommittedState = true}) {
    _replayGeneration++;
    _animation.stop();
    if (!_isReplaying || !mounted) return;
    setState(() {
      _isReplaying = false;
      if (restoreCommittedState) _displayState = _history.state;
    });
  }

  void _undo() {
    _cancelReplay();
    _history.undo();
  }

  void _redo() {
    _cancelReplay();
    _history.redo();
  }

  void _reset() {
    _cancelReplay(restoreCommittedState: false);
    _history.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00030A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00030A),
        surfaceTintColor: Colors.transparent,
        title: const Text('Bloch Explorer',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final sphere = IgnorePointer(
            ignoring: _isReplaying,
            child: _SpherePanel(
              state: _displayState,
              camera: _camera,
              onCameraChanged: (camera) => setState(() => _camera = camera),
              onStatePreview: (state) => setState(() => _displayState = state),
              onStateCommitted: (state) =>
                  _history.commit('Direct state', state),
              onGestureStarted: _animation.stop,
            ),
          );
          final workspace = _buildWorkspace(sphere, wide: wide);
          return ListView(
            key: const ValueKey('bloch-explorer-scroll'),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            children: [
              if (wide)
                Row(
                    key: const ValueKey('bloch-landscape-top-row'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(children: [
                          workspace,
                          const SizedBox(height: 6),
                          _buildHistory(),
                        ]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 5,
                        child: _buildMathsAction(expanded: true),
                      ),
                    ])
              else ...[
                workspace,
                const SizedBox(height: 6),
                _buildHistory(),
                const SizedBox(height: 6),
                _buildMathsAction(),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWorkspace(Widget sphere, {required bool wide}) => Container(
        key: const ValueKey('bloch-primary-workspace'),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: QubitQuestDialog.panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: QubitQuestDialog.borderColor),
        ),
        child: Column(children: [
          SizedBox(height: wide ? 330 : 350, child: sphere),
          const SizedBox(height: 4),
          _buildGateStrip(),
          const SizedBox(height: 4),
          _buildTransportControls(),
        ]),
      );

  Widget _buildGateStrip() => Container(
        key: const ValueKey('bloch-gate-strip'),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 14, runSpacing: 6, children: [
            _gateGroup('Pauli', const [
              SelectedGateType.x,
              SelectedGateType.y,
              SelectedGateType.z,
            ]),
            _gateGroup('Hadamard', const [SelectedGateType.hadamard]),
            _gateGroup('Phase', const [
              SelectedGateType.s,
              SelectedGateType.t,
            ]),
          ]),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, constraints) {
            final angleWidth = math.max(130.0, constraints.maxWidth - 170);
            return Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                _gateGroup('Rotations', const [
                  SelectedGateType.rx,
                  SelectedGateType.ry,
                  SelectedGateType.rz,
                ]),
                SizedBox(
                  key: const ValueKey('bloch-gate-angle-control'),
                  width: angleWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Gate angle: ${_formatAngle(_rotationAngle)}',
                          style: const TextStyle(
                              color: QubitQuestDialog.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                      SizedBox(
                        height: 38,
                        child: Slider(
                          key: const ValueKey('bloch-rotation-slider'),
                          value: _rotationAngle,
                          min: -math.pi,
                          max: math.pi,
                          divisions: 16,
                          onChanged: (value) =>
                              setState(() => _rotationAngle = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ]),
      );

  Widget _gateGroup(String label, List<SelectedGateType> types) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: QubitQuestDialog.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [for (final type in types) _gateChip(type)],
          ),
        ],
      );

  Widget _gateChip(SelectedGateType type) {
    final gate = Gate.fromIdentifier(type,
        angle: type == SelectedGateType.rx ||
                type == SelectedGateType.ry ||
                type == SelectedGateType.rz
            ? _rotationAngle
            : null);
    return QubitQuestGateTile(
      key: ValueKey('bloch-gate-${type.name}'),
      gate: gate,
      size: 44,
      tooltip: 'Apply ${gate.label.replaceAll('\n', ' ')} gate',
      onPressed: _isReplaying ? null : () => _applyGate(type),
    );
  }

  Widget _buildTransportControls() => Container(
        key: const ValueKey('bloch-transport-controls'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: QubitQuestDialog.innerColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final controls = <Widget>[
            _transportButton(
                key: 'bloch-undo',
                label: 'Undo',
                icon: Icons.undo_rounded,
                onPressed: !_isReplaying && _history.canUndo ? _undo : null),
            _transportButton(
                key: 'bloch-redo',
                label: 'Redo',
                icon: Icons.redo_rounded,
                onPressed: !_isReplaying && _history.canRedo ? _redo : null),
            _transportButton(
                key: 'bloch-replay',
                label: 'Replay',
                icon: Icons.play_circle_outline_rounded,
                onPressed: !_isReplaying && _history.replaySequence.isNotEmpty
                    ? _replay
                    : null),
            _transportButton(
                key: 'bloch-reset',
                label: 'Reset',
                icon: Icons.restart_alt_rounded,
                onPressed: _reset),
          ];
          final instant = Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bolt_rounded, size: 16),
            const Text('Instant', style: TextStyle(fontSize: 11)),
            Checkbox(
              key: const ValueKey('bloch-instant-mode'),
              value: _instant,
              visualDensity: VisualDensity.compact,
              onChanged: (value) => setState(() => _instant = value ?? false),
            ),
          ]);
          return Row(children: [
            Expanded(
              child: Row(children: [
                for (final control in controls) Expanded(child: control),
              ]),
            ),
            instant,
          ]);
        }),
      );

  Widget _transportButton({
    required String key,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) =>
      Semantics(
        key: ValueKey(key),
        button: true,
        enabled: onPressed != null,
        label: label,
        child: Tooltip(
          message: label,
          child: TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            ),
            onPressed: onPressed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(fontSize: 10, height: 1),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildMathsAction({bool expanded = false}) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: expanded ? double.infinity : null,
          child: OutlinedButton.icon(
            key: const ValueKey('bloch-maths-action'),
            onPressed: _showMathsDetails,
            icon: const Icon(Icons.functions_rounded, size: 18),
            label: const Text('Maths / state details'),
          ),
        ),
      );

  Future<void> _showMathsDetails() => showDialog<void>(
        context: context,
        builder: (dialogContext) => QubitQuestDialog(
          title: 'State maths',
          maxWidth: 560,
          actions: [
            QubitQuestDialogButton.primary(
              label: 'Close',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          child: _StateMathsDialogContent(
            state: _displayState,
            globalPhase: _globalPhase,
          ),
        ),
      );

  Widget _buildHistory() => Container(
        key: const ValueKey('bloch-history-container'),
        decoration: BoxDecoration(
          color: QubitQuestDialog.panelColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: QubitQuestDialog.borderColor),
        ),
        child: ExpansionTile(
          key: const ValueKey('bloch-history-expansion'),
          dense: true,
          visualDensity: VisualDensity.compact,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          title: const Text('History',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          subtitle: Text('${_history.entries.length} operations',
              style: const TextStyle(fontSize: 10)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_history.entries
                  .asMap()
                  .entries
                  .map((entry) => entry.key == _history.index
                      ? '● ${entry.value.label}'
                      : '○ ${entry.value.label}')
                  .join('  →  ')),
            ),
          ],
        ),
      );

  String _formatAngle(double angle) {
    final ratio = angle / math.pi;
    if (ratio.abs() < 1e-9) return '0';
    for (final denominator in [1, 2, 4, 8]) {
      final numerator = (ratio * denominator).round();
      if ((ratio - numerator / denominator).abs() < 1e-9) {
        if (denominator == 1) return numerator == 1 ? 'π' : '$numeratorπ';
        return '$numeratorπ/$denominator';
      }
    }
    return '${angle.toStringAsFixed(2)} rad';
  }
}

enum BlochSphereGestureMode { state, orbit, zoom }

class BlochGestureResolver {
  const BlochGestureResolver._();

  static const double vectorTipHitRadius = 22;
  static const double orbitSensitivity = .01;

  static BlochSphereGestureMode resolveMode(Offset start, Offset vectorTip) =>
      (start - vectorTip).distance <= vectorTipHitRadius
          ? BlochSphereGestureMode.state
          : BlochSphereGestureMode.orbit;

  static BlochCamera orbit({
    required BlochCamera camera,
    required Offset dragDelta,
  }) =>
      camera.orbit(
        deltaYaw: dragDelta.dx * orbitSensitivity,
        deltaPitch: -dragDelta.dy * orbitSensitivity,
      );
}

class _BlochScaleGestureRecognizer extends ScaleGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _SpherePanel extends StatefulWidget {
  const _SpherePanel({
    required this.state,
    required this.camera,
    required this.onCameraChanged,
    required this.onStatePreview,
    required this.onStateCommitted,
    required this.onGestureStarted,
  });

  final BlochState state;
  final BlochCamera camera;
  final ValueChanged<BlochCamera> onCameraChanged;
  final ValueChanged<BlochState> onStatePreview;
  final ValueChanged<BlochState> onStateCommitted;
  final VoidCallback onGestureStarted;

  @override
  State<_SpherePanel> createState() => _SpherePanelState();
}

class _SpherePanelState extends State<_SpherePanel> {
  BlochSphereGestureMode? _mode;
  BlochCamera? _startCamera;
  Offset? _startPoint;
  BlochState? _latestState;

  @override
  Widget build(BuildContext context) => Stack(
        key: const ValueKey('bloch-sphere-panel'),
        children: [
          Positioned.fill(
              top: 18,
              child: LayoutBuilder(builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final projection =
                    BlochProjection(size: size, camera: widget.camera);
                return RawGestureDetector(
                  key: const ValueKey('bloch-sphere-gesture'),
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    _BlochScaleGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            _BlochScaleGestureRecognizer>(
                      _BlochScaleGestureRecognizer.new,
                      (recognizer) {
                        recognizer
                          ..onStart = (details) {
                            final tip = projection.project(
                                widget.state.x, widget.state.y, widget.state.z);
                            widget.onGestureStarted();
                            _startCamera = widget.camera;
                            _startPoint = details.localFocalPoint;
                            _latestState = widget.state;
                            _mode = BlochGestureResolver.resolveMode(
                                details.localFocalPoint, tip);
                          }
                          ..onUpdate = (details) {
                            final initialCamera = _startCamera ?? widget.camera;
                            if (details.pointerCount > 1) {
                              _mode = BlochSphereGestureMode.zoom;
                              widget.onCameraChanged(
                                  initialCamera.scale(details.scale));
                            } else if (_mode == BlochSphereGestureMode.state) {
                              _latestState = projection.stateForPoint(
                                  details.localFocalPoint,
                                  globalPhase: widget.state.globalPhase);
                              widget.onStatePreview(_latestState!);
                            } else {
                              widget.onCameraChanged(BlochGestureResolver.orbit(
                                camera: initialCamera,
                                dragDelta: details.localFocalPoint -
                                    (_startPoint ?? details.localFocalPoint),
                              ));
                            }
                          }
                          ..onEnd = (_) {
                            if (_mode == BlochSphereGestureMode.state &&
                                _latestState != null) {
                              widget.onStateCommitted(_latestState!);
                            }
                            _mode = null;
                            _startCamera = null;
                            _startPoint = null;
                            _latestState = null;
                          };
                      },
                    ),
                  },
                  child: CustomPaint(
                    key: const ValueKey('bloch-sphere-canvas'),
                    painter: BlochSpherePainter(
                        state: widget.state, camera: widget.camera),
                    child: const SizedBox.expand(),
                  ),
                );
              })),
          const Positioned(
            top: 0,
            left: 2,
            right: 2,
            child: IgnorePointer(
              child: Text(
                'Drag vector • orbit elsewhere • pinch to zoom',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: QubitQuestDialog.mutedText,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          Positioned(
            top: 22,
            left: 2,
            child: _LiveValues(
              key: const ValueKey('bloch-live-angles'),
              values: [
                ('θ', widget.state.theta),
                ('φ', widget.state.phi),
              ],
            ),
          ),
          Positioned(
            top: 22,
            right: 2,
            child: _LiveValues(
              key: const ValueKey('bloch-live-cartesian'),
              alignment: CrossAxisAlignment.end,
              values: [
                ('x', widget.state.x),
                ('y', widget.state.y),
                ('z', widget.state.z),
              ],
            ),
          ),
          Positioned(
            bottom: 2,
            left: 2,
            child: IgnorePointer(
              child: Container(
                key: const ValueKey('bloch-live-probabilities'),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xD9000712),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'P(|0⟩) = ${(widget.state.probabilityZero * 100).toStringAsFixed(1)}%',
                    ),
                    Text(
                      'P(|1⟩) = ${(widget.state.probabilityOne * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

class _LiveValues extends StatelessWidget {
  const _LiveValues({
    super.key,
    required this.values,
    this.alignment = CrossAxisAlignment.start,
  });

  final List<(String, double)> values;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xD9000712),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: alignment,
            children: [
              for (final value in values)
                Text(
                  '${value.$1} = ${value.$2.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 11),
                ),
            ],
          ),
        ),
      );
}

class _StateMathsDialogContent extends StatelessWidget {
  const _StateMathsDialogContent({
    required this.state,
    required this.globalPhase,
  });

  final BlochState state;
  final double globalPhase;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('bloch-maths-dialog-content'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LatexText(
            key: ValueKey('bloch-wavefunction-latex'),
            math:
                r'\[|\psi\rangle=\cos(\theta/2)|0\rangle+e^{i\varphi}\sin(\theta/2)|1\rangle\]',
            textStyle: TextStyle(
              color: QubitQuestDialog.cyan,
              fontWeight: FontWeight.w700,
            ),
            inlineMathColor: QubitQuestDialog.cyan,
            displayMathHeight: 24,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 5,
            children: [
              _detailValue('θ', state.theta),
              _detailValue('φ', state.phi),
              _detailValue('x', state.x),
              _detailValue('y', state.y),
              _detailValue('z', state.z),
              Text(
                  'P(|0⟩) = ${(state.probabilityZero * 100).toStringAsFixed(1)}%'),
              Text(
                  'P(|1⟩) = ${(state.probabilityOne * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const Divider(height: 24),
          const Text('Column vector',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LatexText(
              key: ValueKey('bloch-column-vector-latex'),
              math:
                  r'\[|\psi\rangle=\begin{bmatrix}\cos(\theta/2)\\e^{i\varphi}\sin(\theta/2)\end{bmatrix}\]',
              textStyle: TextStyle(color: Color(0xFFD6E3F8)),
              inlineMathColor: Colors.white,
              displayMathHeight: 34,
            ),
          ),
          const Divider(height: 24),
          Text('Global phase γ: ${globalPhase.toStringAsFixed(2)} rad',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Multiplying the whole state by e^(iγ) changes neither the Bloch position nor measurement probabilities. Relative phase φ, by contrast, changes the Bloch position.',
            style: TextStyle(color: QubitQuestDialog.mutedText, height: 1.35),
          ),
        ],
      );

  static Widget _detailValue(String label, double value) =>
      Text('$label = ${value.toStringAsFixed(3)}');
}

class BlochProjection {
  const BlochProjection({required this.size, required this.camera});
  final Size size;
  final BlochCamera camera;

  Offset get center => size.center(Offset.zero);
  double get radius => math.min(size.width, size.height) * .38 * camera.zoom;

  Offset project(double x, double y, double z) {
    final rotated = _rotate(x, y, z);
    return center + Offset(rotated.$1 * radius, -rotated.$3 * radius);
  }

  Offset safeLabelCenter(
    Offset point,
    Size labelSize, {
    double horizontalInset = 8,
    double topInset = 8,
    double bottomInset = 8,
  }) {
    return Offset(
      point.dx.clamp(horizontalInset + labelSize.width / 2,
          size.width - horizontalInset - labelSize.width / 2),
      point.dy.clamp(topInset + labelSize.height / 2,
          size.height - bottomInset - labelSize.height / 2),
    );
  }

  ({Offset point, double depth}) projectWithDepth(
      double x, double y, double z) {
    final rotated = _rotate(x, y, z);
    return (
      point: center + Offset(rotated.$1 * radius, -rotated.$3 * radius),
      depth: rotated.$2,
    );
  }

  BlochState stateForPoint(Offset point, {required double globalPhase}) {
    final sx = ((point.dx - center.dx) / radius).clamp(-1.0, 1.0);
    final sz = (-(point.dy - center.dy) / radius).clamp(-1.0, 1.0);
    final sy = math.sqrt(math.max(0, 1 - sx * sx - sz * sz));
    final world = _inverseRotate(sx, sy, sz);
    return BlochState.fromCartesian(world.$1, world.$2, world.$3,
        globalPhase: globalPhase);
  }

  (double, double, double) _rotate(double x, double y, double z) {
    final cy = math.cos(camera.yaw), sy = math.sin(camera.yaw);
    final cp = math.cos(camera.pitch), sp = math.sin(camera.pitch);
    final x1 = x * cy - y * sy;
    final y1 = x * sy + y * cy;
    return (x1, y1 * cp + z * sp, -y1 * sp + z * cp);
  }

  (double, double, double) _inverseRotate(double x, double y, double z) {
    final cp = math.cos(camera.pitch), sp = math.sin(camera.pitch);
    final cy = math.cos(camera.yaw), sy = math.sin(camera.yaw);
    final y1 = y * cp - z * sp;
    final z1 = y * sp + z * cp;
    return (x * cy + y1 * sy, -x * sy + y1 * cy, z1);
  }
}

class BlochSpherePainter extends CustomPainter {
  const BlochSpherePainter({required this.state, required this.camera});
  final BlochState state;
  final BlochCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    final p = BlochProjection(size: size, camera: camera);
    final center = p.center;
    final radius = p.radius;
    final sphere = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.35, -.4),
        colors: [
          QubitQuestDialog.cyan.withValues(alpha: .18),
          QubitQuestDialog.innerColor.withValues(alpha: .06),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sphere);
    final front = Paint()
      ..color = QubitQuestDialog.cyan.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final back = Paint()
      ..color = QubitQuestDialog.cyan.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(center, radius, front);
    _circle(canvas, p, front, back,
        (angle) => (math.cos(angle), math.sin(angle), 0.0));
    _circle(canvas, p, front, back,
        (angle) => (math.cos(angle), 0.0, math.sin(angle)));
    for (final z in [-.5, .5]) {
      final r = math.sqrt(1 - z * z);
      _circle(canvas, p, front, back,
          (angle) => (r * math.cos(angle), r * math.sin(angle), z));
    }
    _axis(canvas, p, 1.25, 0, 0, 'X', front);
    _axis(canvas, p, 0, 1.25, 0, 'Y', front);
    _axis(canvas, p, 0, 0, 1.25, 'Z', front);
    final tip = p.project(state.x, state.y, state.z);
    canvas.drawLine(
        center,
        tip,
        Paint()
          ..color = QubitQuestDialog.purple
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(tip, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
        tip,
        13,
        Paint()
          ..color = QubitQuestDialog.purple.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  void _circle(
    Canvas canvas,
    BlochProjection projection,
    Paint front,
    Paint back,
    (double, double, double) Function(double angle) pointAt,
  ) {
    const segments = 72;
    var previousWorld = pointAt(0);
    var previous = projection.projectWithDepth(
        previousWorld.$1, previousWorld.$2, previousWorld.$3);
    for (var index = 1; index <= segments; index++) {
      final world = pointAt(2 * math.pi * index / segments);
      final current = projection.projectWithDepth(world.$1, world.$2, world.$3);
      canvas.drawLine(previous.point, current.point,
          (previous.depth + current.depth) / 2 >= 0 ? front : back);
      previous = current;
    }
  }

  void _axis(Canvas canvas, BlochProjection p, double x, double y, double z,
      String label, Paint paint) {
    final a = p.project(-x, -y, -z);
    final b = p.project(x, y, z);
    canvas.drawLine(a, b, paint);
    final text = TextPainter(
      text: TextSpan(
          text: label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelCenter = p.safeLabelCenter(b, text.size);
    text.paint(canvas, labelCenter - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant BlochSpherePainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.camera != camera;
}
