// Phase W2: Web Sandbox measurement drag/drop, selection, editing and status.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_workspace_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/sandbox_load_recovery.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';

import 'web_sandbox_measurement_test.dart' show openSandbox, tapVisible;

final _surface = find.byKey(const ValueKey('circuit-interaction-surface'));
final _measurementTile = find.byKey(const ValueKey('measurement-palette'));
final _preview = find.byKey(const ValueKey('measurement-drop-preview'));
final _rejectedPreview =
    find.byKey(const ValueKey('measurement-drop-preview-rejected'));
final _selectedMeasurement =
    find.byKey(const ValueKey('web-composer-selected-measurement'));
final _noSelection =
    find.byKey(const ValueKey('web-composer-no-selected-gate'));
final _delete = find.byKey(const ValueKey('web-composer-delete-selected-gate'));
final _bitSelector =
    find.byKey(const ValueKey('web-composer-measurement-classical-bit'));
final _status = find.byKey(const ValueKey('web-storage-status'));

Offset _slot(WidgetTester tester, int qubit, int column) =>
    tester.getTopLeft(_surface) + Offset(40 + column * 40, 20 + qubit * 40);

Finder _paletteGate(SelectedGateType type) => find.byWidgetPredicate((w) =>
    w is Draggable<CircuitDragData> &&
    w.data != null &&
    !w.data!.isMeasurement &&
    !w.data!.isPlaced &&
    w.data!.gate.type == type);

QuantumCircuit _circuit(WidgetTester tester) => tester
    .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
    .circuit;

String _statusText(WidgetTester tester) => tester.widget<Text>(_status).data!;

/// Starts a palette drag grabbed near the tile's top-left corner, so the drag
/// feedback offset (which the canvas resolves) lands on the target slot.
Future<TestGesture> _dragTo(
    WidgetTester tester, Finder tile, int qubit, int column) async {
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  final gesture =
      await tester.startGesture(tester.getTopLeft(tile) + const Offset(2, 2));
  await gesture.moveBy(const Offset(0, 20));
  await tester.pump();
  await gesture.moveTo(_slot(tester, qubit, column) - const Offset(2, 2));
  await tester.pump();
  await gesture.moveTo(_slot(tester, qubit, column));
  await tester.pump();
  return gesture;
}

Future<void> _drop(
    WidgetTester tester, Finder tile, int qubit, int column) async {
  final gesture = await _dragTo(tester, tile, qubit, column);
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('model and drag data', () {
    QuantumCircuit circuit() {
      final c = QuantumCircuit(currentLevel: createSandboxComposerLevel(3));
      c.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      return c;
    }

    test('measurement drag data is typed, not a fake gate', () {
      const data = CircuitDragData.measurement();
      expect(data.isMeasurement, isTrue);
      expect(data.isPlaced, isFalse);
      expect(() => data.gate, throwsStateError);
    });

    test('measurement insertion preview matches placement rules', () {
      final c = circuit();
      // W3: measurements occupy one qubit slot, so q1 may share column 0.
      expect(c.previewMeasurementInsertion(qubit: 1, column: 0).outcome.changed,
          isTrue);
      expect(c.previewMeasurementInsertion(qubit: 3, column: 0).outcome.changed,
          isFalse);
      // Measuring q0 before its H would leave H after a terminal measurement.
      expect(c.previewMeasurementInsertion(qubit: 0, column: 0).outcome.detail,
          QuantumCircuit.terminalMeasurementReason);
      expect(c.hasMeasurements, isFalse, reason: 'previews never mutate');
      expect(() => c.addMeasurement(column: 2, qubit: 0, classicalBit: 1024),
          throwsA(isA<InvalidCircuitProgram>()));
      c.dispose();
    });

    test('classical-bit update preserves ID, column, order and persists', () {
      final c = circuit();
      final first = c.addMeasurement(column: 1, qubit: 1, classicalBit: 1);
      final second = c.addMeasurement(column: 2, qubit: 2, classicalBit: 2);
      var notified = 0;
      c.addListener(() => notified++);
      expect(c.updateMeasurementClassicalBit(first.id, 4), isTrue);
      expect(c.updateMeasurementClassicalBit(first.id, 4), isFalse);
      expect(notified, 1);
      expect(c.measurements.map((m) => (m.id, m.column, m.classicalBit)),
          [(first.id, 1, 4), (second.id, 2, 2)]);
      expect(c.classicalBitCount, 5);
      expect(() => c.updateMeasurementClassicalBit(first.id, -1),
          throwsA(isA<InvalidCircuitProgram>()));
      final restored = SandboxProgramSnapshot.decode(
              SandboxProgramSnapshot.capture(c).encode())
          .restoreCircuit();
      expect(restored.measurementById(first.id)!.classicalBit, 4);
      restored.dispose();
      c.dispose();
    });
  });

  testWidgets('M is a draggable tile with preview and default destination',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 3);
    expect(_measurementTile, findsOneWidget);
    expect(tester.widget(_measurementTile), isA<Draggable<CircuitDragData>>());
    expect(find.widgetWithText(OutlinedButton, 'M'), findsNothing,
        reason: 'legacy tap-to-place button removed from Web');
    final palette = tester.getSize(_paletteGate(SelectedGateType.hadamard));
    expect(tester.getSize(_measurementTile), palette);

    final gesture = await _dragTo(tester, _measurementTile, 2, 0);
    expect(_preview, findsOneWidget);
    expect(_rejectedPreview, findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();

    final m = _circuit(tester).measurements.single;
    expect((m.qubit, m.column, m.classicalBit), (2, 0, 2));
    expect(find.text('Measurement Z — q2 → c2'), findsOneWidget);
    expect(_noSelection, findsNothing);
    expect(_statusText(tester), contains('Measurement added: q2 → c2'));
    expect(_statusText(tester), contains('results will appear'));
    expect(find.byTooltip('Remove measurement'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drops before a gate on the same qubit are visibly rejected',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
    await _drop(tester, _paletteGate(SelectedGateType.hadamard), 0, 0);
    final circuit = _circuit(tester);
    final gateId = circuit.logicalGates.single.id;

    final gesture = await _dragTo(tester, _measurementTile, 0, 0);
    expect(_rejectedPreview, findsOneWidget);
    expect(_preview, findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(circuit.hasMeasurements, isFalse);
    expect(circuit.logicalGates.single.id, gateId);
    expect(find.byKey(const ValueKey('web-composer-drop-rejected')),
        findsOneWidget);
    expect(_statusText(tester),
        'Not changed: ${QuantumCircuit.terminalMeasurementReason}');
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection and deletion go through the Web host', (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
    await _drop(tester, _paletteGate(SelectedGateType.hadamard), 0, 0);
    await _drop(tester, _measurementTile, 1, 1);
    final circuit = _circuit(tester);
    final id = circuit.measurements.single.id;
    // Compaction settles q1's measurement in column 0, sharing it with H.
    expect(circuit.measurements.single.column, 0);
    // Inspector explains the unexecuted measured circuit.
    expect(find.byType(UnexecutedMeasuredCircuit), findsOneWidget);

    await tester.tapAt(_slot(tester, 0, 4));
    await tester.pumpAndSettle();
    expect(_noSelection, findsOneWidget);

    await tester.tapAt(_slot(tester, 1, 0));
    await tester.pumpAndSettle();
    expect(_selectedMeasurement, findsOneWidget);
    expect(find.text('Measurement Z — q1 → c1'), findsOneWidget);
    expect(_noSelection, findsNothing);
    expect(find.text('NO GATE SELECTED'), findsNothing);
    expect(find.byTooltip('Remove measurement'), findsNothing);
    expect(circuit.measurementById(id), isNotNull);

    await tapVisible(tester, _delete);
    expect(circuit.hasMeasurements, isFalse);
    expect(circuit.logicalGates, hasLength(1));
    expect(_noSelection, findsOneWidget);
    expect(_statusText(tester), contains('removed'));
    // Inspector returns to the live state view once the circuit is unitary.
    expect(find.byKey(const ValueKey('web-composer-current-state')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('classical destination edit keeps ID/column and persists',
      (tester) async {
    final storage = InMemoryAppStorage();
    await openSandbox(tester, storage, qubits: 3);
    await _drop(tester, _measurementTile, 2, 0);
    final circuit = _circuit(tester);
    final before = circuit.measurements.single;
    expect(find.byKey(const ValueKey('web-composer-classical-bit-help')),
        findsOneWidget);
    expect(
        find.text('The measurement outcome (0 or 1) will be stored in this '
            'classical bit.'),
        findsOneWidget);

    await tapVisible(tester, _bitSelector);
    await tester.tap(find.text('c0').last);
    await tester.pumpAndSettle();

    final after = circuit.measurements.single;
    expect((after.id, after.column, after.qubit, after.classicalBit),
        (before.id, before.column, 2, 0));
    expect(find.text('Measurement Z — q2 → c0'), findsOneWidget);
    expect(_statusText(tester), contains('now stores its outcome in c0'));

    final saved = (await SandboxWorkspacePersistence(storage).load(3))!;
    final op = saved.program.operations.single as dynamic;
    expect((op.id, op.column, op.classicalBit), (before.id, 0, 0));

    // Restoration in a fresh app session keeps the edited measurement.
    await tester.pumpWidget(const SizedBox());
    await openSandbox(tester, storage, qubits: 3);
    final restored = _circuit(tester).measurements.single;
    expect(
        (restored.id, restored.column, restored.qubit, restored.classicalBit),
        (before.id, 0, 2, 0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('gate drag/drop still works and status counts measurements',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
    await _drop(tester, _paletteGate(SelectedGateType.hadamard), 0, 0);
    final circuit = _circuit(tester);
    expect(circuit.logicalGates.single.type, SelectedGateType.hadamard);
    expect(_statusText(tester), '1 operation(s) in circuit.');

    await _drop(tester, _measurementTile, 0, 1);
    await _drop(tester, _paletteGate(SelectedGateType.x), 1, 2);
    expect(circuit.logicalGates, hasLength(2));
    expect(_statusText(tester), '3 operation(s) in circuit (1 measurement).');

    // A gate after q0's terminal measurement is rejected with a reason.
    await _drop(tester, _paletteGate(SelectedGateType.x), 0, 2);
    expect(circuit.logicalGates, hasLength(2));
    expect(_statusText(tester),
        'Not changed: ${QuantumCircuit.terminalMeasurementReason}');

    // Gate editing stays available in measured circuits.
    await tester.tapAt(_slot(tester, 0, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('web-composer-selected-gate')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-composer-move-selected-gate')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-composer-duplicate-selected-gate')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
