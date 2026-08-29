import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  ComposerLevel level(int id) => getQQLevelById(id)! as ComposerLevel;

  void expectBasisState(QuantumCircuit circuit, int basisIndex) {
    for (final (index, amplitude) in circuit.currentState.stateVector.indexed) {
      final expected = index == basisIndex ? Complex.one() : Complex.zero();
      expect(amplitude.real, closeTo(expected.real, 1e-10),
          reason: 'basis amplitude $index');
      expect(amplitude.imaginary, closeTo(expected.imaginary, 1e-10),
          reason: 'basis amplitude $index');
    }
  }

  Set<SelectedGateType> palette(ComposerLevel candidate) =>
      candidate.availableGates.map((gate) => gate.type).toSet();

  QuantumCircuit oneCnot(
    ComposerLevel candidate, {
    required int control,
    required int target,
  }) {
    final circuit = QuantumCircuit(currentLevel: candidate);
    circuit.insertDoublePlacedGateAt(
      Gate.fromIdentifier(SelectedGateType.cnot),
      circuit.maxCircuitDepth(),
      target,
      control,
    );
    circuit.runSimulation();
    return circuit;
  }

  QuantumCircuit oneCcx(
    ComposerLevel candidate, {
    required int control,
    required int secondControl,
    required int target,
  }) {
    final circuit = QuantumCircuit(currentLevel: candidate);
    circuit.insertTriplePlacedGateAt(
      Gate.fromIdentifier(SelectedGateType.ccnot),
      circuit.maxCircuitDepth(),
      target,
      control,
      secondControl,
    );
    circuit.runSimulation();
    return circuit;
  }

  group('M17 CNOT uncomputation', () {
    test('fixed CNOT creates |01> and the same CNOT restores |11>', () {
      final candidate = level(77);
      final startingCircuit = QuantumCircuit(currentLevel: candidate);
      final fixed = startingCircuit.logicalGates.single;

      expect(candidate.initialQubitsStateStr, '11');
      expect(candidate.targetStateExpression, '|11⟩');
      expect(fixed.type, SelectedGateType.cnot);
      expect(fixed.controlQubit, 0);
      expect(fixed.targetQubit, 1);
      expect(fixed.isDeletable, isFalse);
      expectBasisState(startingCircuit, 1); // |01>

      final solution = buildCanonicalSolutionCircuit(candidate);
      expect(candidate.validateCircuit(solution), isTrue);
      expectBasisState(solution, 3); // |11>
      expect(solution.logicalGates, hasLength(2));
      expect(solution.logicalGates.last.controlQubit, fixed.controlQubit);
      expect(solution.logicalGates.last.targetQubit, fixed.targetQubit);
    });

    test('X/Y shortcuts are unavailable and wrong CNOT topology fails', () {
      final candidate = level(77);

      expect(palette(candidate), {
        SelectedGateType.cnot,
        SelectedGateType.z,
      });
      expect(
        candidate.validateCircuit(oneCnot(candidate, control: 1, target: 0)),
        isFalse,
      );

      for (var qubit = 0; qubit < candidate.numQubits; qubit++) {
        final zOnly = QuantumCircuit(currentLevel: candidate);
        zOnly.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z),
          zOnly.maxCircuitDepth(),
          qubit,
        );
        zOnly.runSimulation();
        expect(candidate.validateCircuit(zOnly), isFalse,
            reason: 'Z on Q$qubit must not bypass CNOT uncomputation');
      }
    });
  });

  group('M18 Toffoli activation', () {
    test('both active controls flip the intended target', () {
      final candidate = level(78);
      final solution = buildCanonicalSolutionCircuit(candidate);
      final step = candidate.canonicalSolution!.steps.single;

      expect(candidate.initialQubitsStateStr, '101');
      expect(step.controlQubit, 0);
      expect(step.secondControlQubit, 2);
      expect(step.targetQubit, 1);
      expect(candidate.validateCircuit(solution), isTrue);
      expectBasisState(solution, 7); // |111>
    });

    test('representative wrong control/target relationships fail', () {
      final candidate = level(78);

      expect(
        candidate.validateCircuit(
          oneCcx(candidate, control: 0, secondControl: 1, target: 2),
        ),
        isFalse,
      );
      expect(
        candidate.validateCircuit(
          oneCcx(candidate, control: 1, secondControl: 2, target: 0),
        ),
        isFalse,
      );
    });
  });

  group('M19 Toffoli topology reasoning', () {
    test('only the intended active controls and changed target succeed', () {
      final candidate = level(79);
      final solution = buildCanonicalSolutionCircuit(candidate);
      final step = candidate.canonicalSolution!.steps.single;

      expect(candidate.numQubits, 4);
      expect(candidate.initialQubitsStateStr, '1001');
      expect(candidate.targetStateExpression, '|1011⟩');
      expect(palette(candidate), {
        SelectedGateType.ccnot,
        SelectedGateType.z,
      });
      expect(step.controlQubit, 0);
      expect(step.secondControlQubit, 3);
      expect(step.targetQubit, 1);
      expect(candidate.validateCircuit(solution), isTrue);
      expectBasisState(solution, 11); // |1011>
    });

    test('a zero-valued control or the wrong target fails', () {
      final candidate = level(79);

      final zeroControl =
          oneCcx(candidate, control: 0, secondControl: 2, target: 1);
      expectBasisState(zeroControl, 9); // Q2=0 prevents firing.
      expect(candidate.validateCircuit(zeroControl), isFalse);

      final wrongTarget =
          oneCcx(candidate, control: 0, secondControl: 3, target: 2);
      expectBasisState(wrongTarget, 13); // |1101>, not |1011>.
      expect(candidate.validateCircuit(wrongTarget), isFalse);
    });
  });

  group('M20 Toffoli uncomputation', () {
    test('same CCX is appended after fixed prefix and restores |110>', () {
      final candidate = level(80);
      final startingCircuit = QuantumCircuit(currentLevel: candidate);
      final fixed = startingCircuit.logicalGates.single;

      expect(candidate.initialQubitsStateStr, '110');
      expectBasisState(startingCircuit, 7); // Fixed CCX produced |111>.
      expect(fixed.type, SelectedGateType.ccnot);
      expect(fixed.controlQubit, 1);
      expect(fixed.secondControlQubit, 2);
      expect(fixed.targetQubit, 0);
      expect(fixed.isDeletable, isFalse);

      final solution = buildCanonicalSolutionCircuit(candidate);
      expect(candidate.validateCircuit(solution), isTrue);
      expectBasisState(solution, 6); // |110>
      expect(solution.logicalGates, hasLength(2));
      expect(solution.logicalGates.first.isDeletable, isFalse);
      expect(solution.logicalGates.first.column, 0);
      expect(solution.logicalGates.last.column, 1);
      expect(solution.logicalGates.last.controlQubit, fixed.controlQubit);
      expect(
        solution.logicalGates.last.secondControlQubit,
        fixed.secondControlQubit,
      );
      expect(solution.logicalGates.last.targetQubit, fixed.targetQubit);
    });
  });
}
