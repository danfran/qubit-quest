import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/screens/bloch_explorer_screen.dart';
import 'package:quantumquiz/widgets/latex_text.dart';

void main() {
  Future<void> pumpExplorer(WidgetTester tester,
      {Size size = const Size(800, 900)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: BlochExplorerScreen()),
    );
  }

  testWidgets('screen exposes sphere mathematics gates and history',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    expect(find.text('Bloch Explorer'), findsOneWidget);
    expect(find.text('Interactive Bloch sphere'), findsNothing);
    expect(find.text('Drag vector • orbit elsewhere • pinch to zoom'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-sphere-canvas')), findsOneWidget);
    expect(find.text('Current state'), findsOneWidget);
    expect(find.text('Gate laboratory'), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-gate-hadamard')), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-undo')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('bloch-transport-controls')), findsOneWidget);
    expect(find.textContaining('P(|0⟩)'), findsOneWidget);
  });

  testWidgets('math notation is balanced and consistently uses lowercase phi',
      (tester) async {
    await pumpExplorer(tester);
    final wavefunction = tester.widget<LatexText>(
        find.byKey(const ValueKey('bloch-wavefunction-latex')));
    final columnVector = tester.widget<LatexText>(
        find.byKey(const ValueKey('bloch-column-vector-latex')));

    expect(wavefunction.displayMathHeight, 20);
    expect(wavefunction.math, contains(r'\phi'));
    expect(wavefunction.math, isNot(contains(r'\Phi')));
    expect(columnVector.math, contains(r'\begin{bmatrix}'));
    expect(columnVector.math, contains(r'e^{i\phi}'));
    expect(find.textContaining('Column vector:'), findsNothing);
  });

  testWidgets('animation preference is collapsed outside primary controls',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    expect(find.byKey(const ValueKey('bloch-instant-mode')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('bloch-animation-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bloch-instant-mode')), findsOneWidget);
  });

  testWidgets('transport controls stay directly beneath the sphere',
      (tester) async {
    await pumpExplorer(tester);
    final sphereBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('bloch-sphere-gesture')))
        .dy;
    final controlsTop = tester
        .getTopLeft(find.byKey(const ValueKey('bloch-transport-controls')))
        .dy;
    // The sphere panel's bottom padding plus the explicit strip gap.
    expect(controlsTop - sphereBottom, lessThanOrEqualTo(24));
  });

  testWidgets('history entries are collapsed and expand on demand',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    expect(find.text('● Initial'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();
    expect(find.text('● Initial'), findsOneWidget);
  });

  testWidgets('gate application updates probabilities and supports undo redo',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pumpAndSettle();
    expect(find.textContaining('P(|1⟩) = 100.0%'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bloch-undo')));
    await tester.pump();
    expect(find.textContaining('P(|0⟩) = 100.0%'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bloch-redo')));
    await tester.pump();
    expect(find.textContaining('P(|1⟩) = 100.0%'), findsOneWidget);
  });

  testWidgets('camera gesture does not change state mathematics',
      (tester) async {
    await pumpExplorer(tester);
    final before = tester
        .widgetList<Text>(find.byType(Text))
        .map((e) => e.data)
        .where((text) => text?.startsWith('P(|0⟩)') ?? false)
        .single;
    final sphere = find.byKey(const ValueKey('bloch-sphere-gesture'));
    final beforePainter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('bloch-sphere-canvas')));
    final beforeCamera = (beforePainter.painter! as BlochSpherePainter).camera;
    await tester.dragFrom(tester.getCenter(sphere), const Offset(90, 20));
    await tester.pump();
    final afterPainter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('bloch-sphere-canvas')));
    final afterCamera = (afterPainter.painter! as BlochSpherePainter).camera;
    final after = tester
        .widgetList<Text>(find.byType(Text))
        .map((e) => e.data)
        .where((text) => text?.startsWith('P(|0⟩)') ?? false)
        .single;
    expect(after, before);
    expect(afterCamera.yaw, isNot(beforeCamera.yaw));
    expect(afterCamera.pitch, isNot(beforeCamera.pitch));
  });

  testWidgets('global phase is advanced and leaves Bloch state unchanged',
      (tester) async {
    await pumpExplorer(tester, size: const Size(700, 1400));
    expect(
        find.byKey(const ValueKey('bloch-global-phase-slider')), findsNothing);
    final thetaBefore = find.text('θ = 0.000');
    final phiBefore = find.text('φ (relative phase) = 0.000');
    expect(thetaBefore, findsOneWidget);
    expect(phiBefore, findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('bloch-global-phase-expansion')));
    await tester.pumpAndSettle();
    final slider = find.byKey(const ValueKey('bloch-global-phase-slider'));
    expect(slider, findsOneWidget);
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    await tester.drag(slider, const Offset(90, 0));
    await tester.pump();

    expect(thetaBefore, findsOneWidget);
    expect(phiBefore, findsOneWidget);
    expect(find.textContaining('P(|0⟩) = 100.0%'), findsOneWidget);
  });

  testWidgets('replay visibly restarts the previous transition',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pumpAndSettle();
    expect(find.textContaining('P(|1⟩) = 100.0%'), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-replay')), findsOneWidget);
    expect(find.text('2 operations'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bloch-replay')));
    await tester.pump();
    expect(find.textContaining('P(|0⟩) = 100.0%'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.textContaining('P(|1⟩) = 100.0%'), findsOneWidget);
    expect(find.text('2 operations'), findsOneWidget);
  });

  testWidgets('landscape layout remains scrollable', (tester) async {
    await pumpExplorer(tester, size: const Size(1000, 520));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('bloch-explorer-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-rotation-slider')), findsOneWidget);
  });

  test('screen projection constrains dragged state to sphere', () {
    const projection = BlochProjection(
      size: Size(400, 400),
      camera: BlochCamera(),
    );
    final state = projection.stateForPoint(
      const Offset(1000, -500),
      globalPhase: .7,
    );
    expect(state.x * state.x + state.y * state.y + state.z * state.z,
        closeTo(1, 1e-12));
    expect(state.globalPhase, closeTo(.7, 1e-12));
  });

  test('gesture resolver reserves a focused tip target and orbits elsewhere',
      () {
    const tip = Offset(200, 100);
    expect(BlochGestureResolver.resolveMode(tip, tip),
        BlochSphereGestureMode.state);
    expect(
        BlochGestureResolver.resolveMode(
            tip + const Offset(BlochGestureResolver.vectorTipHitRadius + 1, 0),
            tip),
        BlochSphereGestureMode.orbit);
    const camera = BlochCamera();
    final orbit = BlochGestureResolver.orbit(
        camera: camera, dragDelta: const Offset(60, -30));
    expect(orbit.yaw, isNot(camera.yaw));
    expect(orbit.pitch, isNot(camera.pitch));
  });
}
