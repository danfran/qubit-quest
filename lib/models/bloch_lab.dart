// The Bloch Explorer as a single-qubit state laboratory (v2.6 M8).
//
// Platform-neutral: no widgets, no web APIs. Gates evolve the exact
// amplitudes through the simulator's own matrices ([BlochState.applyGate]);
// measurement samples with the existing [FinalStateSampler] after a basis
// change. Nothing here touches the Sandbox, Journey, Mastery or Notebook
// progress.
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

/// Single-qubit unitaries the laboratory offers (the production gate set).
const List<SelectedGateType> blochLabGateTypes = [
  SelectedGateType.x,
  SelectedGateType.y,
  SelectedGateType.z,
  SelectedGateType.hadamard,
  SelectedGateType.s,
  SelectedGateType.t,
  SelectedGateType.rx,
  SelectedGateType.ry,
  SelectedGateType.rz,
];

bool blochLabIsRotation(SelectedGateType type) =>
    type == SelectedGateType.rx ||
    type == SelectedGateType.ry ||
    type == SelectedGateType.rz;

/// Builds the gate a lab step applies (rotations carry their angle).
Gate blochLabGate(SelectedGateType type, {double? angle}) =>
    Gate.fromIdentifier(type,
        angle: blochLabIsRotation(type) ? (angle ?? math.pi / 2) : null);

// ------------------------------------------------------------ measurement

/// A projective measurement basis for one qubit.
enum BlochBasis {
  z('Z', '|0⟩', '|1⟩'),
  x('X', '|+⟩', '|−⟩'),
  y('Y', '|+i⟩', '|−i⟩');

  const BlochBasis(this.label, this.plusLabel, this.minusLabel);
  final String label;

  /// The outcome for the +1 eigenstate (classical bit 0).
  final String plusLabel;

  /// The outcome for the −1 eigenstate (classical bit 1).
  final String minusLabel;

  /// The +1 eigenstate's Bloch axis.
  (double, double, double) get axis => switch (this) {
        BlochBasis.z => (0.0, 0.0, 1.0),
        BlochBasis.x => (1.0, 0.0, 0.0),
        BlochBasis.y => (0.0, 1.0, 0.0),
      };

  /// The unitary that maps this basis onto the computational basis, applied
  /// before a Z measurement: H for X, and S† then H (matrix H·S†) for Y.
  QuantumMatrix get basisChange => switch (this) {
        BlochBasis.z => QuantumMatrix.identity(2),
        BlochBasis.x => QuantumMatrix.hadamard(),
        BlochBasis.y => QuantumMatrix.hadamard().dot(_sDagger()),
      };

  static QuantumMatrix _sDagger() => QuantumMatrix([
        [Complex.one(), Complex.zero()],
        [Complex.zero(), Complex(0, -1)],
      ]);

  /// The state vector rotated into this basis: measuring it in Z is
  /// measuring the original state in this basis.
  List<Complex> rotate(BlochState state) {
    final m = basisChange.toComplexList();
    final a = state.alpha, b = state.beta;
    return [m[0][0] * a + m[0][1] * b, m[1][0] * a + m[1][1] * b];
  }

  /// Exact (P(+), P(−)) from the amplitudes after the basis change.
  (double, double) probabilities(BlochState state) {
    final v = rotate(state);
    double p(Complex c) =>
        (c.real * c.real + c.imaginary * c.imaginary).toDouble();
    final plus = p(v[0]), minus = p(v[1]);
    final total = plus + minus;
    return (plus / total, minus / total);
  }

  /// The same probability from the Bloch vector: (1 + r·n)/2. Shown beside
  /// the amplitude result as the geometric reading (equal by construction,
  /// verified in tests).
  double geometricPlusProbability(BlochState state) {
    final (nx, ny, nz) = axis;
    return (1 + state.x * nx + state.y * ny + state.z * nz) / 2;
  }

  /// The post-measurement state for an outcome (the basis eigenstate).
  BlochState eigenstate({required bool plus}) {
    final (nx, ny, nz) = axis;
    return plus
        ? BlochState.fromCartesian(nx, ny, nz)
        : BlochState.fromCartesian(-nx, -ny, -nz);
  }
}

/// One measurement of the prepared state (never applied to it).
@immutable
class BlochSingleMeasurement {
  const BlochSingleMeasurement(this.basis, this.plus);
  final BlochBasis basis;
  final bool plus;
  String get label => plus ? basis.plusLabel : basis.minusLabel;
  BlochState get postMeasurementState => basis.eigenstate(plus: plus);
}

/// Repeated, independent preparations of the same state, each measured once.
@immutable
class BlochShotsMeasurement {
  const BlochShotsMeasurement(this.basis, this.shots, this.plusCount);
  final BlochBasis basis;
  final int shots;
  final int plusCount;
  int get minusCount => shots - plusCount;
}

/// Measures with the existing [FinalStateSampler] on the basis-rotated
/// state: outcome "0" is the +1 eigenstate.
class BlochMeasurer {
  BlochMeasurer({math.Random? random})
      : _sampler = FinalStateSampler(random: random);
  final FinalStateSampler _sampler;

  BlochSingleMeasurement once(BlochState state, BlochBasis basis) {
    final outcome = _sampler.runOnce(basis.rotate(state), 1).outcome;
    return BlochSingleMeasurement(basis, outcome == '0');
  }

  BlochShotsMeasurement shots(BlochState state, BlochBasis basis, int shots) {
    final counts =
        _sampler.runShots(basis.rotate(state), 1, shots: shots).counts;
    return BlochShotsMeasurement(basis, shots, counts['0'] ?? 0);
  }
}

// ---------------------------------------------------------------- session

/// One applied gate: the gate, its input and output states and the Bloch
/// rotation used to draw it.
@immutable
class BlochLabStep {
  const BlochLabStep({
    required this.gate,
    required this.before,
    required this.after,
  });
  final Gate gate;
  final BlochState before;
  final BlochState after;
  BlochRotation get rotation => blochRotationFor(gate.type, angle: gate.angle)!;
  /// "H", or "Rz(π/2)" for rotations (unambiguous angle notation).
  String get label {
    final symbol = gate.label.split('\n').first;
    final angle = gate.angle;
    return angle == null
        ? symbol
        : '$symbol(${blochAngle(angle).split(' (').first})';
  }
}

/// Where an exploration came from, for its banner, reset and return path.
enum BlochLabOrigin { standalone, notebook, composer, comparison }

/// An isolated starting point: a prepared state and the authored gates.
@immutable
class BlochLabSeed {
  BlochLabSeed({
    required this.origin,
    required this.title,
    required this.initial,
    required this.initialLabel,
    Iterable<Gate> gates = const [],
    this.note,
    this.sourceId,
    this.returnLabel,
  }) : gates = List.unmodifiable(gates);

  final BlochLabOrigin origin;
  final String title;
  final BlochState initial;
  final String initialLabel;
  final List<Gate> gates;

  /// Explanation shown with the exploration (e.g. a measured circuit's note).
  final String? note;

  /// The originating Notebook article or example identity.
  final String? sourceId;

  /// Label of the return action ("Back to article", "Back to Composer").
  final String? returnLabel;
}

/// Seed for a Notebook example's "Explore in Bloch" (v2.6 M8): its authored
/// initial state and single-qubit operations, so every intermediate state
/// can be inspected. Null when the example is not a one-qubit, single-qubit
/// gate sequence.
BlochLabSeed? blochSeedForNotebookExample(ExecutableNotebookExample example) {
  if (example.qubitCount != 1) return null;
  if (example.operations
      .any((op) => !blochLabGateTypes.contains(op.gateType))) {
    return null;
  }
  final initial = example.initialState;
  return BlochLabSeed(
    origin: BlochLabOrigin.notebook,
    title: example.title,
    initial: BlochState.fromAmplitudes(initial[0], initial[1]),
    initialLabel: '|${example.initialBinaryState}⟩',
    gates: [
      for (final op in example.operations)
        blochLabGate(op.gateType, angle: op.angle),
    ],
    note: example.description,
    sourceId: example.id,
    returnLabel: 'Back to article',
  );
}

/// Seed for exploring a one-qubit Composer circuit (v2.6 M8). Its gates are
/// taken in circuit order. A measured circuit keeps its measurement out of
/// the exploration and says so: the explorer shows the state *before*
/// measurement (single-qubit circuits measure last). Null for multi-qubit
/// circuits: a subsystem of an entangled state has no pure single-qubit
/// state vector, and reduced states are not supported (M8 boundary).
BlochLabSeed? blochSeedForCircuit(QuantumCircuit circuit) {
  if (circuit.currentLevel.numQubits != 1) return null;
  final gates = [...circuit.logicalGates]
    ..sort((a, b) => a.column.compareTo(b.column));
  if (gates.any((g) => !blochLabGateTypes.contains(g.type))) return null;
  final initial = circuit.initialState.stateVector;
  final measured = circuit.hasMeasurements;
  return BlochLabSeed(
    origin: BlochLabOrigin.composer,
    title: 'Composer circuit',
    initial: BlochState.fromAmplitudes(initial[0], initial[1]),
    initialLabel: '|${circuit.currentLevel.initialQubitsStateStr}⟩',
    gates: [for (final g in gates) g.gate],
    note: measured
        ? 'This circuit ends with a measurement. The explorer shows the '
            'state before it is measured; use Measure here to sample it. '
            'The measurement itself is not applied.'
        : 'The gates of your one-qubit Composer circuit, step by step.',
    returnLabel: 'Back to Composer',
  );
}

/// A laboratory session: a prepared state, an applied-gate history with
/// undo/redo, read-only inspection of earlier steps, and previews that never
/// change the history.
///
/// History semantics:
/// - [commit] appends exactly one step at the current position and discards
///   any redo steps (the usual editor rule).
/// - While a step is being [inspect]ed the exploration is read-only:
///   [commit] is refused until [returnToCurrent].
/// - [prepare] starts a new exploration from a state (clears history).
/// - [reset] returns to the session's seed: its state and authored gates.
class BlochLabSession extends ChangeNotifier {
  BlochLabSession(this.seed) {
    _restoreSeed();
  }

  BlochLabSession.standalone()
      : this(BlochLabSeed(
          origin: BlochLabOrigin.standalone,
          title: 'Bloch Explorer',
          initial: BlochState.zero,
          initialLabel: '|0⟩',
        ));

  final BlochLabSeed seed;
  late BlochState _initial;
  late String _initialLabel;
  final List<BlochLabStep> _steps = [];
  int _applied = 0;
  int? _inspected;

  BlochState get initial => _initial;
  String get initialLabel => _initialLabel;

  /// Steps up to the current position (redo steps excluded).
  List<BlochLabStep> get appliedSteps =>
      List.unmodifiable(_steps.sublist(0, _applied));
  List<BlochLabStep> get allSteps => List.unmodifiable(_steps);
  int get appliedCount => _applied;
  bool get canUndo => _applied > 0 && _inspected == null;
  bool get canRedo => _applied < _steps.length && _inspected == null;

  /// The latest state of the exploration.
  BlochState get current => stateAt(_applied);

  /// The state after [index] applied steps (0 = the prepared state).
  BlochState stateAt(int index) =>
      index == 0 ? _initial : _steps[index - 1].after;

  /// Index being inspected, or null when showing the current state.
  int? get inspectedIndex => _inspected;
  bool get isInspecting => _inspected != null;

  /// What the information panels show: the inspected or the current state.
  BlochState get displayed => stateAt(_inspected ?? _applied);

  /// Gate preview from the current state (pure: nothing is recorded). The
  /// input is always [current], so moving an angle slider any number of
  /// times gives the same result as setting the final angle once.
  BlochLabStep preview(SelectedGateType type, {double? angle}) {
    final gate = blochLabGate(type, angle: angle);
    return BlochLabStep(
      gate: gate,
      before: current,
      after: current.applyGate(type, angle: gate.angle ?? math.pi / 2),
    );
  }

  /// Applies one gate. Returns the step, or null while inspecting.
  BlochLabStep? commit(SelectedGateType type, {double? angle}) {
    if (_inspected != null) return null;
    final step = preview(type, angle: angle);
    _steps
      ..removeRange(_applied, _steps.length)
      ..add(step);
    _applied++;
    notifyListeners();
    return step;
  }

  void undo() {
    if (!canUndo) return;
    _applied--;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _applied++;
    notifyListeners();
  }

  void inspect(int index) {
    if (index < 0 || index > _applied) return;
    _inspected = index == _applied ? null : index;
    notifyListeners();
  }

  void returnToCurrent() {
    if (_inspected == null) return;
    _inspected = null;
    notifyListeners();
  }

  /// Starts a new exploration from [state] (history cleared).
  void prepare(BlochState state, String label) {
    _initial = state;
    _initialLabel = label;
    _steps.clear();
    _applied = 0;
    _inspected = null;
    notifyListeners();
  }

  /// Resets the exploration. For a seeded exploration (Notebook, Composer,
  /// comparison) this restores the seed: its state and authored gates. In
  /// the standalone lab it returns to the prepared state with no gates, so
  /// a state the learner prepared is never discarded by Reset.
  void reset() {
    if (seed.origin == BlochLabOrigin.standalone) {
      _steps.clear();
      _applied = 0;
      _inspected = null;
    } else {
      _restoreSeed();
    }
    notifyListeners();
  }

  void _restoreSeed() {
    _initial = seed.initial;
    _initialLabel = seed.initialLabel;
    _steps.clear();
    _inspected = null;
    var state = _initial;
    for (final gate in seed.gates) {
      final after =
          state.applyGate(gate.type, angle: gate.angle ?? math.pi / 2);
      _steps.add(BlochLabStep(gate: gate, before: state, after: after));
      state = after;
    }
    _applied = _steps.length;
  }
}

// --------------------------------------------------------- presentation

/// Formats a real number with an explicit sign handling that never produces
/// "+ −" (e.g. 0.7071, −0.5).
String blochNumber(double value, {int digits = 4}) {
  final v = value.abs() < 0.5 * math.pow(10, -digits) ? 0.0 : value;
  final text = v.abs().toStringAsFixed(digits);
  return v < 0 ? '−$text' : text;
}

/// An unambiguous complex number: "0.7071", "0.7071i", "0.5 − 0.5i",
/// "−0.7071i". The imaginary unit is always a trailing factor of a single
/// number, never of a fraction.
String blochComplex(Complex c, {int digits = 4}) {
  final eps = 0.5 * math.pow(10, -digits);
  final re = c.real.abs() < eps ? 0.0 : c.real.toDouble();
  final im = c.imaginary.abs() < eps ? 0.0 : c.imaginary.toDouble();
  if (im == 0) return blochNumber(re, digits: digits);
  final imText = '${im.abs().toStringAsFixed(digits)}i';
  if (re == 0) return im < 0 ? '−$imText' : imText;
  return '${blochNumber(re, digits: digits)} ${im < 0 ? '−' : '+'} $imText';
}

/// Formats an angle in radians with its π multiple when it is a simple one
/// ("π/2 (1.5708 rad)"), otherwise radians only.
String blochAngle(double radians) {
  const fractions = {
    0: '0',
    1: 'π/8',
    2: 'π/4',
    3: '3π/8',
    4: 'π/2',
    6: '3π/4',
    8: 'π',
    10: '5π/4',
    12: '3π/2',
    14: '7π/4',
    16: '2π',
    24: '3π',
    32: '4π',
  };
  final eighths = radians / (math.pi / 8);
  final rounded = eighths.round();
  final sign = radians < 0 ? '−' : '';
  final known = fractions[rounded.abs()];
  if ((eighths - rounded).abs() < 1e-9 && known != null) {
    if (rounded == 0) return '0';
    return '$sign$known (${blochNumber(radians)} rad)';
  }
  final thirds = radians / (math.pi / 3);
  if ((thirds - thirds.round()).abs() < 1e-9 && thirds.round().abs() <= 6) {
    final n = thirds.round().abs();
    final text = switch (n) {
      1 => 'π/3',
      2 => '2π/3',
      4 => '4π/3',
      5 => '5π/3',
      _ => null
    };
    if (text != null) return '$sign$text (${blochNumber(radians)} rad)';
  }
  final sixths = radians / (math.pi / 6);
  if ((sixths - sixths.round()).abs() < 1e-9) {
    final n = sixths.round().abs();
    final text = switch (n) {
      1 => 'π/6',
      5 => '5π/6',
      7 => '7π/6',
      11 => '11π/6',
      _ => null
    };
    if (text != null) return '$sign$text (${blochNumber(radians)} rad)';
  }
  return '${blochNumber(radians)} rad';
}

/// The state as α|0⟩ + β|1⟩ with unambiguous coefficients, e.g.
/// "0.7071|0⟩ + 0.7071i|1⟩" or "0.7071|0⟩ − 0.7071|1⟩". Zero terms are
/// omitted; a negative or imaginary-only second term is written with "−"
/// rather than "+ −".
String blochStateExpression(BlochState state, {int digits = 4}) {
  String coeff(Complex c) {
    final text = blochComplex(c, digits: digits);
    final one = 1.0.toStringAsFixed(digits);
    if (text == one) return '';
    if (text == '−$one') return '−';
    return text.contains(' ') ? '($text)' : text;
  }

  final eps = 0.5 * math.pow(10, -digits);
  bool zero(Complex c) => c.real.abs() < eps && c.imaginary.abs() < eps;
  final a = state.alpha, b = state.beta;
  final terms = <String>[];
  if (!zero(a)) terms.add('${coeff(a)}|0⟩');
  if (!zero(b)) {
    var term = '${coeff(b)}|1⟩';
    if (terms.isNotEmpty) {
      term = term.startsWith('−') ? '− ${term.substring(1)}' : '+ $term';
    }
    terms.add(term);
  }
  return terms.join(' ');
}

/// Parses an angle typed by the learner: radians ("1.5708", "-0.5") or a
/// multiple of π ("π", "pi/2", "3π/4", "-2pi", "0.25π"). Null if invalid.
double? parseBlochAngle(String input) {
  final text = input
      .trim()
      .toLowerCase()
      .replaceAll(' ', '')
      .replaceAll('pi', 'π')
      .replaceAll('−', '-');
  if (text.isEmpty) return null;
  final plain = double.tryParse(text);
  if (plain != null) return plain.isFinite ? plain : null;
  final match =
      RegExp(r'^(-?)(\d*\.?\d*)π(?:/(\d+(?:\.\d+)?))?$').firstMatch(text);
  if (match == null) return null;
  final sign = match.group(1) == '-' ? -1.0 : 1.0;
  final coefficientText = match.group(2)!;
  final coefficient =
      coefficientText.isEmpty ? 1.0 : double.tryParse(coefficientText);
  final divisor =
      match.group(3) == null ? 1.0 : double.tryParse(match.group(3)!);
  if (coefficient == null || divisor == null || divisor == 0) return null;
  return sign * coefficient * math.pi / divisor;
}
