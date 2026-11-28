// v2.6 M8: Bloch Explorer — interactive single-qubit state laboratory.
//
// Expected values are written out by hand (independent of the
// implementation). Convention: x = 2Re(α*β), y = 2Im(α*β), z = |α|² − |β|².
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/widgets/state_amplitude_panel.dart'
    show QqCurrentStatePanel;
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_reference_examples.dart';
import 'package:quantumquiz/models/notebook_knowledge_base.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_bloch_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/bloch_lab.dart';
import 'package:quantumquiz/models/canonical_qubit_state.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'support/laboratory_composer_finders.dart';

const _e = 1e-12;
final _r = math.sqrt1_2;

BlochState _amps(double ar, double ai, double br, double bi) =>
    BlochState.fromAmplitudes(Complex(ar, ai), Complex(br, bi));

void _vec(BlochState s, double x, double y, double z, {String? reason}) {
  expect(s.x, closeTo(x, 1e-9), reason: '$reason x');
  expect(s.y, closeTo(y, 1e-9), reason: '$reason y');
  expect(s.z, closeTo(z, 1e-9), reason: '$reason z');
}

void _amp(BlochState s, (double, double) a, (double, double) b,
    {String? reason}) {
  expect(s.alpha.real, closeTo(a.$1, 1e-9), reason: '$reason α re');
  expect(s.alpha.imaginary, closeTo(a.$2, 1e-9), reason: '$reason α im');
  expect(s.beta.real, closeTo(b.$1, 1e-9), reason: '$reason β re');
  expect(s.beta.imaginary, closeTo(b.$2, 1e-9), reason: '$reason β im');
}

/// Bloch vector from amplitudes by the standard convention (independent).
(double, double, double) _blochOf(Complex a, Complex b) {
  final ab = a.conjugate * b;
  return (
    2 * ab.real.toDouble(),
    2 * ab.imaginary.toDouble(),
    (a.real * a.real +
            a.imaginary * a.imaginary -
            b.real * b.real -
            b.imaginary * b.imaginary)
        .toDouble(),
  );
}

class _KeyedStorage extends InMemoryAppStorage {
  final List<String> writtenKeys = [];
  @override
  Future<void> writeString(String key, String value) {
    writtenKeys.add(key);
    return super.writeString(key, value);
  }
}

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<WebBlochWorkspaceState> _pumpLab(WidgetTester tester,
    {BlochLabSession? lab, Size size = const Size(1440, 1000)}) async {
  _size(tester, size);
  final session = lab ?? BlochLabSession.standalone();
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WebBlochWorkspace(standalone: session))));
  await tester.pump();
  return tester.state(find.byType(WebBlochWorkspace));
}

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  group('canonical states', () {
    test('six canonical states map to the six axis points', () {
      final expected = {
        CanonicalQubitState.zero: (0.0, 0.0, 1.0),
        CanonicalQubitState.one: (0.0, 0.0, -1.0),
        CanonicalQubitState.plus: (1.0, 0.0, 0.0),
        CanonicalQubitState.minus: (-1.0, 0.0, 0.0),
        CanonicalQubitState.plusI: (0.0, 1.0, 0.0),
        CanonicalQubitState.minusI: (0.0, -1.0, 0.0),
      };
      for (final MapEntry(key: state, value: (x, y, z)) in expected.entries) {
        _vec(state.blochState, x, y, z, reason: state.label);
        final a = state.amplitudes;
        final (bx, by, bz) = _blochOf(a[0], a[1]);
        expect([bx, by, bz], [closeTo(x, _e), closeTo(y, _e), closeTo(z, _e)]);
      }
    });

    test('θ/φ preparation: cos(θ/2)|0⟩ + e^{iφ} sin(θ/2)|1⟩', () {
      final s = BlochState.fromAngles(theta: 2 * math.pi / 3, phi: math.pi / 4);
      _amp(s, (math.cos(math.pi / 3), 0),
          (math.sin(math.pi / 3) * _r, math.sin(math.pi / 3) * _r));
      final (x, y, z) = _blochOf(s.alpha, s.beta);
      _vec(s, x, y, z);
      expect(s.x * s.x + s.y * s.y + s.z * s.z, closeTo(1, _e));
    });

    test('relative phase is undefined at the poles only', () {
      expect(BlochState.zero.hasDefinedRelativePhase, isFalse);
      expect(_amps(0, 0, 0, 1).hasDefinedRelativePhase, isFalse);
      expect(
          CanonicalQubitState.plusI.blochState.hasDefinedRelativePhase, isTrue);
    });
  });

  group('transformations (simulator matrices, exact phases)', () {
    final zero = BlochState.zero;
    final plus = CanonicalQubitState.plus.blochState;
    test('X|0⟩ = |1⟩, Y|0⟩ = i|1⟩, H|0⟩ = |+⟩, Z|+⟩ = |−⟩, S|+⟩ = |+i⟩', () {
      _amp(zero.applyGate(SelectedGateType.x), (0, 0), (1, 0), reason: 'X');
      _amp(zero.applyGate(SelectedGateType.y), (0, 0), (0, 1), reason: 'Y');
      _amp(zero.applyGate(SelectedGateType.hadamard), (_r, 0), (_r, 0),
          reason: 'H');
      _amp(plus.applyGate(SelectedGateType.z), (_r, 0), (-_r, 0), reason: 'Z');
      _amp(plus.applyGate(SelectedGateType.s), (_r, 0), (0, _r), reason: 'S');
    });

    test('H² = I and HZH = X on arbitrary states', () {
      final psi = _amps(.6, .1, -.2, .7701298586);
      final hh = psi
          .applyGate(SelectedGateType.hadamard)
          .applyGate(SelectedGateType.hadamard);
      _amp(hh, (psi.alpha.real.toDouble(), psi.alpha.imaginary.toDouble()),
          (psi.beta.real.toDouble(), psi.beta.imaginary.toDouble()));
      final hzh = psi
          .applyGate(SelectedGateType.hadamard)
          .applyGate(SelectedGateType.z)
          .applyGate(SelectedGateType.hadamard);
      final x = psi.applyGate(SelectedGateType.x);
      _amp(hzh, (x.alpha.real.toDouble(), x.alpha.imaginary.toDouble()),
          (x.beta.real.toDouble(), x.beta.imaginary.toDouble()));
    });

    test('rotation endpoints', () {
      _vec(zero.applyGate(SelectedGateType.rx, angle: math.pi / 2), 0, -1, 0,
          reason: 'Rx');
      _vec(zero.applyGate(SelectedGateType.ry, angle: math.pi / 2), 1, 0, 0,
          reason: 'Ry');
      _vec(plus.applyGate(SelectedGateType.rz, angle: math.pi / 2), 0, 1, 0,
          reason: 'Rz');
    });

    test('global phase is tracked: Rz(2π) = −I, Bloch position unchanged', () {
      final after = plus.applyGate(SelectedGateType.rz, angle: 2 * math.pi);
      _amp(after, (-_r, 0), (-_r, 0));
      _vec(after, 1, 0, 0);
      final minusZero = zero
          .applyGate(SelectedGateType.x)
          .applyGate(SelectedGateType.z)
          .applyGate(SelectedGateType.x);
      _amp(minusZero, (-1, 0), (0, 0), reason: 'XZX|0⟩ = −|0⟩');
      _vec(minusZero, 0, 0, 1);
    });

    test('Bloch geometry of every gate agrees with its matrix', () {
      final inputs = [
        zero,
        plus,
        _amps(.6, .1, -.2, .7701298586),
        BlochState.fromAngles(theta: 2.2, phi: 4.1),
      ];
      for (final type in blochLabGateTypes) {
        for (final angle in [math.pi / 3, 3 * math.pi / 2, 2 * math.pi]) {
          for (final s in inputs) {
            final rotation = blochRotationFor(type, angle: angle)!;
            final (x, y, z) = rotation.apply(s.vector);
            _vec(s.applyGate(type, angle: angle), x, y, z,
                reason: '${type.name} θ=$angle');
          }
        }
      }
      // H is a π rotation about (X+Z)/√2, not about Y.
      final h = blochRotationFor(SelectedGateType.hadamard)!;
      expect(h.axis.$1, closeTo(_r, _e));
      expect(h.axis.$2, 0);
      expect(h.axis.$3, closeTo(_r, _e));
    });

    test('trajectories follow the full angle (no shortest path)', () {
      final rz = blochRotationFor(SelectedGateType.rz, angle: 3 * math.pi / 2)!;
      // Halfway through 3π/2 from |+⟩ is 3π/4: (−√½, √½, 0); a shortest
      // path to the endpoint (0, −1, 0) would pass through (√½, −√½, 0).
      final (x, y, z) = rz.apply((1, 0, 0), .5);
      expect([x, y, z], [closeTo(-_r, _e), closeTo(_r, _e), closeTo(0, _e)]);
      // States on the axis do not move, though the vector gains a phase.
      expect(rz.fixes((0, 0, 1)), isTrue);
      final s = zero.applyGate(SelectedGateType.rz, angle: math.pi / 2);
      _vec(s, 0, 0, 1);
      expect(s.alpha.imaginary, closeTo(-_r, 1e-9), reason: 'e^{−iπ/4}');
    });

    test('normalisation and pure-state vector length are preserved', () {
      var s = _amps(.6, .1, -.2, .7701298586);
      for (final type in blochLabGateTypes) {
        s = s.applyGate(type, angle: 1.234);
        final n = s.alpha.real * s.alpha.real +
            s.alpha.imaginary * s.alpha.imaginary +
            s.beta.real * s.beta.real +
            s.beta.imaginary * s.beta.imaginary;
        expect(n, closeTo(1, 1e-9));
        expect(math.sqrt(s.x * s.x + s.y * s.y + s.z * s.z), closeTo(1, 1e-9));
      }
    });

    test('global phase never changes Bloch coordinates', () {
      final s = BlochState.fromAngles(theta: 1.3, phi: 2.9);
      for (final g in [0.4, math.pi, -2.0]) {
        final p = s.withGlobalPhase(g);
        _vec(p, s.x, s.y, s.z);
        final (x, y, z) = _blochOf(p.alpha, p.beta);
        _vec(s, x, y, z);
      }
    });
  });

  group('interference: H → Rz(θ) → H on |0⟩', () {
    for (final (theta, p0) in [
      (0.0, 1.0),
      (math.pi / 3, .75),
      (math.pi / 2, .5),
      (math.pi, 0.0),
      (2 * math.pi, 1.0),
    ]) {
      test('θ = $theta: P(0) = $p0', () {
        final session = BlochLabSession.standalone()
          ..commit(SelectedGateType.hadamard)
          ..commit(SelectedGateType.rz, angle: theta)
          ..commit(SelectedGateType.hadamard);
        final (plus, minus) = BlochBasis.z.probabilities(session.current);
        expect(plus, closeTo(p0, 1e-9));
        expect(minus, closeTo(1 - p0, 1e-9));
        if (theta == 2 * math.pi) {
          // H·Rz(2π)·H = −I: the state vector is −|0⟩.
          _amp(session.current, (-1, 0), (0, 0));
        }
        if (theta == math.pi / 3) {
          // cos(π/6)|0⟩ − i sin(π/6)|1⟩.
          _amp(session.current, (math.cos(math.pi / 6), 0),
              (0, -math.sin(math.pi / 6)));
        }
      });
    }
  });

  group('measurement in three bases', () {
    test('probabilities: amplitudes after basis change = (1 ± r·n)/2', () {
      final states = [
        for (final c in CanonicalQubitState.values) c.blochState,
        _amps(.6, .1, -.2, .7701298586),
      ];
      for (final s in states) {
        for (final basis in BlochBasis.values) {
          final (plus, minus) = basis.probabilities(s);
          final (nx, ny, nz) = basis.axis;
          final expected = (1 + s.x * nx + s.y * ny + s.z * nz) / 2;
          expect(plus, closeTo(expected, 1e-9), reason: basis.label);
          expect(minus, closeTo(1 - expected, 1e-9));
          expect(basis.geometricPlusProbability(s), closeTo(expected, 1e-12));
        }
      }
      // Hand-written: |+i⟩ in Y gives P(+i) = 1, in X 1/2.
      final plusI = CanonicalQubitState.plusI.blochState;
      expect(BlochBasis.y.probabilities(plusI).$1, closeTo(1, 1e-9));
      expect(BlochBasis.x.probabilities(plusI).$1, closeTo(.5, 1e-9));
      // |−⟩ in X gives P(−) = 1.
      expect(
          BlochBasis.x.probabilities(CanonicalQubitState.minus.blochState).$2,
          closeTo(1, 1e-9));
    });

    test('|+⟩ vs |−⟩ and |+⟩ vs |+i⟩: same Z statistics, different states', () {
      final plus = CanonicalQubitState.plus.blochState;
      for (final other in [
        CanonicalQubitState.minus.blochState,
        CanonicalQubitState.plusI.blochState,
      ]) {
        expect(BlochBasis.z.probabilities(other).$1,
            closeTo(BlochBasis.z.probabilities(plus).$1, 1e-12));
        expect((other.x - plus.x).abs() + (other.y - plus.y).abs(),
            greaterThan(1));
      }
    });

    test('shots use the existing sampler and never touch the prepared state',
        () {
      final session = BlochLabSession.standalone()
        ..commit(SelectedGateType.hadamard);
      final before = session.current;
      final measurer = BlochMeasurer(random: math.Random(7));
      final shots = measurer.shots(session.current, BlochBasis.x, 2000);
      expect(shots.plusCount, 2000, reason: '|+⟩ measured in X is always +');
      final z = measurer.shots(session.current, BlochBasis.z, 4000);
      expect(z.plusCount / 4000, closeTo(.5, .05));
      final once = measurer.once(session.current, BlochBasis.y);
      expect(once.postMeasurementState.y.abs(), closeTo(1, 1e-9));
      expect(identical(session.current, before), isTrue);
      expect(session.appliedCount, 1);
    });
  });

  group('session: preview, history, inspection, seeds', () {
    test('preview depends only on the final angle; commit adds one step', () {
      final session = BlochLabSession.standalone()
        ..commit(SelectedGateType.hadamard);
      final direct = session.preview(SelectedGateType.ry, angle: 1.1).after;
      for (var i = 0; i < 50; i++) {
        session.preview(SelectedGateType.ry, angle: i / 10);
      }
      final again = session.preview(SelectedGateType.ry, angle: 1.1).after;
      _vec(again, direct.x, direct.y, direct.z);
      expect(session.appliedCount, 1, reason: 'previews record nothing');
      session.commit(SelectedGateType.ry, angle: 1.1);
      expect(session.appliedCount, 2);
      _vec(session.current, direct.x, direct.y, direct.z);
    });

    test('undo, redo, inspection and reset', () {
      final session = BlochLabSession.standalone()
        ..commit(SelectedGateType.hadamard)
        ..commit(SelectedGateType.z)
        ..commit(SelectedGateType.hadamard);
      _amp(session.current, (0, 0), (1, 0), reason: 'HZH|0⟩ = |1⟩');
      session.inspect(1);
      expect(session.isInspecting, isTrue);
      _vec(session.displayed, 1, 0, 0);
      expect(session.commit(SelectedGateType.x), isNull,
          reason: 'read-only while inspecting');
      expect(session.canUndo, isFalse);
      session.returnToCurrent();
      session.undo();
      _vec(session.current, -1, 0, 0);
      session.redo();
      _vec(session.current, 0, 0, -1);
      session.undo();
      session.commit(SelectedGateType.s); // discards the redo step
      expect(session.canRedo, isFalse);
      expect(session.appliedSteps.map((s) => s.gate.type),
          [SelectedGateType.hadamard, SelectedGateType.z, SelectedGateType.s]);
      session.reset();
      expect(session.appliedCount, 0);
      _vec(session.current, 0, 0, 1);
      // Standalone reset keeps a prepared state and clears its gates.
      session
        ..prepare(CanonicalQubitState.plusI.blochState, '|+i⟩')
        ..commit(SelectedGateType.x)
        ..reset();
      expect(session.appliedCount, 0);
      expect(session.initialLabel, '|+i⟩');
      _vec(session.current, 0, 1, 0);
    });

    test('seeds restore their authored gates on reset', () {
      final seed = BlochLabSeed(
        origin: BlochLabOrigin.notebook,
        title: 'H → Rz → H',
        initial: BlochState.zero,
        initialLabel: '|0⟩',
        gates: [
          blochLabGate(SelectedGateType.hadamard),
          blochLabGate(SelectedGateType.rz, angle: math.pi / 3),
          blochLabGate(SelectedGateType.hadamard),
        ],
        sourceId: 'rz_interference',
      );
      final session = BlochLabSession(seed);
      expect(session.appliedCount, 3);
      session
        ..undo()
        ..commit(SelectedGateType.x)
        ..prepare(CanonicalQubitState.minus.blochState, '|−⟩');
      session.reset();
      expect(session.appliedCount, 3);
      expect(
          BlochBasis.z.probabilities(session.current).$1, closeTo(.75, 1e-9));
    });

    test('camera orbit and zoom never alter the state', () {
      final session = BlochLabSession.standalone()
        ..commit(SelectedGateType.hadamard);
      final before = session.current;
      var camera = const BlochCamera();
      for (var i = 0; i < 20; i++) {
        camera = camera.orbit(deltaYaw: .3, deltaPitch: -.1).scale(1.1);
      }
      expect(identical(session.current, before), isTrue);
    });
  });

  group('notation', () {
    test('complex numbers and expressions are unambiguous', () {
      expect(blochComplex(Complex(0, _r)), '0.7071i');
      expect(blochComplex(Complex(.5, -.5)), '0.5000 − 0.5000i');
      expect(blochComplex(Complex(0, -1)), '−1.0000i');
      expect(blochStateExpression(CanonicalQubitState.minus.blochState),
          '0.7071|0⟩ − 0.7071|1⟩');
      expect(blochStateExpression(CanonicalQubitState.plusI.blochState),
          '0.7071|0⟩ + 0.7071i|1⟩');
      expect(
          blochStateExpression(BlochState.zero.applyGate(SelectedGateType.y)),
          '1.0000i|1⟩');
      expect(blochStateExpression(BlochState.zero), '|0⟩');
      expect(
          blochStateExpression(BlochState.zero
              .applyGate(SelectedGateType.x)
              .applyGate(SelectedGateType.z)
              .applyGate(SelectedGateType.x)),
          '−|0⟩');
      expect(blochAngle(math.pi / 2), 'π/2 (1.5708 rad)');
      expect(blochAngle(math.pi / 3), 'π/3 (1.0472 rad)');
      expect(blochAngle(-math.pi), '−π (−3.1416 rad)');
    });
  });

  group('workspace', () {
    testWidgets('preview then Apply: one step; slider moves record nothing',
        (tester) async {
      final lab = await _pumpLab(tester);
      final session = lab.session;
      await tester.tap(find.byKey(const ValueKey('bloch-gate-ry')));
      await tester.pump();
      final slider = find.descendant(
          of: find.byKey(const ValueKey('bloch-rotation-angle')),
          matching: find.byType(Slider));
      for (var i = 0; i < 12; i++) {
        await tester.drag(slider, Offset(i.isEven ? 30 : -18, 0));
        await tester.pump();
      }
      expect(session.appliedCount, 0, reason: 'previews never commit');
      await tester.tap(find.byKey(const ValueKey('angle-preset-1.5708')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('bloch-apply')));
      await tester.tap(find.byKey(const ValueKey('bloch-apply')));
      await tester.pumpAndSettle();
      expect(session.appliedCount, 1);
      _vec(session.current, 1, 0, 0, reason: 'Ry(π/2)|0⟩');
      expect(find.byKey(const ValueKey('bloch-step-1')), findsOneWidget);
      // M11F: the state uses the Composer's own presentation.
      final panel = tester.widget<QqCurrentStatePanel>(find.descendant(
          of: find.byKey(const ValueKey('bloch-state-expression')),
          matching: find.byType(QqCurrentStatePanel)));
      expect(panel.stateVector[0].real, closeTo(math.sqrt1_2, 1e-9));
      expect(panel.stateVector[1].real, closeTo(math.sqrt1_2, 1e-9));
    });

    testWidgets('inspection is read-only until Return to current',
        (tester) async {
      final lab = await _pumpLab(tester);
      lab.session
        ..commit(SelectedGateType.hadamard)
        ..commit(SelectedGateType.z);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('bloch-step-1')));
      await tester.pump();
      expect(lab.session.inspectedIndex, 1);
      expect(
          find.byKey(const ValueKey('bloch-gates-inspecting')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
      await tester.pump();
      expect(find.byKey(const ValueKey('bloch-preview-card')), findsNothing);
      final canvas = tester.widget<CustomPaint>(
          find.byKey(const ValueKey('bloch-sphere-canvas')));
      expect((canvas.painter! as BlochSpherePainter).state.x, closeTo(1, 1e-9),
          reason: 'the sphere shows the inspected |+⟩');
      await tester.tap(find.byKey(const ValueKey('bloch-return-current')));
      await tester.pump();
      expect(lab.session.isInspecting, isFalse);
      _vec(lab.session.displayed, -1, 0, 0);
    });

    testWidgets('measurement never collapses the prepared state',
        (tester) async {
      final lab = await _pumpLab(tester);
      lab.session.commit(SelectedGateType.hadamard);
      await tester.pump();
      // M11F: Measure is always visible beside the sphere on wide screens.
      await tester.ensureVisible(find.byKey(const ValueKey('bloch-basis-x')));
      await tester.tap(find.byKey(const ValueKey('bloch-basis-x')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('bloch-run-shots')));
      await tester.pump();
      expect(find.byKey(const ValueKey('bloch-shots-result')), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('bloch-shots-result')))
              .data,
          contains('1000 × |+⟩'));
      await tester.tap(find.byKey(const ValueKey('bloch-run-once')));
      await tester.pump();
      expect(find.byKey(const ValueKey('bloch-single-result')), findsOneWidget);
      expect(lab.session.appliedCount, 1);
      _vec(lab.session.current, 1, 0, 0);
      await tester.tap(find.byKey(const ValueKey('bloch-basis-z')));
      await tester.pump();
      expect(find.byKey(const ValueKey('bloch-shots-result')), findsNothing,
          reason: 'results belong to one basis');
    });

    testWidgets('camera drags never change the state', (tester) async {
      final lab = await _pumpLab(tester);
      lab.session.commit(SelectedGateType.hadamard);
      await tester.pump();
      final before = lab.session.current;
      final cameraBefore = lab.camera;
      final sphere = find.byKey(const ValueKey('bloch-sphere-gesture'));
      // Drag from the sphere's tip and from elsewhere: both only orbit.
      await tester.drag(sphere, const Offset(80, 30));
      await tester.pump();
      final panel = tester.getRect(sphere);
      final tip = BlochProjection(size: panel.size, camera: lab.camera)
          .project(before.x, before.y, before.z);
      await tester.dragFrom(panel.topLeft + tip, const Offset(-60, 40));
      await tester.pump();
      expect(identical(lab.session.current, before), isTrue);
      expect(lab.session.appliedCount, 1);
      expect(lab.camera.yaw, isNot(cameraBefore.yaw));
    });

    for (final size in const [
      Size(1920, 1080),
      Size(1600, 900),
      Size(1440, 900),
      Size(1280, 800),
      Size(1024, 768),
      Size(800, 700),
      Size(500, 900),
    ]) {
      testWidgets('layout at $size', (tester) async {
        final lab = await _pumpLab(tester, size: size);
        lab.session.commit(SelectedGateType.hadamard);
        await tester.pump();
        expect(find.byType(BlochSpherePanel), findsOneWidget);
        expect(find.byKey(const ValueKey('bloch-evolution')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Notebook and Composer seeds', () {
    test('Bloch examples seed their authored steps and match the simulator',
        () {
      final ids = [
        'x_from_zero',
        'h_superposition',
        's_on_plus',
        't_on_plus',
        'ry_rotation',
        'rz_interference',
        'interference_hzh',
      ];
      for (final id in ids) {
        final example = notebookExampleById(id)!;
        expect(example.allowOpenInBlochExplorer, isTrue, reason: id);
        final seed = blochSeedForNotebookExample(example)!;
        expect(seed.gates.length, example.operations.length);
        expect(seed.sourceId, id);
        final session = BlochLabSession(seed);
        final state = example.execute().state;
        _amp(
            session.current,
            (state[0].real.toDouble(), state[0].imaginary.toDouble()),
            (state[1].real.toDouble(), state[1].imaginary.toDouble()),
            reason: id);
        session.dispose();
      }
      expect(gateReferenceExamplesById['t_on_plus']!.validate(), isEmpty);
    });

    test('Composer seeds: one-qubit only; measured circuits say so', () {
      final two = QuantumCircuit(currentLevel: createSandboxComposerLevel(2));
      expect(blochSeedForCircuit(two), isNull,
          reason: 'no fabricated single-qubit state for a register');
      final one = QuantumCircuit(currentLevel: createSandboxComposerLevel(1));
      one.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      one.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.s), 1, 0);
      final seed = blochSeedForCircuit(one)!;
      expect(seed.gates.map((g) => g.type),
          [SelectedGateType.hadamard, SelectedGateType.s]);
      expect(seed.note, isNot(contains('measurement')));
      one.insertMeasurementWithOutcome(qubit: 0, column: 2);
      final measured = blochSeedForCircuit(one)!;
      expect(measured.note, contains('before it is measured'));
      expect(measured.gates, hasLength(2), reason: 'M is never a gate here');
      _vec(BlochLabSession(measured).current, 0, 1, 0);
    });
  });

  group('shell integration and isolation', () {
    testWidgets('Notebook exploration is isolated and returns to the article',
        (tester) async {
      _size(tester, const Size(1440, 1000));
      final storage = _KeyedStorage();
      await tester.pumpWidget(QubitQuestWebApp(
          storage: storage, startupRoute: '/notebook/gate-hadamard'));
      await tester.pumpAndSettle();
      final progress = CampaignProgressController.instance;
      final before = progress.unlockedDiscoveryTitles().toSet();

      // The learner's own lab, with a step of their own.
      await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
      await tester.pumpAndSettle();
      final lab =
          tester.state<WebBlochWorkspaceState>(find.byType(WebBlochWorkspace));
      final standalone = lab.session..commit(SelectedGateType.x);
      final standaloneState = standalone.current;

      await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
      await tester.pumpAndSettle();
      final bloch =
          find.byKey(const ValueKey('bloch-example-hh_reversibility'));
      await tester.ensureVisible(bloch);
      await tester.pumpAndSettle();
      final writes = storage.writtenKeys.length;
      await tester.tap(bloch);
      await tester.pumpAndSettle();
      final exploring =
          tester.state<WebBlochWorkspaceState>(find.byType(WebBlochWorkspace));
      expect(identical(exploring.session, standalone), isFalse);
      expect(exploring.session.appliedCount, 2, reason: 'H, H');
      expect(find.byKey(const ValueKey('bloch-exploration-banner')),
          findsOneWidget);
      exploring.session.commit(SelectedGateType.y);
      await tester.tap(find.byKey(const ValueKey('bloch-reset')));
      await tester.pump();
      expect(exploring.session.appliedCount, 2, reason: 'reset to example');
      expect(storage.writtenKeys.length, writes,
          reason: 'explorations never write storage');
      expect(progress.unlockedDiscoveryTitles().toSet(), before);
      expect(identical(standalone.current, standaloneState), isTrue);
      expect(standalone.appliedCount, 1);

      await tester.tap(find.byKey(const ValueKey('bloch-exploration-return')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('web-notebook-reader-gate-hadamard')),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bloch-exploration-close')));
      await tester.pumpAndSettle();
      expect(
          identical(
              tester
                  .state<WebBlochWorkspaceState>(find.byType(WebBlochWorkspace))
                  .session,
              standalone),
          isTrue,
          reason: 'leaving shows the untouched own lab');
    });

    testWidgets('Composer exploration keeps the Sandbox and returns to it',
        (tester) async {
      _size(tester, const Size(1440, 1000));
      final storage = _KeyedStorage();
      await tester.pumpWidget(QubitQuestWebApp(storage: storage));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
      await tester.pump();
      await pumpUntilSandboxOpen(tester);
      await tester.tap(find.byKey(const ValueKey('web-composer-qubits-1')));
      await tester.pumpAndSettle();
      final canvas = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
      final circuit = canvas.circuit;
      for (final (type, column) in [
        (SelectedGateType.hadamard, 0),
        (SelectedGateType.t, 1),
      ]) {
        await canvas.onDropRequested(ComposerCircuitDropIntent(
          data: CircuitDragData.palette(Gate.fromIdentifier(type)),
          destination: CircuitDropDestination(
            contentPoint: Offset.zero,
            location: CircuitLocation(qubit: 0, column: column),
          ),
        ));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Bloch'));
      await tester.pumpAndSettle();
      final writes = storage.writtenKeys.length;
      await tester.tap(find.byKey(const ValueKey('composer-explore-in-bloch')));
      await tester.pumpAndSettle();
      final lab =
          tester.state<WebBlochWorkspaceState>(find.byType(WebBlochWorkspace));
      expect(lab.session.seed.origin, BlochLabOrigin.composer);
      expect(lab.session.appliedSteps.map((s) => s.gate.type),
          [SelectedGateType.hadamard, SelectedGateType.t]);
      lab.session.commit(SelectedGateType.x);
      await tester.pump();
      expect(storage.writtenKeys.length, writes);
      await tester.tap(find.byKey(const ValueKey('bloch-exploration-return')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
              .circuit
              .logicalGates
              .map((g) => g.type),
          [SelectedGateType.hadamard, SelectedGateType.t]);
      expect(
          identical(
              tester
                  .widget<ComposerCircuitCanvas>(
                      find.byType(ComposerCircuitCanvas))
                  .circuit,
              circuit),
          isTrue);
    });
  });
}
