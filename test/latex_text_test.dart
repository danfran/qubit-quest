import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:quantumquiz/widgets/latex_text.dart';

const _fixtureSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 700">
  <path d="M0 0 H1000 V700 H0 Z"/>
</svg>
''';

void main() {
  testWidgets('delimiter mode is forwarded to MathJax explicitly',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LatexText(
          math: r'\(X^2=I\) \[X=\begin{bmatrix}0&1\\1&0\end{bmatrix}\]',
        ),
      ),
    ));

    final formulae = tester
        .widgetList<TeX2SVG>(find.byType(TeX2SVG))
        .map((widget) => widget.math)
        .toList();
    expect(formulae, contains(r'\textstyle{X^2=I}'));
    expect(formulae, contains(startsWith(r'\displaystyle{X=')));
  });

  for (final scale in <double>[1, 1.5, 2]) {
    testWidgets('SVG visual roles have enforced bounds at ${scale}x text scale',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: const Scaffold(
            body: Column(
              children: [
                LatexSvgPicture(
                  key: Key('tertiary'),
                  svg: _fixtureSvg,
                  logicalHeight: 11,
                  color: Colors.black,
                ),
                LatexSvgPicture(
                  key: Key('secondary'),
                  svg: _fixtureSvg,
                  logicalHeight: 16,
                  color: Colors.black,
                ),
                LatexSvgPicture(
                  key: Key('primary'),
                  svg: _fixtureSvg,
                  logicalHeight: 28,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ));

      final tertiary = tester.getSize(find.byKey(const Key('tertiary')));
      final secondary = tester.getSize(find.byKey(const Key('secondary')));
      final primary = tester.getSize(find.byKey(const Key('primary')));
      expect(tertiary.height, closeTo(11 * scale, 0.01));
      expect(secondary.height, closeTo(16 * scale, 0.01));
      expect(primary.height, closeTo(28 * scale, 0.01));
      expect(tertiary.height, lessThan(secondary.height));
      expect(secondary.height, lessThan(primary.height));
      expect(tertiary.height, lessThan(primary.height * 0.5));
    });
  }

  testWidgets('tertiary SVG is bounded alongside 14px body text',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Unitary', key: Key('body'), style: TextStyle(fontSize: 14)),
            LatexSvgPicture(
              key: Key('identity'),
              svg: _fixtureSvg,
              logicalHeight: 11,
              color: Colors.black,
            ),
          ],
        ),
      ),
    ));

    expect(tester.getSize(find.byKey(const Key('identity'))).height, 11);
    expect(
      tester.getSize(find.byKey(const Key('identity'))).height,
      lessThan(tester.getSize(find.byKey(const Key('body'))).height),
    );
  });
}
