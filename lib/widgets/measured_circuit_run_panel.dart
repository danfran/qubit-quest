import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

/// The Inspector's Measure tab for every circuit: run controls, the latest
/// single-shot reading and the latest multi-shot histogram. With M
/// operations results are classical bits; without them, final-state samples
/// of every qubit.
///
/// Row 1 is **Run once**; row 2 is **Run shots** with its own shot count
/// (any whole number from 1 to 10,000, with 100 / 1,000 / 10,000 presets).
/// When a new result or error arrives it is scrolled into view.
///
/// Results are sampled by the executor; nothing here is an ideal probability.
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
  });

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
    padding: const EdgeInsets.symmetric(horizontal: 14),
    minimumSize: const Size(0, 40),
  );
  final _singleKey = GlobalKey();
  final _shotsKey = GlobalKey();
  final _errorKey = GlobalKey();
  late final TextEditingController _shotText =
      TextEditingController(text: widget.shots?.toString() ?? '');
  String? _shotError;

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
    return Column(
      key: const ValueKey('web-sandbox-run-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          finalState
              ? 'Final-state sampling · all ${widget.numQubits} qubit'
                  '${widget.numQubits == 1 ? '' : 's'}'
              : 'Measures ${widget.measurements.map((m) => 'q${m.qubit} → c${m.classicalBit}').join(', ')}',
          key: const ValueKey('web-sandbox-measure-summary'),
          style: QubitQuestTypography.supporting,
        ),
        const SizedBox(height: 10),
        Row(
          key: const ValueKey('web-sandbox-run-once-row'),
          children: [
            FilledButton.tonalIcon(
              key: const ValueKey('web-sandbox-run-once'),
              style: _compact,
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
        const SizedBox(height: 8),
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
        if (_shotError case final shotError?) ...[
          const SizedBox(height: 4),
          Text(
            shotError,
            key: const ValueKey('web-sandbox-shot-count-error'),
            style: TextStyle(color: errorColor, fontSize: 12),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          finalState
              ? 'No M gates: each shot prepares the final state and measures '
                  'every qubit in the Z basis. Add M gates to choose which '
                  'qubits are measured and which classical bits store the '
                  'results.'
              : 'Each shot starts from the initial state and executes every '
                  'gate and M operation in order, storing outcomes in '
                  'classical bits.',
          key: const ValueKey('web-sandbox-measure-mode'),
          style: QubitQuestTypography.supporting,
        ),
        const SizedBox(height: 4),
        const Text(
          'Measurement outcomes are random, so runs can differ.',
          style: QubitQuestTypography.supporting,
        ),
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
        if (widget.singleShot case final single?) ...[
          const SizedBox(height: 14),
          KeyedSubtree(key: _singleKey, child: _SingleShotView(result: single)),
        ],
        if (widget.shotsResult case final result?) ...[
          const SizedBox(height: 14),
          KeyedSubtree(key: _shotsKey, child: _ShotsView(result: result)),
        ],
      ],
    );
  }
}

class _SingleShotView extends StatelessWidget {
  const _SingleShotView({required this.result});
  final SingleShotOutcome result;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('web-sandbox-single-shot'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ONE RUN', style: QubitQuestTypography.label),
          const SizedBox(height: 6),
          for (final reading in result.readings)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'q${reading.measurement.qubit} → '
                'c${reading.measurement.classicalBit} = ${reading.value}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          const SizedBox(height: 4),
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
        ],
      );
}

class _ShotsView extends StatefulWidget {
  const _ShotsView({required this.result});
  final ShotsOutcome result;

  @override
  State<_ShotsView> createState() => _ShotsViewState();
}

class _ShotsViewState extends State<_ShotsView> {
  static const int _rowsBeforeScroll = 8;
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final entries = result.counts.entries.toList(growable: false);
    final readout = result.readout;
    // Label line + gap + bar; the label line grows with the text scale.
    final rowHeight = 22 + MediaQuery.textScalerOf(context).scale(18);
    Widget row(MapEntry<String, int> entry) {
      final fraction = entry.value / result.shots;
      final percent = (100 * fraction).toStringAsFixed(1);
      return Tooltip(
        message: '${readout.describe(entry.key)}: '
            '${formatCount(entry.value)} of ${formatCount(result.shots)} shots '
            '($percent%)',
        child: SizedBox(
          height: rowHeight,
          child: Column(
            key: ValueKey('web-sandbox-outcome-${entry.key}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(readout.isFinalState ? '|${entry.key}⟩' : entry.key,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        color: QubitQuestColors.textPrimary,
                      )),
                  const SizedBox(width: 8),
                  // Shrinks (never clips) when large text meets a narrow card.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${formatCount(entry.value)} · $percent%',
                        style: QubitQuestTypography.supporting,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  color: QubitQuestColors.accentInteractive,
                  backgroundColor: QubitQuestColors.surface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final list = entries.length > _rowsBeforeScroll
        ? SizedBox(
            height: rowHeight * _rowsBeforeScroll,
            child: Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              child: ListView(
                key: const ValueKey('web-sandbox-outcomes-scroll'),
                controller: _scroll,
                padding: const EdgeInsets.only(right: 10),
                children: [for (final e in entries) row(e)],
              ),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final e in entries) row(e)],
          );

    return Column(
      key: const ValueKey('web-sandbox-shots-result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${formatCount(result.shots)} SHOTS',
            style: QubitQuestTypography.label),
        const SizedBox(height: 4),
        Text(
          'Outcome order: ${readout.orderLabel} (highest classical bit on '
          'the left) · ${entries.length} distinct outcome'
          '${entries.length == 1 ? '' : 's'}',
          key: const ValueKey('web-sandbox-outcome-order'),
          style: QubitQuestTypography.supporting,
        ),
        const SizedBox(height: 6),
        list,
        const SizedBox(height: 6),
        const Text(
          'Observed frequencies approximate the circuit\'s measurement '
          'probabilities; more shots give a closer estimate.',
          style: QubitQuestTypography.supporting,
        ),
      ],
    );
  }
}
