import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

class _ResultPalette {
  // Qubit Quest composer result tokens mirror the exact composer visual system.
  static const Color qqInner = QubitQuestColors.surfaceInset;
  static const Color qqInner2 = QubitQuestColors.surfaceInsetRaised;
  static const Color qqBorderSoft = Color(0xFF253755);
  static const Color qqCyan = QubitQuestColors.accentInteractive;
  static const Color qqPurple = QubitQuestColors.accentStrong;
  static const Color qqGreen = QubitQuestColors.success;
}

enum StateVectorDisplayTone {
  current,
  target,
}

bool defaultNonZeroOnlyForQubitCount(int numQubits) => numQubits >= 3;

class StateVectorDisplay extends StatefulWidget {
  final List<Complex> stateVector;

  /// Optional target/solution state vector for side-by-side comparison.
  /// When null the widget behaves exactly as before.
  final List<Complex>? targetStateVector;
  final int numQubits;
  final String? titleOverride;
  final String? summaryTitleOverride;
  final String? summarySubtitleOverride;
  final String? stateExpressionLabel;
  final String? stateExpression;
  final StateVectorDisplayTone tone;
  final bool showHeader;
  final bool showToggleInSummary;
  final bool showSummarySubtitle;
  final bool dense;
  final bool showVisibilityControl;
  final bool? nonZeroOnlyOverride;
  final ValueChanged<bool>? onNonZeroOnlyChanged;
  final Widget? visibilityControlOverride;
  final bool contentDriven;
  final bool lightweightTypography;

  const StateVectorDisplay({
    super.key,
    required this.stateVector,
    required this.numQubits,
    this.targetStateVector,
    this.titleOverride,
    this.summaryTitleOverride,
    this.summarySubtitleOverride,
    this.stateExpressionLabel,
    this.stateExpression,
    this.tone = StateVectorDisplayTone.current,
    this.showHeader = true,
    this.showToggleInSummary = false,
    this.showSummarySubtitle = true,
    this.dense = false,
    this.showVisibilityControl = true,
    this.nonZeroOnlyOverride,
    this.onNonZeroOnlyChanged,
    this.visibilityControlOverride,
    this.contentDriven = false,
    this.lightweightTypography = false,
  });

  @override
  State<StateVectorDisplay> createState() => _StateVectorDisplayState();
}

class _StateVectorDisplayState extends State<StateVectorDisplay> {
  late bool _nonZeroOnly;
  static const double _probabilityThreshold = 1e-6;
  static const double _matchTolerance = 1e-6;

  late ScrollController _stateVectorVerticalScrollController;
  late int _lastStateVectorSignature;

  @override
  void initState() {
    super.initState();
    _nonZeroOnly = defaultNonZeroOnlyForQubitCount(widget.numQubits);
    _stateVectorVerticalScrollController = ScrollController();
    _lastStateVectorSignature = _stateVectorSignature(widget.stateVector);
  }

  @override
  void dispose() {
    _stateVectorVerticalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StateVectorDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int nextSignature = _stateVectorSignature(widget.stateVector);
    if (widget.tone == StateVectorDisplayTone.current &&
        nextSignature != _lastStateVectorSignature) {
      _resetStateScroll();
    }
    _lastStateVectorSignature = nextSignature;
  }

  int _stateVectorSignature(List<Complex> vector) {
    return Object.hashAll(
      vector.map((value) {
        return Object.hash(
          (value.real.toDouble() / _matchTolerance).round(),
          (value.imaginary.toDouble() / _matchTolerance).round(),
        );
      }),
    );
  }

  void _resetStateScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_stateVectorVerticalScrollController.hasClients) {
        return;
      }
      _stateVectorVerticalScrollController.jumpTo(0);
    });
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

  Color get _summaryAccent {
    return switch (widget.tone) {
      StateVectorDisplayTone.current => _ResultPalette.qqCyan,
      StateVectorDisplayTone.target => _ResultPalette.qqPurple,
    };
  }

  IconData get _summaryIcon {
    return switch (widget.tone) {
      StateVectorDisplayTone.current => Icons.timeline,
      StateVectorDisplayTone.target => Icons.flag_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final int vectorSize = 1 << widget.numQubits;
    final bool hasTarget = widget.targetStateVector != null &&
        widget.targetStateVector!.length == vectorSize;
    final bool compactSplitPanel =
        widget.dense && !widget.showHeader && widget.showToggleInSummary;
    final currentTerms = widget.tone == StateVectorDisplayTone.current
        ? formatQuantumStateTerms(
            widget.stateVector.take(vectorSize).toList(growable: false),
            numQubits: widget.numQubits,
          )
        : null;
    final rawAuthoredExpression = widget.tone == StateVectorDisplayTone.target
        ? widget.stateExpression?.trim()
        : null;
    final authoredExpression = rawAuthoredExpression?.isNotEmpty == true
        ? targetStateMathExpression(rawAuthoredExpression!)
        : null;

    final stateContent = LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.dense ? 4 : 6,
              vertical: widget.dense ? 1 : 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentTerms != null ||
                    (authoredExpression?.isNotEmpty ?? false))
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: widget.dense ? 4 : 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.stateExpressionLabel != null) ...[
                          Text(
                            widget.stateExpressionLabel!,
                            key: const ValueKey(
                              'target-state-semantic-label',
                            ),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: widget.dense ? 9.5 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: widget.dense ? 2 : 3),
                        ],
                        _StateExpressionLine(
                          currentTerms: currentTerms,
                          authoredExpression: authoredExpression,
                          dense: widget.dense,
                        ),
                      ],
                    ),
                  ),
                _buildProbabilityList(vectorSize, hasTarget),
              ],
            ),
          ),
        );
      },
    );
    final scrollableStateContent = Scrollbar(
      controller: _stateVectorVerticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _stateVectorVerticalScrollController,
        child: stateContent,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: widget.contentDriven ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (widget.showHeader) ...[
          _buildHeader(hasTarget),
          SizedBox(height: widget.dense ? 2 : 4),
        ],
        if (compactSplitPanel) ...[
          _buildStaticStateHeader(hasTarget),
          const SizedBox(height: 2),
        ],
        if (widget.contentDriven)
          stateContent
        else
          Expanded(child: scrollableStateContent),
      ],
    );
  }

  Widget _buildHeader(bool hasTarget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.titleOverride ??
                (hasTarget
                    ? 'Current State'
                    : widget.tone == StateVectorDisplayTone.target
                        ? 'Target State'
                        : 'Current Result'),
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
          children: [_buildStateVisibilityControl()],
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

      final bool nonZeroOnly = widget.nonZeroOnlyOverride ?? _nonZeroOnly;
      final bool shouldShow = !nonZeroOnly ||
          currentProbability > _probabilityThreshold ||
          targetProbability > _probabilityThreshold;

      if (shouldShow) {
        visibleIndexes.add(index);
      }
    }

    if (visibleIndexes.isEmpty) {
      visibleIndexes.add(strongestIndex);
    }

    return visibleIndexes;
  }

  Widget _buildStaticStateHeader(bool hasTarget) {
    return _StateSummarySection(
      title: widget.summaryTitleOverride ?? 'Current State',
      subtitle: widget.showSummarySubtitle ? _summarySubtitle(hasTarget) : null,
      icon: _summaryIcon,
      accent: _summaryAccent,
      dense: widget.dense,
      lightweightTypography: widget.lightweightTypography,
      decorated: false,
      showChips: false,
      toggle: widget.visibilityControlOverride ??
          (widget.showVisibilityControl
              ? _buildStateVisibilityControl()
              : null),
      chips: const [],
    );
  }

  String _summarySubtitle(bool hasTarget) {
    return widget.summarySubtitleOverride ??
        (hasTarget ? 'Measured from your circuit' : 'Live outcome');
  }

  Widget _buildProbabilityList(int vectorSize, bool hasTarget) {
    final List<int> visibleIndexes = _significantIndexes(vectorSize, hasTarget);
    final Color probabilityColor = widget.tone == StateVectorDisplayTone.target
        ? _ResultPalette.qqPurple
        : _ResultPalette.qqCyan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            color: probabilityColor,
            lightweightTypography: widget.lightweightTypography,
          );
        }),
      ],
    );
  }

  Widget _buildStateVisibilityControl() {
    final nonZeroOnly = widget.nonZeroOnlyOverride ?? _nonZeroOnly;
    void update(bool value) {
      if (widget.nonZeroOnlyOverride == null) {
        setState(() => _nonZeroOnly = value);
      }
      widget.onNonZeroOnlyChanged?.call(value);
      _resetStateScroll();
    }

    return InkWell(
      onTap: () => update(!nonZeroOnly),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: widget.dense ? 0.58 : 0.70,
            child: Checkbox(
              value: nonZeroOnly,
              onChanged: (v) => update(v ?? false),
              activeColor: _ResultPalette.qqCyan,
              checkColor: Colors.black,
              side: const BorderSide(color: Colors.white54, width: 1),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Text(
            'Non-zero only',
            style: TextStyle(
              color: Colors.white70,
              fontSize: widget.dense ? 8.6 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateExpressionLine extends StatefulWidget {
  final List<QuantumStateTerm>? currentTerms;
  final String? authoredExpression;
  final bool dense;

  const _StateExpressionLine({
    required this.currentTerms,
    required this.authoredExpression,
    required this.dense,
  });

  String get signature => currentTerms == null
      ? authoredExpression ?? ''
      : currentTerms!.map((term) => term.displayText).join();

  @override
  State<_StateExpressionLine> createState() => _StateExpressionLineState();
}

class _StateExpressionLineState extends State<_StateExpressionLine> {
  late final ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant _StateExpressionLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signature != widget.signature) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_horizontalScrollController.hasClients) {
          _horizontalScrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('state-expression-horizontal-scroll'),
      controller: _horizontalScrollController,
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.hardEdge,
      child: widget.currentTerms == null
          ? LatexText(
              math:
                  '\$${quantumStateNotationToLatex(widget.authoredExpression!)}\$',
              textStyle: _baseStyle,
              inlineMathColor: Colors.white,
              inlineMathHeight: widget.dense ? 13 : 15,
            )
          : RichText(
              key: const ValueKey('current-state-rich-text'),
              softWrap: false,
              text: TextSpan(
                style: _baseStyle,
                children: _currentStateSpans(widget.currentTerms!),
              ),
            ),
    );
  }

  TextStyle get _baseStyle => TextStyle(
        color: Colors.white,
        fontSize: widget.dense ? 11 : 12.5,
        fontWeight: FontWeight.w800,
        height: 1.1,
      );

  List<InlineSpan> _currentStateSpans(List<QuantumStateTerm> terms) {
    final spans = <InlineSpan>[const TextSpan(text: '|ψ⟩ = ')];
    if (terms.isEmpty) {
      spans.add(const TextSpan(text: '0'));
      return spans;
    }

    for (var index = 0; index < terms.length; index++) {
      if (index > 0) {
        spans.add(const TextSpan(text: ' + '));
      }
      final term = terms[index];
      if (!term.coefficientIsUnit) {
        spans.add(TextSpan(text: '(${term.formattedCoefficient})'));
      }
      spans.add(
        TextSpan(
          text: term.basisKet,
          style: const TextStyle(color: _ResultPalette.qqGreen),
        ),
      );
    }
    return spans;
  }
}

class _StateSummarySection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final List<Widget> chips;
  final bool dense;
  final Widget? toggle;
  final bool decorated;
  final bool showChips;
  final bool lightweightTypography;

  const _StateSummarySection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.chips,
    this.dense = false,
    this.toggle,
    this.decorated = true,
    this.showChips = true,
    this.lightweightTypography = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 4 : 8,
        vertical: dense ? 2 : 6,
      ),
      decoration: decorated
          ? BoxDecoration(
              color: _ResultPalette.qqInner,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _ResultPalette.qqBorderSoft),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: dense ? 14 : 18,
                height: dense ? 16 : 20,
                child: Icon(
                  icon,
                  color: accent.withValues(alpha: 0.72),
                  size: dense ? 12 : 15,
                ),
              ),
              SizedBox(width: dense ? 3 : 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: dense ? 10.8 : 12,
                        fontWeight: lightweightTypography
                            ? FontWeight.w500
                            : FontWeight.w800,
                      ),
                    ),
                    if (!dense) const SizedBox(height: 1),
                    if (subtitle != null) ...[
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF9BAAC4),
                          fontSize: dense ? 8.5 : 9.5,
                          fontWeight: lightweightTypography
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (toggle != null) ...[
                SizedBox(width: dense ? 2 : 6),
                toggle!,
              ],
            ],
          ),
          if (showChips) ...[
            SizedBox(height: dense ? 5 : 7),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: chips,
            ),
          ],
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
  final Color color;
  final bool lightweightTypography;

  const _ProbabilityRow({
    required this.ket,
    required this.probability,
    required this.targetProbability,
    required this.matched,
    required this.percentLabel,
    required this.targetPercentLabel,
    required this.color,
    this.lightweightTypography = false,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedProbability = probability.clamp(0, 1).toDouble();
    final double? clampedTargetProbability =
        targetProbability?.clamp(0, 1).toDouble();
    final double ketWidth = math.max(44, math.min(76, ket.length * 7.2 + 8));
    const double percentWidth = 46;
    const double matchIconWidth = 17;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: ketWidth,
                child: Text(
                  ket,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: lightweightTypography
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: _ProbabilityBar(
                  value: clampedProbability,
                  minHeight: 5,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: percentWidth,
                child: Text(
                  percentLabel,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: lightweightTypography
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: matchIconWidth,
                child: matched
                    ? const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.check_circle,
                          color: _ResultPalette.qqGreen,
                          size: 13,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          if (clampedTargetProbability != null &&
              targetPercentLabel != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                SizedBox(
                  width: ketWidth,
                  child: Text(
                    'Target',
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ),
                Expanded(
                  child: _ProbabilityBar(
                    value: clampedTargetProbability,
                    minHeight: 3,
                    color: _ResultPalette.qqPurple,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: percentWidth,
                  child: Text(
                    targetPercentLabel!,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                const SizedBox(width: matchIconWidth),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProbabilityBar extends StatelessWidget {
  final double value;
  final double minHeight;
  final Color color;

  const _ProbabilityBar({
    required this.value,
    required this.minHeight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedValue = value.clamp(0, 1).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        final double rawFillWidth = trackWidth * clampedValue;
        final double fillWidth = clampedValue <= 0
            ? 0
            : math.min(trackWidth, math.max(rawFillWidth, 4.0));

        return ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: minHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: _ResultPalette.qqInner2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: fillWidth,
                    height: minHeight,
                    child: ColoredBox(color: color),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
