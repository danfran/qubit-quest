import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/discovery_progress.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/validation/chapter_release_gate.dart';

void main() {
  test('release requires thirteen Journey chapter gates', () {
    expect(groupedLevels.where((c) => !c.isMasteryPhase), hasLength(13));
  });
  for (final chapter in groupedLevels.where((c) => !c.isMasteryPhase)) {
    test('release gate ${chapter.groupName}', () {
      final result = ChapterReleaseGate.validateChapter(chapter);
      expect(result.passed, isTrue, reason: result.toReport());
    });
  }
  test('all 66 discoveries have unique ordered Notebook coverage', () {
    final entries = notebookEntries.where((e) => e.chapterIndex > 0).toList();
    expect(entries, hasLength(66));
    expect(
        entries.map((e) => e.discoveryTitle), DiscoveryProgress.discoveryOrder);
    expect(entries.map((e) => e.id).toSet(), hasLength(66));
    for (var id = 1; id <= 66; id++) {
      expect(entries[id - 1].discoveryTitle,
          getJourneyLessonById(id)!.discoveryTitle);
    }
  });
  test('Phase uses existing discovery_010 and remains locked until earned',
      () async {
    final store = InMemoryCampaignProgressStore();
    var controller = CampaignProgressController(store: store);
    await controller.load();
    final entry = notebookEntriesByDiscoveryTitle['Phase']!;
    expect(
        isNotebookEntryAvailable(entry, controller.unlockedDiscoveryTitles()),
        isFalse);
    for (var i = 1; i <= 9; i++) {
      await controller.completeLesson(i);
    }
    expect(
        isNotebookEntryAvailable(entry, controller.unlockedDiscoveryTitles()),
        isFalse);
    await controller.completeLesson(10);
    controller = CampaignProgressController(store: store);
    await controller.load();
    expect(controller.state.explicitlyUnlockedDiscoveryIds,
        contains('discovery_010'));
    expect(
        isNotebookEntryAvailable(entry, controller.unlockedDiscoveryTitles()),
        isTrue);
    final lesson = getJourneyLessonById(10)! as ComposerLevel;
    final circuit = buildCanonicalSolutionCircuit(lesson);
    expect(lesson.validateCircuit(circuit), isTrue);
    expect(circuit.currentState.stateVector[1].abs(), closeTo(1, 1e-10));
  });
}
