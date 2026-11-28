// v2.6 M6b: the Notebook as an interactive quantum knowledge base.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_knowledge_base.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_workspace/gate_inspector_panel.dart';

import 'support/mastery_math_test_platform.dart';

ValueKey<String> _k(String k) => ValueKey(k);
final _kb = NotebookKnowledgeBase.instance;

Future<CampaignProgressController> _progress(
    [Iterable<String> discoveries = const []]) async {
  final c = CampaignProgressController(store: InMemoryCampaignProgressStore());
  await c.load();
  for (final d in discoveries) {
    await c.unlockDiscovery(d);
  }
  return c;
}

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

ComposerSession _experiment(String id) {
  final level = executableNotebookExamplesById[id]!.createExperimentLevel();
  final circuit = QuantumCircuit(currentLevel: level)..runSimulation();
  return ComposerSession(
    circuit: circuit,
    policy: ComposerPolicy.forMode(ComposerMode.notebookExample, level),
  );
}

void main() {
  useMasteryMathTestPlatform();

  group('knowledge base derived from existing content', () {
    test('every entry and production gate is one article in one category', () {
      final ids = [
        for (final c in _kb.categories) ...c.articles.map((a) => a.id)
      ];
      expect(ids.toSet(), hasLength(ids.length), reason: 'no duplicates');
      expect(_kb.categories.every((c) => c.articles.isNotEmpty), isTrue,
          reason: 'no empty categories');
      expect(ids, containsAll(notebookEntries.map((e) => e.id)));
      for (final type in GateEducationalCatalog.productionGateTypes) {
        expect(ids, contains(NotebookArticle.gateId(type)));
      }
      expect(
          ids,
          hasLength(notebookEntries.length +
              GateEducationalCatalog.productionGateTypes.length));
    });

    test('each discovery entry links to exactly its Journey lesson', () {
      for (final a in _kb.articles
          .where((a) => a.kind == NotebookArticleKind.discovery)) {
        final link = _kb.lessonFor(a);
        expect(link, isNotNull, reason: a.id);
        expect(link!.level.discoveryTitle, a.entry!.discoveryTitle);
        expect(journeyLessons[link.lessonId - 1], same(link.level));
      }
    });

    test('gate experiments exist and actually use that gate', () {
      for (final MapEntry(key: type, value: ids)
          in notebookGateExampleIds.entries) {
        for (final id in ids) {
          final example = notebookExampleById(id);
          expect(example, isNotNull, reason: id);
          expect(example!.operations.any((op) => op.gateType == type), isTrue,
              reason: '$id uses ${type.name}');
        }
      }
    });

    test('video references are architecture only (none in v2.6)', () {
      expect(notebookVideoReferences, isEmpty);
    });

    test('availability: reference and gates always; discoveries when earned',
        () {
      final fresh = <String>{};
      for (final a in _kb.articles) {
        expect(
            _kb.isAvailable(a, fresh), a.kind != NotebookArticleKind.discovery,
            reason: a.id);
      }
      final first = _kb.byId(notebookEntries.first.id)!;
      expect(_kb.isAvailable(first, {notebookEntries.first.discoveryTitle}),
          isTrue);
    });

    test('search covers gates and only discovered entries', () {
      expect(_kb.search('Hadamard', {}).first.article.id, 'gate-hadamard');
      expect(
          _kb.search('CX', {}).map((h) => h.article.id), contains('gate-cnot'));
      final title = notebookEntries.first.title;
      expect(_kb.search(title, {}).map((h) => h.article.id),
          isNot(contains(notebookEntries.first.id)));
      expect(
          _kb.search(title, {notebookEntries.first.discoveryTitle}).map(
              (h) => h.article.id),
          contains(notebookEntries.first.id));
      expect(_kb.search('qwertyzx', {}), isEmpty);
    });

    test('relationships use stable identifiers, never the article itself', () {
      for (final a in _kb.articles) {
        expect(_kb.relatedArticles(a).map((r) => r.id), isNot(contains(a.id)));
      }
      for (final c in _kb.masteryChallengesUsing(SelectedGateType.cnot)) {
        final level = c.levelDefinition as ComposerLevel;
        expect(level.availableGates.map((g) => g.type),
            contains(SelectedGateType.cnot));
      }
    });
  });

  group('executable experiments on the real simulator', () {
    test('every example loads its authored state and operations', () {
      for (final example in executableNotebookExamples) {
        final session = _experiment(example.id);
        final circuit = session.circuit;
        expect(circuit.currentLevel.initialQubitsStateStr,
            example.initialBinaryState);
        expect(circuit.logicalGates, hasLength(example.operations.length),
            reason: example.id);
        expect(example.resultMatchesExpected(circuit.currentState.stateVector),
            isTrue,
            reason: example.id);
        // The full Sandbox palette, for experimenting further.
        expect(session.policy.availableGates.map((g) => g.type).toSet(),
            sandboxGatePaletteTypes);
        session.dispose();
      }
    });

    test('rotation angle is preserved and follows the simulator convention',
        () {
      final session = _experiment('rz_interference');
      final rz = session.circuit.logicalGates
          .singleWhere((g) => g.type == SelectedGateType.rz);
      expect(rz.gate.angle, closeTo(math.pi / 3, 1e-12));
      final state = session.circuit.currentState.stateVector;
      // H·Rz(θ)·H|0⟩ = cos(θ/2)|0⟩ − i·sin(θ/2)|1⟩.
      expect(state[0].real, closeTo(math.cos(math.pi / 6), 1e-9));
      expect(state[1].imaginary, closeTo(-math.sin(math.pi / 6), 1e-9));
      expect(state[0].magnitude * state[0].magnitude, closeTo(.75, 1e-9));
      // Editing θ moves the probabilities continuously.
      session.editRotationAngle(rz.id, math.pi);
      final after = session.circuit.currentState.stateVector;
      expect(after[1].magnitude * after[1].magnitude, closeTo(1, 1e-9));
      session.dispose();
    });

    test('Bell and GHZ prepare the expected coherent superpositions', () {
      final r2 = 1 / math.sqrt(2);
      final bell = _experiment('bell_phi_plus');
      final b = bell.circuit.currentState.stateVector;
      expect([
        b[0].real,
        b[1].real,
        b[2].real,
        b[3].real
      ], [
        closeTo(r2, 1e-9),
        closeTo(0, 1e-9),
        closeTo(0, 1e-9),
        closeTo(r2, 1e-9)
      ]);
      bell.dispose();
      final ghz = _experiment('ghz_three');
      final g = ghz.circuit.currentState.stateVector;
      for (var i = 0; i < 8; i++) {
        expect(g[i].real, closeTo(i == 0 || i == 7 ? r2 : 0, 1e-9),
            reason: 'amplitude $i');
      }
      ghz.dispose();
    });

    test('measurement and shots run; Reset restores the authored example',
        () async {
      final session = _experiment('h_superposition');
      expect(session.policy.allowsMeasurement, isTrue);
      expect(session.policy.offersCheck, isFalse);
      expect(session.saveQueue, isNull, reason: 'experiments never persist');
      session.insertGate(GatePlacementRequest(
          gate: Gate.fromIdentifier(SelectedGateType.z),
          target: const CircuitLocation(qubit: 0, column: 1)));
      session.insertMeasurement(const CircuitLocation(qubit: 0, column: 2));
      await session.run(manyShots: true);
      expect(session.shotsResult, isNotNull);
      expect(session.shotsResult!.counts.values.fold<int>(0, (a, b) => a + b),
          session.shots);
      session.clear();
      expect(session.shotsResult, isNull, reason: 'M4 invalidation');
      expect(session.circuit.logicalGates.map((g) => g.type),
          [SelectedGateType.hadamard]);
      expect(session.circuit.measurements, isEmpty);
      session.dispose();
    });
  });

  group('Notebook workspace', () {
    Future<WebNotebookWorkspaceState> pump(
      WidgetTester tester,
      CampaignProgressController progress, {
      Size size = const Size(1440, 1000),
      String? articleId,
      ValueChanged<int>? onOpenLesson,
      ValueChanged<String>? onOpenChallenge,
    }) async {
      _size(tester, size);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WebNotebookWorkspace(
            progressController: progress,
            onOpenJourney: () {},
            requestedArticleId: articleId,
            requestSerial: articleId == null ? 0 : 1,
            onOpenJourneyLesson: onOpenLesson,
            onOpenMasteryChallenge: onOpenChallenge,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return tester.state(find.byType(WebNotebookWorkspace));
    }

    Future<void> tapVisible(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    testWidgets('gate article: shared math and visual, experiments, Mastery',
        (tester) async {
      final opened = <String>[];
      await pump(tester, await _progress(),
          articleId: 'gate-cnot', onOpenChallenge: opened.add);
      expect(find.byKey(_k('web-notebook-reader-gate-cnot')), findsOneWidget);
      expect(find.byKey(_k('web-notebook-gate-matrix')), findsOneWidget);
      expect(find.byKey(_k('web-notebook-gate-visual')), findsOneWidget);
      expect(
          find.byKey(_k('executable-example-bell_phi_plus')), findsOneWidget);
      expect(find.byKey(_k('executable-example-ghz_three')), findsOneWidget);
      final challenge = _kb.masteryChallengesUsing(SelectedGateType.cnot).first;
      await tapVisible(
          tester,
          find.descendant(
              of: find.byKey(ValueKey(
                  'web-notebook-activity-mastery-${challenge.semanticId}')),
              matching: find.byType(TextButton)));
      expect(opened, [challenge.semanticId]);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'experiment: authored circuit, shared inspector, isolated, '
        'returns to the article with its scroll', (tester) async {
      final progress = await _progress();
      final before = progress.state;
      final state = await pump(tester, progress, articleId: 'gate-hadamard');
      final reader = find.byKey(_k('web-notebook-reader-gate-hadamard'));
      final scrollable = tester.state<ScrollableState>(
          find.descendant(of: reader, matching: find.byType(Scrollable)).first);
      final explore = find.byKey(_k('notebook-explore-hh_reversibility'));
      await tester.ensureVisible(explore);
      await tester.pumpAndSettle();
      final offset = scrollable.position.pixels;
      expect(offset, greaterThan(0));
      await tester.tap(explore);
      await tester.pumpAndSettle();

      final session = state.experimentSession!;
      expect(session.circuit.logicalGates.map((g) => g.type),
          [SelectedGateType.hadamard, SelectedGateType.hadamard]);
      expect(find.byKey(_k('notebook-experiment-workspace')), findsOneWidget);
      // M11G: the laboratory inspector is contextual: it opens on selection.
      expect(find.byType(GateInspectorPanel), findsNothing);
      session.select(session.circuit.logicalGates.first.id);
      await tester.pumpAndSettle();
      expect(find.byType(GateInspectorPanel), findsOneWidget);
      session.select(null);
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-lesson-check')), findsNothing);
      expect(find.byKey(_k('web-lesson-hint')), findsNothing);

      // Edit, measure, run: progress is untouched.
      session.insertGate(GatePlacementRequest(
          gate: Gate.fromIdentifier(SelectedGateType.x),
          target: const CircuitLocation(qubit: 0, column: 2)));
      final run = session.run(manyShots: true);
      await tester.pump();
      await run;
      await tester.pumpAndSettle();
      expect(progress.state.completedLessonIds, before.completedLessonIds);
      expect(progress.state.completedMasterySemanticIds,
          before.completedMasterySemanticIds);
      expect(progress.unlockedDiscoveryTitles(), isEmpty);

      await tester.tap(find.byKey(_k('notebook-experiment-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('notebook-experiment-workspace')), findsNothing);
      expect(state.selectedArticleId, 'gate-hadamard');
      expect(
          tester
              .state<ScrollableState>(find
                  .descendant(of: reader, matching: find.byType(Scrollable))
                  .first)
              .position
              .pixels,
          offset);
      expect(session.isDisposed, isTrue);

      // Another example starts from its own authored circuit (no leak).
      await tapVisible(
          tester, find.byKey(_k('notebook-explore-h_superposition')));
      expect(state.experimentSession!.circuit.logicalGates.map((g) => g.type),
          [SelectedGateType.hadamard]);
      expect(identical(state.experimentSession, session), isFalse);
    });

    testWidgets('related activities respect Journey locks', (tester) async {
      final lessons = <int>[];
      // Lesson 1's entry, fresh learner: preview offers lesson 1 (unlocked).
      await pump(tester, await _progress(),
          articleId: notebookEntries.first.id, onOpenLesson: lessons.add);
      expect(find.byKey(_k('web-notebook-locked-preview')), findsOneWidget);
      await tapVisible(
          tester, find.byKey(_k('web-notebook-locked-open-lesson')));
      expect(lessons, [1]);
      // An entry from chapter 2: its lesson is locked, so no way in.
      final later = notebookEntries.firstWhere((e) => e.chapterIndex == 2);
      await pump(tester, await _progress(),
          articleId: later.id, onOpenLesson: lessons.add);
      expect(find.byKey(_k('web-notebook-locked-open-lesson')), findsNothing);
      expect(find.byKey(_k('web-notebook-go-journey')), findsOneWidget);
      expect(find.text(later.intuition.body), findsNothing);
    });

    for (final size in const [
      Size(1920, 1080),
      Size(1600, 900),
      Size(1440, 900),
      Size(1280, 800),
      Size(1024, 768),
      Size(800, 700),
      Size(500, 900),
    ]) {
      testWidgets('layout at $size', (tester) async {
        await pump(tester, await _progress(), size: size, articleId: 'gate-ry');
        expect(
            find.byKey(_k(size.width >= 760 + 238
                ? 'web-notebook-master-detail'
                : 'web-notebook-reader-gate-ry')),
            findsOneWidget);
        expect(find.byKey(_k('web-notebook-entry-title')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('shell integration', () {
    test('routes: #/notebook/<article>', () {
      expect(parseWebRoute('/notebook/gate-cnot')!.articleId, 'gate-cnot');
      expect(parseWebRoute('/notebook')!.articleId, isNull);
      expect(parseWebRoute('/notebook/Bad Id')!.articleId, isNull);
    });

    testWidgets('startup route opens a Notebook article', (tester) async {
      _size(tester, const Size(1440, 900));
      await tester.pumpWidget(QubitQuestWebApp(
          storage: InMemoryAppStorage(), startupRoute: '/notebook/gate-cnot'));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-notebook-reader-gate-cnot')), findsOneWidget);
    });

    testWidgets('Mastery gate reference opens the Notebook gate article',
        (tester) async {
      _size(tester, const Size(1440, 900));
      await tester.pumpWidget(QubitQuestWebApp(storage: InMemoryAppStorage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('web-nav-mastery')));
      await tester.pumpAndSettle();
      const id = 'phase_state_uncomputation';
      final row = find.byKey(const ValueKey('web-mastery-challenge-$id'));
      await tester.tap(row);
      await tester.pumpAndSettle();
      final ref = find.byKey(_k('web-mastery-gate-ref-hadamard'));
      await tester.ensureVisible(ref);
      await tester.pumpAndSettle();
      await tester.tap(ref);
      await tester.pumpAndSettle();
      expect(
          find.byKey(_k('web-notebook-reader-gate-hadamard')), findsOneWidget);
    });

    testWidgets('Notebook → Journey lesson opens only unlocked lessons',
        (tester) async {
      _size(tester, const Size(1440, 900));
      await tester.pumpWidget(QubitQuestWebApp(
          storage: InMemoryAppStorage(),
          startupRoute: '/notebook/${notebookEntries.first.id}'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('web-notebook-locked-open-lesson')));
      await tester.pumpAndSettle();
      final lesson =
          tester.widget<WebLessonWorkspace>(find.byType(WebLessonWorkspace));
      expect(lesson.levelId, 1);
    });
  });
}
