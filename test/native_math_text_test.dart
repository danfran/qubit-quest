import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/widgets/native_math_text.dart';

void main() {
  test('classifies simple and complex mathematical content conservatively', () {
    expect(NativeMathText.supports(r'\(X^2=I\)'), isTrue);
    expect(
        NativeMathText.supports(r'\(|0\rangle\rightarrow|1\rangle\)'), isTrue);
    expect(NativeMathText.supports(r'\(S^\dagger=S^3\)'), isTrue);
    expect(NativeMathText.supports(r'\(e^{i\pi/4}|1\rangle\)'), isFalse);
    expect(NativeMathText.supports(r'\(1/\sqrt{2}\)'), isFalse);
    expect(NativeMathText.supports(r'\[X=\begin{bmatrix}0&1\end{bmatrix}\]'),
        isFalse);
  });

  test('converts supported TeX notation to native Unicode', () {
    expect(NativeMathText.plainText(r'\(X^2=I\)'), 'X²=I');
    expect(
      NativeMathText.plainText(r'\(|0\rangle \rightarrow |1\rangle\)'),
      '|0⟩ → |1⟩',
    );
    expect(NativeMathText.plainText(r'\(S^\dagger=S^3\)'), 'S†=S³');
    expect(NativeMathText.plainText(r'\(R_x(-\theta)=I\)'), 'Rₓ(-θ)=I');
  });

  testWidgets('uses native RichText scaling and semantics', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: NativeMathText(
            math: r'\(HZH=X\)',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    ));

    expect(find.byType(RichText), findsOneWidget);
    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(), 'HZH=X');
    expect(richText.textScaler, const TextScaler.linear(2));
  });

  test('M3.1: no raw TeX leaks from the plain-text subset', () {
    // \mathrm{...} keeps its content (previously a literal "\$1").
    expect(NativeMathText.plainText(r'\(\mathrm{CCX}^2=I\)'), 'CCX²=I');
    expect(NativeMathText.supports(r'\(\mathrm{CCX}^2=I\)'), isTrue);
    // \cdot is translated; unknown commands fall back to LaTeX rendering.
    expect(
        NativeMathText.plainText(
            r'\(|a,b,t\rangle \rightarrow |a,b,t\oplus(a\cdot b)\rangle\)'),
        '|a,b,t⟩ → |a,b,t⊕(a·b)⟩');
    expect(NativeMathText.supports(r'\(\alpha|0\rangle\)'), isFalse);
  });
}
