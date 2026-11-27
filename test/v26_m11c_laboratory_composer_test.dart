import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/sandbox_workspace_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_bloch_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_analysis_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_session_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/desktop_composer_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/laboratory_composer_workspace.dart';
import 'package:quantumquiz/widgets/probability_distribution_chart.dart';

/// v2.6 M11C: the laboratory Composer (Sandbox). Layout, modes, the
/// contextual inspector and the central analysis, all presenting the one
/// shared ComposerSession.

const _k = ValueKey<String>.new;

Future<void> _openComposer(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
  AppStorage? storage,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      QubitQuestWebApp(storage: storage ?? InMemoryAppStorage()));
  await tester.pumpAndSettle();
  final menu = find.byKey(_k('web-navigation-menu'));
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(_k('web-nav-composer')));
  await tester.pumpAndSettle();
}

Future<void> _chooseQubits(WidgetTester tester, int n) async {
  final button = find.byKey(ValueKey('web-composer-qubits-$n'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

ComposerSession _session(WidgetTester tester) => tester
    .widget<ComposerSessionWorkspace>(
        find.byType(ComposerSessionWorkspace, skipOffstage: false))
    .slot
    .session;

Gate _g(SelectedGateType t, {double? angle}) =>
    Gate.fromIdentifier(t, angle: angle);

CircuitEditOutcome _place(WidgetTester tester, SelectedGateType type, int qubit,
        int column,
        {List<int> controls = const [], double? angle}) =>
    _session(tester).insertGate(GatePlacementRequest(
      gate: _g(type, angle: angle),
      target: CircuitLocation(qubit: qubit, column: column),
      controls: controls,
    ));

final _inspector = find.byKey(_k('composer-gate-inspector'));

void main() {
  group('entry and structure', () {
    testWidgets('the Composer opens straight into a laboratory Sandbox',
        (tester) async {
      await _openComposer(tester);
      expect(find.text('Choose Number of Qubits'), findsNothing);
      expect(find.byType(LaboratoryComposerWorkspace), findsOneWidget);
      expect(find.byType(DesktopComposerWorkspace), findsNothing);
      expect(_session(tester).circuit.currentLevel.numQubits, 1);
      // Header, horizontal palette, circuit well, analysis; no inspector.
      expect(find.byKey(_k('web-composer-qubit-selector')), findsOneWidget);
      expect(find.byKey(_k('composer-gate-palette-strip')), findsOneWidget);
      for (final group in ['basic', 'phase', 'rotations', 'multiQubit']) {
        expect(find.byKey(ValueKey('composer-palette-group-$group')),
            findsOneWidget);
      }
      expect(find.byKey(_k('composer-palette-group-measurement')),
          findsOneWidget);
      expect(find.byKey(_k('composer-region-canvas')), findsOneWidget);
      expect(find.byKey(_k('composer-analysis-workspace')), findsOneWidget);
      expect(_inspector, findsNothing,
          reason: 'the inspector exists only for a selection');
      // The palette sits above the circuit, the analysis below it.
      final palette =
          tester.getRect(find.byKey(_k('composer-gate-palette-strip')));
      final canvas = tester.getRect(find.byKey(_k('composer-region-canvas')));
      final analysis =
          tester.getRect(find.byKey(_k('composer-analysis-workspace')));
      expect(palette.bottom, lessThanOrEqualTo(canvas.top));
      expect(canvas.bottom, lessThanOrEqualTo(analysis.top));
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide shell carries the brand in the navigation, no top bar',
        (tester) async {
      await _openComposer(tester);
      expect(find.byType(AppBar), findsNothing);
      final brand = find.byKey(_k('web-qubit-quest-wordmark'));
      expect(brand, findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(_k('web-navigation-sidebar')), matching: brand),
          findsOneWidget);
    });

    testWidgets('a one-qubit circuit is a short well, not most of the screen',
        (tester) async {
      await _openComposer(tester, size: const Size(1920, 1080));
      final well = tester.getSize(find.byKey(_k('composer-region-canvas')));
      expect(well.height, lessThan(1080 * .3));
      expect(find.byKey(_k('composer-analysis-bloch')), findsOneWidget);
      // State, probabilities and Bloch side by side at this width.
      final state = tester.getRect(find.byKey(_k('composer-analysis-state')));
      final probs =
          tester.getRect(find.byKey(_k('composer-analysis-probabilities')));
      final bloch = tester.getRect(find.byKey(_k('composer-analysis-bloch')));
      expect(state.top, probs.top);
      expect(probs.top, bloch.top);
      expect(state.right, lessThan(probs.left));
      expect(probs.right, lessThan(bloch.left));
    });

    testWidgets('qubit selector opens each register size in place',
        (tester) async {
      await _openComposer(tester);
      for (final n in [3, 5, 2]) {
        await _chooseQubits(tester, n);
        expect(_session(tester).circuit.currentLevel.numQubits, n);
        expect(find.byType(LaboratoryComposerWorkspace), findsOneWidget);
      }
    });
  });

  group('analysis workspace', () {
    testWidgets('multi-qubit circuits get joint state and probabilities only',
        (tester) async {
      await _openComposer(tester);
      await _chooseQubits(tester, 2);
      _place(tester, SelectedGateType.hadamard, 0, 0);
      _place(tester, SelectedGateType.cnot, 1, 1, controls: [0]);
      await tester.pumpAndSettle();
      expect(find.byKey(_k('composer-analysis-bloch')), findsNothing);
      expect(find.byKey(_k('composer-analysis-bloch-note')), findsOneWidget);
      // Exact probabilities of the Bell state, basis order |q1 q0⟩.
      final chart = tester.widget<ProbabilityDistributionChart>(
          find.byType(ProbabilityDistributionChart));
      final p = [
        for (final a in chart.stateVector)
          ProbabilityDistributionChart.probabilityOf(a)
      ];
      expect(p[0], closeTo(.5, 1e-12));
      expect(p[1], closeTo(0, 1e-12));
      expect(p[2], closeTo(0, 1e-12));
      expect(p[3], closeTo(.5, 1e-12));
      expect(find.textContaining('basis order |q1 q0⟩'), findsOneWidget);
    });

    testWidgets('arbitrary complex amplitudes keep their phase in the data',
        (tester) async {
      await _openComposer(tester);
      await _chooseQubits(tester, 3);
      // A circuit that is not in the M11B prototypes.
      _place(tester, SelectedGateType.hadamard, 0, 0);
      _place(tester, SelectedGateType.rx, 1, 0, angle: math.pi / 3);
      _place(tester, SelectedGateType.t, 0, 1);
      _place(tester, SelectedGateType.ry, 1, 1, angle: 2 * math.pi / 3);
      _place(tester, SelectedGateType.hadamard, 2, 0);
      _place(tester, SelectedGateType.s, 2, 1);
      await tester.pumpAndSettle();
      final simulated = _session(tester).circuit.currentState.stateVector;
      final chart = tester.widget<ProbabilityDistributionChart>(
          find.byType(ProbabilityDistributionChart));
      // The chart is fed the simulator's own vector (no copy, no rounding).
      expect(chart.stateVector.length, 8);
      for (var i = 0; i < 8; i++) {
        expect(chart.stateVector[i].real, simulated[i].real);
        expect(chart.stateVector[i].imaginary, simulated[i].imaginary);
      }
      expect(
          simulated.any((a) => a.imaginary.toDouble().abs() > 1e-6), isTrue,
          reason: 'the state has non-real amplitudes');
      final total = chart.stateVector.fold<double>(
          0, (s, a) => s + ProbabilityDistributionChart.probabilityOf(a));
      expect(total, closeTo(1, 1e-9));
      // M11C.1: the precision explanation is kept, collapsed by default.
      expect(find.byKey(_k('composer-analysis-precision-note')), findsNothing);
      final toggle = find.byKey(_k('state-precision-toggle'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byKey(_k('composer-analysis-precision-note')),
          findsOneWidget);
    });

    testWidgets('Measure samples the circuit; exact and observed differ in kind',
        (tester) async {
      await _openComposer(tester);
      await _chooseQubits(tester, 2);
      _place(tester, SelectedGateType.hadamard, 0, 0);
      _place(tester, SelectedGateType.cnot, 1, 1, controls: [0]);
      _session(tester).insertMeasurement(
          const CircuitLocation(qubit: 0, column: 2));
      _session(tester).insertMeasurement(
          const CircuitLocation(qubit: 1, column: 2));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('composer-analysis-state')), findsOneWidget);
      expect(find.text('STATE BEFORE MEASUREMENT'), findsOneWidget);
      await tester.tap(find.byKey(_k('composer-analysis-tab-measure')));
      await tester.pumpAndSettle();
      final run = find.byKey(_k('web-sandbox-run-shots'));
      await tester.ensureVisible(run);
      await tester.tap(run);
      await tester.pumpAndSettle();
      final shots = _session(tester).shotsResult!;
      final total = shots.counts.values.fold<int>(0, (a, b) => a + b);
      expect(total, 1000);
      expect(shots.counts.keys.toSet().difference({'00', '11'}), isEmpty,
          reason: 'a Bell pair measured in Z gives only 00 and 11');
      expect(find.byKey(_k('measure-outcomes-column')), findsOneWidget);
      expect(find.textContaining('every shot prepares and runs the circuit'),
          findsOneWidget);
    });

    testWidgets('Explore in Bloch Explorer opens the one-qubit circuit',
        (tester) async {
      await _openComposer(tester, size: const Size(1920, 1080));
      _place(tester, SelectedGateType.hadamard, 0, 0);
      await tester.pumpAndSettle();
      final explore = find.byKey(_k('composer-explore-in-bloch'));
      await tester.ensureVisible(explore);
      await tester.tap(explore);
      await tester.pumpAndSettle();
      expect(find.byType(WebBlochWorkspace), findsOneWidget);
      // The Sandbox session is retained behind the exploration.
      expect(_session(tester).circuit.logicalGates, hasLength(1));
    });
  });

  group('modes', () {
    testWidgets('Analysis ↔ Focus circuit never touches the session',
        (tester) async {
      await _openComposer(tester);
      await _chooseQubits(tester, 2);
      final session = _session(tester);
      _place(tester, SelectedGateType.hadamard, 0, 0);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('composer-analysis-tab-measure')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('web-sandbox-run-shots')));
      await tester.pumpAndSettle();
      final result = session.shotsResult;
      final revision = session.revision;
      expect(result, isNotNull);

      await tester.tap(find.byKey(_k('composer-lab-mode-focus')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('composer-workspace-laboratory-focus')),
          findsOneWidget);
      expect(find.byKey(_k('composer-lab-focus-note')), findsOneWidget);
      expect(find.byKey(_k('composer-analysis-workspace')), findsNothing,
          reason: 'kept mounted offstage, not shown');

      await tester.tap(find.byKey(_k('composer-lab-mode-analysis')));
      await tester.pumpAndSettle();
      expect(identical(_session(tester), session), isTrue);
      expect(session.revision, revision);
      expect(identical(session.shotsResult, result), isTrue);
      expect(session.canUndo, isTrue);
      // The Measure tab is still the one chosen before the switch.
      expect(find.byKey(_k('measure-outcomes-column')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('contextual inspector', () {
    testWidgets('opens on selection, closes without editing the circuit',
        (tester) async {
      await _openComposer(tester);
      _place(tester, SelectedGateType.hadamard, 0, 0);
      await tester.pumpAndSettle();
      final session = _session(tester);
      final revision = session.revision;
      // Placing a gate selects it (existing session behaviour), so the
      // inspector opens for the new gate; deselect to start from nothing.
      expect(_inspector, findsOneWidget);
      session.select(null);
      await tester.pumpAndSettle();
      expect(_inspector, findsNothing);

      session.select(session.circuit.logicalGates.single.id);
      await tester.pumpAndSettle();
      expect(_inspector, findsOneWidget);
      expect(find.byKey(_k('composer-inspector-close')), findsOneWidget);
      expect(find.byKey(_k('composer-inspector-expand-mode')), findsNothing);
      expect(find.byKey(_k('composer-inspector-toggle')), findsNothing);
      expect(find.byKey(_k('composer-inspector-tabs')), findsNothing);
      expect(find.byKey(_k('composer-inspector-intuition')), findsOneWidget);
      // Mathematics is advanced: closed until asked for.
      expect(find.byKey(_k('composer-math-matrix')), findsNothing);
      final toggle =
          find.byKey(_k('composer-inspector-section-mathematics-toggle'));
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byKey(_k('composer-math-matrix')), findsOneWidget);

      await tester.tap(find.byKey(_k('composer-inspector-close')));
      await tester.pumpAndSettle();
      expect(_inspector, findsNothing);
      expect(session.selectedId, isNull);
      expect(session.revision, revision);
      expect(session.circuit.logicalGates, hasLength(1));

      // The learner's open disclosure is remembered for the next selection.
      session.select(session.circuit.logicalGates.single.id);
      await tester.pumpAndSettle();
      expect(find.byKey(_k('composer-math-matrix')), findsOneWidget);
    });

    testWidgets('Escape closes it; a palette preview opens it',
        (tester) async {
      await _openComposer(tester);
      await tester.tap(find.byKey(_k('composer-palette-gate-x')));
      await tester.pumpAndSettle();
      expect(_inspector, findsOneWidget);
      expect(find.byKey(_k('composer-inspector-preview')), findsOneWidget);
      expect(_session(tester).circuit.isCircuitEmpty(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_inspector, findsNothing);
    });

    testWidgets('MCX shows every control and the target', (tester) async {
      await _openComposer(tester);
      await _chooseQubits(tester, 5);
      _place(tester, SelectedGateType.mcx, 2, 0, controls: [0, 1, 3, 4]);
      await tester.pumpAndSettle();
      final session = _session(tester);
      session.select(session.circuit.logicalGates.single.id);
      await tester.pumpAndSettle();
      expect(find.text('Controls q0, q1, q3, q4 → target q2'), findsOneWidget);
      // M11C.1: stated once; the classic panel's repeated line is omitted.
      expect(find.byKey(_k('composer-inspector-topology')), findsNothing);
      expect(find.byKey(_k('web-composer-delete-selected-gate')),
          findsOneWidget);
    });

    for (final (size, placement) in [
      (const Size(1440, 900), LaboratoryInspectorPlacement.docked),
      (const Size(1024, 768), LaboratoryInspectorPlacement.overlay),
      (const Size(500, 900), LaboratoryInspectorPlacement.sheet),
    ]) {
      testWidgets('placement at ${size.width.toInt()} px is ${placement.name}',
          (tester) async {
        await _openComposer(tester, size: size);
        _place(tester, SelectedGateType.hadamard, 0, 0);
        await tester.pumpAndSettle();
        final session = _session(tester);
        final canvasBefore =
            tester.getRect(find.byKey(_k('composer-region-canvas')));
        session.select(session.circuit.logicalGates.single.id);
        await tester.pumpAndSettle();
        final inspector =
            tester.getRect(find.byKey(_k('composer-region-inspector')));
        final host = tester.getRect(find.byType(LaboratoryComposerWorkspace));
        switch (placement) {
          case LaboratoryInspectorPlacement.docked:
            final canvas =
                tester.getRect(find.byKey(_k('composer-region-canvas')));
            expect(canvas.right, lessThanOrEqualTo(inspector.left),
                reason: 'docked: nothing is covered');
          case LaboratoryInspectorPlacement.overlay:
            expect(inspector.right, lessThanOrEqualTo(host.right));
            expect(tester.getRect(find.byKey(_k('composer-region-canvas'))),
                canvasBefore,
                reason: 'an overlay never moves the circuit');
          case LaboratoryInspectorPlacement.sheet:
            expect(inspector.bottom, closeTo(host.bottom, 1));
            expect(inspector.width, closeTo(host.width, 1));
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('responsive', () {
    for (final size in const [
      Size(1920, 1080),
      Size(1650, 900),
      Size(1440, 900),
      Size(1280, 800),
      Size(1024, 768),
      Size(800, 700),
      Size(500, 900),
      Size(390, 844),
    ]) {
      testWidgets('${size.width.toInt()}×${size.height.toInt()} lays out '
          'without overflow, with and without an inspector', (tester) async {
        await _openComposer(tester, size: size);
        await _chooseQubits(tester, 3);
        _place(tester, SelectedGateType.hadamard, 0, 0);
        _place(tester, SelectedGateType.ccnot, 2, 1, controls: [0, 1]);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final session = _session(tester);
        session.select(session.circuit.logicalGates.last.id);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_inspector, findsOneWidget);
        // Every gate stays reachable from the palette at every width.
        final palette = size.width < 600 + 1
            ? find.byKey(_k('web-composer-qubit-selector'))
            : find.byKey(_k('composer-gate-palette-strip'));
        expect(palette, findsOneWidget);
        await tester.tap(find.byKey(_k('composer-lab-mode-focus')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    test('one tier resolver for the application', () {
      expect(QubitQuestTier.of(390), QubitQuestTier.phone);
      expect(QubitQuestTier.of(800), QubitQuestTier.small);
      expect(QubitQuestTier.of(1000), QubitQuestTier.tablet);
      expect(QubitQuestTier.of(1024), QubitQuestTier.compact);
      expect(QubitQuestTier.of(1280), QubitQuestTier.standard);
      expect(QubitQuestTier.of(1650), QubitQuestTier.wide);
      expect(QubitQuestTier.of(2560), QubitQuestTier.ultrawide);
      expect(LaboratoryInspectorPlacement.forWidth(1100),
          LaboratoryInspectorPlacement.docked);
      expect(LaboratoryInspectorPlacement.forWidth(1099),
          LaboratoryInspectorPlacement.overlay);
      expect(LaboratoryInspectorPlacement.forWidth(599),
          LaboratoryInspectorPlacement.sheet);
    });
  });

  group('persistence and isolation', () {
    testWidgets('edits save as before and restore in the laboratory',
        (tester) async {
      final storage = InMemoryAppStorage();
      await _openComposer(tester, storage: storage);
      await _chooseQubits(tester, 2);
      _place(tester, SelectedGateType.hadamard, 0, 0);
      _place(tester, SelectedGateType.cnot, 1, 1, controls: [0]);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      await tester.pumpWidget(const SizedBox());
      await _openComposer(tester, storage: storage);
      await _chooseQubits(tester, 2);
      final restored = _session(tester).circuit;
      expect(restored.logicalGates.map((g) => g.type), [
        SelectedGateType.hadamard,
        SelectedGateType.cnot,
      ]);
      final saved = await SandboxWorkspacePersistence(storage).load(2);
      expect(saved?.program.operations, hasLength(2));
    });

    testWidgets('lessons keep the classic layout (redesigned in M11D)',
        (tester) async {
      await _openComposer(tester);
      // Only the Sandbox host opts into the laboratory.
      final workspaces = tester.widgetList<ComposerSessionWorkspace>(
          find.byType(ComposerSessionWorkspace, skipOffstage: false));
      expect(workspaces.where((w) => w.laboratory), hasLength(1));
      expect(
          workspaces
              .where((w) => w.laboratory)
              .single
              .contextLabel,
          'Sandbox');
    });
  });

  group('probability chart', () {
    testWidgets('bars are |amplitude|² and labels use the shared policy',
        (tester) async {
      final vector = [
        Complex(.5, .5),
        Complex(0, 0),
        Complex(-.5, 0),
        Complex(0, .5),
      ];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: ProbabilityDistributionChart(
                stateVector: vector, numQubits: 2),
          ),
        ),
      ));
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('25%'), findsNWidgets(2));
      expect(find.bySemanticsLabel('|01⟩ probability 0%'), findsOneWidget);
      expect(find.byType(ComposerAnalysisWorkspace), findsNothing);
    });
  });
}
