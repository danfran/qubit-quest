import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/widgets/level_header_router.dart';

void main() {
  Future<void> pumpMasteryChallenge(
    WidgetTester tester,
    String semanticId,
  ) async {
    final definition = mastery2Catalogue.requireBySemanticId(semanticId);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: LevelUIRouter.buildLevelUI(
          level: definition.levelDefinition,
          levelId: definition.displayOrder,
          masteryChallenge: definition,
          onLevelUnlocked: null,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('all semantic Mastery headers use display order', (tester) async {
    for (final definition in mastery2Catalogue.orderedDefinitions) {
      await pumpMasteryChallenge(tester, definition.semanticId);

      expect(
        find.text('Mastery Challenge ${definition.displayOrder}'),
        findsOneWidget,
        reason: definition.semanticId,
      );
      expect(find.text(definition.title), findsOneWidget);
      expect(
        find.text('Lesson ${definition.displayOrder}'),
        findsNothing,
        reason: definition.semanticId,
      );
    }
  });

  testWidgets('Journey header continues to derive Lesson N from lesson ID',
      (tester) async {
    final level = getQQLevelById(2)!;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          appBar: LevelHeaderRouter.headerFor(
            level: level,
            levelId: 2,
            compact: true,
          ),
        ),
      ),
    );

    expect(find.text('Lesson 2'), findsOneWidget);
    expect(find.text('Mastery Challenge 2'), findsNothing);
  });
}
