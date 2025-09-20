import 'package:advance_math/advance_math.dart';
import 'package:flutter/cupertino.dart';

import 'package:quantumquiz/utils/math_utils.dart'; // Import math for sqrt

// A wrapper for matrix_utils.Matrix to add quantum-specific operations
class QuantumMatrix {
  final Matrix _matrix;

  // Constructor now directly takes the List<List<Complex>>
  QuantumMatrix(List<List<Complex>> elements)
      : _matrix = Matrix(elements);

  QuantumMatrix.fromMatrix(Matrix matrix)
      : _matrix = matrix;

  QuantumMatrix.transpose(List<List<Complex>> elements)
      : _matrix = Matrix(elements).transpose();

  // Utility to create common quantum gates
  factory QuantumMatrix.identity(int size) {
    final List<List<Complex>> elements = List.generate(size, (i) => List.filled(size, Complex.zero()));
    for (int i = 0; i < size; i++) {
      elements[i][i] = Complex.one();
    }
    return QuantumMatrix(elements);
  }

  factory QuantumMatrix.hadamard() {
    final complexSqrtHalf = Complex(sqrt1_2, 0);
    return QuantumMatrix([
      [complexSqrtHalf, complexSqrtHalf],
      [complexSqrtHalf, Complex(-complexSqrtHalf.real, -complexSqrtHalf.imaginary)],
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
  }) {
    return QuantumMatrix.buildTwoQubitsGateOperator(control: control, target: target, targetOperator: QuantumMatrix.pauliZ());
  }

  factory QuantumMatrix.cnot({
    required int control,
    required int target,
  }) {
    return QuantumMatrix.buildTwoQubitsGateOperator(control: control, target: target, targetOperator: QuantumMatrix.pauliX());
  }

  factory QuantumMatrix.buildTwoQubitsGateOperator({
    required int control,
    required int target,
    required QuantumMatrix targetOperator
  }) {
    // if (control < 0 || control >= nQubits || target < 0 || target >= nQubits) {
    //   throw ArgumentError("Control or target qubit index out of range (0 to ${nQubits - 1}).");
    // }
    if (control == target) {
      throw ArgumentError("Control and target qubits cannot be the same.");
    }

    // should adapt control and target position relative to the number of qubits
    int nQubits = abs(control - target) + 1;
    int relPosition = max(control, target) - nQubits + 1;
    if (relPosition > 0) {
      control -= relPosition;
      target -= relPosition;
    }

    // Define 1-qubit gate matrices and projectors
    final QuantumMatrix I_1q = QuantumMatrix.identity(2);
    final QuantumMatrix X_1q = targetOperator;
    final QuantumMatrix P0_1q = QuantumMatrix([
      [Complex.one(), Complex.zero()],
      [Complex.zero(), Complex.zero()],
    ]); // |0><0|
    final QuantumMatrix P1_1q = QuantumMatrix([
      [Complex.zero(), Complex.zero()],
      [Complex.zero(), Complex.one()],
    ]); // |1><1|

    // Build the list of operators for each qubit for both terms
    List<QuantumMatrix> term0Ops = []; // For control is |0>
    List<QuantumMatrix> term1Ops = []; // For control is |1>

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
    QuantumMatrix kronTerm0 = term0Ops[nQubits - 1]; // Start with the leftmost qubit (Q_{N-1})
    for (int i = nQubits - 2; i >= 0; i--) {
      kronTerm0 = kronTerm0.tensorProduct(term0Ops[i]);
    }

    // Compute the tensor product for Term 1: I_{N-1} \otimes ... \otimes P1_control \otimes ... \otimes X_target \otimes ... \otimes I_0
    QuantumMatrix kronTerm1 = term1Ops[nQubits - 1]; // Start with the leftmost qubit (Q_{N-1})
    for (int i = nQubits - 2; i >= 0; i--) {
      kronTerm1 = kronTerm1.tensorProduct(term1Ops[i]);
    }

    // The CNOT matrix is the sum of these two terms
    return kronTerm0.add(kronTerm1);
  }

  factory QuantumMatrix.ccnot({
    required int control1,
    required int control2,
    required int target,
  }) {
    // 1. Validation for CCNOT
    // if (control1 < 0 || control1 >= nQubits ||
    //     control2 < 0 || control2 >= nQubits ||
    //     target < 0 || target >= nQubits) {
    //   throw ArgumentError("Control or target qubit index out of range (0 to ${nQubits - 1}).");
    // }
    if (control1 == control2 || control1 == target || control2 == target) {
      throw ArgumentError("Control and target qubits must be distinct for CCNOT.");
    }

    // should adapt control and target position relative to the number of qubits
    var lowestQubit = [control1, control2, target].reduce(min);
    var highestQubit = [control1, control2, target].reduce(max);
    int nQubits = highestQubit - lowestQubit + 1;
    if (nQubits < 3) {
      throw ArgumentError("CCNOT gate requires at least 3 qubits.");
    }
    int relPosition = highestQubit - nQubits + 1;
    if (relPosition > 0) {
      control1 -= relPosition;
      control2 -= relPosition;
      target -= relPosition;
    }

    // 2. Define 1-qubit gate matrices and projectors (re-using from CNOT logic)
    final QuantumMatrix I_1q = QuantumMatrix.identity(2);
    final QuantumMatrix X_1q = QuantumMatrix.pauliX();
    final QuantumMatrix P0_1q = QuantumMatrix([
      [Complex.one(), Complex.zero()],
      [Complex.zero(), Complex.zero()],
    ]); // |0><0|
    final QuantumMatrix P1_1q = QuantumMatrix([
      [Complex.zero(), Complex.zero()],
      [Complex.zero(), Complex.one()],
    ]); // |1><1|

    // 3. Initialize lists of operators for each of the four terms
    // Each list corresponds to a (Control1_state, Control2_state, Target_gate) scenario
    List<QuantumMatrix> term00Ops = []; // C1=0, C2=0, Target=I
    List<QuantumMatrix> term01Ops = []; // C1=0, C2=1, Target=I
    List<QuantumMatrix> term10Ops = []; // C1=1, C2=0, Target=I
    List<QuantumMatrix> term11Ops = []; // C1=1, C2=1, Target=X

    // 4. Populate the lists by iterating through all qubits (little-endian convention)
    for (int i = 0; i < nQubits; i++) {
      if (i == control1) {
        term00Ops.add(P0_1q); // C1 is 0
        term01Ops.add(P0_1q); // C1 is 0
        term10Ops.add(P1_1q); // C1 is 1
        term11Ops.add(P1_1q); // C1 is 1
      } else if (i == control2) {
        term00Ops.add(P0_1q); // C2 is 0
        term01Ops.add(P1_1q); // C2 is 1
        term10Ops.add(P0_1q); // C2 is 0
        term11Ops.add(P1_1q); // C2 is 1
      } else if (i == target) {
        term00Ops.add(I_1q); // Target is I
        term01Ops.add(I_1q); // Target is I
        term10Ops.add(I_1q); // Target is I
        term11Ops.add(X_1q); // Target is X only if both controls are 1
      } else {
        // For all other qubits, apply Identity
        term00Ops.add(I_1q);
        term01Ops.add(I_1q);
        term10Ops.add(I_1q);
        term11Ops.add(I_1q);
      }
    }

    // Helper function to compute the tensor product of a list of matrices
    // This maintains the little-endian convention (Q_N-1 \otimes ... \otimes Q_0)
    QuantumMatrix _computeFullTensorProduct(List<QuantumMatrix> ops) {
      QuantumMatrix result = ops[nQubits - 1]; // Start with the highest indexed qubit (leftmost in tensor product)
      for (int i = nQubits - 2; i >= 0; i--) {
        result = result.tensorProduct(ops[i]);
      }
      return result;
    }

    // 5. Compute tensor products for each of the four terms
    QuantumMatrix kronTerm00 = _computeFullTensorProduct(term00Ops);
    QuantumMatrix kronTerm01 = _computeFullTensorProduct(term01Ops);
    QuantumMatrix kronTerm10 = _computeFullTensorProduct(term10Ops);
    QuantumMatrix kronTerm11 = _computeFullTensorProduct(term11Ops);

    // 6. Sum the four terms to get the final CCNOT matrix
    return kronTerm00.add(kronTerm01).add(kronTerm10).add(kronTerm11);
  }

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