// v2.6 M4: the Measure tab's exact-versus-observed presentation, the
// conditional state after a single run and the one-qubit Bloch selector,
// through the real web Composer.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/utils/probability_format.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/measured_circuit_run_panel.dart';

import 'web_sandbox_measurement_test.dart' show openSandbox, tapVisible;

ValueKey<String> _k(String key) => ValueKey(key);
final _runOnce = find.byKey(_k('web-sandbox-run-once'));
final _runShots = find.byKey(_k('web-sandbox-run-shots'));

QuantumCircuit _circuit(WidgetTester tester) => tester
    .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
    .circuit;

MeasuredCircuitRunPanel _panel(WidgetTester tester) => tester
    .widget<MeasuredCircuitRunPanel>(find.byType(MeasuredCircuitRunPanel));

String? _text(WidgetTester tester, String key) {
  final f = find.byKey(_k(key));
  return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
}

Gate _g(SelectedGateType t, [double? angle]) =>
    Gate.fromIdentifier(t, angle: angle);

class _CountingStorage extends InMemoryAppStorage {
  int writes = 0;
  @override
  Future<void> writeString(String key, String value) {
    writes++;
    return super.writeString(key, value);
  }
}

Future<void> _measureTab(WidgetTester tester) => tapVisible(
    tester,
    find.descendant(
        of: find.byKey(_k('quantum-inspector-view-selector')),
        matching: find.text('Measure')));

void main() {
  testWidgets('H → M: exact before sampling, observed after, same scale',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
    final c = _circuit(tester);
    c.insertSingleGateWithOutcome(_g(SelectedGateType.hadamard), 0, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    await tester.pumpAndSettle();
    await _measureTab(tester);

    // Before sampling: exact column only; no artificial observations.
    expect(_text(tester, 'measure-exact-0'), '50%');
    expect(_text(tester, 'measure-exact-1'), '50%');
    expect(find.byKey(_k('measure-observed-0')), findsNothing);
    expect(find.byKey(_k('web-sandbox-outcome-count-0')), findsNothing);
    expect(find.byKey(_k('measure-no-observed')), findsOneWidget);
    expect(_text(tester, 'web-sandbox-measure-summary'), 'Measures q0 → c0');

    await tapVisible(tester, _runShots);
    final observed = _panel(tester).shotsResult!;
    final zeros = observed.counts['0'] ?? 0, ones = observed.counts['1'] ?? 0;
    expect(zeros + ones, 1000);
    expect(_text(tester, 'web-sandbox-outcome-count-0'), formatCount(zeros));
    expect(_text(tester, 'measure-observed-0'), formatProbability(zeros / 1000),
        reason: 'observed frequency is count / shots of the actual samples');
    expect(_text(tester, 'measure-exact-0'), '50%', reason: 'unchanged');
    final bar = tester.widget<ComparisonBar>(find.byKey(_k('measure-bar-0')));
    expect(bar.exact, closeTo(.5, 1e-12));
    expect(bar.observed, zeros / 1000);
    expect(find.text('1,000 SHOTS'), findsOneWidget);

    // Changing the shot count never relabels the existing result.
    await tester.enterText(find.byKey(_k('web-sandbox-shot-count')), '250');
    await tester.pumpAndSettle();
    expect(find.text('1,000 SHOTS'), findsOneWidget);
    expect(find.byKey(_k('measure-shots-changed')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bell, only q0 measured: marginal 50/50 on c0 alone',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
    final c = _circuit(tester);
    c.insertSingleGateWithOutcome(_g(SelectedGateType.hadamard), 0, 0);
    c.insertDoubleGateWithOutcome(_g(SelectedGateType.cnot), 1, 1, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 2);
    await tester.pumpAndSettle();
    await _measureTab(tester);
    expect(_text(tester, 'measure-exact-0'), '50%');
    expect(_text(tester, 'measure-exact-1'), '50%');
    expect(find.byKey(_k('measure-exact-00')), findsNothing,
        reason: 'outcomes are classical bits, not two-qubit basis states');
    expect(
        find.textContaining('unmeasured qubits are not read'), findsOneWidget);
    await tapVisible(tester, _runOnce);
    final single = _panel(tester).singleShot!;
    // Conditional register state: |00⟩ after 0, |11⟩ after 1.
    final state = single.conditionalState!;
    final hit = single.outcome == '0' ? 0 : 3;
    expect(state[hit].real, closeTo(1, 1e-12));
    expect(find.byKey(_k('measure-conditional-state')), findsOneWidget);
    expect(find.textContaining('|ψ_after⟩ ='), findsOneWidget);
  });

  testWidgets('Bell, both measured: All outcomes lists impossible ones',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
    final c = _circuit(tester);
    c.insertSingleGateWithOutcome(_g(SelectedGateType.hadamard), 0, 0);
    c.insertDoubleGateWithOutcome(_g(SelectedGateType.cnot), 1, 1, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 2);
    c.insertMeasurementWithOutcome(qubit: 1, column: 2);
    await tester.pumpAndSettle();
    await _measureTab(tester);
    await tapVisible(tester, _runShots);
    final counts = _panel(tester).shotsResult!.counts;
    expect(counts.keys.toSet().difference({'00', '11'}), isEmpty);
    expect(find.byKey(_k('measure-exact-01')), findsNothing);
    await tapVisible(tester, find.text('All'));
    expect(_text(tester, 'measure-exact-01'), '0%');
    expect(_text(tester, 'web-sandbox-outcome-count-01'), '0');
    expect(tester.takeException(), isNull);
  });

  testWidgets('classical mapping: q0 → c2, q2 → c0 reads c2 c0',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 3);
    final c = _circuit(tester);
    c.insertSingleGateWithOutcome(_g(SelectedGateType.x), 0, 0);
    c.insertSingleGateWithOutcome(_g(SelectedGateType.ry, math.pi / 3), 0, 2);
    c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    c.insertMeasurementWithOutcome(qubit: 2, column: 1);
    final m0 = c.measurements.firstWhere((m) => m.qubit == 0);
    final m2 = c.measurements.firstWhere((m) => m.qubit == 2);
    c.updateMeasurementClassicalBit(m2.id, 1);
    c.updateMeasurementClassicalBit(m0.id, 2);
    c.updateMeasurementClassicalBit(m2.id, 0);
    await tester.pumpAndSettle();
    await _measureTab(tester);
    expect(_text(tester, 'web-sandbox-outcome-order'),
        startsWith('Outcome order: c2 c0'));
    // c2 = q0 = 1; c0 = q2 = 1 with sin²(π/6) = ¼.
    expect(_text(tester, 'measure-exact-10'), '75%');
    expect(_text(tester, 'measure-exact-11'), '25%');
    expect(_text(tester, 'web-sandbox-measure-summary'),
        anyOf('Measures q0 → c2, q2 → c0', 'Measures q2 → c0, q0 → c2'));
  });

  testWidgets('X → M single run: conditional |1⟩ and pre/post Bloch views',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
    final c = _circuit(tester);
    c.insertSingleGateWithOutcome(_g(SelectedGateType.x), 0, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    await tester.pumpAndSettle();
    await _measureTab(tester);
    expect(_text(tester, 'measure-exact-1'), '100%');
    expect(find.byKey(_k('measure-exact-0')), findsNothing);
    await tapVisible(tester, _runOnce);
    expect(_panel(tester).singleShot!.outcome, '1');
    expect(find.byKey(_k('measure-conditional-state')), findsOneWidget);

    await tapVisible(
        tester,
        find.descendant(
            of: find.byKey(_k('quantum-inspector-view-selector')),
            matching: find.text('Bloch')));
    expect(find.byKey(_k('bloch-pre-post-selector')), findsOneWidget);
    expect(find.text('Before measurement'), findsWidgets);
    await tester.tap(find.text('After single run'));
    await tester.pumpAndSettle();
    expect(find.text('After the single run (outcome 1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('final-state sampling never shows a conditional state',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
    _circuit(tester)
      ..insertSingleGateWithOutcome(_g(SelectedGateType.hadamard), 0, 0)
      ..runSimulation();
    await tester.pumpAndSettle();
    await _measureTab(tester);
    expect(_text(tester, 'measure-exact-0'), '50%');
    await tapVisible(tester, _runOnce);
    expect(_panel(tester).singleShot!.conditionalState, isNull);
    expect(find.byKey(_k('measure-conditional-state')), findsNothing);
    await tapVisible(tester, _runShots);
    expect(find.byKey(_k('measure-single-separate')), findsOneWidget,
        reason: 'single run and shots are labelled as separate executions');
  });

  testWidgets('sampling never edits, records history or saves the circuit',
      (tester) async {
    final storage = _CountingStorage();
    await openSandbox(tester, storage, qubits: 1);
    final c = _circuit(tester);
    c.insertSingleGateWithOutcome(_g(SelectedGateType.hadamard), 0, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    await tester.pumpAndSettle();
    await _measureTab(tester);
    final writes = storage.writes;
    final ops = c.logicalGates.length + c.measurements.length;
    for (var i = 0; i < 3; i++) {
      await tapVisible(tester, _runOnce);
      await tapVisible(tester, _runShots);
    }
    expect(storage.writes, writes, reason: 'no autosave from sampling');
    expect(c.logicalGates.length + c.measurements.length, ops);
  });

  testWidgets('an edit invalidates results and updates the exact prediction',
      (tester) async {
    await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
    final c = _circuit(tester);
    c.insertSingleGateWithOutcome(_g(SelectedGateType.hadamard), 0, 0);
    c.insertSingleGateWithOutcome(_g(SelectedGateType.rz, math.pi / 2), 1, 0);
    c.insertSingleGateWithOutcome(_g(SelectedGateType.hadamard), 2, 0);
    c.insertMeasurementWithOutcome(qubit: 0, column: 3);
    await tester.pumpAndSettle();
    await _measureTab(tester);
    expect(_text(tester, 'measure-exact-0'), '50%');
    await tapVisible(tester, _runShots);
    expect(_panel(tester).shotsResult, isNotNull);

    // θ = π/4: P(0) = cos²(π/8) = 85.36%.
    final rz = c.logicalGates.singleWhere((g) => g.type == SelectedGateType.rz);
    tester
        .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
        .onGateTap(rz.toPlacedGateRef());
    await tester.pumpAndSettle();
    // The inspector's preset commits through the session (one edit).
    await tapVisible(tester, find.byKey(_k('composer-angle-preset-π/4')));
    expect(_panel(tester).shotsResult, isNull, reason: 'stale results cleared');
    expect(_text(tester, 'measure-exact-0'), '85.36%');
    expect(_text(tester, 'measure-exact-1'), '14.64%');
  });

  testWidgets('dense five qubits at the minimum results width', (tester) async {
    await openSandbox(tester, InMemoryAppStorage(),
        qubits: 5, size: const Size(1100, 900));
    final c = _circuit(tester);
    for (var q = 0; q < 5; q++) {
      c.insertSingleGateWithOutcome(_g(SelectedGateType.hadamard), 0, q);
    }
    for (var q = 0; q < 5; q++) {
      c.insertMeasurementWithOutcome(qubit: q, column: 1);
    }
    await tester.pumpAndSettle();
    await _measureTab(tester);
    expect(_text(tester, 'measure-exact-00000'), '3.125%');
    expect(find.byKey(_k('web-sandbox-outcomes-scroll')), findsOneWidget);
    await tapVisible(tester, _runShots);
    expect(find.text('1,000 SHOTS'), findsOneWidget);
    expect(find.textContaining('Total exact probability 100%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
