import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/discovery_progress.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CampaignProgressPolicy', () {
    test('fresh install starts with the correct first lesson available', () {
      final state = CampaignProgressState.fresh();

      expect(state.maxUnlockedLevel, 1);
      expect(CampaignProgressPolicy.isLevelUnlocked(state, 1), isTrue);
      expect(CampaignProgressPolicy.isLevelUnlocked(state, 2), isFalse);
      expect(
          CampaignProgressPolicy.getMasteryChallengesUnlocked(state), isTrue);
    });

    test('completing the first lesson marks it complete and unlocks next', () {
      final state = CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(),
        1,
      );

      expect(state.completedLessonIds, contains(1));
      expect(state.maxUnlockedLevel, 2);
      expect(CampaignProgressPolicy.isLevelUnlocked(state, 2), isTrue);
    });

    test('completing the same lesson twice is idempotent', () {
      final once = CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(),
        1,
      );
      final twice = CampaignProgressPolicy.completeLesson(once, 1);

      expect(twice.maxUnlockedLevel, once.maxUnlockedLevel);
      expect(twice.completedLessonIds, once.completedLessonIds);
    });

    test('completing an earlier lesson does not regress later progress', () {
      final advanced = CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(),
        25,
      );
      final replayEarlier = CampaignProgressPolicy.completeLesson(advanced, 3);

      expect(replayEarlier.maxUnlockedLevel, 26);
      expect(replayEarlier.completedLessonIds, containsAll([1, 3, 25]));
    });

    test('completing lessons through a chapter unlocks the next chapter', () {
      var state = CampaignProgressState.fresh();
      for (var lesson = 1; lesson <= 5; lesson++) {
        state = CampaignProgressPolicy.completeLesson(state, lesson);
      }

      expect(state.maxUnlockedLevel, 6);
      final chapter1 = CampaignProgressPolicy.chapterProgress(
        state,
        firstLevel: 1,
        lastLevel: 5,
      );
      final chapter2 = CampaignProgressPolicy.chapterProgress(
        state,
        firstLevel: 6,
        lastLevel: 10,
      );
      expect(chapter1.completed, isTrue);
      expect(chapter2.current, isTrue);
    });

    test('Mastery Challenges are independent of lesson progress', () {
      final fresh = CampaignProgressState.fresh();
      final afterGuided = CampaignProgressPolicy.completeLesson(fresh, 60);

      expect(CampaignProgressPolicy.isLevelUnlocked(fresh, 61), isTrue);
      expect(CampaignProgressPolicy.isLevelUnlocked(fresh, 114), isTrue);
      expect(CampaignProgressPolicy.getMasteryChallengesUnlocked(afterGuided),
          isTrue);
      expect(CampaignProgressPolicy.isLevelUnlocked(afterGuided, 61), isTrue);
      expect(CampaignProgressPolicy.isLevelUnlocked(afterGuided, 114), isTrue);
    });

    test('completing a challenge does not advance the lesson frontier', () {
      final state = CampaignProgressPolicy.completeChallenge(
        CampaignProgressState.fresh(),
        100,
      );

      expect(state.completedChallengeIds, contains(100));
      expect(CampaignProgressPolicy.isLevelUnlocked(state, 114), isTrue);
      expect(state.maxUnlockedLevel, 1);
      expect(CampaignProgressPolicy.isLevelUnlocked(state, 2), isFalse);
    });

    test('Notebook discovery unlocks match lesson completion', () {
      final state = CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(),
        1,
      );

      expect(
        CampaignProgressPolicy.unlockedDiscoveryTitles(state),
        contains(allQQLevels.first.discoveryTitle),
      );
    });

    test('Continue Journey returns the correct next destination', () {
      final state = CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(),
        4,
      );
      final destination =
          CampaignProgressPolicy.continueJourneyDestination(state);

      expect(destination.isJourneyComplete, isFalse);
      expect(destination.levelNumber, 5);
    });

    test('fully completed campaign returns completed-state destination', () {
      final state = CampaignProgressPolicy.unlockAllCampaignContent(
        CampaignProgressState.fresh(),
      );
      final destination =
          CampaignProgressPolicy.continueJourneyDestination(state);

      expect(destination.isJourneyComplete, isTrue);
      expect(destination.levelNumber, isNull);
    });

    test('legacy level completion does not alter guided lesson completions',
        () {
      final state = CampaignProgressPolicy.completeChallenge(
        CampaignProgressState.fresh(),
        61,
      );

      expect(state.completedLessonIds, isEmpty);
      expect(state.completedChallengeIds, contains(61));
    });

    test(
        'title-renamed discoveries retain progress through stable-ID migration',
        () {
      final state = CampaignProgressState(
        maxUnlockedLevel: 1,
        explicitlyUnlockedDiscoveryIds: {'discovery_001'},
      );

      expect(
        CampaignProgressPolicy.unlockedDiscoveryTitles(state),
        contains(DiscoveryProgress.discoveryOrder.first),
      );
    });

    test('missing or corrupt values normalize safely', () {
      final state = CampaignProgressPolicy.normalize(
        CampaignProgressState(
          maxUnlockedLevel: -20,
          completedLessonIds: {-1, 1, 999},
          completedChallengeIds: {2, 61, 999},
        ),
      );

      expect(state.maxUnlockedLevel, 1);
      expect(state.completedLessonIds, {1});
      expect(state.completedChallengeIds, {61});
    });

    test('unlockAllCampaignContent produces a valid fully unlocked state', () {
      final state = CampaignProgressPolicy.unlockAllCampaignContent(
        CampaignProgressState.fresh(),
      );

      expect(state.maxUnlockedLevel, ProgressionRules.journeyLevelCount + 1);
      expect(state.completedLessonIds.length,
          ProgressionRules.guidedDiscoveryLevelCount);
      expect(state.completedChallengeIds.length, 54);
      expect(
          CampaignProgressPolicy.getMasteryChallengesUnlocked(state), isTrue);
    });

    test('reset restores the correct fresh-install state', () async {
      final controller = CampaignProgressController(
        store: InMemoryCampaignProgressStore(
          CampaignProgressPolicy.unlockAllCampaignContent(
            CampaignProgressState.fresh(),
          ),
        ),
      );
      await controller.load();
      await controller.resetProgress();

      expect(controller.state.maxUnlockedLevel, 1);
      expect(controller.state.completedLessonIds, isEmpty);
      expect(controller.state.completedChallengeIds, isEmpty);
    });

    test('Home and Learning Map derive the same chapter completion', () {
      final state = CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(),
        5,
      );
      final category = groupedLevels.first;
      final snapshot = CampaignProgressPolicy.chapterProgress(
        state,
        firstLevel: category.from + 1,
        lastLevel: category.to + 1,
      );

      expect(snapshot.completed, isTrue);
      expect(state.maxUnlockedLevel > category.to + 1, isTrue);
      expect(LearningMapScreen.conceptLinks, isNotEmpty);
    });

    test('out-of-order development completion remains monotonic', () {
      final state = CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(),
        20,
      );

      expect(state.maxUnlockedLevel, 21);
      expect(state.completedLessonIds,
          containsAll(List.generate(20, (i) => i + 1)));
    });
  });

  group('SharedPreferencesCampaignProgressStore', () {
    test('existing 2.0.0 stored progress migrates without loss', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesCampaignProgressStore
            .legacyMaxUnlockedCampaignLevelKey: 12,
        SharedPreferencesCampaignProgressStore.legacyCompletedMasteryLevelsKey:
            [
          '61',
          'bad',
          '62',
        ],
        SharedPreferencesCampaignProgressStore.legacyUnlockedDiscoveriesKey: [
          'Information',
          'Renamed Legacy Discovery',
        ],
        SharedPreferencesCampaignProgressStore.legacyOpenedNotebookEntriesKey: [
          'Information',
        ],
        SharedPreferencesCampaignProgressStore
            .legacyMasteryCompleteDialogShownKey: true,
      });

      final state = await const SharedPreferencesCampaignProgressStore().load();

      expect(state.maxUnlockedLevel, 12);
      expect(state.completedLessonIds,
          containsAll(List.generate(11, (i) => i + 1)));
      expect(state.completedChallengeIds, {61, 62});
      expect(state.explicitlyUnlockedDiscoveryIds, contains('discovery_001'));
      expect(state.legacyUnlockedDiscoveryTitles,
          contains('Renamed Legacy Discovery'));
      expect(state.openedDiscoveryIds, contains('discovery_001'));
      expect(state.masteryCompleteDialogShown, isTrue);
    });

    test('persistence round-trip reproduces the same canonical state',
        () async {
      SharedPreferences.setMockInitialValues({});
      const store = SharedPreferencesCampaignProgressStore();
      final saved = CampaignProgressPolicy.completeChallenge(
        CampaignProgressPolicy.completeLesson(
            CampaignProgressState.fresh(), 10),
        61,
      );

      await store.save(saved);
      final loaded = await store.load();

      expect(loaded.maxUnlockedLevel, saved.maxUnlockedLevel);
      expect(loaded.completedLessonIds, saved.completedLessonIds);
      expect(loaded.completedChallengeIds, saved.completedChallengeIds);
      expect(loaded.explicitlyUnlockedDiscoveryIds,
          saved.explicitlyUnlockedDiscoveryIds);
    });

    test('app restart after completion preserves progress', () async {
      SharedPreferences.setMockInitialValues({});
      const store = SharedPreferencesCampaignProgressStore();
      final controller = CampaignProgressController(store: store);
      await controller.load();
      await controller.completeLesson(1);

      final restarted = CampaignProgressController(store: store);
      await restarted.load();

      expect(restarted.state.maxUnlockedLevel, 2);
      expect(restarted.state.completedLessonIds, contains(1));
    });
  });
}
