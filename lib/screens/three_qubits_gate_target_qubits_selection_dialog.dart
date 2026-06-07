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
          _TargetQubitPill(targetQubitIndex: widget.targetQubitIndex),
          const SizedBox(height: 16),
          _buildQubitGrid(
            title: 'Control qubit 1',
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
            title: 'Control qubit 2',
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
          'Target qubit: q$targetQubitIndex',
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
