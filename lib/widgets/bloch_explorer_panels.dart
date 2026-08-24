import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/canonical_qubit_state.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

const _blochPauliGateTypes = <SelectedGateType>[
  SelectedGateType.x,
  SelectedGateType.y,
  SelectedGateType.z,
];
const _blochHadamardGateTypes = <SelectedGateType>[
  SelectedGateType.hadamard,
];
const _blochPhaseGateTypes = <SelectedGateType>[
  SelectedGateType.s,
  SelectedGateType.t,
];
const _blochRotationGateTypes = <SelectedGateType>[
  SelectedGateType.rx,
  SelectedGateType.ry,
  SelectedGateType.rz,
];

const blochExplorerGateTypes = <SelectedGateType>[
  ..._blochPauliGateTypes,
  ..._blochHadamardGateTypes,
  ..._blochPhaseGateTypes,
  ..._blochRotationGateTypes,
];

class BlochGatePanel extends StatelessWidget {
  const BlochGatePanel({
    super.key,
    required this.initialState,
    required this.rotationAngle,
    required this.enabled,
    required this.onSelectPreset,
    required this.onApplyGate,
    required this.onInspectGate,
    required this.onAngleChanged,
  });

  final BlochState initialState;
  final double rotationAngle;
  final bool enabled;
  final ValueChanged<CanonicalQubitState> onSelectPreset;
  final ValueChanged<SelectedGateType> onApplyGate;
  final ValueChanged<Gate> onInspectGate;
  final ValueChanged<double> onAngleChanged;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('bloch-gate-strip'),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _presetSelector(),
            const SizedBox(height: 5),
            Wrap(spacing: 14, runSpacing: 6, children: [
              _gateGroup('Pauli', _blochPauliGateTypes),
              _gateGroup('Hadamard', _blochHadamardGateTypes),
              _gateGroup('Phase', _blochPhaseGateTypes),
            ]),
            const SizedBox(height: 6),
            LayoutBuilder(builder: (context, constraints) {
              final angleWidth = math.max(130.0, constraints.maxWidth - 170);
              return Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  _gateGroup('Rotations', _blochRotationGateTypes),
                  SizedBox(
                    key: const ValueKey('bloch-gate-angle-control'),
                    width: angleWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gate angle: ${_formatAngle(rotationAngle)}',
                          style: const TextStyle(
                            color: QubitQuestDialog.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(
                          height: 38,
                          child: Slider(
                            key: const ValueKey('bloch-rotation-slider'),
                            value: rotationAngle,
                            min: -math.pi,
                            max: math.pi,
                            divisions: 16,
                            onChanged: onAngleChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      );

  Widget _presetSelector() {
    final preset = CanonicalQubitState.matching(initialState);
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<CanonicalQubitState>(
        key: const ValueKey('bloch-presets-menu'),
        tooltip: 'Choose initial-state preset',
        enabled: enabled,
        onSelected: onSelectPreset,
        itemBuilder: (context) => [
          for (final state in CanonicalQubitState.values)
            PopupMenuItem(
              key: ValueKey('bloch-preset-${state.name}'),
              value: state,
              child: Text(state.label),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: QubitQuestDialog.innerColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: QubitQuestDialog.borderSoftColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_outlined, size: 16),
              const SizedBox(width: 5),
              Text(
                'Start: ${preset?.label ?? 'custom state'}',
                key: const ValueKey('bloch-start-state-label'),
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_drop_down_rounded, size: 17),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gateGroup(String label, List<SelectedGateType> types) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: QubitQuestDialog.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [for (final type in types) _gateChip(type)],
          ),
        ],
      );

  Widget _gateChip(SelectedGateType type) {
    final rotation = type == SelectedGateType.rx ||
        type == SelectedGateType.ry ||
        type == SelectedGateType.rz;
    final gate =
        Gate.fromIdentifier(type, angle: rotation ? rotationAngle : null);
    return QubitQuestGateTile(
      key: ValueKey('bloch-gate-${type.name}'),
      gate: gate,
      size: 44,
      tooltip: 'Apply ${gate.label.replaceAll('\n', ' ')} gate',
      onPressed: enabled ? () => onApplyGate(type) : null,
      onInspect: enabled ? () => onInspectGate(gate) : null,
    );
  }

  static String _formatAngle(double angle) {
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

class BlochPlaybackControls extends StatelessWidget {
  const BlochPlaybackControls({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.canReplay,
    required this.replayRunning,
    required this.instant,
    required this.onUndo,
    required this.onRedo,
    required this.onReplay,
    required this.onReset,
    required this.onInstantChanged,
  });

  final bool canUndo;
  final bool canRedo;
  final bool canReplay;
  final bool replayRunning;
  final bool instant;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onReplay;
  final VoidCallback onReset;
  final ValueChanged<bool> onInstantChanged;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('bloch-transport-controls'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: QubitQuestDialog.innerColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final controls = <Widget>[
            _button('bloch-undo', 'Undo', Icons.undo_rounded,
                !replayRunning && canUndo ? onUndo : null),
            _button('bloch-redo', 'Redo', Icons.redo_rounded,
                !replayRunning && canRedo ? onRedo : null),
            _button('bloch-replay', 'Replay', Icons.play_circle_outline_rounded,
                !replayRunning && canReplay ? onReplay : null),
            _button('bloch-reset', 'Reset', Icons.restart_alt_rounded, onReset),
          ];
          return Row(children: [
            Expanded(
              child: Row(children: [
                for (final control in controls) Expanded(child: control),
              ]),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bolt_rounded, size: 16),
              const Text('Instant', style: TextStyle(fontSize: 11)),
              Checkbox(
                key: const ValueKey('bloch-instant-mode'),
                value: instant,
                visualDensity: VisualDensity.compact,
                onChanged: (value) => onInstantChanged(value ?? false),
              ),
            ]),
          ]);
        }),
      );

  Widget _button(
          String key, String label, IconData icon, VoidCallback? callback) =>
      Semantics(
        key: ValueKey(key),
        button: true,
        enabled: callback != null,
        label: label,
        child: Tooltip(
          message: label,
          child: TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            ),
            onPressed: callback,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 20),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: const TextStyle(fontSize: 10, height: 1),
              ),
            ]),
          ),
        ),
      );
}

class BlochHistoryPanel extends StatelessWidget {
  const BlochHistoryPanel({
    super.key,
    required this.entries,
    required this.currentIndex,
    required this.selectedIndex,
    required this.activeReplayIndex,
    required this.replayRunning,
    required this.scrollController,
    required this.onExpansionChanged,
    required this.onSelected,
    required this.onInspect,
  });

  final List<BlochHistoryEntry> entries;
  final int currentIndex;
  final int? selectedIndex;
  final int? activeReplayIndex;
  final bool replayRunning;
  final ScrollController scrollController;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onInspect;

  String get _operationSummary =>
      currentIndex == 1 ? '1 operation' : '$currentIndex operations';

  String get _status {
    final active = activeReplayIndex;
    if (replayRunning && active != null) {
      return 'Step $active / $currentIndex · ${entries[active].label}';
    }
    final selected = selectedIndex;
    if (selected != null) {
      final position = selected == 0
          ? 'Replay start: Start'
          : 'Replay start: Step $selected / $currentIndex · ${entries[selected].label}';
      return '$_operationSummary · $position';
    }
    return _operationSummary;
  }

  @override
  Widget build(BuildContext context) => Container(
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
            onExpansionChanged: onExpansionChanged,
            title: const Text('History',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            subtitle: Text(_status, style: const TextStyle(fontSize: 10)),
            children: [
              SizedBox(
                height: 60,
                child: ListView.builder(
                  key: const ValueKey('bloch-history-timeline'),
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemExtent: 82,
                  itemCount: currentIndex + 1,
                  itemBuilder: (context, index) => _entry(index),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _entry(int index) {
    final entry = entries[index];
    final active = index == activeReplayIndex;
    final selected = index == selectedIndex;
    final completed = replayRunning &&
        activeReplayIndex != null &&
        index < activeReplayIndex!;
    final labelStyle = TextStyle(
      color: active ? Colors.white : QubitQuestDialog.mutedText,
      fontSize: 10,
      fontWeight: active ? FontWeight.w900 : FontWeight.w600,
    );
    return Semantics(
      key: ValueKey('bloch-history-step-$index'),
      button: !replayRunning,
      selected: selected,
      label: '${index == 0 ? 'Start' : 'Step $index, ${entry.label}'}'
          '${selected ? ', replay start' : ''}'
          '${active ? ', currently replaying' : ''}',
      child: InkWell(
        onTap: replayRunning ? null : () => onSelected(index),
        onLongPress: !replayRunning && entry.gate != null
            ? () => onInspect(index)
            : null,
        child: Stack(children: [
          Positioned(
            left: index == 0 ? 41 : 0,
            right: index == currentIndex ? 41 : 0,
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
              _BlochHistoryMarker(
                active: active,
                selected: selected,
                completed: completed,
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
}

class _BlochHistoryMarker extends StatelessWidget {
  const _BlochHistoryMarker({
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

class BlochStateMathPanel extends StatelessWidget {
  const BlochStateMathPanel({
    super.key,
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
          Wrap(spacing: 18, runSpacing: 5, children: [
            _detailValue('θ', state.theta),
            _detailValue('φ', state.phi),
            _detailValue('x', state.x),
            _detailValue('y', state.y),
            _detailValue('z', state.z),
            Text(
                'P(|0⟩) = ${(state.probabilityZero * 100).toStringAsFixed(1)}%'),
            Text(
                'P(|1⟩) = ${(state.probabilityOne * 100).toStringAsFixed(1)}%'),
          ]),
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
