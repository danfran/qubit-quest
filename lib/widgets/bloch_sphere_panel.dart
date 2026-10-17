import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

enum BlochSphereGestureMode { state, orbit, zoom }

const blochTelemetryTextStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
);

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

class BlochSpherePanel extends StatefulWidget {
  const BlochSpherePanel({
    super.key,
    this.reserveOverlaySafeRegions = false,
    this.showAnnotations = true,
    this.showHelper = true,
    this.compactAnnotations = false,
    this.overlaySphereFraction = .74,
    this.overlaySphereAlignment = Alignment.center,
    this.interactive = true,
    this.allowStateEditing = true,
    required this.state,
    required this.camera,
    required this.onCameraChanged,
    required this.onStatePreview,
    required this.onStateCommitted,
    required this.onGestureStarted,
    required this.onStateGestureStarted,
  });

  final bool reserveOverlaySafeRegions;
  final bool showAnnotations;
  final bool showHelper;
  final bool compactAnnotations;
  final double overlaySphereFraction;
  final Alignment overlaySphereAlignment;
  final bool interactive;

  /// False enables camera gestures without allowing vector/state manipulation.
  final bool allowStateEditing;
  final BlochState state;
  final BlochCamera camera;
  final ValueChanged<BlochCamera> onCameraChanged;
  final ValueChanged<BlochState> onStatePreview;
  final ValueChanged<BlochState> onStateCommitted;
  final VoidCallback onGestureStarted;
  final BlochState Function() onStateGestureStarted;

  @override
  State<BlochSpherePanel> createState() => _BlochSpherePanelState();
}

class _BlochSpherePanelState extends State<BlochSpherePanel> {
  BlochSphereGestureMode? _mode;
  BlochCamera? _startCamera;
  Offset? _startPoint;
  BlochState? _latestState;

  Widget _interactiveCanvas() => LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final projection = BlochProjection(size: size, camera: widget.camera);
        final canvas = CustomPaint(
          key: const ValueKey('bloch-sphere-canvas'),
          painter:
              BlochSpherePainter(state: widget.state, camera: widget.camera),
          child: const SizedBox.expand(),
        );
        if (!widget.interactive) return canvas;
        return RawGestureDetector(
          key: const ValueKey('bloch-sphere-gesture'),
          behavior: HitTestBehavior.opaque,
          gestures: {
            _BlochScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
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
                    _mode = widget.allowStateEditing
                        ? BlochGestureResolver.resolveMode(
                            details.localFocalPoint, tip)
                        : BlochSphereGestureMode.orbit;
                    _latestState = _mode == BlochSphereGestureMode.state
                        ? widget.onStateGestureStarted()
                        : widget.state;
                  }
                  ..onUpdate = (details) {
                    final initialCamera = _startCamera ?? widget.camera;
                    if (details.pointerCount > 1) {
                      _mode = BlochSphereGestureMode.zoom;
                      widget
                          .onCameraChanged(initialCamera.scale(details.scale));
                    } else if (_mode == BlochSphereGestureMode.state) {
                      _latestState = projection.stateForPoint(
                        details.localFocalPoint,
                        globalPhase: _latestState!.globalPhase,
                      );
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
          child: canvas,
        );
      });

  Widget _angles() => _LiveValues(
        key: const ValueKey('bloch-live-angles'),
        compact: widget.compactAnnotations,
        values: [('θ', widget.state.theta), ('φ', widget.state.phi)],
      );

  Widget _cartesian() => _LiveValues(
        key: const ValueKey('bloch-live-cartesian'),
        compact: widget.compactAnnotations,
        alignment: CrossAxisAlignment.end,
        values: [
          ('x', widget.state.x),
          ('y', widget.state.y),
          ('z', widget.state.z),
        ],
      );

  Widget _probabilities() => IgnorePointer(
        child: Container(
          key: const ValueKey('bloch-live-probabilities'),
          padding: widget.compactAnnotations
              ? const EdgeInsets.symmetric(horizontal: 5, vertical: 1)
              : const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xD9000712),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DefaultTextStyle.merge(
            style: widget.compactAnnotations
                ? blochTelemetryTextStyle.copyWith(height: .85)
                : blochTelemetryTextStyle,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
      );

  Widget get _helper => Text(
        key: const ValueKey('bloch-sphere-helper'),
        widget.interactive
            ? 'Drag vector • orbit elsewhere • pinch to zoom'
            : 'Live circuit state',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: QubitQuestDialog.mutedText,
          fontSize: 10,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!widget.showAnnotations) {
      return KeyedSubtree(
        key: const ValueKey('bloch-sphere-panel'),
        child: _interactiveCanvas(),
      );
    }
    if (widget.reserveOverlaySafeRegions) {
      return CustomMultiChildLayout(
        key: const ValueKey('bloch-sphere-panel'),
        delegate: _BlochLandscapeOverlayLayout(
          sphereFraction: widget.overlaySphereFraction,
          sphereAlignment: widget.overlaySphereAlignment,
        ),
        children: [
          LayoutId(id: _BlochOverlaySlot.canvas, child: _interactiveCanvas()),
          LayoutId(
            id: _BlochOverlaySlot.helper,
            child: IgnorePointer(
              child: widget.showHelper ? _helper : const SizedBox.shrink(),
            ),
          ),
          LayoutId(id: _BlochOverlaySlot.angles, child: _angles()),
          LayoutId(id: _BlochOverlaySlot.cartesian, child: _cartesian()),
          LayoutId(
              id: _BlochOverlaySlot.probabilities, child: _probabilities()),
        ],
      );
    }
    return Stack(
      key: const ValueKey('bloch-sphere-panel'),
      children: [
        Positioned.fill(top: 18, child: _interactiveCanvas()),
        Positioned(
          top: 0,
          left: 2,
          right: 2,
          child: IgnorePointer(child: _helper),
        ),
        Positioned(top: 22, left: 2, child: _angles()),
        Positioned(top: 22, right: 2, child: _cartesian()),
        Positioned(bottom: 2, left: 2, child: _probabilities()),
      ],
    );
  }
}

enum _BlochOverlaySlot { canvas, helper, angles, cartesian, probabilities }

class _BlochLandscapeOverlayLayout extends MultiChildLayoutDelegate {
  _BlochLandscapeOverlayLayout({
    required this.sphereFraction,
    required this.sphereAlignment,
  });

  final double sphereFraction;
  final Alignment sphereAlignment;

  static const double edgeInset = 2;
  static const double safeGap = 6;

  @override
  void performLayout(Size size) {
    final loose = BoxConstraints.loose(size);
    final helper = layoutChild(_BlochOverlaySlot.helper, loose);
    final helperRect = Rect.fromLTWH(
      (size.width - helper.width) / 2,
      0,
      helper.width,
      helper.height,
    );
    positionChild(_BlochOverlaySlot.helper, helperRect.topLeft);

    final angles = layoutChild(_BlochOverlaySlot.angles, loose);
    final overlayTop =
        helper.height == 0 ? edgeInset : helperRect.bottom + safeGap;
    final anglesRect =
        Rect.fromLTWH(edgeInset, overlayTop, angles.width, angles.height);
    positionChild(_BlochOverlaySlot.angles, anglesRect.topLeft);
    final cartesian = layoutChild(_BlochOverlaySlot.cartesian, loose);
    final cartesianRect = Rect.fromLTWH(
      size.width - cartesian.width - edgeInset,
      overlayTop,
      cartesian.width,
      cartesian.height,
    );
    positionChild(_BlochOverlaySlot.cartesian, cartesianRect.topLeft);

    final probabilities = layoutChild(_BlochOverlaySlot.probabilities, loose);
    final probabilityRect = Rect.fromLTWH(
      edgeInset,
      size.height - probabilities.height - edgeInset,
      probabilities.width,
      probabilities.height,
    );
    positionChild(_BlochOverlaySlot.probabilities, probabilityRect.topLeft);

    final usablePane = Rect.fromLTRB(
      edgeInset,
      overlayTop,
      size.width - edgeInset,
      size.height - edgeInset,
    );
    final sphereExtent = usablePane.shortestSide * sphereFraction;
    final canvasRect = Rect.fromCenter(
      center: sphereAlignment.inscribe(Size.zero, usablePane).center,
      width: sphereExtent,
      height: sphereExtent,
    );
    layoutChild(
        _BlochOverlaySlot.canvas, BoxConstraints.tight(canvasRect.size));
    positionChild(_BlochOverlaySlot.canvas, canvasRect.topLeft);
  }

  @override
  bool shouldRelayout(covariant _BlochLandscapeOverlayLayout oldDelegate) =>
      sphereFraction != oldDelegate.sphereFraction ||
      sphereAlignment != oldDelegate.sphereAlignment;
}

class _LiveValues extends StatelessWidget {
  const _LiveValues({
    super.key,
    required this.values,
    this.alignment = CrossAxisAlignment.start,
    this.compact = false,
  });

  final List<(String, double)> values;
  final CrossAxisAlignment alignment;
  final bool compact;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 5, vertical: 1)
              : const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xD9000712),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: alignment,
            children: [
              for (final value in values)
                Text(
                  '${value.$1} = ${value.$2.toStringAsFixed(3)}',
                  style: compact
                      ? blochTelemetryTextStyle.copyWith(height: .85)
                      : blochTelemetryTextStyle,
                ),
            ],
          ),
        ),
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

  Offset safeLabelCenter(
    Offset point,
    Size labelSize, {
    double horizontalInset = 8,
    double topInset = 8,
    double bottomInset = 8,
  }) =>
      Offset(
        point.dx.clamp(horizontalInset + labelSize.width / 2,
            size.width - horizontalInset - labelSize.width / 2),
        point.dy.clamp(topInset + labelSize.height / 2,
            size.height - bottomInset - labelSize.height / 2),
      );

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
