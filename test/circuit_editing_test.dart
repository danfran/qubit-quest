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
}
