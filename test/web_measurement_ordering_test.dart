// Phase W3: measurement ordering and circuit editing semantics.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/composer_canvas_geometry.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/circuit_executor.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/sandbox_workspace_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';

import 'web_sandbox_measurement_test.dart' show openSandbox;

final _h = Gate.fromIdentifier(SelectedGateType.hadamard);
final _x = Gate.fromIdentifier(SelectedGateType.x);
final _cnot = Gate.fromIdentifier(SelectedGateType.cnot);
const _terminal = QuantumCircuit.terminalMeasurementReason;

QuantumCircuit _make(int n) =>
    QuantumCircuit(currentLevel: createSandboxComposerLevel(n));

String _encode(QuantumCircuit c) => SandboxProgramSnapshot.capture(c).encode();

/// H(q0), measured q0 → c0, then X(q0): a post-measurement operation that
/// earlier builds could save (the old global barrier allowed it).
const _legacyJson = '{"schemaVersion":2,"qubitCount":2,"classicalBitCount":1,'
    '"initialStateLabel":"|00⟩","initialState":[[1,0],[0,0],[0,0],[0,0]],'
    '"operations":['
    '{"id":1,"column":0,"kind":"unitary","gateType":"hadamard","target":0,'
    '"isDeletable":true},'
    '{"id":2,"column":1,"kind":"measureZ","qubit":0,"classicalBit":0},'
    '{"id":3,"column":2,"kind":"unitary","gateType":"x","target":0,'
    '"isDeletable":true}]}';

void main() {
  group('model ordering rules', () {
    test('gate inserted before a measurement shifts it, keeping ID and bit',
        () {
      final c = _make(2);
      addTearDown(c.dispose);
      final h = c.insertSingleGateWithOutcome(_h, 0, 0).affectedGateId!;
      final m = c.insertMeasurementWithOutcome(qubit: 0, column: 1);
      expect(m.changed, isTrue);
      final before = c.measurements.single;
      expect((before.column, before.classicalBit), (1, 0));

      final x = c.insertSingleGateWithOutcome(_x, 0, 0);
      expect(x.changed, isTrue);
      expect(c.logicalGateById(x.affectedGateId!)!.column, 0);
      expect(c.logicalGateById(h)!.column, 1);
      final after = c.measurements.single;
      expect((after.id, after.column, after.classicalBit),
          (before.id, 2, before.classicalBit));
      expect(CircuitProgram.fromCircuit(c).operations.map((o) => o.id),
          [x.affectedGateId, h, before.id]);
    });

    test('compatible operations on different qubits share a column', () {
      final c = _make(2);
      addTearDown(c.dispose);
      c.insertSingleGateWithOutcome(_x, 0, 0);
      c.insertMeasurementWithOutcome(qubit: 1, column: 3);
      final program = CircuitProgram.fromCircuit(c);
      expect(program.operations.map((o) => o.column), [0, 0]);
      // Same-column operations commute; execution is unchanged by ordering.
      final shot = CircuitExecutor(nextDouble: () => .5).runShot(program);
      expect(shot.classicalState.bits, [null, 0]);
    });

    test('shifting preserves multi-qubit relationships and order', () {
      final c = _make(2);
      addTearDown(c.dispose);
      final cx = c.insertDoubleGateWithOutcome(_cnot, 0, 1, 0).affectedGateId!;
      c.insertMeasurementWithOutcome(qubit: 1, column: 1);
      final h = c.insertSingleGateWithOutcome(_h, 0, 0).affectedGateId!;
      final cnot = c.logicalGateById(cx)!;
      expect((cnot.column, cnot.controlQubit, cnot.targetQubit), (1, 0, 1));
      expect(c.logicalGateById(h)!.column, 0);
      expect(c.measurements.single.column, 2);
    });

    test('terminal measurement rejects later gates, including multi-qubit', () {
      final c = _make(2);
      addTearDown(c.dispose);
      c.insertSingleGateWithOutcome(_h, 0, 0);
      c.insertMeasurementWithOutcome(qubit: 0, column: 1);
      final encoded = _encode(c);
      var notifications = 0;
      c.addListener(() => notifications++);

      final rejected = [
        c.insertSingleGateWithOutcome(_x, 2, 0),
        c.insertDoubleGateWithOutcome(_cnot, 2, 1, 0), // control on q0
        c.insertDoubleGateWithOutcome(_cnot, 2, 0, 1), // target on q0
        c.insertMeasurementWithOutcome(qubit: 0, column: 2), // re-measure
      ];
      for (final outcome in rejected) {
        expect(outcome.status, CircuitEditStatus.invalid);
        expect(outcome.detail, _terminal);
      }
      expect(_encode(c), encoded, reason: 'rejected edits never mutate');
      expect(notifications, 0, reason: 'rejected edits never notify');

      // A multi-qubit gate before the measurement is fine and shifts it.
      expect(c.insertDoubleGateWithOutcome(_cnot, 0, 1, 0).changed, isTrue);
      expect(c.measurements.single.column, 2);
      // Duplicate classical destinations are rejected.
      final dup =
          c.insertMeasurementWithOutcome(qubit: 1, column: 5, classicalBit: 0);
      expect(dup.detail, QuantumCircuit.classicalOrderReason);
    });

    test('a link crossing a measured wire is not an operand', () {
      final c = _make(3);
      addTearDown(c.dispose);
      c.insertMeasurementWithOutcome(qubit: 1, column: 0);
      // CNOT q0 → q2 passes q1 visually but does not act on it.
      expect(c.insertDoubleGateWithOutcome(_cnot, 1, 2, 0).changed, isTrue);
    });

    test('measurements move horizontally within ordering rules', () {
      final c = _make(3);
      addTearDown(c.dispose);
      final cx = c.insertDoubleGateWithOutcome(_cnot, 0, 2, 0).affectedGateId!;
      // q1 holds only the CNOT link, so its measurement can sit either side.
      final m = c
          .insertMeasurementWithOutcome(qubit: 1, column: 1, classicalBit: 4)
          .affectedGateId!;
      expect(c.measurementById(m)!.column, 1);
      final moved = c.moveMeasurementWithOutcome(m, 0);
      expect(moved.changed, isTrue);
      final after = c.measurementById(m)!;
      expect((after.column, after.qubit, after.classicalBit), (0, 1, 4));
      expect(c.logicalGateById(cx)!.column, 1, reason: 'CNOT shifted right');

      // q2's measurement cannot move before the CNOT targeting q2.
      final m2 = c.insertMeasurementWithOutcome(qubit: 2, column: 9);
      final encoded = _encode(c);
      final plan = c.planMeasurementMove(m2.affectedGateId!, 0);
      expect(plan.changed, isFalse);
      expect(plan.reason, _terminal);
      expect(
          c.moveMeasurementWithOutcome(m2.affectedGateId!, 0).changed, isFalse);
      expect(_encode(c), encoded);
    });

    test('shared-column programs persist without schema changes', () {
      final c = _make(2);
      addTearDown(c.dispose);
      c.insertSingleGateWithOutcome(_h, 0, 0);
      c.insertMeasurementWithOutcome(qubit: 1, column: 0, classicalBit: 3);
      final snapshot = SandboxProgramSnapshot.capture(c);
      final decoded = SandboxProgramSnapshot.decode(snapshot.encode());
      final restored = decoded.restoreCircuit();
      addTearDown(restored.dispose);
      expect(_encode(restored), snapshot.encode());
      final m = restored.measurements.single;
      expect((m.column, m.qubit, m.classicalBit), (0, 1, 3));
      expect(restored.classicalBitCount, 4);
    });

    test('legacy post-measurement circuits restore unchanged; edits limited',
        () {
      final legacy = SandboxProgramSnapshot.decode(_legacyJson);
      final c = legacy.restoreCircuit();
      addTearDown(c.dispose);
      expect(c.hasPostMeasurementOperations, isTrue);
      expect(_encode(c), legacy.encode(), reason: 'not silently rewritten');

      // Unrelated edits are allowed and keep the legacy operation.
      expect(c.insertSingleGateWithOutcome(_x, 0, 1).changed, isTrue);
      expect(c.logicalGates.map((g) => g.id.value), containsAll([1, 3]));
      // New post-measurement operations are not.
      expect(c.insertSingleGateWithOutcome(_x, 5, 0).detail, _terminal);
      // Removing the legacy operation clears the condition.
      expect(c.removeLogicalGateByIdWithOutcome(GateId(3)).changed, isTrue);
      expect(c.hasPostMeasurementOperations, isFalse);
    });
  });

  group('Web editing', () {
    final measureTile = find.byKey(const ValueKey('measurement-palette'));
    final status = find.byKey(const ValueKey('web-storage-status'));

    Offset slot(WidgetTester tester, int qubit, int column) =>
        circuitSlotGlobal(tester, qubit, column);
    QuantumCircuit circuitOf(WidgetTester tester) => tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
        .circuit;
    String statusOf(WidgetTester tester) => tester.widget<Text>(status).data!;
    Finder paletteGate(SelectedGateType type) => find.byWidgetPredicate((w) =>
        w is Draggable<CircuitDragData> &&
        w.data != null &&
        !w.data!.isMeasurement &&
        !w.data!.isPlaced &&
        w.data!.gate.type == type);

    Future<TestGesture> hover(
        WidgetTester tester, Finder tile, int qubit, int column) async {
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      final gesture = await tester
          .startGesture(tester.getTopLeft(tile) + const Offset(2, 2));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.moveTo(slot(tester, qubit, column) - const Offset(2, 2));
      await tester.pump();
      await gesture.moveTo(slot(tester, qubit, column));
      await tester.pump();
      return gesture;
    }

    Future<void> drop(
        WidgetTester tester, Finder tile, int qubit, int column) async {
      final gesture = await hover(tester, tile, qubit, column);
      await gesture.up();
      await tester.pumpAndSettle();
    }

    /// Drags a placed measurement by its centre (pointer-anchored).
    Future<TestGesture> grabMeasurement(
        WidgetTester tester, int qubit, int fromColumn, int toColumn) async {
      final gesture =
          await tester.startGesture(slot(tester, qubit, fromColumn));
      await gesture.moveBy(const Offset(12, 0));
      await tester.pump();
      await gesture.moveTo(slot(tester, qubit, toColumn));
      await tester.pump();
      return gesture;
    }

    testWidgets('gate before a measurement inserts and previews the shift',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      await drop(tester, paletteGate(SelectedGateType.hadamard), 0, 0);
      await drop(tester, measureTile, 0, 1);
      final c = circuitOf(tester);
      final m = c.measurements.single;
      expect(m.column, 1);

      final gesture =
          await hover(tester, paletteGate(SelectedGateType.x), 0, 0);
      // Exact preview: the measurement is drawn where the commit will put it.
      expect(
          tester.getCenter(find.byKey(ValueKey('measurement-${m.id.value}'))),
          offsetMoreOrLessEquals(slot(tester, 0, 2), epsilon: 1));
      expect(c.measurements.single.column, 1, reason: 'hover never mutates');
      await gesture.up();
      await tester.pumpAndSettle();

      final after = c.measurements.single;
      expect((after.id, after.column, after.classicalBit), (m.id, 2, 0));
      expect(c.logicalGates.map((g) => g.column).toList()..sort(), [0, 1]);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('composer-circuit-summary')))
              .data,
          '2 qubits · 3 operations · 1 measurement');
      expect(tester.takeException(), isNull);
    });

    testWidgets('measurement moves across a link; invalid moves are rejected',
        (tester) async {
      final storage = InMemoryAppStorage();
      await openSandbox(tester, storage, qubits: 3);
      final c = circuitOf(tester);
      c.insertDoubleGateWithOutcome(_cnot, 0, 2, 0);
      await tester.pumpAndSettle();
      await drop(tester, measureTile, 1, 1);
      final m = c.measurements.single;
      expect(m.column, 1);

      final move = await grabMeasurement(tester, 1, 1, 0);
      expect(find.byKey(const ValueKey('measurement-drop-preview')),
          findsOneWidget);
      await move.up();
      await tester.pumpAndSettle();
      final moved = c.measurementById(m.id)!;
      expect((moved.column, moved.classicalBit), (0, m.classicalBit));
      expect(statusOf(tester), contains('moved'));

      await drop(tester, measureTile, 2, 3);
      final m2 = c.measurements.firstWhere((x) => x.qubit == 2);
      final encoded = _encode(c);
      final bad = await grabMeasurement(tester, 2, m2.column, 0);
      expect(find.byKey(const ValueKey('measurement-drop-preview-rejected')),
          findsOneWidget);
      await bad.up();
      await tester.pumpAndSettle();
      expect(_encode(c), encoded);
      expect(statusOf(tester), 'Not changed: $_terminal');

      // Persistence keeps IDs, columns and destinations.
      final saved = (await SandboxWorkspacePersistence(storage).load(3))!;
      expect(saved.encode(), encoded);
      expect(tester.takeException(), isNull);
    });

    testWidgets('legacy post-measurement circuit opens unchanged with a note',
        (tester) async {
      final storage = InMemoryAppStorage();
      final legacy = SandboxProgramSnapshot.decode(_legacyJson);
      await SandboxWorkspacePersistence(storage).queue(2).saveProgram(legacy);
      await openSandbox(tester, storage, qubits: 2);
      expect(find.byKey(const ValueKey('web-composer-legacy-measurement-note')),
          findsOneWidget);
      expect(_encode(circuitOf(tester)), legacy.encode());
      expect((await SandboxWorkspacePersistence(storage).load(2))!.encode(),
          legacy.encode());
      expect(tester.takeException(), isNull);
    });
  });
}
