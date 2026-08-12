import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';

import 'support/campaign_integration_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final composerLevels = allQQLevels.indexed
      .where((entry) => entry.$2 is ComposerLevel)
      .map((entry) => (id: entry.$1 + 1, level: entry.$2 as ComposerLevel))
      .toList(growable: false);

  group('SLOW RELEASE GATE — production Composer campaign completion', () {
    test('campaign inventory is generated and complete', () {
      expect(composerLevels, hasLength(93));
      expect(
        composerLevels.every((entry) => entry.level.canonicalSolution != null),
        isTrue,
      );
    });

    for (final entry in composerLevels) {
      testWidgets(
        '${entry.id}: ${entry.level.title ?? 'Composer'} completes through Check Result',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final harness = CampaignIntegrationHarness(tester);
          await harness.loadLevel(entry.id, entry.level);
          await harness.applyCanonicalSolution();
          await harness.checkResultAndComplete();
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );
    }
  });

  group('VALIDATION CONTRACT — representative negative journeys', () {
    for (final mode in ValidationMode.values) {
      final entry = composerLevels.firstWhere(
        (candidate) =>
            candidate.level.validationMode == mode &&
            candidate.level.canonicalSolution!.steps.isNotEmpty,
      );
      testWidgets('${mode.name} wrong circuit does not progress',
          (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final harness = CampaignIntegrationHarness(tester);
        await harness.loadLevel(entry.id, entry.level);
        await harness.checkWrongResult();
      });
    }
  });

  testWidgets('PROGRESSION CONTRACT — consecutive completions persist',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final first = composerLevels[0];
    final second = composerLevels[1];
    final firstHarness = CampaignIntegrationHarness(tester);
    await firstHarness.loadLevel(first.id, first.level);
    await firstHarness.applyCanonicalSolution();
    await firstHarness.checkResultAndComplete();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final secondHarness = CampaignIntegrationHarness(tester);
    await secondHarness.loadLevel(
      second.id,
      second.level,
      progressController: firstHarness.progress,
      resetPreferences: false,
    );
    await secondHarness.applyCanonicalSolution();
    await secondHarness.checkResultAndComplete();
    expect(secondHarness.progress.state.completedLessonIds,
        containsAll([first.id, second.id]));
    expect(secondHarness.progress.isLevelUnlocked(second.id + 1), isTrue);
  });
}
