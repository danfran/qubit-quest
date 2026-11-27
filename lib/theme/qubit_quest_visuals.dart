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

  /// Hairline dividing the web shell's header, navigation and workspace.
  static const shellDivider = Color(0x44344A73);

  /// Background of the selected navigation destination.
  static const navigationSelected = Color(0x2222D3EE);
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

/// Surface ladder (v2.6 M11B §2, implemented in M11C). Layers are told
/// apart by tone rather than by more bordered cards: charcoal carries the
/// application chrome, navy carries content, wells sit *darker* than their
/// surroundings and the contextual inspector sits *lighter*.
abstract final class QubitQuestSurfaces {
  /// Behind everything (a slightly lifted [QubitQuestColors.background]).
  static const app = Color(0xFF05070C);

  /// Global navigation (neutral charcoal).
  static const nav = Color(0xFF0A0D14);

  /// Section navigation (deep navy).
  static const section = Color(0xFF0B1220);

  /// Page header band, workspace header and sticky action bars.
  static const page = Color(0xFF0D1526);

  /// Primary workspace panels.
  static const work = Color(0xFF101A2C);

  /// Secondary workspace strips (palette, reading backdrop).
  static const work2 = Color(0xFF0E1728);

  /// Wells: circuit, mathematics, figures, charts.
  static const inset = Color(0xFF070B14);

  /// Contextual inspector.
  static const inspector = Color(0xFF131D31);

  /// Selected segment and raised controls ([QubitQuestColors.surfaceRaised]).
  static const raised = QubitQuestColors.surfaceRaised;

  /// Soft rule used only where two equal tones meet.
  static const rule = Color(0x38344A73);
}

/// One set of responsive tiers for the web application (M11B §6). The shell
/// resolves it from the viewport; workspaces resolve it from their *host*
/// width, because the same workspace is embedded in different hosts.
enum QubitQuestTier {
  phone,
  small,
  tablet,
  compact,
  standard,
  wide,
  ultrawide;

  static QubitQuestTier of(double width) => width >= 2000
      ? ultrawide
      : width >= 1440
          ? wide
          : width >= 1280
              ? standard
              : width >= 1024
                  ? compact
                  : width >= 900
                      ? tablet
                      : width >= 600
                          ? small
                          : phone;

  bool operator >=(QubitQuestTier other) => index >= other.index;
  bool operator <(QubitQuestTier other) => index < other.index;
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

/// Web scientific typography (v2.6 M11C.1). One scale for the browser
/// workspaces, set in Inter (bundled, see pubspec) with the maths-symbol
/// fallback for ⟨ ⟩. Regular and medium weights carry ordinary content;
/// semibold is reserved for headings and the values that matter most.
/// Numbers that line up in columns use [tabular]. The native app keeps
/// [QubitQuestTypography].
abstract final class QqType {
  /// Families selected by the web theme only.
  static const family = 'Inter';
  static const fallback = <String>['QQ Math Symbols'];

  static const tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// Page title (a section's own heading).
  static const pageTitle = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  /// Title of a section within a page.
  static const sectionTitle = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  /// Name of the thing a panel is about (a gate, an experiment).
  static const subjectTitle = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  /// Scientific panel heading ("CURRENT STATE"); shown uppercase.
  static const panelHeading = TextStyle(
    color: QubitQuestColors.accentInteractive,
    fontSize: 12.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
  );

  /// Heading inside a panel ("What it does", "Outcomes").
  static const subheading = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(
    color: QubitQuestColors.textBody,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Body text that must be read first (a recognised state, an outcome).
  static const bodyStrong = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  /// Scientific table cell.
  static const table = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 14.5,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontFeatures: tabular,
  );

  /// Scientific table column heading.
  static const tableHeader = TextStyle(
    color: QubitQuestColors.textMuted,
    fontSize: 12.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  /// Supporting metadata and captions.
  static const meta = TextStyle(
    color: QubitQuestColors.textMuted,
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  /// Button and control labels.
  static const control = TextStyle(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  /// The primary state expression.
  static const stateExpression = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 22,
    height: 1.45,
    fontWeight: FontWeight.w400,
    fontFeatures: tabular,
  );

  /// Basis kets inside expressions and tables.
  static const ketColor = QubitQuestColors.success;

  // ── Learning surfaces (v2.6 M11D) ──────────────────────────────────────

  /// Breadcrumb and location trail ("Journey / Ch 7 GHZ States / 7.3").
  static const breadcrumb = TextStyle(
    color: QubitQuestColors.accentInteractive,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  /// Lesson or challenge title (the page's own heading).
  static const activityTitle = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  /// The conceptual question a lesson asks.
  static const question = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 17,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );

  /// Instruction text inside the task callout.
  static const task = TextStyle(
    color: QubitQuestColors.textBody,
    fontSize: 15.5,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Section navigation rows (curriculum, challenge list).
  static const navLabel = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  /// Secondary line or count in navigation rows.
  static const navMeta = TextStyle(
    color: QubitQuestColors.textMuted,
    fontSize: 12.5,
    height: 1.35,
    fontWeight: FontWeight.w400,
    fontFeatures: tabular,
  );

  /// Numbers that are data (counts, percentages, positions).
  static const numeric = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 14.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
    fontFeatures: tabular,
  );

  /// Inline mathematical notation outside TeX (kets, short expressions).
  static const math = TextStyle(
    color: QubitQuestColors.textPrimary,
    fontSize: 19,
    height: 1.45,
    fontWeight: FontWeight.w400,
    fontFeatures: tabular,
  );
}

/// Padding and gaps of the web scientific panels (v2.6 M11C.1).
abstract final class QqSpace {
  static const panel = EdgeInsets.fromLTRB(20, 16, 20, 20);
  static const panelCompact = EdgeInsets.fromLTRB(16, 14, 16, 16);
  static const gap = 16.0;
  static const blockGap = 20.0;
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
        // v2.6 M11C.1: bundled Inter for the browser; the maths-symbol
        // subset supplies the angle brackets Inter does not contain.
        fontFamily: QqType.family,
        fontFamilyFallback: QqType.fallback,
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
        // v2.6 M9: one readable treatment for transient messages on the
        // dark theme (Material's default was a light-grey bar).
        snackBarTheme: SnackBarThemeData(
          backgroundColor: QubitQuestColors.surfaceRaised,
          contentTextStyle: const TextStyle(
            color: QubitQuestColors.textBody,
            fontSize: 14,
            height: 1.35,
          ),
          actionTextColor: QubitQuestColors.accentInteractive,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: QubitQuestColors.border),
          ),
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: QubitQuestColors.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: QubitQuestColors.border),
          ),
          textStyle: const TextStyle(
              color: QubitQuestColors.textBody, fontSize: 12.5),
          waitDuration: const Duration(milliseconds: 400),
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
