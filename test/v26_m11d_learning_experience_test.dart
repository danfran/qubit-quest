import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_exercise_workspace.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/bloch_summary_panel.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';
import 'package:quantumquiz/widgets/lesson_state_comparison.dart';
import 'package:quantumquiz/widgets/state_amplitude_panel.dart';

/// v2.6 M11D: Journey and Mastery learning experience, and the M11C.1
/// Composer follow-ups.

ValueKey<String> _k(String key) => ValueKey(key);

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<CampaignProgressController> _progress(
    {int unlocked = 71, int completedUpTo = 70}) async {
  final controller = CampaignProgressController(
    store: InMemoryCampaignProgressStore(CampaignProgressState(
      maxUnlockedLevel: unlocked,
      completedLessonIds: {for (var i = 1; i <= completedUpTo; i++) i},
    )),
  );
  await controller.load();
  return controller;
}

Future<void> _journey(WidgetTester tester, CampaignProgressController progress,
    {int? lesson}) async {
  await tester.pumpWidget(MaterialApp(
    theme: QubitQuestTheme.web(),
    home: Scaffold(
      body: WebJourneyWorkspace(
        progressController: progress,
        onOpenNotebook: () {},
        requestedLessonId: lesson,
        lessonRequestSerial: lesson == null ? 0 : 1,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Journey', () {
    testWidgets('lesson 14.5 keeps its operator-level validation scope',
        (tester) async {
      await _size(tester, const Size(1500, 1000));
      final progress = await _progress();
      await _journey(tester, progress, lesson: 71);
      final level = getJourneyLessonById(71)! as ComposerLevel;
      expect(level.validationMode, ValidationMode.unitary);
      // A dedicated learning workspace, not the Sandbox Composer.
      expect(find.byKey(_k('lesson-comparison')), findsOneWidget);
      expect(find.byKey(_k('composer-lab-mode')), findsNothing);
      expect(find.byKey(_k('web-composer-qubit-selector')), findsNothing);
      // The target names its scope: every basis input, the whole operator.
      final note =
          tester.widget<Text>(find.byKey(_k('lesson-validation-scope'))).data!;
      expect(note, contains('all ${1 << level.numQubits} basis inputs'));
      expect(note, contains('matching it alone is not enough'));
      expect(find.text('TARGET FOR THIS INPUT'), findsOneWidget);
      // Check stays explicit: nothing is completed by looking.
      expect(progress.state.completedLessonIds.contains(71), isFalse);
      expect(find.byKey(_k('web-lesson-check')), findsOneWidget);
      expect(find.byKey(_k('web-lesson-check-reminder')), findsOneWidget);
    });

    testWidgets('curriculum stays beside the lesson with its chapter open',
        (tester) async {
      await _size(tester, const Size(1500, 1000));
      final progress = await _progress(unlocked: 69, completedUpTo: 68);
      await _journey(tester, progress, lesson: 69);
      expect(find.byKey(_k('journey-lesson-with-nav')), findsOneWidget);
      expect(find.byKey(_k('journey-nav-lessons-14')), findsOneWidget);
      // Completed, viewing, available and locked lessons are told apart.
      expect(find.byKey(_k('journey-nav-lesson-status-67-completed')),
          findsOneWidget);
      expect(find.byKey(_k('journey-nav-lesson-status-69-viewing')),
          findsOneWidget);
      expect(find.byKey(_k('journey-nav-lesson-status-70-locked')),
          findsOneWidget);
      // A locked lesson cannot be opened from the navigation.
      await tester.tap(find.byKey(_k('journey-nav-lesson-70')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-lesson-69')), findsOneWidget);
      // Navigating to a completed lesson reviews it in place.
      await tester.tap(find.byKey(_k('journey-nav-lesson-67')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-lesson-67')), findsOneWidget);
      expect(find.text('Completed · review'), findsOneWidget);
      // The curriculum collapses to a rail for circuit space.
      await tester.ensureVisible(find.byKey(_k('journey-nav-collapse')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('journey-nav-collapse')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('journey-curriculum-rail')), findsOneWidget);
      // Choosing a chapter returns to its overview.
      await tester.tap(find.byKey(_k('journey-rail-chapter-5')));
      await tester.pumpAndSettle();
      expect(find.text('Entanglement'), findsWidgets);
      expect(find.byKey(_k('journey-detail-title')), findsOneWidget);
    });

    testWidgets('a resize across the navigation boundary keeps the lesson',
        (tester) async {
      await _size(tester, const Size(1400, 1000));
      final progress = await _progress(unlocked: 10, completedUpTo: 9);
      await _journey(tester, progress, lesson: 10);
      QuantumCircuit circuit() => tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .circuit;
      final before = circuit();
      for (final width in [700.0, 1400.0, 880.0]) {
        tester.view.physicalSize = Size(width, 1000);
        await tester.pumpAndSettle();
        expect(circuit(), same(before), reason: 'width $width');
        expect(tester.takeException(), isNull);
      }
      // Narrow: the chapter strip replaces the navigation.
      expect(find.byKey(_k('journey-chapter-strip')), findsOneWidget);
    });
  });

  group('Mastery', () {
    Future<void> mastery(WidgetTester tester) async {
      final progress = await _progress();
      await tester.pumpWidget(MaterialApp(
        theme: QubitQuestTheme.web(),
        home: Scaffold(
          body: WebMasteryWorkspace(
            progressController: progress,
            onBackToJourney: () {},
            onOpenNotebook: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('challenge 48: rail, search kept, whole-operator scope',
        (tester) async {
      await _size(tester, const Size(1500, 1000));
      await mastery(tester);
      final c48 = mastery2Catalogue.orderedDefinitions[47];
      await tester.enterText(find.byKey(_k('web-mastery-search')), 'Trace');
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(ValueKey('web-mastery-challenge-${c48.semanticId}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('web-mastery-start')));
      await tester.pumpAndSettle();
      final level = c48.levelDefinition as ComposerLevel;
      // A circuit challenge collapses the list to a numbered rail.
      expect(find.byKey(_k('web-mastery-rail')), findsOneWidget);
      expect(find.byKey(ValueKey('web-mastery-rail-${c48.semanticId}')),
          findsOneWidget);
      final note =
          tester.widget<Text>(find.byKey(_k('lesson-validation-scope'))).data!;
      if (level.validationMode == ValidationMode.unitary) {
        expect(note, contains('all ${1 << level.numQubits} basis inputs'));
      }
      expect(find.byKey(_k('web-lesson-check')), findsOneWidget);
      // Expanding the list shows the same, still-filtered search.
      await tester.tap(find.byKey(_k('web-mastery-rail-expand')));
      await tester.pumpAndSettle();
      final search =
          tester.widget<TextField>(find.byKey(_k('web-mastery-search')));
      expect(search.controller!.text, 'Trace');
      expect(find.byKey(ValueKey('web-mastery-challenge-${c48.semanticId}')),
          findsOneWidget);
      // Returning to the library keeps the query and the selection.
      await tester.tap(find.byKey(_k('web-mastery-back-overview')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-mastery-detail-title')), findsOneWidget);
      expect(find.text(c48.title), findsWidgets);
    });

    testWidgets('question challenge: lettered cards, no verdict before Check',
        (tester) async {
      await _size(tester, const Size(1500, 1000));
      await mastery(tester);
      final question = mastery2Catalogue.orderedDefinitions
          .firstWhere((c) => c.levelDefinition is McqLevel);
      await tester.tap(
          find.byKey(ValueKey('web-mastery-challenge-${question.semanticId}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('web-mastery-start')));
      await tester.pumpAndSettle();
      // The list stays beside a question challenge.
      expect(find.byKey(_k('web-mastery-pane')), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      final mcq = question.levelDefinition as McqLevel;
      final wrong = (mcq.correctOptionIndex + 1) % mcq.options.length;
      final option = find.byKey(ValueKey('web-lesson-option-$wrong'));
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      // Selection is not feedback.
      expect(find.byKey(_k('web-lesson-feedback')), findsNothing);
      await tester.tap(find.byKey(_k('web-lesson-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-lesson-feedback')), findsOneWidget);
      expect(find.text('Correct.'), findsNothing);
    });
  });

  group('validation scope wording', () {
    test('never suggests probabilities are sufficient', () {
      for (final mode in ValidationMode.values) {
        final note = validationScopeNote(mode, 3);
        expect(note, contains('not enough'));
      }
      expect(validationScopeNote(ValidationMode.finalState, 2),
          contains('including the global phase'));
      expect(validationScopeNote(ValidationMode.physicalState, 2),
          contains('up to a global phase'));
    });

    testWidgets('operator checks label the target as one input',
        (tester) async {
      final h = 1 / math.sqrt(2);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonStateComparison(
              currentState: [
                Complex(h, 0),
                Complex.zero(),
                Complex.zero(),
                Complex(h, 0)
              ],
              numQubits: 2,
              validationMode: ValidationMode.unitary,
              targetState: [
                Complex.one(),
                Complex.zero(),
                Complex.zero(),
                Complex.zero()
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('TARGET FOR THIS INPUT'), findsOneWidget);
      expect(find.byKey(_k('lesson-outcome-0')), findsOneWidget);
      expect(find.byKey(_k('lesson-outcome-3')), findsOneWidget);
      expect(find.byKey(_k('lesson-outcome-1')), findsNothing);
    });
  });

  group('Composer follow-ups', () {
    testWidgets('uniform states lead with |+⟩⊗n; details stay available',
        (tester) async {
      await _size(tester, const Size(1200, 1600));
      final u = 1 / math.sqrt(32);
      await tester.pumpWidget(MaterialApp(
        theme: QubitQuestTheme.web(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: QqCurrentStatePanel(
              stateVector: List.generate(32, (_) => Complex(u, 0)),
              numQubits: 5,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('state-compact-sum')), findsOneWidget);
      expect(find.text('⊗5'), findsOneWidget);
      // Expansion and table are collapsed but present.
      expect(find.byKey(_k('state-row-0')), findsNothing);
      await tester.tap(find.byKey(_k('state-table-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('state-row-0')), findsOneWidget);
      await tester.tap(find.byKey(_k('state-expanded-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('state-expression-wrapped')), findsOneWidget);
    });

    testWidgets('decimal sits beside its amplitude, not at the far edge',
        (tester) async {
      await _size(tester, const Size(1400, 900));
      final h = 1 / math.sqrt(2);
      await tester.pumpWidget(MaterialApp(
        theme: QubitQuestTheme.web(),
        home: Scaffold(
          body: SizedBox(
            width: 1100,
            child: QqCurrentStatePanel(
                stateVector: [Complex(h, 0), Complex(h, 0)], numQubits: 1),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final amp = tester.getRect(find.byKey(_k('state-amplitude-0')));
      final dec = tester.getRect(find.byKey(_k('state-decimal-0')));
      expect(dec.left - amp.right, lessThan(260));
      expect(tester.getRect(find.text('Decimal')).right, closeTo(dec.right, 1));
    });

    testWidgets('narrow palette: shared order, unavailable gates disabled',
        (tester) async {
      final gates = [
        Gate.fromIdentifier(SelectedGateType.cnot),
        Gate.fromIdentifier(SelectedGateType.x),
        Gate.fromIdentifier(SelectedGateType.hadamard),
      ];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ComposerGatePalette(
            gates: gates,
            numQubits: 1,
            embedded: true,
            onGateTap: (_) {},
            onInspectGate: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('palette-gate-unavailable-cnot')), findsOneWidget);
      final h = tester.getCenter(find.text('H')).dx;
      final x = tester.getCenter(find.text('X')).dx;
      expect(h, lessThan(x), reason: 'H before X, as in every palette');
    });

    testWidgets('embedded Bloch sphere labels its six poles', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: QqBlochSummaryPanel(
                alpha: Complex.one(),
                beta: Complex.zero(),
                camera: const BlochCamera(),
                onCameraChanged: (_) {},
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final panel =
          tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
      expect(panel.showStateLabels, isTrue);
    });
  });

  group('M11D.1 refinements', () {
    testWidgets('five-qubit circuit gets its full height; the page scrolls',
        (tester) async {
      await _size(tester, const Size(390, 844));
      final progress = await _progress();
      await _journey(tester, progress, lesson: 71);
      final well = tester.getSize(find.byKey(_k('composer-region-canvas')));
      final canvas = tester.getSize(find.byType(ComposerCircuitCanvas));
      // No capped well with the circuit scrolling inside it.
      expect(well.height, greaterThanOrEqualTo(canvas.height - 1));
      expect(well.height, greaterThan(300));
      // Narrow: the header scrolls with the work, the task label sits
      // above the text, and chapter progress appears only in the strip.
      expect(find.byKey(_k('journey-chapter-strip')), findsOneWidget);
      expect(find.byKey(_k('web-chapter-progress')), findsNothing);
      expect(find.byKey(_k('web-task-callout')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('target typeset like the current state, in target colour',
        (tester) async {
      final h = 1 / math.sqrt(2);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonStateComparison(
              currentState: [
                Complex.one(),
                Complex.zero(),
                Complex.zero(),
                Complex.zero()
              ],
              numQubits: 2,
              validationMode: ValidationMode.finalState,
              targetState: [
                Complex(h, 0),
                Complex.zero(),
                Complex.zero(),
                Complex(h, 0)
              ],
              targetExpression: '(|00> + |11>)/sqrt(2)',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final target = tester.widget<QqStateExpression>(
          find.byKey(_k('lesson-target-expression')));
      final current = tester
          .widgetList<QqStateExpression>(find.byType(QqStateExpression))
          .first;
      expect(target.style.fontSize, current.style.fontSize);
      expect(target.ketColor, QubitQuestColors.accentStrong);
      // Both probabilities are numbers, side by side.
      expect(find.byKey(_k('lesson-target-percent-3')), findsOneWidget);
      // A differently written authored form is kept beneath.
      expect(find.byKey(_k('lesson-target-authored')), findsOneWidget);
    });

    testWidgets('question: compact hints, sticky Check Answer only on request',
        (tester) async {
      await _size(tester, const Size(1500, 1000));
      final progress = await _progress();
      await tester.pumpWidget(MaterialApp(
        theme: QubitQuestTheme.web(),
        home: Scaffold(
          body: WebMasteryWorkspace(
            progressController: progress,
            onBackToJourney: () {},
            onOpenNotebook: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final question = mastery2Catalogue.orderedDefinitions.firstWhere((c) =>
          c.levelDefinition is McqLevel &&
          (c.levelDefinition.hints?.isNotEmpty ?? false));
      await tester.tap(
          find.byKey(ValueKey('web-mastery-challenge-${question.semanticId}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_k('web-mastery-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(_k('web-answer-actions')), findsOneWidget);
      final check = find.byKey(_k('web-lesson-confirm'));
      expect(tester.widget<ButtonStyleButton>(check).onPressed, isNull);
      final hints = find.byKey(_k('web-lesson-hints'));
      expect(hints, findsOneWidget);
      expect(tester.getSize(hints).height, lessThan(60),
          reason: 'a disclosure row, not a card');
      await tester.tap(find.text('Reveal authored hints'));
      await tester.pumpAndSettle();
      expect(tester.getSize(hints).height, greaterThan(60));
      await tester.tap(find.byKey(_k('web-lesson-option-0')));
      await tester.pumpAndSettle();
      expect(tester.widget<ButtonStyleButton>(check).onPressed, isNotNull);
      expect(find.byKey(_k('web-lesson-feedback')), findsNothing);
    });
  });

  test('classic exercise seam defaults to the learning layout', () {
    expect(debugClassicExerciseLayout, isFalse);
  });
}
