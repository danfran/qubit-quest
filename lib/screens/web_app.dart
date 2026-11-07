import '../models/sandbox_program_snapshot.dart';
import '../widgets/sandbox_load_recovery.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:quantumquiz/widgets/progress_save_feedback.dart';
import 'package:quantumquiz/models/circuit_save_queue.dart';
import 'package:quantumquiz/widgets/circuit_save_status.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/composer_gate_capabilities.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_measurement_result.dart';
import 'package:quantumquiz/widgets/measurement_results_view.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/gate_replacement_dialog.dart';
import 'package:quantumquiz/screens/rotation_gate_dialog.dart';
import 'package:quantumquiz/screens/controlled_gate_placement_dialog.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/storage/shared_preferences_app_storage.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/bloch_explorer_panels.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';
import 'package:quantumquiz/widgets/circuit_canvas_metrics.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart'
    show defaultNonZeroOnlyForQubitCount;
import 'package:quantumquiz/widgets/quantum_state_inspector_content.dart';
import 'package:quantumquiz/widgets/web_composer_workbench.dart';

const _background = QubitQuestColors.background;
const _surface = QubitQuestColors.surface;
const _cyan = QubitQuestColors.accentInteractive;
const _purple = QubitQuestColors.accentStrong;

enum WebDestination { journey, notebook, mastery, composer, bloch }

class QubitQuestWebApp extends StatelessWidget {
  QubitQuestWebApp({
    super.key,
    this.storage = const SharedPreferencesAppStorage(),
  })  : progressController = CampaignProgressController(
          store: SharedPreferencesCampaignProgressStore(storage: storage),
        ),
        sandboxPersistenceStore = SandboxPersistenceStore(storage: storage) {
    CampaignProgressController.configureSharedInstance(progressController);
  }

  final AppStorage storage;
  final CampaignProgressController progressController;
  final SandboxPersistenceStore sandboxPersistenceStore;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Qubit Quest',
        debugShowCheckedModeBanner: false,
        theme: QubitQuestTheme.web(),
        home: QubitQuestWebShell(
          progressController: progressController,
          sandboxPersistenceStore: sandboxPersistenceStore,
        ),
      );
}

class QubitQuestWebShell extends StatefulWidget {
  const QubitQuestWebShell({
    super.key,
    required this.progressController,
    required this.sandboxPersistenceStore,
  });

  final CampaignProgressController progressController;
  final SandboxPersistenceStore sandboxPersistenceStore;

  @override
  State<QubitQuestWebShell> createState() => _QubitQuestWebShellState();
}

class _QubitQuestWebShellState extends State<QubitQuestWebShell> {
  static const double _wideNavigationBreakpoint = 900;
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  WebDestination _destination = WebDestination.journey;
  String? _requestedNotebookDiscoveryTitle;
  ExecutableNotebookExample? _requestedComposerExample;
  BlochState? _requestedBlochState;

  @override
  void initState() {
    super.initState();
    unawaited(widget.progressController.load());
  }

  void _select(WebDestination destination) {
    setState(() {
      if (destination == WebDestination.composer) {
        _requestedComposerExample = null;
      }
      _destination = destination;
    });
  }

  void _openNotebook([String? discoveryTitle]) {
    setState(() {
      _requestedNotebookDiscoveryTitle = discoveryTitle;
      _destination = WebDestination.notebook;
    });
  }

  void _openMastery() {
    _select(WebDestination.mastery);
  }

  void _openNotebookExampleInComposer(ExecutableNotebookExample example) {
    setState(() {
      _requestedComposerExample = example;
      _destination = WebDestination.composer;
    });
  }

  void _openNotebookExampleInBloch(
    ExecutableNotebookExample example,
    ExecutableNotebookResult result,
  ) {
    if (example.qubitCount != 1 || result.state.length != 2) return;
    setState(() {
      _requestedBlochState = BlochState.fromAmplitudes(
        result.state[0],
        result.state[1],
      );
      _destination = WebDestination.bloch;
    });
  }

  Widget _workspace() => IndexedStack(
        index: _destination.index,
        children: [
          WebJourneyWorkspace(
            progressController: widget.progressController,
            onOpenNotebook: _openNotebook,
            onOpenNotebookEntry: _openNotebook,
            onOpenMastery: _openMastery,
          ),
          WebNotebookWorkspace(
            key: const ValueKey('web-workspace-notebook'),
            progressController: widget.progressController,
            requestedDiscoveryTitle: _requestedNotebookDiscoveryTitle,
            onOpenJourney: () => _select(WebDestination.journey),
            onOpenExampleInComposer: _openNotebookExampleInComposer,
            onOpenExampleInBlochExplorer: _openNotebookExampleInBloch,
          ),
          WebMasteryWorkspace(
            key: const ValueKey('web-workspace-mastery'),
            progressController: widget.progressController,
            onBackToJourney: () => _select(WebDestination.journey),
            onOpenNotebook: _openNotebook,
            onOpenNotebookEntry: _openNotebook,
          ),
          _ComposerWorkspace(
            key: const ValueKey('web-workspace-composer'),
            persistence: widget.sandboxPersistenceStore,
            example: _requestedComposerExample,
            isActive: _destination == WebDestination.composer,
          ),
          _BlochWorkspace(
            key: const ValueKey('web-workspace-bloch'),
            requestedInitialState: _requestedBlochState,
            onOpenNotebookEntry: _openNotebook,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideNavigationBreakpoint;
          final navigation = AnimatedBuilder(
            animation: widget.progressController,
            builder: (context, _) => _WebNavigation(
              selected: _destination,
              packageInfo: _packageInfo,
              masteryUnlocked: true,
              onSelected: (destination) {
                if (!wide) Navigator.of(context).pop();
                if (destination == WebDestination.mastery) {
                  if (wide) {
                    _openMastery();
                  } else {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _openMastery());
                  }
                } else {
                  _select(destination);
                }
              },
            ),
          );
          return Scaffold(
            key: const ValueKey('web-shell'),
            bottomNavigationBar:
                ProgressSaveStatusView(controller: widget.progressController),
            backgroundColor: _background,
            appBar: AppBar(
              leading: wide
                  ? null
                  : Builder(
                      builder: (context) => IconButton(
                        key: const ValueKey('web-navigation-menu'),
                        tooltip: 'Open navigation',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu),
                      ),
                    ),
              automaticallyImplyLeading: !wide,
              title: const _QubitQuestWordmark(),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: Color(0x44344A73)),
              ),
            ),
            drawer: wide
                ? null
                : Drawer(
                    key: const ValueKey('web-navigation-drawer'),
                    backgroundColor: _surface,
                    child: SafeArea(child: navigation),
                  ),
            body: Row(
              children: [
                if (wide) ...[
                  SizedBox(
                    key: const ValueKey('web-navigation-sidebar'),
                    width: 238,
                    child: navigation,
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: Color(0x44344A73),
                  ),
                ],
                Expanded(
                  key: const ValueKey('web-workspace-host'),
                  child: _workspace(),
                ),
              ],
            ),
          );
        },
      );
}

class _QubitQuestWordmark extends StatelessWidget {
  const _QubitQuestWordmark();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Qubit Quest',
        image: true,
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          key: const ValueKey('web-qubit-quest-wordmark'),
          height: 30,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
      );
}

class _WebNavigation extends StatelessWidget {
  const _WebNavigation({
    required this.selected,
    required this.packageInfo,
    required this.masteryUnlocked,
    required this.onSelected,
  });

  final WebDestination selected;
  final Future<PackageInfo> packageInfo;
  final bool masteryUnlocked;
  final ValueChanged<WebDestination> onSelected;

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
            child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
          children: [
            const _NavigationHeading('LEARN'),
            _item(WebDestination.journey, Icons.route_outlined, 'Journey'),
            _item(
                WebDestination.notebook, Icons.menu_book_outlined, 'Notebook'),
            _item(
              WebDestination.mastery,
              masteryUnlocked
                  ? Icons.workspace_premium_outlined
                  : Icons.lock_outline,
              'Mastery Challenges',
              locked: !masteryUnlocked,
            ),
            const SizedBox(height: 22),
            const _NavigationHeading('EXPLORE'),
            _item(WebDestination.composer, Icons.account_tree_outlined,
                'Composer'),
            _item(WebDestination.bloch, Icons.blur_circular, 'Bloch Explorer'),
          ],
        )),
        FutureBuilder<PackageInfo>(
          future: packageInfo,
          builder: (context, snapshot) {
            final info = snapshot.data;
            if (info == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Divider(color: QubitQuestColors.borderSoft),
                const SizedBox(height: 8),
                Text(
                  'Web v${info.version} · Build ${info.buildNumber}',
                  key: const ValueKey('web-navigation-version'),
                  textAlign: TextAlign.center,
                  style: QubitQuestTypography.supporting
                      .copyWith(color: QubitQuestColors.textMuted),
                ),
              ]),
            );
          },
        ),
      ]);

  Widget _item(
    WebDestination destination,
    IconData icon,
    String label, {
    bool locked = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          key: ValueKey('web-nav-${destination.name}'),
          selected: selected == destination,
          selectedColor: _cyan,
          selectedTileColor: const Color(0x2222D3EE),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon),
          title: Text(
            label,
            style: TextStyle(
              color: locked ? Colors.white54 : null,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: locked
              ? const Icon(
                  Icons.lock_outline,
                  key: ValueKey('web-nav-mastery-lock'),
                  size: 16,
                  color: Colors.white38,
                )
              : null,
          onTap: () => onSelected(destination),
        ),
      );
}

class _NavigationHeading extends StatelessWidget {
  const _NavigationHeading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Text(
          label,
          style: const TextStyle(
            color: _purple,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      );
}

class _ComposerWorkspace extends StatefulWidget {
  const _ComposerWorkspace({
    super.key,
    required this.persistence,
    required this.isActive,
    this.example,
  });
  final SandboxPersistenceStore persistence;
  final bool isActive;
  final ExecutableNotebookExample? example;

  @override
  State<_ComposerWorkspace> createState() => _ComposerWorkspaceState();
}

class _ComposerWorkspaceState extends State<_ComposerWorkspace> {
  QuantumCircuit? _circuit;
  QuantumMeasurementResult? _measurementResult;
  int? _selectedQubitCount;
  GateId? _selectedGateId;
  CircuitSaveQueue get _saves =>
      widget.persistence.programs.queue(_selectedQubitCount!);
  bool _opening = false;
  bool _previouslyMeasured = false;
  void _definitionChanged() {
    if (widget.example == null && _circuit != null) {
      final becameUnitary =
          _previouslyMeasured && !_activeCircuit.hasMeasurements;
      _previouslyMeasured = _activeCircuit.hasMeasurements;
      if (becameUnitary) _activeCircuit.runSimulation();
      unawaited(
          _saves.saveProgram(SandboxProgramSnapshot.capture(_activeCircuit)));
      if (mounted) setState(() => _measurementResult = null);
    }
  }

  String _status = 'Choose a circuit size to open the Sandbox.';
  bool? _nonZeroOnly;

  QuantumCircuit get _activeCircuit => _circuit!;

  List<Gate> get _gates => [
        for (final gate in _activeCircuit.currentLevel.availableGates)
          Gate.fromIdentifier(gate.type, angle: gate.angle),
      ];

  @override
  void initState() {
    super.initState();
    if (widget.example != null) {
      _circuit = _newCircuit();
      _selectedQubitCount = _activeCircuit.currentLevel.numQubits;
      _nonZeroOnly = defaultNonZeroOnlyForQubitCount(
        _activeCircuit.currentLevel.numQubits,
      );
      _status = 'Notebook example: ${widget.example!.title}';
    }
  }

  QuantumCircuit _newCircuit({int? qubitCount, String? initialBinaryState}) =>
      QuantumCircuit(
        currentLevel: widget.example?.createEditableComposerLevel() ??
            createSandboxComposerLevel(
              qubitCount!,
              initialBinaryState: initialBinaryState,
            ),
      );

  @override
  void didUpdateWidget(covariant _ComposerWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive) _measurementResult = null;
    if (!identical(oldWidget.example, widget.example)) {
      _circuit?.removeListener(_definitionChanged);
      _circuit?.dispose();
      setState(() {
        _measurementResult = null;
        _circuit = widget.example == null ? null : _newCircuit();
        _selectedQubitCount = widget.example == null
            ? null
            : _activeCircuit.currentLevel.numQubits;
        _selectedGateId = null;
        _nonZeroOnly = widget.example == null
            ? null
            : defaultNonZeroOnlyForQubitCount(
                _activeCircuit.currentLevel.numQubits,
              );
        _status = widget.example == null
            ? 'Choose a circuit size to open the Sandbox.'
            : 'Notebook example: ${widget.example!.title}';
      });
    }
  }

  @override
  void dispose() {
    _circuit?.removeListener(_definitionChanged);
    _circuit?.dispose();
    super.dispose();
  }

  Future<void> _openSandbox(int qubitCount) async {
    if (_opening) return;
    _opening = true;
    if (_openError != null) setState(() => _openError = null);
    QuantumCircuit? nextCircuit;
    var installed = false;
    try {
      final loaded = await loadSandboxWithRecovery(
          context, widget.persistence.programs, qubitCount);
      if (!mounted || !loaded.opened || widget.example != null) return;
      final snapshot = loaded.snapshot;
      nextCircuit =
          snapshot?.restoreCircuit() ?? _newCircuit(qubitCount: qubitCount);
      if (!nextCircuit.hasMeasurements) nextCircuit.runSimulation();
      _circuit?.removeListener(_definitionChanged);
      _circuit?.dispose();
      installed = true;
      setState(() {
        _measurementResult = null;
        _circuit = nextCircuit;
        _selectedQubitCount = qubitCount;
        _selectedGateId = null;
        _nonZeroOnly = defaultNonZeroOnlyForQubitCount(qubitCount);
        _status = snapshot == null
            ? 'Ready — changes save in this browser.'
            : 'Restored ${snapshot.program.operations.length} saved '
                'operation(s).';
      });
      _previouslyMeasured = nextCircuit.hasMeasurements;
      nextCircuit.addListener(_definitionChanged);
    } catch (error, stackTrace) {
      // Unexpected initialization/restoration failures (recoverable storage
      // errors are handled by loadSandboxWithRecovery). Never substitute an
      // empty circuit: saved records stay untouched for the next attempt.
      debugPrint('Unable to open $qubitCount-qubit Sandbox: $error\n'
          '$stackTrace');
      if (!installed) nextCircuit?.dispose();
      if (!mounted) return;
      final message = 'Could not open the $qubitCount-qubit Sandbox. '
          'Saved circuits were kept. Please try again.';
      setState(() {
        _openError = message;
        _status = message;
      });
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      _opening = false;
    }
  }

  String? _openError;

  Future<void> _commit(CircuitEditOutcome outcome) async {
    if (outcome.changed) {
      setState(() => _measurementResult = null);
      if (!_activeCircuit.hasMeasurements) _activeCircuit.runSimulation();
      if (widget.example == null) {
        unawaited(
            _saves.saveProgram(SandboxProgramSnapshot.capture(_activeCircuit)));
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedGateId = outcome.affectedGateId ?? _selectedGateId;
      _status = outcome.changed
          ? widget.example == null
              ? _operationSummary()
              : 'Updated Notebook example (${_activeCircuit.logicalGates.length} operation(s)).'
          : _editResultMessage(outcome);
    });
  }

  /// Gates plus measurements, e.g. "3 operation(s) in circuit (1 measurement)."
  String _operationSummary() {
    final measurements = _activeCircuit.measurements.length;
    final total = _activeCircuit.logicalGates.length + measurements;
    return measurements == 0
        ? '$total operation(s) in circuit.'
        : '$total operation(s) in circuit ($measurements measurement'
            '${measurements == 1 ? '' : 's'}).';
  }

  String _editResultMessage(CircuitEditOutcome outcome) {
    final detail = outcome.detail;
    if (detail != null &&
        (outcome.status == CircuitEditStatus.invalid ||
            outcome.status == CircuitEditStatus.unsupported)) {
      return 'Not changed: $detail';
    }
    return 'Edit result: ${outcome.status.name}';
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

  static const String _measurementExecutionNote =
      'Measurements are circuit instructions; their results will appear '
      'once circuit execution is supported.';

  void _dropMeasurement(CircuitLocation location) {
    final circuit = _activeCircuit;
    final outcome = circuit.insertMeasurementWithOutcome(
      qubit: location.qubit,
      column: location.column,
    );
    final measurement = outcome.affectedGateId == null
        ? null
        : circuit.measurementById(outcome.affectedGateId!);
    if (!outcome.changed || measurement == null) {
      _rejectEdit(outcome.detail ?? 'A measurement cannot be placed there.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _selectedGateId = measurement.id;
      _status = 'Measurement added: q${measurement.qubit} → '
          'c${measurement.classicalBit}. $_measurementExecutionNote';
    });
  }

  void _selectMeasurement(GateId id) {
    final measurement = _activeCircuit.measurementById(id);
    if (measurement == null) return;
    setState(() {
      _selectedGateId = id;
      _status = 'Selected measurement q${measurement.qubit} → '
          'c${measurement.classicalBit}.';
    });
  }

  void _moveMeasurement(GateId id, int column) {
    final outcome = _activeCircuit.moveMeasurementWithOutcome(id, column);
    if (outcome.status == CircuitEditStatus.same) return;
    final measurement = _activeCircuit.measurementById(id);
    if (!outcome.changed || measurement == null) {
      _rejectEdit(outcome.detail ?? 'The measurement cannot move there.');
      return;
    }
    setState(() {
      _selectedGateId = id;
      _status = 'Measurement q${measurement.qubit} → '
          'c${measurement.classicalBit} moved. ${_operationSummary()}';
    });
  }

  void _updateSelectedClassicalBit(int? classicalBit) {
    final id = _selectedGateId;
    if (id == null || classicalBit == null) return;
    final measurement = _activeCircuit.measurementById(id);
    if (measurement == null) return;
    final outcome = _activeCircuit.updateMeasurementClassicalBitWithOutcome(
        id, classicalBit);
    if (!outcome.changed) {
      if (outcome.status != CircuitEditStatus.same) {
        _rejectEdit(outcome.detail ?? 'Invalid classical bit.');
      }
      return;
    }
    setState(() => _status = 'Measurement q${measurement.qubit} now stores '
        'its outcome in c$classicalBit.');
  }

  Future<void> _handleDrop(ComposerCircuitDropIntent intent) async {
    var gate = intent.data.gate;
    final location = intent.destination.location;
    if (!intent.data.isPlaced && gate.requiresAngle && gate.angle == null) {
      final angle = await _chooseRotationAngle(gate.type);
      if (!mounted || angle == null) return;
      gate = Gate.fromIdentifier(gate.type, angle: angle);
    }
    ControlledGatePlacement? controlledPlacement;
    if (!intent.data.isPlaced &&
        (gate.type == SelectedGateType.cnot ||
            gate.type == SelectedGateType.cz ||
            gate.type == SelectedGateType.ccnot)) {
      controlledPlacement = await showControlledGatePlacementDialog(
        context,
        gateType: gate.type,
        targetQubit: location.qubit,
        numQubits: _activeCircuit.currentLevel.numQubits,
      );
      if (!mounted || controlledPlacement == null) return;
    }
    final outcome = intent.data.isPlaced
        ? _activeCircuit.commitLogicalGateMovePlan(
            intent.movePlan ??
                _activeCircuit.planLogicalGateMove(
                  intent.data.sourceId!,
                  location,
                ),
          )
        : switch (gate.type) {
            SelectedGateType.cnot ||
            SelectedGateType.cz =>
              _activeCircuit.insertDoubleGateWithOutcome(
                gate,
                location.column,
                location.qubit,
                controlledPlacement!.controlQubit,
              ),
            SelectedGateType.ccnot =>
              _activeCircuit.insertTripleGateWithOutcome(
                gate,
                location.column,
                location.qubit,
                controlledPlacement!.controlQubit,
                controlledPlacement.secondControlQubit!,
              ),
            _ => _activeCircuit.insertSingleGateWithOutcome(
                gate,
                location.column,
                location.qubit,
              ),
          };
    await _commit(outcome);
  }

  Future<void> _inspect(Gate gate) => showDialog<void>(
        context: context,
        builder: (_) => GateInspectorDialog.forGate(
          gate: gate,
          info: GateEducationalCatalog.forType(gate.type),
        ),
      );

  void _runAndMeasure() {
    if (widget.example != null) return;
    final error = _activeCircuit.lastSimulationError;
    if (error != null) {
      setState(() {
        _measurementResult = null;
        _status = error.userMessage;
      });
      return;
    }
    if (_activeCircuit.hasMeasurements) return;
    try {
      final result = QuantumMeasurementResult.sample(
        stateVector: _activeCircuit.currentState.stateVector,
        numQubits: _activeCircuit.currentLevel.numQubits,
      );
      setState(() => _measurementResult = result);
    } on ArgumentError {
      setState(() {
        _measurementResult = null;
        _status =
            'This circuit cannot be measured. Check its state and try again.';
      });
    }
  }

  Future<void> _clearCircuit() async {
    if (!_activeCircuit.isCircuitEmpty()) {
      setState(() => _measurementResult = null);
    }
    _activeCircuit.clearPlacedGates();
    if (widget.example == null) {
      unawaited(
          _saves.saveProgram(SandboxProgramSnapshot.capture(_activeCircuit)));
    }
    if (!mounted) return;
    setState(() {
      _selectedGateId = null;
      _status = widget.example == null
          ? 'Circuit cleared.'
          : 'Cleared Notebook example.';
    });
  }

  void _closeCircuit() => setState(() {
        _circuit?.removeListener(_definitionChanged);
        _circuit?.dispose();
        _circuit = null;
        _measurementResult = null;
        _selectedQubitCount = null;
        _selectedGateId = null;
        _status = 'Choose a circuit size to open the Sandbox.';
      });

  Future<double?> _chooseRotationAngle(
    SelectedGateType gateType, {
    double? initialAngle,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => RotationGateDialog(
        gateType: gateType,
        initialAngle: initialAngle,
      ),
    );
    return result?['angle1'] as double?;
  }

  Future<void> _editSelectedRotationAngle() async {
    final selectedId = _selectedGateId;
    if (selectedId == null) return;
    final footprint = _activeCircuit.logicalGateById(selectedId);
    if (footprint == null || !footprint.isParameterEditable) return;
    final angle = await _chooseRotationAngle(
      footprint.type,
      initialAngle: footprint.gate.angle,
    );
    if (!mounted || angle == null) return;
    await _commit(
      _activeCircuit.updateGateParametersWithOutcome(selectedId, angle: angle),
    );
  }

  Future<void> _inspectSelectedGate() async {
    final selectedId = _selectedGateId;
    if (selectedId == null) return;
    final footprint = _activeCircuit.logicalGateById(selectedId);
    if (footprint != null) await _inspect(footprint.gate);
  }

  Future<void> _replaceSelectedGate() async {
    final selectedId = _selectedGateId;
    if (selectedId == null) return;
    final footprint = _activeCircuit.logicalGateById(selectedId);
    if (footprint == null || !footprint.isEditable) return;
    final candidates = _activeCircuit.availableSingleQubitReplacementTypes
        .where((type) => type != footprint.type)
        .toList(growable: false);
    if (candidates.isEmpty) return;
    final replacementType = await showDialog<SelectedGateType>(
      context: context,
      builder: (_) => GateReplacementDialog(gateTypes: candidates),
    );
    if (!mounted || replacementType == null) return;
    double? angle;
    if (Gate.fromIdentifier(replacementType).requiresAngle) {
      angle = await _chooseRotationAngle(replacementType);
      if (!mounted || angle == null) return;
    }
    await _commit(
      _activeCircuit.replaceSingleGateWithOutcome(
        selectedId,
        Gate.fromIdentifier(replacementType, angle: angle),
      ),
    );
  }

  Future<void> _duplicateSelectedGate() async {
    final selectedId = _selectedGateId;
    if (selectedId == null) return;
    await _commit(_activeCircuit.duplicateLogicalGateWithOutcome(selectedId));
  }

  Future<void> _deleteSelectedGate() async {
    final selectedId = _selectedGateId;
    if (selectedId == null) return;
    final measurement = _activeCircuit.measurementById(selectedId);
    if (measurement != null) {
      final outcome = _activeCircuit.removeMeasurementWithOutcome(selectedId);
      if (!outcome.changed) {
        _rejectEdit(outcome.detail ?? 'The measurement could not be removed.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _selectedGateId = null;
        _status = 'Measurement q${measurement.qubit} → '
            'c${measurement.classicalBit} removed. ${_operationSummary()}';
      });
      return;
    }
    await _commit(_activeCircuit.removeLogicalGateByIdWithOutcome(selectedId));
    if (mounted) setState(() => _selectedGateId = null);
  }

  String _selectedGateSummary() {
    final selectedId = _selectedGateId;
    final gate =
        selectedId == null ? null : _activeCircuit.logicalGateById(selectedId);
    if (gate == null) return '';
    if (gate.type == SelectedGateType.ccnot) {
      return '${gate.gate.label}: controls Q${gate.controlQubit}, '
          'Q${gate.secondControlQubit} → target Q${gate.targetQubit}';
    }
    if (gate.isControlled) {
      return '${gate.gate.label}: control Q${gate.controlQubit} '
          '→ target Q${gate.targetQubit}';
    }
    return gate.gate.label.replaceAll('\n', ' ');
  }

  Widget _buildQubitChooser() => _WorkspaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ComposerSectionHeading(
              title: 'Choose Number of Qubits',
              icon: Icons.memory_outlined,
            ),
            const SizedBox(height: 8),
            const Text(
              'Open the sandbox with a circuit size.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var qubits = 1; qubits <= 5; qubits++)
                  FilledButton(
                    key: ValueKey('web-composer-qubits-$qubits'),
                    onPressed: () => _openSandbox(qubits),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, 58),
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Text('$qubits'),
                  ),
              ],
            ),
            if (_openError != null) ...[
              const SizedBox(height: 12),
              Text(
                _openError!,
                key: const ValueKey('web-composer-open-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      );

  Widget _buildStateViews(bool contentDriven) => _activeCircuit.hasMeasurements
      ? const UnexecutedMeasuredCircuit()
      : QuantumStateInspectorContent(
          currentPanelKey: const ValueKey('web-composer-current-state'),
          targetPanelKey: const ValueKey('web-composer-target-state'),
          currentStateVector: _activeCircuit.currentState.stateVector,
          numQubits: _activeCircuit.currentLevel.numQubits,
          targetStateVector: _activeCircuit.currentLevel.solutionFinalVector
              .map((column) => column.first)
              .toList(),
          targetStateLabel: _activeCircuit.currentLevel.targetStateLabel,
          targetStateExpression:
              _activeCircuit.currentLevel.targetStateExpression,
          contentDriven: contentDriven,
          nonZeroOnly: _nonZeroOnly,
          onNonZeroOnlyChanged: (value) => setState(() => _nonZeroOnly = value),
        );

  Widget _buildMeasureView(bool contentDriven) {
    final content = SingleChildScrollView(
      child: Column(
        key: const ValueKey('web-sandbox-measure-view'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Measurement',
              style: TextStyle(fontWeight: FontWeight.w700)),
          if (_measurementResult == null) ...[
            const SizedBox(height: 4),
            const Text('Z basis', style: QubitQuestTypography.supporting),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const ValueKey('web-sandbox-run-measure'),
              onPressed: _runAndMeasure,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run 100 shots'),
            ),
          ),
          const SizedBox(height: 8),
          if (_measurementResult case final result?)
            MeasurementResultsView(
              key: const ValueKey('web-sandbox-measurement-results'),
              result: result,
            )
          else
            const Text(
              'Each shot prepares the circuit again and measures every qubit.',
              style: QubitQuestTypography.supporting,
            ),
        ],
      ),
    );
    return contentDriven
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480), child: content)
        : content;
  }

  Widget _buildMeasurementSummary(MeasureZOperation measurement) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('SELECTED MEASUREMENT', style: QubitQuestTypography.label),
          const SizedBox(height: 4),
          Text(
            'Measurement Z — q${measurement.qubit} → '
            'c${measurement.classicalBit}',
            key: const ValueKey('web-composer-selected-measurement'),
            style: const TextStyle(
              color: QubitQuestColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            _measurementExecutionNote,
            key: ValueKey('web-composer-measurement-note'),
            style: QubitQuestTypography.supporting,
          ),
        ],
      );

  Widget _buildMeasurementActions(MeasureZOperation measurement) {
    final width = math.max(
      _activeCircuit.currentLevel.numQubits,
      _activeCircuit.classicalBitCount,
    );
    // Each classical bit can be written by one measurement.
    final usedBits = <int, int>{
      for (final other in _activeCircuit.measurements)
        if (other.id != measurement.id) other.classicalBit: other.qubit,
    };
    return Wrap(
      runSpacing: 8,
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Classical bit'),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  key: const ValueKey('web-composer-measurement-classical-bit'),
                  value: measurement.classicalBit,
                  items: [
                    for (var bit = 0; bit < width; bit++)
                      if (usedBits[bit] case final user?
                          when user != measurement.qubit)
                        DropdownMenuItem(
                          value: bit,
                          enabled: false,
                          child: Text('c$bit (used by q$user)'),
                        )
                      else
                        DropdownMenuItem(value: bit, child: Text('c$bit')),
                  ],
                  onChanged: _updateSelectedClassicalBit,
                ),
              ],
            ),
            const Text(
              'The measurement outcome (0 or 1) will be stored in this '
              'classical bit.',
              key: ValueKey('web-composer-classical-bit-help'),
              style: QubitQuestTypography.supporting,
            ),
          ],
        ),
        OutlinedButton.icon(
          key: const ValueKey('web-composer-delete-selected-gate'),
          onPressed: _deleteSelectedGate,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Delete'),
        ),
      ],
    );
  }

  Widget _buildWorkspaceFooter({
    required LogicalGateFootprint? selectedGate,
    required MeasureZOperation? selectedMeasurement,
    required ComposerSelectedGateCapabilities selectedCapabilities,
    required bool wide,
  }) {
    final selectionSummary = selectedMeasurement != null
        ? _buildMeasurementSummary(selectedMeasurement)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedGate == null ? 'NO GATE SELECTED' : 'SELECTED GATE',
                style: QubitQuestTypography.label,
              ),
              const SizedBox(height: 4),
              Text(
                selectedGate == null
                    ? 'Select a placed gate to inspect or edit it.'
                    : _selectedGateSummary(),
                key: selectedGate == null
                    ? const ValueKey('web-composer-no-selected-gate')
                    : const ValueKey('web-composer-selected-gate'),
                style: TextStyle(
                  color: selectedGate == null
                      ? QubitQuestColors.textMuted
                      : QubitQuestColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (selectedGate?.isParameterEditable ?? false) ...[
                const SizedBox(height: 3),
                Text(
                  '${selectedGate!.gate.label.replaceAll('\n', ' ')} angle: '
                  '${(selectedGate.gate.angle! / math.pi).toStringAsFixed(3)}π '
                  '(${selectedGate.gate.angle!.toStringAsFixed(6)} rad)',
                  key: const ValueKey('web-composer-selected-rotation-angle'),
                  style: QubitQuestTypography.supporting,
                ),
              ],
            ],
          );
    final actions = selectedMeasurement != null
        ? _buildMeasurementActions(selectedMeasurement)
        : selectedGate == null
            ? null
            : Wrap(
                runSpacing: 8,
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('web-composer-inspect-selected-gate'),
                    onPressed: _inspectSelectedGate,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Inspect'),
                  ),
                  if (selectedCapabilities
                      .supports(ComposerSelectedGateAction.replace))
                    OutlinedButton.icon(
                      key: const ValueKey('web-composer-replace-selected-gate'),
                      onPressed: _replaceSelectedGate,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Replace'),
                    ),
                  if (selectedCapabilities
                      .supports(ComposerSelectedGateAction.editAngle))
                    OutlinedButton.icon(
                      key: const ValueKey('web-composer-edit-selected-angle'),
                      onPressed: _editSelectedRotationAngle,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Edit angle'),
                    ),
                  if (selectedCapabilities
                      .supports(ComposerSelectedGateAction.duplicate))
                    OutlinedButton.icon(
                      key: const ValueKey(
                          'web-composer-duplicate-selected-gate'),
                      onPressed: _duplicateSelectedGate,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Duplicate'),
                    ),
                  if (selectedCapabilities
                      .supports(ComposerSelectedGateAction.move))
                    const Chip(
                      key: ValueKey('web-composer-move-selected-gate'),
                      avatar: Icon(Icons.open_with_rounded, size: 16),
                      label: Text('Drag to move'),
                    ),
                  if (selectedCapabilities
                      .supports(ComposerSelectedGateAction.delete))
                    OutlinedButton.icon(
                      key: const ValueKey('web-composer-delete-selected-gate'),
                      onPressed: _deleteSelectedGate,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                ],
              );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wide && actions != null)
          Row(
            children: [
              Expanded(child: selectionSummary),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: actions),
            ],
          )
        else ...[
          selectionSummary,
          if (actions != null) ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: actions),
          ],
        ],
        const SizedBox(height: 9),
        if (widget.example == null &&
            _activeCircuit.hasPostMeasurementOperations) ...[
          const Text(
            'This saved circuit applies operations to a qubit after it was '
            'measured. It is kept exactly as saved; edits that would add '
            'more operations after a measurement are rejected.',
            key: ValueKey('web-composer-legacy-measurement-note'),
            style: QubitQuestTypography.supporting,
          ),
          const SizedBox(height: 6),
        ],
        if (widget.example == null) CircuitSaveStatusView(queue: _saves),
        Text(
          _status,
          key: const ValueKey('web-storage-status'),
          style: QubitQuestTypography.supporting.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCircuitStage(
    double canvasHeight, {
    required bool integratedWorkbench,
  }) =>
      ConstrainedBox(
        key: const ValueKey('web-composer-circuit-stage'),
        constraints: BoxConstraints(minHeight: canvasHeight),
        child: Align(
          alignment: Alignment.center,
          child: MouseRegion(
            key: const ValueKey('web-composer-canvas-pointer-area'),
            cursor: SystemMouseCursors.precise,
            child: SizedBox(
              key: const ValueKey('web-composer-canvas'),
              height: canvasHeight,
              child: ComposerCircuitCanvas(
                onMeasurementDropped:
                    widget.example == null ? _dropMeasurement : null,
                onMeasurementMoved:
                    widget.example == null ? _moveMeasurement : null,
                onDropRejected: widget.example == null ? _rejectEdit : null,
                onMeasurementSelected:
                    widget.example == null ? _selectMeasurement : null,
                circuit: _activeCircuit,
                enableDesktopHorizontalScrolling: true,
                surfaceTreatment: integratedWorkbench
                    ? ComposerCircuitSurfaceTreatment.workbench
                    : ComposerCircuitSurfaceTreatment.inset,
                selectedGateId: _selectedGateId,
                onGateTap: (gate) => setState(() {
                  _selectedGateId = gate?.id;
                  _status = gate == null
                      ? 'Canvas selection cleared.'
                      : 'Selected ${gate.gate.label.replaceAll('\n', ' ')}.';
                }),
                onDropRequested: _handleDrop,
                onPlacedGateDragStarted: (gate) =>
                    setState(() => _selectedGateId = gate.id),
                onDeletePlacedGateRequested: (gate) => _commit(
                  _activeCircuit.removeLogicalGateByIdWithOutcome(gate.id),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final horizontalPadding = compact ? 14.0 : 24.0;

          if (_circuit == null) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 16 : 24,
                horizontalPadding,
                24,
              ),
              children: [
                const _WorkspaceHeading(
                  title: 'Composer',
                  subtitle: 'Build, move, and inspect quantum gates.',
                ),
                SizedBox(height: compact ? 14 : 18),
                _buildQubitChooser(),
              ],
            );
          }

          final workbenchMetrics = WebCircuitWorkbenchMetrics.calculate(
            qubitCount: _activeCircuit.currentLevel.numQubits,
            hasTargetState:
                _activeCircuit.currentLevel.solutionFinalVector.isNotEmpty,
          );
          final canvasHeight = workbenchMetrics.canvasHeight;
          final selectedGate = _selectedGateId == null
              ? null
              : _activeCircuit.logicalGateById(_selectedGateId!);
          final selectedMeasurement = _selectedGateId == null
              ? null
              : _activeCircuit.measurementById(_selectedGateId!);
          final selectedCapabilities =
              ComposerSelectedGateCapabilities.forSelection(
            _activeCircuit,
            _selectedGateId,
          );

          return ListView(
            key: const ValueKey('web-composer-workspace-scroll'),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              compact ? 16 : 24,
              horizontalPadding,
              24,
            ),
            children: [
              const _WorkspaceHeading(
                title: 'Sandbox Composer',
                subtitle: 'Experiment freely with a live quantum circuit.',
              ),
              SizedBox(height: compact ? 14 : 18),
              WebComposerWorkbench(
                wideMainHeight: workbenchMetrics.mainRowHeight,
                circuitBuilder: (layout) => _buildCircuitStage(
                  canvasHeight,
                  integratedWorkbench: layout.wide,
                ),
                circuitHeaderTrailing: Wrap(
                  key: const ValueKey('web-composer-workspace-actions'),
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    if (widget.example == null) ...[
                      Text('${_selectedQubitCount!} qubits'),
                      TextButton(
                        key: const ValueKey('web-composer-change-qubits'),
                        onPressed: _closeCircuit,
                        child: const Text('Change'),
                      ),
                    ],
                    TextButton.icon(
                      key: const ValueKey('web-clear-circuit'),
                      onPressed: _clearCircuit,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                gatesBuilder: (layout) => ComposerGatePalette(
                  measurementDraggable: widget.example == null,
                  gates: _gates,
                  dense: layout.densePalette,
                  embedded: true,
                  onGateTap: (gate) => setState(() => _status =
                      'Selected ${gate.label.replaceAll('\n', ' ')}.'),
                  onInspectGate: _inspect,
                ),
                stateViewBuilder: (layout) =>
                    _buildStateViews(layout.contentDrivenInspector),
                allowBloch: !_activeCircuit.hasMeasurements,
                measureViewBuilder:
                    widget.example == null && !_activeCircuit.hasMeasurements
                        ? (layout) =>
                            _buildMeasureView(layout.contentDrivenInspector)
                        : null,
                currentStateVector: _activeCircuit.currentState.stateVector,
                numQubits: _activeCircuit.currentLevel.numQubits,
                targetStateExpression:
                    _activeCircuit.currentLevel.targetStateExpression,
                actionsBuilder: (layout) => _buildWorkspaceFooter(
                  selectedGate: selectedGate,
                  selectedMeasurement: selectedMeasurement,
                  selectedCapabilities: selectedCapabilities,
                  wide: layout.inlineActions,
                ),
                inspectorContentSpacing: 14,
                inspectorKey: const ValueKey('web-composer-state-inspection'),
                inspectorViewsKey:
                    const ValueKey('web-composer-inspector-views'),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.15,
                  color: QubitQuestColors.textMuted,
                ),
              ),
            ],
          );
        },
      );
}

class _ComposerSectionHeading extends StatelessWidget {
  const _ComposerSectionHeading({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _cyan),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: QubitQuestColors.textPrimary,
              ),
            ),
          ),
        ],
      );
}

class _BlochWorkspace extends StatefulWidget {
  const _BlochWorkspace({
    super.key,
    this.requestedInitialState,
    this.onOpenNotebookEntry,
  });

  final BlochState? requestedInitialState;
  final ValueChanged<String>? onOpenNotebookEntry;

  @override
  State<_BlochWorkspace> createState() => _BlochWorkspaceState();
}

class _BlochWorkspaceState extends State<_BlochWorkspace>
    with SingleTickerProviderStateMixin {
  static const _gateDuration = Duration(milliseconds: 650);
  static const _replayDuration = Duration(milliseconds: 420);
  static const _replayGap = Duration(milliseconds: 90);

  late final BlochExplorerHistory _history;
  late final AnimationController _animation;
  final ScrollController _historyScrollController = ScrollController();
  late BlochState _displayState;
  BlochState? _animationStart;
  BlochState? _animationEnd;
  BlochCamera _camera = const BlochCamera();
  double _angle = math.pi / 2;
  bool _instant = false;
  bool _replaying = false;
  int _replayGeneration = 0;
  int? _selectedHistoryIndex;
  BlochHistoryEntry? _selectedHistoryEntry;
  int? _activeHistoryIndex;
  bool _historyExpanded = false;
  String _interaction = 'Ready.';

  @override
  void initState() {
    super.initState();
    _displayState = widget.requestedInitialState ?? BlochState.zero;
    _history = BlochExplorerHistory(initial: _displayState)
      ..addListener(_syncHistory);
    _animation = AnimationController(vsync: this, duration: _gateDuration)
      ..addListener(_tickAnimation);
  }

  @override
  void didUpdateWidget(covariant _BlochWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
        oldWidget.requestedInitialState, widget.requestedInitialState)) {
      final requested = widget.requestedInitialState;
      if (requested != null) {
        _cancelMotion(restoreCurrent: false);
        _history.reset(initial: requested);
        setState(() {
          _displayState = requested;
          _selectedHistoryIndex = null;
          _selectedHistoryEntry = null;
          _interaction = 'Opened Notebook example result.';
        });
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _history
      ..removeListener(_syncHistory)
      ..dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _syncHistory() {
    if (!mounted) return;
    setState(() {
      final selected = _selectedHistoryIndex;
      if (selected != null &&
          (selected > _history.index ||
              selected >= _history.entries.length ||
              !identical(_history.entries[selected], _selectedHistoryEntry))) {
        _selectedHistoryIndex = null;
        _selectedHistoryEntry = null;
      }
      _displayState = _history.state;
    });
  }

  void _tickAnimation() {
    final start = _animationStart;
    final end = _animationEnd;
    if (!mounted || start == null || end == null) return;
    final progress = Curves.easeInOut.transform(_animation.value);
    setState(
        () => _displayState = BlochState.interpolate(start, end, progress));
  }

  void _cancelMotion({bool restoreCurrent = true}) {
    _replayGeneration++;
    _animation.stop();
    if (mounted) {
      setState(() {
        _replaying = false;
        _activeHistoryIndex = null;
        if (restoreCurrent) _displayState = _history.state;
      });
    }
  }

  void _animate(BlochState from, BlochState to, Duration duration) {
    _animation
      ..stop()
      ..duration = duration;
    _animationStart = from;
    _animationEnd = to;
    setState(() => _displayState = from);
    unawaited(_animation.forward(from: 0));
  }

  void _applyGate(SelectedGateType type) {
    _cancelMotion();
    _clearHistoryPreview();
    final rotation = type == SelectedGateType.rx ||
        type == SelectedGateType.ry ||
        type == SelectedGateType.rz;
    final gate = Gate.fromIdentifier(type, angle: rotation ? _angle : null);
    final source = _history.state;
    final destination = source.applyGate(type, angle: _angle);
    _history.commit(
      gate.label.replaceAll('\n', ' '),
      destination,
      gate: gate,
    );
    setState(() {
      _interaction = 'Applied ${gate.label.replaceAll('\n', ' ')}.';
    });
    if (!_instant) _animate(source, destination, _gateDuration);
  }

  Future<void> _replay() async {
    if (_replaying) return;
    _cancelMotion();
    final startIndex = _selectedHistoryIndex ?? 0;
    final sequence = _history.replaySequenceFrom(startIndex);
    if (sequence.isEmpty) return;
    final generation = _replayGeneration;
    setState(() => _replaying = true);
    for (final (offset, transition) in sequence.indexed) {
      if (!mounted || generation != _replayGeneration) return;
      setState(() {
        _activeHistoryIndex = startIndex + offset + 1;
        _displayState = _instant ? transition.destination : transition.source;
      });
      _scrollActiveHistoryEntry();
      if (_instant) {
        await Future<void>.delayed(_replayGap);
      } else {
        _animationStart = transition.source;
        _animationEnd = transition.destination;
        _animation.duration = _replayDuration;
        try {
          await _animation.forward(from: 0).orCancel;
        } on TickerCanceled {
          return;
        }
      }
      if (!_instant && offset + 1 < sequence.length) {
        await Future<void>.delayed(_replayGap);
      }
    }
    if (mounted && generation == _replayGeneration) {
      setState(() {
        _replaying = false;
        _activeHistoryIndex = null;
        _displayState = _history.state;
      });
    }
  }

  void _clearHistoryPreview() {
    if (_selectedHistoryIndex == null) return;
    setState(() {
      _selectedHistoryIndex = null;
      _selectedHistoryEntry = null;
      _displayState = _history.state;
    });
  }

  void _selectHistory(int index) {
    if (_replaying || index < 0 || index > _history.index) return;
    setState(() {
      if (_selectedHistoryIndex == index) {
        _selectedHistoryIndex = null;
        _selectedHistoryEntry = null;
        _displayState = _history.state;
      } else {
        final entry = _history.entries[index];
        _selectedHistoryIndex = index;
        _selectedHistoryEntry = entry;
        _displayState = entry.state;
      }
      _interaction = _selectedHistoryIndex == null
          ? 'History preview cleared.'
          : 'History step $index selected.';
    });
  }

  Future<void> _inspectHistoryGate(int index) async {
    if (_replaying || index <= 0 || index > _history.index) return;
    final gate = _history.entries[index].gate;
    if (gate == null) return;
    final preceding = [
      for (var step = 1; step < index; step++) _history.entries[step].label,
    ];
    final concise = preceding.length <= 4
        ? preceding
        : ['…', ...preceding.sublist(preceding.length - 4)];
    await _inspect(
      gate,
      inspectionContext: GateInspectorContext(
        title: 'History step $index of ${_history.index}',
        description:
            'Applied after: ${concise.isEmpty ? 'Start' : concise.join(' → ')}',
      ),
    );
  }

  Future<void> _inspect(
    Gate gate, {
    GateInspectorContext? inspectionContext,
  }) async {
    final info = GateEducationalCatalog.forType(gate.type);
    final notebookTitle = info?.notebookDiscoveryTitle;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => GateInspectorDialog.forGate(
        gate: gate,
        info: info,
        inspectionContext: inspectionContext,
        onOpenNotebook:
            notebookTitle == null || widget.onOpenNotebookEntry == null
                ? null
                : () {
                    Navigator.of(dialogContext).pop();
                    widget.onOpenNotebookEntry!(notebookTitle);
                  },
        onOpenRelatedConcept: widget.onOpenNotebookEntry == null
            ? null
            : (title) {
                Navigator.of(dialogContext).pop();
                widget.onOpenNotebookEntry!(title);
              },
      ),
    );
  }

  void _scrollActiveHistoryEntry() {
    if (!_historyExpanded || _activeHistoryIndex == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_historyScrollController.hasClients) return;
      final target = (_activeHistoryIndex! * 82.0).clamp(
        0.0,
        _historyScrollController.position.maxScrollExtent,
      );
      _historyScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
        key: const ValueKey('web-bloch-workspace-scroll'),
        padding: const EdgeInsets.all(24),
        children: [
          const _WorkspaceHeading(
            title: 'Bloch Explorer',
            subtitle: 'See how gates transform a single qubit.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;
              final sphereHeight = wide
                  ? (constraints.maxWidth * .48).clamp(470.0, 610.0)
                  : (constraints.maxWidth * .72).clamp(350.0, 540.0);
              final sphere = _WorkspaceCard(
                child: MouseRegion(
                  key: const ValueKey('web-bloch-sphere-pointer-area'),
                  cursor: _replaying
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.grab,
                  child: SizedBox(
                    key: const ValueKey('web-bloch-sphere'),
                    height: sphereHeight,
                    child: IgnorePointer(
                      ignoring: _replaying,
                      child: BlochSpherePanel(
                        reserveOverlaySafeRegions: wide,
                        state: _displayState,
                        camera: _camera,
                        onCameraChanged: (camera) => setState(() {
                          _camera = camera;
                          _interaction = 'Camera updated.';
                        }),
                        onStatePreview: (state) => setState(() {
                          _displayState = state;
                          _interaction = 'Vector preview updated.';
                        }),
                        onStateCommitted: (state) {
                          _history.commit('Direct state', state);
                          setState(
                              () => _interaction = 'Vector state committed.');
                        },
                        onGestureStarted: _cancelMotion,
                        onStateGestureStarted: () {
                          _cancelMotion();
                          _clearHistoryPreview();
                          return _history.state;
                        },
                      ),
                    ),
                  ),
                ),
              );
              final controls = Column(
                key: const ValueKey('web-bloch-tools'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WorkspaceCard(
                    child: BlochGatePanel(
                      initialState: _history.initialState,
                      rotationAngle: _angle,
                      enabled: !_replaying,
                      onSelectPreset: (preset) {
                        _cancelMotion(restoreCurrent: false);
                        _history.reset(initial: preset.blochState);
                        setState(() {
                          _selectedHistoryIndex = null;
                          _selectedHistoryEntry = null;
                          _displayState = preset.blochState;
                          _interaction = 'Preset ${preset.label} selected.';
                        });
                      },
                      onApplyGate: _applyGate,
                      onInspectGate: _inspect,
                      onAngleChanged: (angle) => setState(() => _angle = angle),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WorkspaceCard(
                    child: BlochPlaybackControls(
                      canUndo: _history.canUndo,
                      canRedo: _history.canRedo,
                      canReplay: (_selectedHistoryIndex ?? 0) < _history.index,
                      replayRunning: _replaying,
                      instant: _instant,
                      onUndo: () {
                        _cancelMotion();
                        _clearHistoryPreview();
                        _history.undo();
                      },
                      onRedo: () {
                        _cancelMotion();
                        _clearHistoryPreview();
                        _history.redo();
                      },
                      onReplay: _replay,
                      onReset: () {
                        _cancelMotion(restoreCurrent: false);
                        _selectedHistoryIndex = null;
                        _selectedHistoryEntry = null;
                        _history.reset();
                      },
                      onInstantChanged: (value) =>
                          setState(() => _instant = value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WorkspaceCard(
                    child: BlochHistoryPanel(
                      entries: _history.entries,
                      currentIndex: _history.index,
                      selectedIndex: _selectedHistoryIndex,
                      activeReplayIndex: _activeHistoryIndex,
                      replayRunning: _replaying,
                      scrollController: _historyScrollController,
                      onExpansionChanged: (expanded) {
                        _historyExpanded = expanded;
                        if (expanded) _scrollActiveHistoryEntry();
                      },
                      onSelected: _selectHistory,
                      onInspect: _inspectHistoryGate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_interaction, key: const ValueKey('web-bloch-status')),
                ],
              );
              if (!wide) {
                return Column(
                  key: const ValueKey('web-bloch-stacked-layout'),
                  children: [sphere, const SizedBox(height: 12), controls],
                );
              }
              return Row(
                key: const ValueKey('web-bloch-wide-layout'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 13, child: sphere),
                  const SizedBox(width: 18),
                  Expanded(flex: 10, child: controls),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _WorkspaceCard(
            child: BlochStateMathPanel(
              state: _displayState,
              globalPhase: _displayState.globalPhase,
            ),
          ),
        ],
      );
}

class _WorkspaceHeading extends StatelessWidget {
  const _WorkspaceHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      );
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x66344A73)),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );
}
