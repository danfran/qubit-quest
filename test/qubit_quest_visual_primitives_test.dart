import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/dev/qubit_quest_visual_showcase.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';

void main() {
  Future<void> pumpPrimitive(
    WidgetTester tester,
    Widget child, {
    ThemeData? theme,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: theme ?? QubitQuestTheme.mobile(),
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 520, child: child),
            ),
          ),
        ),
      );

  group('Qubit Quest shared visual primitives', () {
    testWidgets('choice states provide visible and semantic distinctions',
        (tester) async {
      await pumpPrimitive(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final state in QubitQuestChoiceState.values)
              QubitQuestChoiceCard(
                key: ValueKey(state.name),
                indexLabel: state.name.substring(0, 1).toUpperCase(),
                state: state,
                onPressed:
                    state == QubitQuestChoiceState.disabled ? null : () {},
                child: Text(state.name),
              ),
          ],
        ),
      );

      expect(find.byType(QubitQuestChoiceCard), findsNWidgets(5));
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

      final semantics =
          tester.getSemantics(find.byKey(const ValueKey('selected')));
      expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
      expect(semantics.flagsCollection.isButton, isTrue);
      final disabled =
          tester.getSemantics(find.byKey(const ValueKey('disabled')));
      expect(disabled.flagsCollection.isEnabled, isNot(Tristate.isTrue));
    });

    testWidgets('callout variants use one shared family', (tester) async {
      await pumpPrimitive(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final variant in QubitQuestCalloutVariant.values)
              QubitQuestCallout(message: 'Message', variant: variant),
          ],
        ),
      );

      expect(find.byType(QubitQuestCallout), findsNWidgets(5));
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets(
        'chip variants preserve metadata, link, status and lock meaning',
        (tester) async {
      await pumpPrimitive(
        tester,
        Wrap(
          children: [
            for (final variant in QubitQuestChipVariant.values)
              QubitQuestChip(
                key: ValueKey(variant.name),
                label: variant.name,
                variant: variant,
                onPressed: variant == QubitQuestChipVariant.link ? () {} : null,
              ),
          ],
        ),
      );

      expect(find.byType(QubitQuestChip), findsNWidgets(6));
      final link = tester.getSemantics(find.byKey(const ValueKey('link')));
      expect(link.flagsCollection.isButton, isTrue);
      expect(link.flagsCollection.isEnabled, Tristate.isTrue);
      final metadata =
          tester.getSemantics(find.byKey(const ValueKey('metadata')));
      expect(metadata.flagsCollection.isButton, isFalse);
    });

    testWidgets(
        'actions expose enabled, disabled, icon and keyboard focus states',
        (tester) async {
      await pumpPrimitive(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QubitQuestActionButton(
              key: const ValueKey('enabled-action'),
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {},
            ),
            const QubitQuestActionButton(
              key: ValueKey('disabled-action'),
              label: 'Unavailable',
              onPressed: null,
            ),
          ],
        ),
      );

      final enabled = tester.widget<TextButton>(
        find.descendant(
          of: find.byKey(const ValueKey('enabled-action')),
          matching: find.byType(TextButton),
        ),
      );
      final disabled = tester.widget<TextButton>(
        find.descendant(
          of: find.byKey(const ValueKey('disabled-action')),
          matching: find.byType(TextButton),
        ),
      );
      expect(enabled.onPressed, isNotNull);
      expect(disabled.onPressed, isNull);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNotNull);
    });

    testWidgets('icon actions keep a 44px target and disabled semantics',
        (tester) async {
      await pumpPrimitive(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QubitQuestIconAction(
              key: const ValueKey('selected-icon'),
              icon: Icons.info_outline,
              tooltip: 'Selected',
              selected: true,
              onPressed: () {},
            ),
            const QubitQuestIconAction(
              key: ValueKey('disabled-icon'),
              icon: Icons.lock_outline,
              tooltip: 'Disabled',
              onPressed: null,
            ),
          ],
        ),
      );

      expect(tester.getSize(find.byKey(const ValueKey('selected-icon'))),
          const Size(44, 44));
      final disabled = tester.widget<IconButton>(
        find.descendant(
          of: find.byKey(const ValueKey('disabled-icon')),
          matching: find.byType(IconButton),
        ),
      );
      expect(disabled.onPressed, isNull);
    });

    testWidgets('showcase renders the complete state vocabulary on both themes',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1800);
      addTearDown(tester.view.reset);

      for (final theme in [QubitQuestTheme.mobile(), QubitQuestTheme.web()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const QubitQuestVisualShowcase(),
          ),
        );
        expect(find.byType(QubitQuestPanel), findsNWidgets(3));
        expect(find.byType(QubitQuestCallout), findsNWidgets(5));
        expect(find.byType(QubitQuestChoiceCard), findsNWidgets(5));
        expect(find.byType(QubitQuestActionButton), findsNWidgets(4));
        expect(find.byType(QubitQuestChip), findsNWidgets(5));
        expect(find.byType(QubitQuestIconAction), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      }
    });

    test('primitive implementation adds no raw product colour literals', () {
      final source =
          File('lib/widgets/qubit_quest_primitives.dart').readAsStringSync();
      expect(source, isNot(contains('Color(0x')));
      expect(source, isNot(contains('Colors.green')));
      expect(source, isNot(contains('Colors.red')));
      expect(source, isNot(contains('Colors.blue')));
      expect(source, isNot(contains('BorderRadius.circular(')));
    });
  });
}
