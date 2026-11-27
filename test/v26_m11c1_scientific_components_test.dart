import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/named_state_recognition.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/bloch_summary_panel.dart';
import 'package:quantumquiz/widgets/probability_distribution_chart.dart';
import 'package:quantumquiz/widgets/qq_scientific_primitives.dart';
import 'package:quantumquiz/widgets/state_amplitude_panel.dart';

/// v2.6 M11C.1: shared scientific presentation components.

ValueKey<String> _k(String key) => ValueKey(key);
final double _h = 1 / math.sqrt(2);

Future<void> _pump(WidgetTester tester, Widget child,
    {double width = 900}) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: QubitQuestTheme.web(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

List<Complex> _basis(int n, Map<int, Complex> amplitudes) => [
      for (var i = 0; i < 1 << n; i++) amplitudes[i] ?? Complex.zero(),
    ];

void main() {
  group('named state recognition', () {
    test('|+⟩ exactly, with no global phase', () {
      final named = recogniseNamedState([Complex(_h, 0), Complex(_h, 0)], 1)!;
      expect(named.symbol, '|+⟩');
      expect(named.hasGlobalPhase, isFalse);
      expect(named.plainText, '|+⟩');
    });

    test('Y|+⟩ = −i|−⟩: the global phase is reported, not hidden', () {
      // Y|+⟩ = (−i|0⟩ + i|1⟩)/√2
      final named = recogniseNamedState([Complex(0, -_h), Complex(0, _h)], 1)!;
      expect(named.symbol, '|−⟩');
      expect(named.hasGlobalPhase, isTrue);
      expect(named.phasePrefix, '−i');
      expect(named.phaseText, '−π/2');
      expect(named.plainText, '−i|−⟩');
    });

    test('an arbitrary global phase is written as an exponent', () {
      final p = Complex(math.cos(math.pi / 4), math.sin(math.pi / 4));
      final named = recogniseNamedState(
          _basis(2, {1: p * Complex(_h, 0), 2: p * Complex(-_h, 0)}), 2)!;
      expect(named.symbol, '|Ψ⁻⟩');
      expect(named.phasePrefix, isNull);
      expect(named.phaseExponent, 'iπ/4');
      expect(named.plainText, 'e^(iπ/4)|Ψ⁻⟩');
    });

    test('Bell, GHZ and uniform superpositions; basis order q0 = bit 0', () {
      expect(
          recogniseNamedState(
                  _basis(2, {0: Complex(_h, 0), 3: Complex(_h, 0)}), 2)!
              .symbol,
          '|Φ⁺⟩');
      expect(
          recogniseNamedState(
                  _basis(2, {1: Complex(_h, 0), 2: Complex(_h, 0)}), 2)!
              .symbol,
          '|Ψ⁺⟩');
      expect(
          recogniseNamedState(
              _basis(5, {0: Complex(_h, 0), 31: Complex(0, _h)}), 5),
          isNull,
          reason: 'a relative phase makes it a different state');
      expect(
          recogniseNamedState(
                  _basis(3, {0: Complex(_h, 0), 7: Complex(_h, 0)}), 3)!
              .symbol,
          '|GHZ⟩');
      final u = 1 / math.sqrt(32);
      final uniform =
          recogniseNamedState(List.generate(32, (_) => Complex(u, 0)), 5)!;
      expect(uniform.plainText, '|+⟩^⊗5');
    });

    test('basis states and unrecognised states get no label', () {
      expect(recogniseNamedState([Complex.one(), Complex.zero()], 1), isNull);
      final c = math.cos(math.pi / 6), s = math.sin(math.pi / 6);
      expect(recogniseNamedState([Complex(c, 0), Complex(0, -s)], 1), isNull);
    });
  });

  group('Current State panel', () {
    testWidgets('one heading, prominent expression, recognised |+⟩',
        (tester) async {
      await _pump(
          tester,
          QqCurrentStatePanel(
            stateVector: [Complex(_h, 0), Complex(_h, 0)],
            numQubits: 1,
          ));
      expect(find.text('CURRENT STATE'), findsOneWidget);
      expect(find.text('Current State'), findsNothing);
      expect(find.text('Current state'), findsNothing);
      // 1/√2 is typeset as a stacked fraction in the expression.
      expect(find.text('√2'), findsNWidgets(2));
      expect(find.byKey(_k('state-named')), findsOneWidget);
      expect(find.text('plus state'), findsOneWidget);
      // Exact amplitude and its decimal both listed, columns aligned.
      expect(find.text('1/√2'), findsNWidgets(2));
      expect(find.text('0.7071'), findsNWidgets(2));
      final header = tester.getRect(find.text('Decimal'));
      final value = tester.getRect(find.byKey(_k('state-decimal-0')));
      expect((header.right - value.right).abs(), lessThan(1),
          reason: 'the decimal column is right-aligned under its heading');
      final amp = tester.getRect(find.text('Amplitude'));
      final a0 = tester.getRect(find.byKey(_k('state-amplitude-0')));
      expect((amp.left - a0.left).abs(), lessThan(1));
      // The precision explanation is available but collapsed.
      expect(find.byKey(_k('composer-analysis-precision-note')), findsNothing);
      await tester.tap(find.byKey(_k('state-precision-toggle')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(_k('composer-analysis-precision-note')), findsOneWidget);
    });

    testWidgets('no decimal column when amplitudes are already decimals',
        (tester) async {
      final c = math.cos(0.3), s = math.sin(0.3);
      await _pump(
          tester,
          QqCurrentStatePanel(
            stateVector: [Complex(c, 0), Complex(0, -s)],
            numQubits: 1,
          ));
      expect(find.text('Decimal'), findsNothing);
      expect(find.byKey(_k('state-named')), findsNothing);
    });

    testWidgets('Copy copies the complete expression of the shared formatter',
        (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      final vector = _basis(2, {0: Complex(_h, 0), 3: Complex(0, -_h)});
      await _pump(
          tester,
          QqCurrentStatePanel(
              stateVector: vector, numQubits: 2, stateLabel: '|ψ_pre⟩'));
      await tester.tap(find.byKey(_k('state-expression-copy')));
      await tester.pump(const Duration(seconds: 2));
      expect(
          copied,
          formatQuantumStateExpression(vector,
              numQubits: 2, stateLabel: '|ψ_pre⟩'));
      // The label's subscript is typeset, not shown with an underscore.
      expect(find.text('pre'), findsOneWidget);
    });

    testWidgets('non-zero filter states what it hides; full list on demand',
        (tester) async {
      final vector = _basis(5, {0: Complex(_h, 0), 31: Complex(_h, 0)});
      await _pump(
          tester, QqCurrentStatePanel(stateVector: vector, numQubits: 5));
      expect(find.byKey(_k('state-row-0')), findsOneWidget);
      expect(find.byKey(_k('state-row-31')), findsOneWidget);
      expect(find.byKey(_k('state-row-1')), findsNothing);
      expect(find.text('30 zero amplitudes hidden'), findsOneWidget);
      await tester.tap(find.byKey(_k('state-show-zero')));
      await tester.pumpAndSettle();
      // Long tables collapse to 16 rows with an explicit "Show all".
      expect(find.byKey(_k('state-row-15')), findsOneWidget);
      expect(find.byKey(_k('state-row-16')), findsNothing);
      await tester.ensureVisible(find.byKey(_k('state-table-show-all')));
      await tester.tap(find.byKey(_k('state-table-show-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('state-row-31')), findsOneWidget);
      expect(find.byKey(_k('state-row-16')), findsOneWidget);
    });

    testWidgets('narrow hosts stack the decimal under its amplitude',
        (tester) async {
      await _pump(
          tester,
          QqCurrentStatePanel(
            stateVector: [Complex(_h, 0), Complex(0.5, 0.5)],
            numQubits: 1,
          ),
          width: 360);
      expect(find.text('Decimal'), findsNothing);
      expect(find.text('Amplitude · decimal'), findsOneWidget);
      final amplitude = tester.getRect(find.byKey(_k('state-amplitude-1')));
      final decimal = tester.getRect(find.byKey(_k('state-decimal-1')));
      expect(decimal.top, greaterThanOrEqualTo(amplitude.bottom - .5));
      expect(find.text('0.5000 + 0.5000i'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Probabilities', () {
    testWidgets('small distributions: one aligned row per outcome',
        (tester) async {
      final vector = _basis(2, {0: Complex(_h, 0), 3: Complex(_h, 0)});
      await _pump(tester,
          ProbabilityDistributionChart(stateVector: vector, numQubits: 2));
      for (var i = 0; i < 4; i++) {
        expect(find.byKey(_k('composer-probability-bar-$i')), findsOneWidget);
      }
      expect(find.bySemanticsLabel('|01⟩ probability 0%'), findsOneWidget);
      expect(find.byKey(_k('composer-probability-histogram')), findsNothing);
      expect(find.byKey(_k('composer-probability-show-all')), findsNothing);
      expect(find.textContaining('basis order |q1 q0⟩'), findsOneWidget);
    });

    testWidgets(
        'sparse five-qubit states list possible outcomes and count '
        'the rest', (tester) async {
      final vector = _basis(5, {0: Complex(_h, 0), 31: Complex(_h, 0)});
      await _pump(tester,
          ProbabilityDistributionChart(stateVector: vector, numQubits: 5));
      expect(find.byKey(_k('composer-probability-bar-0')), findsOneWidget);
      expect(find.byKey(_k('composer-probability-bar-31')), findsOneWidget);
      expect(find.byKey(_k('composer-probability-bar-1')), findsNothing);
      expect(find.text('30 outcomes with probability 0 not listed'),
          findsOneWidget);
      await tester.tap(find.byKey(_k('composer-probability-show-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('composer-probability-bar-1')), findsOneWidget);
    });

    testWidgets('dense states: histogram on 0–100% unless the learner zooms',
        (tester) async {
      final u = 1 / math.sqrt(32);
      await _pump(
          tester,
          ProbabilityDistributionChart(
              stateVector: List.generate(32, (_) => Complex(u, 0)),
              numQubits: 5));
      expect(find.byKey(_k('composer-probability-histogram')), findsOneWidget);
      expect(find.byKey(_k('composer-probability-bar-0')), findsNothing);
      expect(find.text('100%'), findsOneWidget,
          reason: 'fixed axis by default');
      expect(find.textContaining('axis 0–100%'), findsOneWidget);
      await tester.tap(find.byKey(_k('composer-probability-fit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('axis 0–3.125% (zoomed)'), findsOneWidget);
      await tester.tap(find.byKey(_k('composer-probability-show-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('composer-probability-bar-31')), findsOneWidget);
      expect(find.bySemanticsLabel('|10110⟩ probability 3.125%'), findsWidgets);
    });
  });

  group('Bloch summary', () {
    testWidgets('readout below the sphere; no probability overlay',
        (tester) async {
      var opened = false;
      await _pump(
          tester,
          QqBlochSummaryPanel(
            alpha: Complex.one(),
            beta: Complex.zero(),
            camera: const BlochCamera(),
            onCameraChanged: (_) {},
            onOpenExplorer: () => opened = true,
          ),
          width: 340);
      expect(find.byKey(_k('composer-bloch-readout')), findsOneWidget);
      expect(find.byKey(_k('bloch-live-probabilities')), findsNothing);
      expect(find.byKey(_k('bloch-live-angles')), findsNothing);
      expect(find.text('undefined at the pole'), findsOneWidget);
      expect(find.text('(0.000, 0.000, 1.000)'), findsOneWidget);
      await tester.tap(find.byKey(_k('composer-explore-in-bloch')));
      expect(opened, isTrue);
      expect(find.text('Open in Bloch Explorer'), findsOneWidget);
    });
  });

  group('data table', () {
    testWidgets('header cells sit exactly over their data', (tester) async {
      await _pump(
          tester,
          QqDataTable(
            columns: const [
              QqColumn('Basis', width: 90),
              QqColumn('Value', flex: 2),
              QqColumn('Number', flex: 1, align: QqColumn.right),
            ],
            rows: const [
              QqTableRow(cells: [
                Text('|00⟩'),
                Text('a long symbolic value', key: ValueKey('v')),
                Text('0.1234', key: ValueKey('n')),
              ]),
            ],
          ),
          width: 600);
      expect(tester.getRect(find.text('Value')).left,
          tester.getRect(find.byKey(const ValueKey('v'))).left);
      expect(tester.getRect(find.text('Number')).right,
          tester.getRect(find.byKey(const ValueKey('n'))).right);
    });
  });
}
