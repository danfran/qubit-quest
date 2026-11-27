import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/qq_level.dart' show ValidationMode;
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/probability_format.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/qq_scientific_primitives.dart';
import 'package:quantumquiz/widgets/qubit_quest_workspace_primitives.dart';
import 'package:quantumquiz/widgets/state_amplitude_panel.dart';

/// What an explicit Check compares, in the learner's words (v2.6 M11D).
///
/// Derived only from the activity's existing [ValidationMode]; it never
/// suggests that matching probabilities is enough when amplitudes, phases
/// or the whole operator are checked.
String validationScopeNote(ValidationMode mode, int numQubits) {
  final inputs = 1 << numQubits;
  return switch (mode) {
    ValidationMode.finalState => 'Check compares every amplitude of your '
        'final state with the target exactly, including the global phase. '
        'Matching probabilities alone is not enough.',
    ValidationMode.physicalState => 'Check compares your final state with '
        'the target up to a global phase: every magnitude and relative '
        'phase must match. Matching probabilities alone is not enough.',
    ValidationMode.unitary => 'Check compares what your circuit does to all '
        '$inputs basis inputs (its whole operator, phases included) with '
        'the required transformation. The output for this one input is an '
        'example; matching it alone is not enough.',
  };
}

/// "Your circuit now" beside "Target" for Journey lessons and Mastery
/// circuit challenges (v2.6 M11D, M11B prototype 6).
///
/// Shows the learner's live state (expression and exact probabilities)
/// and, when the activity reveals it, the authored target with a dashed
/// outline of its probabilities on the same bars. The validation note
/// states the actual Check contract. Nothing here checks, completes or
/// explains a solution: Check remains the learner's explicit action.
class LessonStateComparison extends StatefulWidget {
  const LessonStateComparison({
    super.key,
    required this.currentState,
    required this.numQubits,
    required this.validationMode,
    this.targetState,
    this.targetLabel,
    this.targetExpression,
    this.nonZeroOnly,
    this.onNonZeroOnlyChanged,
  });

  final List<Complex> currentState;
  final int numQubits;
  final ValidationMode validationMode;

  /// The authored target vector; null when the activity hides its target.
  final List<Complex>? targetState;
  final String? targetLabel;
  final String? targetExpression;
  final bool? nonZeroOnly;
  final ValueChanged<bool>? onNonZeroOnlyChanged;

  /// Outcome rows listed before "Show all".
  static const int collapsedRows = 8;

  @override
  State<LessonStateComparison> createState() => _LessonStateComparisonState();
}

class _LessonStateComparisonState extends State<LessonStateComparison> {
  bool _allRows = false;
  bool _detailsOpen = false;

  static double _p(Complex c) =>
      (c.real * c.real + c.imaginary * c.imaginary).toDouble();

  String _ket(int i) =>
      '|${i.toRadixString(2).padLeft(widget.numQubits, '0')}⟩';

  bool get _operator => widget.validationMode == ValidationMode.unitary;

  @override
  Widget build(BuildContext context) {
    final n = widget.numQubits;
    final size = 1 << n;
    final current = [
      for (var i = 0; i < size; i++)
        i < widget.currentState.length ? widget.currentState[i] : Complex.zero()
    ];
    final target = widget.targetState;
    final hasTarget = target != null && target.length >= size;
    final rows = [
      for (var i = 0; i < size; i++)
        if (_p(current[i]) > probabilityZeroTolerance ||
            (hasTarget && _p(target[i]) > probabilityZeroTolerance))
          i,
    ];
    final collapsible = rows.length > LessonStateComparison.collapsedRows;
    final shown = collapsible && !_allRows
        ? rows.take(LessonStateComparison.collapsedRows).toList()
        : rows;
    final terms = formatQuantumStateTerms(current, numQubits: n);
    final order = '|${[for (var q = n - 1; q >= 0; q--) 'q$q'].join(' ')}⟩';
    final exprStyle = QqType.stateExpression.copyWith(fontSize: 19);

    final currentPanel = QqWorkspacePanel(
      key: const ValueKey('lesson-current-state'),
      label: 'Your circuit now',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          QqStateExpression(
            terms: terms,
            plainText: formatQuantumStateExpression(current, numQubits: n),
            collapsedTermCount: 6,
            style: exprStyle,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final tight = c.maxWidth < 420;
            return QqDataTable(
              key: const ValueKey('lesson-probability-rows'),
              rowMinHeight: 30,
              columnGap: tight ? 8 : 14,
              columns: [
                QqColumn('Outcome', width: (tight ? 28.0 : 46.0) + 10.5 * n),
                const QqColumn('', flex: 1),
                QqColumn('Now', width: tight ? 56 : 72, align: QqColumn.right),
                if (hasTarget)
                  QqColumn('Target',
                      width: tight ? 56 : 72, align: QqColumn.right),
              ],
              rows: [
                for (final i in shown)
                  QqTableRow(
                    key: ValueKey('lesson-outcome-$i'),
                    semanticsLabel: '${_ket(i)} probability '
                        '${formatProbability(_p(current[i]))}'
                        '${hasTarget ? ', target ${formatProbability(_p(target[i]))}' : ''}',
                    cells: [
                      Text(_ket(i),
                          style: QqType.table.copyWith(
                              color: QqType.ketColor,
                              fontWeight: FontWeight.w500)),
                      _TargetBar(
                        value: _p(current[i]),
                        target: hasTarget ? _p(target[i]) : null,
                      ),
                      Text(formatProbability(_p(current[i])),
                          style: QqType.numeric),
                      if (hasTarget)
                        Text(formatProbability(_p(target[i])),
                            key: ValueKey('lesson-target-percent-$i'),
                            style: QqType.numeric.copyWith(
                                color: QubitQuestColors.accentStrong)),
                    ],
                  ),
              ],
            );
          }),
          if (collapsible)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('lesson-outcomes-show-all'),
                onPressed: () => setState(() => _allRows = !_allRows),
                child: Text(_allRows
                    ? 'Show fewer outcomes'
                    : 'Show all ${rows.length} outcomes'),
              ),
            ),
          const SizedBox(height: 6),
          QqMeta(
            '${hasTarget ? 'Bars: now (filled) against the target (dashed). ' : ''}'
            'Exact probabilities in the Z basis · order $order'
            '${rows.length < size ? ' · outcomes with probability 0 in both are not listed' : ''}',
          ),
          const SizedBox(height: 10),
          QqDisclosure(
            key: const ValueKey('lesson-state-details'),
            toggleKey: const ValueKey('lesson-state-details-toggle'),
            title: 'State details',
            summary: 'amplitudes and decimals',
            initiallyExpanded: _detailsOpen,
            onChanged: (open) => _detailsOpen = open,
            child: QqCurrentStatePanel(
              key: const ValueKey('web-composer-current-state'),
              stateVector: current,
              numQubits: n,
              chromeless: true,
              nonZeroOnly: widget.nonZeroOnly,
              onNonZeroOnlyChanged: widget.onNonZeroOnlyChanged,
            ),
          ),
        ],
      ),
    );

    final targetPanel = QqWorkspacePanel(
      key: const ValueKey('lesson-target'),
      label: _operator ? 'Target for this input' : 'Target',
      color: QubitQuestSurfaces.work2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTarget) ...[
            if ((widget.targetLabel ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(widget.targetLabel!.trim(),
                    key: const ValueKey('lesson-target-label'),
                    style: QqType.meta),
              ),
            _targetExpression(target, exprStyle),
            const SizedBox(height: 12),
          ] else ...[
            const Text(
              'This activity does not show its target. Use the task and '
              'your results to decide when to check.',
              key: ValueKey('lesson-target-hidden'),
              style: QqType.body,
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: QubitQuestSurfaces.inset,
              borderRadius: QubitQuestRadii.control,
              border: Border.all(color: QubitQuestSurfaces.rule),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 8),
                  child: Icon(Icons.rule_rounded,
                      size: 16, color: QubitQuestColors.accentStrong),
                ),
                Expanded(
                  child: Text(
                    validationScopeNote(widget.validationMode, n),
                    key: const ValueKey('lesson-validation-scope'),
                    style: QqType.body.copyWith(fontSize: 13.5, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 760) {
        return Row(
          key: const ValueKey('lesson-state-comparison'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: currentPanel),
            const SizedBox(width: QqSpace.gap),
            Expanded(flex: 2, child: targetPanel),
          ],
        );
      }
      return Column(
        key: const ValueKey('lesson-state-comparison'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          currentPanel,
          const SizedBox(height: QqSpace.gap),
          targetPanel,
        ],
      );
    });
  }

  /// The target typeset exactly like the current state (same component,
  /// size and wrapping; target-coloured kets), from the authored target
  /// vector. An authored expression is kept unchanged beneath it, since it
  /// may name a form the formatter cannot (such as |−⟩ ⊗ (…)).
  Widget _targetExpression(List<Complex> target, TextStyle style) {
    final size = 1 << widget.numQubits;
    final vector = target.take(size).toList(growable: false);
    final authored = (widget.targetExpression ?? '').trim();
    String plain(String t) => t
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll('>', '⟩')
        .replaceAll('\\rangle', '⟩')
        .replaceAll('-', '−');
    // The authored form is shown only when it says something the typeset
    // vector does not (a factored or named form).
    final formatted = formatQuantumStateExpression(vector,
            numQubits: widget.numQubits, stateLabel: '')
        .replaceFirst(' = ', '');
    final showAuthored = authored.isNotEmpty &&
        plain(targetStateMathExpression(authored)) != plain(formatted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        QqStateExpression(
          key: const ValueKey('lesson-target-expression'),
          terms: formatQuantumStateTerms(vector, numQubits: widget.numQubits),
          plainText: formatQuantumStateExpression(vector,
              numQubits: widget.numQubits, stateLabel: '|ψ_target⟩'),
          stateLabel: '|ψ_target⟩',
          collapsedTermCount: 6,
          style: style,
          ketColor: QubitQuestColors.accentStrong,
        ),
        if (showAuthored) ...[
          const SizedBox(height: 8),
          const Text('As written in the activity', style: QqType.meta),
          const SizedBox(height: 2),
          SingleChildScrollView(
            key: const ValueKey('lesson-target-authored'),
            scrollDirection: Axis.horizontal,
            child: LatexText(
              math:
                  '\$${quantumStateNotationToLatex(targetStateMathExpression(authored))}\$',
              textStyle: style,
              inlineMathColor: QubitQuestColors.textBody,
              mathFontSize: 17,
            ),
          ),
        ],
      ],
    );
  }
}

/// The learner's probability on a fixed 0–100% track, with the target's
/// probability as a dashed outline on the same scale.
class _TargetBar extends StatelessWidget {
  const _TargetBar({required this.value, this.target});
  final double value;
  final double? target;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 12,
        child: CustomPaint(
          painter: _TargetBarPainter(value.clamp(0.0, 1.0),
              target == null ? null : target!.clamp(0.0, 1.0)),
          size: Size.infinite,
        ),
      );
}

class _TargetBarPainter extends CustomPainter {
  _TargetBarPainter(this.value, this.target);
  final double value;
  final double? target;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(4);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, radius),
        Paint()..color = const Color(0x14FFFFFF));
    if (value > 0) {
      final w = (size.width * value).clamp(2.0, size.width);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, size.height), radius),
          Paint()..color = QubitQuestColors.accentInteractive);
    }
    final t = target;
    if (t == null) return;
    final paint = Paint()
      ..color = QubitQuestColors.accentStrong
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final w = size.width * t;
    if (w <= 0) {
      // Target 0: a short dashed tick at the origin.
      _dash(canvas, const Offset(1, 0), Offset(1, size.height), paint);
      return;
    }
    final r = Rect.fromLTWH(0.7, 0.7, w - 1.4, size.height - 1.4);
    _dash(canvas, r.topLeft, r.topRight, paint);
    _dash(canvas, r.bottomLeft, r.bottomRight, paint);
    _dash(canvas, r.topRight, r.bottomRight, paint);
    _dash(canvas, r.topLeft, r.bottomLeft, paint);
  }

  void _dash(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total < .5) return;
    final u = (b - a) / total;
    for (var d = 0.0; d < total; d += 6) {
      canvas.drawLine(a + u * d, a + u * (d + 3.5).clamp(0, total), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TargetBarPainter old) =>
      old.value != value || old.target != target;
}
