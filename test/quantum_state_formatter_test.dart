import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';

void main() {
  group('quantum state coefficient presentation', () {
    test('omits only an exact unit coefficient', () {
      expect(
        formatQuantumStateExpression([Complex(1, 0)], numQubits: 1),
        '|ψ⟩ = |0⟩',
      );
    });

    test('groups pure real, imaginary, and fractional coefficients', () {
      expect(
        formatQuantumStateExpression([Complex(.5, 0), Complex(0, 1)],
            numQubits: 1),
        '|ψ⟩ = (1/2)|0⟩ + (i)|1⟩',
      );
    });

    test('groups a mixed complex coefficient', () {
      expect(
        formatQuantumStateExpression([Complex(.5, .5)], numQubits: 1),
        '|ψ⟩ = (1/2 + 1/2i)|0⟩',
      );
    });

    test('uses an exact square-root form where presentation supports it', () {
      expect(
        formatQuantumStateExpression(
          [Complex(math.sqrt1_2, 0), Complex(math.sqrt1_2, 0)],
          numQubits: 1,
        ),
        '|ψ⟩ = (1/√2)|0⟩ + (1/√2)|1⟩',
      );
    });

    test('groups decimal and multi-basis-state coefficients', () {
      expect(
        formatQuantumStateExpression(
          [Complex(.793123456, .609123456), Complex.zero(), Complex(-.25, 0)],
          numQubits: 2,
        ),
        '|ψ⟩ = (0.7931 + 0.6091i)|00⟩ + (−1/4)|10⟩',
      );
    });

    test('omits zero terms and groups negative amplitudes', () {
      final terms = formatQuantumStateTerms(
        [Complex.zero(), Complex(-1, 0)],
        numQubits: 1,
      );

      expect(terms, hasLength(1));
      expect(terms.single.formattedCoefficient, '−1');
      expect(terms.single.basisKet, '|1⟩');
      expect(terms.single.displayText, '(−1)|1⟩');
    });
  });

  group('shared mathematical notation', () {
    test('Target State separates identity validation metadata from state math',
        () {
      expect(
        targetStateMathExpression('|00⟩ and identity overall'),
        '|00⟩',
      );
      expect(
        quantumStateNotationToLatex(
          targetStateMathExpression('|00⟩ and identity overall'),
        ),
        r'\lvert 00\rangle',
      );
    });

    test('Target State exponent notation converts to real LaTeX', () {
      expect(
        quantumStateNotationToLatex(r'e^{iπ/4}|1⟩'),
        r'e^{i\pi /4}\lvert 1\rangle',
      );
    });

    test('Goal-style and Target-style ket notation share conversion', () {
      const target = r'(|0⟩ + |1⟩)/√2';
      const goal = r'(|0> + |1>)/\sqrt{2}';
      expect(
        quantumStateNotationToLatex(target),
        quantumStateNotationToLatex(goal),
      );
    });
  });

  group('Current and Target state rendering', () {
    Future<void> pumpDisplay(
      WidgetTester tester, {
      required List<Complex> vector,
      StateVectorDisplayTone tone = StateVectorDisplayTone.current,
      String? expression,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: StateVectorDisplay(
                stateVector: vector,
                numQubits: 1,
                tone: tone,
                stateExpression: expression,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Current State uses structured RichText with grouped terms',
        (tester) async {
      await pumpDisplay(tester, vector: [Complex.zero(), Complex(.5, .5)]);

      expect(find.byType(LatexText), findsNothing);
      final richText = tester.widget<RichText>(
        find.byKey(const ValueKey('current-state-rich-text')),
      );
      expect(richText.text.toPlainText(), '|ψ⟩ = (1/2 + 1/2i)|1⟩');

      final root = richText.text as TextSpan;
      final ketSpan = root.children!.whereType<TextSpan>().last;
      expect(ketSpan.text, '|1⟩');
      expect(ketSpan.style!.color, const Color(0xFF7CFFB2));
      final coefficientSpan = root.children!.whereType<TextSpan>().firstWhere(
            (span) => span.text == '(1/2 + 1/2i)',
          );
      expect(coefficientSpan.style?.color, isNull);
    });

    testWidgets('Target State does not render identity validation metadata',
        (tester) async {
      await pumpDisplay(
        tester,
        vector: [Complex.one(), Complex.zero()],
        tone: StateVectorDisplayTone.target,
        expression: '|00⟩ and identity overall',
      );

      final latex = tester.widget<LatexText>(find.byType(LatexText));
      expect(latex.math, contains(r'\lvert 00\rangle'));
      expect(latex.math, isNot(contains('identityoverall')));
      expect(latex.math, isNot(contains('andidentityoverall')));
    });

    testWidgets('Current State rebuilds immediately when its vector changes',
        (tester) async {
      await pumpDisplay(tester, vector: [Complex(1, 0), Complex.zero()]);
      RichText current() => tester.widget<RichText>(
            find.byKey(const ValueKey('current-state-rich-text')),
          );
      expect(current().text.toPlainText(), '|ψ⟩ = |0⟩');

      await pumpDisplay(
        tester,
        vector: [Complex(math.sqrt1_2, 0), Complex(math.sqrt1_2, 0)],
      );
      expect(
        current().text.toPlainText(),
        '|ψ⟩ = (1/√2)|0⟩ + (1/√2)|1⟩',
      );

      await pumpDisplay(tester, vector: [Complex(1, 0), Complex.zero()]);
      expect(current().text.toPlainText(), '|ψ⟩ = |0⟩');
    });

    testWidgets('long Current State expressions remain horizontally scrollable',
        (tester) async {
      await pumpDisplay(
        tester,
        vector: List.generate(2, (_) => Complex(.5, .5)),
      );
      final scroll = find.ancestor(
        of: find.byKey(const ValueKey('current-state-rich-text')),
        matching: find.byType(SingleChildScrollView),
      );
      expect(
        tester
            .widgetList<SingleChildScrollView>(scroll)
            .any((widget) => widget.scrollDirection == Axis.horizontal),
        isTrue,
      );
    });

    testWidgets('Target State renders authored exponent notation as LaTeX',
        (tester) async {
      await pumpDisplay(
        tester,
        vector: [Complex.zero(), Complex(1, 0)],
        tone: StateVectorDisplayTone.target,
        expression: r'|ψ⟩ = e^{iπ/4}|1⟩',
      );

      final rendered = tester.widget<LatexText>(find.byType(LatexText));
      expect(rendered.math, contains(r'e^{i\pi /4}\lvert 1\rangle'));
    });
  });
}
