// Phase W4.2: unified Inspector (State / Bloch / Measure always present),
// one Measure experience for both execution modes, and a Circuit Workspace
// card whose geometry is independent of the Inspector.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/measured_circuit_run_panel.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';

import 'web_sandbox_measurement_test.dart' show openSandbox, tapVisible;

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

ValueKey<String> _k(String key) => ValueKey(key);
final _selector = find.byKey(_k('quantum-inspector-view-selector'));
Finder _tab(String label) =>
    find.descendant(of: _selector, matching: find.text(label));
final _runOnce = find.byKey(_k('web-sandbox-run-once'));
final _runShots = find.byKey(_k('web-sandbox-run-shots'));
final _shotField = find.byKey(_k('web-sandbox-shot-count'));
final _single = find.byKey(_k('web-sandbox-single-shot'));
final _shots = find.byKey(_k('web-sandbox-shots-result'));
final _circuitCard = find.byKey(_k('composer-region-canvas'));
final _inspectorRegion = find.byKey(_k('composer-region-inspector'));
final _inspectorCard = find.byKey(_k('web-composer-inspector-card'));
final _canvas = find.byKey(_k('web-composer-canvas'));

QuantumCircuit _circuit(WidgetTester tester) => tester
    .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
    .circuit;

MeasuredCircuitRunPanel _panel(WidgetTester tester) => tester
    .widget<MeasuredCircuitRunPanel>(find.byType(MeasuredCircuitRunPanel));

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(_k(key))).data!;

void _expectThreeTabs(WidgetTester tester) {
  final selector = tester.widget<SegmentedButton<Object>>(_selector);
  expect(selector.segments.map((s) => (s.label as Text).data),
      ['State', 'Bloch', 'Measure']);
  expect(selector.segments.every((s) => s.enabled), isTrue);
}

void main() {
  group('tabs', () {
    for (final qubits in [1, 2]) {
      testWidgets(
          '$qubits qubit(s): the same three tabs before, with and '
          'after M', (tester) async {
        await openSandbox(tester, InMemoryAppStorage(), qubits: qubits);
        _expectThreeTabs(tester);
        final c = _circuit(tester);
        c.insertSingleGateWithOutcome(_h, 0, 0);
        await tester.pumpAndSettle();
        _expectThreeTabs(tester);
        c.insertMeasurementWithOutcome(qubit: 0, column: 1);
        await tester.pumpAndSettle();
        _expectThreeTabs(tester);
        await tapVisible(tester, _tab('Measure'));
        c.removeMeasurement(c.measurements.single.id);
        await tester.pumpAndSettle();
        _expectThreeTabs(tester);
        expect(find.byType(MeasuredCircuitRunPanel), findsOneWidget,
            reason: 'the Measure tab stays selected and available');
      });
    }
  });

  group('one Measure experience, two engines', () {
    testWidgets('without M: final-state sampling with the same controls',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      final c = _circuit(tester);
      // Model-level edit: re-simulate as the host does after a UI drop.
      c.insertSingleGateWithOutcome(_x, 0, 0);
      c.runSimulation();
      await tester.pumpAndSettle();
      await tapVisible(tester, _tab('Measure'));
      expect(_text(tester, 'web-sandbox-measure-summary'),
          'Final-state sampling · all 2 qubits');
      expect(_text(tester, 'web-sandbox-measure-mode'),
          contains('measures every qubit in the Z basis'));
      expect(_runOnce, findsOneWidget);
      expect(_runShots, findsOneWidget);
      expect(_shotField, findsOneWidget);
      expect(find.byKey(_k('web-sandbox-shot-presets')), findsOneWidget);
      expect(find.text('Run 100 shots'), findsNothing);

      await tapVisible(tester, _runOnce);
      expect(_text(tester, 'web-sandbox-single-register'),
          'Outcome: |01⟩ (q1=0, q0=1)');
      await tapVisible(tester, _runShots);
      final result = _panel(tester).shotsResult!;
      expect(result.readout.isFinalState, isTrue);
      expect(result.counts, {'01': 1000});
      expect(_text(tester, 'web-sandbox-outcome-order'),
          startsWith('Outcome order: q1 q0'));
      expect(find.descendant(of: _shots, matching: find.text('|01⟩')),
          findsOneWidget);
      // M4: exact, observed and count columns (was "1,000 · 100.0%").
      expect(_text(tester, 'web-sandbox-outcome-count-01'), '1,000');
      expect(_text(tester, 'measure-observed-01'), '100%');
      expect(_text(tester, 'measure-exact-01'), '100%');
    });

    testWidgets('without M: custom count of 876 samples exactly 876 shots',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      _circuit(tester).insertSingleGateWithOutcome(_h, 0, 0);
      await tester.pumpAndSettle();
      await tapVisible(tester, _tab('Measure'));
      await tester.enterText(_shotField, '876');
      await tester.pumpAndSettle();
      await tapVisible(tester, _runShots);
      final result = _panel(tester).shotsResult!;
      expect(result.shots, 876);
      expect(result.counts.values.reduce((a, b) => a + b), 876);
      expect(find.text('876 SHOTS'), findsOneWidget);
    });

    testWidgets('with M: executes measurement operations into classical bits',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 3);
      final c = _circuit(tester);
      c.insertSingleGateWithOutcome(_x, 0, 1);
      c.insertMeasurementWithOutcome(qubit: 1, column: 1, classicalBit: 2);
      await tester.pumpAndSettle();
      await tapVisible(tester, _tab('Measure'));
      expect(_text(tester, 'web-sandbox-measure-summary'), 'Measures q1 → c2');
      expect(_text(tester, 'web-sandbox-measure-mode'),
          contains('every gate and M operation in order'));
      await tapVisible(tester, _runOnce);
      expect(_text(tester, 'web-sandbox-single-register'), 'Register: c2=1');
      await tapVisible(tester, _runShots);
      final result = _panel(tester).shotsResult!;
      expect(result.readout.isFinalState, isFalse);
      expect(result.counts, {'1': 1000});
    });

    testWidgets('switching mode by adding M clears earlier results',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      final c = _circuit(tester);
      await tapVisible(tester, _runShots);
      expect(_panel(tester).shotsResult!.readout.isFinalState, isTrue);
      c.insertMeasurementWithOutcome(qubit: 0, column: 0);
      await tester.pumpAndSettle();
      expect(_shots, findsNothing);
      expect(_single, findsNothing);
      await tapVisible(tester, _runShots);
      expect(_panel(tester).shotsResult!.readout.isFinalState, isFalse);
    });
  });

  group('State and Bloch', () {
    testWidgets('unmeasured: live final state and Bloch, without captions',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      _circuit(tester).insertSingleGateWithOutcome(_h, 0, 0);
      _circuit(tester).runSimulation();
      await tester.pumpAndSettle();
      expect(
          find.byKey(_k('web-composer-pre-measurement-caption')), findsNothing);
      expect(find.byKey(_k('web-composer-current-state')), findsOneWidget);
      await tapVisible(tester, _tab('Bloch'));
      expect(
          tester
              .widget<BlochSpherePanel>(find.byType(BlochSpherePanel))
              .state
              .x,
          closeTo(1, 1e-9));
      expect(find.byKey(_k('quantum-inspector-bloch-caption')), findsNothing);
    });

    testWidgets(
        'measured Bell pair: State shows the labelled pre-measurement '
        'state; Bloch explains it is one-qubit only', (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      final c = _circuit(tester);
      c.insertSingleGateWithOutcome(_h, 0, 0);
      c.insertDoubleGateWithOutcome(_cnot, 1, 1, 0);
      c.insertMeasurementWithOutcome(qubit: 0, column: 2);
      c.insertMeasurementWithOutcome(qubit: 1, column: 2);
      await tester.pumpAndSettle();
      expect(_text(tester, 'web-composer-pre-measurement-caption'),
          'Before measurement');
      final display = tester.widget<StateVectorDisplay>(find.descendant(
          of: find.byKey(_k('web-composer-current-state')),
          matching: find.byType(StateVectorDisplay),
          matchRoot: true));
      final amplitudes =
          display.stateVector.map((a) => a.real.toDouble()).toList();
      expect(amplitudes[0], closeTo(0.70710678, 1e-6));
      expect(amplitudes[3], closeTo(0.70710678, 1e-6));
      expect(amplitudes[1].abs() + amplitudes[2].abs(), lessThan(1e-9));
      await tapVisible(tester, _tab('Bloch'));
      expect(find.byKey(_k('quantum-inspector-bloch-unavailable-reason')),
          findsOneWidget);
    });

    testWidgets('a measured qubit used again: State explains, never guesses',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      final c = _circuit(tester);
      c.addMeasurement(column: 0, qubit: 0, classicalBit: 0);
      c.addMeasurement(column: 1, qubit: 0, classicalBit: 1);
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-composer-state-unavailable')), findsOneWidget);
      expect(find.byKey(_k('web-composer-current-state')), findsNothing);
      expect(find.text(PreMeasurementState.notTerminal(0)), findsOneWidget);
    });
  });

  group('independent layout', () {
    Future<QuantumCircuit> manyOutcomes(WidgetTester tester, Size size) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 5, size: size);
      final c = _circuit(tester);
      for (var q = 0; q < 5; q++) {
        c.insertSingleGateWithOutcome(_h, 0, q);
      }
      for (var q = 0; q < 5; q++) {
        c.insertMeasurementWithOutcome(qubit: q, column: 1);
      }
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('wide: separate columns; results never move the circuit',
        (tester) async {
      await manyOutcomes(tester, const Size(1440, 900));
      final card = tester.getRect(_circuitCard);
      final inspector = tester.getRect(_inspectorCard);
      expect(inspector.left, greaterThan(card.right),
          reason: 'results are an independent column');
      expect(inspector.top, closeTo(card.top, .5), reason: 'top-aligned');
      final canvas = tester.getRect(_canvas);
      final cardSize = tester.getSize(_circuitCard);
      final resultsSize = tester.getSize(_inspectorCard);

      for (final tab in ['Bloch', 'Measure']) {
        await tapVisible(tester, _tab(tab));
        expect(tester.getRect(_canvas), canvas, reason: tab);
      }
      await tester.tap(_runOnce);
      await tester.pumpAndSettle();
      await tester.tap(_runShots);
      await tester.pumpAndSettle();
      expect(_shots, findsOneWidget);
      expect(tester.getSize(_inspectorCard), resultsSize,
          reason: 'the results column scrolls inside itself');
      expect(tester.getRect(_canvas), canvas, reason: 'canvas did not move');
      expect(tester.getSize(_circuitCard), cardSize,
          reason: 'workspace height unchanged');
      final shots = tester.getRect(_shots);
      expect(shots.bottom, lessThanOrEqualTo(900));
      expect(shots.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'medium 900px: Circuit and Results views; running never changes '
        'the circuit', (tester) async {
      await manyOutcomes(tester, const Size(900, 900));
      final view = find.byKey(_k('composer-workspace-view'));
      expect(view, findsOneWidget);
      final canvas = tester.getRect(_canvas);
      final cardSize = tester.getSize(_circuitCard);
      await tapVisible(tester, _tab('Measure'));
      await tapVisible(tester, _runShots);
      final shots = tester.getRect(_shots);
      expect(shots.top, greaterThanOrEqualTo(0));
      expect(shots.bottom, lessThanOrEqualTo(900),
          reason: 'results scrolled into view');
      await tester
          .tap(find.descendant(of: view, matching: find.text('Circuit')));
      await tester.pumpAndSettle();
      expect(tester.getRect(_canvas), canvas);
      expect(tester.getSize(_circuitCard), cardSize);
      expect(_shots.hitTestable(), findsNothing,
          reason: 'results stay mounted offstage, not on top of the circuit');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'narrow 600px: stacked; circuit geometry fixed while results expand',
        (tester) async {
      await manyOutcomes(tester, const Size(600, 900));
      final card = tester.getRect(_circuitCard);
      final inspector = tester.getRect(_inspectorCard);
      expect(inspector.top, greaterThan(card.bottom), reason: 'stacked');
      final page = find.byKey(_k('composer-workspace-narrow'));
      double offset() => tester
          .state<ScrollableState>(find
              .descendant(of: page, matching: find.byType(Scrollable))
              .first)
          .position
          .pixels;
      final canvas = tester.getRect(_canvas).translate(0, offset());
      final cardSize = tester.getSize(_circuitCard);
      await tapVisible(tester, _tab('Measure'));
      await tapVisible(tester, _runShots);
      expect(tester.getRect(_canvas).translate(0, offset()), canvas);
      expect(tester.getSize(_circuitCard), cardSize);
      final shots = tester.getRect(_shots);
      expect(shots.top, greaterThanOrEqualTo(0));
      expect(shots.bottom, lessThanOrEqualTo(900),
          reason: 'results scrolled into view');
      expect(tester.takeException(), isNull);
    });

    testWidgets('editing controls live below the circuit, never in Results',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      final c = _circuit(tester);
      c.insertSingleGateWithOutcome(_x, 0, 0);
      await tester.pumpAndSettle();
      final canvas = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
      canvas.onGateTap(c.logicalGates.single.toPlacedGateRef());
      await tester.pumpAndSettle();
      for (final (key, region) in [
        ('web-composer-delete-selected-gate', _inspectorRegion),
        // M3.1: educational sections are tabs in the inspector.
        ('composer-inspector-tabs', _inspectorRegion),
        ('web-storage-status', _circuitCard),
      ]) {
        expect(find.descendant(of: region, matching: find.byKey(_k(key))),
            findsOneWidget,
            reason: key);
        expect(
            find.descendant(of: _inspectorCard, matching: find.byKey(_k(key))),
            findsNothing);
      }
    });
  });

  group('editing, persistence and messages', () {
    testWidgets('running never edits or saves; edits clear results',
        (tester) async {
      final storage = _CountingStorage();
      await openSandbox(tester, storage, qubits: 1);
      final c = _circuit(tester);
      c.insertSingleGateWithOutcome(_h, 0, 0);
      await tester.pumpAndSettle();
      final encoded = SandboxProgramSnapshot.capture(c).encode();
      final writes = storage.writes;
      await tapVisible(tester, _runOnce);
      await tapVisible(tester, _runShots);
      expect(SandboxProgramSnapshot.capture(c).encode(), encoded);
      expect(storage.writes, writes);
      c.insertSingleGateWithOutcome(_x, 0, 0);
      await tester.pumpAndSettle();
      expect(_shots, findsNothing);
      expect(_single, findsNothing);
    });

    testWidgets('no obsolete "execution not supported" messages',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 2);
      final c = _circuit(tester);
      final id =
          c.insertMeasurementWithOutcome(qubit: 0, column: 0).affectedGateId!;
      await tester.pumpAndSettle();
      final canvas = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
      canvas.onMeasurementSelected!(id);
      await tester.pumpAndSettle();
      for (final tab in ['State', 'Bloch', 'Measure']) {
        await tapVisible(tester, _tab(tab));
        for (final obsolete in [
          'execution is supported',
          'not been executed',
          'results will appear',
        ]) {
          expect(find.textContaining(obsolete), findsNothing,
              reason: '$tab: $obsolete');
        }
      }
      expect(
          _text(tester, 'web-composer-measurement-note'), contains('Measure'));
    });
  });
}
