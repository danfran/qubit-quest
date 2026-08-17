import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_search.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final index = NotebookSearchIndex.build(
    entries: notebookEntries,
    executableExamples: executableNotebookExamples,
  );

  String idAt(String query, int position) =>
      index.search(query)[position].entry.id;

  group('NotebookSearchIndex', () {
    test('indexes the complete authored corpus and passes its content audit',
        () {
      final audit = NotebookSearchIndex.audit(
        entries: notebookEntries,
        executableExamples: executableNotebookExamples,
      );
      expect(audit.errors, isEmpty);
      expect(index.documents, hasLength(notebookEntries.length));
    });

    test('finds representative curriculum concepts', () {
      expect(index.search('Hadamard').map((result) => result.entry.id),
          contains('superposition'));
      expect(index.search('phase').map((result) => result.entry.id),
          contains('the_minus_sign'));
      expect(idAt('relative phase', 0), 'the_minus_sign');
      expect(idAt('Bell', 0), 'bell_state');
      expect(idAt('entanglement', 0), 'entanglement');
      expect(idAt('interference', 0), 'interference');
      expect(index.search('Rx').map((result) => result.entry.id),
          contains('precise_superposition'));
      expect(index.search('rotation').map((result) => result.entry.id),
          contains('precise_superposition'));
      expect(index.search('Grover').first.entry.chapterIndex, 11);
    });

    test('title matches outrank incidental body matches', () {
      expect(idAt('Bell State', 0), 'bell_state');
      expect(idAt('Relative Phase', 0), 'the_minus_sign');
    });

    test('normalization is case, whitespace, punctuation and ket tolerant', () {
      expect(
        index.search('  HADAMARD!! ').map((result) => result.entry.id),
        contains('superposition'),
      );
      expect(
        index.search('|+>').map((result) => result.entry.id).toSet(),
        index.search('|+⟩').map((result) => result.entry.id).toSet(),
      );
    });

    test('multi-word results favour documents containing every token', () {
      final results = index.search('relative phase');
      expect(results, isNotEmpty);
      expect(results.first.entry.id, 'the_minus_sign');
      expect(results.first.score, greaterThan(results.last.score));
    });

    test('empty and nonsense queries return no results', () {
      expect(index.search('  '), isEmpty);
      expect(index.search('teleportation-zebra-947'), isEmpty);
    });

    test('executable examples resolve through their containing entry', () {
      expect(idAt('Build a Bell state', 0), 'bell_state');
      expect(
        index.search('Ry').map((result) => result.entry.id),
        contains('precise_superposition'),
      );
    });
  });

  group('Notebook search UI', () {
    Future<void> pumpSearch(
      WidgetTester tester, {
      Size size = const Size(390, 844),
    }) async {
      SharedPreferences.setMockInitialValues({});
      await CampaignProgressController.instance.load();
      await CampaignProgressController.instance.unlockAllCampaignContent();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: DiscoveriesScreen()),
      );
      await tester.pumpAndSettle();
    }

    Future<void> search(WidgetTester tester, String query) async {
      await tester.tap(find.byKey(const ValueKey('open-notebook-search')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('notebook-search-field')),
        query,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('compact app-bar search filters and navigates normally',
        (tester) async {
      await pumpSearch(tester);
      expect(find.text('Quantum Notebook'), findsOneWidget);
      expect(find.byKey(const ValueKey('notebook-search-field')), findsNothing);
      await search(tester, 'Bell');
      expect(find.byKey(const ValueKey('notebook-search-results')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('notebook-search-result-bell_state')),
          findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('notebook-search-result-bell_state')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bell State'), findsWidgets);
      expect(
        executableNotebookExamplesById['bell_phi_plus'],
        isNotNull,
      );
    });

    testWidgets('empty query restores chapters and clear is accessible',
        (tester) async {
      await pumpSearch(tester);
      await search(tester, 'phase');
      expect(
          find.byKey(const ValueKey('clear-notebook-search')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('clear-notebook-search')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('notebook-search-results')), findsNothing);
      expect(find.textContaining('Chapter 1'), findsWidgets);
    });

    testWidgets('nonsense query has concise empty state', (tester) async {
      await pumpSearch(tester);
      await search(tester, 'teleportation-zebra-947');
      expect(
          find.byKey(const ValueKey('notebook-search-empty')), findsOneWidget);
    });

    for (final size in [
      const Size(320, 700),
      const Size(844, 390),
      const Size(1180, 820),
    ]) {
      testWidgets('results remain usable at ${size.width}x${size.height}',
          (tester) async {
        await pumpSearch(tester, size: size);
        await search(tester, 'phase');
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('notebook-search-results')),
            findsOneWidget);
      });
    }
  });
}
