import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/widgets/level_header_router.dart';
import 'package:quantumquiz/validation/chapter_release_gate.dart';

void main() {
  test('current curriculum release checks still resolve both catalogue domains',
      () {
    final result = ChapterReleaseGate.validateCurriculumJourney();
    expect(result.failures, isEmpty, reason: result.toReport());
  });
  test('all 60 Journey identities match the existing authored snapshot', () {
    final snapshot = jsonDecode(
        File('test/fixtures/web_learning_catalogue_content.json')
            .readAsStringSync()) as List;
    final journey =
        snapshot.where((row) => (row['id'] as String).startsWith('J')).toList();
    expect(journey, hasLength(60));
    expect(numericActivityCatalogue.journey.keys.toSet(),
        {for (var i = 1; i <= 66; i++) i});
    for (final row in journey) {
      final id = int.parse((row['id'] as String).substring(1));
      final level = getJourneyLessonById(id)!;
      expect(level.title, row['title'], reason: 'Journey $id');
      expect(level.taskDescription, row['task'], reason: 'Journey $id');
      expect(level.runtimeType.toString(), row['type'], reason: 'Journey $id');
      expect(identical(level, getQQLevelById(id)), isTrue);
    }
    expect(getJourneyLessonById(67), isNull);
    expect(getJourneyLessonById(0), isNull);
  });

  test('all 54 archived IDs are fixed independently of Journey numbering', () {
    expect(numericActivityCatalogue.historicalMastery.keys.toSet(),
        {for (var i = 61; i <= 114; i++) i});
    for (var id = 61; id <= 114; id++) {
      expect(
          identical(getHistoricalMasteryById(id), getQQLevelById(id)), isTrue);
      expect(
          identical(getHistoricalMasteryById(id),
              historicalMasteryActivities[id - 61]),
          isTrue);
      expect(ProgressionRules.masteryChallengeNumber(id), id - 60);
    }
    expect(getHistoricalMasteryById(60), isNull);
    expect(getHistoricalMasteryById(115), isNull);
  });

  test('separate maps can resolve numeric 61 without shifting any archive ID',
      () {
    // Lookup-only fixture reuses an existing object. No new lesson is authored.
    final borrowed = getJourneyLessonById(1)!;
    final extended = NumericActivityCatalogue(
      journey: {...numericActivityCatalogue.journey, 61: borrowed},
      historicalMastery: numericActivityCatalogue.historicalMastery,
    );
    expect(extended.lookup(61, NumericActivityDomain.journey), same(borrowed));
    expect(extended.lookup(61, NumericActivityDomain.historicalMastery),
        same(getHistoricalMasteryById(61)));
    for (var id = 61; id <= 114; id++) {
      expect(extended.lookup(id, NumericActivityDomain.historicalMastery),
          same(getHistoricalMasteryById(id)));
    }
    expect(getJourneyLessonById(67), isNull);
  });

  test('chapter lookup cannot reinterpret the archive as Journey Chapter13',
      () {
    expect(journeyChapters, hasLength(13));
    for (var id = 1; id <= 60; id++) {
      expect(journeyChapterForLesson(id), same(journeyChapters[(id - 1) ~/ 5]));
    }
    expect(journeyChapterForLesson(61), same(journeyChapters.last));
    expect(journeyChapters.contains(historicalMasteryGroup), isFalse);
    expect(groupedLevels.last, same(historicalMasteryGroup));
    expect(historicalMasteryGroup.from, 60);
    expect(
        const LearningMapConceptLink(
                fromChapter: 12, toChapter: 13, description: '')
            .label,
        '12 -> 13');
    expect(LearningMapScreen.conceptLinks.last.label, '12 -> Mastery');
  });

  test('semantic Mastery still resolves independently by semantic identity',
      () {
    expect(mastery2Catalogue.length, 42);
    for (final challenge in mastery2Catalogue.orderedDefinitions) {
      expect(mastery2Catalogue.bySemanticId(challenge.semanticId),
          same(challenge));
      expect(mastery2Catalogue.isAccessible(challenge.semanticId), isTrue);
    }
  });

  test('explicit completion domains do not award one another credit', () {
    final historical = CampaignProgressPolicy.completeChallenge(
        CampaignProgressState.fresh(), 61);
    final semantic = CampaignProgressPolicy.completeMasteryChallenge(
        historical, 'global_phase_equivalence');
    final journey = CampaignProgressPolicy.completeLesson(semantic, 1);
    expect(journey.completedChallengeIds, {61});
    expect(journey.completedMasterySemanticIds, {'global_phase_equivalence'});
    expect(journey.completedLessonIds, {1});
    expect(journey.completedLessonIds.contains(61), isFalse);
    expect(journey.maxUnlockedLevel, 2);
    expect(
        ProgressionRules.isJourneyLessonUnlocked(
            lessonId: 61, maxUnlockedLevel: 61),
        isTrue);
  });

  test(
      'native and Web route inputs use the same Journey content and explicit domain',
      () {
    final level = getJourneyLessonById(1)!;
    final native = LevelUIRouter.buildLevelUI(
        level: level, levelId: 1, onLevelUnlocked: null) as QuantumComposer;
    final web = WebLessonWorkspace(
        level: level,
        levelId: 1,
        alreadyCompleted: false,
        onCompleted: () async {},
        onNextLesson: () {},
        onBackToChapter: () {},
        onOpenNotebook: () {});
    expect(native.level, same(web.level));
    expect(native.activityDomain, NumericActivityDomain.journey);
    expect(web.activityDomain, NumericActivityDomain.journey);
    expect(LevelHeaderRouter.displayLabel(61), 'Lesson 61');
    expect(
        LevelHeaderRouter.displayLabel(61,
            activityDomain: NumericActivityDomain.historicalMastery),
        'Mastery Challenge 1');
  });

  testWidgets('Learning Map Mastery uses its own callback, never lesson61',
      (tester) async {
    final selected = <int>[];
    var mastery = 0;
    await tester.pumpWidget(MaterialApp(
        home: LearningMapScreen(
      progressState: CampaignProgressPolicy.completeLesson(
          CampaignProgressState.fresh(), 66),
      onStartChapter: (id) async {
        selected.add(id);
      },
      onOpenMastery: () {
        mastery++;
      },
    )));
    final node = find.byKey(const ValueKey('learning-map-chapter-14'));
    await tester.ensureVisible(node);
    await tester.pumpAndSettle();
    await tester.tap(node);
    await tester.pump();
    expect(mastery, 1);
    expect(selected, isEmpty);
  });
}
