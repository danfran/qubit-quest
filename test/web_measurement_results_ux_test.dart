// Phase W4.1: measured-circuit results visibility, run controls, custom shot
// counts and the pre-measurement Bloch view.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';

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

ValueKey<String> _k(String key) => ValueKey(key);
final _runOnce = find.byKey(_k('web-sandbox-run-once'));
final _runShots = find.byKey(_k('web-sandbox-run-shots'));
final _shotField = find.byKey(_k('web-sandbox-shot-count'));
final _shotError = find.byKey(_k('web-sandbox-shot-count-error'));
final _single = find.byKey(_k('web-sandbox-single-shot'));
final _shots = find.byKey(_k('web-sandbox-shots-result'));
final _footer = find.byKey(_k('composer-region-inspector'));
final _blochSegment = find.descendant(
  of: find.byKey(_k('quantum-inspector-view-selector')),
  matching: find.text('Bloch'),
);

QuantumCircuit _circuit(WidgetTester tester) => tester
    .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
    .circuit;

Future<QuantumCircuit> _measured(
  WidgetTester tester, {
  required int qubits,
  Size size = const Size(1440, 900),
  InMemoryAppStorage? storage,
  bool openMeasure = true,
}) async {
  await openSandbox(tester, storage ?? InMemoryAppStorage(),
      qubits: qubits, size: size);
  final c = _circuit(tester);
  c.insertSingleGateWithOutcome(_h, 0, 0);
  c.insertMeasurementWithOutcome(qubit: 0, column: 1);
  await tester.pumpAndSettle();
  if (openMeasure) await tapVisible(tester, _measureTab);
  return c;
}

final _measureTab = anyMeasureTab;
final _inspectorCard = find.byKey(_k('web-composer-inspector-card'));

double _inspectorOffset(WidgetTester tester) => tester
    .state<ScrollableState>(find
        .descendant(
          of: find.byKey(_k('web-composer-inspector-scroll')),
          matching: find.byType(Scrollable),
        )
        .first)
    .position
    .pixels;

double _pageOffset(WidgetTester tester) => tester
    .state<ScrollableState>(find
        .descendant(
          of: find.byKey(_k('web-composer-workspace-scroll')),
          matching: find.byType(Scrollable),
        )
        .first)
    .position
    .pixels;

/// The whole section is inside the window and inside the Inspector card
/// (never clipped by the card or covered by the Gate Inspector).
void _expectFullyVisible(WidgetTester tester, Finder section) {
  final rect = tester.getRect(section);
  final view = tester.view.physicalSize / tester.view.devicePixelRatio;
  final card = tester.getRect(_inspectorCard);
  expect(rect.top, greaterThanOrEqualTo(0), reason: 'top in view: $rect');
  expect(rect.bottom, lessThanOrEqualTo(view.height),
      reason: 'bottom in view: $rect');
  expect(rect.top, greaterThanOrEqualTo(card.top - .5));
  expect(rect.bottom, lessThanOrEqualTo(card.bottom + .5),
      reason: 'inside the Inspector card: $rect vs $card');
  // In the medium Results view the inspector is offstage and cannot cover
  // anything; elsewhere results must never sit behind it.
  if (_footer.evaluate().isNotEmpty) {
    final footer = tester.getRect(_footer);
    expect(rect.overlaps(footer), isFalse, reason: 'not behind the inspector');
  }
}

/// Taps without pre-scrolling, so any scrolling seen afterwards is the
/// panel's own reveal behaviour.
Future<void> _tapInPlace(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _typeShots(WidgetTester tester, String text) async {
  if (_shotField.evaluate().isEmpty) await tapVisible(tester, _measureTab);
  await tester.ensureVisible(_shotField);
  await tester.enterText(_shotField, text);
  await tester.pumpAndSettle();
}

int _histogramTotal(WidgetTester tester) {
  // Sums the comparison rows' observed count cells.
  var total = 0;
  for (final element in find
      .byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>)
              .value
              .startsWith('web-sandbox-outcome-count-'))
      .evaluate()) {
    total += int.parse((element.widget as Text).data!.replaceAll(',', ''));
  }
  return total;
}

BlochSpherePanel _sphere(WidgetTester tester) =>
    tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  group('results visibility', () {
    for (final size in const [Size(1440, 900), Size(1440, 700)]) {
      testWidgets(
          'desktop ${size.width.toInt()}x${size.height.toInt()}: '
          'Run once and Run shots results are fully visible', (tester) async {
        await _measured(tester, qubits: 3, size: size);
        await _tapInPlace(tester, _runOnce);
        expect(_single, findsOneWidget);
        _expectFullyVisible(tester, _single);

        await _tapInPlace(tester, _runShots);
        expect(_shots, findsOneWidget);
        _expectFullyVisible(tester, _shots);
        // W4.2: the Inspector card scrolls by itself, inside the window.
        expect(
            find.ancestor(
                of: find.byKey(_k('web-sandbox-run-panel')),
                matching: find.byKey(_k('web-composer-inspector-scroll'))),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('new results are scrolled into view automatically',
        (tester) async {
      await _measured(tester, qubits: 3, size: const Size(1440, 640));
      await _tapInPlace(tester, _runOnce);
      await tester.ensureVisible(_runShots);
      await tester.pumpAndSettle();
      final page = _pageOffset(tester);
      final inspector = _inspectorOffset(tester);
      final canvas = tester.getRect(find.byKey(_k('web-composer-canvas')));
      await tester.tap(_runShots);
      await tester.pumpAndSettle();
      expect(_inspectorOffset(tester), greaterThan(inspector),
          reason: 'the Inspector card scrolled to reveal the histogram');
      expect(_pageOffset(tester), page, reason: 'the page did not move');
      expect(tester.getRect(find.byKey(_k('web-composer-canvas'))), canvas,
          reason: 'the circuit did not move');
      _expectFullyVisible(tester, _shots);
    });

    for (final width in const [600.0, 900.0]) {
      testWidgets('narrow ${width.toInt()}px: results visible, no clipping',
          (tester) async {
        await _measured(tester, qubits: 2, size: Size(width, 900));
        await tapVisible(tester, _runOnce);
        _expectFullyVisible(tester, _single);
        await _tapInPlace(tester, _runShots);
        _expectFullyVisible(tester, _shots);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('run controls', () {
    for (final width in const [1440.0, 900.0]) {
      testWidgets('shot count sits beside Run shots at ${width.toInt()}px',
          (tester) async {
        await _measured(tester, qubits: 1, size: Size(width, 900));
        final once = tester.getRect(_runOnce);
        final shots = tester.getRect(_runShots);
        final field = tester.getRect(_shotField);
        // M11C.1: the experiment's primary action (Run shots with its
        // count) comes first; Run once is the secondary row below it.
        expect(shots.bottom, lessThanOrEqualTo(once.top),
            reason: 'Run once is on its own row below Run shots');
        expect((field.center.dy - shots.center.dy).abs(), lessThan(4),
            reason: 'shot count is on the Run shots row');
        expect(field.left, greaterThan(shots.right));
        expect(field.left - shots.right, lessThan(24));
      });
    }

    testWidgets('a custom count of 876 runs exactly 876 shots', (tester) async {
      await _measured(tester, qubits: 1);
      await _typeShots(tester, '876');
      expect(_shotError, findsNothing);
      await tapVisible(tester, _runShots);
      expect(find.text('876 shots'), findsOneWidget);
      expect(_histogramTotal(tester), 876);
    });

    testWidgets('presets fill the field; grouped input is accepted',
        (tester) async {
      await _measured(tester, qubits: 1);
      await tapVisible(tester, find.byKey(_k('web-sandbox-shot-presets')));
      await tester.tap(find.byKey(_k('web-sandbox-shot-preset-100')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_shotField).controller!.text, '100');
      await _typeShots(tester, '2,500');
      await tapVisible(tester, _runShots);
      expect(find.text('2,500 shots'), findsOneWidget);
      expect(_histogramTotal(tester), 2500);
    });

    testWidgets('invalid shot counts are rejected without running',
        (tester) async {
      final c = await _measured(tester, qubits: 1);
      final encoded = SandboxProgramSnapshot.capture(c).encode();
      for (final input in ['', 'abc', '87.6', '0', '-5', '10001', '1e3']) {
        await _typeShots(tester, input);
        expect(_shotError, findsOneWidget, reason: '"$input" is rejected');
        expect(tester.widget<FilledButton>(_runShots).onPressed, isNull,
            reason: 'Run shots disabled for "$input"');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(_shots, findsNothing, reason: '"$input" did not run');
        expect(tester.widget<TextField>(_shotField).controller!.text, input,
            reason: 'never rounded or substituted');
      }
      expect(tester.widget<ButtonStyleButton>(_runOnce).onPressed, isNotNull,
          reason: 'Run once does not depend on the shot count');
      await _typeShots(tester, '10000');
      expect(_shotError, findsNothing);
      expect(tester.widget<FilledButton>(_runShots).onPressed, isNotNull);
      expect(SandboxProgramSnapshot.capture(c).encode(), encoded);
    });

    testWidgets('a custom count over the work budget asks for fewer shots',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 5);
      final c = _circuit(tester);
      for (var i = 0; i < 31; i++) {
        c.insertSingleGateWithOutcome(_x, 99, i % 4);
      }
      c.insertMeasurementWithOutcome(qubit: 4, column: 0);
      await tester.pumpAndSettle();
      // 9,470 × 2^5 × (32 + 1) exceeds the executor's 10,000,000 budget.
      await _typeShots(tester, '9470');
      await tapVisible(tester, _runShots);
      final error = find.byKey(_k('web-sandbox-run-error'));
      _expectFullyVisible(tester, error);
      expect(tester.widget<Text>(error).data,
          contains('too large to run 9,470 shots'));
      expect(
          tester.widget<Text>(error).data, contains('Reduce the shot count'));
      expect(_shots, findsNothing);
    });
  });

  group('Bloch before measurement', () {
    Future<void> openBloch(WidgetTester tester) async {
      await tapVisible(tester, _blochSegment);
      expect(find.byKey(_k('quantum-inspector-bloch-view')), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.byKey(_k('quantum-inspector-bloch-caption')))
              .data,
          'Before measurement');
      expect(
          tester
              .widget<Text>(find.byKey(_k('quantum-inspector-bloch-note')))
              .data,
          contains('not a sampled outcome'));
    }

    testWidgets('X → M points to |1⟩', (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      final c = _circuit(tester);
      c.insertSingleGateWithOutcome(_x, 0, 0);
      c.insertMeasurementWithOutcome(qubit: 0, column: 1);
      await tester.pumpAndSettle();
      await openBloch(tester);
      final state = _sphere(tester).state;
      expect(state.z, closeTo(-1, 1e-9));
    });

    testWidgets('H → M is |+⟩ and follows edits before the measurement',
        (tester) async {
      final c = await _measured(tester, qubits: 1);
      await openBloch(tester);
      var state = _sphere(tester).state;
      expect(state.x, closeTo(1, 1e-9));
      expect(state.z, closeTo(0, 1e-9));

      // X inserted before H: H X |0⟩ = |−⟩.
      c.insertSingleGateWithOutcome(_x, 0, 0);
      await tester.pumpAndSettle();
      expect(c.measurements, hasLength(1), reason: 'measurement kept');
      state = _sphere(tester).state;
      expect(state.x, closeTo(-1, 1e-9));
      expect(find.byKey(_k('quantum-inspector-bloch-caption')), findsOneWidget);
    });

    testWidgets('viewing Bloch neither edits nor saves the circuit',
        (tester) async {
      final storage = _CountingStorage();
      final c = await _measured(tester, qubits: 1, storage: storage);
      final encoded = SandboxProgramSnapshot.capture(c).encode();
      final writes = storage.writes;
      await openBloch(tester);
      await tapVisible(tester, find.text('State'));
      await tapVisible(tester, _runShots);
      expect(SandboxProgramSnapshot.capture(c).encode(), encoded);
      expect(storage.writes, writes);
    });

    String reason(WidgetTester tester) => tester
        .widget<Text>(
            find.byKey(_k('quantum-inspector-bloch-unavailable-reason')))
        .data!;

    testWidgets('multi-qubit circuits explain Bloch inside its tab',
        (tester) async {
      await _measured(tester, qubits: 2, openMeasure: false);
      final selector = tester.widget<SegmentedButton<Object>>(
          find.byKey(_k('quantum-inspector-view-selector')));
      expect(selector.segments.every((s) => s.enabled), isTrue,
          reason: 'navigation never changes');
      await tapVisible(tester, _blochSegment);
      expect(find.byKey(_k('quantum-inspector-bloch-view')), findsNothing);
      expect(reason(tester), contains('single qubit'));
      expect(reason(tester), contains('2 qubits'));
    });

    testWidgets('two measurements on one qubit: Bloch explains why',
        (tester) async {
      await openSandbox(tester, InMemoryAppStorage(), qubits: 1);
      final c = _circuit(tester);
      c.addMeasurement(column: 0, qubit: 0, classicalBit: 0);
      c.addMeasurement(column: 1, qubit: 0, classicalBit: 1);
      await tester.pumpAndSettle();
      await tapVisible(tester, _blochSegment);
      expect(reason(tester), PreMeasurementState.notTerminal(0));
      expect(find.byKey(_k('quantum-inspector-bloch-view')), findsNothing);
    });

    testWidgets('selected Bloch stays selected and explains when unsupported',
        (tester) async {
      final c = await _measured(tester, qubits: 1);
      await openBloch(tester);
      c.addMeasurement(column: 2, qubit: 0, classicalBit: 1);
      await tester.pumpAndSettle();
      expect(find.byKey(_k('quantum-inspector-bloch-view')), findsNothing);
      expect(reason(tester), PreMeasurementState.notTerminal(0));
    });
  });
}
