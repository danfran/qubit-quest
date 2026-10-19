import 'package:quantumquiz/models/progression_rules.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/widgets/level_header_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives [QuantumComposer] through the same gesture, dialog, simulation, and
/// Check Result surfaces used by a learner.
///
/// Canonical metadata is used only as the script. The solved circuit is never
/// built separately and injected into the widget.
class CampaignIntegrationHarness {
  CampaignIntegrationHarness(this.tester);

  final WidgetTester tester;

  late ComposerLevel level;
  late int levelId;
  late CampaignProgressController progress;
  late QuantumComposerController composerController;
  final unlockedLevels = <int>[];
  final _completionWrites = <Future<void>>[];
  int _nextColumn = 0;

  Finder get circuitSurface =>
      find.byKey(const ValueKey('circuit-interaction-surface'));

  Future<void> loadLevel(
    int id,
    ComposerLevel composerLevel, {
    Size viewport = const Size(900, 1200),
    CampaignProgressController? progressController,
    bool resetPreferences = true,
  }) async {
    levelId = id;
    level = composerLevel;
    if (resetPreferences) SharedPreferences.setMockInitialValues({});
    progress = progressController ?? CampaignProgressController();
    if (!progress.isLoaded) await progress.load();
    composerController = QuantumComposerController();

    // This detached instance is used only to discover the runtime depth of the
    // level's fixed starting content. The widget creates and owns its own real
    // circuit; no state from this instance is injected.
    final initial = QuantumCircuit(currentLevel: level);
    _nextColumn = initial.maxCircuitDepth();

    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: QuantumComposer(
          key: ValueKey('campaign-composer-$id'),
          levelId: id,
          activityDomain: id >= ProgressionRules.legacyMasteryFirstId
              ? NumericActivityDomain.historicalMastery
              : NumericActivityDomain.journey,
          level: level,
          controller: composerController,
          onLevelUnlocked: (nextLevel) {
            unlockedLevels.add(nextLevel);
            final write = LevelHeaderRouter.isMasteryLevel(id)
                ? progress.completeChallenge(id)
                : progress.completeLesson(id);
            _completionWrites.add(write);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final start = find.text('Start Composing');
    if (start.evaluate().isNotEmpty) {
      await tester.tap(start);
      await tester.pumpAndSettle();
    }

    expect(circuitSurface, findsOneWidget,
        reason: diagnostic('Composer did not build its circuit surface'));
    expect(find.text('Current State'), findsWidgets,
        reason: diagnostic('Current State was not rendered'));
    expect(find.text('Target State'), findsWidgets,
        reason: diagnostic('Target State was not rendered'));
  }

  Future<void> applyCanonicalSolution() async {
    final solution = level.canonicalSolution;
    expect(solution, isNotNull,
        reason: diagnostic('Level has no canonical solution'));
    for (final step in solution!.steps) {
      await insertStep(step);
    }
  }

  Future<void> insertStep(CanonicalCircuitStep step) async {
    final outcome = composerController.insertGate(
      gate: Gate.fromIdentifier(step.gateType, angle: step.angle),
      location: CircuitLocation(
        qubit: step.targetQubit,
        column: _nextColumn,
      ),
      controlQubit: step.controlQubit,
      secondControlQubit: step.secondControlQubit,
    );
    expect(outcome.changed, isTrue,
        reason: diagnostic(
          'Production Composer insertion returned ${outcome.status.name}: '
          '${outcome.detail ?? ''}',
          step,
        ));
    _nextColumn++;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason:
            diagnostic('Editing threw while applying canonical step', step));
  }

  /// Gesture-level counterpart used by the smaller interaction suite.
  Future<void> insertStepWithGesture(CanonicalCircuitStep step) async {
    final paletteGate = find.byWidgetPredicate(
      (widget) =>
          widget is Draggable<CircuitDragData> &&
          widget.data?.isPlaced == false &&
          widget.data?.gate.type == step.gateType,
      description: 'palette ${step.gateType.name} drag source',
    );
    expect(paletteGate, findsOneWidget,
        reason: diagnostic('Canonical gate is absent from the palette', step));
    final paletteData =
        tester.widget<Draggable<CircuitDragData>>(paletteGate).data!;
    await tester.ensureVisible(paletteGate);
    await tester.pumpAndSettle();

    final source = tester.getCenter(paletteGate);
    final childAnchor = source - tester.getTopLeft(paletteGate);
    final feedbackDestination = await _visibleCircuitPoint(
      qubit: step.targetQubit,
      column: _nextColumn,
    );
    // Draggable reports the feedback origin to DragTarget. Preserve the normal
    // palette child anchor so that origin lands on the intended circuit cell.
    await tester.timedDragFrom(
      source,
      feedbackDestination + childAnchor - source,
      const Duration(milliseconds: 300),
    );
    await tester.pump();

    if (_isRotation(step.gateType) && paletteData.gate.angle == null) {
      await _configureRotation(step);
    } else if (step.gateType == SelectedGateType.ccnot) {
      await _configureToffoli(step);
    } else if (_isControlled(step.gateType) && level.numQubits > 2) {
      await _configureControlled(step);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason:
            diagnostic('Editing threw while applying canonical step', step));
    _nextColumn++;
  }

  Future<Offset> _visibleCircuitPoint({
    required int qubit,
    required int column,
  }) async {
    final horizontalScroll = find.descendant(
      of: find.byKey(const ValueKey('circuit-horizontal-scroll')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(horizontalScroll).position;
    final contentX = 40.0 + column * 40.0;
    final viewport = tester.getRect(circuitSurface);
    final wantedOffset = math.max(0.0, contentX - viewport.width + 70.0);
    position.jumpTo(wantedOffset.clamp(0.0, position.maxScrollExtent));
    await tester.pump();
    final visibleX = contentX - position.pixels;
    return tester.getTopLeft(circuitSurface) +
        Offset(visibleX, 2.0 + qubit * 40.0);
  }

  Future<void> _configureRotation(CanonicalCircuitStep step) async {
    expect(find.byType(Dialog), findsWidgets,
        reason: diagnostic('Rotation picker did not open', step));
    final angle = step.angle!;
    const denominators = [1, 2, 3, 4, 5, 6, 7, 8, 9, 16];
    int? numerator;
    int? denominator;
    for (final candidate in denominators) {
      final scaled = angle / math.pi * candidate;
      if ((scaled - scaled.round()).abs() <= 1e-9) {
        numerator = scaled.round();
        denominator = candidate;
        break;
      }
    }
    if (denominator != null) {
      await tester.enterText(
          find.byKey(const ValueKey('fractional-angle-numerator')),
          '$numerator');
      await tester.enterText(
          find.byKey(const ValueKey('fractional-angle-denominator')),
          '$denominator');
    } else {
      await tester.tap(find.text('Numerical (rad)'));
      await tester.pump();
      await tester.enterText(
          find.byKey(const ValueKey('numerical-angle-input')), '$angle');
    }
    await tester.tap(find.text('Apply').last);
  }

  Future<void> _configureControlled(CanonicalCircuitStep step) async {
    expect(find.text('Select Control Qubit'), findsOneWidget,
        reason: diagnostic('Controlled-gate dialog did not open', step));
    await tester.tap(find.text('q${step.controlQubit}').last);
    await tester.pump();
    await tester.tap(find.text('Apply').last);
  }

  Future<void> _configureToffoli(CanonicalCircuitStep step) async {
    expect(find.text('Select Control Qubits'), findsOneWidget,
        reason: diagnostic('Toffoli dialog did not open', step));
    final first = find.text('q${step.controlQubit}');
    await tester.tap(first.first);
    await tester.pump();
    final second = find.text('q${step.secondControlQubit}');
    await tester.tap(second.last);
    await tester.pump();
    await tester.tap(find.text('Apply').last);
  }

  Future<void> checkResultAndComplete() async {
    expect(find.text('Check Result'), findsOneWidget,
        reason: diagnostic('Check Result action is absent'));
    _pressCheckResultAction();
    await tester.pump(const Duration(milliseconds: 500));

    expect(unlockedLevels, contains(levelId + 1),
        reason: diagnostic('Completion callback did not fire'));
    if (LevelHeaderRouter.isMasteryLevel(levelId)) {
      expect(find.text('Challenge Complete'), findsWidgets,
          reason: diagnostic('Mastery success dialog did not appear'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    } else {
      // Guided Composer levels intentionally complete by returning directly to
      // the learning flow; they do not present the Mastery review dialog.
      await tester.pumpAndSettle();
    }
    await Future.wait(_completionWrites);

    if (LevelHeaderRouter.isMasteryLevel(levelId)) {
      expect(progress.state.completedChallengeIds, contains(levelId),
          reason: diagnostic('Mastery progression was not persisted'));
    } else {
      expect(progress.state.completedLessonIds, contains(levelId),
          reason: diagnostic('Guided progression was not persisted'));
    }
  }

  Future<void> checkWrongResult() async {
    _pressCheckResultAction();
    await tester.pumpAndSettle();
    expect(find.textContaining('Not yet'), findsOneWidget,
        reason: diagnostic('Wrong circuit was not rejected'));
    expect(unlockedLevels, isEmpty,
        reason: diagnostic('Wrong circuit advanced progression'));
  }

  void _pressCheckResultAction() {
    final button = find.ancestor(
      of: find.text('Check Result'),
      matching: find.byType(ElevatedButton),
    );
    expect(button, findsOneWidget,
        reason: diagnostic('Check Result button is absent'));
    final onPressed = tester.widget<ElevatedButton>(button).onPressed;
    expect(onPressed, isNotNull,
        reason: diagnostic('Check Result button is disabled'));
    onPressed!();
  }

  String diagnostic(String message, [CanonicalCircuitStep? step]) =>
      '$message\n'
      'level: $levelId ${level.title}\n'
      'validation: ${level.validationMode.name}\n'
      'step: ${step ?? '-'}\n'
      'canonical: ${level.canonicalSolution}\n'
      'initial: ${level.initialQubitsStateStr}\n'
      'target: ${level.targetStateExpression ?? level.targetStateLabel ?? level.solutionFinalVector}';

  static bool _isRotation(SelectedGateType type) =>
      type == SelectedGateType.rx ||
      type == SelectedGateType.ry ||
      type == SelectedGateType.rz;

  static bool _isControlled(SelectedGateType type) =>
      type == SelectedGateType.cnot || type == SelectedGateType.cz;
}
