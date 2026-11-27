import 'package:flutter/material.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

/// Formats a control/target topology, e.g. "Controls: q0, q2, q3 · Target: q1".
String multiControlledTopologySummary(List<int> controls, int target) {
  final sorted = [...controls]..sort();
  final names = sorted.isEmpty ? '—' : sorted.map((q) => 'q$q').join(', ');
  return 'Controls: $names · Target: q$target';
}

/// Why a multi-controlled X cannot be placed in a register of [numQubits]
/// qubits, or null when it can (three controls plus a target).
String? multiControlledUnavailableReason(int numQubits) =>
    numQubits >= QuantumCircuit.minMultiControlCount + 1
        ? null
        : 'MCX needs at least ${QuantumCircuit.minMultiControlCount + 1} '
            'qubits (three controls and a target); this circuit has '
            '$numQubits. Use CX or CCX for one or two controls.';

/// Chooses the controls of a multi-controlled X whose target is the row it
/// was dropped on (v2.6 M7). Returns the controls, or null when cancelled.
///
/// Every other qubit starts selected (with five qubits: four controls);
/// Place is enabled only for three or more distinct controls, so an
/// invalid topology is never committed.
Future<List<int>?> showMultiControlledPlacementDialog(
  BuildContext context, {
  required int targetQubit,
  required int numQubits,
}) {
  if (multiControlledUnavailableReason(numQubits) != null ||
      targetQubit < 0 ||
      targetQubit >= numQubits) {
    return Future.value(null);
  }
  return showDialog<List<int>>(
    context: context,
    builder: (_) => MultiControlledPlacementDialog(
      targetQubit: targetQubit,
      numQubits: numQubits,
    ),
  );
}

class MultiControlledPlacementDialog extends StatefulWidget {
  const MultiControlledPlacementDialog({
    super.key,
    required this.targetQubit,
    required this.numQubits,
  });

  final int targetQubit;
  final int numQubits;

  @override
  State<MultiControlledPlacementDialog> createState() =>
      _MultiControlledPlacementDialogState();
}

class _MultiControlledPlacementDialogState
    extends State<MultiControlledPlacementDialog> {
  late final Set<int> _controls = {
    for (var q = 0; q < widget.numQubits; q++)
      if (q != widget.targetQubit) q,
  };

  bool get _valid =>
      _controls.length >= QuantumCircuit.minMultiControlCount &&
      !_controls.contains(widget.targetQubit);

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(color: Color(0xFFB6C4DA), fontSize: 13);
    final count = _controls.length;
    return QubitQuestDialog(
      title: 'Multi-controlled X',
      actions: [
        QubitQuestDialogButton.secondary(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        QubitQuestDialogButton.primary(
          key: const ValueKey('mcx-place'),
          label: 'Place',
          onPressed: _valid
              ? () => Navigator.of(context).pop(_controls.toList()..sort())
              : null,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: QubitQuestDialog.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: QubitQuestDialog.cyan.withValues(alpha: 0.30)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const Icon(Icons.account_tree_outlined,
                    color: QubitQuestDialog.cyan, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        multiControlledTopologySummary(
                            _controls.toList(), widget.targetQubit),
                        key: const ValueKey('mcx-topology'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count control${count == 1 ? '' : 's'} · the target '
                        'flips in every basis component where all controls '
                        'are 1',
                        key: const ValueKey('mcx-control-count'),
                        style: muted,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose controls (three or more)',
            style: TextStyle(
                fontSize: 13,
                color: Color(0xFFD6E3F8),
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var q = 0; q < widget.numQubits; q++)
                QubitQuestQubitButton(
                  key: ValueKey('mcx-control-q$q'),
                  label: 'q$q',
                  selected: _controls.contains(q),
                  disabled: q == widget.targetQubit,
                  onPressed: () => setState(() {
                    if (!_controls.remove(q)) _controls.add(q);
                  }),
                ),
            ],
          ),
          if (!_valid) ...[
            const SizedBox(height: 14),
            const Text(
              'Select at least three controls. For one or two controls use '
              'CX or CCX.',
              key: ValueKey('mcx-invalid'),
              style: TextStyle(
                  color: Color(0xFFFF8A80),
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
