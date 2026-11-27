// v2.6 M7: Controlled-Y and multi-controlled X as first-class operations.
//
// Conventions under test: register kets |q(n−1)…q0⟩ (amplitude index bit k
// is qubit k); initial binary strings are most significant first; the CY
// matrix in the brief uses the local order |control, target⟩.
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/circuit_save_queue.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/gate_reference_examples.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/notebook_knowledge_base.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/multi_controlled_gate_placement_dialog.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';

// ---------------------------------------------------------------- helpers

const _i = (0.0, 1.0);

List<List<Complex>> _m(QuantumMatrix m) => m.toComplexList();

void _expectMatrix(List<List<Complex>> actual, List<List<(double, double)>> e,
    {String? reason}) {
  expect(actual.length, e.length, reason: reason);
  for (var r = 0; r < e.length; r++) {
    for (var c = 0; c < e.length; c++) {
      expect(actual[r][c].real, closeTo(e[r][c].$1, 1e-12),
          reason: '${reason ?? ''} [$r][$c] re');
      expect(actual[r][c].imaginary, closeTo(e[r][c].$2, 1e-12),
          reason: '${reason ?? ''} [$r][$c] im');
    }
  }
}

List<List<Complex>> _mul(List<List<Complex>> a, List<List<Complex>> b) => [
      for (var r = 0; r < a.length; r++)
        [
          for (var c = 0; c < b.length; c++)
            List.generate(a.length, (k) => a[r][k] * b[k][c])
                .fold<Complex>(Complex.zero(), (x, y) => x + y)
        ]
    ];

List<List<Complex>> _dagger(List<List<Complex>> a) => [
      for (var r = 0; r < a.length; r++)
        [for (var c = 0; c < a.length; c++) a[c][r].conjugate]
    ];

List<List<(double, double)>> _identity(int n) => [
      for (var r = 0; r < n; r++)
        [for (var c = 0; c < n; c++) (r == c ? 1.0 : 0.0, 0.0)]
    ];

List<List<(double, double)>> _plain(List<List<Complex>> a) => [
      for (final row in a)
        [for (final x in row) (x.real.toDouble(), x.imaginary.toDouble())]
    ];

ComposerLevel _level(int n, [String? initial]) =>
    createSandboxComposerLevel(n, initialBinaryState: initial);

String _bits(int index, int n) => index.toRadixString(2).padLeft(n, '0');

QuantumCircuit _circuit(int n, {String? initial}) =>
    QuantumCircuit(currentLevel: _level(n, initial));

List<Complex> _run(QuantumCircuit c) {
  c.runSimulation();
  expect(c.lastSimulationError, isNull);
  return c.currentState.stateVector;
}

void _expectState(List<Complex> actual, List<Complex> expected,
    {String? reason}) {
  expect(actual.length, expected.length, reason: reason);
  for (var k = 0; k < expected.length; k++) {
    expect(actual[k].real, closeTo(expected[k].real, 1e-9),
        reason: '${reason ?? ''} amplitude $k re');
    expect(actual[k].imaginary, closeTo(expected[k].imaginary, 1e-9),
        reason: '${reason ?? ''} amplitude $k im');
  }
}

/// Independent reference: applies a 2×2 [u] to [target] wherever all
/// [controls] are 1, pairwise on amplitudes (no matrices).
List<Complex> _reference(List<Complex> state, List<int> controls, int target,
    List<List<Complex>> u) {
  final out = [...state];
  final mask = controls.fold<int>(0, (m, c) => m | 1 << c);
  final t = 1 << target;
  for (var k = 0; k < state.length; k++) {
    if (k & t != 0 || k & mask != mask) continue;
    final a = state[k], b = state[k | t];
    out[k] = u[0][0] * a + u[0][1] * b;
    out[k | t] = u[1][0] * a + u[1][1] * b;
  }
  return out;
}

final _y = _m(QuantumMatrix.pauliY());
final _x = _m(QuantumMatrix.pauliX());

/// Prepares an arbitrary complex superposition on every qubit.
void _scramble(QuantumCircuit c) {
  final n = c.currentLevel.numQubits;
  for (var q = 0; q < n; q++) {
    c.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.ry, angle: 0.4 + 0.37 * q),
        c.maxCircuitDepth(),
        q);
    c.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.rz, angle: 1.1 - 0.29 * q),
        c.maxCircuitDepth(),
        q);
  }
  for (var q = 0; q + 1 < n; q++) {
    c.insertDoubleGateWithOutcome(Gate.fromIdentifier(SelectedGateType.cnot),
        c.maxCircuitDepth(), q + 1, q);
  }
  c.insertSingleGateWithOutcome(
      Gate.fromIdentifier(SelectedGateType.s), c.maxCircuitDepth(), 0);
}

double _norm(List<Complex> s) => s.fold<double>(
    0, (a, x) => a + x.real * x.real + x.imaginary * x.imaginary);

CircuitEditOutcome _cy(QuantumCircuit c, int control, int target) =>
    c.insertDoubleGateWithOutcome(Gate.fromIdentifier(SelectedGateType.cy),
        c.maxCircuitDepth(), target, control);

CircuitEditOutcome _mcx(QuantumCircuit c, List<int> controls, int target) =>
    c.insertMultiControlledGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.mcx),
        c.maxCircuitDepth(),
        target,
        controls);

ComposerSession _sandbox(int n, {String? initial}) {
  final c = _circuit(n, initial: initial)..runSimulation();
  return ComposerSession(
    circuit: c,
    policy: ComposerPolicy.forMode(ComposerMode.sandbox, c.currentLevel),
    saveQueue: CircuitSaveQueue.programs((_) async {}),
  );
}

GatePlacementRequest _req(SelectedGateType type, int target, int column,
        [List<int> controls = const []]) =>
    GatePlacementRequest(
      gate: Gate.fromIdentifier(type),
      target: CircuitLocation(qubit: target, column: column),
      controls: controls,
    );

void main() {
  // ============================================================== CY maths
  group('CY mathematics', () {
    test('local matrix in |control, target⟩ order is exactly the brief’s', () {
      // control q1, target q0: local index = control·2 + target.
      _expectMatrix(_m(QuantumMatrix.cy(control: 1, target: 0)), [
        [(1, 0), (0, 0), (0, 0), (0, 0)],
        [(0, 0), (1, 0), (0, 0), (0, 0)],
        [(0, 0), (0, 0), (0, 0), (0, -1)],
        [(0, 0), (0, 0), _i, (0, 0)],
      ]);
    });

    test('every basis input, both orientations, through the circuit', () {
      // |control, target⟩: 00→00, 01→01, 10→i|11⟩, 11→−i|10⟩.
      for (final (control, target) in [(0, 1), (1, 0)]) {
        for (var c = 0; c < 2; c++) {
          for (var t = 0; t < 2; t++) {
            final index = c << control | t << target;
            final circuit = _circuit(2, initial: _bits(index, 2));
            expect(_cy(circuit, control, target).changed, isTrue);
            final out = _run(circuit);
            final expected = List.filled(4, Complex.zero());
            if (c == 0) {
              expected[index] = Complex.one();
            } else {
              final flipped = index ^ 1 << target;
              expected[flipped] =
                  t == 0 ? Complex(0, 1) : Complex(0, -1); // i|1⟩, −i|0⟩
            }
            _expectState(out, expected,
                reason: 'control q$control target q$target |c=$c,t=$t⟩');
          }
        }
      }
    });

    test('CY² = I, CY† = CY, and CY = (I⊗S) CX (I⊗S†) exactly', () {
      final cy = _m(QuantumMatrix.cy(control: 1, target: 0));
      _expectMatrix(_mul(cy, cy), _identity(4), reason: 'CY²');
      _expectMatrix(_dagger(cy), _plain(cy), reason: 'CY†');
      // Local order |control, target⟩ = |q1 q0⟩: I⊗S acts on the target q0.
      final iS =
          _m(QuantumMatrix.identity(2).tensorProduct(QuantumMatrix.phaseS()));
      final iSdg = _dagger(iS);
      final cx = _m(QuantumMatrix.cnot(control: 1, target: 0));
      // Exact equality: no per-entry or global phase is discarded.
      _expectMatrix(_mul(iS, _mul(cx, iSdg)), _plain(cy), reason: 'decomp');
    });

    test('complex superpositions, reversed and non-adjacent wires', () {
      for (final (control, target) in [(0, 2), (2, 0), (1, 3), (3, 0)]) {
        final circuit = _circuit(4);
        _scramble(circuit);
        final before = [..._run(circuit)];
        _cy(circuit, control, target);
        final after = _run(circuit);
        _expectState(after, _reference(before, [control], target, _y),
            reason: 'CY q$control→q$target');
        expect(_norm(after), closeTo(1, 1e-9));
      }
    });

    test('H then CY from |00⟩ gives (|00⟩ + i|11⟩)/√2', () {
      final circuit = _circuit(2);
      circuit.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      _cy(circuit, 0, 1);
      _expectState(_run(circuit), [
        Complex(math.sqrt1_2, 0),
        Complex.zero(),
        Complex.zero(),
        Complex(0, math.sqrt1_2),
      ]);
    });
  });

  // ============================================================= MCX maths
  group('MCX mathematics', () {
    void everyBasisInput(int n, List<int> controls, int target) {
      final mask = controls.fold<int>(0, (m, c) => m | 1 << c);
      for (var index = 0; index < 1 << n; index++) {
        final circuit = _circuit(n, initial: _bits(index, n));
        expect(_mcx(circuit, controls, target).changed, isTrue);
        final out = _run(circuit);
        final expectedIndex =
            index & mask == mask ? index ^ 1 << target : index;
        final expected = List.filled(1 << n, Complex.zero())
          ..[expectedIndex] = Complex.one();
        _expectState(out, expected,
            reason: 'controls $controls target q$target input $index');
      }
    }

    test('three controls, every 4-qubit basis input', () {
      everyBasisInput(4, [0, 1, 2], 3);
      everyBasisInput(4, [1, 2, 3], 0); // target below every control
    });

    test('five-qubit configurations, target between and around controls', () {
      everyBasisInput(5, [0, 1, 3, 4], 2); // four controls, target between
      everyBasisInput(5, [4, 2, 1], 0); // unsorted, non-contiguous
      everyBasisInput(5, [0, 2, 4], 3); // gaps on both sides
    });

    test('complex superpositions match the reference; norm preserved', () {
      for (final (controls, target) in [
        ([0, 1, 2], 3),
        ([0, 1, 3, 4], 2),
        ([4, 3, 1], 0),
      ]) {
        final n =
            controls.length >= 4 || target == 4 || controls.contains(4) ? 5 : 4;
        final circuit = _circuit(n);
        _scramble(circuit);
        final before = [..._run(circuit)];
        _mcx(circuit, controls, target);
        final after = _run(circuit);
        _expectState(after, _reference(before, controls, target, _x),
            reason: 'MCX $controls→q$target');
        expect(_norm(after), closeTo(1, 1e-9));
      }
    });

    test('MCX² = I and MCX† = MCX (exact matrices)', () {
      for (final (controls, target) in [
        ([0, 1, 2], 3),
        ([0, 1, 3, 4], 2),
      ]) {
        final m = _m(QuantumMatrix.mcx(controls: controls, target: target));
        _expectMatrix(_mul(m, m), _identity(m.length));
        _expectMatrix(_dagger(m), _plain(m));
      }
    });

    test('invalid topologies are rejected by the model', () {
      final circuit = _circuit(5);
      expect(_mcx(circuit, [0, 1], 3).status, CircuitEditStatus.invalid,
          reason: 'two controls is CCX');
      expect(_mcx(circuit, [0, 1, 1], 3).status, CircuitEditStatus.invalid);
      expect(_mcx(circuit, [0, 1, 3], 3).status, CircuitEditStatus.invalid,
          reason: 'target cannot be a control');
      expect(_mcx(circuit, [0, 1, 5], 3).status, CircuitEditStatus.invalid);
      expect(_mcx(_circuit(3), [0, 1, 2], 0).status, CircuitEditStatus.invalid,
          reason: 'never resizes the register');
      expect(circuit.logicalGates, isEmpty);
    });
  });

  // ============================================== existing gates preserved
  group('existing controlled gates are unchanged', () {
    test('CX, CZ and CCX matrices', () {
      _expectMatrix(_m(QuantumMatrix.cnot(control: 1, target: 0)), [
        [(1, 0), (0, 0), (0, 0), (0, 0)],
        [(0, 0), (1, 0), (0, 0), (0, 0)],
        [(0, 0), (0, 0), (0, 0), (1, 0)],
        [(0, 0), (0, 0), (1, 0), (0, 0)],
      ]);
      _expectMatrix(_m(QuantumMatrix.cz(control: 0, target: 1)), [
        [(1, 0), (0, 0), (0, 0), (0, 0)],
        [(0, 0), (1, 0), (0, 0), (0, 0)],
        [(0, 0), (0, 0), (1, 0), (0, 0)],
        [(0, 0), (0, 0), (0, 0), (-1, 0)],
      ]);
      final ccx = _m(QuantumMatrix.ccnot(control1: 0, control2: 2, target: 1));
      for (var col = 0; col < 8; col++) {
        final row = col & 5 == 5 ? col ^ 2 : col;
        for (var r = 0; r < 8; r++) {
          expect(ccx[r][col].real, r == row ? 1 : 0);
          expect(ccx[r][col].imaginary, 0);
        }
      }
    });

    test('CCX keeps its identity, fields and fragment roles', () {
      final circuit = _circuit(3);
      circuit.insertTripleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.ccnot), 0, 1, 0, 2);
      final g = circuit.logicalGates.single;
      expect(g.type, SelectedGateType.ccnot);
      expect((g.controlQubit, g.secondControlQubit, g.targetQubit), (0, 2, 1));
      expect(g.fragments.map((f) => f.placedGate.controlQubitIndices),
          everyElement(isNull));
      expect(
          g.fragments
              .where((f) => f.placedGate.isControl2)
              .single
              .location
              .qubit,
          2);
      expect(g.hasValidTopology(3), isTrue);
    });
  });

  // ============================================================ measurement
  group('measurement after the new gates', () {
    test('exact probabilities, single run and shots after CY', () async {
      final s = _sandbox(2);
      s.insertGate(_req(SelectedGateType.hadamard, 0, 0));
      s.insertGate(_req(SelectedGateType.cy, 1, 1, [0]));
      final exact = s.exactDistribution.probabilities!;
      expect(exact['00'], closeTo(.5, 1e-9));
      expect(exact['11'], closeTo(.5, 1e-9));
      expect((exact['01'] ?? 0) + (exact['10'] ?? 0), closeTo(0, 1e-9));
      await s.run(manyShots: false);
      expect(['00', '11'], contains(s.singleShot!.outcome));
      await s.run(manyShots: true);
      expect(
          s.shotsResult!.counts.keys.toSet().difference({'00', '11'}), isEmpty);
      expect(
          s.shotsResult!.counts.values.fold<int>(0, (a, b) => a + b), s.shots);
      // An edit invalidates previous results.
      s.insertGate(_req(SelectedGateType.x, 0, 2));
      expect(s.shotsResult, isNull);
      expect(s.singleShot, isNull);
      s.dispose();
    });

    test('partial measurement of an MCX target: coherent AND, P(1) = 1/8',
        () async {
      final s = _sandbox(4);
      for (final q in [0, 1, 2]) {
        s.insertGate(_req(SelectedGateType.hadamard, q, 0));
      }
      s.insertGate(_req(SelectedGateType.mcx, 3, 1, [0, 1, 2]));
      final finalState = s.exactDistribution.probabilities!;
      expect(finalState['1111'], closeTo(1 / 8, 1e-9));
      expect(
          finalState.entries
              .where((e) => e.key.startsWith('1') && e.key != '1111')
              .fold<double>(0, (a, e) => a + e.value),
          closeTo(0, 1e-9),
          reason: 'the target is 1 only alongside 111');
      expect(
          s
              .insertMeasurement(const CircuitLocation(qubit: 3, column: 2))
              .changed,
          isTrue);
      final partial = s.exactDistribution.probabilities!;
      expect(partial.length, 2, reason: 'one classical bit');
      expect(partial['1'], closeTo(1 / 8, 1e-9));
      expect(partial['0'], closeTo(7 / 8, 1e-9));
      await s.run(manyShots: true);
      expect(
          s.shotsResult!.counts.keys.toSet().difference({'0', '1'}), isEmpty);
      s.dispose();
    });

    test('gates after a measurement on other qubits; measured qubit protected',
        () {
      final s = _sandbox(3);
      s.insertGate(_req(SelectedGateType.hadamard, 0, 0));
      s.insertMeasurement(const CircuitLocation(qubit: 0, column: 1));
      s.insertGate(_req(SelectedGateType.x, 1, 0));
      expect(
          s.insertGate(_req(SelectedGateType.cy, 2, 2, [1])).changed, isTrue);
      final program = CircuitProgram.fromCircuit(s.circuit);
      expect(
          program.operations
              .whereType<UnitaryOperation>()
              .any((op) => op.gate.type == SelectedGateType.cy),
          isTrue);
      expect(s.exactDistribution.isAvailable, isTrue);
      // CY controlled by the measured qubit is refused, like every gate.
      final refused = s.insertGate(_req(SelectedGateType.cy, 2, 5, [0]));
      expect(refused.changed, isFalse);
      s.dispose();
    });
  });

  // ================================================ composer and persistence
  group('Composer editing and persistence', () {
    test('palette and activity restrictions', () {
      expect(sandboxGatePaletteTypes,
          containsAll([SelectedGateType.cy, SelectedGateType.mcx]));
      final sandbox = ComposerPolicy.forMode(ComposerMode.sandbox, _level(4));
      expect(sandbox.allowsGateType(SelectedGateType.cy), isTrue);
      expect(sandbox.allowsGateType(SelectedGateType.mcx), isTrue);
      // Only the content authored for them in v2.6 M10 (Chapter 14 and
      // Mastery 43–48) offers the new gates; no earlier palette gained them.
      final authored = [
        for (final l in journeyLessons.take(66)) l,
        for (final c in mastery2Catalogue.orderedDefinitions)
          if (c.displayOrder <= 42) c.levelDefinition,
      ];
      for (final level in authored.whereType<ComposerLevel>()) {
        expect(
            level.availableGates.map((g) => g.type),
            isNot(anyOf(contains(SelectedGateType.cy),
                contains(SelectedGateType.mcx))),
            reason: level.title);
        for (final mode in [
          ComposerMode.journeyExercise,
          ComposerMode.masteryChallenge
        ]) {
          final policy = ComposerPolicy.forMode(mode, level);
          expect(policy.allowsGateType(SelectedGateType.cy), isFalse);
          expect(policy.allowsGateType(SelectedGateType.mcx), isFalse);
        }
      }
      // The session refuses them in an activity.
      final lesson = journeyLessons.whereType<ComposerLevel>().first;
      final session = ComposerSession(
        circuit: QuantumCircuit(currentLevel: lesson),
        policy: ComposerPolicy.forMode(ComposerMode.journeyExercise, lesson),
      );
      expect(session.insertGate(_req(SelectedGateType.cy, 0, 0, [1])).status,
          CircuitEditStatus.unsupported);
      session.dispose();
    });

    test('session validates control counts before committing', () {
      final s = _sandbox(5);
      expect(s.insertGate(_req(SelectedGateType.mcx, 2, 0, [0, 1])).changed,
          isFalse);
      expect(s.insertGate(_req(SelectedGateType.cy, 2, 0)).changed, isFalse);
      expect(s.insertGate(_req(SelectedGateType.mcx, 2, 0, [0, 1, 2])).changed,
          isFalse);
      expect(s.circuit.logicalGates, isEmpty);
      expect(
          s.insertGate(_req(SelectedGateType.mcx, 2, 0, [4, 0, 3, 1])).changed,
          isTrue);
      final g = s.circuit.logicalGates.single;
      expect(g.controlQubits, [0, 1, 3, 4]);
      expect(g.targetQubit, 2);
      expect(g.hasValidTopology(5), isTrue);
      expect(multiControlledUnavailableReason(3), contains('at least 4'));
      expect(multiControlledUnavailableReason(4), isNull);
      s.dispose();
    });

    test('move, duplicate, delete and undo/redo keep CY and MCX intact', () {
      final s = _sandbox(5);
      s.insertGate(_req(SelectedGateType.x, 0, 0));
      s.insertGate(_req(SelectedGateType.cy, 4, 1, [1]));
      s.insertGate(_req(SelectedGateType.mcx, 2, 2, [0, 1, 3, 4]));
      final mcx = s.circuit.logicalGates
          .singleWhere((g) => g.type == SelectedGateType.mcx);
      final cy = s.circuit.logicalGates
          .singleWhere((g) => g.type == SelectedGateType.cy);
      final start = s.circuit.captureEditSnapshot();

      expect(s.duplicateGate(mcx.id).changed, isTrue);
      final copies = s.circuit.logicalGates
          .where((g) => g.type == SelectedGateType.mcx)
          .toList();
      expect(copies, hasLength(2));
      for (final copy in copies) {
        expect(copy.controlQubits, [0, 1, 3, 4]);
        expect(copy.hasValidTopology(5), isTrue);
      }
      expect(s.duplicateGate(cy.id).changed, isTrue);

      // Same movement rules as CCX (a move past the circuit end is invalid).
      expect(
          s
              .moveGate(
                  mcx.id, CircuitLocation(qubit: 2, column: mcx.column + 9))
              .status,
          CircuitEditStatus.invalid);
      final moved = s.moveGate(mcx.id,
          CircuitLocation(qubit: 2, column: s.circuit.maxCircuitDepth()));
      expect(moved.changed, isTrue);
      final after = s.circuit.logicalGateById(mcx.id)!;
      expect(after.controlQubits, [0, 1, 3, 4]);
      expect(after.targetQubit, 2);

      expect(s.deleteOperation(mcx.id).changed, isTrue);
      expect(s.circuit.logicalGateById(mcx.id), isNull);
      while (s.canUndo) {
        s.undo();
      }
      s.redo();
      s.redo();
      s.redo();
      expect(s.circuit.captureEditSnapshot().sameDefinitionAs(start), isTrue,
          reason: 'undo then redo back to the three-gate circuit');
      for (final g in s.circuit.logicalGates) {
        expect(g.hasValidTopology(5), isTrue);
      }
      s.dispose();
    });

    test('schema 2 round trip preserves CY and MCX exactly', () {
      final s = _sandbox(5);
      s.insertGate(_req(SelectedGateType.hadamard, 2, 0));
      s.insertGate(_req(SelectedGateType.cy, 0, 1, [2]));
      s.insertGate(_req(SelectedGateType.mcx, 1, 2, [0, 2, 3]));
      s.insertMeasurement(const CircuitLocation(qubit: 1, column: 3));
      final encoded = SandboxProgramSnapshot.capture(s.circuit).encode();
      expect(encoded, contains('"controls":[0,2,3]'));
      final restored = SandboxProgramSnapshot.decode(encoded).restoreCircuit();
      // Measured circuits are compared through their stable encoding (the
      // grid-definition comparison differs after any measured restore, CX
      // included; pre-existing, documented in the M7 report).
      expect(SandboxProgramSnapshot.capture(restored).encode(), encoded);
      for (final g in restored.logicalGates) {
        final original = s.circuit.logicalGateById(g.id)!;
        expect(g.type, original.type);
        expect(g.controlQubits, original.controlQubits);
        expect((g.targetQubit, g.column),
            (original.targetQubit, original.column));
      }
      // Unmeasured circuits compare by definition.
      final plain = _circuit(5);
      _mcx(plain, [0, 2, 3], 1);
      _cy(plain, 2, 0);
      final plainBack = SandboxProgramSnapshot.decode(
              SandboxProgramSnapshot.capture(plain).encode())
          .restoreCircuit();
      expect(
          plainBack
              .captureEditSnapshot()
              .sameDefinitionAs(plain.captureEditSnapshot()),
          isTrue);
      restored.dispose();
      s.dispose();
    });

    test('schema 1 round trip and legacy CCX records', () {
      final c = _circuit(4);
      _cy(c, 3, 0);
      _mcx(c, [0, 1, 3], 2);
      final snapshot = SandboxCircuitSnapshot.capture(c);
      final back =
          SandboxCircuitSnapshot.decode(snapshot.encode()).restoreCircuit();
      expect(
          back.captureEditSnapshot().sameDefinitionAs(c.captureEditSnapshot()),
          isTrue);
      // A schema-2 CCX record written before M7 (no "controls" key).
      const legacy = '{"schemaVersion":2,"qubitCount":3,"classicalBitCount":0,'
          '"initialStateLabel":"011","initialState":[[0,0],[0,0],[0,0],[1,0],'
          '[0,0],[0,0],[0,0],[0,0]],"operations":[{"id":1,"column":0,'
          '"kind":"unitary","gateType":"ccnot","target":2,"control":0,'
          '"secondControl":1,"isDeletable":true}]}';
      final ccx = SandboxProgramSnapshot.decode(legacy).restoreCircuit();
      final g = ccx.logicalGates.single;
      expect(g.type, SelectedGateType.ccnot);
      expect((g.controlQubit, g.secondControlQubit, g.targetQubit), (0, 1, 2));
      _expectState(
          _run(ccx), List.filled(8, Complex.zero())..[7] = Complex.one());
      expect(SandboxProgramSnapshot.capture(ccx).encode(),
          isNot(contains('"controls"')));
    });

    test('invalid MCX records fail safely', () {
      String record(String controls, {int target = 3}) =>
          '{"schemaVersion":2,"qubitCount":4,"classicalBitCount":0,'
          '"initialStateLabel":"0000","initialState":[[1,0],[0,0],[0,0],'
          '[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],'
          '[0,0],[0,0],[0,0]],"operations":[{"id":1,"column":0,'
          '"kind":"unitary","gateType":"mcx","target":$target'
          '$controls,"isDeletable":true}]}';
      for (final bad in [
        '', // no controls
        ',"controls":[0,1]', // too few
        ',"controls":[0,1,1]', // duplicate
        ',"controls":[0,1,3]', // target among controls
        ',"controls":[0,1,"2"]', // not an int
        ',"controls":[0,1,2],"control":0', // mixed shapes
      ]) {
        expect(
            () => SandboxProgramSnapshot.decode(record(bad)),
            throwsA(
                anyOf(isA<FormatException>(), isA<InvalidCircuitProgram>())),
            reason: bad);
      }
      expect(
          SandboxProgramSnapshot.decode(record(',"controls":[0,1,2]'))
              .program
              .operations
              .single,
          isA<UnitaryOperation>());
    });
  });

  // ================================================================ Notebook
  group('Notebook gate reference', () {
    final kb = NotebookKnowledgeBase.instance;

    test('CY and MCX articles are always available with full content', () {
      for (final type in [SelectedGateType.cy, SelectedGateType.mcx]) {
        final article = kb.byId(NotebookArticle.gateId(type))!;
        expect(kb.isAvailable(article, const {}), isTrue);
        final info = GateEducationalCatalog.forType(type)!;
        expect(info.keyIdeas, isNotEmpty);
        expect(info.identities, isNotEmpty);
        expect(article.exampleIds, hasLength(6));
      }
      final mcx = GateEducationalCatalog.forType(SelectedGateType.mcx)!;
      expect(mcx.matrix, isNot(contains('bmatrix')),
          reason: 'a rule, not a 16×16 or 32×32 matrix');
      expect(mcx.keyIdeas.join(), contains('not a measurement'));
    });

    test('every gate-reference example runs on the simulator as authored', () {
      final ids = {...executableNotebookExamplesById.keys};
      for (final example in gateReferenceExamples) {
        expect(ids.add(example.id), isTrue, reason: 'unique ${example.id}');
        expect(example.validate(), isEmpty, reason: example.id);
        final result = example.execute();
        expect(example.resultMatchesExpected(result.state), isTrue,
            reason: example.id);
        for (final g in result.circuit.logicalGates) {
          expect(g.hasValidTopology(example.qubitCount), isTrue);
        }
      }
      for (final MapEntry(key: type, value: list)
          in notebookGateExampleIds.entries) {
        for (final id in list) {
          final example = notebookExampleById(id);
          expect(example, isNotNull, reason: id);
          expect(example!.operations.any((op) => op.gateType == type), isTrue,
              reason: '$id uses ${type.name}');
        }
      }
    });

    testWidgets('MCX experiment: authored topology, inspector, reset, return',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1000);
      addTearDown(tester.view.reset);
      final progress =
          CampaignProgressController(store: InMemoryCampaignProgressStore());
      await progress.load();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WebNotebookWorkspace(
            progressController: progress,
            onOpenJourney: () {},
            requestedArticleId: 'gate-mcx',
            requestSerial: 1,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('web-notebook-gate-key-ideas')),
          findsOneWidget);
      final explore =
          find.byKey(const ValueKey('notebook-explore-mcx_four_controls'));
      await tester.ensureVisible(explore);
      await tester.pumpAndSettle();
      await tester.tap(explore);
      await tester.pumpAndSettle();
      final state = tester
          .state<WebNotebookWorkspaceState>(find.byType(WebNotebookWorkspace));
      final session = state.experimentSession!;
      final gate = session.circuit.logicalGates.single;
      expect(gate.controlQubits, [0, 1, 3, 4]);
      expect(gate.targetQubit, 2);
      session.select(gate.id);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('composer-inspector-topology')))
              .data,
          '4 controls: q0, q1, q3, q4  ·  Target: q2');
      // Edit, then reset to the authored circuit.
      session.deleteOperation(gate.id);
      expect(session.circuit.logicalGates, isEmpty);
      session.clear();
      await tester.pumpAndSettle();
      expect(session.circuit.logicalGates.single.controlQubits, [0, 1, 3, 4]);
      expect(progress.unlockedDiscoveryTitles(), isEmpty);
      await tester.tap(find.byKey(const ValueKey('notebook-experiment-back')));
      await tester.pumpAndSettle();
      expect(state.selectedArticleId, 'gate-mcx');
      expect(tester.takeException(), isNull);
    });
  });

  // ============================================================== chooser
  group('MCX placement chooser', () {
    testWidgets('preselects, summarises and blocks invalid topologies',
        (tester) async {
      List<int>? chosen;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => chosen =
                await showMultiControlledPlacementDialog(context,
                    targetQubit: 1, numQubits: 5),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      Text topology() =>
          tester.widget<Text>(find.byKey(const ValueKey('mcx-topology')));
      expect(topology().data, 'Controls: q0, q2, q3, q4 · Target: q1');
      await tester.tap(find.byKey(const ValueKey('mcx-control-q4')));
      await tester.pump();
      expect(topology().data, 'Controls: q0, q2, q3 · Target: q1');
      await tester.tap(find.byKey(const ValueKey('mcx-control-q3')));
      await tester.pump();
      expect(find.byKey(const ValueKey('mcx-invalid')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mcx-place')));
      await tester.pump();
      expect(find.byKey(const ValueKey('mcx-topology')), findsOneWidget,
          reason: 'Place is disabled with two controls');
      await tester.tap(find.byKey(const ValueKey('mcx-control-q4')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('mcx-place')));
      await tester.pumpAndSettle();
      expect(chosen, [0, 2, 4]);
    });
  });
}
