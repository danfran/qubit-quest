// lib/models/level.dart

import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/utils/math_utils.dart';

enum ValidationMode {
  finalState,
  unitary,
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
    required this.numQubits,
    required this.initialQubitsStateStr,
    required this.initialQubitsState,
    required this.availableGates,
    required this.solutionFinalVector,
    this.validationMode = ValidationMode.finalState,
    this.targetUnitary,
    this.alternateTargetUnitaries = const [],
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
    int?
        numQubits, // kept for backward compat with existing levels; derived from string if null
    required String initialQubitsStateString,
    required List<Gate> availableGates,
    required List<List<Complex>> solutionFinalVector,
    ValidationMode validationMode = ValidationMode.finalState,
    List<List<Complex>>? targetUnitary,
    List<List<List<Complex>>> alternateTargetUnitaries = const [],
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
      numQubits: resolvedNumQubits,
      initialQubitsStateStr: initialQubitsStateString,
      initialQubitsState: convertedInitialState,
      availableGates: availableGates,
      solutionFinalVector: solutionFinalVector,
      validationMode: validationMode,
      targetUnitary: targetUnitary,
      alternateTargetUnitaries: alternateTargetUnitaries,
      preInsertedGates: preInsertedGates,
    );
  }

  void preInsertGates(QuantumCircuit quantumCircuit) {
    preInsertedGates?.call(quantumCircuit);
  }

  bool validateCircuit(QuantumCircuit circuit, {double eps = 1e-9}) {
    switch (validationMode) {
      case ValidationMode.finalState:
        return matrixClose(
          circuit.currentState.state.toComplexList(),
          solutionFinalVector,
          eps: eps,
        );
      case ValidationMode.unitary:
        if (targetUnitary == null) {
          debugPrint(
            'ComposerLevel "${title ?? taskDescription}" uses unitary validation but targetUnitary is null.',
          );
          return false;
        }

        final currentUnitary =
            circuit.getOverallCircuitMatrix().toComplexList();
        if (currentUnitary.length != targetUnitary!.length) {
          debugPrint(
            'ComposerLevel "${title ?? taskDescription}" unitary validation failed: row count mismatch '
            '(${currentUnitary.length} vs ${targetUnitary!.length}).',
          );
          return false;
        }
        for (int row = 0; row < currentUnitary.length; row++) {
          if (currentUnitary[row].length != targetUnitary![row].length) {
            debugPrint(
              'ComposerLevel "${title ?? taskDescription}" unitary validation failed: '
              'column count mismatch at row $row (${currentUnitary[row].length} vs ${targetUnitary![row].length}).',
            );
            return false;
          }
        }
        if (matrixClose(currentUnitary, targetUnitary!, eps: eps)) {
          return true;
        }
        for (final alternateTargetUnitary in alternateTargetUnitaries) {
          if (matrixClose(currentUnitary, alternateTargetUnitary, eps: eps)) {
            return true;
          }
        }
        return false;
    }
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
    required this.options,
    required this.correctOptionIndex,
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
