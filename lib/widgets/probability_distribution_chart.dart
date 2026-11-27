import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/probability_format.dart';
import 'package:quantumquiz/widgets/qq_scientific_primitives.dart';

/// Exact Z-basis outcome probabilities of a state vector (v2.6 M11C,
/// redesigned in M11C.1). It answers one question: *what outcomes should I
/// expect if I measure every qubit of this state?*
///
/// Every value is |amplitude|² of the supplied simulation state: nothing is
/// sampled, rounded into the data or inferred. Labels follow the register
/// order |q(n−1) … q1 q0⟩, and every bar uses the same fixed 0–100% scale
/// (full width is certainty), so lengths are comparable and never
/// auto-scaled.
///
/// The representation follows the data:
/// * up to 8 outcomes: one aligned row per outcome (label, bar, value),
///   zero-probability outcomes included;
/// * 16 or 32 outcomes, sparse (at most 8 possible): the possible outcomes
///   as rows, with the number of zero-probability outcomes stated and the
///   complete list one tap away;
/// * 16 or 32 outcomes, dense: a compact histogram of every outcome in
///   basis order, with the complete list of rows one tap away.
class ProbabilityDistributionChart extends StatefulWidget {
  const ProbabilityDistributionChart({
    super.key,
    required this.stateVector,
    required this.numQubits,
  });

  final List<Complex> stateVector;
  final int numQubits;

  /// Outcomes always listed in full.
  static const int smallOutcomeCount = 8;

  static double probabilityOf(Complex amplitude) {
    final re = amplitude.real.toDouble();
    final im = amplitude.imaginary.toDouble();
    return re * re + im * im;
  }

  /// The shared display policy (v2.6 M4), so chart and tables agree.
  static String formatPercent(double probability) =>
      formatProbability(probability);

  @override
  State<ProbabilityDistributionChart> createState() =>
      _ProbabilityDistributionChartState();
}

class _ProbabilityDistributionChartState
    extends State<ProbabilityDistributionChart> {
  bool _showAll = false;

  /// The learner may zoom the histogram's axis to the largest probability;
  /// it never rescales on its own, and the axis says which scale is shown.
  bool _fit = false;

  String _ket(int index) =>
      '|${index.toRadixString(2).padLeft(widget.numQubits, '0')}⟩';

  bool _isZero(double p) => p <= probabilityZeroTolerance;

  @override
  Widget build(BuildContext context) {
    final n = widget.numQubits;
    final count = 1 << n;
    final probabilities = [
      for (var i = 0; i < count; i++)
        i < widget.stateVector.length
            ? ProbabilityDistributionChart.probabilityOf(widget.stateVector[i])
            : 0.0,
    ];
    final possible = [
      for (var i = 0; i < count; i++)
        if (!_isZero(probabilities[i])) i,
    ];
    final small = count <= ProbabilityDistributionChart.smallOutcomeCount;
    final sparse = !small &&
        possible.length <= ProbabilityDistributionChart.smallOutcomeCount;
    final dense = !small && !sparse;
    final zeros = count - possible.length;
    final order = '|${[for (var q = n - 1; q >= 0; q--) 'q$q'].join(' ')}⟩';

    final List<int> listed = small || _showAll
        ? [for (var i = 0; i < count; i++) i]
        : sparse
            ? possible
            : const [];

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final children = <Widget>[];
      if (dense) {
        children.add(_Histogram(
          probabilities: probabilities,
          ket: _ket,
          fit: _fit,
          onFitChanged: (fit) => setState(() => _fit = fit),
        ));
        children.add(const SizedBox(height: 10));
      }
      if (listed.isNotEmpty) {
        children.add(_rows(listed, probabilities, width));
      }
      if (!small) {
        children.add(Padding(
          padding: EdgeInsets.only(top: listed.isEmpty ? 0 : 6),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              QqMeta(
                dense
                    ? '${possible.length} of $count outcomes possible'
                        '${zeros > 0 ? ' · $zeros with probability 0' : ''}'
                    : '$zeros outcome${zeros == 1 ? '' : 's'} with '
                        'probability 0 ${_showAll ? 'included' : 'not listed'}',
                key: const ValueKey('composer-probability-hidden'),
              ),
              TextButton(
                key: const ValueKey('composer-probability-show-all'),
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(_showAll
                    ? (dense ? 'Hide the list' : 'Possible outcomes only')
                    : 'List all $count outcomes'),
              ),
            ],
          ),
        ));
      }
      children.add(const SizedBox(height: 8));
      children.add(QqMeta(
        'Exact probabilities |amplitude|² · Z basis · basis order $order',
        key: const ValueKey('composer-probability-caption'),
      ));
      return Column(
        key: const ValueKey('composer-probability-chart'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    });
  }

  /// Aligned rows, in up to two columns when there are many and room.
  Widget _rows(List<int> indexes, List<double> probabilities, double width) {
    final columns = indexes.length > 8 && width >= 640 ? 2 : 1;
    final perColumn = (indexes.length / columns).ceil();
    final ketWidth = math.max(76.0, 30.0 + 10.5 * widget.numQubits);
    Widget table(List<int> part) => QqDataTable(
          rowMinHeight: 30,
          columnGap: 14,
          columns: [
            QqColumn('Outcome', width: ketWidth),
            const QqColumn('', flex: 1),
            const QqColumn('Probability', width: 82, align: QqColumn.right),
          ],
          rows: [
            for (final i in part)
              QqTableRow(
                key: ValueKey('composer-probability-bar-$i'),
                semanticsLabel: '${_ket(i)} probability '
                    '${formatProbability(probabilities[i])}',
                cells: [
                  Text(_ket(i),
                      style: QqType.table.copyWith(
                          color: _isZero(probabilities[i])
                              ? QubitQuestColors.textMuted
                              : QqType.ketColor,
                          fontWeight: FontWeight.w500)),
                  QqProbabilityBar(value: probabilities[i]),
                  Text(
                    formatProbability(probabilities[i]),
                    style: QqType.table.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _isZero(probabilities[i])
                          ? QubitQuestColors.textMuted
                          : QubitQuestColors.textPrimary,
                    ),
                  ),
                ],
              ),
          ],
        );
    if (columns == 1) return table(indexes);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < columns; c++) ...[
          if (c > 0) const SizedBox(width: 28),
          Expanded(
            child: table(indexes
                .skip(c * perColumn)
                .take(perColumn)
                .toList(growable: false)),
          ),
        ],
      ],
    );
  }
}

/// Every outcome as a thin column on the fixed 0–100% scale, in basis
/// order, with gridlines at 25% steps. No per-bar labels (they would have
/// to be tiny and rotated): the first and last outcomes are named under the
/// axis, each bar has a tooltip and a semantic label, and the
/// full list of rows is one tap away.
class _Histogram extends StatelessWidget {
  const _Histogram({
    required this.probabilities,
    required this.ket,
    required this.fit,
    required this.onFitChanged,
  });
  final List<double> probabilities;
  final String Function(int) ket;

  /// Axis from 0 to the largest probability instead of 0–100%.
  final bool fit;
  final ValueChanged<bool> onFitChanged;

  static const double height = 112;

  @override
  Widget build(BuildContext context) {
    final count = probabilities.length;
    final max = probabilities.fold<double>(0, math.max);
    final top = fit && max > 0 ? max : 1.0;
    return Column(
      key: const ValueKey('composer-probability-histogram'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                height: height,
                child: CustomPaint(
                  painter: _GridPainter(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < count; i++)
                        Expanded(
                          child: Tooltip(
                            message: '${ket(i)}  '
                                '${formatProbability(probabilities[i])} (exact)',
                            child: Semantics(
                              key: ValueKey('composer-probability-hist-$i'),
                              label: '${ket(i)} probability '
                                  '${formatProbability(probabilities[i])}',
                              excludeSemantics: true,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: (probabilities[i] / top)
                                        .clamp(0.0, 1.0),
                                    widthFactor: 1,
                                    child: Container(
                                      constraints: BoxConstraints(
                                          minHeight:
                                              probabilities[i] > 0 ? 2 : 0),
                                      decoration: const BoxDecoration(
                                        color:
                                            QubitQuestColors.accentInteractive,
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(2)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final t in [
                    formatProbability(top),
                    formatProbability(top / 2),
                    '0%',
                  ])
                    Text(t,
                        style: QqType.meta.copyWith(fontSize: 11.5, height: 1)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(right: 60),
          child: DefaultTextStyle.merge(
            style: QqType.meta.copyWith(fontSize: 12.5),
            child: Row(
              children: [
                Text(ket(0)),
                const Spacer(),
                Text(ket(count - 1)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            QqMeta(
              'Largest probability ${formatProbability(max)} · axis '
              '0–${formatProbability(top)}${fit ? ' (zoomed)' : ''}',
              key: const ValueKey('composer-probability-histogram-scale'),
            ),
            QqToggleChip(
              key: const ValueKey('composer-probability-fit'),
              label: 'Zoom axis to largest',
              tooltip: 'Scale the axis from 0 to the largest probability',
              value: fit,
              onChanged: onFitChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..strokeWidth = 1;
    for (final f in const [0.0, .25, .5, .75, 1.0]) {
      final y = size.height * (1 - f);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
