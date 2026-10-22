enum NumericActivityDomain { journey, historicalMastery }

class ProgressionRules {
  const ProgressionRules._();

  static const int guidedDiscoveryLevelCount = 66;
  // Frozen historical identity domain, never derived from the live Journey size.
  static const int historicalJourneyCount = 60;
  static const int legacyMasteryFirstId = 61;
  static const int legacyMasteryLastId = 114;
  static const int historicalFrontierLimit = 115;
  static const int journeyLevelCount =
      legacyMasteryLastId; // Legacy campaign API.

  static bool isLegacyMasteryId(int id) =>
      id >= legacyMasteryFirstId && id <= legacyMasteryLastId;

  static bool isJourneyLessonUnlocked(
          {required int lessonId, required int maxUnlockedLevel}) =>
      lessonId >= 1 &&
      lessonId <= guidedDiscoveryLevelCount &&
      lessonId <= maxUnlockedLevel;

  // Compatibility API for the frozen pre-v2.5 numeric campaign only.
  static bool isMasteryLevel(int levelNumber) {
    return levelNumber >= legacyMasteryFirstId;
  }

  static int masteryChallengeNumber(int levelNumber) {
    return levelNumber - legacyMasteryFirstId + 1;
  }

  static bool masteryChallengesUnlocked(int maxUnlockedLevel) => true;

  static bool isLevelUnlocked({
    required int levelNumber,
    required int maxUnlockedLevel,
  }) {
    if (isMasteryLevel(levelNumber)) {
      return levelNumber <= journeyLevelCount;
    }
    return levelNumber <= maxUnlockedLevel;
  }
}
