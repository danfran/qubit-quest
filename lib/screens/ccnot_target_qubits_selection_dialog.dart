import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CCNOTTargetQubitsSelectionDialog extends StatefulWidget {
  final int targetQubitIndex;
  final int totalQubits;

  const CCNOTTargetQubitsSelectionDialog({
    super.key,
    required this.targetQubitIndex,
    required this.totalQubits,
  });

  @override
  State<CCNOTTargetQubitsSelectionDialog> createState() => _CCNOTTargetQubitsSelectionDialogState();
}

class _CCNOTTargetQubitsSelectionDialogState extends State<CCNOTTargetQubitsSelectionDialog> {
  int? _control1Index;
  int? _control2Index;
  String? _errorMessage; // To display validation errors

  // List of all available qubit indices (e.g., [0, 1, 2, 3])
  List<int> _allQubitIndices = [];

  @override
  void initState() {
    super.initState();
    _allQubitIndices = List.generate(widget.totalQubits, (i) => i);

    // Initial validation and pre-selection
    if (widget.totalQubits < 3) {
      // A Toffoli gate requires 3 distinct qubits (1 target, 2 controls)
      _errorMessage = "Not enough qubits for a Toffoli gate (requires 3 distinct qubits).";
    } else {
      // Try to pre-select initial distinct controls that are not the target qubit.
      // This improves UX by giving the user a starting point.
      int? firstAvailableControl;
      int? secondAvailableControl;

      for (int i = 0; i < widget.totalQubits; i++) {
        if (i == widget.targetQubitIndex) continue; // Skip target qubit

        if (firstAvailableControl == null) {
          firstAvailableControl = i;
        } else if (secondAvailableControl == null) {
          secondAvailableControl = i;
          break; // Found two distinct controls
        }
      }
      _control1Index = firstAvailableControl;
      _control2Index = secondAvailableControl;

      // If pre-selection couldn't find two distinct controls (e.g. 2 qubits only, target=0, control1=1, no control2)
      if (_control1Index == null || _control2Index == null || _control1Index == _control2Index) {
        _errorMessage = "Could not auto-select controls. Please select manually.";
      }
    }
  }

  // --- Validation Logic ---
  // This checks if the current selections are valid for applying the gate
  bool _isSelectionValid() {
    if (_control1Index == null || _control2Index == null) {
      return false; // Both controls must be selected
    }
    if (_control1Index == _control2Index) {
      return false; // Control qubits must be distinct
    }
    if (_control1Index == widget.targetQubitIndex || _control2Index == widget.targetQubitIndex) {
      return false; // Control qubits cannot be the target qubit itself
    }
    return true; // All validation checks passed
  }

  // --- Submission Handler ---
  void _validateAndSubmit() {
    // Re-check validation just before submission
    if (!_isSelectionValid()) {
      setState(() {
        if (_control1Index == null || _control2Index == null) {
          _errorMessage = "Please select both control qubits.";
        } else if (_control1Index == _control2Index) {
          _errorMessage = "Control qubits must be distinct.";
        } else if (_control1Index == widget.targetQubitIndex || _control2Index == widget.targetQubitIndex) {
          _errorMessage = "Control qubits cannot be the target qubit.";
        }
      });
      return; // Do not proceed if validation fails
    }

    // Validation passed, return the selected indices to the caller
    Navigator.of(context).pop({
      'control1': _control1Index!,
      'control2': _control2Index!,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configure Toffoli Gate (CCNOT)'),
      content: SingleChildScrollView( // Allows content to scroll if it exceeds screen height
        child: Column(
          mainAxisSize: MainAxisSize.min, // Column takes minimum space required by children
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
          children: [
            // Display the target qubit prominently
            Text(
              'Target Qubit: Q${widget.targetQubitIndex}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Dropdown for Control Qubit 1
            const Text('Select Control Qubit 1:', style: TextStyle(fontSize: 14)),
            DropdownButton<int>(
              value: _control1Index,
              hint: const Text('Select Qubit'),
              isExpanded: true, // Makes the dropdown fill available width
              onChanged: (int? newValue) {
                setState(() {
                  _control1Index = newValue;
                  _errorMessage = null; // Clear error when user makes a change
                });
              },
              items: _allQubitIndices.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('Q$value'),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Dropdown for Control Qubit 2
            const Text('Select Control Qubit 2:', style: TextStyle(fontSize: 14)),
            DropdownButton<int>(
              value: _control2Index,
              hint: const Text('Select Qubit'),
              isExpanded: true,
              onChanged: (int? newValue) {
                setState(() {
                  _control2Index = newValue;
                  _errorMessage = null; // Clear error when user makes a change
                });
              },
              items: _allQubitIndices.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('Q$value'),
                );
              }).toList(),
            ),

            // Display error message if any
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
        // Cancel button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Dismiss dialog without returning data
          },
          child: const Text('Cancel'),
        ),
        // Apply button (enabled only if selection is valid)
        ElevatedButton(
          onPressed: _isSelectionValid() ? _validateAndSubmit : null, // Button is disabled if _isSelectionValid() is false
          child: const Text('Apply'),
        ),
      ],
    );
  }
}