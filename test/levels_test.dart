import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';


void main() {
  _testBody(int levelNumber, Function(QuantumCircuit) body) {
    final level = getQQLevelById(levelNumber)!;

    debugPrint('Level $levelNumber: ${level.taskDescription}\n\n');

    final circuit = QuantumCircuit(currentLevel: level);

    body(circuit);

    debugPrint('Circuit after inserting gates:\n$circuit');

    circuit.runSimulation();

    expect(circuit.currentState.state.almostEqualTo(QuantumMatrix(level.solutionFinalVector)), true);

    debugPrint('\n\n');
  }

  group('Test results for all levels', () {
    var tests = [
      (QuantumCircuit circuit) {
      // check X is in the avaiable gates
      //   assert(circuit.availableGates.contains(Gate.fromIdentifier(SelectedGateType.x)));
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.y), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.y), 0, 0);
      },
      (QuantumCircuit circuit) { // 5
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.t), 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.s), 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 1, 0);
      },
      (QuantumCircuit circuit) { // 10
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.s), 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.s), 3, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 4, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 5, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.s), 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.t), 2, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 3, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 1);
      },
      (QuantumCircuit circuit) { // 15
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 2);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertTriplePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ccnot), 0, 1, 0, 2);
      },
      (QuantumCircuit circuit) {
        circuit.insertTriplePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ccnot), 0, 2, 1, 0);
      },
      (QuantumCircuit circuit) { // 20
        circuit.insertTriplePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ccnot), 0, 0, 1, 2);
      },
      (QuantumCircuit circuit) { // more than one solution, example X(0) + X(1)
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 2);
        circuit.insertTriplePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ccnot), 1, 0, 1, 2);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 2, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 3, 0);
      },
      (QuantumCircuit circuit) { // 25
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 2, 1);
      },
      (QuantumCircuit circuit) { // 2 solution with Z(1)
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 3, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 4, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 5, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 1);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 2, 0);
      },
      (QuantumCircuit circuit) { // 30
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 1);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) { // to check if double solution present
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 1);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 0, 1);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 2, 0);
      },
      (QuantumCircuit circuit) { // 35
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 1, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 2, 1, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 3, 2, 1);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 4, 2);
      },
      (QuantumCircuit circuit) { // double solution
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cz), 1, 1, 0);
      },
      (QuantumCircuit circuit) { // double solution
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cz), 2, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 3, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 3, 1);
      },
      (QuantumCircuit circuit) { // 40
        // Solution: Rx(pi/2) on Q0
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), 0, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Ry(pi/2) on Q0
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2), 0, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Rz(pi/2) on Q0
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), 0, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Ry(-pi/2) on Q0
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ry, angle: -math.pi / 2), 1, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Ry(pi/2) on Q0
        // This gate is placed after the pre-inserted Rx gate.
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2), 1, 0);
      },
      (QuantumCircuit circuit) { // 45
        // Solution: Rz(pi/4) on Q1
        // This gate is placed after the pre-inserted gates.
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 4), 2, 1);
      },
      (QuantumCircuit circuit) {
        // Solution: Rx(pi/2), Ry(pi/4), then Rz(pi/2) on Q0.
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 4), 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), 2, 0);
      },
    ];

    for (int i = 1; i <= tests.length; i++) {
      test('level $i', () {
        _testBody(i, tests[i - 1]);
      });
    }
  });
}