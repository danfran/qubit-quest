import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/bloch_summary_panel.dart';
import 'package:quantumquiz/widgets/probability_distribution_chart.dart';
import 'package:quantumquiz/widgets/qq_scientific_primitives.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/widgets/qubit_quest_workspace_primitives.dart';

/// Which part of the analysis workspace is shown.
enum ComposerAnalysisTab { state, measure }

/// Presentation state of one analysis workspace, owned by the host so that
/// mode switches and relayouts keep the tab and the Bloch camera.
class ComposerAnalysisSelection {
  ComposerAnalysisTab tab = ComposerAnalysisTab.state;

  /// Drives the embedded Bloch view (always its Bloch view) and keeps the
  /// learner's camera across rebuilds.
  final QuantumInspectorSelection bloch = QuantumInspectorSelection()
    ..selected = QuantumInspectorView.bloch;
}

/// The laboratory Composer's central analysis (v2.6 M11C, M11B prototype
/// 1–3): *State* shows the current state, its exact probability distribution
/// and, for one qubit, the Bloch sphere side by side; *Measure* shows the
/// sampled experiment. All content is supplied by the host from the one
/// [ComposerSession]; this widget only arranges it by available width.
class ComposerAnalysisWorkspace extends StatefulWidget {
  const ComposerAnalysisWorkspace({
    super.key,
    required this.selection,
    required this.stateView,
    required this.numQubits,
    required this.blochStateVector,
    this.probabilityStateVector,
    this.probabilityNote,
    this.measureView,
    this.allowBloch = true,
    this.blochCaption,
    this.blochNote,
    this.blochSelector,
    this.onOpenBlochExplorer,
    this.blochUnavailableMessage,
    this.measured = false,
  });

  final ComposerAnalysisSelection selection;

  /// The complete Current State panel (heading, expression, table).
  final Widget stateView;
  final int numQubits;

  /// State for the exact probability chart; null when no single state is
  /// defined (mid-circuit measurement), in which case [probabilityNote]
  /// explains why.
  final List<Complex>? probabilityStateVector;
  final String? probabilityNote;

  /// Null where the activity runs no sampled experiments.
  final Widget? measureView;

  final List<Complex> blochStateVector;
  final bool allowBloch;
  final String? blochCaption;
  final String? blochNote;

  /// Chooses the drawn state (before measurement / after a single run).
  final Widget? blochSelector;
  final VoidCallback? onOpenBlochExplorer;
  final String? blochUnavailableMessage;

  /// Whether the circuit contains M operations (labels the State tab's
  /// panels "before measurement").
  final bool measured;

  @override
  State<ComposerAnalysisWorkspace> createState() =>
      _ComposerAnalysisWorkspaceState();
}

class _ComposerAnalysisWorkspaceState extends State<ComposerAnalysisWorkspace> {
  ComposerAnalysisSelection get _selection => widget.selection;

  bool get _oneQubit => widget.numQubits == 1;

  @override
  Widget build(BuildContext context) {
    if (widget.measureView == null) {
      _selection.tab = ComposerAnalysisTab.state;
    }
    final tab = _selection.tab;
    return Column(
      key: const ValueKey('composer-analysis-workspace'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: [
            if (widget.measureView != null)
              SegmentedButton<ComposerAnalysisTab>(
                key: const ValueKey('composer-analysis-tabs'),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity(horizontal: -1, vertical: -2),
                ),
                segments: const [
                  ButtonSegment(
                    value: ComposerAnalysisTab.state,
                    icon: Icon(Icons.data_array_outlined, size: 16),
                    label: Text('State',
                        key: ValueKey('composer-analysis-tab-state')),
                  ),
                  ButtonSegment(
                    value: ComposerAnalysisTab.measure,
                    icon: Icon(Icons.bar_chart_rounded, size: 16),
                    label: Text('Measure',
                        key: ValueKey('composer-analysis-tab-measure')),
                  ),
                ],
                selected: {tab},
                onSelectionChanged: (value) =>
                    setState(() => _selection.tab = value.single),
              )
            else
              const QqPanelLabel('Analysis'),
            Text(
              tab == ComposerAnalysisTab.state
                  ? 'Exact simulation of the circuit as built'
                  : 'Sampled runs: every shot prepares and runs the circuit '
                      'again',
              key: const ValueKey('composer-analysis-mode-hint'),
              style: QqType.meta,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Both tabs stay mounted, so switching never loses an amplitude
        // filter, a Bloch camera or a typed shot count.
        IndexedStack(
          index: tab == ComposerAnalysisTab.state ? 0 : 1,
          sizing: StackFit.loose,
          children: [
            _stateTab(),
            widget.measureView == null
                ? const SizedBox.shrink()
                : QqWorkspacePanel(
                    key: const ValueKey('composer-analysis-measure'),
                    label: 'Measurement experiment',
                    child: widget.measureView!,
                  ),
          ],
        ),
      ],
    );
  }

  Widget _statePanel() => KeyedSubtree(
        key: const ValueKey('composer-analysis-state'),
        child: widget.stateView,
      );

  Widget? _probabilityPanel() {
    final vector = widget.probabilityStateVector;
    if (vector == null) {
      final note = widget.probabilityNote;
      if (note == null) return null;
      return QqWorkspacePanel(
        key: const ValueKey('composer-analysis-probabilities'),
        label: 'Probabilities',
        child: Text(note,
            key: const ValueKey('composer-probability-unavailable'),
            style: QqType.meta),
      );
    }
    return QqWorkspacePanel(
      key: const ValueKey('composer-analysis-probabilities'),
      label: 'Probabilities',
      subtitle: widget.measured
          ? 'Outcomes of measuring every qubit of the state before '
              'measurement'
          : 'Outcomes of measuring every qubit now',
      child: ProbabilityDistributionChart(
        stateVector: vector,
        numQubits: widget.numQubits,
      ),
    );
  }

  Widget? _blochPanel() {
    if (!_oneQubit || widget.blochStateVector.length < 2) return null;
    if (!widget.allowBloch) {
      return QqWorkspacePanel(
        key: const ValueKey('composer-analysis-bloch'),
        label: 'Bloch sphere',
        child: QqMeta(
          widget.blochUnavailableMessage ??
              'No single state is defined before measurement here, so no '
                  'Bloch vector is drawn.',
          key: const ValueKey('quantum-inspector-bloch-unavailable-reason'),
        ),
      );
    }
    final bloch = _selection.bloch;
    return KeyedSubtree(
      key: const ValueKey('composer-analysis-bloch'),
      child: QqBlochSummaryPanel(
        alpha: widget.blochStateVector[0],
        beta: widget.blochStateVector[1],
        camera: bloch.camera,
        onCameraChanged: (camera) => setState(() => bloch.camera = camera),
        caption: widget.blochCaption,
        note: widget.blochNote,
        selector: widget.blochSelector,
        onOpenExplorer: widget.onOpenBlochExplorer,
      ),
    );
  }

  /// Panels take widths from their content: the state (widest content)
  /// leads, probabilities follow, the Bloch summary keeps a sphere-sized
  /// column. Heights follow content; panels are top-aligned on one grid.
  Widget _stateTab() => LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final state = _statePanel();
        final probabilities = _probabilityPanel();
        final bloch = _blochPanel();
        const gap = QqSpace.gap;
        Widget row(List<Widget> children) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) const SizedBox(width: gap),
                  child,
                ],
              ],
            );
        Widget column(List<Widget> children) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) const SizedBox(height: gap),
                  child,
                ],
              ],
            );
        final Widget grid;
        if (bloch != null && probabilities != null) {
          final blochWidth = width >= 1500 ? 340.0 : 312.0;
          if (width >= 1080) {
            grid = row([
              Expanded(flex: 6, child: state),
              Expanded(flex: 5, child: probabilities),
              SizedBox(width: blochWidth, child: bloch),
            ]);
          } else if (width >= 640) {
            grid = column([
              state,
              row([
                Expanded(child: probabilities),
                SizedBox(width: blochWidth, child: bloch),
              ]),
            ]);
          } else {
            grid = column([state, probabilities, bloch]);
          }
        } else {
          final second = probabilities ?? bloch;
          grid = second == null
              ? state
              : width >= 860
                  ? row([
                      Expanded(flex: 6, child: state),
                      Expanded(flex: 5, child: second),
                    ])
                  : column([state, second]);
        }
        return Column(
          key: const ValueKey('composer-analysis-state-tab'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            grid,
            if (!_oneQubit)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: QqMeta(
                  // M11E: a subsystem does have a (reduced) Bloch vector,
                  // possibly inside the sphere; it just does not describe
                  // the joint state.
                  'The Bloch sphere is currently available for single-qubit '
                  'circuits. In multi-qubit systems, individual qubits may '
                  'have mixed reduced states, and their Bloch vectors do not '
                  'capture the full joint state.',
                  key: ValueKey('composer-analysis-bloch-note'),
                ),
              ),
          ],
        );
      });
}
