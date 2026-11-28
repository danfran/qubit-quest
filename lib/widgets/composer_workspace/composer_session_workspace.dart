import 'dart:async';
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/composer_gate_capabilities.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';
import 'package:quantumquiz/widgets/composer_placement_flow.dart';
import 'package:quantumquiz/widgets/composer_workspace/circuit_scale_control.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_analysis_workspace.dart';
import 'package:quantumquiz/widgets/qubit_quest_workspace_primitives.dart';
import 'package:quantumquiz/widgets/state_amplitude_panel.dart';
import 'package:quantumquiz/widgets/lesson_state_comparison.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_results_panel.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_workspace_toolbar.dart';
import 'package:quantumquiz/widgets/composer_workspace/desktop_composer_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/gate_inspector_panel.dart';
import 'package:quantumquiz/widgets/composer_workspace/laboratory_composer_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';
import 'package:quantumquiz/widgets/measured_circuit_run_panel.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';
import 'package:quantumquiz/widgets/quantum_state_inspector_content.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart'
    show defaultNonZeroOnlyForQubitCount;

/// One Composer session plus the presentation state that belongs to it
/// (status line, state filter, palette preview). Hosts keep slots beside
/// their sessions, so two sessions (Sandbox and Notebook example, or a
/// lesson) never share presentation state.
class ComposerWorkspaceSlot {
  ComposerWorkspaceSlot(
    this.session, {
    required this.status,
    this.statusFades = false,
  }) : nonZeroOnly = defaultNonZeroOnlyForQubitCount(
          session.circuit.currentLevel.numQubits,
        );

  final ComposerSession session;
  String status;

  /// Whether [status] is informational and should fade (M5), consumed when
  /// the workspace first shows it.
  bool statusFades;
  bool? nonZeroOnly;

  /// Gate type previewed from the palette (inspector only; no edit).
  SelectedGateType? previewType;

  int get qubitCount => session.circuit.currentLevel.numQubits;
}

/// The v2.6 desktop Composer workspace for one [ComposerSession]: toolbar,
/// categorised palette, circuit canvas, gate inspector and results.
///
/// Every context uses this one widget (M6a): the Sandbox, Notebook examples,
/// Journey circuit lessons and Mastery circuit challenges. Contexts differ
/// only through the session's [ComposerPolicy] (gates, measurement, target
/// visibility, clear/reset wording) and through the optional [header] and
/// [footer] an educational host adds (objective, hints, Check). Editing
/// always goes through the session's commands, which enforce the policy and
/// the model's fixed-gate rules; this widget only presents outcomes.
class ComposerSessionWorkspace extends StatefulWidget {
  const ComposerSessionWorkspace({
    super.key,
    required this.slot,
    required this.layout,
    required this.shortcutsEnabled,
    required this.contextLabel,
    this.workspaceKey = const ValueKey('web-composer-workspace-scroll'),
    this.onSelectQubits,
    this.clearLabel,
    this.clearedStatus = 'Circuit cleared.',
    this.onOpenNotebookEntry,
    this.showLegacyMeasurementNote = false,
    this.onExploreInBloch,
    this.markFixedGates = false,
    this.header,
    this.footer,
    this.headerScrollsBelow,
    this.laboratory = false,
    this.learning = false,
    this.learningPaletteLabel = 'Available in this lesson',
    this.learningIntro,
  });

  /// Learning layout: a header that scrolls with the work (narrow hosts).
  final Widget? learningIntro;

  /// The learning layout (v2.6 M11D) for Journey lessons and Mastery
  /// circuit challenges: the laboratory skeleton composed for a task. The
  /// restricted palette with undo, redo and reset; the content-sized
  /// circuit; "Your circuit now" against the target with the activity's
  /// validation scope; the contextual inspector. No Sandbox toolbar,
  /// qubit selector, Measure tab or Focus mode.
  final bool learning;
  final String learningPaletteLabel;

  /// The laboratory layout (v2.6 M11C): horizontal palette, content-sized
  /// circuit, central analysis and a contextual inspector, with *Analysis*
  /// and *Focus circuit* modes. False keeps the classic three-column layout
  /// (Journey, Mastery and Notebook hosts until their M11D redesign). Both
  /// present the same session through the same commands.
  final bool laboratory;

  final ComposerWorkspaceSlot slot;
  final WorkspaceLayoutController layout;

  /// Undo/redo keyboard shortcuts; only the visible workspace takes them.
  final bool shortcutsEnabled;

  /// Shown beside the toolbar title, e.g. "Sandbox" or "Lesson 3.3".
  final String contextLabel;
  final Key workspaceKey;

  /// Qubit-count selector (Sandbox only); null hides it.
  final ValueChanged<int>? onSelectQubits;

  /// Overrides the Clear/Reset label derived from the policy.
  final String? clearLabel;
  final String clearedStatus;
  final ValueChanged<String>? onOpenNotebookEntry;

  /// The Sandbox's note for legacy circuits with post-measurement gates.
  final bool showLegacyMeasurementNote;

  /// Opens this one-qubit circuit in the Bloch Explorer as an isolated
  /// exploration (v2.6 M8). Offered in the Bloch results tab only for
  /// one-qubit circuits; null hides it.
  final VoidCallback? onExploreInBloch;

  /// Lock badges on gates the activity fixed in place.
  final bool markFixedGates;

  /// Educational context above the workspace (lesson identity, objective).
  final Widget? header;

  /// Educational actions below the workspace (hints, Check, feedback). It
  /// stays visible at every size, so Check never scrolls away.
  final Widget? footer;

  /// Laboratory hosts only (v2.6 M11G): below this width [header] scrolls
  /// with the work (above the palette and circuit) instead of staying
  /// fixed, so phones keep the circuit near the top. Null: always fixed.
  final double? headerScrollsBelow;

  @override
  State<ComposerSessionWorkspace> createState() =>
      _ComposerSessionWorkspaceState();
}

class _ComposerSessionWorkspaceState extends State<ComposerSessionWorkspace> {
  static const ComposerPlacementFlow _placement = ComposerPlacementFlow();

  ComposerWorkspaceSlot get _slot => widget.slot;
  ComposerSession get _session => _slot.session;
  QuantumCircuit get _activeCircuit => _session.circuit;

  /// Inspector section (presentation only).
  GateInspectorTab _inspectorTab = GateInspectorTab.overview;

  /// One-qubit Bloch view: show the conditional state after the latest
  /// single run instead of the state before measurement (presentation only).
  bool _blochAfterRun = false;

  final QuantumInspectorSelection _resultsSelection =
      QuantumInspectorSelection();
  final ScrollController _resultsScroll = ScrollController();

  /// Laboratory analysis tab and Bloch camera (presentation only).
  final ComposerAnalysisSelection _analysisSelection =
      ComposerAnalysisSelection();

  /// Inspector disclosures the learner opened; in memory (M11B D5).
  final Set<String> _openInspectorSections = {};

  double get _circuitScale => widget.layout.preferences.circuitScale;

  /// Presentation only: never touches the session, its history, results or
  /// autosave; persisted with the workspace layout preferences.
  void _setCircuitScale(double scale) => widget.layout
      .commit(widget.layout.preferences.copyWith(circuitScale: scale));

  String get _status => _slot.status;
  set _status(String value) => _slot.status = value;

  /// How long a successful informational message stays (M5). Rejections,
  /// errors and persistence warnings are never cleared automatically.
  static const Duration _infoLifetime = Duration(seconds: 6);
  Timer? _infoTimer;

  void _info(String message) {
    setState(() => _status = message);
    _clearInfoLater(message);
  }

  void _clearInfoLater(String message) {
    _infoTimer?.cancel();
    _infoTimer = Timer(_infoLifetime, () {
      if (mounted && _status == message) setState(() => _status = '');
    });
  }

  void _consumeFadingStatus() {
    if (!_slot.statusFades) return;
    _slot.statusFades = false;
    _clearInfoLater(_slot.status);
  }

  List<Gate> get _gates => [
        for (final gate in _activeCircuit.currentLevel.availableGates)
          Gate.fromIdentifier(gate.type, angle: gate.angle),
      ];

  @override
  void initState() {
    super.initState();
    _session.addListener(_sessionChanged);
    widget.layout.addListener(_layoutChanged);
    _consumeFadingStatus();
  }

  @override
  void didUpdateWidget(covariant ComposerSessionWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.slot.session, widget.slot.session)) {
      oldWidget.slot.session.removeListener(_sessionChanged);
      widget.slot.session.addListener(_sessionChanged);
    }
    if (!identical(oldWidget.layout, widget.layout)) {
      oldWidget.layout.removeListener(_layoutChanged);
      widget.layout.addListener(_layoutChanged);
    }
    _consumeFadingStatus();
  }

  @override
  void dispose() {
    _infoTimer?.cancel();
    widget.layout.removeListener(_layoutChanged);
    if (!_session.isDisposed) _session.removeListener(_sessionChanged);
    _resultsScroll.dispose();
    super.dispose();
  }

  void _sessionChanged() {
    if (!mounted) return;
    setState(() {
      // Selecting a placed operation replaces any palette preview.
      if (_session.selectedId != null) _slot.previewType = null;
    });
  }

  /// Status wording for a gate command's outcome (selection is already
  /// maintained by the session).
  void _reportGateEdit(CircuitEditOutcome outcome) {
    if (!mounted || outcome.status == CircuitEditStatus.cancelled) return;
    setState(() {
      // A successful edit is visible in the circuit and in the footer's
      // summary; only rejections and other outcomes need a message.
      _status = outcome.changed ? '' : editResultMessage(outcome);
    });
  }

  /// Visible rejection that never modifies the circuit.
  void _rejectEdit(String reason) {
    final message = 'Not changed: $reason';
    setState(() => _status = message);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const ValueKey('web-composer-drop-rejected'),
          content: Text(message),
        ),
      );
  }

  String get _measurementRunNote => widget.laboratory
      ? 'Run it from the Measure tab.'
      : 'Run it from the Measure tab in Results.';

  void _dropMeasurement(CircuitLocation location) {
    final outcome = _session.insertMeasurement(location);
    final measurement = outcome.affectedGateId == null
        ? null
        : _activeCircuit.measurementById(outcome.affectedGateId!);
    if (!outcome.changed || measurement == null) {
      _rejectEdit(outcome.detail ?? 'A measurement cannot be placed there.');
      return;
    }
    _info('Measurement added: q${measurement.qubit} → '
        'c${measurement.classicalBit}. $_measurementRunNote');
  }

  void _moveMeasurement(GateId id, int column) {
    final outcome = _session.moveMeasurement(id, column);
    if (outcome.status == CircuitEditStatus.same) return;
    final measurement = _activeCircuit.measurementById(id);
    if (!outcome.changed || measurement == null) {
      _rejectEdit(outcome.detail ?? 'The measurement cannot move there.');
      return;
    }
    _session.select(id);
    _info('Measurement q${measurement.qubit} → '
        'c${measurement.classicalBit} moved.');
  }

  void _updateSelectedClassicalBit(int? classicalBit) {
    final measurement = _session.selectedMeasurement;
    if (measurement == null || classicalBit == null) return;
    final outcome = _session.setClassicalBit(measurement.id, classicalBit);
    if (!outcome.changed) {
      if (outcome.status != CircuitEditStatus.same) {
        _rejectEdit(outcome.detail ?? 'Invalid classical bit.');
      }
      return;
    }
    _info('Measurement q${measurement.qubit} now stores '
        'its outcome in c$classicalBit.');
  }

  Future<void> _handleDrop(ComposerCircuitDropIntent intent) async {
    final session = _session;
    final outcome = await _placement.drop(context, session, intent);
    if (!identical(session, _session)) return;
    // A drop refused with a reason (e.g. MCX on a register that is too
    // small, v2.6 M7) is shown in full, like other drop rejections.
    final detail = outcome.detail;
    if (!outcome.changed &&
        detail != null &&
        (outcome.status == CircuitEditStatus.unsupported ||
            outcome.status == CircuitEditStatus.invalid)) {
      _rejectEdit(detail);
      return;
    }
    _reportGateEdit(outcome);
  }

  void _clearCircuit() {
    final outcome = _session.clear();
    if (outcome.changed) {
      setState(() => _status = widget.clearedStatus);
    } else {
      _reportGateEdit(outcome);
    }
  }

  Future<void> _replaceSelectedGate(SelectedGateType type) async {
    final id = _session.selectedId;
    if (id == null) return;
    final session = _session;
    final outcome = await _placement.replace(context, session, id, type: type);
    if (identical(session, _session) &&
        outcome.status != CircuitEditStatus.unsupported) {
      _reportGateEdit(outcome);
    }
  }

  void _duplicateSelectedGate() {
    final id = _session.selectedId;
    if (id == null) return;
    _reportGateEdit(_session.duplicateGate(id));
  }

  void _deleteSelectedGate() {
    final measurement = _session.selectedMeasurement;
    if (measurement != null) {
      final outcome = _session.deleteOperation(measurement.id);
      if (!outcome.changed) {
        _rejectEdit(outcome.detail ?? 'The measurement could not be removed.');
        return;
      }
      _info('Measurement q${measurement.qubit} → '
          'c${measurement.classicalBit} removed.');
      return;
    }
    final id = _session.selectedId;
    if (id == null) return;
    _reportGateEdit(_session.deleteOperation(id));
  }

  /// Unmeasured: the ideal final state. Measured: the state immediately
  /// before measurement when that is well defined, otherwise why not.
  Widget _stateContent(
    List<Complex> stateVector,
    bool contentDriven, {
    String stateLabel = '|ψ⟩',
  }) {
    final level = _activeCircuit.currentLevel;
    // Target information is shown only when the activity reveals it.
    final showTarget = _session.policy.showsTargetState;
    return QuantumStateInspectorContent(
      currentPanelKey: const ValueKey('web-composer-current-state'),
      structuredLayout: true,
      stateLabel: stateLabel,
      targetPanelKey: const ValueKey('web-composer-target-state'),
      currentStateVector: stateVector,
      numQubits: level.numQubits,
      targetStateVector: showTarget
          ? level.solutionFinalVector.map((column) => column.first).toList()
          : const [],
      targetStateLabel: showTarget ? level.targetStateLabel : null,
      targetStateExpression: showTarget ? level.targetStateExpression : null,
      contentDriven: contentDriven,
      nonZeroOnly: _slot.nonZeroOnly,
      onNonZeroOnlyChanged: (value) =>
          setState(() => _slot.nonZeroOnly = value),
    );
  }

  static const String _preMeasurementNote =
      'The state just before measurement, not a sampled outcome. Measuring '
      'gives random results; use Measure to run the circuit.';

  Widget _buildStateViews(
    bool contentDriven,
    PreMeasurementState? preMeasurement,
  ) {
    if (preMeasurement == null) {
      return _stateContent(
          _activeCircuit.currentState.stateVector, contentDriven);
    }
    final state = preMeasurement.stateVector;
    if (state == null) {
      return Row(
        key: const ValueKey('web-composer-state-unavailable'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: QubitQuestColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(preMeasurement.unavailableReason!,
                style: QubitQuestTypography.supporting),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The laboratory's panel title already says "State before
        // measurement"; the classic results column needs the caption.
        if (!widget.laboratory)
          const Text(
            'Before measurement',
            key: ValueKey('web-composer-pre-measurement-caption'),
            style: TextStyle(
              color: QubitQuestColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        const Text(_preMeasurementNote, style: QubitQuestTypography.supporting),
        const SizedBox(height: 8),
        // The copied expression leaves this caption behind, so it names
        // the pre-measurement state itself.
        _stateContent(state, contentDriven, stateLabel: '|ψ_pre⟩'),
      ],
    );
  }

  /// The laboratory's Current State panel (v2.6 M11C.1): the ideal state,
  /// or the state just before measurement, or why there is none.
  Widget _buildLaboratoryState(PreMeasurementState? preMeasurement) {
    final numQubits = _activeCircuit.currentLevel.numQubits;
    if (preMeasurement != null && preMeasurement.stateVector == null) {
      return QqWorkspacePanel(
        key: const ValueKey('web-composer-state-unavailable'),
        label: 'State before measurement',
        child: Text(preMeasurement.unavailableReason!, style: QqType.meta),
      );
    }
    final measured = preMeasurement != null;
    return QqCurrentStatePanel(
      key: const ValueKey('web-composer-current-state'),
      stateVector: preMeasurement?.stateVector ??
          _activeCircuit.currentState.stateVector,
      numQubits: numQubits,
      title: measured ? 'State before measurement' : 'Current state',
      stateLabel: measured ? '|ψ_pre⟩' : '|ψ⟩',
      contextNote: measured
          ? 'Just before the measurements: not a sampled outcome. Use '
              'Measure to run the circuit.'
          : null,
      nonZeroOnly: _slot.nonZeroOnly,
      onNonZeroOnlyChanged: (value) =>
          setState(() => _slot.nonZeroOnly = value),
      precisionOpen: _openInspectorSections.contains('state-precision'),
      onPrecisionChanged: (open) => open
          ? _openInspectorSections.add('state-precision')
          : _openInspectorSections.remove('state-precision'),
    );
  }

  /// The single Measure tab for every circuit; the panel picks its wording
  /// from whether the circuit has M operations.
  Widget _buildMeasurePanel() => MeasuredCircuitRunPanel(
        splitLayout: widget.laboratory,
        measurements: _activeCircuit.measurements,
        numQubits: _activeCircuit.currentLevel.numQubits,
        running: _session.running,
        shots: _session.shots,
        onShotsChanged: (value) => _session.shots = value,
        onRunOnce: () => _session.run(manyShots: false),
        onRunShots: () => _session.run(manyShots: true),
        singleShot: _session.singleShot,
        shotsResult: _session.shotsResult,
        error: _session.runError,
        exact: _session.exactDistribution,
      );

  /// Palette preview: a gate *type* shown in the inspector, never placed.
  void _previewGate(SelectedGateType type) {
    _session.select(null);
    setState(() => _slot.previewType = type);
  }

  void _commitAngle(GateId id, double angle) =>
      _reportGateEdit(_session.editRotationAngle(id, angle));

  void _undo() {
    if (!_session.undo()) return;
    _info('Undone.');
  }

  void _redo() {
    if (!_session.redo()) return;
    _info('Redone.');
  }

  ComposerCircuitSummary get _circuitSummary => ComposerCircuitSummary(
        qubits: _activeCircuit.currentLevel.numQubits,
        depth: _activeCircuit.isCircuitEmpty()
            ? 0
            : _activeCircuit.maxCircuitDepth(),
        gates: _activeCircuit.logicalGates.length,
        measurements: _activeCircuit.measurements.length,
      );

  Widget _buildInspector(
    bool collapsed,
    VoidCallback? onToggle,
    bool expanded,
    VoidCallback? onToggleExpanded,
  ) {
    final measurement = _session.selectedMeasurement;
    final selectedId = _session.selectedId;
    final width = math.max(
      _activeCircuit.currentLevel.numQubits,
      _activeCircuit.classicalBitCount,
    );
    // A review-locked circuit stays inspectable; its edit actions are
    // removed here and rejected by the session regardless.
    final editable = !_session.readOnly;
    return GateInspectorPanel(
      summary: _circuitSummary,
      selectedGate: _session.selectedGate,
      selectedMeasurement: measurement,
      capabilities: editable
          ? _session.selectedCapabilities
          : ComposerSelectedGateCapabilities.none,
      previewType: _slot.previewType,
      classicalBitWidth: width,
      usedClassicalBits: {
        for (final other in _activeCircuit.measurements)
          if (other.id != measurement?.id) other.classicalBit: other.qubit,
      },
      replacementTypes: !editable || selectedId == null || measurement != null
          ? const []
          : ComposerPlacementFlow.replacementCandidates(_session, selectedId),
      collapsed: collapsed,
      onToggleCollapsed: onToggle,
      expanded: expanded,
      onToggleExpanded: onToggleExpanded,
      tab: _inspectorTab,
      onTabChanged: (tab) => setState(() => _inspectorTab = tab),
      onOpenRelatedConcept: widget.onOpenNotebookEntry,
      contextual: widget.laboratory || widget.learning,
      onClose: widget.laboratory || widget.learning ? _closeInspector : null,
      openSections: _openInspectorSections,
      onSectionChanged: (section, open) => open
          ? _openInspectorSections.add(section)
          : _openInspectorSections.remove(section),
      actions: GateInspectorActions(
        onReplace: _replaceSelectedGate,
        onDuplicate: _duplicateSelectedGate,
        onDelete: _deleteSelectedGate,
        onAngleCommitted: _commitAngle,
        onClassicalBitChanged: _updateSelectedClassicalBit,
      ),
    );
  }

  Widget _buildResults(
    bool collapsed,
    VoidCallback? onToggle,
    PreMeasurementState? preMeasurement,
  ) {
    final measured = _activeCircuit.hasMeasurements;
    final single = _session.singleShot;
    // After a single run of a one-qubit measured circuit, the Bloch view
    // can show that run's conditional state (a pure single-qubit state).
    final after = measured &&
            _activeCircuit.currentLevel.numQubits == 1 &&
            single?.conditionalState != null
        ? single
        : null;
    final showAfter = after != null && _blochAfterRun;
    return ComposerResultsPanel(
      selection: _resultsSelection,
      scrollController: _resultsScroll,
      collapsed: collapsed,
      onToggleCollapsed: onToggle,
      stateView: _buildStateViews(true, preMeasurement),
      measureView:
          _session.policy.runsExperiments ? _buildMeasurePanel() : null,
      currentStateVector: showAfter
          ? after.conditionalState!
          : preMeasurement?.stateVector ??
              _activeCircuit.currentState.stateVector,
      numQubits: _activeCircuit.currentLevel.numQubits,
      allowBloch: !measured || preMeasurement!.isAvailable || showAfter,
      blochCaption: !measured
          ? null
          : showAfter
              ? 'After the single run (outcome ${after.outcome})'
              : 'Before measurement',
      blochNote: !measured
          ? null
          : showAfter
              ? 'The state this run left after measuring. Another run may '
                  'give the other outcome and state.'
              : 'The state just before M, not a sampled outcome. '
                  'Measuring it gives 0 or 1 at random.',
      blochHeader: _blochHeader(after == null
          ? null
          : SegmentedButton<bool>(
              key: const ValueKey('bloch-pre-post-selector'),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -3),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
              segments: const [
                ButtonSegment(value: false, label: Text('Before measurement')),
                ButtonSegment(value: true, label: Text('After single run')),
              ],
              selected: {showAfter},
              onSelectionChanged: (v) =>
                  setState(() => _blochAfterRun = v.single),
            )),
      blochUnavailableMessage: measured && preMeasurement!.isAvailable
          ? null
          : preMeasurement?.unavailableReason,
      targetStateExpression: _session.policy.showsTargetState
          ? _activeCircuit.currentLevel.targetStateExpression
          : null,
    );
  }

  /// Closes the contextual inspector by clearing the selection and any
  /// palette preview. Never edits the circuit.
  void _closeInspector() {
    _session.select(null);
    setState(() => _slot.previewType = null);
  }

  bool get _inspecting =>
      _session.selectedId != null || _slot.previewType != null;

  /// The laboratory analysis workspace: the same state, Bloch and Measure
  /// content as [_buildResults], arranged centrally.
  Widget _buildAnalysis(PreMeasurementState? preMeasurement) {
    final measured = _activeCircuit.hasMeasurements;
    final single = _session.singleShot;
    final after = measured &&
            _activeCircuit.currentLevel.numQubits == 1 &&
            single?.conditionalState != null
        ? single
        : null;
    final showAfter = after != null && _blochAfterRun;
    final probabilityVector = measured
        ? preMeasurement?.stateVector
        : _activeCircuit.currentState.stateVector;
    return ComposerAnalysisWorkspace(
      selection: _analysisSelection,
      measured: measured,
      stateView: _buildLaboratoryState(preMeasurement),
      numQubits: _activeCircuit.currentLevel.numQubits,
      probabilityStateVector: probabilityVector,
      probabilityNote: probabilityVector == null
          ? 'This circuit has no single state before measurement (an '
              'operation follows a measurement). Use Measure to run it and '
              'see its outcomes.'
          : null,
      measureView:
          _session.policy.runsExperiments ? _buildMeasurePanel() : null,
      blochStateVector: showAfter
          ? after.conditionalState!
          : preMeasurement?.stateVector ??
              _activeCircuit.currentState.stateVector,
      allowBloch: !measured || preMeasurement!.isAvailable || showAfter,
      blochCaption: !measured
          ? null
          : showAfter
              ? 'After the single run (outcome ${after.outcome})'
              : 'Before measurement',
      blochNote: !measured
          ? null
          : showAfter
              ? 'The state this run left after measuring. Another run may '
                  'give the other outcome and state.'
              : 'The state just before M, not a sampled outcome. '
                  'Measuring it gives 0 or 1 at random.',
      onOpenBlochExplorer: _activeCircuit.currentLevel.numQubits == 1
          ? widget.onExploreInBloch
          : null,
      blochSelector: after == null
          ? null
          : SegmentedButton<bool>(
              key: const ValueKey('bloch-pre-post-selector'),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -3),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
              segments: const [
                ButtonSegment(value: false, label: Text('Before measurement')),
                ButtonSegment(value: true, label: Text('After single run')),
              ],
              selected: {showAfter},
              onSelectionChanged: (v) =>
                  setState(() => _blochAfterRun = v.single),
            ),
      blochUnavailableMessage: measured && preMeasurement!.isAvailable
          ? null
          : preMeasurement?.unavailableReason,
    );
  }

  Widget _buildLaboratory(PreMeasurementState? preMeasurement,
          {Widget? intro}) =>
      LaboratoryComposerWorkspace(
        key: widget.workspaceKey,
        intro: intro,
        shortcutsEnabled: widget.shortcutsEnabled,
        onUndo: _undo,
        onRedo: _redo,
        focusCircuit: widget.layout.focusCircuit,
        canvasHeight: _scaledDrawingHeight + _canvasChrome,
        header: ({required bool compact}) => ComposerWorkspaceToolbar(
          title: 'Quantum Composer',
          context: widget.contextLabel,
          qubitCount: _slot.qubitCount,
          qubitChoices: _session.policy.permittedQubitCounts.toList()..sort(),
          onSelectQubits: widget.onSelectQubits,
          inlineQubitSelector: true,
          canUndo: _session.canUndo,
          canRedo: _session.canRedo,
          onUndo: _undo,
          onRedo: _redo,
          clearLabel: widget.clearLabel ??
              (_session.policy.clearAction == ComposerClearAction.reset
                  ? 'Reset'
                  : 'Clear'),
          onClear: _clearCircuit,
          saveQueue: _session.saveQueue,
          focusCircuit: widget.layout.focusCircuit,
          onFocusCircuitChanged: (focus) => widget.layout.focusCircuit = focus,
          compact: compact,
        ),
        palette: (_) => ComposerGatePalettePanel(
          horizontal: true,
          circuitScale: _circuitScale,
          numQubits: _activeCircuit.currentLevel.numQubits,
          gates: _gates,
          allowsMeasurement: _session.policy.allowsMeasurement,
          previewedType: _slot.previewType,
          onPreview: _previewGate,
        ),
        narrowPalette: (_) => ComposerGatePalette(
          numQubits: _activeCircuit.currentLevel.numQubits,
          measurementDraggable: _session.policy.allowsMeasurement,
          gates: _gates,
          embedded: true,
          onGateTap: (gate) => _previewGate(gate.type),
          onInspectGate: (gate) => _previewGate(gate.type),
        ),
        canvas: (_) => _buildCanvasRegion(),
        analysis: (_) => _buildAnalysis(preMeasurement),
        inspector: _inspecting
            ? (_) => _buildInspector(false, null, false, null)
            : null,
        onCloseInspector: _closeInspector,
      );

  /// Undo, redo and reset for the learning layout (same commands and keys
  /// as the Composer toolbar).
  Widget _learningActions() {
    final reset = widget.clearLabel ??
        (_session.policy.clearAction == ComposerClearAction.reset
            ? 'Reset'
            : 'Clear');
    return Row(
      key: const ValueKey('lesson-workspace-actions'),
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('composer-undo'),
          tooltip: 'Undo',
          onPressed: _session.canUndo ? _undo : null,
          icon: const Icon(Icons.undo_rounded, size: 20),
        ),
        IconButton(
          key: const ValueKey('composer-redo'),
          tooltip: 'Redo',
          onPressed: _session.canRedo ? _redo : null,
          icon: const Icon(Icons.redo_rounded, size: 20),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          key: const ValueKey('web-clear-circuit'),
          onPressed: _clearCircuit,
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: Text(reset),
        ),
      ],
    );
  }

  Widget _learningPalette({required bool narrow}) {
    final label = Text(widget.learningPaletteLabel.toUpperCase(),
        key: const ValueKey('lesson-palette-label'),
        style: QqType.panelHeading.copyWith(color: QubitQuestColors.textMuted));
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [Expanded(child: label), _learningActions()]),
          const SizedBox(height: 6),
          ComposerGatePalette(
            numQubits: _activeCircuit.currentLevel.numQubits,
            measurementDraggable: false,
            gates: _gates,
            embedded: true,
            onGateTap: (gate) => _previewGate(gate.type),
            onInspectGate: (gate) => _previewGate(gate.type),
          ),
        ],
      );
    }
    return Row(
      key: const ValueKey('lesson-palette-row'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              label,
              const SizedBox(height: 8),
              ComposerGatePalettePanel(
                horizontal: true,
                circuitScale: _circuitScale,
                numQubits: _activeCircuit.currentLevel.numQubits,
                gates: _gates,
                allowsMeasurement: _session.policy.allowsMeasurement,
                previewedType: _slot.previewType,
                onPreview: _previewGate,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _learningActions(),
      ],
    );
  }

  /// The learning layout's analysis: the learner's state against the
  /// activity's target and its validation scope.
  Widget _buildLessonComparison() {
    final level = _activeCircuit.currentLevel;
    final showTarget = _session.policy.showsTargetState;
    return LessonStateComparison(
      key: const ValueKey('lesson-comparison'),
      currentState: _activeCircuit.currentState.stateVector,
      numQubits: level.numQubits,
      validationMode: level.validationMode,
      targetState: showTarget
          ? [for (final column in level.solutionFinalVector) column.first]
          : null,
      targetLabel: showTarget ? level.targetStateLabel : null,
      targetExpression: showTarget ? level.targetStateExpression : null,
      nonZeroOnly: _slot.nonZeroOnly,
      onNonZeroOnlyChanged: (value) =>
          setState(() => _slot.nonZeroOnly = value),
    );
  }

  Widget _buildLearning() => LaboratoryComposerWorkspace(
        key: widget.workspaceKey,
        shortcutsEnabled: widget.shortcutsEnabled,
        onUndo: _undo,
        onRedo: _redo,
        focusCircuit: false,
        canvasHeight: _scaledDrawingHeight + _canvasChrome,
        header: ({required bool compact}) => const SizedBox.shrink(),
        palette: (_) => _learningPalette(narrow: false),
        narrowPalette: (_) => _learningPalette(narrow: true),
        canvas: (_) => _buildCanvasRegion(),
        analysis: (_) => _buildLessonComparison(),
        inspector: _inspecting
            ? (_) => _buildInspector(false, null, false, null)
            : null,
        onCloseInspector: _closeInspector,
        naturalCanvasHeight: true,
        alignStart: true,
        intro: widget.learningIntro,
      );

  /// The Bloch tab's header: the pre/post selector, if any, and the
  /// "Explore in Bloch Explorer" action for one-qubit circuits (v2.6 M8).
  Widget? _blochHeader(Widget? selector) {
    final explore = widget.onExploreInBloch;
    final oneQubit = _activeCircuit.currentLevel.numQubits == 1;
    if (explore == null || !oneQubit) return selector;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selector != null) selector,
        TextButton.icon(
          key: const ValueKey('composer-explore-in-bloch'),
          onPressed: explore,
          icon: const Icon(Icons.language, size: 16),
          label: const Text('Explore step by step in the Bloch Explorer'),
        ),
      ],
    );
  }

  /// Scaled height of the circuit drawing (logical drawing × scale).
  double get _scaledDrawingHeight =>
      QuantumCircuitPainter.requiredDrawingHeightFor(
          _activeCircuit.currentLevel.numQubits) *
      _circuitScale;

  /// Header (36) + canvas padding and scrollbar room (26) + footer (34).
  static const double _canvasChrome = 96;

  Widget _buildCanvasRegion() {
    final measurable = _session.policy.allowsMeasurement;
    final drawingHeight = _scaledDrawingHeight;
    final summary = _circuitSummary;
    final operations = summary.gates + summary.measurements;
    return Column(
      key: const ValueKey('web-composer-circuit-stage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
          // Wraps (never shrinks) at narrow widths and large text sizes.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 2,
            children: [
              const Text('CIRCUIT', style: workspacePanelTitle),
              CircuitScaleControl(
                scale: _circuitScale,
                onChanged: _setCircuitScale,
              ),
            ],
          ),
        ),
        // Content-sized (M3.1): the drawing takes the height it needs and the
        // summary footer sits directly below the last wire. Scrolls when
        // space is short.
        Flexible(
          child: SingleChildScrollView(
            key: const ValueKey('web-composer-canvas-vertical-scroll'),
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: MouseRegion(
              key: const ValueKey('web-composer-canvas-pointer-area'),
              cursor: SystemMouseCursors.precise,
              child: SizedBox(
                key: const ValueKey('web-composer-canvas'),
                height: drawingHeight + 20,
                child: ComposerCircuitCanvas(
                  scale: _circuitScale,
                  pinnedQubitLabels: true,
                  wireColor: const Color(0x8CC9D6EA),
                  markFixedGates: widget.markFixedGates,
                  onFixedGateDragAttempted: widget.markFixedGates
                      ? (_) => _rejectEdit('this gate is part of the '
                          'activity\'s setup and cannot be moved or removed.')
                      : null,
                  onMeasurementDropped: measurable ? _dropMeasurement : null,
                  onMeasurementMoved: measurable ? _moveMeasurement : null,
                  onDropRejected: measurable ? _rejectEdit : null,
                  onMeasurementSelected: measurable ? _session.select : null,
                  circuit: _activeCircuit,
                  enableDesktopHorizontalScrolling: true,
                  surfaceTreatment: ComposerCircuitSurfaceTreatment.workbench,
                  selectedGateId: _session.selectedId,
                  onGateTap: (gate) => _session.select(gate?.id),
                  onDropRequested: _handleDrop,
                  onPlacedGateDragStarted: (gate) => _session.select(gate.id),
                  onDeletePlacedGateRequested: (gate) =>
                      _reportGateEdit(_session.deleteOperation(gate.id)),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          // One line at every width and text size, so status messages never
          // resize the canvas viewport; long text is ellipsised.
          child: Row(
            children: [
              // The summary is authoritative and keeps priority; status
              // appears only when it adds information (M3.1).
              Flexible(
                  flex: 3,
                  child: Text(
                    '${summary.qubits} qubit${summary.qubits == 1 ? '' : 's'} · '
                    '$operations operation${operations == 1 ? '' : 's'}'
                    '${summary.measurements == 0 ? '' : ' · ${summary.measurements} '
                        'measurement${summary.measurements == 1 ? '' : 's'}'}',
                    key: const ValueKey('composer-circuit-summary'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QubitQuestTypography.supporting,
                  )),
              if (_status.isEmpty)
                const Text('', key: ValueKey('web-storage-status'))
              else ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Tooltip(
                    message: _status,
                    child: Text(
                      _status,
                      key: const ValueKey('web-storage-status'),
                      textAlign: TextAlign.right,
                      // Two lines (v2.6 M9); the tooltip has the full text.
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: QubitQuestTypography.supporting
                          .copyWith(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.showLegacyMeasurementNote &&
            _activeCircuit.hasPostMeasurementOperations)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'This saved circuit applies operations to a qubit after it was '
              'measured. It is kept exactly as saved; edits that would add '
              'more operations after a measurement are rejected.',
              key: ValueKey('web-composer-legacy-measurement-note'),
              style: QubitQuestTypography.supporting,
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar({
    required bool compact,
    required List<WorkspacePanelToggle> toggles,
    required VoidCallback? onResetLayout,
    required ComposerWorkspaceView? view,
    required ValueChanged<ComposerWorkspaceView>? onViewChanged,
  }) =>
      ComposerWorkspaceToolbar(
        title: 'Quantum Composer',
        context: widget.contextLabel,
        qubitCount: _slot.qubitCount,
        qubitChoices: _session.policy.permittedQubitCounts.toList()..sort(),
        onSelectQubits: widget.onSelectQubits,
        // The Composer opens straight into the Sandbox (M11C): the size is
        // always one visible choice in the header.
        inlineQubitSelector: true,
        canUndo: _session.canUndo,
        canRedo: _session.canRedo,
        onUndo: _undo,
        onRedo: _redo,
        clearLabel: widget.clearLabel ??
            (_session.policy.clearAction == ComposerClearAction.reset
                ? 'Reset'
                : 'Clear'),
        onClear: _clearCircuit,
        saveQueue: _session.saveQueue,
        panelToggles: toggles,
        onResetLayout: onResetLayout,
        view: view,
        onViewChanged: onViewChanged,
        compact: compact,
      );

  /// The laboratory reads the Analysis / Focus mode from the layout
  /// controller; the classic layout listens to it on its own.
  void _layoutChanged() {
    if (mounted && widget.laboratory) setState(() {});
  }

  bool get _scrollingHeader =>
      widget.laboratory &&
      widget.header != null &&
      widget.headerScrollsBelow != null &&
      MediaQuery.sizeOf(context).width < widget.headerScrollsBelow!;

  @override
  Widget build(BuildContext context) {
    final preMeasurement = _session.preMeasurement;
    final workspace = widget.learning
        ? _buildLearning()
        : widget.laboratory
            ? _buildLaboratory(preMeasurement,
                intro: _scrollingHeader ? widget.header : null)
            : DesktopComposerWorkspace(
                key: widget.workspaceKey,
                layout: widget.layout,
                shortcutsEnabled: widget.shortcutsEnabled,
                inspectorIdle:
                    _session.selectedId == null && _slot.previewType == null,
                onUndo: _undo,
                onRedo: _redo,
                canvasMinHeight: _scaledDrawingHeight + _canvasChrome,
                toolbar: _buildToolbar,
                palette: (collapsed, onToggle) => ComposerGatePalettePanel(
                  circuitScale: _circuitScale,
                  numQubits: _activeCircuit.currentLevel.numQubits,
                  gates: _gates,
                  allowsMeasurement: _session.policy.allowsMeasurement,
                  previewedType: _slot.previewType,
                  onPreview: _previewGate,
                  collapsed: collapsed,
                  onToggleCollapsed: onToggle,
                ),
                narrowPalette: (_) => ComposerGatePalette(
                  measurementDraggable: _session.policy.allowsMeasurement,
                  gates: _gates,
                  embedded: true,
                  onGateTap: (gate) => _previewGate(gate.type),
                  // The stacked layout keeps the integrated inspector below the
                  // canvas, so inspection previews there instead of opening a modal.
                  onInspectGate: (gate) => _previewGate(gate.type),
                ),
                canvas: (_) => _buildCanvasRegion(),
                inspector: _buildInspector,
                results: (collapsed, onToggle) =>
                    _buildResults(collapsed, onToggle, preMeasurement),
              );
    // The classic layout has no scrolling intro: a narrow host's header is
    // shown fixed above it instead.
    final intro = widget.learning ? null : widget.learningIntro;
    final header = (_scrollingHeader ? null : widget.header) ??
        (intro == null
            ? null
            : ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .45),
                child: SingleChildScrollView(child: intro),
              ));
    final footer = widget.footer;
    if (header == null && footer == null) return workspace;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header,
        Expanded(child: workspace),
        if (footer != null) footer,
      ],
    );
  }
}

/// Learner-facing wording for an edit the session did not commit.
String editResultMessage(CircuitEditOutcome outcome) {
  final detail = outcome.detail;
  if (detail != null &&
      (outcome.status == CircuitEditStatus.invalid ||
          outcome.status == CircuitEditStatus.unsupported ||
          outcome.status == CircuitEditStatus.protected)) {
    return 'Not changed: $detail';
  }
  return switch (outcome.status) {
    CircuitEditStatus.protected =>
      'Not changed: this operation is part of the activity and stays fixed.',
    CircuitEditStatus.unsupported =>
      'Not changed: that edit is not available here.',
    _ => 'Edit result: ${outcome.status.name}',
  };
}
