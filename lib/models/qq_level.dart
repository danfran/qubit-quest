// lib/models/level.dart

import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/utils/math_utils.dart';

enum ValidationMode {
  finalState,
  unitary,
}

class ComposerValidationResult {
  final bool success;
  final bool stateMatches;
  final double tolerance;
  final bool withinTolerance;
  final bool globalPhaseMatches;
  final bool explicitConstraintMatches;
  final String explicitConstraint;
  final String finalReason;

  const ComposerValidationResult({
    required this.success,
    required this.stateMatches,
    required this.tolerance,
    required this.withinTolerance,
    required this.globalPhaseMatches,
    required this.explicitConstraintMatches,
    required this.explicitConstraint,
    required this.finalReason,
  });
}

// ── Base sealed class ──────────────────────────────────────────────────────────
sealed class QQLevel {
  final String? title; // shown in level grid; shows number if null
  final String taskDescription;
  final String? conceptIntro; // shown BEFORE the puzzle
  final String? solutionExplanation; // shown AFTER success
  final List<String>? hints; // progressive hints revealed one at a time
  final String? targetStateLabel; // display-only target notation
  final String? targetStateExpression; // display-only target expression
  final String? mysteryTitle;
  final String? mysteryText;
  final String? discoveryTitle;
  final String? discoveryText;
  final String? keyInsight;
  final String? whyItMatters;
  final String? nextMystery;
  final List<String> conceptsUsed;
  final String? difficulty;
  final List<String> relatedDiscoveryTitles;

  const QQLevel({
    this.title,
    required this.taskDescription,
    this.conceptIntro,
    this.solutionExplanation,
    this.hints,
    this.targetStateLabel,
    this.targetStateExpression,
    this.mysteryTitle,
    this.mysteryText,
    this.discoveryTitle,
    this.discoveryText,
    this.keyInsight,
    this.whyItMatters,
    this.nextMystery,
    this.conceptsUsed = const [],
    this.difficulty,
    this.relatedDiscoveryTitles = const [],
  });

  bool get hasMystery =>
      (mysteryTitle?.trim().isNotEmpty ?? false) ||
      (mysteryText?.trim().isNotEmpty ?? false);

  bool get hasDiscovery =>
      (discoveryTitle?.trim().isNotEmpty ?? false) ||
      (discoveryText?.trim().isNotEmpty ?? false) ||
      (keyInsight?.trim().isNotEmpty ?? false);

  bool get hasWhyItMatters =>
      (whyItMatters?.trim().isNotEmpty ?? false) ||
      (nextMystery?.trim().isNotEmpty ?? false);
}

// ── Circuit Composer (all existing levels) ────────────────────────────────────
class ComposerLevel extends QQLevel {
  final int numQubits;
  final String initialQubitsStateStr;
  final List<Complex> initialQubitsState;
  final Function(QuantumCircuit)? preInsertedGates;
  final List<Gate> availableGates;
  final List<List<Complex>> solutionFinalVector;
  final ValidationMode validationMode;
  final List<List<Complex>>? targetUnitary;
  final List<List<List<Complex>>> alternateTargetUnitaries;
  final CanonicalComposerSolution? canonicalSolution;

  const ComposerLevel({
    super.title,
    required super.taskDescription,
    super.conceptIntro,
    super.solutionExplanation,
    super.hints,
    super.targetStateLabel,
    super.targetStateExpression,
    super.mysteryTitle,
    super.mysteryText,
    super.discoveryTitle,
    super.discoveryText,
    super.keyInsight,
    super.whyItMatters,
    super.nextMystery,
    super.conceptsUsed,
    super.difficulty,
    super.relatedDiscoveryTitles,
    required this.numQubits,
    required this.initialQubitsStateStr,
    required this.initialQubitsState,
    required this.availableGates,
    required this.solutionFinalVector,
    this.validationMode = ValidationMode.finalState,
    this.targetUnitary,
    this.alternateTargetUnitaries = const [],
    this.canonicalSolution,
    this.preInsertedGates,
  });

  factory ComposerLevel.fromBinaryString({
    String? title,
    required String taskDescription,
    String? conceptIntro,
    String? solutionExplanation,
    List<String>? hints,
    String? targetStateLabel,
    String? targetStateExpression,
    String? mysteryTitle,
    String? mysteryText,
    String? discoveryTitle,
    String? discoveryText,
    String? keyInsight,
    String? whyItMatters,
    String? nextMystery,
    List<String> conceptsUsed = const [],
    String? difficulty,
    List<String> relatedDiscoveryTitles = const [],
    int?
        numQubits, // kept for backward compat with existing levels; derived from string if null
    required String initialQubitsStateString,
    required List<Gate> availableGates,
    required List<List<Complex>> solutionFinalVector,
    ValidationMode validationMode = ValidationMode.finalState,
    List<List<Complex>>? targetUnitary,
    List<List<List<Complex>>> alternateTargetUnitaries = const [],
    CanonicalComposerSolution? canonicalSolution,
    Function(QuantumCircuit)? preInsertedGates,
  }) {
    final int resolvedNumQubits = initialQubitsStateString.length;
    final List<Complex> convertedInitialState =
        binaryStringToInitialStateVector(
            initialQubitsStateString, resolvedNumQubits);
    return ComposerLevel(
      title: title,
      taskDescription: taskDescription,
      conceptIntro: conceptIntro,
      solutionExplanation: solutionExplanation,
      hints: hints,
      targetStateLabel: targetStateLabel,
      targetStateExpression: targetStateExpression,
      mysteryTitle: mysteryTitle,
      mysteryText: mysteryText,
      discoveryTitle: discoveryTitle,
      discoveryText: discoveryText,
      keyInsight: keyInsight,
      whyItMatters: whyItMatters,
      nextMystery: nextMystery,
      conceptsUsed: conceptsUsed,
      difficulty: difficulty,
      relatedDiscoveryTitles: relatedDiscoveryTitles,
      numQubits: resolvedNumQubits,
      initialQubitsStateStr: initialQubitsStateString,
      initialQubitsState: convertedInitialState,
      availableGates: availableGates,
      solutionFinalVector: solutionFinalVector,
      validationMode: validationMode,
      targetUnitary: targetUnitary,
      alternateTargetUnitaries: alternateTargetUnitaries,
      canonicalSolution: canonicalSolution,
      preInsertedGates: preInsertedGates,
    );
  }

  void preInsertGates(QuantumCircuit quantumCircuit) {
    preInsertedGates?.call(quantumCircuit);
  }

  ComposerValidationResult evaluateCircuit(QuantumCircuit circuit,
      {double eps = 1e-9}) {
    final malformedCircuit = circuit.lastSimulationError;
    if (malformedCircuit != null) {
      return ComposerValidationResult(
        success: false,
        stateMatches: false,
        tolerance: eps,
        withinTolerance: false,
        globalPhaseMatches: false,
        explicitConstraintMatches: false,
        explicitConstraint: 'valid circuit metadata',
        finalReason: malformedCircuit.userMessage,
      );
    }

    final currentVector = circuit.currentState.state.toComplexList();
    final bool stateMatches = matrixClose(
      currentVector,
      solutionFinalVector,
      eps: eps,
    );
    final bool globalPhaseMatches =
        _matrixCloseUpToGlobalPhase(currentVector, solutionFinalVector, eps);

    switch (validationMode) {
      case ValidationMode.finalState:
        return ComposerValidationResult(
          success: stateMatches,
          stateMatches: stateMatches,
          tolerance: eps,
          withinTolerance: stateMatches,
          globalPhaseMatches: globalPhaseMatches,
          explicitConstraintMatches: true,
          explicitConstraint: 'none',
          finalReason: stateMatches
              ? 'final state matches target'
              : 'final state mismatch',
        );
      case ValidationMode.unitary:
        if (targetUnitary == null) {
          return ComposerValidationResult(
            success: false,
            stateMatches: stateMatches,
            tolerance: eps,
            withinTolerance: stateMatches,
            globalPhaseMatches: globalPhaseMatches,
            explicitConstraintMatches: false,
            explicitConstraint: 'unitary target',
            finalReason: 'missing targetUnitary',
          );
        }

        final List<List<Complex>> currentUnitary;
        try {
          currentUnitary = circuit.getOverallCircuitMatrix().toComplexList();
        } on MalformedCircuitException catch (error) {
          return ComposerValidationResult(
            success: false,
            stateMatches: stateMatches,
            tolerance: eps,
            withinTolerance: stateMatches,
            globalPhaseMatches: globalPhaseMatches,
            explicitConstraintMatches: false,
            explicitConstraint: 'valid circuit metadata',
            finalReason: error.userMessage,
          );
        }
        if (currentUnitary.length != targetUnitary!.length) {
          return ComposerValidationResult(
            success: false,
            stateMatches: stateMatches,
            tolerance: eps,
            withinTolerance: stateMatches,
            globalPhaseMatches: globalPhaseMatches,
            explicitConstraintMatches: false,
            explicitConstraint: 'unitary target',
            finalReason: 'unitary row count mismatch',
          );
        }
        for (int row = 0; row < currentUnitary.length; row++) {
          if (currentUnitary[row].length != targetUnitary![row].length) {
            return ComposerValidationResult(
              success: false,
              stateMatches: stateMatches,
              tolerance: eps,
              withinTolerance: stateMatches,
              globalPhaseMatches: globalPhaseMatches,
              explicitConstraintMatches: false,
              explicitConstraint: 'unitary target',
              finalReason: 'unitary column count mismatch at row $row',
            );
          }
        }
        bool unitaryMatches =
            matrixClose(currentUnitary, targetUnitary!, eps: eps);
        for (final alternateTargetUnitary in alternateTargetUnitaries) {
          unitaryMatches = unitaryMatches ||
              matrixClose(currentUnitary, alternateTargetUnitary, eps: eps);
        }
        return ComposerValidationResult(
          success: unitaryMatches,
          stateMatches: stateMatches,
          tolerance: eps,
          withinTolerance: stateMatches,
          globalPhaseMatches: globalPhaseMatches,
          explicitConstraintMatches: unitaryMatches,
          explicitConstraint: 'unitary target',
          finalReason: unitaryMatches
              ? 'explicit unitary constraint matches'
              : 'explicit unitary constraint mismatch',
        );
    }
  }

  bool validateCircuit(QuantumCircuit circuit, {double eps = 1e-9}) {
    final result = evaluateCircuit(circuit, eps: eps);
    if (!result.success) {
      _debugLogValidationFailure(circuit, result);
    }
    return result.success;
  }

  void _debugLogValidationFailure(
    QuantumCircuit circuit,
    ComposerValidationResult result,
  ) {
    assert(() {
      debugPrint(
        'ComposerLevel validation failed for "${title ?? taskDescription}".\n'
        'currentVector: ${circuit.currentState.state.toComplexList()}\n'
        'targetVector: $solutionFinalVector\n'
        'stateMatches: ${result.stateMatches}\n'
        'tolerance: ${result.tolerance}\n'
        'withinTolerance: ${result.withinTolerance}\n'
        'globalPhaseMatches: ${result.globalPhaseMatches}\n'
        'explicitConstraint: ${result.explicitConstraint}\n'
        'explicitConstraintMatches: ${result.explicitConstraintMatches}\n'
        'finalReason: ${result.finalReason}',
      );
      return true;
    }());
  }

  static bool _matrixCloseUpToGlobalPhase(
    List<List<Complex>> a,
    List<List<Complex>> b,
    double eps,
  ) {
    if (a.length != b.length) {
      return false;
    }

    Complex? phase;
    for (int row = 0; row < a.length; row++) {
      if (a[row].length != b[row].length) {
        return false;
      }

      for (int col = 0; col < a[row].length; col++) {
        final target = b[row][col];
        final current = a[row][col];
        if (_complexMagnitudeSquared(target) <= eps * eps) {
          if (!complexClose(current, Complex.zero(), eps: eps)) {
            return false;
          }
          continue;
        }

        phase ??= _complexDivide(current, target);
        if (!complexClose(current, _complexMultiply(phase, target), eps: eps)) {
          return false;
        }
      }
    }

    return phase != null && (_complexMagnitudeSquared(phase) - 1).abs() < eps;
  }

  static double _complexMagnitudeSquared(Complex value) {
    return (value.real * value.real + value.imaginary * value.imaginary)
        .toDouble();
  }

  static Complex _complexMultiply(Complex a, Complex b) {
    return Complex(
      a.real * b.real - a.imaginary * b.imaginary,
      a.real * b.imaginary + a.imaginary * b.real,
    );
  }

  static Complex _complexDivide(Complex numerator, Complex denominator) {
    final scale = _complexMagnitudeSquared(denominator);
    return Complex(
      (numerator.real * denominator.real +
              numerator.imaginary * denominator.imaginary) /
          scale,
      (numerator.imaginary * denominator.real -
              numerator.real * denominator.imaginary) /
          scale,
    );
  }

  static List<Complex> getZeroStateVector(int numQubits) {
    final int dim = 1 << numQubits;
    final List<Complex> state = List.filled(dim, Complex.zero());
    state[0] = Complex.one();
    return state;
  }

  static List<Complex> getOneStateVector(int numQubits) {
    final int dim = 1 << numQubits;
    final List<Complex> state = List.filled(dim, Complex.zero());
    state[dim - 1] = Complex.one();
    return state;
  }
}

// ── Fill the Gate ─────────────────────────────────────────────────────────────
// Shows a circuit with one gate replaced by "?". User picks the correct gate.
class FillTheGateLevel extends QQLevel {
  final int numQubits;
  final String initialQubitsStateString;
  final Function(QuantumCircuit) preBuiltGates; // all gates EXCEPT the blank
  final Gate correctGate;
  final List<Gate> options; // 4 choices including correctGate
  final List<List<Complex>> solutionFinalVector;

  const FillTheGateLevel({
    super.title,
    required super.taskDescription,
    super.conceptIntro,
    super.solutionExplanation,
    super.hints,
    super.mysteryTitle,
    super.mysteryText,
    super.discoveryTitle,
    super.discoveryText,
    super.keyInsight,
    super.whyItMatters,
    super.nextMystery,
    super.conceptsUsed,
    super.difficulty,
    super.relatedDiscoveryTitles,
    required this.numQubits,
    required this.initialQubitsStateString,
    required this.preBuiltGates,
    required this.correctGate,
    required this.options,
    required this.solutionFinalVector,
  });

  /// Builds a ComposerLevel for simulation with the given gate filling the blank.
  ComposerLevel toComposerLevelWith(Gate filledGate) {
    return ComposerLevel.fromBinaryString(
      taskDescription: taskDescription,
      initialQubitsStateString: initialQubitsStateString,
      availableGates: const [],
      solutionFinalVector: solutionFinalVector,
      preInsertedGates: (circuit) {
        preBuiltGates(circuit);
        circuit.insertSinglePlacedGateAt(
            filledGate, circuit.maxCircuitDepth(), 0,
            isDeletable: false);
      },
    );
  }
}

// ── Circuit Reading ───────────────────────────────────────────────────────────
// Shows a complete pre-built circuit. User identifies the output state.
class CircuitReadingLevel extends QQLevel {
  final int numQubits;
  final String initialQubitsStateString;
  final Function(QuantumCircuit) circuit; // pre-built read-only circuit
  final List<String> options; // LaTeX state descriptions
  final int correctOptionIndex;

  const CircuitReadingLevel({
    super.title,
    required super.taskDescription,
    super.conceptIntro,
    super.solutionExplanation,
    super.hints,
    super.mysteryTitle,
    super.mysteryText,
    super.discoveryTitle,
    super.discoveryText,
    super.keyInsight,
    super.whyItMatters,
    super.nextMystery,
    super.conceptsUsed,
    super.difficulty,
    super.relatedDiscoveryTitles,
    required this.numQubits,
    required this.initialQubitsStateString,
    required this.circuit,
    required this.options,
    required this.correctOptionIndex,
  });

  ComposerLevel toComposerLevel() {
    return ComposerLevel.fromBinaryString(
      taskDescription: taskDescription,
      initialQubitsStateString: initialQubitsStateString,
      availableGates: const [],
      solutionFinalVector: const [],
      preInsertedGates: circuit,
    );
  }
}

// ── Multiple Choice Question ──────────────────────────────────────────────────
class McqLevel extends QQLevel {
  final List<String> options;
  final int correctOptionIndex;

  const McqLevel({
    super.title,
    required super.taskDescription,
    super.conceptIntro,
    super.solutionExplanation,
    super.hints,
    super.mysteryTitle,
    super.mysteryText,
    super.discoveryTitle,
    super.discoveryText,
    super.keyInsight,
    super.whyItMatters,
    super.nextMystery,
    super.conceptsUsed,
    super.difficulty,
    super.relatedDiscoveryTitles,
    required this.options,
    required this.correctOptionIndex,
  });
}

// Concept checks are MCQ-style understanding checkpoints, not construction
// puzzles. The final level of a chapter should use this shape when it is a
// synthesis/interpretation checkpoint rather than another mechanics exercise.
class ConceptCheckLevel extends McqLevel {
  final String badgeLabel;

  const ConceptCheckLevel({
    super.title,
    required super.taskDescription,
    super.conceptIntro,
    super.solutionExplanation,
    super.hints,
    super.mysteryTitle,
    super.mysteryText,
    super.discoveryTitle,
    super.discoveryText,
    super.keyInsight,
    super.whyItMatters,
    super.nextMystery,
    super.conceptsUsed,
    super.difficulty,
    super.relatedDiscoveryTitles,
    required super.options,
    required super.correctOptionIndex,
    this.badgeLabel = 'Concept Check',
  });
}

// ── Measurement Lab ───────────────────────────────────────────────────────────
// User presses "Measure" repeatedly to observe probability convergence.
class MeasurementLabLevel extends QQLevel {
  final int numQubits;
  final String initialQubitsStateString;
  final Function(QuantumCircuit)? preBuiltCircuit;
  final int requiredMeasurements;

  const MeasurementLabLevel({
    super.title,
    required super.taskDescription,
    super.conceptIntro,
    super.solutionExplanation,
    super.hints,
    super.mysteryTitle,
    super.mysteryText,
    super.discoveryTitle,
    super.discoveryText,
    super.keyInsight,
    super.whyItMatters,
    super.nextMystery,
    super.conceptsUsed,
    super.difficulty,
    super.relatedDiscoveryTitles,
    required this.numQubits,
    required this.initialQubitsStateString,
    this.preBuiltCircuit,
    this.requiredMeasurements = 20,
  });

  ComposerLevel toComposerLevel() {
    return ComposerLevel.fromBinaryString(
      taskDescription: taskDescription,
      initialQubitsStateString: initialQubitsStateString,
      availableGates: const [],
      solutionFinalVector: const [],
      preInsertedGates: preBuiltCircuit,
    );
  }
}
