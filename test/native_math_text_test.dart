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
}
