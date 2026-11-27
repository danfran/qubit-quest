// v2.6 M3.1: circuit scale (revised D5) in the real web Composer. Every
// interaction uses real pointer gestures through the scaled canvas, and
// positions come from the canvas's own transform (support helper), so the
// displayed geometry and the committed positions are checked against each
// other at 100%, 125% and 150%.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/circuit_layout_metrics.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';

import 'support/composer_canvas_geometry.dart';
import 'support/laboratory_composer_finders.dart';

ValueKey<String> _k(String key) => ValueKey(key);

class _CountingStorage extends InMemoryAppStorage {
  final writes = <String>[];
  @override
  Future<void> writeString(String key, String value) {
    writes.add(key);
    return super.writeString(key, value);
  }
}

Future<void> _open(WidgetTester tester, AppStorage storage,
    {int qubits = 5, Size size = const Size(1440, 900)}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(QubitQuestWebApp(storage: storage));
  await tester.pumpAndSettle();
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

Future<void> _setScale(WidgetTester tester, int percent) async {
  final step = find.byKey(ValueKey('composer-circuit-scale-$percent'));
  await tester.tap(step);
  await tester.pumpAndSettle();
  expect(circuitScaleOf(tester), percent / 100);
}

/// Real pointer drag from [source] to [target], checking the overlay
/// feedback size mid-drag when [feedbackSize] is given.
Future<void> _drag(WidgetTester tester, Finder source, Offset target,
    {double? feedbackSize}) async {
  final gesture = await tester.startGesture(tester.getCenter(source));
  await gesture.moveBy(const Offset(0, 24));
  await tester.pump();
  await gesture.moveTo(target - const Offset(6, 0));
  await tester.pump();
  await gesture.moveTo(target);
  await tester.pump();
  if (feedbackSize != null) {
    final feedback = find.byKey(_k('composer-palette-drag-feedback'));
    expect(tester.getSize(feedback).width, closeTo(feedbackSize, .01));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

Finder _palette(SelectedGateType type) =>
    find.byKey(ValueKey('composer-palette-gate-${type.name}'));

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  for (final percent in [100, 125, 150]) {
    testWidgets('$percent%: drops, moves and hit-tests agree with geometry',
        (tester) async {
      await _open(tester, InMemoryAppStorage());
      await _setScale(tester, percent);
      final scale = percent / 100;
      final c = _circuit(tester);

      // Palette drops land on the slot under the pointer.
      await _drag(tester, _palette(SelectedGateType.hadamard),
          circuitSlotGlobal(tester, 3, 0),
          feedbackSize: paletteFeedbackSize(scale));
      await _drag(tester, _palette(SelectedGateType.rz),
          circuitSlotGlobal(tester, 3, 1));
      await _drag(tester, _palette(SelectedGateType.y),
          circuitSlotGlobal(tester, 1, 0));
      final placed = {
        for (final g in c.logicalGates) g.type: (g.anchor.qubit, g.column)
      };
      expect(placed[SelectedGateType.hadamard], (3, 0));
      expect(placed[SelectedGateType.rz], (3, 1));
      expect(placed[SelectedGateType.y], (1, 0));

      // The painted gate is where geometry says: its global slot centre
      // hit-tests to that gate (selection).
      final rz =
          c.logicalGates.singleWhere((g) => g.type == SelectedGateType.rz);
      await tester.tapAt(circuitSlotGlobal(tester, 3, 1));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(find.byKey(_k('web-composer-selected-gate')))
              .data,
          'Rz rotation gate');

      // Moving a placed gate to another wire.
      final y = c.logicalGates.singleWhere((g) => g.type == SelectedGateType.y);
      final gesture =
          await tester.startGesture(circuitSlotGlobal(tester, 1, 0));
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump();
      await gesture.moveTo(circuitSlotGlobal(tester, 4, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(c.logicalGateById(y.id)!.anchor.qubit, 4);
      expect(c.logicalGateById(rz.id)!.anchor.qubit, 3, reason: 'unchanged');

      // Controlled gates: CCX target and controls hit-test at their wires.
      c.insertTripleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.ccnot), 0, 2, 0, 3);
      await tester.pumpAndSettle();
      final ccx =
          c.logicalGates.singleWhere((g) => g.type == SelectedGateType.ccnot);
      await tester.tapAt(circuitSlotGlobal(tester, 2, ccx.column));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(find.byKey(_k('web-composer-selection-position')))
              .data,
          'Controls q0, q3 → target q2');

      // Measurement drop on the pointer's wire, after the gates.
      await _drag(tester, find.byKey(_k('measurement-palette')),
          circuitSlotGlobal(tester, 4, 3),
          feedbackSize: paletteFeedbackSize(scale));
      expect(c.measurements.single.qubit, 4);

      // Invalid drop: a gate after q4's terminal measurement is rejected.
      final before = c.logicalGates.length;
      await _drag(tester, _palette(SelectedGateType.x),
          circuitSlotGlobal(tester, 4, c.measurements.single.column + 1));
      expect(c.logicalGates.length, before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scrolled canvas at 150% keeps pointer mapping exact',
      (tester) async {
    await _open(tester, InMemoryAppStorage(), size: const Size(1280, 800));
    await _setScale(tester, 150);
    final c = _circuit(tester);
    for (var col = 0; col < 24; col++) {
      c.insertSingleGateWithOutcome(
          Gate.fromIdentifier(
              col.isEven ? SelectedGateType.x : SelectedGateType.z),
          col,
          0);
    }
    c.runSimulation();
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find.descendant(
        of: find.byKey(_k('circuit-horizontal-scroll')),
        matching: find.byType(Scrollable)));
    expect(scrollable.position.maxScrollExtent, greaterThan(200));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    // The last gate is visible at its scaled, scrolled position.
    await tester.tapAt(circuitSlotGlobal(tester, 0, 23));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Text>(find.byKey(_k('web-composer-selected-gate-detail')))
            .data,
        'Column 24');

    // A drop into the scrolled view lands on the wire under the pointer.
    await _drag(tester, _palette(SelectedGateType.hadamard),
        circuitSlotGlobal(tester, 2, 22));
    expect(
        c.logicalGates
            .singleWhere((g) => g.type == SelectedGateType.hadamard)
            .anchor
            .qubit,
        2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scale is presentation only and persists with the layout',
      (tester) async {
    final storage = _CountingStorage();
    await _open(tester, storage, qubits: 2);
    expect(
        circuitScaleOf(tester), WorkspaceLayoutPreferences.defaultCircuitScale);
    final c = _circuit(tester);
    await _drag(tester, _palette(SelectedGateType.hadamard),
        circuitSlotGlobal(tester, 0, 0));
    await tester.tap(find.text('Measure'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_k('web-sandbox-run-shots')));
    await tester.pumpAndSettle();
    final structure = [
      for (final g in c.logicalGates) (g.id, g.type, g.column, g.anchor.qubit)
    ];
    final writes = storage.writes.length;
    final drawing = tester.getSize(find.byKey(_k('web-composer-canvas')));

    for (final percent in [150, 100, 125]) {
      await _setScale(tester, percent);
    }
    await _setScale(tester, 150);
    expect(tester.getSize(find.byKey(_k('web-composer-canvas'))).height,
        greaterThanOrEqualTo(drawing.height - 1));
    expect([
      for (final g in c.logicalGates) (g.id, g.type, g.column, g.anchor.qubit)
    ], structure);
    expect(find.byKey(_k('web-sandbox-shots-result')), findsOneWidget,
        reason: 'valid results survive');
    expect(tester.widget<IconButton>(find.byKey(_k('composer-undo'))).onPressed,
        isNotNull);
    // Only the layout record was written: no circuit autosave.
    expect(storage.writes.sublist(writes).toSet(),
        {WorkspaceLayoutController.storageKey});
    final saved = jsonDecode(
            (await storage.readString(WorkspaceLayoutController.storageKey))!)
        as Map<String, dynamic>;
    expect(saved['circuitScale'], 1.5);

    // Undo still undoes the gate edit, not a scale change.
    await tester.tap(find.byKey(_k('composer-undo')));
    await tester.pumpAndSettle();
    expect(c.logicalGates, isEmpty);
    expect(circuitScaleOf(tester), 1.5);

    // Restored in a fresh app; Reset layout restores the default.
    await tester.pumpWidget(const SizedBox());
    await _open(tester, storage, qubits: 2);
    expect(circuitScaleOf(tester), 1.5);
    await tester.tap(find.byKey(_k('composer-reset-layout')));
    await tester.pumpAndSettle();
    expect(
        circuitScaleOf(tester), WorkspaceLayoutPreferences.defaultCircuitScale);
  });

  test('drag feedback matches the displayed gate size', () {
    for (final scale in WorkspaceLayoutPreferences.circuitScales) {
      expect(paletteFeedbackSize(scale),
          CircuitLayoutMetrics.gateSize * scale + 4);
    }
    expect(paletteFeedbackSize(1), 34, reason: 'unchanged at 100%');
  });
}
