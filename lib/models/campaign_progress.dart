import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/discovery_catalog.dart' as discovery_catalog;
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class CampaignProgressState {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final int maxUnlockedLevel;
  final Set<int> completedLessonIds;
  final Set<int> completedChallengeIds;
  final Set<String> explicitlyUnlockedDiscoveryIds;
  final Set<String> legacyUnlockedDiscoveryTitles;
  final Set<String> openedDiscoveryIds;
  final Set<String> legacyOpenedDiscoveryTitles;
  final bool masteryCompleteDialogShown;

  CampaignProgressState({
    this.schemaVersion = currentSchemaVersion,
    required this.maxUnlockedLevel,
    Set<int> completedLessonIds = const {},
    Set<int> completedChallengeIds = const {},
    Set<String> explicitlyUnlockedDiscoveryIds = const {},
    Set<String> legacyUnlockedDiscoveryTitles = const {},
    Set<String> openedDiscoveryIds = const {},
    Set<String> legacyOpenedDiscoveryTitles = const {},
    this.masteryCompleteDialogShown = false,
  })  : completedLessonIds = Set.unmodifiable(completedLessonIds),
        completedChallengeIds = Set.unmodifiable(completedChallengeIds),
        explicitlyUnlockedDiscoveryIds =
            Set.unmodifiable(explicitlyUnlockedDiscoveryIds),
        legacyUnlockedDiscoveryTitles =
            Set.unmodifiable(legacyUnlockedDiscoveryTitles),
        openedDiscoveryIds = Set.unmodifiable(openedDiscoveryIds),
        legacyOpenedDiscoveryTitles =
            Set.unmodifiable(legacyOpenedDiscoveryTitles);

  factory CampaignProgressState.fresh() {
    return CampaignProgressState(maxUnlockedLevel: 1);
  }

  CampaignProgressState copyWith({
    int? schemaVersion,
    int? maxUnlockedLevel,
    Set<int>? completedLessonIds,
    Set<int>? completedChallengeIds,
    Set<String>? explicitlyUnlockedDiscoveryIds,
    Set<String>? legacyUnlockedDiscoveryTitles,
    Set<String>? openedDiscoveryIds,
    Set<String>? legacyOpenedDiscoveryTitles,
    bool? masteryCompleteDialogShown,
  }) {
    return CampaignProgressState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      maxUnlockedLevel: maxUnlockedLevel ?? this.maxUnlockedLevel,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      completedChallengeIds:
          completedChallengeIds ?? this.completedChallengeIds,
      explicitlyUnlockedDiscoveryIds:
          explicitlyUnlockedDiscoveryIds ?? this.explicitlyUnlockedDiscoveryIds,
      legacyUnlockedDiscoveryTitles:
          legacyUnlockedDiscoveryTitles ?? this.legacyUnlockedDiscoveryTitles,
      openedDiscoveryIds: openedDiscoveryIds ?? this.openedDiscoveryIds,
      legacyOpenedDiscoveryTitles:
          legacyOpenedDiscoveryTitles ?? this.legacyOpenedDiscoveryTitles,
      masteryCompleteDialogShown:
          masteryCompleteDialogShown ?? this.masteryCompleteDialogShown,
    );
  }
}

class ContinueJourneyDestination {
  final int? levelNumber;
  final bool isJourneyComplete;

  const ContinueJourneyDestination._({
    required this.levelNumber,
    required this.isJourneyComplete,
  });

  const ContinueJourneyDestination.level(int levelNumber)
      : this._(levelNumber: levelNumber, isJourneyComplete: false);

  const ContinueJourneyDestination.completed()
      : this._(levelNumber: null, isJourneyComplete: true);
}

class ChapterProgressSnapshot {
  final bool locked;
  final bool current;
  final bool completed;
  final int completedLevels;
  final int totalLevels;

  const ChapterProgressSnapshot({
    required this.locked,
    required this.current,
    required this.completed,
    required this.completedLevels,
    required this.totalLevels,
  });
}

class CampaignProgressPolicy {
  const CampaignProgressPolicy._();

  static int clampFrontier(int value) {
    return value.clamp(1, ProgressionRules.journeyLevelCount + 1).toInt();
  }

  static CampaignProgressState normalize(CampaignProgressState state) {
    final maxUnlockedLevel = clampFrontier(state.maxUnlockedLevel);
    final completedLessons = <int>{
      for (final id in state.completedLessonIds)
        if (_isGuidedLesson(id)) id,
    };
    final completedChallenges = <int>{
      for (final id in state.completedChallengeIds)
        if (ProgressionRules.isMasteryLevel(id) &&
            id <= ProgressionRules.journeyLevelCount)
          id,
    };

    return state.copyWith(
      schemaVersion: CampaignProgressState.currentSchemaVersion,
      maxUnlockedLevel: maxUnlockedLevel,
      completedLessonIds: completedLessons,
      completedChallengeIds: completedChallenges,
    );
  }

  static CampaignProgressState completeLevel(
    CampaignProgressState state,
    int levelNumber,
  ) {
    if (ProgressionRules.isMasteryLevel(levelNumber)) {
      return completeChallenge(state, levelNumber);
    }
    return completeLesson(state, levelNumber);
  }

  static CampaignProgressState completeLesson(
    CampaignProgressState state,
    int lessonId,
  ) {
    if (!_isGuidedLesson(lessonId)) return normalize(state);

    final nextFrontier = math.max(state.maxUnlockedLevel, lessonId + 1);
    final completedLessons = {...state.completedLessonIds};
    for (int id = 1; id <= lessonId; id++) {
      completedLessons.add(id);
    }

    final unlockedDiscoveries = {...state.explicitlyUnlockedDiscoveryIds};
    final discoveryId = discoveryIdForLevel(lessonId);
    if (discoveryId != null) unlockedDiscoveries.add(discoveryId);

    return normalize(
      state.copyWith(
        maxUnlockedLevel: nextFrontier,
        completedLessonIds: completedLessons,
        explicitlyUnlockedDiscoveryIds: unlockedDiscoveries,
      ),
    );
  }

  static CampaignProgressState completeChallenge(
    CampaignProgressState state,
    int challengeLevelId,
  ) {
    if (!ProgressionRules.isMasteryLevel(challengeLevelId) ||
        challengeLevelId > ProgressionRules.journeyLevelCount) {
      return normalize(state);
    }
    return normalize(
      state.copyWith(
        maxUnlockedLevel:
            math.max(state.maxUnlockedLevel, challengeLevelId + 1),
        completedChallengeIds: {
          ...state.completedChallengeIds,
          challengeLevelId,
        },
      ),
    );
  }

  static CampaignProgressState unlockDiscoveryByTitle(
    CampaignProgressState state,
    String discoveryTitle,
  ) {
    final normalized = discoveryTitle.trim();
    if (normalized.isEmpty) return normalize(state);
    final discoveryId = discoveryIdForTitle(normalized);
    if (discoveryId.isEmpty) {
      return normalize(
        state.copyWith(
          legacyUnlockedDiscoveryTitles: {
            ...state.legacyUnlockedDiscoveryTitles,
            normalized,
          },
        ),
      );
    }
    return normalize(
      state.copyWith(
        explicitlyUnlockedDiscoveryIds: {
          ...state.explicitlyUnlockedDiscoveryIds,
          discoveryId,
        },
      ),
    );
  }

  static CampaignProgressState markNotebookEntryOpened(
    CampaignProgressState state,
    String discoveryTitle,
  ) {
    final normalized = discoveryTitle.trim();
    if (normalized.isEmpty) return normalize(state);
    final discoveryId = discoveryIdForTitle(normalized);
    if (discoveryId.isEmpty) {
      return normalize(
        state.copyWith(
          legacyOpenedDiscoveryTitles: {
            ...state.legacyOpenedDiscoveryTitles,
            normalized,
          },
        ),
      );
    }
    return normalize(
      state.copyWith(
        openedDiscoveryIds: {...state.openedDiscoveryIds, discoveryId},
      ),
    );
  }

  static CampaignProgressState unlockAllCampaignContent(
    CampaignProgressState state,
  ) {
    return normalize(
      state.copyWith(
        maxUnlockedLevel: ProgressionRules.journeyLevelCount + 1,
        completedLessonIds: {
          for (int id = 1;
              id <= ProgressionRules.guidedDiscoveryLevelCount;
              id++)
            id,
        },
        completedChallengeIds: {
          for (int id = ProgressionRules.guidedDiscoveryLevelCount + 1;
              id <= ProgressionRules.journeyLevelCount;
              id++)
            id,
        },
        explicitlyUnlockedDiscoveryIds: discoveryIds.toSet(),
      ),
    );
  }

  static bool isLevelUnlocked(CampaignProgressState state, int levelNumber) {
    return ProgressionRules.isLevelUnlocked(
      levelNumber: levelNumber,
      maxUnlockedLevel: state.maxUnlockedLevel,
    );
  }

  static bool isLessonCompleted(CampaignProgressState state, int lessonId) {
    return state.completedLessonIds.contains(lessonId);
  }

  static bool isChallengeCompleted(CampaignProgressState state, int levelId) {
    return state.completedChallengeIds.contains(levelId);
  }

  static bool getMasteryChallengesUnlocked(CampaignProgressState state) {
    return ProgressionRules.masteryChallengesUnlocked(state.maxUnlockedLevel);
  }

  static ContinueJourneyDestination continueJourneyDestination(
    CampaignProgressState state,
  ) {
    if (state.maxUnlockedLevel > ProgressionRules.journeyLevelCount) {
      return const ContinueJourneyDestination.completed();
    }
    return ContinueJourneyDestination.level(state.maxUnlockedLevel);
  }

  static Set<String> unlockedDiscoveryTitles(CampaignProgressState state) {
    final titles = <String>{...state.legacyUnlockedDiscoveryTitles};
    for (final id in derivedUnlockedDiscoveryIds(state)) {
      final title = discoveryTitleForId(id);
      if (title != null) titles.add(title);
    }
    return titles;
  }

  static Set<String> openedDiscoveryTitles(CampaignProgressState state) {
    final titles = <String>{...state.legacyOpenedDiscoveryTitles};
    for (final id in state.openedDiscoveryIds) {
      final title = discoveryTitleForId(id);
      if (title != null) titles.add(title);
    }
    return titles;
  }

  static Set<String> derivedUnlockedDiscoveryIds(CampaignProgressState state) {
    return {
      ...state.explicitlyUnlockedDiscoveryIds,
      for (final lessonId in state.completedLessonIds)
        if (discoveryIdForLevel(lessonId) != null)
          discoveryIdForLevel(lessonId)!,
    };
  }

  static bool hasUnopenedNotebookEntries(
    CampaignProgressState state,
    Iterable<String> notebookDiscoveryTitles,
  ) {
    final unlocked = unlockedDiscoveryTitles(state);
    final opened = openedDiscoveryTitles(state);
    final notebookTitles = notebookDiscoveryTitles.toSet();
    return unlocked.intersection(notebookTitles).difference(opened).isNotEmpty;
  }

  static ChapterProgressSnapshot chapterProgress(
    CampaignProgressState state, {
    required int firstLevel,
    required int lastLevel,
  }) {
    final total = lastLevel - firstLevel + 1;
    final completed = List<int>.generate(total, (index) => firstLevel + index)
        .where((id) => isLessonCompleted(state, id))
        .length;
    final locked = state.maxUnlockedLevel < firstLevel;
    final isCompleted = state.maxUnlockedLevel > lastLevel;
    return ChapterProgressSnapshot(
      locked: locked,
      current: !locked && !isCompleted,
      completed: isCompleted,
      completedLevels: completed,
      totalLevels: total,
    );
  }

  static double campaignCompletionFraction(CampaignProgressState state) {
    final completedGuided = state.completedLessonIds.length;
    final completedMastery = state.completedChallengeIds.length;
    return ((completedGuided + completedMastery) /
            ProgressionRules.journeyLevelCount)
        .clamp(0.0, 1.0);
  }

  static String discoveryIdForTitle(String title) {
    final index = discovery_catalog.discoveryOrder.indexOf(title);
    if (index < 0) return '';
    return _discoveryIdForIndex(index);
  }

  static String? discoveryIdForLevel(int levelNumber) {
    if (levelNumber < 1 || levelNumber > allQQLevels.length) return null;
    final title = allQQLevels[levelNumber - 1].discoveryTitle?.trim();
    if (title == null || title.isEmpty) return null;
    final id = discoveryIdForTitle(title);
    return id.isEmpty ? null : id;
  }

  static String? discoveryTitleForId(String discoveryId) {
    final prefix = RegExp(r'^discovery_(\d{3})$');
    final match = prefix.firstMatch(discoveryId);
    if (match == null) return null;
    final index = int.parse(match.group(1)!) - 1;
    if (index < 0 || index >= discovery_catalog.discoveryOrder.length) {
      return null;
    }
    return discovery_catalog.discoveryOrder[index];
  }

  static List<String> get discoveryIds => [
        for (int index = 0;
            index < discovery_catalog.discoveryOrder.length;
            index++)
          _discoveryIdForIndex(index),
      ];

  static String _discoveryIdForIndex(int index) {
    return 'discovery_${(index + 1).toString().padLeft(3, '0')}';
  }

  static bool _isGuidedLesson(int id) {
    return id >= 1 && id <= ProgressionRules.guidedDiscoveryLevelCount;
  }
}

abstract class CampaignProgressStore {
  Future<CampaignProgressState> load();
  Future<void> save(CampaignProgressState state);
  Future<void> reset();
}

class SharedPreferencesCampaignProgressStore implements CampaignProgressStore {
  const SharedPreferencesCampaignProgressStore();

  static const schemaVersionKey = 'qq_progress_schema_version';
  static const maxUnlockedLevelKey = 'qq_progress_max_unlocked_level';
  static const completedLessonIdsKey = 'qq_progress_completed_lesson_ids';
  static const completedChallengeIdsKey = 'qq_progress_completed_challenge_ids';
  static const unlockedDiscoveryIdsKey = 'qq_progress_unlocked_discovery_ids';
  static const legacyUnlockedDiscoveryTitlesKey =
      'qq_progress_legacy_unlocked_discovery_titles';
  static const openedDiscoveryIdsKey = 'qq_progress_opened_discovery_ids';
  static const legacyOpenedDiscoveryTitlesKey =
      'qq_progress_legacy_opened_discovery_titles';
  static const masteryCompleteDialogShownKey =
      'qq_progress_mastery_complete_dialog_shown';

  static const legacyMaxUnlockedCampaignLevelKey = 'maxUnlockedCampaignLevel';
  static const legacyCompletedMasteryLevelsKey = 'completedMasteryLevels';
  static const legacyMasteryCompleteDialogShownKey =
      'masteryCompleteDialogShown';
  static const legacyUnlockedDiscoveriesKey = 'unlockedDiscoveries';
  static const legacyOpenedNotebookEntriesKey = 'openedNotebookEntries';

  @override
  Future<CampaignProgressState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCanonical = prefs.containsKey(schemaVersionKey);
    final canonical = hasCanonical ? _loadCanonical(prefs) : null;
    final legacy =
        hasCanonical ? CampaignProgressState.fresh() : _loadLegacy(prefs);

    final merged = CampaignProgressPolicy.normalize(
      CampaignProgressState(
        schemaVersion: CampaignProgressState.currentSchemaVersion,
        maxUnlockedLevel: math.max(
          canonical?.maxUnlockedLevel ?? 1,
          legacy.maxUnlockedLevel,
        ),
        completedLessonIds: {
          ...?canonical?.completedLessonIds,
          ...legacy.completedLessonIds,
        },
        completedChallengeIds: {
          ...?canonical?.completedChallengeIds,
          ...legacy.completedChallengeIds,
        },
        explicitlyUnlockedDiscoveryIds: {
          ...?canonical?.explicitlyUnlockedDiscoveryIds,
          ...legacy.explicitlyUnlockedDiscoveryIds,
        },
        legacyUnlockedDiscoveryTitles: {
          ...?canonical?.legacyUnlockedDiscoveryTitles,
          ...legacy.legacyUnlockedDiscoveryTitles,
        },
        openedDiscoveryIds: {
          ...?canonical?.openedDiscoveryIds,
          ...legacy.openedDiscoveryIds,
        },
        legacyOpenedDiscoveryTitles: {
          ...?canonical?.legacyOpenedDiscoveryTitles,
          ...legacy.legacyOpenedDiscoveryTitles,
        },
        masteryCompleteDialogShown:
            (canonical?.masteryCompleteDialogShown ?? false) ||
                legacy.masteryCompleteDialogShown,
      ),
    );

    if (!hasCanonical) {
      await save(merged);
    }
    return merged;
  }

  @override
  Future<void> save(CampaignProgressState state) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = CampaignProgressPolicy.normalize(state);

    await prefs.setInt(
      schemaVersionKey,
      CampaignProgressState.currentSchemaVersion,
    );
    await prefs.setInt(maxUnlockedLevelKey, normalized.maxUnlockedLevel);
    await prefs.setStringList(
      completedLessonIdsKey,
      _sortedIntStrings(normalized.completedLessonIds),
    );
    await prefs.setStringList(
      completedChallengeIdsKey,
      _sortedIntStrings(normalized.completedChallengeIds),
    );
    await prefs.setStringList(
      unlockedDiscoveryIdsKey,
      _sortedStrings(normalized.explicitlyUnlockedDiscoveryIds),
    );
    await prefs.setStringList(
      legacyUnlockedDiscoveryTitlesKey,
      _sortedStrings(normalized.legacyUnlockedDiscoveryTitles),
    );
    await prefs.setStringList(
      openedDiscoveryIdsKey,
      _sortedStrings(normalized.openedDiscoveryIds),
    );
    await prefs.setStringList(
      legacyOpenedDiscoveryTitlesKey,
      _sortedStrings(normalized.legacyOpenedDiscoveryTitles),
    );
    await prefs.setBool(
      masteryCompleteDialogShownKey,
      normalized.masteryCompleteDialogShown,
    );

    await _saveLegacyMirror(prefs, normalized);
  }

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in const [
      schemaVersionKey,
      maxUnlockedLevelKey,
      completedLessonIdsKey,
      completedChallengeIdsKey,
      unlockedDiscoveryIdsKey,
      legacyUnlockedDiscoveryTitlesKey,
      openedDiscoveryIdsKey,
      legacyOpenedDiscoveryTitlesKey,
      masteryCompleteDialogShownKey,
      legacyMaxUnlockedCampaignLevelKey,
      legacyCompletedMasteryLevelsKey,
      legacyMasteryCompleteDialogShownKey,
      legacyUnlockedDiscoveriesKey,
      legacyOpenedNotebookEntriesKey,
    ]) {
      await prefs.remove(key);
    }
    await save(CampaignProgressState.fresh());
  }

  CampaignProgressState? _loadCanonical(SharedPreferences prefs) {
    return CampaignProgressPolicy.normalize(
      CampaignProgressState(
        schemaVersion: prefs.getInt(schemaVersionKey) ??
            CampaignProgressState.currentSchemaVersion,
        maxUnlockedLevel: CampaignProgressPolicy.clampFrontier(
            prefs.getInt(maxUnlockedLevelKey) ?? 1),
        completedLessonIds:
            _parseInts(prefs.getStringList(completedLessonIdsKey)),
        completedChallengeIds:
            _parseInts(prefs.getStringList(completedChallengeIdsKey)),
        explicitlyUnlockedDiscoveryIds:
            _validDiscoveryIds(prefs.getStringList(unlockedDiscoveryIdsKey)),
        legacyUnlockedDiscoveryTitles:
            (prefs.getStringList(legacyUnlockedDiscoveryTitlesKey) ?? const [])
                .map((title) => title.trim())
                .where((title) => title.isNotEmpty)
                .toSet(),
        openedDiscoveryIds:
            _validDiscoveryIds(prefs.getStringList(openedDiscoveryIdsKey)),
        legacyOpenedDiscoveryTitles:
            (prefs.getStringList(legacyOpenedDiscoveryTitlesKey) ?? const [])
                .map((title) => title.trim())
                .where((title) => title.isNotEmpty)
                .toSet(),
        masteryCompleteDialogShown:
            prefs.getBool(masteryCompleteDialogShownKey) ?? false,
      ),
    );
  }

  CampaignProgressState _loadLegacy(SharedPreferences prefs) {
    final maxUnlocked = CampaignProgressPolicy.clampFrontier(
      prefs.getInt(legacyMaxUnlockedCampaignLevelKey) ?? 1,
    );
    final completedLessons = <int>{
      for (int id = 1;
          id <
              math.min(
                  maxUnlocked, ProgressionRules.guidedDiscoveryLevelCount + 1);
          id++)
        id,
    };

    final migratedUnlocked = _migrateDiscoveryTitles(
      prefs.getStringList(legacyUnlockedDiscoveriesKey),
    );
    final migratedOpened = _migrateDiscoveryTitles(
      prefs.getStringList(legacyOpenedNotebookEntriesKey),
    );

    return CampaignProgressState(
      maxUnlockedLevel: maxUnlocked,
      completedLessonIds: completedLessons,
      completedChallengeIds:
          _parseInts(prefs.getStringList(legacyCompletedMasteryLevelsKey)),
      explicitlyUnlockedDiscoveryIds: migratedUnlocked.ids,
      legacyUnlockedDiscoveryTitles: migratedUnlocked.legacyTitles,
      openedDiscoveryIds: migratedOpened.ids,
      legacyOpenedDiscoveryTitles: migratedOpened.legacyTitles,
      masteryCompleteDialogShown:
          prefs.getBool(legacyMasteryCompleteDialogShownKey) ?? false,
    );
  }

  Future<void> _saveLegacyMirror(
    SharedPreferences prefs,
    CampaignProgressState state,
  ) async {
    await prefs.setInt(
        legacyMaxUnlockedCampaignLevelKey, state.maxUnlockedLevel);
    await prefs.setStringList(
      legacyCompletedMasteryLevelsKey,
      _sortedIntStrings(state.completedChallengeIds),
    );
    await prefs.setBool(
      legacyMasteryCompleteDialogShownKey,
      state.masteryCompleteDialogShown,
    );
    await prefs.setStringList(
      legacyUnlockedDiscoveriesKey,
      _sortedStrings(CampaignProgressPolicy.unlockedDiscoveryTitles(state)),
    );
    await prefs.setStringList(
      legacyOpenedNotebookEntriesKey,
      _sortedStrings(CampaignProgressPolicy.openedDiscoveryTitles(state)),
    );
  }

  static Set<int> _parseInts(List<String>? values) {
    return (values ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  static Set<String> _validDiscoveryIds(List<String>? values) {
    return (values ?? const <String>[])
        .where((id) => CampaignProgressPolicy.discoveryTitleForId(id) != null)
        .toSet();
  }

  static _MigratedDiscoveryTitles _migrateDiscoveryTitles(
      List<String>? titles) {
    final ids = <String>{};
    final legacyTitles = <String>{};
    for (final rawTitle in titles ?? const <String>[]) {
      final title = rawTitle.trim();
      if (title.isEmpty) continue;
      final id = CampaignProgressPolicy.discoveryIdForTitle(title);
      if (id.isEmpty) {
        legacyTitles.add(title);
      } else {
        ids.add(id);
      }
    }
    return _MigratedDiscoveryTitles(ids, legacyTitles);
  }

  static List<String> _sortedIntStrings(Set<int> values) {
    return (values.toList()..sort()).map((value) => value.toString()).toList();
  }

  static List<String> _sortedStrings(Set<String> values) {
    return values.toList()..sort();
  }
}

class _MigratedDiscoveryTitles {
  final Set<String> ids;
  final Set<String> legacyTitles;

  const _MigratedDiscoveryTitles(this.ids, this.legacyTitles);
}

class InMemoryCampaignProgressStore implements CampaignProgressStore {
  CampaignProgressState _state;

  InMemoryCampaignProgressStore([CampaignProgressState? initialState])
      : _state = CampaignProgressPolicy.normalize(
          initialState ?? CampaignProgressState.fresh(),
        );

  @override
  Future<CampaignProgressState> load() async => _state;

  @override
  Future<void> save(CampaignProgressState state) async {
    _state = CampaignProgressPolicy.normalize(state);
  }

  @override
  Future<void> reset() async {
    _state = CampaignProgressState.fresh();
  }
}

class CampaignProgressController extends ChangeNotifier {
  CampaignProgressController({CampaignProgressStore? store})
      : _store = store ?? const SharedPreferencesCampaignProgressStore();

  static final CampaignProgressController instance =
      CampaignProgressController();

  final CampaignProgressStore _store;
  CampaignProgressState _state = CampaignProgressState.fresh();
  bool _loaded = false;

  CampaignProgressState get state => _state;
  bool get isLoaded => _loaded;

  Future<CampaignProgressState> load() async {
    _state = await _store.load();
    _loaded = true;
    notifyListeners();
    return _state;
  }

  Future<void> _commit(CampaignProgressState state) async {
    _state = CampaignProgressPolicy.normalize(state);
    await _store.save(_state);
    _loaded = true;
    notifyListeners();
  }

  Future<void> completeLevel(int levelNumber) async {
    await _commit(CampaignProgressPolicy.completeLevel(_state, levelNumber));
  }

  Future<void> completeLesson(int lessonId) async {
    await _commit(CampaignProgressPolicy.completeLesson(_state, lessonId));
  }

  Future<void> completeChallenge(int levelId) async {
    await _commit(CampaignProgressPolicy.completeChallenge(_state, levelId));
  }

  Future<void> unlockDiscovery(String discoveryTitle) async {
    await _commit(
      CampaignProgressPolicy.unlockDiscoveryByTitle(_state, discoveryTitle),
    );
  }

  Future<void> markNotebookEntryOpened(String discoveryTitle) async {
    await _commit(
      CampaignProgressPolicy.markNotebookEntryOpened(_state, discoveryTitle),
    );
  }

  Future<void> markMasteryCompleteDialogShown() async {
    await _commit(_state.copyWith(masteryCompleteDialogShown: true));
  }

  Future<void> unlockAllCampaignContent() async {
    await _commit(CampaignProgressPolicy.unlockAllCampaignContent(_state));
  }

  Future<void> resetProgress() async {
    await _store.reset();
    _state = await _store.load();
    _loaded = true;
    notifyListeners();
  }

  bool isLevelUnlocked(int levelNumber) {
    return CampaignProgressPolicy.isLevelUnlocked(_state, levelNumber);
  }

  bool isChallengeCompleted(int levelNumber) {
    return CampaignProgressPolicy.isChallengeCompleted(_state, levelNumber);
  }

  bool get masteryChallengesUnlocked {
    return CampaignProgressPolicy.getMasteryChallengesUnlocked(_state);
  }

  ContinueJourneyDestination get continueJourneyDestination {
    return CampaignProgressPolicy.continueJourneyDestination(_state);
  }

  Set<String> unlockedDiscoveryTitles() {
    return CampaignProgressPolicy.unlockedDiscoveryTitles(_state);
  }

  Set<String> openedDiscoveryTitles() {
    return CampaignProgressPolicy.openedDiscoveryTitles(_state);
  }

  bool hasUnopenedNotebookEntries(Iterable<String> notebookDiscoveryTitles) {
    return CampaignProgressPolicy.hasUnopenedNotebookEntries(
      _state,
      notebookDiscoveryTitles,
    );
  }
}
