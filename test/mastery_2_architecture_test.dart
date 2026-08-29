import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  MasteryChallengeDefinition definition({
    required String semanticId,
    required int displayOrder,
    MasteryDifficulty difficulty = MasteryDifficulty.foundation,
    MasteryInteractionType interaction = MasteryInteractionType.evidence,
  }) {
    return MasteryChallengeDefinition(
      semanticId: semanticId,
      displayOrder: displayOrder,
      title: semanticId.replaceAll('_', ' '),
      difficulty: difficulty,
      conceptTags: const {
        MasteryConceptTag.globalPhase,
        MasteryConceptTag.relativePhase,
      },
      interactionType: interaction,
      // Existing payloads are fixtures only; this test does not author Mastery 2
      // challenge content.
      levelDefinition: allQQLevels[61],
    );
  }

  group('MasteryChallengeCatalogue', () {
    test('display order may swap without changing semantic identity', () {
      final phase = definition(
        semanticId: 'global_phase_equivalence',
        displayOrder: 1,
      );
      final uncompute = definition(
        semanticId: 'phase_state_uncomputation',
        displayOrder: 2,
      );

      final reordered = MasteryChallengeCatalogue([
        phase.copyWith(displayOrder: 2),
        uncompute.copyWith(displayOrder: 1),
      ]);

      expect(reordered.orderedDefinitions.first.semanticId,
          'phase_state_uncomputation');
      expect(
        reordered.requireBySemanticId('global_phase_equivalence').semanticId,
        phase.semanticId,
      );
    });

    test('insertion does not alter existing identities', () {
      final first = definition(
        semanticId: 'global_phase_equivalence',
        displayOrder: 10,
      );
      final second = definition(
        semanticId: 'cnot_topology_inference',
        displayOrder: 30,
      );
      final inserted = definition(
        semanticId: 'same_histogram_different_state',
        displayOrder: 20,
      );
      final catalogue = MasteryChallengeCatalogue([first, inserted, second]);

      expect(
        catalogue.orderedDefinitions.map((item) => item.semanticId),
        [
          'global_phase_equivalence',
          'same_histogram_different_state',
          'cnot_topology_inference',
        ],
      );
      expect(catalogue.requireBySemanticId(first.semanticId), same(first));
      expect(catalogue.requireBySemanticId(second.semanticId), same(second));
    });

    test('duplicate semantic IDs are rejected', () {
      expect(
        () => MasteryChallengeCatalogue([
          definition(
            semanticId: 'global_phase_equivalence',
            displayOrder: 1,
          ),
          definition(
            semanticId: 'global_phase_equivalence',
            displayOrder: 99,
          ),
        ]),
        throwsStateError,
      );
    });

    test('semantic IDs are non-empty stable lower_snake_case keys', () {
      expect(
        MasteryChallengeDefinition.isValidSemanticId(
          'oracle_marked_state_inference',
        ),
        isTrue,
      );
      for (final invalid in ['', 'Challenge 1', '1_phase', 'phase-kickback']) {
        expect(
          () => definition(semanticId: invalid, displayOrder: 1),
          throwsArgumentError,
        );
      }
    });

    test('difficulty and interaction metadata never create access locks', () {
      final catalogue = MasteryChallengeCatalogue([
        definition(
          semanticId: 'foundation_prediction',
          displayOrder: 1,
          difficulty: MasteryDifficulty.foundation,
          interaction: MasteryInteractionType.prediction,
        ),
        definition(
          semanticId: 'advanced_algorithm_diagnosis',
          displayOrder: 2,
          difficulty: MasteryDifficulty.advanced,
          interaction: MasteryInteractionType.algorithm,
        ),
      ]);

      expect(catalogue.isAccessible('foundation_prediction'), isTrue);
      expect(catalogue.isAccessible('advanced_algorithm_diagnosis'), isTrue);
    });
  });

  group('semantic Mastery completion', () {
    test('completion round-trips by semantic ID, not display order', () async {
      SharedPreferences.setMockInitialValues({});
      const store = SharedPreferencesCampaignProgressStore();
      final controller = CampaignProgressController(store: store);
      await controller.load();
      await controller.completeMasteryChallenge('global_phase_equivalence');

      final restarted = CampaignProgressController(store: store);
      await restarted.load();

      expect(
        restarted.state.completedMasterySemanticIds,
        {'global_phase_equivalence'},
      );
      expect(restarted.state.completedChallengeIds, isEmpty);
    });

    test('discarding legacy Mastery completion preserves Journey progress', () {
      final state = CampaignProgressState(
        maxUnlockedLevel: 11,
        completedLessonIds: {
          for (var lesson = 1; lesson <= 10; lesson++) lesson
        },
        completedChallengeIds: const {61, 72, 114},
        completedMasterySemanticIds: const {'global_phase_equivalence'},
        masteryCompleteDialogShown: true,
      );

      final reset =
          CampaignProgressPolicy.discardLegacyMasteryCompletion(state);

      expect(reset.maxUnlockedLevel, 11);
      expect(reset.completedLessonIds, state.completedLessonIds);
      expect(reset.completedChallengeIds, isEmpty);
      expect(reset.completedMasterySemanticIds, {'global_phase_equivalence'});
      expect(reset.masteryCompleteDialogShown, isFalse);
    });

    test('Journey completion behavior is unchanged by semantic Mastery', () {
      final withMastery = CampaignProgressPolicy.completeMasteryChallenge(
        CampaignProgressState.fresh(),
        'phase_kickback_conditions',
      );
      final afterLesson = CampaignProgressPolicy.completeLesson(withMastery, 1);

      expect(afterLesson.maxUnlockedLevel, 2);
      expect(afterLesson.completedLessonIds, {1});
      expect(afterLesson.completedMasterySemanticIds,
          {'phase_kickback_conditions'});
    });
  });
}
