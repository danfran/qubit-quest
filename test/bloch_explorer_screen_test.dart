import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/bloch_explorer_screen.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
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

  testWidgets('landscape layout remains scrollable', (tester) async {
    await pumpExplorer(tester, size: const Size(1000, 520));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('bloch-explorer-scroll')), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(find
        .descendant(
          of: find.byKey(const ValueKey('bloch-explorer-scroll')),
          matching: find.byType(Scrollable),
        )
        .first);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bloch-rotation-slider')), findsOneWidget);
    final row = find.byKey(const ValueKey('bloch-landscape-top-row'));
    final spherePanel = find.byKey(const ValueKey('bloch-primary-workspace'));
    final currentState = find.byKey(const ValueKey('bloch-maths-action'));
    expect(row, findsOneWidget);
    expect(
      (tester.getTopLeft(spherePanel).dy - tester.getTopLeft(currentState).dy)
          .abs(),
      lessThan(1),
    );
  });

  testWidgets('tablet landscape top columns align without overflow',
      (tester) async {
    await pumpExplorer(tester, size: const Size(1280, 800));
    expect(
        find.byKey(const ValueKey('bloch-landscape-top-row')), findsOneWidget);
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
