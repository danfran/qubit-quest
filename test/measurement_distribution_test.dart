// v2.6 M4: exact measurement distributions, marginalisation, classical-bit
// mapping, conditional states and the probability display policy. Expected
// values are derived by hand in the comments, never from the code under test.
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_executor.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/models/measurement_distribution.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/utils/probability_format.dart';

int _id = 0;

/// Ops are given as (column, op) in execution order.
CircuitProgram prog(int n, int c, List<CircuitOperation> ops) => CircuitProgram(
      qubitCount: n,
      classicalBitCount: c,
      initialState: List.generate(1 << n, (i) => Complex(i == 0 ? 1 : 0, 0)),
      operations: ops,
    );

UnitaryOperation g(int col, SelectedGateType t,
        {int q = 0, int? ctl, int? ctl2, double? angle}) =>
    UnitaryOperation(
      id: GateId(++_id),
      column: col,
      target: q,
      control: ctl,
      secondControl: ctl2,
      gate: Gate.fromIdentifier(t, angle: angle),
    );

MeasureZOperation m(int col, int q, int c) => MeasureZOperation(
    id: GateId(++_id), column: col, qubit: q, classicalBit: c);

const _h = SelectedGateType.hadamard;
const _x = SelectedGateType.x;

Map<String, double> exactOf(CircuitProgram p) =>
    ExactMeasurementDistribution.explicit(p).probabilities!;

void expectDist(Map<String, double> actual, Map<String, double> expected) {
  expect(actual.keys.toSet(), expected.keys.toSet());
  for (final e in expected.entries) {
    expect(actual[e.key], closeTo(e.value, 1e-12), reason: e.key);
  }
}

void expectState(List<Complex> actual, Map<int, Complex> nonZero, int n) {
  expect(actual.length, 1 << n);
  for (var i = 0; i < actual.length; i++) {
    final want = nonZero[i] ?? Complex(0, 0);
    expect(actual[i].real, closeTo(want.real.toDouble(), 1e-12), reason: '$i');
    expect(actual[i].imaginary, closeTo(want.imaginary.toDouble(), 1e-12),
        reason: '$i');
  }
}

/// Runs one shot choosing measurement outcomes through [draws] (u < p0 → 0).
CircuitShotResult shotWith(CircuitProgram p, List<double> draws) {
  var i = 0;
  return CircuitExecutor(nextDouble: () => draws[i++]).runShot(p);
}

void main() {
  final r2 = 1 / math.sqrt(2);

  group('final-state sampling (no M operations)', () {
    test('H: 50/50, labels match the sampler', () {
      final d = ExactMeasurementDistribution.finalState(
          [Complex(r2, 0), Complex(r2, 0)], 1);
      expect(d.mode, MeasurementMode.finalStateSampling);
      expectDist(d.probabilities!, {'0': .5, '1': .5});
      final sampled = FinalStateSampler(random: math.Random(1))
          .runShots([Complex(r2, 0), Complex(r2, 0)], 1, shots: 200);
      expect(d.readout.bits, sampled.readout.bits);
      expect(sampled.counts.keys.every(d.isPossible), isTrue);
    });

    test('H then Z (|−⟩): phase leaves probabilities 50/50', () {
      final d = ExactMeasurementDistribution.finalState(
          [Complex(r2, 0), Complex(-r2, 0)], 1);
      expectDist(d.probabilities!, {'0': .5, '1': .5});
    });

    test('dense five-qubit state: 32 outcomes of 1/32, total 1', () {
      final a = 1 / math.sqrt(32);
      final d = ExactMeasurementDistribution.finalState(
          List.generate(32, (_) => Complex(a, 0)), 5);
      expect(d.probabilities, hasLength(32));
      for (final p in d.probabilities!.values) {
        expect(p, closeTo(1 / 32, 1e-15));
      }
      expect(d.total, closeTo(1, 1e-12));
      expect(formatProbability(d.probabilities!.values.first), '3.125%');
    });
  });

  group('explicit measurement: exact distributions', () {
    test('X then M: outcome 1 with certainty', () {
      expectDist(exactOf(prog(1, 1, [g(0, _x), m(1, 0, 0)])), {'1': 1});
    });

    test('H then M: 50/50', () {
      expectDist(
          exactOf(prog(1, 1, [g(0, _h), m(1, 0, 0)])), {'0': .5, '1': .5});
    });

    for (final theta in [
      0.0,
      math.pi / 4,
      math.pi / 2,
      3 * math.pi / 4,
      math.pi
    ]) {
      test('H·Rz(θ)·H then M: P(0)=cos²(θ/2), θ=$theta', () {
        final d = exactOf(prog(1, 1, [
          g(0, _h),
          g(1, SelectedGateType.rz, angle: theta),
          g(2, _h),
          m(3, 0, 0),
        ]));
        final p0 = math.pow(math.cos(theta / 2), 2).toDouble();
        expect(d['0'] ?? 0, closeTo(p0, 1e-12));
        expect(d['1'] ?? 0, closeTo(1 - p0, 1e-12));
      });
    }

    final bell = [g(0, _h, q: 0), g(1, SelectedGateType.cnot, q: 1, ctl: 0)];

    test('Bell, both measured: only 00 and 11', () {
      final d = exactOf(prog(2, 2, [...bell, m(2, 0, 0), m(2, 1, 1)]));
      expectDist(d, {'00': .5, '11': .5});
    });

    test('Bell, only q0 measured: marginal 50/50, one-bit outcomes', () {
      final p = prog(2, 2, [...bell, m(2, 0, 0)]);
      final d = ExactMeasurementDistribution.explicit(p);
      expect(d.readout.bits, [0], reason: 'only c0 is written');
      expectDist(d.probabilities!, {'0': .5, '1': .5});
      // Conditional states: outcome 0 → |00⟩, outcome 1 → |11⟩.
      expectState(shotWith(p, [0.1]).quantumState, {0: Complex(1, 0)}, 2);
      expectState(shotWith(p, [0.9]).quantumState, {3: Complex(1, 0)}, 2);
    });

    test('GHZ then H on the measured qubit: superposition survives', () {
      // GHZ (|000⟩+|111⟩)/√2, then H on q0:
      //   ½(|000⟩ + |001⟩ + |110⟩ − |111⟩)   (kets written |q2 q1 q0⟩)
      // Measuring q0: P(0) = P(1) = ½.
      //   0 → (|000⟩ + |110⟩)/√2,   1 → (|001⟩ − |111⟩)/√2
      // so q1 q2 stay entangled in both branches.
      final p = prog(3, 1, [
        g(0, _h, q: 0),
        g(1, SelectedGateType.cnot, q: 1, ctl: 0),
        g(2, SelectedGateType.cnot, q: 2, ctl: 0),
        g(3, _h, q: 0),
        m(4, 0, 0),
      ]);
      expectDist(exactOf(p), {'0': .5, '1': .5});
      expectState(shotWith(p, [0.2]).quantumState,
          {0: Complex(r2, 0), 6: Complex(r2, 0)}, 3);
      expectState(shotWith(p, [0.8]).quantumState,
          {1: Complex(r2, 0), 7: Complex(-r2, 0)}, 3);
    });
  });

  group('classical-bit mapping', () {
    // q0 = 1 always, q1 = 0 (unmeasured), q2 = 1 with P = sin²(π/6) = ¼.
    List<CircuitOperation> asym() => [
          g(0, _x, q: 0),
          g(0, SelectedGateType.ry, q: 2, angle: math.pi / 3),
        ];

    test('q0 → c2, q2 → c0 (sparse: c1 unwritten)', () {
      final p = prog(3, 3, [...asym(), m(1, 0, 2), m(1, 2, 0)]);
      final d = ExactMeasurementDistribution.explicit(p);
      expect(d.readout.orderLabel, 'c2 c0');
      // label = c2 c0 = q0 q2
      expectDist(d.probabilities!, {'10': .75, '11': .25});
    });

    test('swapped: q0 → c0, q2 → c2', () {
      // label = c2 c0 = q2 q0
      expectDist(exactOf(prog(3, 3, [...asym(), m(1, 0, 0), m(1, 2, 2)])),
          {'01': .75, '11': .25});
    });

    test('insertion order within a column does not matter', () {
      final a = exactOf(prog(3, 3, [...asym(), m(1, 0, 2), m(1, 2, 0)]));
      final b = exactOf(prog(3, 3, [...asym(), m(1, 2, 0), m(1, 0, 2)]));
      expectDist(a, b);
    });

    test('non-consecutive bits in a wide register: q0 → c4, q2 → c1', () {
      final d = ExactMeasurementDistribution.explicit(
          prog(3, 5, [...asym(), m(1, 0, 4), m(1, 2, 1)]));
      expect(d.readout.orderLabel, 'c4 c1');
      expectDist(d.probabilities!, {'10': .75, '11': .25});
    });

    test('labels agree with the executor through the runner', () {
      final p = prog(3, 3, [...asym(), m(1, 0, 2), m(1, 2, 0)]);
      final d = ExactMeasurementDistribution.explicit(p);
      final observed = MeasuredCircuitRunner(
              executor: CircuitExecutor(nextDouble: math.Random(3).nextDouble))
          .runShots(p, shots: 400);
      expect(observed.readout.bits, d.readout.bits);
      expect(observed.counts.keys.every(d.isPossible), isTrue);
    });
  });

  group('measurement ordering', () {
    test('measurement followed by an operation on another qubit', () {
      // H q0; M q0 → c0; X q1; M q1 → c1: c1 c0 ∈ {10, 11}, ½ each.
      final p = prog(2, 2, [
        g(0, _h, q: 0),
        m(1, 0, 0),
        g(2, _x, q: 1),
        m(3, 1, 1),
      ]);
      expectDist(exactOf(p), {'10': .5, '11': .5});
      // The later X is part of the conditional final state: c0 = 1 → |11⟩.
      expectState(shotWith(p, [0.9]).quantumState, {3: Complex(1, 0)}, 2);
      // The terminal-per-qubit pre-measurement state agrees.
      final pre = PreMeasurementState.of(() => p);
      final fromPre = <String, double>{};
      for (var i = 0; i < 4; i++) {
        final a = pre.stateVector![i];
        final w = (a.real * a.real + a.imaginary * a.imaginary).toDouble();
        if (w > 0) {
          final label = '${(i >> 1) & 1}${i & 1}'; // c1 c0 = q1 q0
          fromPre[label] = (fromPre[label] ?? 0) + w;
        }
      }
      expectDist(fromPre, {'10': .5, '11': .5});
    });

    test('operations after a measurement on the same qubit (legacy)', () {
      // H; M → c0; H; M → c1: independent fair bits, 4 outcomes of ¼.
      // No single pre-measurement state exists, but the exact
      // distribution of this experiment does.
      final p = prog(1, 2, [g(0, _h), m(1, 0, 0), g(2, _h), m(3, 0, 1)]);
      expect(PreMeasurementState.of(() => p).isAvailable, isFalse);
      expectDist(exactOf(p), {'00': .25, '01': .25, '10': .25, '11': .25});
    });

    test('exact distribution matches 10,000 executor samples', () {
      final p = prog(3, 3, [
        g(0, _h, q: 0),
        g(0, SelectedGateType.ry, q: 1, angle: 1.1),
        g(1, SelectedGateType.cnot, q: 2, ctl: 0),
        m(2, 1, 0),
        g(3, SelectedGateType.rx, q: 2, angle: 0.7),
        m(4, 2, 2),
        m(4, 0, 1),
      ]);
      final d = exactOf(p);
      expect(d.values.fold<double>(0, (s, v) => s + v), closeTo(1, 1e-12));
      const n = 10000;
      final counts = CircuitExecutor(nextDouble: math.Random(42).nextDouble)
          .runShots(p, shots: n)
          .counts;
      for (final label in {...d.keys, ...counts.keys}) {
        final pr = d[label] ?? 0;
        final f = (counts[label] ?? 0) / n;
        final sigma = math.sqrt(math.max(pr * (1 - pr), 1e-9) / n);
        expect((f - pr).abs(), lessThan(5 * sigma + 1e-9), reason: label);
      }
    });
  });

  group('exact versus observed comparison', () {
    final exact = ExactMeasurementDistribution.finalState(
        [Complex(math.sqrt(.9), 0), Complex(math.sqrt(.1), 0)], 1);
    ShotsOutcome shots(Map<String, int> counts) => ShotsOutcome(
        readout: exact.readout,
        shots: counts.values.fold(0, (a, b) => a + b),
        counts: counts);

    test('before sampling: exact only, no artificial observations', () {
      final c = MeasurementComparison.build(exact: exact);
      expect(c.rows.map((r) => r.outcome), ['0', '1']);
      expect(
          c.rows.every((r) => r.count == null && r.frequency == null), isTrue);
    });

    test('possible but unobserved outcomes stay listed', () {
      final c =
          MeasurementComparison.build(exact: exact, observed: shots({'0': 5}));
      final one = c.rows.singleWhere((r) => r.outcome == '1');
      expect(one.count, 0);
      expect(one.exact, closeTo(.1, 1e-12));
      expect(c.rows.singleWhere((r) => r.outcome == '0').frequency, 1);
    });

    test('zero-probability outcomes appear only under All outcomes', () {
      final bell = ExactMeasurementDistribution.explicit(prog(2, 2, [
        g(0, _h, q: 0),
        g(1, SelectedGateType.cnot, q: 1, ctl: 0),
        m(2, 0, 0),
        m(2, 1, 1),
      ]));
      expect(
          MeasurementComparison.build(exact: bell).rows.map((r) => r.outcome),
          ['00', '11']);
      final all =
          MeasurementComparison.build(exact: bell, filter: OutcomeFilter.all);
      expect(all.rows.map((r) => r.outcome), ['00', '01', '10', '11']);
      expect(all.rows[1].exact, 0);
    });

    test('an observed outcome predicted impossible is shown and flagged', () {
      final certain = ExactMeasurementDistribution.finalState(
          [Complex(1, 0), Complex(0, 0)], 1);
      final c = MeasurementComparison.build(
          exact: certain,
          observed: ShotsOutcome(
              readout: certain.readout, shots: 3, counts: {'0': 2, '1': 1}));
      expect(c.rows.map((r) => r.outcome), ['0', '1']);
      expect(c.hasUnexpected, isTrue);
    });

    test('frequency uses the executed shot count', () {
      final c = MeasurementComparison.build(
          exact: exact, observed: shots({'0': 876, '1': 124}));
      expect(c.observed!.shots, 1000);
      expect(c.rows.first.frequency, closeTo(.876, 1e-15));
    });
  });

  group('probability display policy', () {
    test('adaptive precision', () {
      expect(formatProbability(.5), '50%');
      expect(formatProbability(1 / 32), '3.125%');
      expect(formatProbability(3 / 32), '9.375%');
      expect(formatProbability(.125), '12.5%');
      expect(formatProbability(math.pow(math.cos(math.pi / 8), 2).toDouble()),
          '85.36%');
      expect(formatProbability(.4267766952966369), '42.68%');
      expect(formatProbability(1 / 3), '33.33%');
      expect(formatProbability(.51), '51%');
    });

    test('never 0% for non-zero, never 100% below certainty', () {
      expect(formatProbability(0), '0%');
      expect(formatProbability(1e-14), '0%', reason: 'numerical zero');
      expect(formatProbability(1e-6), '<0.01%');
      expect(formatProbability(.00004), '<0.01%');
      expect(formatProbability(1 - 1e-6), '>99.99%');
      expect(formatProbability(1), '100%');
      expect(formatProbability(1 - 1e-14), '100%');
    });
  });
}
