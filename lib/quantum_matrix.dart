import 'package:advance_math/advance_math.dart';

import 'dart:math' as math; // Import math for sqrt

// A wrapper for matrix_utils.Matrix to add quantum-specific operations
class QuantumMatrix {
  final Matrix _matrix;

  // Constructor now directly takes the List<List<Complex>>
  QuantumMatrix(List<List<Complex>> elements)
      : _matrix = Matrix(elements);

  QuantumMatrix.fromMatrix(Matrix matrix)
      : _matrix = matrix;

  // Getter for the underlying matrix_utils.Matrix
  Matrix get rawMatrix => _matrix;

  int get rowCount => _matrix.rowCount;
  int get columnCount => _matrix.columnCount;

  Iterable<List> get rows => _matrix.rows;
  Iterable<List> get cols => _matrix.columns;

  // (a + ib) (c + id) = (ac - bd) + i(ad + bc)
  Complex multiply(Complex x, Complex y) =>
      Complex(x.real*y.real - x.imaginary*y.imaginary, x.real*y.imaginary + x.imaginary*y.real);

  // Apply a quantum gate (matrix multiplication)
  // This will handle both matrix-matrix and matrix-vector multiplication
  QuantumMatrix operate(QuantumMatrix other) {
    final result = _matrix.dot(other.rawMatrix);
    // Ensure the result's elements are correctly cast to List<List<Complex>>
    return QuantumMatrix(result.rows.map((row) => row.cast<Complex>()).toList());
  }

  // Adds two matrices.
  QuantumMatrix add(QuantumMatrix other) {
    // A.rawMatrix.add(B.rawMatrix);
    // if (A.length != B.length || A[0].length != B[0].length) {
    //   throw ArgumentError("Matrices must have the same dimensions for addition.");
    // }
    //
    // int rows = A.length;
    // int cols = A[0].length;
    // List<List<Complex>> result = List.generate(rows, (_) => List.filled(cols, Complex.zero()));
    //
    // for (int r = 0; r < rows; r++) {
    //   for (int c = 0; c < cols; c++) {
    //     result[r][c] = A[r][c] + B[r][c];
    //   }
    // }
    // return result;
    Matrix matrix = _matrix + other.rawMatrix;
    return QuantumMatrix.fromMatrix(matrix);
  }

  // --- CNOT Matrix Generation Function ---

  List<List<Complex>> createNQuibitCnotMatrix({
    required int nQubits,
    required int control,
    required int target,
  }) {
    if (control < 0 || control >= nQubits || target < 0 || target >= nQubits) {
      throw ArgumentError("Control or target qubit index out of range (0 to ${nQubits - 1}).");
    }
    if (control == target) {
      throw ArgumentError("Control and target qubits cannot be the same.");
    }

    // Define 1-qubit gate matrices and projectors
    final List<List<Complex>> I_1q = [
      [Complex.one(), Complex.zero()],
      [Complex.zero(), Complex.one()],
    ];
    final List<List<Complex>> X_1q = [
      [Complex.zero(), Complex.one()],
      [Complex.one(), Complex.zero()],
    ];
    final List<List<Complex>> P0_1q = [
      [Complex.one(), Complex.zero()],
      [Complex.zero(), Complex.zero()],
    ]; // |0><0|
    final List<List<Complex>> P1_1q = [
      [Complex.zero(), Complex.zero()],
      [Complex.zero(), Complex.one()],
    ]; // |1><1|

    // Build the list of operators for each qubit for both terms
    List<List<List<Complex>>> term0Ops = []; // For control is |0>
    List<List<List<Complex>>> term1Ops = []; // For control is |1>

    // Qiskit's convention is little-endian (qubit 0 is rightmost in |q2 q1 q0>).
    // When building the tensor product A \otimes B \otimes C,
    // where C is q0, B is q1, A is q2.
    // The loop goes from q0 to q_{n-1}
    for (int i = 0; i < nQubits; i++) {
      if (i == control) {
        term0Ops.add(P0_1q);
        term1Ops.add(P1_1q);
      } else if (i == target) {
        term0Ops.add(I_1q); // If control is 0, target is Identity
        term1Ops.add(X_1q); // If control is 1, target is X
      } else {
        // For all other qubits, apply Identity
        term0Ops.add(I_1q);
        term1Ops.add(I_1q);
      }
    }

    // Compute the tensor product for Term 0: I_{N-1} \otimes ... \otimes P0_control \otimes ... \otimes I_target \otimes ... \otimes I_0
    // Note: List is built from Q0 to Q_{N-1}. Kronecker product order is reversed (A \otimes B \otimes C for [C, B, A])
    List<List<Complex>> kronTerm0 = term0Ops[nQubits - 1]; // Start with the leftmost qubit (Q_{N-1})
    for (int i = nQubits - 2; i >= 0; i--) {
      kronTerm0 = tensorProduct2(kronTerm0, term0Ops[i]);
    }

    // Compute the tensor product for Term 1: I_{N-1} \otimes ... \otimes P1_control \otimes ... \otimes X_target \otimes ... \otimes I_0
    List<List<Complex>> kronTerm1 = term1Ops[nQubits - 1]; // Start with the leftmost qubit (Q_{N-1})
    for (int i = nQubits - 2; i >= 0; i--) {
      kronTerm1 = tensorProduct2(kronTerm1, term1Ops[i]);
    }

    // The CNOT matrix is the sum of these two terms
    // return matrixAdd(kronTerm0, kronTerm1);
    return List<List<Complex>>.empty();
  }

  List<List<Complex>> tensorProduct2(List<List<Complex>> A, List<List<Complex>> B) {
    int m = A.length;
    int n = A[0].length;
    int p = B.length;
    int q = B[0].length;

    List<List<Complex>> result = List.generate(m * p, (_) => List.filled(n * q, Complex.zero()));

    for (int i = 0; i < m; i++) {
      for (int j = 0; j < n; j++) {
        for (int k = 0; k < p; k++) {
          for (int l = 0; l < q; l++) {
            result[i * p + k][j * q + l] = A[i][j] * B[k][l];
          }
        }
      }
    }
    return result;
  }

  // Kronecker Product (Tensor Product) - Essential for multi-qubit systems
  // A ⊗ B
  QuantumMatrix tensorProduct(QuantumMatrix other) {
    final newRows = rowCount * other.rowCount;
    final newCols = columnCount * other.columnCount;

    final List<List<Complex>> resultElements = List.generate(newRows, (i) => List.filled(newCols, Complex.zero()));

    for (int i = 0; i < rowCount; i++) {
      for (int j = 0; j < columnCount; j++) {
        final Complex elementA = _matrix.row(i).getValueAt(j) as Complex;

        for (int r = 0; r < other.rowCount; r++) {
          for (int c = 0; c < other.columnCount; c++) {
            final Complex elementB = other._matrix.row(r).getValueAt(c) as Complex;
            resultElements[i * other.rowCount + r][j * other.columnCount + c] = multiply(elementA, elementB);
          }
        }
      }
    }
    return QuantumMatrix(resultElements);
  }

  // Utility to create common quantum gates
  static QuantumMatrix identity(int size) {
    final List<List<Complex>> elements = List.generate(size, (i) => List.filled(size, Complex.zero()));
    for (int i = 0; i < size; i++) {
      elements[i][i] = Complex.one();
    }
    return QuantumMatrix(elements);
  }

  static QuantumMatrix hadamard() {
    final complexSqrtHalf = Complex(1 / math.sqrt(2), 0);
    return QuantumMatrix([
      [complexSqrtHalf, complexSqrtHalf],
      [complexSqrtHalf, Complex(-complexSqrtHalf.real, -complexSqrtHalf.imaginary)],
    ]);
  }

  static QuantumMatrix pauliX() {
    return QuantumMatrix([
      [Complex.zero(), Complex.one()],
      [Complex.one(), Complex.zero()],
    ]);
  }

  static QuantumMatrix pauliY() {
    return QuantumMatrix([
      [Complex.zero(), Complex(-Complex.i().real, -Complex.i().imaginary)],
      [Complex.one(), Complex.zero()],
    ]);
  }

  static QuantumMatrix pauliZ() {
    return QuantumMatrix([
      [Complex.one(), Complex.zero()],
      [Complex.zero(), Complex(-Complex.one().real, -Complex.one().imaginary)],
    ]);
  }

  // Method to check if two QuantumMatrices are approximately equal (for floating point comparisons)
  bool almostEqualTo(QuantumMatrix other, {double tolerance = 1e-9}) {
    // if (rows != other.rows || cols != other.cols) {
    //   return false;
    // }
    for (int i = 0; i < _matrix.rowCount; i++) {
      for (int j = 0; j < _matrix.columnCount; j++) {
        final Complex c1 = _matrix.row(i).getValueAt(j);
        final Complex c2 = other._matrix.row(i).getValueAt(j) as Complex;
        if ((c1.real - c2.real).abs() > tolerance || (c1.imaginary - c2.imaginary).abs() > tolerance) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  String toString() {
    return _matrix.toString(); // Uses matrix_utils' toString
  }
}