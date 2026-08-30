import 'package:flutter/material.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/latex_text.dart';

/// Shared semantic typography for Quantum Notebook readers.
///
/// Authoring rule: choose a semantic role, never an expression-specific size.
/// Prose stays Flutter text. Standalone mathematics uses [NotebookMathEvidence]
/// with [NotebookMathRole.display] by default; reserve `emphasis` for a major
/// transformation. Related equations are separate lines at the same role size,
/// not one scaled-down TeX block. Long expressions wrap through authored lines
/// and only use the renderer's bounded scale-down as a final fallback.
enum NotebookTextRole {
  pageTitle,
  context,
  entryTitle,
  lead,
  sectionHeading,
  subsection,
  body,
  supporting,
  interactiveTitle,
  circuitCaption,
}

abstract final class NotebookTypography {
  static const double inlineMathHeight = 17;
  static const double displayMathHeight = 23;
  static const double emphasisMathHeight = 26;
  static const double minimumMathScale = 0.82;

  // MathJax includes the numerator, fraction rule, and denominator in an
  // expression's SVG height. Fitting that taller box to the same height as a
  // simple equation makes the numerator and denominator glyphs substantially
  // smaller. These renderer-level factors compensate for that box geometry;
  // they do not promote the expression to a different semantic role.
  // Device review established that the first compensation (1.38 / 1.10) was
  // still visually subordinate to ordinary display equations. These values
  // are approximately 17.5% larger while retaining the same semantic role.
  static const double fractionPerceivedHeightFactor = 2.22;
  static const double rootPerceivedHeightFactor = 1.89;

  static TextStyle text(
    NotebookTextRole role, {
    required Color color,
  }) {
    switch (role) {
      case NotebookTextRole.pageTitle:
        return TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        );
      case NotebookTextRole.context:
        return TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        );
      case NotebookTextRole.entryTitle:
        return TextStyle(
          color: color,
          fontSize: 26,
          height: 1.08,
          fontWeight: FontWeight.w900,
        );
      case NotebookTextRole.lead:
        return TextStyle(
          color: color,
          fontSize: 17,
          height: 1.4,
          fontWeight: FontWeight.w700,
        );
      case NotebookTextRole.sectionHeading:
        return TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        );
      case NotebookTextRole.subsection:
        return TextStyle(
          color: color,
          fontSize: 16,
          letterSpacing: 0.1,
          fontWeight: FontWeight.w900,
        );
      case NotebookTextRole.body:
        return TextStyle(
          color: color,
          fontSize: 16,
          height: 1.42,
          fontWeight: FontWeight.w600,
        );
      case NotebookTextRole.supporting:
        return TextStyle(
          color: color,
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w600,
        );
      case NotebookTextRole.interactiveTitle:
        return TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        );
      case NotebookTextRole.circuitCaption:
        return TextStyle(color: color, fontSize: 10);
    }
  }

  static double mathHeight(NotebookMathRole role) => switch (role) {
        NotebookMathRole.inline => inlineMathHeight,
        NotebookMathRole.display => displayMathHeight,
        NotebookMathRole.emphasis => emphasisMathHeight,
      };

  static double mathRenderHeight(NotebookMathRole role, String latex) {
    final semanticHeight = mathHeight(role);
    if (role == NotebookMathRole.inline) return semanticHeight;
    if (latex.contains(r'\frac')) {
      return semanticHeight * fractionPerceivedHeightFactor;
    }
    if (latex.contains(r'\sqrt')) {
      return semanticHeight * rootPerceivedHeightFactor;
    }
    return semanticHeight;
  }
}

/// A Notebook mathematical object rendered by semantic role.
///
/// Multi-line groups deliberately become multiple TeX objects so every line
/// retains the role's perceived size.
class NotebookMathEvidence extends StatelessWidget {
  const NotebookMathEvidence({
    super.key,
    required this.example,
    this.color = Colors.white,
  });

  final NotebookExample example;
  final Color color;

  List<String> get _lines {
    if (example.latexLines.isNotEmpty) return example.latexLines;
    if (example.latex != null) return [example.latex!];
    return example.notation
        .split('\n')
        .map(notebookMathNotationToLatex)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    assert(example.presentation == NotebookExamplePresentation.math);
    final role = example.mathRole;
    final inline = role == NotebookMathRole.inline;

    return Semantics(
      label: example.notation,
      child: ExcludeSemantics(
        child: Column(
          key: ValueKey('notebook-math-${role.name}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < _lines.length; index++) ...[
              // The semantic role remains stable; only the SVG paint height is
              // compensated for vertically stacked mathematical structures.
              Align(
                key: ValueKey('notebook-math-line-${role.name}-$index'),
                alignment: inline ? Alignment.centerLeft : Alignment.center,
                child: LatexText(
                  math: inline
                      ? r'\(' + _lines[index] + r'\)'
                      : r'\[' + _lines[index] + r'\]',
                  textStyle: TextStyle(
                    color: color,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                  inlineMathHeight: NotebookTypography.mathRenderHeight(
                    role,
                    _lines[index],
                  ),
                  displayMathHeight: NotebookTypography.mathRenderHeight(
                    role,
                    _lines[index],
                  ),
                  minimumDisplayMathScale: NotebookTypography.minimumMathScale,
                ),
              ),
              if (index != _lines.length - 1) const SizedBox(height: 3),
            ],
          ],
        ),
      ),
    );
  }
}
