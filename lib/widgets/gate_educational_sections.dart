import 'package:flutter/material.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/widgets/gate_inspector_theme.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/native_math_text.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

/// Shared presentation of [GateEducationalInfo].
///
/// The modal `GateInspectorDialog` (native, Bloch Explorer, lesson hosts)
/// and the desktop Composer's integrated inspector both compose these
/// sections, so gate descriptions, matrices and explanations exist once:
///
/// ```text
/// GateEducationalCatalog (data)
///          │
/// gate_educational_sections.dart (presentation)
///     ┌────┴──────────────┐
/// GateInspectorPanel   GateInspectorDialog
/// ```
///
/// [decorated] chooses between the dialog's card treatment and the
/// inspector's flat treatment (the inspector is already a panel).

/// Heading for a gate's definition, from what the TeX actually shows: a
/// matrix (`bmatrix`/`pmatrix`, `diag`), a basis-state transformation
/// (`↦`, `→`), or otherwise a definition. A mapping is never called a matrix.
String mathDefinitionHeading(String tex) {
  if (tex.contains(r'\begin{') || tex.contains('diag')) return 'MATRIX';
  if (tex.contains(r'\mapsto') ||
      tex.contains(r'\rightarrow') ||
      tex.contains('→')) {
    return 'STATE TRANSFORMATION';
  }
  return 'DEFINITION';
}

/// Body copy explaining why a Bloch sphere cannot show a controlled gate.
const String controlledGateBlochNote =
    'A Bloch sphere describes one isolated qubit. Controlled gates act on '
    'joint basis states and can create entanglement, so their full behavior '
    'belongs to the multi-qubit state space.';

bool isControlledEducationalVisual(GateEducationalVisualKind kind) =>
    switch (kind) {
      GateEducationalVisualKind.controlledX ||
      GateEducationalVisualKind.controlledPhase ||
      GateEducationalVisualKind.multiControlledX =>
        true,
      _ => false,
    };

/// A titled group. Decorated: the dialog's bordered card. Flat: spacing only.
class GateEducationalCard extends StatelessWidget {
  const GateEducationalCard({
    super.key,
    required this.children,
    this.decorated = true,
  });

  final List<Widget> children;
  final bool decorated;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
    if (!decorated) {
      return Padding(padding: const EdgeInsets.only(bottom: 6), child: column);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
      decoration: BoxDecoration(
        color: QubitQuestDialog.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: column,
    );
  }
}

/// A heading and a paragraph (inline LaTeX allowed).
class GateEducationalTextSection extends StatelessWidget {
  const GateEducationalTextSection({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GateInspectorTheme.sectionTitle),
          const SizedBox(height: 5),
          LatexText(
            math: body,
            textStyle: GateInspectorTheme.body,
            inlineMathColor: Colors.white,
            inlineMathHeight: GateInspectorTheme.mathSecondaryInlineHeight,
            displayMathHeight: GateInspectorTheme.mathSecondaryDisplayHeight,
          ),
        ]),
      );
}

/// A heading and a bulleted list.
class GateEducationalListSection extends StatelessWidget {
  const GateEducationalListSection({
    super.key,
    required this.title,
    required this.values,
  });

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) => GateEducationalTextSection(
        title: title,
        body: values.map((value) => '• $value').join('\n'),
      );
}

/// Intuition, what changes and common use: the conceptual summary.
class GateEducationalSummary extends StatelessWidget {
  const GateEducationalSummary({
    super.key,
    required this.info,
    this.decorated = true,
    this.includeIntuition = true,
  });

  final GateEducationalInfo info;
  final bool decorated;

  /// False when the host already shows the intuition elsewhere.
  final bool includeIntuition;

  @override
  Widget build(BuildContext context) => GateEducationalCard(
        decorated: decorated,
        children: [
          if (includeIntuition && info.intuition.isNotEmpty)
            GateEducationalTextSection(
                title: 'Intuition', body: info.intuition),
          if (info.physicalChange.isNotEmpty)
            GateEducationalTextSection(
                title: 'What changes', body: info.physicalChange),
          if (info.commonUse.isNotEmpty)
            GateEducationalTextSection(
                title: 'Common use', body: info.commonUse),
        ],
      );
}

enum GateEducationalMathLevel { secondary, tertiary }

/// A titled list of formulas (state action, identities).
class GateEducationalMathList extends StatelessWidget {
  const GateEducationalMathList({
    super.key,
    required this.title,
    required this.values,
    required this.level,
    required this.keyPrefix,
    this.decorated = true,
    this.large = false,
  });

  final String title;
  final List<String> values;
  final GateEducationalMathLevel level;
  final String keyPrefix;
  final bool decorated;

  /// Larger maths for the desktop inspector; the dialog keeps its sizes.
  final bool large;

  @override
  Widget build(BuildContext context) => GateEducationalCard(
        decorated: decorated,
        children: [
          Text(title, style: GateInspectorTheme.sectionTitle),
          const SizedBox(height: 8),
          for (final entry in values.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: GateEducationalMathExpression(
                key: ValueKey('$keyPrefix-${entry.key}'),
                math: entry.value,
                level: level,
                large: large,
              ),
            ),
        ],
      );
}

class GateEducationalMathExpression extends StatelessWidget {
  const GateEducationalMathExpression({
    super.key,
    required this.math,
    required this.level,
    this.large = false,
  });

  final String math;
  final GateEducationalMathLevel level;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final secondary = level == GateEducationalMathLevel.secondary;
    final base = secondary
        ? GateInspectorTheme.mathSecondary
        : GateInspectorTheme.mathTertiary;
    final style = large ? base.copyWith(fontSize: 16.5, height: 1.4) : base;
    if (large && !NativeMathText.supports(math)) {
      return LatexText(
        math: math,
        textStyle: style,
        inlineMathColor: Colors.white,
        mathFontSize: 16.5,
      );
    }
    if (NativeMathText.supports(math)) {
      return NativeMathText(math: math, style: style);
    }
    return LatexText(
      math: math,
      textStyle: style,
      inlineMathColor: Colors.white,
      inlineMathHeight: secondary
          ? GateInspectorTheme.mathSecondaryInlineHeight
          : GateInspectorTheme.mathTertiaryInlineHeight,
      displayMathHeight: secondary
          ? GateInspectorTheme.mathSecondaryDisplayHeight
          : GateInspectorTheme.mathTertiaryDisplayHeight,
    );
  }
}

/// The gate's matrix definition. Large matrices (CCX is 8×8) scroll
/// horizontally inside their own region instead of shrinking.
class GateEducationalMatrix extends StatelessWidget {
  const GateEducationalMatrix({
    super.key,
    required this.matrix,
    this.mathFontSize,
    this.latexKey,
    this.minimumScale = 0,
  });

  /// With [mathFontSize]: a display formula wider than its column may
  /// shrink to this fraction before it scrolls horizontally (0 = never
  /// shrink, always scroll). Keeps a readable floor.
  final double minimumScale;

  final String matrix;

  /// Key placed on the rendered [LatexText] itself.
  final Key? latexKey;

  /// MathJax em size; null keeps the dialog's height-based sizing.
  final double? mathFontSize;

  @override
  Widget build(BuildContext context) {
    final latex = LatexText(
      key: latexKey,
      math: matrix,
      textStyle: GateInspectorTheme.mathPrimary,
      inlineMathHeight: GateInspectorTheme.mathPrimaryInlineHeight,
      displayMathHeight: GateInspectorTheme.mathPrimaryDisplayHeight,
      mathFontSize: mathFontSize,
      minimumDisplayMathScale: minimumScale,
    );
    // LatexText scrolls by itself below its minimum scale.
    if (mathFontSize == null || minimumScale > 0) return latex;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: latex,
    );
  }
}

/// Related concepts as chips; tappable when [onOpen] is available and the
/// concept has a Notebook discovery.
class GateRelatedConceptsSection extends StatelessWidget {
  const GateRelatedConceptsSection({
    super.key,
    required this.concepts,
    this.onOpen,
    this.decorated = true,
  });

  final List<GateRelatedConcept> concepts;
  final ValueChanged<String>? onOpen;
  final bool decorated;

  @override
  Widget build(BuildContext context) => GateEducationalCard(
        decorated: decorated,
        children: [
          const Text('Related concepts',
              style: GateInspectorTheme.sectionTitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final concept in concepts)
                ActionChip(
                  key: ValueKey('gate-concept-${concept.label}'),
                  avatar: concept.notebookDiscoveryTitle == null
                      ? null
                      : const Icon(Icons.menu_book_outlined, size: 15),
                  label: Text(concept.label),
                  tooltip: concept.notebookDiscoveryTitle == null
                      ? concept.label
                      : 'Open ${concept.label} in Notebook',
                  onPressed:
                      concept.notebookDiscoveryTitle == null || onOpen == null
                          ? null
                          : () => onOpen!(concept.notebookDiscoveryTitle!),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
}
