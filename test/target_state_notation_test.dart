import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';

ComposerLevel composerLevel(String title) {
  for (var id = 1; id <= 114; id++) {
    final level = getQQLevelById(id);
    if (level is ComposerLevel && level.title == title) {
      return level;
    }
  }
  throw StateError('Composer level not found: $title');
}

void main() {
  group('canonical authored Target State notation', () {
    test('Rz physical-state target keeps coefficients with their kets', () {
      final level = composerLevel('Rz — Phase Rotation');

      expect(
        level.targetStateExpression,
        '|+i⟩ = (|0⟩ + i|1⟩)/√2',
      );
      expect(level.targetStateExpression, isNot(contains('|1⟩/√2')));
      expect(level.solutionFinalVector, [
        [Complex(math.sqrt1_2)],
        [Complex(0, math.sqrt1_2)],
      ]);
    });

    test('multi-axis expanded coefficients each precede their ket', () {
      final level = composerLevel('Composing Rx and Ry');

      expect(
        level.targetStateExpression,
        '((1+i)/2)|0⟩ + ((1-i)/2)|1⟩',
      );
      expect(level.solutionFinalVector, [
        [Complex(.5, .5)],
        [Complex(.5, -.5)],
      ]);
    });

    test('phased Bell coefficients each include normalization before ket', () {
      final level = composerLevel('Rz on an Entangled State');
      final expression = level.targetStateExpression!;

      expect(
        expression,
        '(e^{-iπ/8}/√2)|00⟩ + (e^{iπ/8}/√2)|11⟩',
      );
      expect(expression, isNot(endsWith('/√2')));
      expect(level.solutionFinalVector, hasLength(4));
    });

    test('well-established Bell and GHZ symbolic definitions stay factored',
        () {
      expect(
        composerLevel('First Bell State Φ⁺').targetStateExpression,
        '|Φ⁺⟩ = (|00⟩ + |11⟩)/√2',
      );
      expect(
        composerLevel('All Together').targetStateExpression,
        '(|000⟩ + |111⟩)/√2',
      );
    });

    test('symbolic exponential form remains symbolic through LaTeX conversion',
        () {
      final expression = composerLevel('An Eighth Turn').targetStateExpression!;
      final latex = quantumStateNotationToLatex(expression);

      expect(latex, contains(r'e^{i\pi /4}'));
      expect(latex, isNot(contains(r'\cos')));
      expect(latex, isNot(contains(r'\sin')));
    });

    test('no authored target places a normalizing scalar after a ket', () {
      for (var id = 1; id <= 114; id++) {
        final expression = getQQLevelById(id)?.targetStateExpression;
        if (expression == null) continue;
        expect(
          RegExp(r'⟩\s*/\s*(?:√2|2)(?:\s|$)').hasMatch(expression),
          isFalse,
          reason: 'Level $id has a trailing scalar: $expression',
        );
      }
    });
  });
}
