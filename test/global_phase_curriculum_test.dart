import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  ComposerLevel composer(int id) => getQQLevelById(id)! as ComposerLevel;

  QuantumCircuit circuitFor(ComposerLevel level) {
    final circuit = QuantumCircuit(currentLevel: level);
    circuit.runSimulation();
    return circuit;
  }

  group('physical pure-state validation', () {
    test('|1>, -|1>, and i|1> are equivalent', () {
      final level = ComposerLevel.fromBinaryString(
        taskDescription: 'Reach the physical state |1>.',
        initialQubitsStateString: '0',
        availableGates: [Gate.fromIdentifier(SelectedGateType.y)],
        solutionFinalVector: [
          [Complex.zero()],
          [Complex.one()],
        ],
        validationMode: ValidationMode.physicalState,
      );

      final minusCircuit = QuantumCircuit(
        currentLevel: ComposerLevel.fromBinaryString(
          taskDescription: 'Represent -|1>.',
          initialQubitsStateString: '1',
          availableGates: [Gate.fromIdentifier(SelectedGateType.z)],
          solutionFinalVector: [
            [Complex.zero()],
            [Complex.one()],
          ],
          validationMode: ValidationMode.physicalState,
        ),
      );
      minusCircuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      minusCircuit.runSimulation();
      expect(minusCircuit.currentLevel.validateCircuit(minusCircuit), isTrue);

      final iCircuit = QuantumCircuit(currentLevel: level);
      iCircuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.y), 0, 0);
      iCircuit.runSimulation();
      expect(level.validateCircuit(iCircuit), isTrue);
      expect(level.evaluateCircuit(iCircuit).globalPhaseMatches, isTrue);
    });

    test('|+> differs from |-> and |+i> differs from |-i>', () {
      ComposerLevel physicalTarget(List<List<Complex>> target) =>
          ComposerLevel.fromBinaryString(
            taskDescription: 'Match a relative-phase target.',
            initialQubitsStateString: '0',
            availableGates: const [],
            solutionFinalVector: target,
            validationMode: ValidationMode.physicalState,
          );

      final minusTarget = physicalTarget([
        [Complex(math.sqrt1_2, 0)],
        [Complex(-math.sqrt1_2, 0)],
      ]);
      final plusCircuit = QuantumCircuit(currentLevel: minusTarget);
      plusCircuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      plusCircuit.runSimulation();
      expect(minusTarget.validateCircuit(plusCircuit), isFalse);

      final minusITarget = physicalTarget([
        [Complex(math.sqrt1_2, 0)],
        [Complex(0, -math.sqrt1_2)],
      ]);
      final plusICircuit = QuantumCircuit(currentLevel: minusITarget);
      plusICircuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      plusICircuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.s), 1, 0);
      plusICircuit.runSimulation();
      expect(minusITarget.validateCircuit(plusICircuit), isFalse);
    });
  });

  group('corrected canonical phase curriculum', () {
    test('Chapter 2 preserves order and global-to-relative progression', () {
      expect(composer(6).title, 'Nothing Happened?');
      expect(composer(7).title, 'The Invisible Difference');
      expect(composer(7).keyInsight, contains('global phase'));
      expect(composer(7).solutionExplanation, contains('same physical'));
      expect(composer(8).title, 'The Minus Sign');
      expect(composer(8).keyInsight, contains('Relative phase'));
      expect(composer(9).title, 'Hidden Information');
      expect(composer(10).title, 'What Did We Actually Discover?');
      expect(
          [
            composer(10).conceptIntro,
            composer(10).discoveryText,
            composer(10).keyInsight,
            composer(10).whyItMatters,
          ].join(' '),
          contains('interfer'));
    });

    test('Mastery M2-M5 distinguish representations and relative phase', () {
      final m2 = getQQLevelById(62)! as McqLevel;
      expect(m2.options[m2.correctOptionIndex], contains('same physical'));
      expect(m2.solutionExplanation, contains('global phase'));

      final m3 = getQQLevelById(63)! as CircuitReadingLevel;
      expect(m3.solutionExplanation, contains('factor −i is global'));
      expect(m3.solutionExplanation, contains('minus sign between'));

      final m4 = getQQLevelById(64)! as FillTheGateLevel;
      expect(m4.correctGate.type, SelectedGateType.s);
      expect(m4.solutionExplanation, contains('relative phase'));
      expect(composer(65).targetStateExpression, contains('XZX = -Z ~ Z'));
      expect(composer(65).validationMode, ValidationMode.unitary);
    });

    test('M42 and M46 validate relative-phase targets up to global phase', () {
      final m42 = composer(102);
      final c42 = circuitFor(m42);
      c42.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), 1, 0);
      c42.runSimulation();
      expect(m42.validateCircuit(c42), isTrue);
      expect(m42.evaluateCircuit(c42).globalPhaseMatches, isTrue);

      final m46 = composer(106);
      final c46 = circuitFor(m46);
      c46.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 3), 0, 0);
      c46.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), 1, 0);
      c46.runSimulation();
      expect(m46.validateCircuit(c46), isTrue);
      expect(m46.evaluateCircuit(c46).globalPhaseMatches, isTrue);
    });

    test('known false claims and unsafe labels are absent', () {
      final affected = [7, 62, 63, 64, 65, 102, 106, 110]
          .map((id) => getQQLevelById(id)!)
          .expand((level) => [
                level.title,
                level.taskDescription,
                level.conceptIntro,
                level.solutionExplanation,
                level.targetStateLabel,
                level.targetStateExpression,
                level.discoveryText,
                level.keyInsight,
                level.whyItMatters,
                ...?level.hints,
              ])
          .whereType<String>()
          .join('\n');

      expect(affected, isNot(contains('physically distinct from |1⟩')));
      expect(affected,
          isNot(contains('cannot happen with classical random bits')));
      expect(affected, isNot(contains('This state is |i⟩')));
      expect(affected, isNot(contains('exact displayed state vector')));
    });

    test('Notebook explains global and relative phase consistently', () {
      final entry = notebookEntries
          .singleWhere((candidate) => candidate.id == 'invisible_difference');
      final copy = [
        entry.summary,
        entry.intuition.body,
        entry.whatChanged!.body,
        entry.quantumView!.body,
        entry.advancedNotes!.body,
      ].join('\n');
      expect(copy, contains('same physical pure state'));
      expect(copy, contains('every possible experimental prediction'));
      expect(copy, contains('Relative phase'));
      expect(copy, contains('same Bloch-sphere point'));
    });
  });
}
