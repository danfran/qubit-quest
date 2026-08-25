import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';

/// Run directly for manual review; this entry point is not used by the app:
/// `flutter run -d chrome -t lib/dev/qubit_quest_visual_showcase.dart`
void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: kIsWeb ? QubitQuestTheme.web() : QubitQuestTheme.mobile(),
        home: const QubitQuestVisualShowcase(),
      ),
    );

/// Developer/test-only visual review surface. It is intentionally not linked
/// from production navigation and is tree-shaken from release builds.
class QubitQuestVisualShowcase extends StatelessWidget {
  const QubitQuestVisualShowcase({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Qubit Quest Visual Showcase')),
        body: ListView(
          padding: const EdgeInsets.all(QubitQuestSpacing.section),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _TypographyShowcase(),
                    SizedBox(height: QubitQuestSpacing.section),
                    _SurfaceShowcase(),
                    SizedBox(height: QubitQuestSpacing.section),
                    _CalloutShowcase(),
                    SizedBox(height: QubitQuestSpacing.section),
                    _ChoiceShowcase(),
                    SizedBox(height: QubitQuestSpacing.section),
                    _ActionShowcase(),
                    SizedBox(height: QubitQuestSpacing.section),
                    _ChipShowcase(),
                    SizedBox(height: QubitQuestSpacing.section),
                    _IconActionShowcase(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _TypographyShowcase extends StatelessWidget {
  const _TypographyShowcase();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Display', style: QubitQuestTypography.display),
          Text('Title', style: QubitQuestTypography.title),
          Text('Heading', style: QubitQuestTypography.heading),
          Text('What does this circuit produce?',
              style: QubitQuestTypography.question),
          Text('Body text explains the idea without competing with it.',
              style: QubitQuestTypography.body),
          Text('Supporting context stays subordinate.',
              style: QubitQuestTypography.supporting),
          Text('ACTIVITY LABEL', style: QubitQuestTypography.label),
          Text('Action', style: QubitQuestTypography.action),
        ],
      );
}

class _SurfaceShowcase extends StatelessWidget {
  const _SurfaceShowcase();

  @override
  Widget build(BuildContext context) => QubitQuestPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Text('Panel', style: QubitQuestTypography.heading),
            SizedBox(height: QubitQuestSpacing.regular),
            QubitQuestPanel(
              level: QubitQuestSurfaceLevel.card,
              child: Text('Card surface', style: QubitQuestTypography.body),
            ),
            SizedBox(height: QubitQuestSpacing.regular),
            QubitQuestPanel(
              level: QubitQuestSurfaceLevel.inset,
              child: Text('Inset surface', style: QubitQuestTypography.body),
            ),
          ],
        ),
      );
}

class _CalloutShowcase extends StatelessWidget {
  const _CalloutShowcase();

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          QubitQuestCallout(
              title: 'Information', message: 'Supporting context stays quiet.'),
          SizedBox(height: QubitQuestSpacing.compact),
          QubitQuestCallout(
              variant: QubitQuestCalloutVariant.insight,
              title: 'Insight',
              message: 'A phase relationship can change interference.'),
          SizedBox(height: QubitQuestSpacing.compact),
          QubitQuestCallout(
              variant: QubitQuestCalloutVariant.success,
              title: 'Correct',
              message: 'The state matches the physical target.'),
          SizedBox(height: QubitQuestSpacing.compact),
          QubitQuestCallout(
              variant: QubitQuestCalloutVariant.warning,
              title: 'Check this',
              message: 'Probabilities alone may not identify phase.'),
          SizedBox(height: QubitQuestSpacing.compact),
          QubitQuestCallout(
              variant: QubitQuestCalloutVariant.error,
              title: 'Try again',
              message: 'The circuit remains editable.'),
        ],
      );
}

class _ChoiceShowcase extends StatelessWidget {
  const _ChoiceShowcase();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const QubitQuestActivityQuestion(
              activityLabel: 'CIRCUIT READING',
              question: Text('Which output state is physically equivalent?'),
              supportingText:
                  'Compare the whole state, not only one amplitude.'),
          const SizedBox(height: QubitQuestSpacing.component),
          for (final entry in const [
            ('A', 'Neutral answer', QubitQuestChoiceState.neutral),
            ('B', 'Selected answer', QubitQuestChoiceState.selected),
            ('C', 'Correct answer', QubitQuestChoiceState.correct),
            ('D', 'Incorrect answer', QubitQuestChoiceState.incorrect),
            ('E', 'Disabled answer', QubitQuestChoiceState.disabled),
          ]) ...[
            QubitQuestChoiceCard(
              indexLabel: entry.$1,
              state: entry.$3,
              onPressed:
                  entry.$3 == QubitQuestChoiceState.disabled ? null : () {},
              child: Text(entry.$2),
            ),
            const SizedBox(height: QubitQuestSpacing.compact),
          ],
        ],
      );
}

class _ActionShowcase extends StatelessWidget {
  const _ActionShowcase();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: QubitQuestSpacing.compact,
        runSpacing: QubitQuestSpacing.compact,
        children: [
          QubitQuestActionButton(label: 'Primary', onPressed: () {}),
          QubitQuestActionButton(
              label: 'Secondary',
              role: QubitQuestActionRole.secondary,
              onPressed: () {}),
          QubitQuestActionButton(
              label: 'Tertiary',
              role: QubitQuestActionRole.tertiary,
              onPressed: () {}),
          const QubitQuestActionButton(label: 'Disabled', onPressed: null),
        ],
      );
}

class _ChipShowcase extends StatelessWidget {
  const _ChipShowcase();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: QubitQuestSpacing.compact,
        runSpacing: QubitQuestSpacing.compact,
        children: [
          const QubitQuestChip(label: 'Phase', icon: Icons.sell_outlined),
          QubitQuestChip(
              label: 'Notebook link',
              variant: QubitQuestChipVariant.link,
              icon: Icons.menu_book_outlined,
              onPressed: () {}),
          const QubitQuestChip(
              label: 'Completed',
              variant: QubitQuestChipVariant.success,
              icon: Icons.check_rounded),
          const QubitQuestChip(
              label: 'Locked',
              variant: QubitQuestChipVariant.locked,
              icon: Icons.lock_outline_rounded),
          const QubitQuestChip(
              label: '4 / 12', variant: QubitQuestChipVariant.count),
        ],
      );
}

class _IconActionShowcase extends StatelessWidget {
  const _IconActionShowcase();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          QubitQuestIconAction(
              icon: Icons.info_outline_rounded,
              tooltip: 'Inspect',
              onPressed: () {}),
          const SizedBox(width: QubitQuestSpacing.compact),
          QubitQuestIconAction(
              icon: Icons.check_rounded,
              tooltip: 'Selected action',
              selected: true,
              onPressed: () {}),
          const SizedBox(width: QubitQuestSpacing.compact),
          const QubitQuestIconAction(
              icon: Icons.lock_outline_rounded,
              tooltip: 'Disabled action',
              onPressed: null),
        ],
      );
}
