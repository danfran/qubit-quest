import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';

import 'package:quantumquiz/utils/probability_format.dart';

import 'circuit_executor.dart';
import 'circuit_program.dart';
import 'measured_circuit_runner.dart';

/// v2.6 M4 scientific results contract. Five distinct quantities:
///
/// * **Quantum state:** the state vector of a unitary circuit (State tab).
/// * **Exact probability:** a theoretical probability of a measurement
///   outcome ([ExactMeasurementDistribution]).
/// * **Observed frequency:** count / shots of sampled runs ([ShotsOutcome]).
/// * **Single-run outcome:** one sampled classical result ([SingleShotOutcome]).
/// * **Conditional state after execution:** the register state left by that
///   single run ([SingleShotOutcome.conditionalState]).
///
/// See `docs/v2.6/V26_MEASUREMENT_RESULTS.md`.
enum MeasurementMode {
  /// No M operations: every shot measures every qubit of the ideal final
  /// state in the Z basis ([FinalStateSampler]).
  finalStateSampling,

  /// M operations: every shot executes the circuit program, and outcomes are
  /// the classical bits the measurements write ([MeasuredCircuitRunner]).
  explicitMeasurement,
}

/// The exact probability distribution of the outcomes of the **same**
/// experiment that Run once and Run shots sample, keyed by the same outcome
/// labels ([ClassicalReadout]), or the reason it is unavailable.
@immutable
class ExactMeasurementDistribution {
  const ExactMeasurementDistribution._({
    required this.mode,
    required this.readout,
    this.probabilities,
    this.unavailableReason,
  });

  final MeasurementMode mode;
  final ClassicalReadout readout;

  /// Outcome label → exact probability for every outcome with non-zero
  /// probability, ascending by label; null when unavailable.
  final Map<String, double>? probabilities;
  final String? unavailableReason;

  bool get isAvailable => probabilities != null;

  /// Number of bits in an outcome label.
  int get outcomeWidth => readout.bits.length;

  /// Every label the readout can produce, ascending (2^[outcomeWidth]).
  List<String> get allOutcomes => [
        for (var i = 0; i < 1 << outcomeWidth; i++)
          i.toRadixString(2).padLeft(outcomeWidth, '0'),
      ];

  /// Exact probability of [outcome] (0 for impossible outcomes).
  double probabilityOf(String outcome) => probabilities?[outcome] ?? 0;

  /// Whether [outcome] has non-zero exact probability.
  bool isPossible(String outcome) =>
      probabilityOf(outcome) > probabilityZeroTolerance;

  /// Sum of the unrounded probabilities (1 for a valid distribution).
  double get total =>
      probabilities?.values.fold<double>(0, (s, p) => s + p) ?? 0;

  /// No exact prediction can be made; [reason] says why.
  factory ExactMeasurementDistribution.unavailable(
    MeasurementMode mode,
    ClassicalReadout readout,
    String reason,
  ) =>
      ExactMeasurementDistribution._(
        mode: mode,
        readout: readout,
        unavailableReason: reason,
      );

  /// Final-state sampling: P(x) = |αₓ|² for every basis state x, labelled
  /// `q(n−1)…q0` exactly as [FinalStateSampler] labels its samples.
  factory ExactMeasurementDistribution.finalState(
    List<Complex> stateVector,
    int numQubits,
  ) {
    final readout = ClassicalReadout.finalState(numQubits);
    if (stateVector.length != 1 << numQubits) {
      return ExactMeasurementDistribution._(
        mode: MeasurementMode.finalStateSampling,
        readout: readout,
        unavailableReason: 'The state does not match the qubit count.',
      );
    }
    final probabilities = <String, double>{};
    for (var i = 0; i < stateVector.length; i++) {
      final a = stateVector[i];
      final p = (a.real * a.real + a.imaginary * a.imaginary).toDouble();
      if (!p.isFinite) {
        return ExactMeasurementDistribution._(
          mode: MeasurementMode.finalStateSampling,
          readout: readout,
          unavailableReason: 'The state contains non-finite amplitudes.',
        );
      }
      if (p > 0) {
        probabilities[i.toRadixString(2).padLeft(numQubits, '0')] = p;
      }
    }
    return ExactMeasurementDistribution._(
      mode: MeasurementMode.finalStateSampling,
      readout: readout,
      probabilities: Map.unmodifiable(probabilities),
    );
  }

  /// Explicit measurements: the executor's exact branching distribution of
  /// the classical register ([CircuitExecutor.exactDistribution]), projected
  /// onto the measured classical bits. Measurements on a subset of qubits
  /// are therefore marginalised over the unmeasured qubits, and classical
  /// bits follow the circuit's actual mapping.
  factory ExactMeasurementDistribution.explicit(
    CircuitProgram program, {
    CircuitExecutor? executor,
  }) {
    final readout = ClassicalReadout.forProgram(program);
    try {
      final register =
          (executor ?? CircuitExecutor()).exactDistribution(program);
      final probabilities = <String, double>{};
      for (final entry in register.entries) {
        final outcome = readout.outcomeOf(entry.key);
        probabilities[outcome] = (probabilities[outcome] ?? 0) + entry.value;
      }
      return ExactMeasurementDistribution._(
        mode: MeasurementMode.explicitMeasurement,
        readout: readout,
        probabilities: Map.unmodifiable({
          for (final k in probabilities.keys.toList()..sort())
            k: probabilities[k]!,
        }),
      );
    } on CircuitExecutionException catch (e) {
      return ExactMeasurementDistribution._(
        mode: MeasurementMode.explicitMeasurement,
        readout: readout,
        unavailableReason: e.message == 'Exact distribution budget exceeded'
            ? 'This circuit branches into too many measurement outcomes to '
                'list exactly here. Observed results are still valid.'
            : 'The exact distribution could not be calculated '
                '(${e.message}). Observed results are still valid.',
      );
    }
  }
}

/// One outcome row of the exact-versus-observed comparison.
@immutable
class OutcomeComparison {
  const OutcomeComparison({
    required this.outcome,
    required this.exact,
    required this.count,
    required this.shots,
  });

  final String outcome;

  /// Exact probability; null when the exact distribution is unavailable.
  final double? exact;

  /// Observed count; null before any shots were run.
  final int? count;

  /// Shots of the observed experiment; null before any shots were run.
  final int? shots;

  double? get frequency =>
      count == null || shots == null || shots == 0 ? null : count! / shots!;

  /// Observed although the exact probability is zero: indicates an
  /// implementation or numerical problem and is always shown and flagged.
  bool get unexpected =>
      (count ?? 0) > 0 && exact != null && exact! <= probabilityZeroTolerance;
}

/// Which outcomes the comparison lists.
enum OutcomeFilter {
  /// Outcomes with non-zero exact probability plus every observed outcome.
  possibleOrObserved,

  /// Every outcome the classical readout can produce.
  all,
}

/// Exact-versus-observed rows for one experiment. Rows are the union of
/// relevant exact outcomes and observed outcomes; an observed outcome is
/// never hidden.
@immutable
class MeasurementComparison {
  const MeasurementComparison._(this.rows, this.observed, this.totalOutcomes);

  final List<OutcomeComparison> rows;

  /// The sampled experiment shown, if any.
  final ShotsOutcome? observed;

  /// How many outcomes the readout can produce (2^bits).
  final int totalOutcomes;

  factory MeasurementComparison.build({
    required ExactMeasurementDistribution exact,
    ShotsOutcome? observed,
    OutcomeFilter filter = OutcomeFilter.possibleOrObserved,
  }) {
    // Observed results from a different readout cannot be compared.
    final shots = observed != null &&
            listEquals(observed.readout.bits, exact.readout.bits) &&
            observed.readout.prefix == exact.readout.prefix
        ? observed
        : null;
    final labels = <String>{
      if (filter == OutcomeFilter.all) ...exact.allOutcomes,
      if (exact.isAvailable)
        ...exact.probabilities!.keys.where(exact.isPossible),
      ...?shots?.counts.keys,
    }.toList()
      ..sort();
    return MeasurementComparison._(
      List.unmodifiable([
        for (final label in labels)
          OutcomeComparison(
            outcome: label,
            exact: exact.isAvailable ? exact.probabilityOf(label) : null,
            count: shots == null ? null : (shots.counts[label] ?? 0),
            shots: shots?.shots,
          ),
      ]),
      shots,
      1 << exact.outcomeWidth,
    );
  }

  int get hiddenOutcomes => totalOutcomes - rows.length;
  bool get hasUnexpected => rows.any((r) => r.unexpected);
}
