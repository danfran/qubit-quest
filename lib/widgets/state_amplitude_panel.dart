import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantumquiz/models/bloch_lab.dart' show blochComplex;
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/named_state_recognition.dart';
import 'package:quantumquiz/utils/probability_format.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/qq_scientific_primitives.dart';
import 'package:quantumquiz/widgets/qubit_quest_workspace_primitives.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart'
    show defaultNonZeroOnlyForQubitCount;

/// How amplitudes are written and rounded (shared by every host that shows
/// amplitudes: Composer, lessons, Bloch Explorer).
const String qqAmplitudePrecisionNote =
    'Amplitudes are written exactly (such as 1/√2 or 3/8 − i/8) when the '
    'value is recognised, otherwise as decimals rounded to four places, '
    'and an expression with a rounded coefficient is written with ≈. '
    'Rounding affects the display only; the simulation keeps full '
    'precision, including every phase. A global phase (one factor shared '
    'by every amplitude) is kept as calculated: it does not change any '
    'measurement. A recognised state (such as |+⟩ or |Φ⁺⟩) is named only '
    'when the state equals it, up to the phase shown, within 10⁻⁶ in every '
    'amplitude, the precision of the simulation; it is written with = only '
    'when every coefficient is exact.';

/// The Current State component (v2.6 M11C.1).
///
/// Reading order: one heading with its actions (filter, copy); the state
/// expression, prominent; a recognised textbook state when the vector
/// equals one up to a global phase (shown as an equation, never instead of
/// the vector); compact metadata; the amplitude table; collapsed
/// background on precision.
///
/// Every value comes from [stateVector] through the shared formatters
/// ([formatQuantumStateTerms], [formatQuantumAmplitude],
/// [formatQuantumStateExpression]); nothing is rounded into the data, and
/// Copy copies the same complete expression as before.
class QqCurrentStatePanel extends StatefulWidget {
  const QqCurrentStatePanel({
    super.key,
    required this.stateVector,
    required this.numQubits,
    this.title = 'Current state',
    this.stateLabel = '|ψ⟩',
    this.nonZeroOnly,
    this.onNonZeroOnlyChanged,
    this.showProbabilities = false,
    this.contextNote,
    this.precisionOpen = false,
    this.onPrecisionChanged,
    this.chromeless = false,
    this.expressionOnly = false,
    this.expressionStyle = QqType.stateExpression,
  });

  /// Only the expression and its recognised-state line (v2.6 M11G): no
  /// metadata, amplitude table or precision note. For hosts that show the
  /// amplitudes elsewhere (the Bloch Explorer's disclosures, a gate
  /// preview).
  final bool expressionOnly;

  /// Expression text style (a smaller size for previews).
  final TextStyle expressionStyle;

  /// Content without its own panel, for hosts that already frame it (a
  /// lesson's "State details" disclosure).
  final bool chromeless;

  final List<Complex> stateVector;
  final int numQubits;
  final String title;
  final String stateLabel;

  /// Null: the shared default (non-zero only from three qubits).
  final bool? nonZeroOnly;
  final ValueChanged<bool>? onNonZeroOnlyChanged;

  /// Adds an exact-probability column, for hosts that have no separate
  /// probability component. The Composer analysis leaves it off.
  final bool showProbabilities;

  /// A short qualifier under the heading (e.g. the pre-measurement note).
  final String? contextNote;

  final bool precisionOpen;
  final ValueChanged<bool>? onPrecisionChanged;

  /// Rows listed before "Show all" (the full table is one tap away).
  static const int collapsedRowCount = 16;

  /// Terms written before "+ … n more terms".
  static const int collapsedTermCount = 8;

  @override
  State<QqCurrentStatePanel> createState() => _QqCurrentStatePanelState();
}

class _QqCurrentStatePanelState extends State<QqCurrentStatePanel> {
  bool? _localNonZeroOnly;
  bool _allRows = false;
  bool _copied = false;

  /// Same threshold as the expression, so table and expression agree.
  static const double _zero = 1e-9;

  bool get _nonZeroOnly =>
      widget.nonZeroOnly ??
      _localNonZeroOnly ??
      defaultNonZeroOnlyForQubitCount(widget.numQubits);

  void _setNonZeroOnly(bool value) {
    setState(() {
      _localNonZeroOnly = value;
      _allRows = false;
    });
    widget.onNonZeroOnlyChanged?.call(value);
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _copied = false);
  }

  String _ket(int index) =>
      '|${index.toRadixString(2).padLeft(widget.numQubits, '0')}⟩';

  @override
  Widget build(BuildContext context) {
    final n = widget.numQubits;
    final size = 1 << n;
    final vector = [
      for (var i = 0; i < size; i++)
        i < widget.stateVector.length ? widget.stateVector[i] : Complex.zero(),
    ];
    final terms = formatQuantumStateTerms(vector, numQubits: n);
    final full = formatQuantumStateExpression(vector,
        numQubits: n, stateLabel: widget.stateLabel);
    double p(Complex c) =>
        (c.real * c.real + c.imaginary * c.imaginary).toDouble();
    final total = vector.fold<double>(0, (s, a) => s + p(a));
    final named = recogniseNamedState(vector, n);
    // A rounded coefficient makes the expression, and any recognised state
    // written after it, an approximation (M11G): ≈, never =.
    final approximate = quantumTermsAreApproximate(terms);
    final nonZeroOnly = _nonZeroOnly;
    final visible = [
      for (var i = 0; i < size; i++)
        if (!nonZeroOnly || vector[i].magnitude > _zero) i,
    ];
    if (visible.isEmpty) visible.add(0);
    final hiddenZeros = size - visible.length;
    final amplitudes = {
      for (final i in visible) i: formatQuantumAmplitude(vector[i])
    };
    // A decimal column only where it adds information: when some visible
    // amplitude is written exactly (a fraction or a root).
    final showDecimal =
        amplitudes.values.any((a) => a.contains('/') || a.contains('√'));
    final collapsible = visible.length > QqCurrentStatePanel.collapsedRowCount;
    final shownRows = collapsible && !_allRows
        ? visible.take(QqCurrentStatePanel.collapsedRowCount).toList()
        : visible;
    final order = '|${[for (var q = n - 1; q >= 0; q--) 'q$q'].join(' ')}⟩';
    // A reliably recognised dense state (|+⟩^⊗n) is shown compactly first;
    // its expansion and amplitude table stay one tap away (v2.6 M11D).
    final compact = named != null &&
        named.superscript != null &&
        terms.length > QqCurrentStatePanel.collapsedTermCount;

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (n >= 2) ...[
          QqToggleChip(
            key: const ValueKey('state-nonzero-toggle'),
            label: 'Non-zero only',
            tooltip: 'List only basis states with a non-zero amplitude',
            value: nonZeroOnly,
            onChanged: _setNonZeroOnly,
          ),
          const SizedBox(width: 6),
        ],
        QqIconAction(
          key: const ValueKey('state-expression-copy'),
          icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
          tooltip: _copied ? 'Copied' : 'Copy the complete state',
          onPressed: () => _copy(full),
        ),
      ],
    );

    Widget amplitudeText(int i) => Text(amplitudes[i]!,
        key: ValueKey('state-amplitude-$i'),
        softWrap: false,
        style: QqType.table.copyWith(
            color: vector[i].magnitude > _zero
                ? QubitQuestColors.textPrimary
                : QubitQuestColors.textMuted));
    String decimal(int i) =>
        vector[i].magnitude > _zero ? blochComplex(vector[i]) : '0';
    Widget decimalText(int i, {TextStyle? style}) => Text(decimal(i),
        key: ValueKey('state-decimal-$i'),
        softWrap: false,
        style:
            style ?? QqType.table.copyWith(color: QubitQuestColors.textBody));
    String rowLabel(int i) => '${_ket(i)} amplitude ${amplitudes[i]}'
        '${showDecimal ? ', decimal ${decimal(i)}' : ''}'
        '${widget.showProbabilities ? ', probability ${formatProbability(p(vector[i]))}' : ''}';
    final ketStyle = QqType.table
        .copyWith(color: QqType.ketColor, fontWeight: FontWeight.w500);

    // Narrow hosts (phones, a 390 px sheet): the decimal sits under its
    // amplitude in the same cell instead of being squeezed into a column.
    // Deliberate column widths from the widest value (v2.6 M11D): the
    // decimal sits next to its symbolic amplitude instead of at the far
    // edge of a wide panel; a trailing spacer takes the rest.
    final base = DefaultTextStyle.of(context).style.merge(QqType.table);
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text) => (TextPainter(
          text: TextSpan(text: text, style: base),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout())
            .width;
    double widest(Iterable<String> texts) =>
        texts.map(measure).fold(0.0, (a, b) => a > b ? a : b);
    final basisWidth = 40.0 + 10.5 * n + 24;
    final ampWidth =
        widest(['Amplitude', for (final i in shownRows) amplitudes[i]!])
                .clamp(70.0, 300.0) +
            24;
    final decWidth = widest(['Decimal', for (final i in shownRows) decimal(i)])
            .clamp(60.0, 260.0) +
        8;
    final table = LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 520;
      final fixedTotal = basisWidth +
          ampWidth +
          (showDecimal ? decWidth + 16 : 0) +
          (widget.showProbabilities ? 100 : 0) +
          32;
      final measured = !narrow && fixedTotal <= constraints.maxWidth;
      return QqDataTable(
        headerKey: const ValueKey('state-basis-table-header'),
        columns: [
          QqColumn('Basis state', width: basisWidth),
          if (measured)
            QqColumn('Amplitude', width: ampWidth)
          else
            QqColumn(
                narrow && showDecimal ? 'Amplitude · decimal' : 'Amplitude',
                flex: 5),
          if (showDecimal && !narrow)
            measured
                ? QqColumn('Decimal', width: decWidth, align: QqColumn.right)
                : const QqColumn('Decimal', flex: 4, align: QqColumn.right),
          if (widget.showProbabilities)
            const QqColumn('Probability', width: 84, align: QqColumn.right),
          if (measured) const QqColumn('', flex: 1),
        ],
        rows: [
          for (final i in shownRows)
            QqTableRow(
              key: ValueKey('state-row-$i'),
              semanticsLabel: rowLabel(i),
              cells: [
                Text(_ket(i), style: ketStyle),
                if (narrow && showDecimal)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Scrollable(amplitudeText(i)),
                      _Scrollable(decimalText(i,
                          style: QqType.meta
                              .copyWith(fontFeatures: QqType.tabular))),
                    ],
                  )
                else
                  _Scrollable(amplitudeText(i)),
                if (showDecimal && !narrow)
                  _Scrollable(decimalText(i), alignEnd: true),
                if (widget.showProbabilities)
                  Text(formatProbability(p(vector[i])), style: QqType.table),
                if (measured) const SizedBox.shrink(),
              ],
            ),
        ],
      );
    });

    Widget tableBlock() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            table,
            if (collapsible || hiddenZeros > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    if (hiddenZeros > 0)
                      QqMeta(
                        '$hiddenZeros zero amplitude'
                        '${hiddenZeros == 1 ? '' : 's'} hidden',
                        key: const ValueKey('state-zero-hidden'),
                      ),
                    if (hiddenZeros > 0)
                      TextButton(
                        key: const ValueKey('state-show-zero'),
                        onPressed: () => _setNonZeroOnly(false),
                        child: const Text('Show all basis states'),
                      ),
                    if (collapsible)
                      TextButton(
                        key: const ValueKey('state-table-show-all'),
                        onPressed: () => setState(() => _allRows = !_allRows),
                        child: Text(_allRows
                            ? 'Show first ${QqCurrentStatePanel.collapsedRowCount} rows'
                            : 'Show all ${visible.length} rows'),
                      ),
                  ],
                ),
              ),
          ],
        );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.contextNote case final note?) ...[
          QqMeta(note),
          const SizedBox(height: 8),
        ],
        if (compact) ...[
          _NamedStateLine(
              named: named,
              stateLabel: widget.stateLabel,
              approximate: approximate),
          const SizedBox(height: 6),
          _UniformSum(named: named, numQubits: n),
        ] else ...[
          QqStateExpression(
            terms: terms,
            stateLabel: widget.stateLabel,
            plainText: full,
            collapsedTermCount: QqCurrentStatePanel.collapsedTermCount,
            style: widget.expressionStyle,
          ),
          if (named != null && terms.length > 1) ...[
            const SizedBox(height: 4),
            _NamedStateLine(
                named: named,
                approximate: approximate,
                style: widget.expressionStyle),
          ],
        ],
        if (!widget.expressionOnly) ...[
          const SizedBox(height: 10),
          QqMeta(
            '${terms.length} of $size amplitude${size == 1 ? '' : 's'} '
            'non-zero · total probability ${formatProbability(total)} · '
            'order $order',
            key: const ValueKey('state-nonzero-count'),
          ),
          if ((total - 1).abs() > 1e-6)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'This state is not normalised (total probability '
                '${total.toStringAsFixed(6)}); values are shown as '
                'calculated.',
                key: const ValueKey('state-not-normalised'),
                style: QqType.meta.copyWith(color: QubitQuestColors.warning),
              ),
            ),
          const SizedBox(height: QqSpace.gap),
          if (compact) ...[
            QqDisclosure(
              key: const ValueKey('state-expanded-disclosure'),
              toggleKey: const ValueKey('state-expanded-toggle'),
              title: 'Expanded expression',
              summary: '${terms.length} terms',
              child: QqStateExpression(
                terms: terms,
                stateLabel: widget.stateLabel,
                plainText: full,
                collapsedTermCount: QqCurrentStatePanel.collapsedTermCount,
                style: QqType.stateExpression.copyWith(fontSize: 18),
              ),
            ),
            QqDisclosure(
              key: const ValueKey('state-table-disclosure'),
              toggleKey: const ValueKey('state-table-toggle'),
              title: 'Amplitude table',
              summary: '${visible.length} rows',
              child: tableBlock(),
            ),
          ] else
            tableBlock(),
          const SizedBox(height: 12),
          QqDisclosure(
            key: const ValueKey('state-precision-disclosure'),
            toggleKey: const ValueKey('state-precision-toggle'),
            title: 'About amplitude precision',
            summary: 'exact values and rounding',
            initiallyExpanded: widget.precisionOpen,
            onChanged: widget.onPrecisionChanged,
            child: const Text(
              qqAmplitudePrecisionNote,
              key: ValueKey('composer-analysis-precision-note'),
            ),
          ),
        ],
      ],
    );
    if (widget.expressionOnly) return body;
    if (widget.chromeless) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(alignment: Alignment.centerRight, child: actions),
          body,
        ],
      );
    }
    return QqWorkspacePanel(
      label: widget.title,
      trailing: actions,
      child: body,
    );
  }
}

/// A table cell that scrolls sideways rather than clipping a long value.
class _Scrollable extends StatelessWidget {
  const _Scrollable(this.child, {this.alignEnd = false});
  final Widget child;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: alignEnd,
        child: child,
      );
}

/// "= i|+⟩  plus state · global phase π/2": the recognised state as an
/// exact equation including its global phase.
class _NamedStateLine extends StatelessWidget {
  const _NamedStateLine({
    required this.named,
    this.stateLabel,
    this.approximate = false,
    this.style = QqType.stateExpression,
  });
  final NamedState named;

  /// The expression has rounded coefficients: the state is recognised
  /// within tolerance, which is not an exact equality (≈).
  final bool approximate;
  final TextStyle style;

  /// Written before the equals sign when this line *is* the expression
  /// (compact form); otherwise the line continues the expression above.
  final String? stateLabel;

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    final small = style.copyWith(fontSize: 13, height: 1);
    final prefix = named.phasePrefix;
    final relation = approximate || !named.isExact ? '≈' : '=';
    final ket = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(named.symbol, style: style.copyWith(color: QqType.ketColor)),
        if (named.superscript case final sup?)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(sup, style: small.copyWith(color: QqType.ketColor)),
          ),
      ],
    );
    return Semantics(
      label: 'Recognised: ${named.name}, ${named.plainText}'
          '${named.hasGlobalPhase ? ', global phase ${named.phaseText}' : ''}',
      excludeSemantics: true,
      child: Wrap(
        key: const ValueKey('state-named'),
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 2,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stateLabel == null ? '$relation ' : '$stateLabel $relation ',
                  key: const ValueKey('state-named-relation'), style: style),
              if (prefix != null)
                Text(prefix, style: style)
              else ...[
                Text('e', style: style),
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 1),
                  child: Text(named.phaseExponent, style: small),
                ),
              ],
              ket,
            ],
          ),
          QqMeta(
            named.hasGlobalPhase
                ? '${named.name} · global phase ${named.phaseText}, '
                    'not observable on its own'
                : named.name,
            key: const ValueKey('state-named-caption'),
          ),
        ],
      ),
    );
  }
}

/// The state written as a sum of basis terms, wrapping only between whole
/// terms. Coefficients come from the shared formatter; a simple fraction
/// (1/√2, i/√2, 3/8) is typeset stacked, compound complex coefficients keep
/// their brackets. Long states show their first terms and say how many
/// follow; the complete expression is one tap away and is what Copy and
/// assistive technology receive.
class QqStateExpression extends StatefulWidget {
  const QqStateExpression({
    super.key,
    required this.terms,
    required this.plainText,
    this.stateLabel = '|ψ⟩',
    this.collapsedTermCount = 8,
    this.style = QqType.stateExpression,
    this.ketColor = QqType.ketColor,
  });

  /// Basis-ket colour: green for a current state, the target colour for a
  /// target (M11D.1), so the two read as different states at equal size.
  final Color ketColor;

  final List<QuantumStateTerm> terms;

  /// The complete expression as text (copy and semantics).
  final String plainText;
  final String stateLabel;
  final int collapsedTermCount;
  final TextStyle style;

  @override
  State<QqStateExpression> createState() => _QqStateExpressionState();
}

class _QqStateExpressionState extends State<QqStateExpression> {
  bool _expanded = false;

  static final _fraction = RegExp(r'^(−?)([^/\s]+)/([^/\s]+)$');
  static final _operator = RegExp(r' ([+−]) ');

  Widget _fractionWidget(String numerator, String denominator) {
    final style = widget.style;
    final small = style.copyWith(fontSize: style.fontSize! * .66, height: 1.1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(numerator, textAlign: TextAlign.center, style: small),
            Container(
              height: 1.3,
              margin: const EdgeInsets.symmetric(vertical: 2),
              color: style.color,
            ),
            Text(denominator, textAlign: TextAlign.center, style: small),
          ],
        ),
      ),
    );
  }

  /// One coefficient part ("1/√2", "−i/8", "0.4001").
  List<Widget> _part(String text) {
    final m = _fraction.firstMatch(text);
    if (m == null) return [Text(text, style: widget.style)];
    return [
      if (m.group(1)!.isNotEmpty) Text('−', style: widget.style),
      _fractionWidget(m.group(2)!, m.group(3)!),
    ];
  }

  List<Widget> _coefficient(String display) {
    if (display.isEmpty) return const [];
    final bracketed = display.startsWith('(') && display.endsWith(')');
    final inner =
        bracketed ? display.substring(1, display.length - 1) : display;
    final pieces = <Widget>[];
    var start = 0;
    final ops = _operator.allMatches(inner).toList();
    for (final op in ops) {
      pieces.addAll(_part(inner.substring(start, op.start)));
      pieces.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(op.group(1)!, style: widget.style),
      ));
      start = op.end;
    }
    pieces.addAll(_part(inner.substring(start)));
    // A single part needs no brackets: a stacked fraction or a plain
    // number already has an unambiguous extent.
    if (ops.isEmpty) return pieces;
    final hasFraction = inner.split(_operator).any(_fraction.hasMatch);
    final bracket = widget.style.copyWith(
      fontSize: widget.style.fontSize! * (hasFraction ? 1.45 : 1),
      fontWeight: FontWeight.w300,
      height: 1,
      color: QubitQuestColors.textMuted,
    );
    return [Text('(', style: bracket), ...pieces, Text(')', style: bracket)];
  }

  Widget _term(QuantumStateTerm term, {required bool first}) {
    final sep = term.separator(first: first).trim();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sep.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(right: first ? 1 : 6),
            child: Text(sep, style: widget.style),
          ),
        ..._coefficient(term.coefficientDisplay),
        const SizedBox(width: 2),
        Text(term.basisKet,
            style: widget.style.copyWith(color: widget.ketColor)),
      ],
    );
  }

  /// "|ψ⟩ =", with a written subscript for labels such as |ψ_pre⟩.
  Widget _label() {
    final label = widget.stateLabel;
    final match = RegExp(r'^\|(.+)_([^⟩]+)⟩$').firstMatch(label);
    final relation = quantumTermsAreApproximate(widget.terms) ? '≈' : '=';
    if (match == null) return Text('$label $relation', style: widget.style);
    final sub = widget.style.copyWith(
        fontSize: widget.style.fontSize! * .6,
        color: QubitQuestColors.textBody);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('|${match.group(1)}', style: widget.style),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(match.group(2)!, style: sub),
        ),
        Text('⟩ $relation', style: widget.style),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final terms = widget.terms;
    final limit = widget.collapsedTermCount;
    final collapsible = terms.length > limit;
    final shown = collapsible && !_expanded ? terms.take(limit) : terms;
    final hidden = terms.length - shown.length;
    return Semantics(
      label: widget.plainText,
      child: Column(
        key: const ValueKey('state-expression-wrapped'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _label(),
                if (terms.isEmpty) Text('0', style: widget.style),
                for (final (i, term) in shown.indexed)
                  _term(term, first: i == 0),
                if (hidden > 0)
                  Text(
                    '+ … $hidden more term${hidden == 1 ? '' : 's'}',
                    key: const ValueKey('state-expression-abbreviated'),
                    style: widget.style.copyWith(
                        color: QubitQuestColors.textMuted,
                        fontSize: widget.style.fontSize! * .8),
                  ),
              ],
            ),
          ),
          if (collapsible)
            TextButton(
              key: const ValueKey('state-expression-expand'),
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(_expanded
                  ? 'Show fewer terms'
                  : 'Show all ${terms.length} terms'),
            ),
        ],
      ),
    );
  }
}

/// "= (1/√32) Σₓ |x⟩": the uniform superposition in summation notation,
/// with its global phase factor, over every basis state of the register.
class _UniformSum extends StatelessWidget {
  const _UniformSum({required this.named, required this.numQubits});
  final NamedState named;
  final int numQubits;

  @override
  Widget build(BuildContext context) {
    const style = QqType.stateExpression;
    final count = 1 << numQubits;
    final prefix = named.phasePrefix;
    final small = style.copyWith(fontSize: 13, height: 1);
    final first = '|${'0' * numQubits}⟩';
    final last = '|${'1' * numQubits}⟩';
    return Wrap(
      key: const ValueKey('state-compact-sum'),
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('= ', style: style),
            if (prefix != null && prefix.isNotEmpty)
              Text(prefix, style: style)
            else if (prefix == null) ...[
              Text('e', style: style),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(named.phaseExponent, style: small),
              ),
            ],
            QqFraction(numerator: '1', denominator: '√$count', style: style),
            const SizedBox(width: 4),
            Text('Σ', style: style.copyWith(fontSize: 26)),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text('x', style: small),
            ),
            const SizedBox(width: 4),
            Text('|x⟩', style: style.copyWith(color: QqType.ketColor)),
          ],
        ),
        QqMeta('sum over all $count basis states x = $first … $last'),
      ],
    );
  }
}

/// A stacked fraction in the expression style (numerator over a rule over
/// the denominator), sized from [style].
class QqFraction extends StatelessWidget {
  const QqFraction({
    super.key,
    required this.numerator,
    required this.denominator,
    this.style = QqType.stateExpression,
  });
  final String numerator;
  final String denominator;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final small = style.copyWith(fontSize: style.fontSize! * .66, height: 1.1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(numerator, textAlign: TextAlign.center, style: small),
            Container(
              height: 1.3,
              margin: const EdgeInsets.symmetric(vertical: 2),
              color: style.color,
            ),
            Text(denominator, textAlign: TextAlign.center, style: small),
          ],
        ),
      ),
    );
  }
}
