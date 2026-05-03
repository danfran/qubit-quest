import 'package:advance_math/advance_math.dart';

List<Complex> binaryStringToInitialStateVector(
    String binaryQubitString, int expectedNumQubits) {
  if (binaryQubitString.isEmpty) {
    throw ArgumentError('The binary qubit string cannot be empty.');
  }
  final int numQubits = binaryQubitString.length;
  if (expectedNumQubits != numQubits) {
    throw ArgumentError(
        'The expected number of qubits is not equal to the number of qubits in the binary string.');
  }
  final int vectorSize = 1 << numQubits;
  final int initialBasisIndex = int.parse(binaryQubitString, radix: 2);

  final List<Complex> stateVector = List.filled(vectorSize, Complex.zero());
  stateVector[initialBasisIndex] = Complex.one();
  return stateVector;
}

Complex fromEuler(double angleRadians) {
  return Complex(cos(angleRadians), sin(angleRadians));
}

bool complexClose(Complex a, Complex b, {double eps = 1e-9}) {
  return (a.real - b.real).abs() < eps &&
      (a.imaginary - b.imaginary).abs() < eps;
}

bool matrixClose(List<List<Complex>> a, List<List<Complex>> b,
    {double eps = 1e-9}) {
  if (a.length != b.length) {
    return false;
  }

  for (int row = 0; row < a.length; row++) {
    if (a[row].length != b[row].length) {
      return false;
    }

    for (int col = 0; col < a[row].length; col++) {
      if (!complexClose(a[row][col], b[row][col], eps: eps)) {
        return false;
      }
    }
  }

  return true;
}
