import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  const singleTypes = [
    SelectedGateType.x,
    SelectedGateType.y,
    SelectedGateType.z,
    SelectedGateType.hadamard,
    SelectedGateType.s,
    SelectedGateType.t,
    SelectedGateType.rx,
    SelectedGateType.ry,
    SelectedGateType.rz,
  ];
  const controlledTypes = [
    SelectedGateType.cnot,
    SelectedGateType.cz,
    SelectedGateType.ccnot,
  ];

  Gate configuredGate(SelectedGateType type, {double angle = math.pi / 4}) =>
      Gate.fromIdentifier(
        type,
        angle: const {
          SelectedGateType.rx,
          SelectedGateType.ry,
          SelectedGateType.rz,
        }.contains(type)
            ? angle
            : null,
      );

  QuantumCircuit circuit({int qubits = 5}) => QuantumCircuit(
        currentLevel: ComposerLevel(
          taskDescription: '2.1 release hardening',
          numQubits: qubits,
          initialQubitsStateStr: '0' * qubits,
          initialQubitsState: ComposerLevel.getZeroStateVector(qubits),
          availableGates: [
            ...singleTypes.map(configuredGate),
            ...controlledTypes.map(Gate.fromIdentifier),
          ],
          solutionFinalVector: const [],
        ),
      );

  CircuitEditOutcome insertControlled(
    QuantumCircuit model,
    SelectedGateType type, {
    int column = 0,
    int target = 4,
    int control = 0,
    int control2 = 2,
    bool isDeletable = true,
  }) {
    if (type == SelectedGateType.ccnot) {
      return model.insertTripleGateWithOutcome(
        Gate.fromIdentifier(type),
        column,
        target,
        control,
        control2,
        isDeletable: isDeletable,
      );
    }
    return model.insertDoubleGateWithOutcome(
      Gate.fromIdentifier(type),
      column,
      target,
      control,
      isDeletable: isDeletable,
    );
  }

  void expectReleaseInvariants(QuantumCircuit model) {
    final nonEmpty = model.placedGates
        .expand((row) => row)
        .where((cell) => cell.gate.type != SelectedGateType.none)
        .toList(growable: false);
    expect(
        nonEmpty,
        everyElement(predicate<PlacedQuantumGate>(
          (cell) => cell.id != null,
          'every non-empty cell has a GateId',
        )));
    final ids = nonEmpty.map((cell) => cell.id!).toSet();
    expect(model.logicalGates.map((gate) => gate.id).toSet(), ids);
    for (final footprint in model.logicalGates) {
      expect(
        footprint.hasValidTopology(model.currentLevel.numQubits),
        isTrue,
        reason: 'Malformed footprint ${footprint.id} (${footprint.type})',
      );
      expect(
        footprint.fragments.map((part) => part.placedGate.id).toSet(),
        {footprint.id},
      );
      expect(
        footprint.fragments.map((part) => part.location.column).toSet(),
        hasLength(1),
      );
    }
  }

  List<List<PlacedQuantumGate>> copyRows(QuantumCircuit model) =>
      model.placedGates
          .map((row) => List<PlacedQuantumGate>.from(row))
          .toList(growable: false);

  void expectRowsEqual(
    List<List<PlacedQuantumGate>> actual,
    List<List<PlacedQuantumGate>> expected,
  ) {
    expect(actual, hasLength(expected.length));
    for (var row = 0; row < actual.length; row++) {
      expect(listEquals(actual[row], expected[row]), isTrue,
          reason: 'row $row differs');
    }
  }

  group('A. PRESERVED PRODUCTION CONTRACT', () {
    test('insert, logical delete, compaction, and clear retain identity rules',
        () {
      final model = circuit();
      final first = model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.hadamard),
        0,
        0,
      );
      final second = model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.x),
        1,
        0,
      );
      final neighbour = model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.z),
        1,
        3,
      );
      expectReleaseInvariants(model);
      final secondId = second.affectedGateId!;
      final neighbourId = neighbour.affectedGateId!;

      expect(
        model.removeLogicalGateByIdWithOutcome(first.affectedGateId!).status,
        CircuitEditStatus.changed,
      );
      expect(model.logicalGateById(secondId)!.id, secondId);
      expect(model.logicalGateById(neighbourId)!.id, neighbourId);
      expectReleaseInvariants(model);
      expect(model.clearPlacedGatesWithOutcome().status,
          CircuitEditStatus.changed);
      expect(
          model.clearPlacedGatesWithOutcome().status, CircuitEditStatus.same);
      expect(model.logicalGates, isEmpty);
    });

    test('malformed controlled metadata blocks simulation without throwing',
        () {
      final model = circuit(qubits: 2);
      model.placedGates[0].add(PlacedQuantumGate(
        id: const GateId(9001),
        gate: Gate.fromIdentifier(SelectedGateType.cnot),
        isControl: true,
      ));
      expect(model.runSimulation, returnsNormally);
      expect(model.lastSimulationError, isNotNull);
      expect(model.lastSimulationError!.parameterName, 'logical footprint');
      expect(model.lastSimulationError!.userMessage, contains('incomplete'));
    });

    test('reset restores protected gates with one structural notification', () {
      final level = ComposerLevel(
        taskDescription: 'protected reset',
        numQubits: 2,
        initialQubitsStateStr: '00',
        initialQubitsState: ComposerLevel.getZeroStateVector(2),
        availableGates: [configuredGate(SelectedGateType.hadamard)],
        solutionFinalVector: const [],
        preInsertedGates: (model) {
          model.insertSinglePlacedGateAt(
            configuredGate(SelectedGateType.x),
            0,
            0,
            isDeletable: false,
          );
          model.insertSinglePlacedGateAt(
            configuredGate(SelectedGateType.z),
            0,
            1,
            isDeletable: false,
          );
        },
      );
      final model = QuantumCircuit(currentLevel: level);
      model.insertSinglePlacedGateAt(
        configuredGate(SelectedGateType.hadamard),
        1,
        0,
      );
      var notifications = 0;
      model.addListener(() => notifications++);
      expect(model.clearPlacedGatesWithOutcome().status,
          CircuitEditStatus.changed);
      expect(notifications, 1);
      expect(model.logicalGates, hasLength(2));
      expect(model.logicalGates.every((gate) => !gate.isDeletable), isTrue);
      expectReleaseInvariants(model);
    });
  });

  group('B. QUBIT QUEST 2.1 FEATURE CONTRACT', () {
    for (final type in singleTypes) {
      test('$type insert/move/duplicate/replace/delete operation matrix', () {
        final model = circuit();
        final insertion = model.insertSingleGateWithOutcome(
          configuredGate(type),
          0,
          0,
        );
        expect(insertion.status, CircuitEditStatus.changed);
        final sourceId = insertion.affectedGateId!;
        expectReleaseInvariants(model);

        final movePlan = model.planLogicalGateMove(
          sourceId,
          const CircuitLocation(qubit: 1, column: 0),
        );
        expect(movePlan.status, CircuitEditStatus.changed);
        expect(model.logicalGateById(sourceId)!.anchor.qubit, 0);
        var notifications = 0;
        model.addListener(() => notifications++);
        expect(model.commitLogicalGateMovePlan(movePlan).status,
            CircuitEditStatus.changed);
        expect(notifications, 1);
        expect(model.logicalGateById(sourceId)!.id, sourceId);
        expectReleaseInvariants(model);

        final duplicate = model.duplicateLogicalGateWithOutcome(sourceId);
        expect(duplicate.status, CircuitEditStatus.changed);
        final duplicateId = duplicate.affectedGateId!;
        expect(duplicateId, isNot(sourceId));
        if (configuredGate(type).requiresAngle) {
          expect(model.logicalGateById(duplicateId)!.gate.angle, math.pi / 4);
        }
        expectReleaseInvariants(model);

        final replacement = model.replaceSingleGateWithOutcome(
          sourceId,
          configuredGate(
            type == SelectedGateType.x
                ? SelectedGateType.hadamard
                : SelectedGateType.x,
          ),
        );
        expect(replacement.status, CircuitEditStatus.changed);
        expect(model.logicalGateById(sourceId)!.id, sourceId);
        expect(model.logicalGateById(duplicateId)!.type, type);
        expectReleaseInvariants(model);

        expect(model.removeLogicalGateByIdWithOutcome(sourceId).status,
            CircuitEditStatus.changed);
        expect(model.logicalGateById(sourceId), isNull);
        expect(model.logicalGateById(duplicateId), isNotNull);
        expectReleaseInvariants(model);
      });
    }

    for (final type in controlledTypes) {
      test('$type rigid move/duplicate/delete operation matrix', () {
        final model = circuit();
        final insertion = insertControlled(
          model,
          type,
          target: 3,
          control: 0,
          control2: 1,
        );
        final sourceId = insertion.affectedGateId!;
        final before = model.logicalGateById(sourceId)!;
        expectReleaseInvariants(model);

        final plan = model.planLogicalGateMove(
          sourceId,
          const CircuitLocation(qubit: 4, column: 0),
        );
        expect(plan.status, CircuitEditStatus.changed);
        expect(model.commitLogicalGateMovePlan(plan).status,
            CircuitEditStatus.changed);
        final moved = model.logicalGateById(sourceId)!;
        expect(moved.id, sourceId);
        expect(
          moved.fragments
              .map((part) => part.location.qubit - moved.anchor.qubit),
          before.fragments
              .map((part) => part.location.qubit - before.anchor.qubit),
        );
        expectReleaseInvariants(model);

        final duplicate = model.duplicateLogicalGateWithOutcome(sourceId);
        expect(duplicate.status, CircuitEditStatus.changed);
        final copy = model.logicalGateById(duplicate.affectedGateId!)!;
        expect(copy.id, isNot(sourceId));
        expect(copy.controlQubit, moved.controlQubit);
        expect(copy.secondControlQubit, moved.secondControlQubit);
        expect(copy.targetQubit, moved.targetQubit);
        expectReleaseInvariants(model);

        expect(model.removeLogicalGateByIdWithOutcome(sourceId).status,
            CircuitEditStatus.changed);
        expect(model.logicalGateById(sourceId), isNull);
        expect(model.logicalGateById(copy.id), isNotNull);
        expectReleaseInvariants(model);
      });
    }

    test('rotation parameters remain independent through chained abuse', () {
      final model = circuit();
      for (final type in [
        SelectedGateType.rx,
        SelectedGateType.ry,
        SelectedGateType.rz,
      ]) {
        for (final angle in [
          0.0,
          math.pi / 4,
          math.pi / 2,
          math.pi,
          -math.pi / 3,
          0.731,
        ]) {
          final source = model.insertSingleGateWithOutcome(
            configuredGate(type, angle: angle),
            model.maxCircuitDepth(),
            0,
          );
          final copy = model.duplicateLogicalGateWithOutcome(
            source.affectedGateId!,
          );
          expect(
            model
                .updateGateParametersWithOutcome(
                  copy.affectedGateId!,
                  angle: angle + 0.125,
                )
                .status,
            CircuitEditStatus.changed,
          );
          expect(
              model.logicalGateById(source.affectedGateId!)!.gate.angle, angle);
          expect(model.logicalGateById(copy.affectedGateId!)!.gate.angle,
              angle + 0.125);
          expectReleaseInvariants(model);
        }
      }
      expect(
          model
              .updateGateParametersWithOutcome(
                model.logicalGates.first.id,
                angle: double.nan,
              )
              .status,
          CircuitEditStatus.invalid);
    });

    test('planner is detached, commit-exact, and stale-plan safe', () {
      final model = circuit();
      final source = model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.hadamard),
        0,
        0,
      );
      model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.x),
        1,
        0,
      );
      final before = copyRows(model);
      final simulationsBefore = model.simulationRunCount;
      var notifications = 0;
      model.addListener(() => notifications++);
      final plan = model.planLogicalGateMove(
        source.affectedGateId!,
        const CircuitLocation(qubit: 0, column: 1),
      );
      expect(plan.status, CircuitEditStatus.changed);
      expectRowsEqual(model.placedGates, before);
      expect(notifications, 0);
      expect(model.simulationRunCount, simulationsBefore);
      expect(model.commitLogicalGateMovePlan(plan).status,
          CircuitEditStatus.changed);
      expectRowsEqual(model.placedGates, plan.proposedRows!);
      expect(notifications, 1);
      expectReleaseInvariants(model);

      final stale = model.planLogicalGateMove(
        source.affectedGateId!,
        const CircuitLocation(qubit: 1, column: 0),
      );
      model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.z),
        model.maxCircuitDepth(),
        4,
      );
      final changed = copyRows(model);
      expect(model.commitLogicalGateMovePlan(stale).status,
          CircuitEditStatus.cancelled);
      expectRowsEqual(model.placedGates, changed);
    });

    test('deterministic generated edit sequence preserves all invariants', () {
      final model = circuit();
      final random = math.Random(210);
      for (var step = 0; step < 75; step++) {
        final gates = model.logicalGates;
        if (gates.isEmpty || random.nextInt(4) == 0) {
          final type = singleTypes[random.nextInt(singleTypes.length)];
          model.insertSingleGateWithOutcome(
            configuredGate(type, angle: (random.nextInt(9) - 4) * math.pi / 4),
            model.maxCircuitDepth(),
            random.nextInt(5),
          );
        } else {
          final selected = gates[random.nextInt(gates.length)];
          switch (random.nextInt(4)) {
            case 0:
              model.commitLogicalGateMovePlan(model.planLogicalGateMove(
                selected.id,
                CircuitLocation(
                  qubit: random.nextInt(5),
                  column: random.nextInt(model.maxCircuitDepth() + 1),
                ),
              ));
              break;
            case 1:
              model.duplicateLogicalGateWithOutcome(selected.id);
              break;
            case 2:
              if (selected.isSingleQubit) {
                model.replaceSingleGateWithOutcome(
                  selected.id,
                  configuredGate(
                      singleTypes[random.nextInt(singleTypes.length)]),
                );
              }
              break;
            case 3:
              model.removeLogicalGateByIdWithOutcome(selected.id);
              break;
          }
        }
        expectReleaseInvariants(model);
        expect(model.runSimulation, returnsNormally);
      }
    });
  });

  group('C. BUG REGRESSIONS', () {
    test('occupied CCNOT insertion retains every connector across extrema', () {
      final model = circuit();
      model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.x),
        0,
        3,
      );
      final result = insertControlled(
        model,
        SelectedGateType.ccnot,
        target: 0,
        control: 1,
        control2: 4,
      );
      expect(result.status, CircuitEditStatus.changed);
      final footprint = model.logicalGateById(result.affectedGateId!)!;
      expect(footprint.fragments, hasLength(5));
      expect(footprint.fragments.map((part) => part.location.qubit).toSet(),
          {0, 1, 2, 3, 4});
      expect(
        footprint.fragments
            .where((part) => part.placedGate.isLink)
            .map((part) => part.location.qubit)
            .toSet(),
        {2, 3},
      );
      expectReleaseInvariants(model);
      expect(model.runSimulation, returnsNormally);
      expect(model.lastSimulationError, isNull);
    });

    test('Z-T-S-Z / Z-Z move leaves aligned lower Z stationary', () {
      final model = circuit(qubits: 4);
      for (final type in [
        SelectedGateType.z,
        SelectedGateType.t,
        SelectedGateType.s,
        SelectedGateType.z,
      ]) {
        model.insertSingleGateWithOutcome(
          configuredGate(type),
          model.placedGates[2].length,
          2,
        );
      }
      final lowerFirst = model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.z),
        0,
        3,
      );
      final lowerSecond = model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.z),
        1,
        3,
      );
      final source = model.logicalGates.singleWhere(
        (gate) => gate.type == SelectedGateType.s && gate.anchor.qubit == 2,
      );
      final lowerBefore = {
        lowerFirst.affectedGateId!: model
            .logicalGateById(
              lowerFirst.affectedGateId!,
            )!
            .anchor,
        lowerSecond.affectedGateId!: model
            .logicalGateById(
              lowerSecond.affectedGateId!,
            )!
            .anchor,
      };
      final plan = model.planLogicalGateMove(
        source.id,
        const CircuitLocation(qubit: 2, column: 1),
      );
      expect(plan.status, CircuitEditStatus.changed);
      expect(model.commitLogicalGateMovePlan(plan).status,
          CircuitEditStatus.changed);
      for (final entry in lowerBefore.entries) {
        expect(model.logicalGateById(entry.key)!.anchor, entry.value);
      }
      expectReleaseInvariants(model);
    });

    test('protected content rejects movement and duplication atomically', () {
      final model = circuit(qubits: 2);
      final source = model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.hadamard),
        0,
        0,
      );
      final protected = model.insertSingleGateWithOutcome(
        configuredGate(SelectedGateType.x),
        1,
        0,
        isDeletable: false,
      );
      final before = copyRows(model);
      expect(
          model
              .planLogicalGateMove(
                source.affectedGateId!,
                const CircuitLocation(qubit: 0, column: 1),
              )
              .status,
          CircuitEditStatus.protected);
      expect(
          model.duplicateLogicalGateWithOutcome(source.affectedGateId!).status,
          CircuitEditStatus.protected);
      expectRowsEqual(model.placedGates, before);
      expect(
          model.logicalGateById(protected.affectedGateId!)!.anchor.column, 1);
      expectReleaseInvariants(model);
    });
  });
}
