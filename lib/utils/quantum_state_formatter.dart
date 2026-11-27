import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/utils/complex_formatter.dart';

const double _stateMatchTolerance = 1e-6;
const double _stateAmplitudeThreshold = 1e-9;

class TargetStateDisplayContent {
  final String? semanticLabel;
  final String mathExpression;

  const TargetStateDisplayContent({
    required this.semanticLabel,
    required this.mathExpression,
  });
}

String targetStateMathExpression(String expression) =>
    expression.trim().replaceFirst(
          RegExp(r'\s+and\s+identity\s+overall\s*$', caseSensitive: false),
          '',
        );

/// Keeps human-readable target metadata out of the TeX maths expression.
TargetStateDisplayContent targetStateDisplayContent({
  required String expression,
  String? semanticLabel,
}) {
  final stateExpression = targetStateMathExpression(expression);
  if (stateExpression.contains('=')) {
    return TargetStateDisplayContent(
      semanticLabel: null,
      mathExpression: stateExpression,
    );
  }

  final trimmedLabel = semanticLabel?.trim();
  if (trimmedLabel != null && trimmedLabel.isNotEmpty) {
    return TargetStateDisplayContent(
      semanticLabel: trimmedLabel,
      mathExpression: stateExpression,
    );
  }

  return TargetStateDisplayContent(
    semanticLabel: null,
    mathExpression: '|ψ⟩ = $stateExpression',
  );
}

class QuantumStateTerm {
  final String formattedCoefficient;
  final String basisKet;
  final bool coefficientIsUnit;

  const QuantumStateTerm({
    required this.formattedCoefficient,
    required this.basisKet,
    required this.coefficientIsUnit,
  });

  String get displayText =>
      coefficientIsUnit ? basisKet : '($formattedCoefficient)$basisKet';

  /// A single-signed negative coefficient (real or imaginary only, e.g.
  /// "−1/√2", "−i/√2", "−1"), written as a subtraction (v2.6 M9).
  bool get isNegated =>
      formattedCoefficient.startsWith('−') &&
      !formattedCoefficient.substring(1).contains(RegExp(r' [+−] '));

  /// What precedes the term: "" or "−" first; " + " or " − " after.
  String separator({required bool first}) => first
      ? (isNegated ? '−' : '')
      : (isNegated ? ' − ' : ' + ');

  /// The coefficient as shown after [separator]: nothing for ±1, bare "i"
  /// for ±i, otherwise parenthesised ("(1/√2)", "(1/2 + i/2)").
  String get coefficientDisplay {
    if (coefficientIsUnit) return '';
    final magnitude =
        isNegated ? formattedCoefficient.substring(1) : formattedCoefficient;
    if (magnitude == '1') return '';
    if (magnitude == 'i') return 'i';
    return '($magnitude)';
  }

  /// The term with its separator, e.g. " − (1/√2)|11⟩".
  String joinedText({required bool first}) =>
      '${separator(first: first)}$coefficientDisplay$basisKet';
}

/// Joins terms as conventional algebra: "(1/√2)|00⟩ − (1/√2)|11⟩",
/// "−|0⟩", "(1/2 + i/2)|0⟩ + (1/2 − i/2)|1⟩" (v2.6 M9).
String joinQuantumStateTerms(List<QuantumStateTerm> terms) => [
      for (final (i, t) in terms.indexed) t.joinedText(first: i == 0),
    ].join();

List<QuantumStateTerm> formatQuantumStateTerms(
  List<Complex> stateVector, {
  required int numQubits,
}) {
  final terms = <QuantumStateTerm>[];
  for (var index = 0; index < stateVector.length; index++) {
    final coefficient = stateVector[index];
    if (coefficient.magnitude <= _stateAmplitudeThreshold) {
      continue;
    }
    terms.add(
      _formatStateTerm(
        coefficient,
        '|${index.toRadixString(2).padLeft(numQubits, '0')}⟩',
      ),
    );
  }
  return List.unmodifiable(terms);
}

/// The display text of one amplitude, exactly as it appears inside a state
/// term (`1`, `1/√2`, `−0.5i`, `0.4001 − 0.0957i`); `0` below the display
/// threshold. Presentation only: values and tolerances are unchanged.
String formatQuantumAmplitude(Complex coefficient) =>
    coefficient.magnitude <= _stateAmplitudeThreshold
        ? '0'
        : _formatStateTerm(coefficient, '').formattedCoefficient;

/// Formats a state vector without changing its ordering or numeric values.
///
/// Every non-unit coefficient is grouped before its ket so the visual scope of
/// complex coefficients is unambiguous.
String formatQuantumStateExpression(
  List<Complex> stateVector, {
  required int numQubits,
  String stateLabel = '|ψ⟩',
}) {
  final terms = formatQuantumStateTerms(
    stateVector,
    numQubits: numQubits,
  );

  return '$stateLabel = ${terms.isEmpty ? '0' : joinQuantumStateTerms(terms)}';
}

QuantumStateTerm _formatStateTerm(Complex coefficient, String ket) {
  final real = coefficient.real.toDouble();
  final imaginary = coefficient.imaginary.toDouble();
  if ((real - 1).abs() < _stateMatchTolerance &&
      imaginary.abs() < _stateMatchTolerance) {
    return QuantumStateTerm(
      formattedCoefficient: '1',
      basisKet: ket,
      coefficientIsUnit: true,
    );
  }

  final invSqrt2 = 1 / math.sqrt(2);
  final coefficientText = switch ((real, imaginary)) {
    (final r, final i)
        when (r - invSqrt2).abs() < _stateMatchTolerance &&
            i.abs() < _stateMatchTolerance =>
      '1/√2',
    (final r, final i)
        when (r + invSqrt2).abs() < _stateMatchTolerance &&
            i.abs() < _stateMatchTolerance =>
      '−1/√2',
    _ => formatComplex(coefficient).replaceAll('-', '−'),
  };
  return QuantumStateTerm(
    formattedCoefficient: coefficientText,
    basisKet: ket,
    coefficientIsUnit: false,
  );
}

/// Normalises common authored notation for non-LaTeX educational text.
String formatQuantumNotationForPlainText(String value) {
  return value
      .replaceAllMapped(
        RegExp(r'\|([01+\-−]+)>'),
        (match) => '|${match.group(1)!.replaceAll('-', '−')}⟩',
      )
      .replaceAll(r'\sqrt{2}', '√2')
      .replaceAll('sqrt(2)', '√2')
      .replaceAll('sqrt2', '√2')
      .replaceAll('->', '→');
}

/// Converts the app's compact Unicode state notation to inline LaTeX.
///
/// This is presentation-only and is shared by Current and Target state lines.
String quantumStateNotationToLatex(String value) {
  var result = formatQuantumNotationForPlainText(value)
      // Percent is ordinary authored probability notation in Qubit Quest,
      // but starts a comment in TeX and would hide the rest of the target.
      .replaceAllMapped(RegExp(r'(?<!\\)%'), (_) => r'\%')
      .replaceAllMapped(
        RegExp(r'√([0-9]+)'),
        (match) => r'\sqrt{' + match.group(1)! + '}',
      )
      .replaceAll('π', r'\pi ')
      .replaceAll('⊗', r'\otimes ')
      .replaceAll('†', r'^{\dagger}')
      .replaceAll('−', '-');

  result = result.replaceAllMapped(RegExp(r'\|([^⟩]+)⟩'), (match) {
    final body = match
        .group(1)!
        .replaceAll('ψ', r'\psi ')
        .replaceAll('Φ', r'\Phi ')
        .replaceAll('Ψ', r'\Psi ');
    return r'\lvert ' + body + r'\rangle ';
  });
  return result.trim();
}

/// Converts an explicitly-authored Notebook mathematical example to TeX.
///
/// This is deliberately not a math detector. Notebook authors opt an example
/// into mathematical presentation with `NotebookExample.math`; this helper
/// only normalises the app's compact Unicode quantum notation.
String notebookMathNotationToLatex(String value) {
  String convertLine(String line) {
    var result = quantumStateNotationToLatex(line)
        .replaceAll('²', '^{2}')
        .replaceAll('⁻¹', '^{-1}')
        .replaceAll('⁺', '^{+}')
        .replaceAll('⁻', '^{-}')
        .replaceAll('→', r'\rightarrow ')
        .replaceAll('×', r'\times ')
        .replaceAll('Φ', r'\Phi ')
        .replaceAll('φ', r'\phi ')
        .replaceAll('α', r'\alpha ')
        .replaceAll('β', r'\beta ');
    result = result.replaceAllMapped(
      RegExp(r'\(([^()]*)\)/\\sqrt\{2\}'),
      (match) => '\\frac{${match.group(1)!}}{\\sqrt{2}}',
    );
    result = result
        .replaceAll(RegExp(r'(?<![A-Za-z])1/2'), r'\frac{1}{2}')
        .replaceAll('CNOT', r'\operatorname{CNOT}')
        .replaceAll('CX', r'\operatorname{CX}');
    return result;
  }

  final lines = value.split('\n').map(convertLine).toList(growable: false);
  if (lines.length == 1) return lines.single;
  return r'\begin{gathered}' + lines.join(r' \\ ') + r'\end{gathered}';
}

/// Reports structural problems in the exact source passed to the Target State
/// maths renderer. This intentionally validates presentation syntax only; it
/// does not interpret or alter quantum-state semantics.
List<String> targetStateLatexStructuralIssues(String authoredExpression) {
  final latex = quantumStateNotationToLatex(authoredExpression);
  final issues = <String>[];
  if (RegExp(r'(?<!\\)%').hasMatch(latex)) {
    issues.add('contains an unescaped TeX comment marker');
  }
  if (latex.contains('√') ||
      latex.contains('π') ||
      latex.contains('⊗') ||
      latex.contains('†') ||
      latex.contains('⟩')) {
    issues.add('contains Unicode notation that should have been normalized');
  }

  var braceDepth = 0;
  for (var index = 0; index < latex.length; index++) {
    final character = latex[index];
    final escaped = index > 0 && latex[index - 1] == r'\';
    if (!escaped && character == '{') braceDepth++;
    if (!escaped && character == '}') braceDepth--;
    if (braceDepth < 0) break;
  }
  if (braceDepth != 0) issues.add('contains unbalanced TeX braces');
  return List.unmodifiable(issues);
}
