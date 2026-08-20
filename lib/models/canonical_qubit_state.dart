import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';

/// Display-neutral definitions for the six canonical pure qubit states.
enum CanonicalQubitState {
  zero('|0⟩'),
  one('|1⟩'),
  plus('|+⟩'),
  minus('|−⟩'),
  plusI('|+i⟩'),
  minusI('|−i⟩');

  const CanonicalQubitState(this.label);

  final String label;

  List<Complex> get amplitudes {
    final balanced = math.sqrt1_2;
    return switch (this) {
      zero => [Complex.one(), Complex.zero()],
      one => [Complex.zero(), Complex.one()],
      plus => [Complex(balanced), Complex(balanced)],
      minus => [Complex(balanced), Complex(-balanced)],
      plusI => [Complex(balanced), Complex(0, balanced)],
      minusI => [Complex(balanced), Complex(0, -balanced)],
    };
  }

  BlochState get blochState =>
      BlochState.fromAmplitudes(amplitudes[0], amplitudes[1]);

  static CanonicalQubitState? matching(
    BlochState state, {
    double tolerance = 1e-9,
  }) {
    for (final preset in values) {
      final candidate = preset.blochState;
      if ((candidate.x - state.x).abs() <= tolerance &&
          (candidate.y - state.y).abs() <= tolerance &&
          (candidate.z - state.z).abs() <= tolerance) {
        return preset;
      }
    }
    return null;
  }
}
