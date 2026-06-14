import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';

void main() {
  _testBody(int levelNumber, Function(QuantumCircuit) body) {
    final level = getQQLevelById(levelNumber)!;

    // Only ComposerLevels can be tested via circuit simulation
    if (level is! ComposerLevel) {
      debugPrint(
          'Level $levelNumber is ${level.runtimeType}, skipping circuit test.\n\n');
      return;
    }

    debugPrint('Level $levelNumber: ${level.taskDescription}\n\n');

    final circuit = QuantumCircuit(currentLevel: level);

    body(circuit);

    debugPrint('Circuit after inserting gates:\n$circuit');

    circuit.runSimulation();

    expect(level.validateCircuit(circuit), true);

    debugPrint('\n\n');
  }

  group('Test results for all levels', () {
    var tests = [
      (QuantumCircuit circuit) {
        // check X is in the avaiable gates
        //   assert(circuit.availableGates.contains(Gate.fromIdentifier(SelectedGateType.x)));
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.y), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.y), 0, 0);
      },
      (QuantumCircuit circuit) {
        // 5
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.z), 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.t), 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.s), 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.z), 1, 0);
      },
      (QuantumCircuit circuit) {
        // 10
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.s), 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.z), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.s), 3, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 4, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 5, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.s), 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.t), 2, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.z), 3, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 1);
      },
      (QuantumCircuit circuit) {
        // 15
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 2);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertTriplePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ccnot), 0, 1, 0, 2);
      },
      (QuantumCircuit circuit) {
        circuit.insertTriplePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ccnot), 0, 2, 1, 0);
      },
      (QuantumCircuit circuit) {
        // 20
        circuit.insertTriplePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ccnot), 0, 0, 1, 2);
      },
      (QuantumCircuit circuit) {
        // more than one solution, example X(0) + X(1)
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 0, 2);
        circuit.insertTriplePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ccnot), 1, 0, 1, 2);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 2, 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 3, 0);
      },
      (QuantumCircuit circuit) {
        // 25
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.z), 2, 1);
      },
      (QuantumCircuit circuit) {
        // 2 solution with Z(1)
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.z), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.z), 3, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 4, 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 5, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 1);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 2, 0, 1);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 2, 0);
      },
      (QuantumCircuit circuit) {
        // 30
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 0, 1);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        // to check if double solution present
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 0, 1);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.z), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 0, 1);
      },
      (QuantumCircuit circuit) {
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 0, 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 0, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 2, 0);
      },
      (QuantumCircuit circuit) {
        // 35
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1);
      },
      (QuantumCircuit circuit) {
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.x), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 1, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 2, 1, 0);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 3, 2, 1);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.z), 4, 2);
      },
      (QuantumCircuit circuit) {
        // double solution
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cz), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        // double solution
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cz), 2, 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 3, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard), 3, 1);
      },
      (QuantumCircuit circuit) {
        // 40
        // Solution: Rx(pi/2) on Q0
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), 0, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Ry(pi/2) on Q0
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2), 0, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Rz(pi/2) on Q0
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), 0, 0);
      },
      (QuantumCircuit circuit) {
        // Solution: Ry(-pi/2) on Q0
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ry, angle: -math.pi / 2),
            1,
            0);
      },
      (QuantumCircuit circuit) {
        // Solution: Ry(pi/2) on Q0
        // This gate is placed after the pre-inserted Rx gate.
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 2), 1, 0);
      },
      (QuantumCircuit circuit) {
        // 45
        // Solution: Rz(pi/4) on Q1
        // This gate is placed after the pre-inserted gates.
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 4), 2, 1);
      },
      (QuantumCircuit circuit) {
        // Solution: Rx(pi/2), Ry(pi/4), then Rz(pi/2) on Q0.
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 4), 1, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), 2, 0);
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
    QuantumCircuit _simulate(ComposerLevel level) =>
        QuantumCircuit(currentLevel: level);

    // Shorthand for the |+⟩ / Bell-diagonal amplitude.
    final s = math.sqrt1_2;

    // ── Structural sanity ───────────────────────────────────────────────────
    test('total level count is 73', () {
      expect(numberOfLevels, equals(73));
    });

    test('levels 47–73 have the expected types', () {
      expect(getQQLevelById(47), isA<McqLevel>());
      expect(getQQLevelById(48), isA<McqLevel>());
      expect(getQQLevelById(49), isA<MeasurementLabLevel>());
      expect(getQQLevelById(50), isA<MeasurementLabLevel>());
      expect(getQQLevelById(51), isA<FillTheGateLevel>());
      expect(getQQLevelById(52), isA<FillTheGateLevel>());
      expect(getQQLevelById(53), isA<CircuitReadingLevel>());
      expect(getQQLevelById(54), isA<CircuitReadingLevel>());
      expect(getQQLevelById(55), isA<ComposerLevel>());
      expect(getQQLevelById(56), isA<ComposerLevel>());
      expect(getQQLevelById(57), isA<ComposerLevel>());
      expect(getQQLevelById(58), isA<ComposerLevel>());
      expect(getQQLevelById(59), isA<ComposerLevel>());
      expect(getQQLevelById(60), isA<ComposerLevel>());
      expect(getQQLevelById(61), isA<ComposerLevel>());
      expect(getQQLevelById(62), isA<ComposerLevel>());
      expect(getQQLevelById(63), isA<ComposerLevel>());
      expect(getQQLevelById(64), isA<ComposerLevel>());
      expect(getQQLevelById(65), isA<ComposerLevel>());
      expect(getQQLevelById(66), isA<ComposerLevel>());
      expect(getQQLevelById(67), isA<ComposerLevel>());
      expect(getQQLevelById(68), isA<ComposerLevel>());
      expect(getQQLevelById(69), isA<ComposerLevel>());
      expect(getQQLevelById(70), isA<ComposerLevel>());
      expect(getQQLevelById(71), isA<ComposerLevel>());
      expect(getQQLevelById(72), isA<ComposerLevel>());
      expect(getQQLevelById(73), isA<ComposerLevel>());
    });

    test('initial qubit labels preserve authored ket tokens', () {
      expect(
        QuantumCircuitPainter.initialQubitLabelsFor(
          initialQubitsStateStr: '|1⟩|−⟩',
          numQubits: 2,
        ),
        equals(['|1⟩', '|−⟩']),
      );
      expect(
        QuantumCircuitPainter.initialQubitLabelsFor(
          initialQubitsStateStr: '|+⟩',
          numQubits: 1,
        ),
        equals(['|+⟩']),
      );
      expect(
        QuantumCircuitPainter.initialQubitLabelsFor(
          initialQubitsStateStr: '10',
          numQubits: 2,
        ),
        equals(['|1⟩', '|0⟩']),
      );
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
        expect(level.hints, isNotNull, reason: 'level $levelId missing hints');
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

      test('level 50 — Measure Bell State: circuit simulates to (|00⟩+|11⟩)/√2',
          () {
        final level = getQQLevelById(50)! as MeasurementLabLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)], // |00⟩
          [Complex.zero()], // |01⟩ — zero amplitude
          [Complex.zero()], // |10⟩ — zero amplitude
          [Complex(s)], // |11⟩
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

      test(
          'level 51 — Fill: Create |+⟩: correct gate simulation matches solution',
          () {
        final level = getQQLevelById(51)! as FillTheGateLevel;
        final circuit = _simulate(level.toComposerLevelWith(level.correctGate));
        expect(
          circuit.currentState.state
              .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
          isTrue,
          reason:
              'Filling with the correct gate must produce solutionFinalVector',
        );
      });

      test('level 51 — Fill: Create |+⟩: wrong gates do NOT match solution',
          () {
        final level = getQQLevelById(51)! as FillTheGateLevel;
        final wrongOptions =
            level.options.where((g) => g.type != level.correctGate.type);
        for (final wrong in wrongOptions) {
          final circuit = _simulate(level.toComposerLevelWith(wrong));
          expect(
            circuit.currentState.state
                .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
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

      test(
          'level 52 — Fill: Flip the Bit: correct gate simulation matches solution',
          () {
        final level = getQQLevelById(52)! as FillTheGateLevel;
        final circuit = _simulate(level.toComposerLevelWith(level.correctGate));
        expect(
          circuit.currentState.state
              .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
          isTrue,
          reason:
              'Filling with the correct gate must produce solutionFinalVector',
        );
      });

      test('level 52 — Fill: Flip the Bit: wrong gates do NOT match solution',
          () {
        final level = getQQLevelById(52)! as FillTheGateLevel;
        final wrongOptions =
            level.options.where((g) => g.type != level.correctGate.type);
        for (final wrong in wrongOptions) {
          final circuit = _simulate(level.toComposerLevelWith(wrong));
          expect(
            circuit.currentState.state
                .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
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
            reason:
                'CircuitReading level $levelId must have exactly 4 options');
        expect(level.correctOptionIndex, inInclusiveRange(0, 3));
        expect(level.correctOptionIndex, equals(expectedCorrectIndex),
            reason: 'Wrong correctOptionIndex for level $levelId');
        expect(level.conceptIntro, isNotNull,
            reason: 'level $levelId missing conceptIntro');
        expect(level.solutionExplanation, isNotNull,
            reason: 'level $levelId missing solutionExplanation');
        expect(level.hints, isNotNull, reason: 'level $levelId missing hints');
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
          [Complex(s)], // |00⟩
          [Complex.zero()], // |01⟩
          [Complex.zero()], // |10⟩
          [Complex(s)], // |11⟩
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'H⊗I then CNOT on 00⟩ must produce Bell state Φ+');
      });
    });
  });

  group('ComposerLevel validation modes', () {
    QuantumCircuit simulate(ComposerLevel level) =>
        QuantumCircuit(currentLevel: level);

    ComposerLevel findComposerLevelByTitle(String title) {
      for (int id = 1; id <= numberOfLevels; id++) {
        final level = getQQLevelById(id);
        if (level is ComposerLevel && level.title == title) {
          return level;
        }
      }
      throw StateError('ComposerLevel with title "$title" not found');
    }

    void insertTwoQubitDiffuser(QuantumCircuit circuit, int startPosition) {
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), startPosition, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), startPosition, 1);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), startPosition + 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), startPosition + 1, 1);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), startPosition + 2, 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), startPosition + 3, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), startPosition + 3, 1);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), startPosition + 4, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), startPosition + 4, 1);
    }

    test('finalState validation remains the default', () {
      final level = ComposerLevel.fromBinaryString(
        title: 'Default final-state validation',
        taskDescription: 'Apply X to reach |1>.',
        initialQubitsStateString: '0',
        availableGates: [Gate.fromIdentifier(SelectedGateType.x)],
        solutionFinalVector: [
          [Complex.zero()],
          [Complex.one()],
        ],
      );

      final circuit = simulate(level);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.runSimulation();

      expect(level.validationMode, ValidationMode.finalState);
      expect(level.validateCircuit(circuit), isTrue);
    });

    test('SWAP via Three CNOTs rejects two CNOTs even if |10> reaches |01>',
        () {
      final level = findComposerLevelByTitle('SWAP via Three CNOTs');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 1);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.runSimulation();

      expect(
        circuit.currentState.state
            .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
        isTrue,
        reason: 'Two CNOTs still map the configured |10> input to |01>.',
      );
      expect(level.validateCircuit(circuit), isFalse);
    });

    test('SWAP via Three CNOTs passes with the full three-CNOT unitary', () {
      final level = findComposerLevelByTitle('SWAP via Three CNOTs');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 1);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 0, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('unitary validation fails safely when targetUnitary is null', () {
      final level = ComposerLevel.fromBinaryString(
        title: 'Missing target unitary',
        taskDescription: 'Invalid unitary level',
        initialQubitsStateString: '0',
        availableGates: const [],
        solutionFinalVector: [
          [Complex.one()],
          [Complex.zero()],
        ],
        validationMode: ValidationMode.unitary,
      );

      expect(level.validateCircuit(simulate(level)), isFalse);
    });

    test('unitary validation fails safely on matrix dimension mismatch', () {
      final level = ComposerLevel.fromBinaryString(
        title: 'Mismatched target unitary',
        taskDescription: 'Invalid unitary dimensions',
        initialQubitsStateString: '0',
        availableGates: const [],
        solutionFinalVector: [
          [Complex.one()],
          [Complex.zero()],
        ],
        validationMode: ValidationMode.unitary,
        targetUnitary: [
          [Complex.one(), Complex.zero()],
          [Complex.zero(), Complex.one()],
          [Complex.zero(), Complex.zero()],
        ],
      );

      expect(level.validateCircuit(simulate(level)), isFalse);
    });

    test('Chapter 8 level 59 validates the hidden phase CNOT', () {
      final level = findComposerLevelByTitle('Something Changed');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 8 level 60 validates preparing the phase carrier', () {
      final level = findComposerLevelByTitle('The Hidden Passenger');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 8 level 61 validates first kickback', () {
      final level = findComposerLevelByTitle('First Kickback');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 8 level 62 validates hidden communication with CZ', () {
      final level = findComposerLevelByTitle('Information Without Flips');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 8 level 63 validates kickback then reveal', () {
      final level = findComposerLevelByTitle('The Quantum Secret');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 9 level 64 validates marking the special state', () {
      final level = findComposerLevelByTitle('The Special State');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 9 level 65 validates marking without measuring', () {
      final level = findComposerLevelByTitle('Mark Without Measuring');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 9 level 66 validates building a |10> oracle', () {
      final level = findComposerLevelByTitle('Build An Oracle');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 1, 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 9 level 67 validates identifying a |01> mark', () {
      final level = findComposerLevelByTitle('Which State Was Marked?');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 1);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 1, 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 9 level 68 validates preparing for Grover', () {
      final level = findComposerLevelByTitle('Preparing For Grover');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 1);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 1, 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 10 level 69 validates hidden mark only', () {
      final level = findComposerLevelByTitle('The Mark Is Still Hidden');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 10 level 70 validates interference revealing the mark', () {
      final level = findComposerLevelByTitle('Interference Reveals the Mark');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 10 level 71 validates amplifying |11>', () {
      final level = findComposerLevelByTitle('Amplify One State');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 0, 1, 0);
      insertTwoQubitDiffuser(circuit, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 10 level 72 validates mini Grover for |10>', () {
      final level = findComposerLevelByTitle('Mini Grover');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 1, 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      insertTwoQubitDiffuser(circuit, 3);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 10 level 73 validates mini Grover for |00>', () {
      final level = findComposerLevelByTitle('Why Search Can Be Faster');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 1);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 1, 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 1);
      insertTwoQubitDiffuser(circuit, 3);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });
  });

  // ── Titles ─────────────────────────────────────────────────────────────────
  // All levels must have a non-null, non-empty title so the grid can
  // display it. Tests here cover: (1) exhaustive null/empty check, and
  // (2) one exact-string spot-check per category group to guard against
  // accidental renames or copy-paste errors.
  group('Titles', () {
    // ── Exhaustive: every level must have a title ──────────────────────────
    test('all 73 levels have a non-null, non-empty title', () {
      for (int id = 1; id <= numberOfLevels; id++) {
        final level = getQQLevelById(id)!;
        expect(level.title, isNotNull,
            reason: 'Level $id is missing a title (null)');
        expect(level.title!, isNotEmpty,
            reason: 'Level $id has an empty title string');
      }
    });

    // ── Category spot-checks (one representative per group) ────────────────

    // Basic Gate Operations (levels 1–5)
    test('level 1  — "Bit Flip"', () {
      expect(getQQLevelById(1)!.title, equals('Bit Flip'));
    });

    // Superposition and Phase Gates (levels 6–13)
    test('level 6  — "Superposition"', () {
      expect(getQQLevelById(6)!.title, equals('Superposition'));
    });
    test('level 13 — "T† — Inverse Phase Gate"', () {
      expect(getQQLevelById(13)!.title, equals('T† — Inverse Phase Gate'));
    });

    // Controlled Gates (levels 14–21)
    test('level 14 — "CNOT Gate"', () {
      expect(getQQLevelById(14)!.title, equals('CNOT Gate'));
    });
    test('level 20 — "Toffoli Self-Inverse"', () {
      expect(getQQLevelById(20)!.title, equals('Toffoli Self-Inverse'));
    });

    // Entanglement & Disentanglement (levels 22–27)
    test('level 22 — "First Bell State Φ⁺"', () {
      expect(getQQLevelById(22)!.title, equals('First Bell State Φ⁺'));
    });
    test('level 25 — "Bell State Ψ⁻"', () {
      expect(getQQLevelById(25)!.title, equals('Bell State Ψ⁻'));
    });

    // Advanced 2-Qubit Puzzles (levels 28–32)
    test('level 28 — "SWAP via Three CNOTs"', () {
      expect(getQQLevelById(28)!.title, equals('SWAP via Three CNOTs'));
    });

    // Toffoli Gate Logic (levels 33–35)
    test('level 33 — "Long-Range CNOT"', () {
      expect(getQQLevelById(33)!.title, equals('Long-Range CNOT'));
    });

    // Advanced Entanglement and Algorithms (levels 36–39)
    test('level 36 — "Uniform 2-Qubit Superposition"', () {
      expect(
          getQQLevelById(36)!.title, equals('Uniform 2-Qubit Superposition'));
    });

    // Rotation Gates (levels 40–46) — first and last
    test('level 40 — "Rx Rotation Gate"', () {
      expect(getQQLevelById(40)!.title, equals('Rx Rotation Gate'));
    });
    test('level 46 — "Precise Bloch Sphere Navigation"', () {
      expect(
          getQQLevelById(46)!.title, equals('Precise Bloch Sphere Navigation'));
    });

    // Concept Checks — MCQ (levels 47–48)
    test('level 47 — "What is Superposition?"', () {
      expect(getQQLevelById(47)!.title, equals('What is Superposition?'));
    });
    test('level 48 — "What is Entanglement?"', () {
      expect(getQQLevelById(48)!.title, equals('What is Entanglement?'));
    });

    // Measurement Labs (levels 49–50)
    test('level 49 — "Measure |+⟩"', () {
      expect(getQQLevelById(49)!.title, equals('Measure |+⟩'));
    });
    test('level 50 — "Measure Bell State"', () {
      expect(getQQLevelById(50)!.title, equals('Measure Bell State'));
    });

    // Fill the Gate (levels 51–52)
    test('level 51 — "Fill: Create |+⟩"', () {
      expect(getQQLevelById(51)!.title, equals('Fill: Create |+⟩'));
    });
    test('level 52 — "Fill: Flip the Bit"', () {
      expect(getQQLevelById(52)!.title, equals('Fill: Flip the Bit'));
    });

    // Circuit Reading (levels 53–54)
    test('level 53 — "Read: H Gate"', () {
      expect(getQQLevelById(53)!.title, equals('Read: H Gate'));
    });
    test('level 54 — "Read: Bell State"', () {
      expect(getQQLevelById(54)!.title, equals('Read: Bell State'));
    });

    // Chapter 4 - Interference vertical slice (levels 55–58)
    test('level 55 — "Phase Is Hidden"', () {
      expect(getQQLevelById(55)!.title, equals('Phase Is Hidden'));
    });
    test('level 56 — "HZH = X"', () {
      expect(getQQLevelById(56)!.title, equals('HZH = X'));
    });
    test('level 57 — "HXH = Z"', () {
      expect(getQQLevelById(57)!.title, equals('HXH = Z'));
    });
    test('level 58 — "Make Zero Impossible"', () {
      expect(getQQLevelById(58)!.title, equals('Make Zero Impossible'));
    });

    // Chapter 8 - Phase Kickback vertical slice (levels 59–63)
    test('level 59 — "Something Changed"', () {
      expect(getQQLevelById(59)!.title, equals('Something Changed'));
    });
    test('level 60 — "The Hidden Passenger"', () {
      expect(getQQLevelById(60)!.title, equals('The Hidden Passenger'));
    });
    test('level 61 — "First Kickback"', () {
      expect(getQQLevelById(61)!.title, equals('First Kickback'));
    });
    test('level 62 — "Information Without Flips"', () {
      expect(getQQLevelById(62)!.title, equals('Information Without Flips'));
    });
    test('level 63 — "The Quantum Secret"', () {
      expect(getQQLevelById(63)!.title, equals('The Quantum Secret'));
    });

    // Chapter 9 - Oracle Thinking vertical slice (levels 64–68)
    test('level 64 — "The Special State"', () {
      expect(getQQLevelById(64)!.title, equals('The Special State'));
    });
    test('level 65 — "Mark Without Measuring"', () {
      expect(getQQLevelById(65)!.title, equals('Mark Without Measuring'));
    });
    test('level 66 — "Build An Oracle"', () {
      expect(getQQLevelById(66)!.title, equals('Build An Oracle'));
    });
    test('level 67 — "Which State Was Marked?"', () {
      expect(getQQLevelById(67)!.title, equals('Which State Was Marked?'));
    });
    test('level 68 — "Preparing For Grover"', () {
      expect(getQQLevelById(68)!.title, equals('Preparing For Grover'));
    });

    // Chapter 10 - Amplitude Amplification vertical slice (levels 69–73)
    test('level 69 — "The Mark Is Still Hidden"', () {
      expect(getQQLevelById(69)!.title, equals('The Mark Is Still Hidden'));
    });
    test('level 70 — "Interference Reveals the Mark"', () {
      expect(
        getQQLevelById(70)!.title,
        equals('Interference Reveals the Mark'),
      );
    });
    test('level 71 — "Amplify One State"', () {
      expect(getQQLevelById(71)!.title, equals('Amplify One State'));
    });
    test('level 72 — "Mini Grover"', () {
      expect(getQQLevelById(72)!.title, equals('Mini Grover'));
    });
    test('level 73 — "Why Search Can Be Faster"', () {
      expect(getQQLevelById(73)!.title, equals('Why Search Can Be Faster'));
    });
  });
}
