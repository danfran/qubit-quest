import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:quantumquiz/widgets/activity_instruction_presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/two_qubits_gate_target_qubit_selection_dialog.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/circuit_layout_metrics.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/screens/web_exercise_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_session_workspace.dart';

import 'support/mastery_math_test_platform.dart';
import 'support/journey_navigation.dart';

void main() {
  useMasteryMathTestPlatform();
  Future<CampaignProgressController> controllerWith(
      [CampaignProgressState? state]) async {
    final controller = CampaignProgressController(
      store: InMemoryCampaignProgressStore(state),
    );
    await controller.load();
    return controller;
  }

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpJourney(
    WidgetTester tester,
    CampaignProgressController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebJourneyWorkspace(
            progressController: controller,
            onOpenNotebook: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Journey opens a chapter and keeps locked lessons inaccessible',
      (tester) async {
    await setSize(tester, const Size(1280, 900));
    final controller = await controllerWith();
    await pumpJourney(tester, controller);

    await openJourneyChapter(tester, 1);
    await tester.pump();

    expect(find.byKey(const ValueKey('web-compact-activity-context')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-list-wide')), findsNothing);
    expect(find.byKey(const ValueKey('web-lesson-chooser')), findsOneWidget);
    expect(find.text('Lesson 1 of 5'), findsOneWidget);
    expect(find.text('0 / 5 complete'), findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-choice-1')), findsNothing);
    expect(find.byKey(const ValueKey('web-lesson-1')), findsOneWidget);
    expect(find.text(getQQLevelById(1)!.title!), findsOneWidget);
    expect(find.byKey(const ValueKey('web-compact-question')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-compact-task')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('web-compact-activity-context')),
            matching: find.byType(ActivityInstructionPresentation)),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-1-learning-brief')),
        findsNothing);

    // Longer authored guidance sits behind the context toggle (M6a), so
    // the objective stays compact above the workspace.
    expect(find.text(getQQLevelById(1)!.mysteryText!), findsNothing);
    await tester.tap(find.byKey(const ValueKey('web-activity-details-toggle')));
    await tester.pump();
    expect(find.text(getQQLevelById(1)!.mysteryText!), findsOneWidget);
    final description = tester.widget<Tooltip>(
      find.byKey(const ValueKey('web-chapter-description')),
    );
    expect(description.message, groupedLevels.first.categoryIntro);

    final activityWidth = tester
        .getSize(find.byKey(const ValueKey('web-chapter-activity')))
        .width;
    expect(activityWidth, greaterThan(1200));

    await tester.tap(find.byKey(const ValueKey('web-lesson-chooser')));
    await tester.pumpAndSettle();
    for (var levelId = 1; levelId <= 5; levelId++) {
      expect(
          find.byKey(ValueKey('web-lesson-choice-$levelId')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('web-lesson-choice-2')),
        warnIfMissed: false);
    await tester.pump();
    expect(find.byKey(const ValueKey('web-lesson-1')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('web-journey-back-map')));
    await tester.pump();
    // M5: returning lands on the Journey with the lesson's chapter selected.
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('journey-detail-title')))
            .data,
        'Information');
  });

  testWidgets('wide lesson chooser navigates to an unlocked lesson',
      (tester) async {
    await setSize(tester, const Size(1280, 900));
    final controller = await controllerWith(
      CampaignProgressState(
        maxUnlockedLevel: 2,
        completedLessonIds: const {1},
      ),
    );
    await pumpJourney(tester, controller);
    await openJourneyChapter(tester, 1);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('web-lesson-chooser')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-lesson-choice-2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('web-lesson-2')), findsOneWidget);
    expect(find.text('Lesson 2 of 5'), findsOneWidget);
    expect(find.text('1 / 5 complete'), findsOneWidget);
    expect(controller.state.maxUnlockedLevel, 2);
    expect(controller.state.completedLessonIds, const {1});
  });

  testWidgets('Lesson 2 uses the Journey workspace with its fixed X state',
      (tester) async {
    await setSize(tester, const Size(1280, 900));
    final controller = await controllerWith(
      CampaignProgressState(
        maxUnlockedLevel: 2,
        completedLessonIds: const {1},
      ),
    );
    await pumpJourney(tester, controller);
    await openJourneyChapter(tester, 1);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-lesson-chooser')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-lesson-choice-2')));
    await tester.pumpAndSettle();

    expect(find.text('Undo The Change'), findsOneWidget);
    // M6a: the shared desktop Composer workspace, in exercise mode.
    expect(find.byType(ComposerSessionWorkspace), findsOneWidget);
    expect(find.byType(WebComposerExercise), findsOneWidget);
    expect(find.byKey(const ValueKey('composer-region-results')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('quantum-inspector-view-selector')),
        findsOneWidget);
    expect(find.text('LIVE INSPECTOR'), findsNothing);
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('Updates as you build'), findsNothing);
    expect(
        find.text('Current state · updated from this circuit'), findsNothing);
    final canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    expect(canvas.circuit.logicalGates, hasLength(1));
    expect(canvas.circuit.logicalGates.single.gate.type, SelectedGateType.x);
    expect(canvas.circuit.logicalGates.single.isDeletable, isFalse);
    expect(canvas.markFixedGates, isTrue,
        reason: 'fixed operations are visibly marked');
    final state = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-composer-current-state')),
    );
    expect(state.stateVector[0].real, closeTo(0, 1e-9));
    expect(state.stateVector[1].real, closeTo(1, 1e-9));
    expect(find.byKey(const ValueKey('web-composer-target-state')),
        findsOneWidget);
    expect(find.text('Live outcome'), findsNothing);
    expect(controller.state.completedLessonIds, const {1});
    expect(controller.state.maxUnlockedLevel, 2);
  });

  testWidgets('full Journey Composer and choice instructions use shared roles',
      (tester) async {
    await setSize(tester, const Size(700, 900));
    for (final level in [
      getQQLevelById(2)!,
      allQQLevels.firstWhere((level) => level is McqLevel)
    ]) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: WebLessonWorkspace(
        key: ValueKey(level),
        levelId: 2,
        level: level,
        journeyActivity: true,
        alreadyCompleted: false,
        onCompleted: () async {},
        onNextLesson: () {},
        onBackToChapter: () {},
        onOpenNotebook: () {},
      ))));
      await tester.pumpAndSettle();
      final task = find.byWidgetPredicate((widget) =>
          widget is ActivityInstructionPresentation &&
          widget.task == level.taskDescription);
      expect(task, findsOneWidget);
      final presentation = tester.widget<ActivityInstructionPresentation>(task);
      expect(presentation.question, level.mysteryTitle);
      if (level is ComposerLevel) {
        expect(find.byKey(const ValueKey('web-lesson-check')), findsOneWidget);
      } else {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('web-lesson-confirm')),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
            find.byKey(const ValueKey('web-lesson-confirm')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('narrow chapter keeps the lesson chooser and shared canvas',
      (tester) async {
    await setSize(tester, const Size(700, 900));
    final controller = await controllerWith();
    await pumpJourney(tester, controller);
    await openJourneyChapter(tester, 1);
    await tester.pump();

    expect(find.byKey(const ValueKey('web-lesson-chooser')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-composer-canvas')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-check')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lesson 1 workspace shows live state before explicit completion',
      (tester) async {
    await setSize(tester, const Size(1300, 900));
    final level = getQQLevelById(1)! as ComposerLevel;
    final controller = await controllerWith();
    var completionCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebLessonWorkspace(
            levelId: 1,
            level: level,
            alreadyCompleted: false,
            onCompleted: () async {
              completionCalls++;
              await controller.completeLevel(1);
            },
            onNextLesson: () {},
            onBackToChapter: () {},
            onOpenNotebook: () {},
            journeyActivity: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(level.title, 'The First Qubit');
    expect(level.availableGates.map((gate) => gate.type), [SelectedGateType.x]);
    // M6a: the shared desktop workspace with palette, circuit, inspector
    // and results side by side, plus the exercise's action footer.
    expect(find.byKey(const ValueKey('web-exercise-workspace')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('composer-workspace-wide')),
        findsOneWidget);
    final paletteRegion =
        tester.getRect(find.byKey(const ValueKey('composer-region-palette')));
    final canvasRegion =
        tester.getRect(find.byKey(const ValueKey('composer-region-canvas')));
    final resultsRegion =
        tester.getRect(find.byKey(const ValueKey('composer-region-results')));
    expect(paletteRegion.right, lessThan(canvasRegion.left));
    expect(canvasRegion.right, lessThan(resultsRegion.left));
    final actions =
        tester.getRect(find.byKey(const ValueKey('web-exercise-actions')));
    expect(actions.top, greaterThanOrEqualTo(canvasRegion.bottom));
    expect(actions.bottom, lessThanOrEqualTo(900));
    expect(find.text('Concept'), findsNothing);
    expect(find.text('Task'), findsNothing);

    var canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    expect(
      canvas.surfaceTreatment,
      ComposerCircuitSurfaceTreatment.workbench,
    );
    final circuit = canvas.circuit;
    final initialRuns = circuit.simulationRunCount;
    var stateDisplay = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-composer-current-state')),
    );
    final targetDisplay = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-composer-target-state')),
    );
    expect(
      targetDisplay.stateVector,
      orderedEquals(level.solutionFinalVector.map((value) => value.first)),
    );
    expect(
        identical(stateDisplay.stateVector, circuit.currentState.stateVector),
        isTrue);
    expect(stateDisplay.stateVector[0].real, closeTo(1, 1e-9));
    expect(stateDisplay.stateVector[1].real, closeTo(0, 1e-9));

    final selector = find.byKey(
      const ValueKey('quantum-inspector-view-selector'),
    );
    await tester
        .tap(find.descendant(of: selector, matching: find.text('Bloch')));
    await tester.pump();
    var bloch = tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
    expect(bloch.interactive, isTrue);
    final stateBeforeDrag = circuit.currentState;
    final amplitudesBeforeDrag = List.of(stateBeforeDrag.stateVector);
    final yawBeforeDrag = bloch.camera.yaw;
    final sphere = find.byKey(const ValueKey('bloch-sphere-canvas'));
    await tester.ensureVisible(sphere);
    await tester.pumpAndSettle();
    final mouse = await tester.startGesture(tester.getCenter(sphere),
        kind: PointerDeviceKind.mouse);
    await mouse.moveBy(const Offset(20, 8));
    await tester.pump();
    await mouse.moveBy(const Offset(40, 18));
    await mouse.up();
    await tester.pumpAndSettle();
    bloch = tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
    expect(bloch.camera.yaw, isNot(yawBeforeDrag));
    expect(circuit.currentState, same(stateBeforeDrag));
    expect(
        circuit.currentState.stateVector, orderedEquals(amplitudesBeforeDrag));
    expect(bloch.state.z, closeTo(1, 1e-9));
    expect(identical(canvas.circuit, circuit), isTrue);
    expect(circuit.simulationRunCount, initialRuns);
    expect(completionCalls, 0);
    expect(controller.state.completedLessonIds, isEmpty);
    expect(find.text('Target'), findsOneWidget);

    await tester
        .tap(find.descendant(of: selector, matching: find.text('State')));
    await tester.pump();

    await canvas.onDropRequested(
      ComposerCircuitDropIntent(
        data: CircuitDragData.palette(
          Gate.fromIdentifier(SelectedGateType.x),
        ),
        destination: const CircuitDropDestination(
          contentPoint: Offset(40, 20),
          location: CircuitLocation(qubit: 0, column: 0),
        ),
      ),
    );
    await tester.pump();

    canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    stateDisplay = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-composer-current-state')),
    );
    expect(identical(canvas.circuit, circuit), isTrue);
    expect(circuit.simulationRunCount, initialRuns + 1);
    expect(stateDisplay.stateVector[0].real, closeTo(0, 1e-9));
    expect(stateDisplay.stateVector[1].real, closeTo(1, 1e-9));
    expect(completionCalls, 0);
    expect(controller.state.completedLessonIds, isEmpty);
    expect(controller.state.maxUnlockedLevel, 1);
    expect(find.byKey(const ValueKey('web-lesson-success')), findsNothing);

    await tester
        .tap(find.descendant(of: selector, matching: find.text('Bloch')));
    await tester.pump();
    bloch = tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
    expect(bloch.state.z, closeTo(-1, 1e-9));
    expect(circuit.simulationRunCount, initialRuns + 1);
    expect(completionCalls, 0);
    await tester
        .tap(find.descendant(of: selector, matching: find.text('State')));
    await tester.pump();

    // Offstage-aware: at medium width Results is the hidden view of the
    // Circuit/Results switch, but its state (the filter) is retained.
    final checkbox = find.descendant(
      of: find.byKey(const ValueKey('web-composer-current-state'),
          skipOffstage: false),
      matching: find.byType(Checkbox, skipOffstage: false),
    );
    await tester.tap(checkbox);
    await tester.pump();
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);

    await setSize(tester, const Size(700, 1000));
    await tester.pump();
    expect(
      identical(
        tester
            .widget<ComposerCircuitCanvas>(
              find.byType(ComposerCircuitCanvas),
            )
            .circuit,
        circuit,
      ),
      isTrue,
    );
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
    expect(circuit.simulationRunCount, initialRuns + 1);

    await setSize(tester, const Size(1300, 900));
    await tester.pump();
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
    expect(circuit.simulationRunCount, initialRuns + 1);

    // Check stays in the fixed action footer: no scrolling needed.
    await tester.tap(find.byKey(const ValueKey('web-lesson-check')));
    await tester.pumpAndSettle();

    expect(completionCalls, 1);
    expect(circuit.simulationRunCount, initialRuns + 2);
    expect(controller.state.completedLessonIds, contains(1));
    expect(controller.state.maxUnlockedLevel, 2);
    expect(
      find.byKey(const ValueKey('web-lesson-success'), skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('Lesson 1 at medium width switches Circuit and Results views',
      (tester) async {
    await setSize(tester, const Size(700, 1000));
    final level = getQQLevelById(1)! as ComposerLevel;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebLessonWorkspace(
            levelId: 1,
            level: level,
            alreadyCompleted: false,
            onCompleted: () async {},
            onNextLesson: () {},
            onBackToChapter: () {},
            onOpenNotebook: () {},
            journeyActivity: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('composer-workspace-medium')),
        findsOneWidget);
    // The objective (header) and Check (footer) frame the workspace.
    final header = tester.getRect(
        find.byKey(const ValueKey('web-lesson-content-1')));
    final workspace = tester.getRect(
        find.byKey(const ValueKey('web-exercise-workspace')));
    final actions =
        tester.getRect(find.byKey(const ValueKey('web-exercise-actions')));
    expect(header.bottom, lessThanOrEqualTo(workspace.top));
    expect(workspace.bottom, lessThanOrEqualTo(actions.top));
    expect(actions.bottom, lessThanOrEqualTo(1000));
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi-qubit Journey workspace shows every wire and its target',
      (tester) async {
    await setSize(tester, const Size(1300, 1000));
    final indexed = allQQLevels.indexed.firstWhere(
      (entry) =>
          entry.$2 is ComposerLevel &&
          (entry.$2 as ComposerLevel).numQubits > 1,
    );
    final level = indexed.$2 as ComposerLevel;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebLessonWorkspace(
            levelId: indexed.$1 + 1,
            level: level,
            alreadyCompleted: false,
            onCompleted: () async {},
            onNextLesson: () {},
            onBackToChapter: () {},
            onOpenNotebook: () {},
            journeyActivity: true,
          ),
        ),
      ),
    );
    await tester.pump();

    final canvas = tester.widget<ComposerCircuitCanvas>(
        find.byType(ComposerCircuitCanvas));
    expect(canvas.circuit.currentLevel.numQubits, level.numQubits);
    expect(
        tester.widget<Text>(
            find.byKey(const ValueKey('composer-circuit-summary'))).data,
        startsWith('${level.numQubits} qubits'));
    expect(find.byKey(const ValueKey('web-composer-target-state')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every web Composer activity uses the shared workspace',
      (tester) async {
    await setSize(tester, const Size(1300, 1000));
    final indexed = allQQLevels.indexed.firstWhere(
      (entry) => entry.$1 > 0 && entry.$2 is ComposerLevel,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebLessonWorkspace(
            levelId: indexed.$1 + 1,
            level: indexed.$2,
            alreadyCompleted: false,
            onCompleted: () async {},
            onNextLesson: () {},
            onBackToChapter: () {},
            onOpenNotebook: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Interactive Composer'), findsNothing);
    expect(find.byType(ComposerSessionWorkspace), findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-check')), findsOneWidget);
  });

  test('Composer Web validation delegates to the canonical level validator',
      () {
    final level = allQQLevels.whereType<ComposerLevel>().first;
    final canonical = buildCanonicalSolutionCircuit(level);
    final wrong = QuantumCircuit(currentLevel: level);

    expect(validateWebComposerLesson(level, canonical).success, isTrue);
    expect(validateWebComposerLesson(level, wrong).success, isFalse);

    canonical.dispose();
    wrong.dispose();
  });

  testWidgets('wrong Composer circuit stays editable and does not complete',
      (tester) async {
    await setSize(tester, const Size(1100, 1400));
    final level = allQQLevels.whereType<ComposerLevel>().first;
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebComposerExercise(
            level: level,
            mode: ComposerMode.journeyExercise,
            contextLabel: 'Lesson 1.1',
            onCompleted: () async => completed = true,
            onNext: () {},
            onOpenNotebook: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('web-lesson-check')));
    await tester.pump();

    expect(completed, isFalse);
    expect(find.textContaining('Not quite yet'), findsOneWidget);
    final state = tester.state<WebComposerExerciseState>(
        find.byType(WebComposerExercise));
    expect(state.session.readOnly, isFalse);
    expect(state.solved, isFalse);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('web-lesson-check')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('exercise palette offers exactly the level\'s gates',
      (tester) async {
    await setSize(tester, const Size(1100, 1200));
    final level = allQQLevels.whereType<ComposerLevel>().first;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebComposerExercise(
            level: level,
            mode: ComposerMode.journeyExercise,
            contextLabel: 'Lesson',
            onCompleted: () async {},
            onNext: () {},
            onOpenNotebook: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final palette = tester.widget<ComposerGatePalettePanel>(
      find.byType(ComposerGatePalettePanel),
    );
    expect(
      palette.gates.map((gate) => gate.type),
      level.availableGates.map((gate) => gate.type),
    );
    expect(palette.allowsMeasurement, isFalse);
  });

  testWidgets('Journey auto-selects the only valid controlled-gate role',
      (tester) async {
    await setSize(tester, const Size(1100, 1200));
    final level = allQQLevels.whereType<ComposerLevel>().firstWhere(
          (level) =>
              level.numQubits == 2 &&
              level.availableGates.any(
                (gate) => gate.type == SelectedGateType.cnot,
              ),
        );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebComposerExercise(
            level: level,
            mode: ComposerMode.journeyExercise,
            contextLabel: 'Lesson',
            onCompleted: () async {},
            onNext: () {},
            onOpenNotebook: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    var canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    await canvas.onDropRequested(
      ComposerCircuitDropIntent(
        data: CircuitDragData.palette(
          Gate.fromIdentifier(SelectedGateType.cnot),
        ),
        destination: const CircuitDropDestination(
          contentPoint: Offset(40, 60),
          location: CircuitLocation(qubit: 1, column: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(TwoQubitsGateTargetQubitSelectionDialog),
      findsNothing,
    );

    canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    final gate = canvas.circuit.logicalGates.single;
    expect(gate.type, SelectedGateType.cnot);
    expect(gate.targetQubit, 1);
    expect(gate.controlQubit, 0);
    expect(gate.hasValidTopology(level.numQubits), isTrue);
  });

  testWidgets('Web drop compacts an independent X beside a fixed X',
      (tester) async {
    await setSize(tester, const Size(1100, 900));
    final level = ComposerLevel(
      title: 'Independent alignment regression',
      taskDescription: 'Align independent gates.',
      numQubits: 2,
      initialQubitsStateStr: '00',
      initialQubitsState: ComposerLevel.getZeroStateVector(2),
      availableGates: [Gate.fromIdentifier(SelectedGateType.x)],
      solutionFinalVector: ComposerLevel.getOneStateVector(2)
          .map((amplitude) => [amplitude])
          .toList(),
      preInsertedGates: (circuit) {
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x),
          0,
          0,
          isDeletable: false,
        );
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebComposerExercise(
            level: level,
            mode: ComposerMode.journeyExercise,
            contextLabel: 'Lesson',
            onCompleted: () async {},
            onNext: () {},
            onOpenNotebook: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    var canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    final circuit = canvas.circuit;
    final fixed = circuit.logicalGates.single;
    final initialSimulationRuns = circuit.simulationRunCount;
    await canvas.onDropRequested(
      ComposerCircuitDropIntent(
        data: CircuitDragData.palette(
          Gate.fromIdentifier(SelectedGateType.x),
        ),
        destination: const CircuitDropDestination(
          contentPoint: Offset(240, 60),
          location: CircuitLocation(qubit: 1, column: 5),
        ),
      ),
    );
    await tester.pump();

    canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    final inserted = circuit.logicalGates.singleWhere(
      (gate) => gate.id != fixed.id,
    );
    expect(identical(canvas.circuit, circuit), isTrue);
    expect(fixed.column, 0);
    expect(inserted.column, 0);
    expect(circuit.placedGates[0].indexWhere((gate) => gate.id == fixed.id), 0);
    expect(
      circuit.placedGates[1].indexWhere((gate) => gate.id == inserted.id),
      0,
    );
    expect(inserted.fragments, hasLength(1));
    expect(inserted.occupiedLocations,
        [const CircuitLocation(qubit: 1, column: 0)]);
    expect(
      CircuitLayoutMetrics.slotCenter(fixed.anchor).dx,
      CircuitLayoutMetrics.slotCenter(inserted.anchor).dx,
    );
    expect(circuit.simulationRunCount, initialSimulationRuns + 1);
    expect(circuit.currentState.stateVector[3].real, closeTo(1, 1e-9));
  });

  testWidgets(
      'wrong answer does not progress; correct answer persists progress',
      (tester) async {
    await setSize(tester, const Size(1100, 1400));
    final indexed = allQQLevels.indexed.firstWhere(
      (entry) => entry.$2 is McqLevel && entry.$2.discoveryTitle != null,
    );
    final levelId = indexed.$1 + 1;
    final level = indexed.$2 as McqLevel;
    String? requestedNotebookEntry;
    final controller = await controllerWith(
      CampaignProgressState(maxUnlockedLevel: levelId),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebLessonWorkspace(
            levelId: levelId,
            level: level,
            alreadyCompleted: false,
            onCompleted: () => controller.completeLevel(levelId),
            onNextLesson: () {},
            onBackToChapter: () {},
            onOpenNotebook: () {},
            onOpenNotebookEntry: (title) => requestedNotebookEntry = title,
          ),
        ),
      ),
    );
    await tester.pump();

    final wrongIndex = level.correctOptionIndex == 0 ? 1 : 0;
    await tester
        .ensureVisible(find.byKey(ValueKey('web-lesson-option-$wrongIndex')));
    await tester.tap(find.byKey(ValueKey('web-lesson-option-$wrongIndex')));
    await tester.pump();
    await tester
        .ensureVisible(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.tap(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.pump();
    expect(controller.state.completedLessonIds.contains(levelId), isFalse);
    expect(find.byKey(const ValueKey('web-lesson-success')), findsNothing);

    await tester.ensureVisible(
      find.byKey(ValueKey('web-lesson-option-${level.correctOptionIndex}')),
    );
    await tester.tap(
        find.byKey(ValueKey('web-lesson-option-${level.correctOptionIndex}')));
    await tester.pump();
    await tester
        .ensureVisible(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.tap(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.pump();

    expect(controller.state.completedLessonIds.contains(levelId), isTrue);
    expect(controller.state.maxUnlockedLevel, greaterThan(levelId));
    expect(
      CampaignProgressPolicy.unlockedDiscoveryTitles(controller.state),
      contains(level.discoveryTitle),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('web-lesson-success'), skipOffstage: false),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('web-lesson-success'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('web-notebook-updated'), skipOffstage: false),
      findsOneWidget,
    );
    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('web-open-notebook'), skipOffstage: false),
        )
        .onPressed!();
    expect(requestedNotebookEntry, level.discoveryTitle);
  });

  testWidgets('Mastery answer uses shared challenge completion state',
      (tester) async {
    await setSize(tester, const Size(1100, 1400));
    final entry = numericActivityCatalogue.historicalMastery.entries.firstWhere(
      (entry) => entry.value is McqLevel,
    );
    final levelId = entry.key;
    final level = entry.value as McqLevel;
    final controller = await controllerWith(
      CampaignProgressState(
        maxUnlockedLevel: ProgressionRules.guidedDiscoveryLevelCount + 1,
        completedLessonIds: {
          for (int id = 1;
              id <= ProgressionRules.guidedDiscoveryLevelCount;
              id++)
            id,
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebLessonWorkspace(
            levelId: levelId,
            activityDomain: NumericActivityDomain.historicalMastery,
            level: level,
            alreadyCompleted: false,
            onCompleted: () => controller.completeChallenge(levelId),
            onNextLesson: () {},
            onBackToChapter: () {},
            onOpenNotebook: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(ValueKey('web-lesson-option-${level.correctOptionIndex}')),
    );
    await tester.tap(
        find.byKey(ValueKey('web-lesson-option-${level.correctOptionIndex}')));
    await tester.pump();
    await tester
        .ensureVisible(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.tap(find.byKey(const ValueKey('web-lesson-confirm')));
    await tester.pump();

    expect(controller.state.completedChallengeIds, contains(levelId));
    expect(
      find.byKey(const ValueKey('web-lesson-success'), skipOffstage: false),
      findsOneWidget,
    );
  });
}
