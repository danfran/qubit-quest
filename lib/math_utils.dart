import 'package:complex/complex.dart';

// Helper function to multiply two 4x4 complex matrices (result = matrixA * matrixB)
List<List<Complex>> multiplyMatrices(List<List<Complex>> matrixA, List<List<Complex>> matrixB) {
  if (matrixA[0].length != matrixB.length || matrixA[0].length != 4 || matrixB.length != 4) {
    throw ArgumentError("Matrices must be 4x4 for multiplication.");
  }

  List<List<Complex>> resultMatrix = List.generate(4, (_) => List.filled(4, Complex.zero));

  for (int i = 0; i < 4; i++) { // Rows of result
    for (int j = 0; j < 4; j++) { // Columns of result
      Complex sum = Complex.zero;
      for (int k = 0; k < 4; k++) { // Summation index
        sum += matrixA[i][k] * matrixB[k][j];
      }
      resultMatrix[i][j] = sum;
    }
  }
  return resultMatrix;
}

// Define a 4x4 Identity matrix
List<List<Complex>> identityMatrix = [
  [Complex(1.0), Complex(0.0), Complex(0.0), Complex(0.0)],
  [Complex(0.0), Complex(1.0), Complex(0.0), Complex(0.0)],
  [Complex(0.0), Complex(0.0), Complex(1.0), Complex(0.0)],
  [Complex(0.0), Complex(0.0), Complex(0.0), Complex(1.0)],
];