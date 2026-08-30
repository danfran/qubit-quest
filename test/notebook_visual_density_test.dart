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
import 'package:quantumquiz/widgets/notebook_typography.dart';
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
    expect(complexI.latexLines, contains(r'i^{2}=-1'));
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
      final latexLines = example.latexLines.isNotEmpty
          ? example.latexLines
          : [example.latex ?? notebookMathNotationToLatex(example.notation)];
      for (final latex in latexLines) {
        expect(latex, isNotEmpty, reason: example.label);
        expect(latex, isNot(contains('⟩')), reason: example.label);
        expect(latex, isNot(contains('√')), reason: example.label);
        expect(latex, isNot(contains('†')), reason: example.label);
        expect(latex, isNot(contains('²')), reason: example.label);
        expect(latex, isNot(contains('e^(')), reason: example.label);
        expect(latex, isNot(contains(' × ')), reason: example.label);
      }
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

  test('Notebook text roles form one restrained semantic hierarchy', () {
    TextStyle style(NotebookTextRole role) =>
        NotebookTypography.text(role, color: Colors.white);

    expect(style(NotebookTextRole.entryTitle).fontSize,
        greaterThan(style(NotebookTextRole.lead).fontSize!));
    expect(style(NotebookTextRole.lead).fontSize,
        lessThan(style(NotebookTextRole.sectionHeading).fontSize!));
    expect(style(NotebookTextRole.sectionHeading).fontSize,
        greaterThan(style(NotebookTextRole.body).fontSize!));
    expect(style(NotebookTextRole.body).fontSize,
        greaterThan(style(NotebookTextRole.supporting).fontSize!));
    expect(style(NotebookTextRole.subsection).fontSize,
        lessThanOrEqualTo(style(NotebookTextRole.body).fontSize!));
    expect(
      style(NotebookTextRole.subsection).fontWeight!.value,
      greaterThan(style(NotebookTextRole.body).fontWeight!.value),
    );
  });

  test('Notebook math roles use a readable, restrained shared scale', () {
    expect(
      NotebookTypography.mathHeight(NotebookMathRole.inline),
      lessThan(NotebookTypography.mathHeight(NotebookMathRole.display)),
    );
    expect(
      NotebookTypography.mathHeight(NotebookMathRole.emphasis),
      greaterThan(NotebookTypography.mathHeight(NotebookMathRole.display)),
    );
    expect(
      NotebookTypography.mathHeight(NotebookMathRole.emphasis) -
          NotebookTypography.mathHeight(NotebookMathRole.display),
      lessThanOrEqualTo(4),
    );
    expect(NotebookTypography.minimumMathScale, greaterThanOrEqualTo(0.8));
  });

  test('stacked math keeps its semantic role and compensates SVG geometry', () {
    const plus =
        r'\lvert +\rangle=\frac{\lvert0\rangle+\lvert1\rangle}{\sqrt{2}}';
    const minus =
        r'\lvert -\rangle=\frac{\lvert0\rangle-\lvert1\rangle}{\sqrt{2}}';
    const multi =
        r'\lvert +0\rangle=\frac{\lvert00\rangle+\lvert10\rangle}{\sqrt{2}}';
    const rootOnly = r'\sqrt{2}';
    const identity = r'U^{\dagger}U=I';
    const probability = r'P(\lvert0\rangle)=50\%';

    expect(NotebookTypography.fractionPerceivedHeightFactor, greaterThan(1));
    expect(NotebookTypography.rootPerceivedHeightFactor, greaterThan(1));

    for (final normalizedState in [plus, minus, multi]) {
      expect(
        NotebookTypography.mathRenderHeight(
          NotebookMathRole.display,
          normalizedState,
        ),
        NotebookTypography.displayMathHeight *
            NotebookTypography.fractionPerceivedHeightFactor,
      );
    }
    expect(
      NotebookTypography.mathRenderHeight(
        NotebookMathRole.display,
        rootOnly,
      ),
      NotebookTypography.displayMathHeight *
          NotebookTypography.rootPerceivedHeightFactor,
    );
    expect(
      NotebookTypography.mathRenderHeight(
        NotebookMathRole.display,
        identity,
      ),
      NotebookTypography.displayMathHeight,
    );
    expect(
      NotebookTypography.mathRenderHeight(
        NotebookMathRole.display,
        probability,
      ),
      NotebookTypography.displayMathHeight,
    );
    expect(
      NotebookTypography.mathRenderHeight(
        NotebookMathRole.emphasis,
        identity,
      ),
      NotebookTypography.emphasisMathHeight,
    );
  });

  test('all authored fractions use the shared compensated math path', () {
    final examples = notebookEntries.expand((entry) => [
          ...entry.intuition.examples,
          ...?entry.whatChanged?.examples,
          ...?entry.quantumView?.examples,
          ...?entry.advancedNotes?.examples,
        ]);
    final fractionLines = <(NotebookExample, String)>[];
    for (final example in examples.where(
      (example) => example.presentation == NotebookExamplePresentation.math,
    )) {
      final lines = example.latexLines.isNotEmpty
          ? example.latexLines
          : [example.latex ?? notebookMathNotationToLatex(example.notation)];
      for (final line in lines.where((line) => line.contains(r'\frac'))) {
        fractionLines.add((example, line));
      }
    }

    expect(fractionLines.length, greaterThan(10));
    for (final (example, line) in fractionLines) {
      expect(example.mathRole, isNot(NotebookMathRole.inline));
      expect(
        NotebookTypography.mathRenderHeight(example.mathRole, line),
        greaterThan(NotebookTypography.mathHeight(example.mathRole)),
        reason: '${example.label}: $line',
      );
    }
  });

  test('authored equations use standard display unless deliberately emphasized',
      () {
    final reversibility = notebookEntriesById['reversibility']!;
    NotebookExample named(String label) => [
          ...reversibility.whatChanged!.examples,
          ...reversibility.quantumView!.examples,
        ].singleWhere((example) => example.label == label);

    for (final label in const [
      'Inverse identity',
      'X on basis states',
      'Self-inverse gates',
      'Phase inverses',
    ]) {
      expect(named(label).mathRole, NotebookMathRole.display, reason: label);
    }
    expect(named('X progression').mathRole, NotebookMathRole.emphasis);
    expect(named('Reverse a sequence').mathRole, NotebookMathRole.emphasis);
    expect(named('Self-inverse gates').notation.split('\n'), hasLength(2));
    expect(named('Phase inverses').notation.split('\n'), hasLength(2));
  });

  test('representative mathematical roles span the production curriculum', () {
    NotebookExample example(String entryId, String label) {
      final entry = notebookEntriesById[entryId]!;
      return [
        ...entry.intuition.examples,
        ...?entry.whatChanged?.examples,
        ...?entry.quantumView?.examples,
        ...?entry.advancedNotes?.examples,
      ].singleWhere((example) => example.label == label);
    }

    final representatives = [
      example('information', 'Before'),
      example('the_minus_sign', 'Before'),
      example('hidden_information', 'Measurement before'),
      example('hidden_information', 'Accumulated phase'),
      example('hidden_information', 'Y on basis states'),
      example('bell_state', 'Bell state'),
      example('ghz_state', 'Global branch phase'),
      example('notation_and_terms', 'Tensor product'),
      example('oracle_intuition', 'Accepted'),
      example('reversibility', 'Reverse a sequence'),
    ];
    expect(
      representatives.every(
        (example) => example.presentation == NotebookExamplePresentation.math,
      ),
      isTrue,
    );
    expect(
        example('the_minus_sign', 'Before').mathRole, NotebookMathRole.display);
    expect(
        example('bell_state', 'Bell state').mathRole, NotebookMathRole.display);
    expect(example('ghz_state', 'Global branch phase').mathRole,
        NotebookMathRole.emphasis);
    expect(notebookEntriesById.keys.toSet(), hasLength(notebookEntries.length));
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

  testWidgets('grouped equations keep one standard size per equation',
      (tester) async {
    final example = notebookEntriesById['reversibility']!
        .quantumView!
        .examples
        .singleWhere((example) => example.label == 'Self-inverse gates');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: NotebookMathEvidence(example: example),
          ),
        ),
      ),
    );

    final renderers = tester.widgetList<LatexText>(find.byType(LatexText));
    expect(renderers, hasLength(2));
    expect(
      renderers.map((renderer) => renderer.displayMathHeight).toSet(),
      {NotebookTypography.displayMathHeight},
    );
  });

  testWidgets('normalized states share readable fraction sizing at phone width',
      (tester) async {
    NotebookExample example(String entryId, String label) {
      final entry = notebookEntriesById[entryId]!;
      return [
        ...entry.intuition.examples,
        ...?entry.whatChanged?.examples,
        ...?entry.quantumView?.examples,
        ...?entry.advancedNotes?.examples,
      ].singleWhere((example) => example.label == label);
    }

    final fixtures = [
      example('the_third_state', 'Plus state'),
      example('the_minus_sign', 'After'),
      example('superposition', 'Two-qubit superposition'),
      example('bell_state', 'Bell state'),
    ];
    expect(fixtures.every((item) => item.mathRole == NotebookMathRole.display),
        isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final fixture in fixtures)
                    NotebookMathEvidence(example: fixture),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final renderers = tester.widgetList<LatexText>(find.byType(LatexText));
    expect(renderers, hasLength(fixtures.length));
    for (final renderer in renderers) {
      expect(
        renderer.displayMathHeight,
        NotebookTypography.displayMathHeight *
            NotebookTypography.fractionPerceivedHeightFactor,
      );
      expect(renderer.minimumDisplayMathScale,
          NotebookTypography.minimumMathScale);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('emphasis and inline math resolve through semantic roles',
      (tester) async {
    final emphasis = notebookEntriesById['reversibility']!
        .whatChanged!
        .examples
        .singleWhere((example) => example.label == 'X progression');
    const inline = NotebookExample.math(
      label: 'Inline fixture',
      notation: 'U†',
      mathRole: NotebookMathRole.inline,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              NotebookMathEvidence(example: emphasis),
              const NotebookMathEvidence(example: inline),
            ],
          ),
        ),
      ),
    );

    final renderers =
        tester.widgetList<LatexText>(find.byType(LatexText)).toList();
    expect(
        renderers[0].displayMathHeight, NotebookTypography.emphasisMathHeight);
    expect(renderers[1].inlineMathHeight, NotebookTypography.inlineMathHeight);
  });

  testWidgets('math fitting preserves short size and floors long expressions',
      (tester) async {
    const shortSvg =
        '<svg viewBox="0 0 100 20"><rect width="100" height="20"/></svg>';
    const longSvg =
        '<svg viewBox="0 0 1000 20"><rect width="1000" height="20"/></svg>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 300,
                child: LatexSvgPicture(
                  svg: shortSvg,
                  logicalHeight: NotebookTypography.displayMathHeight,
                  minimumScale: NotebookTypography.minimumMathScale,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 300,
                child: LatexSvgPicture(
                  svg: longSvg,
                  logicalHeight: NotebookTypography.displayMathHeight,
                  minimumScale: NotebookTypography.minimumMathScale,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('latex-readable-overflow-fallback')),
        findsOneWidget);
    final fallbackSize = tester.getSize(
      find.byKey(const ValueKey('latex-readable-overflow-fallback')),
    );
    expect(
      fallbackSize.height,
      greaterThanOrEqualTo(
        NotebookTypography.displayMathHeight *
            NotebookTypography.minimumMathScale,
      ),
    );
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
