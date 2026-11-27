// v2.6 M3.1: scalable state presentation in the desktop Composer's State
// tab (structured layout of StateVectorDisplay). Presentation only: every
// expectation is derived from the existing formatters, never re-computed.
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/quantum_state_inspector_content.dart';

ValueKey<String> _k(String key) => ValueKey(key);

List<Complex> _uniform(int qubits) {
  final a = 1 / math.sqrt(1 << qubits);
  return List.generate(1 << qubits, (_) => Complex(a, 0));
}

Future<void> _show(
  WidgetTester tester,
  List<Complex> state,
  int qubits, {
  double width = 420,
  bool? nonZeroOnly = true,
  ValueChanged<bool>? onNonZeroOnlyChanged,
  String stateLabel = '|ψ⟩',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          height: 1600,
          child: SingleChildScrollView(
            child: QuantumStateInspectorContent(
              currentStateVector: state,
              numQubits: qubits,
              contentDriven: true,
              structuredLayout: true,
              stateLabel: stateLabel,
              nonZeroOnly: nonZeroOnly,
              onNonZeroOnlyChanged: onNonZeroOnlyChanged ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

/// Captures Clipboard.setData through the platform channel.
List<String> _captureClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copied.add((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return copied;
}

/// Basis-row occurrences of [text], excluding the expression above them
/// (a unit-coefficient term renders the bare ket there too).
int _rowCount(String text) =>
    find.text(text).evaluate().length -
    find
        .descendant(
            of: find.byKey(_k('state-expression-wrapped')),
            matching: find.text(text))
        .evaluate()
        .length;

String _ket(int index, int qubits) =>
    '|${index.toRadixString(2).padLeft(qubits, '0')}⟩';

void main() {
  testWidgets('dense five-qubit state: count, collapse, expand, every row',
      (tester) async {
    final state = _uniform(5);
    await _show(tester, state, 5);
    expect(tester.widget<Text>(find.byKey(_k('state-nonzero-count'))).data,
        '32 of 32 amplitudes non-zero · total probability 100%');
    // M4: exact symbolic amplitude and adaptive precision (was 0.1768, 3.1%).
    expect(formatQuantumAmplitude(state.first), '1/√32');
    expect(find.text('3.125%'), findsNWidgets(32));

    // Collapsed: explicitly abbreviated, never silently truncated.
    final terms = formatQuantumStateTerms(state, numQubits: 5);
    expect(terms, hasLength(32));
    final expression = find.byKey(_k('state-expression-wrapped'));
    expect(
        find.descendant(
            of: expression,
            matching: find.text('+ … 24 more terms', findRichText: true)),
        findsOneWidget);
    expect(find.text('Show all 32 terms'), findsOneWidget);

    await tester.tap(find.byKey(_k('state-expression-expand')));
    await tester.pump();
    expect(find.byKey(_k('state-expression-abbreviated')), findsNothing);
    expect(find.text('Show fewer terms'), findsOneWidget);
    for (var i = 0; i < 32; i++) {
      final term = terms[i];
      expect(
          find.descendant(
              of: expression,
              matching: find.textContaining(term.basisKet, findRichText: true)),
          findsOneWidget,
          reason: term.basisKet);
    }

    // Structured rows: basis, amplitude (existing formatter), probability.
    expect(find.byKey(_k('state-basis-table-header')), findsOneWidget);
    final amplitude = formatQuantumAmplitude(state.first);
    expect(find.text(amplitude), findsNWidgets(32));
    for (var i = 0; i < 32; i++) {
      expect(find.text(_ket(i, 5)), findsOneWidget, reason: _ket(i, 5));
    }
    await tester.tap(find.byKey(_k('state-expression-expand')));
    await tester.pump();
    expect(find.byKey(_k('state-expression-abbreviated')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('copy puts the complete expression on the clipboard',
      (tester) async {
    final copied = _captureClipboard(tester);
    final state = _uniform(5);
    await _show(tester, state, 5);
    await tester.tap(find.byKey(_k('state-expression-copy')));
    await tester.pump();
    expect(copied, [formatQuantumStateExpression(state, numQubits: 5)]);
    expect(copied.single, startsWith('|ψ⟩ = '));
    for (var i = 0; i < 32; i++) {
      expect(copied.single, contains(_ket(i, 5)));
    }
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('complex amplitudes keep signs, i and basis association',
      (tester) async {
    // 1/2 (|00⟩ + i|01⟩ − |10⟩ − i|11⟩)
    final state = [
      Complex(.5, 0),
      Complex(0, .5),
      Complex(-.5, 0),
      Complex(0, -.5),
    ];
    await _show(tester, state, 2);
    final labels = state.map(formatQuantumAmplitude).toList();
    expect(labels[1], contains('i'));
    expect(labels[2], startsWith('−'));
    expect(labels[3], startsWith('−'));
    expect(labels[3], contains('i'));
    // Each amplitude is on the row of its own basis state.
    for (var i = 0; i < 4; i++) {
      final ket = tester.getCenter(find.text(_ket(i, 2)));
      final amp = tester.getCenter(find.text(labels[i]).first);
      expect((ket.dy - amp.dy).abs(), lessThan(1), reason: _ket(i, 2));
    }
    // The expression shows every term with its own sign (v2.6 M9:
    // negative terms are written as subtractions, never "+ (−1/2)").
    final terms = formatQuantumStateTerms(state, numQubits: 2);
    expect(joinQuantumStateTerms(terms),
        '(1/2)|00⟩ + (i/2)|01⟩ − (1/2)|10⟩ − (i/2)|11⟩');
    for (final term in terms) {
      expect(
          find.descendant(
              of: find.byKey(_k('state-expression-wrapped')),
              matching: find.textContaining(
                  '${term.coefficientDisplay}${term.basisKet}',
                  findRichText: true)),
          findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-zero filter is preserved', (tester) async {
    final state = [Complex(1, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)];
    await _show(tester, state, 2, nonZeroOnly: true);
    expect(_rowCount('|01⟩'), 0);
    expect(tester.widget<Text>(find.byKey(_k('state-nonzero-count'))).data,
        '1 of 4 amplitudes non-zero · total probability 100%');
    await _show(tester, state, 2, nonZeroOnly: false);
    for (var i = 0; i < 4; i++) {
      expect(_rowCount(_ket(i, 2)), 1, reason: _ket(i, 2));
    }
    expect(find.text('0'), findsNWidgets(3), reason: 'zero amplitudes');
  });

  testWidgets('narrow results panel wraps whole terms without overflow',
      (tester) async {
    final rng = math.Random(7);
    final raw = List.generate(
        32, (_) => Complex(rng.nextDouble() - .5, rng.nextDouble() - .5));
    final norm = math.sqrt(raw.fold<double>(
        0, (s, c) => s + c.real * c.real + c.imaginary * c.imaginary));
    final state = [
      for (final c in raw) Complex(c.real / norm, c.imaginary / norm)
    ];
    await _show(tester, state, 5, width: 280);
    await tester.tap(find.byKey(_k('state-expression-expand')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    final box = tester.getRect(find.byKey(_k('state-expression-wrapped')));
    expect(box.width, lessThanOrEqualTo(280));
    expect(box.height, greaterThan(100), reason: 'wrapped onto many lines');
  });

  testWidgets('a measured circuit labels and copies the pre-measurement state',
      (tester) async {
    final copied = _captureClipboard(tester);
    final a = 1 / math.sqrt(2);
    final state = [Complex(a, 0), Complex(a, 0)];
    await _show(tester, state, 1, stateLabel: '|ψ_pre⟩');
    expect(find.text('|ψ_pre⟩ ='), findsOneWidget);
    await tester.tap(find.byKey(_k('state-expression-copy')));
    await tester.pump();
    expect(copied.single, startsWith('|ψ_pre⟩ = '));
    await tester.pump(const Duration(seconds: 2));
  });
}
