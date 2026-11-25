import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

/// Which kind of Composer session is running. Each mode has one
/// [ComposerPolicy]; hosts never branch on the mode for editing rules.
enum ComposerMode {
  sandbox,
  notebookExample,
  journeyExercise,
  masteryChallenge
}

/// How a rotation gate dragged from the palette gets its angle.
enum ComposerAngleEntry {
  /// Place with [ComposerPolicy.defaultRotationAngle] and select the gate so
  /// its angle is configured in the inspector (web Sandbox, v2.6 M3).
  defaultOnPlacement,

  /// Ask when the gate is dropped (Notebook examples).
  promptOnPlacement,

  /// Use the palette gate's own angle (a lesson preset, or the lesson's
  /// palette-wide angle control). Never prompts.
  palettePreset,
}

/// What the Clear/Reset action is called. Both restore the level's authored
/// starting circuit (pre-inserted, fixed gates included) through the same
/// model operation; only the wording differs.
enum ComposerClearAction { clear, reset }

/// Mode-specific editing restrictions, derived from the existing behaviour
/// of each web Composer host (see docs/v2.6/V26_SHARED_ARCHITECTURE.md §3).
///
/// Rules the quantum model already enforces are not duplicated here:
/// fixed gates (`isDeletable == false`) can never be moved, replaced,
/// re-parameterised or deleted in any mode; replacements are limited to the
/// level's available gate types; measurement ordering is validated by
/// `QuantumCircuit`. The policy adds only what differs between modes.
@immutable
class ComposerPolicy {
  const ComposerPolicy._({
    required this.mode,
    required this.availableGates,
    required this.permittedQubitCounts,
    required this.allowsMeasurement,
    required this.runsExperiments,
    required this.persistsToSandbox,
    required this.showsTargetState,
    required this.offersCheck,
    required this.offersHints,
    required this.clearAction,
    required this.angleEntry,
    required Set<SelectedGateType> presetAngleTypes,
  }) : _presetAngleTypes = presetAngleTypes;

  /// Builds the policy for [mode] from the session's [level].
  ///
  /// [revealTarget] is an information restriction, independent of the
  /// editing rules: when false, the target state is never shown (state view,
  /// Bloch overlay or expression), for activities whose target is something
  /// to discover. Every current Journey and Mastery circuit activity reveals
  /// its target, so the default keeps today's behaviour (v2.6 M6a).
  factory ComposerPolicy.forMode(
    ComposerMode mode,
    ComposerLevel level, {
    bool revealTarget = true,
  }) {
    final gates = List<Gate>.unmodifiable(level.availableGates);
    final presetAngles = {
      for (final gate in level.availableGates)
        if (gate.requiresAngle && gate.angle != null) gate.type,
    };
    final hasTarget = level.solutionFinalVector.isNotEmpty && revealTarget;
    return switch (mode) {
      ComposerMode.sandbox => ComposerPolicy._(
          mode: mode,
          availableGates: gates,
          permittedQubitCounts: sandboxQubitCounts,
          allowsMeasurement: true,
          runsExperiments: true,
          persistsToSandbox: true,
          showsTargetState: false,
          offersCheck: false,
          offersHints: false,
          clearAction: ComposerClearAction.clear,
          angleEntry: ComposerAngleEntry.defaultOnPlacement,
          presetAngleTypes: const {},
        ),
      ComposerMode.notebookExample => ComposerPolicy._(
          mode: mode,
          availableGates: gates,
          permittedQubitCounts: {level.numQubits},
          allowsMeasurement: false,
          runsExperiments: true,
          persistsToSandbox: false,
          showsTargetState: hasTarget,
          offersCheck: false,
          offersHints: false,
          clearAction: ComposerClearAction.clear,
          angleEntry: ComposerAngleEntry.promptOnPlacement,
          presetAngleTypes: const {},
        ),
      ComposerMode.journeyExercise ||
      ComposerMode.masteryChallenge =>
        ComposerPolicy._(
          mode: mode,
          availableGates: gates,
          permittedQubitCounts: {level.numQubits},
          // Existing exercises and challenges were not designed for M, and
          // their contract has no sampled runs: completion comes only from
          // the explicit Check.
          allowsMeasurement: false,
          runsExperiments: false,
          persistsToSandbox: false,
          showsTargetState: hasTarget,
          offersCheck: true,
          offersHints: true,
          clearAction: ComposerClearAction.reset,
          angleEntry: ComposerAngleEntry.palettePreset,
          presetAngleTypes: presetAngles,
        ),
    };
  }

  static const Set<int> sandboxQubitCounts = {1, 2, 3, 4, 5};

  /// Angle given to a rotation placed with
  /// [ComposerAngleEntry.defaultOnPlacement]: π/2, a quarter turn that
  /// visibly changes |0⟩ for every rotation axis except Rz.
  static const double defaultRotationAngle = math.pi / 2;

  final ComposerMode mode;

  /// Palette gates, in authored order. Measurement is not a palette gate;
  /// see [allowsMeasurement].
  final List<Gate> availableGates;

  /// Qubit counts the session may be opened with. Only the Sandbox lets the
  /// learner choose; every other mode is fixed by its level or example.
  final Set<int> permittedQubitCounts;
  final bool allowsMeasurement;

  /// Whether Results offers Run once / Run shots (the Measure view).
  final bool runsExperiments;

  /// Whether committed edits autosave to the per-qubit-count Sandbox store.
  /// Never true for examples, exercises or challenges.
  final bool persistsToSandbox;
  /// Whether the target state may be presented at all (see
  /// [ComposerPolicy.forMode]'s `revealTarget`).
  final bool showsTargetState;
  final bool offersCheck;
  final bool offersHints;
  final ComposerClearAction clearAction;
  final ComposerAngleEntry angleEntry;
  final Set<SelectedGateType> _presetAngleTypes;

  /// Whether a placed rotation of [type] may have its angle changed. Lessons
  /// that author a fixed angle for a rotation (for example Rz(π/4) in the
  /// palette) keep it; free rotations stay editable. The model additionally
  /// protects fixed gates.
  bool allowsAngleEditing(SelectedGateType type) =>
      !_presetAngleTypes.contains(type);

  bool allowsGateType(SelectedGateType type) =>
      availableGates.any((gate) => gate.type == type);
}
