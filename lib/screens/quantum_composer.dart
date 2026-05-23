import 'dart:math' as math;

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
  State<QuantumComposer> createState() => _QuantumComposerState();
}

class _QuantumComposerState extends State<QuantumComposer> {
  // Qubit Quest composer visual system tokens. Use these exact colours for composer surfaces.
  static const Color qqBlack = Color(0xFF00030A);
  static const Color qqCard = Color(0xFF111827);
  static const Color qqCard2 = Color(0xFF18233A);
  static const Color qqInner = Color(0xFF030814);
  static const Color qqInner2 = Color(0xFF101A2D);

  static const Color qqBorder = Color(0x66344A73);
  static const Color qqBorderSoft = Color(0x3D344A73);
  static const BorderSide qqComposerCardBorder =
      BorderSide(color: qqBorder, width: 1);
  static const BorderSide qqComposerInnerBorder =
      BorderSide(color: qqBorderSoft, width: 1);

  static const Color qqCyan = Color(0xFF56CCF2);
  static const Color qqPurple = Color(0xFFB388FF);
  static const Color qqGreen = Color(0xFF7CFFB2);
  static const Color qqYellow = Color(0xFFFFD54F);

  static const Color gateBlueTop = Color(0xFF2F6FEA);
  static const Color gateBlueMiddle = Color(0xFF2458C7);
  static const Color gateBlueBottom = Color(0xFF173A8F);

  static const Color gateCyanTop = Color(0xFF36B8D8);
  static const Color gateCyanMiddle = Color(0xFF238EAA);
  static const Color gateCyanBottom = Color(0xFF145B72);

  static const Color gateRedTop = Color(0xFFE44747);
  static const Color gateRedMiddle = Color(0xFFB83232);
  static const Color gateRedBottom = Color(0xFF7F1F1F);

  static const Color gatePurpleTop = Color(0xFF8E46E8);
  static const Color gatePurpleMiddle = Color(0xFF6E32C7);
  static const Color gatePurpleBottom = Color(0xFF451D8F);

  static const Color gateGreenTop = Color(0xFF239D66);
  static const Color gateGreenMiddle = Color(0xFF19764E);
  static const Color gateGreenBottom = Color(0xFF104A32);
  static const Color gateBorder = Color(0xFF31405F);

  static _GateVisual _gateVisualFor(Gate gate) {
    switch (gate.type) {
      case SelectedGateType.hadamard:
        return const _GateVisual(
          top: gateRedTop,
          middle: gateRedMiddle,
          bottom: gateRedBottom,
        );
      case SelectedGateType.x:
      case SelectedGateType.cnot:
      case SelectedGateType.ccnot:
      case SelectedGateType.cz:
      case SelectedGateType.rx:
        return const _GateVisual(
          top: gateBlueTop,
          middle: gateBlueMiddle,
          bottom: gateBlueBottom,
        );
      case SelectedGateType.y:
      case SelectedGateType.z:
        return const _GateVisual(
          top: gateCyanTop,
          middle: gateCyanMiddle,
          bottom: gateCyanBottom,
        );
      case SelectedGateType.s:
      case SelectedGateType.t:
      case SelectedGateType.rz:
        return const _GateVisual(
          top: gatePurpleTop,
          middle: gatePurpleMiddle,
          bottom: gatePurpleBottom,
        );
      case SelectedGateType.ry:
        return const _GateVisual(
          top: gateGreenTop,
          middle: gateGreenMiddle,
          bottom: gateGreenBottom,
        );
      default:
        return _GateVisual(
          top: gate.color,
          middle: Color.lerp(gate.color, Colors.black, 0.14)!,
          bottom: Color.lerp(gate.color, Colors.black, 0.30)!,
        );
    }
  }

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
  String? _checkFeedbackTitle;
  String? _checkFeedbackMessage;
  bool _checkFeedbackSuccess = false;
  bool _isShowingCompletionDialog = false;
  bool _levelSolved = false;

  final ValueNotifier<double> _circuitWidthNotifier =
      ValueNotifier<double>(0.0);

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
        _currentInstructionMessage =
            "Drag a gate onto the circuit."; // Default message for drag mode
      }
    });
    debugPrint('Interaction mode set to: $_currentMode');
  }

  // Method to handle a gate being dropped onto the circuit area
  Offset? _gatePositionToLocal(Offset offset) {
    final RenderBox? renderBox =
        _gestureDetectorKey.currentContext?.findRenderObject() as RenderBox?;
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
    debugPrint(
        'Gate dropped at local position: ${details.offset}'); // localPosition relative to the DragTarget
    debugPrint(
        'Dropped gate type: ${details.data}'); // The data from the Draggable

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
    final painter = QuantumCircuitPainter(_circuit, _circuitWidthNotifier,
        _draggingOffset, _draggingGate); // Painter knows layout constants

    // Determine the tapped qubit line based on the vertical drop position
    final tappedQubitLine = painter.getTappedQubitLine(dropPosition);

    if (tappedQubitLine == null) {
      debugPrint('Dropped outside qubit lines. Ignoring drop.');
      // Optionally provide feedback to the user
      return;
    }

    // Determine the horizontal insertion position based on the horizontal drop position
    final insertionPosition = painter.getInsertionPosition(
        dropPosition); // <-- Need to implement this in Painter

    if (insertionPosition == null) {
      debugPrint(
          'Could not determine valid insertion position. Ignoring drop.');
      // Optionally provide feedback
      return;
    }

    debugPrint(
        'Dropped on Qubit line: $tappedQubitLine at insertion position: $insertionPosition');

    if (droppedGateType == SelectedGateType.cnot ||
        droppedGateType == SelectedGateType.cz) {
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
        debugPrint(
            'Cannot place $gateLabel on single qubit or invalid target.');
        // Optionally provide feedback
        return;
      } else if (_numQubits == 2) {
        if (tappedQubitLine == 0) {
          controlQubitLine = 1;
        } else if (tappedQubitLine == 1) {
          controlQubitLine = 0;
        }
      } else if (_numQubits > 2) {
        await _showCNOTTargetSelectionDialog(
            context, tappedQubitLine, _numQubits);
        if (_cnotControlQubit != null) {
          controlQubitLine = _cnotControlQubit;
        }
      }

      if (controlQubitLine != null && tappedQubitLine != controlQubitLine) {
        debugPrint(
            '$gateLabel placement (control line = $_cnotControlQubit and target line = $tappedQubitLine).');
        _circuit.insertDoublePlacedGateAt(
            droppedGate, insertionPosition, tappedQubitLine, controlQubitLine);
        debugPrint(
            "Gate $gateLabel inserted at position $insertionPosition on qubits $tappedQubitLine and $controlQubitLine.");
      } else {
        debugPrint(
            'Invalid $gateLabel placement (control == target or not enough qubits).');
        // Optionally provide feedback
        return;
      }
    } else if (droppedGateType == SelectedGateType.ccnot) {
      if (_numQubits < 3) {
        debugPrint(
            'Cannot place CCNOT on less than 3 qubits circuit or invalid target.');
        // Optionally provide feedback
        return;
      } else if (_numQubits >= 3) {
        await _showCCNOTTargetSelectionDialog(
            context, tappedQubitLine, _numQubits);
      }

      if (_ccnotControl1Qubit != null &&
          _ccnotControl2Qubit != null &&
          tappedQubitLine != _ccnotControl1Qubit &&
          tappedQubitLine != _ccnotControl2Qubit) {
        debugPrint(
            'CCNOT placement (control line 1 = $_ccnotControl1Qubit, control line 2 = $_ccnotControl2Qubit and target line = $tappedQubitLine).');
        _circuit.insertTriplePlacedGateAt(droppedGate, insertionPosition,
            tappedQubitLine, _ccnotControl1Qubit!, _ccnotControl2Qubit!);
        debugPrint(
            "Gate CCNOT inserted at position $insertionPosition on qubits $tappedQubitLine, $_ccnotControl1Qubit and $_ccnotControl2Qubit.");
      } else {
        debugPrint(
            'Invalid CCNOT placement (control == target or not enough qubits).');
        // Optionally provide feedback
        return;
      }
    } else if ((droppedGateType == SelectedGateType.rx ||
            droppedGateType == SelectedGateType.ry ||
            droppedGateType == SelectedGateType.rz) &&
        widget.levelId == -1) {
      // if in the composer screen >> widget.levelId == -1
      await _showRotationAngleSetDialog(context);
      if (_rotationAngle != null) {
        Gate updatedRotationGate =
            Gate.fromIdentifier(droppedGateType, angle: _rotationAngle!);
        _circuit.insertSinglePlacedGateAt(
            updatedRotationGate, insertionPosition, tappedQubitLine);
      }
      debugPrint(
          "Gate inserted at position $insertionPosition on qubit $tappedQubitLine.");
    } else if (droppedGateType != SelectedGateType.draggedGate) {
      _circuit.insertSinglePlacedGateAt(
          droppedGate, insertionPosition, tappedQubitLine);
      debugPrint(
          "Gate inserted at position $insertionPosition on qubit $tappedQubitLine.");
    }

    _runSimulation(); // Optionally run simulation after placing
  }

  Future<void> _showCNOTTargetSelectionDialog(
      BuildContext context, int targetQubit, int numQubits) async {
    // Ensure dialog is not already shown
    if (ModalRoute.of(context)?.isCurrent != true ||
        Navigator.of(context).canPop() == false) {
      // This is a crude check to avoid showing multiple dialogs.
      // A more robust solution might involve a global boolean or state for dialog visibility.
      return;
    }

    final Map<String, dynamic>? selectedQubit =
        await showDialog<Map<String, dynamic>>(
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
    if (ModalRoute.of(context)?.isCurrent != true ||
        Navigator.of(context).canPop() == false) {
      // This is a crude check to avoid showing multiple dialogs.
      // A more robust solution might involve a global boolean or state for dialog visibility.
      return;
    }

    final Map<String, dynamic>? selectedAngle =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return RotationGateDialog();
      },
    );

    _rotationAngle = selectedAngle?['angle1'];
  }

  Future<void> _showCCNOTTargetSelectionDialog(
      BuildContext context, int targetQubit, int numQubits) async {
    // Ensure dialog is not already shown
    if (ModalRoute.of(context)?.isCurrent != true ||
        Navigator.of(context).canPop() == false) {
      // This is a crude check to avoid showing multiple dialogs.
      // A more robust solution might involve a global boolean or state for dialog visibility.
      return;
    }

    final Map<String, dynamic>? selectedQubits =
        await showDialog<Map<String, dynamic>>(
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

    debugPrint('Local tap position: $localPosition');

    // Create a temporary painter instance for hit testing
    final painter = QuantumCircuitPainter(
        _circuit, _circuitWidthNotifier, _draggingOffset, _draggingGate);

    if (_currentMode == SelectedGateType.delete) {
      debugPrint('In delete mode.');
      // Use the painter's hit-testing method to find if a gate was tapped
      bool gateRemoved = painter.removeGateAtTap(localPosition);

      if (gateRemoved) {
        _runSimulation(); // Update simulation after deletion
        setState(() {
          _currentMode =
              SelectedGateType.none; // Reset mode after successful deletion
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

  void _runSimulation({bool manualCheck = false}) {
    debugPrint("Running simulation...");

    if (!manualCheck && _checkFeedbackTitle != null && !_checkFeedbackSuccess) {
      setState(() {
        _checkFeedbackTitle = null;
        _checkFeedbackMessage = null;
      });
    }

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

    if (!runningAsQuantumComposer()) {
      // Format the final state vector for display
      // Access the state data via the finalState object obtained from circuit.currentState
      // simulationResult = "Final State Vector:\n${_circuit.initialState}"; // Assuming formatStateVector helper
      _checkLevelCompletion(manual: manualCheck);
    }
    debugPrint("Simulation finished.");
  }

  void _handleCheckResultPressed() {
    _runSimulation(manualCheck: true);
  }

  void _setCheckFeedback({
    required bool success,
    required String title,
    required String message,
  }) {
    if (!mounted) return;
    setState(() {
      _checkFeedbackSuccess = success;
      _checkFeedbackTitle = title;
      _checkFeedbackMessage = message;
    });
  }

  Future<void> _checkLevelCompletion({bool manual = false}) async {
    if (_isShowingCompletionDialog) return;

    // Only check if not already completed to avoid re-triggering
    bool match = widget.level.validateCircuit(_circuit);
    if (match) {
      _levelSolved = true;
      _setCheckFeedback(
        success: true,
        title: 'Solved',
        message: 'Nice work. Your circuit reaches the target.',
      );

      _isShowingCompletionDialog = true;
      await Future.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;

      final dialogResult =
          await _showLevelCompleteDialog(); // Trigger success actions
      _isShowingCompletionDialog = false;
      if (!mounted) return;

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
          debugPrint(
              "Review solution selected. Staying on QuantumComposerScreen.");
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
    } else {
      _levelSolved = false;
      if (manual) {
        _setCheckFeedback(
          success: false,
          title: 'Not yet',
          message: 'Adjust the gates and try again.',
        );
      } else if (_checkFeedbackSuccess) {
        setState(() {
          _checkFeedbackTitle = null;
          _checkFeedbackMessage = null;
          _checkFeedbackSuccess = false;
        });
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
          backgroundColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: qqCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: qqBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.36),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                // mainAxisSize: max — lets Expanded children work correctly
                children: [
                  // ── Fixed header ──────────────────────────────────────────
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:
                              const Color(0xFF66BB6A).withValues(alpha: 0.54)),
                    ),
                    child: const Icon(Icons.check_circle,
                        color: Color(0xFF81C784), size: 36),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Level Complete!',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your circuit reaches the target.',
                    style: TextStyle(
                      color: Color(0xFFB9C6DD),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
                              Icon(Icons.emoji_events,
                                  color: Colors.amber, size: 36),
                              SizedBox(height: 10),
                              Text(
                                'Congratulations!\nYou\'ve successfully solved the puzzle.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),

                        // Vertical divider
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child:
                              VerticalDivider(color: Colors.white24, width: 1),
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
                                    color: qqInner,
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
                          'action': LevelCompletionAction.nextLevel,
                          'shouldUnlock': true,
                        }),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Next Level'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: qqPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 11),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w800),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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
                          backgroundColor: qqCard2,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop({
                          'action': LevelCompletionAction.reviewSolution,
                          'shouldUnlock': true,
                        }),
                        icon: const Icon(Icons.menu_book, size: 16),
                        label: const Text('Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: qqCard2,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
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
        backgroundColor: qqCard,
        title: const Text('Before you start',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(intro,
            style: const TextStyle(
                color: Colors.white70, fontSize: 15, height: 1.5)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: qqPurple),
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Got it →', style: TextStyle(color: Colors.white)),
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
        backgroundColor: qqCard,
        title: Text('Hint ${nextIndex + 1} / ${_hints.length}',
            style: const TextStyle(
                color: Colors.amber, fontWeight: FontWeight.bold)),
        content: Text(_hints[nextIndex],
            style: const TextStyle(
                color: Colors.white70, fontSize: 15, height: 1.5)),
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
    _levelSolved = false;
    _checkFeedbackTitle = null;
    _checkFeedbackMessage = null;
    _runSimulation(); // Run simulation - empty circuit
    _circuitWidthNotifier.value = 0; // Reset width notifier
  }

  void _openQuantumFundamentals() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WebViewPage(
          title: 'Quantum Fundamentals',
          url:
              'https://danfran.github.io/qubit-quest/quantum-fundamentals.html',
        ),
      ),
    );
  }

  void _selectComposerMenuAction(String action) {
    switch (action) {
      case 'matrix':
        _showOperatorMatrixDialog();
        break;
      case 'fundamentals':
        _openQuantumFundamentals();
        break;
      case 'clear':
        _clearCircuit();
        break;
      case 'hint':
        _showNextHint();
        break;
    }
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
    final String teXMatrix =
        _formatMatrixForTeX(_circuit.getOverallCircuitMatrix());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OperatorMatrixDialog(
            numQubits: _numQubits, teXMatrix: teXMatrix);
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
    if (!_gatesScrollController.hasClients) {
      return; // Ensure controller is attached to a view
    }
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
    bool newCanScrollLeft =
        position.extentBefore > 0.1; // If > 0.1, there's content to the left

    // Determine if there's content to scroll after the current view
    bool newCanScrollRight =
        position.extentAfter > 0.1; // If > 0.1, there's content to the right

    // Only call setState if the scrollability state has actually changed
    if (_canScrollLeft != newCanScrollLeft ||
        _canScrollRight != newCanScrollRight) {
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
    _scroll(-scrollAmount / 3);
  }

  void _scrollRight() {
    if (!_gatesScrollController.hasClients) return;
    double scrollAmount = _gatesScrollController.position.viewportDimension;
    _scroll(scrollAmount / 3);
  }

  @override
  Widget build(BuildContext context) {
    final bool compactAppBar = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
        backgroundColor: qqBlack,
        // Modify the AppBar
        appBar: AppBar(
          toolbarHeight: compactAppBar ? 60 : 56,
          backgroundColor: qqBlack, // Dark app bar
          leadingWidth: compactAppBar ? 42 : 50,
          leading: _buildHeaderBackButton(compact: compactAppBar),
          flexibleSpace: const ColoredBox(color: qqBlack),
          elevation: 0,
          shadowColor: Colors.transparent,
          scrolledUnderElevation: 0.0, // Prevent elevation change on scroll
          surfaceTintColor:
              Colors.transparent, // Prevent color tinting on scroll
          titleSpacing: compactAppBar ? 0 : 8,
          title: Row(
            // Use a Row to hold multiple widgets
            mainAxisSize:
                MainAxisSize.min, // Make the row take minimal horizontal space
            children: [
              _buildHeaderLogo(compact: compactAppBar),
              SizedBox(
                  width: compactAppBar
                      ? 11
                      : 12), // Add some spacing between the logo and the text
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      runningAsQuantumComposer()
                          ? 'Composer'
                          : 'Level ${widget.levelId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compactAppBar ? 16 : 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.08,
                      ),
                    ),
                    Text(
                      _goalTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compactAppBar ? 11 : 12.5,
                        fontWeight: FontWeight.w700,
                        color: qqPurple,
                        height: 1.18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ** Add the actions list here **
          actions: _buildAppBarActions(compactAppBar),
          // ****************************
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final bool compact = constraints.maxWidth < 720;
            final bool short = constraints.maxHeight < 560;
            final Widget circuitCard = _buildCircuitCard(
              compact: short,
              showHeader: !compact,
            );
            final Widget statePanel = _buildStatePanel();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 16,
                short ? 3 : 5,
                compact ? 12 : 16,
                short ? 6 : (compact ? 8 : 10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: compact
                        ? _buildPortraitComposerLayout(
                            circuitCard: circuitCard,
                            statePanel: statePanel,
                            short: short,
                          )
                        : Row(
                            children: [
                              Expanded(flex: 68, child: circuitCard),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 32,
                                child: Column(
                                  children: [
                                    _buildTaskDetailsPanel(compact: false),
                                    const SizedBox(height: 10),
                                    Expanded(child: statePanel),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (!compact) ...[
                    SizedBox(height: short ? 6 : 10),
                    _buildGatePalette(compact: compact, dense: short),
                  ],
                ],
              ),
            );
          }),
        ));
  }

  Widget _buildHeaderLogo({required bool compact}) {
    final double size = compact ? 34 : 38;

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/images/qubit_quest_atom_logo.svg',
        fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(
          qqCyan,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget? _buildHeaderBackButton({required bool compact}) {
    if (!(ModalRoute.of(context)?.canPop ?? false)) {
      return null;
    }

    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_rounded),
      iconSize: compact ? 21 : 22,
      color: Colors.white.withValues(alpha: 0.90),
      padding: EdgeInsets.only(left: compact ? 2 : 4),
      splashRadius: 22,
      tooltip: 'Back',
    );
  }

  Widget _buildPortraitGoalSection({required bool short}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGoalBanner(compact: true),
      ],
    );
  }

  Widget _buildPortraitComposerLayout({
    required Widget circuitCard,
    required Widget statePanel,
    required bool short,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPortraitGoalSection(short: short),
        SizedBox(height: short ? 5 : 6),
        Expanded(flex: short ? 44 : 52, child: circuitCard),
        SizedBox(height: short ? 5 : 6),
        SizedBox(height: short ? 96 : 118, child: statePanel),
        SizedBox(height: short ? 5 : 6),
        _buildGatePalette(compact: true, dense: short),
        SizedBox(height: short ? 5 : 6),
        _buildPortraitCheckArea(compact: short),
      ],
    );
  }

  List<Widget> _buildAppBarActions(bool compact) {
    if (compact) {
      return [
        _buildHeaderIconAction(
          icon: Icons.school_outlined,
          tooltip: 'Learn',
          onPressed: _openQuantumFundamentals,
        ),
        const SizedBox(width: 6),
        PopupMenuButton<String>(
          tooltip: 'Composer actions',
          color: qqCard,
          offset: const Offset(0, 10),
          onSelected: _selectComposerMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'matrix',
              child: ListTile(
                leading: Icon(Icons.grid_on, color: Colors.white),
                title: Text('Operator Matrix'),
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: ListTile(
                leading: Icon(Icons.cleaning_services, color: Colors.white),
                title: Text('Clear'),
              ),
            ),
            if (_hints.isNotEmpty && !runningAsQuantumComposer())
              PopupMenuItem(
                value: 'hint',
                child: ListTile(
                  leading: const Icon(
                    Icons.lightbulb_outline,
                    color: qqYellow,
                  ),
                  title: Text(_currentHintIndex < 0
                      ? 'Hint'
                      : 'Hint ${_currentHintIndex + 1}/${_hints.length}'),
                ),
              ),
          ],
          child: _HeaderActionShell(
            child: Icon(
              Icons.settings_outlined,
              size: 18,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
        ),
        const SizedBox(width: 10),
      ];
    }

    return [
      TextButton.icon(
        onPressed: _openQuantumFundamentals,
        icon: const Icon(Icons.school_outlined),
        label: const Text('Learn'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: qqPurple.withValues(alpha: 0.14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: qqPurple.withValues(alpha: 0.22),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: _showOperatorMatrixDialog,
        icon: const Icon(Icons.grid_on),
        label: const Text('Operator Matrix'),
        style: TextButton.styleFrom(
          foregroundColor:
              Colors.white, // White icon/text color for contrast on AppBar
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          // You might adjust padding if needed to fit
          // padding: EdgeInsets.symmetric(horizontal: 8.0),
        ),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: _clearCircuit,
        icon: const Icon(Icons.cleaning_services),
        label: const Text('Clear'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
        ),
      ),
      if (_hints.isNotEmpty && !runningAsQuantumComposer())
        const SizedBox(width: 8),
      if (_hints.isNotEmpty && !runningAsQuantumComposer())
        TextButton.icon(
          onPressed:
              _currentHintIndex < _hints.length - 1 ? _showNextHint : null,
          icon: const Icon(Icons.lightbulb_outline),
          label: Text(_currentHintIndex < 0
              ? 'Hint'
              : 'Hint ${_currentHintIndex + 1}/${_hints.length}'),
          style: TextButton.styleFrom(
            foregroundColor: qqYellow,
            backgroundColor: qqYellow.withValues(alpha: 0.10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: qqYellow.withValues(alpha: 0.18),
              ),
            ),
          ),
        ),
      const SizedBox(width: 12),
    ];
  }

  Widget _buildHeaderIconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: _HeaderActionShell(
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 18,
          color: Colors.white.withValues(alpha: 0.94),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          splashRadius: 18,
        ),
      ),
    );
  }

  bool runningAsQuantumComposer() => widget.levelId == -1;

  String _goalTitle() {
    if (runningAsQuantumComposer()) {
      return 'Composer';
    }
    return widget.level.title ?? 'Level ${widget.levelId}';
  }

  Widget _buildGoalBanner({required bool compact}) {
    final bool canShowHint = _hints.isNotEmpty && !runningAsQuantumComposer();

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 12,
        compact ? 6 : 9,
        compact ? 4 : 8,
        compact ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: qqCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: qqComposerCardBorder.color),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: qqYellow,
            size: compact ? 18 : 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal:',
                  style: TextStyle(
                    color: qqPurple,
                    fontSize: compact ? 12.5 : 14,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: compact ? 58 : 72),
                    child: SingleChildScrollView(
                      child: LatexText(
                        math: _taskDescription,
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 12.5 : 14,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                        ),
                        inlineMathColor: qqGreen,
                        inlineMathHeight: compact ? 12.5 : 14,
                        displayMathHeight: compact ? 18 : 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (canShowHint) ...[
            const SizedBox(width: 6),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed:
                  _currentHintIndex < _hints.length - 1 ? _showNextHint : null,
              icon: const Icon(Icons.help_outline),
              iconSize: compact ? 20 : 21,
              color: Colors.white.withValues(alpha: 0.72),
              disabledColor: const Color(0xFF6B7890),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 28,
                height: 28,
              ),
              splashRadius: 16,
              tooltip: _currentHintIndex < 0
                  ? 'Hint'
                  : 'Hint ${_currentHintIndex + 1}/${_hints.length}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircuitCard({
    bool compact = false,
    bool showHeader = true,
  }) {
    final bool isDraggingGate = _draggingOffset != null &&
        _draggingGate.type != SelectedGateType.none &&
        _draggingGate.type != SelectedGateType.delete;

    return Container(
      decoration: BoxDecoration(
        color: qqCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDraggingGate ? qqCyan : qqComposerCardBorder.color,
          width: isDraggingGate ? 1.5 : qqComposerCardBorder.width,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
          if (isDraggingGate)
            BoxShadow(
              color: qqCyan.withValues(alpha: 0.16),
              blurRadius: 24,
              spreadRadius: 1,
            ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 12,
        compact ? 6 : 9,
        compact ? 8 : 12,
        compact ? 6 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            _buildCircuitSurfaceHeader(
              compact: compact,
              isDraggingGate: isDraggingGate,
            ),
            if (_checkFeedbackTitle != null) ...[
              SizedBox(height: compact ? 6 : 8),
              _buildCheckFeedbackBanner(compact: compact),
            ],
            SizedBox(height: compact ? 5 : 7),
          ],
          Expanded(child: _buildCircuitDragTarget()),
        ],
      ),
    );
  }

  Widget _buildCircuitSurfaceHeader({
    required bool compact,
    required bool isDraggingGate,
  }) {
    final String instruction = isDraggingGate
        ? 'Release on a highlighted slot'
        : (compact ? 'Build circuit' : _currentInstructionMessage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: compact ? 28 : 32,
              height: compact ? 28 : 32,
              decoration: BoxDecoration(
                color:
                    isDraggingGate ? qqCyan.withValues(alpha: 0.16) : qqCard2,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isDraggingGate ? qqCyan : qqComposerInnerBorder.color,
                ),
              ),
              child: Icon(
                runningAsQuantumComposer()
                    ? Icons.tune_outlined
                    : Icons.flag_outlined,
                color: qqCyan,
                size: compact ? 16 : 18,
              ),
            ),
            SizedBox(width: compact ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    runningAsQuantumComposer()
                        ? 'Sandbox'
                        : 'Level ${widget.levelId}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _goalTitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 16 : 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
            if (!runningAsQuantumComposer()) ...[
              SizedBox(width: compact ? 8 : 10),
              _buildCheckResultButton(compact: compact),
            ],
          ],
        ),
        SizedBox(height: compact ? 6 : 7),
        Row(
          children: [
            Container(
              width: 3,
              height: compact ? 18 : 20,
              decoration: BoxDecoration(
                color: isDraggingGate ? qqCyan : qqPurple,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            SizedBox(width: compact ? 7 : 8),
            Icon(
              isDraggingGate ? Icons.add_box_outlined : Icons.timeline,
              color: qqCyan,
              size: compact ? 14 : 15,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                instruction,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckResultButton({required bool compact}) {
    const Color checkSurfaceTop = Color(0xFFA855F7);
    const Color checkSurfaceMiddle = Color(0xFF8B4BE8);
    const Color checkSurfaceBottom = Color(0xFF5B21B6);
    const Color checkSurfaceBorder = Color(0xFF3B1B75);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            checkSurfaceTop,
            checkSurfaceMiddle,
            checkSurfaceBottom,
          ],
          stops: [0.0, 0.52, 1.0],
        ),
        border: Border.all(
          color: checkSurfaceBorder.withValues(alpha: 0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: checkSurfaceBottom.withValues(alpha: 0.40),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF240D4F).withValues(alpha: 0.38),
            blurRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed:
            _isShowingCompletionDialog ? null : _handleCheckResultPressed,
        icon: Icon(
          _levelSolved ? Icons.check_circle_outline : Icons.play_arrow_rounded,
          size: compact ? 16 : 18,
        ),
        label: Text(compact ? 'Check' : 'Check Result'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 7 : 9,
          ),
          textStyle: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitCheckArea({required bool compact}) {
    if (runningAsQuantumComposer()) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_checkFeedbackTitle != null) ...[
          _buildCheckFeedbackBanner(compact: compact),
          SizedBox(height: compact ? 6 : 8),
        ],
        SizedBox(
          height: compact ? 40 : 44,
          child: _buildCheckResultButton(compact: false),
        ),
      ],
    );
  }

  Widget _buildCheckFeedbackBanner({required bool compact}) {
    final Color accent = _checkFeedbackSuccess
        ? const Color(0xFF66BB6A)
        : const Color(0xFFFFB74D);
    final IconData icon =
        _checkFeedbackSuccess ? Icons.emoji_events_outlined : Icons.refresh;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: qqInner,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: qqComposerInnerBorder.color),
      ),
      child: Row(
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            scale: _checkFeedbackSuccess ? 1.08 : 1.0,
            child: Icon(icon, color: accent, size: compact ? 16 : 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_checkFeedbackTitle!}: ${_checkFeedbackMessage!}',
              style: TextStyle(
                color: const Color(0xFFD6E3F8),
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitDragTarget() {
    final bool isDraggingGate = _draggingOffset != null &&
        _draggingGate.type != SelectedGateType.none &&
        _draggingGate.type != SelectedGateType.delete;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: qqInner,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDraggingGate ? qqCyan : qqComposerInnerBorder.color,
          width: isDraggingGate ? 1.5 : qqComposerInnerBorder.width,
        ),
        boxShadow: [
          BoxShadow(
            color: isDraggingGate
                ? qqCyan.withValues(alpha: 0.13)
                : Colors.black.withValues(alpha: 0.18),
            blurRadius: isDraggingGate ? 18 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (context, constraints) {
        debugPrint("  LayoutBuilder constraints: $constraints");
        final double availableContainerWidth = constraints.maxWidth;

        final int maxPosition = _circuit.isCircuitEmpty()
            ? -1
            : _circuit.placedGates.map((e) => e.length).reduce(max);
        final double minRequiredWidth =
            (maxPosition + 3) * QuantumCircuitPainter.gateSpacing +
                QuantumCircuitPainter.padding * 2;

        final double sizedBoxWidth =
            max(minRequiredWidth, availableContainerWidth);
        final double sizedBoxHeight =
            _numQubits * QuantumCircuitPainter.qubitSpacing +
                QuantumCircuitPainter.padding * 2;
        final double viewportHeight =
            max(sizedBoxHeight, constraints.maxHeight);
        final bool circuitIsEmpty = _circuit.isCircuitEmpty();
        debugPrint(
            "  Calculated SizedBox size: Size($sizedBoxWidth, $sizedBoxHeight)");

        return DragTarget<Gate>(
          onAcceptWithDetails: (details) {
            _handleGateDrop(details);
            _onDragLeave();
          },
          onLeave: (data) {
            _onDragLeave();
          },
          onMove: (data) {
            _onDragEnter(data.offset, data.data);
          },
          onWillAcceptWithDetails: (details) {
            Gate data = details.data;
            _onDragEnter(details.offset, details.data);
            bool isNotDelete = data.type != SelectedGateType.delete;
            return isNotDelete;
          },
          builder: (context, candidateData, rejectedData) {
            return GestureDetector(
              key: _gestureDetectorKey,
              onTapDown: _handleCircuitTap,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: max(sizedBoxWidth, _circuitWidthNotifier.value),
                  height: viewportHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _CircuitGuidePainter(
                          numQubits: _numQubits,
                          columns: math.max(
                            4,
                            maxPosition + 4,
                          ),
                          isDragging: isDraggingGate,
                          dragOffset: _draggingOffset,
                        ),
                      ),
                      CustomPaint(
                        painter: QuantumCircuitPainter(
                          _circuit,
                          _circuitWidthNotifier,
                          _draggingOffset,
                          _draggingGate,
                        ),
                        child: ListenableBuilder(
                          listenable: _circuit,
                          builder: (context, child) {
                            debugPrint(
                                "ListenableBuilder rebuilding CustomPaint.");
                            return const SizedBox.expand();
                          },
                        ),
                      ),
                      if (circuitIsEmpty)
                        _EmptyCircuitPrompt(isDragging: isDraggingGate),
                      if (isDraggingGate)
                        const Positioned(
                          right: 12,
                          top: 10,
                          child: _DropReadyPill(),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildDeleteGateButton({required bool dense}) {
    final double buttonSize = dense ? 44 : 52;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gateGreenBottom.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gateGreenTop,
              gateGreenMiddle,
              gateGreenBottom,
            ],
            stops: const [0.0, 0.50, 1.0],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gateBorder.withValues(alpha: 0.65)),
        ),
        child: ElevatedButton(
          onPressed: () => _initDeletion(),
          style: ElevatedButton.styleFrom(
            minimumSize: Size.square(buttonSize),
            fixedSize: Size.square(buttonSize),
            padding: EdgeInsets.zero,
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white.withValues(alpha: 0.94),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
            ),
          ),
          child: Center(child: Icon(Icons.delete, size: dense ? 18 : 20)),
        ),
      ),
    );
  }

  Widget _buildGatePalette({required bool compact, required bool dense}) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, dense ? 6 : 8, 10, dense ? 6 : 9),
      decoration: BoxDecoration(
        color: qqCard,
        borderRadius: BorderRadius.circular(dense ? 12 : 14),
        border: Border.all(color: qqComposerCardBorder.color),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!dense)
            Row(children: [
              const Text(
                "Gate Palette",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: qqCyan.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.arrow_left,
                    color: _canScrollLeft ? Colors.white : Colors.grey),
                onPressed: _canScrollLeft ? _scrollLeft : null,
                tooltip: 'Scroll Left',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.arrow_right,
                    color: _canScrollRight ? Colors.white : Colors.grey),
                onPressed: _canScrollRight ? _scrollRight : null,
                tooltip: 'Scroll Right',
              ),
            ]),
          if (!dense) const SizedBox(height: 2),
          Row(
            children: [
              if (dense) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.arrow_left,
                      color: _canScrollLeft ? Colors.white : Colors.grey),
                  onPressed: _canScrollLeft ? _scrollLeft : null,
                  tooltip: 'Scroll Left',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.arrow_right,
                      color: _canScrollRight ? Colors.white : Colors.grey),
                  onPressed: _canScrollRight ? _scrollRight : null,
                  tooltip: 'Scroll Right',
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Scrollbar(
                  controller: _gatesScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _gatesScrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildDeleteGateButton(dense: dense),
                          SizedBox(width: dense ? 5 : 8),
                          Container(
                            height: dense ? 30 : 36,
                            width: 1,
                            color: qqComposerInnerBorder.color,
                          ),
                          SizedBox(width: dense ? 5 : 8),
                          ..._availableGates.map((gateType) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: dense ? 2.5 : 4.0),
                              child: _buildDraggableGateButton(
                                gateType,
                                dense: dense,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDetailsPanel({required bool compact}) {
    return Container(
      constraints: BoxConstraints(maxHeight: compact ? 170 : double.infinity),
      decoration: BoxDecoration(
        color: qqCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: qqComposerCardBorder.color),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: !compact,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: qqCyan,
          collapsedIconColor: Colors.white.withValues(alpha: 0.48),
          title: Text(
            runningAsQuantumComposer() ? 'Composer notes' : 'Goal details',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            SizedBox(
              height: compact ? 86 : 132,
              child: Scrollbar(
                controller: _taskTextScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _taskTextScrollController,
                  child: LatexText(
                    math: _taskDescription,
                    textStyle: const TextStyle(
                      color: Color(0xFFC3CEE2),
                      fontSize: 14,
                      height: 1.35,
                    ),
                    inlineMathHeight: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatePanel() {
    return Container(
      padding: const EdgeInsets.all(7.0),
      decoration: BoxDecoration(
        color: qqCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: qqComposerCardBorder.color,
          width: qqComposerCardBorder.width,
        ),
      ),
      child: StateVectorDisplay(
        stateVector: _circuit.currentState.stateVector,
        numQubits: _numQubits,
        targetStateVector: runningAsQuantumComposer()
            ? null
            : _solutionVector.map((col) => col.first).toList(),
      ),
    );
  }

  Widget _buildDraggableGateButton(Gate gate, {bool dense = false}) {
    double fontSizeW;
    if (gate.type == SelectedGateType.ccnot) {
      fontSizeW = dense ? 12 : 14;
    } else if ((gate.type == SelectedGateType.rx ||
            gate.type == SelectedGateType.ry ||
            gate.type == SelectedGateType.rz) &&
        gate.angle != null) {
      fontSizeW = dense ? 9 : 10;
    } else {
      fontSizeW = dense ? 16 : 18;
    }

    final double buttonSize = dense ? 44 : 52;
    final BorderRadius gateRadius = BorderRadius.circular(14);
    final _GateVisual visual = _gateVisualFor(gate);

    return Draggable<Gate>(
      // Draggable for Hadamard
      data: gate, // Data carried by the drag
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                visual.top,
                visual.middle,
                visual.bottom,
              ],
              stops: const [0.0, 0.50, 1.0],
            ),
            borderRadius: gateRadius,
            border: Border.all(color: gateBorder.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: visual.bottom.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              gate.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: fontSizeW,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.46,
        child: _GatePaletteButton(
          gate: gate,
          buttonSize: buttonSize,
          fontSize: fontSizeW,
          onPressed: () => _setInteractionMode(SelectedGateType.none),
        ),
      ),
      child: _GatePaletteButton(
        gate: gate,
        buttonSize: buttonSize,
        fontSize: fontSizeW,
        onPressed: () => _setInteractionMode(
            SelectedGateType.none), // Tapping button resets mode
      ),
    );
  }
}

class _GatePaletteButton extends StatelessWidget {
  final Gate gate;
  final double buttonSize;
  final double fontSize;
  final VoidCallback onPressed;

  const _GatePaletteButton({
    required this.gate,
    required this.buttonSize,
    required this.fontSize,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final _GateVisual visual = _QuantumComposerState._gateVisualFor(gate);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: visual.bottom.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              visual.top,
              visual.middle,
              visual.bottom,
            ],
            stops: const [0.0, 0.50, 1.0],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _QuantumComposerState.gateBorder.withValues(alpha: 0.65),
          ),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size.square(buttonSize),
            fixedSize: Size.square(buttonSize),
            padding: EdgeInsets.zero,
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white.withValues(alpha: 0.94),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
            ),
          ),
          child: Center(
            child: Text(
              gate.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GateVisual {
  final Color top;
  final Color middle;
  final Color bottom;

  const _GateVisual({
    required this.top,
    required this.middle,
    required this.bottom,
  });
}

class _DropReadyPill extends StatelessWidget {
  const _DropReadyPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _QuantumComposerState.qqCyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _QuantumComposerState.qqCyan.withValues(alpha: 0.5),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          'Drop ready',
          style: TextStyle(
            color: Color(0xFFB9F0FF),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyCircuitPrompt extends StatelessWidget {
  final bool isDragging;

  const _EmptyCircuitPrompt({required this.isDragging});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isDragging
                ? _QuantumComposerState.qqCyan.withValues(alpha: 0.10)
                : _QuantumComposerState.qqCard2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDragging
                  ? _QuantumComposerState.qqCyan.withValues(alpha: 0.46)
                  : _QuantumComposerState.qqComposerInnerBorder.color,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDragging
                    ? Icons.add_circle_outline
                    : Icons.touch_app_outlined,
                color: _QuantumComposerState.qqCyan,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                isDragging ? 'Release on a slot' : 'Drag a gate here',
                style: const TextStyle(
                  color: Color(0xFFD6E3F8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionShell extends StatelessWidget {
  final Widget child;

  const _HeaderActionShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _QuantumComposerState.qqCard2,
        shape: BoxShape.circle,
        border:
            Border.all(color: _QuantumComposerState.qqComposerCardBorder.color),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _CircuitGuidePainter extends CustomPainter {
  final int numQubits;
  final int columns;
  final bool isDragging;
  final Offset? dragOffset;

  const _CircuitGuidePainter({
    required this.numQubits,
    required this.columns,
    required this.isDragging,
    required this.dragOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint lanePaint = Paint()
      ..color = _QuantumComposerState.qqInner2.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final Paint depthGuidePaint = Paint()
      ..color = _QuantumComposerState.qqCyan.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Paint activeSlotPaint = Paint()
      ..color = _QuantumComposerState.qqCyan.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Paint activeSlotFillPaint = Paint()
      ..color = _QuantumComposerState.qqCyan.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final Paint activeLanePaint = Paint()
      ..color = _QuantumComposerState.qqCyan.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    int? activeQubit;
    int? activeColumn;
    if (dragOffset != null) {
      activeQubit = _qubitIndexForY(dragOffset!.dy);
      activeColumn = _columnIndexForX(dragOffset!.dx);
    }

    for (int column = 0; column < columns; column++) {
      final double centerX = QuantumCircuitPainter.padding +
          column * QuantumCircuitPainter.gateSpacing +
          QuantumCircuitPainter.gateSpacing / 2;
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, size.height),
        depthGuidePaint,
      );
    }

    for (int qubit = 0; qubit < numQubits; qubit++) {
      final double centerY = QuantumCircuitPainter.qubitSpacing * qubit +
          QuantumCircuitPainter.qubitSpacing / 2;
      final Rect laneRect = Rect.fromLTRB(
        0,
        centerY - QuantumCircuitPainter.hitTolerance,
        size.width,
        centerY + QuantumCircuitPainter.hitTolerance,
      );

      if (qubit.isEven) {
        canvas.drawRect(laneRect, lanePaint);
      }

      if (isDragging && activeQubit == qubit) {
        canvas.drawRect(laneRect, activeLanePaint);
      }

      for (int column = 0; column < columns; column++) {
        final double centerX = QuantumCircuitPainter.padding +
            column * QuantumCircuitPainter.gateSpacing +
            QuantumCircuitPainter.gateSpacing / 2;
        final Rect slotRect = Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: QuantumCircuitPainter.gateSize + 4,
          height: QuantumCircuitPainter.gateSize + 4,
        );
        final RRect slotRRect =
            RRect.fromRectAndRadius(slotRect, const Radius.circular(7));

        if (isDragging && activeQubit == qubit && activeColumn == column) {
          canvas.drawRRect(slotRRect, activeSlotFillPaint);
          canvas.drawRRect(slotRRect, activeSlotPaint);
        }
      }
    }
  }

  int? _qubitIndexForY(double y) {
    for (int qubit = 0; qubit < numQubits; qubit++) {
      final double centerY = QuantumCircuitPainter.qubitSpacing * qubit +
          QuantumCircuitPainter.qubitSpacing / 2;
      if (y >= centerY - QuantumCircuitPainter.hitTolerance &&
          y <= centerY + QuantumCircuitPainter.hitTolerance) {
        return qubit;
      }
    }
    return null;
  }

  int _columnIndexForX(double x) {
    final double relativeX = x - QuantumCircuitPainter.padding;
    return math.max(
      0,
      (relativeX / QuantumCircuitPainter.gateSpacing).floor(),
    );
  }

  @override
  bool shouldRepaint(covariant _CircuitGuidePainter oldDelegate) {
    return oldDelegate.numQubits != numQubits ||
        oldDelegate.columns != columns ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.dragOffset != dragOffset;
  }
}
