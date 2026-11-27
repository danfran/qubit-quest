// v2.6 M3: desktop Composer workspace through the real web shell.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/composer_gate_capabilities.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/rotation_gate_dialog.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_workspace/gate_inspector_panel.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';
import 'support/laboratory_composer_finders.dart';

ValueKey<String> _k(String key) => ValueKey(key);

class _CountingStorage extends InMemoryAppStorage {
  int writes = 0;
  @override
  Future<void> writeString(String key, String value) {
    writes++;
    return super.writeString(key, value);
  }
}

Future<void> _open(
  WidgetTester tester, {
  AppStorage? storage,
  Size size = const Size(1440, 900),
  int qubits = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester
      .pumpWidget(QubitQuestWebApp(storage: storage ?? InMemoryAppStorage()));
  await tester.pumpAndSettle();
  if (find.byKey(_k('web-navigation-menu')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(_k('web-navigation-menu')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(_k('web-nav-composer')));
  await tester.pumpAndSettle();
  await pumpUntilSandboxOpen(tester);
  await pumpUntilSandboxOpen(tester);
  await tester.tap(find.byKey(ValueKey('web-composer-qubits-$qubits')));
  await tester.pumpAndSettle();
}

QuantumCircuit _circuit(WidgetTester tester) => tester
    .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
    .circuit;

Future<void> _drop(
    WidgetTester tester, Gate gate, int qubit, int column) async {
  final canvas =
      tester.widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
  await canvas.onDropRequested(ComposerCircuitDropIntent(
    data: CircuitDragData.palette(gate),
    destination: CircuitDropDestination(
      contentPoint: Offset.zero,
      location: CircuitLocation(qubit: qubit, column: column),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, String key) =>
    tester.widget<IconButton>(find.byKey(_k(key))).onPressed != null;

Future<void> _shortcut(WidgetTester tester, LogicalKeyboardKey key,
    {bool shift = false}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  testWidgets('wide workspace shows palette, canvas, inspector and results',
      (tester) async {
    await _open(tester);
    expect(find.byKey(_k('composer-workspace-wide')), findsOneWidget);
    for (final region in [
      'composer-region-palette',
      'composer-region-canvas',
      'composer-region-inspector',
      'composer-region-results',
      'composer-workspace-toolbar',
    ]) {
      expect(find.byKey(_k(region)), findsOneWidget, reason: region);
    }
    // Categories come from the Sandbox policy, measurement included.
    for (final category in ['basic', 'phase', 'rotations', 'multiQubit']) {
      expect(find.byKey(ValueKey('composer-palette-category-$category')),
          findsOneWidget);
    }
    expect(find.byKey(_k('measurement-palette')), findsOneWidget);
    expect(find.byKey(_k('web-composer-selection-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('palette preview never edits, saves or records history',
      (tester) async {
    final storage = _CountingStorage();
    await _open(tester, storage: storage);
    await tester.pumpAndSettle();
    final writes = storage.writes;
    await tester.tap(find.byKey(_k('composer-palette-gate-hadamard')));
    await tester.pumpAndSettle();
    expect(find.byKey(_k('composer-inspector-preview')), findsOneWidget);
    expect(find.text('Hadamard gate'), findsOneWidget);
    expect(find.byKey(_k('web-composer-delete-selected-gate')), findsNothing,
        reason: 'a preview is a gate type, not an operation');
    expect(_circuit(tester).isCircuitEmpty(), isTrue);
    expect(_enabled(tester, 'composer-undo'), isFalse);
    expect(storage.writes, writes);
  });

  testWidgets('rotations are placed at π/2 and edited in the inspector',
      (tester) async {
    await _open(tester);
    await _drop(tester, Gate.fromIdentifier(SelectedGateType.rz), 0, 0);
    expect(find.byType(RotationGateDialog), findsNothing,
        reason: 'inspector-first: no modal on placement');
    final gate = _circuit(tester).logicalGates.single;
    expect(gate.gate.angle, math.pi / 2);
    expect(find.byKey(_k('composer-angle-slider')), findsOneWidget,
        reason: 'the new gate is selected for immediate editing');

    // Invalid input is rejected without touching the circuit.
    await _show(tester, find.byKey(_k('composer-angle-field')));
    await tester.enterText(find.byKey(_k('composer-angle-field')), 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byKey(_k('composer-angle-error')), findsOneWidget);
    expect(_circuit(tester).logicalGates.single.gate.angle, math.pi / 2);

    // Typed π/4 commits once.
    await tester.enterText(find.byKey(_k('composer-angle-field')), 'pi/4');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_circuit(tester).logicalGates.single.gate.angle, math.pi / 4);

    // A slider drag is many ticks but one commit, hence one undo step.
    await _show(tester, find.byKey(_k('composer-angle-slider')));
    await tester.drag(
        find.byKey(_k('composer-angle-slider')), const Offset(120, 0));
    await tester.pumpAndSettle();
    final dragged = _circuit(tester).logicalGates.single.gate.angle!;
    expect(dragged, greaterThan(math.pi / 4));
    await tester.tap(find.byKey(_k('composer-undo')));
    await tester.pumpAndSettle();
    expect(_circuit(tester).logicalGates.single.gate.angle, math.pi / 4);
    await tester.tap(find.byKey(_k('composer-redo')));
    await tester.pumpAndSettle();
    expect(_circuit(tester).logicalGates.single.gate.angle, dragged);
  });

  testWidgets('presets compute the expected H·Rz·H probabilities',
      (tester) async {
    await _open(tester);
    final h = Gate.fromIdentifier(SelectedGateType.hadamard);
    await _drop(tester, h, 0, 0);
    await _drop(tester, Gate.fromIdentifier(SelectedGateType.rz), 0, 1);
    await _drop(tester, h, 0, 2);
    final rz = _circuit(tester)
        .logicalGates
        .firstWhere((g) => g.type == SelectedGateType.rz);
    final canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    canvas.onGateTap(rz.toPlacedGateRef());
    await tester.pumpAndSettle();
    double p1() {
      final a = _circuit(tester).currentState.stateVector[1];
      return (a.real * a.real + a.imaginary * a.imaginary).toDouble();
    }

    for (final (label, expected) in [('0', 0.0), ('π/2', .5), ('π', 1.0)]) {
      await _show(tester, find.byKey(ValueKey('composer-angle-preset-$label')));
      await tester.tap(find.byKey(ValueKey('composer-angle-preset-$label')));
      await tester.pumpAndSettle();
      expect(p1(), closeTo(expected, 1e-9), reason: 'θ = $label');
    }
  });

  testWidgets('shortcuts undo and redo the session, not text fields',
      (tester) async {
    await _open(tester);
    await _drop(tester, Gate.fromIdentifier(SelectedGateType.x), 0, 0);
    expect(_circuit(tester).logicalGates, hasLength(1));
    await _shortcut(tester, LogicalKeyboardKey.keyZ);
    expect(_circuit(tester).logicalGates, isEmpty);
    await _shortcut(tester, LogicalKeyboardKey.keyZ, shift: true);
    expect(_circuit(tester).logicalGates, hasLength(1));
    await _shortcut(tester, LogicalKeyboardKey.keyZ);
    await _shortcut(tester, LogicalKeyboardKey.keyY);
    expect(_circuit(tester).logicalGates, hasLength(1), reason: 'Ctrl+Y');

    // With the angle field focused, Ctrl+Z belongs to the text field.
    await _drop(tester, Gate.fromIdentifier(SelectedGateType.rx), 0, 1);
    await _show(tester, find.byKey(_k('composer-angle-field')));
    await tester.tap(find.byKey(_k('composer-angle-field')));
    await tester.pumpAndSettle();
    expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>(),
        isNotNull);
    await _shortcut(tester, LogicalKeyboardKey.keyZ);
    expect(_circuit(tester).logicalGates, hasLength(2));
  });

  testWidgets('layout changes never touch the session', (tester) async {
    final storage = _CountingStorage();
    await _open(tester, storage: storage, qubits: 2);
    await _drop(tester, Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
    final circuit = _circuit(tester);
    final selected = circuit.logicalGates.single.id;
    await tester.tap(find.text('Measure'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_k('web-sandbox-run-shots')));
    await tester.pumpAndSettle();
    expect(find.byKey(_k('web-sandbox-shots-result')), findsOneWidget);
    final writes = storage.writes;

    await tester.tap(find.byKey(_k('web-navigation-collapse')));
    await tester.pumpAndSettle();
    expect(find.byKey(_k('web-navigation-rail')), findsOneWidget);
    await tester.tap(find.byKey(_k('composer-toggle-focus')));
    await tester.pumpAndSettle();
    expect(find.byKey(_k('composer-gate-palette-rail')), findsOneWidget);
    await tester.tap(find.byKey(_k('composer-reset-layout')));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1024, 768);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();

    expect(identical(_circuit(tester), circuit), isTrue);
    expect(circuit.logicalGates.single.id, selected);
    expect(find.byKey(_k('web-composer-selected-gate')), findsOneWidget,
        reason: 'selection survives');
    expect(find.byKey(_k('web-sandbox-shots-result')), findsOneWidget,
        reason: 'valid results survive purely visual changes');
    expect(_enabled(tester, 'composer-undo'), isTrue);
    // Only the layout record may have been written, never the circuit.
    expect(
      storage.writes - writes,
      lessThanOrEqualTo(4),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('responsive tiers at real viewport sizes', (tester) async {
    await _open(tester, qubits: 3);
    for (final (size, tier) in [
      (const Size(1920, 1080), 'wide'),
      (const Size(1280, 800), 'wide'),
      (const Size(1024, 768), 'medium'),
      (const Size(800, 700), 'medium'),
      (const Size(600, 800), 'narrow'),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('composer-workspace-$tier')), findsOneWidget,
          reason: '$size');
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('controlled gates list controls and target', (tester) async {
    await _open(tester, qubits: 3);
    final c = _circuit(tester);
    c.insertTripleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.ccnot), 0, 2, 0, 1);
    await tester.pumpAndSettle();
    final canvas = tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
    canvas.onGateTap(c.logicalGates.single.toPlacedGateRef());
    await tester.pumpAndSettle();
    // M3.1: one relationship line names every control and the target once;
    // the detail carries only the position.
    expect(
        tester
            .widget<Text>(find.byKey(_k('web-composer-selection-position')))
            .data,
        'Controls q0, q1 → target q2');
    expect(
        tester
            .widget<Text>(find.byKey(_k('web-composer-selected-gate-detail')))
            .data,
        'Column 1');
    expect(find.textContaining('target q2'), findsOneWidget);
  });

  testWidgets('fixed gates are read-only in the inspector', (tester) async {
    final level = ComposerLevel(
      taskDescription: 'fixed',
      numQubits: 1,
      initialQubitsStateStr: '0',
      initialQubitsState: ComposerLevel.getZeroStateVector(1),
      availableGates: [Gate.fromIdentifier(SelectedGateType.x)],
      solutionFinalVector: const [],
      preInsertedGates: (c) => c.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0,
          isDeletable: false),
    );
    final circuit = QuantumCircuit(currentLevel: level);
    final fixed = circuit.logicalGates.single;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 700,
          height: 400,
          child: GateInspectorPanel(
            summary: const ComposerCircuitSummary(
                qubits: 1, depth: 1, gates: 1, measurements: 0),
            selectedGate: fixed,
            capabilities: ComposerSelectedGateCapabilities.forSelection(
                circuit, fixed.id),
            onTabChanged: (_) {},
            actions: GateInspectorActions(
              onReplace: (_) {},
              onDuplicate: () {},
              onDelete: () {},
              onAngleCommitted: (_, __) {},
              onClassicalBitChanged: (_) {},
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byKey(_k('composer-inspector-read-only')), findsOneWidget);
    expect(find.byKey(_k('web-composer-delete-selected-gate')), findsNothing);
    expect(find.byKey(_k('web-composer-replace-selected-gate')), findsNothing);
    // Fixed gates can still be studied: the educational sections remain.
    expect(find.byKey(_k('composer-inspector-tabs')), findsOneWidget);
    await tester.tap(find.byKey(_k('composer-inspector-tab-mathematics')));
    await tester.pump();
    expect(find.byKey(_k('composer-inspector-tabs')), findsOneWidget);
  });

  test('layout preferences live outside the editing session', () {
    expect(WorkspaceLayoutController.storageKey, 'qq_web_workspace_layout_v1');
  });
}
