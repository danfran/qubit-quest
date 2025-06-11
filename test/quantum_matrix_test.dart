// test/quantum_matrix_test.dart
import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;

import 'package:quantumquiz/quantum_matrix.dart';

void main() {
  group('QuantumMatrix Operations', () {
    // Define a tolerance for floating point comparisons
    const double tolerance = 1e-9;

    // --- Test Matrix Multiplication (Gate Application) ---
    test('Applying Hadamard to |0> state results in superposition', () {
      // |0> state vector
      final zeroState = QuantumMatrix([
        [Complex.one()],
        [Complex.zero()],
      ]);
      final hadamard = QuantumMatrix.hadamard();

      final resultState = hadamard.operate(zeroState);

      // Expected state: (1/sqrt(2))|0> + (1/sqrt(2))|1>
      final expectedReal = 1 / math.sqrt(2);
      final expectedState = QuantumMatrix([
        [Complex(expectedReal, 0)],
        [Complex(expectedReal, 0)],
      ]);

      expect(resultState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'H|0> operation incorrect');
    });

    test('Applying Pauli-X to |0> state results in |1>', () {
      // |0> state vector
      final zeroState = QuantumMatrix([
        [Complex.one()],
        [Complex.zero()],
      ]);
      final pauliX = QuantumMatrix.pauliX();

      final resultState = pauliX.operate(zeroState);

      // Expected state: |1>
      final expectedState = QuantumMatrix([
        [Complex.zero()],
        [Complex.one()],
      ]);

      expect(resultState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'X|0> operation incorrect');
    });

    test('Applying Pauli-X to |1> state results in |0>', () {
      // |1> state vector
      final oneState = QuantumMatrix([
        [Complex.zero()],
        [Complex.one()],
      ]);
      final pauliX = QuantumMatrix.pauliX();

      final resultState = pauliX.operate(oneState);

      // Expected state: |0>
      final expectedState = QuantumMatrix([
        [Complex.one()],
        [Complex.zero()],
      ]);

      expect(resultState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'X|1> operation incorrect');
    });

    test('Sum (+) of two matrices 2X2', () {
      final matrixA = QuantumMatrix([
        [Complex.one(), Complex(1, 5)],
        [Complex.zero(), Complex(7, 0)],
      ]);

      final matrixB = QuantumMatrix([
        [Complex.i(), Complex(4, 2)],
        [Complex(1, 5), Complex(-3, 1)],
      ]);

      final resultState = matrixA.add(matrixB);

      final expectedState = QuantumMatrix([
        [Complex(1, 1), Complex(5, 7)],
        [Complex(1, 5), Complex(4, 1)],
      ]);

      expect(resultState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: '"+" operation incorrect');
    });

    // --- Tests Kronecker Product (Tensor Product) ---
    test('Tensor product (⊗) of two matrices 2X2', () {
      final matrixA = QuantumMatrix([
        [Complex.one(), Complex(1, 5)],
        [Complex.zero(), Complex(7, 0)],
      ]);

      final matrixB = QuantumMatrix([
        [Complex.i(), Complex(4, 2)],
        [Complex(1, 5), Complex(-3, 1)],
      ]);

      final resultState = matrixA.tensorProduct(matrixB);

      final expectedState = QuantumMatrix([
        [Complex.i(), Complex(4, 2), Complex(-5, 1), Complex(-6, 22)],
        [Complex(1, 5), Complex(-3, 1), Complex(-24, 10), Complex(-8, -14)],
        [Complex.zero(), Complex.zero(), Complex(0, 7), Complex(28, 14)],
        [Complex.zero(), Complex.zero(), Complex(7, 35), Complex(-21, 7)],
      ]);

      expect(resultState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: '"⊗" operation incorrect');
    });

    test('Tensor product of two Pauli-X gates is correct', () {
      final x = QuantumMatrix.pauliX();
      final x2 = x.tensorProduct(x);

      // Expected X ⊗ X matrix:
      // [[0,0,0,1],
      //  [0,0,1,0],
      //  [0,1,0,0],
      //  [1,0,0,0]]
      final expectedX2 = QuantumMatrix([
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
      ]);

      expect(x2.almostEqualTo(expectedX2, tolerance: tolerance), isTrue, reason: 'X ⊗ X product incorrect');
    });

    test('Tensor product of Hadamard and Identity is correct', () {
      final h = QuantumMatrix.hadamard();
      final i = QuantumMatrix.identity(2); // Identity for a single qubit

      final hTensorI = h.tensorProduct(i);

      final complexSqrtHalf = Complex(1 / math.sqrt(2), 0);
      // Expected H ⊗ I matrix:
      // [[1/√2, 0, 1/√2, 0],
      //  [0, 1/√2, 0, 1/√2],
      //  [1/√2, 0, -1/√2, 0],
      //  [0, 1/√2, 0, -1/√2]]
      final expectedHTensorI = QuantumMatrix([
        [complexSqrtHalf, Complex.zero(), complexSqrtHalf, Complex.zero()],
        [Complex.zero(), complexSqrtHalf, Complex.zero(), complexSqrtHalf],
        [complexSqrtHalf, Complex.zero(), Complex(-complexSqrtHalf.real, -complexSqrtHalf.imaginary), Complex.zero()], // CORRECTED
        [Complex.zero(), complexSqrtHalf, Complex.zero(), Complex(-complexSqrtHalf.real, -complexSqrtHalf.imaginary)], // CORRECTED
      ]);

      expect(hTensorI.almostEqualTo(expectedHTensorI, tolerance: tolerance), isTrue, reason: 'H ⊗ I product incorrect');
    });

    // --- Test a Simple Circuit (H on Q0, then X on Q1) ---
    test('Simulating H on Q0 then X on Q1 for |00> state', () {
      // Initial state |00> = |0> ⊗ |0>
      // As a 4x1 vector: [1, 0, 0, 0]
      final initialZeroZeroState = QuantumMatrix([
        [Complex.one()],
        [Complex.zero()],
        [Complex.zero()],
        [Complex.zero()],
      ]);

      // Overall circuit operator: (I ⊗ X) * (H ⊗ I)
      final hadamard = QuantumMatrix.hadamard();
      final pauliX = QuantumMatrix.pauliX();
      final identity2 = QuantumMatrix.identity(2);

      // (H ⊗ I) operator
      final H_tensor_I = hadamard.tensorProduct(identity2);
      // (I ⊗ X) operator
      final I_tensor_X = identity2.tensorProduct(pauliX);

      // Final circuit operator (applied right-to-left)
      final finalOperator = I_tensor_X.operate(H_tensor_I);

      // Apply to initial state
      final finalState = finalOperator.operate(initialZeroZeroState);

      // Expected state: (1/sqrt(2))|01> + (1/sqrt(2))|11>
      // As a 4x1 vector: [0, 1/√2, 0, 1/√2]
      final expectedReal = 1 / math.sqrt(2);
      final expectedState = QuantumMatrix([
        [Complex.zero()],
        [Complex(expectedReal, 0)],
        [Complex.zero()],
        [Complex(expectedReal, 0)],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'H on Q0 then X on Q1 simulation incorrect');
    });

    test('Create CNOT matrix for qubits 2, control 0, target 1', () {
      // Apply to initial state
      int q = 2;
      int c = 0;
      int t = 1;
      final finalState = QuantumMatrix.createNQubitCnotMatrix(nQubits: q, control: c, target: t);

      final expectedState = QuantumMatrix([
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'Should create a CNOT Matrix q=$q, c=$c, t=$t');
    });

    test('Create CNOT matrix for qubits 2, control 1, target 0', () {
      // Apply to initial state
      int q = 2;
      int c = 1;
      int t = 0;
      final finalState = QuantumMatrix.createNQubitCnotMatrix(nQubits: q, control: c, target: t);

      final expectedState = QuantumMatrix([
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'Should create a CNOT Matrix q=$q, c=$c, t=$t');
    });

    test('Create CNOT matrix for qubits 3, control 0, target 1', () {
      // Apply to initial state
      int q = 3;
      int c = 0;
      int t = 1;
      final finalState = QuantumMatrix.createNQubitCnotMatrix(nQubits: q, control: c, target: t);

      final expectedState = QuantumMatrix([
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'Should create a CNOT Matrix q=$q, c=$c, t=$t');
    });

    test('Create CNOT matrix for qubits 3, control 0, target 2', () {
      // Apply to initial state
      int q = 3;
      int c = 0;
      int t = 2;
      final finalState = QuantumMatrix.createNQubitCnotMatrix(nQubits: q, control: c, target: t);

      final expectedState = QuantumMatrix([
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'Should create a CNOT Matrix q=$q, c=$c, t=$t');
    });

    test('Create CNOT matrix for qubits 3, control 1, target 0', () {
      // Apply to initial state
      int q = 3;
      int c = 1;
      int t = 0;
      final finalState = QuantumMatrix.createNQubitCnotMatrix(nQubits: q, control: c, target: t);

      final expectedState = QuantumMatrix([
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'Should create a CNOT Matrix q=$q, c=$c, t=$t');
    });

  test('Create CNOT matrix for qubits 3, control 1, target 2', () {
      // Apply to initial state
      int q = 3;
      int c = 1;
      int t = 2;
      final finalState = QuantumMatrix.createNQubitCnotMatrix(nQubits: q, control: c, target: t);

      final expectedState = QuantumMatrix([
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'Should create a CNOT Matrix q=$q, c=$c, t=$t');
    });

    test('Create CNOT matrix for qubits 3, control 2, target 0', () {
      // Apply to initial state
      int q = 3;
      int c = 2;
      int t = 0;
      final finalState = QuantumMatrix.createNQubitCnotMatrix(nQubits: q, control: c, target: t);

      final expectedState = QuantumMatrix([
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'Should create a CNOT Matrix q=$q, c=$c, t=$t');
    });

    test('Create CNOT matrix for qubits 3, control 2, target 1', () {
      // Apply to initial state
      int q = 3;
      int c = 2;
      int t = 1;
      final finalState = QuantumMatrix.createNQubitCnotMatrix(nQubits: q, control: c, target: t);

      final expectedState = QuantumMatrix([
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'Should create a CNOT Matrix q=$q, c=$c, t=$t');
    });

    test('Create CNOT matrix for qubits 4, control 2, target 1', () {
      // Apply to initial state
      int q = 4;
      int c = 2;
      int t = 1;
      final finalState = QuantumMatrix.createNQubitCnotMatrix(nQubits: q, control: c, target: t);

      final expectedState = QuantumMatrix([
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'Should create a CNOT Matrix q=$q, c=$c, t=$t');
    });

    test('Create CNOT matrix for qubits 5, control 4, target 1', () {
      // Apply to initial state
      int q = 5;
      int c = 4;
      int t = 1;
      final finalState = QuantumMatrix.createNQubitCnotMatrix(nQubits: q, control: c, target: t);

      final expectedState = QuantumMatrix([
        [Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero(), Complex.zero()],
        [Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.zero(), Complex.one(), Complex.zero(), Complex.zero()],
      ]);

      expect(finalState.almostEqualTo(expectedState, tolerance: tolerance), isTrue, reason: 'Should create a CNOT Matrix q=$q, c=$c, t=$t');
    });
  });
}