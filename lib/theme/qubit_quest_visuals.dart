import 'package:flutter/material.dart';

/// Canonical semantic visual foundation for Qubit Quest product UI.
///
/// New user-facing features should use these semantic tokens instead of raw
/// product-palette literals. Keep metadata neutral by default, use semantic
/// state colours only for their stated meaning, and avoid nested emphasis that
/// does not communicate hierarchy. Quantum-domain colours (gate identities,
/// circuit wires, Bloch visualisation, and state/probability encodings) remain
/// independently owned by their domain components.
abstract final class QubitQuestColors {
  static const background = Color(0xFF00030A);

  /// Level 1: major panels, workspace sections, and dialogs.
  static const surface = Color(0xFF111827);

  /// Level 2: interactive cards and raised rows.
  static const surfaceRaised = Color(0xFF18233A);

  /// Level 2: wells and recessed local tools.
  static const surfaceInset = Color(0xFF030814);

  /// A lighter inset alternative where separation from [background] is needed.
  static const surfaceInsetRaised = Color(0xFF101A2D);

  static const border = Color(0x66344A73);
  static const borderSoft = Color(0x3D344A73);
  static const borderFocus = Color(0xFF56CCF2);

  static const textPrimary = Colors.white;
  static const textBody = Color(0xFFD6E3F8);
  static const textMuted = Color(0xFF95A4BC);

  /// Navigation, links, focus, and neutral interaction/selection.
  static const accentInteractive = Color(0xFF56CCF2);

  /// Strong product accent and phase-specific educational emphasis.
  static const accentStrong = Color(0xFFB388FF);

  static const success = Color(0xFF7CFFB2);
  static const warning = Color(0xFFFFD54F);
  static const error = Color(0xFFFF7A7A);
  static const disabled = Color(0xFF243047);
}

abstract final class QubitQuestTypography {
  static const display = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 28,
    height: 1.06,
    fontWeight: FontWeight.w900,
  );
  static const title = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 22,
    height: 1.12,
    fontWeight: FontWeight.w800,
  );
  static const heading = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );
  static const question = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 19,
    height: 1.38,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(
    color: QubitQuestColors.textBody,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );
  static const supporting = TextStyle(
    color: QubitQuestColors.textMuted,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const label = TextStyle(
    color: QubitQuestColors.textMuted,
    fontSize: 12,
    height: 1.2,
    letterSpacing: 0.4,
    fontWeight: FontWeight.w800,
  );
  static const action = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );

  // Maths roles describe surrounding Flutter typography. LatexText/TeX keeps
  // ownership of mathematical glyph layout and containment.
  static const mathInline = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 15,
  );
  static const mathDisplay = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );
  static const mathState = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
}

abstract final class QubitQuestSpacing {
  static const micro = 4.0;
  static const compact = 8.0;
  static const regular = 12.0;
  static const component = 16.0;
  static const section = 24.0;
  static const workspace = 32.0;
}

abstract final class QubitQuestLayout {
  static const activityMaxContentWidth = 920.0;
  static const activityCompactBreakpoint = 680.0;
}

abstract final class QubitQuestRadii {
  static const controlValue = 10.0;
  static const cardValue = 12.0;
  static const calloutValue = 14.0;
  static const panelValue = 18.0;
  static const pillValue = 999.0;

  static const control = BorderRadius.all(Radius.circular(controlValue));
  static const card = BorderRadius.all(Radius.circular(cardValue));
  static const callout = BorderRadius.all(Radius.circular(calloutValue));
  static const panel = BorderRadius.all(Radius.circular(panelValue));
  static const pill = BorderRadius.all(Radius.circular(pillValue));
}

abstract final class QubitQuestBorders {
  static const standard = BorderSide(
    color: QubitQuestColors.border,
    width: 1,
  );
  static const soft = BorderSide(
    color: QubitQuestColors.borderSoft,
    width: 1,
  );
  static const focus = BorderSide(
    color: QubitQuestColors.borderFocus,
    width: 1.5,
  );

  /// Reserved for genuinely raised top-level surfaces such as dialogs.
  static const topLevelShadow = BoxShadow(
    color: Color(0x5C000000),
    blurRadius: 24,
    offset: Offset(0, 14),
  );
}

/// Semantic interaction colours shared by pointer and touch presentations.
abstract final class QubitQuestInteractionStates {
  static const neutral = QubitQuestColors.surfaceRaised;
  static const hover = QubitQuestColors.surfaceInsetRaised;
  static const focus = QubitQuestColors.accentInteractive;
  static const selected = QubitQuestColors.accentInteractive;
  static const correct = QubitQuestColors.success;
  static const incorrect = QubitQuestColors.error;
  static const disabled = QubitQuestColors.disabled;
  static const completed = QubitQuestColors.success;
  static const locked = QubitQuestColors.textMuted;
}

/// Theme roots deliberately configure only safe product fundamentals.
/// Component-specific themes remain unchanged until their visual migration.
abstract final class QubitQuestTheme {
  static ThemeData mobile() => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: QubitQuestColors.background,
        disabledColor: QubitQuestColors.disabled,
        focusColor: QubitQuestColors.accentInteractive,
        dividerColor: QubitQuestColors.borderSoft,
        textTheme: _baseTextTheme,
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E2C),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Colors.blue.withValues(alpha: 0.5),
          selectionHandleColor: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E2C),
          foregroundColor: Colors.white,
        ),
      );

  static ThemeData web() => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: QubitQuestColors.background,
        disabledColor: QubitQuestColors.disabled,
        focusColor: QubitQuestColors.accentInteractive,
        dividerColor: QubitQuestColors.borderSoft,
        colorScheme: ColorScheme.fromSeed(
          seedColor: QubitQuestColors.accentInteractive,
          brightness: Brightness.dark,
          surface: QubitQuestColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: QubitQuestColors.background,
          surfaceTintColor: Colors.transparent,
        ),
      );

  static const _baseTextTheme = TextTheme(
    displayLarge: TextStyle(color: Colors.white),
    displayMedium: TextStyle(color: Colors.white),
    displaySmall: TextStyle(color: Colors.white),
    headlineLarge: TextStyle(color: Colors.white),
    headlineMedium: TextStyle(color: Colors.white),
    headlineSmall: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Colors.white),
    titleSmall: TextStyle(color: Colors.white),
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    bodySmall: TextStyle(color: Colors.white),
    labelLarge: TextStyle(color: Colors.white),
    labelMedium: TextStyle(color: Colors.white),
    labelSmall: TextStyle(color: Colors.white),
  );
}
