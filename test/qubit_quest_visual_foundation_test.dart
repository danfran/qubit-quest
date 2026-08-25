import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/level_type_headers.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

void main() {
  group('canonical Qubit Quest visual foundation', () {
    test('product colour contract remains stable', () {
      expect(QubitQuestColors.background, const Color(0xFF00030A));
      expect(QubitQuestColors.surface, const Color(0xFF111827));
      expect(QubitQuestColors.surfaceRaised, const Color(0xFF18233A));
      expect(QubitQuestColors.surfaceInset, const Color(0xFF030814));
      expect(QubitQuestColors.surfaceInsetRaised, const Color(0xFF101A2D));
      expect(QubitQuestColors.textBody, const Color(0xFFD6E3F8));
      expect(QubitQuestColors.textMuted, const Color(0xFF95A4BC));
      expect(QubitQuestColors.accentInteractive, const Color(0xFF56CCF2));
      expect(QubitQuestColors.accentStrong, const Color(0xFFB388FF));
      expect(QubitQuestColors.success, const Color(0xFF7CFFB2));
      expect(QubitQuestColors.warning, const Color(0xFFFFD54F));
      expect(QubitQuestColors.error, const Color(0xFFFF7A7A));
    });

    test('spacing, radii, and border roles stay compact and semantic', () {
      expect(
        <double>[
          QubitQuestSpacing.micro,
          QubitQuestSpacing.compact,
          QubitQuestSpacing.regular,
          QubitQuestSpacing.component,
          QubitQuestSpacing.section,
          QubitQuestSpacing.workspace,
        ],
        orderedEquals(<double>[4, 8, 12, 16, 24, 32]),
      );
      expect(QubitQuestRadii.controlValue, 10);
      expect(QubitQuestRadii.cardValue, 12);
      expect(QubitQuestRadii.calloutValue, 14);
      expect(QubitQuestRadii.panelValue, 18);
      expect(QubitQuestBorders.standard.width, 1);
      expect(QubitQuestBorders.soft.width, 1);
      expect(QubitQuestBorders.focus.width, 1.5);
    });

    test('typography follows the intended hierarchy', () {
      expect(
        QubitQuestTypography.display.fontSize!,
        greaterThan(QubitQuestTypography.title.fontSize!),
      );
      expect(
        QubitQuestTypography.title.fontSize!,
        greaterThan(QubitQuestTypography.question.fontSize!),
      );
      expect(
        QubitQuestTypography.question.fontSize!,
        greaterThan(QubitQuestTypography.body.fontSize!),
      );
      expect(
        QubitQuestTypography.body.fontSize!,
        greaterThan(QubitQuestTypography.supporting.fontSize!),
      );
      expect(QubitQuestTypography.body.fontFamily, isNull);
    });

    test('interaction states use semantic product colours', () {
      expect(
        QubitQuestInteractionStates.selected,
        QubitQuestColors.accentInteractive,
      );
      expect(QubitQuestInteractionStates.correct, QubitQuestColors.success);
      expect(QubitQuestInteractionStates.completed, QubitQuestColors.success);
      expect(QubitQuestInteractionStates.incorrect, QubitQuestColors.error);
      expect(QubitQuestInteractionStates.locked, QubitQuestColors.textMuted);
    });

    test('mobile and Web themes consume the shared foundation', () {
      final mobile = QubitQuestTheme.mobile();
      final web = QubitQuestTheme.web();

      for (final theme in <ThemeData>[mobile, web]) {
        expect(theme.scaffoldBackgroundColor, QubitQuestColors.background);
        expect(theme.disabledColor, QubitQuestColors.disabled);
        expect(theme.focusColor, QubitQuestColors.accentInteractive);
        expect(theme.dividerColor, QubitQuestColors.borderSoft);
      }
      expect(web.colorScheme.primary, isNot(Colors.blue));
      expect(web.colorScheme.surface, QubitQuestColors.surface);
    });

    test('existing shared aliases resolve to the canonical authority', () {
      expect(QubitQuestDialog.panelColor, QubitQuestColors.surface);
      expect(QubitQuestDialog.innerColor, QubitQuestColors.surfaceInset);
      expect(QubitQuestDialog.cardColor, QubitQuestColors.surfaceRaised);
      expect(QubitQuestDialog.cyan, QubitQuestColors.accentInteractive);
      expect(QubitQuestDialog.purple, QubitQuestColors.accentStrong);
      expect(LevelHeaderTokens.black, QubitQuestColors.background);
      expect(LevelHeaderTokens.cyan, QubitQuestColors.accentInteractive);
      expect(LevelHeaderTokens.green, QubitQuestColors.success);
    });
  });
}
