// Web Notebook workspace (v2.6 M6b knowledge base). Ported from the pre-M6b
// modal-index tests: the behaviours they protected are kept.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';

void main() {
  Future<CampaignProgressController> controllerWithDiscoveries(
    Iterable<String> discoveries,
  ) async {
    final controller = CampaignProgressController(
      store: InMemoryCampaignProgressStore(),
    );
    await controller.load();
    for (final discovery in discoveries) {
      await controller.unlockDiscovery(discovery);
    }
    return controller;
  }

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpWorkspace(
    WidgetTester tester, {
    required CampaignProgressController controller,
    String? requestedDiscoveryTitle,
    void Function(ExecutableNotebookExample, ExecutableNotebookResult)?
        onOpenExampleInBlochExplorer,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: WebNotebookWorkspace(
            progressController: controller,
            requestedDiscoveryTitle: requestedDiscoveryTitle,
            onOpenJourney: () {},
            onOpenExampleInBlochExplorer: onOpenExampleInBlochExplorer,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> expandChapter(WidgetTester tester, int chapter) async {
    await tester.tap(
        find.byKey(ValueKey('web-notebook-category-chapter-$chapter')));
    await tester.pumpAndSettle();
  }

  testWidgets('wide layout: persistent index and article; locked entries '
      'preview without content', (tester) async {
    await setSize(tester, const Size(1280, 1000));
    final first = notebookEntries.first;
    final second = notebookEntries[1];
    final locked = notebookEntries[2];
    final controller = await controllerWithDiscoveries(
      [first.discoveryTitle, second.discoveryTitle],
    );
    await pumpWorkspace(tester, controller: controller);

    expect(find.byKey(const ValueKey('web-notebook-master-detail')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-notebook-index')), findsOneWidget);
    // The always-available notation reference is the default article.
    expect(find.byKey(const ValueKey('web-notebook-reader-notation_and_terms')),
        findsOneWidget);
    expect(find.byKey(ValueKey('web-notebook-entry-${first.id}')),
        findsNothing, reason: 'chapters start collapsed');
    await expandChapter(tester, first.chapterIndex);
    expect(find.byKey(ValueKey('web-notebook-entry-${first.id}')),
        findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(ValueKey(
                'web-notebook-category-count-chapter-${first.chapterIndex}')))
            .data,
        '2 / 5 discovered');

    // A locked entry is selectable but shows no content.
    await tester.tap(find.byKey(ValueKey('web-notebook-entry-${locked.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('web-notebook-locked-preview')),
        findsOneWidget);
    expect(find.text(locked.intuition.body), findsNothing);
    expect(controller.openedDiscoveryTitles(),
        isNot(contains(locked.discoveryTitle)));
    expect(controller.unlockedDiscoveryTitles(),
        isNot(contains(locked.discoveryTitle)));

    await tester.tap(find.byKey(ValueKey('web-notebook-entry-${first.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('web-notebook-reader-${first.id}')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-notebook-section-Intuition')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-notebook-section-What Changed?')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-notebook-section-Quantum View')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-notebook-advanced-notes')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-notebook-related')), findsOneWidget);
    expect(controller.openedDiscoveryTitles(), contains(first.discoveryTitle));
    expect(find.byKey(const ValueKey('web-notebook-next')), findsOneWidget);
  });

  testWidgets('search uses canonical index and opens only discovered results',
      (tester) async {
    await setSize(tester, const Size(1280, 900));
    final first = notebookEntries.first;
    final second = notebookEntries[1];
    final controller = await controllerWithDiscoveries(
      [first.discoveryTitle, second.discoveryTitle],
    );
    await pumpWorkspace(tester, controller: controller);

    await tester.enterText(
      find.byKey(const ValueKey('web-notebook-search-field')),
      second.title,
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('web-notebook-search-results')),
        findsOneWidget);
    expect(find.byKey(ValueKey('web-notebook-search-${second.id}')),
        findsOneWidget);
    // Undiscovered entries are never search results.
    expect(find.byKey(ValueKey('web-notebook-search-${notebookEntries[2].id}')),
        findsNothing);
    await tester.tap(find.byKey(ValueKey('web-notebook-search-${second.id}')));
    await tester.pump();
    expect(find.byKey(ValueKey('web-notebook-reader-${second.id}')),
        findsOneWidget);
    expect(
      tester
          .widget<TextField>(
              find.byKey(const ValueKey('web-notebook-search-field')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.byKey(const ValueKey('web-notebook-search-results')),
        findsNothing);
  });

  testWidgets('narrow search replaces an active reader and opens its result',
      (tester) async {
    await setSize(tester, const Size(620, 900));
    final first = notebookEntries.first;
    final second = notebookEntries[1];
    final controller = await controllerWithDiscoveries(
      [first.discoveryTitle, second.discoveryTitle],
    );
    await pumpWorkspace(tester, controller: controller);
    await expandChapter(tester, first.chapterIndex);
    await tester.tap(find.byKey(ValueKey('web-notebook-entry-${first.id}')));
    await tester.pump();
    expect(find.byKey(const ValueKey('web-notebook-reader-narrow')),
        findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('web-notebook-search-field')),
      second.title,
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('web-notebook-index-narrow')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-notebook-search-results')),
        findsOneWidget);
    await tester.tap(find.byKey(ValueKey('web-notebook-search-${second.id}')));
    await tester.pump();
    expect(find.byKey(ValueKey('web-notebook-reader-${second.id}')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-notebook-search-results')),
        findsNothing);
  });

  testWidgets('Journey deep-link clears stale search and selects its entry',
      (tester) async {
    await setSize(tester, const Size(620, 900));
    final first = notebookEntries.first;
    final second = notebookEntries[1];
    final controller = await controllerWithDiscoveries(
      [first.discoveryTitle, second.discoveryTitle],
    );
    await pumpWorkspace(
      tester,
      controller: controller,
      requestedDiscoveryTitle: first.discoveryTitle,
    );
    await tester.enterText(
      find.byKey(const ValueKey('web-notebook-search-field')),
      second.title,
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('web-notebook-search-results')),
        findsOneWidget);

    await pumpWorkspace(
      tester,
      controller: controller,
      requestedDiscoveryTitle: second.discoveryTitle,
    );
    await tester.pump();

    expect(find.byKey(ValueKey('web-notebook-reader-${second.id}')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-notebook-search-results')),
        findsNothing);
  });

  testWidgets('X example opens a Notebook experiment and the Bloch handoff',
      (tester) async {
    await setSize(tester, const Size(1280, 1100));
    final entry = notebookEntries.first;
    final controller = await controllerWithDiscoveries([entry.discoveryTitle]);
    ExecutableNotebookExample? blochExample;
    ExecutableNotebookResult? blochResult;
    await pumpWorkspace(
      tester,
      controller: controller,
      requestedDiscoveryTitle: entry.discoveryTitle,
      onOpenExampleInBlochExplorer: (example, result) {
        blochExample = example;
        blochResult = result;
      },
    );
    await tester.pumpAndSettle();
    final bloch = find.byKey(const ValueKey('bloch-example-x_from_zero'));
    await tester.ensureVisible(bloch);
    await tester.pumpAndSettle();
    await tester.tap(bloch);
    expect(blochExample?.id, 'x_from_zero');
    expect(blochResult?.state, hasLength(2));

    final explore = find.byKey(const ValueKey('notebook-explore-x_from_zero'));
    await tester.ensureVisible(explore);
    await tester.pumpAndSettle();
    await tester.tap(explore);
    await tester.pumpAndSettle();
    final state = tester.state<WebNotebookWorkspaceState>(
        find.byType(WebNotebookWorkspace));
    final session = state.experimentSession!;
    expect(session.circuit.logicalGates.map((g) => g.type),
        [SelectedGateType.x]);
    expect(find.byKey(const ValueKey('notebook-experiment-workspace')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('web-lesson-check')), findsNothing,
        reason: 'experiments have no Check');
  });

  testWidgets('requested Journey discovery opens the matching canonical entry',
      (tester) async {
    await setSize(tester, const Size(1200, 900));
    final entry = notebookEntries[1];
    final controller = await controllerWithDiscoveries([entry.discoveryTitle]);
    await pumpWorkspace(
      tester,
      controller: controller,
      requestedDiscoveryTitle: entry.discoveryTitle,
    );
    await tester.pump();

    expect(find.byKey(ValueKey('web-notebook-reader-${entry.id}')),
        findsOneWidget);
    expect(find.text(entry.title), findsWidgets);
  });

  testWidgets('narrow layout uses index then reader with a back affordance',
      (tester) async {
    await setSize(tester, const Size(620, 900));
    final entry = notebookEntries.first;
    final controller = await controllerWithDiscoveries([entry.discoveryTitle]);
    await pumpWorkspace(tester, controller: controller);

    expect(find.byKey(const ValueKey('web-notebook-master-detail')),
        findsNothing);
    expect(find.byKey(const ValueKey('web-notebook-index-narrow')),
        findsOneWidget);
    await expandChapter(tester, entry.chapterIndex);
    await tester.tap(find.byKey(ValueKey('web-notebook-entry-${entry.id}')));
    await tester.pump();

    expect(
        find.byKey(const ValueKey('web-notebook-index-narrow')), findsNothing);
    expect(find.byKey(const ValueKey('web-notebook-reader-narrow')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('web-notebook-back-index')));
    await tester.pump();
    expect(find.byKey(const ValueKey('web-notebook-index-narrow')),
        findsOneWidget);
  });
}
