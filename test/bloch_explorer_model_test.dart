import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/canonical_qubit_state.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  test('canonical presets expose exact amplitudes and Bloch positions', () {
    const expected = {
      CanonicalQubitState.zero: (0.0, 0.0, 1.0, 0.0, 0.0),
      CanonicalQubitState.one: (0.0, 0.0, -1.0, math.pi, 0.0),
      CanonicalQubitState.plus: (1.0, 0.0, 0.0, math.pi / 2, 0.0),
      CanonicalQubitState.minus: (-1.0, 0.0, 0.0, math.pi / 2, math.pi),
      CanonicalQubitState.plusI: (0.0, 1.0, 0.0, math.pi / 2, math.pi / 2),
      CanonicalQubitState.minusI: (0.0, -1.0, 0.0, math.pi / 2, -math.pi / 2),
    };
    const expectedAmplitudes = {
      CanonicalQubitState.zero: (1.0, 0.0, 0.0, 0.0),
      CanonicalQubitState.one: (0.0, 0.0, 1.0, 0.0),
      CanonicalQubitState.plus: (math.sqrt1_2, 0.0, math.sqrt1_2, 0.0),
      CanonicalQubitState.minus: (math.sqrt1_2, 0.0, -math.sqrt1_2, 0.0),
      CanonicalQubitState.plusI: (math.sqrt1_2, 0.0, 0.0, math.sqrt1_2),
      CanonicalQubitState.minusI: (math.sqrt1_2, 0.0, 0.0, -math.sqrt1_2),
    };
    for (final preset in CanonicalQubitState.values) {
      final amplitudes = preset.amplitudes;
      final state = preset.blochState;
      final position = expected[preset]!;
      final expectedPair = expectedAmplitudes[preset]!;
      final norm = amplitudes.fold<double>(
        0,
        (sum, amplitude) => sum + amplitude.magnitude * amplitude.magnitude,
      );
      expect(norm, closeTo(1, 1e-12), reason: preset.label);
      expect(amplitudes[0].real, closeTo(expectedPair.$1, 1e-12));
      expect(amplitudes[0].imaginary, closeTo(expectedPair.$2, 1e-12));
      expect(amplitudes[1].real, closeTo(expectedPair.$3, 1e-12));
      expect(amplitudes[1].imaginary, closeTo(expectedPair.$4, 1e-12));
      expect(state.x, closeTo(position.$1, 1e-12), reason: preset.label);
      expect(state.y, closeTo(position.$2, 1e-12), reason: preset.label);
      expect(state.z, closeTo(position.$3, 1e-12), reason: preset.label);
      expect(state.theta, closeTo(position.$4, 1e-12), reason: preset.label);
      expect(_angleDistance(state.phi, position.$5), lessThan(1e-12),
          reason: preset.label);
      expect(state.probabilityZero,
          closeTo(amplitudes[0].magnitude * amplitudes[0].magnitude, 1e-12));
      expect(state.probabilityOne,
          closeTo(amplitudes[1].magnitude * amplitudes[1].magnitude, 1e-12));
      expect(CanonicalQubitState.matching(state), preset);
      expect(CanonicalQubitState.matching(state.withGlobalPhase(.73)), preset);
    }
  });

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
    expect(history.operationCount, 0);
    history.commit('X', history.state.applyGate(SelectedGateType.x));
    expect(history.operationCount, 1);
    expect(history.state.z, closeTo(-1, 1e-12));
    history.undo();
    expect(history.operationCount, 0);
    expect(history.state.z, closeTo(1, 1e-12));
    history.redo();
    expect(history.operationCount, 1);
    expect(history.state.z, closeTo(-1, 1e-12));
    history.undo();
    history.commit('H', history.state.applyGate(SelectedGateType.hadamard));
    expect(history.operationCount, 1);
    expect(history.canRedo, isFalse);
    history.reset();
    expect(history.entries, hasLength(1));
    expect(history.operationCount, 0);
    expect(history.state.z, closeTo(1, 1e-12));
  });

  test('history reset preserves or replaces its authored initial state', () {
    final custom = BlochState.fromAngles(theta: 1.1, phi: .7);
    final plus = CanonicalQubitState.plus.blochState;
    final history = BlochExplorerHistory(initial: custom)
      ..commit('X', custom.applyGate(SelectedGateType.x));
    history.reset();
    expect(history.state.x, closeTo(custom.x, 1e-12));
    expect(history.operationCount, 0);
    history.reset(initial: plus);
    expect(history.initialState.x, closeTo(1, 1e-12));
    expect(history.entries, hasLength(1));
    expect(history.operationCount, 0);
  });

  test('history gate metadata preserves type and configured angle', () {
    final history = BlochExplorerHistory();
    final gate = Gate.fromIdentifier(SelectedGateType.ry, angle: -math.pi / 4);
    history.commit(
      gate.label.replaceAll('\n', ' '),
      history.state.applyGate(gate.type, angle: gate.angle!),
      gate: gate,
    );

    expect(history.entries.first.gate, isNull);
    expect(history.entries[1].gate?.type, SelectedGateType.ry);
    expect(history.entries[1].gate?.angle, closeTo(-math.pi / 4, 1e-12));
  });

  test('replay sequence exposes every endpoint without changing history', () {
    final history = BlochExplorerHistory();
    final initial = history.state;
    final h = initial.applyGate(SelectedGateType.hadamard);
    final s = h.applyGate(SelectedGateType.s);
    final rx = s.applyGate(SelectedGateType.rx, angle: math.pi / 3);
    history
      ..commit('H', h)
      ..commit('S', s)
      ..commit('Rx(π/3)', rx);
    final entriesBefore = history.entries.length;
    final indexBefore = history.index;

    final sequence = history.replaySequence;

    expect(sequence, hasLength(3));
    expect(sequence[0].source, initial);
    expect(sequence[0].destination, h);
    expect(sequence[1].source, h);
    expect(sequence[1].destination, s);
    expect(sequence[2].source, s);
    expect(sequence[2].destination, rx);
    expect(history.entries, hasLength(entriesBefore));
    expect(history.index, indexBefore);
  });

  test('replay sequence is empty before a committed transition', () {
    expect(BlochExplorerHistory().replaySequence, isEmpty);
  });

  test('replay sequence stops at undo index and excludes redo branch', () {
    final history = BlochExplorerHistory();
    history
      ..commit('H', history.state.applyGate(SelectedGateType.hadamard))
      ..commit('Z', history.state.applyGate(SelectedGateType.z))
      ..commit('S', history.state.applyGate(SelectedGateType.s))
      ..undo();

    expect(history.replaySequence, hasLength(2));
    expect(history.replaySequence.last.destination, history.state);
    expect(history.canRedo, isTrue);
  });

  test('replay sequence follows a new branch after undo', () {
    final history = BlochExplorerHistory();
    history
      ..commit('H', history.state.applyGate(SelectedGateType.hadamard))
      ..commit('Z', history.state.applyGate(SelectedGateType.z))
      ..undo();
    final dragged = BlochState.fromAngles(theta: 1.1, phi: .7);
    history.commit('Direct state', dragged);

    expect(history.canRedo, isFalse);
    expect(history.replaySequence, hasLength(2));
    expect(history.replaySequence.last.destination, dragged);
  });

  test('replay sequence can begin after a selected history state', () {
    final history = BlochExplorerHistory();
    history
      ..commit('H', history.state.applyGate(SelectedGateType.hadamard))
      ..commit('Z', history.state.applyGate(SelectedGateType.z))
      ..commit('S', history.state.applyGate(SelectedGateType.s));

    final selectedState = history.entries[2].state;
    final sequence = history.replaySequenceFrom(2);
    expect(sequence, hasLength(1));
    expect(sequence.single.source, selectedState);
    expect(sequence.single.destination, history.state);
    expect(history.index, 3);
  });

  test('selecting current state produces no replay transitions', () {
    final history = BlochExplorerHistory();
    history.commit('H', history.state.applyGate(SelectedGateType.hadamard));
    expect(history.replaySequenceFrom(history.index), isEmpty);
    expect(history.replaySequenceFrom(-1), isEmpty);
    expect(history.replaySequenceFrom(history.index + 1), isEmpty);
  });
}

double _angleDistance(double first, double second) =>
    math.atan2(math.sin(first - second), math.cos(first - second)).abs();
