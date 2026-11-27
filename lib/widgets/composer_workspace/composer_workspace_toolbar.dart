import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_save_queue.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

/// Which region a medium-width workspace shows beside the palette rail.
enum ComposerWorkspaceView { circuit, results }

/// Compact circuit-level actions for the desktop workspace. Run controls are
/// deliberately absent: they live with their results in the Measure tab.
class ComposerWorkspaceToolbar extends StatelessWidget {
  const ComposerWorkspaceToolbar({
    super.key,
    required this.title,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.clearLabel,
    required this.onClear,
    this.context,
    this.qubitCount,
    this.qubitChoices = const [],
    this.onSelectQubits,
    this.saveQueue,
    this.panelToggles = const [],
    this.onResetLayout,
    this.view,
    this.onViewChanged,
    this.compact = false,
    this.focusCircuit,
    this.onFocusCircuitChanged,
    this.inlineQubitSelector = false,
  });

  /// Laboratory layout (v2.6 M11C): the Analysis / Focus circuit switch.
  /// Null hides it (the classic three-column layout).
  final bool? focusCircuit;
  final ValueChanged<bool>? onFocusCircuitChanged;

  /// Shows the qubit choices as one visible segmented control instead of a
  /// menu (the laboratory Composer opens straight into the Sandbox, so the
  /// register size is chosen here).
  final bool inlineQubitSelector;

  /// Narrow layouts wrap the same controls onto several lines.
  final bool compact;

  final String title;

  /// Short context such as the Notebook example name.
  final String? context;
  final int? qubitCount;
  final Iterable<int> qubitChoices;

  /// Opens (or re-opens from storage) the Sandbox with that many qubits.
  /// Null outside the Sandbox, where the qubit count is fixed.
  final ValueChanged<int>? onSelectQubits;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final String clearLabel;
  final VoidCallback onClear;
  final CircuitSaveQueue? saveQueue;
  final List<WorkspacePanelToggle> panelToggles;
  final VoidCallback? onResetLayout;

  /// Medium layouts switch between circuit and results instead of showing
  /// both; null when both are visible.
  final ComposerWorkspaceView? view;
  final ValueChanged<ComposerWorkspaceView>? onViewChanged;

  static bool get _isApple => const {TargetPlatform.macOS, TargetPlatform.iOS}
      .contains(defaultTargetPlatform);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => _build(
          context,
          width: constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : double.infinity,
        ),
      );

  Widget _build(BuildContext context, {required double width}) {
    final modifier = _isApple ? '⌘' : 'Ctrl+';
    // Narrower toolbars drop secondary text before anything can overflow.
    final showContext = compact || width >= 860;
    final showSaveText =
        compact || width >= (focusCircuit == null ? 980 : 1320);
    final children = <Widget>[
      const Icon(Icons.blur_on_rounded,
          size: 18, color: QubitQuestColors.accentInteractive),
      const SizedBox(width: 8),
      Flexible(
        flex: 0,
        child: Text(
          title,
          key: const ValueKey('composer-workspace-title'),
          overflow: TextOverflow.ellipsis,
          style: QubitQuestTypography.heading.copyWith(fontSize: 15),
        ),
      ),
      if (this.context case final detail? when showContext) ...[
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            detail,
            key: const ValueKey('composer-workspace-context'),
            overflow: TextOverflow.ellipsis,
            style: QubitQuestTypography.supporting,
          ),
        ),
      ],
      const SizedBox(width: 10),
      if (onSelectQubits != null && inlineQubitSelector)
        _QubitSelector(
          count: qubitCount,
          choices: qubitChoices.toList(),
          onSelected: onSelectQubits!,
        )
      else if (onSelectQubits != null)
        PopupMenuButton<int>(
          key: const ValueKey('web-composer-change-qubits'),
          tooltip: 'Change the number of qubits',
          onSelected: onSelectQubits,
          itemBuilder: (_) => [
            for (final n in qubitChoices)
              CheckedPopupMenuItem<int>(
                key: ValueKey('web-composer-qubits-$n'),
                value: n,
                checked: n == qubitCount,
                child: Text('$n qubit${n == 1 ? '' : 's'}'),
              ),
          ],
          child: _Pill(
            child: Text(
              '$qubitCount qubit${qubitCount == 1 ? '' : 's'}  ▾',
              key: const ValueKey('web-composer-qubit-count'),
              style: const TextStyle(
                color: QubitQuestColors.textBody,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        )
      else if (qubitCount != null)
        Text(
          '$qubitCount qubit${qubitCount == 1 ? '' : 's'}',
          key: const ValueKey('web-composer-qubit-count'),
          style: QubitQuestTypography.supporting,
        ),
      const _Divider(),
      IconButton(
        key: const ValueKey('composer-undo'),
        tooltip: 'Undo (${modifier}Z)',
        onPressed: canUndo ? onUndo : null,
        icon: const Icon(Icons.undo_rounded, size: 19),
      ),
      IconButton(
        key: const ValueKey('composer-redo'),
        tooltip: 'Redo (${modifier}Shift+Z)',
        onPressed: canRedo ? onRedo : null,
        icon: const Icon(Icons.redo_rounded, size: 19),
      ),
      TextButton.icon(
        key: const ValueKey('web-clear-circuit'),
        onPressed: onClear,
        icon: const Icon(Icons.restart_alt_rounded, size: 18),
        label: Text(clearLabel),
      ),
      if (saveQueue case final queue?) ...[
        const _Divider(),
        if (showSaveText)
          _SaveStatusText(queue: queue)
        else
          _SaveStatusIcon(queue: queue),
      ],
      const _Gap(),
      if (view != null && onViewChanged != null) ...[
        SegmentedButton<ComposerWorkspaceView>(
          key: const ValueKey('composer-workspace-view'),
          segments: const [
            ButtonSegment(
              value: ComposerWorkspaceView.circuit,
              label: Text('Circuit'),
            ),
            ButtonSegment(
              value: ComposerWorkspaceView.results,
              label: Text('Results'),
            ),
          ],
          selected: {view!},
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity(horizontal: -2, vertical: -3),
          ),
          onSelectionChanged: (s) => onViewChanged!(s.single),
        ),
        const SizedBox(width: 6),
      ],
      if (focusCircuit != null && onFocusCircuitChanged != null) ...[
        SegmentedButton<bool>(
          key: const ValueKey('composer-lab-mode'),
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.analytics_outlined, size: 16),
              label:
                  Text('Analysis', key: ValueKey('composer-lab-mode-analysis')),
              tooltip: 'Circuit with its state and measurement analysis',
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.fit_screen_outlined, size: 16),
              label: Text('Focus circuit',
                  key: ValueKey('composer-lab-mode-focus')),
              tooltip: 'Give the circuit the whole workspace for editing',
            ),
          ],
          selected: {focusCircuit!},
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity(horizontal: -2, vertical: -3),
          ),
          onSelectionChanged: (s) => onFocusCircuitChanged!(s.single),
        ),
        const SizedBox(width: 6),
      ],
      for (final toggle in panelToggles)
        IconButton(
          key: ValueKey('composer-toggle-${toggle.id}'),
          tooltip:
              toggle.visible ? 'Hide ${toggle.label}' : 'Show ${toggle.label}',
          isSelected: toggle.visible,
          onPressed: toggle.onPressed,
          icon: Icon(toggle.icon, size: 18),
          color: QubitQuestColors.textMuted,
          selectedIcon: Icon(toggle.icon,
              size: 18, color: QubitQuestColors.accentInteractive),
        ),
      if (onResetLayout != null)
        IconButton(
          key: const ValueKey('composer-reset-layout'),
          tooltip: 'Restore default layout',
          onPressed: onResetLayout,
          icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
          color: QubitQuestColors.textMuted,
        ),
    ];
    final decoration = BoxDecoration(
      color: focusCircuit == null ? null : QubitQuestSurfaces.page,
      border:
          const Border(bottom: BorderSide(color: QubitQuestColors.borderSoft)),
    );
    if (compact) {
      return Container(
        key: const ValueKey('composer-workspace-toolbar'),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        decoration: decoration,
        child: Wrap(
          key: const ValueKey('web-composer-workspace-actions'),
          crossAxisAlignment: WrapCrossAlignment.center,
          // Items never touch when the compact header wraps (M11C.1).
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final child in children)
              if (child is Flexible)
                child.child
              else if (child is ConstrainedBox)
                child.child!
              else if (child is! _Gap && child is! _Divider)
                child,
          ],
        ),
      );
    }
    return Container(
      key: const ValueKey('composer-workspace-toolbar'),
      height: focusCircuit == null ? 48 : 56,
      padding: EdgeInsets.symmetric(horizontal: focusCircuit == null ? 12 : 20),
      decoration: decoration,
      // The leading group scrolls horizontally when text is wider than
      // expected (large text, long example titles), so the toolbar can never
      // overflow; trailing layout controls stay put.
      child: Row(
        key: const ValueKey('web-composer-workspace-actions'),
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final child in children.takeWhile((c) => c is! _Gap))
                    child is Flexible ? child.child : child,
                ],
              ),
            ),
          ),
          ...children.skipWhile((c) => c is! _Gap).skip(1),
        ],
      ),
    );
  }
}

/// Marks where the wide toolbar pushes the remaining controls to the end.
class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

@immutable
class WorkspacePanelToggle {
  const WorkspacePanelToggle({
    required this.id,
    required this.label,
    required this.icon,
    required this.visible,
    required this.onPressed,
  });
  final String id;
  final String label;
  final IconData icon;
  final bool visible;
  final VoidCallback onPressed;
}

/// Register size as one visible choice ("Qubits 1 2 3 4 5"). Choosing a
/// size opens (or restores from storage) that Sandbox.
class _QubitSelector extends StatelessWidget {
  const _QubitSelector({
    required this.count,
    required this.choices,
    required this.onSelected,
  });

  final int? count;
  final List<int> choices;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Number of qubits',
        child: Row(
          key: const ValueKey('web-composer-qubit-selector'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Qubits',
                key: const ValueKey('web-composer-qubit-count'),
                semanticsLabel: '$count qubit${count == 1 ? '' : 's'}',
                style: QubitQuestTypography.supporting),
            const SizedBox(width: 8),
            for (final n in choices)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Tooltip(
                  message: n == count
                      ? '$n-qubit Sandbox (open)'
                      : 'Open the $n-qubit Sandbox',
                  child: Semantics(
                    selected: n == count,
                    button: true,
                    label: '$n qubit${n == 1 ? '' : 's'}',
                    excludeSemantics: true,
                    child: InkWell(
                      key: ValueKey('web-composer-qubits-$n'),
                      borderRadius: QubitQuestRadii.control,
                      onTap: n == count ? null : () => onSelected(n),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: n == count
                              ? QubitQuestColors.navigationSelected
                              : null,
                          borderRadius: QubitQuestRadii.control,
                          border: Border.all(
                            color: n == count
                                ? QubitQuestColors.accentInteractive
                                : QubitQuestColors.border,
                          ),
                        ),
                        child: Text(
                          '$n',
                          style: TextStyle(
                            color: n == count
                                ? QubitQuestColors.accentInteractive
                                : QubitQuestColors.textBody,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: QubitQuestColors.surfaceRaised,
          borderRadius: QubitQuestRadii.control,
        ),
        child: child,
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: QubitQuestColors.borderSoft,
      );
}

/// Icon-only save status for narrow toolbars; the full wording is in the
/// tooltip, and a failed save still offers Retry inline.
class _SaveStatusIcon extends StatelessWidget {
  const _SaveStatusIcon({required this.queue});
  final CircuitSaveQueue queue;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: queue,
        builder: (context, _) {
          final (icon, color, text) = switch (queue.status) {
            CircuitSaveStatus.idle => (
                Icons.cloud_outlined,
                QubitQuestColors.textMuted,
                'No pending circuit changes'
              ),
            CircuitSaveStatus.pending => (
                Icons.cloud_upload_outlined,
                QubitQuestColors.textMuted,
                'Saving circuit…'
              ),
            CircuitSaveStatus.saved => (
                Icons.cloud_done_outlined,
                QubitQuestColors.textMuted,
                'Circuit saved'
              ),
            CircuitSaveStatus.failed => (
                Icons.cloud_off_outlined,
                QubitQuestColors.error,
                'Circuit not saved. Please retry.'
              ),
          };
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: text,
                child: Icon(icon,
                    key: const ValueKey('composer-save-status-icon'),
                    size: 18,
                    color: color),
              ),
              if (queue.status == CircuitSaveStatus.failed)
                TextButton(
                  onPressed: queue.retry,
                  child: const Text('Retry save'),
                ),
            ],
          );
        },
      );
}

/// Save status with Retry inline. In the fixed-height wide toolbar it never
/// wraps (its parent is horizontally unbounded); in compact toolbars it may.
class _SaveStatusText extends StatelessWidget {
  const _SaveStatusText({required this.queue});
  final CircuitSaveQueue queue;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: queue,
        // A Wrap: unbounded in the wide toolbar's scrolling group (so Retry
        // stays inline) and wrapping, not overflowing, in compact toolbars.
        builder: (context, _) => Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              switch (queue.status) {
                CircuitSaveStatus.idle => 'No pending circuit changes',
                CircuitSaveStatus.pending => 'Saving circuit…',
                CircuitSaveStatus.saved => 'Circuit saved',
                CircuitSaveStatus.failed => 'Circuit not saved. Please retry.',
              },
              key: const ValueKey('composer-save-status-text'),
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                color: queue.status == CircuitSaveStatus.failed
                    ? QubitQuestColors.error
                    : QubitQuestColors.textMuted,
              ),
            ),
            if (queue.status == CircuitSaveStatus.failed)
              TextButton(
                onPressed: queue.retry,
                child: const Text('Retry save'),
              ),
          ],
        ),
      );
}
