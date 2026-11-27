// v2.6 M10: Chapter 14 (Conditional Quantum Logic), Mastery 43–48 and the
// five new Notebook discoveries.
//
// Expected amplitudes are computed here from definitions (bit arithmetic,
// written-out phases), independently of the simulator; circuits are then run
// through the real validators.
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/discovery_catalog.dart' as discovery_catalog;
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_knowledge_base.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';

const _e = 1e-9;
final _r = math.sqrt1_2;

ComposerLevel _lesson(int id) => getJourneyLessonById(id)! as ComposerLevel;
QQLevel _challenge(String id) => mastery2Catalogue.orderedDefinitions
    .singleWhere((c) => c.semanticId == id)
    .levelDefinition;

/// Runs [steps] after the level's fixed gates and returns the circuit.
QuantumCircuit _attempt(ComposerLevel level, List<CanonicalCircuitStep> steps) {
  final c = QuantumCircuit(currentLevel: level);
  applyCanonicalCircuitSteps(c, steps);
  c.runSimulation();
  return c;
}

bool _accepts(ComposerLevel level, List<CanonicalCircuitStep> steps) =>
    level.evaluateCircuit(_attempt(level, steps)).success;

const _x = SelectedGateType.x;
CanonicalCircuitStep _single(SelectedGateType t, int q) =>
    CanonicalCircuitStep.single(t, targetQubit: q);
CanonicalCircuitStep _mcx(List<int> c, int t) =>
    CanonicalCircuitStep.multiControlledX(controlQubits: c, targetQubit: t);

void _expectState(List<Complex> actual, Map<int, (double, double)> expected,
    {String? reason}) {
  for (var i = 0; i < actual.length; i++) {
    final (re, im) = expected[i] ?? (0.0, 0.0);
    expect(actual[i].real, closeTo(re, _e), reason: '$reason [$i] re');
    expect(actual[i].imaginary, closeTo(im, _e), reason: '$reason [$i] im');
  }
}

void main() {
  group('content integrity', () {
    test('totals: 14 chapters, 71 lessons, 48 challenges, 71 discoveries', () {
      expect(journeyChapters, hasLength(14));
      expect(journeyLessons, hasLength(71));
      expect(ProgressionRules.guidedDiscoveryLevelCount, 71);
      expect(mastery2Catalogue.length, 48);
      expect(discovery_catalog.discoveryOrder, hasLength(71));
      expect(notebookEntries.where((e) => e.chapterIndex > 0), hasLength(71));
    });

    test('Chapter 14 occupies lessons 67–71 in order', () {
      final chapter = journeyChapters.last;
      expect(chapter.groupName, 'Chapter 14 - Conditional Quantum Logic');
      expect((chapter.from, chapter.to), (66, 70));
      expect([
        for (var id = 67; id <= 71; id++) getJourneyLessonById(id)!.title
      ], [
        'More Than a Controlled Flip',
        'When Every Condition Holds',
        'Conditions in Superposition',
        'From Conditions to Phase',
        'Building a Reusable Oracle',
      ]);
      for (var id = 67; id <= 71; id++) {
        expect(journeyChapterForLesson(id), same(chapter));
      }
    });

    test('existing identities are unchanged; new ones are appended', () {
      expect(discovery_catalog.discoveryOrder.sublist(66), [
        'Conditional Phase',
        'Multi-Controlled Logic',
        'Coherent Conditions',
        'Condition Becomes Phase',
        'Reusable Phase Oracle',
      ]);
      expect(discovery_catalog.discoveryOrder[65], 'Quantitative Search');
      expect(getJourneyLessonById(66)!.title, 'Choose a Stopping Point');
      final ordered = mastery2Catalogue.orderedDefinitions;
      expect(ordered[41].semanticId, 'nonuniform_reference_reflection');
      expect(ordered.skip(42).map((c) => (c.displayOrder, c.semanticId)), [
        (43, 'same_odds_different_phase'),
        (44, 'undo_complex_control'),
        (45, 'every_control_matters'),
        (46, 'condition_without_decision'),
        (47, 'mark_the_condition'),
        (48, 'oracle_left_a_trace'),
      ]);
      for (final c in ordered.skip(42)) {
        expect(mastery2Presentations[c.semanticId], isNotNull);
      }
      for (var i = 61; i <= 114; i++) {
        expect(getHistoricalMasteryById(i), isNotNull);
      }
    });

    test('each lesson unlocks its own Notebook entry, with examples', () {
      for (var id = 67; id <= 71; id++) {
        final title = getJourneyLessonById(id)!.discoveryTitle!;
        final entry = notebookEntriesByDiscoveryTitle[title]!;
        expect(entry.chapterIndex, 14);
        expect(entry.executableExampleIds, isNotEmpty);
        for (final ex in entry.executableExampleIds) {
          final example = executableNotebookExamplesById[ex]!;
          expect(example.relatedConcept, title);
          expect(example.validate(), isEmpty, reason: ex);
          expect(example.resultMatchesExpected(example.execute().state), isTrue,
              reason: ex);
          expect(example.allowOpenInBlochExplorer, isFalse,
              reason: 'multi-qubit: no single Bloch vector');
        }
      }
    });

    test('gate references link the new lessons and challenges', () {
      final kb = NotebookKnowledgeBase.instance;
      expect(kb.journeyLessonsUsing(SelectedGateType.cy), contains(67));
      expect(kb.journeyLessonsUsing(SelectedGateType.mcx),
          containsAll([68, 69, 70, 71]));
      expect(
          kb
              .masteryChallengesUsing(SelectedGateType.cy)
              .map((c) => c.semanticId),
          contains('undo_complex_control'));
      expect(
          kb
              .masteryChallengesUsing(SelectedGateType.mcx)
              .map((c) => c.semanticId),
          containsAll(['every_control_matters', 'oracle_left_a_trace']));
      final cy = kb.byId('gate-cy')!;
      expect(kb.relatedArticles(cy).map((a) => a.id),
          contains('conditional_phase'));
      final mcx = kb.byId('gate-mcx')!;
      expect(kb.relatedArticles(mcx).map((a) => a.id),
          containsAll(['multi_controlled_logic', 'reusable_phase_oracle']));
      // The CY/MCX articles keep their six experiments each.
      expect(cy.exampleIds, hasLength(6));
      expect(mcx.exampleIds, hasLength(6));
      for (final id in [...cy.exampleIds, ...mcx.exampleIds]) {
        expect(notebookExampleById(id), isNotNull, reason: id);
      }
    });

    test('every gate an activity needs is in its palette', () {
      final levels = [
        for (var id = 67; id <= 71; id++) _lesson(id),
        for (final c in mastery2Catalogue.orderedDefinitions.skip(42))
          if (c.levelDefinition case final ComposerLevel l) l,
      ];
      for (final level in levels) {
        expect(validateCanonicalSolutionMetadata(level), isEmpty,
            reason: level.title);
        final palette = level.availableGates.map((g) => g.type).toSet();
        for (final step in level.canonicalSolution!.steps) {
          expect(palette, contains(step.gateType), reason: level.title);
        }
      }
    });

    test('native activities use the shared router (no web-only guard)', () {
      for (var id = 67; id <= 71; id++) {
        expect(LevelUIRouter.routeKindFor(_lesson(id)),
            LevelUIRouteKind.composer);
      }
    });
  });

  group('lesson 14.1: CY versus CX', () {
    test('the fixed circuit prepares (|00⟩ + i|11⟩)/√2', () {
      _expectState(_attempt(_lesson(67), const []).currentState.stateVector,
          {0: (_r, 0), 3: (0, _r)});
    });

    test('CX, S, H gives |01⟩; the same gates on the CX state give 50/50', () {
      const fix = [
        CanonicalCircuitStep.controlled(SelectedGateType.cnot,
            controlQubit: 0, targetQubit: 1),
        CanonicalCircuitStep.single(SelectedGateType.s, targetQubit: 0),
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
      ];
      expect(_accepts(_lesson(67), fix), isTrue);
      _expectState(
          _attempt(_lesson(67), fix).currentState.stateVector, {1: (1, 0)});
      // Independent: the CX state through the same gates.
      final cx = QuantumCircuit(
          currentLevel: ComposerLevel.fromBinaryString(
              taskDescription: 'reference',
              initialQubitsStateString: '00',
              availableGates: const [],
              solutionFinalVector: const []));
      applyCanonicalCircuitSteps(cx, const [
        CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
        CanonicalCircuitStep.controlled(SelectedGateType.cnot,
            controlQubit: 0, targetQubit: 1),
        ...fix,
      ]);
      cx.runSimulation();
      _expectState(cx.currentState.stateVector, {0: (.5, .5), 1: (.5, -.5)});
    });

    test('rejects circuits that do not use the phase', () {
      expect(_accepts(_lesson(67), const []), isFalse);
      expect(
          _accepts(_lesson(67), const [
            CanonicalCircuitStep.controlled(SelectedGateType.cnot,
                controlQubit: 0, targetQubit: 1),
            CanonicalCircuitStep.single(SelectedGateType.hadamard,
                targetQubit: 0),
          ]),
          isFalse,
          reason: 'without S the i survives: 50/50');
    });
  });

  group('lesson 14.2: MCX with three controls on five qubits', () {
    test('accepts exactly MCX(q0,q2,q3 → q1) and checks all 32 inputs', () {
      final level = _lesson(68);
      expect(
          _accepts(level, [
            _mcx([0, 2, 3], 1)
          ]),
          isTrue);
      expect(
          _accepts(level, [
            _mcx([0, 2, 3, 4], 1)
          ]),
          isFalse,
          reason: 'q4 is not part of the condition');
      expect(
          _accepts(level, [
            _mcx([0, 2, 4], 1)
          ]),
          isFalse);
      expect(_accepts(level, [_single(_x, 1)]), isFalse,
          reason: 'right display, wrong operator');
      // Independent truth table of the accepted operator.
      final target = level.targetUnitary!;
      for (var input = 0; input < 32; input++) {
        final all = input & 1 != 0 && input & 4 != 0 && input & 8 != 0;
        final output = all ? input ^ 2 : input;
        expect(target[output][input].real, 1, reason: 'input $input');
      }
    });

    test('applying it twice restores every input', () {
      final level = _lesson(68);
      final twice = _attempt(level, [
        _mcx([0, 2, 3], 1),
        _mcx([0, 2, 3], 1)
      ]);
      final m = twice.getOverallCircuitMatrix().toComplexList();
      for (var i = 0; i < 32; i++) {
        expect(m[i][i].real, closeTo(1, _e));
      }
    });
  });

  group('lesson 14.3: conditions in superposition', () {
    test('joint state and Z-basis marginals', () {
      final level = _lesson(69);
      final steps = [
        _single(SelectedGateType.hadamard, 0),
        _single(SelectedGateType.hadamard, 1),
        _single(SelectedGateType.hadamard, 2),
        _mcx([0, 1, 2], 3),
      ];
      expect(_accepts(level, steps), isTrue);
      final s = _attempt(level, steps).currentState.stateVector;
      final a = 1 / math.sqrt(8);
      _expectState(s, {for (var i = 0; i < 7; i++) i: (a, 0), 15: (a, 0)});
      double p(Complex c) =>
          (c.real * c.real + c.imaginary * c.imaginary).toDouble();
      final targetOne =
          [for (var i = 8; i < 16; i++) p(s[i])].reduce((x, y) => x + y);
      expect(targetOne, closeTo(1 / 8, _e));
      expect(1 - targetOne, closeTo(.875, _e));
      // Not a product state: P(q3=1 and q0=0) = 0 although P(q0=0) = 1/2.
      expect(p(s[8]) + p(s[10]) + p(s[12]) + p(s[14]), 0);
      expect(_accepts(level, steps.take(3).toList()), isFalse);
      expect(
          _accepts(level, [
            ...steps.take(3),
            _mcx([1, 2, 3], 0)
          ]),
          isFalse);
    });
  });

  group('lesson 14.4: phase kickback onto |−⟩', () {
    test('marks |111⟩, keeps every label and the auxiliary in |−⟩', () {
      final level = _lesson(70);
      final steps = [
        _mcx([0, 1, 2], 3)
      ];
      expect(_accepts(level, steps), isTrue);
      final s = _attempt(level, steps).currentState.stateVector;
      for (var b = 0; b < 16; b++) {
        final sign = ((b & 7) == 7 ? -1 : 1) * ((b & 8) == 0 ? 1 : -1);
        expect(s[b].real, closeTo(sign / 4, _e), reason: '$b');
        expect(s[b].imaginary, closeTo(0, _e));
        // Separable auxiliary: every q3=1 amplitude is −(its q3=0 partner).
        if (b < 8) expect(s[b + 8].real, closeTo(-s[b].real, _e));
      }
      expect(_accepts(level, const []), isFalse, reason: 'no mark yet');
      expect(
          _accepts(level, [
            CanonicalCircuitStep.toffoli(
                controlQubit: 0, secondControlQubit: 1, targetQubit: 3)
          ]),
          isFalse,
          reason: 'CCX marks 011 and 111');
    });
  });

  group('lesson 14.5: reusable phase oracle', () {
    final level = _lesson(71);
    const pattern = [
      CanonicalCircuitStep.single(_x, targetQubit: 0),
      CanonicalCircuitStep.single(_x, targetQubit: 2),
    ];
    final oracle = [
      ...pattern,
      _mcx([0, 1, 2, 3], 4),
      ...pattern
    ];

    test('the X / MCX / X construction is accepted and marks only 1010', () {
      expect(_accepts(level, oracle), isTrue);
      final s = _attempt(level, oracle).currentState.stateVector;
      final a = 1 / math.sqrt(32);
      for (var b = 0; b < 32; b++) {
        final marked = (b & 15) == 10;
        final sign = (marked ? -1 : 1) * ((b & 16) == 0 ? 1 : -1);
        expect(s[b].real, closeTo(sign * a, _e), reason: '$b');
      }
      // The auxiliary is restored to |−⟩ and separable from the inputs.
      for (var b = 0; b < 16; b++) {
        expect(s[b + 16].real, closeTo(-s[b].real, _e));
      }
    });

    test('an equivalent multi-controlled Z on the inputs is also accepted', () {
      expect(
          _accepts(level, [
            ...pattern,
            _single(SelectedGateType.hadamard, 3),
            _mcx([0, 1, 2], 3),
            _single(SelectedGateType.hadamard, 3),
            ...pattern,
          ]),
          isTrue,
          reason: 'equal on the prepared |−⟩ subspace');
    });

    test('rejects missing uncomputation, wrong pattern and no-op', () {
      expect(
          _accepts(level, [
            ...pattern,
            _mcx([0, 1, 2, 3], 4)
          ]),
          isFalse,
          reason: 'inputs left relabelled');
      expect(
          _accepts(level, [
            _mcx([0, 1, 2, 3], 4)
          ]),
          isFalse,
          reason: 'marks 1111, not 1010');
      expect(_accepts(level, const []), isFalse,
          reason: 'same probabilities, no mark');
      // Probabilities alone cannot tell the correct oracle from no oracle.
      double p(Complex c) =>
          (c.real * c.real + c.imaginary * c.imaginary).toDouble();
      final good = _attempt(level, oracle).currentState.stateVector;
      final none = _attempt(level, const []).currentState.stateVector;
      for (var b = 0; b < 32; b++) {
        expect(p(good[b]), closeTo(p(none[b]), _e));
      }
    });

    test('the accepted operators are the definitions, phase for phase', () {
      // On the prepared subspace both targets agree exactly (no per-input
      // phase freedom): compare their columns for inputs with q4 = 0.
      final a = level.targetUnitary!;
      final b = level.alternateTargetUnitaries.single;
      for (var col = 0; col < 16; col++) {
        for (var row = 0; row < 32; row++) {
          expect(a[row][col].real, closeTo(b[row][col].real.toDouble(), _e));
        }
      }
    });
  });

  group('Mastery 43–48', () {
    test('concept checks have one correct option and authored hints', () {
      for (final id in [
        'same_odds_different_phase',
        'condition_without_decision',
        'mark_the_condition'
      ]) {
        final level = _challenge(id) as ConceptCheckLevel;
        expect(level.options, hasLength(4));
        expect(level.correctOptionIndex, inInclusiveRange(0, 3));
        expect(level.hints, hasLength(2));
      }
    });

    test('44: only the reversed inverse is the identity', () {
      final level = _challenge('undo_complex_control') as ComposerLevel;
      const cy10 = CanonicalCircuitStep.controlled(SelectedGateType.cy,
          controlQubit: 1, targetQubit: 0);
      expect(
          _accepts(level, [
            cy10,
            _single(SelectedGateType.z, 0),
            _single(SelectedGateType.s, 0)
          ]),
          isTrue);
      expect(
          _accepts(level, [
            _single(SelectedGateType.z, 0),
            _single(SelectedGateType.s, 0),
            cy10
          ]),
          isFalse,
          reason: 'wrong order');
      expect(_accepts(level, [cy10, _single(SelectedGateType.s, 0)]), isFalse,
          reason: 'S is not its own inverse');
      expect(
          _accepts(level, [
            const CanonicalCircuitStep.controlled(SelectedGateType.cnot,
                controlQubit: 1, targetQubit: 0),
            _single(SelectedGateType.z, 0),
            _single(SelectedGateType.s, 0)
          ]),
          isFalse,
          reason: 'CX is not CY');
    });

    test('45: X-conjugated q4 control, q1 excluded', () {
      final level = _challenge('every_control_matters') as ComposerLevel;
      final good = [
        _single(_x, 4),
        _mcx([0, 2, 4], 3),
        _single(_x, 4)
      ];
      expect(_accepts(level, good), isTrue);
      expect(
          _accepts(level, [
            _single(_x, 4),
            _mcx([0, 2, 4], 3)
          ]),
          isFalse);
      expect(
          _accepts(level, [
            _single(_x, 4),
            _mcx([0, 1, 2, 4], 3),
            _single(_x, 4)
          ]),
          isFalse);
      expect(
          _accepts(level, [
            _mcx([0, 2, 4], 3)
          ]),
          isFalse);
    });

    test('48: the buggy fixed oracle is wrong until X(q3) is added', () {
      final level = _challenge('oracle_left_a_trace') as ComposerLevel;
      expect(_accepts(level, const []), isFalse);
      _expectState(
          _attempt(level, const []).currentState.stateVector, {0x1E: (1, 0)},
          reason: 'the visible trace |11110⟩');
      expect(_accepts(level, [_single(_x, 3)]), isTrue);
      _expectState(_attempt(level, [_single(_x, 3)]).currentState.stateVector,
          {0x16: (1, 0)});
    });

    test('challenges stay independent of Journey progress', () async {
      final c =
          CampaignProgressController(store: InMemoryCampaignProgressStore());
      await c.load();
      expect(c.state.maxUnlockedLevel, 1);
      for (final def in mastery2Catalogue.orderedDefinitions.skip(42)) {
        expect(mastery2Catalogue.isAccessible(def.semanticId), isTrue);
      }
    });
  });

  group('progress', () {
    test('existing completion is kept; Chapter 14 unlocks after lesson 66',
        () async {
      final c =
          CampaignProgressController(store: InMemoryCampaignProgressStore());
      await c.load();
      for (var id = 1; id <= 66; id++) {
        await c.completeLesson(id);
      }
      expect(c.state.completedLessonIds, hasLength(66));
      expect(c.state.maxUnlockedLevel, 67);
      expect(c.unlockedDiscoveryTitles(), isNot(contains('Conditional Phase')));
      await c.completeLesson(67);
      expect(c.unlockedDiscoveryTitles(), contains('Conditional Phase'));
      await c.completeLesson(67); // revisit: idempotent
      expect(c.state.completedLessonIds.where((id) => id == 67), hasLength(1));
      expect(c.state.maxUnlockedLevel, 68);
    });
  });

  group('Notebook experiments', () {
    testWidgets('oracle experiment opens, resets and returns', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1000);
      addTearDown(tester.view.reset);
      final progress =
          CampaignProgressController(store: InMemoryCampaignProgressStore());
      await progress.load();
      await progress.unlockDiscovery('Reusable Phase Oracle');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WebNotebookWorkspace(
            progressController: progress,
            onOpenJourney: () {},
            requestedArticleId: 'reusable_phase_oracle',
            requestSerial: 1,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(
          find.byKey(
              const ValueKey('web-notebook-reader-reusable_phase_oracle')),
          findsOneWidget);
      final explore =
          find.byKey(const ValueKey('notebook-explore-oracle_pattern_1010'));
      await tester.ensureVisible(explore);
      await tester.pumpAndSettle();
      await tester.tap(explore);
      await tester.pumpAndSettle();
      final state = tester
          .state<WebNotebookWorkspaceState>(find.byType(WebNotebookWorkspace));
      final session = state.experimentSession!;
      expect(session.circuit.logicalGates.map((g) => g.type),
          contains(SelectedGateType.mcx));
      final before = session.circuit.logicalGates.length;
      session.clear();
      await tester.pumpAndSettle();
      expect(session.circuit.logicalGates, hasLength(before));
      expect(progress.state.completedLessonIds, isEmpty);
      await tester.tap(find.byKey(const ValueKey('notebook-experiment-back')));
      await tester.pumpAndSettle();
      expect(state.selectedArticleId, 'reusable_phase_oracle');
      expect(tester.takeException(), isNull);
    });

    test('notation follows the guide in the new content', () {
      final texts = [
        for (var id = 67; id <= 71; id++)
          '${getJourneyLessonById(id)!.taskDescription} '
              '${getJourneyLessonById(id)!.solutionExplanation}',
        for (final e in notebookEntries.where((e) => e.chapterIndex == 14))
          '${e.intuition.body} ${e.whatChanged?.body} ${e.quantumView?.body}',
      ].join(' ');
      expect(texts, isNot(contains('1/√2i')));
      expect(texts, isNot(contains('1/2π')));
      expect(texts, isNot(contains('+ −')));
      expect(GateEducationalCatalog.forType(SelectedGateType.cy), isNotNull);
    });
  });
}
