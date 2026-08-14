import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/bloch_explorer_screen.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

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

  BlochState paintedState(WidgetTester tester) => (tester
          .widget<CustomPaint>(
              find.byKey(const ValueKey('bloch-sphere-canvas')))
          .painter! as BlochSpherePainter)
      .state;

  void expectLandscapeGeometry(
    WidgetTester tester,
    Size viewport, {
    required bool inlineMaths,
  }) {
    final left = tester
        .getRect(find.byKey(const ValueKey('bloch-landscape-left-column')));
    final right = tester
        .getRect(find.byKey(const ValueKey('bloch-landscape-right-column')));
    final sphere =
        tester.getRect(find.byKey(const ValueKey('bloch-sphere-panel')));
    final fittedSphereRegion =
        tester.getRect(find.byKey(const ValueKey('bloch-sphere-canvas')));
    final angles =
        tester.getRect(find.byKey(const ValueKey('bloch-live-angles')));
    final cartesian =
        tester.getRect(find.byKey(const ValueKey('bloch-live-cartesian')));
    final probabilities =
        tester.getRect(find.byKey(const ValueKey('bloch-live-probabilities')));
    final helper =
        tester.getRect(find.byKey(const ValueKey('bloch-sphere-helper')));
    final gates =
        tester.getRect(find.byKey(const ValueKey('bloch-gate-strip')));
    final playback =
        tester.getRect(find.byKey(const ValueKey('bloch-transport-controls')));
    final history =
        tester.getRect(find.byKey(const ValueKey('bloch-history-container')));
    final maths = tester.getRect(find.byKey(ValueKey(
        inlineMaths ? 'bloch-inline-maths-details' : 'bloch-maths-action')));
    final slider =
        tester.getRect(find.byKey(const ValueKey('bloch-rotation-slider')));

    expect((left.top - right.top).abs(), lessThan(1));
    expect(sphere.width, closeTo(sphere.height, 1e-9));
    expect(sphere.left, greaterThanOrEqualTo(left.left));
    expect(sphere.right, lessThanOrEqualTo(left.right));
    expect(sphere.bottom, lessThanOrEqualTo(left.bottom));
    expect(sphere.bottom, lessThanOrEqualTo(viewport.height));
    for (final overlay in [angles, cartesian, probabilities]) {
      expect(
        overlay.overlaps(fittedSphereRegion),
        isFalse,
        reason: 'Live-value overlay $overlay intersects the fitted sphere '
            'drawing region $fittedSphereRegion',
      );
    }
    expect(angles.bottom, lessThan(fittedSphereRegion.top));
    expect(cartesian.bottom, lessThan(fittedSphereRegion.top));
    expect(
      fittedSphereRegion.shortestSide / sphere.shortestSide,
      greaterThan(.44),
      reason: 'The centred sphere should use a substantial fraction of even '
          'the smallest supported landscape pane.',
    );
    final expectedCentre = Offset(
      sphere.left + sphere.width / 2,
      (helper.bottom + 6 + sphere.bottom - 2) / 2,
    );
    expect(
        (fittedSphereRegion.center.dx - expectedCentre.dx).abs(), lessThan(1));
    expect(
        (fittedSphereRegion.center.dy - expectedCentre.dy).abs(), lessThan(1));
    expect(probabilities.width, greaterThan(probabilities.height));
    for (final control in [gates, playback, history, maths]) {
      expect(control.left, greaterThanOrEqualTo(right.left));
      expect(control.right, lessThanOrEqualTo(right.right));
      expect(control.left, greaterThan(sphere.right));
    }
    expect(gates.top, lessThan(sphere.bottom));
    expect(playback.top, lessThan(sphere.bottom));
    expect(slider.width, lessThanOrEqualTo(right.width));
    expect(slider.width, lessThan(viewport.width * .6));
  }

  testWidgets('screen exposes sphere mathematics gates and history',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    expect(find.text('Bloch Explorer'), findsOneWidget);
    expect(find.text('Interactive Bloch sphere'), findsNothing);
    expect(find.text('Drag vector • orbit elsewhere • pinch to zoom'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-sphere-canvas')), findsOneWidget);
    expect(find.text('Maths / state details'), findsOneWidget);
    expect(find.text('Gate laboratory'), findsNothing);
    expect(find.byKey(const ValueKey('bloch-gate-hadamard')), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-undo')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('bloch-transport-controls')), findsOneWidget);
    expect(find.textContaining('P(|0⟩)'), findsOneWidget);
  });

  testWidgets('math notation is balanced and consistently uses lowercase phi',
      (tester) async {
    await pumpExplorer(tester);
    expect(find.byKey(const ValueKey('bloch-state-maths-expansion')),
        findsNothing);
    expect(find.byKey(const ValueKey('bloch-global-phase-expansion')),
        findsNothing);
    await tester.tap(find.byKey(const ValueKey('bloch-maths-action')));
    await tester.pumpAndSettle();
    final wavefunction = tester.widget<LatexText>(
        find.byKey(const ValueKey('bloch-wavefunction-latex')));
    expect(wavefunction.displayMathHeight, 24);
    expect(wavefunction.math, contains(r'\varphi'));
    expect(wavefunction.math, isNot(contains(r'\phi')));
    expect(wavefunction.math, isNot(contains(r'\Phi')));
    final columnVector = tester.widget<LatexText>(
        find.byKey(const ValueKey('bloch-column-vector-latex')));
    expect(columnVector.math, contains(r'\begin{bmatrix}'));
    expect(columnVector.math, contains(r'e^{i\varphi}'));
    expect(columnVector.math, isNot(contains(r'e^{i\phi}')));
    expect(columnVector.math, isNot(contains(r'\Phi')));
    expect(find.textContaining('Column vector:'), findsNothing);
    expect(find.textContaining('Φ'), findsNothing);
  });

  testWidgets('instant mode is adjacent to primary playback controls',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    expect(find.byKey(const ValueKey('bloch-instant-mode')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('bloch-animation-settings')), findsNothing);
    final controls = find.byKey(const ValueKey('bloch-transport-controls'));
    expect(
        find.descendant(
            of: controls,
            matching: find.byKey(const ValueKey('bloch-instant-mode'))),
        findsOneWidget);
    final instantCenter =
        tester.getCenter(find.byKey(const ValueKey('bloch-instant-mode'))).dy;
    final replayCenter =
        tester.getCenter(find.byKey(const ValueKey('bloch-replay'))).dy;
    expect((instantCenter - replayCenter).abs(), lessThan(12));
  });

  testWidgets('there is exactly one Reset and transport semantics are clear',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    expect(find.text('Reset'), findsOneWidget);
    expect(find.byTooltip('Reset'), findsOneWidget);
    for (final entry in {
      'bloch-undo': 'Undo',
      'bloch-redo': 'Redo',
      'bloch-replay': 'Replay',
      'bloch-reset': 'Reset',
    }.entries) {
      final semantics =
          tester.widget<Semantics>(find.byKey(ValueKey(entry.key)));
      expect(semantics.properties.label, entry.value);
      final button = find.descendant(
        of: find.byKey(ValueKey(entry.key)),
        matching: find.byType(TextButton),
      );
      expect(
        find.descendant(of: button, matching: find.byType(Column)),
        findsOneWidget,
      );
    }
  });

  testWidgets('gate strip precedes transport controls', (tester) async {
    await pumpExplorer(tester);
    final sphereBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('bloch-sphere-gesture')))
        .dy;
    final controlsTop = tester
        .getTopLeft(find.byKey(const ValueKey('bloch-transport-controls')))
        .dy;
    final gatesTop =
        tester.getTopLeft(find.byKey(const ValueKey('bloch-gate-strip'))).dy;
    expect(gatesTop, greaterThanOrEqualTo(sphereBottom));
    expect(controlsTop, greaterThan(gatesTop));
    final workspace = find.byKey(const ValueKey('bloch-primary-workspace'));
    expect(
        find.descendant(
            of: workspace,
            matching: find.byKey(const ValueKey('bloch-transport-controls'))),
        findsOneWidget);
    final historyTop = tester
        .getTopLeft(find.byKey(const ValueKey('bloch-history-container')))
        .dy;
    expect(
        historyTop - tester.getBottomLeft(workspace).dy, lessThanOrEqualTo(8));
  });

  testWidgets('live values are inside the primary sphere workspace',
      (tester) async {
    await pumpExplorer(tester, size: const Size(430, 900));
    final workspace = find.byKey(const ValueKey('bloch-primary-workspace'));
    for (final key in [
      'bloch-live-angles',
      'bloch-live-cartesian',
      'bloch-live-probabilities',
    ]) {
      expect(
          find.descendant(of: workspace, matching: find.byKey(ValueKey(key))),
          findsOneWidget);
    }
    expect(find.text('θ = 0.000'), findsOneWidget);
    expect(find.text('φ = 0.000'), findsOneWidget);
    expect(find.text('x = 0.000'), findsOneWidget);
    expect(find.text('y = 0.000'), findsOneWidget);
    expect(find.text('z = 1.000'), findsOneWidget);
  });

  testWidgets('gate strip is part of the primary workspace', (tester) async {
    await pumpExplorer(tester, size: const Size(430, 900));
    final workspace = find.byKey(const ValueKey('bloch-primary-workspace'));
    expect(
        find.descendant(
            of: workspace,
            matching: find.byKey(const ValueKey('bloch-gate-strip'))),
        findsOneWidget);
    expect(find.text('Gate laboratory'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bloch-gate-strip')),
        matching: find.byKey(const ValueKey('bloch-gate-angle-control')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Gate laboratory reuses production gate tiles and angles',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    expect(find.byType(QubitQuestGateTile), findsNWidgets(9));
    final rx = tester.widget<QubitQuestGateTile>(
        find.byKey(const ValueKey('bloch-gate-rx')));
    expect(rx.gate.label, contains('1/2π'));
  });

  testWidgets('history entries are collapsed and expand on demand',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    expect(find.byKey(const ValueKey('bloch-history-timeline')), findsNothing);
    final workspace = find.byKey(const ValueKey('bloch-primary-workspace'));
    final history = find.byKey(const ValueKey('bloch-history-container'));
    expect(
      (tester.getTopLeft(history).dx - tester.getTopLeft(workspace).dx).abs(),
      lessThan(1),
    );
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('bloch-history-timeline')), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-history-label-0')), findsOneWidget);
    final timeline = tester
        .widget<ListView>(find.byKey(const ValueKey('bloch-history-timeline')));
    expect(timeline.scrollDirection, Axis.horizontal);
    final expansionTheme = tester.widget<Theme>(find
        .ancestor(
          of: find.byKey(const ValueKey('bloch-history-expansion')),
          matching: find.byType(Theme),
        )
        .first);
    expect(expansionTheme.data.dividerColor, Colors.transparent);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bloch-history-container')),
        matching: find.byType(Divider),
      ),
      findsNothing,
    );
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('0 operations'), findsOneWidget);
  });

  testWidgets('timeline operation numbering follows Undo Redo and branching',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 operations'), findsOneWidget);
    expect(find.text('Step 1'), findsOneWidget);
    expect(find.text('Step 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bloch-undo')));
    await tester.pump();
    expect(find.text('1 operation'), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-history-step-2')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('bloch-redo')));
    await tester.pump();
    expect(find.text('2 operations'), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-history-step-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bloch-undo')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-z')));
    await tester.pump();
    expect(find.text('2 operations'), findsOneWidget);
    expect(find.text('Z'), findsWidgets);
    expect(find.text('Step 2'), findsOneWidget);
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

  testWidgets('global phase is explanatory detail rather than primary control',
      (tester) async {
    await pumpExplorer(tester, size: const Size(700, 1400));
    expect(
        find.byKey(const ValueKey('bloch-global-phase-slider')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bloch-primary-workspace')),
        matching: find.byKey(const ValueKey('bloch-global-phase-expansion')),
      ),
      findsNothing,
    );
    final thetaBefore = find.text('θ = 0.000');
    final phiBefore = find.text('φ = 0.000');
    expect(thetaBefore, findsWidgets);
    expect(phiBefore, findsWidgets);

    await tester.tap(find.byKey(const ValueKey('bloch-maths-action')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('bloch-global-phase-slider')), findsNothing);
    expect(find.textContaining('Global phase γ:'), findsOneWidget);
    expect(find.textContaining('Relative phase φ'), findsOneWidget);

    expect(thetaBefore, findsNWidgets(2));
    expect(phiBefore, findsNWidgets(2));
    expect(find.textContaining('P(|0⟩) = 100.0%'), findsNWidgets(2));
  });

  testWidgets('Replay animates the full sequence even in Instant mode',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    expect(find.text('2 operations'), findsOneWidget);
    final committed = paintedState(tester);
    expect(committed.x, closeTo(-1, 1e-9));

    await tester.tap(find.byKey(const ValueKey('bloch-replay')));
    await tester.pump();
    expect(paintedState(tester).z, closeTo(1, 1e-9));

    await tester.pump(const Duration(milliseconds: 420));
    expect(paintedState(tester).z, closeTo(-1, 1e-9));
    await tester.pumpAndSettle();
    expect(paintedState(tester).x, closeTo(committed.x, 1e-9));
    expect(find.text('2 operations'), findsOneWidget);
  });

  testWidgets('timeline selection starts Replay after the selected state',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    final committed = paintedState(tester);

    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bloch-history-step-1')));
    await tester.pump();
    expect(paintedState(tester).z, closeTo(-1, 1e-9));
    expect(find.byKey(const ValueKey('bloch-history-marker-selected')),
        findsOneWidget);
    expect(find.textContaining('Replay start: Step 1 / 2'), findsOneWidget);
    expect(find.textContaining('· X'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bloch-replay')));
    await tester.pump();
    expect(paintedState(tester).z, closeTo(-1, 1e-9));
    expect(find.byKey(const ValueKey('bloch-history-marker-active')),
        findsOneWidget);
    expect(find.textContaining('Step 2 / 2'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(paintedState(tester).x, closeTo(committed.x, 1e-9));
    expect(find.byKey(const ValueKey('bloch-history-marker-active')),
        findsNothing);
    expect(find.byKey(const ValueKey('bloch-history-marker-selected')),
        findsOneWidget);
  });

  testWidgets('history selection previews recorded state and toggles current',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    final committed = paintedState(tester);
    expect(committed.x, closeTo(-1, 1e-9));

    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();
    final undoBefore = tester.widget<TextButton>(find.descendant(
      of: find.byKey(const ValueKey('bloch-undo')),
      matching: find.byType(TextButton),
    ));
    final redoBefore = tester.widget<TextButton>(find.descendant(
      of: find.byKey(const ValueKey('bloch-redo')),
      matching: find.byType(TextButton),
    ));
    await tester.tap(find.byKey(const ValueKey('bloch-history-step-1')));
    await tester.pump();
    final firstStep = paintedState(tester);
    final recordedFirstStep = BlochState.zero.applyGate(SelectedGateType.x);
    expect(firstStep.theta, closeTo(math.pi, 1e-9));
    expect(firstStep.phi, closeTo(recordedFirstStep.phi, 1e-9));
    expect(firstStep.x, closeTo(0, 1e-9));
    expect(firstStep.y, closeTo(0, 1e-9));
    expect(firstStep.z, closeTo(-1, 1e-9));
    expect(find.text('θ = 3.142'), findsOneWidget);
    expect(find.text('z = -1.000'), findsOneWidget);
    expect(find.textContaining('P(|1⟩) = 100.0%'), findsOneWidget);
    final undoAfter = tester.widget<TextButton>(find.descendant(
      of: find.byKey(const ValueKey('bloch-undo')),
      matching: find.byType(TextButton),
    ));
    final redoAfter = tester.widget<TextButton>(find.descendant(
      of: find.byKey(const ValueKey('bloch-redo')),
      matching: find.byType(TextButton),
    ));
    expect(undoAfter.onPressed != null, undoBefore.onPressed != null);
    expect(redoAfter.onPressed != null, redoBefore.onPressed != null);
    expect(find.textContaining('2 operations'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bloch-history-step-0')));
    await tester.pump();
    expect(paintedState(tester).z, closeTo(1, 1e-9));
    expect(find.textContaining('Replay start: Start'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bloch-history-step-0')));
    await tester.pump();
    expect(paintedState(tester).x, closeTo(committed.x, 1e-9));
    expect(find.byKey(const ValueKey('bloch-history-marker-selected')),
        findsNothing);
  });

  testWidgets('Undo and a new gate exit preview without historical branching',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bloch-history-step-0')));
    await tester.pump();
    expect(paintedState(tester).z, closeTo(1, 1e-9));
    await tester.tap(find.byKey(const ValueKey('bloch-undo')));
    await tester.pump();
    expect(paintedState(tester).z, closeTo(-1, 1e-9));
    expect(find.text('1 operation'), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-history-marker-selected')),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey('bloch-redo')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-step-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-z')));
    await tester.pump();
    expect(paintedState(tester).x, closeTo(1, 1e-9));
    expect(find.text('3 operations'), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-history-marker-selected')),
        findsNothing);
  });

  testWidgets('vector editing exits preview and appends to committed history',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bloch-history-step-0')));
    await tester.pump();
    expect(paintedState(tester).z, closeTo(1, 1e-9));

    final canvas = find.byKey(const ValueKey('bloch-sphere-canvas'));
    final paint = tester.widget<CustomPaint>(canvas);
    final painter = paint.painter! as BlochSpherePainter;
    final size = tester.getSize(canvas);
    final projection = BlochProjection(size: size, camera: painter.camera);
    final start = tester.getTopLeft(canvas) + projection.project(0, 0, 1);
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveBy(const Offset(70, 55));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.text('2 operations'), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-history-marker-selected')),
        findsNothing);
    await tester.tap(find.byKey(const ValueKey('bloch-undo')));
    await tester.pump();
    expect(paintedState(tester).z, closeTo(-1, 1e-9));
  });

  testWidgets(
      'long press inspects a history gate without changing replay selection',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bloch-history-step-1')));
    await tester.pump();
    final selectedPreview = paintedState(tester);
    expect(find.byType(GateInspectorDialog), findsNothing);

    await tester.longPress(find.byKey(const ValueKey('bloch-history-step-2')));
    await tester.pumpAndSettle();
    expect(find.byType(GateInspectorDialog), findsOneWidget);
    expect(find.text('Hadamard gate'), findsOneWidget);
    expect(find.text('History step 2 of 2'), findsOneWidget);
    expect(find.text('Applied after: X'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('gate-inspector-context')), findsOneWidget);
    expect(find.text('Open Notebook'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(GateInspectorDialog), findsNothing);
    expect(find.byKey(const ValueKey('bloch-history-marker-selected')),
        findsOneWidget);
    expect(paintedState(tester).z, closeTo(selectedPreview.z, 1e-9));
    expect(find.textContaining('Replay start: Step 1 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bloch-replay')));
    await tester.pumpAndSettle();
    expect(paintedState(tester).x, closeTo(-1, 1e-9));
  });

  testWidgets('Bloch gate long press inspects while tap still applies',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    final gate = find.byKey(const ValueKey('bloch-gate-hadamard'));

    await tester.longPress(gate);
    await tester.pumpAndSettle();
    expect(find.byType(GateInspectorDialog), findsOneWidget);
    expect(find.text('Hadamard gate'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('0 operations'), findsOneWidget);

    await tester.tap(gate);
    await tester.pumpAndSettle();
    expect(find.byType(GateInspectorDialog), findsNothing);
    expect(find.text('1 operation'), findsOneWidget);
    expect(paintedState(tester).x, closeTo(1, 1e-9));
  });

  testWidgets('rotation history inspection uses the recorded configured angle',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    final slider = tester
        .widget<Slider>(find.byKey(const ValueKey('bloch-rotation-slider')));
    slider.onChanged!(-math.pi / 4);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-ry')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('bloch-history-step-1')));
    await tester.pumpAndSettle();
    expect(find.byType(GateInspectorDialog), findsOneWidget);
    expect(find.text('Ry rotation gate'), findsOneWidget);
    expect(find.textContaining('Configured angle: Ry -1/4π'), findsOneWidget);
    expect(find.text('History step 1 of 1'), findsOneWidget);
    expect(find.text('Applied after: Start'), findsOneWidget);
  });

  testWidgets('Start and direct-state entries do not open Gate Inspector',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('bloch-history-step-0')));
    await tester.pumpAndSettle();
    expect(find.byType(GateInspectorDialog), findsNothing);

    final canvas = find.byKey(const ValueKey('bloch-sphere-canvas'));
    final paint = tester.widget<CustomPaint>(canvas);
    final painter = paint.painter! as BlochSpherePainter;
    final projection =
        BlochProjection(size: tester.getSize(canvas), camera: painter.camera);
    final start = tester.getTopLeft(canvas) + projection.project(0, 0, 1);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(65, 45));
    await gesture.up();
    await tester.pump();
    await tester.longPress(find.byKey(const ValueKey('bloch-history-step-1')));
    await tester.pumpAndSettle();
    expect(find.byType(GateInspectorDialog), findsNothing);
  });

  testWidgets('selecting current disables Replay and Undo clears stale start',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bloch-history-step-2')));
    await tester.pump();

    final replay = tester.widget<TextButton>(find.descendant(
      of: find.byKey(const ValueKey('bloch-replay')),
      matching: find.byType(TextButton),
    ));
    expect(replay.onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('bloch-undo')));
    await tester.pump();
    expect(find.byKey(const ValueKey('bloch-history-marker-selected')),
        findsNothing);
    await tester.tap(find.byKey(const ValueKey('bloch-gate-z')));
    await tester.pump();
    expect(find.byKey(const ValueKey('bloch-history-marker-selected')),
        findsNothing);
  });

  testWidgets('selecting Initial explicitly performs full Replay',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bloch-history-step-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-replay')));
    await tester.pump();
    expect(paintedState(tester).z, closeTo(1, 1e-9));
    await tester.pumpAndSettle();
  });

  testWidgets('Replay disables conflicts and Reset cancels playback',
      (tester) async {
    await pumpExplorer(tester, size: const Size(800, 1400));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-history-expansion')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bloch-replay')));
    await tester.pump(const Duration(milliseconds: 100));
    final replayButton = tester.widget<TextButton>(find.descendant(
      of: find.byKey(const ValueKey('bloch-replay')),
      matching: find.byType(TextButton),
    ));
    expect(replayButton.onPressed, isNull);
    final gate = tester
        .widget<QubitQuestGateTile>(find.byKey(const ValueKey('bloch-gate-z')));
    expect(gate.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('bloch-reset')));
    await tester.pumpAndSettle();
    expect(paintedState(tester).z, closeTo(1, 1e-9));
    expect(find.text('0 operations'), findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-history-marker-active')),
        findsNothing);
  });

  testWidgets('landscape uses fixed sphere and scrollable controls columns',
      (tester) async {
    const viewport = Size(1000, 520);
    await pumpExplorer(tester, size: viewport);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('bloch-landscape-workspace')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-explorer-scroll')), findsNothing);
    final left = find.byKey(const ValueKey('bloch-landscape-left-column'));
    final right = find.byKey(const ValueKey('bloch-landscape-right-column'));
    expect(
      (tester.getTopLeft(left).dy - tester.getTopLeft(right).dy).abs(),
      lessThan(1),
    );
    for (final key in [
      'bloch-gate-strip',
      'bloch-transport-controls',
      'bloch-history-container',
      'bloch-inline-maths-details',
    ]) {
      expect(
        find.descendant(of: right, matching: find.byKey(ValueKey(key))),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: left,
        matching: find.byKey(const ValueKey('bloch-gate-strip')),
      ),
      findsNothing,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('bloch-gate-strip'))).dy,
      lessThan(tester
          .getTopLeft(find.byKey(const ValueKey('bloch-transport-controls')))
          .dy),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('bloch-transport-controls')))
          .dy,
      lessThan(tester
          .getTopLeft(find.byKey(const ValueKey('bloch-history-container')))
          .dy),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('bloch-history-container')))
          .dy,
      lessThan(tester
          .getTopLeft(find.byKey(const ValueKey('bloch-inline-maths-details')))
          .dy),
    );
    expect(tester.getRect(right).right, closeTo(986, 1));
    expectLandscapeGeometry(tester, viewport, inlineMaths: true);
  });

  testWidgets('tablet landscape sphere is square and fully visible',
      (tester) async {
    const viewport = Size(1280, 800);
    await pumpExplorer(tester, size: viewport);
    expect(find.byKey(const ValueKey('bloch-landscape-workspace')),
        findsOneWidget);
    final square = tester
        .getRect(find.byKey(const ValueKey('bloch-landscape-sphere-square')));
    final panel =
        tester.getRect(find.byKey(const ValueKey('bloch-sphere-panel')));
    expect(square.width, closeTo(square.height, 1e-9));
    expect(panel.width, closeTo(panel.height, 1e-9));
    expect(square.top, greaterThanOrEqualTo(0));
    expect(square.bottom, lessThanOrEqualTo(800));
    final left = find.byKey(const ValueKey('bloch-landscape-left-column'));
    for (final key in [
      'bloch-live-angles',
      'bloch-live-cartesian',
      'bloch-live-probabilities',
    ]) {
      expect(find.descendant(of: left, matching: find.byKey(ValueKey(key))),
          findsOneWidget);
    }
    expectLandscapeGeometry(tester, viewport, inlineMaths: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide landscape expands maths inline in controls column',
      (tester) async {
    await pumpExplorer(tester, size: const Size(1000, 520));
    final right = find.byKey(const ValueKey('bloch-landscape-right-column'));
    expect(find.byKey(const ValueKey('bloch-inline-maths-details')),
        findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('bloch-inline-maths-expansion')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: right,
        matching: find.byKey(const ValueKey('bloch-maths-dialog-content')),
      ),
      findsOneWidget,
    );
    expect(find.byType(QubitQuestDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small landscape phone uses two columns without overflow',
      (tester) async {
    const viewport = Size(700, 400);
    await pumpExplorer(tester, size: viewport);
    expect(find.byKey(const ValueKey('bloch-landscape-workspace')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('bloch-maths-action')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('bloch-inline-maths-details')), findsNothing);
    expectLandscapeGeometry(tester, viewport, inlineMaths: false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait retains the full-width interactive sphere canvas',
      (tester) async {
    await pumpExplorer(tester, size: const Size(430, 900));
    final panel =
        tester.getRect(find.byKey(const ValueKey('bloch-sphere-panel')));
    final canvas =
        tester.getRect(find.byKey(const ValueKey('bloch-sphere-canvas')));
    expect(canvas.width, closeTo(panel.width, 1e-9));
    expect(canvas.top, closeTo(panel.top + 18, 1e-9));
    expect(
        find.byKey(const ValueKey('bloch-landscape-workspace')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('constrained landscape falls back to portrait composition',
      (tester) async {
    await pumpExplorer(tester, size: const Size(560, 320));
    expect(
        find.byKey(const ValueKey('bloch-landscape-workspace')), findsNothing);
    expect(find.byKey(const ValueKey('bloch-explorer-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  test('responsive landscape sizing uses both width and height', () {
    final phone = BlochExplorerLayout.resolve(const Size(800, 374));
    final tablet = BlochExplorerLayout.resolve(const Size(1280, 744));
    final constrained = BlochExplorerLayout.resolve(const Size(560, 264));

    expect(phone.twoColumn, isTrue);
    expect(tablet.twoColumn, isTrue);
    expect(constrained.twoColumn, isFalse);
    for (final layout in [phone, tablet]) {
      expect(
          layout.spherePanelExtent, lessThanOrEqualTo(layout.leftColumnWidth));
      expect(layout.spherePanelExtent, lessThanOrEqualTo(layout.contentHeight));
      expect(layout.sphereExtent, closeTo(layout.spherePanelExtent - 16, 1e-9));
      expect(
          layout.leftColumnWidth + layout.rightColumnWidth + 14,
          closeTo(
              layout.spherePanelExtent + layout.rightColumnWidth + 14, 1e-9));
    }
  });

  test('projected vector tips remain interactable at sphere extremes', () {
    const size = Size(340, 340);
    const projection = BlochProjection(size: size, camera: BlochCamera());
    for (final vector in const <(double, double, double)>[
      (1, 0, 0),
      (-1, 0, 0),
      (0, 1, 0),
      (0, -1, 0),
      (0, 0, 1),
      (0, 0, -1),
    ]) {
      final tip = projection.project(vector.$1, vector.$2, vector.$3);
      expect(tip.dx, inInclusiveRange(0, size.width));
      expect(tip.dy, inInclusiveRange(0, size.height));
      expect(BlochGestureResolver.resolveMode(tip, tip),
          BlochSphereGestureMode.state);
    }
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

  test('axis labels are clamped to the sphere drawing safe area', () {
    const projection = BlochProjection(
      size: Size(300, 220),
      camera: BlochCamera(),
    );
    const labelSize = Size(12, 14);
    final top = projection.safeLabelCenter(const Offset(150, -20), labelSize);
    final right = projection.safeLabelCenter(const Offset(340, 110), labelSize);
    final bottom =
        projection.safeLabelCenter(const Offset(150, 260), labelSize);
    expect(top.dy, greaterThanOrEqualTo(15));
    expect(right.dx, lessThanOrEqualTo(286));
    expect(bottom.dy, lessThanOrEqualTo(205));

    for (final endpoint in [
      projection.project(1.25, 0, 0),
      projection.project(0, 1.25, 0),
      projection.project(0, 0, 1.25),
    ]) {
      expect(
        (projection.safeLabelCenter(endpoint, labelSize) - endpoint).distance,
        lessThan(20),
      );
    }
  });
}
