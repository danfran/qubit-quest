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
}
