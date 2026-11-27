// Phase W4.3 selected-component contract, ported in v2.6 M3 to the
// persistent Gate Inspector below the circuit (the toolbar it replaced), and
// in M3.1 to the integrated educational inspector: educational inspection
// and replacement no longer open modal dialogs in the desktop Composer.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_workspace_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/gate_replacement_dialog.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/measurement_glyph.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

import 'web_sandbox_measurement_test.dart' show openSandbox, tapVisible;
import 'package:quantumquiz/screens/web_app.dart' show debugClassicSandboxLayout;

ValueKey<String> _k(String key) => ValueKey(key);
final _toolbar = find.byKey(_k('composer-inspector-placed-gate'));
final _tile = find.byKey(_k('web-composer-selection-tile'));
final _empty = find.byKey(_k('web-composer-no-selected-gate'));
final _status = find.byKey(_k('web-storage-status'));
final _inspect = find.byKey(_k('web-composer-inspect-selected-gate'));
final _replace = find.byKey(_k('web-composer-replace-selected-gate'));
final _duplicate = find.byKey(_k('web-composer-duplicate-selected-gate'));
final _delete = find.byKey(_k('web-composer-delete-selected-gate'));
final _angleEditor = find.byKey(_k('composer-angle-field'));
final _inspectorRegion = find.byKey(_k('composer-region-inspector'));
final _inspectorCard = find.byKey(_k('web-composer-inspector-card'));
final _canvasKey = find.byKey(_k('web-composer-canvas'));

QuantumCircuit _circuit(WidgetTester tester) => tester
    .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
    .circuit;

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(_k(key))).data!;

Future<void> _select(WidgetTester tester, int index) async {
  final gate = _circuit(tester).logicalGates[index];
  tester
      .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
      .onGateTap(gate.toPlacedGateRef());
  await tester.pumpAndSettle();
}

Future<void> _clearSelection(WidgetTester tester) async {
  tester
      .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
      .onGateTap(null);
  await tester.pumpAndSettle();
}

Future<void> _place(WidgetTester tester, Gate gate,
    {int column = 0, int qubit = 0}) async {
  final c = _circuit(tester);
  expect(c.insertSingleGateWithOutcome(gate, column, qubit).changed, isTrue);
  c.runSimulation();
  await tester.pumpAndSettle();
}

/// Structural identity of the circuit (IDs, types, positions, angles).
List<Object?> _structure(QuantumCircuit c) => [
      for (final g in c.logicalGates)
        (g.id, g.type, g.column, g.anchor.qubit, g.gate.angle),
      for (final m in c.measurements) (m.id, m.qubit, m.column, m.classicalBit),
    ];

Gate _toolbarGate(WidgetTester tester) => tester
    .widget<QubitQuestGateTile>(
        find.descendant(of: _tile, matching: find.byType(QubitQuestGateTile)))
    .gate;

List<Rect> _actionRects(WidgetTester tester) => [
      for (final f in [_replace, _duplicate, _delete])
        if (f.evaluate().isNotEmpty) tester.getRect(f),
    ];

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  group('identity', () {
    final cases = {
      SelectedGateType.x: 'Pauli-X gate',
      SelectedGateType.hadamard: 'Hadamard gate',
    };
    for (final MapEntry(key: type, value: name) in cases.entries) {
      testWidgets('$name shows its own tile, name and location',
          (tester) async {
        await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
        await _place(tester, Gate.fromIdentifier(type), qubit: 1);
        await _select(tester, 0);
        expect(_toolbar, findsOneWidget);
        expect(_toolbarGate(tester).type, type);
        expect(_text(tester, 'web-composer-selected-gate'), name);
        // M3.1: the qubit is named once (relationship line); the detail
        // carries only the position.
        expect(_text(tester, 'web-composer-selection-position'),
            'Single-qubit gate on q1');
        expect(_text(tester, 'web-composer-selected-gate-detail'), 'Column 1');
        expect(find.byKey(_k('composer-inspector-matrix')), findsOneWidget);
        expect(find.text('Drag to move'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('parameterised Rx shows its angle and the angle editor',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      await _place(
          tester, Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4));
      await _select(tester, 0);
      final gate = _toolbarGate(tester);
      expect(gate.type, SelectedGateType.rx);
      expect(gate.angle, closeTo(math.pi / 4, 1e-12));
      expect(_text(tester, 'web-composer-selected-gate'), 'Rx rotation gate');
      expect(_text(tester, 'web-composer-selected-rotation-angle'),
          'Angle: 0.250π (0.785398 rad)');
      expect(_angleEditor, findsOneWidget);
    });

    testWidgets('controlled gate names control and target', (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      final c = _circuit(tester);
      c.insertDoubleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      c.runSimulation();
      await tester.pumpAndSettle();
      await _select(tester, 0);
      expect(_text(tester, 'web-composer-selected-gate'),
          'Controlled-X (CX / CNOT)');
      expect(_text(tester, 'web-composer-selection-position'),
          'Control q0 → target q1');
      expect(_text(tester, 'web-composer-selected-gate-detail'), 'Column 1');
    });
  });

  group('actions', () {
    testWidgets(
        'educational content is integrated in the inspector, never a dialog',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      await _place(tester, Gate.fromIdentifier(SelectedGateType.hadamard));
      await _select(tester, 0);
      final c = _circuit(tester);
      final before = _structure(c);
      expect(_inspect, findsNothing, reason: 'no modal More details action');

      await tapVisible(
          tester, find.byKey(_k('composer-inspector-tab-mathematics')));
      expect(find.byKey(_k('composer-inspector-mathematics')), findsOneWidget);
      expect(find.byKey(_k('composer-math-matrix')), findsOneWidget);
      expect(find.text('State action'), findsOneWidget);

      await tapVisible(tester, find.byKey(_k('composer-inspector-tab-learn')));
      expect(find.byKey(_k('composer-inspector-learn')), findsOneWidget);
      expect(find.text('Intuition'), findsOneWidget);
      expect(find.byKey(_k('composer-learn-visual')), findsOneWidget);

      expect(find.byType(GateInspectorDialog), findsNothing);
      expect(_structure(c), before, reason: 'tabs are presentation only');
      expect(c.logicalGates.single.type, SelectedGateType.hadamard);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Replace, Duplicate and Delete keep their behaviour',
        (tester) async {
      final storage = InMemoryAppStorage();
      await openSandbox(tester, storage, qubits: 2);
      await _place(tester, Gate.fromIdentifier(SelectedGateType.x));
      await _select(tester, 0);
      final id = _circuit(tester).logicalGates.single.id;

      // Replacement is an anchored menu of valid types (M3.1), not a dialog;
      // dismissing it cancels without an edit.
      final before = _structure(_circuit(tester));
      await tapVisible(tester, _replace);
      expect(find.byType(GateReplacementDialog), findsNothing);
      expect(find.byKey(_k('composer-replace-with-hadamard')), findsOneWidget);
      expect(find.byKey(_k('composer-replace-with-x')), findsNothing,
          reason: 'the current type is not offered');
      // Clicking outside dismisses the menu without an edit.
      await tester.tap(find.byKey(_k('composer-inspector-heading')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('composer-replace-with-hadamard')), findsNothing);
      expect(_structure(_circuit(tester)), before, reason: 'dismiss cancels');

      await tapVisible(tester, _replace);
      await tester.tap(find.byKey(_k('composer-replace-with-hadamard')));
      await tester.pumpAndSettle();
      final replaced = _circuit(tester).logicalGates.single;
      expect((replaced.id, replaced.type), (id, SelectedGateType.hadamard));
      expect(_toolbarGate(tester).type, SelectedGateType.hadamard);
      expect(_text(tester, 'web-composer-selected-gate'), 'Hadamard gate');

      await tapVisible(tester, _duplicate);
      expect(_circuit(tester).logicalGates, hasLength(2));

      await _select(tester, 0);
      await tapVisible(tester, _delete);
      expect(_circuit(tester).logicalGates, hasLength(1));
      expect(_empty, findsOneWidget);
      expect(_toolbar, findsNothing);

      // Edits still persist through the existing save queue.
      final saved = (await SandboxWorkspacePersistence(storage).load(2))!;
      expect(saved.program.operations, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Delete is last and visually distinct', (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      await _place(tester, Gate.fromIdentifier(SelectedGateType.x));
      await _select(tester, 0);
      final rects = _actionRects(tester);
      expect(rects.last, tester.getRect(_delete));
      Color? fg(Finder f) => tester
          .widget<OutlinedButton>(
              find.descendant(of: f, matching: find.byType(OutlinedButton)))
          .style!
          .foregroundColor
          ?.resolve({});
      expect(fg(_delete), QubitQuestColors.error);
      expect(fg(_duplicate), isNot(QubitQuestColors.error));
    });
  });

  group('measurement', () {
    testWidgets('meter tile, route, classical-bit editing, Delete only',
        (tester) async {
      final storage = InMemoryAppStorage();
      await openSandbox(tester, storage, qubits: 2);
      final c = _circuit(tester);
      c.insertMeasurementWithOutcome(qubit: 1, column: 0);
      await tester.pumpAndSettle();
      final m = c.measurements.single;
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .onMeasurementSelected!(m.id);
      await tester.pumpAndSettle();

      expect(
          find.descendant(of: _tile, matching: find.byType(MeasurementGlyph)),
          findsOneWidget);
      expect(
          _text(tester, 'web-composer-selected-measurement'), 'Measurement Z');
      expect(_text(tester, 'web-composer-selection-position'),
          'q1 → c1 · column 1');
      expect(find.byKey(_k('web-composer-classical-bit-help')), findsOneWidget);
      expect(_delete, findsOneWidget);
      expect(_inspect, findsNothing);
      expect(find.byKey(_k('composer-inspector-tabs')), findsNothing,
          reason: 'a measurement has no gate educational sections');
      expect(_replace, findsNothing);
      expect(_duplicate, findsNothing);

      await tapVisible(
          tester, find.byKey(_k('web-composer-measurement-classical-bit')));
      await tester.tap(find.text('c0').last);
      await tester.pumpAndSettle();
      final after = c.measurements.single;
      expect((after.id, after.classicalBit), (m.id, 0));
      expect(_text(tester, 'web-composer-selection-position'),
          'q1 → c0 · column 1');
      final saved = (await SandboxWorkspacePersistence(storage).load(2))!;
      expect((saved.program.operations.single as dynamic).classicalBit, 0);
    });
  });

  group('empty and status', () {
    testWidgets('empty selection is a compact hint with circuit facts',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      expect(_empty, findsOneWidget);
      expect(_text(tester, 'web-composer-selection-empty'),
          'Select a gate to inspect it, or drag a gate onto the circuit.');
      expect(
          find.byKey(_k('composer-inspector-circuit-summary')), findsOneWidget);
      expect(_toolbar, findsNothing);
      expect(tester.getSize(_inspectorRegion).height, lessThan(130),
          reason: 'the idle inspector does not reserve its full height');
    });

    testWidgets('the status line never describes a past selection',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      await _place(
          tester, Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2));
      await _place(tester, Gate.fromIdentifier(SelectedGateType.x), qubit: 1);
      await _select(tester, 0);
      await _select(tester, 1);
      expect(_text(tester, 'web-composer-selected-gate'), 'Pauli-X gate');
      final status = tester.widget<Text>(_status).data!;
      expect(status, isNot(contains('Selected')));
      expect(status, isNot(contains('Rx')));

      // Clicking a palette gate previews the type; it never edits or
      // pretends to be a selection.
      await tapVisible(tester, find.byKey(_k('composer-palette-gate-rx')));
      expect(find.byKey(_k('composer-inspector-preview')), findsOneWidget);
      expect(_toolbar, findsNothing);
      expect(tester.widget<Text>(_status).data, status);
      expect(_circuit(tester).logicalGates, hasLength(2));

      await _clearSelection(tester);
      expect(find.byKey(_k('composer-inspector-preview')), findsOneWidget,
          reason: 'clearing a selection keeps the preview');
    });
  });

  group('layout', () {
    for (final (name, size) in [
      ('desktop', const Size(1440, 1000)),
      ('narrow', const Size(560, 1000)),
      ('phone', const Size(380, 900)),
    ]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('$name ×$scale: actions fit inside the inspector',
            (tester) async {
          await openSandbox(tester, InMemoryAppStorage(),
              qubits: 1, size: size, scale: scale);
          await _place(tester,
              Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 3));
          await _select(tester, 0);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(_delete);
          await tester.pumpAndSettle();
          final region = tester.getRect(_inspectorRegion);
          final rects = _actionRects(tester);
          // Replace, Duplicate, Delete (More details became inline tabs).
          expect(rects, hasLength(3));
          for (final r in rects) {
            expect(r.left, greaterThanOrEqualTo(region.left - .5));
            expect(r.right, lessThanOrEqualTo(region.right + .5));
            expect(r.height, greaterThanOrEqualTo(40));
          }
          expect(rects.last, tester.getRect(_delete),
              reason: 'Delete stays last');
          // Whether the four actions share one row depends on real font
          // metrics; it is checked in the browser screenshots, not with the
          // wide test font.
        });
      }
    }

    testWidgets('selection never moves the circuit or the results',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      await _place(tester, Gate.fromIdentifier(SelectedGateType.x));
      final canvasTop = tester.getTopLeft(_canvasKey);
      final results = tester.getRect(_inspectorCard);
      await _select(tester, 0);
      expect(tester.getTopLeft(_canvasKey), canvasTop);
      expect(tester.getRect(_inspectorCard), results);
      expect(find.descendant(of: _inspectorRegion, matching: _toolbar),
          findsOneWidget);
      expect(find.descendant(of: _inspectorCard, matching: _toolbar),
          findsNothing);
      await _clearSelection(tester);
      expect(tester.getTopLeft(_canvasKey), canvasTop);
      expect(tester.getRect(_inspectorCard), results);
    });

    testWidgets('measurement results survive selection changes',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      await _place(tester, Gate.fromIdentifier(SelectedGateType.hadamard));
      await tapVisible(tester, find.byKey(_k('web-sandbox-run-shots')));
      final result = find.byKey(_k('web-sandbox-shots-result'));
      expect(result, findsOneWidget);
      await _select(tester, 0);
      expect(result, findsOneWidget);
      await _clearSelection(tester);
      expect(result, findsOneWidget);
    });
  });
}
