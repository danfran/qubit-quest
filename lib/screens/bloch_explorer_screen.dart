import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

class BlochExplorerScreen extends StatefulWidget {
  const BlochExplorerScreen({super.key});

  @override
  State<BlochExplorerScreen> createState() => _BlochExplorerScreenState();
}

class _BlochExplorerScreenState extends State<BlochExplorerScreen>
    with SingleTickerProviderStateMixin {
  late final BlochExplorerHistory _history;
  late final AnimationController _animation;
  BlochState _displayState = BlochState.zero;
  BlochState? _animationStart;
  BlochState? _animationEnd;
  BlochCamera _camera = const BlochCamera();
  double _rotationAngle = math.pi / 2;
  double _globalPhase = 0;
  bool _instant = false;

  @override
  void initState() {
    super.initState();
    _history = BlochExplorerHistory()..addListener(_historyChanged);
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
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
    _animationStart = source;
    _animationEnd = target;
    _displayState = _animationStart!;
    _animation.forward(from: 0);
  }

  void _replay() {
    final transition = _history.replayTransition;
    if (transition == null) return;
    _animation.stop();
    _animationStart = transition.source;
    _animationEnd = transition.destination;
    if (_instant) {
      setState(() => _displayState = transition.destination);
      return;
    }
    setState(() => _displayState = transition.source);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animation.forward(from: 0);
    });
  }

  void _setGlobalPhase(double value) {
    setState(() {
      _globalPhase = value;
      _displayState = _displayState.withGlobalPhase(value);
    });
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
        actions: [
          IconButton(
            tooltip: 'Reset state',
            onPressed: _history.reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final sphere = _SpherePanel(
            state: _displayState,
            camera: _camera,
            onCameraChanged: (camera) => setState(() => _camera = camera),
            onStatePreview: (state) => setState(() => _displayState = state),
            onStateCommitted: (state) => _history.commit('Direct state', state),
            onGestureStarted: _animation.stop,
          );
          final details = _StateDetails(
            state: _displayState,
            globalPhase: _globalPhase,
            onGlobalPhaseChanged: _setGlobalPhase,
          );
          final sphereWithControls = Column(children: [
            Expanded(child: sphere),
            const SizedBox(height: 8),
            _buildTransportControls(),
          ]);
          return ListView(
            key: const ValueKey('bloch-explorer-scroll'),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            children: [
              if (wide)
                SizedBox(
                  height: math.max(420, constraints.maxHeight * .58),
                  child: Row(children: [
                    Expanded(flex: 6, child: sphereWithControls),
                    const SizedBox(width: 14),
                    Expanded(
                        flex: 5, child: SingleChildScrollView(child: details)),
                  ]),
                )
              else ...[
                SizedBox(height: 430, child: sphereWithControls),
                const SizedBox(height: 12),
                details,
              ],
              const SizedBox(height: 14),
              _buildGateLab(),
              const SizedBox(height: 12),
              _buildHistory(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildGateLab() => _Panel(
        title: 'Gate laboratory',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 14, runSpacing: 10, children: [
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
            _gateGroup('Rotations', const [
              SelectedGateType.rx,
              SelectedGateType.ry,
              SelectedGateType.rz,
            ]),
          ]),
          const SizedBox(height: 12),
          Text('Rotation angle: ${_formatAngle(_rotationAngle)}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          Slider(
            key: const ValueKey('bloch-rotation-slider'),
            value: _rotationAngle,
            min: -math.pi,
            max: math.pi,
            divisions: 16,
            onChanged: (value) => setState(() => _rotationAngle = value),
          ),
          ExpansionTile(
            key: const ValueKey('bloch-animation-settings'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Animation',
                style: TextStyle(fontWeight: FontWeight.w800)),
            children: [
              SwitchListTile.adaptive(
                key: const ValueKey('bloch-instant-mode'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Instant mode'),
                subtitle: const Text('Skip the educational vector transition'),
                value: _instant,
                onChanged: (value) => setState(() => _instant = value),
              ),
            ],
          ),
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

  Widget _gateChip(SelectedGateType type) => ActionChip(
        key: ValueKey('bloch-gate-${type.name}'),
        label: Text(Gate.fromIdentifier(type,
                angle: type == SelectedGateType.rx ||
                        type == SelectedGateType.ry ||
                        type == SelectedGateType.rz
                    ? _rotationAngle
                    : null)
            .label
            .replaceAll('\n', ' ')),
        onPressed: () => _applyGate(type),
      );

  Widget _buildTransportControls() => Container(
        key: const ValueKey('bloch-transport-controls'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: QubitQuestDialog.panelColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: QubitQuestDialog.borderColor),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _transportButton(
              key: 'bloch-undo',
              tooltip: 'Undo',
              icon: Icons.undo_rounded,
              onPressed: _history.canUndo ? _history.undo : null),
          _transportButton(
              key: 'bloch-redo',
              tooltip: 'Redo',
              icon: Icons.redo_rounded,
              onPressed: _history.canRedo ? _history.redo : null),
          _transportButton(
              key: 'bloch-replay',
              tooltip: 'Replay',
              icon: Icons.replay_rounded,
              onPressed: _history.replayTransition != null ? _replay : null),
          _transportButton(
              key: 'bloch-reset',
              tooltip: 'Reset',
              icon: Icons.restart_alt_rounded,
              onPressed: _history.reset),
        ]),
      );

  Widget _transportButton({
    required String key,
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) =>
      IconButton(
        key: ValueKey(key),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon),
      );

  Widget _buildHistory() => _Panel(
        title: 'History',
        child: ExpansionTile(
          key: const ValueKey('bloch-history-expansion'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text('${_history.entries.length} operations'),
          subtitle: const Text('Show state journey'),
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
  Widget build(BuildContext context) => _Panel(
        title: '',
        expandChild: true,
        trailing: const Text('Drag vector • orbit elsewhere • pinch to zoom',
            style: TextStyle(color: QubitQuestDialog.mutedText, fontSize: 11)),
        child: LayoutBuilder(builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight - 8);
          final projection = BlochProjection(size: size, camera: widget.camera);
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
        }),
      );
}

class _StateDetails extends StatelessWidget {
  const _StateDetails({
    required this.state,
    required this.globalPhase,
    required this.onGlobalPhaseChanged,
  });
  final BlochState state;
  final double globalPhase;
  final ValueChanged<double> onGlobalPhaseChanged;

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'Current state',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const LatexText(
            key: ValueKey('bloch-wavefunction-latex'),
            math:
                r'\[|\psi\rangle=\cos(\theta/2)|0\rangle+e^{i\phi}\sin(\theta/2)|1\rangle\]',
            textStyle: TextStyle(
              color: QubitQuestDialog.cyan,
              fontWeight: FontWeight.w700,
            ),
            inlineMathColor: QubitQuestDialog.cyan,
            displayMathHeight: 20,
          ),
          _value('θ', state.theta),
          _value('φ (relative phase)', state.phi),
          _value('x', state.x),
          _value('y', state.y),
          _value('z', state.z),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: LatexText(
              key: ValueKey('bloch-column-vector-latex'),
              math:
                  r'\[|\psi\rangle=\begin{bmatrix}\cos(\theta/2)\\e^{i\phi}\sin(\theta/2)\end{bmatrix}\]',
              textStyle: TextStyle(color: Color(0xFFD6E3F8)),
              inlineMathColor: Colors.white,
              displayMathHeight: 21,
            ),
          ),
          Text('P(|0⟩) = ${(state.probabilityZero * 100).toStringAsFixed(1)}%'),
          Text('P(|1⟩) = ${(state.probabilityOne * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 8),
          ExpansionTile(
            key: const ValueKey('bloch-global-phase-expansion'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Advanced',
                style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Global phase γ'),
            children: [
              Text('Global phase γ: ${globalPhase.toStringAsFixed(2)} rad'),
              Slider(
                key: const ValueKey('bloch-global-phase-slider'),
                value: globalPhase,
                min: 0,
                max: 2 * math.pi,
                onChanged: onGlobalPhaseChanged,
              ),
              const Text(
                'Unlike relative phase φ, multiplying the whole ket by e^(iγ) changes neither the Bloch position nor its probabilities.',
                style:
                    TextStyle(color: QubitQuestDialog.mutedText, height: 1.35),
              ),
            ],
          ),
        ]),
      );

  Widget _value(String label, double value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text('$label = ${value.toStringAsFixed(3)}'),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.trailing,
    this.expandChild = false,
  });
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool expandChild;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QubitQuestDialog.panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: QubitQuestDialog.borderColor),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (title.isNotEmpty || trailing != null) ...[
            Row(children: [
              if (title.isNotEmpty)
                Expanded(
                  flex: trailing == null ? 1 : 2,
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                ),
              if (trailing != null)
                Expanded(
                  flex: 3,
                  child:
                      Align(alignment: Alignment.centerRight, child: trailing!),
                ),
            ]),
            const SizedBox(height: 10),
          ],
          if (expandChild) Expanded(child: child) else child,
        ]),
      );
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
    text.paint(canvas, b - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant BlochSpherePainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.camera != camera;
}
