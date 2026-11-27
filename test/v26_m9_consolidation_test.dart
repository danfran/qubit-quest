// v2.6 M9: consolidation regressions (notation, workspace, isolation).
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_lab.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_bloch_workspace.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/complex_formatter.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';
import 'support/laboratory_composer_finders.dart';

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

String _expr(List<Complex> v, int n) =>
    formatQuantumStateExpression(v, numQubits: n);

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  group('shared notation', () {
    test('imaginary unit placement is unambiguous', () {
      expect(formatComplex(Complex(0, math.sqrt1_2)), 'i/√2');
      expect(formatComplex(Complex(0, -math.sqrt1_2)), '-i/√2');
      expect(formatComplex(Complex(.5, .5)), '1/2 + i/2');
      expect(formatComplex(Complex(0, .75)), '3i/4');
      expect(formatComplex(Complex(0, 1)), 'i');
      for (final c in [
        Complex(0, .5),
        Complex(.5, -.5),
        Complex(0, math.sqrt1_2)
      ]) {
        expect(formatComplex(c), isNot(matches(RegExp(r'/[^ ]*i$'))),
            reason: 'never "1/2i" or "1/√2i"');
      }
    });

    test('decimals are never shown as implausible fractions', () {
      expect(formatComplex(Complex(.70710678, -.123456)), '0.7071 - 0.1235i');
      expect(formatComplex(Complex(.375, 0)), '3/8');
    });

    test('state expressions use subtraction and bare unit coefficients', () {
      final r = math.sqrt1_2;
      expect(
          _expr([Complex(r, 0), Complex.zero(), Complex.zero(), Complex(-r, 0)],
              2),
          '|ψ⟩ = (1/√2)|00⟩ − (1/√2)|11⟩');
      expect(_expr([Complex(r, 0), Complex(0, r)], 1),
          '|ψ⟩ = (1/√2)|0⟩ + (i/√2)|1⟩');
      expect(_expr([Complex(r, 0), Complex(0, -r)], 1),
          '|ψ⟩ = (1/√2)|0⟩ − (i/√2)|1⟩');
      expect(_expr([Complex(-1, 0), Complex.zero()], 1), '|ψ⟩ = −|0⟩');
      expect(_expr([Complex.zero(), Complex(0, 1)], 1), '|ψ⟩ = i|1⟩');
      expect(_expr([Complex(.5, .5), Complex(.5, -.5)], 1),
          '|ψ⟩ = (1/2 + i/2)|0⟩ + (1/2 − i/2)|1⟩');
      for (final s in [
        _expr([Complex(r, 0), Complex(-r, 0)], 1),
        _expr(
            [Complex(.5, 0), Complex(-.5, 0), Complex(0, -.5), Complex(.5, 0)],
            2),
      ]) {
        expect(s, isNot(contains('+ (−')));
        expect(s, isNot(contains('+ −')));
      }
    });

    test('rotation labels use π/2, never 1/2π', () {
      expect(Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2).label,
          'Rz\nπ/2');
      expect(
          Gate.fromIdentifier(SelectedGateType.rx, angle: 3 * math.pi / 4)
              .label,
          'Rx\n3π/4');
      expect(
          Gate.fromIdentifier(SelectedGateType.ry, angle: -math.pi / 4).label,
          'Ry\n−π/4');
    });

    test('Bloch numbers never show negative zero', () {
      expect(blochNumber(-1e-17, digits: 3), '0.000');
      expect(blochNumber(-.5, digits: 3), '−0.500');
    });
  });

  group('persistence', () {
    test('a measured circuit is the same definition after a restore', () {
      final c = QuantumCircuit(currentLevel: createSandboxComposerLevel(2));
      c.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      c.insertDoubleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      c.insertMeasurementWithOutcome(qubit: 0, column: 2);
      final back = SandboxProgramSnapshot.decode(
              SandboxProgramSnapshot.capture(c).encode())
          .restoreCircuit();
      expect(
          back.captureEditSnapshot().sameDefinitionAs(c.captureEditSnapshot()),
          isTrue);
      // Different measurement width is still a different definition.
      c.insertMeasurementWithOutcome(qubit: 1, column: 2, classicalBit: 3);
      expect(
          back.captureEditSnapshot().sameDefinitionAs(c.captureEditSnapshot()),
          isFalse);
    });
  });

  group('Composer', () {
    test('minimum register sizes', () {
      expect(minimumQubitsFor(SelectedGateType.hadamard), 1);
      expect(minimumQubitsFor(SelectedGateType.cy), 2);
      expect(minimumQubitsFor(SelectedGateType.ccnot), 3);
      expect(minimumQubitsFor(SelectedGateType.mcx), 4);
    });

    testWidgets(
        'gates that do not fit are shown unavailable, still previewable',
        (tester) async {
      _size(tester, const Size(400, 900));
      SelectedGateType? previewed;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ComposerGatePalettePanel(
            gates: [
              for (final t in sandboxGatePaletteTypes) Gate.fromIdentifier(t)
            ],
            allowsMeasurement: true,
            numQubits: 3,
            onPreview: (t) => previewed = t,
          ),
        ),
      ));
      Draggable<Object> drag(SelectedGateType t) => tester
          .widget(find.byKey(ValueKey('composer-palette-gate-${t.name}')));
      expect(drag(SelectedGateType.mcx).maxSimultaneousDrags, 0);
      expect(drag(SelectedGateType.ccnot).maxSimultaneousDrags, isNull);
      expect(
          find.byWidgetPredicate((w) =>
              w is Tooltip &&
              (w.message ?? '').startsWith('Needs at least 4 qubits')),
          findsOneWidget);
      await tester.ensureVisible(
          find.byKey(const ValueKey('composer-palette-gate-mcx')));
      await tester.tap(find.byKey(const ValueKey('composer-palette-gate-mcx')));
      expect(previewed, SelectedGateType.mcx);
    });

    testWidgets('a five-qubit circuit stays visible with the inspector open',
        (tester) async {
      _size(tester, const Size(1280, 800));
      await tester.pumpWidget(QubitQuestWebApp(storage: InMemoryAppStorage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
      await tester.pump();
      await pumpUntilSandboxOpen(tester);
      await tester.tap(find.byKey(const ValueKey('web-composer-qubits-5')));
      await tester.pumpAndSettle();
      // Preview a gate: the inspector shows a subject.
      await tester
          .tap(find.byKey(const ValueKey('composer-palette-gate-hadamard')));
      await tester.pumpAndSettle();
      final canvas =
          tester.getRect(find.byKey(const ValueKey('composer-region-canvas')));
      final lastWire = tester.getRect(find.text('q4').first);
      expect(lastWire.bottom, lessThanOrEqualTo(canvas.bottom),
          reason: 'q4 is not cut off by the inspector');
      expect(tester.takeException(), isNull);
    });

    test('the web theme gives transient messages a dark treatment', () {
      final theme = QubitQuestTheme.web().snackBarTheme;
      expect(theme.backgroundColor, QubitQuestColors.surfaceRaised);
      expect(theme.contentTextStyle?.color, QubitQuestColors.textBody);
      expect(theme.behavior, SnackBarBehavior.floating);
    });
  });

  group('Notebook experiment', () {
    testWidgets('edited experiments label the authored description',
        (tester) async {
      _size(tester, const Size(1440, 1000));
      final progress =
          CampaignProgressController(store: InMemoryCampaignProgressStore());
      await progress.load();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WebNotebookWorkspace(
            progressController: progress,
            onOpenJourney: () {},
            requestedArticleId: 'gate-hadamard',
            requestSerial: 1,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final explore =
          find.byKey(const ValueKey('notebook-explore-h_superposition'));
      await tester.ensureVisible(explore);
      await tester.pumpAndSettle();
      await tester.tap(explore);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notebook-experiment-modified')),
          findsNothing);
      final state = tester
          .state<WebNotebookWorkspaceState>(find.byType(WebNotebookWorkspace));
      state.experimentSession!.insertGate(GatePlacementRequest(
          gate: Gate.fromIdentifier(SelectedGateType.z),
          target: const CircuitLocation(qubit: 0, column: 1)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notebook-experiment-modified')),
          findsOneWidget);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('notebook-experiment-description')))
              .data,
          startsWith('Original example:'));
      state.experimentSession!.clear();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notebook-experiment-modified')),
          findsNothing,
          reason: 'Reset example restores the authored circuit');
    });
  });

  group('Bloch Explorer', () {
    Future<WebBlochWorkspaceState> pump(WidgetTester tester, Size size) async {
      _size(tester, size);
      final lab = BlochLabSession.standalone();
      addTearDown(lab.dispose);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: WebBlochWorkspace(standalone: lab))));
      await tester.pump();
      return tester.state(find.byType(WebBlochWorkspace));
    }

    testWidgets('gate tiles are disabled while inspecting history',
        (tester) async {
      final lab = await pump(tester, const Size(1440, 1000));
      lab.session
        ..commit(SelectedGateType.hadamard)
        ..inspect(0);
      await tester.pump();
      final tile = tester.widget<QubitQuestGateTile>(
          find.byKey(const ValueKey('bloch-gate-x')));
      expect(tile.onPressed, isNull);
      lab.session.returnToCurrent();
      await tester.pump();
      expect(
          tester
              .widget<QubitQuestGateTile>(
                  find.byKey(const ValueKey('bloch-gate-x')))
              .onPressed,
          isNotNull);
    });

    testWidgets('narrow layout keeps gates and preview under the sphere',
        (tester) async {
      final lab = await pump(tester, const Size(390, 844));
      expect(
          find.byKey(const ValueKey('web-bloch-narrow-gates')), findsOneWidget);
      final sphere =
          tester.getRect(find.byKey(const ValueKey('web-bloch-sphere')));
      final gates =
          tester.getRect(find.byKey(const ValueKey('web-bloch-narrow-gates')));
      expect(gates.top, greaterThan(sphere.bottom));
      expect(gates.top - sphere.bottom, lessThan(120),
          reason: 'gates follow the sphere directly');
      await tester.tap(find.byKey(const ValueKey('bloch-gate-hadamard')));
      await tester.pump();
      expect(find.byKey(const ValueKey('bloch-preview-card')), findsOneWidget);
      expect(lab.session.appliedCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('global phase is described as a notation convention',
        (tester) async {
      await pump(tester, const Size(1440, 1000));
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('bloch-global-phase')))
              .data,
          contains('not an observable'));
    });
  });

  group('scientific wording', () {
    test('Bell and GHZ correlation statements name the Z basis', () {
      final texts = [
        for (final l in allQQLevels)
          '${l.taskDescription} ${l.conceptIntro}',
      ].join(' ');
      expect(
          texts, isNot(contains('Entangled qubits are perfectly correlated')));
      expect(texts, isNot(contains('affects all terms of the superposition')));
      expect(texts, contains('In this Bell state, measured in the Z basis'));
      expect(texts,
          contains('Measured in the Z basis, the three qubits always agree'));
    });
  });
}
