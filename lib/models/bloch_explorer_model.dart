import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

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

  BlochState applyGate(SelectedGateType type, {double angle = math.pi / 2}) {
    return switch (type) {
      SelectedGateType.x => rotate('X', math.pi),
      SelectedGateType.y => rotate('Y', math.pi),
      SelectedGateType.z => rotate('Z', math.pi),
      SelectedGateType.s => rotate('Z', math.pi / 2),
      SelectedGateType.t => rotate('Z', math.pi / 4),
      SelectedGateType.rx => rotate('X', angle),
      SelectedGateType.ry => rotate('Y', angle),
      SelectedGateType.rz => rotate('Z', angle),
      SelectedGateType.hadamard => BlochState.fromCartesian(
          z,
          -y,
          x,
          globalPhase: globalPhase,
        ),
      _ => this,
    };
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
  const BlochHistoryEntry({required this.label, required this.state});
  final String label;
  final BlochState state;
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
      : _entries = [
          BlochHistoryEntry(label: 'Initial', state: initial ?? BlochState.zero)
        ];

  final List<BlochHistoryEntry> _entries;
  int _index = 0;

  List<BlochHistoryEntry> get entries => List.unmodifiable(_entries);
  int get index => _index;
  BlochState get state => _entries[_index].state;
  bool get canUndo => _index > 0;
  bool get canRedo => _index + 1 < _entries.length;
  BlochReplayTransition? get replayTransition => _index == 0
      ? null
      : BlochReplayTransition(
          source: _entries[_index - 1].state,
          destination: _entries[_index].state,
        );

  void commit(String label, BlochState state) {
    if (_index + 1 < _entries.length) {
      _entries.removeRange(_index + 1, _entries.length);
    }
    _entries.add(BlochHistoryEntry(label: label, state: state));
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

  void reset() {
    _entries
      ..clear()
      ..add(BlochHistoryEntry(label: 'Initial', state: BlochState.zero));
    _index = 0;
    notifyListeners();
  }
}
