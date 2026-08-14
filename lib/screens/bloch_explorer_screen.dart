import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

class BlochExplorerScreen extends StatefulWidget {
  const BlochExplorerScreen({super.key});

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
    _history = BlochExplorerHistory()..addListener(_historyChanged);
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
          _displayState = transition.source;
        });
        _scrollActiveHistoryEntry();
        await _animation.forward(from: 0).orCancel;
        if (index + 1 < sequence.length) {
          await Future<void>.delayed(_replayStepGap);
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
        child: _SpherePanel(
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

  Widget _buildGateStrip() => Container(
        key: const ValueKey('bloch-gate-strip'),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 14, runSpacing: 6, children: [
            _gateGroup('Pauli', const [
              SelectedGateType.x,
              SelectedGateType.y,
              SelectedGateType.z,
            ]),
            _gateGroup('Hadamard', const [SelectedGateType.hadamard]),
            _gateGroup('Phase', const [
              SelectedGateType.s,
              SelectedGateType.t,
            ]),
          ]),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, constraints) {
            final angleWidth = math.max(130.0, constraints.maxWidth - 170);
            return Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                _gateGroup('Rotations', const [
                  SelectedGateType.rx,
                  SelectedGateType.ry,
                  SelectedGateType.rz,
                ]),
                SizedBox(
                  key: const ValueKey('bloch-gate-angle-control'),
                  width: angleWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Gate angle: ${_formatAngle(_rotationAngle)}',
                          style: const TextStyle(
                              color: QubitQuestDialog.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                      SizedBox(
                        height: 38,
                        child: Slider(
                          key: const ValueKey('bloch-rotation-slider'),
                          value: _rotationAngle,
                          min: -math.pi,
                          max: math.pi,
                          divisions: 16,
                          onChanged: (value) =>
                              setState(() => _rotationAngle = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ]),
      );

  Widget _gateGroup(String label, List<SelectedGateType> types) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: QubitQuestDialog.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [for (final type in types) _gateChip(type)],
          ),
        ],
      );

  Widget _gateChip(SelectedGateType type) {
    final gate = Gate.fromIdentifier(type,
        angle: type == SelectedGateType.rx ||
                type == SelectedGateType.ry ||
                type == SelectedGateType.rz
            ? _rotationAngle
            : null);
    return QubitQuestGateTile(
      key: ValueKey('bloch-gate-${type.name}'),
      gate: gate,
      size: 44,
      tooltip: 'Apply ${gate.label.replaceAll('\n', ' ')} gate',
      onPressed: _isReplaying ? null : () => _applyGate(type),
      onInspect: _isReplaying ? null : () => _inspectGate(gate),
    );
  }

  Widget _buildTransportControls() => Container(
        key: const ValueKey('bloch-transport-controls'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: QubitQuestDialog.innerColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final controls = <Widget>[
            _transportButton(
                key: 'bloch-undo',
                label: 'Undo',
                icon: Icons.undo_rounded,
                onPressed: !_isReplaying && _history.canUndo ? _undo : null),
            _transportButton(
                key: 'bloch-redo',
                label: 'Redo',
                icon: Icons.redo_rounded,
                onPressed: !_isReplaying && _history.canRedo ? _redo : null),
            _transportButton(
                key: 'bloch-replay',
                label: 'Replay',
                icon: Icons.play_circle_outline_rounded,
                onPressed: !_isReplaying &&
                        (_selectedReplayStartIndex ?? 0) < _history.index
                    ? _replay
                    : null),
            _transportButton(
                key: 'bloch-reset',
                label: 'Reset',
                icon: Icons.restart_alt_rounded,
                onPressed: _reset),
          ];
          final instant = Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bolt_rounded, size: 16),
            const Text('Instant', style: TextStyle(fontSize: 11)),
            Checkbox(
              key: const ValueKey('bloch-instant-mode'),
              value: _instant,
              visualDensity: VisualDensity.compact,
              onChanged: (value) => setState(() => _instant = value ?? false),
            ),
          ]);
          return Row(children: [
            Expanded(
              child: Row(children: [
                for (final control in controls) Expanded(child: control),
              ]),
            ),
            instant,
          ]);
        }),
      );

  Widget _transportButton({
    required String key,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) =>
      Semantics(
        key: ValueKey(key),
        button: true,
        enabled: onPressed != null,
        label: label,
        child: Tooltip(
          message: label,
          child: TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            ),
            onPressed: onPressed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(fontSize: 10, height: 1),
                ),
              ],
            ),
          ),
        ),
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
              _StateMathsDialogContent(
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
          child: _StateMathsDialogContent(
            state: _displayState,
            globalPhase: _globalPhase,
          ),
        ),
      );

  Widget _buildHistory() => Container(
        key: const ValueKey('bloch-history-container'),
        decoration: BoxDecoration(
          color: QubitQuestDialog.panelColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: QubitQuestDialog.borderColor),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('bloch-history-expansion'),
            dense: true,
            visualDensity: VisualDensity.compact,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            onExpansionChanged: (expanded) {
              _historyExpanded = expanded;
              if (expanded) _scrollActiveHistoryEntry();
            },
            title: const Text('History',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            subtitle:
                Text(_historyStatus, style: const TextStyle(fontSize: 10)),
            children: [
              SizedBox(
                height: 60,
                child: ListView.builder(
                  key: const ValueKey('bloch-history-timeline'),
                  controller: _historyScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemExtent: 82,
                  itemCount: _history.index + 1,
                  itemBuilder: (context, index) =>
                      _buildHistoryTimelineEntry(index),
                ),
              ),
            ],
          ),
        ),
      );

  String get _historyStatus {
    final active = _activeReplayEntryIndex;
    if (_isReplaying && active != null) {
      return 'Step $active / ${_history.index} · ${_history.entries[active].label}';
    }
    final selected = _selectedReplayStartIndex;
    if (selected != null) {
      final position = selected == 0
          ? 'Replay start: Start'
          : 'Replay start: Step $selected / ${_history.index} · '
              '${_history.entries[selected].label}';
      return '$_operationSummary · $position';
    }
    return _operationSummary;
  }

  String get _operationSummary => _history.operationCount == 1
      ? '1 operation'
      : '${_history.operationCount} operations';

  Widget _buildHistoryTimelineEntry(int index) {
    final entry = _history.entries[index];
    final active = index == _activeReplayEntryIndex;
    final selected = index == _selectedReplayStartIndex;
    final replayCompleted = _isReplaying &&
        _activeReplayEntryIndex != null &&
        index < _activeReplayEntryIndex!;
    final labelStyle = TextStyle(
      color: active ? Colors.white : QubitQuestDialog.mutedText,
      fontSize: 10,
      fontWeight: active ? FontWeight.w900 : FontWeight.w600,
    );
    return Semantics(
      key: ValueKey('bloch-history-step-$index'),
      button: !_isReplaying,
      selected: selected,
      label: '${index == 0 ? 'Start' : 'Step $index, ${entry.label}'}'
          '${selected ? ', replay start' : ''}'
          '${active ? ', currently replaying' : ''}',
      child: InkWell(
        onTap: _isReplaying ? null : () => _selectReplayStart(index),
        onLongPress: !_isReplaying && entry.gate != null
            ? () => _inspectHistoryGate(index)
            : null,
        child: Stack(children: [
          Positioned(
            left: index == 0 ? 41 : 0,
            right: index == _history.index ? 41 : 0,
            top: 9,
            child: Container(
              key: ValueKey('bloch-history-connector-$index'),
              height: 1,
              color: QubitQuestDialog.mutedText.withValues(alpha: .42),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _HistoryMarker(
                active: active,
                selected: selected,
                completed: replayCompleted,
                start: index == 0,
              ),
              const SizedBox(height: 4),
              Text(
                index == 0 ? 'Start' : entry.label,
                key: ValueKey('bloch-history-label-$index'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: labelStyle,
              ),
              if (index > 0)
                Text('Step $index',
                    style: const TextStyle(
                        color: QubitQuestDialog.mutedText, fontSize: 8)),
            ]),
          ),
        ]),
      ),
    );
  }

  String _formatAngle(double angle) {
    final ratio = angle / math.pi;
    if (ratio.abs() < 1e-9) return '0';
    for (final denominator in [1, 2, 4, 8]) {
      final numerator = (ratio * denominator).round();
      if ((ratio - numerator / denominator).abs() < 1e-9) {
        if (denominator == 1) return numerator == 1 ? 'π' : '$numeratorπ';
        return '$numeratorπ/$denominator';
      }
    }
    return '${angle.toStringAsFixed(2)} rad';
  }
}

class _HistoryMarker extends StatelessWidget {
  const _HistoryMarker({
    required this.active,
    required this.selected,
    required this.completed,
    required this.start,
  });

  final bool active;
  final bool selected;
  final bool completed;
  final bool start;

  @override
  Widget build(BuildContext context) {
    final accent = QubitQuestDialog.purple;
    final border = selected || active
        ? accent
        : QubitQuestDialog.mutedText.withValues(alpha: .65);
    return AnimatedContainer(
      key: ValueKey(active
          ? 'bloch-history-marker-active'
          : selected
              ? 'bloch-history-marker-selected'
              : completed
                  ? 'bloch-history-marker-completed'
                  : 'bloch-history-marker-idle'),
      duration: const Duration(milliseconds: 120),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? accent : Colors.transparent,
        border: Border.all(color: border, width: selected && !active ? 2 : 1),
      ),
      child: active
          ? const Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white)
          : completed
              ? const Icon(Icons.check_rounded,
                  size: 12, color: QubitQuestDialog.mutedText)
              : start
                  ? Icon(Icons.flag_rounded,
                      size: 11,
                      color: selected ? accent : QubitQuestDialog.mutedText)
                  : selected
                      ? Center(
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
    );
  }
}

enum BlochSphereGestureMode { state, orbit, zoom }

class BlochGestureResolver {
  const BlochGestureResolver._();

  static const double vectorTipHitRadius = 22;
  static const double orbitSensitivity = .01;

  static BlochSphereGestureMode resolveMode(Offset start, Offset vectorTip) =>
      (start - vectorTip).distance <= vectorTipHitRadius
          ? BlochSphereGestureMode.state
          : BlochSphereGestureMode.orbit;

  static BlochCamera orbit({
    required BlochCamera camera,
    required Offset dragDelta,
  }) =>
      camera.orbit(
        deltaYaw: dragDelta.dx * orbitSensitivity,
        deltaPitch: -dragDelta.dy * orbitSensitivity,
      );
}

class _BlochScaleGestureRecognizer extends ScaleGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _SpherePanel extends StatefulWidget {
  const _SpherePanel({
    this.reserveOverlaySafeRegions = false,
    required this.state,
    required this.camera,
    required this.onCameraChanged,
    required this.onStatePreview,
    required this.onStateCommitted,
    required this.onGestureStarted,
    required this.onStateGestureStarted,
  });

  final bool reserveOverlaySafeRegions;
  final BlochState state;
  final BlochCamera camera;
  final ValueChanged<BlochCamera> onCameraChanged;
  final ValueChanged<BlochState> onStatePreview;
  final ValueChanged<BlochState> onStateCommitted;
  final VoidCallback onGestureStarted;
  final BlochState Function() onStateGestureStarted;

  @override
  State<_SpherePanel> createState() => _SpherePanelState();
}

class _SpherePanelState extends State<_SpherePanel> {
  BlochSphereGestureMode? _mode;
  BlochCamera? _startCamera;
  Offset? _startPoint;
  BlochState? _latestState;

  Widget _interactiveCanvas() => LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final projection = BlochProjection(size: size, camera: widget.camera);
        return RawGestureDetector(
          key: const ValueKey('bloch-sphere-gesture'),
          behavior: HitTestBehavior.opaque,
          gestures: {
            _BlochScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                _BlochScaleGestureRecognizer>(
              _BlochScaleGestureRecognizer.new,
              (recognizer) {
                recognizer
                  ..onStart = (details) {
                    final tip = projection.project(
                        widget.state.x, widget.state.y, widget.state.z);
                    widget.onGestureStarted();
                    _startCamera = widget.camera;
                    _startPoint = details.localFocalPoint;
                    _mode = BlochGestureResolver.resolveMode(
                        details.localFocalPoint, tip);
                    _latestState = _mode == BlochSphereGestureMode.state
                        ? widget.onStateGestureStarted()
                        : widget.state;
                  }
                  ..onUpdate = (details) {
                    final initialCamera = _startCamera ?? widget.camera;
                    if (details.pointerCount > 1) {
                      _mode = BlochSphereGestureMode.zoom;
                      widget
                          .onCameraChanged(initialCamera.scale(details.scale));
                    } else if (_mode == BlochSphereGestureMode.state) {
                      _latestState = projection.stateForPoint(
                          details.localFocalPoint,
                          globalPhase: _latestState!.globalPhase);
                      widget.onStatePreview(_latestState!);
                    } else {
                      widget.onCameraChanged(BlochGestureResolver.orbit(
                        camera: initialCamera,
                        dragDelta: details.localFocalPoint -
                            (_startPoint ?? details.localFocalPoint),
                      ));
                    }
                  }
                  ..onEnd = (_) {
                    if (_mode == BlochSphereGestureMode.state &&
                        _latestState != null) {
                      widget.onStateCommitted(_latestState!);
                    }
                    _mode = null;
                    _startCamera = null;
                    _startPoint = null;
                    _latestState = null;
                  };
              },
            ),
          },
          child: CustomPaint(
            key: const ValueKey('bloch-sphere-canvas'),
            painter:
                BlochSpherePainter(state: widget.state, camera: widget.camera),
            child: const SizedBox.expand(),
          ),
        );
      });

  Widget _angles() => _LiveValues(
        key: const ValueKey('bloch-live-angles'),
        values: [('θ', widget.state.theta), ('φ', widget.state.phi)],
      );

  Widget _cartesian() => _LiveValues(
        key: const ValueKey('bloch-live-cartesian'),
        alignment: CrossAxisAlignment.end,
        values: [
          ('x', widget.state.x),
          ('y', widget.state.y),
          ('z', widget.state.z),
        ],
      );

  Widget _probabilities() => IgnorePointer(
        child: Container(
          key: const ValueKey('bloch-live-probabilities'),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xD9000712),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'P(|0⟩) = ${(widget.state.probabilityZero * 100).toStringAsFixed(1)}%',
                ),
                Text(
                  'P(|1⟩) = ${(widget.state.probabilityOne * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ),
      );

  static const _helper = Text(
    key: ValueKey('bloch-sphere-helper'),
    'Drag vector • orbit elsewhere • pinch to zoom',
    textAlign: TextAlign.center,
    style: TextStyle(color: QubitQuestDialog.mutedText, fontSize: 10),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.reserveOverlaySafeRegions) {
      return CustomMultiChildLayout(
        key: const ValueKey('bloch-sphere-panel'),
        delegate: _BlochLandscapeOverlayLayout(),
        children: [
          LayoutId(id: _BlochOverlaySlot.canvas, child: _interactiveCanvas()),
          LayoutId(
              id: _BlochOverlaySlot.helper,
              child: const IgnorePointer(child: _helper)),
          LayoutId(id: _BlochOverlaySlot.angles, child: _angles()),
          LayoutId(id: _BlochOverlaySlot.cartesian, child: _cartesian()),
          LayoutId(
              id: _BlochOverlaySlot.probabilities, child: _probabilities()),
        ],
      );
    }
    return Stack(
      key: const ValueKey('bloch-sphere-panel'),
      children: [
        Positioned.fill(top: 18, child: _interactiveCanvas()),
        const Positioned(
          top: 0,
          left: 2,
          right: 2,
          child: IgnorePointer(
            child: _helper,
          ),
        ),
        Positioned(
          top: 22,
          left: 2,
          child: _angles(),
        ),
        Positioned(
          top: 22,
          right: 2,
          child: _cartesian(),
        ),
        Positioned(
          bottom: 2,
          left: 2,
          child: _probabilities(),
        ),
      ],
    );
  }
}

enum _BlochOverlaySlot { canvas, helper, angles, cartesian, probabilities }

class _BlochLandscapeOverlayLayout extends MultiChildLayoutDelegate {
  static const double edgeInset = 2;
  static const double safeGap = 6;

  @override
  void performLayout(Size size) {
    final loose = BoxConstraints.loose(size);
    final helper = layoutChild(_BlochOverlaySlot.helper, loose);
    final helperRect = Rect.fromLTWH(
      (size.width - helper.width) / 2,
      0,
      helper.width,
      helper.height,
    );
    positionChild(_BlochOverlaySlot.helper, helperRect.topLeft);

    final angles = layoutChild(_BlochOverlaySlot.angles, loose);
    final overlayTop = helperRect.bottom + safeGap;
    final anglesRect = Rect.fromLTWH(
      edgeInset,
      overlayTop,
      angles.width,
      angles.height,
    );
    positionChild(_BlochOverlaySlot.angles, anglesRect.topLeft);
    final cartesian = layoutChild(_BlochOverlaySlot.cartesian, loose);
    final cartesianRect = Rect.fromLTWH(
      size.width - cartesian.width - edgeInset,
      overlayTop,
      cartesian.width,
      cartesian.height,
    );
    positionChild(_BlochOverlaySlot.cartesian, cartesianRect.topLeft);

    final probabilities = layoutChild(_BlochOverlaySlot.probabilities, loose);
    final probabilityRect = Rect.fromLTWH(
      edgeInset,
      size.height - probabilities.height - edgeInset,
      probabilities.width,
      probabilities.height,
    );
    positionChild(_BlochOverlaySlot.probabilities, probabilityRect.topLeft);

    final usablePane = Rect.fromLTRB(
      edgeInset,
      helperRect.bottom + safeGap,
      size.width - edgeInset,
      size.height - edgeInset,
    );
    final centre = usablePane.center;
    var radius = <double>[
      centre.dx - usablePane.left,
      usablePane.right - centre.dx,
      centre.dy - usablePane.top,
      usablePane.bottom - centre.dy,
      _maximumRadiusClearOf(centre, anglesRect),
      _maximumRadiusClearOf(centre, cartesianRect),
      _maximumRadiusClearOf(centre, probabilityRect),
    ].reduce(math.min);
    radius = math.max(0, radius);
    final canvasRect = Rect.fromCircle(
      center: centre,
      radius: radius,
    );
    layoutChild(
      _BlochOverlaySlot.canvas,
      BoxConstraints.tight(canvasRect.size),
    );
    positionChild(_BlochOverlaySlot.canvas, canvasRect.topLeft);
  }

  double _maximumRadiusClearOf(Offset centre, Rect obstacle) {
    final horizontalClearance = centre.dx < obstacle.center.dx
        ? obstacle.left - centre.dx - safeGap
        : centre.dx - obstacle.right - safeGap;
    final verticalClearance = centre.dy < obstacle.center.dy
        ? obstacle.top - centre.dy - safeGap
        : centre.dy - obstacle.bottom - safeGap;
    // Axis-aligned squares are disjoint when separated on either axis.
    return math.max(horizontalClearance, verticalClearance);
  }

  @override
  bool shouldRelayout(covariant _BlochLandscapeOverlayLayout oldDelegate) =>
      false;
}

class _LiveValues extends StatelessWidget {
  const _LiveValues({
    super.key,
    required this.values,
    this.alignment = CrossAxisAlignment.start,
  });

  final List<(String, double)> values;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xD9000712),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: alignment,
            children: [
              for (final value in values)
                Text(
                  '${value.$1} = ${value.$2.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 11),
                ),
            ],
          ),
        ),
      );
}

class _StateMathsDialogContent extends StatelessWidget {
  const _StateMathsDialogContent({
    required this.state,
    required this.globalPhase,
  });

  final BlochState state;
  final double globalPhase;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('bloch-maths-dialog-content'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LatexText(
            key: ValueKey('bloch-wavefunction-latex'),
            math:
                r'\[|\psi\rangle=\cos(\theta/2)|0\rangle+e^{i\varphi}\sin(\theta/2)|1\rangle\]',
            textStyle: TextStyle(
              color: QubitQuestDialog.cyan,
              fontWeight: FontWeight.w700,
            ),
            inlineMathColor: QubitQuestDialog.cyan,
            displayMathHeight: 24,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 5,
            children: [
              _detailValue('θ', state.theta),
              _detailValue('φ', state.phi),
              _detailValue('x', state.x),
              _detailValue('y', state.y),
              _detailValue('z', state.z),
              Text(
                  'P(|0⟩) = ${(state.probabilityZero * 100).toStringAsFixed(1)}%'),
              Text(
                  'P(|1⟩) = ${(state.probabilityOne * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const Divider(height: 24),
          const Text('Column vector',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LatexText(
              key: ValueKey('bloch-column-vector-latex'),
              math:
                  r'\[|\psi\rangle=\begin{bmatrix}\cos(\theta/2)\\e^{i\varphi}\sin(\theta/2)\end{bmatrix}\]',
              textStyle: TextStyle(color: Color(0xFFD6E3F8)),
              inlineMathColor: Colors.white,
              displayMathHeight: 34,
            ),
          ),
          const Divider(height: 24),
          Text('Global phase γ: ${globalPhase.toStringAsFixed(2)} rad',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Multiplying the whole state by e^(iγ) changes neither the Bloch position nor measurement probabilities. Relative phase φ, by contrast, changes the Bloch position.',
            style: TextStyle(color: QubitQuestDialog.mutedText, height: 1.35),
          ),
        ],
      );

  static Widget _detailValue(String label, double value) =>
      Text('$label = ${value.toStringAsFixed(3)}');
}

class BlochProjection {
  const BlochProjection({required this.size, required this.camera});
  final Size size;
  final BlochCamera camera;

  Offset get center => size.center(Offset.zero);
  double get radius => math.min(size.width, size.height) * .38 * camera.zoom;

  Offset project(double x, double y, double z) {
    final rotated = _rotate(x, y, z);
    return center + Offset(rotated.$1 * radius, -rotated.$3 * radius);
  }

  Offset safeLabelCenter(
    Offset point,
    Size labelSize, {
    double horizontalInset = 8,
    double topInset = 8,
    double bottomInset = 8,
  }) {
    return Offset(
      point.dx.clamp(horizontalInset + labelSize.width / 2,
          size.width - horizontalInset - labelSize.width / 2),
      point.dy.clamp(topInset + labelSize.height / 2,
          size.height - bottomInset - labelSize.height / 2),
    );
  }

  ({Offset point, double depth}) projectWithDepth(
      double x, double y, double z) {
    final rotated = _rotate(x, y, z);
    return (
      point: center + Offset(rotated.$1 * radius, -rotated.$3 * radius),
      depth: rotated.$2,
    );
  }

  BlochState stateForPoint(Offset point, {required double globalPhase}) {
    final sx = ((point.dx - center.dx) / radius).clamp(-1.0, 1.0);
    final sz = (-(point.dy - center.dy) / radius).clamp(-1.0, 1.0);
    final sy = math.sqrt(math.max(0, 1 - sx * sx - sz * sz));
    final world = _inverseRotate(sx, sy, sz);
    return BlochState.fromCartesian(world.$1, world.$2, world.$3,
        globalPhase: globalPhase);
  }

  (double, double, double) _rotate(double x, double y, double z) {
    final cy = math.cos(camera.yaw), sy = math.sin(camera.yaw);
    final cp = math.cos(camera.pitch), sp = math.sin(camera.pitch);
    final x1 = x * cy - y * sy;
    final y1 = x * sy + y * cy;
    return (x1, y1 * cp + z * sp, -y1 * sp + z * cp);
  }

  (double, double, double) _inverseRotate(double x, double y, double z) {
    final cp = math.cos(camera.pitch), sp = math.sin(camera.pitch);
    final cy = math.cos(camera.yaw), sy = math.sin(camera.yaw);
    final y1 = y * cp - z * sp;
    final z1 = y * sp + z * cp;
    return (x * cy + y1 * sy, -x * sy + y1 * cy, z1);
  }
}

class BlochSpherePainter extends CustomPainter {
  const BlochSpherePainter({required this.state, required this.camera});
  final BlochState state;
  final BlochCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    final p = BlochProjection(size: size, camera: camera);
    final center = p.center;
    final radius = p.radius;
    final sphere = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.35, -.4),
        colors: [
          QubitQuestDialog.cyan.withValues(alpha: .18),
          QubitQuestDialog.innerColor.withValues(alpha: .06),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sphere);
    final front = Paint()
      ..color = QubitQuestDialog.cyan.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final back = Paint()
      ..color = QubitQuestDialog.cyan.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(center, radius, front);
    _circle(canvas, p, front, back,
        (angle) => (math.cos(angle), math.sin(angle), 0.0));
    _circle(canvas, p, front, back,
        (angle) => (math.cos(angle), 0.0, math.sin(angle)));
    for (final z in [-.5, .5]) {
      final r = math.sqrt(1 - z * z);
      _circle(canvas, p, front, back,
          (angle) => (r * math.cos(angle), r * math.sin(angle), z));
    }
    _axis(canvas, p, 1.25, 0, 0, 'X', front);
    _axis(canvas, p, 0, 1.25, 0, 'Y', front);
    _axis(canvas, p, 0, 0, 1.25, 'Z', front);
    final tip = p.project(state.x, state.y, state.z);
    canvas.drawLine(
        center,
        tip,
        Paint()
          ..color = QubitQuestDialog.purple
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(tip, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
        tip,
        13,
        Paint()
          ..color = QubitQuestDialog.purple.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  void _circle(
    Canvas canvas,
    BlochProjection projection,
    Paint front,
    Paint back,
    (double, double, double) Function(double angle) pointAt,
  ) {
    const segments = 72;
    var previousWorld = pointAt(0);
    var previous = projection.projectWithDepth(
        previousWorld.$1, previousWorld.$2, previousWorld.$3);
    for (var index = 1; index <= segments; index++) {
      final world = pointAt(2 * math.pi * index / segments);
      final current = projection.projectWithDepth(world.$1, world.$2, world.$3);
      canvas.drawLine(previous.point, current.point,
          (previous.depth + current.depth) / 2 >= 0 ? front : back);
      previous = current;
    }
  }

  void _axis(Canvas canvas, BlochProjection p, double x, double y, double z,
      String label, Paint paint) {
    final a = p.project(-x, -y, -z);
    final b = p.project(x, y, z);
    canvas.drawLine(a, b, paint);
    final text = TextPainter(
      text: TextSpan(
          text: label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelCenter = p.safeLabelCenter(b, text.size);
    text.paint(canvas, labelCenter - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant BlochSpherePainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.camera != camera;
}
