import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/quantum_state_inspector_content.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';
import 'support/mastery_math_test_platform.dart';

void main() {
  // Representative MathJax geometry: a long expression with a tall fraction.
  // This checks actual SVG layout, not the unavailable widget-test MathJax engine.
  useMasteryMathTestPlatform(
    svg: '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 -1200 30000 2400">'
        '<path d="M0 -1200 H30000 V1200 H0 Z"/></svg>',
  );

  testWidgets(
      'target glyph scale survives fractions, narrow widths and text scaling',
      (tester) async {
    const expression =
        r'\frac{1}{\sqrt{2}}(|00\rangle+|11\rangle)\langle\psi|^{2}';
    final vector = [
      Complex.one(),
      Complex.zero(),
      Complex.zero(),
      Complex.zero()
    ];
    for (final width in [320.0, 400.0]) {
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: width,
                  child: QuantumStateInspectorContent(
                    currentStateVector: vector,
                    numQubits: 2,
                    targetStateVector: vector,
                    targetStateExpression: expression,
                    contentDriven: true,
                    nonZeroOnly: false,
                    onNonZeroOnlyChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        final target = find.byWidgetPredicate((w) =>
            w is StateVectorDisplay && w.tone == StateVectorDisplayTone.target);
        final latex = tester.widget<LatexText>(
            find.descendant(of: target, matching: find.byType(LatexText)));
        expect(latex.mathFontSize, 14);
        expect(tester.widget<StateVectorDisplay>(target).stateExpression,
            expression);
        expect(tester.widget<StateVectorDisplay>(target).stateVector,
            same(vector));
        final svg =
            find.descendant(of: target, matching: find.byType(LatexSvgPicture));
        expect(tester.getSize(svg).height, closeTo(2.4 * 14 * scale, .01));
        final scroll = find.descendant(
          of: target,
          matching:
              find.byKey(const ValueKey('state-expression-horizontal-scroll')),
        );
        final controller =
            tester.widget<SingleChildScrollView>(scroll).controller!;
        expect(controller.position.maxScrollExtent, greaterThan(0));
        await tester.drag(scroll, const Offset(-100, 0));
        await tester.pumpAndSettle();
        expect(controller.offset, greaterThan(0));
        expect(find.byKey(const ValueKey('current-state-rich-text')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
