import 'package:flutter/material.dart';

class TwoQubitsGateTargetQubitSelectionDialog extends StatefulWidget {
  final int targetQubitIndex;
  final int numQubits;

  const TwoQubitsGateTargetQubitSelectionDialog({
    super.key,
    required this.targetQubitIndex,
    required this.numQubits,
  });

  @override
  State<TwoQubitsGateTargetQubitSelectionDialog> createState() => _TwoQubitsGateTargetQubitSelectionDialogState();
}

class _TwoQubitsGateTargetQubitSelectionDialogState extends State<TwoQubitsGateTargetQubitSelectionDialog> {
  int? _control1Index;
  String? _errorMessage; // To display validation errors

  // List of all available qubit indices (e.g., [0, 1, 2, 3])
  List<int> _allQubitIndices = [];

  @override
  void initState() {
    super.initState();
    _allQubitIndices = List.generate(widget.numQubits, (i) => i);

    if (widget.numQubits < 2) {
      _errorMessage = "Not enough qubits for a two-qubits gate.";
    }
  }

  void _validateAndSubmit() {
    setState(() {
      if (widget.numQubits < 2) {
        _errorMessage = "Not enough qubits for a two-qubits gate.";
        return;
      }
      if (_control1Index == null) {
        _errorMessage = "Please select control qubit.";
        return;
      }
      if (_control1Index == widget.targetQubitIndex) {
        _errorMessage = "Control qubits cannot be the target qubit.";
        return;
      }

      _errorMessage = null; // Clear previous errors if valid

      Navigator.of(context).pop({
        'control1': _control1Index!,
      });
    });
  }

  // Helper to build a qubit selection grid
  Widget _buildQubitGrid({
    required String title,
    required int? selectedQubit, // The qubit selected for *this* control slot
    required Function(int?) onSelect, // Function to update the selected qubit, now can pass null
    required int targetQubitIndex,    // The target qubit index
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _allQubitIndices.map<Widget>((int qubitIndex) {
            bool isSelected = qubitIndex == selectedQubit; // Is this button currently selected for *this* control?

            // A button is "disabled" if it's the target qubit OR
            bool isDisabled = (qubitIndex == targetQubitIndex);

            return ElevatedButton(
              // If the button is disabled, onPressed is null.
              // Otherwise, if it's currently selected, tapping it should deselect (pass null).
              // If it's not selected, tapping it should select it (pass qubitIndex).
              onPressed: isDisabled
                  ? null
                  : () {
                onSelect(isSelected ? null : qubitIndex); // Pass null to deselect
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.blueAccent[700] : Colors.blueGrey[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: isSelected ? 8 : 2,
              ),
              child: Text(
                'q$qubitIndex',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Control Qubit (Target Qubit: ${widget.targetQubitIndex})', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.grey[800], // Dark background for the dialog
      content: SingleChildScrollView( // <--- REINTRODUCE SingleChildScrollView here
        child: Column(
          mainAxisSize: MainAxisSize.min, // Keep this, it's still good practice for Columns in dialogs
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Qubit 1 selection
            _buildQubitGrid(
              title: 'Select Control Qubit:',
              selectedQubit: _control1Index,
              onSelect: (q) {
                setState(() {
                  _control1Index = q;
                  _errorMessage = null;
                });
              },
              targetQubitIndex: widget.targetQubitIndex,
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}