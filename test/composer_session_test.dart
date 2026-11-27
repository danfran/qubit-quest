// v2.6 M2: shared Composer foundation (ComposerSession, ComposerPolicy,
// EditHistory and CircuitEditSnapshot).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/circuit_executor.dart';
import 'package:quantumquiz/models/circuit_save_queue.dart';
import 'package:quantumquiz/models/composer_gate_capabilities.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/edit_history.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/sandbox_workspace_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';

Gate _g(SelectedGateType type, {double? angle}) =>
    Gate.fromIdentifier(type, angle: angle);
final _h = _g(SelectedGateType.hadamard);
final _x = _g(SelectedGateType.x);
final _cnot = _g(SelectedGateType.cnot);
final _ccx = _g(SelectedGateType.ccnot);

CircuitLocation _at(int qubit, int column) =>
    CircuitLocation(qubit: qubit, column: column);

GatePlacementRequest _place(Gate gate, int qubit, int column,
        [List<int> controls = const []]) =>
    GatePlacementRequest(
        gate: gate, target: _at(qubit, column), controls: controls);

class _CountingStorage extends InMemoryAppStorage {
  int writes = 0;
  @override
  Future<void> writeString(String key, String value) {
    writes++;
    return super.writeString(key, value);
  }
}

/// A lesson with a fixed X on q0, a preset Rz(π/4) and a free Ry.
ComposerLevel _lessonLevel() => ComposerLevel(
      title: 'Fixed-gate lesson',
      taskDescription: 'Test lesson.',
      numQubits: 2,
      initialQubitsStateStr: '00',
      initialQubitsState: ComposerLevel.getZeroStateVector(2),
      availableGates: [
        _x,
        _h,
        _cnot,
        _g(SelectedGateType.rz, angle: math.pi / 4),
        _g(SelectedGateType.ry),
      ],
      solutionFinalVector: ComposerLevel.getOneStateVector(2)
          .map((amplitude) => [amplitude])
          .toList(),
      preInsertedGates: (circuit) => circuit.insertSinglePlacedGateAt(
        _x,
        0,
        0,
        isDeletable: false,
      ),
    );

ComposerSession _sandbox(int qubits,
    {CircuitSaveQueue? queue, MeasuredCircuitRunner? runner}) {
  final circuit =
      QuantumCircuit(currentLevel: createSandboxComposerLevel(qubits));
  return ComposerSession(
    circuit: circuit,
    policy: ComposerPolicy.forMode(ComposerMode.sandbox, circuit.currentLevel),
    saveQueue: queue ?? CircuitSaveQueue.programs((_) async {}),
    runner: runner,
  );
}

ComposerSession _lesson([ComposerMode mode = ComposerMode.journeyExercise]) {
  final level = _lessonLevel();
  return ComposerSession(
    circuit: QuantumCircuit(currentLevel: level),
    policy: ComposerPolicy.forMode(mode, level),
  );
}

/// Exact definition of the circuit, for comparisons.
CircuitEditSnapshot _def(ComposerSession s) => s.circuit.captureEditSnapshot();

String _program(ComposerSession s) =>
    SandboxProgramSnapshot.capture(s.circuit).encode();

void main() {
  group('EditHistory', () {
    test('records, undoes, redoes and drops the redo branch', () {
      final history = EditHistory<int>(0);
      history
        ..record(1)
        ..record(2);
      expect(history.undo(), 1);
      expect(history.canRedo, isTrue);
      history.record(3);
      expect(history.canRedo, isFalse);
      expect(history.undo(), 1);
      expect(history.undo(), 0);
      expect(history.undo(), isNull);
      expect(history.redo(), 1);
      expect(history.redo(), 3);
    });

    test('keeps at most limit undo steps', () {
      final history = EditHistory<int>(0, limit: 100);
      for (var i = 1; i <= 150; i++) {
        history.record(i);
      }
      expect(history.undoDepth, 100);
      var last = 150;
      while (history.canUndo) {
        last = history.undo()!;
      }
      expect(last, 50);
    });
  });

  group('ComposerPolicy', () {
    test('expresses the four modes from the M1 constraint table', () {
      final sandbox = ComposerPolicy.forMode(
          ComposerMode.sandbox, createSandboxComposerLevel(3));
      expect(sandbox.allowsMeasurement, isTrue);
      expect(sandbox.persistsToSandbox, isTrue);
      expect(sandbox.permittedQubitCounts, {1, 2, 3, 4, 5});
      expect(sandbox.offersCheck, isFalse);
      expect(sandbox.clearAction, ComposerClearAction.clear);
      expect(sandbox.angleEntry, ComposerAngleEntry.defaultOnPlacement);

      for (final mode in [
        ComposerMode.journeyExercise,
        ComposerMode.masteryChallenge,
      ]) {
        final lesson = ComposerPolicy.forMode(mode, _lessonLevel());
        expect(lesson.allowsMeasurement, isFalse);
        expect(lesson.persistsToSandbox, isFalse);
        expect(lesson.permittedQubitCounts, {2});
        expect(lesson.showsTargetState, isTrue);
        expect(lesson.offersCheck, isTrue);
        expect(lesson.offersHints, isTrue);
        expect(lesson.clearAction, ComposerClearAction.reset);
        expect(lesson.angleEntry, ComposerAngleEntry.palettePreset);
        expect(lesson.allowsAngleEditing(SelectedGateType.rz), isFalse);
        expect(lesson.allowsAngleEditing(SelectedGateType.ry), isTrue);
      }

      final notebook =
          ComposerPolicy.forMode(ComposerMode.notebookExample, _lessonLevel());
      // M6b: Notebook experiments measure like the Sandbox, never persist,
      // offer no Check, and Reset restores the authored example.
      expect(notebook.allowsMeasurement, isTrue);
      expect(notebook.runsExperiments, isTrue);
      expect(notebook.persistsToSandbox, isFalse);
      expect(notebook.offersCheck, isFalse);
      expect(notebook.offersHints, isFalse);
      expect(notebook.clearAction, ComposerClearAction.reset);
      expect(notebook.angleEntry, ComposerAngleEntry.defaultOnPlacement);
    });

    test('only Sandbox sessions may own a save queue', () {
      final level = _lessonLevel();
      expect(
        () => ComposerSession(
          circuit: QuantumCircuit(currentLevel: level),
          policy: ComposerPolicy.forMode(ComposerMode.masteryChallenge, level),
          saveQueue: CircuitSaveQueue.programs((_) async {}),
        ),
        throwsArgumentError,
      );
      final sandboxLevel = createSandboxComposerLevel(1);
      expect(
        () => ComposerSession(
          circuit: QuantumCircuit(currentLevel: sandboxLevel),
          policy: ComposerPolicy.forMode(ComposerMode.sandbox, sandboxLevel),
        ),
        throwsArgumentError,
      );
    });
  });

  group('commands', () {
    test('a committed insert notifies once, simulates, selects, revises', () {
      final s = _sandbox(1);
      var notifications = 0;
      s.addListener(() => notifications++);
      final outcome = s.insertGate(_place(_x, 0, 0));
      expect(outcome.changed, isTrue);
      expect(notifications, 1);
      expect(s.revision, 1);
      expect(s.selectedId, outcome.affectedGateId);
      expect(s.canUndo, isTrue);
      expect(s.circuit.currentState.stateVector[1].real, closeTo(1, 1e-12));
      expect(s.lastFeedback!.kind, ComposerFeedbackKind.committed);
    });

    test('a rejected command leaves circuit, history and revision unchanged',
        () {
      final s = _sandbox(1);
      final before = _def(s);
      final outcome = s.insertGate(_place(_x, 3, 0)); // no qubit 3
      expect(outcome.changed, isFalse);
      expect(_def(s).sameDefinitionAs(before), isTrue);
      expect(s.canUndo, isFalse);
      expect(s.revision, 0);
      expect(s.lastFeedback!.kind, ComposerFeedbackKind.rejected);
    });

    test('rotation without an angle is never placed (no partial gate)', () {
      final s = _sandbox(1);
      final outcome = s.insertGate(_place(_g(SelectedGateType.rx), 0, 0));
      expect(outcome.status, CircuitEditStatus.invalid);
      expect(s.circuit.isCircuitEmpty(), isTrue);
      expect(s.canUndo, isFalse);
    });

    test('control count must match the gate type', () {
      final s = _sandbox(3);
      expect(
          s.insertGate(_place(_cnot, 1, 0)).status, CircuitEditStatus.invalid);
      expect(s.insertGate(_place(_ccx, 2, 0, [0])).status,
          CircuitEditStatus.invalid);
      expect(s.circuit.isCircuitEmpty(), isTrue);
      final ccx = s.insertGate(_place(_ccx, 2, 0, [0, 1]));
      expect(ccx.changed, isTrue);
      final gate = s.circuit.logicalGateById(ccx.affectedGateId!)!;
      expect(gate.controlQubit, 0);
      expect(gate.secondControlQubit, 1);
      expect(gate.targetQubit, 2);
      expect(controlCountFor(SelectedGateType.ccnot), 2);
      expect(controlCountFor(SelectedGateType.hadamard), 0);
    });

    test('policy restrictions: no measurement or foreign gates in lessons', () {
      final s = _lesson();
      final before = _def(s);
      expect(
          s.insertMeasurement(_at(1, 0)).status, CircuitEditStatus.unsupported);
      expect(s.insertGate(_place(_g(SelectedGateType.t), 1, 0)).status,
          CircuitEditStatus.unsupported);
      expect(_def(s).sameDefinitionAs(before), isTrue);
      expect(s.canUndo, isFalse);
    });

    test('fixed gates cannot be deleted, moved, replaced or re-angled', () {
      final s = _lesson();
      final fixed = s.circuit.logicalGates.single;
      expect(fixed.isDeletable, isFalse);
      final before = _def(s);
      expect(s.deleteOperation(fixed.id).status, CircuitEditStatus.protected);
      expect(s.replaceGate(fixed.id, _h).changed, isFalse);
      expect(s.moveGate(fixed.id, _at(0, 3)).changed, isFalse);
      expect(_def(s).sameDefinitionAs(before), isTrue);
      expect(s.canUndo, isFalse);
    });

    test('preset lesson angles are protected, free ones editable', () {
      final s = _lesson();
      final rz = s
          .insertGate(_place(_g(SelectedGateType.rz, angle: math.pi / 4), 1, 0))
          .affectedGateId!;
      final ry = s
          .insertGate(_place(_g(SelectedGateType.ry, angle: math.pi / 2), 1, 1))
          .affectedGateId!;
      expect(
          s.editRotationAngle(rz, math.pi).status, CircuitEditStatus.protected);
      s.select(rz);
      expect(
          s.selectedCapabilities.supports(ComposerSelectedGateAction.editAngle),
          isFalse);
      expect(s.editRotationAngle(ry, math.pi).changed, isTrue);
      s.select(ry);
      expect(
          s.selectedCapabilities.supports(ComposerSelectedGateAction.editAngle),
          isTrue);
    });

    test('selection lifecycle: invalid IDs, delete and undo clear it', () {
      final s = _sandbox(2);
      var notifications = 0;
      final id = s.insertGate(_place(_h, 0, 0)).affectedGateId!;
      s.addListener(() => notifications++);
      s.select(id);
      expect(notifications, 0, reason: 'already selected: no notification');
      s.select(null);
      expect(s.selectedId, isNull);
      s.select(id);
      expect(s.canUndo, isTrue);
      final depth = s.canRedo;
      expect(depth, isFalse, reason: 'selection is not an edit');
      s.deleteOperation(id);
      expect(s.selectedId, isNull);
      s.undo();
      s.select(id);
      expect(s.selectedId, id, reason: 'undo restores the same gate identity');
      s.undo();
      expect(s.selectedId, isNull, reason: 'gate no longer exists');
    });
  });

  group('undo / redo', () {
    test('round-trips every gate command exactly', () {
      final s = _sandbox(3);
      final states = <CircuitEditSnapshot>[_def(s)];
      void step(CircuitEditOutcome outcome) {
        expect(outcome.changed, isTrue, reason: outcome.detail);
        states.add(_def(s));
      }

      final h = s.insertGate(_place(_h, 0, 0)).affectedGateId!;
      states.add(_def(s));
      step(s.insertGate(_place(_cnot, 1, 1, [0])));
      final rx = s
          .insertGate(_place(_g(SelectedGateType.rx, angle: math.pi / 3), 2, 0))
          .affectedGateId!;
      states.add(_def(s));
      step(s.editRotationAngle(rx, math.pi / 5));
      step(s.replaceGate(h, _g(SelectedGateType.y)));
      step(s.duplicateGate(h));
      step(s.moveGate(rx, _at(1, 0)));
      step(s.deleteOperation(h));
      step(s.clear());

      for (var i = states.length - 2; i >= 0; i--) {
        expect(s.undo(), isTrue);
        expect(_def(s).sameDefinitionAs(states[i]), isTrue, reason: 'undo $i');
      }
      expect(s.undo(), isFalse);
      for (var i = 1; i < states.length; i++) {
        expect(s.redo(), isTrue);
        expect(_def(s).sameDefinitionAs(states[i]), isTrue, reason: 'redo $i');
      }
      expect(s.redo(), isFalse);
    });

    test('a move that settles back into its slot is a no-op', () async {
      final s = _sandbox(1);
      final id = s.insertGate(_place(_x, 0, 0)).affectedGateId!;
      await s.run(manyShots: true);
      final revision = s.revision;
      // Gravity compaction returns the lone gate to column 0.
      s.moveGate(id, _at(0, 3));
      expect(s.revision, revision);
      expect(s.shotsResult, isNotNull, reason: 'results are still valid');
      s.undo();
      expect(s.circuit.isCircuitEmpty(), isTrue,
          reason: 'one undo reverts the insert, not the no-op move');
    });

    test('rotation parameters survive undo/redo', () {
      final s = _sandbox(1);
      final id = s
          .insertGate(_place(_g(SelectedGateType.rz, angle: math.pi / 2), 0, 0))
          .affectedGateId!;
      s.editRotationAngle(id, math.pi / 8);
      s.undo();
      expect(s.circuit.logicalGateById(id)!.gate.angle, math.pi / 2);
      s.redo();
      expect(s.circuit.logicalGateById(id)!.gate.angle, math.pi / 8);
    });

    test('a new edit after undo discards the redo branch', () {
      final s = _sandbox(1);
      s.insertGate(_place(_h, 0, 0));
      s.insertGate(_place(_x, 0, 1));
      s.undo();
      expect(s.canRedo, isTrue);
      s.insertGate(_place(_g(SelectedGateType.z), 0, 1));
      expect(s.canRedo, isFalse);
    });

    test('no-op, rejected and selection commands create no history', () {
      final s = _sandbox(2);
      final id = s
          .insertGate(_place(_g(SelectedGateType.rx, angle: math.pi), 0, 0))
          .affectedGateId!;
      final m = s.insertMeasurement(_at(1, 0)).affectedGateId!;
      s.undo();
      s.redo();
      expect(s.canRedo, isFalse);
      // Every one of these is unchanged or rejected.
      expect(s.editRotationAngle(id, math.pi).status, CircuitEditStatus.same);
      expect(s.setClassicalBit(m, 1).status, CircuitEditStatus.same);
      expect(s.insertGate(_place(_x, 9, 0)).changed, isFalse);
      s.select(m);
      s.select(null);
      s.undo();
      expect(s.circuit.measurements, isEmpty,
          reason: 'one undo reverts the last real edit');
    });

    test('measurement insert, move, classical bit and delete round-trip', () {
      final s = _sandbox(3);
      s.insertGate(_place(_cnot, 2, 0, [0]));
      final states = <String>[_program(s)];
      final m1 = s.insertMeasurement(_at(1, 1)).affectedGateId!;
      states.add(_program(s));
      final m0 = s.insertMeasurement(_at(0, 1)).affectedGateId!;
      states.add(_program(s));
      expect(s.setClassicalBit(m0, 2).changed, isTrue);
      states.add(_program(s));
      expect(s.moveMeasurement(m1, 0).changed, isTrue,
          reason: 'a measurement can move across the link on q1');
      states.add(_program(s));
      expect(s.deleteOperation(m1).changed, isTrue);
      states.add(_program(s));

      for (var i = states.length - 2; i >= 0; i--) {
        s.undo();
        expect(_program(s), states[i], reason: 'undo to $i');
      }
      for (var i = 1; i < states.length; i++) {
        s.redo();
        expect(_program(s), states[i], reason: 'redo to $i');
      }
      expect(s.circuit.measurementById(m0)!.classicalBit, 2);
    });

    test('undo across the measured/unmeasured boundary re-simulates', () {
      final s = _sandbox(1);
      s.insertGate(_place(_x, 0, 0));
      s.insertMeasurement(_at(0, 1));
      s.undo();
      expect(s.circuit.hasMeasurements, isFalse);
      expect(s.circuit.currentState.stateVector[1].real, closeTo(1, 1e-12));
      s.undo();
      expect(s.circuit.currentState.stateVector[0].real, closeTo(1, 1e-12));
    });

    test('reset keeps fixed gates and is undoable', () {
      final s = _lesson();
      final fixed = s.circuit.logicalGates.single;
      s.insertGate(_place(_h, 1, 0));
      s.insertGate(_place(_x, 1, 1));
      final edited = _def(s);
      s.clear();
      final reset = s.circuit.logicalGates.single;
      expect(reset.isDeletable, isFalse);
      expect(reset.type, SelectedGateType.x);
      expect(reset.anchor, fixed.anchor);
      s.undo();
      expect(_def(s).sameDefinitionAs(edited), isTrue);
      expect(s.circuit.logicalGates.where((g) => !g.isDeletable).single.id,
          fixed.id,
          reason: 'fixed-gate identity and protection are restored');
    });

    test('history is bounded to 100 steps', () {
      final s = _sandbox(1);
      for (var i = 0; i < 120; i++) {
        s.insertGate(_place(_x, 0, i));
      }
      var undone = 0;
      while (s.undo()) {
        undone++;
      }
      expect(undone, 100);
      expect(s.circuit.logicalGates, hasLength(20));
    });

    test('restoring a snapshot of another qubit count is refused', () {
      final one = QuantumCircuit(currentLevel: createSandboxComposerLevel(1));
      final two = QuantumCircuit(currentLevel: createSandboxComposerLevel(2));
      expect(() => two.restoreEditSnapshot(one.captureEditSnapshot()),
          throwsArgumentError);
    });
  });

  group('persistence', () {
    test('Sandbox autosaves once per commit and after undo/redo', () async {
      final storage = _CountingStorage();
      final programs = SandboxWorkspacePersistence(storage);
      final s = _sandbox(2, queue: programs.queue(2));
      s.insertGate(_place(_h, 0, 0));
      await programs.queue(2).retry();
      final afterInsert = storage.writes;
      expect(afterInsert, greaterThan(0));
      expect((await programs.load(2))!.program.operations, hasLength(1));

      s.select(s.circuit.logicalGates.single.id);
      s.insertGate(_place(_x, 5, 0)); // rejected
      await programs.queue(2).retry();
      expect(storage.writes, afterInsert,
          reason: 'selection and rejected edits never save');

      s.undo();
      await programs.queue(2).retry();
      expect((await programs.load(2))!.program.operations, isEmpty);
      s.redo();
      await programs.queue(2).retry();
      expect((await programs.load(2))!.program.operations, hasLength(1));
    });

    test('lesson sessions never touch Sandbox storage', () {
      final s = _lesson(ComposerMode.masteryChallenge);
      expect(s.saveQueue, isNull);
      s.insertGate(_place(_h, 1, 0));
      expect(s.saveQueue, isNull);
    });
  });

  group('results lifecycle', () {
    ComposerSession seeded(int qubits) => _sandbox(qubits,
        runner: MeasuredCircuitRunner(
            executor: CircuitExecutor(nextDouble: math.Random(7).nextDouble)));

    test('running never mutates the circuit, history or storage', () async {
      final s = seeded(2);
      s.insertGate(_place(_h, 0, 0));
      s.insertGate(_place(_cnot, 1, 1, [0]));
      s.insertMeasurement(_at(0, 2));
      s.insertMeasurement(_at(1, 2));
      final definition = _program(s);
      final revision = s.revision;
      await s.run(manyShots: true);
      await s.run(manyShots: false);
      expect(_program(s), definition);
      expect(s.revision, revision);
      expect(s.shotsResult!.shots, 1000);
      expect(s.shotsResult!.counts.keys.toSet(), {'00', '11'});
      expect(s.singleShot, isNotNull);
      s.undo();
      expect(s.shotsResult, isNull, reason: 'undo invalidates results');
      expect(s.singleShot, isNull);
    });

    test('edits clear results; selection does not', () async {
      final s = seeded(1);
      s.insertGate(_place(_x, 0, 0));
      await s.run(manyShots: true);
      expect(s.shotsResult!.counts, {'1': 1000});
      s.select(s.circuit.logicalGates.single.id);
      expect(s.shotsResult, isNotNull);
      s.insertGate(_place(_h, 0, 1));
      expect(s.shotsResult, isNull);
    });

    test('a run that finishes after an edit is discarded', () async {
      late ComposerSession s;
      final circuit =
          QuantumCircuit(currentLevel: createSandboxComposerLevel(1));
      s = ComposerSession(
        circuit: circuit,
        policy:
            ComposerPolicy.forMode(ComposerMode.sandbox, circuit.currentLevel),
        saveQueue: CircuitSaveQueue.programs((_) async {}),
        beforeRun: () async => s.insertGate(_place(_x, 0, 0)),
      );
      await s.run(manyShots: true);
      expect(s.running, isFalse);
      expect(s.shotsResult, isNull);
    });

    test('pre-measurement state is cached per revision', () {
      final s = seeded(1);
      s.insertGate(_place(_x, 0, 0));
      s.insertMeasurement(_at(0, 1));
      final first = s.preMeasurement!;
      expect(identical(first, s.preMeasurement), isTrue);
      expect(first.stateVector![1].real, closeTo(1, 1e-12));
      s.undo();
      expect(s.preMeasurement, isNull);
    });
  });

  group('direct circuit edits', () {
    test('are adopted like commands (history, revision, results)', () async {
      final s = _sandbox(1);
      await s.run(manyShots: true);
      expect(s.shotsResult, isNotNull);
      s.circuit.insertSingleGateWithOutcome(_x, 0, 0);
      expect(s.revision, 1);
      expect(s.shotsResult, isNull);
      expect(s.canUndo, isTrue);
      expect(s.circuit.currentState.stateVector[1].real, closeTo(1, 1e-12));
      s.circuit.runSimulation(); // not a definition change
      expect(s.revision, 1);
    });

    test('dispose detaches from and disposes the owned circuit', () {
      final s = _sandbox(1);
      final circuit = s.circuit;
      s.dispose();
      expect(s.isDisposed, isTrue);
      expect(
          s.insertGate(_place(_x, 0, 0)).status, CircuitEditStatus.cancelled);
      expect(() => circuit.addListener(() {}), throwsFlutterError);
    });
  });

  group('host parity', () {
    test('identical commands give identical circuits in every mode', () {
      ComposerLevel level() => ComposerLevel(
            taskDescription: 'parity',
            numQubits: 3,
            initialQubitsStateStr: '000',
            initialQubitsState: ComposerLevel.getZeroStateVector(3),
            availableGates: [
              for (final type in sandboxGatePaletteTypes)
                Gate.fromIdentifier(type)
            ],
            solutionFinalVector: const [],
          );
      final encodings = <String>{};
      for (final mode in ComposerMode.values) {
        final l = level();
        final circuit = QuantumCircuit(currentLevel: l);
        final policy = ComposerPolicy.forMode(mode, l);
        final s = ComposerSession(
          circuit: circuit,
          policy: policy,
          saveQueue: policy.persistsToSandbox
              ? CircuitSaveQueue.programs((_) async {})
              : null,
        );
        final h = s.insertGate(_place(_h, 0, 0)).affectedGateId!;
        s.insertGate(_place(_cnot, 1, 1, [0]));
        s.insertGate(_place(_ccx, 2, 2, [0, 1]));
        s.insertGate(_place(_g(SelectedGateType.ry, angle: 1.25), 2, 0));
        s.duplicateGate(h);
        s.replaceGate(h, _g(SelectedGateType.s));
        s.undo();
        s.redo();
        encodings.add(_program(s));
        s.dispose();
      }
      expect(encodings, hasLength(1));
    });
  });
}
