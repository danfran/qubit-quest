import 'package:shared_preferences/shared_preferences.dart';

class MasteryCompletionProgress {
  const MasteryCompletionProgress._();

  static const String _completedMasteryLevelsKey = 'completedMasteryLevels';
  static const String _masteryCompleteDialogShownKey =
      'masteryCompleteDialogShown';

  static Future<Set<int>> loadCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_completedMasteryLevelsKey) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  static Future<void> markCompleted(int levelNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = (prefs.getStringList(_completedMasteryLevelsKey) ??
            const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet()
      ..add(levelNumber);
    final sortedCompleted = completed.toList()..sort();
    await prefs.setStringList(
      _completedMasteryLevelsKey,
      sortedCompleted.map((level) => level.toString()).toList(),
    );
  }

  static Future<bool> hasShownMasteryCompleteDialog() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_masteryCompleteDialogShownKey) ?? false;
  }

  static Future<void> markMasteryCompleteDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_masteryCompleteDialogShownKey, true);
  }
}
