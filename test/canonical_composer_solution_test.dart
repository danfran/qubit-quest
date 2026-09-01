import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/canonical_solution_catalog.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

ComposerLevel level(int id) => getQQLevelById(id)! as ComposerLevel;

ComposerLevel fixture({
  required CanonicalComposerSolution solution,
  int qubits = 3,
  List<Gate>? availableGates,
}) {
  return ComposerLevel.fromBinaryString(
    title: 'Canonical fixture',
    taskDescription: 'Fixture',
    initialQubitsStateString: '0' * qubits,
    availableGates: availableGates ??
        [
          Gate.fromIdentifier(SelectedGateType.x),
          Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2),
          Gate.fromIdentifier(SelectedGateType.cnot),
          Gate.fromIdentifier(SelectedGateType.cz),
          Gate.fromIdentifier(SelectedGateType.ccnot),
        ],
    solutionFinalVector: List.generate(
      1 << qubits,
      (index) => [index == 0 ? Complex.one() : Complex.zero()],
    ),
    canonicalSolution: solution,
  );
}

void main() {
  group('canonical solution schema', () {
    test('solution owns an immutable ordered step list', () {
      final source = <CanonicalCircuitStep>[
        const CanonicalCircuitStep.single(
          SelectedGateType.x,
          targetQubit: 0,
        ),
      ];
      final solution = CanonicalComposerSolution(source);
      source.clear();

      expect(solution.steps, hasLength(1));
      expect(
        () => solution.steps.add(
          const CanonicalCircuitStep.single(
            SelectedGateType.z,
            targetQubit: 0,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('single, rotation, CX, CZ, and CCNOT steps validate', () {
      final candidate = fixture(
        solution: CanonicalComposerSolution([
          const CanonicalCircuitStep.single(
            SelectedGateType.x,
            targetQubit: 0,
          ),
          const CanonicalCircuitStep.single(
            SelectedGateType.rz,
            targetQubit: 1,
            angle: math.pi / 2,
          ),
          const CanonicalCircuitStep.controlled(
            SelectedGateType.cnot,
            controlQubit: 0,
            targetQubit: 1,
          ),
          const CanonicalCircuitStep.controlled(
            SelectedGateType.cz,
            controlQubit: 1,
            targetQubit: 2,
          ),
          const CanonicalCircuitStep.toffoli(
            controlQubit: 0,
            secondControlQubit: 1,
            targetQubit: 2,
          ),
        ]),
      );

      expect(validateCanonicalSolutionMetadata(candidate), isEmpty);
    });

    test('invalid qubits and controlled topology are rejected', () {
      final invalid = fixture(
        solution: CanonicalComposerSolution([
          const CanonicalCircuitStep.single(
            SelectedGateType.x,
            targetQubit: 3,
          ),
          const CanonicalCircuitStep.controlled(
            SelectedGateType.cnot,
            controlQubit: 1,
            targetQubit: 1,
          ),
          const CanonicalCircuitStep.toffoli(
            controlQubit: 0,
            secondControlQubit: 0,
            targetQubit: 2,
          ),
        ]),
      );

      final errors = validateCanonicalSolutionMetadata(invalid).join(' ');
      expect(errors, contains('out of range'));
      expect(errors, contains('control and target must be distinct'));
      expect(errors, contains('three distinct'));
    });

    test('missing, non-finite, and meaningless angles are rejected', () {
      final invalid = fixture(
        solution: CanonicalComposerSolution([
          const CanonicalCircuitStep.single(
            SelectedGateType.rz,
            targetQubit: 0,
          ),
          const CanonicalCircuitStep.single(
            SelectedGateType.rz,
            targetQubit: 0,
            angle: double.nan,
          ),
          const CanonicalCircuitStep.single(
            SelectedGateType.x,
            targetQubit: 0,
            angle: 1,
          ),
        ]),
      );

      final errors = validateCanonicalSolutionMetadata(invalid).join(' ');
      expect(
          RegExp('requires a finite angle').allMatches(errors), hasLength(2));
      expect(errors, contains('meaningless angle'));
    });
  });

  group('self-verifying Composer campaign', () {
    final composerEntries = allQQLevels.indexed
        .where((entry) => entry.$2 is ComposerLevel)
        .map((entry) => (id: entry.$1 + 1, level: entry.$2 as ComposerLevel))
        .toList(growable: false);

    test('all 85 active Composer levels carry canonical metadata', () {
      expect(composerEntries, hasLength(85));
      for (final entry in composerEntries) {
        expect(
          entry.level.canonicalSolution,
          isNotNull,
          reason: 'Level ${entry.id} ${entry.level.title}',
        );
        expect(
          entry.level.canonicalSolution!.steps,
          isNotEmpty,
          reason: 'Level ${entry.id} ${entry.level.title}',
        );
      }
      expect(
        canonicalComposerSolutionCatalog,
        hasLength(75),
        reason:
            'Only active Composer levels without inline metadata need catalog entries.',
      );
    });

    for (final entry in composerEntries) {
      test('level ${entry.id} ${entry.level.title} self-verifies', () {
        final candidate = entry.level;
        expect(
          validateCanonicalSolutionMetadata(candidate),
          isEmpty,
          reason: 'Level ${entry.id} ${candidate.title}',
        );

        final circuit = buildCanonicalSolutionCircuit(candidate);
        expect(circuit.lastSimulationError, isNull);
        expect(
          candidate.validateCircuit(circuit),
          isTrue,
          reason: 'Level ${entry.id} ${candidate.title}\n'
              'steps: ${candidate.canonicalSolution}\n'
              'circuit: $circuit\n'
              'state: ${circuit.currentState.stateVector}\n'
              'target: ${candidate.solutionFinalVector}\n'
              'mode: ${candidate.validationMode.name}',
        );
        final ids = circuit.logicalGates.map((gate) => gate.id).toList();
        expect(ids.toSet(), hasLength(ids.length));
        for (final footprint in circuit.logicalGates) {
          expect(footprint.hasValidTopology(candidate.numQubits), isTrue);
        }
      });
    }

    test('unitary representatives exercise unitary validation', () {
      final unitaryEntries = composerEntries.where(
        (entry) => entry.level.validationMode == ValidationMode.unitary,
      );
      expect(unitaryEntries, isNotEmpty);
      for (final entry in unitaryEntries) {
        final candidate = entry.level;
        expect(candidate.validationMode, ValidationMode.unitary);
        expect(candidate.targetUnitary, isNotNull);
        expect(
          candidate
              .evaluateCircuit(buildCanonicalSolutionCircuit(candidate))
              .explicitConstraintMatches,
          isTrue,
        );
      }
    });

    test('pre-inserted protected content is not duplicated by learner steps',
        () {
      for (final entry in composerEntries
          .where((entry) => entry.level.preInsertedGates != null)) {
        final initial = QuantumCircuit(currentLevel: entry.level);
        final built = buildCanonicalSolutionCircuit(entry.level);
        final initialProtected =
            initial.logicalGates.where((gate) => !gate.isDeletable).length;
        final builtProtected =
            built.logicalGates.where((gate) => !gate.isDeletable).length;
        expect(
          builtProtected,
          initialProtected,
          reason: 'Level ${entry.id} ${entry.level.title}',
        );
        expect(
          built.logicalGates.length,
          initial.logicalGates.length +
              entry.level.canonicalSolution!.steps.length,
          reason: 'Level ${entry.id} ${entry.level.title}',
        );
      }
    });

    test('all authored rotations are finite and controlled roles are distinct',
        () {
      const rotations = {
        SelectedGateType.rx,
        SelectedGateType.ry,
        SelectedGateType.rz,
      };
      for (final entry in composerEntries) {
        for (final step in entry.level.canonicalSolution!.steps) {
          if (rotations.contains(step.gateType)) {
            expect(step.angle, isNotNull,
                reason: 'Level ${entry.id} ${entry.level.title}');
            expect(step.angle!.isFinite, isTrue,
                reason: 'Level ${entry.id} ${entry.level.title}');
          }
          final roles = [
            step.targetQubit,
            if (step.controlQubit != null) step.controlQubit!,
            if (step.secondControlQubit != null) step.secondControlQubit!,
          ];
          expect(roles.toSet(), hasLength(roles.length),
              reason: 'Level ${entry.id} ${entry.level.title}: $step');
        }
      }
    });

    test('Lesson 17 encodes the authored H-Z-H sequence', () {
      expect(
        level(17)
            .canonicalSolution!
            .steps
            .map((step) => step.gateType)
            .toList(),
        [
          SelectedGateType.hadamard,
          SelectedGateType.z,
          SelectedGateType.hadamard,
        ],
      );
    });

    test('pre-inserted rotation is not duplicated in user steps', () {
      final candidate = level(103);
      expect(candidate.preInsertedGates, isNotNull);
      expect(candidate.canonicalSolution!.steps, hasLength(1));
      expect(candidate.canonicalSolution!.steps.single.angle, -math.pi / 2);

      final circuit = buildCanonicalSolutionCircuit(candidate);
      expect(circuit.logicalGates, hasLength(2));
      expect(circuit.logicalGates.where((gate) => !gate.isDeletable),
          hasLength(1));
    });

    test('mastery wrapping retains canonical metadata', () {
      final mastery = level(65);
      expect(mastery.title, 'Phase Sandwich');
      expect(mastery.canonicalSolution, isNotNull);
      expect(
        mastery.canonicalSolution!.steps.map((step) => step.gateType),
        [SelectedGateType.x, SelectedGateType.z, SelectedGateType.x],
      );
    });

    test('ID 74 follows the documented little-endian qubit convention', () {
      final candidate = level(74);
      final step = candidate.canonicalSolution!.steps.single;
      expect(step.gateType, SelectedGateType.cnot);
      expect(step.controlQubit, 1);
      expect(step.targetQubit, 0);
      expect(candidate.hints!.join(' '), contains('Q1=1 and Q0=0'));
      expect(
        candidate.validateCircuit(buildCanonicalSolutionCircuit(candidate)),
        isTrue,
      );
    });

    test('altered canonical step fails real validation', () {
      final wrong = fixture(
        qubits: 1,
        availableGates: [Gate.fromIdentifier(SelectedGateType.hadamard)],
        solution: CanonicalComposerSolution([
          const CanonicalCircuitStep.single(
            SelectedGateType.hadamard,
            targetQubit: 0,
          ),
        ]),
      );
      final circuit = buildCanonicalSolutionCircuit(wrong);
      expect(wrong.validateCircuit(circuit), isFalse);
    });
  });
}
