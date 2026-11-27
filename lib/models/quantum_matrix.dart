import 'package:advance_math/advance_math.dart';

import 'package:quantumquiz/utils/math_utils.dart'; // Import math for sqrt

// A wrapper for matrix_utils.Matrix to add quantum-specific operations
class QuantumMatrix {
  final Matrix _matrix;

  // Constructor now directly takes the List<List<Complex>>
  QuantumMatrix(List<List<Complex>> elements) : _matrix = Matrix(elements);

  QuantumMatrix.fromMatrix(Matrix matrix) : _matrix = matrix;

  QuantumMatrix.transpose(List<List<Complex>> elements)
      : _matrix = Matrix(elements).transpose();

  // Utility to create common quantum gates
  factory QuantumMatrix.identity(int size) {
    final List<List<Complex>> elements =
        List.generate(size, (i) => List.filled(size, Complex.zero()));
    for (int i = 0; i < size; i++) {
      elements[i][i] = Complex.one();
    }
    return QuantumMatrix(elements);
  }

  factory QuantumMatrix.hadamard() {
    final complexSqrtHalf = Complex(sqrt1_2, 0);
    return QuantumMatrix([
      [complexSqrtHalf, complexSqrtHalf],
      [
        complexSqrtHalf,
        Complex(-complexSqrtHalf.real, -complexSqrtHalf.imaginary)
      ],
    ]);
  }

  factory QuantumMatrix.phaseS() {
    return QuantumMatrix([
      [Complex.one(), Complex.zero()],
      [Complex.zero(), Complex.i()],
    ]);
  }

  factory QuantumMatrix.t() {
    final double piOver4 = pi / 4; // π/4 radians
    final Complex expIPiOver4 = fromEuler(piOver4);
    return QuantumMatrix([
      [Complex.one(), Complex.zero()],
      [Complex.zero(), expIPiOver4],
    ]);
  }

  factory QuantumMatrix.pauliX() {
    return QuantumMatrix([
      [Complex.zero(), Complex.one()],
      [Complex.one(), Complex.zero()],
    ]);
  }

  factory QuantumMatrix.pauliY() {
    return QuantumMatrix([
      [Complex.zero(), Complex(-Complex.i().real, -Complex.i().imaginary)],
      [Complex.i(), Complex.zero()],
    ]);
  }

  factory QuantumMatrix.pauliZ() {
    return QuantumMatrix([
      [Complex.one(), Complex.zero()],
      [Complex.zero(), Complex(-Complex.one().real, -Complex.one().imaginary)],
    ]);
  }

  /// Creates a rotation matrix for the X-axis.
  /// The matrix is defined as:
  /// [[cos(theta/2), -i * sin(theta/2)],
  /// [-i * sin(theta/2), cos(theta/2)]]
  factory QuantumMatrix.rx(double theta) {
    final cosTheta = cos(theta / 2.0);
    final sinTheta = sin(theta / 2.0);
    return QuantumMatrix([
      [Complex(cosTheta), Complex(0, -sinTheta)],
      [Complex(0, -sinTheta), Complex(cosTheta)],
    ]);
  }

  /// Creates a rotation matrix for the Y-axis.
  /// The matrix is defined as:
  /// [[cos(theta/2), -sin(theta/2)],
  /// [sin(theta/2), cos(theta/2)]]
  factory QuantumMatrix.ry(double theta) {
    final cosTheta = cos(theta / 2.0);
    final sinTheta = sin(theta / 2.0);
    return QuantumMatrix([
      [Complex(cosTheta), Complex(-sinTheta)],
      [Complex(sinTheta), Complex(cosTheta)],
    ]);
  }

  /// Creates a rotation matrix for the Z-axis.
  /// The matrix is defined as:
  /// [[e^(-i*theta/2), 0],
  /// [0, e^(i*theta/2)]]
  ///
  /// This implementation uses Euler's formula to represent the complex exponential:
  /// e^(ix) = cos(x) + i*sin(x)
  factory QuantumMatrix.rz(double theta) {
    final halfTheta = theta / 2.0;
    // e^(-i*theta/2) = cos(-theta/2) + i*sin(-theta/2)
    final complexTopLeft = Complex(cos(-halfTheta), sin(-halfTheta));
    // e^(i*theta/2) = cos(theta/2) + i*sin(theta/2)
    final complexBottomRight = Complex(cos(halfTheta), sin(halfTheta));
    return QuantumMatrix([
      [complexTopLeft, Complex.zero()],
      [Complex.zero(), complexBottomRight],
    ]);
  }

  factory QuantumMatrix.cz({
    required int control,
    required int target,
  }) =>
      QuantumMatrix.controlled(
          controls: [control],
          target: target,
          targetOperator: QuantumMatrix.pauliZ());

  factory QuantumMatrix.cnot({
    required int control,
    required int target,
  }) =>
      QuantumMatrix.controlled(
          controls: [control],
          target: target,
          targetOperator: QuantumMatrix.pauliX());

  /// Controlled Pauli-Y (v2.6 M7). In the local basis |control, target⟩:
  /// |10⟩ → i|11⟩ and |11⟩ → −i|10⟩ (Y = [[0, −i], [i, 0]]).
  factory QuantumMatrix.cy({
    required int control,
    required int target,
  }) =>
      QuantumMatrix.controlled(
          controls: [control],
          target: target,
          targetOperator: QuantumMatrix.pauliY());

  factory QuantumMatrix.ccnot({
    required int control1,
    required int control2,
    required int target,
  }) =>
      QuantumMatrix.controlled(
          controls: [control1, control2],
          target: target,
          targetOperator: QuantumMatrix.pauliX());

  /// Multi-controlled X with any number of controls (v2.6 M7).
  factory QuantumMatrix.mcx({
    required List<int> controls,
    required int target,
  }) =>
      QuantumMatrix.controlled(
          controls: controls,
          target: target,
          targetOperator: QuantumMatrix.pauliX());

  /// The one controlled-operation kernel (v2.6 M7): applies the 2×2
  /// [targetOperator] to [target] in every computational-basis component
  /// whose [controls] are all 1, and the identity elsewhere.
  ///
  /// The matrix spans only the qubits from the lowest to the highest operand
  /// (the circuit tensors it with the rest of its column), in the project's
  /// little-endian basis: bit k of a local index is qubit `min + k`. It is
  /// built column by column, with no Kronecker products of projectors, so
  /// it serves any control count; CX, CZ, CY, CCX and MCX all use it.
  factory QuantumMatrix.controlled({
    required List<int> controls,
    required int target,
    required QuantumMatrix targetOperator,
  }) {
    if (controls.isEmpty) {
      throw ArgumentError('A controlled operation needs a control.');
    }
    final operands = [...controls, target];
    if (operands.toSet().length != operands.length ||
        operands.any((q) => q < 0)) {
      throw ArgumentError(
          'Control and target qubits must be distinct and non-negative.');
    }
    final low = operands.reduce(min);
    final high = operands.reduce(max);
    final size = 1 << (high - low + 1);
    final targetBit = 1 << (target - low);
    final controlMask =
        controls.fold<int>(0, (mask, c) => mask | 1 << (c - low));
    final u = targetOperator.toComplexList();
    final elements =
        List.generate(size, (_) => List.filled(size, Complex.zero()));
    for (var column = 0; column < size; column++) {
      if (column & controlMask != controlMask) {
        elements[column][column] = Complex.one();
        continue;
      }
      final input = column & targetBit == 0 ? 0 : 1;
      final zero = column & ~targetBit;
      elements[zero][column] = u[0][input];
      elements[zero | targetBit][column] = u[1][input];
    }
    return QuantumMatrix(elements);
  }

  // Getter for the underlying matrix_utils.Matrix
  Matrix get rawMatrix => _matrix;

  int get rowCount => _matrix.rowCount;
  int get columnCount => _matrix.columnCount;

  Iterable<List> get rows => _matrix.rows;
  Iterable<List> get cols => _matrix.columns;

  List<List<Complex>> toComplexList() {
    return List.generate(
      rowCount,
      (row) => List.generate(
        columnCount,
        (col) => _matrix.row(row).getValueAt(col) as Complex,
      ),
    );
  }

  // (a + ib) (c + id) = (ac - bd) + i(ad + bc)
  Complex multiply(Complex x, Complex y) => Complex(
      x.real * y.real - x.imaginary * y.imaginary,
      x.real * y.imaginary + x.imaginary * y.real);

  // Apply a quantum gate (matrix multiplication)
  // This will handle both matrix-matrix and matrix-vector multiplication
  QuantumMatrix dot(QuantumMatrix other) {
    final result = _matrix.dot(other.rawMatrix);
    // Ensure the result's elements are correctly cast to List<List<Complex>>
    return QuantumMatrix.fromMatrix(result);
  }

  // Adds two matrices.
  QuantumMatrix add(QuantumMatrix other) {
    Matrix matrix = _matrix + other.rawMatrix;
    return QuantumMatrix.fromMatrix(matrix);
  }

  // Kronecker Product (Tensor Product) - Essential for multi-qubit systems
  // A ⊗ B
  QuantumMatrix tensorProduct(QuantumMatrix other) {
    final newRows = rowCount * other.rowCount;
    final newCols = columnCount * other.columnCount;

    final List<List<Complex>> resultElements =
        List.generate(newRows, (i) => List.filled(newCols, Complex.zero()));

    for (int i = 0; i < rowCount; i++) {
      for (int j = 0; j < columnCount; j++) {
        final Complex elementA = _matrix.row(i).getValueAt(j) as Complex;

        for (int r = 0; r < other.rowCount; r++) {
          for (int c = 0; c < other.columnCount; c++) {
            final Complex elementB =
                other._matrix.row(r).getValueAt(c) as Complex;
            resultElements[i * other.rowCount + r][j * other.columnCount + c] =
                multiply(elementA, elementB);
          }
        }
      }
    }
    return QuantumMatrix(resultElements);
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
        if ((c1.real - c2.real).abs() > tolerance ||
            (c1.imaginary - c2.imaginary).abs() > tolerance) {
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
