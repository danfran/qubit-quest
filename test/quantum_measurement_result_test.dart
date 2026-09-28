import 'dart:math' as math;
import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_measurement_result.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

class ZeroRandom implements math.Random {
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
  @override
  int nextInt(int max) => 0;
}

class AlternatingRandom extends ZeroRandom {
  bool _upperHalf = false;
  @override
  double nextDouble() {
    _upperHalf = !_upperHalf;
    return _upperHalf ? 0.75 : 0.25;
  }
}

void main() {
  test('X on top wire q0 produces 01 in a two-qubit register', () {
    final circuit = QuantumCircuit(currentLevel: createSandboxComposerLevel(2));
    addTearDown(circuit.dispose);
    circuit.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.x), 0, 0);
    circuit.runSimulation();
    final result = QuantumMeasurementResult.sample(
      stateVector: circuit.currentState.stateVector,
      numQubits: 2,
      random: ZeroRandom(),
    );
    expect(result.numQubits, 2);
    expect(result.counts, {'01': 100});
  });

  for (final bits in ['0', '1', '01', '10', '00100']) {
    test('deterministic $bits preserves q0-LSB and totals 100', () {
      final circuit = QuantumCircuit(
          currentLevel: createSandboxComposerLevel(
        bits.length,
        initialBinaryState: bits,
      ));
      addTearDown(circuit.dispose);
      final result = QuantumMeasurementResult.sample(
        stateVector: circuit.currentState.stateVector,
        numQubits: bits.length,
        random: ZeroRandom(),
      );
      expect(result.counts, {bits: 100});
      expect(() => result.counts[bits] = 2, throwsUnsupportedError);
    });
  }

  test('H and Bell sample joint support without mutating or simulating', () {
    for (final qubits in [1, 2]) {
      final circuit =
          QuantumCircuit(currentLevel: createSandboxComposerLevel(qubits));
      addTearDown(circuit.dispose);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      if (qubits == 2) {
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      }
      circuit.runSimulation();
      final state = circuit.currentState;
      final vector = List<Complex>.of(state.stateVector);
      final simulations = circuit.simulationRunCount;
      final result = QuantumMeasurementResult.sample(
        stateVector: state.stateVector,
        numQubits: qubits,
        random: AlternatingRandom(),
      );
      expect(result.counts.keys,
          orderedEquals(qubits == 1 ? ['0', '1'] : ['00', '11']));
      expect(result.counts.values, everyElement(greaterThan(0)));
      expect(result.counts.values.reduce((a, b) => a + b), 100);
      expect(circuit.currentState, same(state));
      expect(state.stateVector, vector);
      expect(circuit.simulationRunCount, simulations);
    }
  });

  test('normalizes rounding drift and rejects invalid states', () {
    expect(
        QuantumMeasurementResult.sample(
          stateVector: [Complex(0, 0), Complex(1 + 1e-8, 0)],
          numQubits: 1,
          random: ZeroRandom(),
        ).counts,
        {'1': 100});
    for (final vector in [
      [Complex(0, 0), Complex(0, 0)],
      [Complex(2, 0), Complex(0, 0)],
      [Complex(double.nan, 0), Complex(0, 0)],
      [Complex(1, 0)],
    ]) {
      expect(
          () => QuantumMeasurementResult.sample(
              stateVector: vector, numQubits: 1),
          throwsArgumentError);
    }
  });
}
