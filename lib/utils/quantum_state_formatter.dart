import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/utils/complex_formatter.dart';

const double _stateMatchTolerance = 1e-6;
const double _stateAmplitudeThreshold = 1e-9;

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
}

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

  return '$stateLabel = ${terms.isEmpty ? '0' : terms.map((term) => term.displayText).join(' + ')}';
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
      .replaceAll('√2', r'\sqrt{2}')
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
