import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/discovery_progress.dart';
import 'package:quantumquiz/models/mastery_completion_progress.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/utils/math_utils.dart';
import 'package:quantumquiz/validation/chapter_release_gate.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.s), 1, 0);
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
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      },
      (QuantumCircuit circuit) {
        circuit.insertTriplePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ccnot), 0, 1, 0, 2);
      },
      (QuantumCircuit circuit) {
        circuit.insertTriplePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ccnot), 0, 1, 0, 3);
      },
      (QuantumCircuit circuit) {
        // 20
        circuit.insertTriplePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ccnot), 1, 0, 1, 2);
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
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 2);
        circuit.insertDoublePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.cnot), 1, 0, 2);
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
            Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), 1, 0);
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
        // Solution: Ry(pi/3), then Rz(pi/2) on Q0.
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.ry, angle: math.pi / 3), 0, 0);
        circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 2), 1, 0);
      },
    ];

    for (int i = 1; i <= tests.length; i++) {
      test('legacy level ${i + 60}', () {
        _testBody(i + 60, tests[i - 1]);
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
    test('total level count is 114', () {
      expect(numberOfLevels, equals(114));
    });

    test('levels 1–60 are the discovery campaign levels', () {
      for (int levelNumber = 1; levelNumber <= 60; levelNumber++) {
        if (levelNumber == 35 ||
            levelNumber == 49 ||
            levelNumber == 50 ||
            (levelNumber >= 51 && levelNumber <= 60)) {
          expect(getQQLevelById(levelNumber), isA<ConceptCheckLevel>());
        } else {
          expect(getQQLevelById(levelNumber), isA<ComposerLevel>());
        }
      }
    });

    test('mastery challenge levels preserve the expected mixed types', () {
      expect(getQQLevelById(61), isA<CircuitReadingLevel>());
      expect(getQQLevelById(62), isA<McqLevel>());
      expect(getQQLevelById(63), isA<CircuitReadingLevel>());
      expect(getQQLevelById(64), isA<FillTheGateLevel>());
      expect(getQQLevelById(65), isA<ComposerLevel>());
      expect(getQQLevelById(66), isA<CircuitReadingLevel>());
      expect(getQQLevelById(67), isA<ComposerLevel>());
      expect(getQQLevelById(68), isA<FillTheGateLevel>());
      expect(getQQLevelById(69), isA<MeasurementLabLevel>());
      expect(getQQLevelById(70), isA<ComposerLevel>());
      expect(getQQLevelById(71), isA<CircuitReadingLevel>());
      for (int levelNumber = 72; levelNumber <= 106; levelNumber++) {
        expect(getQQLevelById(levelNumber), isA<ComposerLevel>());
      }
      expect(getQQLevelById(107), isA<McqLevel>());
      expect(getQQLevelById(108), isA<McqLevel>());
      expect(getQQLevelById(109), isA<MeasurementLabLevel>());
      expect(getQQLevelById(110), isA<MeasurementLabLevel>());
      expect(getQQLevelById(111), isA<FillTheGateLevel>());
      expect(getQQLevelById(112), isA<FillTheGateLevel>());
      expect(getQQLevelById(113), isA<CircuitReadingLevel>());
      expect(getQQLevelById(114), isA<CircuitReadingLevel>());
    });

    test('groupedLevels exposes guided discovery before mastery challenges',
        () {
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
          'Chapter 11 - Grover Loop Intuition',
          'Chapter 12 - Quantum Algorithm Structure',
          'Mastery Challenges',
        ]),
      );
      expect(groupedLevels.first.from, equals(0));
      expect(groupedLevels.first.to, equals(4));
      expect(groupedLevels[9].from, equals(45));
      expect(groupedLevels[9].to, equals(49));
      expect(groupedLevels[10].from, equals(50));
      expect(groupedLevels[10].to, equals(54));
      expect(groupedLevels[11].from, equals(55));
      expect(groupedLevels[11].to, equals(59));
      expect(groupedLevels.last.from, equals(60));
      expect(groupedLevels.last.to, equals(113));
      expect(groupedLevels.last.isMasteryPhase, isTrue);
      expect(groupedLevels.last.phasePurpose, equals('Concept Integration'));
    });

    test('Mastery Challenges carry educational metadata only', () {
      const allowedDifficulties = {
        'Beginner',
        'Intermediate',
        'Advanced',
        'Expert',
      };

      for (int levelNumber = 61; levelNumber <= 114; levelNumber++) {
        final level = getQQLevelById(levelNumber)!;

        expect(level.conceptsUsed, isNotEmpty);
        expect(allowedDifficulties, contains(level.difficulty));
        expect(level.relatedDiscoveryTitles, isNotEmpty);

        for (final discoveryTitle in level.relatedDiscoveryTitles) {
          expect(
            notebookEntriesByDiscoveryTitle,
            contains(discoveryTitle),
            reason:
                'Mastery Challenge $levelNumber links to an unknown discovery.',
          );
        }
      }
    });

    test('Progression keeps lessons gated but opens Mastery on fresh install',
        () {
      const freshInstallMaxUnlockedLevel = 1;

      expect(
        ProgressionRules.isLevelUnlocked(
          levelNumber: 1,
          maxUnlockedLevel: freshInstallMaxUnlockedLevel,
        ),
        isTrue,
      );
      expect(
        ProgressionRules.isLevelUnlocked(
          levelNumber: 2,
          maxUnlockedLevel: freshInstallMaxUnlockedLevel,
        ),
        isFalse,
      );
      expect(
        ProgressionRules.isLevelUnlocked(
          levelNumber: 61,
          maxUnlockedLevel: freshInstallMaxUnlockedLevel,
        ),
        isTrue,
      );
      expect(
        ProgressionRules.isLevelUnlocked(
          levelNumber: 114,
          maxUnlockedLevel: freshInstallMaxUnlockedLevel,
        ),
        isTrue,
      );
    });

    test('Progression unlocks all Mastery Challenges after Guided Discovery',
        () {
      const afterGuidedDiscovery =
          ProgressionRules.guidedDiscoveryLevelCount + 1;

      expect(
        ProgressionRules.masteryChallengesUnlocked(afterGuidedDiscovery),
        isTrue,
      );
      expect(
        ProgressionRules.isLevelUnlocked(
          levelNumber: 61,
          maxUnlockedLevel: afterGuidedDiscovery,
        ),
        isTrue,
      );
      expect(
        ProgressionRules.isLevelUnlocked(
          levelNumber: 114,
          maxUnlockedLevel: afterGuidedDiscovery,
        ),
        isTrue,
      );
    });

    test('Mastery completion progress persists completed challenge ids',
        () async {
      SharedPreferences.setMockInitialValues({});

      expect(await MasteryCompletionProgress.loadCompletedLevels(), isEmpty);

      await MasteryCompletionProgress.markCompleted(61);

      expect(
        await MasteryCompletionProgress.loadCompletedLevels(),
        equals({61}),
      );
    });

    test('Mastery complete dialog flag persists after first display', () async {
      SharedPreferences.setMockInitialValues({});

      expect(
        await MasteryCompletionProgress.hasShownMasteryCompleteDialog(),
        isFalse,
      );

      await MasteryCompletionProgress.markMasteryCompleteDialogShown();

      expect(
        await MasteryCompletionProgress.hasShownMasteryCompleteDialog(),
        isTrue,
      );
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
          'Precise Superposition',
          'Prepared Possibilities',
          'Superposition',
          'Phase Is Hidden',
          'Phase Becomes Bit',
          'Bit Becomes Phase',
          'Destructive Interference',
          'Interference',
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
          'Bias Becomes Amplification',
          'Amplification as Computational Advantage',
          'Why One Step Is Not Enough',
          'Iteration Improves Likelihood',
          'Convergence Toward Solution',
          'Classical vs Quantum Iteration',
          'Cognitive Transfer of Iteration Thinking',
          'Quantum Algorithm Structure',
          'Role Separation in Quantum Algorithms',
          'Why Composition Creates Advantage',
          'Classical vs Quantum Structural Difference',
          'Unified Quantum Algorithm Model',
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

    test('Quantum Notebook v1 entries unlock from discovery titles', () {
      expect(notebookEntriesByDiscoveryTitle['Invisible Difference']?.title,
          equals('Invisible Difference'));
      expect(notebookEntriesByDiscoveryTitle['Relative Phase']?.title,
          equals('The Minus Sign'));
      expect(notebookEntriesByDiscoveryTitle['Phase Information']?.title,
          equals('Hidden Information'));

      for (final entry in notebookEntries) {
        expect(
            DiscoveryProgress.discoveryOrder, contains(entry.discoveryTitle));
      }
    });

    test('Quantum Notebook covers Chapter 6 discovery levels', () {
      final chapter6DiscoveryTitles = [
        for (int levelNumber = 26; levelNumber <= 30; levelNumber++)
          getQQLevelById(levelNumber)!.discoveryTitle,
      ];

      expect(
        chapter6DiscoveryTitles,
        equals([
          'Control',
          'Conditional Action',
          'Information Transfer',
          'Swap',
          'Information Flow',
        ]),
      );

      for (final discoveryTitle in chapter6DiscoveryTitles) {
        expect(discoveryTitle, isNotNull);
        expect(
          notebookEntriesByDiscoveryTitle,
          contains(discoveryTitle),
        );
        expect(
          notebookEntriesByDiscoveryTitle[discoveryTitle]!.chapterIndex,
          equals(6),
        );
      }
    });

    test('Quantum Notebook covers Chapter 7 GHZ discovery levels', () {
      final chapter7DiscoveryTitles = [
        for (int levelNumber = 31; levelNumber <= 35; levelNumber++)
          getQQLevelById(levelNumber)!.discoveryTitle,
      ];

      expect(
        chapter7DiscoveryTitles,
        equals([
          'Three Qubits',
          'Shared Information',
          'All Together',
          'GHZ State',
          'One System, Three Qubits',
        ]),
      );

      for (final discoveryTitle in chapter7DiscoveryTitles) {
        expect(discoveryTitle, isNotNull);
        expect(
          notebookEntriesByDiscoveryTitle,
          contains(discoveryTitle),
        );
        expect(
          notebookEntriesByDiscoveryTitle[discoveryTitle]!.chapterIndex,
          equals(7),
        );
      }
    });

    test('Quantum Notebook covers Chapter 8 Phase Kickback discovery levels',
        () {
      final chapter8DiscoveryTitles = [
        for (int levelNumber = 36; levelNumber <= 40; levelNumber++)
          getQQLevelById(levelNumber)!.discoveryTitle,
      ];

      expect(
        chapter8DiscoveryTitles,
        equals([
          'Hidden Information',
          'Phase Carrier',
          'Phase Kickback',
          'Hidden Communication',
          'The Language of Quantum Algorithms',
        ]),
      );

      final chapter8NotebookTitles = [
        for (final discoveryTitle in chapter8DiscoveryTitles)
          notebookEntriesByDiscoveryTitle[discoveryTitle]?.title,
      ];

      expect(
        chapter8NotebookTitles,
        equals([
          'Hidden Mark',
          'Phase On The Control',
          'The Kickback Effect',
          'Setup Matters',
          'Compute → Encode → Reveal',
        ]),
      );

      for (final discoveryTitle in chapter8DiscoveryTitles) {
        expect(discoveryTitle, isNotNull);
        expect(
          notebookEntriesByDiscoveryTitle,
          contains(discoveryTitle),
        );
        expect(
          notebookEntriesByDiscoveryTitle[discoveryTitle]!.chapterIndex,
          equals(8),
        );
      }
    });

    test('Quantum Notebook covers Chapter 9 Oracle Thinking discovery levels',
        () {
      final chapter9DiscoveryTitles = [
        for (int levelNumber = 41; levelNumber <= 45; levelNumber++)
          getQQLevelById(levelNumber)!.discoveryTitle,
      ];

      expect(
        chapter9DiscoveryTitles,
        equals([
          'A Special State',
          'Hidden Mark',
          'Oracle',
          'Invisible Mark',
          'Phase Marking',
        ]),
      );

      final chapter9NotebookTitles = [
        for (final discoveryTitle in chapter9DiscoveryTitles)
          notebookEntriesByDiscoveryTitle[discoveryTitle]?.title,
      ];

      expect(
        chapter9NotebookTitles,
        equals([
          'Oracle Intuition',
          'Simple Marking Rule',
          'Hidden Structure Effect',
          'Why Classical Fails',
          'Oracle as Computation Primitive',
        ]),
      );

      for (final discoveryTitle in chapter9DiscoveryTitles) {
        expect(
          notebookEntriesByDiscoveryTitle[discoveryTitle]!.chapterIndex,
          equals(9),
        );
      }
    });

    test(
        'Quantum Notebook covers Chapter 10 Amplitude Amplification discovery levels',
        () {
      final chapter10DiscoveryTitles = [
        for (int levelNumber = 46; levelNumber <= 50; levelNumber++)
          getQQLevelById(levelNumber)!.discoveryTitle,
      ];

      expect(
        chapter10DiscoveryTitles,
        equals([
          'Marked But Hidden',
          'Mark Becomes Probability',
          'Amplitude Amplification',
          'Bias Becomes Amplification',
          'Amplification as Computational Advantage',
        ]),
      );

      final chapter10NotebookTitles = [
        for (final discoveryTitle in chapter10DiscoveryTitles)
          notebookEntriesByDiscoveryTitle[discoveryTitle]?.title,
      ];

      expect(
        chapter10NotebookTitles,
        equals([
          'Why Marking Is Not Enough',
          'First Sign of Bias',
          'Reinforcement of Probability',
          'Bias Becomes Amplification',
          'Amplification as Computational Advantage',
        ]),
      );

      for (final discoveryTitle in chapter10DiscoveryTitles) {
        expect(
          notebookEntriesByDiscoveryTitle[discoveryTitle]!.chapterIndex,
          equals(10),
        );
      }
    });

    test('Quantum Notebook covers Chapter 11 Grover Loop discovery levels', () {
      final chapter11DiscoveryTitles = [
        for (int levelNumber = 51; levelNumber <= 55; levelNumber++)
          getQQLevelById(levelNumber)!.discoveryTitle,
      ];

      expect(
        chapter11DiscoveryTitles,
        equals([
          'Why One Step Is Not Enough',
          'Iteration Improves Likelihood',
          'Convergence Toward Solution',
          'Classical vs Quantum Iteration',
          'Cognitive Transfer of Iteration Thinking',
        ]),
      );

      final chapter11NotebookTitles = [
        for (final discoveryTitle in chapter11DiscoveryTitles)
          notebookEntriesByDiscoveryTitle[discoveryTitle]?.title,
      ];

      expect(
        chapter11NotebookTitles,
        equals([
          'Why One Step Is Not Enough',
          'Iteration Improves Likelihood',
          'Convergence Toward Solution',
          'Classical vs Quantum Iteration',
          'Cognitive Transfer of Iteration Thinking',
        ]),
      );

      for (final discoveryTitle in chapter11DiscoveryTitles) {
        expect(
          notebookEntriesByDiscoveryTitle[discoveryTitle]!.chapterIndex,
          equals(11),
        );
      }
    });

    test('Quantum Notebook covers Chapter 12 algorithm structure levels', () {
      final chapter12DiscoveryTitles = [
        for (int levelNumber = 56; levelNumber <= 60; levelNumber++)
          getQQLevelById(levelNumber)!.discoveryTitle,
      ];

      expect(
        chapter12DiscoveryTitles,
        equals([
          'Quantum Algorithm Structure',
          'Role Separation in Quantum Algorithms',
          'Why Composition Creates Advantage',
          'Classical vs Quantum Structural Difference',
          'Unified Quantum Algorithm Model',
        ]),
      );

      final chapter12NotebookTitles = [
        for (final discoveryTitle in chapter12DiscoveryTitles)
          notebookEntriesByDiscoveryTitle[discoveryTitle]?.title,
      ];

      expect(
        chapter12NotebookTitles,
        equals([
          'Quantum Algorithm Structure',
          'Role Separation in Quantum Algorithms',
          'Why Composition Creates Advantage',
          'Classical vs Quantum Structural Difference',
          'Unified Quantum Algorithm Model',
        ]),
      );

      for (final discoveryTitle in chapter12DiscoveryTitles) {
        expect(
          notebookEntriesByDiscoveryTitle[discoveryTitle]!.chapterIndex,
          equals(12),
        );
      }
    });

    test('Chapter 7 notebook entries include GHZ global constraint language',
        () {
      final ghzEntry = notebookEntriesByDiscoveryTitle['GHZ State']!;
      final synthesisEntry =
          notebookEntriesByDiscoveryTitle['One System, Three Qubits']!;

      expect(ghzEntry.whatChanged!.body,
          contains('allowed vs forbidden global outcomes'));
      expect(ghzEntry.advancedNotes!.body,
          contains('state space restriction interpretation'));
      expect(synthesisEntry.whatChanged!.body,
          contains('forbidden global outcomes'));
      expect(synthesisEntry.quantumView!.examples.first.label,
          contains('State space restriction interpretation'));
    });

    test('Quantum Notebook chapter identities are stable', () {
      expect(
        notebookEntriesByDiscoveryTitle['Information']!.chapterIdentity,
        equals('How quantum information is stored and transformed'),
      );
      expect(
        notebookEntriesByDiscoveryTitle['Hidden Change']!.chapterIdentity,
        equals('How hidden properties affect states without visible change'),
      );
      expect(
        notebookEntriesByDiscoveryTitle['The Third State']!.chapterIdentity,
        equals('How quantum states are prepared and interpreted'),
      );
      expect(
        notebookEntriesByDiscoveryTitle['Interference']!.chapterIdentity,
        equals('How hidden phase becomes visible through interference'),
      );
      expect(
        notebookEntriesByDiscoveryTitle['Entanglement']!.chapterIdentity,
        equals('When quantum systems become inseparable'),
      );
      expect(
        notebookEntriesByDiscoveryTitle['Information Flow']!.chapterIdentity,
        equals('How information is created, controlled, and routed'),
      );
      expect(
        notebookEntriesByDiscoveryTitle['GHZ State']!.chapterIdentity,
        equals('How multi-qubit states become global constraints'),
      );
      expect(
        notebookEntriesByDiscoveryTitle['Phase Kickback']!.chapterIdentity,
        equals('How controlled operations write information into phase'),
      );
      expect(
        notebookEntriesByDiscoveryTitle['Oracle']!.chapterIdentity,
        equals(
          'How hidden rules classify valid inputs without revealing answers',
        ),
      );
      expect(
        notebookEntriesByDiscoveryTitle['Amplitude Amplification']!
            .chapterIdentity,
        equals('How probability is concentrated toward valid states'),
      );
      expect(
        notebookEntriesByDiscoveryTitle[
                'Cognitive Transfer of Iteration Thinking']!
            .chapterIdentity,
        equals('How repeated abstractions build search advantage'),
      );
      expect(
        notebookEntriesByDiscoveryTitle['Unified Quantum Algorithm Model']!
            .chapterIdentity,
        equals('How algorithm roles compose into structured advantage'),
      );
    });

    test('Quantum Notebook opened state tracks unread notebook entries',
        () async {
      SharedPreferences.setMockInitialValues({});

      await DiscoveryProgress.unlock('Information');

      expect(
        await DiscoveryProgress.hasUnopenedNotebookEntries(
          notebookEntriesByDiscoveryTitle.keys,
        ),
        isTrue,
      );

      await DiscoveryProgress.markNotebookEntryOpened('Information');

      expect(
        await DiscoveryProgress.hasUnopenedNotebookEntries(
          notebookEntriesByDiscoveryTitle.keys,
        ),
        isFalse,
      );
    });

    test('Chapter Release Gate passes Chapter 8 integration', () {
      final chapter8 = groupedLevels.firstWhere(
        (category) => category.groupName == 'Chapter 8 - Phase Kickback',
      );
      final result = ChapterReleaseGate.validateChapter(chapter8);

      expect(result.passed, isTrue, reason: result.toReport());
      expect(result.validatedSections,
          equals(ChapterReleaseGate.mandatorySections));
      expect(result.status, equals('PASS'));
    });

    test('Chapter Release Gate passes Chapter 9 abstraction', () {
      final chapter9 = groupedLevels.firstWhere(
        (category) => category.groupName == 'Chapter 9 - Oracle Thinking',
      );
      final result = ChapterReleaseGate.validateChapter(chapter9);

      expect(result.passed, isTrue, reason: result.toReport());
      expect(result.status, equals('PASS'));
    });

    test('Chapter Release Gate passes Chapter 10 probability abstraction', () {
      final chapter10 = groupedLevels.firstWhere(
        (category) =>
            category.groupName == 'Chapter 10 - Amplitude Amplification',
      );
      final result = ChapterReleaseGate.validateChapter(chapter10);

      expect(result.passed, isTrue, reason: result.toReport());
      expect(result.status, equals('PASS'));
    });

    test('Chapter Release Gate passes Chapter 11 iteration abstraction', () {
      final chapter11 = groupedLevels.firstWhere(
        (category) =>
            category.groupName == 'Chapter 11 - Grover Loop Intuition',
      );
      final result = ChapterReleaseGate.validateChapter(chapter11);

      expect(result.passed, isTrue, reason: result.toReport());
      expect(result.status, equals('PASS'));
    });

    test('Chapter Release Gate passes Chapter 12 meta synthesis', () {
      final chapter12 = groupedLevels.firstWhere(
        (category) =>
            category.groupName == 'Chapter 12 - Quantum Algorithm Structure',
      );
      final result = ChapterReleaseGate.validateChapter(chapter12);

      expect(result.passed, isTrue, reason: result.toReport());
      expect(result.status, equals('PASS'));
    });

    test('Chapter Release Gate validates the continuous curriculum', () {
      final result = ChapterReleaseGate.validateCurriculumJourney();

      expect(result.passed, isTrue, reason: result.toReport());
      expect(result.status, equals('PASS'));
      expect(
        result.validatedSections,
        contains('Phase 1 Concept Acquisition'),
      );
      expect(
        result.validatedSections,
        contains('Phase 2 Concept Integration'),
      );
    });

    test('Chapter Release Gate routes mastery through journey validation', () {
      final mastery = groupedLevels.firstWhere(
        (category) => category.groupName == 'Mastery Challenges',
      );
      final result = ChapterReleaseGate.validateChapter(mastery);

      expect(result.passed, isFalse);
      expect(result.status, equals('FAIL'));
      expect(
        result.failures,
        contains(contains('[Level System Validation]')),
      );
      expect(result.fixPlan, isNotEmpty);
    });

    test('initial wire labels identify Q0-top and preserve authored states',
        () {
      expect(
        QuantumCircuitPainter.initialQubitLabelsFor(
          initialQubitsStateStr: '|1⟩|−⟩',
          numQubits: 2,
        ),
        equals(['q0 |−⟩', 'q1 |1⟩']),
      );
      expect(
        QuantumCircuitPainter.initialQubitLabelsFor(
          initialQubitsStateStr: '|+⟩',
          numQubits: 1,
        ),
        equals(['q0 |+⟩']),
      );
      expect(
        QuantumCircuitPainter.initialQubitLabelsFor(
          initialQubitsStateStr: '10',
          numQubits: 2,
        ),
        equals(['q0 |0⟩', 'q1 |1⟩']),
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

      test('level 107 — What is Superposition?', () {
        // Correct: "In both |0⟩ and |1⟩ simultaneously…" (index 1)
        _checkMcq(107, 1);
      });

      test('level 108 — What is Entanglement?', () {
        // Correct: "Their joint state cannot be written as a product…" (index 2)
        _checkMcq(108, 2);
      });

      test('Chapter 7 level 35 — GHZ synthesis interpretation', () {
        _checkMcq(35, 0);
        final level = getQQLevelById(35)! as ConceptCheckLevel;

        expect(level.title, equals('One System, Three Qubits'));
        expect(level.badgeLabel, equals('Chapter Synthesis Check'));
        expect(level.discoveryTitle, equals('One System, Three Qubits'));
        expect(
          level.taskDescription,
          contains(r'(|000\rangle + |111\rangle)/\sqrt{2}'),
        );
        expect(
          level.options[level.correctOptionIndex],
          contains('Only the full-register outcomes |000⟩ and |111⟩'),
        );
        expect(
          level.options,
          contains(
              'The state means information moved from Q0 through Q1 to Q2.'),
        );
      });
    });

    // ── MeasurementLab ───────────────────────────────────────────────────────
    group('MeasurementLab', () {
      test('level 109 — Measure |+⟩: structure', () {
        final level = getQQLevelById(109)! as MeasurementLabLevel;
        expect(level.numQubits, equals(1));
        expect(level.requiredMeasurements, greaterThanOrEqualTo(1));
        expect(level.conceptIntro, isNotNull);
        expect(level.solutionExplanation, isNotNull);
        expect(level.hints, isNotNull);
        expect(level.hints!, isNotEmpty);
      });

      test('level 109 — Measure |+⟩: circuit simulates to (|0⟩+|1⟩)/√2', () {
        final level = getQQLevelById(109)! as MeasurementLabLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)],
          [Complex(s)],
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'Level 109 circuit should produce the |+⟩ state');
      });

      test('level 110 — Measure Bell State: structure', () {
        final level = getQQLevelById(110)! as MeasurementLabLevel;
        expect(level.numQubits, equals(2));
        expect(level.requiredMeasurements, greaterThanOrEqualTo(1));
        expect(level.conceptIntro, isNotNull);
        expect(level.solutionExplanation, isNotNull);
        expect(level.hints, isNotNull);
        expect(level.hints!, isNotEmpty);
      });

      test(
          'level 110 — Measure Bell State: circuit simulates to (|00⟩+|11⟩)/√2',
          () {
        final level = getQQLevelById(110)! as MeasurementLabLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)], // |00⟩
          [Complex.zero()], // |01⟩ — zero amplitude
          [Complex.zero()], // |10⟩ — zero amplitude
          [Complex(s)], // |11⟩
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'Level 110 circuit should produce the Bell Φ+ state');
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

      test('level 111 — Fill: Create |+⟩: structure', () {
        _checkFtgStructure(111);
        final level = getQQLevelById(111)! as FillTheGateLevel;
        expect(level.correctGate.type, equals(SelectedGateType.hadamard));
      });

      test(
          'level 111 — Fill: Create |+⟩: correct gate simulation matches solution',
          () {
        final level = getQQLevelById(111)! as FillTheGateLevel;
        final circuit = _simulate(level.toComposerLevelWith(level.correctGate));
        expect(
          circuit.currentState.state
              .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
          isTrue,
          reason:
              'Filling with the correct gate must produce solutionFinalVector',
        );
      });

      test('level 111 — Fill: Create |+⟩: wrong gates do NOT match solution',
          () {
        final level = getQQLevelById(111)! as FillTheGateLevel;
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

      test('level 112 — Fill: Flip the Bit: structure', () {
        _checkFtgStructure(112);
        final level = getQQLevelById(112)! as FillTheGateLevel;
        expect(level.correctGate.type, equals(SelectedGateType.x));
      });

      test(
          'level 112 — Fill: Flip the Bit: correct gate simulation matches solution',
          () {
        final level = getQQLevelById(112)! as FillTheGateLevel;
        final circuit = _simulate(level.toComposerLevelWith(level.correctGate));
        expect(
          circuit.currentState.state
              .almostEqualTo(QuantumMatrix(level.solutionFinalVector)),
          isTrue,
          reason:
              'Filling with the correct gate must produce solutionFinalVector',
        );
      });

      test('level 112 — Fill: Flip the Bit: wrong gates do NOT match solution',
          () {
        final level = getQQLevelById(112)! as FillTheGateLevel;
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

      test('level 113 — Read: H Gate: structure', () {
        // Correct option index 2 → |+⟩ = (|0⟩+|1⟩)/√2
        _checkCrStructure(113, 2);
      });

      test('level 113 — Read: H Gate: circuit simulates to |+⟩', () {
        final level = getQQLevelById(113)! as CircuitReadingLevel;
        final circuit = _simulate(level.toComposerLevel());
        final expected = QuantumMatrix([
          [Complex(s)],
          [Complex(s)],
        ]);
        expect(circuit.currentState.state.almostEqualTo(expected), isTrue,
            reason: 'H|0⟩ must equal |+⟩ = (|0⟩+|1⟩)/√2');
      });

      test('level 114 — Read: Bell State: structure', () {
        // Correct option index 1 → (|00⟩+|11⟩)/√2 = Φ+
        _checkCrStructure(114, 1);
      });

      test('level 114 — Read: Bell State: circuit simulates to Φ+', () {
        final level = getQQLevelById(114)! as CircuitReadingLevel;
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

    test('Lesson 17 HZH = X accepts H Z H as a final-state solution', () {
      final level = getQQLevelById(17)!;
      expect(level, isA<ComposerLevel>());

      final composerLevel = level as ComposerLevel;
      expect(composerLevel.title, 'HZH = X');
      expect(composerLevel.initialQubitsStateStr, '0');
      expect(
        composerLevel.availableGates.map((gate) => gate.type),
        equals([SelectedGateType.hadamard, SelectedGateType.z]),
      );
      expect(composerLevel.validationMode, ValidationMode.finalState);
      expect(composerLevel.targetUnitary, isNull);

      final circuit = simulate(composerLevel);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 2, 0);
      circuit.runSimulation();

      expect(
        matrixClose(
          circuit.currentState.state.toComplexList(),
          composerLevel.solutionFinalVector,
        ),
        isTrue,
      );
      expect(composerLevel.validateCircuit(circuit), isTrue);
    });

    test(
        'final-state validation accepts numerical differences within tolerance',
        () {
      final level = ComposerLevel.fromBinaryString(
        title: 'Tolerance final-state validation',
        taskDescription: 'Apply X to reach a numerically close |1> target.',
        initialQubitsStateString: '0',
        availableGates: [Gate.fromIdentifier(SelectedGateType.x)],
        solutionFinalVector: [
          [Complex(1e-10, 0)],
          [Complex(1 - 1e-10, 0)],
        ],
      );

      final circuit = simulate(level);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('global phase remains exact under current state comparison rule', () {
      final level = ComposerLevel.fromBinaryString(
        title: 'Exact global phase validation',
        taskDescription: 'Reach |1> exactly.',
        initialQubitsStateString: '0',
        availableGates: [Gate.fromIdentifier(SelectedGateType.y)],
        solutionFinalVector: [
          [Complex.zero()],
          [Complex.one()],
        ],
      );

      final circuit = simulate(level);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.y), 0, 0);
      circuit.runSimulation();

      expect(
        matrixClose(
          circuit.currentState.state.toComplexList(),
          level.solutionFinalVector,
        ),
        isFalse,
        reason:
            'The existing final-state rule compares displayed amplitudes exactly within tolerance.',
      );
      expect(level.validateCircuit(circuit), isFalse);
    });

    test('Lesson 17 incorrect circuits still fail', () {
      final level = findComposerLevelByTitle('HZH = X');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isFalse);
    });

    test('CNOT Fan-Out requires one control fanned out to two targets', () {
      final level = findComposerLevelByTitle('CNOT Fan-Out');

      expect(level.initialQubitsStateStr, '100');
      expect(
        level.availableGates.map((gate) => gate.type),
        equals([SelectedGateType.cnot]),
      );

      final fanOutCircuit = simulate(level);
      fanOutCircuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 2);
      fanOutCircuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 0, 2);
      fanOutCircuit.runSimulation();

      expect(level.validateCircuit(fanOutCircuit), isTrue);

      final oldShortcutCircuit = simulate(level);
      oldShortcutCircuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      oldShortcutCircuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 1, 2);
      oldShortcutCircuit.runSimulation();

      expect(
        matrixClose(
          oldShortcutCircuit.currentState.state.toComplexList(),
          level.solutionFinalVector,
        ),
        isFalse,
      );
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

    test('Chapter 4 level 19 validates destructive interference', () {
      final level = findComposerLevelByTitle('Make Zero Impossible');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 2, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 4 level 20 validates the interference finale', () {
      final level = findComposerLevelByTitle('What Is Interference?');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 2, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 8 level 36 validates hidden mark with CZ', () {
      final level = findComposerLevelByTitle('Hidden Mark');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 8 level 37 validates fixed-control phase carrier', () {
      final level = findComposerLevelByTitle('Control Affects Control');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 8 level 38 validates phase kickback onto control', () {
      final level = findComposerLevelByTitle('Unexpected Phase Change');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 8 level 39 requires same CX circuit for setup boundary', () {
      final level = findComposerLevelByTitle('Setup Matters');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 8 level 39 rejects empty circuit shortcut', () {
      final level = findComposerLevelByTitle('Setup Matters');
      final circuit = simulate(level);

      expect(level.validateCircuit(circuit), isFalse);
    });

    test('Chapter 8 level 40 validates compute encode reveal', () {
      final level = findComposerLevelByTitle('Compute, Encode, Reveal');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 9 level 64 validates marking the special state', () {
      final level = findComposerLevelByTitle('Oracle Intuition');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 9 level 65 validates marking without measuring', () {
      final level = findComposerLevelByTitle('Simple Marking Rule');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.z), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 9 level 66 validates building a |10> oracle', () {
      final level = findComposerLevelByTitle('Hidden Structure Effect');
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
      final level = findComposerLevelByTitle('Why Classical Fails');
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
      final level = findComposerLevelByTitle('Oracle as Computation Primitive');
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
      final level = findComposerLevelByTitle('Why Marking Is Not Enough');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 0, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 10 level 70 validates first sign of bias', () {
      final level = findComposerLevelByTitle('First Sign of Bias');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 10 level 71 validates weak reinforcement for |11>', () {
      final level = findComposerLevelByTitle('Reinforcement of Probability');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cz), 0, 1, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 10 level 72 is concept-only bias reinforcement', () {
      final level = getQQLevelById(49);

      expect(level, isA<ConceptCheckLevel>());
      final conceptCheck = level! as ConceptCheckLevel;
      expect(conceptCheck.title, equals('Bias Becomes Amplification'));
      expect(
        conceptCheck.discoveryTitle,
        equals('Bias Becomes Amplification'),
      );
      expect(conceptCheck.correctOptionIndex, equals(0));
      expect(
        conceptCheck.solutionExplanation,
        contains('stronger preference for |11⟩'),
      );
    });

    test('Chapter 10 level 73 is concept-only amplification synthesis', () {
      final level = getQQLevelById(50);

      expect(level, isA<ConceptCheckLevel>());
      final conceptCheck = level! as ConceptCheckLevel;
      expect(
        conceptCheck.title,
        equals('Amplification as Computational Advantage'),
      );
      expect(
        conceptCheck.discoveryTitle,
        equals('Amplification as Computational Advantage'),
      );
      expect(conceptCheck.correctOptionIndex, equals(0));
      expect(
        conceptCheck.solutionExplanation,
        contains('small probability advantage becomes a useful bias'),
      );
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

    test('Chapter 3 level 86 validates precise superposition', () {
      final level = findComposerLevelByTitle('Precise, Not Random');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 3 level 87 validates building the balance', () {
      final level = findComposerLevelByTitle('Build The Balance');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 0);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 3 level 88 validates the superposition finale', () {
      final level = findComposerLevelByTitle('What Is Superposition?');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 1);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 1, 1);
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
          Gate.fromIdentifier(SelectedGateType.cnot), 0, 0, 1);
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

    test('Chapter 6 level 110 validates swap places', () {
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

    test('Chapter 6 level 30 validates information flow', () {
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

    test('Chapter 6 level 30 accepts mirrored information flow', () {
      final level = findComposerLevelByTitle('Information Flow');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 0, 1);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 0, 1);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 3, 1, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 7 level 110 validates three qubits', () {
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

    test('Chapter 7 level 110 validates shared information', () {
      final level = findComposerLevelByTitle('Shared Information');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 7 level 110 exposes only CX after fixed X(q0)', () {
      final level = findComposerLevelByTitle('Shared Information');
      final circuit = simulate(level);

      expect(
        level.availableGates.map((gate) => gate.type),
        equals([SelectedGateType.cnot]),
      );
      expect(
          circuit.placedGates[0].first.gate.type, equals(SelectedGateType.x));
      expect(circuit.placedGates[0].first.isDeletable, isFalse);
    });

    test('Chapter 7 level 110 rejects independent X shortcut', () {
      final level = findComposerLevelByTitle('Shared Information');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 1, 1);
      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.x), 2, 2);
      circuit.runSimulation();

      expect(
        matrixClose(
          circuit.currentState.state.toComplexList(),
          level.solutionFinalVector,
        ),
        isTrue,
      );
      expect(level.validateCircuit(circuit), isFalse);
    });

    test('Chapter 7 level 110 rejects chain CX propagation', () {
      final level = findComposerLevelByTitle('Shared Information');
      final circuit = simulate(level);

      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 1);
      circuit.runSimulation();

      expect(
        matrixClose(
          circuit.currentState.state.toComplexList(),
          level.solutionFinalVector,
        ),
        isTrue,
      );
      expect(level.validateCircuit(circuit), isFalse);
    });

    test('Chapter 7 level 110 validates all together', () {
      final level = findComposerLevelByTitle('All Together');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 7 level 110 rejects chain CX propagation', () {
      final level = findComposerLevelByTitle('All Together');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 1);
      circuit.runSimulation();

      expect(
        matrixClose(
          circuit.currentState.state.toComplexList(),
          level.solutionFinalVector,
        ),
        isTrue,
      );
      expect(level.validateCircuit(circuit), isFalse);
    });

    test('Chapter 7 level 110 validates beyond Bell states', () {
      final level = findComposerLevelByTitle('Beyond Bell States');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 0);
      circuit.runSimulation();

      expect(level.validateCircuit(circuit), isTrue);
    });

    test('Chapter 7 level 110 rejects chain CX propagation', () {
      final level = findComposerLevelByTitle('Beyond Bell States');
      final circuit = simulate(level);

      circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 1, 1, 0);
      circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot), 2, 2, 1);
      circuit.runSimulation();

      expect(
        matrixClose(
          circuit.currentState.state.toComplexList(),
          level.solutionFinalVector,
        ),
        isTrue,
      );
      expect(level.validateCircuit(circuit), isFalse);
    });
  });

  group('Content accuracy 2.0.2', () {
    test('Mastery Challenge 40 describes Rx(pi/2)|0> instead of |+>', () {
      final level = getQQLevelById(100)! as ComposerLevel;

      expect(level.title, equals('Rx Rotation Gate'));
      expect(level.taskDescription, contains(r'Rx(\pi/2)|0\rangle'));
      expect(level.taskDescription, isNot(contains("'plus' state")));
      expect(level.taskDescription, isNot(contains(r'|+\rangle')));
      expect(
        level.targetStateExpression,
        equals('Rx(π/2)|0⟩ = (|0⟩ - i|1⟩)/√2'),
      );
      expect(
        level.solutionExplanation,
        contains('not the same quantum state'),
      );
      expect(
        level.solutionFinalVector[0][0],
        equals(Complex(math.sqrt1_2, 0)),
      );
      expect(
        level.solutionFinalVector[1][0],
        equals(Complex(0, -math.sqrt1_2)),
      );
    });

    test('Rz challenge uses relative phase on a superposition', () {
      final level = getQQLevelById(102)! as ComposerLevel;

      expect(level.title, equals('Rz — Phase Rotation'));
      expect(level.taskDescription, contains(r'|+i\rangle'));
      expect(
        level.targetStateExpression,
        equals('|+i⟩ = (|0⟩ + i|1⟩)/√2'),
      );
      expect(level.validationMode, ValidationMode.physicalState);
      expect(
        level.solutionFinalVector[0][0],
        equals(Complex(math.sqrt1_2, 0)),
      );
      expect(level.solutionFinalVector[1][0], equals(Complex(0, math.sqrt1_2)));
    });

    test('precise rotation challenge targets relative phase', () {
      final level = getQQLevelById(106)! as ComposerLevel;

      expect(level.title, equals('Precise Relative-Phase State'));
      expect(level.targetStateLabel, contains('relative phase'));
      expect(level.conceptIntro, contains('global phase'));
      expect(level.validationMode, ValidationMode.physicalState);
      expect(level.solutionExplanation, contains('relative phase'));
    });

    test('guided Bell state text matches the configured Bell targets', () {
      ComposerLevel composerByTitle(String title) {
        return allQQLevels
            .whereType<ComposerLevel>()
            .firstWhere((level) => level.title == title);
      }

      final phiPlus = composerByTitle('The Bell State');
      final psiPlus = composerByTitle('More Than Correlation');
      final phiMinus = composerByTitle('What Is Entanglement?');

      expect(phiPlus.targetStateLabel, equals('|Φ⁺⟩'));
      expect(phiPlus.solutionExplanation, contains('Bell state Φ⁺'));
      expect(psiPlus.targetStateLabel, equals('|Ψ⁺⟩'));
      expect(psiPlus.solutionExplanation, contains('same positive phase'));
      expect(psiPlus.solutionExplanation, isNot(contains('hidden sign')));
      expect(phiMinus.targetStateLabel, equals('|Φ⁻⟩'));
      expect(phiMinus.solutionExplanation, contains('|00⟩ and |11⟩'));
      expect(phiMinus.solutionExplanation, isNot(contains('|01⟩ and |10⟩')));
    });

    test('Bell notebook uses the same Phi-plus notation as lessons', () {
      final entry = notebookEntriesByDiscoveryTitle['Bell State']!;

      expect(entry.quantumView!.body, contains('Φ⁺'));
      expect(entry.quantumView!.body, isNot(contains('Φ+')));
      expect(
        entry.quantumView!.examples.map((example) => example.notation),
        contains('|Φ⁺⟩ = (|00⟩ + |11⟩)/√2'),
      );
    });
  });

  // ── Titles ─────────────────────────────────────────────────────────────────
  // All levels must have a non-null, non-empty title so the grid can
  // display it. Tests here cover: (1) exhaustive null/empty check, and
  // (2) one exact-string spot-check per category group to guard against
  // accidental renames or copy-paste errors.
  group('Titles', () {
    // ── Exhaustive: every level must have a title ──────────────────────────
    test('all 114 levels have a non-null, non-empty title', () {
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
      expect(getQQLevelById(36)!.title, equals('Hidden Mark'));
      expect(getQQLevelById(41)!.title, equals('Oracle Intuition'));
      expect(getQQLevelById(46)!.title, equals('Why Marking Is Not Enough'));
      expect(getQQLevelById(50)!.title,
          equals('Amplification as Computational Advantage'));
      expect(getQQLevelById(51)!.title, equals('Why One Step Is Not Enough'));
      expect(
          getQQLevelById(54)!.title, equals('Classical vs Quantum Iteration'));
      expect(getQQLevelById(55)!.title,
          equals('Applying Iteration Thinking to Structured Problems'));
      expect(getQQLevelById(56)!.title, equals('The Full Picture Appears'));
      expect(
          getQQLevelById(60)!.title, equals('Unified Quantum Algorithm Model'));
    });

    test('mastery challenges start after guided discovery', () {
      expect(getQQLevelById(61)!.title, equals('A Change That Cancels'));
      expect(getQQLevelById(107)!.title, equals('What is Superposition?'));
      expect(getQQLevelById(114)!.title, equals('Read: Bell State'));
    });
  });
}
