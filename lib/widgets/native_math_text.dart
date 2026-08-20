import 'package:flutter/material.dart';

/// Native Flutter rendering for deliberately small, single-line TeX subsets.
///
/// This is intentionally conservative. Expressions needing mathematical
/// layout (fractions, roots, matrices, trigonometry, or exponentials) remain on
/// the LaTeX renderer instead of being approximated here.
class NativeMathText extends StatelessWidget {
  const NativeMathText({
    super.key,
    required this.math,
    required this.style,
  });

  final String math;
  final TextStyle style;

  static bool supports(String math) {
    final value = _withoutDelimiters(math);
    return value.isNotEmpty &&
        !value.contains('\n') &&
        !value.contains(r'\frac') &&
        !value.contains(r'\sqrt') &&
        !value.contains(r'\begin') &&
        !value.contains(r'\cos') &&
        !value.contains(r'\sin') &&
        !value.contains(r'e^{');
  }

  static String plainText(String math) {
    var value = _withoutDelimiters(math)
        .replaceAll(r'\rightarrow', '→')
        .replaceAll(r'\mapsto', '↦')
        .replaceAll(r'\oplus', '⊕')
        .replaceAll(r'\langle', '⟨')
        .replaceAll(r'\rangle', '⟩')
        .replaceAll(r'\dagger', '†')
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\theta', 'θ')
        .replaceAll(r'\phi', 'φ')
        .replaceAll(RegExp(r'\\mathrm\{([^}]*)\}'), r'$1');

    value = value.replaceAllMapped(
      RegExp(r'\^\{?([0-9+\-n†]+)\}?'),
      (match) => _superscript(match.group(1)!),
    );
    value = value.replaceAllMapped(
      RegExp(r'_\{?([0-9a-zA-Z]+)\}?'),
      (match) => _subscript(match.group(1)!),
    );
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _withoutDelimiters(String math) {
    final trimmed = math.trim();
    if ((trimmed.startsWith(r'\(') && trimmed.endsWith(r'\)')) ||
        (trimmed.startsWith(r'\[') && trimmed.endsWith(r'\]'))) {
      return trimmed.substring(2, trimmed.length - 2).trim();
    }
    if ((trimmed.startsWith(r'$$') && trimmed.endsWith(r'$$'))) {
      return trimmed.substring(2, trimmed.length - 2).trim();
    }
    if (trimmed.startsWith(r'$') && trimmed.endsWith(r'$')) {
      return trimmed.substring(1, trimmed.length - 1).trim();
    }
    return trimmed;
  }

  static String _superscript(String value) => _translate(value, const {
        '0': '⁰',
        '1': '¹',
        '2': '²',
        '3': '³',
        '4': '⁴',
        '5': '⁵',
        '6': '⁶',
        '7': '⁷',
        '8': '⁸',
        '9': '⁹',
        '+': '⁺',
        '-': '⁻',
        'n': 'ⁿ',
        '†': '†',
      });

  static String _subscript(String value) => _translate(value, const {
        '0': '₀',
        '1': '₁',
        '2': '₂',
        '3': '₃',
        '4': '₄',
        '5': '₅',
        '6': '₆',
        '7': '₇',
        '8': '₈',
        '9': '₉',
        'x': 'ₓ',
        'y': 'ᵧ',
      });

  static String _translate(String value, Map<String, String> characters) =>
      value
          .split('')
          .map((character) => characters[character] ?? character)
          .join();

  @override
  Widget build(BuildContext context) => RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(text: plainText(math), style: style),
      );
}
