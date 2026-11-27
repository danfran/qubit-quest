import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/models/measurement_distribution.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/probability_format.dart';
import 'package:quantumquiz/widgets/qq_scientific_primitives.dart';
import 'package:quantumquiz/widgets/qubit_quest_workspace_primitives.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';

/// The Measure tab (v2.6 M4): the environment for comparing theory with
/// sampled outcomes. In order:
///
/// 1. measurement configuration (explicit M operations and their classical
///    bits, or final-state sampling of every qubit);
/// 2. Run once, and Run shots with its own shot count (1–10,000, presets);
/// 3. the latest single-run outcome;
/// 4. the exact-versus-observed distribution ([exact] is available before
///    any shots; observed columns appear only after Run shots);
/// 5. the conditional state after the single run, when the run executed
///    explicit measurements;
/// 6. a short explanation.
///
/// Every number comes from the session: [exact] from
/// `ComposerSession.exactDistribution`, results from its runs. The panel
/// computes nothing scientific itself beyond count / shots.
class MeasuredCircuitRunPanel extends StatefulWidget {
  const MeasuredCircuitRunPanel({
    super.key,
    required this.measurements,
    required this.numQubits,
    required this.running,
    required this.shots,
    required this.onShotsChanged,
    required this.onRunOnce,
    required this.onRunShots,
    this.singleShot,
    this.shotsResult,
    this.error,
    this.exact,
    this.splitLayout = false,
  });

  /// Laboratory Composer (v2.6 M11C): from 760 px the experiment set-up,
  /// run controls and single run sit in a left column and the outcome
  /// distribution gets the remaining width. Content and order are otherwise
  /// unchanged; narrower hosts keep the single column.
  final bool splitLayout;

  /// The exact distribution of this experiment (null: not shown, for hosts
  /// that have not adopted M4).
  final ExactMeasurementDistribution? exact;

  /// Empty for circuits without M operations: the panel then runs
  /// final-state sampling and words itself accordingly.
  final List<MeasureZOperation> measurements;
  final int numQubits;
  final bool running;

  /// The validated shot count, or null while the typed value is invalid.
  final int? shots;

  /// Called with the parsed count, or null when the input is rejected.
  final ValueChanged<int?> onShotsChanged;
  final VoidCallback onRunOnce;
  final VoidCallback onRunShots;
  final SingleShotOutcome? singleShot;
  final ShotsOutcome? shotsResult;
  final String? error;

  @override
  State<MeasuredCircuitRunPanel> createState() =>
      _MeasuredCircuitRunPanelState();
}

class _MeasuredCircuitRunPanelState extends State<MeasuredCircuitRunPanel> {
  static final _compact = FilledButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    minimumSize: const Size(0, 42),
    textStyle: QqType.control,
  );
  static final _secondary = OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    minimumSize: const Size(0, 40),
    textStyle: QqType.control,
    side: const BorderSide(color: QubitQuestColors.border),
  );
  final _singleKey = GlobalKey();
  final _shotsKey = GlobalKey();
  final _errorKey = GlobalKey();
  late final TextEditingController _shotText =
      TextEditingController(text: widget.shots?.toString() ?? '');
  String? _shotError;
  OutcomeFilter _filter = OutcomeFilter.possibleOrObserved;

  @override
  void initState() {
    super.initState();
    _shotError = MeasuredCircuitRunner.parseShots(_shotText.text).error;
  }

  @override
  void didUpdateWidget(covariant MeasuredCircuitRunPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shots = widget.shots;
    if (shots != null &&
        shots != MeasuredCircuitRunner.parseShots(_shotText.text).shots) {
      _shotText.text = '$shots';
      _shotError = null;
    }
    if (widget.error != null && widget.error != oldWidget.error) {
      _reveal(_errorKey);
    } else if (widget.shotsResult != null &&
        !identical(widget.shotsResult, oldWidget.shotsResult)) {
      _reveal(_shotsKey);
    } else if (widget.singleShot != null &&
        !identical(widget.singleShot, oldWidget.singleShot)) {
      _reveal(_singleKey);
    }
  }

  @override
  void dispose() {
    _shotText.dispose();
    super.dispose();
  }

  /// Brings a freshly rendered section into view within the **nearest**
  /// scroll view only (the Inspector card's own scroll on wide layouts, the
  /// page when stacked), so the circuit never moves on wide layouts: its
  /// bottom first, then its top if it is taller than the viewport.
  void _reveal(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final target = key.currentContext;
      if (!mounted || target == null || !target.mounted) return;
      final duration = MediaQuery.maybeDisableAnimationsOf(context) ?? false
          ? Duration.zero
          : const Duration(milliseconds: 250);
      for (final policy in [
        ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ]) {
        if (!target.mounted) return;
        final scrollable = Scrollable.maybeOf(target);
        final object = target.findRenderObject();
        if (scrollable == null || object == null) return;
        await scrollable.position.ensureVisible(
          object,
          duration: duration,
          curve: Curves.easeOutCubic,
          alignmentPolicy: policy,
        );
      }
    });
  }

  void _shotsTyped(String text) {
    final parsed = MeasuredCircuitRunner.parseShots(text);
    setState(() => _shotError = parsed.error);
    widget.onShotsChanged(parsed.shots);
  }

  void _presetChosen(int value) {
    _shotText.text = '$value';
    _shotsTyped(_shotText.text);
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    final running = widget.running;
    final canRunShots = !running && widget.shots != null;
    final errorColor = Theme.of(context).colorScheme.error;
    final finalState = widget.measurements.isEmpty;
    final single = widget.singleShot;
    final observed = widget.shotsResult;
    final exact = widget.exact;
    final setup = <Widget>[
      _MeasurementConfiguration(
        finalState: finalState,
        numQubits: widget.numQubits,
        measurements: widget.measurements,
      ),
      const SizedBox(height: 16),
      // The shot count belongs to Run shots: same row, never wrapped away.
      Row(
        key: const ValueKey('web-sandbox-run-shots-row'),
        children: [
          // Under large text the label shortens rather than overflowing.
          Flexible(
            flex: 3,
            child: FilledButton.icon(
              key: const ValueKey('web-sandbox-run-shots'),
              style: _compact,
              onPressed: canRunShots ? widget.onRunShots : null,
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: const Text(
                'Run shots',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96, maxWidth: 132),
              child: TextField(
                key: const ValueKey('web-sandbox-shot-count'),
                controller: _shotText,
                enabled: !running,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onChanged: _shotsTyped,
                onSubmitted: (_) {
                  if (canRunShots) widget.onRunShots();
                },
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Shots',
                  hintText: '1–10,000',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                  enabledBorder: _shotError == null
                      ? null
                      : OutlineInputBorder(
                          borderSide: BorderSide(color: errorColor),
                        ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  suffixIcon: PopupMenuButton<int>(
                    key: const ValueKey('web-sandbox-shot-presets'),
                    enabled: !running,
                    tooltip: 'Shot presets',
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    onSelected: _presetChosen,
                    itemBuilder: (context) => [
                      for (final option in MeasuredCircuitRunner.shotOptions)
                        PopupMenuItem(
                          key: ValueKey('web-sandbox-shot-preset-$option'),
                          value: option,
                          child: Text('${formatCount(option)} shots'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        key: const ValueKey('web-sandbox-run-once-row'),
        children: [
          OutlinedButton.icon(
            key: const ValueKey('web-sandbox-run-once'),
            style: _secondary,
            onPressed: running ? null : widget.onRunOnce,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Run once'),
          ),
          if (running) ...[
            const SizedBox(width: 10),
            const SizedBox.square(
              key: ValueKey('web-sandbox-running'),
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
      if (_shotError case final shotError?) ...[
        const SizedBox(height: 4),
        Text(
          shotError,
          key: const ValueKey('web-sandbox-shot-count-error'),
          style: TextStyle(color: errorColor, fontSize: 12),
        ),
      ],
      if (error != null) ...[
        const SizedBox(height: 8),
        KeyedSubtree(
          key: _errorKey,
          child: Text(
            error,
            key: const ValueKey('web-sandbox-run-error'),
            style: TextStyle(color: errorColor),
          ),
        ),
      ],
      if (single != null) ...[
        const SizedBox(height: 16),
        KeyedSubtree(
          key: _singleKey,
          child: _SingleShotView(
            result: single,
            separateFromShots: observed != null,
          ),
        ),
        // The single run's conditional state belongs with that run.
        if (single.conditionalState case final state?) ...[
          const SizedBox(height: 10),
          _ConditionalStateView(
            state: state,
            numQubits: widget.numQubits,
            single: single,
          ),
        ],
      ],
    ];
    final distribution = exact != null || observed != null
        ? KeyedSubtree(
            key: _shotsKey,
            child: _DistributionView(
              exact: exact,
              observed: observed,
              configuredShots: widget.shots,
              filter: _filter,
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
          )
        : null;
    final notes = <Widget>[
      const SizedBox(height: 14),
      const QqMeta('Measurement outcomes are random, so runs can differ.'),
      const SizedBox(height: 8),
      _MoreAbout(finalState: finalState),
    ];
    Widget column(List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
    final stacked = column([
      ...setup,
      if (distribution != null) ...[const SizedBox(height: 18), distribution],
      ...notes,
    ]);
    if (!widget.splitLayout) {
      return KeyedSubtree(
          key: const ValueKey('web-sandbox-run-panel'), child: stacked);
    }
    return LayoutBuilder(
      key: const ValueKey('web-sandbox-run-panel'),
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) return stacked;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: (constraints.maxWidth * .34).clamp(320.0, 400.0),
              child: column([...setup, ...notes]),
            ),
            const SizedBox(width: 20),
            const SizedBox(
              height: 220,
              child: VerticalDivider(width: 1, color: QubitQuestSurfaces.rule),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: KeyedSubtree(
                key: const ValueKey('measure-outcomes-column'),
                // Outcome rows stay readable on ultrawide screens.
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: distribution ??
                        const QqMeta(
                            'Run the experiment to see outcome counts here.'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Which experiment runs, which qubits are read and where results go.
class _MeasurementConfiguration extends StatelessWidget {
  const _MeasurementConfiguration({
    required this.finalState,
    required this.numQubits,
    required this.measurements,
  });

  final bool finalState;
  final int numQubits;
  final List<MeasureZOperation> measurements;

  @override
  Widget build(BuildContext context) {
    final ordered = [...measurements]
      ..sort((a, b) => a.qubit.compareTo(b.qubit));
    return Column(
      key: const ValueKey('measure-configuration'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Experiment', style: QqType.subheading),
        const SizedBox(height: 8),
        QqFactList(
          labelWidth: 84,
          facts: [
            (
              'Setup',
              Text(
                finalState
                    ? 'Final-state sampling · all $numQubits qubit'
                        '${numQubits == 1 ? '' : 's'}'
                    : 'Measures ${measurements.map((m) => 'q${m.qubit} → c${m.classicalBit}').join(', ')}',
                key: const ValueKey('web-sandbox-measure-summary'),
              ),
            ),
            ('Basis', const Text('Z (computational basis)')),
            (
              'Each shot',
              Text(
                finalState
                    ? 'No M gates: each shot prepares the final state and '
                        'measures every qubit in the Z basis.'
                    : 'Each shot starts from the initial state and executes '
                        'every gate and M operation in order.',
                key: const ValueKey('web-sandbox-measure-mode'),
                style: QqType.body.copyWith(fontSize: 14, height: 1.45),
              ),
            ),
          ],
        ),
        if (!finalState && ordered.length < numQubits) ...[
          const SizedBox(height: 8),
          const QqMeta(
            'Outcomes are classical-register values, not full basis '
            'states: unmeasured qubits are not read.',
          ),
        ],
      ],
    );
  }
}

class _SingleShotView extends StatelessWidget {
  const _SingleShotView({
    required this.result,
    required this.separateFromShots,
  });
  final SingleShotOutcome result;

  /// A multi-shot result is shown too; they are different executions.
  final bool separateFromShots;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('web-sandbox-single-shot'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Single run', style: QqType.subheading),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Outcome  ', style: QqType.meta),
              TextSpan(
                text: result.readout.isFinalState
                    ? '|${result.outcome}⟩'
                    : result.outcome,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFeatures: QqType.tabular,
                  color: QubitQuestColors.textPrimary,
                ),
              ),
            ]),
            key: const ValueKey('measure-single-outcome'),
          ),
          const SizedBox(height: 4),
          for (final reading in result.readings)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'q${reading.measurement.qubit} → '
                'c${reading.measurement.classicalBit} = ${reading.value}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          Text(
            result.readout.isFinalState
                ? 'Outcome: |${result.outcome}⟩ (${result.register})'
                : 'Register: ${result.register}',
            key: const ValueKey('web-sandbox-single-register'),
            style: const TextStyle(
              color: QubitQuestColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (result.sharedBits.isNotEmpty)
            Text(
              '${result.sharedBits.map((b) => 'c$b').join(', ')} '
              'is written by more than one measurement; the register shows '
              'the last value.',
              style: QubitQuestTypography.supporting,
            ),
          if (separateFromShots)
            Text(
              'A separate execution from the shot experiment below.',
              key: const ValueKey('measure-single-separate'),
              style: QqType.meta,
            ),
        ],
      );
}

/// Exact probability against observed frequency on one linear 0–100% scale.
class _DistributionView extends StatefulWidget {
  const _DistributionView({
    required this.exact,
    required this.observed,
    required this.configuredShots,
    required this.filter,
    required this.onFilterChanged,
  });

  final ExactMeasurementDistribution? exact;
  final ShotsOutcome? observed;
  final int? configuredShots;
  final OutcomeFilter filter;
  final ValueChanged<OutcomeFilter> onFilterChanged;

  @override
  State<_DistributionView> createState() => _DistributionViewState();
}

class _DistributionViewState extends State<_DistributionView> {
  static const double _exactWidth = 64;
  static const double _observedWidth = 64;
  static const double _countWidth = 56;

  /// Long distributions scroll in a bounded list so a new result (its
  /// header and first rows) is always fully revealed (W4.2 contract).
  /// Rows visible before the list scrolls: at least 8, more on tall
  /// windows (up to 16), so long distributions use the available height.
  int _rowsBeforeScroll(BuildContext context) =>
      ((MediaQuery.sizeOf(context).height - 520) / _rowHeight(context))
          .floor()
          .clamp(8, 16);

  /// Wide outcome tables put label, bar and values on one aligned line.
  bool _wide = false;
  final ScrollController scroll = ScrollController();

  double _rowHeight(BuildContext context) => _wide
      ? 12 + MediaQuery.textScalerOf(context).scale(22)
      : 6 + MediaQuery.textScalerOf(context).scale(18) + 4 + 12;

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  ExactMeasurementDistribution? get exact => widget.exact;
  ShotsOutcome? get observed => widget.observed;
  int? get configuredShots => widget.configuredShots;
  OutcomeFilter get filter => widget.filter;
  ValueChanged<OutcomeFilter> get onFilterChanged => widget.onFilterChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        _wide = c.maxWidth >= 520;
        return _build(context);
      });

  Widget _build(BuildContext context) {
    final wide = _wide;
    final exact = this.exact;
    final observed = this.observed;
    final readout = exact?.readout ?? observed!.readout;
    final bits = (exact?.isAvailable ?? false)
        ? (exact!.readout.orderLabel.split(' ').length)
        : (observed?.counts.keys.firstOrNull?.length ?? 1);
    final outcomeWidth = (28.0 + 10.5 * bits).clamp(80.0, 200.0);
    final comparison = exact != null
        ? MeasurementComparison.build(
            exact: exact, observed: observed, filter: filter)
        : null;
    final hasExact = exact?.isAvailable ?? false;
    final hasObserved = observed != null;
    final rows = comparison?.rows ??
        [
          for (final e in observed!.counts.entries)
            OutcomeComparison(
                outcome: e.key,
                exact: null,
                count: e.value,
                shots: observed.shots),
        ];
    final distinct = observed?.counts.length;
    final finalState = readout.isFinalState;

    String label(String o) => finalState ? '|$o⟩' : o;

    final header = DefaultTextStyle(
      style: QqType.tableHeader,
      child: Row(
        children: [
          if (wide) ...[
            SizedBox(width: outcomeWidth, child: const Text('Outcome')),
            const SizedBox(width: 12),
            const Expanded(child: Text('0–100%')),
            const SizedBox(width: 16),
          ] else
            const Expanded(child: Text('Outcome')),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                if (hasExact || !hasObserved)
                  const SizedBox(
                    width: _exactWidth,
                    child: Text('Exact', textAlign: TextAlign.right),
                  ),
                if (hasObserved) ...const [
                  SizedBox(
                    width: _observedWidth,
                    child: Text('Observed', textAlign: TextAlign.right),
                  ),
                  SizedBox(
                    width: _countWidth,
                    child: Text('Count', textAlign: TextAlign.right),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    Widget row(OutcomeComparison r) {
      final cells = Row(
        children: [
          if (hasExact || !hasObserved)
            SizedBox(
              width: _exactWidth,
              child: Text(
                r.exact == null ? '—' : formatProbability(r.exact!),
                key: ValueKey('measure-exact-${r.outcome}'),
                textAlign: TextAlign.right,
                style: QqType.table.copyWith(
                  color: QubitQuestColors.accentInteractive,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (hasObserved) ...[
            SizedBox(
              width: _observedWidth,
              child: Text(
                formatProbability(r.frequency ?? 0),
                key: ValueKey('measure-observed-${r.outcome}'),
                textAlign: TextAlign.right,
                style: QqType.table.copyWith(
                  color: _observedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: _countWidth,
              child: Text(
                formatCount(r.count ?? 0),
                key: ValueKey('web-sandbox-outcome-count-${r.outcome}'),
                textAlign: TextAlign.right,
                style: QqType.table,
              ),
            ),
          ],
        ],
      );
      final tooltip = [
        readout.describe(r.outcome),
        if (r.exact != null) 'exact ${formatProbability(r.exact!)}',
        if (r.count != null)
          'observed ${formatCount(r.count!)} of '
              '${formatCount(r.shots!)} shots '
              '(${formatProbability(r.frequency!)})',
      ].join(' · ');
      final outcomeLabel = Text(
        label(r.outcome),
        style: QqType.table.copyWith(
          fontWeight: FontWeight.w600,
          color: finalState ? QqType.ketColor : QubitQuestColors.textPrimary,
        ),
      );
      if (wide) {
        return Tooltip(
          message: tooltip,
          child: Container(
            key: ValueKey('web-sandbox-outcome-${r.outcome}'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x1F344A73))),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: outcomeWidth,
                  child: Row(children: [
                    Flexible(child: outcomeLabel),
                    if (r.unexpected) ...[
                      const SizedBox(width: 4),
                      const Tooltip(
                        message: 'Observed although its exact probability is '
                            '0%: please report this circuit.',
                        child: Icon(Icons.warning_amber_rounded,
                            key: ValueKey('measure-unexpected'),
                            size: 16,
                            color: QubitQuestColors.warning),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ComparisonBar(
                    key: ValueKey('measure-bar-${r.outcome}'),
                    exact: r.exact,
                    observed: r.frequency,
                  ),
                ),
                const SizedBox(width: 16),
                cells,
              ],
            ),
          ),
        );
      }
      return Tooltip(
        message: tooltip,
        child: Padding(
          key: ValueKey('web-sandbox-outcome-${r.outcome}'),
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  outcomeLabel,
                  if (r.unexpected) ...[
                    const SizedBox(width: 6),
                    const Tooltip(
                      message: 'Observed although its exact probability is '
                          '0%: please report this circuit.',
                      child: Icon(Icons.warning_amber_rounded,
                          key: ValueKey('measure-unexpected'),
                          size: 16,
                          color: QubitQuestColors.warning),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Shrinks (never clips) when large text meets a narrow card.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: cells,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ComparisonBar(
                key: ValueKey('measure-bar-${r.outcome}'),
                exact: r.exact,
                observed: r.frequency,
              ),
            ],
          ),
        ),
      );
    }

    final exactNote =
        exact != null && !exact.isAvailable ? exact.unavailableReason! : null;
    final footnote = [
      if (comparison != null && comparison.hiddenOutcomes > 0)
        '${comparison.hiddenOutcomes} more outcome'
            '${comparison.hiddenOutcomes == 1 ? '' : 's'} with exact '
            'probability 0%${hasObserved ? ', not observed' : ''}.',
      if (hasExact)
        'Total exact probability ${formatProbability(exact!.total)}.',
      if (hasObserved && hasExact)
        'Finite shots fluctuate around the exact probabilities.'
      else if (hasObserved)
        'More shots give a closer estimate of the probabilities.',
    ].join(' ');
    final list = rows.length > _rowsBeforeScroll(context)
        ? SizedBox(
            height: _rowHeight(context) * _rowsBeforeScroll(context),
            child: Scrollbar(
              controller: scroll,
              thumbVisibility: true,
              child: ListView(
                key: const ValueKey('web-sandbox-outcomes-scroll'),
                controller: scroll,
                padding: const EdgeInsets.only(right: 16),
                children: [for (final r in rows) row(r)],
              ),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final r in rows) row(r)],
          );
    final section = Column(
      key: const ValueKey('measure-distribution'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Expanded(
              child: Text('Outcomes', style: QqType.subheading),
            ),
            if (observed != null)
              Text(
                '${formatCount(observed.shots)} shots',
                key: const ValueKey('measure-observed-shots'),
                style: QqType.table.copyWith(
                    color: _observedColor, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Outcome order: ${readout.orderLabel} (highest '
          '${finalState ? 'qubit' : 'classical bit'} on the left)'
          '${distinct == null ? '' : ' · $distinct distinct outcome${distinct == 1 ? '' : 's'}'}',
          key: const ValueKey('web-sandbox-outcome-order'),
          style: QqType.meta,
        ),
        const SizedBox(height: 8),
        _Legend(observed: hasObserved, exact: hasExact),
        if (observed != null &&
            configuredShots != null &&
            configuredShots != observed.shots)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Shot count is now ${formatCount(configuredShots!)}; these '
              'results are from ${formatCount(observed.shots)} shots.',
              key: const ValueKey('measure-shots-changed'),
              style: QqType.meta,
            ),
          )
        else if (observed == null && hasExact)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No shots run yet: run shots to compare.',
              key: const ValueKey('measure-no-observed'),
              style: QqType.meta,
            ),
          ),
        if (exactNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              exactNote,
              key: const ValueKey('measure-exact-unavailable'),
              style: QqType.meta,
            ),
          ),
        if (comparison != null &&
            (comparison.hiddenOutcomes > 0 || filter == OutcomeFilter.all) &&
            comparison.totalOutcomes <= 64) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<OutcomeFilter>(
              key: const ValueKey('measure-outcome-filter'),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -3),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
              segments: const [
                ButtonSegment(
                  value: OutcomeFilter.possibleOrObserved,
                  label: Text('Possible or observed'),
                ),
                ButtonSegment(value: OutcomeFilter.all, label: Text('All')),
              ],
              selected: {filter},
              onSelectionChanged: (v) => onFilterChanged(v.single),
            ),
          ),
        ],
        const SizedBox(height: 12),
        header,
        const Divider(height: 10, color: QubitQuestSurfaces.rule),
        list,
        if (footnote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              footnote,
              key: const ValueKey('measure-footnote'),
              style: QqType.meta,
            ),
          ),
        if (comparison?.hasUnexpected ?? false)
          Text(
            'An outcome was observed although its exact probability is 0%. '
            'This indicates a numerical or implementation problem.',
            key: const ValueKey('measure-unexpected-note'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
      ],
    );
    // With observed data the whole comparison is the shot result.
    return observed == null
        ? section
        : KeyedSubtree(
            key: const ValueKey('web-sandbox-shots-result'), child: section);
  }
}

const Color _observedColor = Color(0xFFB794F6);

class _Legend extends StatelessWidget {
  const _Legend({required this.observed, required this.exact});
  final bool observed;
  final bool exact;

  @override
  Widget build(BuildContext context) {
    Widget item(Widget swatch, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch,
            const SizedBox(width: 6),
            Flexible(
              child: Text(text, style: QqType.meta),
            ),
          ],
        );
    return Wrap(
      key: const ValueKey('measure-legend'),
      spacing: 14,
      runSpacing: 4,
      children: [
        if (exact)
          item(
            Container(
              width: 16,
              height: 10,
              decoration: BoxDecoration(
                border: Border.all(
                    color: QubitQuestColors.accentInteractive, width: 1.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            'Exact probability (outline)',
          ),
        if (observed)
          item(
            Container(
              width: 16,
              height: 10,
              decoration: BoxDecoration(
                color: _observedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            'Observed frequency (filled)',
          ),
      ],
    );
  }
}

/// One outcome's bar on a fixed 0–100% scale: the exact probability as a
/// cyan outline ending in a marker, the observed frequency as a filled
/// purple bar. Both use the same linear scale (full width = 100%).
class ComparisonBar extends StatelessWidget {
  const ComparisonBar({super.key, this.exact, this.observed});
  final double? exact;
  final double? observed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 12,
        child: CustomPaint(
          painter: _ComparisonBarPainter(exact: exact, observed: observed),
          size: Size.infinite,
        ),
      );
}

class _ComparisonBarPainter extends CustomPainter {
  _ComparisonBarPainter({this.exact, this.observed});
  final double? exact;
  final double? observed;

  @override
  void paint(Canvas canvas, Size size) {
    final track =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3));
    // A faint track shows the full 0–100% scale even for 0% outcomes.
    canvas.drawRRect(track, Paint()..color = const Color(0x1AFFFFFF));
    if (observed case final f?) {
      final w = size.width * f.clamp(0, 1);
      if (w > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(0, 2, w, size.height - 4),
              const Radius.circular(2)),
          Paint()..color = _observedColor,
        );
      }
    }
    if (exact case final p?) {
      final x = size.width * p.clamp(0, 1);
      final outline = Paint()
        ..color = QubitQuestColors.accentInteractive
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      if (x > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(0.7, 0.7, x - 1.4, size.height - 1.4),
              const Radius.circular(3)),
          outline,
        );
        canvas.drawLine(
          Offset(x, -1),
          Offset(x, size.height + 1),
          Paint()
            ..color = QubitQuestColors.accentInteractive
            ..strokeWidth = 2.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ComparisonBarPainter old) =>
      old.exact != exact || old.observed != observed;
}

/// The register state left by the single run (explicit measurements only).
class _ConditionalStateView extends StatefulWidget {
  const _ConditionalStateView({
    required this.state,
    required this.numQubits,
    required this.single,
  });

  final List<Complex> state;
  final int numQubits;
  final SingleShotOutcome single;

  @override
  State<_ConditionalStateView> createState() => _ConditionalStateViewState();
}

class _ConditionalStateViewState extends State<_ConditionalStateView> {
  bool _open = true;

  List<Complex> get state => widget.state;
  int get numQubits => widget.numQubits;
  SingleShotOutcome get single => widget.single;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('measure-conditional-state'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: const ValueKey('measure-conditional-toggle'),
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                const Expanded(
                  child: Text('CONDITIONAL STATE AFTER THIS RUN',
                      style: QubitQuestTypography.label),
                ),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                  color: QubitQuestColors.textMuted,
                ),
              ],
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 4),
            Text(
              'The full register after this run (outcome ${single.outcome}: '
              '${single.register}), including every later operation. It '
              'belongs to this run only, not to the shot experiment.',
              style: QqType.meta,
            ),
            const SizedBox(height: 6),
            StateVectorDisplay(
              key: const ValueKey('measure-conditional-state-vector'),
              stateVector: state,
              numQubits: numQubits,
              showHeader: false,
              dense: true,
              contentDriven: true,
              structuredLayout: true,
              lightweightTypography: true,
              stateLabel: '|ψ_after⟩',
            ),
          ],
        ],
      );
}

/// Longer explanation, collapsed by default; the essential distinctions
/// (mode, randomness, exact versus observed) stay visible above it.
class _MoreAbout extends StatefulWidget {
  const _MoreAbout({required this.finalState});
  final bool finalState;

  @override
  State<_MoreAbout> createState() => _MoreAboutState();
}

class _MoreAboutState extends State<_MoreAbout> {
  @override
  Widget build(BuildContext context) => QqDisclosure(
        toggleKey: const ValueKey('measure-more-about'),
        title: 'More about this experiment',
        summary: 'exact versus observed',
        child: Text(
          widget.finalState
              ? 'Add M gates to choose which qubits are measured and '
                  'which classical bits store the results. Exact '
                  'probabilities are |amplitude|² of the final state; '
                  'observed frequencies are counts divided by shots.'
              : 'Outcomes are the values of the classical bits the '
                  'measurements write (unmeasured qubits are not read). '
                  'Exact probabilities follow this same sequence of '
                  'operations; observed frequencies are counts divided '
                  'by shots. A single run\'s conditional state belongs to '
                  'that run only.',
          key: const ValueKey('measure-more-about-text'),
        ),
      );
}
