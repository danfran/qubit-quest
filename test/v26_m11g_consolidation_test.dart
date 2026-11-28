// v2.6 M11G: experience consolidation.
//
// * Notebook experiments run in the laboratory Composer, keep their own
//   isolated session, and return to the article with its reading context.
// * Shared scientific presentation: rounded expressions use ≈, a recognised
//   state is "=" only when exact, zero probabilities draw nothing.
// * Authored Notebook claims agree with the simulator (kets and relative
//   phases parsed from the authored notation and TeX).
// * Bloch Explorer: measurement before the detailed mathematics, the shared
//   expression in gate previews (global phase kept), explicit replay notes,
//   compact phone and landscape layouts.
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_lab.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/canonical_qubit_state.dart';
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/gate_reference_examples.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/notebook_article_view.dart';
import 'package:quantumquiz/screens/web_bloch_workspace.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/utils/named_state_recognition.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/composer_workspace/laboratory_composer_workspace.dart';
import 'package:quantumquiz/widgets/state_amplitude_panel.dart';

ValueKey<String> _k(String v) => ValueKey(v);

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

// ───────────────────────────────────────────── authored content vs simulator

typedef _Op = CanonicalCircuitStep;
_Op _h(int q) => _Op.single(SelectedGateType.hadamard, targetQubit: q);
_Op _x(int q) => _Op.single(SelectedGateType.x, targetQubit: q);
_Op _z(int q) => _Op.single(SelectedGateType.z, targetQubit: q);
_Op _cx(int c, int t) =>
    _Op(gateType: SelectedGateType.cnot, targetQubit: t, controlQubit: c);

List<Complex> _simulate(int n, String initial, List<_Op> ops) =>
    ExecutableNotebookExample(
      id: 'audit',
      title: 'audit',
      description: 'audit',
      qubitCount: n,
      initialBinaryState: initial,
      operations: ops,
    ).execute().state;

/// Kets and their relative phase factor (+1, −1, +i, −i) in the final
/// expression of an authored line: the part after the last →, -> or =.
Map<String, Complex> _authoredTerms(String notation) {
  var tail = notation;
  for (final sep in ['→', '->', '=']) {
    final i = tail.lastIndexOf(sep);
    if (i >= 0) tail = tail.substring(i + sep.length);
  }
  final terms = <String, Complex>{};
  final term = RegExp(r'([+−-])?\s*(i)?\s*\|([01]+)⟩');
  for (final m in term.allMatches(tail)) {
    final negative = m.group(1) == '−' || m.group(1) == '-';
    final imaginary = m.group(2) != null;
    final s = negative ? -1.0 : 1.0;
    terms[m.group(3)!] = imaginary ? Complex(0, s) : Complex(s, 0);
  }
  return terms;
}

/// The simulated support and relative phases, normalised to the first
/// non-zero amplitude (the authored common factor such as 1/√2 is dropped).
Map<String, Complex> _simulatedTerms(List<Complex> v, int n) {
  final out = <String, Complex>{};
  Complex? ref;
  for (var i = 0; i < v.length; i++) {
    if (v[i].magnitude < 1e-9) continue;
    ref ??= v[i];
    final r = v[i] / ref;
    out[i.toRadixString(2).padLeft(n, '0')] = r;
  }
  return out;
}

Iterable<NotebookExample> _examples(NotebookEntry e) => [
      e.intuition,
      e.whatChanged,
      e.quantumView,
      e.advancedNotes,
    ].expand((s) => s?.examples ?? const <NotebookExample>[]);

NotebookExample _example(String entryId, String label) =>
    _examples(notebookEntries.singleWhere((e) => e.id == entryId))
        .singleWhere((x) => x.label == label);

/// Each authored claim with the circuit it describes (the lesson's own
/// circuit, q0 the rightmost ket symbol).
final _claims = <(String, String, int, String, List<_Op>)>[
  ('bell_state', 'Prepare possibilities', 2, '00', [_h(0)]),
  ('bell_state', 'Connect branches', 2, '00', [_h(0), _cx(0, 1)]),
  ('bell_state', 'Bell state', 2, '00', [_h(0), _cx(0, 1)]),
  ('entanglement', 'Entangled state', 2, '00', [_h(0), _z(0), _cx(0, 1)]),
  ('entanglement', 'Bell example', 2, '00', [_h(0), _z(0), _cx(0, 1)]),
  (
    'one_quantum_system',
    'Entangled example',
    2,
    '00',
    [_h(0), _cx(0, 1), _x(0)]
  ),
  ('superposition', 'Prepare register', 2, '10', [_x(1)]),
  ('superposition', 'Two-qubit superposition', 2, '10', [_x(1), _h(1)]),
  ('correlation', 'Control off', 2, '00', [_cx(1, 0)]),
  ('correlation', 'Control on', 2, '10', [_cx(1, 0)]),
  ('control', 'Control active', 2, '01', [_cx(0, 1)]),
  ('control', 'Control inactive', 2, '00', [_cx(0, 1)]),
  ('conditional_action', 'Flip', 2, '01', [_cx(0, 1)]),
  ('conditional_action', 'No flip', 2, '00', [_cx(0, 1)]),
  ('information_transfer', 'Create', 2, '00', [_x(1)]),
  ('information_transfer', 'Propagate', 2, '10', [_cx(1, 0)]),
  ('swap', 'Example input', 2, '10', [_cx(0, 1), _cx(1, 0), _cx(0, 1)]),
  ('swap', 'Other direction', 2, '01', [_cx(0, 1), _cx(1, 0), _cx(0, 1)]),
  ('all_together', 'GHZ-like state', 3, '000', [_h(0), _cx(0, 1), _cx(1, 2)]),
  (
    'ghz_state',
    'Global branch phase',
    3,
    '000',
    [_h(0), _cx(0, 1), _cx(1, 2), _z(2)]
  ),
];

void main() {
  group('authored Notebook claims agree with the simulator', () {
    for (final (entry, label, n, initial, ops) in _claims) {
      test('$entry · $label', () {
        final example = _example(entry, label);
        final simulated = _simulatedTerms(_simulate(n, initial, ops), n);
        final authored = _authoredTerms(example.notation);
        expect(authored.keys.toSet(), simulated.keys.toSet(),
            reason: 'kets in "${example.notation}"');
        // Relative phases, against the first authored ket.
        final first = authored.keys.first;
        for (final ket in authored.keys) {
          final a = authored[ket]! / authored[first]!;
          final s = simulated[ket]! / simulated[first]!;
          expect((a - s).magnitude, lessThan(1e-9),
              reason: 'relative phase of |$ket⟩ in "${example.notation}"');
        }
        // The TeX shown on screen names the same final kets.
        final latex = example.latex;
        if (latex != null) {
          final cut = [r'\rightarrow', r'\xrightarrow', '=']
              .map((s) => latex.lastIndexOf(s))
              .reduce((a, b) => a > b ? a : b);
          var tail = cut < 0 ? latex : latex.substring(cut);
          // Skip an arrow label ({...}) so it is not read as the result.
          if (tail.startsWith(r'\xrightarrow')) {
            tail = tail.substring(tail.indexOf('}') + 1);
          }
          final kets = RegExp(r'\\lvert\s*([01]+)\\rangle')
              .allMatches(tail)
              .map((m) => m.group(1)!)
              .toSet();
          expect(kets, simulated.keys.toSet(), reason: 'TeX "$latex"');
        }
      });
    }

    test('two-qubit operations state their control (no bare CX)', () {
      for (final e in notebookEntries) {
        for (final x in _examples(e)) {
          if (RegExp(r'\|[01]{2}⟩').hasMatch(x.notation) &&
              RegExp(r'\b(CX|CNOT)\|').hasMatch(x.notation)) {
            fail('${e.id} · ${x.label}: "${x.notation}" names no control');
          }
        }
      }
    });

    test('ket positions are named by wire, never "first qubit"', () {
      for (final e in notebookEntries) {
        for (final x in _examples(e)) {
          expect(x.notation.toLowerCase(), isNot(contains('first qubit')),
              reason: '${e.id} · ${x.label}');
        }
      }
    });

    test('plain-text descriptions contain no TeX braces', () {
      for (final x in [
        ...executableNotebookExamples,
        ...gateReferenceExamples,
        ...conditionalLogicExamples
      ]) {
        expect(x.description, isNot(contains('{')), reason: x.id);
        expect(x.description, isNot(contains(r'\')), reason: x.id);
      }
    });

    test('every executable example still matches its simulated state', () {
      for (final x in [
        ...executableNotebookExamples,
        ...gateReferenceExamples,
        ...conditionalLogicExamples
      ]) {
        expect(x.resultMatchesExpected(x.execute().state), isTrue,
            reason: x.id);
      }
    });
  });

  group('exact and approximate presentation', () {
    test('a rounded coefficient makes the expression an approximation', () {
      expect(
          formatQuantumStateExpression([Complex(0.6, 0), Complex(0.8, 0)],
              numQubits: 1),
          '|ψ⟩ = (3/5)|0⟩ + (4/5)|1⟩');
      expect(
          formatQuantumStateExpression(
              [Complex(0.5403023, 0), Complex(0, -0.8414710)],
              numQubits: 1),
          startsWith('|ψ⟩ ≈ '));
      expect(quantumAmplitudeIsApproximate('1/√2'), isFalse);
      expect(quantumAmplitudeIsApproximate('0.7071'), isTrue);
    });

    test('1/√2 is written exactly only at floating-point precision', () {
      const h = 0.70710678118654752;
      expect(formatQuantumAmplitude(Complex(h, 0)), '1/√2');
      expect(formatQuantumAmplitude(Complex(h + 1e-7, 0)), contains('0.7071'));
    });

    test('a tolerance match is recognised but not called exact', () {
      const h = 0.70710678118654752;
      final exact = recogniseNamedState([Complex(h, 0), Complex(h, 0)], 1)!;
      expect(exact.symbol, '|+⟩');
      expect(exact.isExact, isTrue);
      // A normalised state 10⁻⁴ rad from |+⟩: overlap 1 − 5·10⁻⁹, inside
      // the recognition tolerance but not equal to floating-point precision.
      final near = recogniseNamedState([
        Complex(math.cos(math.pi / 4 + 1e-4), 0),
        Complex(math.sin(math.pi / 4 + 1e-4), 0),
      ], 1)!;
      expect(near.symbol, '|+⟩');
      expect(near.isExact, isFalse);
    });

    testWidgets('the state panel writes ≈ for rounded expressions',
        (tester) async {
      Future<String> relation(List<Complex> v) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: QqCurrentStatePanel(
                stateVector: v, numQubits: 1, expressionOnly: true),
          ),
        ));
        return tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .firstWhere((t) => t.startsWith('|ψ⟩'));
      }

      const h = 0.70710678118654752;
      expect(await relation([Complex(h, 0), Complex(h, 0)]), '|ψ⟩ =');
      expect(await relation([Complex(0.5403023, 0), Complex(0.8414710, 0)]),
          '|ψ⟩ ≈');
      // A recognised state keeps its global phase in the equation: i|+⟩.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QqCurrentStatePanel(
              stateVector: [Complex(0, h), Complex(0, h)],
              numQubits: 1,
              expressionOnly: true),
        ),
      ));
      expect(find.byKey(_k('state-named')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(_k('state-named-relation'))).data,
          '= ');
      expect(find.text('i'), findsWidgets);
    });
  });

  group('Notebook experiments in the laboratory Composer', () {
    Future<(WebNotebookWorkspaceState, CampaignProgressController)> pump(
        WidgetTester tester,
        {Size size = const Size(1600, 1000)}) async {
      final progress =
          CampaignProgressController(store: InMemoryCampaignProgressStore());
      await progress.load();
      for (final e in notebookEntries) {
        await progress.unlockDiscovery(e.discoveryTitle);
      }
      _size(tester, size);
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: WebNotebookWorkspace(
              progressController: progress,
              onOpenJourney: () {},
              requestedArticleId: 'bell_state',
              requestSerial: 1,
              onOpenJourneyLesson: (_) {},
              onOpenMasteryChallenge: (_) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return (
        tester.state<WebNotebookWorkspaceState>(
            find.byType(WebNotebookWorkspace)),
        progress
      );
    }

    testWidgets(
        'opens in the laboratory layout with article context, isolation '
        'and the authored circuit; Reset and Back restore', (tester) async {
      final (state, progress) = await pump(tester);
      final before = progress.state;
      // Spread, then scroll the reader: both must survive the experiment.
      await tester.tap(find.descendant(
          of: find.byKey(_k('web-notebook-mode')),
          matching: find.text('Spread')));
      await tester.pumpAndSettle();
      expect(state.readingMode, NotebookReadingMode.spread);
      final run = find.byKey(_k('notebook-explore-bell_phi_plus'));
      await tester.ensureVisible(run);
      await tester.pumpAndSettle();
      final reader = find
          .descendant(
              of: find.byKey(_k('web-notebook-reader-bell_state')),
              matching: find.byType(Scrollable))
          .first;
      final offset = tester.state<ScrollableState>(reader).position.pixels;
      expect(offset, greaterThan(0));

      await tester.tap(run);
      await tester.pumpAndSettle();
      final workspace = find.byKey(_k('notebook-experiment-workspace'));
      expect(workspace, findsOneWidget);
      expect(tester.widget(workspace), isA<LaboratoryComposerWorkspace>(),
          reason: 'the modern Composer, not the classic three columns');
      expect(find.byKey(_k('composer-lab-scroll')), findsOneWidget);
      expect(find.byKey(_k('notebook-experiment-breadcrumb')), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.byKey(_k('notebook-experiment-breadcrumb')))
              .data,
          contains('Bell State'));
      expect(find.byKey(_k('notebook-experiment-isolation')), findsOneWidget);
      expect(
          find.byKey(_k('notebook-experiment-back-article')), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.byKey(_k('notebook-experiment-description')))
              .textSpan!
              .toPlainText(),
          startsWith('Demonstrates: '));
      // No Check, hints or completion in an experiment.
      expect(find.byKey(_k('web-lesson-check')), findsNothing);

      final session = state.experimentSession!;
      final authored = [
        for (final g in session.circuit.logicalGates) g.type,
      ];
      expect(authored, [SelectedGateType.hadamard, SelectedGateType.cnot]);
      session.deleteOperation(session.circuit.logicalGates.last.id);
      await tester.pumpAndSettle();
      expect(find.byKey(_k('notebook-experiment-modified')), findsOneWidget);
      session.clear(); // Reset example
      await tester.pumpAndSettle();
      expect([for (final g in session.circuit.logicalGates) g.type], authored);
      expect(find.byKey(_k('notebook-experiment-modified')), findsNothing);
      final run2 = session.run(manyShots: true);
      await tester.pump();
      await run2;
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_k('notebook-experiment-back-article')));
      await tester.pumpAndSettle();
      expect(workspace, findsNothing);
      expect(state.selectedArticleId, 'bell_state');
      expect(state.readingMode, NotebookReadingMode.spread);
      expect(tester.state<ScrollableState>(reader).position.pixels, offset,
          reason: 'the article keeps its scroll position');
      // Progress is untouched by running, editing and resetting.
      expect(progress.state.completedLessonIds, before.completedLessonIds);
      expect(progress.state.completedMasterySemanticIds,
          before.completedMasterySemanticIds);
      expect(tester.takeException(), isNull);
    });

    for (final size in const [
      Size(1440, 900),
      Size(800, 900),
      Size(390, 844)
    ]) {
      testWidgets('experiment layout at $size', (tester) async {
        final (state, _) = await pump(tester, size: size);
        final run = find.byKey(_k('notebook-explore-bell_phi_plus'));
        await tester.ensureVisible(run);
        await tester.pumpAndSettle();
        await tester.tap(run);
        await tester.pumpAndSettle();
        expect(find.byKey(_k('notebook-experiment-workspace')), findsOneWidget);
        expect(state.experimentSession, isNotNull);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Bloch Explorer refinements', () {
    Future<WebBlochWorkspaceState> pump(WidgetTester tester,
        {Size size = const Size(1440, 900), bool reducedMotion = false}) async {
      _size(tester, size);
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, disableAnimations: reducedMotion),
          child: Scaffold(
              body:
                  WebBlochWorkspace(standalone: BlochLabSession.standalone())),
        ),
      ));
      await tester.pump();
      return tester.state(find.byType(WebBlochWorkspace));
    }

    testWidgets(
        'measurement comes before the detailed mathematics and is on screen '
        'at 1440×900', (tester) async {
      await pump(tester);
      final measure = tester.getRect(find.byKey(_k('bloch-run-once')));
      final details = tester.getRect(find.byKey(_k('bloch-state-details')));
      final expression =
          tester.getRect(find.byKey(_k('bloch-state-expression')));
      expect(expression.top, lessThan(measure.top));
      expect(measure.top, lessThan(details.top));
      expect(measure.bottom, lessThanOrEqualTo(900),
          reason: 'Measure once is visible without scrolling');
      expect(tester.getRect(find.byKey(_k('bloch-exact'))).bottom,
          lessThanOrEqualTo(900));
      // No separate Z-basis duplicate while Z is the measured basis.
      expect(find.byKey(_k('bloch-z-reference')), findsNothing);
      await tester.tap(find.byKey(_k('bloch-basis-x')));
      await tester.pump();
      expect(find.byKey(_k('bloch-z-reference')), findsOneWidget,
          reason: 'Z-basis probabilities stay available, labelled apart');
      expect(find.byKey(_k('bloch-measure-legend')), findsOneWidget);
    });

    testWidgets('deterministic and random outcomes are worded differently',
        (tester) async {
      final lab = await pump(tester);
      final once = find.byKey(_k('bloch-run-once'));
      await tester.tap(once);
      await tester.pump();
      String result() => tester
          .widget<Text>(find.descendant(
              of: find.byKey(_k('bloch-single-result')),
              matching: find.byType(Text)))
          .data!;
      expect(result(), contains('certain'));
      lab.session.prepare(CanonicalQubitState.plus.blochState, '|+⟩');
      await tester.pump();
      await tester.tap(once);
      await tester.pump();
      expect(result(), contains('random'));
      expect(result(), contains('probability 50%'));
    });

    testWidgets(
        'gate preview uses the shared expression: named states, exact '
        'coefficients and global phase', (tester) async {
      final lab = await pump(tester);
      lab.selectGate(SelectedGateType.hadamard);
      await tester.pump();
      final result = find.byKey(_k('bloch-preview-result'));
      expect(
          find.descendant(
              of: result, matching: find.byType(QqCurrentStatePanel)),
          findsOneWidget);
      expect(
          find.descendant(of: result, matching: find.byKey(_k('state-named'))),
          findsOneWidget,
          reason: 'H|0⟩ = |+⟩');
      expect(
          find.descendant(of: result, matching: find.text('√2')), findsWidgets,
          reason: 'exact 1/√2, not 0.7071');
      expect(find.descendant(of: result, matching: find.text('0.7071')),
          findsNothing);
      // Y|0⟩ = i|1⟩: the global phase i is kept.
      lab.selectGate(SelectedGateType.y);
      await tester.pump();
      final panel = tester.widget<QqCurrentStatePanel>(find.descendant(
          of: find.byKey(_k('bloch-preview-result')),
          matching: find.byType(QqCurrentStatePanel)));
      expect(panel.stateVector[0].magnitude, lessThan(1e-12));
      expect(panel.stateVector[1].imaginary, closeTo(1, 1e-12));
      expect(
          find.descendant(
              of: find.byKey(_k('bloch-preview-result')),
              matching: find.text('i')),
          findsOneWidget);
      // Apply stays above the longer explanation.
      lab.selectGate(SelectedGateType.z);
      await tester.pump();
      lab.session.prepare(CanonicalQubitState.one.blochState, '|1⟩');
      lab.selectGate(SelectedGateType.z);
      await tester.pump();
      if (find.byKey(_k('bloch-preview-on-axis')).evaluate().isNotEmpty) {
        expect(
            tester.getRect(find.byKey(_k('bloch-apply'))).top,
            lessThan(
                tester.getRect(find.byKey(_k('bloch-preview-on-axis'))).top));
      }
      expect(lab.session.appliedCount, 0, reason: 'previews never record');
    });

    testWidgets('replay, pause, history and return state their relationship',
        (tester) async {
      final lab = await pump(tester);
      lab.session
        ..commit(SelectedGateType.hadamard)
        ..commit(SelectedGateType.s);
      await tester.pump();
      expect(find.byKey(_k('bloch-presentation-note')), findsNothing,
          reason: 'the current state needs no note');
      lab.playSteps();
      await tester.pump(const Duration(milliseconds: 200));
      String note() =>
          tester.widget<Text>(find.byKey(_k('bloch-presentation-note'))).data!;
      expect(note(), contains('Replaying step 1 of 2'));
      lab.pausePlayback();
      await tester.pump();
      expect(note(), contains('Paused part-way along step 1'));
      lab.toCurrent();
      await tester.pump();
      expect(find.byKey(_k('bloch-presentation-note')), findsNothing);
      lab.toStart();
      await tester.pump();
      expect(note(), contains('History'));
      lab.toCurrent();
      await tester.pump();
      lab.selectGate(SelectedGateType.x);
      await tester.pump();
      lab.applySelected();
      await tester.pump(const Duration(milliseconds: 100));
      expect(note(), contains('the numbers already show the completed step'));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('bloch-presentation-note')), findsNothing);
      expect(lab.session.appliedCount, 3);
    });

    testWidgets(
        'phone portrait: gates right under the sphere, compact playback '
        'before any step, custom state from Prepare', (tester) async {
      final lab = await pump(tester, size: const Size(390, 844));
      final sphere = tester.getRect(find.byKey(_k('web-bloch-sphere')));
      final gates = tester.getRect(find.byKey(_k('web-bloch-narrow-gates')));
      expect(gates.top - sphere.bottom, lessThan(60));
      expect(find.byKey(_k('bloch-play')), findsNothing,
          reason: 'nothing to replay yet');
      expect(find.byKey(_k('bloch-animate-toggle')), findsOneWidget);
      expect(find.byKey(_k('bloch-speed')), findsOneWidget);
      await tester.tap(find.byKey(_k('bloch-custom-chip')));
      await tester.pump();
      expect(find.byKey(_k('bloch-custom-card')), findsOneWidget);
      await tester.tap(find.byKey(_k('bloch-custom-close')));
      await tester.pump();
      lab.session.commit(SelectedGateType.hadamard);
      await tester.pump();
      expect(find.byKey(_k('bloch-play')), findsOneWidget);
      expect(tester.getRect(find.byKey(_k('web-bloch-narrow-gates'))).top,
          gates.top,
          reason: 'the first step does not move the gates');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'phone landscape 844×390: the whole sphere beside Prepare, playback '
        'and gates', (tester) async {
      await pump(tester, size: const Size(844, 390));
      final stage = tester.getRect(find.byKey(_k('web-bloch-stage')));
      expect(stage.bottom, lessThanOrEqualTo(390));
      final controls =
          tester.getRect(find.byKey(_k('web-bloch-landscape-controls')));
      expect(controls.left, greaterThan(stage.right));
      for (final key in ['bloch-prep-zero', 'bloch-gate-hadamard']) {
        final r = tester.getRect(find.byKey(_k(key)));
        expect(r.bottom, lessThanOrEqualTo(390), reason: '$key visible');
      }
      expect(tester.takeException(), isNull);
    });

    for (final size in const [
      Size(2560, 1080),
      Size(1920, 1080),
      Size(1650, 900),
      Size(1440, 900),
      Size(1280, 800),
      Size(1024, 768),
      Size(800, 900),
      Size(500, 900),
      Size(390, 844),
      Size(844, 390),
    ]) {
      testWidgets('no overflow with measurement and preview at $size',
          (tester) async {
        final lab = await pump(tester, size: size);
        lab.session.prepare(CanonicalQubitState.plusI.blochState, '|+i⟩');
        lab.selectGate(SelectedGateType.rx);
        await tester.pump();
        // Medium layouts show one side panel: switch to State & measure.
        final read = find.byKey(_k('web-bloch-tab-read'));
        if (read.evaluate().isNotEmpty) {
          await tester.tap(read);
          await tester.pump();
        }
        final x = find.byKey(_k('bloch-basis-x'));
        await tester.ensureVisible(x);
        await tester.tap(x);
        await tester.pump();
        final shots = find.byKey(_k('bloch-run-shots'));
        await tester.ensureVisible(shots);
        await tester.tap(shots);
        await tester.pump();
        expect(find.byKey(_k('bloch-shots-result')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
