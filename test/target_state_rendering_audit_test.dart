import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';

typedef _TargetEntry = ({int levelId, QQLevel level, String expression});

List<_TargetEntry> get _targetEntries => [
      for (final (index, level) in allQQLevels.indexed)
        if ((level.targetStateExpression ?? '').trim().isNotEmpty)
          (
            levelId: index + 1,
            level: level,
            expression: level.targetStateExpression!.trim(),
          ),
    ];

void main() {
  group('Target State corpus audit', () {
    test('every authored expression produces structurally safe renderer input',
        () {
      final affected = <int>[];
      for (final entry in _targetEntries) {
        final issues = targetStateLatexStructuralIssues(entry.expression);
        expect(
          issues,
          isEmpty,
          reason:
              'Level ${entry.levelId} (${entry.level.title}) target "${entry.expression}"',
        );

        final authoredPercentCount = '%'.allMatches(entry.expression).length;
        if (authoredPercentCount > 0) {
          affected.add(entry.levelId);
          final latex = quantumStateNotationToLatex(entry.expression);
          expect(r'\%'.allMatches(latex).length, authoredPercentCount);
          expect(RegExp(r'(?<!\\)%').hasMatch(latex), isFalse);
        }
      }

      expect(affected, [46, 47, 48]);
      expect(_targetEntries, isNotEmpty);
      // Kept as an audit diagnostic so additions change the reported corpus
      // size without requiring a brittle hard-coded count assertion.
      // ignore: avoid_print
      print(
          'TARGET_STATE_AUDIT total=${_targetEntries.length} affected=$affected');
      // ignore: avoid_print
      print('TARGET_STATE_LONG ids=${[
        for (final entry in _targetEntries)
          if (entry.expression.length >= 36) entry.levelId,
      ]}');
      for (final id in [44, 45, 46, 104, 105, 106]) {
        final level = getQQLevelById(id)!;
        // ignore: avoid_print
        print(
            'TARGET_STATE_LEVEL id=$id title=${level.title} expression=${level.targetStateExpression}');
      }
    });

    test('working and formerly broken notation retain exact semantics', () {
      expect(quantumStateNotationToLatex('|1⟩'), r'\lvert 1\rangle');
      expect(
        quantumStateNotationToLatex('(|0⟩ + |1⟩)/√2'),
        r'(\lvert 0\rangle  + \lvert 1\rangle )/\sqrt{2}',
      );
      expect(
        quantumStateNotationToLatex('((1+i)/2)|0⟩ + ((1-i)/2)|1⟩'),
        r'((1+i)/2)\lvert 0\rangle  + ((1-i)/2)\lvert 1\rangle',
      );
      expect(
        quantumStateNotationToLatex('P(00)=P(01)=P(10)=P(11)=25%'),
        r'P(00)=P(01)=P(10)=P(11)=25\%',
      );
    });

    test('Levels 44, 45, and 46 produce clean shared-renderer input', () {
      for (final id in [44, 45, 46]) {
        final expression = getQQLevelById(id)!.targetStateExpression!;
        expect(
          targetStateLatexStructuralIssues(expression),
          isEmpty,
          reason: 'Level $id: $expression',
        );
      }
      expect(
        quantumStateNotationToLatex(getQQLevelById(44)!.targetStateExpression!),
        contains(r'\lvert ++\rangle'),
      );
      expect(
        quantumStateNotationToLatex(getQQLevelById(45)!.targetStateExpression!),
        contains(r'\lvert 00\rangle'),
      );
      expect(
        quantumStateNotationToLatex(getQQLevelById(46)!.targetStateExpression!),
        endsWith(r'25\%'),
      );
    });

    test('Mastery 44-46 keep semantic labels out of maths input', () {
      final expectedLabels = {
        104: 'Complex equator state',
        105: 'Phased Bell pair',
        106: 'Global-phase |+⟩',
      };

      for (final id in [104, 105, 106]) {
        final level = getQQLevelById(id)!;
        final display = targetStateDisplayContent(
          expression: level.targetStateExpression!,
          semanticLabel: level.targetStateLabel,
        );
        final latex = quantumStateNotationToLatex(display.mathExpression);

        expect(display.semanticLabel, expectedLabels[id]);
        expect(display.mathExpression, level.targetStateExpression);
        expect(latex, isNot(contains('Complexequatorstate')));
        expect(latex, isNot(contains(level.targetStateLabel!)));
      }
    });
  });

  group('Target State shared widget path', () {
    Future<void> pumpTarget(
      WidgetTester tester, {
      required String expression,
      double width = 320,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 260,
              child: StateVectorDisplay(
                stateVector: [Complex.one(), Complex.zero()],
                numQubits: 1,
                tone: StateVectorDisplayTone.target,
                stateExpression: expression,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
        'basis, superposition, complex, phase, and probability targets '
        'use the same normalized LatexText input', (tester) async {
      const representatives = [
        '|1⟩',
        '(|0⟩ + |1⟩)/√2',
        '((1+i)/2)|0⟩ + ((1-i)/2)|1⟩',
        '(e^{-iπ/8}/√2)|00⟩ + (e^{iπ/8}/√2)|11⟩',
        'P(00)=P(01)=P(10)=P(11)=25%',
        'P(00)=50%, P(10)=50%',
        'P(00)=50%, P(11)=50%',
      ];
      for (final expression in representatives) {
        await pumpTarget(tester, expression: expression);
        final rendered = tester.widget<LatexText>(find.byType(LatexText));
        expect(rendered.math, '\$${quantumStateNotationToLatex(expression)}\$');
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
        'long Current/Target expression viewport is clipped and scrollable',
        (tester) async {
      await pumpTarget(
        tester,
        width: 180,
        expression: 'P(00)=P(01)=P(10)=P(11)=25%',
      );

      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('state-expression-horizontal-scroll')),
      );
      expect(scroll.scrollDirection, Axis.horizontal);
      expect(scroll.clipBehavior, Clip.hardEdge);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Mastery semantic label renders separately from LatexText',
        (tester) async {
      final level = getQQLevelById(104)!;
      final display = targetStateDisplayContent(
        expression: level.targetStateExpression!,
        semanticLabel: level.targetStateLabel,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 260,
              child: StateVectorDisplay(
                stateVector: [Complex.one(), Complex.zero()],
                numQubits: 1,
                tone: StateVectorDisplayTone.target,
                stateExpressionLabel: display.semanticLabel,
                stateExpression: display.mathExpression,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Complex equator state'), findsOneWidget);
      final rendered = tester.widget<LatexText>(find.byType(LatexText));
      expect(rendered.math, isNot(contains('Complex equator state')));
      expect(
        rendered.math,
        '\$${quantumStateNotationToLatex(level.targetStateExpression!)}\$',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
