import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/bloch_lab.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
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
    this.overlay,
    this.showStateLabels = false,
  });

  /// Draws |0⟩ |1⟩ |±⟩ |±i⟩ beside the six poles (v2.6 M11D).
  final bool showStateLabels;

  /// Optional laboratory overlays (v2.6 M8); none by default.
  final BlochSphereOverlay? overlay;
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
          painter: BlochSpherePainter(
              state: widget.state,
              camera: widget.camera,
              overlay: widget.overlay,
              stateLabels: widget.showStateLabels),
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
                  '${value.$1} = ${blochNumber(value.$2, digits: 3)}',
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

/// What the Bloch Explorer draws on top of the sphere (v2.6 M8).
@immutable
class BlochSphereOverlay {
  const BlochSphereOverlay({
    this.startVector,
    this.previewVector,
    this.rotation,
    this.basis,
    this.basisLabels = false,
    this.applied = false,
    this.outcomeVector,
  });

  /// The trajectory is an applied (or replayed) step rather than a
  /// prediction: drawn solid and quieter instead of dashed (v2.6 M11F).
  final bool applied;

  /// The post-measurement state of the last single measurement (a ring on
  /// the measured axis end); never the state itself.
  final (double, double, double)? outcomeVector;

  /// The input state of a transformation (hollow marker).
  final (double, double, double)? startVector;

  /// The state a previewed gate would produce (dashed amber).
  final (double, double, double)? previewVector;

  /// The equivalent rotation: its axis and the full-angle trajectory of
  /// [startVector] are drawn.
  final BlochRotation? rotation;

  /// Highlighted measurement axis.
  final BlochBasis? basis;

  /// Labels |0⟩, |1⟩, |±⟩, |±i⟩ at the axis ends.
  final bool basisLabels;

  @override
  bool operator ==(Object other) =>
      other is BlochSphereOverlay &&
      other.startVector == startVector &&
      other.previewVector == previewVector &&
      other.rotation?.axis == rotation?.axis &&
      other.rotation?.angle == rotation?.angle &&
      other.basis == basis &&
      other.basisLabels == basisLabels &&
      other.applied == applied &&
      other.outcomeVector == outcomeVector;

  @override
  int get hashCode => Object.hash(startVector, previewVector, rotation?.axis,
      rotation?.angle, basis, basisLabels, applied, outcomeVector);
}

/// Overlay colours, shared with the Explorer's legend.
abstract final class BlochOverlayColors {
  static const current = QubitQuestDialog.purple;
  static const start = Color(0xFF9FB0CC);
  static const preview = Color(0xFFFFC857);
  static const axis = Color(0xFFFFC857);
  static const basis = Color(0xFF7CFFB2);
  static const path = Color(0xFF9FB0CC);
}

class BlochSpherePainter extends CustomPainter {
  const BlochSpherePainter({
    required this.state,
    required this.camera,
    this.overlay,
    this.stateLabels = false,
  });
  final BlochState state;
  final BlochCamera camera;
  final BlochSphereOverlay? overlay;

  /// Canonical states at the six poles (|0⟩ |1⟩ |+⟩ |−⟩ |+i⟩ |−i⟩), placed
  /// from the same projection as the sphere (v2.6 M11D).
  final bool stateLabels;

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
    final o = overlay;
    if (o != null) _paintOverlay(canvas, p, o);
    final tip = p.project(state.x, state.y, state.z);
    if (stateLabels) {
      _paintStateLabels(canvas, p, tip, [
        for (final v in [o?.startVector, o?.previewVector, o?.outcomeVector])
          if (v != null) p.project(v.$1, v.$2, v.$3),
      ]);
    }
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

  void _paintOverlay(Canvas canvas, BlochProjection p, BlochSphereOverlay o) {
    final center = p.center;
    Offset at((double, double, double) v, [double scale = 1]) =>
        p.project(v.$1 * scale, v.$2 * scale, v.$3 * scale);
    if (o.basisLabels) {
      for (final (v, label) in const [
        ((0.0, 0.0, 1.0), '|0⟩'),
        ((0.0, 0.0, -1.0), '|1⟩'),
        ((1.0, 0.0, 0.0), '|+⟩'),
        ((-1.0, 0.0, 0.0), '|−⟩'),
        ((0.0, 1.0, 0.0), '|+i⟩'),
        ((0.0, -1.0, 0.0), '|−i⟩'),
      ]) {
        // Offset beside the axis end so the label never sits on the axis
        // letter or on a vector tip.
        _label(canvas, p, at(v, 1.12) + const Offset(18, 10), label,
            const Color(0xFFB6C4DA), 11, FontWeight.w600);
      }
    }
    final basis = o.basis;
    if (basis != null) {
      final paint = Paint()
        ..color = BlochOverlayColors.basis
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final plus = at(basis.axis), minus = at(_neg(basis.axis));
      canvas.drawLine(minus, plus, paint);
      canvas.drawCircle(plus, 6, Paint()..color = BlochOverlayColors.basis);
      canvas.drawCircle(minus, 6, Paint()..color = BlochOverlayColors.basis);
    }
    final rotation = o.rotation;
    final start = o.startVector;
    if (rotation != null) {
      final axisPaint = Paint()
        ..color = BlochOverlayColors.axis.withValues(alpha: .85)
        ..strokeWidth = 2;
      _dashed(canvas, at(_neg(rotation.axis), 1.18), at(rotation.axis, 1.18),
          axisPaint);
      // At the negative end, clear of the X/Y/Z letters.
      _label(canvas, p, at(_neg(rotation.axis), 1.2) + const Offset(-22, 0),
          'axis', BlochOverlayColors.axis, 11, FontWeight.w800);
      // Drawn whenever the start is off the axis and the angle is not zero,
      // so a full turn (2π, 4π) shows its whole circle even though it ends
      // where it began (v2.6 M11F). Predictions are dashed; an applied or
      // replayed step is solid and quieter.
      if (start != null &&
          !rotation.isOnAxis(start) &&
          rotation.angle.abs() > 1e-9) {
        final color =
            o.applied ? BlochOverlayColors.path : BlochOverlayColors.preview;
        final arc = Paint()
          ..color = o.applied ? color.withValues(alpha: .7) : color
          ..strokeWidth = o.applied ? 2.5 : 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final segments = math.max(24, (rotation.angle.abs() * 24).ceil());
        var previous = at(start);
        for (var i = 1; i <= segments; i++) {
          final point = at(rotation.apply(start, i / segments));
          // Every other segment for the dashed prediction.
          if (o.applied || i.isOdd) canvas.drawLine(previous, point, arc);
          previous = point;
        }
        // Direction arrowhead at the end of the trajectory.
        final end = at(rotation.apply(start, 1));
        final before = at(rotation.apply(start, (segments - 1) / segments));
        final dir = end - before;
        if (dir.distance > 0.01) {
          final u = dir / dir.distance;
          final normal = Offset(-u.dy, u.dx);
          final head = Path()
            ..moveTo(end.dx, end.dy)
            ..lineTo(
                (end - u * 10 + normal * 5).dx, (end - u * 10 + normal * 5).dy)
            ..lineTo(
                (end - u * 10 - normal * 5).dx, (end - u * 10 - normal * 5).dy)
            ..close();
          canvas.drawPath(head, Paint()..color = color);
        }
      }
    }
    if (start != null) {
      final tip = at(start);
      canvas.drawLine(
          center,
          tip,
          Paint()
            ..color = BlochOverlayColors.start.withValues(alpha: .7)
            ..strokeWidth = 2);
      canvas.drawCircle(
          tip,
          7,
          Paint()
            ..color = BlochOverlayColors.start
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    final preview = o.previewVector;
    if (preview != null) {
      final tip = at(preview);
      _dashed(
          canvas,
          center,
          tip,
          Paint()
            ..color = BlochOverlayColors.preview
            ..strokeWidth = 3);
      // Ring with a centre dot: distinct in shape from the current state's
      // solid tip and the input state's plain ring.
      canvas.drawCircle(
          tip,
          9,
          Paint()
            ..color = BlochOverlayColors.preview
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      canvas.drawCircle(tip, 3, Paint()..color = BlochOverlayColors.preview);
    }
    final outcome = o.outcomeVector;
    if (outcome != null) {
      final tip = at(outcome);
      canvas.drawCircle(
          tip,
          11,
          Paint()
            ..color = BlochOverlayColors.basis
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }

  static (double, double, double) _neg((double, double, double) v) =>
      (-v.$1, -v.$2, -v.$3);

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total < 1) return;
    final u = (b - a) / total;
    for (var d = 0.0; d < total; d += 10) {
      canvas.drawLine(a + u * d, a + u * math.min(d + 6, total), paint);
    }
  }

  void _label(Canvas canvas, BlochProjection p, Offset point, String text,
      Color color, double size, FontWeight weight) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: weight,
              fontFamily: QqType.family,
              fontFamilyFallback: QqType.fallback)),
      textDirection: TextDirection.ltr,
    )..layout();
    final c = p.safeLabelCenter(point, painter.size);
    painter.paint(canvas, c - Offset(painter.width / 2, painter.height / 2));
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

  /// Each pole label sits just outside the sphere along its projected
  /// axis direction, nudged sideways off the axis line (so it never covers
  /// the axis letter at the axis end). Labels on the far hemisphere are
  /// dimmer. A label that would overlap the state vector's tip or an
  /// earlier label moves further out along its direction.
  void _paintStateLabels(Canvas canvas, BlochProjection p, Offset tip,
      [List<Offset> markers = const []]) {
    const poles = [
      (0.0, 0.0, 1.0, '|0⟩'),
      (0.0, 0.0, -1.0, '|1⟩'),
      (1.0, 0.0, 0.0, '|+⟩'),
      (-1.0, 0.0, 0.0, '|−⟩'),
      (0.0, 1.0, 0.0, '|+i⟩'),
      (0.0, -1.0, 0.0, '|−i⟩'),
    ];
    final center = p.center;
    final placed = <Rect>[
      Rect.fromCircle(center: tip, radius: 15),
      for (final m in markers) Rect.fromCircle(center: m, radius: 12),
    ];
    // Axis letters (drawn at 1.25 R on the positive ends) are obstacles too.
    for (final (x, y, z) in const [
      (1.25, 0.0, 0.0),
      (0.0, 1.25, 0.0),
      (0.0, 0.0, 1.25)
    ]) {
      placed.add(Rect.fromCircle(center: p.project(x, y, z), radius: 9));
    }
    for (final (x, y, z, text) in poles) {
      final surface = p.projectWithDepth(x, y, z);
      var direction = surface.point - center;
      if (direction.distance < p.radius * .2) {
        // An axis pointing at the viewer: offset to the lower right.
        direction = const Offset(1, 1);
      }
      final unit = direction / direction.distance;
      final normal = Offset(-unit.dy, unit.dx);
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: QqType.family,
            fontFamilyFallback: QqType.fallback,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: QubitQuestColors.textBody
                .withValues(alpha: surface.depth >= -0.05 ? .95 : .5),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      Rect rectAt(double out) {
        final c = surface.point + unit * out + normal * 12;
        final clamped = p.safeLabelCenter(c, painter.size);
        return Rect.fromCenter(
            center: clamped,
            width: painter.width + 4,
            height: painter.height + 2);
      }

      var out = 12.0;
      var rect = rectAt(out);
      for (var attempt = 0;
          attempt < 6 && placed.any((r) => r.overlaps(rect));
          attempt++) {
        out += 10;
        rect = rectAt(out);
      }
      placed.add(rect);
      painter.paint(canvas, rect.topLeft + const Offset(2, 1));
    }
  }

  @override
  bool shouldRepaint(covariant BlochSpherePainter oldDelegate) =>
      oldDelegate.stateLabels != stateLabels ||
      oldDelegate.state != state ||
      oldDelegate.camera != camera ||
      oldDelegate.overlay != overlay;
}
