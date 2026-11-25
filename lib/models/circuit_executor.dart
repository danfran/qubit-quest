import 'dart:math' as math;
import 'package:advance_math/advance_math.dart';
import 'circuit_program.dart';
import 'quantum_matrix.dart';
import 'selected_gate_type.dart';

class CircuitExecutionException implements Exception {
  const CircuitExecutionException(this.message);
  final String message;
  @override
  String toString() => 'CircuitExecutionException: $message';
}

class CircuitShotResult {
  CircuitShotResult(List<Complex> state, this.classicalState)
      : _state = List.unmodifiable(
            state.map((a) => (a.real.toDouble(), a.imaginary.toDouble())));
  final List<(double, double)> _state;
  final ClassicalState classicalState;
  List<Complex> get quantumState =>
      List.unmodifiable(_state.map((a) => Complex(a.$1, a.$2)));
}

class CircuitShotsResult {
  CircuitShotsResult(this.shots, Map<String, int> counts)
      : counts = Map.unmodifiable(counts);
  final int shots;

  /// Observed classical frequencies, not theoretical probabilities.
  final Map<String, int> counts;
}

/// Independent trajectories; q0 is the least-significant bit. Never mutates a
/// program or the existing ideal-state simulator. No overall measured unitary.
class CircuitExecutor {
  CircuitExecutor({double Function()? nextDouble})
      : _draw = nextDouble ?? math.Random().nextDouble;
  final double Function() _draw;
  static const double normTolerance = 1e-6;
  static const int maxShots = 10000;
  static const int maxQubits = 10;
  static const int maxWork = 10000000;

  void _budget(CircuitProgram p, int shots) {
    if (shots < 1 ||
        shots > maxShots ||
        p.qubitCount > maxQubits ||
        shots * (1 << p.qubitCount) * (p.operations.length + 1) > maxWork) {
      throw const CircuitExecutionException('Execution budget exceeded');
    }
  }

  CircuitShotResult runShot(CircuitProgram program) {
    _budget(program, 1);
    var state = program.initialState.toList();
    // Revalidate immutable snapshots at the execution boundary.
    CircuitProgram(
        qubitCount: program.qubitCount,
        classicalBitCount: program.classicalBitCount,
        initialState: state,
        operations: program.operations);
    _normalize(state);
    var classical = ClassicalState(program.classicalBitCount);
    for (final op in program.operations) {
      switch (op) {
        case UnitaryOperation():
          _apply(state, op);
          _normalize(state);
        case MeasureZOperation():
          final mass = _outcomeMasses(state, op.qubit);
          final total = mass[0] + mass[1];
          final int outcome;
          if (mass[0] == 0) {
            outcome = 1;
          } else if (mass[1] == 0) {
            outcome = 0;
          } else {
            final u = _draw();
            if (!u.isFinite || u < 0 || u >= 1) {
              throw const CircuitExecutionException(
                  'Random draw must be in [0,1)');
            }
            outcome = u < mass[0] / total ? 0 : 1;
          }
          _project(state, op.qubit, outcome, mass[outcome]);
          classical = classical.write(op.classicalBit, outcome);
      }
    }
    return CircuitShotResult(state, classical);
  }

  /// Largest number of measurement branches [exactDistribution] follows.
  static const int maxExactBranches = 4096;

  /// The exact probability of every classical register value the program
  /// can produce, keyed by [ClassicalState.label] (highest bit first, `?`
  /// for bits no measurement writes).
  ///
  /// Follows **both** outcomes of every measurement, weighted by its Born
  /// probability, using the same gate application and projection as
  /// [runShot]. It therefore describes exactly the experiment that [runShot]
  /// and [runShots] sample, including measurements followed by operations on
  /// other qubits. Outcomes with exactly zero probability are skipped, as
  /// [runShot] never draws them. Deterministic: no random draws.
  Map<String, double> exactDistribution(CircuitProgram program) {
    _budget(program, 1);
    final initial = program.initialState.toList();
    CircuitProgram(
        qubitCount: program.qubitCount,
        classicalBitCount: program.classicalBitCount,
        initialState: initial,
        operations: program.operations);
    _normalize(initial);
    final result = <String, double>{};
    var branches = 1;
    void follow(int index, List<Complex> state, ClassicalState classical,
        double probability) {
      for (var i = index; i < program.operations.length; i++) {
        final op = program.operations[i];
        switch (op) {
          case UnitaryOperation():
            _apply(state, op);
            _normalize(state);
          case MeasureZOperation():
            final mass = _outcomeMasses(state, op.qubit);
            final total = mass[0] + mass[1];
            final outcomes = [
              for (final b in [0, 1])
                if (mass[b] > 0) b
            ];
            if (outcomes.length == 2 && ++branches > maxExactBranches) {
              throw const CircuitExecutionException(
                  'Exact distribution budget exceeded');
            }
            for (final b in outcomes) {
              final next = b == outcomes.last ? state : state.toList();
              _project(next, op.qubit, b, mass[b]);
              follow(i + 1, next, classical.write(op.classicalBit, b),
                  probability * mass[b] / total);
            }
            return;
        }
      }
      result[classical.label] = (result[classical.label] ?? 0) + probability;
    }

    follow(0, initial, ClassicalState(program.classicalBitCount), 1);
    return {for (final k in result.keys.toList()..sort()) k: result[k]!};
  }

  /// Born probabilities of measuring 0 and 1 on [qubit].
  List<double> _outcomeMasses(List<Complex> state, int qubit) {
    final mass = [0.0, 0.0];
    for (var i = 0; i < state.length; i++) {
      mass[(i >> qubit) & 1] += _weight(state[i]);
    }
    final total = mass[0] + mass[1];
    if (!total.isFinite || total <= 0 || (total - 1).abs() > normTolerance) {
      throw const CircuitExecutionException('Invalid measurement probability');
    }
    return mass;
  }

  /// Projects [state] onto [outcome] of [qubit] and renormalises (P|ψ⟩/√p).
  void _project(List<Complex> state, int qubit, int outcome, double mass) {
    final scale = math.sqrt(mass);
    if (scale == 0 || !scale.isFinite) {
      throw const CircuitExecutionException('Cannot project zero probability');
    }
    for (var i = 0; i < state.length; i++) {
      state[i] = ((i >> qubit) & 1) == outcome
          ? Complex(state[i].real / scale, state[i].imaginary / scale)
          : Complex.zero();
    }
    _normalize(state);
  }

  CircuitShotsResult runShots(CircuitProgram program, {required int shots}) {
    _budget(program, shots);
    final counts = <String, int>{};
    for (var i = 0; i < shots; i++) {
      final label = runShot(program).classicalState.label;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return CircuitShotsResult(
        shots, {for (final k in counts.keys.toList()..sort()) k: counts[k]!});
  }

  double _weight(Complex a) =>
      (a.real * a.real + a.imaginary * a.imaginary).toDouble();
  void _normalize(List<Complex> state) {
    final norm = state.fold<double>(0, (sum, a) => sum + _weight(a));
    if (!norm.isFinite || norm <= 0 || (norm - 1).abs() > normTolerance) {
      throw const CircuitExecutionException(
          'Nonfinite or non-normalized state');
    }
    final scale = math.sqrt(norm);
    for (var i = 0; i < state.length; i++) {
      state[i] = Complex(state[i].real / scale, state[i].imaginary / scale);
    }
  }

  void _apply(List<Complex> state, UnitaryOperation op) {
    // Reuse existing 2x2 gate mathematics. Apply to amplitude pairs where every
    // control is set, equivalent to the existing controlled operator projectors.
    final matrix = switch (op.gate.type) {
      SelectedGateType.hadamard => QuantumMatrix.hadamard(),
      SelectedGateType.s => QuantumMatrix.phaseS(),
      SelectedGateType.t => QuantumMatrix.t(),
      SelectedGateType.x ||
      SelectedGateType.cnot ||
      SelectedGateType.ccnot =>
        QuantumMatrix.pauliX(),
      SelectedGateType.y => QuantumMatrix.pauliY(),
      SelectedGateType.z || SelectedGateType.cz => QuantumMatrix.pauliZ(),
      SelectedGateType.rx => QuantumMatrix.rx(op.gate.angle!),
      SelectedGateType.ry => QuantumMatrix.ry(op.gate.angle!),
      SelectedGateType.rz => QuantumMatrix.rz(op.gate.angle!),
      _ =>
        throw const CircuitExecutionException('Unsupported unitary operation'),
    };
    final m = matrix.toComplexList();
    final target = 1 << op.target;
    final controls = (op.control == null ? 0 : 1 << op.control!) |
        (op.secondControl == null ? 0 : 1 << op.secondControl!);
    for (var i = 0; i < state.length; i++) {
      if ((i & target) != 0 || (i & controls) != controls) continue;
      final j = i | target;
      final a = state[i], b = state[j];
      state[i] = m[0][0] * a + m[0][1] * b;
      state[j] = m[1][0] * a + m[1][1] * b;
    }
  }
}
