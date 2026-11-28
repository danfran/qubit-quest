// v2.6 M11F: Bloch Explorer refinement.
//
// The geometry must agree with the simulator: every drawn path ends at the
// simulated state, full turns are drawn as full turns, and equal Bloch
// vectors are never mistaken for equal state vectors. Previews and playback
// never change the recorded steps.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/bloch_lab.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/canonical_qubit_state.dart';
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_bloch_workspace.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';

const _e = 1e-9;
ValueKey<String> _k(String v) => ValueKey(v);

void _same((double, double, double) a, (double, double, double) b,
    {String? reason}) {
  expect(a.$1, closeTo(b.$1, 1e-7), reason: '$reason x');
  expect(a.$2, closeTo(b.$2, 1e-7), reason: '$reason y');
  expect(a.$3, closeTo(b.$3, 1e-7), reason: '$reason z');
}

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<WebBlochWorkspaceState> _pump(WidgetTester tester,
    {BlochLabSession? lab,
    Size size = const Size(1440, 900),
    bool reducedMotion = false,
    double textScale = 1}) async {
  _size(tester, size);
  final session = lab ?? BlochLabSession.standalone();
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        disableAnimations: reducedMotion,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(body: WebBlochWorkspace(standalone: session)),
    ),
  ));
  await tester.pump();
  return tester.state(find.byType(WebBlochWorkspace));
}

BlochSpherePainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(_k('bloch-sphere-canvas'))).painter!
        as BlochSpherePainter;

void main() {
  final custom = BlochState.fromAngles(theta: 1.1, phi: 2.3);
  final starts = [
    for (final c in CanonicalQubitState.values) c.blochState,
    custom,
  ];
  const angles = [
    math.pi / 4,
    math.pi / 2,
    math.pi,
    3 * math.pi / 2,
    2 * math.pi,
    5 * math.pi / 2,
    4 * math.pi,
    -math.pi / 2,
  ];

  group('geometry agrees with the simulator', () {
    test('every drawn path ends at the simulated state', () {
      for (final start in starts) {
        for (final type in blochLabGateTypes) {
          for (final angle
              in blochLabIsRotation(type) ? angles : const [math.pi / 2]) {
            final session = BlochLabSession.standalone()
              ..prepare(start, 'start');
            final step = session.preview(type, angle: angle);
            _same(step.rotation.apply(start.vector, 1), step.after.vector,
                reason: '${type.name}($angle) from ${start.vector}');
          }
        }
      }
    });

    test('Rx, Ry and Rz turn about their own axes by the given angle', () {
      for (final (type, axis) in const [
        (SelectedGateType.rx, (1.0, 0.0, 0.0)),
        (SelectedGateType.ry, (0.0, 1.0, 0.0)),
        (SelectedGateType.rz, (0.0, 0.0, 1.0)),
      ]) {
        for (final angle in angles) {
          final r = blochRotationFor(type, angle: angle)!;
          expect(r.axis, axis);
          expect(r.angle, angle, reason: 'no reduction modulo 2π');
        }
      }
      // Right-hand rule: Rz(π/2) takes |+⟩ to |+i⟩ (the simulator agrees).
      final s = CanonicalQubitState.plus.blochState
          .applyGate(SelectedGateType.rz, angle: math.pi / 2);
      _same(s.vector, (0, 1, 0));
    });

    test('a 3π/2 rotation goes the long way round', () {
      final r = blochRotationFor(SelectedGateType.rx, angle: 3 * math.pi / 2)!;
      // From |0⟩ about +X: after π/2 the vector is at −Y (|−i⟩), after π at
      // |1⟩; the shortest path to the endpoint |+i⟩ would never pass |1⟩.
      _same(r.apply((0, 0, 1), 1 / 3), (0, -1, 0));
      _same(r.apply((0, 0, 1), 2 / 3), (0, 0, -1));
      _same(r.apply((0, 0, 1), 1), (0, 1, 0));
    });

    test('Rx(2π) = −I: a full turn, same Bloch vector, state × −1', () {
      final session = BlochLabSession.standalone();
      final step = session.preview(SelectedGateType.rx, angle: 2 * math.pi);
      final outcome = BlochStepOutcome.of(step);
      expect(outcome.moves, isFalse);
      expect(outcome.fullTurns, 1);
      expect(outcome.globalPhase!.abs(), closeTo(math.pi, _e));
      expect(step.after.alpha.real, closeTo(-1, _e));
      // The path is a whole circle, not a point: halfway it is at |1⟩.
      expect(step.rotation.isOnAxis(step.before.vector), isFalse);
      _same(step.rotation.apply(step.before.vector, .5), (0, 0, -1));
    });

    test('Rx(4π) = I: two full turns and no phase at all', () {
      final step = BlochLabSession.standalone()
          .preview(SelectedGateType.rx, angle: 4 * math.pi);
      final outcome = BlochStepOutcome.of(step);
      expect(outcome.fullTurns, 2);
      expect(outcome.globalPhase, 0);
      expect(step.after.alpha.real, closeTo(1, _e));
    });

    test('a gate that only adds a global phase: Z on |1⟩, Rz on |0⟩', () {
      final one = BlochLabSession.standalone()
        ..prepare(CanonicalQubitState.one.blochState, '|1⟩');
      final z = BlochStepOutcome.of(one.preview(SelectedGateType.z));
      expect(z.moves, isFalse);
      expect(z.fullTurns, 0, reason: 'on the axis: no path');
      expect(z.globalPhase!.abs(), closeTo(math.pi, _e), reason: 'Z|1⟩ = −|1⟩');
      final rz = BlochStepOutcome.of(BlochLabSession.standalone()
          .preview(SelectedGateType.rz, angle: math.pi / 2));
      expect(rz.globalPhase, closeTo(-math.pi / 4, _e),
          reason: 'Rz(π/2)|0⟩ = e^{−iπ/4}|0⟩');
      final zero = BlochStepOutcome.of(
          BlochLabSession.standalone().preview(SelectedGateType.z));
      expect(zero.globalPhase, 0, reason: 'Z|0⟩ = |0⟩ exactly');
    });

    test('T on |+⟩ and H twice: geometry and exact amplitudes', () {
      final plus = BlochLabSession.standalone()
        ..prepare(CanonicalQubitState.plus.blochState, '|+⟩');
      final t = plus.preview(SelectedGateType.t);
      _same(t.after.vector, (math.sqrt1_2, math.sqrt1_2, 0));
      final hh = BlochLabSession.standalone()
        ..commit(SelectedGateType.hadamard)
        ..commit(SelectedGateType.hadamard);
      _same(hh.current.vector, (0, 0, 1));
      expect(hh.current.alpha.real, closeTo(1, _e), reason: 'H² = I');
    });
  });

  test('equal Bloch vectors, different state vectors, different names', () {
    final zero = BlochState.zero;
    final minusZero = zero
        .applyGate(SelectedGateType.x)
        .applyGate(SelectedGateType.z)
        .applyGate(SelectedGateType.x);
    _same(minusZero.vector, zero.vector);
    expect(blochCanonicalName(zero), '|0⟩');
    expect(blochCanonicalName(minusZero), '−|0⟩');
    expect(blochCanonicalName(zero.applyGate(SelectedGateType.y)), 'i|1⟩');
    expect(blochCanonicalName(BlochState.fromAngles(theta: 1, phi: 1)), isNull);
  });

  group('workspace', () {
    testWidgets('previews never record: gates, angles and cancel',
        (tester) async {
      final lab = await _pump(tester);
      await tester.tap(find.byKey(_k('bloch-gate-rx')));
      await tester.pump();
      for (final preset in ['3.1416', '6.2832', '12.5664']) {
        await tester.ensureVisible(find.byKey(_k('angle-preset-$preset')));
        await tester.tap(find.byKey(_k('angle-preset-$preset')));
        await tester.pump();
      }
      expect(lab.session.allSteps, isEmpty);
      expect(find.byKey(_k('bloch-legend-path')), findsOneWidget);
      expect(find.byKey(_k('bloch-preview-on-axis')), findsOneWidget,
          reason: 'Rx(4π) returns to its start: said, not implied');
      final overlay = _painter(tester).overlay!;
      expect(overlay.applied, isFalse, reason: 'a prediction is dashed');
      expect(overlay.rotation!.angle, 4 * math.pi);
      await tester.tap(find.byKey(_k('bloch-cancel-preview')));
      await tester.pump();
      expect(lab.session.allSteps, isEmpty);
    });

    testWidgets('canonical labels follow the projection; old fixed labels off',
        (tester) async {
      await _pump(tester);
      final painter = _painter(tester);
      expect(painter.stateLabels, isTrue);
      expect(painter.overlay!.basisLabels, isFalse);
      for (final c in CanonicalQubitState.values) {
        expect(find.byKey(_k('bloch-prep-${c.name}')), findsOneWidget);
      }
    });

    testWidgets(
        'Play steps replays the recorded steps without adding any; pause, '
        'resume and speed change only the drawing', (tester) async {
      final lab = await _pump(tester);
      final s = lab.session
        ..commit(SelectedGateType.hadamard)
        ..commit(SelectedGateType.s)
        ..commit(SelectedGateType.rx, angle: 2 * math.pi);
      final expected = s.current;
      await tester.pump();
      await tester.tap(find.byKey(_k('bloch-play')));
      await tester.pump();
      expect(lab.isPlaying, isTrue);
      expect(lab.playbackStep, 1);
      expect(s.inspectedIndex, 1, reason: 'the panels name the step shown');
      await tester.pump(const Duration(milliseconds: 300));
      // Pause mid-step: the vector stays where it is.
      await tester.tap(find.byKey(_k('bloch-play')));
      await tester.pump();
      expect(lab.isPaused, isTrue);
      final paused = lab.sphereState.vector;
      await tester.pump(const Duration(seconds: 2));
      _same(lab.sphereState.vector, paused);
      // Resume at double speed.
      await tester.tap(find.byKey(_k('bloch-play')));
      await tester.pump();
      lab.setSpeed(2);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(lab.isPlaying, isFalse);
      expect(s.isInspecting, isFalse, reason: 'ends on the current state');
      expect(s.allSteps.length, 3, reason: 'no duplicated steps');
      expect(s.appliedCount, 3);
      _same(lab.sphereState.vector, expected.vector);
      expect(identical(s.current, expected), isTrue);
    });

    testWidgets('step back and forward inspect; history is untouched',
        (tester) async {
      final lab = await _pump(tester);
      final s = lab.session
        ..commit(SelectedGateType.hadamard)
        ..commit(SelectedGateType.z);
      await tester.pump();
      await tester.tap(find.byKey(_k('bloch-step-back')));
      await tester.pumpAndSettle();
      expect(s.inspectedIndex, 1);
      _same(lab.sphereState.vector, (1, 0, 0));
      await tester.tap(find.byKey(_k('bloch-to-start')));
      await tester.pumpAndSettle();
      expect(s.inspectedIndex, 0);
      await tester.tap(find.byKey(_k('bloch-step-forward')));
      await tester.pumpAndSettle();
      expect(s.inspectedIndex, 1);
      await tester.tap(find.byKey(_k('bloch-to-current')));
      await tester.pumpAndSettle();
      expect(s.isInspecting, isFalse);
      expect(s.allSteps.length, 2);
    });

    testWidgets('reset and prepare during playback stop it safely',
        (tester) async {
      final lab = await _pump(tester);
      lab.session
        ..commit(SelectedGateType.x)
        ..commit(SelectedGateType.hadamard);
      await tester.pump();
      await tester.tap(find.byKey(_k('bloch-play')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(_k('bloch-reset')));
      await tester.pumpAndSettle();
      expect(lab.isPlaying, isFalse);
      expect(lab.session.allSteps, isEmpty);
      lab.session.commit(SelectedGateType.y);
      await tester.pump();
      await tester.tap(find.byKey(_k('bloch-play')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.ensureVisible(find.byKey(_k('bloch-prep-minusI')));
      await tester.tap(find.byKey(_k('bloch-prep-minusI')));
      await tester.pumpAndSettle();
      expect(lab.isPlaying, isFalse);
      _same(lab.sphereState.vector, (0, -1, 0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Apply records exactly one step and animates along its path',
        (tester) async {
      final lab = await _pump(tester);
      await tester.tap(find.byKey(_k('bloch-gate-hadamard')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(_k('bloch-apply')));
      await tester.tap(find.byKey(_k('bloch-apply')));
      await tester.pump(const Duration(milliseconds: 450));
      expect(lab.session.appliedCount, 1);
      final mid = lab.sphereState.vector;
      expect((mid.$1 - 1).abs() > .01 || mid.$3.abs() > .01, isTrue,
          reason: 'mid-path, not yet at |+⟩');
      await tester.pumpAndSettle();
      _same(lab.sphereState.vector, (1, 0, 0));
      expect(lab.session.allSteps.length, 1);
    });

    testWidgets('reduced motion: Apply shows the result at once',
        (tester) async {
      final lab = await _pump(tester, reducedMotion: true);
      await tester.tap(find.byKey(_k('bloch-gate-x')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(_k('bloch-apply')));
      await tester.tap(find.byKey(_k('bloch-apply')));
      await tester.pump();
      _same(lab.sphereState.vector, (0, 0, -1));
    });

    testWidgets(
        'measurement: predicted probabilities, a random outcome and the '
        'post-measurement state; the prepared state is never collapsed',
        (tester) async {
      final lab = await _pump(tester, size: const Size(1920, 1080));
      lab.session.prepare(CanonicalQubitState.plusI.blochState, '|+i⟩');
      await tester.pump();
      final y = find.byKey(_k('bloch-basis-y'));
      await tester.ensureVisible(y);
      await tester.tap(y);
      await tester.pump();
      expect(find.text('100.0%'), findsWidgets);
      await tester.ensureVisible(find.byKey(_k('bloch-run-once')));
      await tester.tap(find.byKey(_k('bloch-run-once')));
      await tester.pump();
      expect(find.byKey(_k('bloch-single-result')), findsOneWidget);
      final overlay = _painter(tester).overlay!;
      expect(overlay.basis, BlochBasis.y);
      _same(overlay.outcomeVector!, (0, 1, 0), reason: 'outcome |+i⟩');
      _same(lab.session.current.vector, (0, 1, 0));
      expect(lab.session.allSteps, isEmpty);
    });

    testWidgets('resizing keeps the exploration and the selected gate',
        (tester) async {
      final lab = await _pump(tester, size: const Size(1920, 1080));
      lab.session.commit(SelectedGateType.hadamard);
      await tester.tap(find.byKey(_k('bloch-gate-t')));
      await tester.pump();
      for (final size in const [
        Size(1024, 768),
        Size(390, 844),
        Size(844, 390),
        Size(1920, 1080),
      ]) {
        _size(tester, size);
        await tester.pump();
        expect(lab.session.appliedCount, 1);
        expect(lab.selectedGate, SelectedGateType.t);
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });
  });

  group('no overflow', () {
    for (final (size, scale) in const [
      (Size(390, 844), 1.0),
      (Size(390, 844), 1.4),
      (Size(500, 900), 1.0),
      (Size(800, 900), 1.0),
      (Size(1024, 768), 1.0),
      (Size(1280, 800), 1.0),
      (Size(1440, 900), 1.0),
      (Size(1650, 900), 1.0),
      (Size(1920, 1080), 1.0),
      (Size(2560, 1080), 1.0),
      (Size(844, 390), 1.0),
    ]) {
      testWidgets('$size ×$scale with a preview and steps', (tester) async {
        final lab = await _pump(tester, size: size, textScale: scale);
        lab.session
          ..commit(SelectedGateType.hadamard)
          ..commit(SelectedGateType.s);
        lab.selectGate(SelectedGateType.ry);
        await tester.pump();
        expect(find.byType(BlochSpherePanel), findsOneWidget);
        expect(find.byKey(_k('bloch-evolution')), findsOneWidget);
        expect(find.byKey(_k('bloch-transport')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('scientific content (M11F audit)', () {
    test('Bell State: H on q0 from |00⟩ gives (|00⟩ + |01⟩)/√2', () {
      final prepare = notebookEntriesById['bell_state']!
          .whatChanged!
          .examples
          .firstWhere((e) => e.label == 'Prepare possibilities');
      expect(prepare.notation, contains('(|00⟩ + |01⟩)/√2'));
      expect(prepare.latex, contains(r'\lvert01\rangle'));
      expect(prepare.latex, isNot(contains(r'\lvert10\rangle')));
      // The simulator, with q0 as the rightmost ket symbol.
      final h = ExecutableNotebookExample(
        id: 'audit-h-q0',
        title: 'H on q0',
        description: '',
        qubitCount: 2,
        initialBinaryState: '00',
        operations: const [
          CanonicalCircuitStep.single(SelectedGateType.hadamard,
              targetQubit: 0),
        ],
      ).execute().state;
      expect(h[1].real, closeTo(math.sqrt1_2, _e), reason: '|01⟩');
      expect(h[2].real, closeTo(0, _e), reason: '|10⟩');
      // The Notebook's own Bell experiment uses the same first step.
      final bell = executableNotebookExamplesById['bell_phi_plus']!;
      expect(bell.operations.first.gateType, SelectedGateType.hadamard);
      expect(bell.operations.first.targetQubit, 0);
    });
  });
}
