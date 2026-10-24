import 'dart:convert';
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
  static const int currentSchemaVersion = 3;

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
    return value
        .clamp(1, ProgressionRules.guidedDiscoveryLevelCount + 1)
        .toInt();
  }

  static CampaignProgressState normalize(CampaignProgressState state) {
    final maxUnlockedLevel = clampFrontier(state.maxUnlockedLevel);
    final completedLessons = <int>{
      for (final id in state.completedLessonIds)
        if (_isGuidedLesson(id)) id,
    };
    final completedChallenges = <int>{
      for (final id in state.completedChallengeIds)
        if (ProgressionRules.isLegacyMasteryId(id)) id,
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

  // Frozen combined-campaign compatibility API. New routes must use
  // completeLesson, completeChallenge or completeMasteryChallenge explicitly.
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
    if (!ProgressionRules.isLegacyMasteryId(challengeLevelId)) {
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
          for (int id = ProgressionRules.legacyMasteryFirstId;
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
    final isCompleted = completed == total;
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
    final title = getJourneyLessonById(levelNumber)?.discoveryTitle?.trim();
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

  // Double-buffered complete records. Old binaries never write these keys.
  static const activeV3Key = 'qq_progress_v3_active';
  static const recordV3AKey = 'qq_progress_v3_record_a';
  static const recordV3BKey = 'qq_progress_v3_record_b';

  Future<String?> _activeSlot() async {
    final slot = await storage.readString(activeV3Key);
    if (slot != null && slot != recordV3AKey && slot != recordV3BKey) {
      throw const FormatException('Unknown progress activation record');
    }
    return slot;
  }

  @override
  Future<CampaignProgressState> load() async {
    final active = await _activeSlot();
    if (active != null) {
      // Never fall back to stale v2 data after activation, even on corruption.
      return _decodeV3(await storage.readString(active));
    }
    final version = await storage.readInt(schemaVersionKey);
    final CampaignProgressState historical;
    switch (version) {
      case null:
        historical = await _loadLegacy();
      case 2:
        historical = await _loadCanonical();
      default:
        throw UnsupportedError(
            'Unsupported historical progress schema: $version');
    }
    final lessons = historical.completedLessonIds
        .where((id) => id >= 1 && id <= ProgressionRules.historicalJourneyCount)
        .toSet();
    var frontier = 1;
    while (lessons.contains(frontier) &&
        frontier <= ProgressionRules.historicalJourneyCount) {
      frontier++;
    }
    final migrated = CampaignProgressPolicy.normalize(historical.copyWith(
      completedLessonIds: lessons,
      maxUnlockedLevel: frontier,
      explicitlyUnlockedDiscoveryIds: {
        ...historical.explicitlyUnlockedDiscoveryIds,
        for (final id in lessons)
          if (CampaignProgressPolicy.discoveryIdForLevel(id) != null)
            CampaignProgressPolicy.discoveryIdForLevel(id)!,
      },
    ));
    await save(migrated);
    return migrated;
  }

  @override
  Future<void> save(CampaignProgressState state) async {
    final active = await _activeSlot();
    if (active != null) _decodeV3(await storage.readString(active));
    final slot = active == recordV3AKey ? recordV3BKey : recordV3AKey;
    final payload = _encodeV3(CampaignProgressPolicy.normalize(state));
    await storage.writeString(slot, payload);
    final staged = await storage.readString(slot);
    if (staged != payload)
      throw StateError('Progress staging verification failed');
    _decodeV3(staged);
    await storage.writeString(activeV3Key, slot);
    if (await storage.readString(activeV3Key) != slot) {
      throw StateError('Progress activation verification failed');
    }
    // Keep every v2/legacy key untouched as the migration recovery source.
  }

  static String _encodeV3(CampaignProgressState s) => jsonEncode({
        'schema': 3,
        'journey': {
          'frontier': s.maxUnlockedLevel,
          'completed': s.completedLessonIds.toList()..sort()
        },
        'legacyMastery': s.completedChallengeIds.toList()..sort(),
        'semanticMastery': _sortedStrings(s.completedMasterySemanticIds),
        'discoveries': _sortedStrings(s.explicitlyUnlockedDiscoveryIds),
        'legacyTitles': _sortedStrings(s.legacyUnlockedDiscoveryTitles),
        'opened': _sortedStrings(s.openedDiscoveryIds),
        'legacyOpenedTitles': _sortedStrings(s.legacyOpenedDiscoveryTitles),
        'masteryDialogShown': s.masteryCompleteDialogShown,
      });

  static CampaignProgressState _decodeV3(String? raw) {
    if (raw == null)
      throw const FormatException('Missing active progress record');
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['schema'] != 3)
        throw const FormatException('Unsupported progress schema');
      final journey = data['journey'] as Map<String, dynamic>;
      final state = CampaignProgressState(
        maxUnlockedLevel: journey['frontier'] as int,
        completedLessonIds: (journey['completed'] as List).cast<int>().toSet(),
        completedChallengeIds:
            (data['legacyMastery'] as List).cast<int>().toSet(),
        completedMasterySemanticIds:
            (data['semanticMastery'] as List).cast<String>().toSet(),
        explicitlyUnlockedDiscoveryIds:
            (data['discoveries'] as List).cast<String>().toSet(),
        legacyUnlockedDiscoveryTitles:
            (data['legacyTitles'] as List).cast<String>().toSet(),
        openedDiscoveryIds: (data['opened'] as List).cast<String>().toSet(),
        legacyOpenedDiscoveryTitles:
            (data['legacyOpenedTitles'] as List).cast<String>().toSet(),
        masteryCompleteDialogShown: data['masteryDialogShown'] as bool,
      );
      if (_encodeV3(CampaignProgressPolicy.normalize(state)) != raw) {
        throw const FormatException('Invalid progress record');
      }
      return state;
    } on TypeError {
      throw const FormatException('Malformed progress record');
    }
  }

  @override
  Future<void> reset() async {
    for (final key in const [
      activeV3Key,
      recordV3AKey,
      recordV3BKey,
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

  Future<CampaignProgressState> _loadCanonical() async {
    return CampaignProgressState(
      schemaVersion: await storage.readInt(schemaVersionKey) ??
          CampaignProgressState.currentSchemaVersion,
      maxUnlockedLevel: (await storage.readInt(maxUnlockedLevelKey) ?? 1)
          .clamp(1, ProgressionRules.historicalFrontierLimit),
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
    );
  }

  Future<CampaignProgressState> _loadLegacy() async {
    final maxUnlocked =
        (await storage.readInt(legacyMaxUnlockedCampaignLevelKey) ?? 1)
            .clamp(1, ProgressionRules.historicalFrontierLimit);
    final completedLessons = <int>{
      for (int id = 1;
          id <
              math.min(
                  maxUnlocked, ProgressionRules.historicalJourneyCount + 1);
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

enum ProgressSaveStatus { saved, pending, failed }

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
    await _enqueue(() async {
      final restored = await _store.load();
      _state = restored;
      _loaded = true;
      _notifySave();
    });
    return _state;
  }

  ProgressSaveStatus saveStatus = ProgressSaveStatus.saved;
  final List<CampaignProgressState Function(CampaignProgressState)> _pending =
      [];
  Future<void>? _saveQueue;
  bool _disposed = false;

  void _notifySave() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _commit(
      CampaignProgressState Function(CampaignProgressState) edit) {
    return _enqueue(() async {
      _pending.add(edit);
      await _savePending();
    });
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final previous = _saveQueue;
    final operation = previous == null
        ? Future<void>.microtask(action)
        : previous.then((_) => action(),
            onError: (Object _, StackTrace __) => action());
    late final Future<void> queued;
    queued = operation.whenComplete(() {
      // Do not retain a completed future (or its execution zone) when idle.
      // Cleanup completes before the caller observes operation completion.
      if (identical(_saveQueue, queued)) _saveQueue = null;
    });
    _saveQueue = queued;
    return queued;
  }

  Future<void> _savePending() async {
    if (_pending.isEmpty) return;
    saveStatus = ProgressSaveStatus.pending;
    _notifySave();
    var candidate = _state;
    for (final edit in _pending) {
      candidate = edit(candidate);
    }
    candidate = CampaignProgressPolicy.normalize(candidate);
    try {
      await _store.save(candidate);
      _state = candidate;
      _loaded = true;
      _pending.clear();
      saveStatus = ProgressSaveStatus.saved;
    } catch (_) {
      saveStatus = ProgressSaveStatus.failed;
      rethrow;
    } finally {
      _notifySave();
    }
  }

  Future<void> retrySave() => _enqueue(_savePending);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> completeLevel(int id) =>
      _commit((state) => CampaignProgressPolicy.completeLevel(state, id));
  Future<void> completeLesson(int id) =>
      _commit((state) => CampaignProgressPolicy.completeLesson(state, id));
  Future<void> completeChallenge(int id) =>
      _commit((state) => CampaignProgressPolicy.completeChallenge(state, id));
  Future<void> completeMasteryChallenge(String id) => _commit(
      (state) => CampaignProgressPolicy.completeMasteryChallenge(state, id));
  Future<void> discardLegacyMasteryCompletion() =>
      _commit(CampaignProgressPolicy.discardLegacyMasteryCompletion);
  Future<void> unlockDiscovery(String title) => _commit(
      (state) => CampaignProgressPolicy.unlockDiscoveryByTitle(state, title));
  Future<void> markNotebookEntryOpened(String title) => _commit(
      (state) => CampaignProgressPolicy.markNotebookEntryOpened(state, title));
  Future<void> markMasteryCompleteDialogShown() =>
      _commit((state) => state.copyWith(masteryCompleteDialogShown: true));
  Future<void> unlockAllCampaignContent() =>
      _commit(CampaignProgressPolicy.unlockAllCampaignContent);

  Future<void> resetProgress() => _enqueue(() async {
        await _store.reset();
        final restored = await _store.load();
        _state = restored;
        _pending.clear();
        _loaded = true;
        saveStatus = ProgressSaveStatus.saved;
        _notifySave();
      });

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
