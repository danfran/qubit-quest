// Phase W4.3: one selected-component toolbar for gates and measurements.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_workspace_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/gate_replacement_dialog.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/measurement_glyph.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

import 'web_sandbox_measurement_test.dart' show openSandbox, tapVisible;

ValueKey<String> _k(String key) => ValueKey(key);
final _toolbar = find.byKey(_k('web-composer-selection-toolbar'));
final _tile = find.byKey(_k('web-composer-selection-tile'));
final _empty = find.byKey(_k('web-composer-no-selected-gate'));
final _status = find.byKey(_k('web-storage-status'));
final _inspect = find.byKey(_k('web-composer-inspect-selected-gate'));
final _replace = find.byKey(_k('web-composer-replace-selected-gate'));
final _duplicate = find.byKey(_k('web-composer-duplicate-selected-gate'));
final _delete = find.byKey(_k('web-composer-delete-selected-gate'));
final _editAngle = find.byKey(_k('web-composer-edit-selected-angle'));
final _circuitCard = find.byKey(_k('quantum-workspace-surface'));
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

Gate _toolbarGate(WidgetTester tester) => tester
    .widget<QubitQuestGateTile>(
        find.descendant(of: _tile, matching: find.byType(QubitQuestGateTile)))
    .gate;

List<Rect> _actionRects(WidgetTester tester) => [
      for (final f in [_inspect, _replace, _editAngle, _duplicate, _delete])
        if (f.evaluate().isNotEmpty) tester.getRect(f),
    ];

void main() {
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
        expect(find.text('SELECTED COMPONENT'), findsOneWidget);
        expect(_toolbarGate(tester).type, type);
        expect(_text(tester, 'web-composer-selected-gate'), name);
        expect(
            _text(tester, 'web-composer-selection-position'), 'q1 · column 1');
        expect(_text(tester, 'web-composer-selected-gate-detail'),
            'Single-qubit gate on q1');
        expect(find.byKey(_k('web-composer-move-hint')), findsOneWidget);
        expect(find.text('Drag to move'), findsNothing);
        expect(find.byType(Chip), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('parameterised Rx shows its angle and Edit angle',
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
      expect(_editAngle, findsOneWidget);
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
      expect(_text(tester, 'web-composer-selected-gate-detail'),
          'Control q0 → target q1');
      expect(_text(tester, 'web-composer-selection-position'),
          'q0, q1 · column 1');
    });
  });

  group('actions', () {
    testWidgets('Inspect opens the existing educational dialog',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      await _place(tester, Gate.fromIdentifier(SelectedGateType.hadamard));
      await _select(tester, 0);
      await tapVisible(tester, _inspect);
      expect(find.byType(GateInspectorDialog), findsOneWidget);
      expect(find.text('Intuition'), findsOneWidget);
      expect(find.text('Mathematical definition'), findsOneWidget);
    });

    testWidgets('Replace, Duplicate and Delete keep their behaviour',
        (tester) async {
      final storage = InMemoryAppStorage();
      await openSandbox(tester, storage, qubits: 2);
      await _place(tester, Gate.fromIdentifier(SelectedGateType.x));
      await _select(tester, 0);
      final id = _circuit(tester).logicalGates.single.id;

      await tapVisible(tester, _replace);
      expect(find.byType(GateReplacementDialog), findsOneWidget);
      await tester.tap(find.byKey(_k('replacement-gate-hadamard')));
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
      final deleteStyle =
          tester.widget<OutlinedButton>(_delete).style!.foregroundColor;
      final inspectStyle =
          tester.widget<OutlinedButton>(_inspect).style!.foregroundColor;
      expect(deleteStyle?.resolve({}), isNotNull);
      expect(inspectStyle?.resolve({}), isNull,
          reason: 'regular actions use the theme colour');
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
    testWidgets('empty selection is one compact line', (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      expect(_empty, findsOneWidget);
      expect(_text(tester, 'web-composer-no-selected-gate'),
          'Select a gate or measurement to inspect or edit it.');
      expect(_toolbar, findsNothing);
      expect(
          tester.getSize(find.byKey(_k('web-composer-selection-empty'))).height,
          lessThan(30));
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

      // Tapping a palette gate gives placement guidance, not a selection.
      final paletteRx = find.byWidgetPredicate((w) =>
          w is QubitQuestGateTile &&
          w.onPressed != null &&
          w.gate.type == SelectedGateType.rx);
      await tapVisible(tester, paletteRx.first);
      expect(tester.widget<Text>(_status).data, startsWith('Drag Rx'));
      expect(_text(tester, 'web-composer-selected-gate'), 'Pauli-X gate');

      await _clearSelection(tester);
      expect(_empty, findsOneWidget);
    });
  });

  group('layout', () {
    for (final (name, size) in [
      ('desktop', const Size(1440, 1000)),
      ('narrow', const Size(560, 1000)),
      ('phone', const Size(380, 900)),
    ]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('$name ×$scale: actions fit, no lone Delete',
            (tester) async {
          await openSandbox(tester, InMemoryAppStorage(),
              qubits: 1, size: size, scale: scale);
          // Opening at 380 px ×1.5 overflows outside this toolbar (before
          // any selection exists); only the toolbar is judged here.
          tester.takeException();
          await _place(tester,
              Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 3));
          await _select(tester, 0);
          expect(tester.takeException(), isNull);
          final card = tester.getRect(_circuitCard);
          final rects = _actionRects(tester);
          expect(rects, hasLength(5));
          for (final r in rects) {
            expect(r.left, greaterThanOrEqualTo(card.left - .5));
            expect(r.right, lessThanOrEqualTo(card.right + .5));
            expect(r.height, greaterThanOrEqualTo(40));
          }
          final rows = <double, int>{};
          for (final r in rects) {
            rows.update(r.top, (n) => n + 1, ifAbsent: () => 1);
          }
          expect(rows[rects.last.top], greaterThan(1),
              reason: 'Delete never sits alone on its row');
          if (name == 'desktop' && scale == 1) {
            expect(rows, hasLength(1), reason: 'one row at desktop width');
            expect(tester.getRect(_tile).top, lessThan(rects.first.bottom),
                reason: 'tile, identity and actions share the row');
          }
        });
      }
    }

    testWidgets('selection changes leave canvas and Inspector in place',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      await _place(tester, Gate.fromIdentifier(SelectedGateType.x));
      final canvas = tester.getRect(_canvasKey);
      final inspector = tester.getRect(_inspectorCard);
      await _select(tester, 0);
      expect(tester.getRect(_canvasKey), canvas);
      expect(tester.getRect(_inspectorCard), inspector);
      expect(find.descendant(of: _circuitCard, matching: _toolbar),
          findsOneWidget);
      expect(find.descendant(of: _inspectorCard, matching: _toolbar),
          findsNothing);
      await _clearSelection(tester);
      expect(tester.getRect(_canvasKey), canvas);
      expect(tester.getRect(_inspectorCard), inspector);
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
