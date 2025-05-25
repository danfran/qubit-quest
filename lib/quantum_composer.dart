import 'dart:math';

import 'package:complex/complex.dart';
import 'package:quantumquiz/placed_quantum_gate.dart';
import 'package:quantumquiz/probability_histogram.dart';
import 'package:quantumquiz/quantum_circuit.dart';
import 'package:quantumquiz/quantum_circuit_painter.dart';
import 'package:quantumquiz/quantum_doc_dialog.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/qubit_state.dart';
import 'package:quantumquiz/selected_gate_type.dart';

import 'math_utils.dart';

class QuantumComposer extends StatefulWidget {
  @override
  _QuantumComposerState createState() => _QuantumComposerState();
}

class _QuantumComposerState extends State<QuantumComposer> {
  static final int numberQubits = 2;
  final QuantumCircuit circuit = QuantumCircuit(numQubits: numberQubits);
  String simulationResult = "Run the circuit to see the result";
  List<List<Complex>> overallCircuitMatrix = identityMatrix(numberQubits);
  List<double> measurementProbabilities = [0.0, 0.0, 0.0, 0.0];
  SelectedGateType _currentMode = SelectedGateType.none;
  int? _cnotControlQubit; // To track the first tap for CNOT

  // State to manage the highlight box for drag-and-drop
  Offset? _draggingOffset;

  final ValueNotifier<double> _circuitWidthNotifier = ValueNotifier<double>(0.0);

// You'll likely need a helper to format the QubitState for display
  String formatStateVector(QubitState state) {
    // Implement formatting based on your QubitState structure
    // Example: [a+bi, c+di, ...]
    String formatted = "[";
    for (int i = 0; i < state.state.length; i++) {
      String real = state.state[i].real.toStringAsFixed(2);
      String imag = state.state[i].imaginary.toStringAsFixed(2);
      String complexStr;
      if (state.state[i].imaginary == 0) {
        complexStr = real;
      } else if (state.state[i].real == 0) {
        complexStr = "${imag}i";
      } else if (state.state[i].imaginary > 0) {
        complexStr = "$real+$imag" + "i";
      } else {
        complexStr = "$real$imag" + "i"; // Imaginary part already has '-'
      }
      formatted += complexStr;
      if (i < state.state.length - 1) {
        formatted += ", ";
      }
    }
    formatted += "]";
    return formatted;
  }

  void _setInteractionMode(SelectedGateType mode) {
    setState(() {
      _currentMode = mode;
      _cnotControlQubit = null; // Reset CNOT control on mode change
      if (mode == SelectedGateType.delete) {
        simulationResult = "Tap on a gate to delete it.";
      } else {
        simulationResult = "Drag a gate onto the circuit."; // Default message for drag mode
      }
    });
    print('Interaction mode set to: $_currentMode');
  }

  // New method to handle a gate being dropped onto the circuit area
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

    // New method to handle a gate being dropped onto the circuit area
  void _handleGateDrop(DragTargetDetails<SelectedGateType> details) {
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
    final painter = QuantumCircuitPainter(circuit, _circuitWidthNotifier, _draggingOffset); // Painter knows layout constants

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

    // Create the PlacedQuantumGate based on the dropped type and calculated position
    PlacedQuantumGate? placedGate;

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
      final int controlQubit = tappedQubitLine;
      int? targetQubit;
      if (controlQubit == 0 && circuit.numQubits > 1) {
        targetQubit = 1;
      } else if (controlQubit == 1 && circuit.numQubits > 0) {
        targetQubit = 0;
      } else {
        print('Cannot place CNOT on single qubit or invalid target.');
        // Optionally provide feedback
        return;
      }

      if (targetQubit != null && controlQubit != targetQubit) {
        placedGate = PlacedQuantumGate(
          type: SelectedGateType.cnot,
          position: insertionPosition,
          controlQubitIndex: controlQubit,
          targetQubitIndex: targetQubit,
        );
      } else {
        print('Invalid CNOT placement (control == target or not enough qubits).');
        // Optionally provide feedback
        return;
      }
    } else {
      placedGate = PlacedQuantumGate(
        type: droppedGateType,
        position: insertionPosition,
        singleQubitIndex: tappedQubitLine,
      );
    }

    if (placedGate != null) {
      // ** Add the PlacedQuantumGate to the circuit at the specific position **
      // The QuantumCircuit class needs a method like insertPlacedGateAt
      circuit.insertPlacedGateAt(placedGate, insertionPosition, tappedQubitLine); // <-- Need to implement this in QuantumCircuit

      print('Gate successfully placed.');
      // No need for setState here, circuit.insertPlacedGateAt should call notifyListeners()
      // _runSimulation(); // Optionally run simulation after placing
    }
  }

  void _selectGateForPlacement(SelectedGateType gateType) {
    setState(() {
      _currentMode = gateType;
      _cnotControlQubit = null; // Reset CNOT control on new gate selection
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
    final painter = QuantumCircuitPainter(circuit, _circuitWidthNotifier, _draggingOffset);


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
    circuit.runSimulation();

    // ** Access the updated circuit.currentState property to get the final state **
    // Now that runSimulation is complete, circuit.currentState holds the result.
    final QubitState finalState = circuit.currentState;

    // ** Calculate measurement probabilities from the final state **
    measurementProbabilities = finalState.state.map((amplitude) {
      return amplitude.abs() * amplitude.abs();
    }).toList();

    print("Calculated probabilities: $measurementProbabilities");

    // ** Update the UI state variables to trigger a rebuild **
    setState(() {
      // Format the final state vector for display
      // Access the state data via the finalState object obtained from circuit.currentState
      simulationResult = "Final State Vector:\n${formatStateVector(finalState)}"; // Assuming formatStateVector helper
    });
    print("Simulation finished.");
  }


  void _clearCircuit() {
    circuit.clearPlacedGates(); // This calls notifyListeners()
    print('Circuit cleared.');
    _setInteractionMode(SelectedGateType.none); // Reset mode
    _cnotControlQubit = null;
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

  void _onDragEnter(Offset offset) {
    setState(() {
      final localPosition = _gatePositionToLocal(offset);

      if (localPosition == null) {
        print('Error: Could not convert global position to local.');
        return;
      }

      _draggingOffset = localPosition;
    });
  }

  void _onDragLeave() {
    setState(() {
      _draggingOffset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
      // Modify the AppBar
      appBar: AppBar(
        title: Text("<Q|Q> Level 05",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),),
        // ** Add the actions list here **
        actions: [
          // Info Button (as TextButton.icon)
          TextButton.icon(
            onPressed: _showGateListDialog,
            icon: Icon(Icons.info_outline),
            label: Text('Info'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, // White icon/text color for contrast on AppBar
              // You might adjust padding if needed to fit
              // padding: EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
          // Run Simulation Button (as TextButton)
          TextButton.icon(
            onPressed: _runSimulation,
            icon: Icon(Icons.play_arrow),
            label: Text('Run'), // Shorten text for AppBar
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, // White text color
            ),
          ),
          // Clear Circuit Button (as TextButton)
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
                  child: Container( // Container for padding
                    // color: Colors.grey[900],
                    decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: Colors.grey[900],
                        border: Border.all(color: Colors.yellowAccent, width: 4),
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
                          final int maxPosition = circuit.isEmpty() ? -1 : circuit.placedGates.expand((e) => e).map((e) => e.position).reduce(max);
                          // Add 2 for the next column and some extra space
                          final double minRequiredWidth = (maxPosition + 3) * QuantumCircuitPainter.gateSpacing + QuantumCircuitPainter.padding * 2;


                          final double sizedBoxWidth = max(minRequiredWidth, availableContainerWidth);
                          // The height of the SizedBox should be fixed based on the number of qubits and spacing
                          final double sizedBoxHeight = circuit.numQubits * QuantumCircuitPainter.qubitSpacing + QuantumCircuitPainter.padding * 2;
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
                              _onDragEnter(data.offset);
                            },
                            onWillAcceptWithDetails: (details) {
                              SelectedGateType data = details.data;
                              _onDragEnter(details.offset);
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
                                    painter: QuantumCircuitPainter(circuit, _circuitWidthNotifier, _draggingOffset), // Pass the circuit
                                    child: ListenableBuilder(
                                      listenable: circuit, // Listen to the circuit object
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
                  ),
                ),

                // Add VerticalDivider here
                // VerticalDivider(
                //   width: 1,
                //   thickness: 1,
                //   indent: 0,
                //   endIndent: 0,
                //   color: Colors.grey,
                // ),

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
                              child: ProbabilityHistogram(probabilities: measurementProbabilities),
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

          // Controls Section (Below the Row)

          // Add Gates Buttons (This section remains)
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                          foregroundColor: Colors.black, // White text/icon color
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
                      Draggable<SelectedGateType>( // Draggable for Hadamard
                        data: SelectedGateType.hadamard, // Data carried by the drag
                        feedback: Container( // Visual feedback while dragging
                          width: QuantumCircuitPainter.gateSize,
                          height: QuantumCircuitPainter.gateSize,
                          color: SelectedGateType.hadamard.color.withOpacity(0.7), // Semi-transparent feedback
                          child: Center(child: Text(SelectedGateType.hadamard.label, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                        ),
                        // childWhenDragging: Container( // What to show in the original position while dragging
                        //   width: QuantumCircuitPainter.gateSize,
                        //   height: QuantumCircuitPainter.gateSize,
                        //   color: Colors.grey.withOpacity(0.5), // Placeholder appearance
                        // ),
                        child: ElevatedButton( // The original button appearance
                          onPressed: () => _setInteractionMode(SelectedGateType.none), // Tapping button resets mode
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize),
                            padding: EdgeInsets.zero,
                            backgroundColor: SelectedGateType.hadamard.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(0.0),),
                          ),
                          child: Text(SelectedGateType.hadamard.label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                        ),
                      ),
                      // SizedBox(width: 4),
                      Draggable<SelectedGateType>( // Draggable for CNOT
                        data: SelectedGateType.cnot, // Data carried by the drag
                        feedback: Container( // Visual feedback while dragging
                          width: QuantumCircuitPainter.gateSize * 2, // CNOT feedback might be wider
                          height: QuantumCircuitPainter.gateSize * 2, // CNOT feedback might be taller
                          color: SelectedGateType.cnot.color.withOpacity(0.7), // Semi-transparent feedback
                          child: Center(child: Text(SelectedGateType.cnot.label, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                        ),
                        // childWhenDragging: Container( // What to show in the original position while dragging
                        //   width: QuantumCircuitPainter.gateSize,
                        //   height: QuantumCircuitPainter.gateSize,
                        //   color: Colors.grey.withOpacity(0.5), // Placeholder appearance
                        // ),
                        child: ElevatedButton( // The original button appearance
                          onPressed: () => _setInteractionMode(SelectedGateType.none), // Tapping button resets mode
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize),
                            padding: EdgeInsets.zero,
                            backgroundColor: SelectedGateType.cnot.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(0.0),),
                          ),
                          child: Text(SelectedGateType.cnot.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),),
                        ),
                      ),

                      Draggable<SelectedGateType>( // Draggable for x
                        data: SelectedGateType.x, // Data carried by the drag
                        feedback: Container( // Visual feedback while dragging
                          width: QuantumCircuitPainter.gateSize,
                          height: QuantumCircuitPainter.gateSize,
                          color: SelectedGateType.x.color.withOpacity(0.7), // Semi-transparent feedback
                          child: Center(child: Text(SelectedGateType.x.label, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                        ),
                        // childWhenDragging: Container( // What to show in the original position while dragging
                        //   width: QuantumCircuitPainter.gateSize,
                        //   height: QuantumCircuitPainter.gateSize,
                        //   color: Colors.grey.withOpacity(0.5), // Placeholder appearance
                        // ),
                        child: ElevatedButton( // The original button appearance
                          onPressed: () => _setInteractionMode(SelectedGateType.none), // Tapping button resets mode
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize),
                            padding: EdgeInsets.zero,
                            backgroundColor: SelectedGateType.x.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(0.0),),
                          ),
                          child: Text(SelectedGateType.x.label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                        ),
                      ),

                      Draggable<SelectedGateType>( // Draggable for y
                        data: SelectedGateType.y, // Data carried by the drag
                        feedback: Container( // Visual feedback while dragging
                          width: QuantumCircuitPainter.gateSize,
                          height: QuantumCircuitPainter.gateSize,
                          color: SelectedGateType.y.color.withOpacity(0.7), // Semi-transparent feedback
                          child: Center(child: Text(SelectedGateType.y.label, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                        ),
                        // childWhenDragging: Container( // What to show in the original position while dragging
                        //   width: QuantumCircuitPainter.gateSize,
                        //   height: QuantumCircuitPainter.gateSize,
                        //   color: Colors.grey.withOpacity(0.5), // Placeholder appearance
                        // ),
                        child: ElevatedButton( // The original button appearance
                          onPressed: () => _setInteractionMode(SelectedGateType.none), // Tapping button resets mode
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize),
                            padding: EdgeInsets.zero,
                            backgroundColor: SelectedGateType.y.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(0.0),),
                          ),
                          child: Text(SelectedGateType.y.label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                        ),
                      ),

                      Draggable<SelectedGateType>( // Draggable for z
                        data: SelectedGateType.z, // Data carried by the drag
                        feedback: Container( // Visual feedback while dragging
                          width: QuantumCircuitPainter.gateSize,
                          height: QuantumCircuitPainter.gateSize,
                          color: SelectedGateType.z.color.withOpacity(0.7), // Semi-transparent feedback
                          child: Center(child: Text(SelectedGateType.z.label, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                        ),
                        // childWhenDragging: Container( // What to show in the original position while dragging
                        //   width: QuantumCircuitPainter.gateSize,
                        //   height: QuantumCircuitPainter.gateSize,
                        //   color: Colors.grey.withOpacity(0.5), // Placeholder appearance
                        // ),
                        child: ElevatedButton( // The original button appearance
                          onPressed: () => _setInteractionMode(SelectedGateType.none), // Tapping button resets mode
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize),
                            padding: EdgeInsets.zero,
                            backgroundColor: SelectedGateType.z.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(0.0),),
                          ),
                          child: Text(SelectedGateType.z.label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                        ),
                      ),
                      // Info button was moved to AppBar
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}