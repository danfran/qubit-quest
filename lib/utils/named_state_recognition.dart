import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:quantumquiz/utils/angle_expression.dart';

/// Recognition of a few textbook states (v2.6 M11C.1), used only to *add* a
/// label beside the full state expression, never to replace it.
///
/// A state is recognised when it equals a catalogue state up to a global
/// phase: |⟨named|ψ⟩| = 1 within [namedStateTolerance]. The global phase
/// e^{iγ} = ⟨named|ψ⟩ is reported, so the label is an exact equation
/// (|ψ⟩ = e^{iγ}|named⟩). The catalogue is deliberately small and contains
/// no circuit-specific interpretation:
///
/// * one qubit: |+⟩, |−⟩, |+i⟩, |−i⟩ (Z-basis states already read as
///   themselves in the expression, so they are not relabelled);
/// * two qubits: the Bell states |Φ⁺⟩, |Φ⁻⟩, |Ψ⁺⟩, |Ψ⁻⟩;
/// * three or more qubits: |GHZ⟩ = (|0…0⟩ + |1…1⟩)/√2 and the uniform
///   superposition |+⟩^⊗n.
///
/// Basis order is the app's convention: index bit k is qubit k (q0 is the
/// rightmost symbol of a ket).
class NamedState {
  const NamedState({
    required this.symbol,
    required this.name,
    required this.globalPhase,
    this.superscript,
    this.isExact = true,
  });

  /// Whether the state equals this one (with the phase shown) to
  /// floating-point precision, not only within [namedStateTolerance]
  /// (v2.6 M11G). Hosts write the relation as = only when this is true,
  /// and as ≈ otherwise: a tolerance match is not an exact equality.
  final bool isExact;

  /// The ket as written, e.g. `|+⟩`, `|Φ⁺⟩`, `|+⟩^⊗3` (with [superscript]).
  final String symbol;

  /// Plain-language name, e.g. "plus state", "Bell state Φ⁺".
  final String name;

  /// γ in (−π, π] with |ψ⟩ = e^{iγ}|named⟩.
  final double globalPhase;

  bool get hasGlobalPhase => globalPhase.abs() > namedStateTolerance;

  /// Superscript after [symbol], e.g. `⊗3`; null for none.
  final String? superscript;

  /// The phase factor as written before the ket: '' (γ = 0), '−' (π),
  /// 'i' (π/2), '−i' (−π/2), otherwise null (use [phaseExponent]).
  String? get phasePrefix {
    if (!hasGlobalPhase) return '';
    if (_near(globalPhase.abs(), math.pi)) return '−';
    if (_near(globalPhase, math.pi / 2)) return 'i';
    if (_near(globalPhase, -math.pi / 2)) return '−i';
    return null;
  }

  /// `iπ/4`, `−i·0.3183π` …: the exponent of e for other phases.
  String get phaseExponent {
    final angle = formatAngleAsPi(_snap(globalPhase)).replaceAll('-', '−');
    return angle.startsWith('−') ? '−i${angle.substring(1)}' : 'i$angle';
  }

  /// The global phase as a multiple of π (`π/2`, `−π/4`, `0.3183π`).
  String get phaseText =>
      formatAngleAsPi(_snap(globalPhase)).replaceAll('-', '−');

  /// One-line plain text: `i|+⟩`, `e^(iπ/4)|Φ⁺⟩`, `|+⟩^⊗3`.
  String get plainText {
    final ket = '$symbol${superscript == null ? '' : '^$superscript'}';
    final prefix = phasePrefix;
    return prefix != null ? '$prefix$ket' : 'e^($phaseExponent)$ket';
  }

  static bool _near(double a, double b) => (a - b).abs() < 1e-6;

  /// Removes floating-point noise before formatting as a multiple of π.
  static double _snap(double angle) {
    final ratio = angle / math.pi;
    for (final d in const [1, 2, 3, 4, 6, 8, 12, 16]) {
      final n = (ratio * d).roundToDouble();
      if ((ratio * d - n).abs() < 1e-6) return n * math.pi / d;
    }
    return angle;
  }
}

/// Tolerance on |⟨named|ψ⟩| and on the phase (display decisions only).
const double namedStateTolerance = 1e-6;

/// Below this the overlap is 1 to floating-point precision (M11G).
const double _exactTolerance = 1e-9;

/// The recognised textbook state equal to [state] up to a global phase,
/// or null. [state] must be normalised (as simulation states are).
NamedState? recogniseNamedState(List<Complex> state, int numQubits) {
  final size = 1 << numQubits;
  if (state.length < size || numQubits < 1) return null;
  for (final candidate in _catalogue(numQubits)) {
    // ⟨named|ψ⟩ with real non-negative named amplitudes … except Φ⁻/Ψ⁻/|−⟩
    // and the ±i states, so the full conjugate product is used.
    var re = 0.0, im = 0.0;
    for (var i = 0; i < size; i++) {
      final (nr, ni) = candidate.amplitudes(i);
      if (nr == 0 && ni == 0) continue;
      final sr = state[i].real.toDouble(), si = state[i].imaginary.toDouble();
      // conj(n) · s
      re += nr * sr + ni * si;
      im += nr * si - ni * sr;
    }
    final overlap = math.sqrt(re * re + im * im);
    if ((overlap - 1).abs() < namedStateTolerance) {
      var phase = math.atan2(im, re);
      if (phase <= -math.pi + 1e-9) phase = math.pi;
      final named = NamedState(
        symbol: candidate.symbol,
        name: candidate.name,
        globalPhase: phase.abs() < namedStateTolerance ? 0 : phase,
        superscript: candidate.superscript,
      );
      // Exact: the overlap is 1 to floating-point precision and the phase
      // is written exactly (−, ±i or a simple multiple of π).
      final exact = (overlap - 1).abs() < _exactTolerance &&
          (named.phasePrefix != null || !named.phaseText.contains('.'));
      return exact
          ? named
          : NamedState(
              symbol: named.symbol,
              name: named.name,
              globalPhase: named.globalPhase,
              superscript: named.superscript,
              isExact: false,
            );
    }
  }
  return null;
}

class _Candidate {
  const _Candidate(this.symbol, this.name, this.amplitudes, {this.superscript});
  final String symbol;
  final String name;
  final String? superscript;
  final (double, double) Function(int index) amplitudes;
}

Iterable<_Candidate> _catalogue(int n) sync* {
  final h = 1 / math.sqrt(2);
  if (n == 1) {
    yield _Candidate('|+⟩', 'plus state', (i) => (h, 0));
    yield _Candidate('|−⟩', 'minus state', (i) => (i == 0 ? h : -h, 0));
    yield _Candidate('|+i⟩', 'plus-i state', (i) => i == 0 ? (h, 0) : (0, h));
    yield _Candidate('|−i⟩', 'minus-i state', (i) => i == 0 ? (h, 0) : (0, -h));
    return;
  }
  if (n == 2) {
    // Index bits: q1 q0 (|q1 q0⟩). |Φ±⟩ on 00/11, |Ψ±⟩ on 01/10.
    yield _Candidate(
        '|Φ⁺⟩', 'Bell state Φ⁺', (i) => i == 0 || i == 3 ? (h, 0) : (0, 0));
    yield _Candidate(
        '|Φ⁻⟩',
        'Bell state Φ⁻',
        (i) => i == 0
            ? (h, 0)
            : i == 3
                ? (-h, 0)
                : (0, 0));
    yield _Candidate(
        '|Ψ⁺⟩', 'Bell state Ψ⁺', (i) => i == 1 || i == 2 ? (h, 0) : (0, 0));
    yield _Candidate(
        '|Ψ⁻⟩',
        'Bell state Ψ⁻',
        (i) => i == 1
            ? (h, 0)
            : i == 2
                ? (-h, 0)
                : (0, 0));
  }
  final last = (1 << n) - 1;
  if (n >= 3) {
    yield _Candidate(
        '|GHZ⟩', 'GHZ state', (i) => i == 0 || i == last ? (h, 0) : (0, 0));
  }
  final u = 1 / math.sqrt((1 << n).toDouble());
  yield _Candidate('|+⟩', 'equal superposition', (i) => (u, 0),
      superscript: '⊗$n');
}
