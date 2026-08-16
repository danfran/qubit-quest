import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

class CanonicalSolutionException implements Exception {
  final List<String> errors;

  const CanonicalSolutionException(this.errors);

  @override
  String toString() => 'Invalid canonical solution: ${errors.join('; ')}';
}

const _singleGateTypes = {
  SelectedGateType.x,
  SelectedGateType.y,
  SelectedGateType.z,
  SelectedGateType.hadamard,
  SelectedGateType.s,
  SelectedGateType.t,
  SelectedGateType.rx,
  SelectedGateType.ry,
  SelectedGateType.rz,
};

const _rotationGateTypes = {
  SelectedGateType.rx,
  SelectedGateType.ry,
  SelectedGateType.rz,
};

const _controlledGateTypes = {
  SelectedGateType.cnot,
  SelectedGateType.cz,
};

List<String> validateCanonicalSolutionMetadata(ComposerLevel level) {
  final solution = level.canonicalSolution;
  if (solution == null) return const ['canonical solution is absent'];
  final errors = <String>[];

  for (final (index, step) in solution.steps.indexed) {
    final prefix = 'step ${index + 1} (${step.gateType.name})';
    final supported = _singleGateTypes.contains(step.gateType) ||
        _controlledGateTypes.contains(step.gateType) ||
        step.gateType == SelectedGateType.ccnot;
    if (!supported) errors.add('$prefix uses an unsupported gate type');
    if (step.targetQubit < 0 || step.targetQubit >= level.numQubits) {
      errors.add('$prefix target qubit is out of range');
    }

    final available = level.availableGates
        .where((gate) => gate.type == step.gateType)
        .toList(growable: false);
    if (available.isEmpty) {
      errors.add('$prefix is not permitted by availableGates');
    }

    if (_rotationGateTypes.contains(step.gateType)) {
      if (step.angle == null || !step.angle!.isFinite) {
        errors.add('$prefix requires a finite angle');
      } else if (available.isNotEmpty &&
          available.every((gate) => gate.angle != null) &&
          !available.any(
            (gate) => (gate.angle! - step.angle!).abs() < 1e-10,
          )) {
        errors.add('$prefix angle is not permitted by availableGates');
      }
    } else if (step.angle != null) {
      errors.add('$prefix has meaningless angle metadata');
    }

    if (_controlledGateTypes.contains(step.gateType)) {
      final control = step.controlQubit;
      if (control == null || control < 0 || control >= level.numQubits) {
        errors.add('$prefix control qubit is missing or out of range');
      } else if (control == step.targetQubit) {
        errors.add('$prefix control and target must be distinct');
      }
      if (step.secondControlQubit != null) {
        errors.add('$prefix has an unexpected second control');
      }
    } else if (step.gateType == SelectedGateType.ccnot) {
      final roles = {
        step.targetQubit,
        step.controlQubit,
        step.secondControlQubit,
      };
      if (step.controlQubit == null ||
          step.secondControlQubit == null ||
          roles.length != 3 ||
          roles.whereType<int>().any(
                (qubit) => qubit < 0 || qubit >= level.numQubits,
              )) {
        errors.add('$prefix requires three distinct in-range qubits');
      }
    } else if (step.controlQubit != null || step.secondControlQubit != null) {
      errors.add('$prefix has control metadata for a single-qubit gate');
    }
  }
  return List.unmodifiable(errors);
}

QuantumCircuit buildCanonicalSolutionCircuit(ComposerLevel level) {
  final errors = validateCanonicalSolutionMetadata(level);
  if (errors.isNotEmpty) throw CanonicalSolutionException(errors);

  final circuit = QuantumCircuit(currentLevel: level);
  applyCanonicalCircuitSteps(circuit, level.canonicalSolution!.steps);
  circuit.runSimulation();
  final simulationError = circuit.lastSimulationError;
  if (simulationError != null) {
    throw CanonicalSolutionException([simulationError.userMessage]);
  }
  for (final footprint in circuit.logicalGates) {
    if (!footprint.hasValidTopology(level.numQubits)) {
      throw CanonicalSolutionException([
        'logical footprint ${footprint.id} is malformed',
      ]);
    }
  }
  return circuit;
}

/// Applies semantic operations through the production circuit editing APIs.
///
/// Callers own metadata validation. This is shared by canonical campaign
/// construction and immutable educational handoffs.
void applyCanonicalCircuitSteps(
  QuantumCircuit circuit,
  Iterable<CanonicalCircuitStep> steps,
) {
  for (final step in steps) {
    final gate = Gate.fromIdentifier(step.gateType, angle: step.angle);
    final column = circuit.maxCircuitDepth();
    final CircuitEditOutcome outcome;
    if (_singleGateTypes.contains(step.gateType)) {
      outcome = circuit.insertSingleGateWithOutcome(
        gate,
        column,
        step.targetQubit,
      );
    } else if (_controlledGateTypes.contains(step.gateType)) {
      outcome = circuit.insertDoubleGateWithOutcome(
        gate,
        column,
        step.targetQubit,
        step.controlQubit!,
      );
    } else {
      outcome = circuit.insertTripleGateWithOutcome(
        gate,
        column,
        step.targetQubit,
        step.controlQubit!,
        step.secondControlQubit!,
      );
    }
    if (!outcome.changed) {
      throw CanonicalSolutionException([
        'failed to apply $step: ${outcome.status.name} ${outcome.detail ?? ''}',
      ]);
    }
  }
}
