import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';


void main() {
  _testBody(int levelNumber, Function(QuantumCircuit) body) {
    final level = getQQLevelById(levelNumber)!;

    // Only ComposerLevels can be tested via circuit simulation
    if (level is! ComposerLevel) {
      debugPrint('Level $levelNumber is ${level.runtimeType}, skipping circuit test.\n\n');
      return;
    }

    debugPrint('Level $levelNumber: ${level.taskDescription}\n\n');

    final circuit = QuantumCircuit(currentLevel: level);

    body(circuit);

    debugPrint('Circuit after inserting gates:\n$circuit');

    circuit.runSimulation();

    expect(circuit.currentState.state.almostEqualTo(QuantumMatrix(level.solutionFinalVector)), true);

    debugPrint('\n\n');
  }

  group('Test results for all levels', () {
    var tests = [
      (QuantumCircuit circuit) {
      // check X is in the avaiable gates
      //   assert(circuit.availableGates.contains(Gate.fromIdentifier(SelectedGateType.x)));
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.y), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.y), 0, 0);
      },
      (QuantumCircuit circuit) { // 5
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.t), 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.s), 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 1, 0);
      },
      (QuantumCircuit circuit) { // 10
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.s), 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.s), 3, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 4, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 5, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.s), 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.t), 2, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 3, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 1);
      },
      (QuantumCircuit circuit) { // 15
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 2);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertTriplePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ccnot), 0, 1, 0, 2);
      },
      (QuantumCircuit circuit) {
        circuit.insertTriplePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ccnot), 0, 2, 1, 0);
      },
      (QuantumCircuit circuit) { // 20
        circuit.insertTriplePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ccnot), 0, 0, 1, 2);
      },
      (QuantumCircuit circuit) { // more than one solution, example X(0) + X(1)
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 2);
        circuit.insertTriplePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ccnot), 1, 0, 1, 2);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 2, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 3, 0);
      },
      (QuantumCircuit circuit) { // 25
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 2, 1);
      },
      (QuantumCircuit circuit) { // 2 solution with Z(1)
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 3, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 4, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 5, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 1);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 2, 0);
      },
      (QuantumCircuit circuit) { // 30
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 1);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) { // to check if double solution present
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 1);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 0, 1);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 0, 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 1, 2, 0);
      },
      (QuantumCircuit circuit) { // 35
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.x), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 1, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 2, 1, 0);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cnot), 3, 2, 1);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.z), 4, 2);
      },
      (QuantumCircuit circuit) { // double solution
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1);
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cz), 1, 1, 0);
      },
      (QuantumCircuit circuit) { // double solution
        circuit.insertDoublePlacedGateAt(Gate.fromIdentifier(SelectedGateType.cz), 2, 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 3, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.hadamard), 3, 1);
      },
      (QuantumCircuit circuit) { // 40
        // Solution: Rx(pi/2) on Q0
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), 0, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Ry(pi/2) on Q0
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2), 0, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Rz(pi/2) on Q0
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), 0, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Ry(-pi/2) on Q0
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ry, angle: -math.pi / 2), 1, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Ry(pi/2) on Q0
        // This gate is placed after the pre-inserted Rx gate.
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2), 1, 0);
      },
      (QuantumCircuit circuit) { // 45
        // Solution: Rz(pi/4) on Q1
        // This gate is placed after the pre-inserted gates.
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 4), 2, 1);
      },
      (QuantumCircuit circuit) {
        // Solution: Rx(pi/2), Ry(pi/4), then Rz(pi/2) on Q0.
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), 0, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 4), 1, 0);
        circuit.insertSinglePlacedGateAt(Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), 2, 0);
      },
    ];

    for (int i = 1; i <= tests.length; i++) {
      test('level $i', () {
        _testBody(i, tests[i - 1]);
      });
    }
  });

  // ── Non-composer levels (47+) ───────────────────────────────────────────────
  group('Non-composer levels (47+)', () {

    // Shared helper: run a ComposerLevel through QuantumCircuit and return the
    // final state (runSimulation() is called automatically in the constructor).
    QuantumCircuit _simulate(ComposerLevel level) => QuantumCircuit(currentLevel: level);

    // Shorthand for the |+⟩ / Bell-diagonal amplitude.
    final s = math.sqrt1_2;

    // ── Structural sanity ───────────────────────────────────────────────────
    test('total level count is 54', () {
      expect(numberOfLevels, equals(54));
    });

    test('levels 47–54 have the expected types', () {
      expect(getQQLevelById(47), isA<McqLevel>());
      expect(getQQLevelById(48), isA<McqLevel>());
      expect(getQQLevelById(49), isA<MeasurementLabLevel>());
      expect(getQQLevelById(50), isA<MeasurementLabLevel>());
      expect(getQQLevelById(51), isA<FillTheGateLevel>());
      expect(getQQLevelById(52), isA<FillTheGateLevel>());
      expect(getQQLevelById(53), isA<CircuitReadingLevel>());
      expect(getQQLevelById(54), isA<CircuitReadingLevel>());
    });

    // ── MCQ ─────────────────────────────────────────────────────────────────
    group('MCQ', () {
      void _checkMcq(int levelId, int expectedCorrectIndex) {
        final level = getQQLevelById(levelId)! as McqLevel;
        expect(level.options.length, equals(4),
            reason: 'MCQ level $levelId must have exactly 4 options');
        expect(level.correctOptionIndex, inInclusiveRange(0, 3),
            reason: 'correctOptionIndex must be a valid index');
        expect(level.correctOptionIndex, equals(expectedCorrectIndex),
            reason: 'Wrong correctOptionIndex for level $levelId');
        expect(level.conceptIntro, isNotNull,
            reason: 'level $levelId missing conceptIntro');
        expect(level.solutionExplanation, isNotNull,
            reason: 'level $levelId missing solutionExplanation');
        expect(level.hints, isNotNull,
            reason: 'level $levelId missing hints');
        expect(level.hints!, isNotEmpty,
            reason: 'level $levelId hints list must not be empty');
        expect(level.taskDescription, isNotEmpty,
            reason: 'level $levelId missing taskDescription');
      }

      test('level 47 — What is Superposition?', () {
        // Correct: "In both |0⟩ and |1⟩ simultaneously…" (index 1)
        _checkMcq(47, 1);
      });

      test('level 48 — What is Entanglement?', () {
        // Correct: "Their joint state cannot be written as a product…" (index 2)
        _checkMcq(48, 2);
      });
    });

    // ── MeasurementLab ───────────────────────────────────────────────────────
    group('MeasurementLab', () {
      test('level 49 — Measure |+⟩: structure', () {
        final level = getQQLevelById(49)! as MeasurementLabLevel;
        expect(level.numQubits, equals(1));
        expect(level.requiredMeasurements, greaterThanOrEqualTo(1));
        expect(level.conceptIntro, isNotNull);
        expect(level.solutionExplanation, isNotNull);
        expect(level.hints, isNotNull);
        expect(level.hints!, isNotEmpty);
      });

      test('level 49 — Measure |+⟩: circuit simulates to (|0⟩+|1⟩)/√2', () {
        final level = getQQLevelById(49)! as MeasurementLabLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)],
          [Complex(s)],
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'Level 49 circuit should produce the |+⟩ state');
      });

      test('level 50 — Measure Bell State: structure', () {
        final level = getQQLevelById(50)! as MeasurementLabLevel;
        expect(level.numQubits, equals(2));
        expect(level.requiredMeasurements, greaterThanOrEqualTo(1));
        expect(level.conceptIntro, isNotNull);
        expect(level.solutionExplanation, isNotNull);
        expect(level.hints, isNotNull);
        expect(level.hints!, isNotEmpty);
      });

      test('level 50 — Measure Bell State: circuit simulates to (|00⟩+|11⟩)/√2', () {
        final level = getQQLevelById(50)! as MeasurementLabLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)],     // |00⟩
          [Complex.zero()], // |01⟩ — zero amplitude
          [Complex.zero()], // |10⟩ — zero amplitude
          [Complex(s)],     // |11⟩
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'Level 50 circuit should produce the Bell Φ+ state');
      });
    });

    // ── FillTheGate ──────────────────────────────────────────────────────────
    group('FillTheGate', () {
      void _checkFtgStructure(int levelId) {
        final level = getQQLevelById(levelId)! as FillTheGateLevel;
        expect(level.options.length, equals(4),
            reason: 'FillTheGate level $levelId must have exactly 4 options');
        expect(
          level.options.any((g) => g.type == level.correctGate.type),
          isTrue,
          reason: 'correctGate must appear in the options list',
        );
        expect(level.hints, isNotNull);
        expect(level.hints!, isNotEmpty);
        expect(level.solutionExplanation, isNotNull);
        expect(level.conceptIntro, isNotNull);
      }

      test('level 51 — Fill: Create |+⟩: structure', () {
        _checkFtgStructure(51);
        final level = getQQLevelById(51)! as FillTheGateLevel;
        expect(level.correctGate.type, equals(SelectedGateType.hadamard));
      });

      test('level 51 — Fill: Create |+⟩: correct gate simulation matches solution', () {
        final level = getQQLevelById(51)! as FillTheGateLevel;
        final circuit = _simulate(level.toComposerLevelWith(level.correctGate));
        expect(
          circuit.currentState.state.almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
          isTrue,
          reason: 'Filling with the correct gate must produce solutionFinalVector',
        );
      });

      test('level 51 — Fill: Create |+⟩: wrong gates do NOT match solution', () {
        final level = getQQLevelById(51)! as FillTheGateLevel;
        final wrongOptions = level.options.where((g) => g.type != level.correctGate.type);
        for (final wrong in wrongOptions) {
          final circuit = _simulate(level.toComposerLevelWith(wrong));
          expect(
            circuit.currentState.state.almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
            isFalse,
            reason: 'Gate ${wrong.type} should NOT match the solution',
          );
        }
      });

      test('level 52 — Fill: Flip the Bit: structure', () {
        _checkFtgStructure(52);
        final level = getQQLevelById(52)! as FillTheGateLevel;
        expect(level.correctGate.type, equals(SelectedGateType.x));
      });

      test('level 52 — Fill: Flip the Bit: correct gate simulation matches solution', () {
        final level = getQQLevelById(52)! as FillTheGateLevel;
        final circuit = _simulate(level.toComposerLevelWith(level.correctGate));
        expect(
          circuit.currentState.state.almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
          isTrue,
          reason: 'Filling with the correct gate must produce solutionFinalVector',
        );
      });

      test('level 52 — Fill: Flip the Bit: wrong gates do NOT match solution', () {
        final level = getQQLevelById(52)! as FillTheGateLevel;
        final wrongOptions = level.options.where((g) => g.type != level.correctGate.type);
        for (final wrong in wrongOptions) {
          final circuit = _simulate(level.toComposerLevelWith(wrong));
          expect(
            circuit.currentState.state.almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
            isFalse,
            reason: 'Gate ${wrong.type} should NOT match the solution',
          );
        }
      });
    });

    // ── CircuitReading ───────────────────────────────────────────────────────
    group('CircuitReading', () {
      void _checkCrStructure(int levelId, int expectedCorrectIndex) {
        final level = getQQLevelById(levelId)! as CircuitReadingLevel;
        expect(level.options.length, equals(4),
            reason: 'CircuitReading level $levelId must have exactly 4 options');
        expect(level.correctOptionIndex, inInclusiveRange(0, 3));
        expect(level.correctOptionIndex, equals(expectedCorrectIndex),
            reason: 'Wrong correctOptionIndex for level $levelId');
        expect(level.conceptIntro, isNotNull,
            reason: 'level $levelId missing conceptIntro');
        expect(level.solutionExplanation, isNotNull,
            reason: 'level $levelId missing solutionExplanation');
        expect(level.hints, isNotNull,
            reason: 'level $levelId missing hints');
        expect(level.hints!, isNotEmpty);
      }

      test('level 53 — Read: H Gate: structure', () {
        // Correct option index 2 → |+⟩ = (|0⟩+|1⟩)/√2
        _checkCrStructure(53, 2);
      });

      test('level 53 — Read: H Gate: circuit simulates to |+⟩', () {
        final level = getQQLevelById(53)! as CircuitReadingLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)],
          [Complex(s)],
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'H|0⟩ must equal |+⟩ = (|0⟩+|1⟩)/√2');
      });

      test('level 54 — Read: Bell State: structure', () {
        // Correct option index 1 → (|00⟩+|11⟩)/√2 = Φ+
        _checkCrStructure(54, 1);
      });

      test('level 54 — Read: Bell State: circuit simulates to Φ+', () {
        final level = getQQLevelById(54)! as CircuitReadingLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)],     // |00⟩
          [Complex.zero()], // |01⟩
          [Complex.zero()], // |10⟩
          [Complex(s)],     // |11⟩
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'H⊗I then CNOT on |00⟩ must produce Bell state Φ+');
      });
    });
  });
}