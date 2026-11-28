import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

/// Tolerance below which an amplitude counts as zero (relative phase then
/// undefined) in the Bloch Explorer.
const double blochAmplitudeEpsilon = 1e-9;

/// The simulator's own 2×2 matrix for a single-qubit gate (v2.6 M8): the
/// Bloch Explorer evolves states with exactly the matrices the Composer uses,
/// so it has no second gate implementation. Null for non-unitary or
/// multi-qubit types.
QuantumMatrix? singleQubitGateMatrix(SelectedGateType type, {double? angle}) =>
    switch (type) {
      SelectedGateType.x => QuantumMatrix.pauliX(),
      SelectedGateType.y => QuantumMatrix.pauliY(),
      SelectedGateType.z => QuantumMatrix.pauliZ(),
      SelectedGateType.hadamard => QuantumMatrix.hadamard(),
      SelectedGateType.s => QuantumMatrix.phaseS(),
      SelectedGateType.t => QuantumMatrix.t(),
      SelectedGateType.rx => QuantumMatrix.rx(angle ?? math.pi / 2),
      SelectedGateType.ry => QuantumMatrix.ry(angle ?? math.pi / 2),
      SelectedGateType.rz => QuantumMatrix.rz(angle ?? math.pi / 2),
      _ => null,
    };

/// A rotation of the Bloch sphere: unit [axis] and signed [angle] (right-hand
/// rule). Used only to *visualise* a gate; the state itself always comes from
/// [singleQubitGateMatrix].
@immutable
class BlochRotation {
  const BlochRotation(this.axis, this.angle);
  final (double, double, double) axis;
  final double angle;

  /// Rotates [v] by `fraction × angle` about [axis] (Rodrigues' formula), so
  /// a 3π/2 rotation is drawn as 3π/2, never as a shortest-path arc.
  (double, double, double) apply((double, double, double) v,
      [double fraction = 1]) {
    final a = angle * fraction;
    final c = math.cos(a), s = math.sin(a);
    final (kx, ky, kz) = axis;
    final (vx, vy, vz) = v;
    final dot = kx * vx + ky * vy + kz * vz;
    final cx = ky * vz - kz * vy,
        cy = kz * vx - kx * vz,
        cz = kx * vy - ky * vx;
    return (
      vx * c + cx * s + kx * dot * (1 - c),
      vy * c + cy * s + ky * dot * (1 - c),
      vz * c + cz * s + kz * dot * (1 - c),
    );
  }

  /// Whether [v] lies on the rotation axis: it stays put for every angle,
  /// so there is no path to draw (v2.6 M11F). Unlike [fixes], a full turn
  /// (2π, 4π) of a state off the axis is *not* on the axis: it travels a
  /// whole circle and returns to where it started.
  bool isOnAxis((double, double, double) v) {
    final (kx, ky, kz) = axis;
    final (vx, vy, vz) = v;
    final cx = ky * vz - kz * vy,
        cy = kz * vx - kx * vz,
        cz = kx * vy - ky * vx;
    return math.sqrt(cx * cx + cy * cy + cz * cz) < 1e-9;
  }

  /// Whether [v] ends where it started: on the axis, or a whole number of
  /// turns (the state vector may still gain a phase, e.g. Rx(2π) = −I).
  bool fixes((double, double, double) v) {
    final (kx, ky, kz) = axis;
    final (vx, vy, vz) = v;
    final cx = ky * vz - kz * vy,
        cy = kz * vx - kx * vz,
        cz = kx * vy - ky * vx;
    return math.sqrt(cx * cx + cy * cy + cz * cz) < 1e-9 ||
        (math.sin(angle / 2)).abs() < 1e-12;
  }
}

/// The equivalent Bloch rotation of a gate, up to global phase: X, Y, Z are
/// π about their axes; S and T are π/2 and π/4 about Z; H is π about
/// (X + Z)/√2 (not a Y rotation); Rx, Ry, Rz rotate by their own angle.
/// For discrete gates this is the chosen interpolation, not a claim about
/// how hardware implements the gate.
BlochRotation? blochRotationFor(SelectedGateType type, {double? angle}) {
  const x = (1.0, 0.0, 0.0), y = (0.0, 1.0, 0.0), z = (0.0, 0.0, 1.0);
  final theta = angle ?? math.pi / 2;
  return switch (type) {
    SelectedGateType.x => const BlochRotation(x, math.pi),
    SelectedGateType.y => const BlochRotation(y, math.pi),
    SelectedGateType.z => const BlochRotation(z, math.pi),
    SelectedGateType.s => const BlochRotation(z, math.pi / 2),
    SelectedGateType.t => const BlochRotation(z, math.pi / 4),
    SelectedGateType.hadamard =>
      const BlochRotation((math.sqrt1_2, 0.0, math.sqrt1_2), math.pi),
    SelectedGateType.rx => BlochRotation(x, theta),
    SelectedGateType.ry => BlochRotation(y, theta),
    SelectedGateType.rz => BlochRotation(z, theta),
    _ => null,
  };
}

@immutable
class BlochState {
  const BlochState._({
    required this.theta,
    required this.phi,
    required this.globalPhase,
  });

  factory BlochState.fromAngles({
    required double theta,
    required double phi,
    double globalPhase = 0,
  }) {
    final clampedTheta = theta.clamp(0.0, math.pi).toDouble();
    return BlochState._(
      theta: clampedTheta,
      phi: _wrapAngle(phi),
      globalPhase: _wrapAngle(globalPhase),
    );
  }

  factory BlochState.fromCartesian(double x, double y, double z,
      {double globalPhase = 0}) {
    final length = math.sqrt(x * x + y * y + z * z);
    if (length < 1e-12) {
      return BlochState.fromAngles(theta: 0, phi: 0, globalPhase: globalPhase);
    }
    final nx = x / length;
    final ny = y / length;
    final nz = z / length;
    return BlochState.fromAngles(
      theta: math.acos(nz.clamp(-1.0, 1.0)),
      phi: math.atan2(ny, nx),
      globalPhase: globalPhase,
    );
  }

  factory BlochState.fromAmplitudes(Complex alpha, Complex beta) {
    final alphaMagnitude = math.sqrt(
      alpha.real * alpha.real + alpha.imaginary * alpha.imaginary,
    );
    final betaMagnitude = math.sqrt(
      beta.real * beta.real + beta.imaginary * beta.imaginary,
    );
    final norm = math.sqrt(
      alphaMagnitude * alphaMagnitude + betaMagnitude * betaMagnitude,
    );
    if (!norm.isFinite || norm < 1e-12) {
      throw ArgumentError('Single-qubit amplitudes must be normalized.');
    }
    final normalizedAlpha = alphaMagnitude / norm;
    final normalizedBeta = betaMagnitude / norm;
    final alphaPhase =
        alphaMagnitude < 1e-12 ? 0.0 : math.atan2(alpha.imaginary, alpha.real);
    final betaPhase = betaMagnitude < 1e-12
        ? alphaPhase
        : math.atan2(beta.imaginary, beta.real);
    return BlochState.fromAngles(
      theta: 2 * math.atan2(normalizedBeta, normalizedAlpha),
      phi: betaPhase - alphaPhase,
      globalPhase: alphaPhase,
    );
  }

  static BlochState get zero => BlochState.fromAngles(theta: 0, phi: 0);

  final double theta;
  final double phi;
  final double globalPhase;

  double get x => math.sin(theta) * math.cos(phi);
  double get y => math.sin(theta) * math.sin(phi);
  double get z => math.cos(theta);
  double get alphaMagnitude => math.cos(theta / 2);
  double get betaMagnitude => math.sin(theta / 2);
  double get probabilityZero => alphaMagnitude * alphaMagnitude;
  double get probabilityOne => betaMagnitude * betaMagnitude;

  /// The exact amplitude of |0⟩, including the global phase:
  /// α = e^{iγ} cos(θ/2).
  Complex get alpha => Complex(alphaMagnitude * math.cos(globalPhase),
      alphaMagnitude * math.sin(globalPhase));

  /// The exact amplitude of |1⟩: β = e^{i(γ+φ)} sin(θ/2).
  Complex get beta => Complex(betaMagnitude * math.cos(globalPhase + phi),
      betaMagnitude * math.sin(globalPhase + phi));

  /// Relative phase is defined only when both amplitudes are non-zero; at
  /// the poles φ carries no physical meaning.
  bool get hasDefinedRelativePhase =>
      alphaMagnitude > blochAmplitudeEpsilon &&
      betaMagnitude > blochAmplitudeEpsilon;

  (double, double, double) get vector => (x, y, z);

  BlochState withGlobalPhase(double phase) => BlochState.fromAngles(
        theta: theta,
        phi: phi,
        globalPhase: phase,
      );

  BlochState rotate(String axis, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    final currentX = x;
    final currentY = y;
    final currentZ = z;
    return switch (axis) {
      'X' => BlochState.fromCartesian(
          currentX,
          currentY * c - currentZ * s,
          currentY * s + currentZ * c,
          globalPhase: globalPhase,
        ),
      'Y' => BlochState.fromCartesian(
          currentX * c + currentZ * s,
          currentY,
          -currentX * s + currentZ * c,
          globalPhase: globalPhase,
        ),
      _ => BlochState.fromCartesian(
          currentX * c - currentY * s,
          currentX * s + currentY * c,
          currentZ,
          globalPhase: globalPhase,
        ),
    };
  }

  /// Applies a gate with the simulator's own matrix to the exact amplitudes
  /// (v2.6 M8). The global phase is tracked, so Y|0⟩ = i|1⟩ and
  /// Rz(2π)|ψ⟩ = −|ψ⟩ exactly. Non-gates leave the state unchanged.
  BlochState applyGate(SelectedGateType type, {double angle = math.pi / 2}) {
    final matrix = singleQubitGateMatrix(type, angle: angle);
    if (matrix == null) return this;
    final m = matrix.toComplexList();
    final a = alpha, b = beta;
    return BlochState.fromAmplitudes(
        m[0][0] * a + m[0][1] * b, m[1][0] * a + m[1][1] * b);
  }

  static BlochState interpolate(BlochState from, BlochState to, double t) {
    final clamped = t.clamp(0.0, 1.0).toDouble();
    final dot =
        (from.x * to.x + from.y * to.y + from.z * to.z).clamp(-1.0, 1.0);
    if (dot > .9995) {
      return BlochState.fromCartesian(
        from.x * (1 - clamped) + to.x * clamped,
        from.y * (1 - clamped) + to.y * clamped,
        from.z * (1 - clamped) + to.z * clamped,
        globalPhase:
            from.globalPhase * (1 - clamped) + to.globalPhase * clamped,
      );
    }
    if (dot < -.9995) {
      var axisX = -from.y;
      var axisY = from.x;
      var axisZ = 0.0;
      var length = math.sqrt(axisX * axisX + axisY * axisY);
      if (length < 1e-9) {
        axisX = 0;
        axisY = -from.z;
        axisZ = from.y;
        length = math.sqrt(axisY * axisY + axisZ * axisZ);
      }
      axisX /= length;
      axisY /= length;
      axisZ /= length;
      final angle = math.pi * clamped;
      final c = math.cos(angle), s = math.sin(angle);
      final crossX = axisY * from.z - axisZ * from.y;
      final crossY = axisZ * from.x - axisX * from.z;
      final crossZ = axisX * from.y - axisY * from.x;
      return BlochState.fromCartesian(
        from.x * c + crossX * s,
        from.y * c + crossY * s,
        from.z * c + crossZ * s,
        globalPhase:
            from.globalPhase * (1 - clamped) + to.globalPhase * clamped,
      );
    }
    final omega = math.acos(dot);
    final sinOmega = math.sin(omega);
    final fromWeight = math.sin((1 - clamped) * omega) / sinOmega;
    final toWeight = math.sin(clamped * omega) / sinOmega;
    return BlochState.fromCartesian(
      from.x * fromWeight + to.x * toWeight,
      from.y * fromWeight + to.y * toWeight,
      from.z * fromWeight + to.z * toWeight,
      globalPhase: from.globalPhase * (1 - clamped) + to.globalPhase * clamped,
    );
  }

  static double _wrapAngle(double angle) {
    var result = angle % (2 * math.pi);
    if (result < 0) result += 2 * math.pi;
    return result;
  }
}

@immutable
class BlochCamera {
  const BlochCamera({this.yaw = -.55, this.pitch = .32, this.zoom = 1});

  final double yaw;
  final double pitch;
  final double zoom;

  BlochCamera orbit({required double deltaYaw, required double deltaPitch}) =>
      BlochCamera(
        yaw: yaw + deltaYaw,
        pitch: (pitch + deltaPitch).clamp(-1.25, 1.25),
        zoom: zoom,
      );

  BlochCamera scale(double factor) => BlochCamera(
        yaw: yaw,
        pitch: pitch,
        zoom: (zoom * factor).clamp(.7, 2.2),
      );
}

@immutable
class BlochHistoryEntry {
  const BlochHistoryEntry({
    required this.label,
    required this.state,
    this.gate,
  });
  final String label;
  final BlochState state;
  final Gate? gate;
}

@immutable
class BlochReplayTransition {
  const BlochReplayTransition({
    required this.source,
    required this.destination,
  });

  final BlochState source;
  final BlochState destination;
}

class BlochExplorerHistory extends ChangeNotifier {
  BlochExplorerHistory({BlochState? initial})
      : _initialState = initial ?? BlochState.zero,
        _entries = [
          BlochHistoryEntry(label: 'Initial', state: initial ?? BlochState.zero)
        ];

  BlochState _initialState;
  final List<BlochHistoryEntry> _entries;
  int _index = 0;

  List<BlochHistoryEntry> get entries => List.unmodifiable(_entries);
  int get index => _index;
  int get operationCount => _index;
  BlochState get initialState => _initialState;
  BlochState get state => _entries[_index].state;
  bool get canUndo => _index > 0;
  bool get canRedo => _index + 1 < _entries.length;
  List<BlochReplayTransition> get replaySequence => replaySequenceFrom(0);

  List<BlochReplayTransition> replaySequenceFrom(int startIndex) {
    if (startIndex < 0 || startIndex > _index) return const [];
    return List.unmodifiable([
      for (var step = startIndex; step < _index; step++)
        BlochReplayTransition(
          source: _entries[step].state,
          destination: _entries[step + 1].state,
        ),
    ]);
  }

  void commit(String label, BlochState state, {Gate? gate}) {
    if (_index + 1 < _entries.length) {
      _entries.removeRange(_index + 1, _entries.length);
    }
    _entries.add(BlochHistoryEntry(label: label, state: state, gate: gate));
    _index = _entries.length - 1;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _index--;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _index++;
    notifyListeners();
  }

  void reset({BlochState? initial}) {
    if (initial != null) _initialState = initial;
    _entries
      ..clear()
      ..add(BlochHistoryEntry(label: 'Initial', state: _initialState));
    _index = 0;
    notifyListeners();
  }
}
