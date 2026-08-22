import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/canonical_qubit_state.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/widgets/bloch_explorer_panels.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

export 'package:quantumquiz/widgets/bloch_explorer_panels.dart';
export 'package:quantumquiz/widgets/bloch_sphere_panel.dart';

class BlochExplorerScreen extends StatefulWidget {
  const BlochExplorerScreen({super.key, this.initialState});

  final BlochState? initialState;

  @override
  State<BlochExplorerScreen> createState() => _BlochExplorerScreenState();
}

@immutable
class BlochExplorerLayout {
  const BlochExplorerLayout._({
    required this.twoColumn,
    required this.contentHeight,
    required this.leftColumnWidth,
    required this.rightColumnWidth,
    required this.spherePanelExtent,
    required this.sphereExtent,
    required this.inlineMaths,
  });

  static const double horizontalPadding = 28;
  static const double verticalPadding = 20;
  static const double columnGap = 14;
  static const double spherePanelPadding = 16;
  static const double minimumSphereColumn = 260;
  static const double minimumControlsColumn = 300;
  static const double inlineMathsControlsWidth = 480;

  final bool twoColumn;
  final double contentHeight;
  final double leftColumnWidth;
  final double rightColumnWidth;
  final double spherePanelExtent;
  final double sphereExtent;
  final bool inlineMaths;

  factory BlochExplorerLayout.resolve(Size viewport) {
    final contentWidth = math.max(0.0, viewport.width - horizontalPadding);
    final contentHeight = math.max(0.0, viewport.height - verticalPadding);
    final columnWidth = math.max(0.0, contentWidth - columnGap);
    final leftWidth = math.min(contentHeight, columnWidth * .52);
    final rightWidth = math.max(0.0, columnWidth - leftWidth);
    final twoColumn = viewport.width > viewport.height &&
        leftWidth >= minimumSphereColumn &&
        rightWidth >= minimumControlsColumn;
    final panelExtent = twoColumn ? math.min(leftWidth, contentHeight) : 0.0;
    return BlochExplorerLayout._(
      twoColumn: twoColumn,
      contentHeight: contentHeight,
      leftColumnWidth: leftWidth,
      rightColumnWidth: rightWidth,
      spherePanelExtent: panelExtent,
      sphereExtent: math.max(0.0, panelExtent - spherePanelPadding),
      inlineMaths: twoColumn && rightWidth >= inlineMathsControlsWidth,
    );
  }
}

class _BlochExplorerScreenState extends State<BlochExplorerScreen>
    with SingleTickerProviderStateMixin {
  static const _gateTransitionDuration = Duration(milliseconds: 650);
  static const _replayTransitionDuration = Duration(milliseconds: 420);
  static const _replayStepGap = Duration(milliseconds: 90);

  late final BlochExplorerHistory _history;
  late final AnimationController _animation;
  late final ScrollController _historyScrollController;
  BlochState _displayState = BlochState.zero;
  BlochState? _animationStart;
  BlochState? _animationEnd;
  BlochCamera _camera = const BlochCamera();
  double _rotationAngle = math.pi / 2;
  double _globalPhase = 0;
  bool _instant = false;
  bool _isReplaying = false;
  int _replayGeneration = 0;
  int? _selectedReplayStartIndex;
  BlochHistoryEntry? _selectedReplayStartEntry;
  int? _activeReplayEntryIndex;
  bool _historyExpanded = false;

  @override
  void initState() {
    super.initState();
    _displayState = widget.initialState ?? BlochState.zero;
    _history = BlochExplorerHistory(initial: _displayState)
      ..addListener(_historyChanged);
    _historyScrollController = ScrollController();
    _animation = AnimationController(
      vsync: this,
      duration: _gateTransitionDuration,
    )
      ..addListener(_tickAnimation)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _displayState = _animationEnd ?? _displayState);
        }
      });
  }

  @override
  void dispose() {
    _replayGeneration++;
    _animation.stop();
    _history
      ..removeListener(_historyChanged)
      ..dispose();
    _animation.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _historyChanged() {
    _animation.stop();
    setState(() {
      final selectedIndex = _selectedReplayStartIndex;
      if (selectedIndex != null &&
          (selectedIndex > _history.index ||
              selectedIndex >= _history.entries.length ||
              !identical(_history.entries[selectedIndex],
                  _selectedReplayStartEntry))) {
        _selectedReplayStartIndex = null;
        _selectedReplayStartEntry = null;
      }
      _displayState = _history.state;
      _globalPhase = _history.state.globalPhase;
    });
  }

  void _tickAnimation() {
    final start = _animationStart;
    final end = _animationEnd;
    if (start == null || end == null) return;
    final t = Curves.easeInOut.transform(_animation.value);
    setState(() => _displayState = BlochState.interpolate(start, end, t));
  }

  void _applyGate(SelectedGateType type) {
    _cancelReplay();
    _clearHistoryPreview();
    final source = _history.state;
    final angle = switch (type) {
      SelectedGateType.rx ||
      SelectedGateType.ry ||
      SelectedGateType.rz =>
        _rotationAngle,
      _ => 0.0,
    };
    final target = source.applyGate(type, angle: angle);
    final gate = Gate.fromIdentifier(type,
        angle: type == SelectedGateType.rx ||
                type == SelectedGateType.ry ||
                type == SelectedGateType.rz
            ? angle
            : null);
    _history.commit(
      gate.label.replaceAll('\n', ' '),
      target,
      gate: gate,
    );
    if (_instant) return;
    _animation.duration = _gateTransitionDuration;
    _animationStart = source;
    _animationEnd = target;
    _displayState = _animationStart!;
    _animation.forward(from: 0);
  }

  Future<void> _replay() async {
    final startIndex = _selectedReplayStartIndex ?? 0;
    final sequence = _history.replaySequenceFrom(startIndex);
    if (sequence.isEmpty || _isReplaying) return;
    _animation.stop();
    final generation = ++_replayGeneration;
    setState(() {
      _isReplaying = true;
      _activeReplayEntryIndex = startIndex;
      _displayState = sequence.first.source;
    });
    _scrollActiveHistoryEntry();

    try {
      for (var index = 0; index < sequence.length; index++) {
        if (!mounted || generation != _replayGeneration) return;
        final transition = sequence[index];
        _animationStart = transition.source;
        _animationEnd = transition.destination;
        _animation.duration = _replayTransitionDuration;
        setState(() {
          _activeReplayEntryIndex = startIndex + index + 1;
          _displayState = _instant ? transition.destination : transition.source;
        });
        _scrollActiveHistoryEntry();
        if (_instant) {
          await Future<void>.delayed(_replayStepGap);
        } else {
          await _animation.forward(from: 0).orCancel;
          if (index + 1 < sequence.length) {
            await Future<void>.delayed(_replayStepGap);
          }
        }
      }
    } on TickerCanceled {
      return;
    } finally {
      if (mounted && generation == _replayGeneration) {
        _animation.duration = _gateTransitionDuration;
        setState(() {
          _isReplaying = false;
          _activeReplayEntryIndex = null;
          _displayState = _history.state;
        });
      }
    }
  }

  void _cancelReplay({bool restoreCommittedState = true}) {
    _replayGeneration++;
    _animation.stop();
    if (!_isReplaying || !mounted) return;
    setState(() {
      _isReplaying = false;
      _activeReplayEntryIndex = null;
      if (restoreCommittedState) _displayState = _history.state;
    });
  }

  void _undo() {
    _cancelReplay();
    _clearHistoryPreview();
    _history.undo();
  }

  void _redo() {
    _cancelReplay();
    _clearHistoryPreview();
    _history.redo();
  }

  void _reset() {
    _cancelReplay(restoreCommittedState: false);
    _selectedReplayStartIndex = null;
    _selectedReplayStartEntry = null;
    _history.reset();
  }

  void _selectPreset(CanonicalQubitState preset) {
    _cancelReplay(restoreCommittedState: false);
    _animation.stop();
    _selectedReplayStartIndex = null;
    _selectedReplayStartEntry = null;
    _activeReplayEntryIndex = null;
    _history.reset(initial: preset.blochState);
  }

  void _selectReplayStart(int index) {
    if (_isReplaying || index < 0 || index > _history.index) return;
    setState(() {
      if (_selectedReplayStartIndex == index) {
        _selectedReplayStartIndex = null;
        _selectedReplayStartEntry = null;
        _displayState = _history.state;
        _globalPhase = _history.state.globalPhase;
      } else {
        final entry = _history.entries[index];
        _selectedReplayStartIndex = index;
        _selectedReplayStartEntry = entry;
        _displayState = entry.state;
        _globalPhase = entry.state.globalPhase;
      }
    });
  }

  void _clearHistoryPreview() {
    if (_selectedReplayStartIndex == null) return;
    setState(() {
      _selectedReplayStartIndex = null;
      _selectedReplayStartEntry = null;
      _displayState = _history.state;
      _globalPhase = _history.state.globalPhase;
    });
  }

  BlochState _beginStateEdit() {
    _animation.stop();
    _cancelReplay();
    _clearHistoryPreview();
    return _history.state;
  }

  Future<void> _inspectHistoryGate(int index) async {
    if (_isReplaying || index <= 0 || index > _history.index) return;
    final gate = _history.entries[index].gate;
    if (gate == null) return;
    final preceding = [
      for (var step = 1; step < index; step++) _history.entries[step].label,
    ];
    final concisePreceding = preceding.length <= 4
        ? preceding
        : ['…', ...preceding.sublist(preceding.length - 4)];
    await _inspectGate(
      gate,
      inspectionContext: GateInspectorContext(
        title: 'History step $index of ${_history.index}',
        description: 'Applied after: '
            '${concisePreceding.isEmpty ? 'Start' : concisePreceding.join(' → ')}',
      ),
    );
  }

  Future<void> _inspectGate(
    Gate gate, {
    GateInspectorContext? inspectionContext,
  }) async {
    final info = GateEducationalCatalog.forType(gate.type);
    final notebookTitle = info?.notebookDiscoveryTitle;
    final notebook = notebookTitle == null
        ? null
        : notebookEntriesByDiscoveryTitle[notebookTitle];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => GateInspectorDialog.forGate(
        gate: gate,
        info: info,
        inspectionContext: inspectionContext,
        onOpenNotebook:
            notebook == null ? null : () => _openGateNotebook(notebook),
        onOpenRelatedConcept: _openInspectorRelatedConcept,
      ),
    );
  }

  void _openGateNotebook(NotebookEntry entry) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NotebookEntryScreen(entry: entry),
      ),
    );
  }

  void _openInspectorRelatedConcept(String discoveryTitle) {
    final entry = notebookEntriesByDiscoveryTitle[discoveryTitle];
    if (entry != null) _openGateNotebook(entry);
  }

  void _scrollActiveHistoryEntry() {
    if (!_historyExpanded) return;
    final active = _activeReplayEntryIndex;
    if (active == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_historyScrollController.hasClients) return;
      final target = (active * 82.0).clamp(
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00030A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00030A),
        surfaceTintColor: Colors.transparent,
        title: const Text('Bloch Explorer',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final layout = BlochExplorerLayout.resolve(constraints.biggest);
          if (layout.twoColumn) {
            return _buildLandscapeWorkspace(
              _buildSphere(reserveOverlaySafeRegions: true),
              layout,
            );
          }
          return _buildPortraitWorkspace(_buildSphere());
        }),
      ),
    );
  }

  Widget _buildSphere({bool reserveOverlaySafeRegions = false}) =>
      IgnorePointer(
        ignoring: _isReplaying,
        child: BlochSpherePanel(
          reserveOverlaySafeRegions: reserveOverlaySafeRegions,
          state: _displayState,
          camera: _camera,
          onCameraChanged: (camera) => setState(() => _camera = camera),
          onStatePreview: (state) => setState(() => _displayState = state),
          onStateCommitted: (state) => _history.commit('Direct state', state),
          onGestureStarted: _animation.stop,
          onStateGestureStarted: _beginStateEdit,
        ),
      );

  Widget _buildPortraitWorkspace(Widget sphere) => ListView(
        key: const ValueKey('bloch-explorer-scroll'),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          _buildPortraitPrimaryWorkspace(sphere),
          const SizedBox(height: 6),
          _buildHistory(),
          const SizedBox(height: 6),
          _buildMathsAction(),
        ],
      );

  Widget _buildLandscapeWorkspace(
    Widget sphere,
    BlochExplorerLayout layout,
  ) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          key: const ValueKey('bloch-landscape-workspace'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              key: const ValueKey('bloch-landscape-left-column'),
              width: layout.leftColumnWidth,
              height: layout.contentHeight,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  key: const ValueKey('bloch-primary-workspace'),
                  width: layout.spherePanelExtent,
                  height: layout.spherePanelExtent,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: QubitQuestDialog.panelColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: QubitQuestDialog.borderColor),
                  ),
                  child: SizedBox.square(
                    key: const ValueKey('bloch-landscape-sphere-square'),
                    dimension: layout.sphereExtent,
                    child: sphere,
                  ),
                ),
              ),
            ),
            const SizedBox(width: BlochExplorerLayout.columnGap),
            Expanded(
              child: ListView(
                key: const ValueKey('bloch-landscape-controls-scroll'),
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    key: const ValueKey('bloch-landscape-right-column'),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: QubitQuestDialog.panelColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: QubitQuestDialog.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildGateStrip(),
                        const SizedBox(height: 6),
                        _buildTransportControls(),
                        const SizedBox(height: 6),
                        _buildHistory(),
                        const SizedBox(height: 6),
                        if (layout.inlineMaths)
                          _buildInlineMathsDetails()
                        else
                          _buildMathsAction(expanded: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildPortraitPrimaryWorkspace(Widget sphere) => Container(
        key: const ValueKey('bloch-primary-workspace'),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: QubitQuestDialog.panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: QubitQuestDialog.borderColor),
        ),
        child: Column(children: [
          SizedBox(height: 350, child: sphere),
          const SizedBox(height: 4),
          _buildGateStrip(),
          const SizedBox(height: 4),
          _buildTransportControls(),
        ]),
      );

  Widget _buildGateStrip() => BlochGatePanel(
        initialState: _history.initialState,
        rotationAngle: _rotationAngle,
        enabled: !_isReplaying,
        onSelectPreset: _selectPreset,
        onApplyGate: _applyGate,
        onInspectGate: _inspectGate,
        onAngleChanged: (value) => setState(() => _rotationAngle = value),
      );

  Widget _buildTransportControls() => BlochPlaybackControls(
        canUndo: _history.canUndo,
        canRedo: _history.canRedo,
        canReplay: (_selectedReplayStartIndex ?? 0) < _history.index,
        replayRunning: _isReplaying,
        instant: _instant,
        onUndo: _undo,
        onRedo: _redo,
        onReplay: _replay,
        onReset: _reset,
        onInstantChanged: (value) => setState(() => _instant = value),
      );

  Widget _buildMathsAction({bool expanded = false}) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: expanded ? double.infinity : null,
          child: OutlinedButton.icon(
            key: const ValueKey('bloch-maths-action'),
            onPressed: _showMathsDetails,
            icon: const Icon(Icons.functions_rounded, size: 18),
            label: const Text('Maths / state details'),
          ),
        ),
      );

  Widget _buildInlineMathsDetails() => Container(
        key: const ValueKey('bloch-inline-maths-details'),
        decoration: BoxDecoration(
          color: QubitQuestDialog.innerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QubitQuestDialog.borderSoftColor),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('bloch-inline-maths-expansion'),
            dense: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: const Icon(Icons.functions_rounded, size: 18),
            title: const Text(
              'Maths / state details',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            children: [
              BlochStateMathPanel(
                state: _displayState,
                globalPhase: _globalPhase,
              ),
            ],
          ),
        ),
      );

  Future<void> _showMathsDetails() => showDialog<void>(
        context: context,
        builder: (dialogContext) => QubitQuestDialog(
          title: 'State maths',
          maxWidth: 560,
          actions: [
            QubitQuestDialogButton.primary(
              label: 'Close',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          child: BlochStateMathPanel(
            state: _displayState,
            globalPhase: _globalPhase,
          ),
        ),
      );

  Widget _buildHistory() => BlochHistoryPanel(
        entries: _history.entries,
        currentIndex: _history.index,
        selectedIndex: _selectedReplayStartIndex,
        activeReplayIndex: _activeReplayEntryIndex,
        replayRunning: _isReplaying,
        scrollController: _historyScrollController,
        onExpansionChanged: (expanded) {
          _historyExpanded = expanded;
          if (expanded) _scrollActiveHistoryEntry();
        },
        onSelected: _selectReplayStart,
        onInspect: _inspectHistoryGate,
      );
}
