import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  ComposerLevel level(int id) => getQQLevelById(id)! as ComposerLevel;

  void expectBasisState(QuantumCircuit circuit, int basisIndex,
      {double sign = 1}) {
    for (final (index, amplitude) in circuit.currentState.stateVector.indexed) {
      final expected = index == basisIndex ? Complex(sign, 0) : Complex.zero();
      expect(
        amplitude.real,
        closeTo(expected.real, 1e-10),
        reason: 'basis amplitude $index',
      );
      expect(
        amplitude.imaginary,
        closeTo(expected.imaginary, 1e-10),
        reason: 'basis amplitude $index',
      );
    }
  }

  group('authored starting-state invariant', () {
    test('M14 starts at authored |10> with no fixed operation', () {
      final circuit = QuantumCircuit(currentLevel: level(74));

      expect(circuit.logicalGates, isEmpty);
      expect(circuit.learnerEditableStartColumn, 0);
      expectBasisState(circuit, 2);
    });

    test('M16 starts at authored |101> with no fixed operation', () {
      final circuit = QuantumCircuit(currentLevel: level(76));

      expect(circuit.logicalGates, isEmpty);
      expect(circuit.learnerEditableStartColumn, 0);
      expectBasisState(circuit, 5);
    });

    test('M20 applies its authored fixed CCX before exposing Current State',
        () {
      final circuit = QuantumCircuit(currentLevel: level(80));
      final fixed = circuit.logicalGates.single;

      expect(fixed.isDeletable, isFalse);
      expect(fixed.column, 0);
      expect(fixed.type, SelectedGateType.ccnot);
      expect(fixed.controlQubit, 1);
      expect(fixed.secondControlQubit, 2);
      expect(fixed.targetQubit, 0);
      expect(circuit.learnerEditableStartColumn, 1);
      expectBasisState(circuit, 7);
    });
  });

  group('fixed operation boundary is gate-type independent', () {
    test('Z, CX, and CCX insert after and cannot move before M20 fixed CCX',
        () {
      for (final type in const [
        SelectedGateType.z,
        SelectedGateType.cnot,
        SelectedGateType.ccnot,
      ]) {
        final circuit = QuantumCircuit(currentLevel: level(80));
        final fixed = circuit.logicalGates.single;
        final CircuitEditOutcome inserted;
        if (type == SelectedGateType.z) {
          inserted = circuit.insertSingleGateWithOutcome(
            Gate.fromIdentifier(type),
            0,
            0,
          );
        } else if (type == SelectedGateType.cnot) {
          inserted = circuit.insertDoubleGateWithOutcome(
            Gate.fromIdentifier(type),
            0,
            0,
            1,
          );
        } else {
          inserted = circuit.insertTripleGateWithOutcome(
            Gate.fromIdentifier(type),
            0,
            0,
            1,
            2,
          );
        }

        expect(inserted.changed, isTrue, reason: type.name);
        expect(circuit.logicalGateById(fixed.id)!.column, 0, reason: type.name);
        expect(
          circuit.logicalGateById(inserted.affectedGateId!)!.column,
          1,
          reason: type.name,
        );
        expect(
          circuit
              .planLogicalGateMove(
                inserted.affectedGateId!,
                const CircuitLocation(qubit: 0, column: 0),
              )
              .status,
          CircuitEditStatus.protected,
          reason: type.name,
        );
        expect(circuit.logicalGateById(fixed.id)!.column, 0, reason: type.name);
      }
    });

    test(
        'reported M20 CCX/Z move keeps fixed prefix and compacts learner order',
        () {
      final circuit = QuantumCircuit(currentLevel: level(80));
      final fixed = circuit.logicalGates.single;
      final learnerCcx = circuit.insertTripleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.ccnot),
        0,
        0,
        1,
        2,
      );
      final learnerZ = circuit.insertSingleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.z),
        0,
        0,
      );

      expect(circuit.logicalGateById(fixed.id)!.column, 0);
      expect(circuit.logicalGateById(learnerZ.affectedGateId!)!.column, 1);
      expect(circuit.logicalGateById(learnerCcx.affectedGateId!)!.column, 2);
      circuit.runSimulation();
      expectBasisState(circuit, 6, sign: -1);

      expect(
        circuit
            .commitLogicalGateMovePlan(
              circuit.planLogicalGateMove(
                learnerCcx.affectedGateId!,
                const CircuitLocation(qubit: 0, column: 0),
              ),
            )
            .status,
        CircuitEditStatus.protected,
      );
      expect(
        circuit
            .commitLogicalGateMovePlan(
              circuit.planLogicalGateMove(
                learnerZ.affectedGateId!,
                const CircuitLocation(qubit: 0, column: 0),
              ),
            )
            .status,
        CircuitEditStatus.protected,
      );

      final movedRight = circuit.commitLogicalGateMovePlan(
        circuit.planLogicalGateMove(
          learnerZ.affectedGateId!,
          const CircuitLocation(qubit: 0, column: 2),
        ),
      );
      expect(movedRight.status, CircuitEditStatus.changed);
      expect(circuit.logicalGateById(fixed.id)!.column, 0);
      expect(circuit.logicalGateById(learnerCcx.affectedGateId!)!.column, 1);
      expect(circuit.logicalGateById(learnerZ.affectedGateId!)!.column, 2);
      expect(
        circuit.logicalGates.map((gate) => gate.column).toSet(),
        {0, 1, 2},
      );
      circuit.runSimulation();
      expectBasisState(circuit, 6);

      expect(
        circuit
            .removeLogicalGateByIdWithOutcome(learnerZ.affectedGateId!)
            .status,
        CircuitEditStatus.changed,
      );
      circuit.runSimulation();
      expect(circuit.logicalGateById(fixed.id)!.column, 0);
      expect(circuit.logicalGateById(learnerCcx.affectedGateId!)!.column, 1);
      expectBasisState(circuit, 6);
    });
  });

  test('M14-M20 canonical solutions include fixed content and self-verify', () {
    for (var id = 74; id <= 80; id++) {
      final authoredLevel = level(id);
      final circuit = buildCanonicalSolutionCircuit(authoredLevel);

      expect(circuit.lastSimulationError, isNull, reason: 'level $id');
      expect(authoredLevel.validateCircuit(circuit), isTrue,
          reason: 'level $id ${authoredLevel.title}');
      if (id == 77 || id == 80) {
        expect(
          circuit.logicalGates.where((gate) => !gate.isDeletable),
          hasLength(1),
        );
        expect(circuit.logicalGates, hasLength(2));
      } else {
        expect(
          circuit.logicalGates.where((gate) => !gate.isDeletable),
          isEmpty,
        );
      }
    }
  });
}
