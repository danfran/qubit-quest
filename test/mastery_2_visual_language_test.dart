import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/screens/mcq_screen.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/mastery_evidence_view.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/mastery_math_test_platform.dart';

void main() {
  useMasteryMathTestPlatform();
  Future<void> pumpEvidence(
    WidgetTester tester,
    MasteryChallengePresentation presentation, {
    Size size = const Size(320, 700),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MasteryEvidenceView(presentation: presentation),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  MasteryCircuitEvidence circuit(String semanticId, [int index = 0]) =>
      mastery2Presentations[semanticId]!
          .evidence
          .whereType<MasteryCircuitEvidence>()
          .elementAt(index);

  Future<void> pumpMasteryScreen(
    WidgetTester tester,
    String semanticId,
    Size size,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final definition = mastery2Catalogue.requireBySemanticId(semanticId);
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: LevelUIRouter.buildLevelUI(
          level: definition.levelDefinition,
          levelId: definition.displayOrder,
          masteryChallenge: definition,
          onLevelUnlocked: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpJourneyComposer(WidgetTester tester, Size size,
      {int qubitCount = 1}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final indexedLevel = allQQLevels.asMap().entries.firstWhere(
          (entry) =>
              entry.key < 60 &&
              entry.value is ComposerLevel &&
              (entry.value as ComposerLevel).numQubits == qubitCount,
        );
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: LevelUIRouter.buildLevelUI(
          level: indexedLevel.value,
          levelId: indexedLevel.key + 1,
          masteryChallenge: null,
          onLevelUnlocked: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('static circuit evidence', () {
    testWidgets(
        'one-qubit sequence uses the production painter without editor chrome',
        (tester) async {
      final presentation =
          mastery2Presentations['phase_accumulation_prediction']!;
      await pumpEvidence(tester, presentation);

      expect(find.byType(QubitQuestStaticCircuit), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is QuantumCircuitPainter,
        ),
        findsOneWidget,
      );
      expect(find.byType(ComposerCircuitCanvas), findsNothing);
      expect(find.byType(Draggable), findsNothing);
      expect(tester.takeException(), isNull);

      final evidence = circuit('phase_accumulation_prediction');
      expect(evidence.operations.map((step) => step.gateType.name),
          ['hadamard', 't', 's']);
    });

    testWidgets(
        'controlled and fan-out circuits preserve topology at narrow width',
        (tester) async {
      final fanout = mastery2Presentations['fanout_is_not_cloning']!;
      await pumpEvidence(tester, fanout);

      final evidence = circuit('fanout_is_not_cloning');
      expect(evidence.qubitCount, 3);
      expect(evidence.operations, hasLength(2));
      expect(evidence.operations[0].controlQubit, 0);
      expect(evidence.operations[0].targetQubit, 1);
      expect(evidence.operations[1].controlQubit, 0);
      expect(evidence.operations[1].targetQubit, 2);
      expect(tester.takeException(), isNull);

      final controlled = circuit('phase_kickback_conditions');
      expect(controlled.operations.single.controlQubit, 0);
      expect(controlled.operations.single.targetQubit, 1);
    });

    testWidgets('complete static circuit canvas is centred when it fits',
        (tester) async {
      await pumpEvidence(
        tester,
        mastery2Presentations['fanout_is_not_cloning']!,
        size: const Size(600, 700),
      );

      final surfaceRect = tester.getRect(
        find.byKey(const ValueKey('mastery-evidence-block-0')),
      );
      final canvasRect = tester.getRect(
        find.byKey(const ValueKey('circuit-preview-canvas')),
      );
      expect(
        (surfaceRect.center.dx - canvasRect.center.dx).abs(),
        lessThan(1),
      );
      expect(find.byKey(const ValueKey('centered-circuit-preview')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('wire labels retain q0-top Q0-LSB convention', () {
      expect(
        QuantumCircuitPainter.initialQubitLabelsFor(
          initialQubitsStateStr: '10',
          numQubits: 2,
        ),
        ['q0 |0⟩', 'q1 |1⟩'],
      );
      expect(
        QuantumCircuitPainter.initialQubitLabelsFor(
          initialQubitsStateStr: '101',
          numQubits: 3,
        ),
        ['q0 |1⟩', 'q1 |0⟩', 'q2 |1⟩'],
      );
    });

    testWidgets('static circuit exposes a concise semantic description',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final presentation = mastery2Presentations['ghz_broken_link']!;
      await pumpEvidence(tester, presentation);
      expect(
        find.bySemanticsLabel(
          'Broken GHZ circuit: H on q0, CNOT q0 to q1, then CNOT q2 to q1.',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('math and structured evidence', () {
    testWidgets('standalone state comparison is centred as one group',
        (tester) async {
      await pumpEvidence(
        tester,
        mastery2Presentations['global_phase_equivalence']!,
        size: const Size(390, 844),
      );

      final region = tester.getRect(
        find.byKey(const ValueKey('mastery-math-centering-region')),
      );
      final math = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('mastery-math-centered-group')),
          matching: find.byType(LatexText),
        ),
      );
      expect((region.center.dx - math.center.dx).abs(), lessThan(2));
      expect(tester.takeException(), isNull);
    });

    test('representative evidence uses delimited structured mathematics', () {
      final global = mastery2Presentations['global_phase_equivalence']!
          .evidence
          .whereType<MasteryMathEvidence>()
          .single;
      final fanout = mastery2Presentations['fanout_is_not_cloning']!
          .evidence
          .whereType<MasteryMathEvidence>()
          .last;
      final search = mastery2Presentations['search_pipeline_forensics']!
          .evidence
          .whereType<MasteryMathEvidence>()
          .last;

      expect(global.expression, contains(r'\[|1\rangle'));
      expect(fanout.expression, contains(r'\tfrac'));
      expect(fanout.expression, contains(r'\to'));
      expect(search.expression, contains(r'\sqrt8'));
      for (final expression in [
        global.expression,
        fanout.expression,
        search.expression
      ]) {
        expect(expression, isNot(contains('|000>')));
        expect(expression, isNot(contains('[?]')));
      }
    });

    testWidgets('math evidence is placed in a horizontally safe viewport',
        (tester) async {
      await pumpEvidence(
        tester,
        mastery2Presentations['fanout_is_not_cloning']!,
      );
      expect(find.byKey(const ValueKey('mastery-math-evidence')),
          findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('mastery-math-evidence')),
          matching: find.byType(LatexText),
        ),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'short cases use whitespace grouping and one compact math scale',
        (tester) async {
      await pumpEvidence(
        tester,
        mastery2Presentations['fanout_is_not_cloning']!,
      );

      // The substantial circuit keeps one diagram surface. CASE A and CASE B
      // are not each wrapped in another bordered panel.
      expect(find.byType(QubitQuestPanel), findsOneWidget);
      expect(find.text('CASE A'), findsOneWidget);
      expect(find.text('CASE B'), findsOneWidget);

      final circuitPanel = tester.widget<QubitQuestPanel>(
        find.byType(QubitQuestPanel),
      );
      expect(
        circuitPanel.padding,
        const EdgeInsets.symmetric(
          horizontal: QubitQuestSpacing.regular,
          vertical: QubitQuestSpacing.compact,
        ),
      );

      final mathWidgets = tester.widgetList<LatexText>(
        find.descendant(
          of: find.byKey(const ValueKey('mastery-math-evidence')),
          matching: find.byType(LatexText),
        ),
      );
      expect(mathWidgets, hasLength(2));
      final simpleKet = mathWidgets.first;
      final fraction = mathWidgets.last;
      expect(
        simpleKet.displayMathHeight,
        MasteryEvidenceView.normalMathDisplayHeight,
      );
      expect(
        fraction.displayMathHeight,
        MasteryEvidenceView.stackedMathDisplayHeight,
      );
      expect(fraction.math, contains(r'\frac'));
      expect(fraction.math, isNot(contains(r'\tfrac')));
      expect(fraction.displayMathHeight, greaterThanOrEqualTo(30));
      for (final math in [simpleKet, fraction]) {
        expect(
          math.inlineMathHeight,
          MasteryEvidenceView.normalMathInlineHeight,
        );
        expect(
            math.textStyle,
            QubitQuestTypography.body.copyWith(
              color: QubitQuestColors.textPrimary,
              fontWeight: FontWeight.w600,
            ));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Bell input and long fractions retain readable display scale',
        (tester) async {
      for (final semanticId in [
        'bell_decoder_bug',
        'fanout_is_not_cloning',
        'search_pipeline_forensics',
      ]) {
        await pumpEvidence(
          tester,
          mastery2Presentations[semanticId]!,
          size: const Size(390, 844),
        );
        final fractionMath = tester
            .widgetList<LatexText>(
              find.descendant(
                of: find.byKey(const ValueKey('mastery-math-evidence')),
                matching: find.byType(LatexText),
              ),
            )
            .where((widget) => widget.math.contains(r'\frac'));
        expect(fractionMath, isNotEmpty, reason: semanticId);
        for (final math in fractionMath) {
          expect(
            math.displayMathHeight,
            MasteryEvidenceView.stackedMathDisplayHeight,
            reason: semanticId,
          );
        }
        expect(tester.takeException(), isNull, reason: semanticId);
      }
    });

    testWidgets('ket convention remains helper prose with inline subscripts',
        (tester) async {
      await pumpEvidence(
        tester,
        mastery2Presentations['fanout_is_not_cloning']!,
      );

      final helper = tester.widget<LatexText>(
        find.byKey(const ValueKey('mastery-evidence-helper')),
      );
      expect(helper.math, startsWith('Kets: '));
      expect(helper.math, contains(r'\(\lvert q_{2}\,q_{1}\,q_{0}\rangle\)'));
      expect(helper.math, isNot(contains(r'\[')));
      expect(helper.textStyle, QubitQuestTypography.supporting);
      expect(tester.takeException(), isNull);
    });

    test('every selectable challenge has authored visual presentation', () {
      final selectableIds = mastery2Catalogue.orderedDefinitions
          .where((definition) => definition.levelDefinition is McqLevel)
          .map((definition) => definition.semanticId)
          .toSet();
      expect(mastery2Presentations.keys.toSet(), {
        ...selectableIds,
        'bell_input_sign_preparation',
        'ghz_phase_manipulation',
        'inverse_phase_synthesis',
      });
    });
  });

  group('Composer state panel geometry', () {
    testWidgets('Journey portrait uses shared content-driven state panels',
        (tester) async {
      const viewport = Size(390, 844);
      await pumpJourneyComposer(tester, viewport);

      final currentFinder =
          find.byKey(const ValueKey('composer-current-state-panel'));
      final targetFinder =
          find.byKey(const ValueKey('composer-target-state-panel'));
      final current = tester.getRect(currentFinder);
      final target = tester.getRect(targetFinder);
      for (final panel in [current, target]) {
        expect(panel.height, greaterThan(60));
        expect(panel.height, lessThan(viewport.height * 0.25));
      }
      expect(current.height + target.height, lessThan(viewport.height * 0.5));
      expect(
        tester
            .widgetList<StateVectorDisplay>(find.byType(StateVectorDisplay))
            .every((display) => display.contentDriven),
        isTrue,
      );
      expect(
        find.descendant(of: currentFinder, matching: find.byType(Scrollbar)),
        findsNothing,
      );
      expect(
        find.descendant(of: targetFinder, matching: find.byType(Scrollbar)),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('portrait-composer-page-scroll')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('portrait-state-section-scroll')),
          findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Journey portrait scrolls the page instead of state panels',
        (tester) async {
      await pumpJourneyComposer(
        tester,
        const Size(390, 560),
        qubitCount: 3,
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      final pageScroll =
          find.byKey(const ValueKey('portrait-composer-page-scroll'));
      final scrollable = find
          .descendant(
            of: pageScroll,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          )
          .first;
      expect(scrollable, findsOneWidget);
      expect(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        greaterThan(0),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('portrait-state-section')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('one-qubit portrait panels size to their content',
        (tester) async {
      await pumpMasteryScreen(
        tester,
        'phase_state_uncomputation',
        const Size(390, 844),
      );

      final current = tester.getRect(
        find.byKey(const ValueKey('composer-current-state-panel')),
      );
      final target = tester.getRect(
        find.byKey(const ValueKey('composer-target-state-panel')),
      );
      for (final panel in [current, target]) {
        expect(panel.height, greaterThan(60));
        expect(panel.height, lessThan(150));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('multi-qubit portrait state defaults filtered and scroll-safe',
        (tester) async {
      await pumpMasteryScreen(
        tester,
        'ghz_phase_manipulation',
        const Size(390, 900),
      );

      final current = tester.getRect(
        find.byKey(const ValueKey('composer-current-state-panel')),
      );
      expect(current.height, greaterThan(60));
      expect(current.height, lessThan(150));
      final stateDisplays = tester.widgetList<StateVectorDisplay>(
        find.byType(StateVectorDisplay),
      );
      expect(stateDisplays, hasLength(2));
      expect(
        stateDisplays.every((display) => display.nonZeroOnlyOverride == true),
        isTrue,
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      tester.view.physicalSize = const Size(391, 900);
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(
        tester
            .widgetList<StateVectorDisplay>(find.byType(StateVectorDisplay))
            .every((display) => display.nonZeroOnlyOverride == false),
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('portrait-composer-page-scroll')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('portrait-state-section-scroll')),
          findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape keeps bounded current and target result panels',
        (tester) async {
      await pumpMasteryScreen(
        tester,
        'phase_state_uncomputation',
        const Size(844, 390),
      );

      final current = tester.getRect(
        find.byKey(const ValueKey('composer-current-state-panel')),
      );
      final target = tester.getRect(
        find.byKey(const ValueKey('composer-target-state-panel')),
      );
      expect(current.height, greaterThan(40));
      expect(target.height, greaterThan(40));
      expect(current.bottom, lessThanOrEqualTo(390));
      expect(target.bottom, lessThanOrEqualTo(390));
      expect(
        tester
            .widgetList<StateVectorDisplay>(find.byType(StateVectorDisplay))
            .every((display) => !display.contentDriven),
        isTrue,
      );
      expect(find.byType(Scrollbar), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('compact concept check keeps selection, mapping, and feedback',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    final definition = mastery2Catalogue.requireBySemanticId(
      'reversible_cancellation_trace',
    );
    final level = definition.levelDefinition as McqLevel;
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: McqScreen(
          levelId: definition.displayOrder,
          level: level,
          masteryChallenge: definition,
          onLevelUnlocked: null,
        ),
      ),
    );
    await tester.pump();

    final question = tester.widget<LatexText>(
      find
          .descendant(
            of: find.byKey(const ValueKey('m2-activity-question')),
            matching: find.byType(LatexText),
          )
          .last,
    );
    expect(question.textStyle!.fontSize, 16.5);

    final correct =
        find.byKey(ValueKey('mcq-option-${level.correctOptionIndex}'));
    final verticalScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;
    await tester.scrollUntilVisible(
      correct,
      180,
      scrollable: verticalScroll,
    );
    await tester.tap(correct);
    final confirm = find.byKey(const ValueKey('m2-primary-action'));
    await tester.scrollUntilVisible(
      confirm,
      180,
      scrollable: verticalScroll,
    );
    await tester.pump();
    await tester.tap(confirm);
    await tester.pump();

    expect(find.byKey(const ValueKey('m2-answer-feedback')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long answer remains usable at narrow width and 1.3x text scale',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    final definition = mastery2Catalogue.requireBySemanticId(
      'same_histogram_different_state',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: QubitQuestTheme.mobile(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.3),
          ),
          child: McqScreen(
            levelId: definition.displayOrder,
            level: definition.levelDefinition as McqLevel,
            masteryChallenge: definition,
            onLevelUnlocked: null,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('mastery-evidence-view')), findsOneWidget);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -1800),
      6000,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mcq-option-3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('catalogue identity and interaction metadata remain intact', () {
    expect(mastery2Catalogue.length, 36);
    for (final definition in mastery2Catalogue.orderedDefinitions) {
      expect(definition.displayOrder, inInclusiveRange(1, 36));
      expect(definition.semanticId, isNotEmpty);
      expect(definition.interactionType, isA<MasteryInteractionType>());
    }
  });
}
