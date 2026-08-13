import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  test('Cartesian construction remains normalized on sphere', () {
    final state = BlochState.fromCartesian(4, -2, 7);
    expect(state.x * state.x + state.y * state.y + state.z * state.z,
        closeTo(1, 1e-12));
  });

  test('theta and phi map to expected Cartesian coordinates', () {
    final state = BlochState.fromAngles(theta: math.pi / 2, phi: math.pi / 2);
    expect(state.x, closeTo(0, 1e-12));
    expect(state.y, closeTo(1, 1e-12));
    expect(state.z, closeTo(0, 1e-12));
  });

  test('single-qubit gate endpoints are correct', () {
    final zero = BlochState.zero;
    final x = zero.applyGate(SelectedGateType.x);
    expect(x.z, closeTo(-1, 1e-12));
    final h = zero.applyGate(SelectedGateType.hadamard);
    expect(h.x, closeTo(1, 1e-12));
    final plusI = h.applyGate(SelectedGateType.s);
    expect(plusI.y, closeTo(1, 1e-12));
  });

  test('rotation gates use configured angle', () {
    final plus = BlochState.fromCartesian(1, 0, 0);
    final result = plus.applyGate(SelectedGateType.rz, angle: math.pi / 4);
    expect(result.x, closeTo(math.sqrt1_2, 1e-12));
    expect(result.y, closeTo(math.sqrt1_2, 1e-12));
  });

  test('animation interpolation stays normalized including antipodal states',
      () {
    final north = BlochState.zero;
    final south = north.applyGate(SelectedGateType.x);
    for (final t in [0.0, .25, .5, .75, 1.0]) {
      final state = BlochState.interpolate(north, south, t);
      expect(state.x * state.x + state.y * state.y + state.z * state.z,
          closeTo(1, 1e-12));
    }
    expect(BlochState.interpolate(north, south, 1).z, closeTo(-1, 1e-12));
  });

  test('global phase does not change Bloch position or probability', () {
    final state = BlochState.fromAngles(theta: 1.1, phi: 2.2);
    final phased = state.withGlobalPhase(1.7);
    expect(phased.x, closeTo(state.x, 1e-12));
    expect(phased.y, closeTo(state.y, 1e-12));
    expect(phased.z, closeTo(state.z, 1e-12));
    expect(phased.probabilityZero, closeTo(state.probabilityZero, 1e-12));
  });

  test('camera orbit and zoom never alter state', () {
    final state = BlochState.fromAngles(theta: 1, phi: 2);
    const camera = BlochCamera();
    final changed = camera.orbit(deltaYaw: .4, deltaPitch: -.2).scale(1.5);
    expect(changed.yaw, isNot(camera.yaw));
    expect(changed.zoom, greaterThan(camera.zoom));
    expect(state.theta, 1);
    expect(state.phi, 2);
  });

  test('history supports undo redo branching and reset', () {
    final history = BlochExplorerHistory();
    history.commit('X', history.state.applyGate(SelectedGateType.x));
    expect(history.state.z, closeTo(-1, 1e-12));
    history.undo();
    expect(history.state.z, closeTo(1, 1e-12));
    history.redo();
    expect(history.state.z, closeTo(-1, 1e-12));
    history.undo();
    history.commit('H', history.state.applyGate(SelectedGateType.hadamard));
    expect(history.canRedo, isFalse);
    history.reset();
    expect(history.entries, hasLength(1));
    expect(history.state.z, closeTo(1, 1e-12));
  });

  test('replay transition exposes endpoints without changing history', () {
    final history = BlochExplorerHistory();
    final source = history.state;
    final destination = source.applyGate(SelectedGateType.x);
    history.commit('X', destination);
    final entriesBefore = history.entries.length;
    final indexBefore = history.index;

    final transition = history.replayTransition!;

    expect(transition.source.z, closeTo(source.z, 1e-12));
    expect(transition.destination.z, closeTo(destination.z, 1e-12));
    expect(history.entries, hasLength(entriesBefore));
    expect(history.index, indexBefore);
  });

  test('replay transition is absent before a committed transition', () {
    expect(BlochExplorerHistory().replayTransition, isNull);
  });
}
