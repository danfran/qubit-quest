import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/canonical_qubit_state.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/storage/shared_preferences_app_storage.dart';
import 'package:quantumquiz/widgets/bloch_explorer_panels.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';

const _background = Color(0xFF00030A);
const _surface = Color(0xFF111827);
const _cyan = Color(0xFF22D3EE);
const _purple = Color(0xFF9B7BFF);

enum WebDestination { journey, notebook, composer, bloch }

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
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: _background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _cyan,
            brightness: Brightness.dark,
            surface: _surface,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: _background,
            surfaceTintColor: Colors.transparent,
          ),
        ),
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
  WebDestination _destination = WebDestination.journey;

  @override
  void initState() {
    super.initState();
    unawaited(widget.progressController.load());
  }

  void _select(WebDestination destination) =>
      setState(() => _destination = destination);

  Widget _workspace() => IndexedStack(
        index: _destination.index,
        children: [
          WebJourneyWorkspace(
            progressController: widget.progressController,
            onOpenNotebook: () => _select(WebDestination.notebook),
          ),
          const DiscoveriesScreen(key: ValueKey('web-workspace-notebook')),
          _ComposerWorkspace(
            key: const ValueKey('web-workspace-composer'),
            persistence: widget.sandboxPersistenceStore,
          ),
          const _BlochWorkspace(key: ValueKey('web-workspace-bloch')),
        ],
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideNavigationBreakpoint;
          final navigation = _WebNavigation(
            selected: _destination,
            onSelected: (destination) {
              _select(destination);
              if (!wide) Navigator.of(context).pop();
            },
          );
          return Scaffold(
            key: const ValueKey('web-shell'),
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
              actions: wide
                  ? [
                      AnimatedBuilder(
                        animation: widget.progressController,
                        builder: (context, _) => Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Center(
                            child: Text(
                              widget.progressController.isLoaded
                                  ? 'Level ${widget.progressController.state.maxUnlockedLevel}'
                                  : 'Loading journey…',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ]
                  : null,
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
            body: wide
                ? Row(
                    children: [
                      SizedBox(
                        key: const ValueKey('web-navigation-sidebar'),
                        width: 238,
                        child: navigation,
                      ),
                      const VerticalDivider(
                        width: 1,
                        color: Color(0x44344A73),
                      ),
                      Expanded(child: _workspace()),
                    ],
                  )
                : _workspace(),
          );
        },
      );
}

class _QubitQuestWordmark extends StatelessWidget {
  const _QubitQuestWordmark();

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.blur_circular, color: _cyan),
          SizedBox(width: 10),
          Text(
            'Qubit Quest',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .3),
          ),
        ],
      );
}

class _WebNavigation extends StatelessWidget {
  const _WebNavigation({required this.selected, required this.onSelected});

  final WebDestination selected;
  final ValueChanged<WebDestination> onSelected;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
        children: [
          const _NavigationHeading('LEARN'),
          _item(WebDestination.journey, Icons.route_outlined, 'Journey'),
          _item(WebDestination.notebook, Icons.menu_book_outlined, 'Notebook'),
          const SizedBox(height: 22),
          const _NavigationHeading('EXPLORE'),
          _item(
              WebDestination.composer, Icons.account_tree_outlined, 'Composer'),
          _item(WebDestination.bloch, Icons.blur_circular, 'Bloch Explorer'),
        ],
      );

  Widget _item(WebDestination destination, IconData icon, String label) =>
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
          title:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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
  const _ComposerWorkspace({super.key, required this.persistence});
  final SandboxPersistenceStore persistence;

  @override
  State<_ComposerWorkspace> createState() => _ComposerWorkspaceState();
}

class _ComposerWorkspaceState extends State<_ComposerWorkspace> {
  late QuantumCircuit _circuit;
  GateId? _selectedGateId;
  double _rotationAngle = math.pi / 2;
  String _status = 'Loading saved Sandbox workspace…';

  List<Gate> get _gates => [
        for (final type in sandboxGatePaletteTypes)
          Gate.fromIdentifier(
            type,
            angle: type == SelectedGateType.rx ||
                    type == SelectedGateType.ry ||
                    type == SelectedGateType.rz
                ? _rotationAngle
                : null,
          ),
      ];

  @override
  void initState() {
    super.initState();
    _circuit = _newCircuit();
    unawaited(_restore());
  }

  QuantumCircuit _newCircuit() =>
      QuantumCircuit(currentLevel: createSandboxComposerLevel(3));

  Future<void> _restore() async {
    final snapshot = await widget.persistence.loadSnapshot(3);
    if (!mounted) return;
    setState(() {
      if (snapshot == null) {
        _status = 'Ready — changes save in this browser.';
      } else {
        _circuit = snapshot.restoreCircuit();
        _status = 'Restored ${snapshot.operations.length} saved operation(s).';
      }
    });
  }

  Future<void> _commit(CircuitEditOutcome outcome) async {
    if (outcome.changed) {
      _circuit.runSimulation();
      await widget.persistence.saveCircuit(_circuit);
    }
    if (!mounted) return;
    setState(() {
      _selectedGateId = outcome.affectedGateId ?? _selectedGateId;
      _status = outcome.changed
          ? 'Saved ${_circuit.logicalGates.length} operation(s) locally.'
          : 'Edit result: ${outcome.status.name}';
    });
  }

  Future<void> _handleDrop(ComposerCircuitDropIntent intent) async {
    final gate = intent.data.gate;
    final location = intent.destination.location;
    final outcome = intent.data.isPlaced
        ? _circuit.commitLogicalGateMovePlan(
            intent.movePlan ??
                _circuit.planLogicalGateMove(
                  intent.data.sourceId!,
                  location,
                ),
          )
        : switch (gate.type) {
            SelectedGateType.cnot ||
            SelectedGateType.cz =>
              _circuit.insertDoubleGateWithOutcome(
                gate,
                location.column,
                location.qubit,
                location.qubit == 0 ? 1 : 0,
              ),
            SelectedGateType.ccnot => _circuit.insertTripleGateWithOutcome(
                gate,
                location.column,
                location.qubit,
                (location.qubit + 1) % 3,
                (location.qubit + 2) % 3,
              ),
            _ => _circuit.insertSingleGateWithOutcome(
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

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _WorkspaceHeading(
            title: 'Composer',
            subtitle: 'Build, move, and inspect quantum gates.',
          ),
          const SizedBox(height: 18),
          _WorkspaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ComposerGatePalette(
                  gates: _gates,
                  onGateTap: (gate) => setState(() => _status =
                      'Selected ${gate.label.replaceAll('\n', ' ')}.'),
                  onInspectGate: _inspect,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Rotation angle'),
                    Expanded(
                      child: Slider(
                        key: const ValueKey('web-composer-rotation-angle'),
                        value: _rotationAngle,
                        min: 0,
                        max: 2 * math.pi,
                        divisions: 16,
                        onChanged: (value) =>
                            setState(() => _rotationAngle = value),
                      ),
                    ),
                    SizedBox(
                      width: 54,
                      child: Text(
                          '${(_rotationAngle / math.pi).toStringAsFixed(2)}π'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _WorkspaceCard(
            child: SizedBox(
              key: const ValueKey('web-composer-canvas'),
              height: 230,
              child: ComposerCircuitCanvas(
                circuit: _circuit,
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
                onDeletePlacedGateRequested: (gate) =>
                    _commit(_circuit.removeLogicalGateByIdWithOutcome(gate.id)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(_status, key: const ValueKey('web-storage-status')),
              ),
              TextButton.icon(
                key: const ValueKey('web-clear-circuit'),
                onPressed: () async {
                  _circuit.clearPlacedGates();
                  await widget.persistence.saveCircuit(_circuit);
                  if (mounted) {
                    setState(() {
                      _selectedGateId = null;
                      _status = 'Saved an empty circuit.';
                    });
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      );
}

class _BlochWorkspace extends StatefulWidget {
  const _BlochWorkspace({super.key});

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
  BlochState _displayState = CanonicalQubitState.plus.blochState;
  BlochState? _animationStart;
  BlochState? _animationEnd;
  BlochCamera _camera = const BlochCamera();
  double _angle = math.pi / 2;
  bool _instant = false;
  bool _replaying = false;
  int _replayGeneration = 0;
  int? _selectedHistoryIndex;
  int? _activeHistoryIndex;
  String _interaction = 'Ready.';

  @override
  void initState() {
    super.initState();
    _history = BlochExplorerHistory(initial: _displayState)
      ..addListener(_syncHistory);
    _animation = AnimationController(vsync: this, duration: _gateDuration)
      ..addListener(_tickAnimation);
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
    setState(() => _displayState = _history.state);
  }

  void _tickAnimation() {
    final start = _animationStart;
    final end = _animationEnd;
    if (!mounted || start == null || end == null) return;
    setState(() =>
        _displayState = BlochState.interpolate(start, end, _animation.value));
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
      _selectedHistoryIndex = null;
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
        _displayState = transition.source;
      });
      if (_instant) {
        setState(() => _displayState = transition.destination);
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
      await Future<void>.delayed(_replayGap);
    }
    if (mounted && generation == _replayGeneration) {
      setState(() {
        _replaying = false;
        _activeHistoryIndex = null;
        _displayState = _history.state;
      });
    }
  }

  void _inspect(Gate gate) {
    showDialog<void>(
      context: context,
      builder: (_) => GateInspectorDialog.forGate(
        gate: gate,
        info: GateEducationalCatalog.forType(gate.type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _WorkspaceHeading(
            title: 'Bloch Explorer',
            subtitle: 'See how gates transform a single qubit.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 920;
              final sphere = _WorkspaceCard(
                child: SizedBox(
                  key: const ValueKey('web-bloch-sphere'),
                  height: wide ? 500 : 390,
                  child: BlochSpherePanel(
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
                      setState(() => _interaction = 'Vector state committed.');
                    },
                    onGestureStarted: _cancelMotion,
                    onStateGestureStarted: () {
                      _cancelMotion();
                      return _history.state;
                    },
                  ),
                ),
              );
              final controls = Column(
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
                        _history.undo();
                      },
                      onRedo: () {
                        _cancelMotion();
                        _history.redo();
                      },
                      onReplay: _replay,
                      onReset: () {
                        _cancelMotion(restoreCurrent: false);
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
                      onExpansionChanged: (_) {},
                      onSelected: (index) {
                        _cancelMotion(restoreCurrent: false);
                        setState(() {
                          _selectedHistoryIndex = index;
                          _displayState = _history.entries[index].state;
                          _interaction = 'History step $index selected.';
                        });
                      },
                      onInspect: (index) {
                        final gate = _history.entries[index].gate;
                        if (gate != null) _inspect(gate);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_interaction, key: const ValueKey('web-bloch-status')),
                ],
              );
              if (!wide) {
                return Column(
                  children: [sphere, const SizedBox(height: 12), controls],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: sphere),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: controls),
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
