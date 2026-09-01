import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_reinforcement.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/screens/mcq_screen.dart';
import 'package:quantumquiz/widgets/adaptive_learning_card.dart';

void main() {
  const genericFallbackLevel = McqLevel(
    title: 'Generic reinforcement fixture',
    taskDescription: 'Choose the supported conclusion.',
    options: ['Unsupported', 'Also unsupported', 'Supported'],
    correctOptionIndex: 2,
    solutionExplanation: 'The third conclusion follows from the evidence.',
  );
  final genericFallbackDefinition = MasteryChallengeDefinition(
    semanticId: 'generic_reinforcement_fixture',
    displayOrder: 99,
    title: 'Generic reinforcement fixture',
    difficulty: MasteryDifficulty.integration,
    conceptTags: const {MasteryConceptTag.reversibility},
    interactionType: MasteryInteractionType.evidence,
    levelDefinition: genericFallbackLevel,
  );

  Future<CampaignProgressController> configureProgress({
    String? unlockedDiscovery,
  }) async {
    final controller = CampaignProgressController(
      store: InMemoryCampaignProgressStore(),
    );
    await controller.load();
    if (unlockedDiscovery != null) {
      await controller.unlockDiscovery(unlockedDiscovery);
    }
    CampaignProgressController.configureSharedInstance(controller);
    return controller;
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

  Future<void> answerIncorrectly(
    WidgetTester tester,
    McqLevel level,
  ) async {
    final wrongIndex = level.correctOptionIndex == 0 ? 1 : 0;
    final option = find.byKey(ValueKey('mcq-option-$wrongIndex'));
    await reveal(tester, option);
    await tester.tap(option);
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
    await pumpChallenge(
      tester,
      level: genericFallbackLevel,
      definition: genericFallbackDefinition,
    );
    await answerIncorrectly(tester, genericFallbackLevel);

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
    final definition = mastery2Catalogue.requireBySemanticId(
      'global_phase_equivalence',
    );
    final level = definition.levelDefinition as McqLevel;
    final entry = mastery2ReinforcementNotebookEntry(definition.semanticId)!;
    final controller =
        await configureProgress(unlockedDiscovery: entry.discoveryTitle);
    await controller.completeLesson(3);
    final journeyFrontier = controller.state.maxUnlockedLevel;
    final completedLessons = controller.state.completedLessonIds;
    final completedMastery = controller.state.completedMasterySemanticIds;
    await pumpChallenge(tester, level: level, definition: definition);
    await answerIncorrectly(tester, level);

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
    expect(controller.state.maxUnlockedLevel, journeyFrontier);
    expect(controller.state.completedLessonIds, completedLessons);
    expect(controller.state.completedMasterySemanticIds, completedMastery);
  });

  testWidgets('mapped but locked Notebook destination has no unusable action',
      (tester) async {
    final definition = mastery2Catalogue.requireBySemanticId(
      'global_phase_equivalence',
    );
    final level = definition.levelDefinition as McqLevel;
    await pumpChallenge(tester, level: level, definition: definition);
    await answerIncorrectly(tester, level);

    expect(find.byType(AdaptiveLearningCard), findsOneWidget);
    expect(find.text('Review notebook entry'), findsNothing);
    expect(
      tester
          .widget<AdaptiveLearningCard>(find.byType(AdaptiveLearningCard))
          .onReviewNotebook,
      isNull,
    );
  });

  testWidgets('reinforcement survives rebuild, elapsed time, and scrolling',
      (tester) async {
    await pumpChallenge(
      tester,
      level: genericFallbackLevel,
      definition: genericFallbackDefinition,
    );
    await answerIncorrectly(tester, genericFallbackLevel);

    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(AdaptiveLearningCard), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
    await tester.pump();
    expect(find.byType(AdaptiveLearningCard), findsOneWidget);
  });

  testWidgets('card body and non-action content do not dismiss reinforcement',
      (tester) async {
    await pumpChallenge(
      tester,
      level: genericFallbackLevel,
      definition: genericFallbackDefinition,
    );
    await answerIncorrectly(tester, genericFallbackLevel);

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
    await pumpChallenge(
      tester,
      level: genericFallbackLevel,
      definition: genericFallbackDefinition,
    );
    await answerIncorrectly(tester, genericFallbackLevel);
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
    await pumpChallenge(
      tester,
      level: genericFallbackLevel,
      definition: genericFallbackDefinition,
    );
    await answerIncorrectly(tester, genericFallbackLevel);
    await tester.tap(find.byTooltip('Dismiss adaptive reinforcement'));
    await tester.pump();
    expect(find.byType(AdaptiveLearningCard), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpChallenge(
      tester,
      level: genericFallbackLevel,
      definition: genericFallbackDefinition,
    );
    await answerIncorrectly(tester, genericFallbackLevel);
    expect(find.byType(AdaptiveLearningCard), findsOneWidget);
  });

  testWidgets('correct answer remains free of adaptive reinforcement',
      (tester) async {
    await pumpChallenge(
      tester,
      level: genericFallbackLevel,
      definition: genericFallbackDefinition,
    );
    await reveal(tester, find.byKey(const ValueKey('mcq-option-2')));
    await tester.tap(find.byKey(const ValueKey('mcq-option-2')));
    await reveal(tester, find.byKey(const ValueKey('m2-primary-action')));
    await tester.tap(find.byKey(const ValueKey('m2-primary-action')));
    await tester.pump();

    expect(find.byType(AdaptiveLearningCard), findsNothing);
  });
}
