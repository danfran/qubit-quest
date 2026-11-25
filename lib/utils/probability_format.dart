/// Probability display policy (v2.6 M4), shared by the State and Measure
/// views for exact probabilities and observed frequencies alike.
///
/// * Exactly representable percentages keep their digits, up to three
///   decimals: 50%, 12.5%, 3.125%, 9.375%.
/// * Other values use two decimals: 42.68%, 7.32%, 33.33%.
/// * A non-zero value never reads 0%: below 0.01% it reads `<0.01%`.
/// * A value below certainty never reads 100%: above 99.99% it reads
///   `>99.99%`.
/// * Values within [zeroTolerance] of 0 or 1 are treated as exactly 0 or 1
///   (floating-point noise from the simulator, not physics).
/// * Individual values are never adjusted to make a list sum to 100%.
library;

/// Probabilities closer than this to 0 or 1 are reported as exactly 0 or 1.
const double probabilityZeroTolerance = 1e-12;

/// Formats a probability in [0, 1] as a percentage (see library docs).
String formatProbability(double probability) {
  if (!probability.isFinite) return '—';
  if (probability <= probabilityZeroTolerance) return '0%';
  if (probability >= 1 - probabilityZeroTolerance) return '100%';
  final percent = probability * 100;
  if (percent < 0.01) return '<0.01%';
  if (percent > 99.99) return '>99.99%';
  for (var digits = 0; digits <= 3; digits++) {
    final rounded = double.parse(percent.toStringAsFixed(digits));
    if ((rounded - percent).abs() < 1e-9) {
      return '${percent.toStringAsFixed(digits)}%';
    }
  }
  final text = percent.toStringAsFixed(2);
  // Guard the edges the two-decimal rounding could reach.
  if (text == '0.00') return '<0.01%';
  if (text == '100.00') return '>99.99%';
  return '$text%';
}
