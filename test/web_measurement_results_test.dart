// Phase W4: Web measured-circuit execution panel and results lifecycle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/sandbox_load_recovery.dart';

import 'web_sandbox_measurement_test.dart' show openSandbox, tapVisible;
import 'support/laboratory_composer_finders.dart';
import 'package:quantumquiz/screens/web_app.dart' show debugClassicSandboxLayout;

class _CountingStorage extends InMemoryAppStorage {
  int writes = 0;
  @override
  Future<void> writeString(String key, String value) {
    writes++;
    return super.writeString(key, value);
  }
}

final _h = Gate.fromIdentifier(SelectedGateType.hadamard);
final _x = Gate.fromIdentifier(SelectedGateType.x);
final _cnot = Gate.fromIdentifier(SelectedGateType.cnot);

final _panel = find.byKey(const ValueKey('web-sandbox-run-panel'));
final _runOnce = find.byKey(const ValueKey('web-sandbox-run-once'));
final _runShots = find.byKey(const ValueKey('web-sandbox-run-shots'));
final _single = find.byKey(const ValueKey('web-sandbox-single-shot'));
final _shots = find.byKey(const ValueKey('web-sandbox-shots-result'));
final _register = find.byKey(const ValueKey('web-sandbox-single-register'));
final _error = find.byKey(const ValueKey('web-sandbox-run-error'));

QuantumCircuit _circuit(WidgetTester tester) => tester
    .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
    .circuit;

String _encode(QuantumCircuit c) => SandboxProgramSnapshot.capture(c).encode();

String _text(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).data!;

/// Observed count for [outcome], read from the rendered comparison row's
/// count cell; null when the outcome is not listed (impossible and
/// unobserved).
int? _count(WidgetTester tester, String outcome) {
  final cell = find.byKey(ValueKey('web-sandbox-outcome-count-$outcome'));
  if (cell.evaluate().isEmpty) return null;
  return int.parse(tester.widget<Text>(cell).data!.replaceAll(',', ''));
}

Future<void> _chooseShots(WidgetTester tester, int preset) async {
  await tapVisible(
      tester, find.byKey(const ValueKey('web-sandbox-shot-presets')));
  await tester.tap(find.byKey(ValueKey('web-sandbox-shot-preset-$preset')));
  await tester.pumpAndSettle();
}

final _measureTab = anyMeasureTab;

/// W4.2: results live in the Inspector's Measure tab.
Future<void> _openMeasure(WidgetTester tester) =>
    tapVisible(tester, _measureTab);

Future<QuantumCircuit> _measuredSandbox(
  WidgetTester tester,
  InMemoryAppStorage storage, {
  required int qubits,
  required void Function(QuantumCircuit) build,
  bool openMeasure = true,
}) async {
  await openSandbox(tester, storage, qubits: qubits);
  final c = _circuit(tester);
  build(c);
  await tester.pumpAndSettle();
  if (openMeasure) await _openMeasure(tester);
  return c;
}

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  testWidgets('panel replaces the placeholder; H → M runs once and in shots',
      (tester) async {
    final storage = _CountingStorage();
    final c = await _measuredSandbox(tester, storage, qubits: 1, build: (c) {
      c.insertSingleGateWithOutcome(_h, 0, 0);
      c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    });
    expect(_panel, findsOneWidget);
    expect(find.byType(UnexecutedMeasuredCircuit), findsNothing);
    expect(find.byKey(const ValueKey('web-sandbox-measure-summary')),
        findsOneWidget);
    expect(
        tester
            .widget<TextField>(
                find.byKey(const ValueKey('web-sandbox-shot-count')))
            .controller!
            .text,
        '1000',
        reason: 'default');
    final encoded = _encode(c);
    final writes = storage.writes;

    await tapVisible(tester, _runOnce);
    expect(_single, findsOneWidget);
    expect(_text(tester, _register), anyOf('Register: c0=0', 'Register: c0=1'));
    expect(
        find.textContaining('Measurement outcomes are random'), findsOneWidget);

    await tapVisible(tester, _runShots);
    expect(find.text('1,000 shots'), findsOneWidget);
    expect(
        _text(tester, find.byKey(const ValueKey('web-sandbox-outcome-order'))),
        startsWith('Outcome order: c0 (highest classical bit on the left)'));
    final zeros = _count(tester, '0')!, ones = _count(tester, '1')!;
    expect(zeros + ones, 1000);
    expect(zeros, inInclusiveRange(400, 600));
    // Observed frequencies are explained as estimates of the exact
    // probabilities shown beside them (M4 wording).
    expect(find.textContaining('fluctuate around the exact probabilities'),
        findsOneWidget);

    await _chooseShots(tester, 100);
    await tapVisible(tester, _runShots);
    expect(find.text('100 shots'), findsOneWidget);
    expect((_count(tester, '0') ?? 0) + (_count(tester, '1') ?? 0), 100);
    expect(_single, findsOneWidget, reason: 'latest single run is kept');

    // Running never edits the circuit or autosaves.
    expect(_encode(c), encoded);
    expect(storage.writes, writes);
    expect(tester.widget<FilledButton>(_runShots).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('X → M is 1 every time; destination shown in the register',
      (tester) async {
    await _measuredSandbox(tester, InMemoryAppStorage(), qubits: 3, build: (c) {
      c.insertSingleGateWithOutcome(_x, 0, 1);
      c.insertMeasurementWithOutcome(qubit: 1, column: 1, classicalBit: 2);
    });
    for (var i = 0; i < 3; i++) {
      await tapVisible(tester, _runOnce);
      expect(_text(tester, _register), 'Register: c2=1');
      expect(find.text('q1 → c2 = 1'), findsOneWidget);
    }
    await tapVisible(tester, _runShots);
    expect(_count(tester, '1'), 1000);
    expect(_count(tester, '0'), isNull);
  });

  testWidgets('Bell pair shows only correlated outcomes', (tester) async {
    await _measuredSandbox(tester, InMemoryAppStorage(), qubits: 2, build: (c) {
      c.insertSingleGateWithOutcome(_h, 0, 0);
      c.insertDoubleGateWithOutcome(_cnot, 1, 1, 0);
      c.insertMeasurementWithOutcome(qubit: 0, column: 2);
      c.insertMeasurementWithOutcome(qubit: 1, column: 2);
    });
    await tapVisible(tester, _runShots);
    final same = (_count(tester, '00') ?? 0) + (_count(tester, '11') ?? 0);
    expect(same, 1000);
    expect(_count(tester, '01'), isNull);
    expect(_count(tester, '10'), isNull);
    expect(_count(tester, '00'), inInclusiveRange(400, 600));
  });

  testWidgets('edits, destination changes and workspace switches clear results',
      (tester) async {
    final c = await _measuredSandbox(tester, InMemoryAppStorage(), qubits: 2,
        build: (c) {
      c.insertSingleGateWithOutcome(_x, 0, 0);
      c.insertMeasurementWithOutcome(qubit: 0, column: 1);
    });
    await tapVisible(tester, _runShots);
    await tapVisible(tester, _runOnce);
    expect(_shots, findsOneWidget);

    c.insertSingleGateWithOutcome(_h, 0, 1); // gate on unmeasured q1
    await tester.pumpAndSettle();
    expect(_shots, findsNothing);
    expect(_single, findsNothing);

    await tapVisible(tester, _runOnce);
    c.updateMeasurementClassicalBit(c.measurements.single.id, 1);
    await tester.pumpAndSettle();
    expect(_single, findsNothing);
    await tapVisible(tester, _runOnce);
    expect(_text(tester, _register), 'Register: c1=1');

    // M11C: the qubit choices are always visible in the header; the open
    // size is not re-chosen, so reopen it from storage via another size.
    await tapVisible(
        tester, find.byKey(const ValueKey('web-composer-qubits-1')));
    await tapVisible(
        tester, find.byKey(const ValueKey('web-composer-qubits-2')));
    await _openMeasure(tester);
    expect(_panel, findsOneWidget, reason: 'restored measured circuit');
    expect(_single, findsNothing, reason: 'no stale results after restore');
    expect(_shots, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('execution errors are explained and leave the circuit intact',
      (tester) async {
    final c = await _measuredSandbox(tester, InMemoryAppStorage(), qubits: 5,
        build: (c) {
      for (var i = 0; i < 31; i++) {
        c.insertSingleGateWithOutcome(_x, 99, i % 4);
      }
      c.insertMeasurementWithOutcome(qubit: 4, column: 0);
    });
    final encoded = _encode(c);
    await _chooseShots(tester, 10000);
    await tapVisible(tester, _runShots);
    expect(_error, findsOneWidget);
    expect(_text(tester, _error), contains('Reduce the shot count'));
    expect(_shots, findsNothing);
    expect(_encode(c), encoded);

    await _chooseShots(tester, 100);
    await tapVisible(tester, _runShots);
    expect(_error, findsNothing);
    expect(_count(tester, '0'), 100);
  });

  testWidgets('unmeasured circuits keep State and Bloch views', (tester) async {
    await _measuredSandbox(tester, InMemoryAppStorage(), qubits: 1, build: (c) {
      c.insertSingleGateWithOutcome(_h, 0, 0);
      c.runSimulation();
    }, openMeasure: false);
    expect(_panel, findsNothing, reason: 'State is the default tab');
    expect(find.byKey(const ValueKey('web-composer-current-state')),
        findsOneWidget);
    final selector = tester.widget<SegmentedButton<Object>>(
        find.byKey(const ValueKey('quantum-inspector-view-selector')));
    expect(selector.segments.map((s) => (s.label as Text).data),
        contains('Bloch'));
    expect(selector.segments.every((s) => s.enabled), isTrue);
  });

  for (final width in [1440.0, 900.0, 600.0]) {
    testWidgets('many outcomes scroll without overflow at ${width.toInt()}px',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(),
          qubits: 5, size: Size(width, 1000));
      final c = _circuit(tester);
      for (var q = 0; q < 5; q++) {
        c.insertSingleGateWithOutcome(_h, 0, q);
      }
      for (var q = 0; q < 5; q++) {
        c.insertMeasurementWithOutcome(qubit: q, column: 1);
      }
      await tester.pumpAndSettle();
      await tapVisible(tester, _runShots);
      expect(_shots, findsOneWidget);
      final order = _text(
          tester, find.byKey(const ValueKey('web-sandbox-outcome-order')));
      expect(order, startsWith('Outcome order: c4 c3 c2 c1 c0'));
      final distinct =
          int.parse(RegExp(r'· (\d+) distinct').firstMatch(order)!.group(1)!);
      expect(distinct, greaterThan(8));
      expect(find.byKey(const ValueKey('web-sandbox-outcomes-scroll')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
