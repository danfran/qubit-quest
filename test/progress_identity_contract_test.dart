import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/storage/app_storage.dart';

Set<int> lessonsThrough(int last) => {for (var id = 1; id <= last; id++) id};
Set<String> discoveriesThrough(int last) => {
      for (var id = 1; id <= last; id++)
        'discovery_${id.toString().padLeft(3, '0')}'
    };

// Historical identity fixture: intentionally independent of the live catalogue.
// Future discoveries may be appended; these identities must not move.
const historicalDiscoveryTitles = [
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
];

void main() {
  group('Historical progress identity guarantees', () {
    test('fresh storage grants no completions or discoveries', () async {
      final state = await SharedPreferencesCampaignProgressStore(
        storage: InMemoryAppStorage(),
      ).load();
      expect(state.maxUnlockedLevel, 1);
      expect(state.completedLessonIds, isEmpty);
      expect(state.completedChallengeIds, isEmpty);
      expect(state.completedMasterySemanticIds, isEmpty);
      expect(
          CampaignProgressPolicy.derivedUnlockedDiscoveryIds(state), isEmpty);
      expect(CampaignProgressPolicy.isLevelUnlocked(state, 1), isTrue);
      expect(CampaignProgressPolicy.isLevelUnlocked(state, 2), isFalse);
    });

    test('partial Journey grants only its completed lesson discoveries', () {
      final state = CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(),
        12,
      );
      expect(state.completedLessonIds, lessonsThrough(12));
      expect(state.maxUnlockedLevel, 13);
      expect(state.completedChallengeIds, isEmpty);
      expect(state.completedMasterySemanticIds, isEmpty);
      expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(state),
          discoveriesThrough(12));
    });

    test('original Journey completion contains exactly lessons 1 through 60',
        () {
      final state = CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(),
        60,
      );
      expect(state.completedLessonIds, lessonsThrough(60));
      expect(state.maxUnlockedLevel, 61);
      expect(state.completedChallengeIds, isEmpty);
      expect(state.completedMasterySemanticIds, isEmpty);
      expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(state),
          discoveriesThrough(60));
    });

    test('semantic Mastery survives storage without numeric reinterpretation',
        () async {
      final store = SharedPreferencesCampaignProgressStore(
        storage: InMemoryAppStorage(),
      );
      final state = CampaignProgressState(
        maxUnlockedLevel: 1,
        completedMasterySemanticIds: const {
          'global_phase_equivalence',
          'phase_kickback_conditions',
        },
      );
      await store.save(state);
      final restored = await store.load();
      expect(restored.completedMasterySemanticIds,
          state.completedMasterySemanticIds);
      expect(restored.completedLessonIds, isEmpty);
      expect(restored.completedChallengeIds, isEmpty);
      expect(restored.maxUnlockedLevel, 1);
      expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(restored),
          isEmpty);
    });

    for (final frontier in [1, 115]) {
      test(
          'legacy frontier $frontier keeps numeric Mastery separate on restart',
          () async {
        final storage = InMemoryAppStorage({
          'maxUnlockedCampaignLevel': frontier,
          'completedMasteryLevels': ['61', '66', '114'],
        });
        final migrated = await SharedPreferencesCampaignProgressStore(
          storage: storage,
        ).load();
        final restarted = await SharedPreferencesCampaignProgressStore(
          storage: storage,
        ).load();
        for (final state in [migrated, restarted]) {
          expect(state.completedLessonIds,
              frontier == 1 ? <int>{} : lessonsThrough(60));
          expect(state.completedChallengeIds, {61, 66, 114});
          expect(state.completedMasterySemanticIds, isEmpty);
          expect(state.maxUnlockedLevel, frontier == 115 ? 61 : frontier);
          expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(state),
              frontier == 1 ? <String>{} : discoveriesThrough(60));
        }
      });
    }

    test('canonical mixed progress wins over stale legacy mirrors', () async {
      final storage = InMemoryAppStorage({
        'qq_progress_schema_version': 2,
        'qq_progress_max_unlocked_level': 13,
        'qq_progress_completed_lesson_ids': [
          for (var i = 1; i <= 12; i++) '$i'
        ],
        'qq_progress_completed_challenge_ids': ['61', '114'],
        'qq_progress_completed_mastery_semantic_ids': [
          'global_phase_equivalence'
        ],
        'maxUnlockedCampaignLevel': 115,
        'completedMasteryLevels': ['66'],
      });
      final store = SharedPreferencesCampaignProgressStore(storage: storage);
      final state = await store.load();
      expect(state.completedLessonIds, lessonsThrough(12));
      expect(state.maxUnlockedLevel, 13);
      expect(state.completedChallengeIds, {61, 114});
      expect(state.completedMasterySemanticIds, {'global_phase_equivalence'});
      expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(state),
          discoveriesThrough(12));
      await store.save(state);
      final restored = await store.load();
      expect(restored.completedLessonIds, state.completedLessonIds);
      expect(restored.completedChallengeIds, state.completedChallengeIds);
      expect(restored.completedMasterySemanticIds,
          state.completedMasterySemanticIds);
      expect(restored.maxUnlockedLevel, 13);
    });

    test('explicit discoveries survive independently of Journey completion',
        () async {
      final store = SharedPreferencesCampaignProgressStore(
        storage: InMemoryAppStorage({
          'maxUnlockedCampaignLevel': 1,
          'unlockedDiscoveries': [
            'Information',
            'Amplification as Computational Advantage',
            'Renamed Legacy Discovery'
          ],
          'openedNotebookEntries': ['Information', 'Renamed Legacy Discovery'],
        }),
      );
      for (var restart = 0; restart < 2; restart++) {
        final state = await store.load();
        expect(state.completedLessonIds, isEmpty);
        expect(state.maxUnlockedLevel, 1);
        expect(state.explicitlyUnlockedDiscoveryIds,
            {'discovery_001', 'discovery_050'});
        expect(CampaignProgressPolicy.unlockedDiscoveryTitles(state), {
          'Information',
          'Amplification as Computational Advantage',
          'Renamed Legacy Discovery',
        });
        expect(CampaignProgressPolicy.openedDiscoveryTitles(state), {
          'Information',
          'Renamed Legacy Discovery',
        });
      }
    });

    test('all 60 historical discovery IDs, titles and lesson links stay stable',
        () {
      for (var index = 0; index < historicalDiscoveryTitles.length; index++) {
        final id = 'discovery_${(index + 1).toString().padLeft(3, '0')}';
        final title = historicalDiscoveryTitles[index];
        expect(CampaignProgressPolicy.discoveryTitleForId(id), title,
            reason: id);
        expect(CampaignProgressPolicy.discoveryIdForTitle(title), id,
            reason: title);
        expect(CampaignProgressPolicy.discoveryIdForLevel(index + 1), id,
            reason: 'Historical Journey lesson ${index + 1}');
      }
    });
  });

  group('Schema 3 migration', () {
    Map<String, Object> source(int count) => {
          'qq_progress_schema_version': 2,
          'qq_progress_max_unlocked_level': 115,
          'qq_progress_completed_lesson_ids': [
            for (var i = 1; i <= count; i++) '$i'
          ],
          'qq_progress_completed_challenge_ids': ['61', '66', '114'],
          'qq_progress_completed_mastery_semantic_ids': [
            'global_phase_equivalence'
          ],
          'qq_progress_unlocked_discovery_ids': ['discovery_050'],
          'qq_progress_mastery_complete_dialog_shown': true,
        };
    for (final count in [12, 60]) {
      test('canonical $count lessons ignores historical frontier115', () async {
        final storage = InMemoryAppStorage(source(count));
        final store = SharedPreferencesCampaignProgressStore(storage: storage);
        final state = await store.load();
        expect(state.schemaVersion, 3);
        expect(state.completedLessonIds, lessonsThrough(count));
        expect(state.completedLessonIds.contains(61), isFalse);
        expect(state.completedChallengeIds, {61, 66, 114});
        expect(state.completedMasterySemanticIds, {'global_phase_equivalence'});
        expect(state.maxUnlockedLevel, count + 1);
        expect(state.masteryCompleteDialogShown, isTrue);
        expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(state),
            {...discoveriesThrough(count), 'discovery_050'});
        final chapter = CampaignProgressPolicy.chapterProgress(state,
            firstLevel: 61, lastLevel: 66);
        expect(chapter.completed, isFalse);
        expect(chapter.completedLevels, 0);
        expect(chapter.locked, count < 60);
        final active = await storage
            .readString(SharedPreferencesCampaignProgressStore.activeV3Key);
        final record = await storage.readString(active!);
        await store.load();
        expect(await storage.readString(active), record);
        expect(await storage.readInt('qq_progress_max_unlocked_level'), 115);
        // Simulate an older binary saving/resetting its own keys after migration.
        await storage.writeInt('qq_progress_max_unlocked_level', 1);
        await storage.writeStringList('qq_progress_completed_lesson_ids', []);
        expect((await store.load()).completedLessonIds, lessonsThrough(count));
      });
    }
    for (final failure in ['stage', 'corrupt', 'activate', 'afterActivate']) {
      test('interruption at $failure preserves source and recovers', () async {
        final storage = FaultStorage(source(60))..failure = failure;
        final store = SharedPreferencesCampaignProgressStore(storage: storage);
        await expectLater(store.load(), throwsA(anything));
        expect(await storage.readInt('qq_progress_schema_version'), 2);
        expect(await storage.readStringList('qq_progress_completed_lesson_ids'),
            [for (var i = 1; i <= 60; i++) '$i']);
        storage.failure = null;
        final recovered =
            await SharedPreferencesCampaignProgressStore(storage: storage)
                .load();
        expect(recovered.completedLessonIds, lessonsThrough(60));
        expect(recovered.maxUnlockedLevel, 61);
        expect(recovered.completedChallengeIds, {61, 66, 114});
        expect(recovered.completedMasterySemanticIds,
            {'global_phase_equivalence'});
        expect(recovered.completedLessonIds.contains(61), isFalse);
      });
    }
    test('failed later save leaves the previous active record intact',
        () async {
      final storage = FaultStorage(source(12));
      final store = SharedPreferencesCampaignProgressStore(storage: storage);
      final state = await store.load();
      for (final failure in ['stage', 'corrupt', 'activate']) {
        storage.failure = failure;
        await expectLater(
            store.save(CampaignProgressPolicy.completeLesson(state, 13)),
            throwsA(anything));
        storage.failure = null;
        expect((await store.load()).completedLessonIds, lessonsThrough(12));
      }
    });
    test('sparse canonical completions are retained without filling gaps',
        () async {
      final storage = InMemoryAppStorage({
        ...source(0),
        'qq_progress_completed_lesson_ids': ['1', '3', '60', '61'],
      });
      final state =
          await SharedPreferencesCampaignProgressStore(storage: storage).load();
      expect(state.completedLessonIds, {1, 3, 60});
      expect(state.maxUnlockedLevel, 2);
      expect(state.completedChallengeIds, {61, 66, 114});
      expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(state),
          {'discovery_001', 'discovery_003', 'discovery_050', 'discovery_060'});
    });
    test('explicit reset clears both versions so stale source cannot resurrect',
        () async {
      final storage = InMemoryAppStorage(source(60));
      final store = SharedPreferencesCampaignProgressStore(storage: storage);
      await store.load();
      await store.reset();
      final state = await store.load();
      expect(state.completedLessonIds, isEmpty);
      expect(state.completedChallengeIds, isEmpty);
      expect(state.completedMasterySemanticIds, isEmpty);
      expect(state.maxUnlockedLevel, 1);
      expect(await storage.readInt('qq_progress_schema_version'), isNull);
    });
    test('unsupported source schema refuses migration without writes',
        () async {
      final storage = InMemoryAppStorage({'qq_progress_schema_version': 4});
      await expectLater(
          SharedPreferencesCampaignProgressStore(storage: storage).load(),
          throwsUnsupportedError);
      expect(await storage.readInt('qq_progress_schema_version'), 4);
      expect(
          await storage
              .readString(SharedPreferencesCampaignProgressStore.activeV3Key),
          isNull);
    });
    test('invalid active record fails closed instead of loading stale source',
        () async {
      final storage = InMemoryAppStorage(source(12));
      final store = SharedPreferencesCampaignProgressStore(storage: storage);
      await store.load();
      final slot = await storage
          .readString(SharedPreferencesCampaignProgressStore.activeV3Key);
      await storage.writeString(slot!, '{}');
      await expectLater(store.load(), throwsFormatException);
      expect(await storage.readString(slot), '{}');
    });
  });

  test('legacy decoding stays capped at60 with the real66-lesson catalogue',
      () async {
    final store = SharedPreferencesCampaignProgressStore(
        storage: InMemoryAppStorage({
      'maxUnlockedCampaignLevel': 115,
      'completedMasteryLevels': ['61', '114'],
    }));
    final state = await store.load();
    expect(state.completedLessonIds, lessonsThrough(60));
    expect(state.completedChallengeIds, {61, 114});
    expect(state.maxUnlockedLevel, 61);
    expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(state),
        discoveriesThrough(60));
  });
  test('real Journey61 completion coexists with archived Mastery61 on restart',
      () async {
    final store =
        SharedPreferencesCampaignProgressStore(storage: InMemoryAppStorage());
    final before = CampaignProgressPolicy.completeChallenge(
        CampaignProgressPolicy.completeLesson(
            CampaignProgressState.fresh(), 60),
        61);
    final after = CampaignProgressPolicy.completeLesson(before, 61);
    await store.save(after);
    final restored = await store.load();
    expect(restored.completedLessonIds, lessonsThrough(61));
    expect(restored.completedChallengeIds, {61});
    expect(restored.completedMasterySemanticIds, isEmpty);
    expect(restored.maxUnlockedLevel, 62);
  });
  test(
      'appended discovery is earned only by its lesson and retains explicit old unlocks',
      () async {
    final store = SharedPreferencesCampaignProgressStore(
        storage: InMemoryAppStorage({
      'maxUnlockedCampaignLevel': 1,
      'unlockedDiscoveries': [
        'Amplification as Computational Advantage',
        'Old title'
      ],
    }));
    final before = await store.load();
    expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(before),
        {'discovery_050'});
    final after = CampaignProgressPolicy.completeLesson(before, 61);
    await store.save(after);
    final restored = await store.load();
    expect(CampaignProgressPolicy.derivedUnlockedDiscoveryIds(restored),
        discoveriesThrough(61));
    expect(restored.legacyUnlockedDiscoveryTitles, {'Old title'});
    expect(
        CampaignProgressPolicy.derivedUnlockedDiscoveryIds(restored)
            .contains('discovery_062'),
        isFalse);
  });
}

class FaultStorage extends InMemoryAppStorage {
  FaultStorage(super.initialValues);
  String? failure;
  @override
  Future<void> writeString(String key, String value) async {
    final activation =
        key == SharedPreferencesCampaignProgressStore.activeV3Key;
    if ((!activation && failure == 'stage') ||
        (activation && failure == 'activate')) {
      throw StateError('Injected interrupted write');
    }
    await super
        .writeString(key, !activation && failure == 'corrupt' ? '{}' : value);
    if (activation && failure == 'afterActivate')
      throw StateError('Injected crash after commit');
  }
}
