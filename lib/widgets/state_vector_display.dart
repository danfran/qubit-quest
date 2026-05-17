import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/utils/complex_formatter.dart';

class _ResultPalette {
  // Qubit Quest composer result tokens mirror the exact composer visual system.
  static const Color qqCard2 = Color(0xFF18233A);
  static const Color qqInner = Color(0xFF030814);
  static const Color qqInner2 = Color(0xFF101A2D);
  static const Color qqBorderSoft = Color(0xFF253755);
  static const Color qqCyan = Color(0xFF56CCF2);
  static const Color qqPurple = Color(0xFFB388FF);
  static const Color qqGreen = Color(0xFF7CFFB2);
}

class StateVectorDisplay extends StatefulWidget {
  final List<Complex> stateVector;

  /// Optional target/solution state vector for side-by-side comparison.
  /// When null the widget behaves exactly as before.
  final List<Complex>? targetStateVector;
  final int numQubits;

  const StateVectorDisplay({
    super.key,
    required this.stateVector,
    required this.numQubits,
    this.targetStateVector,
  });

  @override
  State<StateVectorDisplay> createState() => _StateVectorDisplayState();
}

class _StateVectorDisplayState extends State<StateVectorDisplay> {
  bool _showAllValues = false;
  static const double _emptyThreshold = 1e-9;
  static const double _probabilityThreshold = 1e-6;
  static const double _matchTolerance = 1e-6;
  static const int _summaryOutcomeLimit = 3;

  late ScrollController _stateVectorVerticalScrollController;

  @override
  void initState() {
    super.initState();
    _stateVectorVerticalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _stateVectorVerticalScrollController.dispose();
    super.dispose();
  }

  String _toBinaryKet(int index, int numQubits) {
    String binary = index.toRadixString(2);
    return '|${binary.padLeft(numQubits, '0')}⟩';
  }

  bool _complexClose(Complex a, Complex b) {
    return (a.real - b.real).abs() < _matchTolerance &&
        (a.imaginary - b.imaginary).abs() < _matchTolerance;
  }

  double _probability(Complex value) {
    final double magnitude = value.magnitude.toDouble();
    return magnitude * magnitude;
  }

  String _formatPercent(double probability) {
    final double percent = probability * 100;
    if (percent > 0 && percent < 0.1) {
      return '<0.1%';
    }
    if ((percent - percent.round()).abs() < 0.05) {
      return '${percent.round()}%';
    }
    return '${percent.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final int vectorSize = 1 << widget.numQubits;
    final bool hasTarget = widget.targetStateVector != null &&
        widget.targetStateVector!.length == vectorSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(hasTarget),
        const SizedBox(height: 4),
        Expanded(
          child: Scrollbar(
            controller: _stateVectorVerticalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _stateVectorVerticalScrollController,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOutcomeSummary(hasTarget),
                        const SizedBox(height: 5),
                        _buildProbabilityList(vectorSize, hasTarget),
                        const SizedBox(height: 4),
                        _buildAdvancedDetails(vectorSize, hasTarget),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool hasTarget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            hasTarget ? 'Measurement Result' : 'Current Result',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('All',
                style: TextStyle(color: Colors.white70, fontSize: 10)),
            Transform.scale(
              scale: 0.62,
              child: Switch(
                value: _showAllValues,
                onChanged: (v) => setState(() => _showAllValues = v),
                activeThumbColor: _ResultPalette.qqCyan,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: _ResultPalette.qqInner2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<int> _significantIndexes(int vectorSize, bool hasTarget) {
    final List<int> visibleIndexes = [];
    int strongestIndex = 0;
    double strongestProbability = -1.0;

    for (int index = 0; index < vectorSize; index++) {
      final double currentProbability = _probability(widget.stateVector[index]);
      final double targetProbability =
          hasTarget ? _probability(widget.targetStateVector![index]) : 0.0;

      if (currentProbability > strongestProbability) {
        strongestProbability = currentProbability;
        strongestIndex = index;
      }

      if (_showAllValues ||
          currentProbability > _probabilityThreshold ||
          targetProbability > _probabilityThreshold) {
        visibleIndexes.add(index);
      }
    }

    if (visibleIndexes.isEmpty) {
      visibleIndexes.add(strongestIndex);
    }

    return visibleIndexes;
  }

  List<int> _topOutcomeIndexes(List<Complex> vector) {
    final List<int> indexes = List.generate(vector.length, (index) => index);
    indexes.sort((a, b) => _probability(vector[b]).compareTo(_probability(
          vector[a],
        )));

    final List<int> significant = indexes
        .where((index) => _probability(vector[index]) > _probabilityThreshold)
        .take(_summaryOutcomeLimit)
        .toList();

    if (significant.isNotEmpty) {
      return significant;
    }

    return indexes.take(1).toList();
  }

  Widget _buildOutcomeSummary(bool hasTarget) {
    final List<int> currentOutcomes = _topOutcomeIndexes(widget.stateVector);
    final List<int> targetOutcomes = hasTarget
        ? _topOutcomeIndexes(widget.targetStateVector!)
        : const <int>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: _ResultPalette.qqInner,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ResultPalette.qqBorderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OutcomeGroup(
            label: hasTarget ? 'Now' : 'Most likely outcomes',
            chips: currentOutcomes.map((index) {
              final double probability =
                  _probability(widget.stateVector[index]);
              return _OutcomeChip(
                ket: _toBinaryKet(index, widget.numQubits),
                percentLabel: _formatPercent(probability),
                color: _ResultPalette.qqCyan,
              );
            }).toList(),
          ),
          if (hasTarget) ...[
            const SizedBox(height: 5),
            _OutcomeGroup(
              label: 'Target',
              chips: targetOutcomes.map((index) {
                final double probability =
                    _probability(widget.targetStateVector![index]);
                return _OutcomeChip(
                  ket: _toBinaryKet(index, widget.numQubits),
                  percentLabel: _formatPercent(probability),
                  color: _ResultPalette.qqPurple,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProbabilityList(int vectorSize, bool hasTarget) {
    final List<int> visibleIndexes = _significantIndexes(vectorSize, hasTarget);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Probabilities',
              style: TextStyle(
                color: _ResultPalette.qqCyan,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              _showAllValues ? 'showing all' : 'non-zero only',
              style: const TextStyle(
                color: Color(0xFF9BAAC4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...visibleIndexes.map((index) {
          final Complex current = widget.stateVector[index];
          final Complex? target =
              hasTarget ? widget.targetStateVector![index] : null;
          final double currentProbability = _probability(current);
          final double targetProbability =
              target == null ? 0.0 : _probability(target);
          final bool matched = target != null && _complexClose(current, target);

          return _ProbabilityRow(
            ket: _toBinaryKet(index, widget.numQubits),
            probability: currentProbability,
            targetProbability: hasTarget ? targetProbability : null,
            matched: matched,
            percentLabel: _formatPercent(currentProbability),
            targetPercentLabel:
                hasTarget ? _formatPercent(targetProbability) : null,
          );
        }),
      ],
    );
  }

  Widget _buildAdvancedDetails(int vectorSize, bool hasTarget) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        iconColor: _ResultPalette.qqCyan,
        collapsedIconColor: const Color(0xFF9BAAC4),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Raw amplitudes and exact statevector entries',
              style: TextStyle(
                color: Color(0xFF9BAAC4),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _ResultPalette.qqInner,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _ResultPalette.qqBorderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(vectorSize, (index) {
                final Complex current = widget.stateVector[index];
                final Complex? target =
                    hasTarget ? widget.targetStateVector![index] : null;

                final bool currentNonZero = current.magnitude > _emptyThreshold;
                final bool targetNonZero =
                    target != null && target.magnitude > _emptyThreshold;

                if (!_showAllValues && !currentNonZero && !targetNonZero) {
                  return const SizedBox.shrink();
                }

                final String ket = _toBinaryKet(index, widget.numQubits);

                if (!hasTarget) {
                  return _AdvancedAmplitudeRow(
                    currentText: '$ket: ${formatComplex(current)}',
                    currentActive: currentNonZero,
                  );
                }

                final bool matched = _complexClose(current, target!);

                return _AdvancedAmplitudeRow(
                  currentText: '$ket: ${formatComplex(current)}',
                  currentActive: currentNonZero,
                  targetText: '→ ${formatComplex(target)}',
                  targetActive: targetNonZero,
                  matched: matched,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeGroup extends StatelessWidget {
  final String label;
  final List<_OutcomeChip> chips;

  const _OutcomeGroup({
    required this.label,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool narrow = constraints.maxWidth < 280;

      final Widget labelWidget = Text(
        label,
        style: const TextStyle(
          color: Color(0xFFCAD5EA),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      );

      final Widget chipsWidget = Wrap(
        spacing: 5,
        runSpacing: 5,
        children: chips,
      );

      if (narrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelWidget,
            const SizedBox(height: 4),
            chipsWidget,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: labelWidget),
          Expanded(child: chipsWidget),
        ],
      );
    });
  }
}

class _OutcomeChip extends StatelessWidget {
  final String ket;
  final String percentLabel;
  final Color color;

  const _OutcomeChip({
    required this.ket,
    required this.percentLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _ResultPalette.qqCard2,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ket,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            percentLabel,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProbabilityRow extends StatelessWidget {
  final String ket;
  final double probability;
  final double? targetProbability;
  final bool matched;
  final String percentLabel;
  final String? targetPercentLabel;

  const _ProbabilityRow({
    required this.ket,
    required this.probability,
    required this.targetProbability,
    required this.matched,
    required this.percentLabel,
    required this.targetPercentLabel,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedProbability = probability.clamp(0, 1).toDouble();
    final double? clampedTargetProbability =
        targetProbability?.clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  ket,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: clampedProbability,
                    minHeight: 6,
                    backgroundColor: _ResultPalette.qqInner2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _ResultPalette.qqCyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 46,
                child: Text(
                  percentLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (matched) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle,
                  color: _ResultPalette.qqGreen,
                  size: 13,
                ),
              ],
            ],
          ),
          if (clampedTargetProbability != null &&
              targetPercentLabel != null) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const SizedBox(
                  width: 44,
                  child: Text(
                    'Target',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: clampedTargetProbability,
                      minHeight: 4,
                      backgroundColor: _ResultPalette.qqInner2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _ResultPalette.qqPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 46,
                  child: Text(
                    targetPercentLabel!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 17),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AdvancedAmplitudeRow extends StatelessWidget {
  final String currentText;
  final bool currentActive;
  final String? targetText;
  final bool targetActive;
  final bool matched;

  const _AdvancedAmplitudeRow({
    required this.currentText,
    required this.currentActive,
    this.targetText,
    this.targetActive = false,
    this.matched = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentText,
            style: TextStyle(
              color: currentActive ? Colors.white : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          if (targetText != null)
            Row(
              children: [
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    targetText!,
                    style: TextStyle(
                      color: targetActive
                          ? _ResultPalette.qqCyan
                          : Colors.grey[700],
                      fontSize: 11,
                    ),
                  ),
                ),
                if (matched) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check_circle,
                    color: _ResultPalette.qqGreen,
                    size: 12,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
