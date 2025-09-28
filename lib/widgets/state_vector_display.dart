import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/utils/complex_formatter.dart';
import 'package:quantumquiz/utils/qq_fraction.dart';


class StateVectorDisplay extends StatefulWidget {
  final List<Complex> stateVector;
  final int numQubits;

  const StateVectorDisplay({
    super.key,
    required this.stateVector,
    required this.numQubits,
  });

  @override
  State<StateVectorDisplay> createState() => _StateVectorDisplayState();
}

class _StateVectorDisplayState extends State<StateVectorDisplay> {
  // false means "only show non-empty values" initially
  bool _showAllValues = false;
  // Threshold to consider a value "empty"
  static const double _emptyThreshold = 1e-9; // Values with magnitude less than this

  late ScrollController _stateVectorVerticalScrollController;
  // No need for a separate horizontal controller as it's the child of the vertical one
  // and the horizontal one's Scrollbar is not explicitly shown.

  @override
  void initState() {
    super.initState();
    _stateVectorVerticalScrollController = ScrollController(); // Initialize controller
  }

  @override
  void dispose() {
    _stateVectorVerticalScrollController.dispose(); // Dispose controller
    super.dispose();
  }


  // Helper to convert an integer index to a binary ket string (e.g., 0 -> |000>)
  String _toBinaryKet(int index, int numQubits) {
    String binary = index.toRadixString(2);
    return '|${binary.padLeft(numQubits, '0')}>';
  }

  @override
  Widget build(BuildContext context) {
    final int vectorSize = 1 << widget.numQubits; // Calculate 2^numQubits

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'State Vector:',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min, // Keep this row compact
              children: [
                const Text(
                  'Show All',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Transform.scale( // Scale down the switch if it's too large
                  scale: 0.8,
                  child: Switch(
                    value: _showAllValues,
                    onChanged: (bool newValue) {
                      setState(() {
                        _showAllValues = newValue;
                      });
                    },
                    activeColor: Colors.blueAccent,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
        // const SizedBox(height: 4),
        Expanded( // Use Expanded to ensure SingleChildScrollView takes available height
          child: LayoutBuilder( // <--- NEW: Use LayoutBuilder to get available width
            builder: (BuildContext context, BoxConstraints constraints) {
              return Scrollbar(
                controller: _stateVectorVerticalScrollController, // <-- Assign controller to Scrollbar
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _stateVectorVerticalScrollController, // <-- Assign controller to vertical SingleChildScrollView
                  child: ConstrainedBox( // <--- NEW: Forces the Column to be at least this wide
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    // Use the width from LayoutBuilder
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(vectorSize, (index) {
                        final Complex value = widget.stateVector[index];
                        final String ket = _toBinaryKet(
                            index, widget.numQubits);

                        // Conditionally hide "empty" values
                        if (!_showAllValues &&
                            value.magnitude < _emptyThreshold) {
                          return const SizedBox.shrink(); // Hide this entry
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.0),
                          // Smaller vertical padding
                          child: Text(
                            '$ket: ${formatComplex(value)}',
                            style: TextStyle(
                              color: value.magnitude > _emptyThreshold ? Colors
                                  .white : Colors.grey[600],
                              fontSize: 13, // Slightly smaller font for list items
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              );
            }
          ),
        ),
      ],
    );
  }
}