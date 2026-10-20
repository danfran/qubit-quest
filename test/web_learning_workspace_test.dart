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
import 'package:quantumquiz/widgets/composer_gate_palette.dart';
import 'package:quantumquiz/widgets/circuit_canvas_metrics.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/circuit_layout_metrics.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/widgets/quantum_workspace_layout.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';
import 'package:quantumquiz/widgets/web_composer_workbench.dart';

import 'support/mastery_math_test_platform.dart';

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

    await tester.tap(find.text('Chapter 1 — Information'));
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

    // The shared context includes the authored guidance at both widths.
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
    expect(find.text('Chapter 1 — Information'), findsOneWidget);
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
    await tester.tap(find.text('Chapter 1 — Information'));
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
    await tester.tap(find.text('Chapter 1 — Information'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-lesson-chooser')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-lesson-choice-2')));
    await tester.pumpAndSettle();

    expect(find.text('Undo The Change'), findsOneWidget);
    expect(find.byType(QuantumWorkspaceLayout), findsOneWidget);
    expect(find.byType(WebComposerWorkbench), findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-live-inspector')),
        findsOneWidget);
    expect(find.text('INSPECTOR'), findsOneWidget);
    expect(find.text('State'), findsOneWidget);
    expect(find.text('Bloch'), findsOneWidget);
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
    final state = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-lesson-current-state')),
    );
    expect(state.stateVector[0].real, closeTo(0, 1e-9));
    expect(state.stateVector[1].real, closeTo(1, 1e-9));
    expect(
        find.byKey(const ValueKey('web-lesson-target-state')), findsOneWidget);
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

  testWidgets('narrow chapter uses stacked lesson navigation', (tester) async {
    await setSize(tester, const Size(700, 900));
    final controller = await controllerWith();
    await pumpJourney(tester, controller);
    await tester.tap(find.text('Chapter 1 — Information'));
    await tester.pump();

    expect(
        find.byKey(const ValueKey('web-lesson-list-narrow')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-composer-canvas')),
        findsOneWidget);
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
    expect(
      find.byKey(const ValueKey('web-lesson-1-quantum-workspace')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quantum-workspace-wide-layout')),
      findsOneWidget,
    );
    final primaryPane = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-primary-pane')),
    );
    final inspectorPane = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-inspection-pane')),
    );
    expect(primaryPane.right, lessThan(inspectorPane.left));
    expect(primaryPane.width, greaterThan(inspectorPane.width));
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('web-lesson-composer-canvas')),
          )
          .height,
      lessThanOrEqualTo(100),
    );
    final circuitStage = tester.getRect(
      find.byKey(const ValueKey('web-lesson-circuit-stage')),
    );
    final circuitCanvas = tester.getRect(
      find.byKey(const ValueKey('web-lesson-composer-canvas')),
    );
    expect(circuitStage.height, greaterThan(circuitCanvas.height + 50));
    expect(circuitCanvas.center.dy, closeTo(circuitStage.center.dy, 1));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('quantum-workspace-main-row')))
          .height,
      WebCircuitWorkbenchMetrics.calculate(
        qubitCount: 1,
        hasTargetState: true,
      ).mainRowHeight,
    );
    expect(find.text('Concept'), findsNothing);
    expect(find.text('Task'), findsNothing);

    var canvas = tester.widget<ComposerCircuitCanvas>(
      find.byType(ComposerCircuitCanvas),
    );
    expect(
      canvas.surfaceTreatment,
      ComposerCircuitSurfaceTreatment.workbench,
    );
    expect(
      find.byKey(const ValueKey('circuit-workbench-surface')),
      findsOneWidget,
    );
    final circuit = canvas.circuit;
    final initialRuns = circuit.simulationRunCount;
    var stateDisplay = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-lesson-current-state')),
    );
    final targetDisplay = tester.widget<StateVectorDisplay>(
      find.byKey(const ValueKey('web-lesson-target-state')),
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
      find.byKey(const ValueKey('web-lesson-current-state')),
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

    final checkbox = find.descendant(
      of: find.byKey(const ValueKey('web-lesson-current-state')),
      matching: find.byType(Checkbox),
    );
    await tester.tap(checkbox);
    await tester.pump();
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);

    await setSize(tester, const Size(700, 1000));
    await tester.pump();
    expect(
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .surfaceTreatment,
      ComposerCircuitSurfaceTreatment.inset,
    );
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

    await tester.drag(
      find.byKey(const ValueKey('web-lesson-content-1')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
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

  testWidgets('Lesson 1 workspace stacks Circuit Gates State and actions',
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

    final circuit = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-primary-pane')),
    );
    final toolbar = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-toolbar')),
    );
    final inspector = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-inspection-pane')),
    );
    final actions = tester.getRect(
      find.byKey(const ValueKey('quantum-workspace-contextual-actions')),
    );
    expect(circuit.bottom, lessThanOrEqualTo(toolbar.top));
    expect(toolbar.bottom, lessThanOrEqualTo(inspector.top));
    expect(inspector.bottom, lessThanOrEqualTo(actions.top));
    expect(
      tester
          .widget<StateVectorDisplay>(
            find.byKey(const ValueKey('web-lesson-current-state')),
          )
          .contentDriven,
      isTrue,
    );
    tester
        .widget<SegmentedButton<QuantumInspectorView>>(
          find.byKey(const ValueKey('quantum-inspector-view-selector')),
        )
        .onSelectionChanged!
        .call({QuantumInspectorView.bloch});
    await tester.pump();
    final sphere = tester.getRect(find.byType(BlochSpherePanel));
    expect(sphere.width, lessThanOrEqualTo(inspector.width));
    expect(sphere.height, lessThanOrEqualTo(280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi-qubit Journey workspace centers the circuit group',
      (tester) async {
    await setSize(tester, const Size(1300, 1000));
    final indexed = allQQLevels.indexed.firstWhere(
      (entry) =>
          entry.$2 is ComposerLevel &&
          (entry.$2 as ComposerLevel).numQubits > 1,
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
            journeyActivity: true,
          ),
        ),
      ),
    );
    await tester.pump();

    final stage = tester.getRect(
      find.byKey(const ValueKey('web-lesson-circuit-stage')),
    );
    final canvas = tester.getRect(
      find.byKey(const ValueKey('web-lesson-composer-canvas')),
    );
    expect(canvas.center.dy, closeTo(stage.center.dy, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-Journey Composer callers retain the legacy presentation',
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

    expect(find.text('Interactive Composer'), findsOneWidget);
    expect(find.byType(QuantumWorkspaceLayout), findsNothing);
    expect(find.byType(StateVectorDisplay), findsNothing);
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
          body: WebComposerLesson(
            level: level,
            enabled: true,
            onSolved: () async => completed = true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('web-lesson-check')));
    await tester.pump();

    expect(completed, isFalse);
    expect(find.textContaining('Not quite yet'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('web-lesson-check')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Journey Composer renders canonical canvas before gate palette',
      (tester) async {
    await setSize(tester, const Size(1100, 1200));
    final level = allQQLevels.whereType<ComposerLevel>().first;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebComposerLesson(
            level: level,
            enabled: true,
            onSolved: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final palette = tester.widget<ComposerGatePalette>(
      find.byType(ComposerGatePalette),
    );
    expect(
      palette.gates.map((gate) => gate.type),
      level.availableGates.map((gate) => gate.type),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('web-lesson-composer-canvas')),
          )
          .dy,
      lessThan(tester.getTopLeft(find.byType(ComposerGatePalette)).dy),
    );
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
          body: WebComposerLesson(
            level: level,
            enabled: true,
            onSolved: () async {},
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
          body: WebComposerLesson(
            level: level,
            enabled: true,
            onSolved: () async {},
            desktopWorkspace: true,
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
