import 'package:quantumquiz/models/campaign_progress.dart';

class MasteryCompletionProgress {
  const MasteryCompletionProgress._();

  static const String completedMasteryLevelsKey =
      SharedPreferencesCampaignProgressStore.legacyCompletedMasteryLevelsKey;
  static const String masteryCompleteDialogShownKey =
      SharedPreferencesCampaignProgressStore
          .legacyMasteryCompleteDialogShownKey;

  static Future<Set<int>> loadCompletedLevels() async {
    final controller = CampaignProgressController.instance;
    await controller.load();
    return controller.state.completedChallengeIds;
  }

  static Future<void> markCompleted(int levelNumber) async {
    final controller = CampaignProgressController.instance;
    await controller.load();
    await controller.completeChallenge(levelNumber);
  }

  static Future<bool> hasShownMasteryCompleteDialog() async {
    final controller = CampaignProgressController.instance;
    await controller.load();
    return controller.state.masteryCompleteDialogShown;
  }

  static Future<void> markMasteryCompleteDialogShown() async {
    final controller = CampaignProgressController.instance;
    await controller.load();
    await controller.markMasteryCompleteDialogShown();
  }
}
