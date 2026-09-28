import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';

/// Transient observations from independent all-qubit Z-basis shots.
/// Ownership and invalidation belong to the activity, not QuantumCircuit.
class QuantumMeasurementResult {
  QuantumMeasurementResult._(this.numQubits, Map<String, int> counts)
      : counts = Map.unmodifiable(counts);

  static const int defaultShots = 100;
  final int numQubits;
  final Map<String, int> counts;
  int get shots => defaultShots;

  /// Samples without modifying the ideal state. Keys use q0-LSB ordering.
  factory QuantumMeasurementResult.sample({
    required List<Complex> stateVector,
    required int numQubits,
    math.Random? random,
  }) {
    if (numQubits < 1 || stateVector.length != 1 << numQubits) {
      throw ArgumentError('Statevector size does not match the qubit count.');
    }
    final weights = stateVector.map((amplitude) {
      if (!amplitude.real.isFinite || !amplitude.imaginary.isFinite) {
        throw ArgumentError('Measurement requires finite amplitudes.');
      }
      final magnitude = amplitude.magnitude.toDouble();
      return magnitude * magnitude;
    }).toList(growable: false);
    final norm = weights.fold<double>(0, (sum, weight) => sum + weight);
    if (!norm.isFinite || norm <= 0 || (norm - 1).abs() > 1e-6) {
      throw ArgumentError('Measurement requires a normalized finite state.');
    }
    final support = <int>[];
    final cumulative = <double>[];
    var sum = 0.0;
    for (var index = 0; index < weights.length; index++) {
      if (weights[index] == 0) continue;
      sum += weights[index] / norm;
      support.add(index);
      cumulative.add(sum);
    }
    // Absorb rounding drift at the final supported outcome, never at |0...0⟩.
    cumulative[cumulative.length - 1] = 1;
    final rng = random ?? math.Random();
    final counts = <String, int>{};
    for (var shot = 0; shot < defaultShots; shot++) {
      final draw = rng.nextDouble();
      var position = 0;
      while (position < cumulative.length - 1 && draw >= cumulative[position]) {
        position++;
      }
      final bits = support[position].toRadixString(2).padLeft(numQubits, '0');
      counts[bits] = (counts[bits] ?? 0) + 1;
    }
    return QuantumMeasurementResult._(numQubits, {
      for (final bits in counts.keys.toList()..sort()) bits: counts[bits]!,
    });
  }
}
