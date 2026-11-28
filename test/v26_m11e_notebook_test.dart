// v2.6 M11E: Notebook reading, mathematics and exploration.
//
// Article and Spread are two presentations of one ordered block list; the
// contextual margin only moves blocks, never repeats them; authored content
// (including advanced-note examples, previously not shown on the web) is all
// reachable; layouts do not overflow at phone width or with large text.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/screens/notebook_article_view.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/widgets/notebook_typography.dart';

ValueKey<String> _k(String v) => ValueKey(v);

Future<CampaignProgressController> _allDiscovered() async {
  final c = CampaignProgressController(store: InMemoryCampaignProgressStore());
  await c.load();
  for (final e in notebookEntries) {
    await c.unlockDiscovery(e.discoveryTitle);
  }
  return c;
}

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<WebNotebookWorkspaceState> _pump(
  WidgetTester tester,
  CampaignProgressController progress, {
  required String articleId,
  Size size = const Size(2000, 1200),
  double textScale = 1,
}) async {
  _size(tester, size);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: WebNotebookWorkspace(
          progressController: progress,
          onOpenJourney: () {},
          requestedArticleId: articleId,
          requestSerial: 1,
          onOpenJourneyLesson: (_) {},
          onOpenMasteryChallenge: (_) {},
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return tester.state(find.byType(WebNotebookWorkspace));
}

/// Block IDs rendered in [scope] (`notebook-block-<id>`).
Set<String> _blocks([Finder? scope]) {
  final finder = find.byWidgetPredicate((w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('notebook-block-'));
  final f = scope == null
      ? finder
      : find.descendant(of: scope, matching: finder);
  return {
    for (final e in f.evaluate())
      (e.widget.key! as ValueKey<String>)
          .value
          .substring('notebook-block-'.length),
  };
}

Future<void> _setMode(WidgetTester tester, String mode) async {
  await tester.tap(find.byKey(_k('web-notebook-mode-$mode')));
  await tester.pumpAndSettle();
}

void main() {
  group('Article and Spread present the same content', () {
    for (final id in const [
      'reusable_phase_oracle',
      'bell_state',
      'superposition',
      'gate-mcx',
      'gate-cy',
    ]) {
      testWidgets('$id: same blocks, maths and experiments', (tester) async {
        final progress = await _allDiscovered();
        final state = await _pump(tester, progress, articleId: id);
        expect(state.readingMode, NotebookReadingMode.article);
        expect(find.byKey(_k('web-notebook-spread')), findsNothing);
        // Wide Article: the margin holds "Where it is used" instead of the
        // column, so nothing is shown twice.
        expect(find.byKey(_k('web-notebook-margin')), findsOneWidget);
        expect(find.byKey(_k('web-notebook-activities')), findsOneWidget);
        final article = _blocks();
        final articleMaths = find.byType(NotebookMathEvidence).evaluate().length;
        final articleFigures =
            find.byType(NotebookExperimentFigure).evaluate().length;

        await _setMode(tester, 'spread');
        expect(state.readingMode, NotebookReadingMode.spread);
        expect(find.byKey(_k('web-notebook-spread')), findsOneWidget);
        expect(find.byKey(_k('web-notebook-margin')), findsNothing);
        final spread = _blocks();
        expect(spread, {...article, 'activities'},
            reason: 'the margin block returns to the left page');
        expect(find.byType(NotebookMathEvidence).evaluate().length,
            articleMaths);
        expect(find.byType(NotebookExperimentFigure).evaluate().length,
            articleFigures);

        // Explanation on the left, evidence on the right.
        final left = _blocks(find.byKey(_k('web-notebook-page-left')));
        final right = _blocks(find.byKey(_k('web-notebook-page-right')));
        expect(left, contains('header'));
        expect(left.intersection(right), isEmpty);
        if (article.contains('experiments')) {
          expect(right, contains('experiments'));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('discovery sections keep their authored text in both modes',
        (tester) async {
      final progress = await _allDiscovered();
      final entry = notebookEntriesById['bell_state']!;
      await _pump(tester, progress, articleId: entry.id);
      for (final mode in ['article', 'spread']) {
        await _setMode(tester, mode);
        for (final section in [
          entry.intuition,
          entry.whatChanged!,
          entry.quantumView!,
        ]) {
          expect(find.byKey(_k('web-notebook-section-${section.title}')),
              findsOneWidget);
          expect(find.textContaining(section.body.substring(0, 30)),
              findsOneWidget,
              reason: '$mode: ${section.title}');
        }
      }
    });
  });

  testWidgets(
      'Spread falls back to Article where it does not fit and returns '
      'when it does; the preference is kept', (tester) async {
    final progress = await _allDiscovered();
    final state =
        await _pump(tester, progress, articleId: 'reusable_phase_oracle');
    await _setMode(tester, 'spread');
    expect(find.byKey(_k('web-notebook-spread')), findsOneWidget);

    _size(tester, const Size(1280, 900));
    await tester.pumpAndSettle();
    expect(find.byKey(_k('web-notebook-spread')), findsNothing);
    expect(state.readingMode, NotebookReadingMode.spread);
    final toggle = tester.widget<SegmentedButton<NotebookReadingMode>>(
        find.byKey(_k('web-notebook-mode')));
    expect(toggle.selected, {NotebookReadingMode.article});
    expect(toggle.segments.last.enabled, isFalse);

    _size(tester, const Size(2000, 1200));
    await tester.pumpAndSettle();
    expect(find.byKey(_k('web-notebook-spread')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the notation glossary always reads as one column',
      (tester) async {
    final progress = await _allDiscovered();
    final state =
        await _pump(tester, progress, articleId: 'notation_and_terms');
    final toggle = tester.widget<SegmentedButton<NotebookReadingMode>>(
        find.byKey(_k('web-notebook-mode')));
    expect(toggle.segments.last.enabled, isFalse);
    expect(state.readingMode, NotebookReadingMode.article);
    final entry = notebookEntriesById['notation_and_terms']!;
    for (final e in [
      ...entry.intuition.examples,
      ...entry.whatChanged!.examples,
      ...entry.quantumView!.examples,
    ]) {
      expect(find.byKey(_k('web-notebook-term-${e.label}')), findsOneWidget,
          reason: e.label);
    }
    expect(find.byKey(_k('web-notebook-conventions')), findsOneWidget);
    expect(find.textContaining('q0 is the rightmost symbol'), findsOneWidget);
  });

  testWidgets('advanced notes: a disclosure, with their authored examples',
      (tester) async {
    final progress = await _allDiscovered();
    final entry = notebookEntriesById['bell_state']!;
    expect(entry.advancedNotes!.examples, isNotEmpty);
    await _pump(tester, progress, articleId: entry.id);
    expect(find.byKey(_k('web-notebook-advanced-notes')), findsOneWidget);
    expect(find.byKey(_k('web-notebook-examples-advanced')), findsNothing);
    final toggle = find.byKey(_k('web-notebook-advanced-toggle'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byKey(_k('web-notebook-examples-advanced')), findsOneWidget);
    expect(find.textContaining(entry.advancedNotes!.body.substring(0, 30)),
        findsOneWidget);
  });

  testWidgets(
      'experiments: Run in Composer is the primary action and opens the '
      'authored circuit', (tester) async {
    final progress = await _allDiscovered();
    final state =
        await _pump(tester, progress, articleId: 'reusable_phase_oracle');
    final run = find.byKey(_k('notebook-explore-oracle_pattern_1010'));
    expect(
        find.descendant(of: run, matching: find.text('Run in Composer')),
        findsOneWidget);
    expect(find.byKey(_k('notebook-example-state-oracle_pattern_1010')),
        findsOneWidget);
    await tester.ensureVisible(run);
    await tester.pumpAndSettle();
    await tester.tap(run);
    await tester.pumpAndSettle();
    final circuit = state.experimentSession!.circuit;
    expect(circuit.currentLevel.numQubits, 5);
    expect(circuit.logicalGates, isNotEmpty);
    expect(find.byKey(_k('notebook-experiment-workspace')), findsOneWidget);
  });

  testWidgets('index: three groups, selected entry revealed', (tester) async {
    final progress = await _allDiscovered();
    final state = await _pump(tester, progress,
        articleId: 'notation_and_terms', size: const Size(1440, 1400));
    for (final g in ['notation', 'gates', 'discoveries']) {
      expect(find.byKey(_k('web-notebook-group-$g')), findsOneWidget);
    }
    _size(tester, const Size(1440, 700));
    state.select('reusable_phase_oracle');
    await tester.pumpAndSettle();
    final row = find.byKey(_k('web-notebook-entry-reusable_phase_oracle'));
    expect(row, findsOneWidget);
    final index = tester.getRect(find.byKey(_k('web-notebook-index')));
    final rect = tester.getRect(row);
    expect(index.contains(rect.center), isTrue,
        reason: 'the last chapter\'s entry is scrolled into view');
  });

  group('no overflow', () {
    for (final (size, scale) in const [
      (Size(390, 844), 1.0),
      (Size(390, 844), 1.5),
      (Size(844, 390), 1.0),
      (Size(1024, 768), 1.3),
      (Size(2560, 1080), 1.0),
    ]) {
      for (final id in const [
        'gate-mcx',
        'gate-ry',
        'reusable_phase_oracle',
        'notation_and_terms',
        'superposition',
      ]) {
        testWidgets('$id at $size ×$scale', (tester) async {
          final progress = await _allDiscovered();
          await _pump(tester, progress,
              articleId: id, size: size, textScale: scale);
          expect(find.byKey(_k('web-notebook-entry-title')), findsOneWidget);
          final reader = find.byKey(_k('web-notebook-reader-$id'));
          await tester.drag(reader.first, const Offset(0, -3000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
