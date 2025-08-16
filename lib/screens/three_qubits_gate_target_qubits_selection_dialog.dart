import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ThreeQubitsGateTargetQubitsSelectionDialog extends StatefulWidget {
  final int targetQubitIndex;
  final int numQubits;

  const ThreeQubitsGateTargetQubitsSelectionDialog({
    super.key,
    required this.targetQubitIndex,
    required this.numQubits,
  });

  @override
  State<ThreeQubitsGateTargetQubitsSelectionDialog> createState() => _ThreeQubitsGateTargetQubitsSelectionDialogState();
}

class _ThreeQubitsGateTargetQubitsSelectionDialogState extends State<ThreeQubitsGateTargetQubitsSelectionDialog> {
  int? _control1Index;
  int? _control2Index;
  String? _errorMessage; // To display validation errors

  // List of all available qubit indices (e.g., [0, 1, 2, 3])
  List<int> _allQubitIndices = [];

  @override
  void initState() {
    super.initState();
    _allQubitIndices = List.generate(widget.numQubits, (i) => i);

    if (widget.numQubits < 3) {
      _errorMessage = "Not enough qubits for a three-qubits gate.";
    }
  }

  // --- Validation Logic ---
  bool _isSelectionValid() {
    if (_control1Index == null || _control2Index == null) {
      return false; // Not all selected
    }
    if (_control1Index == _control2Index) {
      return false; // Controls are the same
    }
    if (_control1Index == widget.targetQubitIndex || _control2Index == widget.targetQubitIndex) {
      return false; // Controls are the target
    }
    return true; // All good
  }

  void _validateAndSubmit() {
    setState(() {
      if (!_isSelectionValid()) {
        if (widget.numQubits < 3) {
          _errorMessage = "Not enough qubits for a three-qubits gate.";
        } else if (_control1Index == null || _control2Index == null) {
          _errorMessage = "Please select both control qubits.";
        } else if (_control1Index == _control2Index) {
          _errorMessage = "Control qubits must be distinct.";
        } else if (_control1Index == widget.targetQubitIndex || _control2Index == widget.targetQubitIndex) {
          _errorMessage = "Control qubits cannot be the target qubit.";
        }
        return; // Stop here if invalid
      }
      _errorMessage = null; // Clear previous errors if valid

      Navigator.of(context).pop({
        'control1': _control1Index!,
        'control2': _control2Index!,
      });
    });
  }

  // Helper to build a qubit selection grid
  Widget _buildQubitGrid({
    required String title,
    required int? selectedQubit, // The qubit selected for *this* control slot
    required Function(int?) onSelect, // Function to update the selected qubit, now can pass null
    required int? otherSelectedQubit, // The qubit selected for the *other* control slot
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
            // if it's the *other* control qubit (unless it's the one we're currently trying to deselect).
            bool isDisabled = (qubitIndex == targetQubitIndex) ||
                (qubitIndex == otherSelectedQubit && !isSelected);

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
      title: Text('Select Control Qubits (Target Qubit: ${widget.targetQubitIndex})', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.grey[850], // Dark background for the dialog
      content: SingleChildScrollView( // <--- REINTRODUCE SingleChildScrollView here
        child: Column(
          mainAxisSize: MainAxisSize.min, // Keep this, it's still good practice for Columns in dialogs
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Qubit 1 selection
            _buildQubitGrid(
              title: 'Select Control Qubit 1:',
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
            const SizedBox(height: 20),

            // Control Qubit 2 selection
            _buildQubitGrid(
              title: 'Select Control Qubit 2:',
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
          onPressed: _isSelectionValid() ? _validateAndSubmit : null,
          child: const Text('Apply'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}