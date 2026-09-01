import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';

void main() {
  test('adaptive non-zero default follows state-space size', () {
    expect(defaultNonZeroOnlyForQubitCount(1), isFalse);
    expect(defaultNonZeroOnlyForQubitCount(2), isFalse);
    expect(defaultNonZeroOnlyForQubitCount(3), isTrue);
    expect(defaultNonZeroOnlyForQubitCount(4), isTrue);
  });

  Future<void> pumpDisplay(
    WidgetTester tester, {
    required int qubits,
    required List<Complex> vector,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 500,
            child: StateVectorDisplay(
              key: const ValueKey('adaptive-filter-display'),
              stateVector: vector,
              numQubits: qubits,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  List<Complex> basisState(int qubits, int index) => [
        for (var basis = 0; basis < 1 << qubits; basis++)
          basis == index ? Complex.one() : Complex.zero(),
      ];

  for (final entry in {1: false, 2: false, 3: true, 4: true}.entries) {
    testWidgets('${entry.key}-qubit widget initial filter is ${entry.value}',
        (tester) async {
      await pumpDisplay(
        tester,
        qubits: entry.key,
        vector: basisState(entry.key, 0),
      );
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox)).value,
        entry.value,
      );
    });
  }

  testWidgets('three-qubit GHZ starts filtered and can reveal every row',
      (tester) async {
    final amplitude = Complex(math.sqrt1_2, 0);
    final ghz = [
      amplitude,
      ...List<Complex>.filled(6, Complex.zero()),
      amplitude,
    ];
    await pumpDisplay(tester, qubits: 3, vector: ghz);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(find.text('|000⟩'), findsOneWidget);
    expect(find.text('|111⟩'), findsOneWidget);
    for (final ket in ['|001⟩', '|010⟩', '|011⟩', '|100⟩', '|101⟩', '|110⟩']) {
      expect(find.text(ket), findsNothing);
    }

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    for (var basis = 0; basis < 8; basis++) {
      expect(
        find.text('|${basis.toRadixString(2).padLeft(3, '0')}⟩'),
        findsOneWidget,
      );
    }
  });

  testWidgets('three-qubit explicit OFF survives a state update',
      (tester) async {
    await pumpDisplay(tester, qubits: 3, vector: basisState(3, 0));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    await pumpDisplay(tester, qubits: 3, vector: basisState(3, 7));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(find.text('|000⟩'), findsOneWidget);
    expect(find.text('|111⟩'), findsOneWidget);
  });

  testWidgets('two-qubit explicit ON survives a state update', (tester) async {
    await pumpDisplay(tester, qubits: 2, vector: basisState(2, 0));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await pumpDisplay(tester, qubits: 2, vector: basisState(2, 3));

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(find.text('|00⟩'), findsNothing);
    expect(find.text('|11⟩'), findsOneWidget);
  });
}
