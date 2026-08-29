import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/screens/mcq_screen.dart';
import 'package:quantumquiz/widgets/adaptive_learning_card.dart';

void main() {
  Future<void> configureProgress({String? unlockedDiscovery}) async {
    final controller = CampaignProgressController(
      store: InMemoryCampaignProgressStore(),
    );
    await controller.load();
    if (unlockedDiscovery != null) {
      await controller.unlockDiscovery(unlockedDiscovery);
    }
    CampaignProgressController.configureSharedInstance(controller);
  }

  Future<void> pumpChallenge(
    WidgetTester tester, {
    required McqLevel level,
    required MasteryChallengeDefinition definition,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 700);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: McqScreen(
          levelId: definition.displayOrder,
          level: level,
          masteryChallenge: definition,
          onLevelUnlocked: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  Future<void> answerIncorrectly(WidgetTester tester) async {
    await reveal(tester, find.byKey(const ValueKey('mcq-option-1')));
    await tester.tap(find.byKey(const ValueKey('mcq-option-1')));
    await reveal(tester, find.byKey(const ValueKey('m2-primary-action')));
    await tester.tap(find.byKey(const ValueKey('m2-primary-action')));
    await tester.pump();
    await reveal(tester, find.byType(AdaptiveLearningCard));
    await tester.pump();
  }

  setUp(() async {
    await configureProgress();
  });

  testWidgets('unmapped Mastery insight has no dead Notebook action',
      (tester) async {
    final definition = mastery2Catalogue.requireBySemanticId(
      'oracle_marked_state_inference',
    );
    final level = definition.levelDefinition as McqLevel;
    await pumpChallenge(tester, level: level, definition: definition);
    await answerIncorrectly(tester);

    expect(find.byType(AdaptiveLearningCard), findsOneWidget);
    expect(find.text('Review notebook entry'), findsNothing);
    expect(find.textContaining('notebook idea'), findsNothing);
    final card = tester.widget<AdaptiveLearningCard>(
      find.byType(AdaptiveLearningCard),
    );
    expect(card.onReviewNotebook, isNull);
  });

  testWidgets('mapped and unlocked Notebook destination keeps its action',
      (tester) async {
    final entry = notebookEntries.first;
    await configureProgress(unlockedDiscovery: entry.discoveryTitle);
    const level = McqLevel(
      title: 'Mapped reinforcement fixture',
      discoveryTitle: 'PLACEHOLDER',
      taskDescription: 'Choose the correct answer.',
      options: ['Correct', 'Incorrect'],
      correctOptionIndex: 0,
      solutionExplanation: 'The first answer is correct.',
    );
    final mappedLevel = McqLevel(
      title: level.title,
      discoveryTitle: entry.discoveryTitle,
      taskDescription: level.taskDescription,
      options: level.options,
      correctOptionIndex: level.correctOptionIndex,
      solutionExplanation: level.solutionExplanation,
    );
    final definition = MasteryChallengeDefinition(
      semanticId: 'mapped_reinforcement_fixture',
      displayOrder: 99,
      title: mappedLevel.title!,
      difficulty: MasteryDifficulty.foundation,
      conceptTags: const {MasteryConceptTag.superposition},
      interactionType: MasteryInteractionType.evidence,
      levelDefinition: mappedLevel,
    );
    await pumpChallenge(tester, level: mappedLevel, definition: definition);
    await answerIncorrectly(tester);

    expect(find.text('Review notebook entry'), findsOneWidget);
    expect(
      tester
          .widget<AdaptiveLearningCard>(find.byType(AdaptiveLearningCard))
          .onReviewNotebook,
      isNotNull,
    );
    await reveal(tester, find.text('Review notebook entry'));
    await tester.tap(find.text('Review notebook entry'));
    await tester.pumpAndSettle();
    expect(find.byType(NotebookEntryScreen), findsOneWidget);
  });

  testWidgets('reinforcement survives rebuild, elapsed time, and scrolling',
      (tester) async {
    final definition = mastery2Catalogue.requireBySemanticId(
      'oracle_marked_state_inference',
    );
    await pumpChallenge(
      tester,
      level: definition.levelDefinition as McqLevel,
      definition: definition,
    );
    await answerIncorrectly(tester);

    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(AdaptiveLearningCard), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
    await tester.pump();
    expect(find.byType(AdaptiveLearningCard), findsOneWidget);
  });

  testWidgets('card body and non-action content do not dismiss reinforcement',
      (tester) async {
    final definition = mastery2Catalogue.requireBySemanticId(
      'oracle_marked_state_inference',
    );
    await pumpChallenge(
      tester,
      level: definition.levelDefinition as McqLevel,
      definition: definition,
    );
    await answerIncorrectly(tester);

    await tester.tap(
      find.byKey(const ValueKey('adaptive-reinforcement-surface')),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(AdaptiveLearningCard), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('adaptive-reinforcement-concept')),
    );
    await tester.pump();
    expect(find.byType(AdaptiveLearningCard), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss adaptive reinforcement'));
    await tester.pump();
    expect(find.byType(AdaptiveLearningCard), findsNothing);
  });

  testWidgets('explicit dismissal persists through rebuild and scrolling',
      (tester) async {
    final definition = mastery2Catalogue.requireBySemanticId(
      'oracle_marked_state_inference',
    );
    await pumpChallenge(
      tester,
      level: definition.levelDefinition as McqLevel,
      definition: definition,
    );
    await answerIncorrectly(tester);
    await tester.tap(find.byTooltip('Dismiss adaptive reinforcement'));
    await tester.pump();

    expect(find.byType(AdaptiveLearningCard), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
    await tester.pump();
    expect(find.byType(AdaptiveLearningCard), findsNothing);
  });

  testWidgets('a new failed attempt may show reinforcement again',
      (tester) async {
    final definition = mastery2Catalogue.requireBySemanticId(
      'oracle_marked_state_inference',
    );
    final level = definition.levelDefinition as McqLevel;
    await pumpChallenge(tester, level: level, definition: definition);
    await answerIncorrectly(tester);
    await tester.tap(find.byTooltip('Dismiss adaptive reinforcement'));
    await tester.pump();
    expect(find.byType(AdaptiveLearningCard), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpChallenge(tester, level: level, definition: definition);
    await answerIncorrectly(tester);
    expect(find.byType(AdaptiveLearningCard), findsOneWidget);
  });

  testWidgets('correct answer remains free of adaptive reinforcement',
      (tester) async {
    final definition = mastery2Catalogue.requireBySemanticId(
      'oracle_marked_state_inference',
    );
    await pumpChallenge(
      tester,
      level: definition.levelDefinition as McqLevel,
      definition: definition,
    );
    await reveal(tester, find.byKey(const ValueKey('mcq-option-0')));
    await tester.tap(find.byKey(const ValueKey('mcq-option-0')));
    await reveal(tester, find.byKey(const ValueKey('m2-primary-action')));
    await tester.tap(find.byKey(const ValueKey('m2-primary-action')));
    await tester.pump();

    expect(find.byType(AdaptiveLearningCard), findsNothing);
  });
}
