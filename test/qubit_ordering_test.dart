import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/utils/math_utils.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';

ComposerLevel orderingLevel(String initial) => ComposerLevel.fromBinaryString(
      title: 'Qubit ordering fixture',
      taskDescription: 'Verify the production qubit-ordering convention.',
      initialQubitsStateString: initial,
      availableGates: SelectedGateType.values
          .where((type) => type != SelectedGateType.none)
          .map(Gate.fromIdentifier)
          .toList(),
      solutionFinalVector: List.generate(
        1 << initial.length,
        (index) => [index == 0 ? Complex.one() : Complex.zero()],
      ),
    );

void expectBasisState(QuantumCircuit circuit, int expectedIndex) {
  final vector = circuit.currentState.stateVector;
  for (var index = 0; index < vector.length; index++) {
    final expected = index == expectedIndex ? 1.0 : 0.0;
    expect(vector[index].real, closeTo(expected, 1e-10),
        reason: 'index $index');
    expect(vector[index].imaginary, closeTo(0, 1e-10), reason: 'index $index');
  }
}

void main() {
  group('authoritative qubit ordering convention', () {
    for (final entry in const {'00': 0, '01': 1, '10': 2, '11': 3}.entries) {
      test('${entry.key} maps to state-vector index ${entry.value}', () {
        final vector = binaryStringToInitialStateVector(entry.key, 2);
        expect(vector.indexWhere((amplitude) => amplitude == Complex.one()),
            entry.value);
        expect(formatQuantumStateTerms(vector, numQubits: 2).single.basisKet,
            '|${entry.key}⟩');
      });
    }

    test('top Q0 wire receives the rightmost binary-string bit', () {
      expect(
        QuantumCircuitPainter.initialQubitLabelsFor(
          initialQubitsStateStr: '10',
          numQubits: 2,
        ),
        ['|0⟩', '|1⟩'],
      );
    });

    test('X on Q0 flips the rightmost bit and X on Q1 the leftmost', () {
      final q0 = QuantumCircuit(currentLevel: orderingLevel('00'));
      q0.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      q0.runSimulation();
      expectBasisState(q0, 1); // |01>

      final q1 = QuantumCircuit(currentLevel: orderingLevel('00'));
      q1.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 1);
      q1.runSimulation();
      expectBasisState(q1, 2); // |10>
    });

    test('H on Q0 superposes indices 0 and 1', () {
      final circuit = QuantumCircuit(currentLevel: orderingLevel('00'));
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.runSimulation();
      final vector = circuit.currentState.stateVector;
      expect(vector[0].real, closeTo(math.sqrt1_2, 1e-10));
      expect(vector[1].real, closeTo(math.sqrt1_2, 1e-10));
      expect(vector[2].magnitude, closeTo(0, 1e-10));
      expect(vector[3].magnitude, closeTo(0, 1e-10));
    });

    test('CNOT control Q0 target Q1 maps |01> to |11>', () {
      final circuit = QuantumCircuit(currentLevel: orderingLevel('01'));
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.runSimulation();
      expectBasisState(circuit, 3);
    });

    test('CNOT control Q1 target Q0 maps |10> to |11>', () {
      final circuit = QuantumCircuit(currentLevel: orderingLevel('10'));
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 1);
      circuit.runSimulation();
      expectBasisState(circuit, 3);
    });

    test('CZ changes only the phase of |11>', () {
      final circuit = QuantumCircuit(currentLevel: orderingLevel('11'));
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 0, 0, 1);
      circuit.runSimulation();
      final vector = circuit.currentState.stateVector;
      expect(vector[3].real, closeTo(-1, 1e-10));
      expect(vector.take(3).every((value) => value.magnitude < 1e-10), isTrue);
    });

    test('CCNOT controls Q0,Q2 target Q1 maps |101> to |111>', () {
      final circuit = QuantumCircuit(currentLevel: orderingLevel('101'));
      circuit.insertTriplePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.ccnot), 0, 1, 0, 2);
      circuit.runSimulation();
      expectBasisState(circuit, 7);
    });
  });
}
