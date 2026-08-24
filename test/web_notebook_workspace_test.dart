import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
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
    ValueChanged<ExecutableNotebookExample>? onOpenExampleInComposer,
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
            onOpenExampleInComposer: onOpenExampleInComposer,
            onOpenExampleInBlochExplorer: onOpenExampleInBlochExplorer,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('wide layout keeps canonical index and reading pane together',
      (tester) async {
    await setSize(tester, const Size(1280, 1000));
    final first = notebookEntries.first;
    final second = notebookEntries[1];
    final locked = notebookEntries[2];
    final controller = await controllerWithDiscoveries(
      [first.discoveryTitle, second.discoveryTitle],
    );
    await pumpWorkspace(tester, controller: controller);

    expect(
        find.byKey(const ValueKey('web-notebook-index-wide')), findsOneWidget);
    expect(find.byKey(const ValueKey('web-notebook-welcome')), findsOneWidget);
    expect(find.text(first.chapterTitle.toUpperCase()), findsOneWidget);
    expect(find.text(first.title), findsOneWidget);

    final lockedTile = tester.widget<ListTile>(
      find.byKey(ValueKey('web-notebook-entry-${locked.id}')),
    );
    expect(lockedTile.enabled, isFalse);
    expect(find.text(locked.intuition.body), findsNothing);

    await tester.tap(find.byKey(ValueKey('web-notebook-entry-${first.id}')));
    await tester.pump();

    expect(find.byKey(ValueKey('web-notebook-reader-${first.id}')),
        findsOneWidget);
    expect(find.text(first.title), findsWidgets);
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

  testWidgets('X example exposes shared Composer and Bloch actions on Web',
      (tester) async {
    await setSize(tester, const Size(1280, 1100));
    final entry = notebookEntries.first;
    final controller = await controllerWithDiscoveries([entry.discoveryTitle]);
    ExecutableNotebookExample? composerExample;
    ExecutableNotebookExample? blochExample;
    ExecutableNotebookResult? blochResult;
    await pumpWorkspace(
      tester,
      controller: controller,
      onOpenExampleInComposer: (example) => composerExample = example,
      onOpenExampleInBlochExplorer: (example, result) {
        blochExample = example;
        blochResult = result;
      },
    );
    await tester.tap(find.byKey(ValueKey('web-notebook-entry-${entry.id}')));
    await tester.pump();
    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('composer-example-x_from_zero')),
        )
        .onPressed!();
    expect(composerExample?.id, 'x_from_zero');

    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('run-example-x_from_zero')),
        )
        .onPressed!();
    await tester.pump();
    expect(find.byKey(const ValueKey('bloch-example-x_from_zero')),
        findsOneWidget);
    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('bloch-example-x_from_zero')),
        )
        .onPressed!();
    expect(blochExample?.id, 'x_from_zero');
    expect(blochResult?.state, hasLength(2));
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

    expect(find.byKey(const ValueKey('web-notebook-index-wide')), findsNothing);
    expect(find.byKey(const ValueKey('web-notebook-index-narrow')),
        findsOneWidget);
    await tester.tap(find.byKey(ValueKey('web-notebook-entry-${entry.id}')));
    await tester.pump();

    expect(
        find.byKey(const ValueKey('web-notebook-index-narrow')), findsNothing);
    expect(find.byKey(const ValueKey('web-notebook-reader-narrow')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('web-notebook-back-index')), findsOneWidget);
  });
}
