// v2.6 M6a: one quantum workspace, several educational contexts.
//
// Covers the exercise configuration of every existing definition, fixed
// operations at the session boundary, the explicit Check contract, the
// evaluators' scientific semantics, hidden targets, the Mastery library,
// the session-owned measurement-result lifecycle and responsive layouts.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/composer_gate_capabilities.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/screens/web_exercise_workspace.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/screens/web_mastery_browser.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_session_workspace.dart';
import 'package:quantumquiz/widgets/quantum_state_inspector_content.dart';

import 'support/journey_navigation.dart';
import 'support/mastery_math_test_platform.dart';
import 'support/laboratory_composer_finders.dart';

ValueKey<String> _k(String key) => ValueKey(key);

/// Every circuit exercise on the web: Journey lessons and Mastery challenges.
List<(String, ComposerLevel, ComposerMode)> get _exercises => [
      for (final (i, level) in journeyLessons.indexed)
        if (level is ComposerLevel)
          ('Journey ${i + 1}', level, ComposerMode.journeyExercise),
      for (final c in mastery2Catalogue.orderedDefinitions)
        if (c.levelDefinition is ComposerLevel)
          (
            'Mastery ${c.displayOrder}',
            c.levelDefinition as ComposerLevel,
            ComposerMode.masteryChallenge
          ),
    ];

ComposerSession _session(ComposerLevel level, ComposerMode mode,
        {bool revealTarget = true}) =>
    ComposerSession(
      circuit: QuantumCircuit(currentLevel: level),
      policy: ComposerPolicy.forMode(mode, level, revealTarget: revealTarget),
    );

/// Replays the learner part of [level]'s canonical solution through the
/// session's own commands (the same path drag and drop uses).
void _replayCanonical(ComposerSession session, ComposerLevel level) {
  final canonical = buildCanonicalSolutionCircuit(level);
  final learner = canonical.logicalGates.where((g) => g.isDeletable).toList()
    ..sort((a, b) => a.column.compareTo(b.column));
  for (final gate in learner) {
    final outcome = session.insertGate(GatePlacementRequest(
      gate: gate.gate,
      target: CircuitLocation(
          qubit: gate.isSingleQubit ? gate.anchor.qubit : gate.targetQubit!,
          column: gate.column),
      // Every control, including a multi-controlled X's (v2.6 M10).
      controls: gate.controlQubits,
    ));
    expect(outcome.changed, isTrue,
        reason: 'canonical ${gate.type} at ${gate.anchor}');
  }
  canonical.dispose();
}

Future<CampaignProgressController> _progress(
    [CampaignProgressState? state]) async {
  final c = CampaignProgressController(
      store: InMemoryCampaignProgressStore(state));
  await c.load();
  return c;
}

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void main() {
  // These tests verify the classic three-column exercise layout, kept as a
  // test seam after M11D moved lessons and challenges to the learning layout.
  setUpAll(() => debugClassicExerciseLayout = true);
  tearDownAll(() => debugClassicExerciseLayout = false);
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  useMasteryMathTestPlatform();

  group('every existing circuit exercise in the shared session', () {
    test('inventory: Journey and Mastery circuit exercises exist', () {
      // Baseline, not a limit: counts are read from the curriculum.
      expect(_exercises.where((e) => e.$3 == ComposerMode.journeyExercise),
          isNotEmpty);
      expect(_exercises.where((e) => e.$3 == ComposerMode.masteryChallenge),
          isNotEmpty);
    });

    test('policy matches each definition; no Sandbox capabilities', () {
      for (final (name, level, mode) in _exercises) {
        final p = ComposerPolicy.forMode(mode, level);
        expect(p.availableGates.map((g) => g.type),
            level.availableGates.map((g) => g.type),
            reason: name);
        expect(p.permittedQubitCounts, {level.numQubits}, reason: name);
        expect(p.allowsMeasurement, isFalse, reason: name);
        expect(p.runsExperiments, isFalse, reason: name);
        expect(p.persistsToSandbox, isFalse, reason: name);
        expect(p.offersCheck, isTrue, reason: name);
        expect(p.clearAction, ComposerClearAction.reset, reason: name);
        expect(p.showsTargetState, level.solutionFinalVector.isNotEmpty,
            reason: name);
        // Information restrictions are independent of editing rules.
        final hidden = ComposerPolicy.forMode(mode, level, revealTarget: false);
        expect(hidden.showsTargetState, isFalse, reason: name);
        expect(hidden.availableGates.length, p.availableGates.length);
      }
    });

    test(
        'canonical solutions are buildable through session commands and '
        'pass; the starting circuit does not', () {
      for (final (name, level, mode) in _exercises) {
        final session = _session(level, mode);
        session.circuit.runSimulation();
        expect(level.evaluateCircuit(session.circuit).success, isFalse,
            reason: '$name must not be solved before the learner acts');
        _replayCanonical(session, level);
        session.circuit.runSimulation();
        expect(level.evaluateCircuit(session.circuit).success, isTrue,
            reason: name);
        session.dispose();
      }
    });

    test('fixed operations resist every mutation path at the session', () {
      var checked = 0;
      for (final (name, level, mode) in _exercises) {
        final session = _session(level, mode);
        final fixed =
            session.circuit.logicalGates.where((g) => !g.isDeletable).toList();
        if (fixed.isEmpty) {
          session.dispose();
          continue;
        }
        checked++;
        // Reset re-creates authored gates (new IDs); what is protected is
        // the operation itself: type, position, parameters and the lock.
        String snapshot() => session.circuit.logicalGates
            .where((g) => !g.isDeletable)
            .map((g) => '${g.type}@${g.anchor.qubit},${g.column}'
                ':${g.controlQubit}:${g.secondControlQubit}:${g.gate.angle}')
            .join(',');
        final before = snapshot();
        for (final gate in fixed) {
          expect(session.deleteOperation(gate.id).changed, isFalse,
              reason: '$name delete');
          expect(session.duplicateGate(gate.id).changed, isFalse,
              reason: '$name duplicate');
          for (final g in level.availableGates) {
            expect(session.replaceGate(gate.id, g).changed, isFalse,
                reason: '$name replace');
          }
          expect(
              session
                  .moveGate(
                      gate.id,
                      CircuitLocation(
                          qubit: gate.anchor.qubit,
                          column: gate.column + 3))
                  .changed,
              isFalse,
              reason: '$name move');
          expect(session.editRotationAngle(gate.id, math.pi / 3).changed,
              isFalse,
              reason: '$name angle');
          // Inspection never grants mutation.
          session.select(gate.id);
          final caps = session.selectedCapabilities;
          expect(caps.actions.difference({ComposerSelectedGateAction.inspect}),
              isEmpty,
              reason: '$name capabilities');
        }
        // A learner edit, Reset, undo and redo never touch fixed gates.
        final free = level.availableGates.first;
        session.insertGate(GatePlacementRequest(
          gate: free,
          target: CircuitLocation(
              qubit: 0, column: session.circuit.maxCircuitDepth() + 1),
          controls: [
            for (var c = 0; c < controlCountFor(free.type); c++)
              level.numQubits - 1 - c,
          ],
        ));
        session.clear();
        session.undo();
        session.redo();
        expect(snapshot(), before, reason: name);
        session.dispose();
      }
      expect(checked, greaterThan(0), reason: 'fixed-gate exercises exist');
    });

    test('review lock rejects every command and history step', () {
      final level = getQQLevelById(1)! as ComposerLevel;
      final session = _session(level, ComposerMode.journeyExercise);
      _replayCanonical(session, level);
      final before = session.circuit.captureEditSnapshot();
      session.readOnly = true;
      final id = session.circuit.logicalGates.first.id;
      expect(session.canUndo, isFalse);
      expect(session.undo(), isFalse);
      expect(session.redo(), isFalse);
      expect(session.deleteOperation(id).changed, isFalse);
      expect(session.clear().changed, isFalse);
      expect(
          session
              .insertGate(GatePlacementRequest(
                  gate: level.availableGates.first,
                  target: const CircuitLocation(qubit: 0, column: 3)))
              .changed,
          isFalse);
      expect(session.lastFeedback?.detail, ComposerSession.readOnlyOutcome.detail);
      expect(session.circuit.captureEditSnapshot().sameDefinitionAs(before),
          isTrue);
      session.dispose();
    });
  });

  group('evaluation semantics are preserved', () {
    test('relative phase: equal Z probabilities do not pass (|+⟩ vs |−⟩)', () {
      final level = journeyLessons.whereType<ComposerLevel>().firstWhere(
          (l) => l.title == 'The Minus Sign');
      final session = _session(level, ComposerMode.journeyExercise);
      final c = session.circuit..runSimulation();
      final target = level.solutionFinalVector.map((v) => v.first).toList();
      final current = c.currentState.stateVector;
      for (var i = 0; i < target.length; i++) {
        expect(
            math.pow(current[i].magnitude.toDouble(), 2),
            closeTo(math.pow(target[i].magnitude.toDouble(), 2), 1e-12),
            reason: 'same Z-basis probabilities');
      }
      expect(level.evaluateCircuit(c).success, isFalse);
      _replayCanonical(session, level);
      c.runSimulation();
      expect(level.evaluateCircuit(c).success, isTrue);
      session.dispose();
    });

    test('global phase: exact-state mode rejects, physical-state accepts', () {
      ComposerLevel level(ValidationMode mode) => ComposerLevel(
            taskDescription: 'Prepare |1⟩',
            numQubits: 1,
            initialQubitsStateStr: '0',
            initialQubitsState: ComposerLevel.getZeroStateVector(1),
            availableGates: [
              Gate.fromIdentifier(SelectedGateType.x),
              Gate.fromIdentifier(SelectedGateType.z),
            ],
            solutionFinalVector: ComposerLevel.getOneStateVector(1)
                .map((a) => [a])
                .toList(),
            validationMode: mode,
          );
      for (final mode in [ValidationMode.finalState, ValidationMode.physicalState]) {
        final l = level(mode);
        final c = QuantumCircuit(currentLevel: l)
          ..insertSingleGateWithOutcome(Gate.fromIdentifier(SelectedGateType.x), 0, 0)
          ..insertSingleGateWithOutcome(Gate.fromIdentifier(SelectedGateType.z), 1, 0)
          ..runSimulation();
        final result = l.evaluateCircuit(c);
        // Z·X|0⟩ = −|1⟩.
        expect(result.globalPhaseMatches, isTrue);
        expect(result.success, mode == ValidationMode.physicalState);
        if (mode == ValidationMode.finalState) {
          expect(ExerciseCheckFeedback.failure(l, result).message,
              contains('global phase'));
        }
        c.dispose();
      }
    });

    test('unitary mode: matching the shown input is not enough', () {
      final level = journeyLessons.whereType<ComposerLevel>().firstWhere(
          (l) => l.title == 'Nothing Happened?');
      expect(level.validationMode, ValidationMode.unitary);
      final c = QuantumCircuit(currentLevel: level)..runSimulation();
      final result = level.evaluateCircuit(c);
      expect(result.stateMatches, isTrue,
          reason: 'Z|0⟩ = |0⟩: the shown input cannot tell I from Z');
      expect(result.success, isFalse);
      expect(ExerciseCheckFeedback.failure(level, result).message,
          contains('every input'));
      c.dispose();
    });
  });

  group('explicit Check', () {
    Future<WebComposerExerciseState> pump(
      WidgetTester tester,
      ComposerLevel level, {
      required Future<void> Function() onCompleted,
      bool revealTarget = true,
    }) async {
      _size(tester, const Size(1440, 1000));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WebComposerExercise(
            level: level,
            mode: ComposerMode.journeyExercise,
            contextLabel: 'Lesson',
            onCompleted: onCompleted,
            onNext: () {},
            onOpenNotebook: () {},
            revealTarget: revealTarget,
          ),
        ),
      ));
      await tester.pump();
      return tester.state(find.byType(WebComposerExercise));
    }

    testWidgets('a correct circuit never completes until Check; then once',
        (tester) async {
      final level = getQQLevelById(1)! as ComposerLevel;
      final progress = await _progress();
      var calls = 0;
      final state = await pump(tester, level, onCompleted: () async {
        calls++;
        await progress.completeLesson(1);
      });
      _replayCanonical(state.session, level);
      await tester.pumpAndSettle();
      // Correct, but not checked: nothing completes or announces success.
      expect(level.evaluateCircuit(state.session.circuit).success, isTrue);
      expect(calls, 0);
      expect(progress.state.completedLessonIds, isEmpty);
      expect(find.byKey(_k('web-lesson-success')), findsNothing);
      expect(find.byKey(_k('web-lesson-feedback')), findsNothing);
      expect(find.text('Correct circuit.'), findsNothing);

      await tester.tap(find.byKey(_k('web-lesson-check')));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(progress.state.completedLessonIds, {1});
      expect(find.byKey(_k('web-lesson-success')), findsOneWidget);
      expect(
          tester.widget<FilledButton>(find.byKey(_k('web-lesson-check')))
              .onPressed,
          isNull);
      expect(state.session.readOnly, isTrue);
      final before = progress.state;
      // Completing again (e.g. a review) changes nothing.
      await progress.completeLesson(1);
      expect(progress.state.completedLessonIds, before.completedLessonIds);
      expect(progress.state.maxUnlockedLevel, before.maxUnlockedLevel);
    });

    testWidgets('a wrong Check keeps circuit, history and progress',
        (tester) async {
      final level = journeyLessons.whereType<ComposerLevel>().firstWhere(
          (l) => l.title == 'The Minus Sign');
      var calls = 0;
      final state =
          await pump(tester, level, onCompleted: () async => calls++);
      // A legitimate but wrong edit: Z twice is the identity.
      for (final column in [0, 1]) {
        state.session.insertGate(GatePlacementRequest(
            gate: Gate.fromIdentifier(SelectedGateType.z),
            target: CircuitLocation(qubit: 0, column: column)));
      }
      await tester.pump();
      final snapshot = state.session.circuit.captureEditSnapshot();
      await tester.tap(find.byKey(_k('web-lesson-check')));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.textContaining('Not quite yet'), findsOneWidget);
      expect(state.session.circuit.captureEditSnapshot()
          .sameDefinitionAs(snapshot), isTrue);
      expect(state.session.canUndo, isTrue);
      expect(state.session.readOnly, isFalse);
      // The next edit retires the feedback.
      state.session.undo();
      await tester.pump();
      expect(find.byKey(_k('web-lesson-feedback')), findsNothing);
    });

    testWidgets('hidden targets never reach the Results panel',
        (tester) async {
      final level = getQQLevelById(8)! as ComposerLevel;
      await pump(tester, level,
          onCompleted: () async {}, revealTarget: false);
      expect(find.byKey(_k('web-composer-target-state')), findsNothing);
      final content = tester.widget<QuantumStateInspectorContent>(
          find.byType(QuantumStateInspectorContent));
      expect(content.targetStateVector, isEmpty);
      expect(content.targetStateExpression, isNull);
      expect(content.targetStateLabel, isNull);
    });

    testWidgets('fixed gates are marked, inspectable and protected',
        (tester) async {
      final level = getQQLevelById(2)! as ComposerLevel;
      final state = await pump(tester, level, onCompleted: () async {});
      final canvas = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
      expect(canvas.markFixedGates, isTrue);
      final fixed = canvas.circuit.logicalGates.single;
      expect(fixed.isDeletable, isFalse);
      canvas.onGateTap(fixed.toPlacedGateRef());
      await tester.pumpAndSettle();
      // Inspectable (the inspector shows the gate) but no edit actions.
      expect(find.text('Pauli-X gate'), findsWidgets);
      for (final action in ['replace', 'duplicate', 'delete']) {
        expect(find.byKey(ValueKey('web-composer-$action-selected-gate')),
            findsNothing,
            reason: action);
      }
      // Drag-to-delete is refused with an explanation.
      canvas.onDeletePlacedGateRequested(fixed.toPlacedGateRef());
      await tester.pump();
      expect(
          tester.widget<Text>(find.byKey(_k('web-storage-status'))).data,
          contains('part of the activity'));
      expect(state.session.circuit.logicalGates.single.id, fixed.id);
      // Dragging the fixed gate explains instead of silently ignoring.
      await tester.drag(find.byKey(ValueKey('fixed-gate-${fixed.id.value}')),
          const Offset(120, 140));
      await tester.pump();
      expect(
          tester.widget<Text>(find.byKey(_k('web-storage-status'))).data,
          contains('cannot be moved or removed'));
      expect(state.session.circuit.logicalGates.single.anchor, fixed.anchor);
    });
  });

  group('Sandbox measurement results belong to the session (M6a)', () {
    /// The shell's sessions wait for a painted frame before running, so a
    /// widget test pumps while the run completes.
    Future<void> run(WidgetTester tester, ComposerSession s, bool many) async {
      final pending = s.run(manyShots: many);
      await tester.pump();
      await pending;
      await tester.pump();
    }

    ComposerSession sandboxSession(WidgetTester tester) => tester
        .widget<ComposerSessionWorkspace>(find.byType(ComposerSessionWorkspace))
        .slot
        .session;

    testWidgets(
        'results survive every destination and an opened lesson; '
        'edits invalidate them', (tester) async {
      _size(tester, const Size(1440, 1000));
      await tester.pumpWidget(QubitQuestWebApp(storage: InMemoryAppStorage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('web-nav-composer')));
      await tester.pumpAndSettle();
      await pumpUntilSandboxOpen(tester);
      await tester.tap(find.byKey(_k('web-composer-qubits-2')));
      await tester.pumpAndSettle();
      final session = sandboxSession(tester);
      session.insertGate(GatePlacementRequest(
          gate: Gate.fromIdentifier(SelectedGateType.hadamard),
          target: const CircuitLocation(qubit: 0, column: 0)));
      session.insertGate(GatePlacementRequest(
          gate: Gate.fromIdentifier(SelectedGateType.cnot),
          target: const CircuitLocation(qubit: 1, column: 1),
          controls: const [0]));
      session.insertMeasurement(const CircuitLocation(qubit: 0, column: 2));
      await run(tester, session, false);
      await run(tester, session, true);
      await tester.pumpAndSettle();
      final single = session.singleShot!;
      final shots = session.shotsResult!;
      final conditional = single.conditionalState;
      expect(conditional, isNotNull);
      final revision = session.revision;

      // Journey, an opened lesson, Notebook, Mastery, Bloch Explorer.
      await tester.tap(find.byKey(_k('web-nav-journey')));
      await tester.pumpAndSettle();
      await openJourneyChapter(tester, 1);
      await tester.pumpAndSettle();
      final lesson = tester
          .widgetList<ComposerSessionWorkspace>(
              find.byType(ComposerSessionWorkspace, skipOffstage: false))
          .map((w) => w.slot.session)
          .firstWhere((s) => !identical(s, session));
      expect(lesson.policy.mode, ComposerMode.journeyExercise);
      lesson.insertGate(GatePlacementRequest(
          gate: Gate.fromIdentifier(SelectedGateType.x),
          target: const CircuitLocation(qubit: 0, column: 0)));
      for (final nav in ['notebook', 'mastery', 'bloch', 'composer']) {
        await tester.tap(find.byKey(_k('web-nav-$nav')));
        await tester.pumpAndSettle();
      }
      expect(sandboxSession(tester), same(session));
      // The same experiment objects: nothing was re-run or rebuilt.
      expect(session.singleShot, same(single));
      expect(session.shotsResult, same(shots));
      expect(session.singleShot!.conditionalState, same(conditional));
      expect(session.revision, revision);
      await tester.tap(find.descendant(
          of: find.byKey(_k('quantum-inspector-view-selector')),
          matching: find.text('Measure')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-sandbox-shots-result')), findsOneWidget);

      // Presentation changes keep them.
      session.select(session.circuit.logicalGates.first.id);
      await tester.pumpAndSettle();
      expect(session.shotsResult, same(shots));

      // A circuit change invalidates them; a new run makes new results.
      session.insertGate(GatePlacementRequest(
          gate: Gate.fromIdentifier(SelectedGateType.x),
          target: const CircuitLocation(qubit: 1, column: 3)));
      expect(session.singleShot, isNull);
      expect(session.shotsResult, isNull);
      await run(tester, session, true);
      expect(session.shotsResult, isNotNull);
      expect(session.shotsResult, isNot(same(shots)));
      expect(tester.takeException(), isNull);
    });

    test('every circuit mutation invalidates results; selection does not',
        () async {
      final store = SandboxPersistenceStore(storage: InMemoryAppStorage());
      final level = createSandboxComposerLevel(2);
      final session = ComposerSession(
        circuit: QuantumCircuit(currentLevel: level),
        policy: ComposerPolicy.forMode(ComposerMode.sandbox, level),
        saveQueue: store.programs.queue(2),
      );
      addTearDown(session.dispose);
      final h = session.insertGate(GatePlacementRequest(
              gate: Gate.fromIdentifier(SelectedGateType.hadamard),
              target: const CircuitLocation(qubit: 0, column: 0)))
          .affectedGateId!;
      final rx = session.insertGate(GatePlacementRequest(
              gate: Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2),
              target: const CircuitLocation(qubit: 1, column: 0)))
          .affectedGateId!;
      final m = session
          .insertMeasurement(const CircuitLocation(qubit: 0, column: 1))
          .affectedGateId!;

      Future<void> expectInvalidated(String what, bool Function() edit) async {
        await session.run(manyShots: true);
        await session.run(manyShots: false);
        expect(session.shotsResult, isNotNull, reason: what);
        expect(edit(), isTrue, reason: '$what must change the circuit');
        expect(session.shotsResult, isNull, reason: what);
        expect(session.singleShot, isNull, reason: what);
      }

      await session.run(manyShots: true);
      final kept = session.shotsResult;
      session.select(h);
      session.select(null);
      expect(session.shotsResult, same(kept), reason: 'selection');

      await expectInvalidated(
          'angle', () => session.editRotationAngle(rx, 1.0).changed);
      await expectInvalidated(
          'replace',
          () => session
              .replaceGate(h, Gate.fromIdentifier(SelectedGateType.x))
              .changed);
      // Moves rx from q1 to q0, before the measured X (a real change).
      await expectInvalidated(
          'move',
          () => session
              .moveGate(rx, const CircuitLocation(qubit: 0, column: 0))
              .changed);
      await expectInvalidated(
          'duplicate', () => session.duplicateGate(rx).changed);
      await expectInvalidated(
          'classical bit', () => session.setClassicalBit(m, 1).changed);
      // A measurement move that settles back into its slot (left
      // compaction) changes nothing and keeps results; one that changes the
      // program invalidates them.
      await session.run(manyShots: true);
      final beforeMove = session.shotsResult;
      final moved = session.moveMeasurement(m, 4);
      if (moved.changed &&
          session.revision > 0 &&
          !identical(session.shotsResult, beforeMove)) {
        expect(session.shotsResult, isNull);
      } else {
        expect(session.shotsResult, same(beforeMove),
            reason: 'a no-op move keeps results');
      }
      await expectInvalidated('undo', session.undo);
      await expectInvalidated('redo', session.redo);
      await expectInvalidated(
          'delete', () => session.deleteOperation(h).changed);
      await expectInvalidated('clear', () => session.clear().changed);
    });

    testWidgets('leaving a lesson disposes its session; Sandbox untouched',
        (tester) async {
      _size(tester, const Size(1440, 1000));
      final progress = await _progress();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WebJourneyWorkspace(
              progressController: progress, onOpenNotebook: () {}),
        ),
      ));
      await tester.pumpAndSettle();
      await openJourneyChapter(tester, 1);
      await tester.pumpAndSettle();
      final lesson = tester
          .widget<ComposerSessionWorkspace>(find.byType(ComposerSessionWorkspace))
          .slot
          .session;
      expect(lesson.saveQueue, isNull, reason: 'exercises never autosave');
      await tester.tap(find.byKey(_k('web-journey-back-map')));
      await tester.pumpAndSettle();
      expect(lesson.isDisposed, isTrue);
    });
  });

  group('Mastery library', () {
    Future<CampaignProgressController> pumpLibrary(WidgetTester tester,
        {Size size = const Size(1440, 1000)}) async {
      _size(tester, size);
      final progress = await _progress();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WebMasteryWorkspace(
            progressController: progress,
            onBackToJourney: () {},
            onOpenNotebook: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return progress;
    }

    String count(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(_k('web-mastery-result-count'))).data!;

    testWidgets('search covers concepts and types; filters use real metadata',
        (tester) async {
      await pumpLibrary(tester);
      final all = mastery2Catalogue.orderedDefinitions;
      expect(count(tester), '${all.length} of ${all.length} challenges');
      await tester.enterText(find.byKey(_k('web-mastery-search')), 'kickback');
      await tester.pumpAndSettle();
      final kickback = all
          .where((c) =>
              c.conceptTags.contains(MasteryConceptTag.kickback) ||
              c.title.toLowerCase().contains('kickback'))
          .length;
      expect(count(tester), '$kickback of ${all.length} challenges');
      await tester.tap(find.byKey(_k('web-mastery-clear-filters')));
      await tester.pumpAndSettle();
      expect(count(tester), '${all.length} of ${all.length} challenges');

      const query = MasteryLibraryQuery(
          type: MasteryInteractionType.construction,
          difficulty: MasteryDifficulty.advanced);
      final expected = all.where((c) => query.matches(c, const {})).length;
      expect(
          expected,
          all
              .where((c) =>
                  c.interactionType == MasteryInteractionType.construction &&
                  c.difficulty == MasteryDifficulty.advanced)
              .length);
      // Empty state with a way back.
      await tester.enterText(find.byKey(_k('web-mastery-search')), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-mastery-empty')), findsOneWidget);
      await tester.tap(find.byKey(_k('web-mastery-empty-reset')));
      await tester.pumpAndSettle();
      expect(count(tester), '${all.length} of ${all.length} challenges');
    });

    testWidgets('details never reveal answers; selecting never starts',
        (tester) async {
      await pumpLibrary(tester);
      for (final c in mastery2Catalogue.orderedDefinitions.take(12)) {
        await tester.ensureVisible(
            find.byKey(ValueKey('web-mastery-challenge-${c.semanticId}')));
        await tester
            .tap(find.byKey(ValueKey('web-mastery-challenge-${c.semanticId}')));
        await tester.pumpAndSettle();
        expect(find.byKey(_k('web-mastery-activity')), findsNothing);
        final level = c.levelDefinition;
        // The start-of-challenge task statement is always present.
        expect(find.byKey(_k('web-mastery-detail-task')), findsOneWidget,
            reason: c.semanticId);
        final hidden = <String>[
          ...?level.hints,
          if ((level.solutionExplanation ?? '').isNotEmpty)
            level.solutionExplanation!,
          if (level is McqLevel) ...level.options,
        ];
        for (final text in hidden) {
          expect(find.text(text), findsNothing, reason: c.semanticId);
        }
      }
    });

    testWidgets(
        'returning from a challenge keeps search, selection and completion',
        (tester) async {
      final progress = await pumpLibrary(tester);
      await tester.enterText(
          find.byKey(_k('web-mastery-search')), 'entanglement');
      await tester.pumpAndSettle();
      const id = 'bell_input_sign_preparation';
      final row = find.byKey(const ValueKey('web-mastery-challenge-$id'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('web-mastery-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('web-mastery-activity-$id')),
          findsOneWidget);
      await progress.completeMasteryChallenge(id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('web-mastery-back-overview')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextField>(find.byKey(_k('web-mastery-search')))
              .controller!
              .text,
          'entanglement');
      expect(find.byKey(const ValueKey('web-mastery-detail-$id')),
          findsOneWidget);
      expect(find.text('Review challenge'), findsOneWidget);
      expect(find.byKey(const ValueKey('web-mastery-status-$id-completed')),
          findsOneWidget);
    });

    testWidgets('narrow library: list, then details with a way back',
        (tester) async {
      await pumpLibrary(tester, size: const Size(500, 900));
      expect(find.byKey(_k('web-mastery-master-detail')), findsNothing);
      const id = 'global_phase_equivalence';
      await tester.tap(find.byKey(const ValueKey('web-mastery-challenge-$id')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('web-mastery-detail-$id')),
          findsOneWidget);
      await tester.tap(find.byKey(_k('web-mastery-back-to-list')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-mastery-list')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('responsive educational workspaces', () {
    for (final size in const [
      Size(1920, 1080),
      Size(1600, 900),
      Size(1440, 900),
      Size(1280, 800),
      Size(1024, 768),
      Size(800, 700),
      Size(500, 900),
    ]) {
      testWidgets('Journey 2-qubit lesson in the real shell at $size',
          (tester) async {
        _size(tester, size);
        final progress = await _progress(CampaignProgressPolicy.completeLesson(
            CampaignProgressState.fresh(), 22));
        // Valid fixture progress: lessons 1–22 complete (chapter 5 current).
        await tester.pumpWidget(MaterialApp(
          home: QubitQuestWebShell(
            progressController: progress,
            sandboxPersistenceStore:
                SandboxPersistenceStore(storage: InMemoryAppStorage()),
            startupRoute: '/journey/chapter-5',
          ),
        ));
        await tester.pumpAndSettle();
        final start = find.byKey(_k('journey-primary-action'));
        await tester.ensureVisible(start);
        await tester.tap(start);
        await tester.pumpAndSettle();
        expect(find.byKey(_k('web-exercise-workspace')), findsOneWidget);
        expect(find.byKey(_k('web-lesson-check')).hitTestable(), findsOneWidget,
            reason: 'Check reachable without scrolling');
        expect(find.byKey(_k('web-compact-task')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a concept check uses a reading page, not a Composer',
        (tester) async {
      _size(tester, const Size(1440, 900));
      final level =
          journeyLessons.firstWhere((l) => l is ConceptCheckLevel);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WebLessonWorkspace(
            levelId: 35,
            level: level,
            alreadyCompleted: false,
            onCompleted: () async {},
            onNextLesson: () {},
            onBackToChapter: () {},
            onOpenNotebook: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(ComposerSessionWorkspace), findsNothing);
      expect(find.byType(ComposerCircuitCanvas), findsNothing);
      final page = tester.getSize(find.byKey(const ValueKey('web-lesson-content-35')));
      expect(page.width, lessThanOrEqualTo(860));
    });
  });
}
