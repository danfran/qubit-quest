import 'package:flutter/material.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

class ThreeQubitsGateTargetQubitsSelectionDialog extends StatefulWidget {
  final int targetQubitIndex;
  final int numQubits;

  const ThreeQubitsGateTargetQubitsSelectionDialog({
    super.key,
    required this.targetQubitIndex,
    required this.numQubits,
  });

  @override
  State<ThreeQubitsGateTargetQubitsSelectionDialog> createState() =>
      _ThreeQubitsGateTargetQubitsSelectionDialogState();
}

class _ThreeQubitsGateTargetQubitsSelectionDialogState
    extends State<ThreeQubitsGateTargetQubitsSelectionDialog> {
  int? _control1Index;
  int? _control2Index;
  String? _errorMessage;
  List<int> _allQubitIndices = [];

  @override
  void initState() {
    super.initState();
    _allQubitIndices = List.generate(widget.numQubits, (i) => i);

    if (widget.numQubits < 3) {
      _errorMessage = 'Not enough qubits for a three-qubits gate.';
    }
  }

  bool _isSelectionValid() {
    if (_control1Index == null || _control2Index == null) {
      return false;
    }
    if (_control1Index == _control2Index) {
      return false;
    }
    if (_control1Index == widget.targetQubitIndex ||
        _control2Index == widget.targetQubitIndex) {
      return false;
    }
    return true;
  }

  void _validateAndSubmit() {
    setState(() {
      if (!_isSelectionValid()) {
        if (widget.numQubits < 3) {
          _errorMessage = 'Not enough qubits for a three-qubits gate.';
        } else if (_control1Index == null || _control2Index == null) {
          _errorMessage = 'Please select both control qubits.';
        } else if (_control1Index == _control2Index) {
          _errorMessage = 'Control qubits must be distinct.';
        } else if (_control1Index == widget.targetQubitIndex ||
            _control2Index == widget.targetQubitIndex) {
          _errorMessage = 'Control qubits cannot be the target qubit.';
        }
        return;
      }

      _errorMessage = null;

      Navigator.of(context).pop({
        'control1': _control1Index!,
        'control2': _control2Index!,
      });
    });
  }

  Widget _buildQubitGrid({
    required String title,
    required int? selectedQubit,
    required ValueChanged<int?> onSelect,
    required int? otherSelectedQubit,
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
            final bool isDisabled = qubitIndex == targetQubitIndex ||
                (qubitIndex == otherSelectedQubit && !isSelected);

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
      title: 'Select Control Qubits',
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
          _ControlsTargetPreview(
            control1QubitIndex: _control1Index,
            control2QubitIndex: _control2Index,
            targetQubitIndex: widget.targetQubitIndex,
          ),
          const SizedBox(height: 12),
          _TargetQubitPill(targetQubitIndex: widget.targetQubitIndex),
          const SizedBox(height: 16),
          _buildQubitGrid(
            title: 'Choose Control 1 (decides whether the operation happens)',
            selectedQubit: _control1Index,
            onSelect: (q) {
              setState(() {
                _control1Index = q;
                _errorMessage = null;
              });
            },
            otherSelectedQubit: _control2Index,
            targetQubitIndex: widget.targetQubitIndex,
          ),
          const SizedBox(height: 16),
          _buildQubitGrid(
            title: 'Choose Control 2 (also must allow the operation)',
            selectedQubit: _control2Index,
            onSelect: (q) {
              setState(() {
                _control2Index = q;
                _errorMessage = null;
              });
            },
            otherSelectedQubit: _control1Index,
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

class _ControlsTargetPreview extends StatelessWidget {
  const _ControlsTargetPreview({
    required this.control1QubitIndex,
    required this.control2QubitIndex,
    required this.targetQubitIndex,
  });

  final int? control1QubitIndex;
  final int? control2QubitIndex;
  final int targetQubitIndex;

  @override
  Widget build(BuildContext context) {
    final control1Label =
        control1QubitIndex == null ? '?' : 'q$control1QubitIndex';
    final control2Label =
        control2QubitIndex == null ? '?' : 'q$control2QubitIndex';

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
                    label: 'Control 1',
                    value: control1Label,
                    helper: 'must allow it',
                  ),
                  const SizedBox(height: 3),
                  _PreviewRoleLine(
                    label: 'Control 2',
                    value: control2Label,
                    helper: 'must also allow it',
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
