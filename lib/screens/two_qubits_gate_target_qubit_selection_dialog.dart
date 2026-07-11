import 'package:flutter/material.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

class TwoQubitsGateTargetQubitSelectionDialog extends StatefulWidget {
  final int targetQubitIndex;
  final int numQubits;

  const TwoQubitsGateTargetQubitSelectionDialog({
    super.key,
    required this.targetQubitIndex,
    required this.numQubits,
  });

  @override
  State<TwoQubitsGateTargetQubitSelectionDialog> createState() =>
      _TwoQubitsGateTargetQubitSelectionDialogState();
}

class _TwoQubitsGateTargetQubitSelectionDialogState
    extends State<TwoQubitsGateTargetQubitSelectionDialog> {
  int? _control1Index;
  String? _errorMessage;
  List<int> _allQubitIndices = [];

  @override
  void initState() {
    super.initState();
    _allQubitIndices = List.generate(widget.numQubits, (i) => i);

    if (widget.numQubits < 2) {
      _errorMessage = 'Not enough qubits for a two-qubits gate.';
    }
  }

  bool _isSelectionValid() {
    return widget.numQubits >= 2 &&
        _control1Index != null &&
        _control1Index != widget.targetQubitIndex;
  }

  void _validateAndSubmit() {
    setState(() {
      if (widget.numQubits < 2) {
        _errorMessage = 'Not enough qubits for a two-qubits gate.';
        return;
      }
      if (_control1Index == null) {
        _errorMessage = 'Please select control qubit.';
        return;
      }
      if (_control1Index == widget.targetQubitIndex) {
        _errorMessage = 'Control qubits cannot be the target qubit.';
        return;
      }

      _errorMessage = null;

      Navigator.of(context).pop({
        'control1': _control1Index!,
      });
    });
  }

  Widget _buildQubitGrid({
    required String title,
    required int? selectedQubit,
    required ValueChanged<int?> onSelect,
    required int targetQubitIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFD6E3F8),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allQubitIndices.map<Widget>((int qubitIndex) {
            final bool isSelected = qubitIndex == selectedQubit;
            final bool isDisabled = qubitIndex == targetQubitIndex;

            return QubitQuestQubitButton(
              label: 'q$qubitIndex',
              selected: isSelected,
              disabled: isDisabled,
              onPressed: () {
                onSelect(isSelected ? null : qubitIndex);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return QubitQuestDialog(
      title: 'Select Control Qubit',
      actions: [
        QubitQuestDialogButton.secondary(
          label: 'Cancel',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        QubitQuestDialogButton.primary(
          label: 'Apply',
          onPressed: _isSelectionValid() ? _validateAndSubmit : null,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ControlTargetPreview(
            controlQubitIndex: _control1Index,
            targetQubitIndex: widget.targetQubitIndex,
          ),
          const SizedBox(height: 12),
          _TargetQubitPill(targetQubitIndex: widget.targetQubitIndex),
          const SizedBox(height: 16),
          _buildQubitGrid(
            title: 'Choose Control (decides whether the operation happens)',
            selectedQubit: _control1Index,
            onSelect: (q) {
              setState(() {
                _control1Index = q;
                _errorMessage = null;
              });
            },
            targetQubitIndex: widget.targetQubitIndex,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFFF8A80),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ControlTargetPreview extends StatelessWidget {
  const _ControlTargetPreview({
    required this.controlQubitIndex,
    required this.targetQubitIndex,
  });

  final int? controlQubitIndex;
  final int targetQubitIndex;

  @override
  Widget build(BuildContext context) {
    final controlLabel =
        controlQubitIndex == null ? '?' : 'q$controlQubitIndex';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: QubitQuestDialog.cyan.withValues(alpha: 0.30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.account_tree_outlined,
              color: QubitQuestDialog.cyan,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PreviewRoleLine(
                    label: 'Control',
                    value: controlLabel,
                    helper: 'decides whether it happens',
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 22, top: 2, bottom: 2),
                    child: Text(
                      '|',
                      style: TextStyle(
                        color: QubitQuestDialog.cyan,
                        fontSize: 16,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _PreviewRoleLine(
                    label: 'Target',
                    value: 'q$targetQubitIndex',
                    helper: 'may be changed',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRoleLine extends StatelessWidget {
  const _PreviewRoleLine({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: QubitQuestDialog.cyan,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: '  $helper',
            style: const TextStyle(
              color: QubitQuestDialog.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 13, height: 1.25),
    );
  }
}

class _TargetQubitPill extends StatelessWidget {
  const _TargetQubitPill({required this.targetQubitIndex});

  final int targetQubitIndex;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          'Target (will be changed): q$targetQubitIndex',
          style: const TextStyle(
            color: Color(0xFFB9C6DD),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
