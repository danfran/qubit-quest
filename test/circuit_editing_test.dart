import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  QuantumCircuit circuit(int qubits) => QuantumCircuit(
        currentLevel: ComposerLevel(
          taskDescription: 'editing test',
          numQubits: qubits,
          initialQubitsStateStr: '0' * qubits,
          initialQubitsState: ComposerLevel.getZeroStateVector(qubits),
          availableGates: const [],
          solutionFinalVector: const [],
        ),
      );

  void expectCanonicallyCompacted(QuantumCircuit model) {
    for (final footprint in model.logicalGates) {
      if (footprint.column == 0 || !footprint.isDeletable) continue;
      final blockedOnLeft = footprint.fragments.any((fragment) {
        final row = model.placedGates[fragment.location.qubit];
        final left = footprint.column - 1;
        return left < row.length &&
            row[left].gate.type != SelectedGateType.none;
      });
      expect(
        blockedOnLeft,
        isTrue,
        reason: '${footprint.type} at column ${footprint.column} can move left',
      );
    }
  }

  group('canonical compaction after logical move', () {
    test('independent learner gate shares a protected gate column', () {
      final model = circuit(2);
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        0,
        isDeletable: false,
      );
      final inserted = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        5,
        1,
      );

      final fixed = model.logicalGates.singleWhere((gate) => !gate.isDeletable);
      final learner = model.logicalGateById(inserted.affectedGateId!)!;
      expect(fixed.column, 0);
      expect(learner.column, 0);
      expect(model.placedGates[0][0].id, fixed.id);
      expect(model.placedGates[1][0].id, learner.id);
      expect(learner.occupiedLocations,
          [const CircuitLocation(qubit: 1, column: 0)]);
      expectCanonicallyCompacted(model);
    });

    test('same-wire insertion preserves order at the earliest legal column',
        () {
      final model = circuit(2);
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        0,
        isDeletable: false,
      );
      final inserted = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        5,
        0,
      );

      expect(model.logicalGateById(inserted.affectedGateId!)!.column, 1);
      expectCanonicallyCompacted(model);
    });

    test('independent gates on multiple wires share earliest legal columns',
        () {
      final model = circuit(4);
      final gates = [
        model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.hadamard),
          0,
          0,
        ),
        model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.x),
          5,
          1,
        ),
        model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.z),
          4,
          2,
        ),
        model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.s),
          3,
          3,
        ),
      ];

      expect(
        gates.map((outcome) =>
            model.logicalGateById(outcome.affectedGateId!)!.column),
        everyElement(0),
      );
      expectCanonicallyCompacted(model);
    });

    for (final gateType in [
      SelectedGateType.cnot,
      SelectedGateType.cz,
    ]) {
      test('$gateType insertion compacts as a rigid footprint', () {
        final model = circuit(3);
        model.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x),
          0,
          2,
          isDeletable: false,
        );
        final inserted = model.insertDoubleGateWithOutcome(
          Gate.fromIdentifier(gateType),
          5,
          1,
          0,
        );

        final footprint = model.logicalGateById(inserted.affectedGateId!)!;
        expect(footprint.column, 0);
        expect(footprint.controlQubit, 0);
        expect(footprint.targetQubit, 1);
        expect(
          footprint.fragments.map((fragment) => fragment.location.column),
          everyElement(0),
        );
        expectCanonicallyCompacted(model);
      });
    }

    test('CCNOT insertion compacts as one rigid footprint', () {
      final model = circuit(4);
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        3,
        isDeletable: false,
      );
      final inserted = model.insertTripleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.ccnot),
        5,
        2,
        0,
        1,
      );

      final footprint = model.logicalGateById(inserted.affectedGateId!)!;
      expect(footprint.column, 0);
      expect(footprint.hasValidTopology(4), isTrue);
      expect(
        footprint.fragments.map((fragment) => fragment.location.column),
        everyElement(0),
      );
      expectCanonicallyCompacted(model);
    });

    test('deletion reflows remaining gates without crossing wire blockers', () {
      final model = circuit(2);
      final first = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      final second = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        1,
        0,
      );
      final independent = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.z),
        5,
        1,
      );

      expect(model.logicalGateById(second.affectedGateId!)!.column, 1);
      expect(model.logicalGateById(independent.affectedGateId!)!.column, 0);
      expect(
          model.removeLogicalGateByIdWithOutcome(first.affectedGateId!).changed,
          isTrue);
      expect(model.logicalGateById(second.affectedGateId!)!.column, 0);
      expect(model.logicalGateById(independent.affectedGateId!)!.column, 0);
      expectCanonicallyCompacted(model);
    });

    test('single gate cannot leave a removable right-side gap', () {
      final model = circuit(2);
      model.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      model.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 1, 0);
      model.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 2, 0);
      final z = model.logicalGates
          .singleWhere((gate) => gate.type == SelectedGateType.z);
      final outcome = model.moveSingleGateWithOutcome(
        z.id,
        const CircuitLocation(qubit: 1, column: 2),
      );

      expect(outcome.changed, isTrue);
      expect(model.logicalGateById(z.id)!.anchor,
          const CircuitLocation(qubit: 1, column: 0));
      expectCanonicallyCompacted(model);
      model.runSimulation();
      final expected = circuit(2);
      expected.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      expected.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 1, 0);
      expected.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 1);
      expected.runSimulation();
      expect(
          model.currentState.state.almostEqualTo(expected.currentState.state),
          isTrue);
    });

    test('CX compacts as one rigid logical footprint', () {
      final model = circuit(4);
      final inserted = model.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.cnot),
        0,
        1,
        0,
      );
      model.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 1, 3);
      model.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 3);

      final outcome = model.commitLogicalGateMovePlan(
        model.planLogicalGateMove(
          inserted.affectedGateId!,
          const CircuitLocation(qubit: 2, column: 2),
        ),
      );

      expect(outcome.changed, isTrue);
      final moved = model.logicalGateById(inserted.affectedGateId!)!;
      expect(moved.column, 0);
      expect(moved.controlQubit, 1);
      expect(moved.targetQubit, 2);
      expect(moved.fragments.map((fragment) => fragment.placedGate.id).toSet(),
          {moved.id});
      expect(moved.hasValidTopology(4), isTrue);
      expectCanonicallyCompacted(model);
      model.runSimulation();
      final expected = circuit(4);
      expected.insertDoubleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 2, 1);
      expected.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 3);
      expected.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 1, 3);
      expected.runSimulation();
      expect(
          model.currentState.state.almostEqualTo(expected.currentState.state),
          isTrue);
    });

    test('CCNOT compacts all fragments without changing topology', () {
      final model = circuit(6);
      final inserted = model.insertTripleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.ccnot),
        0,
        2,
        0,
        1,
      );
      model.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 1, 5);
      model.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 5);

      final outcome = model.commitLogicalGateMovePlan(
        model.planLogicalGateMove(
          inserted.affectedGateId!,
          const CircuitLocation(qubit: 4, column: 2),
        ),
      );

      expect(outcome.changed, isTrue);
      final moved = model.logicalGateById(inserted.affectedGateId!)!;
      expect(moved.column, 0);
      expect(moved.controlQubit, 2);
      expect(moved.secondControlQubit, 3);
      expect(moved.targetQubit, 4);
      expect(moved.fragments.map((fragment) => fragment.placedGate.id).toSet(),
          {moved.id});
      expect(moved.hasValidTopology(6), isTrue);
      expectCanonicallyCompacted(model);
      model.runSimulation();
      final expected = circuit(6);
      expected.insertTripleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.ccnot), 0, 4, 2, 3);
      expected.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 5);
      expected.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 1, 5);
      expected.runSimulation();
      expect(
          model.currentState.state.almostEqualTo(expected.currentState.state),
          isTrue);
    });

    test('mixed moved circuit remains compact after every commit', () {
      final model = circuit(6);
      model.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      final rotation = model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 7), 1, 0);
      final cx = model.insertDoubleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 1);
      final ccnot = model.insertTripleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.ccnot), 3, 4, 1, 3);
      model.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 4, 5);
      model.runSimulation();

      final outcome = model.commitLogicalGateMovePlan(
        model.planLogicalGateMove(
          rotation.affectedGateId!,
          CircuitLocation(qubit: 5, column: model.maxCircuitDepth()),
        ),
      );
      expect(outcome.changed, isTrue);
      expect(model.logicalGateById(cx.affectedGateId!)!.hasValidTopology(6),
          isTrue);
      expect(model.logicalGateById(ccnot.affectedGateId!)!.hasValidTopology(6),
          isTrue);
      expectCanonicallyCompacted(model);
      model.runSimulation();
      expect(model.lastSimulationError, isNull);
    });
  });

  group('stable logical gate identity', () {
    test('single insertion allocates a stable non-empty identity', () {
      final model = circuit(1);
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      expect(model.placedGates[0][0].id, isNotNull);
      expect(model.placedGates[0][0].id,
          model.placedGateById(model.placedGates[0][0].id!)!.id);
      expect(PlacedQuantumGate.emptyGate().id, isNull);
    });

    test('controlled fragments share one identity', () {
      final model = circuit(3);
      model.insertDoublePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.cnot),
        0,
        2,
        0,
      );
      final ids =
          model.placedGates.expand((row) => row).map((cell) => cell.id).toSet();
      expect(ids, hasLength(1));
      expect(ids.single, isNotNull);
    });

    for (final gateType in [
      SelectedGateType.cnot,
      SelectedGateType.cz,
      SelectedGateType.ccnot,
    ]) {
      test('$gateType fragments share exactly one logical identity', () {
        final model = circuit(4);
        if (gateType == SelectedGateType.ccnot) {
          model.insertTriplePlacedGateAt(
            Gate.fromIdentifier(gateType),
            0,
            3,
            0,
            1,
          );
        } else {
          model.insertDoublePlacedGateAt(
            Gate.fromIdentifier(gateType),
            0,
            3,
            0,
          );
        }
        final fragments = model.placedGates
            .expand((row) => row)
            .where((cell) => cell.gate.type == gateType)
            .toList();
        expect(fragments, isNotEmpty);
        expect(fragments.map((cell) => cell.id).toSet(), hasLength(1));
        expect(fragments.first.id, isNotNull);
      });
    }
  });

  group('atomic logical gate deletion', () {
    for (final gateType in [
      SelectedGateType.cnot,
      SelectedGateType.cz,
      SelectedGateType.ccnot,
    ]) {
      test('removing $gateType by ID removes every fragment and notifies once',
          () {
        final model = circuit(4);
        if (gateType == SelectedGateType.ccnot) {
          model.insertTriplePlacedGateAt(
            Gate.fromIdentifier(gateType),
            0,
            3,
            0,
            1,
          );
        } else {
          model.insertDoublePlacedGateAt(
            Gate.fromIdentifier(gateType),
            0,
            3,
            0,
          );
        }
        final id = model.placedGates
            .expand((row) => row)
            .firstWhere((cell) => cell.gate.type == gateType)
            .id!;
        final before = model.placedGates
            .expand((row) => row)
            .where((cell) => cell.id == id)
            .length;
        expect(before, greaterThan(1));
        var notifications = 0;
        model.addListener(() => notifications++);

        expect(
          model.removeLogicalGateById(id),
          RemoveGateResult.removed,
        );
        expect(
          model.placedGates.expand((row) => row).where((cell) => cell.id == id),
          isEmpty,
        );
        expect(notifications, 1);
      });
    }

    test('protected controlled gate is unchanged and does not notify', () {
      final model = circuit(3);
      model.insertDoublePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.cnot),
        0,
        2,
        0,
        isDeletable: false,
      );
      final id = model.placedGates[0][0].id!;
      final fragmentCount = model.placedGates
          .expand((row) => row)
          .where((cell) => cell.id == id)
          .length;
      var notifications = 0;
      model.addListener(() => notifications++);

      expect(
        model.removeLogicalGateById(id),
        RemoveGateResult.notDeletable,
      );
      expect(
        model.removeSingleGateById(id),
        RemoveGateResult.notSingleQubit,
      );
      expect(
        model.placedGates.expand((row) => row).where((cell) => cell.id == id),
        hasLength(fragmentCount),
      );
      expect(notifications, 0);
    });
  });

  group('atomic single gate editing', () {
    test('move preserves identity and configured rotation angle', () {
      final model = circuit(2);
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
        0,
        0,
      );
      final id = model.placedGates[0][0].id!;
      expect(
        model.moveSingleGate(
          id,
          const CircuitLocation(qubit: 1, column: 0),
        ),
        MoveResult.moved,
      );
      final moved = model.placedGateById(id)!;
      expect(moved.id, id);
      expect(moved.location, const CircuitLocation(qubit: 1, column: 0));
      expect(moved.gate.angle, math.pi / 4);
    });

    test('same slot, invalid, and missing moves do not mutate or notify', () {
      final model = circuit(1);
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        0,
      );
      final id = model.placedGates[0][0].id!;
      var notifications = 0;
      model.addListener(() => notifications++);
      expect(
        model.moveSingleGate(
          id,
          const CircuitLocation(qubit: 0, column: 0),
        ),
        MoveResult.sameSlot,
      );
      expect(
        model.moveSingleGate(
          id,
          const CircuitLocation(qubit: 9, column: 0),
        ),
        MoveResult.invalid,
      );
      expect(
        model.moveSingleGate(
          const GateId(99999),
          const CircuitLocation(qubit: 0, column: 1),
        ),
        MoveResult.notFound,
      );
      expect(notifications, 0);
      expect(model.placedGateById(id)!.location,
          const CircuitLocation(qubit: 0, column: 0));
    });

    test('successful move notifies exactly once', () {
      final model = circuit(2);
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        0,
      );
      final id = model.placedGates[0][0].id!;
      var notifications = 0;
      model.addListener(() => notifications++);
      expect(
        model.moveSingleGate(
          id,
          const CircuitLocation(qubit: 1, column: 0),
        ),
        MoveResult.moved,
      );
      expect(notifications, 1);
    });

    test('non-deletable and controlled gates cannot move', () {
      final model = circuit(2);
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        0,
        isDeletable: false,
      );
      final fixedId = model.placedGates[0][0].id!;
      expect(
        model.moveSingleGate(
          fixedId,
          const CircuitLocation(qubit: 1, column: 0),
        ),
        MoveResult.notMovable,
      );

      model.insertDoublePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.cnot),
        1,
        1,
        0,
      );
      final controlledId = model.placedGates
          .expand((row) => row)
          .firstWhere((cell) => cell.gate.type == SelectedGateType.cnot)
          .id!;
      expect(
        model.moveSingleGate(
          controlledId,
          const CircuitLocation(qubit: 0, column: 2),
        ),
        MoveResult.notMovable,
      );
    });

    test('ID deletion removes and compacts once', () {
      final model = circuit(1);
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        0,
      );
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        1,
        0,
      );
      final removedId = model.placedGates[0][0].id!;
      final remainingId = model.placedGates[0][1].id!;
      var notifications = 0;
      model.addListener(() => notifications++);
      expect(model.removeSingleGateById(removedId), RemoveGateResult.removed);
      expect(model.placedGateById(removedId), isNull);
      expect(model.placedGateById(remainingId)!.location.column, 0);
      expect(notifications, 1);
    });
  });

  group('atomic controlled gate horizontal movement', () {
    CircuitEditOutcome insertControlled(
      QuantumCircuit model,
      SelectedGateType type,
    ) {
      return type == SelectedGateType.ccnot
          ? model.insertTripleGateWithOutcome(
              Gate.fromIdentifier(type),
              0,
              3,
              0,
              1,
            )
          : model.insertDoubleGateWithOutcome(
              Gate.fromIdentifier(type),
              0,
              3,
              0,
            );
    }

    for (final type in [
      SelectedGateType.cnot,
      SelectedGateType.cz,
      SelectedGateType.ccnot,
    ]) {
      test('$type moves as one footprint and notifies once', () {
        final model = circuit(5);
        final inserted = insertControlled(model, type);
        final id = inserted.affectedGateId!;
        model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.hadamard),
          1,
          0,
        );
        final before = model.logicalGateById(id)!;
        final fragmentRoles = before.fragments
            .map((fragment) => (
                  fragment.location.qubit,
                  fragment.placedGate.isControl,
                  fragment.placedGate.isControl2,
                  fragment.placedGate.isTarget,
                  fragment.placedGate.isLink,
                ))
            .toList();
        var notifications = 0;
        model.addListener(() => notifications++);

        final outcome = model.moveLogicalGateHorizontallyWithOutcome(id, 1);
        final after = model.logicalGateById(id)!;
        expect(outcome.status, CircuitEditStatus.changed);
        expect(after.id, id);
        expect(after.column, 1);
        expect(after.type, type);
        expect(after.controlQubit, before.controlQubit);
        expect(after.secondControlQubit, before.secondControlQubit);
        expect(after.targetQubit, before.targetQubit);
        expect(
          after.fragments
              .map((fragment) => (
                    fragment.location.qubit,
                    fragment.placedGate.isControl,
                    fragment.placedGate.isControl2,
                    fragment.placedGate.isTarget,
                    fragment.placedGate.isLink,
                  ))
              .toList(),
          fragmentRoles,
        );
        expect(
            after.fragments.every((fragment) => fragment.location.column == 1),
            isTrue);
        expect(notifications, 1);
      });
    }

    test('same, invalid, protected, and unsupported moves do not notify', () {
      final model = circuit(4);
      final controlled = model.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.cnot),
        0,
        3,
        0,
      );
      final single = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        1,
        3,
      );
      model.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.cz),
        2,
        2,
        0,
        isDeletable: false,
      );
      final protected = model.logicalGates.firstWhere(
        (gate) => gate.type == SelectedGateType.cz,
      );
      var notifications = 0;
      model.addListener(() => notifications++);

      expect(
          model
              .moveLogicalGateHorizontallyWithOutcome(
                controlled.affectedGateId!,
                0,
              )
              .status,
          CircuitEditStatus.same);
      expect(
          model
              .moveLogicalGateHorizontallyWithOutcome(
                controlled.affectedGateId!,
                -1,
              )
              .status,
          CircuitEditStatus.invalid);
      expect(
          model.moveLogicalGateHorizontallyWithOutcome(protected.id, 1).status,
          CircuitEditStatus.protected);
      expect(
          model
              .moveLogicalGateHorizontallyWithOutcome(
                single.affectedGateId!,
                0,
              )
              .status,
          CircuitEditStatus.unsupported);
      expect(notifications, 0);
    });

    test('occupied destination shifts neighbours as one atomic proposal', () {
      final model = circuit(4);
      final controlled = model.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.cnot),
        0,
        3,
        0,
      );
      model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        1,
        1,
      );
      model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.y),
        2,
        1,
      );
      final id = controlled.affectedGateId!;
      final before = model.logicalGateById(id)!.occupiedLocations;
      var notifications = 0;
      model.addListener(() => notifications++);

      expect(model.validateLogicalGateHorizontalMove(id, 1).status,
          CircuitEditStatus.changed);
      expect(model.previewLogicalGateHorizontalMove(id, 1), isNotNull);
      expect(model.moveLogicalGateHorizontallyWithOutcome(id, 1).status,
          CircuitEditStatus.changed);
      expect(
        model.logicalGateById(id)!.occupiedLocations,
        isNot(equals(before)),
      );
      expect(model.logicalGateById(id)!.column, 1);
      expect(notifications, 1);
    });

    test('parameter-edited neighbouring rotation is unaffected', () {
      final model = circuit(5);
      final controlled = insertControlled(model, SelectedGateType.cnot);
      final rotation = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2),
        0,
        4,
      );
      expect(
          model
              .updateGateParametersWithOutcome(
                rotation.affectedGateId!,
                angle: math.pi / 4,
              )
              .status,
          CircuitEditStatus.changed);
      expect(
          model
              .moveLogicalGateHorizontallyWithOutcome(
                controlled.affectedGateId!,
                1,
              )
              .status,
          CircuitEditStatus.changed);
      final neighbour = model.logicalGateById(rotation.affectedGateId!)!;
      expect(neighbour.id, rotation.affectedGateId);
      expect(neighbour.gate.angle, closeTo(math.pi / 4, 1e-12));
    });
  });

  group('unified logical move planning', () {
    List<List<(GateId?, SelectedGateType, bool, bool, bool, bool)>> snapshot(
      List<List<PlacedQuantumGate>> rows,
    ) =>
        rows
            .map(
              (row) => row
                  .map(
                    (cell) => (
                      cell.id,
                      cell.gate.type,
                      cell.isControl,
                      cell.isControl2,
                      cell.isTarget,
                      cell.isLink,
                    ),
                  )
                  .toList(),
            )
            .toList();

    test(
        'single and controlled gates share occupied-column insertion semantics',
        () {
      final singleModel = circuit(2);
      final h = singleModel.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      final x = singleModel.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        1,
        0,
      );
      final z = singleModel.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.z),
        2,
        0,
      );
      final singlePlan = singleModel.planLogicalGateMove(
        z.affectedGateId!,
        const CircuitLocation(qubit: 0, column: 1),
      );
      expect(singlePlan.status, CircuitEditStatus.changed);
      expect(
        singlePlan.proposedRows![0]
            .where((cell) => cell.id != null)
            .map((cell) => cell.id),
        [h.affectedGateId, z.affectedGateId, x.affectedGateId],
      );

      final controlledModel = circuit(3);
      final first = controlledModel.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      final second = controlledModel.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        1,
        0,
      );
      final cx = controlledModel.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.cnot),
        2,
        2,
        0,
      );
      final controlledPlan = controlledModel.planLogicalGateMove(
        cx.affectedGateId!,
        const CircuitLocation(qubit: 2, column: 1),
      );
      expect(controlledPlan.status, CircuitEditStatus.changed);
      final rowIds = controlledPlan.proposedRows![0]
          .where((cell) => cell.id != null)
          .map((cell) => cell.id)
          .toList();
      expect(rowIds,
          [first.affectedGateId, cx.affectedGateId, second.affectedGateId]);
      expect(rowIds.toSet(), hasLength(3));
    });

    for (final type in [
      SelectedGateType.cnot,
      SelectedGateType.cz,
      SelectedGateType.ccnot,
    ]) {
      test('$type proposal is detached, rigid, and commit-exact', () {
        final model = circuit(4);
        model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.hadamard),
          0,
          0,
        );
        final neighbour = model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.x),
          1,
          0,
        );
        final controlled = type == SelectedGateType.ccnot
            ? model.insertTripleGateWithOutcome(
                Gate.fromIdentifier(type),
                2,
                3,
                0,
                1,
              )
            : model.insertDoubleGateWithOutcome(
                Gate.fromIdentifier(type),
                2,
                3,
                0,
              );
        final id = controlled.affectedGateId!;
        final before = snapshot(model.placedGates);
        final neighbourBefore =
            model.logicalGateById(neighbour.affectedGateId!)!;
        var notifications = 0;
        model.addListener(() => notifications++);

        final plan = model.planLogicalGateMove(
          id,
          const CircuitLocation(qubit: 3, column: 1),
        );
        expect(plan.status, CircuitEditStatus.changed);
        expect(notifications, 0);
        expect(snapshot(model.placedGates), before);
        final proposedFragments = [
          for (final (qubit, row) in plan.proposedRows!.indexed)
            for (final (column, cell) in row.indexed)
              if (cell.id == id) (qubit, column, cell),
        ];
        expect(proposedFragments, isNotEmpty);
        expect(proposedFragments.every((fragment) => fragment.$2 == 1), isTrue);
        expect(
            proposedFragments.map((fragment) => fragment.$3.id).toSet(), {id});

        expect(model.commitLogicalGateMovePlan(plan).status,
            CircuitEditStatus.changed);
        expect(notifications, 1);
        expect(snapshot(model.placedGates), snapshot(plan.proposedRows!));
        final moved = model.logicalGateById(id)!;
        expect(moved.column, 1);
        expect(moved.controlQubit, isNotNull);
        expect(
          model.logicalGateById(neighbour.affectedGateId!)!.id,
          neighbourBefore.id,
        );
      });
    }

    test('protected obstacle rejects the entire detached proposal', () {
      final model = circuit(3);
      model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        1,
        0,
        isDeletable: false,
      );
      final cx = model.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.cnot),
        2,
        2,
        0,
      );
      final before = snapshot(model.placedGates);
      var notifications = 0;
      model.addListener(() => notifications++);

      final plan = model.planLogicalGateMove(
        cx.affectedGateId!,
        const CircuitLocation(qubit: 2, column: 1),
      );
      expect(plan.status, CircuitEditStatus.protected);
      expect(plan.proposedRows, isNull);
      expect(model.commitLogicalGateMovePlan(plan).status,
          CircuitEditStatus.protected);
      expect(snapshot(model.placedGates), before);
      expect(notifications, 0);
    });

    test('moving S before T leaves an aligned lower-row Z stationary', () {
      final model = circuit(4);
      final upper = <CircuitEditOutcome>[];
      for (final type in [
        SelectedGateType.z,
        SelectedGateType.t,
        SelectedGateType.s,
        SelectedGateType.z,
      ]) {
        upper.add(model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(type),
          upper.length,
          2,
        ));
      }
      model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.z),
        0,
        3,
      );
      final unaffected = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.z),
        1,
        3,
      );
      final unaffectedId = unaffected.affectedGateId!;
      final beforeRows = snapshot(model.placedGates);
      var notifications = 0;
      model.addListener(() => notifications++);

      final plan = model.planLogicalGateMove(
        upper[2].affectedGateId!,
        const CircuitLocation(qubit: 2, column: 1),
      );
      expect(plan.status, CircuitEditStatus.changed);
      expect(notifications, 0);
      expect(snapshot(model.placedGates), beforeRows);
      expect(
        plan.proposedRows![2]
            .where((gate) => gate.id != null)
            .map((gate) => gate.gate.type),
        [
          SelectedGateType.z,
          SelectedGateType.s,
          SelectedGateType.t,
          SelectedGateType.z,
        ],
      );
      final proposedUnaffectedLocations = [
        for (final (qubit, row) in plan.proposedRows!.indexed)
          for (final (column, gate) in row.indexed)
            if (gate.id == unaffectedId)
              CircuitLocation(qubit: qubit, column: column),
      ];
      expect(
        proposedUnaffectedLocations,
        [const CircuitLocation(qubit: 3, column: 1)],
      );

      expect(model.commitLogicalGateMovePlan(plan).status,
          CircuitEditStatus.changed);
      expect(model.logicalGateById(unaffectedId)!.anchor,
          const CircuitLocation(qubit: 3, column: 1));
      expect(snapshot(model.placedGates), snapshot(plan.proposedRows!));
      expect(notifications, 1);
    });

    test('controlled collision shifts the complete conflicting footprint only',
        () {
      final model = circuit(5);
      model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        4,
      );
      model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        1,
      );
      model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        1,
        0,
      );
      final unaffected = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.z),
        1,
        4,
      );
      final cz = model.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.cz),
        1,
        3,
        1,
      );
      final cx = model.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.cnot),
        2,
        2,
        0,
      );
      final czBefore = model.logicalGateById(cz.affectedGateId!)!;
      final plan = model.planLogicalGateMove(
        cx.affectedGateId!,
        const CircuitLocation(qubit: 2, column: 1),
      );
      expect(plan.status, CircuitEditStatus.changed);

      expect(model.commitLogicalGateMovePlan(plan).status,
          CircuitEditStatus.changed);
      final movedCx = model.logicalGateById(cx.affectedGateId!)!;
      final displacedCz = model.logicalGateById(cz.affectedGateId!)!;
      expect(movedCx.column, 1);
      expect(displacedCz.column, 2);
      expect(displacedCz.id, czBefore.id);
      expect(displacedCz.controlQubit, czBefore.controlQubit);
      expect(displacedCz.targetQubit, czBefore.targetQubit);
      expect(model.logicalGateById(unaffected.affectedGateId!)!.anchor,
          const CircuitLocation(qubit: 4, column: 1));
    });
  });

  group('rigid two-dimensional logical movement', () {
    CircuitEditOutcome insertDouble(
      QuantumCircuit model,
      SelectedGateType type, {
      required int control,
      required int target,
      int column = 0,
    }) =>
        model.insertDoubleGateWithOutcome(
          Gate.fromIdentifier(type),
          column,
          target,
          control,
        );

    test('CX q2-q4 translates rigidly to q0-q2 and preserves identity', () {
      final model = circuit(5);
      final inserted = insertDouble(
        model,
        SelectedGateType.cnot,
        control: 2,
        target: 4,
      );
      final id = inserted.affectedGateId!;
      final before = model.logicalGateById(id)!;
      final offsets = before.fragments
          .map((fragment) => fragment.location.qubit - before.anchor.qubit)
          .toList();
      var notifications = 0;
      model.addListener(() => notifications++);

      final plan = model.planLogicalGateMove(
        id,
        const CircuitLocation(qubit: 2, column: 0),
      );
      expect(plan.status, CircuitEditStatus.changed);
      expect(notifications, 0);
      expect(model.logicalGateById(id)!.controlQubit, 2);
      expect(model.commitLogicalGateMovePlan(plan).status,
          CircuitEditStatus.changed);
      final moved = model.logicalGateById(id)!;
      expect(moved.id, id);
      expect(moved.controlQubit, 0);
      expect(moved.targetQubit, 2);
      expect(
        moved.fragments
            .map((fragment) => fragment.location.qubit - moved.anchor.qubit),
        offsets,
      );
      expect(moved.fragments.map((fragment) => fragment.location.qubit),
          [0, 1, 2]);
      expect(notifications, 1);
      expect(
        [
          for (final row in plan.proposedRows!)
            for (final gate in row)
              if (gate.id == id) gate,
        ],
        hasLength(3),
      );
    });

    test('CX q0-q2 translates downward to q1-q3', () {
      final model = circuit(4);
      final inserted = insertDouble(
        model,
        SelectedGateType.cnot,
        control: 0,
        target: 2,
      );
      final outcome = model.moveSingleGateWithOutcome(
        inserted.affectedGateId!,
        const CircuitLocation(qubit: 3, column: 0),
      );
      expect(outcome.status, CircuitEditStatus.unsupported);
      final plan = model.planLogicalGateMove(
        inserted.affectedGateId!,
        const CircuitLocation(qubit: 3, column: 0),
      );
      expect(model.commitLogicalGateMovePlan(plan).status,
          CircuitEditStatus.changed);
      final moved = model.logicalGateById(inserted.affectedGateId!)!;
      expect(moved.controlQubit, 1);
      expect(moved.targetQubit, 3);
    });

    test('CZ and CCNOT preserve every relative row offset', () {
      final czModel = circuit(5);
      final cz = insertDouble(
        czModel,
        SelectedGateType.cz,
        control: 1,
        target: 3,
      );
      expect(
        czModel
            .commitLogicalGateMovePlan(
              czModel.planLogicalGateMove(
                cz.affectedGateId!,
                const CircuitLocation(qubit: 2, column: 0),
              ),
            )
            .status,
        CircuitEditStatus.changed,
      );
      expect(czModel.logicalGateById(cz.affectedGateId!)!.controlQubit, 0);
      expect(czModel.logicalGateById(cz.affectedGateId!)!.targetQubit, 2);

      final toffoliModel = circuit(6);
      final toffoli = toffoliModel.insertTripleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.ccnot),
        0,
        4,
        1,
        3,
      );
      final before = toffoliModel.logicalGateById(toffoli.affectedGateId!)!;
      final beforeOffsets = before.fragments
          .map((fragment) => fragment.location.qubit - before.anchor.qubit)
          .toList();
      final plan = toffoliModel.planLogicalGateMove(
        toffoli.affectedGateId!,
        const CircuitLocation(qubit: 5, column: 1),
      );
      expect(plan.status, CircuitEditStatus.changed);
      expect(toffoliModel.commitLogicalGateMovePlan(plan).status,
          CircuitEditStatus.changed);
      final moved = toffoliModel.logicalGateById(toffoli.affectedGateId!)!;
      expect(moved.controlQubit, 2);
      expect(moved.secondControlQubit, 4);
      expect(moved.targetQubit, 5);
      expect(
        moved.fragments
            .map((fragment) => fragment.location.qubit - moved.anchor.qubit),
        beforeOffsets,
      );
      expect(moved.column, 0);
    });

    test('top and bottom boundary failures are detached and atomic', () {
      final model = circuit(5);
      final cx = insertDouble(
        model,
        SelectedGateType.cnot,
        control: 2,
        target: 4,
      );
      final before = model.logicalGateById(cx.affectedGateId!)!;
      var notifications = 0;
      model.addListener(() => notifications++);

      final above = model.planLogicalGateMove(
        before.id,
        const CircuitLocation(qubit: 1, column: 0),
      );
      final below = model.planLogicalGateMove(
        before.id,
        const CircuitLocation(qubit: 5, column: 0),
      );
      expect(above.status, CircuitEditStatus.invalid);
      expect(below.status, CircuitEditStatus.invalid);
      expect(above.proposedRows, isNull);
      expect(below.proposedRows, isNull);
      expect(model.logicalGateById(before.id)!.occupiedLocations,
          before.occupiedLocations);
      expect(notifications, 0);
    });

    test('diagonal occupied move shifts neighbours without retargeting', () {
      final model = circuit(5);
      final neighbour = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      final cx = insertDouble(
        model,
        SelectedGateType.cnot,
        control: 2,
        target: 4,
        column: 1,
      );
      final plan = model.planLogicalGateMove(
        cx.affectedGateId!,
        const CircuitLocation(qubit: 2, column: 0),
      );
      expect(plan.status, CircuitEditStatus.changed);
      expect(model.logicalGateById(cx.affectedGateId!)!.controlQubit, 2);
      expect(model.commitLogicalGateMovePlan(plan).status,
          CircuitEditStatus.changed);
      final moved = model.logicalGateById(cx.affectedGateId!)!;
      expect(moved.controlQubit, 0);
      expect(moved.targetQubit, 2);
      expect(moved.column, 0);
      expect(model.logicalGateById(neighbour.affectedGateId!)!.id,
          neighbour.affectedGateId);
    });
  });

  group('structured edit outcomes', () {
    test('insert, move, delete, and clear report coherent outcomes', () {
      final model = circuit(2);
      var notifications = 0;
      model.addListener(() => notifications++);

      final inserted = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      expect(inserted.status, CircuitEditStatus.changed);
      expect(inserted.affectedGateId, isNotNull);
      expect(notifications, 1);

      final same = model.moveSingleGateWithOutcome(
        inserted.affectedGateId!,
        const CircuitLocation(qubit: 0, column: 0),
      );
      expect(same.status, CircuitEditStatus.same);
      expect(notifications, 1);

      final moved = model.moveSingleGateWithOutcome(
        inserted.affectedGateId!,
        const CircuitLocation(qubit: 1, column: 0),
      );
      expect(moved.status, CircuitEditStatus.changed);
      expect(moved.affectedGateId, inserted.affectedGateId);
      expect(notifications, 2);

      final removed =
          model.removeLogicalGateByIdWithOutcome(inserted.affectedGateId!);
      expect(removed.status, CircuitEditStatus.changed);
      expect(notifications, 3);

      expect(
          model.clearPlacedGatesWithOutcome().status, CircuitEditStatus.same);
      expect(notifications, 3);
    });

    test('invalid and protected edits do not notify', () {
      final model = circuit(2);
      var notifications = 0;
      model.addListener(() => notifications++);

      expect(
        model
            .insertSingleGateWithOutcome(
              Gate.fromIdentifier(SelectedGateType.none),
              0,
              0,
            )
            .status,
        CircuitEditStatus.invalid,
      );
      expect(notifications, 0);

      final inserted = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        0,
        isDeletable: false,
      );
      expect(inserted.status, CircuitEditStatus.changed);
      expect(notifications, 1);
      expect(
        model.removeLogicalGateByIdWithOutcome(inserted.affectedGateId!).status,
        CircuitEditStatus.protected,
      );
      expect(notifications, 1);
    });

    test('clear reports changed once for a non-empty circuit', () {
      final model = circuit(1);
      model.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        0,
      );
      var notifications = 0;
      model.addListener(() => notifications++);
      expect(model.clearPlacedGatesWithOutcome().status,
          CircuitEditStatus.changed);
      expect(notifications, 1);
      expect(model.isCircuitEmpty(), isTrue);
    });
  });

  group('logical gate footprints', () {
    test('single gate has one canonical occupied cell', () {
      final model = circuit(2);
      final outcome = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2),
        0,
        1,
      );
      final footprint = model.logicalGateById(outcome.affectedGateId!)!;
      expect(footprint.fragments, hasLength(1));
      expect(footprint.anchor, const CircuitLocation(qubit: 1, column: 0));
      expect(footprint.isSingleQubit, isTrue);
      expect(footprint.gate.angle, math.pi / 2);
    });

    for (final gateType in [
      SelectedGateType.cnot,
      SelectedGateType.cz,
      SelectedGateType.ccnot,
    ]) {
      test('$gateType footprint exposes every fragment and metadata', () {
        final model = circuit(4);
        final outcome = gateType == SelectedGateType.ccnot
            ? model.insertTripleGateWithOutcome(
                Gate.fromIdentifier(gateType), 0, 3, 0, 1)
            : model.insertDoubleGateWithOutcome(
                Gate.fromIdentifier(gateType), 0, 3, 0);
        final footprint = model.footprintForGateId(outcome.affectedGateId!)!;
        expect(footprint.isControlled, isTrue);
        expect(footprint.fragments, hasLength(4));
        expect(
            footprint.fragments
                .every((fragment) => fragment.placedGate.id == footprint.id),
            isTrue);
        expect(footprint.controlQubit, 0);
        expect(footprint.targetQubit, 3);
        expect(footprint.secondControlQubit,
            gateType == SelectedGateType.ccnot ? 1 : isNull);
      });
    }

    test('compaction preserves footprint identity and unknown IDs are safe',
        () {
      final model = circuit(2);
      final first = model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      final second = model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.hadamard), 1, 0);
      model.removeLogicalGateByIdWithOutcome(first.affectedGateId!);
      final footprint = model.logicalGateById(second.affectedGateId!)!;
      expect(footprint.id, second.affectedGateId);
      expect(footprint.column, 0);
      expect(model.logicalGateById(const GateId(999999)), isNull);
    });
  });

  group('rotation parameter editing', () {
    for (final gateType in [
      SelectedGateType.rx,
      SelectedGateType.ry,
      SelectedGateType.rz,
    ]) {
      test('$gateType edit preserves identity and location and notifies once',
          () {
        final model = circuit(2);
        final insertion = model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(gateType, angle: math.pi / 4),
          1,
          1,
        );
        final id = insertion.affectedGateId!;
        final location = model.logicalGateById(id)!.anchor;
        var notifications = 0;
        model.addListener(() => notifications++);

        final outcome = model.updateGateParametersWithOutcome(
          id,
          angle: -math.pi / 2,
        );
        final updated = model.logicalGateById(id)!;
        expect(outcome.status, CircuitEditStatus.changed);
        expect(updated.id, id);
        expect(updated.anchor, location);
        expect(updated.gate.angle, -math.pi / 2);
        expect(notifications, 1);
      });
    }

    test('same equivalent angle is a no-op', () {
      final model = circuit(1);
      final insertion = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2),
        0,
        0,
      );
      var notifications = 0;
      model.addListener(() => notifications++);
      expect(
        model
            .updateGateParametersWithOutcome(
              insertion.affectedGateId!,
              angle: math.pi / 2 + 1e-12,
            )
            .status,
        CircuitEditStatus.same,
      );
      expect(notifications, 0);
    });

    test('invalid, unknown, unsupported, and protected edits are safe', () {
      final model = circuit(2);
      final ordinary = model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      final protected = model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.rz, angle: 0), 0, 1,
          isDeletable: false);
      var notifications = 0;
      model.addListener(() => notifications++);

      expect(
          model
              .updateGateParametersWithOutcome(const GateId(9999), angle: 0)
              .status,
          CircuitEditStatus.notFound);
      expect(
          model
              .updateGateParametersWithOutcome(ordinary.affectedGateId!,
                  angle: 0)
              .status,
          CircuitEditStatus.unsupported);
      expect(
          model
              .updateGateParametersWithOutcome(protected.affectedGateId!,
                  angle: math.pi)
              .status,
          CircuitEditStatus.protected);
      for (final invalidAngle in <double?>[null, double.nan, double.infinity]) {
        final rotation = model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 4),
          1,
          0,
        );
        notifications = 0;
        expect(
            model
                .updateGateParametersWithOutcome(rotation.affectedGateId!,
                    angle: invalidAngle)
                .status,
            CircuitEditStatus.invalid);
        expect(notifications, 0);
        model.removeLogicalGateByIdWithOutcome(rotation.affectedGateId!);
      }
    });

    test('edit leaves unrelated gates unchanged and survives move and delete',
        () {
      final model = circuit(2);
      final unrelated = model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.x), 0, 1);
      final rotation = model.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.rz, angle: 0), 1, 0);
      final unrelatedBefore = model.logicalGateById(unrelated.affectedGateId!)!;
      expect(
          model
              .updateGateParametersWithOutcome(rotation.affectedGateId!,
                  angle: math.pi)
              .status,
          CircuitEditStatus.changed);
      final unrelatedAfter = model.logicalGateById(unrelated.affectedGateId!)!;
      expect(unrelatedAfter.id, unrelatedBefore.id);
      expect(unrelatedAfter.gate.type, unrelatedBefore.gate.type);
      expect(
          model
              .moveSingleGateWithOutcome(rotation.affectedGateId!,
                  const CircuitLocation(qubit: 1, column: 1))
              .status,
          CircuitEditStatus.changed);
      expect(
          model.logicalGateById(rotation.affectedGateId!)!.gate.angle, math.pi);
      expect(
          model
              .removeLogicalGateByIdWithOutcome(rotation.affectedGateId!)
              .status,
          CircuitEditStatus.changed);
      expect(model.logicalGateById(rotation.affectedGateId!), isNull);
      expect(model.logicalGateById(unrelated.affectedGateId!), isNotNull);
    });

    test('malformed historical rotation can be repaired safely', () {
      final model = circuit(1);
      const id = GateId(700);
      model.placedGates[0].add(PlacedQuantumGate(
        id: id,
        gate: Gate.fromIdentifier(SelectedGateType.rx),
      ));
      var notifications = 0;
      model.addListener(() => notifications++);
      expect(
          model.updateGateParametersWithOutcome(id, angle: math.pi / 4).status,
          CircuitEditStatus.changed);
      expect(model.logicalGateById(id)!.gate.angle, math.pi / 4);
      expect(notifications, 1);
    });
  });

  group('single-qubit gate replacement', () {
    QuantumCircuit replacementCircuit({int qubits = 2}) => QuantumCircuit(
          currentLevel: ComposerLevel(
            taskDescription: 'replacement test',
            numQubits: qubits,
            initialQubitsStateStr: '0' * qubits,
            initialQubitsState: ComposerLevel.getZeroStateVector(qubits),
            availableGates: [
              Gate.fromIdentifier(SelectedGateType.hadamard),
              Gate.fromIdentifier(SelectedGateType.x),
              Gate.fromIdentifier(SelectedGateType.y),
              Gate.fromIdentifier(SelectedGateType.rx),
              Gate.fromIdentifier(SelectedGateType.ry),
            ],
            solutionFinalVector: const [],
          ),
        );

    test('H to X is atomic and preserves identity, location, and policy', () {
      final model = replacementCircuit();
      final insertion = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        1,
        1,
      );
      final id = insertion.affectedGateId!;
      final before = model.logicalGateById(id)!;
      var notifications = 0;
      model.addListener(() => notifications++);

      final outcome = model.replaceSingleGateWithOutcome(
        id,
        Gate.fromIdentifier(SelectedGateType.x),
      );
      final after = model.logicalGateById(id)!;
      expect(outcome.status, CircuitEditStatus.changed);
      expect(after.id, id);
      expect(after.anchor, before.anchor);
      expect(after.isDeletable, before.isDeletable);
      expect(after.type, SelectedGateType.x);
      expect(notifications, 1);
    });

    test('same configuration is a no-op and configured rotations are valid',
        () {
      final model = replacementCircuit();
      final insertion = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2),
        0,
        0,
      );
      var notifications = 0;
      model.addListener(() => notifications++);
      expect(
        model
            .replaceSingleGateWithOutcome(
              insertion.affectedGateId!,
              Gate.fromIdentifier(
                SelectedGateType.rx,
                angle: math.pi / 2 + 1e-12,
              ),
            )
            .status,
        CircuitEditStatus.same,
      );
      expect(notifications, 0);
      expect(
        model
            .replaceSingleGateWithOutcome(
              insertion.affectedGateId!,
              Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 4),
            )
            .status,
        CircuitEditStatus.changed,
      );
      expect(model.logicalGateById(insertion.affectedGateId!)!.gate.angle,
          math.pi / 4);
      expect(notifications, 1);
    });

    test('invalid, unsupported, unknown, protected, and forbidden are safe',
        () {
      final model = replacementCircuit(qubits: 3);
      final ordinary = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      final protected = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        1,
        isDeletable: false,
      );
      final controlled = model.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.cnot),
        1,
        2,
        0,
      );
      var notifications = 0;
      model.addListener(() => notifications++);

      expect(
          model
              .replaceSingleGateWithOutcome(
                const GateId(99999),
                Gate.fromIdentifier(SelectedGateType.x),
              )
              .status,
          CircuitEditStatus.notFound);
      expect(
          model
              .replaceSingleGateWithOutcome(
                controlled.affectedGateId!,
                Gate.fromIdentifier(SelectedGateType.x),
              )
              .status,
          CircuitEditStatus.unsupported);
      expect(
          model
              .replaceSingleGateWithOutcome(
                protected.affectedGateId!,
                Gate.fromIdentifier(SelectedGateType.x),
              )
              .status,
          CircuitEditStatus.protected);
      expect(
          model
              .replaceSingleGateWithOutcome(
                ordinary.affectedGateId!,
                Gate.fromIdentifier(SelectedGateType.cnot),
              )
              .status,
          CircuitEditStatus.unsupported);
      expect(
          model
              .replaceSingleGateWithOutcome(
                ordinary.affectedGateId!,
                Gate.fromIdentifier(SelectedGateType.rx),
              )
              .status,
          CircuitEditStatus.invalid);
      expect(
          model
              .replaceSingleGateWithOutcome(
                ordinary.affectedGateId!,
                Gate.fromIdentifier(SelectedGateType.z),
              )
              .status,
          CircuitEditStatus.protected);
      expect(model.logicalGateById(ordinary.affectedGateId!)!.type,
          SelectedGateType.hadamard);
      expect(notifications, 0);
    });

    test('replacement keeps unrelated cells and supports chained edits', () {
      final model = replacementCircuit();
      final unrelated = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        1,
      );
      final edited = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        1,
        0,
      );
      final id = edited.affectedGateId!;
      final unrelatedGate = model.logicalGateById(unrelated.affectedGateId!)!;

      expect(
          model
              .replaceSingleGateWithOutcome(
                id,
                Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2),
              )
              .status,
          CircuitEditStatus.changed);
      expect(
          model.updateGateParametersWithOutcome(id, angle: math.pi / 4).status,
          CircuitEditStatus.changed);
      expect(
          model
              .moveSingleGateWithOutcome(
                id,
                const CircuitLocation(qubit: 1, column: 0),
              )
              .status,
          CircuitEditStatus.changed);
      expect(model.logicalGateById(id)!.id, id);
      expect(model.logicalGateById(id)!.gate.angle, math.pi / 4);
      expect(model.logicalGateById(unrelatedGate.id)!.type, unrelatedGate.type);
      expect(model.removeLogicalGateByIdWithOutcome(id).status,
          CircuitEditStatus.changed);
      expect(model.logicalGateById(id), isNull);
    });

    test('repeated replacement retains one unique GateId', () {
      final model = replacementCircuit();
      final insertion = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      final id = insertion.affectedGateId!;
      for (final type in [
        SelectedGateType.x,
        SelectedGateType.y,
        SelectedGateType.hadamard,
      ]) {
        expect(
            model
                .replaceSingleGateWithOutcome(id, Gate.fromIdentifier(type))
                .status,
            CircuitEditStatus.changed);
      }
      expect(model.logicalGates.map((gate) => gate.id), [id]);
    });
  });

  group('logical gate duplication', () {
    QuantumCircuit duplicationCircuit({int qubits = 4}) => QuantumCircuit(
          currentLevel: ComposerLevel(
            taskDescription: 'duplication test',
            numQubits: qubits,
            initialQubitsStateStr: '0' * qubits,
            initialQubitsState: ComposerLevel.getZeroStateVector(qubits),
            availableGates: [
              for (final type in [
                SelectedGateType.hadamard,
                SelectedGateType.x,
                SelectedGateType.y,
                SelectedGateType.z,
                SelectedGateType.s,
                SelectedGateType.t,
                SelectedGateType.rx,
                SelectedGateType.ry,
                SelectedGateType.rz,
                SelectedGateType.cnot,
                SelectedGateType.cz,
                SelectedGateType.ccnot,
              ])
                Gate.fromIdentifier(type),
            ],
            solutionFinalVector: const [],
          ),
        );

    CircuitEditOutcome insertControlled(
      QuantumCircuit model,
      SelectedGateType type, {
      int column = 0,
      bool isDeletable = true,
    }) {
      if (type == SelectedGateType.ccnot) {
        return model.insertTripleGateWithOutcome(
          Gate.fromIdentifier(type),
          column,
          3,
          0,
          1,
          isDeletable: isDeletable,
        );
      }
      return model.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(type),
        column,
        3,
        0,
        isDeletable: isDeletable,
      );
    }

    test('duplicate H uses a new identity and commits exactly once', () {
      final model = duplicationCircuit();
      final source = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      final sourceId = source.affectedGateId!;
      final plan = model.planLogicalGateDuplication(sourceId);
      expect(plan.status, CircuitEditStatus.changed);
      expect(plan.duplicateId, isNot(sourceId));
      expect(model.logicalGates, hasLength(1));

      var notifications = 0;
      model.addListener(() => notifications++);
      final outcome = model.commitLogicalGateDuplicationPlan(plan);
      expect(outcome.status, CircuitEditStatus.changed);
      expect(outcome.affectedGateId, plan.duplicateId);
      expect(model.logicalGateById(sourceId)!.type, SelectedGateType.hadamard);
      expect(model.logicalGateById(plan.duplicateId!)!.type,
          SelectedGateType.hadamard);
      expect(model.logicalGateById(plan.duplicateId!)!.column, 1);
      expect(model.logicalGates.map((gate) => gate.id).toSet(), hasLength(2));
      expect(notifications, 1);
    });

    test('rotation duplication preserves configuration independently', () {
      final model = duplicationCircuit();
      final source = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
        0,
        1,
      );
      final duplicate = model.duplicateLogicalGateWithOutcome(
        source.affectedGateId!,
      );
      expect(duplicate.status, CircuitEditStatus.changed);
      expect(model.logicalGateById(duplicate.affectedGateId!)!.gate.angle,
          math.pi / 4);
      expect(
        model
            .updateGateParametersWithOutcome(
              duplicate.affectedGateId!,
              angle: math.pi / 2,
            )
            .status,
        CircuitEditStatus.changed,
      );
      expect(model.logicalGateById(source.affectedGateId!)!.gate.angle,
          math.pi / 4);
      expect(model.logicalGateById(duplicate.affectedGateId!)!.gate.angle,
          math.pi / 2);
    });

    for (final type in [
      SelectedGateType.cnot,
      SelectedGateType.cz,
      SelectedGateType.ccnot,
    ]) {
      test('duplicate $type preserves its complete topology with one new ID',
          () {
        final model = duplicationCircuit();
        final sourceOutcome = insertControlled(model, type);
        final source = model.logicalGateById(sourceOutcome.affectedGateId!)!;
        final outcome = model.duplicateLogicalGateWithOutcome(source.id);
        final duplicate = model.logicalGateById(outcome.affectedGateId!)!;

        expect(outcome.status, CircuitEditStatus.changed);
        expect(duplicate.id, isNot(source.id));
        expect(duplicate.fragments, hasLength(source.fragments.length));
        expect(duplicate.fragments.map((part) => part.placedGate.id).toSet(),
            {duplicate.id});
        expect(duplicate.controlQubit, source.controlQubit);
        expect(duplicate.secondControlQubit, source.secondControlQubit);
        expect(duplicate.targetQubit, source.targetQubit);
        expect(duplicate.occupiedLocations.map((cell) => cell.qubit),
            source.occupiedLocations.map((cell) => cell.qubit));
        expect(duplicate.column, source.column + 1);
      });
    }

    test('occupied destination shifts only conflicting logical operations', () {
      final model = duplicationCircuit(qubits: 2);
      final source = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      final blocker = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.t),
        1,
        0,
      );
      final unrelated = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.z),
        1,
        1,
      );
      final unrelatedBefore = model.logicalGateById(unrelated.affectedGateId!)!;

      final plan = model.planLogicalGateDuplication(source.affectedGateId!);
      expect(plan.status, CircuitEditStatus.changed);
      expect(model.logicalGateById(blocker.affectedGateId!)!.column, 1);
      expect(model.logicalGateById(unrelated.affectedGateId!)!.anchor,
          unrelatedBefore.anchor);
      model.commitLogicalGateDuplicationPlan(plan);
      expect(model.logicalGateById(blocker.affectedGateId!)!.column, 2);
      expect(model.logicalGateById(unrelated.affectedGateId!)!.anchor,
          unrelatedBefore.anchor);
      expect(model.logicalGateById(unrelated.affectedGateId!)!.id,
          unrelatedBefore.id);
    });

    test('protected, unavailable, and unknown duplication is safe', () {
      final model = duplicationCircuit(qubits: 2);
      final protected = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
        isDeletable: false,
      );
      final source = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.x),
        0,
        1,
      );
      model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.z),
        1,
        1,
        isDeletable: false,
      );
      var notifications = 0;
      model.addListener(() => notifications++);
      expect(model.planLogicalGateDuplication(const GateId(9999)).status,
          CircuitEditStatus.notFound);
      expect(
          model
              .duplicateLogicalGateWithOutcome(protected.affectedGateId!)
              .status,
          CircuitEditStatus.protected);
      expect(
          model.duplicateLogicalGateWithOutcome(source.affectedGateId!).status,
          CircuitEditStatus.protected);
      expect(model.logicalGates, hasLength(3));
      expect(notifications, 0);

      final restricted = circuit(1);
      final unavailable = restricted.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.hadamard),
        0,
        0,
      );
      expect(
          restricted
              .duplicateLogicalGateWithOutcome(unavailable.affectedGateId!)
              .status,
          CircuitEditStatus.protected);
    });

    test('chained duplicate edits preserve independent identities', () {
      final model = duplicationCircuit();
      final sourceRx = model.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
        0,
        0,
      );
      final duplicateRx = model.duplicateLogicalGateWithOutcome(
        sourceRx.affectedGateId!,
      );
      expect(
          model
              .updateGateParametersWithOutcome(
                duplicateRx.affectedGateId!,
                angle: math.pi / 2,
              )
              .status,
          CircuitEditStatus.changed);
      expect(
          model
              .moveSingleGateWithOutcome(
                duplicateRx.affectedGateId!,
                const CircuitLocation(qubit: 1, column: 1),
              )
              .status,
          CircuitEditStatus.changed);
      expect(
          model
              .replaceSingleGateWithOutcome(
                sourceRx.affectedGateId!,
                Gate.fromIdentifier(SelectedGateType.hadamard),
              )
              .status,
          CircuitEditStatus.changed);

      final sourceCx = insertControlled(model, SelectedGateType.cnot,
          column: model.maxCircuitDepth());
      final duplicateCx = model.duplicateLogicalGateWithOutcome(
        sourceCx.affectedGateId!,
      );
      expect(
          model
              .commitLogicalGateMovePlan(
                model.planLogicalGateMove(
                  duplicateCx.affectedGateId!,
                  const CircuitLocation(qubit: 3, column: 0),
                ),
              )
              .status,
          CircuitEditStatus.changed);
      expect(
          model
              .removeLogicalGateByIdWithOutcome(duplicateCx.affectedGateId!)
              .status,
          CircuitEditStatus.changed);

      expect(model.logicalGateById(sourceRx.affectedGateId!)!.type,
          SelectedGateType.hadamard);
      expect(model.logicalGateById(duplicateRx.affectedGateId!)!.gate.angle,
          math.pi / 2);
      expect(model.logicalGateById(sourceCx.affectedGateId!), isNotNull);
      expect(model.logicalGateById(duplicateCx.affectedGateId!), isNull);
      expect(model.logicalGates.map((gate) => gate.id).toSet(),
          hasLength(model.logicalGates.length));
    });
  });
}
