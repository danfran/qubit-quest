import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/discovery_progress.dart';
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

  group('Test results for legacy composer challenges', () {
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
      test('legacy level ${i + 50}', () {
        _testBody(i + 50, tests[i - 1]);
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
    test('total level count is 104', () {
      expect(numberOfLevels, equals(104));
    });

    test('levels 1–50 are the discovery campaign composer levels', () {
      for (int levelNumber = 1; levelNumber <= 50; levelNumber++) {
        expect(getQQLevelById(levelNumber), isA<ComposerLevel>());
      }
    });

    test('legacy challenge levels preserve the expected mixed types', () {
      for (int levelNumber = 51; levelNumber <= 96; levelNumber++) {
        expect(getQQLevelById(levelNumber), isA<ComposerLevel>());
      }
      expect(getQQLevelById(97), isA<McqLevel>());
      expect(getQQLevelById(98), isA<McqLevel>());
      expect(getQQLevelById(99), isA<MeasurementLabLevel>());
      expect(getQQLevelById(100), isA<MeasurementLabLevel>());
      expect(getQQLevelById(101), isA<FillTheGateLevel>());
      expect(getQQLevelById(102), isA<FillTheGateLevel>());
      expect(getQQLevelById(103), isA<CircuitReadingLevel>());
      expect(getQQLevelById(104), isA<CircuitReadingLevel>());
    });

    test('groupedLevels exposes the campaign before legacy challenges', () {
      expect(
        groupedLevels.map((category) => category.groupName).toList(),
        equals([
          'Chapter 1 - Information',
          'Chapter 2 - Hidden Change',
          'Chapter 3 - Superposition',
          'Chapter 4 - Interference',
          'Chapter 5 - Entanglement',
          'Chapter 6 - Information Flow',
          'Chapter 7 - GHZ States',
          'Chapter 8 - Phase Kickback',
          'Chapter 9 - Oracle Thinking',
          'Chapter 10 - Amplitude Amplification',
          'Legacy Challenges',
        ]),
      );
      expect(groupedLevels.first.from, equals(0));
      expect(groupedLevels.first.to, equals(4));
      expect(groupedLevels[9].from, equals(45));
      expect(groupedLevels[9].to, equals(49));
      expect(groupedLevels.last.from, equals(50));
      expect(groupedLevels.last.to, equals(103));
    });

    test('DiscoveryProgress follows the consolidated campaign sequence', () {
      expect(
        DiscoveryProgress.discoveryOrder,
        equals([
          'Information',
          'Reversibility',
          'Equivalent Results',
          'State Transformations',
          'The Quantum Bit',
          'Hidden Change',
          'Invisible Difference',
          'Relative Phase',
          'Phase Information',
          'Phase',
          'The Third State',
          'Two Possibilities',
          'Plus And Minus',
          'Not The Same',
          'Superposition',
          'Phase Is Hidden',
          'Phase Becomes Bit',
          'Bit Becomes Phase',
          'Interference',
          'Destructive Interference',
          'Two Qubits',
          'Correlation',
          'Bell State',
          'One Quantum System',
          'Entanglement',
          'Control',
          'Conditional Action',
          'Information Transfer',
          'Swap',
          'Information Flow',
          'Three Qubits',
          'Shared Information',
          'All Together',
          'GHZ State',
          'One System, Three Qubits',
          'Hidden Information',
          'Phase Carrier',
          'Phase Kickback',
          'Hidden Communication',
          'The Language of Quantum Algorithms',
          'A Special State',
          'Hidden Mark',
          'Oracle',
          'Invisible Mark',
          'Phase Marking',
          'Marked But Hidden',
          'Mark Becomes Probability',
          'Amplitude Amplification',
          'Mini Grover',
          'Search Through Interference',
        ]),
      );
    });

    test('DiscoveryProgress titles are unique for persistence', () {
      expect(
        DiscoveryProgress.discoveryOrder.toSet().length,
        equals(DiscoveryProgress.discoveryOrder.length),
      );
      expect(
          DiscoveryProgress.discoveryOrder, contains('Invisible Difference'));
      expect(DiscoveryProgress.discoveryOrder, contains('Invisible Mark'));
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

      test('level 97 — What is Superposition?', () {
        // Correct: "In both |0⟩ and |1⟩ simultaneously…" (index 1)
        _checkMcq(97, 1);
      });

      test('level 98 — What is Entanglement?', () {
        // Correct: "Their joint state cannot be written as a product…" (index 2)
        _checkMcq(98, 2);
      });
    });

    // ── MeasurementLab ───────────────────────────────────────────────────────
    group('MeasurementLab', () {
      test('level 99 — Measure |+⟩: structure', () {
        final level = getQQLevelById(99)! as MeasurementLabLevel;
        expect(level.numQubits, equals(1));
        expect(level.requiredMeasurements, greaterThanOrEqualTo(1));
        expect(level.conceptIntro, isNotNull);
        expect(level.solutionExplanation, isNotNull);
        expect(level.hints, isNotNull);
        expect(level.hints!, isNotEmpty);
      });

      test('level 99 — Measure |+⟩: circuit simulates to (|0⟩+|1⟩)/√2', () {
        final level = getQQLevelById(99)! as MeasurementLabLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)],
          [Complex(s)],
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'Level 99 circuit should produce the |+⟩ state');
      });

      test('level 100 — Measure Bell State: structure', () {
        final level = getQQLevelById(100)! as MeasurementLabLevel;
        expect(level.numQubits, equals(2));
        expect(level.requiredMeasurements, greaterThanOrEqualTo(1));
        expect(level.conceptIntro, isNotNull);
        expect(level.solutionExplanation, isNotNull);
        expect(level.hints, isNotNull);
        expect(level.hints!, isNotEmpty);
      });

      test(
          'level 100 — Measure Bell State: circuit simulates to (|00⟩+|11⟩)/√2',
          () {
        final level = getQQLevelById(100)! as MeasurementLabLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)], // |00⟩
          [Complex.zero()], // |01⟩ — zero amplitude
          [Complex.zero()], // |10⟩ — zero amplitude
          [Complex(s)], // |11⟩
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'Level 100 circuit should produce the Bell Φ+ state');
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

      test('level 101 — Fill: Create |+⟩: structure', () {
        _checkFtgStructure(101);
        final level = getQQLevelById(101)! as FillTheGateLevel;
        expect(level.correctGate.type, equals(SelectedGateType.hadamard));
      });

      test(
          'level 101 — Fill: Create |+⟩: correct gate simulation matches solution',
          () {
        final level = getQQLevelById(101)! as FillTheGateLevel;
        final circuit = _simulate(level.toComposerLevelWith(level.correctGate));
        expect(
          circuit.currentState.state
              .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
          isTrue,
          reason:
              'Filling with the correct gate must produce solutionFinalVector',
        );
      });

      test('level 101 — Fill: Create |+⟩: wrong gates do NOT match solution',
          () {
        final level = getQQLevelById(101)! as FillTheGateLevel;
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

      test('level 102 — Fill: Flip the Bit: structure', () {
        _checkFtgStructure(102);
        final level = getQQLevelById(102)! as FillTheGateLevel;
        expect(level.correctGate.type, equals(SelectedGateType.x));
      });

      test(
          'level 102 — Fill: Flip the Bit: correct gate simulation matches solution',
          () {
        final level = getQQLevelById(102)! as FillTheGateLevel;
        final circuit = _simulate(level.toComposerLevelWith(level.correctGate));
        expect(
          circuit.currentState.state
              .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
          isTrue,
          reason:
              'Filling with the correct gate must produce solutionFinalVector',
        );
      });

      test('level 102 — Fill: Flip the Bit: wrong gates do NOT match solution',
          () {
        final level = getQQLevelById(102)! as FillTheGateLevel;
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

      test('level 103 — Read: H Gate: structure', () {
        // Correct option index 2 → |+⟩ = (|0⟩+|1⟩)/√2
        _checkCrStructure(103, 2);
      });

      test('level 103 — Read: H Gate: circuit simulates to |+⟩', () {
        final level = getQQLevelById(103)! as CircuitReadingLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)],
          [Complex(s)],
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'H|0⟩ must equal |+⟩ = (|0⟩+|1⟩)/√2');
      });

      test('level 104 — Read: Bell State: structure', () {
        // Correct option index 1 → (|00⟩+|11⟩)/√2 = Φ+
        _checkCrStructure(104, 1);
      });

      test('level 104 — Read: Bell State: circuit simulates to Φ+', () {
        final level = getQQLevelById(104)! as CircuitReadingLevel;
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

    test('Chapter 4 level 20 validates the interference finale', () {
      final level = findComposerLevelByTitle('What Is Interference?');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 2, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 8 level 36 validates the hidden phase CNOT', () {
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

    test('Chapter 1 level 74 validates the first qubit flip', () {
      final level = findComposerLevelByTitle('The First Qubit');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 1 level 75 validates undoing the pre-built change', () {
      final level = findComposerLevelByTitle('Undo The Change');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 1 level 76 validates an equivalent longer path', () {
      final level = findComposerLevelByTitle('Different Paths');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 1 level 77 validates transforming |00> to |11>', () {
      final level = findComposerLevelByTitle('Information Patterns');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 1 level 78 validates the finale pattern change', () {
      final level = findComposerLevelByTitle('What Have We Learned?');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 2 level 79 requires the hidden Z operation', () {
      final level = findComposerLevelByTitle('Nothing Happened?');
      final emptyCircuit = simulate(level);
      expect(level.validateCircuit(emptyCircuit), isFalse);

      final circuit = simulate(level);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 2 level 80 validates the invisible difference', () {
      final level = findComposerLevelByTitle('The Invisible Difference');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 2 level 81 validates the minus sign', () {
      final level = findComposerLevelByTitle('The Minus Sign');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 2 level 82 validates hidden information', () {
      final level = findComposerLevelByTitle('Hidden Information');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 2 level 83 validates revealing phase', () {
      final level = findComposerLevelByTitle('What Did We Actually Discover?');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 3 level 84 validates the third state', () {
      final level = findComposerLevelByTitle('The Third State');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 3 level 85 validates fifty fifty', () {
      final level = findComposerLevelByTitle('Fifty Fifty');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 3 level 86 validates plus and minus', () {
      final level = findComposerLevelByTitle('Plus And Minus');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 3 level 87 validates revisiting the hidden difference', () {
      final level = findComposerLevelByTitle('Hidden Difference Revisited');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 3 level 88 validates the superposition finale', () {
      final level = findComposerLevelByTitle('What Is Superposition?');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 5 level 89 validates preparing two qubits together', () {
      final level = findComposerLevelByTitle('Together');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 5 level 90 validates connected qubits', () {
      final level = findComposerLevelByTitle('Connected');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 5 level 91 validates the Bell state', () {
      final level = findComposerLevelByTitle('The Bell State');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 5 level 92 validates more than correlation', () {
      final level = findComposerLevelByTitle('More Than Correlation');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 5 level 93 validates the entanglement finale', () {
      final level = findComposerLevelByTitle('What Is Entanglement?');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 6 level 94 validates the control qubit', () {
      final level = findComposerLevelByTitle('The Control Qubit');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 6 level 95 requires the conditional CX action', () {
      final level = findComposerLevelByTitle('Conditional Action');
      expect(level.validateCircuit(simulate(level)), isFalse);

      final circuit = simulate(level);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 6 level 96 validates information transfer', () {
      final level = findComposerLevelByTitle('Information Transfer');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 6 level 97 validates swap places', () {
      final level = findComposerLevelByTitle('Swap Places');
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

    test('Chapter 6 level 98 validates information flow', () {
      final level = findComposerLevelByTitle('Information Flow');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 0, 1);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 3, 0, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 7 level 99 validates three qubits', () {
      final level = findComposerLevelByTitle('Three Qubits');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 1, 1);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 2);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 7 level 100 validates shared information', () {
      final level = findComposerLevelByTitle('Shared Information');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 7 level 101 validates all together', () {
      final level = findComposerLevelByTitle('All Together');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 7 level 102 validates beyond Bell states', () {
      final level = findComposerLevelByTitle('Beyond Bell States');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 1);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 7 level 103 validates one system, three qubits', () {
      final level = findComposerLevelByTitle('One System, Three Qubits');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 3, 2, 1);
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
    test('all 104 levels have a non-null, non-empty title', () {
      for (int id = 1; id <= numberOfLevels; id++) {
        final level = getQQLevelById(id)!;
        expect(level.title, isNotNull,
            reason: 'Level $id is missing a title (null)');
        expect(level.title!, isNotEmpty,
            reason: 'Level $id has an empty title string');
      }
    });

    // ── Campaign spot-checks ────────────────────────────────────────────────
    test('campaign chapter boundaries are in the official order', () {
      expect(getQQLevelById(1)!.title, equals('The First Qubit'));
      expect(getQQLevelById(6)!.title, equals('Nothing Happened?'));
      expect(getQQLevelById(11)!.title, equals('The Third State'));
      expect(getQQLevelById(16)!.title, equals('Phase Is Hidden'));
      expect(getQQLevelById(20)!.title, equals('What Is Interference?'));
      expect(getQQLevelById(21)!.title, equals('Together'));
      expect(getQQLevelById(26)!.title, equals('The Control Qubit'));
      expect(getQQLevelById(31)!.title, equals('Three Qubits'));
      expect(getQQLevelById(36)!.title, equals('Something Changed'));
      expect(getQQLevelById(41)!.title, equals('The Special State'));
      expect(getQQLevelById(46)!.title, equals('The Mark Is Still Hidden'));
      expect(getQQLevelById(50)!.title, equals('Why Search Can Be Faster'));
    });

    test('legacy challenges start after the campaign', () {
      expect(getQQLevelById(51)!.title, equals('Bit Flip'));
      expect(getQQLevelById(97)!.title, equals('What is Superposition?'));
      expect(getQQLevelById(104)!.title, equals('Read: Bell State'));
    });
  });
}
