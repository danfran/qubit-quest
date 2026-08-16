import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

class NotebookAmplitude {
  const NotebookAmplitude(this.real, [this.imaginary = 0]);

  final double real;
  final double imaginary;

  Complex toComplex() => Complex(real, imaginary);
}

class ExecutableNotebookResult {
  const ExecutableNotebookResult({required this.circuit});

  final QuantumCircuit circuit;
  List<Complex> get state => circuit.currentState.stateVector;
}

/// Immutable, display-neutral authored circuit example.
class ExecutableNotebookExample {
  ExecutableNotebookExample({
    required this.id,
    required this.title,
    required this.description,
    required this.qubitCount,
    required this.initialBinaryState,
    required Iterable<CanonicalCircuitStep> operations,
    Iterable<NotebookAmplitude>? expectedState,
    this.relatedConcept,
    this.allowOpenInComposer = true,
    this.allowOpenInBlochExplorer = false,
  })  : operations = List.unmodifiable(operations),
        expectedState =
            expectedState == null ? null : List.unmodifiable(expectedState);

  final String id;
  final String title;
  final String description;
  final int qubitCount;
  final String initialBinaryState;
  final List<CanonicalCircuitStep> operations;
  final List<NotebookAmplitude>? expectedState;
  final String? relatedConcept;
  final bool allowOpenInComposer;
  final bool allowOpenInBlochExplorer;

  List<Complex> get initialState {
    final dimension = 1 << qubitCount;
    final index = int.parse(initialBinaryState, radix: 2);
    return List.generate(
      dimension,
      (candidate) => candidate == index ? Complex.one() : Complex.zero(),
    );
  }

  ComposerLevel _level({required bool prepopulate}) {
    final available = <Gate>[];
    final seen = <String>{};
    for (final step in operations) {
      final key = '${step.gateType.name}:${step.angle}';
      if (seen.add(key)) {
        available.add(Gate.fromIdentifier(step.gateType, angle: step.angle));
      }
    }
    return ComposerLevel(
      title: title,
      taskDescription: description,
      numQubits: qubitCount,
      initialQubitsStateStr: initialBinaryState,
      initialQubitsState: initialState,
      availableGates: available,
      solutionFinalVector: [
        for (final amplitude in expectedState ?? const <NotebookAmplitude>[])
          [amplitude.toComplex()],
      ],
      canonicalSolution:
          prepopulate ? null : CanonicalComposerSolution(operations),
      preInsertedGates: prepopulate
          ? (circuit) => applyCanonicalCircuitSteps(circuit, operations)
          : null,
    );
  }

  ExecutableNotebookResult execute() => ExecutableNotebookResult(
        circuit: buildCanonicalSolutionCircuit(_level(prepopulate: false)),
      );

  ComposerLevel createEditableComposerLevel() => _level(prepopulate: true);

  List<String> validate() {
    final errors = <String>[];
    if (id.trim().isEmpty) errors.add('id is empty');
    if (title.trim().isEmpty) errors.add('$id title is empty');
    if (qubitCount < 1 || qubitCount > 5) {
      errors.add('$id has invalid qubit count $qubitCount');
    }
    if (initialBinaryState.length != qubitCount ||
        !RegExp(r'^[01]+$').hasMatch(initialBinaryState)) {
      errors.add('$id has invalid initial binary state');
    }
    if (operations.isEmpty) errors.add('$id has no operations');
    if (allowOpenInBlochExplorer && qubitCount != 1) {
      errors.add('$id enables Bloch handoff for $qubitCount qubits');
    }
    if (expectedState != null && expectedState!.length != 1 << qubitCount) {
      errors.add('$id expected-state dimension is invalid');
    }
    if (errors.isNotEmpty) return errors;
    errors
        .addAll(validateCanonicalSolutionMetadata(_level(prepopulate: false)));
    return errors;
  }

  bool resultMatchesExpected(List<Complex> result, {double tolerance = 1e-9}) {
    final expected = expectedState;
    if (expected == null || expected.length != result.length) return true;
    return result.indexed.every((item) {
      final target = expected[item.$1].toComplex();
      final deltaReal = item.$2.real - target.real;
      final deltaImaginary = item.$2.imaginary - target.imaginary;
      return math
              .sqrt(deltaReal * deltaReal + deltaImaginary * deltaImaginary) <
          tolerance;
    });
  }
}
