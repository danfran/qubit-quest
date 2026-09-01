import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/discovery_catalog.dart' as discovery_catalog;
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/storage/shared_preferences_app_storage.dart';

@immutable
class CampaignProgressState {
  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final int maxUnlockedLevel;
  final Set<int> completedLessonIds;
  final Set<int> completedChallengeIds;
  final Set<String> completedMasterySemanticIds;
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
    Set<String> completedMasterySemanticIds = const {},
    Set<String> explicitlyUnlockedDiscoveryIds = const {},
    Set<String> legacyUnlockedDiscoveryTitles = const {},
    Set<String> openedDiscoveryIds = const {},
    Set<String> legacyOpenedDiscoveryTitles = const {},
    this.masteryCompleteDialogShown = false,
  })  : completedLessonIds = Set.unmodifiable(completedLessonIds),
        completedChallengeIds = Set.unmodifiable(completedChallengeIds),
        completedMasterySemanticIds =
            Set.unmodifiable(completedMasterySemanticIds),
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
    Set<String>? completedMasterySemanticIds,
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
      completedMasterySemanticIds:
          completedMasterySemanticIds ?? this.completedMasterySemanticIds,
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
    final completedMasterySemanticIds = <String>{
      for (final semanticId in state.completedMasterySemanticIds)
        if (MasteryChallengeDefinition.isValidSemanticId(semanticId))
          semanticId,
    };

    return state.copyWith(
      schemaVersion: CampaignProgressState.currentSchemaVersion,
      maxUnlockedLevel: maxUnlockedLevel,
      completedLessonIds: completedLessons,
      completedChallengeIds: completedChallenges,
      completedMasterySemanticIds: completedMasterySemanticIds,
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
        completedChallengeIds: {
          ...state.completedChallengeIds,
          challengeLevelId,
        },
      ),
    );
  }

  static CampaignProgressState completeMasteryChallenge(
    CampaignProgressState state,
    String semanticId,
  ) {
    if (!MasteryChallengeDefinition.isValidSemanticId(semanticId)) {
      throw ArgumentError.value(
        semanticId,
        'semanticId',
        'Mastery completion requires a valid semantic identity.',
      );
    }
    return normalize(
      state.copyWith(
        completedMasterySemanticIds: {
          ...state.completedMasterySemanticIds,
          semanticId,
        },
      ),
    );
  }

  static CampaignProgressState discardLegacyMasteryCompletion(
    CampaignProgressState state,
  ) {
    return normalize(
      state.copyWith(
        completedChallengeIds: const {},
        masteryCompleteDialogShown: false,
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

  static bool isMasteryChallengeCompleted(
    CampaignProgressState state,
    String semanticId,
  ) {
    return state.completedMasterySemanticIds.contains(semanticId);
  }

  static bool getMasteryChallengesUnlocked(CampaignProgressState state) {
    return ProgressionRules.masteryChallengesUnlocked(state.maxUnlockedLevel);
  }

  static ContinueJourneyDestination continueJourneyDestination(
    CampaignProgressState state,
  ) {
    if (state.maxUnlockedLevel > ProgressionRules.guidedDiscoveryLevelCount ||
        state.completedLessonIds.length >=
            ProgressionRules.guidedDiscoveryLevelCount) {
      return const ContinueJourneyDestination.completed();
    }
    return ContinueJourneyDestination.level(
      state.maxUnlockedLevel.clamp(
        1,
        ProgressionRules.guidedDiscoveryLevelCount,
      ),
    );
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
  const SharedPreferencesCampaignProgressStore({
    this.storage = const SharedPreferencesAppStorage(),
  });

  final AppStorage storage;

  static const schemaVersionKey = 'qq_progress_schema_version';
  static const maxUnlockedLevelKey = 'qq_progress_max_unlocked_level';
  static const completedLessonIdsKey = 'qq_progress_completed_lesson_ids';
  static const completedChallengeIdsKey = 'qq_progress_completed_challenge_ids';
  static const completedMasterySemanticIdsKey =
      'qq_progress_completed_mastery_semantic_ids';
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
    final hasCanonical = await storage.readInt(schemaVersionKey) != null;
    final canonical = hasCanonical ? await _loadCanonical() : null;
    final legacy =
        hasCanonical ? CampaignProgressState.fresh() : await _loadLegacy();

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
        completedMasterySemanticIds: {
          ...?canonical?.completedMasterySemanticIds,
          ...legacy.completedMasterySemanticIds,
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
    final normalized = CampaignProgressPolicy.normalize(state);

    await storage.writeInt(
      schemaVersionKey,
      CampaignProgressState.currentSchemaVersion,
    );
    await storage.writeInt(maxUnlockedLevelKey, normalized.maxUnlockedLevel);
    await storage.writeStringList(
      completedLessonIdsKey,
      _sortedIntStrings(normalized.completedLessonIds),
    );
    await storage.writeStringList(
      completedChallengeIdsKey,
      _sortedIntStrings(normalized.completedChallengeIds),
    );
    await storage.writeStringList(
      completedMasterySemanticIdsKey,
      _sortedStrings(normalized.completedMasterySemanticIds),
    );
    await storage.writeStringList(
      unlockedDiscoveryIdsKey,
      _sortedStrings(normalized.explicitlyUnlockedDiscoveryIds),
    );
    await storage.writeStringList(
      legacyUnlockedDiscoveryTitlesKey,
      _sortedStrings(normalized.legacyUnlockedDiscoveryTitles),
    );
    await storage.writeStringList(
      openedDiscoveryIdsKey,
      _sortedStrings(normalized.openedDiscoveryIds),
    );
    await storage.writeStringList(
      legacyOpenedDiscoveryTitlesKey,
      _sortedStrings(normalized.legacyOpenedDiscoveryTitles),
    );
    await storage.writeBool(
      masteryCompleteDialogShownKey,
      normalized.masteryCompleteDialogShown,
    );

    await _saveLegacyMirror(normalized);
  }

  @override
  Future<void> reset() async {
    for (final key in const [
      schemaVersionKey,
      maxUnlockedLevelKey,
      completedLessonIdsKey,
      completedChallengeIdsKey,
      completedMasterySemanticIdsKey,
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
      await storage.delete(key);
    }
    await save(CampaignProgressState.fresh());
  }

  Future<CampaignProgressState?> _loadCanonical() async {
    return CampaignProgressPolicy.normalize(
      CampaignProgressState(
        schemaVersion: await storage.readInt(schemaVersionKey) ??
            CampaignProgressState.currentSchemaVersion,
        maxUnlockedLevel: CampaignProgressPolicy.clampFrontier(
            await storage.readInt(maxUnlockedLevelKey) ?? 1),
        completedLessonIds:
            _parseInts(await storage.readStringList(completedLessonIdsKey)),
        completedChallengeIds:
            _parseInts(await storage.readStringList(completedChallengeIdsKey)),
        completedMasterySemanticIds: _validMasterySemanticIds(
          await storage.readStringList(completedMasterySemanticIdsKey),
        ),
        explicitlyUnlockedDiscoveryIds: _validDiscoveryIds(
            await storage.readStringList(unlockedDiscoveryIdsKey)),
        legacyUnlockedDiscoveryTitles:
            (await storage.readStringList(legacyUnlockedDiscoveryTitlesKey) ??
                    const [])
                .map((title) => title.trim())
                .where((title) => title.isNotEmpty)
                .toSet(),
        openedDiscoveryIds: _validDiscoveryIds(
            await storage.readStringList(openedDiscoveryIdsKey)),
        legacyOpenedDiscoveryTitles:
            (await storage.readStringList(legacyOpenedDiscoveryTitlesKey) ??
                    const [])
                .map((title) => title.trim())
                .where((title) => title.isNotEmpty)
                .toSet(),
        masteryCompleteDialogShown:
            await storage.readBool(masteryCompleteDialogShownKey) ?? false,
      ),
    );
  }

  Future<CampaignProgressState> _loadLegacy() async {
    final maxUnlocked = CampaignProgressPolicy.clampFrontier(
      await storage.readInt(legacyMaxUnlockedCampaignLevelKey) ?? 1,
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
      await storage.readStringList(legacyUnlockedDiscoveriesKey),
    );
    final migratedOpened = _migrateDiscoveryTitles(
      await storage.readStringList(legacyOpenedNotebookEntriesKey),
    );

    return CampaignProgressState(
      maxUnlockedLevel: maxUnlocked,
      completedLessonIds: completedLessons,
      completedChallengeIds: _parseInts(
          await storage.readStringList(legacyCompletedMasteryLevelsKey)),
      explicitlyUnlockedDiscoveryIds: migratedUnlocked.ids,
      legacyUnlockedDiscoveryTitles: migratedUnlocked.legacyTitles,
      openedDiscoveryIds: migratedOpened.ids,
      legacyOpenedDiscoveryTitles: migratedOpened.legacyTitles,
      masteryCompleteDialogShown:
          await storage.readBool(legacyMasteryCompleteDialogShownKey) ?? false,
    );
  }

  Future<void> _saveLegacyMirror(
    CampaignProgressState state,
  ) async {
    await storage.writeInt(
        legacyMaxUnlockedCampaignLevelKey, state.maxUnlockedLevel);
    await storage.writeStringList(
      legacyCompletedMasteryLevelsKey,
      _sortedIntStrings(state.completedChallengeIds),
    );
    await storage.writeBool(
      legacyMasteryCompleteDialogShownKey,
      state.masteryCompleteDialogShown,
    );
    await storage.writeStringList(
      legacyUnlockedDiscoveriesKey,
      _sortedStrings(CampaignProgressPolicy.unlockedDiscoveryTitles(state)),
    );
    await storage.writeStringList(
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

  static Set<String> _validMasterySemanticIds(List<String>? values) {
    return (values ?? const <String>[])
        .where(MasteryChallengeDefinition.isValidSemanticId)
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

  static CampaignProgressController _instance = CampaignProgressController();

  static CampaignProgressController get instance => _instance;

  static void configureSharedInstance(CampaignProgressController controller) {
    _instance = controller;
  }

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

  Future<void> completeMasteryChallenge(String semanticId) async {
    await _commit(
      CampaignProgressPolicy.completeMasteryChallenge(_state, semanticId),
    );
  }

  Future<void> discardLegacyMasteryCompletion() async {
    await _commit(
      CampaignProgressPolicy.discardLegacyMasteryCompletion(_state),
    );
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
