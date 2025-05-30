import 'package:advance_math/advance_math.dart';

import 'dart:math' as math; // Import math for sqrt

// A wrapper for matrix_utils.Matrix to add quantum-specific operations
class QuantumMatrix {
  final Matrix _matrix;

  // Constructor now directly takes the List<List<Complex>>
  QuantumMatrix(List<List<Complex>> elements)
      : _matrix = Matrix(elements);

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

  // Kronecker Product (Tensor Product) - Essential for multi-qubit systems
  // A ⊗ B
  QuantumMatrix kroneckerProduct(QuantumMatrix other) {
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