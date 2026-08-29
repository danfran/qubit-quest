import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/mastery_2_reinforcement.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/notebook_search.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Undo The Change introduces inverse notation before precision', () {
    final entry = notebookEntriesById['reversibility']!;
    expect(entry.intuition.body, contains('U† (“U dagger”)'));
    expect(entry.quantumView!.body, contains('U†U = I'));
    expect(entry.quantumView!.body, contains('identity'));
    expect(entry.advancedNotes!.body, contains('conjugate transpose'));
    expect(entry.advancedNotes!.body, contains('U⁻¹'));

    final notation = [
      for (final example in [
        ...entry.intuition.examples,
        ...entry.whatChanged!.examples,
        ...entry.quantumView!.examples,
      ])
        example.notation,
    ].join('\n');
    expect(notation, contains('|0⟩ → X → |1⟩ → X → |0⟩'));
    expect(notation, contains('X² = I'));
    expect(notation, contains('CNOT² = I'));
    expect(notation, contains('S†S = I'));
    expect(notation, contains('T†T = I'));
    expect(
      entry.quantumView!.examples.every(
        (example) => example.presentation == NotebookExamplePresentation.math,
      ),
      isTrue,
    );
  });

  test('authored Notebook math uses explicit mathematical presentation', () {
    NotebookExample example(String entryId, String label) {
      final entry = notebookEntriesById[entryId]!;
      return [
        ...entry.intuition.examples,
        ...?entry.whatChanged?.examples,
        ...?entry.quantumView?.examples,
        ...?entry.advancedNotes?.examples,
      ].singleWhere((example) => example.label == label);
    }

    final plus = example('the_minus_sign', 'Before');
    final probability = example('hidden_information', 'Measurement before');
    final phase = example('hidden_information', 'Accumulated phase');
    final complexI = example('hidden_information', 'Quarter turns');
    final inverseIdentity = example('reversibility', 'Inverse identity');
    final dagger = example('reversibility', 'Phase inverses');

    for (final math in [
      plus,
      probability,
      phase,
      complexI,
      inverseIdentity,
      dagger,
    ]) {
      expect(math.presentation, NotebookExamplePresentation.math);
    }
    expect(notebookMathNotationToLatex(plus.notation), contains(r'\frac{'));
    expect(notebookMathNotationToLatex(plus.notation), contains(r'\sqrt{2}'));
    expect(probability.notation, contains('P(|0⟩)'));
    expect(phase.latex, r'e^{i\alpha}e^{i\beta}=e^{i(\alpha+\beta)}');
    expect(complexI.latex, contains(r'i^{2}=-1'));
    expect(
      notebookMathNotationToLatex(inverseIdentity.notation),
      r'U^{\dagger}U = I',
    );
    expect(
        notebookMathNotationToLatex(dagger.notation), contains(r'^{\dagger}'));

    final prose = example('hidden_information', 'Key difference');
    expect(prose.presentation, NotebookExamplePresentation.prose);
    expect(prose.latex, isNull);
  });

  test('all authored mathematical examples normalize to TeX notation', () {
    final examples = notebookEntries.expand((entry) => [
          ...entry.intuition.examples,
          ...?entry.whatChanged?.examples,
          ...?entry.quantumView?.examples,
          ...?entry.advancedNotes?.examples,
        ]);
    final mathExamples = examples.where(
      (example) => example.presentation == NotebookExamplePresentation.math,
    );
    expect(mathExamples.length, greaterThan(100));
    for (final example in mathExamples) {
      final latex =
          example.latex ?? notebookMathNotationToLatex(example.notation);
      expect(latex, isNotEmpty, reason: example.label);
      expect(latex, isNot(contains('⟩')), reason: example.label);
      expect(latex, isNot(contains('√')), reason: example.label);
      expect(latex, isNot(contains('†')), reason: example.label);
      expect(latex, isNot(contains('²')), reason: example.label);
      expect(latex, isNot(contains('e^(')), reason: example.label);
      expect(latex, isNot(contains(' × ')), reason: example.label);
    }
  });

  test('Notation & Terms is registered, available, and searchable', () {
    final glossary = notebookEntriesById[notebookReferenceEntryId];
    expect(glossary, isNotNull);
    expect(isNotebookEntryAvailable(glossary!, const {}), isTrue);

    final text = [
      glossary.summary,
      glossary.intuition.body,
      ...glossary.intuition.examples.expand((e) => [e.label, e.notation]),
      ...glossary.whatChanged!.examples.expand((e) => [e.label, e.notation]),
      ...glossary.quantumView!.examples.expand((e) => [e.label, e.notation]),
    ].join('\n');
    for (final term in const [
      'Dagger',
      'Identity',
      'Ket',
      'Amplitude',
      'Global phase',
      'Relative phase',
      'Superposition',
      'Entanglement',
      'Ancilla',
      'Oracle',
      'Uncomputation',
      'Tensor product',
    ]) {
      expect(text, contains(term));
    }
    final ket =
        glossary.intuition.examples.singleWhere((e) => e.label == 'Ket');
    final dagger =
        glossary.whatChanged!.examples.singleWhere((e) => e.label == 'Dagger');
    expect(ket.latex, r'\lvert\psi\rangle');
    expect(dagger.latex, r'U^{\dagger}=U^{-1}');
    expect(dagger.presentation, NotebookExamplePresentation.math);

    final allowed = notebookSearchAllowedEntryIds(
      entries: notebookEntries,
      unlockedDiscoveryTitles: const {},
    );
    expect(allowed, contains(notebookReferenceEntryId));
  });

  test('all 34 reinforcement destinations remain registered', () {
    expect(mastery2NotebookReinforcementEntryIds, hasLength(34));
    for (final entryId in mastery2NotebookReinforcementEntryIds.values) {
      expect(notebookEntriesById[entryId], isNotNull);
    }
  });

  Future<void> setPhoneSize(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  testWidgets('dense Notebook entry is compact and scrolls without overflow',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await CampaignProgressController.instance.load();
    await setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: NotebookEntryScreen(
          entry: notebookEntriesById['reversibility']!,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notebook-key-examples')), findsOneWidget);
    expect(find.text('STATE'), findsNothing);
    expect(find.text('FORMULA'), findsNothing);
    expect(find.text('TRANSFORM'), findsNothing);
    expect(find.byType(LatexText), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('prose stays text while probability comparison fits a phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await CampaignProgressController.instance.load();
    await setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: NotebookEntryScreen(
          entry: notebookEntriesById['hidden_information']!,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Measurement before'), findsOneWidget);
    expect(find.text('Measurement after'), findsOneWidget);
    expect(
      find.text(
        'The probabilities stayed the same, but the phase relationship changed.',
      ),
      findsOneWidget,
    );
    expect(find.byType(LatexText), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('glossary is navigable with no Journey discoveries unlocked',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = CampaignProgressController(
      store: InMemoryCampaignProgressStore(),
    );
    await controller.load();
    CampaignProgressController.configureSharedInstance(controller);
    await setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const DiscoveriesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notation & Terms'), findsOneWidget);
    await tester.tap(find.text('Notation & Terms'));
    await tester.pumpAndSettle();
    expect(find.byType(NotebookEntryScreen), findsOneWidget);
    expect(
      find.text(
        'A compact reference for the symbols and recurring language used in Qubit Quest.',
      ),
      findsOneWidget,
    );
    expect(controller.state.completedLessonIds, isEmpty);
    expect(controller.state.completedMasterySemanticIds, isEmpty);
    expect(controller.state.maxUnlockedLevel, 1);
  });
}
