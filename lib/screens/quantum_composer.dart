import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/screens/operator_matrix_dialog.dart';
import 'package:quantumquiz/screens/rotation_gate_dialog.dart';
import 'package:quantumquiz/screens/three_qubits_gate_target_qubits_selection_dialog.dart';
import 'package:quantumquiz/screens/two_qubits_gate_target_qubit_selection_dialog.dart';
import 'package:quantumquiz/screens/webview_page.dart';
import 'package:quantumquiz/utils/complex_formatter.dart';
import 'package:quantumquiz/utils/qq_fraction.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';
import 'package:quantumquiz/models/level_completion_action.dart';

import '../models/qq_level.dart';

class QuantumComposer extends StatefulWidget {
  final int levelId;
  final ComposerLevel level;
  final Function(int unlockedLevel)? onLevelUnlocked;

  const QuantumComposer({
    super.key,
    required this.levelId,
    required this.level,
    required this.onLevelUnlocked,
  });

  @override
  _QuantumComposerState createState() => _QuantumComposerState();
}

class _QuantumComposerState extends State<QuantumComposer> {
  late int _numQubits;
  late String _taskDescription;
  late List<Complex> _initialState;
  late List<Gate> _availableGates;
  late List<List<Complex>> _solutionVector;
  late QuantumCircuit _circuit;

  SelectedGateType _currentMode = SelectedGateType.none;
  int? _cnotControlQubit;

  int? _ccnotControl1Qubit;
  int? _ccnotControl2Qubit;

  double? _rotationAngle;

  // Hints state
  List<String> _hints = [];
  int _currentHintIndex = -1;

  // State to manage the highlight box for drag-and-drop
  Offset? _draggingOffset;
  Gate _draggingGate = Gate.fromIdentifier(SelectedGateType.none);

  String _currentInstructionMessage = "Drag a gate onto the circuit.";

  final ValueNotifier<double> _circuitWidthNotifier = ValueNotifier<double>(0.0);

  late ScrollController _taskTextScrollController;
  late ScrollController _gatesScrollController;

  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _taskTextScrollController = ScrollController(); // Initialize the controller
    _gatesScrollController = ScrollController()
      ..addListener(_updateScrollButtonStates);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollButtonStates();
      if (widget.level.conceptIntro != null && !runningAsQuantumComposer()) {
        _showConceptIntro(widget.level.conceptIntro!);
      }
    });

    _hints = widget.level.hints ?? [];
    _currentHintIndex = -1;

    _numQubits = widget.level.numQubits;
    _taskDescription = widget.level.taskDescription;
    _initialState = widget.level.initialQubitsState;
    _availableGates = widget.level.availableGates;
    _solutionVector = widget.level.solutionFinalVector;
    _circuit = QuantumCircuit(currentLevel: widget.level);

    debugPrint('Task: $_taskDescription');
    debugPrint('Number of qubits: $_numQubits');
    debugPrint('Initial state: $_initialState');
    debugPrint('Available gates: $_availableGates');
    debugPrint('Solution vector: $_solutionVector');
  }

  @override
  void dispose() {
    _taskTextScrollController.dispose(); // Dispose the controller
    _gatesScrollController.removeListener(_updateScrollButtonStates);
    _gatesScrollController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _setInteractionMode(SelectedGateType mode) {
    setState(() {
      _currentMode = mode;
      _cnotControlQubit = null; // Reset CNOT control on mode change
      _ccnotControl1Qubit = null;
      _ccnotControl2Qubit = null;
      if (mode == SelectedGateType.delete) {
        _currentInstructionMessage = "Tap on a gate to delete it.";
      } else {
        _currentInstructionMessage = "Drag a gate onto the circuit."; // Default message for drag mode
      }

    });
    debugPrint('Interaction mode set to: $_currentMode');
  }

  // Method to handle a gate being dropped onto the circuit area
  Offset? _gatePositionToLocal(Offset offset) {
    final RenderBox? renderBox = _gestureDetectorKey.currentContext
        ?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint('Error: Could not find RenderBox for GestureDetector.');
      return null;
    }
    final localPosition = renderBox.globalToLocal(offset);
    return localPosition;
  }

  // Method to handle a gate being dropped onto the circuit area
  Future<void> _handleGateDrop(DragTargetDetails<Gate> details) async {
    // Corrected: Use details.offset for the local drop position
    debugPrint('Gate dropped at local position: ${details.offset}'); // localPosition relative to the DragTarget
    debugPrint('Dropped gate type: ${details.data}'); // The data from the Draggable

    final localPosition = _gatePositionToLocal(details.offset);

    if (localPosition == null) {
      debugPrint('Error: Could not convert global position to local.');
      return;
    }

    final droppedGate = details.data;
    final droppedGateType = details.data.type;
    // final dropPosition = details.offset; // Use details.offset
    final dropPosition = localPosition; // Use details.offset

    // Use the painter's logic to determine the qubit line and insertion position
    final painter = QuantumCircuitPainter(_circuit, _circuitWidthNotifier, _draggingOffset, _draggingGate); // Painter knows layout constants

    // Determine the tapped qubit line based on the vertical drop position
    final tappedQubitLine = painter.getTappedQubitLine(dropPosition);

    if (tappedQubitLine == null) {
      debugPrint('Dropped outside qubit lines. Ignoring drop.');
      // Optionally provide feedback to the user
      return;
    }

    // Determine the horizontal insertion position based on the horizontal drop position
    final insertionPosition = painter.getInsertionPosition(dropPosition); // <-- Need to implement this in Painter

    if (insertionPosition == null) {
      debugPrint('Could not determine valid insertion position. Ignoring drop.');
      // Optionally provide feedback
      return;
    }

    debugPrint('Dropped on Qubit line: $tappedQubitLine at insertion position: $insertionPosition');

    if (droppedGateType == SelectedGateType.cnot || droppedGateType == SelectedGateType.cz) {
      // For CNOT/CZ drag and drop, we need to select control/target after dropping.
      // This is a more complex interaction. For simplicity in this initial drag/drop,
      // let's assume CNOT/CZ drag requires dropping the control part, and then
      // a subsequent tap selects the target. Or, the drop position implies control,
      // and the nearest other qubit line is the target? This needs careful UI design.

      // A simpler approach for initial drag/drop: CNOT/CZ drag places a CNOT/CZ
      // with control on the dropped line and target on the next line (if available).
      // This might not be ideal but simplifies the initial implementation.
      // A better approach might involve a special CNOT/CZ drag feedback that shows
      // both control and target and lets the user position both before dropping.

      // Let's go with the simpler approach for now: Drop implies control qubit.
      // Target is the next available qubit line, if different from control.
      int? controlQubitLine;
      Gate droppedGate = Gate.fromIdentifier(droppedGateType);
      String gateLabel = droppedGate.label;

      if (_numQubits == 1) {
        debugPrint('Cannot place $gateLabel on single qubit or invalid target.');
          // Optionally provide feedback
        return;
      } else if (_numQubits == 2) {
        if (tappedQubitLine == 0) {
          controlQubitLine = 1;
        } else if (tappedQubitLine == 1) {
          controlQubitLine = 0;
        }
      } else if (_numQubits > 2){
        await _showCNOTTargetSelectionDialog(context, tappedQubitLine, _numQubits);
        if (_cnotControlQubit != null) {
          controlQubitLine = _cnotControlQubit;
        }
      }

      if (controlQubitLine != null && tappedQubitLine != controlQubitLine) {
        debugPrint('$gateLabel placement (control line = $_cnotControlQubit and target line = $tappedQubitLine).');
        _circuit.insertDoublePlacedGateAt(droppedGate, insertionPosition, tappedQubitLine, controlQubitLine);
        debugPrint("Gate $gateLabel inserted at position $insertionPosition on qubits $tappedQubitLine and $controlQubitLine.");
      } else {
        debugPrint('Invalid $gateLabel placement (control == target or not enough qubits).');
        // Optionally provide feedback
        return;
      }
    } else if (droppedGateType == SelectedGateType.ccnot) {

      if (_numQubits < 3) {
        debugPrint('Cannot place CCNOT on less than 3 qubits circuit or invalid target.');
        // Optionally provide feedback
        return;
      } else if (_numQubits >= 3) {
        await _showCCNOTTargetSelectionDialog(context, tappedQubitLine, _numQubits);
      }

      if (_ccnotControl1Qubit != null && _ccnotControl2Qubit != null && tappedQubitLine != _ccnotControl1Qubit && tappedQubitLine != _ccnotControl2Qubit) {
        debugPrint('CCNOT placement (control line 1 = $_ccnotControl1Qubit, control line 2 = $_ccnotControl2Qubit and target line = $tappedQubitLine).');
        _circuit.insertTriplePlacedGateAt(droppedGate, insertionPosition, tappedQubitLine, _ccnotControl1Qubit!, _ccnotControl2Qubit!);
        debugPrint("Gate CCNOT inserted at position $insertionPosition on qubits $tappedQubitLine, $_ccnotControl1Qubit and $_ccnotControl2Qubit.");
      } else {
        debugPrint('Invalid CCNOT placement (control == target or not enough qubits).');
        // Optionally provide feedback
        return;
      }
    } else if ((droppedGateType == SelectedGateType.rx || droppedGateType == SelectedGateType.ry || droppedGateType == SelectedGateType.rz) && widget.levelId == -1) {
      // if in the composer screen >> widget.levelId == -1
      await _showRotationAngleSetDialog(context);
      if (_rotationAngle != null) {
        Gate updatedRotationGate = Gate.fromIdentifier(droppedGateType, angle: _rotationAngle!);
        _circuit.insertSinglePlacedGateAt(updatedRotationGate, insertionPosition, tappedQubitLine);
      }
      debugPrint("Gate inserted at position $insertionPosition on qubit $tappedQubitLine.");
    } else if (droppedGateType != SelectedGateType.draggedGate) {
      _circuit.insertSinglePlacedGateAt(droppedGate, insertionPosition, tappedQubitLine);
      debugPrint("Gate inserted at position $insertionPosition on qubit $tappedQubitLine.");
    }

    _runSimulation(); // Optionally run simulation after placing
  }

  Future<void> _showCNOTTargetSelectionDialog(BuildContext context, int targetQubit, int numQubits) async {
    // Ensure dialog is not already shown
    if (ModalRoute.of(context)?.isCurrent != true || Navigator.of(context).canPop() == false) {
      // This is a crude check to avoid showing multiple dialogs.
      // A more robust solution might involve a global boolean or state for dialog visibility.
      return;
    }

    final Map<String, dynamic>? selectedQubit = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return TwoQubitsGateTargetQubitSelectionDialog(
          targetQubitIndex: targetQubit,
          numQubits: numQubits,
        );
      },
    );

    _cnotControlQubit = selectedQubit?['control1'];
  }

  Future<void> _showRotationAngleSetDialog(BuildContext context) async {
    // Ensure dialog is not already shown
    if (ModalRoute.of(context)?.isCurrent != true || Navigator.of(context).canPop() == false) {
      // This is a crude check to avoid showing multiple dialogs.
      // A more robust solution might involve a global boolean or state for dialog visibility.
      return;
    }

    final Map<String, dynamic>? selectedAngle = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return RotationGateDialog();
      },
    );

    _rotationAngle = selectedAngle?['angle1'];
  }

  Future<void> _showCCNOTTargetSelectionDialog(BuildContext context, int targetQubit, int numQubits) async {
    // Ensure dialog is not already shown
    if (ModalRoute.of(context)?.isCurrent != true || Navigator.of(context).canPop() == false) {
      // This is a crude check to avoid showing multiple dialogs.
      // A more robust solution might involve a global boolean or state for dialog visibility.
      return;
    }

    final Map<String, dynamic>? selectedQubits = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return ThreeQubitsGateTargetQubitsSelectionDialog(
          targetQubitIndex: targetQubit,
          numQubits: numQubits,
        );
      },
    );

    _ccnotControl1Qubit = selectedQubits?['control1'];
    _ccnotControl2Qubit = selectedQubits?['control2'];
  }

  void _initDeletion() {
    setState(() {
      _currentMode = SelectedGateType.delete;
      _cnotControlQubit = null; // Reset CNOT control on new gate selection
      _ccnotControl1Qubit = null;
      _ccnotControl2Qubit = null;
      _currentInstructionMessage = "Tap on a gate to delete it.";
    });
    debugPrint('Selected gate type for placement: $_currentMode');
  }

  // ** Add a GlobalKey for the GestureDetector **
  final GlobalKey _gestureDetectorKey = GlobalKey();
  // *****************************************


  void _handleCircuitTap(TapDownDetails details) {
    debugPrint('Tap detected.');
    // final localPosition = _gatePositionToLocal(details.globalPosition);
    final localPosition = details.localPosition;

    if (localPosition == null) {
      debugPrint('Error: Could not convert global position to local.');
      return;
    }
    debugPrint('Local tap position: $localPosition');

    // Create a temporary painter instance for hit testing
    final painter = QuantumCircuitPainter(_circuit, _circuitWidthNotifier, _draggingOffset, _draggingGate);


    if (_currentMode == SelectedGateType.delete) {
      debugPrint('In delete mode.');
      // Use the painter's hit-testing method to find if a gate was tapped
      bool gateRemoved = painter.removeGateAtTap(localPosition);

      if (gateRemoved) {
        _runSimulation(); // Update simulation after deletion
        setState(() {
          _currentMode = SelectedGateType.none; // Reset mode after successful deletion
          _currentInstructionMessage = "Gate deleted."; // Reset message
        });

      } else {
        debugPrint('Gate not deleted.');
        setState(() {
          _currentInstructionMessage = "Gate not deleted."; // Reset message
        });
        // Optional: Provide feedback or reset mode if user taps outside gates
        // setState(() { simulationResult = "No gate tapped. Exiting delete mode."; }); // Example feedback
        // _setInteractionMode(SelectedGateType.none); // Example: Exit delete mode on tap outside
      }
      return; // Exit _handleCircuitTap if in delete mode
    }

    // If not in delete mode, taps on the circuit might be ignored or used for other interactions later
    debugPrint('Tapped on circuit in non-delete mode. Ignoring for now.');
  }

  void _runSimulation() {
    debugPrint("Running simulation...");

    // ** Call the void simulation method on the circuit **
    // This method executes the simulation and updates circuit.currentState internally.
    debugPrint(_circuit.toString());
    _circuit.runSimulation();

    // ** Access the updated circuit.currentState property to get the final state **
    // Now that runSimulation is complete, circuit.currentState holds the result.

    // ** Calculate measurement probabilities from the final state **
    // measurementProbabilities = finalState.state.map((amplitude) {
    //   return amplitude.abs() * amplitude.abs();
    // }).cast<double>().toList();
    //
    // debugPrint("Calculated probabilities: $measurementProbabilities");

    // ** Update the UI state variables to trigger a rebuild **
    if (!runningAsQuantumComposer()) {
      setState(() {
        // Format the final state vector for display
        // Access the state data via the finalState object obtained from circuit.currentState
        // simulationResult = "Final State Vector:\n${_circuit.initialState}"; // Assuming formatStateVector helper
        _checkLevelCompletion();
      });
    }
    debugPrint("Simulation finished.");
  }

  Future<void> _checkLevelCompletion() async {
    // Only check if not already completed to avoid re-triggering
    // expect(circuit.currentState.state.rawMatrix, Matrix(level.solutionFinalVector));
    bool match = _circuit.currentState.state.almostEqualTo(QuantumMatrix(_solutionVector));
    if (match) {
      final dialogResult = await _showLevelCompleteDialog(); // Trigger success actions

      if (dialogResult != null) {
        final LevelCompletionAction action = dialogResult['action'];
        final bool shouldUnlock = dialogResult['shouldUnlock'];

        // Perform unlock if indicated by the dialog
        if (shouldUnlock) {
          widget.onLevelUnlocked?.call(widget.levelId + 1);
        }

        // Now, based on the user's choice in the dialog, pop the QuantumComposerScreen itself.
        // This will complete the 'await Navigator.push' call back in HomePage.
        if (action == LevelCompletionAction.nextLevel ||
            action == LevelCompletionAction.levelSelect) {
          // If user chose to go to next level or level select, pop this composer screen
          // and pass the action back to HomePage.
          Navigator.of(context).pop(action);
        } else if (action == LevelCompletionAction.reviewSolution) {
          // If user chose to review, pop the composer screen and return to HomePage.
          // HomePage will then simply be visible again.
          debugPrint("Review solution selected. Staying on QuantumComposerScreen.");
        } else {
          // Default case: dialog might have been dismissed without a specific action
          // (e.g., tapping outside if barrierDismissible was true, or system back button on dialog).
          // In this case, also pop the composer screen, returning 'none'.
          Navigator.of(context).pop(LevelCompletionAction.none);
        }
      } else {
        // Default case: dialog might have been dismissed without a specific action
        // (e.g., tapping outside if barrierDismissible was true, or system back button on dialog).
        // In this case, also pop the composer screen, returning 'none'.
        Navigator.of(context).pop(LevelCompletionAction.none);
      }
    }
  }

  Future<Map<String, dynamic>?> _showLevelCompleteDialog() {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final double maxHeight = MediaQuery.of(context).size.height - 80;
        return Dialog(
          backgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                // mainAxisSize: max — lets Expanded children work correctly
                children: [

                  // ── Fixed header ──────────────────────────────────────────
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 6),
                  const Text(
                    'Level Complete!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 10),

                  // ── Flexible two-column body ──────────────────────────────
                  // Expanded gives the Row all remaining height between header and footer.
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // Left 35% — fixed congratulations (vertically centred)
                        Expanded(
                          flex: 35,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.emoji_events, color: Colors.amber, size: 36),
                              SizedBox(height: 10),
                              Text(
                                'Congratulations!\nYou\'ve successfully solved the puzzle.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                              ),
                            ],
                          ),
                        ),

                        // Vertical divider
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: VerticalDivider(color: Colors.white24, width: 1),
                        ),

                        // Right 65% — solution fills all available height
                        Expanded(
                          flex: 65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SOLUTION',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.blueAccent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Scrollbar(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        widget.level.solutionExplanation ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Fixed footer ──────────────────────────────────────────
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop({
                          'action': LevelCompletionAction.reviewSolution,
                          'shouldUnlock': true,
                        }),
                        icon: const Icon(Icons.menu_book, size: 16),
                        label: const Text('Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D5FE6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop({
                          'action': LevelCompletionAction.levelSelect,
                          'shouldUnlock': true,
                        }),
                        icon: const Icon(Icons.grid_view, size: 16),
                        label: const Text('Level Select'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop({
                          'action': LevelCompletionAction.nextLevel,
                          'shouldUnlock': true,
                        }),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Next Level'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConceptIntro(String intro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2E40),
        title: const Text('Before you start',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(intro,
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D5FE6)),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it →', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNextHint() {
    final nextIndex = _currentHintIndex + 1;
    if (nextIndex >= _hints.length) return;
    setState(() => _currentHintIndex = nextIndex);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2E40),
        title: Text('Hint ${nextIndex + 1} / ${_hints.length}',
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        content: Text(_hints[nextIndex],
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _clearCircuit() {
    _circuit.clearPlacedGates(); // This calls notifyListeners()
    debugPrint('Circuit cleared.');
    _setInteractionMode(SelectedGateType.none); // Reset mode
    _cnotControlQubit = null;
    _ccnotControl1Qubit = null;
    _ccnotControl2Qubit = null;
    _runSimulation(); // Run simulation - empty circuit
    _circuitWidthNotifier.value = 0; // Reset width notifier
  }

  // Helper to format a matrix for LaTeX display
  String _formatMatrixForTeX(QuantumMatrix matrix) {
    // if (matrix.matrixData.isEmpty) {
    //   return r'\begin{pmatrix} \end{pmatrix}'; // Empty matrix
    // }

    String teX = r'\begin{pmatrix}';
    for (int i = 0; i < matrix.rows.length; i++) {
      for (int j = 0; j < matrix.cols.length; j++) {
        Complex val = matrix.rows.elementAt(i).elementAt(j); // row(i)get(i, j);
        String complexStr = formatComplex(val);

        teX += complexStr;
        if (j < matrix.cols.length - 1) {
          teX += " & ";
        }
      }
      teX += r' \\ '; // New row
    }
    teX += r'\end{pmatrix}';
    return teX;
  }

  void _showOperatorMatrixDialog() {
    final String teXMatrix = _formatMatrixForTeX(_circuit.getOverallCircuitMatrix());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OperatorMatrixDialog(numQubits: _numQubits, teXMatrix: teXMatrix);
      },
    );
  }

  void _onDragEnter(Offset offset, Gate gate) {
    setState(() {
      final localPosition = _gatePositionToLocal(offset);

      if (localPosition == null) {
        debugPrint('Error: Could not convert global position to local.');
        return;
      }

      _draggingOffset = localPosition;
      _draggingGate = gate;
    });
  }

  void _onDragLeave() {
    setState(() {
      _draggingOffset = null;
      _draggingGate = Gate.fromIdentifier(SelectedGateType.none);
    });
  }

  void _updateScrollButtonStates() {
    if (!_gatesScrollController.hasClients) return; // Ensure controller is attached to a view
    final position = _gatesScrollController.position;

    // Debug prints (helpful to see the values if issues persist)
    debugPrint('Current Pixels: ${position.pixels}');
    debugPrint('Min Scroll Extent: ${position.minScrollExtent}');
    debugPrint('Max Scroll Extent: ${position.maxScrollExtent}');
    debugPrint('Viewport Dimension: ${position.viewportDimension}');
    debugPrint('Extent Before: ${position.extentBefore}');
    debugPrint('Extent After: ${position.extentAfter}');
    debugPrint('---');

    // Determine if there's content to scroll before the current view
    bool newCanScrollLeft = position.extentBefore > 0.1; // If > 0.1, there's content to the left

    // Determine if there's content to scroll after the current view
    bool newCanScrollRight = position.extentAfter > 0.1; // If > 0.1, there's content to the right

    // Only call setState if the scrollability state has actually changed
    if (_canScrollLeft != newCanScrollLeft || _canScrollRight != newCanScrollRight) {
      setState(() {
        _canScrollLeft = newCanScrollLeft;
        _canScrollRight = newCanScrollRight;
      });
    }
  }

  void _scroll(double offset) {
    if (!_gatesScrollController.hasClients) return;
    _gatesScrollController.animateTo(
      _gatesScrollController.position.pixels + offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollLeft() {
    if (!_gatesScrollController.hasClients) return;
    double scrollAmount = _gatesScrollController.position.viewportDimension;
    _scroll(-scrollAmount/3);
  }

  void _scrollRight() {
    if (!_gatesScrollController.hasClients) return;
    double scrollAmount = _gatesScrollController.position.viewportDimension;
    _scroll(scrollAmount/3);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF1E1E2C),
      // Modify the AppBar
      appBar: AppBar(
        backgroundColor: Color(0xFF1E1E2C), // Dark app bar
        scrolledUnderElevation: 0.0, // Prevent elevation change on scroll
        surfaceTintColor: Colors.transparent, // Prevent color tinting on scroll
        title: Row( // Use a Row to hold multiple widgets
          mainAxisSize: MainAxisSize.min, // Make the row take minimal horizontal space
          children: [
            SvgPicture.asset(
              'assets/images/logo_mini.svg', // Path to your white SVG logo
              height: 32, // Adjust the height to fit nicely in the AppBar
              colorFilter: ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ), // Ensure the SVG is white
            ),
            SizedBox(width: 8), // Add some spacing between the logo and the text
            Text(
              runningAsQuantumComposer() ? "Composer" : "Level ${widget.levelId}", // Keep your dynamic level text
              style: TextStyle(
                fontSize: 28, // Adjust font size as needed
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        // ** Add the actions list here **
        actions: [
          // Run Simulation Button (as TextButton)
          TextButton.icon(
            onPressed: _showOperatorMatrixDialog,
            icon: Icon(Icons.grid_on),
            label: Text('Operator Matrix'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, // White icon/text color for contrast on AppBar
              // You might adjust padding if needed to fit
              // padding: EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                  const WebViewPage(
                    title: 'Quantum Fundamentals',
                    url: 'https://danfran.github.io/qubit-quest/quantum-fundamentals.html',
                  ),
                ),
              );
            },
            icon: Icon(Icons.book),
            label: Text('Quantum Fundamentals'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, // White icon/text color for contrast on AppBar
              // You might adjust padding if needed to fit
              // padding: EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
          TextButton.icon(
            onPressed: _clearCircuit,
            icon: Icon(Icons.cleaning_services),
            label: Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
          if (_hints.isNotEmpty && !runningAsQuantumComposer())
            TextButton.icon(
              onPressed: _currentHintIndex < _hints.length - 1 ? _showNextHint : null,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(_currentHintIndex < 0
                  ? 'Hint'
                  : 'Hint ${_currentHintIndex + 1}/${_hints.length}'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber,
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
                          debugPrint("  LayoutBuilder constraints: $constraints"); // Debug constraints
                          final double availableContainerWidth = constraints.maxWidth;
                          final double availableContainerHeight = constraints.maxHeight;
                          debugPrint("  Available container size: Size($availableContainerWidth, $availableContainerHeight)"); // Debug available size


                          // Calculate the minimum width needed based on the maximum position of placed gates
                          final int maxPosition = _circuit.isCircuitEmpty() ? -1 : _circuit.placedGates.map((e) => e.length).reduce(max);
                          // Add 2 for the next column and some extra space
                          final double minRequiredWidth = (maxPosition + 3) * QuantumCircuitPainter.gateSpacing + QuantumCircuitPainter.padding * 2;


                          final double sizedBoxWidth = max(minRequiredWidth, availableContainerWidth);
                          // The height of the SizedBox should be fixed based on the number of qubits and spacing
                          final double sizedBoxHeight = _numQubits * QuantumCircuitPainter.qubitSpacing + QuantumCircuitPainter.padding * 2;
                          debugPrint("  Calculated SizedBox size: Size($sizedBoxWidth, $sizedBoxHeight)"); // Debug SizedBox size

                          return DragTarget<Gate>( // DragTarget wraps the scrollable area
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
                              Gate data = details.data;
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
                                    painter: QuantumCircuitPainter(_circuit, _circuitWidthNotifier, _draggingOffset, _draggingGate), // Pass the circuit
                                    child: ListenableBuilder(
                                      listenable: _circuit, // Listen to the circuit object
                                      builder: (context, child) {
                                        debugPrint("ListenableBuilder rebuilding CustomPaint."); // Debug rebuild
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
                  Row(children: [
                    Text("Add/Remove Gates:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.arrow_left, color: _canScrollLeft ? Colors.white : Colors.grey),
                      onPressed: _canScrollLeft ? _scrollLeft : null,
                      tooltip: 'Scroll Left',
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_right, color: _canScrollRight ? Colors.white : Colors.grey),
                      onPressed: _canScrollRight ? _scrollRight : null,
                      tooltip: 'Scroll Right',
                    ),
                  ]),
                  // SizedBox(height: 8),
                  Scrollbar(
                    controller: _gatesScrollController, // <-- Assign controller to Scrollbar
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _gatesScrollController, // <-- Assign controller to Scrollbar
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              onPressed: () => _initDeletion(),
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
                      // padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
                        children: [
                          // TOP SECTION: Scrollable Task Text
                          Flexible( // Use Flexible to allow the task text to take some space, but not too much
                            flex: 35, // Adjust this flex to control vertical space distribution (e.g., 20% of right column's height)
                            child: Column( // <--- NEW: Column to stack "Task:" label and text
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity, // This container will try to fill its parent's horizontal space
                                  padding: const EdgeInsets.all(2.0),
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[700],
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Text(
                                    _currentInstructionMessage,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Text( // <--- "Task:" label
                                  runningAsQuantumComposer() ? "Welcome to the Composer!" : "Task:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16, // Font size 16 for the label
                                  ),
                                ),
                                Expanded( // <--- Ensures the task description text takes available space and scrolls
                                  child: Scrollbar(
                                    controller: _taskTextScrollController, // <-- Assign controller to Scrollbar
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: _taskTextScrollController, // <-- Assign controller to SingleChildScrollView
                                      child: LatexText(
                                        math: _taskDescription,
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        inlineMathHeight: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(),
                          // SizedBox(height: 10.0),
                          Expanded(
                            flex: 40, // Changed from 8 to 6 for 60% vertical space
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: Colors.blueGrey.withOpacity(0.5), width: 0.5)
                              ),
                              child: StateVectorDisplay(
                                stateVector: _circuit.currentState.stateVector,
                                numQubits: _numQubits,
                                targetStateVector: runningAsQuantumComposer()
                                    ? null
                                    : _solutionVector
                                        .map((col) => col.first)
                                        .toList(),
                              ),
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

  bool runningAsQuantumComposer() => widget.levelId == -1;

  Widget _buildDraggableGateButton(Gate gate) {
    double fontSizeW;
    if (gate.type == SelectedGateType.ccnot) {
      fontSizeW = 14;
    } else if ((gate.type == SelectedGateType.rx || gate.type == SelectedGateType.ry || gate.type == SelectedGateType.rz) && gate.angle != null) {
      fontSizeW = 10;
    } else {
      fontSizeW = 18;
    }

    return Draggable<Gate>( // Draggable for Hadamard
      data: gate, // Data carried by the drag
      feedback: Container( // Visual feedback while dragging
        width: QuantumCircuitPainter.gateSize,
        height: QuantumCircuitPainter.gateSize,
        color: gate.color.withOpacity(0.7), // Semi-transparent feedback
        child: Center(
            child: Text(
                gate.label,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: fontSizeW, fontWeight: FontWeight.bold))),
      ),
      child: ElevatedButton( // The original button appearance
        onPressed: () => _setInteractionMode(SelectedGateType.none), // Tapping button resets mode
        style: ElevatedButton.styleFrom(
          minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize),
          padding: EdgeInsets.zero,
          backgroundColor: gate.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(0.0),),
        ),
        child: Text(
          gate.label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: fontSizeW, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}