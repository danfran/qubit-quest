import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/discovery_progress.dart';
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/validation/chapter_release_gate.dart';
import 'support/mastery_math_test_platform.dart';

void main() {
  useMasteryMathTestPlatform();
  final entries = notebookEntries.where((e) => e.chapterIndex == 13).toList();
  test(
      'six ordered discoveries cover unchanged Journey and Mastery namespaces; release passes',
      () {
    expect(journeyLessons, hasLength(66));
    expect(mastery2Catalogue.length, 42);
    for (var i = 1; i <= 66; i++) {
      expect(getJourneyLessonById(i), same(journeyLessons[i - 1]));
    }
    for (var i = 61; i <= 114; i++) {
      expect(getHistoricalMasteryById(i),
          same(historicalMasteryActivities[i - 61]));
    }
    expect(entries, hasLength(6));
    expect(entries.map((e) => e.discoveryTitle),
        DiscoveryProgress.discoveryOrder.skip(60));
    for (var i = 0; i < 6; i++) {
      expect(entries[i].discoveryTitle,
          getJourneyLessonById(61 + i)!.discoveryTitle);
      expect(entries[i].chapterIdentity, isNotEmpty);
      expect(entries[i].relatedDiscoveryTitles,
          everyElement(isIn(entries.map((e) => e.discoveryTitle))));
      expect(entries[i].executableExampleIds, isNotEmpty);
    }
    final gate =
        ChapterReleaseGate.validateChapter(journeyChapterForLesson(61)!);
    expect(gate.passed, isTrue, reason: gate.toReport());
  });
  test(
      'each discovery alone unlocks its entry; sequential completion and reload preserve access',
      () async {
    for (final entry in entries) {
      for (final other in entries) {
        expect(isNotebookEntryAvailable(other, {entry.discoveryTitle}),
            identical(entry, other));
      }
    }
    final storage = InMemoryAppStorage();
    final store = SharedPreferencesCampaignProgressStore(storage: storage);
    await store.save(CampaignProgressState(
        maxUnlockedLevel: 61,
        completedLessonIds: {for (var i = 1; i <= 60; i++) i}));
    var controller = CampaignProgressController(store: store);
    await controller.load();
    for (var earned = 0; earned <= 6; earned++) {
      for (var i = 0; i < 6; i++) {
        expect(
            isNotebookEntryAvailable(
                entries[i], controller.unlockedDiscoveryTitles()),
            i < earned);
        expect(
            controller.state.completedLessonIds.contains(61 + i), i < earned);
      }
      if (earned < 6) {
        await controller.completeLesson(61 + earned);
      }
      controller = CampaignProgressController(
          store: SharedPreferencesCampaignProgressStore(storage: storage));
      await controller.load();
    }
    expect(
        controller.state.explicitlyUnlockedDiscoveryIds,
        containsAll([
          for (var i = 61; i <= 66; i++)
            'discovery_${i.toString().padLeft(3, '0')}'
        ]));
    expect(controller.state.completedChallengeIds, isEmpty);
    expect(controller.state.completedMasterySemanticIds, isEmpty);
  });
  test('executable chronology, D/-D signs and independent recurrence agree',
      () {
    List<double> state(String id) {
      final e = executableNotebookExamplesById[id]!;
      expect(e.validate(), isEmpty);
      final output = e.execute();
      expect(e.resultMatchesExpected(output.state), isTrue);
      for (final a in output.state) {
        expect(a.imaginary, closeTo(0, 1e-10));
      }
      final v = output.state.map((a) => a.real.toDouble()).toList();
      expect(v.fold<double>(0, (s, a) => s + a * a), closeTo(1, 1e-10));
      return v;
    }

    void vector(List<double> actual, List<double> expected) {
      for (var i = 0; i < actual.length; i++) {
        expect(actual[i], closeTo(expected[i], 1e-10));
      }
    }

    vector(state('search_marked_input'), [.5, .5, -.5, .5]);
    vector(state('search_reflection'), [.5, -.5, -.5, -.5]);
    vector(state('search_correct_order'), [0, 0, -1, 0]);
    vector(state('search_reordered'), [-.5, -.5, .5, -.5]);
    vector(state('search_two_rounds'), [-.5, -.5, .5, -.5]);
    List<double> round(List<double> v, int marked) {
      final o = [for (var i = 0; i < v.length; i++) i == marked ? -v[i] : v[i]];
      final m = o.reduce((a, b) => a + b) / o.length;
      return [for (final a in o) 2 * m - a];
    }

    var v = [.5, .5, .5, .5];
    for (var r = 0; r <= 2; r++) {
      expect(v[2] * v[2], closeTo([.25, 1, .25][r], 1e-10));
      if (r > 0) {
        vector(state(r == 1 ? 'search_correct_order' : 'search_two_rounds'),
            v.map((a) => a * (r.isOdd ? -1 : 1)).toList());
      }
      v = round(v, 2);
    }
    v = List.filled(8, 1 / math.sqrt(8));
    var b = 1.0, c = 1.0;
    final probs = <double>[];
    for (var r = 0; r <= 3; r++) {
      vector(v, [for (var i = 0; i < 8; i++) (i == 6 ? b : c) / math.sqrt(8)]);
      probs.add(b * b / 8);
      expect(probs.last,
          closeTo([1 / 8, 25 / 32, 121 / 128, 169 / 512][r], 1e-10));
      if (r > 0) {
        vector(state('search_eight_$r'),
            v.map((a) => a * (r.isOdd ? -1 : 1)).toList());
      }
      v = round(v, 6);
      final m = (7 * c - b) / 8;
      final nb = 2 * m + b;
      c = 2 * m - c;
      b = nb;
    }
    expect(probs.indexWhere((p) => p > .9), 2);
    expect(probs.indexOf(probs.reduce(math.max)), 2);
  });
  testWidgets(
      'Chapter 13 reader keeps locked future content inaccessible and navigates earned neighbours',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller =
        CampaignProgressController(store: InMemoryCampaignProgressStore());
    await controller.load();
    await controller.unlockDiscovery(entries[0].discoveryTitle);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WebNotebookWorkspace(
                progressController: controller,
                requestedDiscoveryTitle: entries[0].discoveryTitle,
                onOpenJourney: () {}))));
    await tester.pumpAndSettle();
    expect(find.text(entries[0].intuition.body), findsOneWidget);
    expect(find.text(entries[1].intuition.body), findsNothing);
    final related = find.widgetWithText(ActionChip, entries[1].discoveryTitle);
    expect(tester.widget<ActionChip>(related).onPressed, isNull);
    // Navigation skips locked discoveries and may reach the always-open reference.
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('web-notebook-next')),
            matching: find
                .text(notebookEntriesById[notebookReferenceEntryId]!.title)),
        findsOneWidget);
    await controller.unlockDiscovery(entries[1].discoveryTitle);
    await tester.pumpAndSettle();
    expect(controller.unlockedDiscoveryTitles(),
        contains(entries[1].discoveryTitle));
    final next = find.byKey(const ValueKey('web-notebook-next'));
    expect(find.descendant(of: next, matching: find.text(entries[1].title)),
        findsOneWidget);
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('web-notebook-reader-${entries[1].id}')),
        findsOneWidget);
    final previous = find.byKey(const ValueKey('web-notebook-previous'));
    await tester.ensureVisible(previous);
    await tester.pumpAndSettle();
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(find.text(entries[0].intuition.body), findsOneWidget);
    expect(tester.widget<ActionChip>(related).onPressed, isNotNull);
    await tester.ensureVisible(related);
    await tester.pumpAndSettle();
    await tester.tap(related);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('web-notebook-reader-${entries[1].id}')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
