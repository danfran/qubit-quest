import 'package:advance_math/advance_math.dart';

List<Complex> binaryStringToInitialStateVector(String binaryQubitString, int expectedNumQubits) {
  if (binaryQubitString.isEmpty) {
    throw ArgumentError('The binary qubit string cannot be empty.');
  }
  final int numQubits = binaryQubitString.length;
  if (expectedNumQubits != numQubits) {
    throw ArgumentError('The expected number of qubits is not equal to the number of qubits in the binary string.');
  }
  final int vectorSize = 1 << numQubits;
  final int initialBasisIndex = int.parse(binaryQubitString, radix: 2);

  final List<Complex> stateVector = List.filled(vectorSize, Complex.zero());
  stateVector[initialBasisIndex] = Complex.one();
  return stateVector;
}