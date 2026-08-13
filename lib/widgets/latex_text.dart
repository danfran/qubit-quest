import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

/// Renders a mixed text + LaTeX string correctly.
///
/// The [flutter_tex] `TeXWidget` has a bug where it concatenates delimiter
/// regexes without the `|` alternation operator, so no formulas are ever
/// extracted and everything renders as plain text.
///
/// This widget uses the correct alternation regex and feeds each formula
/// directly to [TeX2SVG].
///
/// Supported delimiters:
///   inline  → \( ... \)  or  $ ... $
///   display → \[ ... \]  or  $$ ... $$
class LatexText extends StatelessWidget {
  final String math;
  final TextStyle? textStyle;
  final Color? inlineMathColor;

  /// Height for inline math glyphs (should match the surrounding font size).
  final double inlineMathHeight;

  /// Height for display (block) math glyphs.
  final double displayMathHeight;

  const LatexText({
    super.key,
    required this.math,
    this.textStyle,
    this.inlineMathColor,
    this.inlineMathHeight = 16.0,
    this.displayMathHeight = 24.0,
  });

  // ── Regex with correct alternation ────────────────────────────────────────
  static final RegExp _latexRegex = RegExp(
    r'(\$\$(.*?)\$\$)|(\\\[(.*?)\\\])|(\$(.*?)\$)|(\\\((.*?)\\\))',
    dotAll: true,
  );

  List<_Segment> _parse(String input) {
    final segments = <_Segment>[];
    int lastEnd = 0;

    for (final match in _latexRegex.allMatches(input)) {
      if (match.start > lastEnd) {
        final txt = input.substring(lastEnd, match.start);
        if (txt.isNotEmpty) segments.add(_Segment.text(txt));
      }

      // Group indices with alternation:
      // 2 = $$...$$, 4 = \[...\], 6 = $...$, 8 = \(...\)
      final displayDollar = match.group(2);
      final displayBracket = match.group(4);
      final inlineDollar = match.group(6);
      final inlineBracket = match.group(8);

      final formula = displayDollar ??
          displayBracket ??
          inlineDollar ??
          inlineBracket ??
          '';
      final isDisplay = displayDollar != null || displayBracket != null;

      if (formula.isNotEmpty) {
        segments.add(_Segment.math(formula.trim(), isDisplay: isDisplay));
      }

      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      final remaining = input.substring(lastEnd);
      if (remaining.isNotEmpty) segments.add(_Segment.text(remaining));
    }

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle.merge(textStyle);
    final color = effectiveStyle.color ?? Colors.white;
    final inlineColor = inlineMathColor ?? color;

    final segments = _parse(math);

    final List<Widget> rows = [];
    final List<InlineSpan> currentSpans = [];

    void flushSpans() {
      if (currentSpans.isNotEmpty) {
        rows.add(RichText(
          text: TextSpan(children: List.of(currentSpans)),
        ));
        currentSpans.clear();
      }
    }

    for (final seg in segments) {
      if (seg.isText) {
        currentSpans.add(TextSpan(text: seg.content, style: effectiveStyle));
      } else if (seg.isDisplay) {
        flushSpans();
        rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TeX2SVG(
            math: _mathJaxSource(seg),
            formulaWidgetBuilder: (ctx, svg) => LatexSvgPicture(
              svg: svg,
              logicalHeight: displayMathHeight,
              color: color,
            ),
          ),
        ));
      } else {
        // Inline math — embed as a WidgetSpan inside the RichText
        currentSpans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: TeX2SVG(
            math: _mathJaxSource(seg),
            formulaWidgetBuilder: (ctx, svg) => LatexSvgPicture(
              svg: svg,
              logicalHeight: inlineMathHeight,
              color: inlineColor,
            ),
          ),
        ));
      }
    }

    flushSpans();

    if (rows.length == 1) return rows.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  // flutter_tex calls MathJax's convert() without forwarding delimiter mode;
  // bare input therefore defaults to display style. Preserve the parsed TeX
  // semantics explicitly when the delimiters themselves are removed.
  String _mathJaxSource(_Segment segment) {
    final style = segment.isDisplay ? r'\displaystyle' : r'\textstyle';
    return '$style{${segment.content}}';
  }
}

/// Renders MathJax SVG output inside an explicit logical-height contract.
///
/// MathJax emits paths in an intrinsic SVG viewBox, not Flutter text glyphs.
/// This tight, clipped viewport makes [logicalHeight] an actual paint bound
/// rather than only a preferred picture dimension. It also follows Flutter's
/// accessibility text scale just like the surrounding text.
class LatexSvgPicture extends StatelessWidget {
  const LatexSvgPicture({
    super.key,
    required this.svg,
    required this.logicalHeight,
    required this.color,
  });

  final String svg;
  final double logicalHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final resolvedHeight =
        MediaQuery.textScalerOf(context).scale(logicalHeight);
    return SizedBox(
      height: resolvedHeight,
      child: ClipRect(
        child: SvgPicture.string(
          svg,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          height: resolvedHeight,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

class _Segment {
  final String content;
  final bool isText;
  final bool isDisplay;

  const _Segment.text(String c)
      : content = c,
        isText = true,
        isDisplay = false;

  const _Segment.math(String c, {required bool isDisplay})
      : content = c,
        isText = false,
        isDisplay = isDisplay;
}
