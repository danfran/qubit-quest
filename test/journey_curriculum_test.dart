// v2.6 M5: the Journey curriculum model (status, progress, actions,
// selection) and the scientific accuracy of the chapter illustrations.
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/journey_curriculum.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/widgets/journey_chapter_illustration.dart';

CampaignProgressState _after(int lessonsCompleted) {
  var state = CampaignProgressState.fresh();
  if (lessonsCompleted > 0) {
    state = CampaignProgressPolicy.completeLesson(state, lessonsCompleted);
  }
  return state;
}

void main() {
  final lessonCount = journeyLessons.length;

  group('curriculum status and progress', () {
    test('fresh user: chapter 1 available and active, rest locked', () {
      final c = JourneyCurriculum.of(CampaignProgressState.fresh());
      expect(c.chapters, hasLength(journeyChapters.length));
      expect(c.totalLessons, lessonCount);
      expect(c.completedLessons, 0);
      expect(c.completedChapters, 0);
      expect(c.chapters.first.status, JourneyChapterStatus.available);
      expect(c.chapters.first.isActive, isTrue);
      expect(
          c.chapters
              .skip(1)
              .every((ch) => ch.status == JourneyChapterStatus.locked),
          isTrue);
      expect(c.initialSelection, 0);
      expect(
          c.chapters.first.primaryAction.kind, JourneyChapterActionKind.start);
      expect(c.chapters.first.primaryAction.lessonId, 1);
    });

    test('partial progress: completed, in progress, locked, next lesson', () {
      // Chapters 1–2 are lessons 1–10; complete through lesson 12.
      final c = JourneyCurriculum.of(_after(12));
      expect(c.chapters[0].status, JourneyChapterStatus.completed);
      expect(c.chapters[1].status, JourneyChapterStatus.completed);
      expect(c.chapters[2].status, JourneyChapterStatus.inProgress);
      expect(c.chapters[2].completedLessons, 2);
      expect(c.chapters[2].nextLessonId, 13);
      expect(c.chapters[2].isActive, isTrue);
      expect(c.chapters[3].status, JourneyChapterStatus.locked);
      expect(c.chapters[3].prerequisiteLessonId, 15,
          reason: 'the final lesson of chapter 3 unlocks chapter 4');
      expect(c.completedChapters, 2);
      expect(c.completedLessons, 12);
      expect(c.initialSelection, 2);
      expect(c.chapters[2].primaryAction.kind, JourneyChapterActionKind.resume);
      expect(c.chapters[2].primaryAction.lessonId, 13);
      expect(c.chapters[0].primaryAction.kind, JourneyChapterActionKind.review);
      expect(c.chapters[3].primaryAction.lessonId, isNull);
    });

    test('finishing a chapter makes the next one available and active', () {
      final c = JourneyCurriculum.of(_after(5));
      expect(c.chapters[0].status, JourneyChapterStatus.completed);
      expect(c.chapters[1].status, JourneyChapterStatus.available);
      expect(c.chapters[1].isActive, isTrue);
      expect(c.initialSelection, 1);
    });

    test('completed curriculum: no active chapter, final chapter selected', () {
      final c = JourneyCurriculum.of(_after(lessonCount));
      expect(c.isComplete, isTrue);
      expect(c.activeChapterIndex, isNull);
      expect(c.initialSelection, c.chapters.length - 1);
      expect(
          c.chapters.every(
              (ch) => ch.primaryAction.kind == JourneyChapterActionKind.review),
          isTrue);
    });

    test('a stale or unknown selection falls back to the initial one', () {
      final c = JourneyCurriculum.of(_after(12));
      expect(c.validSelection(99), c.initialSelection);
      expect(c.validSelection(-1), c.initialSelection);
      expect(c.validSelection(null), c.initialSelection);
      expect(c.validSelection(0), 0);
    });

    test('the model never changes progress', () {
      final state = _after(7);
      final before = state.completedLessonIds.toSet();
      JourneyCurriculum.of(state)
        ..initialSelection
        ..chapters.map((ch) => ch.primaryAction).toList();
      expect(state.completedLessonIds, before);
      expect(state.maxUnlockedLevel, 8);
    });

    test('totals come from the curriculum, not constants', () {
      final c = JourneyCurriculum.of(CampaignProgressState.fresh());
      expect(c.totalLessons,
          journeyChapters.fold<int>(0, (s, ch) => s + ch.to - ch.from + 1));
    });
  });

  group('chapter illustrations match their captions', () {
    final r2 = 1 / math.sqrt(2);
    // Expected amplitudes (index = q(n−1)…q0 bits), derived by hand.
    final expected = <int, Map<int, Complex>>{
      2: {0: Complex(r2, 0), 1: Complex(-r2, 0)},
      3: {0: Complex(r2, 0), 2: Complex(r2, 0)},
      4: {0: Complex(1, 0)},
      5: {1: Complex(r2, 0), 2: Complex(r2, 0)},
      6: {7: Complex(1, 0)},
      7: {0: Complex(r2, 0), 7: Complex(r2, 0)},
      9: {
        0: Complex(.5, 0),
        1: Complex(.5, 0),
        2: Complex(.5, 0),
        3: Complex(-.5, 0)
      },
    };
    for (final entry in journeyChapterIllustrations.entries) {
      test('chapter ${entry.key}', () {
        final circuit = entry.value.createCircuit()..runSimulation();
        expect(circuit.lastSimulationError, isNull);
        final state = circuit.currentState.stateVector;
        final want = expected[entry.key];
        if (want != null) {
          for (var i = 0; i < state.length; i++) {
            final w = want[i] ?? Complex(0, 0);
            expect(state[i].real, closeTo(w.real.toDouble(), 1e-9),
                reason: 'amplitude $i');
            expect(state[i].imaginary, closeTo(w.imaginary.toDouble(), 1e-9));
          }
        }
        if (entry.key == 8) {
          // Phase kickback: q0 reads 1 with certainty (q1 stays in |−⟩).
          final p1 = [1, 3].fold<double>(
              0, (s, i) => s + math.pow(state[i].magnitude.toDouble(), 2));
          expect(p1, closeTo(1, 1e-9));
        }
        if (entry.key == 10) {
          // Two-qubit Grover: |11⟩ with certainty (global phase allowed).
          expect(state[3].magnitude.toDouble(), closeTo(1, 1e-9));
        }
        circuit.dispose();
      });
    }

    test('every gate of every illustration was placed', () {
      const gateCounts = {
        2: 2,
        3: 1,
        4: 2,
        5: 3,
        6: 3,
        7: 3,
        8: 5,
        9: 3,
        10: 12
      };
      for (final entry in journeyChapterIllustrations.entries) {
        final circuit = entry.value.createCircuit();
        expect(circuit.logicalGates, hasLength(gateCounts[entry.key]),
            reason: 'chapter ${entry.key}');
        circuit.dispose();
      }
    });

    // v2.6 M6a: a preview (often of a locked chapter) must never be the
    // complete solution of a lesson. A preview counts as a solution when a
    // learner could copy its gate sequence into a lesson (every gate type is
    // in that lesson's palette) and, after the lesson's fixed gates, it
    // passes the lesson's own evaluator.
    test('no chapter preview is the complete solution of any Journey lesson',
        () {
      final reveals = <String>[];
      for (final entry in journeyChapterIllustrations.entries) {
        final preview = entry.value.createCircuit();
        final types = preview.logicalGates.map((g) => g.type).toSet();
        final ordered = [...preview.logicalGates]
          ..sort((a, b) => a.column.compareTo(b.column));
        for (final (index, level) in journeyLessons.indexed) {
          if (level is! ComposerLevel ||
              level.numQubits != entry.value.qubits ||
              !types.every(level.availableGates.map((g) => g.type).contains)) {
            continue;
          }
          final circuit = QuantumCircuit(currentLevel: level);
          final offset =
              circuit.isCircuitEmpty() ? 0 : circuit.maxCircuitDepth();
          var placed = true;
          for (final gate in ordered) {
            final outcome = gate.controlQubit == null
                ? circuit.insertSingleGateWithOutcome(
                    gate.gate, offset + gate.column, gate.anchor.qubit)
                : circuit.insertDoubleGateWithOutcome(gate.gate,
                    offset + gate.column, gate.targetQubit!, gate.controlQubit!);
            placed = placed && outcome.changed;
          }
          circuit.runSimulation();
          if (placed && level.evaluateCircuit(circuit).success) {
            reveals.add('chapter ${entry.key} preview solves lesson '
                '${index + 1} (${level.title})');
          }
          circuit.dispose();
        }
        preview.dispose();
      }
      expect(reveals, isEmpty);
    });
  });

  test('captions never break inside a ket', () {
    const caption = 'the GHZ state (|000⟩ + |111⟩)/√2';
    final joined = keepKetsTogether(caption);
    expect(joined.replaceAll('\u2060', ''), caption);
    expect(joined, contains('(\u2060|\u20600\u20600\u20600\u2060⟩'));
  });
}
