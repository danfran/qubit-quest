class ProgressionRules {
  const ProgressionRules._();

  static const int guidedDiscoveryLevelCount = 60;
  static const int journeyLevelCount = 114;

  static bool isMasteryLevel(int levelNumber) {
    return levelNumber > guidedDiscoveryLevelCount;
  }

  static int masteryChallengeNumber(int levelNumber) {
    return levelNumber - guidedDiscoveryLevelCount;
  }

  static bool masteryChallengesUnlocked(int maxUnlockedLevel) {
    return maxUnlockedLevel > guidedDiscoveryLevelCount;
  }

  static bool isLevelUnlocked({
    required int levelNumber,
    required int maxUnlockedLevel,
  }) {
    if (isMasteryLevel(levelNumber)) {
      return masteryChallengesUnlocked(maxUnlockedLevel);
    }
    return levelNumber <= maxUnlockedLevel;
  }
}
