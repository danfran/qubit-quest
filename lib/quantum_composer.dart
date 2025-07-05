import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/quantum_circuit.dart';
import 'package:quantumquiz/quantum_circuit_painter.dart';
import 'package:quantumquiz/quantum_doc_dialog.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/quantum_task_dialog.dart';
import 'package:quantumquiz/selected_gate_type.dart';
import 'package:quantumquiz/utils/level_completion_action.dart';

import 'cnot_target_qubit_selection_dialog.dart';
import 'models/qq_level.dart';

class QuantumComposer extends StatefulWidget {
  final int levelId;
  final QQLevel level; // Now, QuantumComposer accepts a Level object

  const QuantumComposer({
    Key? key,
    required this.levelId, // Level is now required
    required this.level, // Level is now required
  }) : super(key: key);

  @override
  _QuantumComposerState createState() => _QuantumComposerState();
}

class _QuantumComposerState extends State<QuantumComposer> {
  late int _numQubits;
  late String _taskDescription;
  late List<Complex> _initialState;
  late List<SelectedGateType> _availableGates;
  late List<List<Complex>> _solutionVector;
  late QuantumCircuit _circuit;

  String simulationResult = "Run the circuit to see the result";
  // List<double> measurementProbabilities = [0.0, 0.0, 0.0, 0.0];
  SelectedGateType _currentMode = SelectedGateType.none;
  int? _cnotTargetQubit; // To track the target for CNOT

  // State to manage the highlight box for drag-and-drop
  Offset? _draggingOffset;
  SelectedGateType _draggingGateType = SelectedGateType.none;

  final ValueNotifier<double> _circuitWidthNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _numQubits = widget.level.numQubits;
    _taskDescription = widget.level.taskDescription;
    _initialState = widget.level.initialQubitsState;
    _availableGates = widget.level.availableGates;
    _solutionVector = widget.level.solutionFinalVector;
    _circuit = QuantumCircuit(currentLevel: widget.level);

    print('Task: $_taskDescription');
    print('Number of qubits: $_numQubits');
    print('Initial state: $_initialState');
    print('Available gates: $_availableGates');
    print('Solution vector: $_solutionVector');
  }


  void _setInteractionMode(SelectedGateType mode) {
    setState(() {
      _currentMode = mode;
      _cnotTargetQubit = null; // Reset CNOT control on mode change
      if (mode == SelectedGateType.delete) {
        simulationResult = "Tap on a gate to delete it.";
      } else {
        simulationResult = "Drag a gate onto the circuit."; // Default message for drag mode
      }
    });
    print('Interaction mode set to: $_currentMode');
  }

  // Method to handle a gate being dropped onto the circuit area
  Offset? _gatePositionToLocal(Offset offset) {
    final RenderBox? renderBox = _gestureDetectorKey.currentContext
        ?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      print('Error: Could not find RenderBox for GestureDetector.');
      return null;
    }
    final localPosition = renderBox.globalToLocal(offset);
    return localPosition;
  }

  // Method to handle a gate being dropped onto the circuit area
  Future<void> _handleGateDrop(DragTargetDetails<SelectedGateType> details) async {
    // Corrected: Use details.offset for the local drop position
    print('Gate dropped at local position: ${details.offset}'); // localPosition relative to the DragTarget
    print('Dropped gate type: ${details.data}'); // The data from the Draggable

    final localPosition = _gatePositionToLocal(details.offset);

    if (localPosition == null) {
      print('Error: Could not convert global position to local.');
      return;
    }

    final droppedGateType = details.data;
    // final dropPosition = details.offset; // Use details.offset
    final dropPosition = localPosition; // Use details.offset

    // Use the painter's logic to determine the qubit line and insertion position
    final painter = QuantumCircuitPainter(_circuit, _circuitWidthNotifier, _draggingOffset, _draggingGateType); // Painter knows layout constants

    // Determine the tapped qubit line based on the vertical drop position
    final tappedQubitLine = painter.getTappedQubitLine(dropPosition);

    if (tappedQubitLine == null) {
      print('Dropped outside qubit lines. Ignoring drop.');
      // Optionally provide feedback to the user
      return;
    }

    // Determine the horizontal insertion position based on the horizontal drop position
    final insertionPosition = painter.getInsertionPosition(dropPosition); // <-- Need to implement this in Painter

    if (insertionPosition == null) {
      print('Could not determine valid insertion position. Ignoring drop.');
      // Optionally provide feedback
      return;
    }

    print('Dropped on Qubit line: $tappedQubitLine at insertion position: $insertionPosition');

    if (droppedGateType == SelectedGateType.cnot) {
      // For CNOT drag and drop, we need to select control/target after dropping.
      // This is a more complex interaction. For simplicity in this initial drag/drop,
      // let's assume CNOT drag requires dropping the control part, and then
      // a subsequent tap selects the target. Or, the drop position implies control,
      // and the nearest other qubit line is the target? This needs careful UI design.

      // A simpler approach for initial drag/drop: CNOT drag places a CNOT
      // with control on the dropped line and target on the next line (if available).
      // This might not be ideal but simplifies the initial implementation.
      // A better approach might involve a special CNOT drag feedback that shows
      // both control and target and lets the user position both before dropping.

      // Let's go with the simpler approach for now: Drop implies control qubit.
      // Target is the next available qubit line, if different from control.
      int? targetQubitLine;

      if (_numQubits == 1) {
        print('Cannot place CNOT on single qubit or invalid target.');
          // Optionally provide feedback
        return;
      } else if (_numQubits == 2) {
        if (tappedQubitLine == 0) {
          targetQubitLine = 1;
        } else if (tappedQubitLine == 1) {
          targetQubitLine = 0;
        }
      } else if (_numQubits > 2){
        await _showTargetSelectionDialog(context, tappedQubitLine, _numQubits);
        if (_cnotTargetQubit != null) {
          targetQubitLine = _cnotTargetQubit;
        }
      }

      if (targetQubitLine != null && tappedQubitLine != targetQubitLine) {
        print('CNOT placement (control line = $tappedQubitLine and target line = $_cnotTargetQubit).');
        _circuit.insertDoublePlacedGateAt(droppedGateType, insertionPosition, tappedQubitLine, targetQubitLine);
        print("Gate CNOT inserted at position $insertionPosition on qubits $tappedQubitLine and $targetQubitLine.");
        print(_circuit);
      } else {
        print('Invalid CNOT placement (control == target or not enough qubits).');
        // Optionally provide feedback
        return;
      }
    } else {
      _circuit.insertSinglePlacedGateAt(droppedGateType, insertionPosition, tappedQubitLine);
      print("Gate inserted at position $insertionPosition on qubit $tappedQubitLine.");
      print(_circuit);
    }

    _runSimulation(); // Optionally run simulation after placing
  }

  Future<void> _showTargetSelectionDialog(BuildContext context, int controlQubit, int numQubits) async {
    // Ensure dialog is not already shown
    if (ModalRoute.of(context)?.isCurrent != true || Navigator.of(context).canPop() == false) {
      // This is a crude check to avoid showing multiple dialogs.
      // A more robust solution might involve a global boolean or state for dialog visibility.
      return;
    }

    final int? selectedTarget = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CNOTTargetQubitSelectionDialog(
          controlQubitIndex: controlQubit,
          numQubits: numQubits,
        );
      },
    );

    _cnotTargetQubit = selectedTarget;
  }

  void _selectGateForPlacement(SelectedGateType gateType) {
    setState(() {
      _currentMode = gateType;
      _cnotTargetQubit = null; // Reset CNOT control on new gate selection
      simulationResult = "Tap on a qubit line to place the gate.";
      if (gateType == SelectedGateType.cnot) {
        simulationResult = "Tap on the control qubit for CNOT.";
      } else if (gateType == SelectedGateType.none) {
        simulationResult = "Run the circuit to see the result";
      } else if (gateType == SelectedGateType.delete) {
        simulationResult = "Tap on a gate to delete it."; // Updated message
      }
    });
    print('Selected gate type for placement: $_currentMode');
  }

  // ** Add a GlobalKey for the GestureDetector **
  final GlobalKey _gestureDetectorKey = GlobalKey();
  // *****************************************


  void _handleCircuitTap(TapDownDetails details) {
    print('Tap detected.');
    // final localPosition = _gatePositionToLocal(details.globalPosition);
    final localPosition = details.localPosition;

    if (localPosition == null) {
      print('Error: Could not convert global position to local.');
      return;
    }
    print('Local tap position: $localPosition');

    // Create a temporary painter instance for hit testing
    final painter = QuantumCircuitPainter(_circuit, _circuitWidthNotifier, _draggingOffset, _draggingGateType);


    if (_currentMode == SelectedGateType.delete) {
      print('In delete mode.');
      // Use the painter's hit-testing method to find if a gate was tapped
      bool gateRemoved = painter.removeGateAtTap(localPosition);

      if (gateRemoved) {
        _runSimulation(); // Update simulation after deletion
        setState(() {
          _currentMode = SelectedGateType.none; // Reset mode after successful deletion
          simulationResult = "Gate deleted. Drag a gate onto the circuit."; // Reset message
        });

      } else {
        print('Tapped outside gates in delete mode.');
        // Optional: Provide feedback or reset mode if user taps outside gates
        // setState(() { simulationResult = "No gate tapped. Exiting delete mode."; }); // Example feedback
        // _setInteractionMode(SelectedGateType.none); // Example: Exit delete mode on tap outside
      }
      return; // Exit _handleCircuitTap if in delete mode
    }

    // If not in delete mode, taps on the circuit might be ignored or used for other interactions later
    print('Tapped on circuit in non-delete mode. Ignoring for now.');
  }

  void _runSimulation() {
    print("Running simulation...");

    // ** Call the void simulation method on the circuit **
    // This method executes the simulation and updates circuit.currentState internally.
    print(_circuit);
    _circuit.runSimulation();

    // ** Access the updated circuit.currentState property to get the final state **
    // Now that runSimulation is complete, circuit.currentState holds the result.

    // ** Calculate measurement probabilities from the final state **
    // measurementProbabilities = finalState.state.map((amplitude) {
    //   return amplitude.abs() * amplitude.abs();
    // }).cast<double>().toList();
    //
    // print("Calculated probabilities: $measurementProbabilities");

    // ** Update the UI state variables to trigger a rebuild **
    setState(() {
      // Format the final state vector for display
      // Access the state data via the finalState object obtained from circuit.currentState
      simulationResult = "Final State Vector:\n${_circuit.initialState}"; // Assuming formatStateVector helper
      _checkLevelCompletion();
    });
    print("Simulation finished.");
  }

  Future<void> _checkLevelCompletion() async {
    // Only check if not already completed to avoid re-triggering
    // expect(circuit.currentState.state.rawMatrix, Matrix(level.solutionFinalVector));
    bool match = _circuit.currentState.state.almostEqualTo(QuantumMatrix(_solutionVector));
    if (match) {
      final action = await _showLevelCompleteDialog(); // Trigger success actions

      // Now, based on the user's choice in the dialog, pop the QuantumComposerScreen itself.
      // This will complete the 'await Navigator.push' call back in HomePage.
      if (action == LevelCompletionAction.nextLevel || action == LevelCompletionAction.levelSelect) {
        // If user chose to go to next level or level select, pop this composer screen
        // and pass the action back to HomePage.
        Navigator.of(context).pop(action);
      } else if (action == LevelCompletionAction.reviewSolution) {
        // If user chose to review, pop the composer screen and return to HomePage.
        // HomePage will then simply be visible again.
        Navigator.of(context).pop(action);
      } else {
        // Default case: dialog might have been dismissed without a specific action
        // (e.g., tapping outside if barrierDismissible was true, or system back button on dialog).
        // In this case, also pop the composer screen, returning 'none'.
        Navigator.of(context).pop(LevelCompletionAction.none);
      }
    }
  }

  Future<LevelCompletionAction?> _showLevelCompleteDialog() {
    return showDialog<LevelCompletionAction>(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text('Level Complete!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Congratulations! You\'ve successfully solved the puzzle.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton.icon(
              onPressed: () {
                print('Going to the next level.');
                Navigator.of(context).pop(LevelCompletionAction.nextLevel); // Close dialog
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Level'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10), // Space between buttons
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(LevelCompletionAction.levelSelect); // Close dialog
              },
              icon: const Icon(Icons.list),
              label: const Text('Level Select'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueGrey,
                side: const BorderSide(color: Colors.blueGrey),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTask() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuantumTaskDialog(taskDescription: _taskDescription);
      },
    );
  }

  void _clearCircuit() {
    _circuit.clearPlacedGates(); // This calls notifyListeners()
    print('Circuit cleared.');
    _setInteractionMode(SelectedGateType.none); // Reset mode
    _cnotTargetQubit = null;
    _runSimulation(); // Run simulation - empty circuit
    _circuitWidthNotifier.value = 0; // Reset width notifier
  }

  void _showGateListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const QuantumDocDialog();
      },
    );
  }

  // Helper to format the overall matrix for display
  String formatMatrix(List<List<Complex>> matrix) {
    String formatted = "";
    for (int i = 0; i < 4; i++) {
      formatted += "[";
      for (int j = 0; j < 4; j++) {
        // Format complex number (e.g., "1.00+0.00i" or "0.71-0.71i")
        String real = matrix[i][j].real.toStringAsFixed(2);
        String imag = matrix[i][j].imaginary.toStringAsFixed(2);
        String complexStr;
        if (matrix[i][j].imaginary == 0) {
          complexStr = real;
        } else if (matrix[i][j].real == 0) {
          complexStr = "${imag}i";
        } else if (matrix[i][j].imaginary > 0) {
          complexStr = "$real+$imag" + "i";
        } else {
          complexStr = "$real$imag" + "i"; // Imaginary part already has '-'
        }

        formatted += complexStr;
        if (j < 3) {
          formatted += ", ";
        }
      }
      formatted += "]\n"; // New line for each row
    }
    return formatted;
  }

  void _onDragEnter(Offset offset, SelectedGateType gateType) {
    setState(() {
      final localPosition = _gatePositionToLocal(offset);

      if (localPosition == null) {
        print('Error: Could not convert global position to local.');
        return;
      }

      _draggingOffset = localPosition;
      _draggingGateType = gateType;
    });
  }

  void _onDragLeave() {
    setState(() {
      _draggingOffset = null;
      _draggingGateType = SelectedGateType.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF1E1E2C),
      // Modify the AppBar
      appBar: AppBar(
        title: Text("⟨𝜑|𝜑⟩ Level ${widget.levelId}",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),),
        // ** Add the actions list here **
        actions: [
          // Run Simulation Button (as TextButton)
          TextButton.icon(
            onPressed: _showTask,
            icon: Icon(Icons.task),
            label: Text('Task'), // Shorten text for AppBar
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, // White text color
            ),
          ),
          TextButton.icon(
            onPressed: _showGateListDialog,
            icon: Icon(Icons.book),
            label: Text('Doc'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, // White icon/text color for contrast on AppBar
              // You might adjust padding if needed to fit
              // padding: EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
          TextButton.icon(
            onPressed: _clearCircuit,
            icon: Icon(Icons.cleaning_services),
            label: Text('Clear'), // Shorten text for AppBar
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, // White text color
            ),
          ),
        ],
        // ****************************
      ),
      body: SafeArea(child: Column( // Main Column stacking the top section and controls
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded( // This Expanded makes the Row take available vertical space
            child: Row( // <-- Main Row for Circuit and Histogram side-by-side
              children: [
                // Circuit Visualization (Left - 70% width)
                Expanded(
                  flex: 7, // Allocate 70% width
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Expanded(child: Container( // Container for padding
                    // color: Colors.grey[900],
                    decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: Color(0xFF1E1E2C),
                        border: Border.all(color: Color(0xFF4D4D5C), width: 1),
                        borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: EdgeInsets.all(2.0),
                    child: LayoutBuilder( // LayoutBuilder gets bounded constraints from Container/Expanded
                        builder: (context, constraints) {
                          print("  LayoutBuilder constraints: $constraints"); // Debug constraints
                          final double availableContainerWidth = constraints.maxWidth;
                          final double availableContainerHeight = constraints.maxHeight;
                          print("  Available container size: Size($availableContainerWidth, $availableContainerHeight)"); // Debug available size


                          // Calculate the minimum width needed based on the maximum position of placed gates
                          final int maxPosition = _circuit.isCircuitEmpty() ? -1 : _circuit.placedGates.map((e) => e.length).reduce(max);
                          // Add 2 for the next column and some extra space
                          final double minRequiredWidth = (maxPosition + 3) * QuantumCircuitPainter.gateSpacing + QuantumCircuitPainter.padding * 2;


                          final double sizedBoxWidth = max(minRequiredWidth, availableContainerWidth);
                          // The height of the SizedBox should be fixed based on the number of qubits and spacing
                          final double sizedBoxHeight = _numQubits * QuantumCircuitPainter.qubitSpacing + QuantumCircuitPainter.padding * 2;
                          print("  Calculated SizedBox size: Size($sizedBoxWidth, $sizedBoxHeight)"); // Debug SizedBox size

                          return DragTarget<SelectedGateType>( // DragTarget wraps the scrollable area
                            // onWillAccept: (data) => data != null && data != SelectedGateType.delete, // Accept any gate type except delete
                            onAcceptWithDetails: (details) {
                              _handleGateDrop(details);
                              _onDragLeave();
                              }, // Handle the drop event
                            onLeave: (data) {
                              _onDragLeave();
                              },
                            onMove: (data) {
                              _onDragEnter(data.offset, data.data);
                            },
                            onWillAcceptWithDetails: (details) {
                              SelectedGateType data = details.data;
                              _onDragEnter(details.offset, details.data);
                              bool isNotDelete = data != null && data != SelectedGateType.delete;
                              return isNotDelete;
                            },
                            builder: (context, candidateData, rejectedData) {
                              // We can use the presence of candidateData to provide visual feedback
                              bool isDraggingOver = candidateData.isNotEmpty;

                              return GestureDetector( // GestureDetector wraps the scrollable area
                                key: _gestureDetectorKey,
                                onTapDown: _handleCircuitTap, // Tap handler for deletion
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  // ** Wrap CustomPaint in ConstrainedBox to force size **
                                  child: CustomPaint(
                                    painter: QuantumCircuitPainter(_circuit, _circuitWidthNotifier, _draggingOffset, _draggingGateType), // Pass the circuit
                                    child: ListenableBuilder(
                                      listenable: _circuit, // Listen to the circuit object
                                      builder: (context, child) {
                                        print("ListenableBuilder rebuilding CustomPaint."); // Debug rebuild
                                        return Container(
                                            width: max(sizedBoxWidth, _circuitWidthNotifier.value),
                                            // color: isDraggingOver ? Colors.white.withOpacity(0.1) : Colors.transparent, // Subtle overlay when dragging over
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                    ),
                  )),

            // Add Gates Buttons (This section remains)
            Padding(
              padding: const EdgeInsets.only(top:8.0, bottom:8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Add/Remove Gates:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  // SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectGateForPlacement(SelectedGateType.delete),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize), // Use gate size for button size
                            padding: EdgeInsets.zero, // Remove internal padding
                            backgroundColor: Colors.green[700], // Red color for delete
                            foregroundColor: Colors.white, // White text/icon color
                            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(0.0),), // Square shape
                          ),
                          child: FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Icon(Icons.delete, size: 18)),
                          // child: Text('DEL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), // Button text
                        ),

                        SizedBox(width: 4), // Space after Delete button
                        // ** Add the Vertical Divider **
                        Container( // Wrap divider in Container to give it a height matching buttons
                          height: QuantumCircuitPainter.gateSize * 0.75, // Match button height
                          child: VerticalDivider(
                            width: 1,
                            thickness: 2,
                            indent: 0, // Adjust indent/endIndent if buttons have different padding
                            endIndent: 0,
                            color: Colors.white, // White divider for visibility on black background
                          ),
                        ),
                        SizedBox(width: 4), // Space after divider
                        // --- Dynamic Draggable Gate Buttons ---
                        ..._availableGates.map((gateType) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add spacing between dynamic buttons
                            child: _buildDraggableGateButton(gateType),
                          );
                        }), // Convert the iterable to a List<Widget>
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ]),

                ),

                // Histogram Visualization (Right - 30% width)
                Expanded(
                  flex: 3,
                  child:
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(children: [
                        Text(
                            simulationResult,
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        Divider(),
                        SizedBox(height: 10.0),
                        Container(
                          padding: EdgeInsets.all(8.0),
                          // The histogram content itself is scrollable inside _buildProbabilityHistogram if needed
                          child: SingleChildScrollView( // Scroll the whole histogram section if needed
                            scrollDirection: Axis.vertical,
                            child: AspectRatio(
                              aspectRatio: 1.8,
                              child: Text('placeholder'),
                            ), // Your histogram helper
                          ),
                        ),
                        // State Vector Display (Below buttons)
                      ]),
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildDraggableGateButton(SelectedGateType type) {
    double fontSizeW = type == SelectedGateType.cnot ? 10 : 18;
    return Draggable<SelectedGateType>( // Draggable for Hadamard
      data: type, // Data carried by the drag
      feedback: Container( // Visual feedback while dragging
        width: QuantumCircuitPainter.gateSize,
        height: QuantumCircuitPainter.gateSize,
        color: type.color.withOpacity(0.7), // Semi-transparent feedback
        child: Center(child: Text(type.label, style: TextStyle(color: Colors.white, fontSize: fontSizeW, fontWeight: FontWeight.bold))),
      ),
      child: ElevatedButton( // The original button appearance
        onPressed: () => _setInteractionMode(SelectedGateType.none), // Tapping button resets mode
        style: ElevatedButton.styleFrom(
          minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize),
          padding: EdgeInsets.zero,
          backgroundColor: type.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(0.0),),
        ),
        child: Text(type.label, style: TextStyle(fontSize: fontSizeW, fontWeight: FontWeight.bold),),
      ),
    );
  }
}