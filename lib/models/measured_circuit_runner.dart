import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import 'circuit_executor.dart';
import 'circuit_program.dart';
import 'quantum_measurement_result.dart';

/// Thousands-grouped count, e.g. `10,000`.
String formatCount(int value) => value
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// Classical-register readout convention for measured circuits.
///
/// Outcome labels list only the classical bits that some measurement writes,
/// **highest classical index on the left** (as in Qiskit): with measurements
/// into c2 and c0, the label `10` means c2 = 1 and c0 = 0. Bits no measurement
/// writes are omitted because they are never assigned.
///
/// [ClassicalReadout.finalState] uses the same layout for final-state
/// sampling of an unmeasured circuit, with qubits in place of classical bits
/// (`q1 q0`, highest qubit on the left, as in `|10⟩`).
@immutable
class ClassicalReadout {
  const ClassicalReadout._(this.bits, this.width, {this.prefix = 'c'});

  /// Every qubit of an unmeasured circuit, highest first.
  factory ClassicalReadout.finalState(int numQubits) => ClassicalReadout._(
        List.unmodifiable([for (var q = numQubits - 1; q >= 0; q--) q]),
        numQubits,
        prefix: 'q',
      );

  /// `c` for classical bits written by measurements, `q` for qubits sampled
  /// from the final state.
  final String prefix;
  bool get isFinalState => prefix == 'q';

  factory ClassicalReadout.forProgram(CircuitProgram program) {
    final bits = {
      for (final op in program.operations)
        if (op is MeasureZOperation) op.classicalBit,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return ClassicalReadout._(
        List.unmodifiable(bits), program.classicalBitCount);
  }

  /// Measured classical bits, highest index first (label order).
  final List<int> bits;

  /// Full register width of the executed program.
  final int width;

  /// e.g. `c2 c0`.
  String get orderLabel => bits.map((b) => '$prefix$b').join(' ');

  /// Projects an executor register label ([ClassicalState.label], whose
  /// leftmost character is the highest bit) onto [bits].
  String outcomeOf(String registerLabel) {
    if (registerLabel.length != width) {
      throw ArgumentError.value(registerLabel, 'registerLabel');
    }
    return bits.map((b) => registerLabel[width - 1 - b]).join();
  }

  /// e.g. `c2=1, c0=0` for outcome `10`.
  String describe(String outcome) => [
        for (var i = 0; i < bits.length; i++) '$prefix${bits[i]}=${outcome[i]}',
      ].join(', ');
}

/// One measurement's observed value in a single run.
@immutable
class MeasurementReading {
  const MeasurementReading(this.measurement, this.value);
  final MeasureZOperation measurement;
  final int value;
}

@immutable
class SingleShotOutcome {
  const SingleShotOutcome({
    required this.readout,
    required this.outcome,
    required this.readings,
    required this.sharedBits,
    this.conditionalState,
  });
  final ClassicalReadout readout;

  /// The full register state this run left after executing every
  /// operation (each measurement projects P|ψ⟩/√p for its outcome), from the
  /// **same** execution that produced [outcome]. Null for final-state
  /// sampling, which has no explicit measurement to condition on.
  final List<Complex>? conditionalState;

  /// Compact outcome label in [ClassicalReadout] order.
  final String outcome;

  /// Per measurement, in execution order.
  final List<MeasurementReading> readings;

  /// Classical bits written by more than one measurement (legacy circuits);
  /// the register then holds the last written value.
  final Set<int> sharedBits;

  String get register => readout.describe(outcome);
}

@immutable
class ShotsOutcome {
  const ShotsOutcome({
    required this.readout,
    required this.shots,
    required this.counts,
  });
  final ClassicalReadout readout;
  final int shots;

  /// Observed outcomes (compact labels) to counts, in ascending label order.
  /// Every observed outcome is present; counts sum to [shots].
  final Map<String, int> counts;
}

/// Runs measured programs with the existing [CircuitExecutor]. Reads only the
/// immutable [CircuitProgram]; never touches the editable circuit or storage.
class MeasuredCircuitRunner {
  MeasuredCircuitRunner({CircuitExecutor? executor})
      : _executor = executor ?? CircuitExecutor();
  final CircuitExecutor _executor;

  static const List<int> shotOptions = [100, 1000, 10000];
  static const int defaultShots = 1000;
  static const int minShots = 1;
  static const int maxShots = CircuitExecutor.maxShots;

  /// Parses a typed shot count exactly: plain digits or `1,000`-style
  /// grouping, 1 to [maxShots]. Never rounds or substitutes a value; returns
  /// either the count or the reason it is rejected.
  static ({int? shots, String? error}) parseShots(String input) {
    final text = input.trim();
    final range = 'from ${formatCount(minShots)} to ${formatCount(maxShots)}';
    if (text.isEmpty) {
      return (shots: null, error: 'Enter a number of shots $range.');
    }
    if (!RegExp(r'^(\d+|\d{1,3}(,\d{3})+)$').hasMatch(text)) {
      return (shots: null, error: 'Shots must be a whole number $range.');
    }
    final digits =
        text.replaceAll(',', '').replaceFirst(RegExp('^0+(?=.)'), '');
    final value = digits.length > 6 ? null : int.tryParse(digits);
    if (value == null || value < minShots || value > maxShots) {
      return (shots: null, error: 'Choose $range shots.');
    }
    return (shots: value, error: null);
  }

  SingleShotOutcome runOnce(CircuitProgram program) {
    final readout = ClassicalReadout.forProgram(program);
    final shot = _executor.runShot(program);
    final state = shot.classicalState;
    final measurements = program.operations.whereType<MeasureZOperation>();
    final writers = <int, int>{};
    for (final m in measurements) {
      writers[m.classicalBit] = (writers[m.classicalBit] ?? 0) + 1;
    }
    return SingleShotOutcome(
      readout: readout,
      outcome: readout.outcomeOf(state.label),
      readings: [
        for (final m in measurements)
          MeasurementReading(m, state.bits[m.classicalBit]!),
      ],
      sharedBits: {
        for (final e in writers.entries)
          if (e.value > 1) e.key,
      },
      conditionalState: shot.quantumState,
    );
  }

  ShotsOutcome runShots(CircuitProgram program, {required int shots}) {
    final readout = ClassicalReadout.forProgram(program);
    final raw = _executor.runShots(program, shots: shots);
    final counts = <String, int>{};
    for (final entry in raw.counts.entries) {
      final label = readout.outcomeOf(entry.key);
      counts[label] = (counts[label] ?? 0) + entry.value;
    }
    return ShotsOutcome(
      readout: readout,
      shots: raw.shots,
      counts: Map.unmodifiable(
          {for (final k in counts.keys.toList()..sort()) k: counts[k]!}),
    );
  }
}

/// Final-state Z-basis sampling for circuits **without** M operations: each
/// shot measures every qubit of the ideal final state. Uses the existing
/// [QuantumMeasurementResult.sample] engine; results share the measured
/// panel's types so both modes render identically.
class FinalStateSampler {
  FinalStateSampler({math.Random? random}) : _random = random;
  final math.Random? _random;

  SingleShotOutcome runOnce(List<Complex> stateVector, int numQubits) {
    final readout = ClassicalReadout.finalState(numQubits);
    final result = QuantumMeasurementResult.sample(
        stateVector: stateVector,
        numQubits: numQubits,
        random: _random,
        shots: 1);
    return SingleShotOutcome(
      readout: readout,
      outcome: result.counts.keys.single,
      readings: const [],
      sharedBits: const {},
    );
  }

  ShotsOutcome runShots(List<Complex> stateVector, int numQubits,
      {required int shots}) {
    if (shots < MeasuredCircuitRunner.minShots ||
        shots > MeasuredCircuitRunner.maxShots) {
      throw ArgumentError.value(shots, 'shots');
    }
    final result = QuantumMeasurementResult.sample(
        stateVector: stateVector,
        numQubits: numQubits,
        random: _random,
        shots: shots);
    return ShotsOutcome(
      readout: ClassicalReadout.finalState(numQubits),
      shots: result.shots,
      counts: result.counts,
    );
  }
}

/// The quantum state immediately before measurement, for the State and Bloch
/// views of a measured circuit, or the reason it cannot be shown.
///
/// Supported when every measurement is terminal for its qubit (no later
/// operation, including another measurement, touches that qubit). Each later
/// operation then acts on other qubits and commutes with the measurement, so
/// the circuit is equivalent to all of its gates followed by all of its
/// measurements, and "the state before measurement" is well defined.
///
/// Computed by running the existing [CircuitExecutor] on a program of the
/// circuit's unitary operations in program order. That program has no
/// measurement, so nothing is sampled and the result is the same on every
/// call. The circuit and its saved program are never changed.
@immutable
class PreMeasurementState {
  const PreMeasurementState._(this.stateVector, this.unavailableReason);

  /// [stateVector] is null exactly when [unavailableReason] is not.
  final List<Complex>? stateVector;
  final String? unavailableReason;
  bool get isAvailable => stateVector != null;

  static String notTerminal(int qubit) =>
      'An operation follows the measurement on q$qubit, so the state depends '
      'on random measurement outcomes. Use Measure to run the circuit.';
  static const failed = 'The state before measurement could not be '
      'calculated for this circuit. Use Measure to run it.';

  static PreMeasurementState of(
    CircuitProgram Function() build, {
    CircuitExecutor? executor,
  }) {
    try {
      final program = build();
      final operations = program.operations;
      final measured = <int>{};
      for (final op in operations) {
        final wires = switch (op) {
          MeasureZOperation() => [op.qubit],
          UnitaryOperation() => [op.target, ...op.controls],
        };
        for (final q in wires) {
          if (measured.contains(q)) {
            return PreMeasurementState._(null, notTerminal(q));
          }
        }
        if (op is MeasureZOperation) measured.add(op.qubit);
      }
      final unitary = CircuitProgram(
        qubitCount: program.qubitCount,
        classicalBitCount: program.classicalBitCount,
        initialState: program.initialState,
        operations: operations.whereType<UnitaryOperation>(),
      );
      final state =
          (executor ?? CircuitExecutor()).runShot(unitary).quantumState;
      return PreMeasurementState._(state, null);
    } on Object {
      return const PreMeasurementState._(null, failed);
    }
  }
}
