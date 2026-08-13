import 'dart:async';
import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/adaptive_learning.dart';
import 'package:quantumquiz/models/discovery_progress.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/screens/operator_matrix_dialog.dart';
import 'package:quantumquiz/screens/rotation_gate_dialog.dart';
import 'package:quantumquiz/screens/gate_replacement_dialog.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/three_qubits_gate_target_qubits_selection_dialog.dart';
import 'package:quantumquiz/screens/two_qubits_gate_target_qubit_selection_dialog.dart';
import 'package:quantumquiz/utils/complex_formatter.dart';
import 'package:quantumquiz/widgets/adaptive_learning_card.dart';
import 'package:quantumquiz/widgets/circuit_canvas_metrics.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/level_header_router.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';
import 'package:quantumquiz/models/level_completion_action.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';

import '../models/qq_level.dart';

enum _MasteryChallengeCompletionAction {
  review,
  continueJourney,
}

typedef _ComposerInsertCallback = CircuitEditOutcome Function({
  required Gate gate,
  required CircuitLocation location,
  int? controlQubit,
  int? secondControlQubit,
});

/// Drives the Composer's normal insertion pipeline without exposing its live
/// circuit or its completion/validation internals.
class QuantumComposerController {
  _ComposerInsertCallback? _insert;

  bool get isAttached => _insert != null;

  CircuitEditOutcome insertGate({
    required Gate gate,
    required CircuitLocation location,
    int? controlQubit,
    int? secondControlQubit,
  }) {
    final insert = _insert;
    if (insert == null) {
      return const CircuitEditOutcome(
        CircuitEditStatus.notFound,
        detail: 'QuantumComposerController is not attached.',
      );
    }
    return insert(
      gate: gate,
      location: location,
      controlQubit: controlQubit,
      secondControlQubit: secondControlQubit,
    );
  }

  void _attach(_ComposerInsertCallback insert) => _insert = insert;

  void _detach() => _insert = null;
}

@visibleForTesting
bool requiresRotationAngleSelection(Gate gate) {
  return gate.requiresAngle && gate.angle == null;
}

class QuantumComposer extends StatefulWidget {
  final int levelId;
  final ComposerLevel level;
  final Function(int unlockedLevel)? onLevelUnlocked;
  final bool isCompleted;
  final QuantumComposerController? controller;

  const QuantumComposer({
    super.key,
    required this.levelId,
    required this.level,
    required this.onLevelUnlocked,
    this.isCompleted = false,
    this.controller,
  });

  @override
  State<QuantumComposer> createState() => _QuantumComposerState();
}

class _QuantumComposerState extends State<QuantumComposer>
    with SingleTickerProviderStateMixin {
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

  // Hints state
  List<String> _hints = [];
  int _currentHintIndex = -1;

  // State to manage the highlight box for drag-and-drop
  Offset? _draggingOffset;
  CircuitDropDestination? _draggingDestination;
  LogicalMovePlan? _draggingMovePlan;
  Offset? _latestCircuitDragGlobalPosition;
  Gate _draggingGate = Gate.fromIdentifier(SelectedGateType.none);
  GateId? _selectedGateId;
  CircuitDragData? _activeDragData;
  Offset? _latestPlacedDragPointerPosition;
  int _placedDragAnchorRowOffset = 0;
  bool _placedDragOutsideCircuit = false;
  bool _placedDragWasCancelled = false;
  Rect? _circuitViewportBounds;

  String _currentInstructionMessage = "Drag a gate onto the circuit.";
  String? _checkFeedbackTitle;
  String? _checkFeedbackMessage;
  bool _checkFeedbackSuccess = false;
  bool _isShowingCompletionDialog = false;
  bool _levelSolved = false;
  late bool _isCompleted;

  late ScrollController _gatesScrollController;
  late ScrollController _circuitScrollController;
  late AnimationController _notebookPulseController;
  late Animation<double> _notebookPulseScale;

  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  bool _sharedNonZeroOnly = false;
  bool _hasUnopenedNotebookEntries = false;
  late AdaptiveLearningSession _adaptiveLearningSession;
  AdaptiveLearningInsight? _adaptiveInsight;
  bool _adaptiveInsightDismissed = false;
  Timer? _adaptiveInsightAutoDismissTimer;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
    _adaptiveLearningSession = AdaptiveLearningSession(
      level: widget.level,
      notebookEntry: _notebookEntryForLevel(),
    );
    _gatesScrollController = ScrollController()
      ..addListener(_updateScrollButtonStates);
    _circuitScrollController = ScrollController()
      ..addListener(_refreshCircuitDragDestinationAfterScroll);
    _notebookPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _notebookPulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 55),
    ]).animate(
      CurvedAnimation(
        parent: _notebookPulseController,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollButtonStates();
      _loadNotebookAttentionState();
      if (runningAsQuantumComposer()) {
        _showComposerIntro();
      } else if (widget.level.conceptIntro != null) {
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
    widget.controller?._attach(_insertGateFromController);

    debugPrint('Task: $_taskDescription');
    debugPrint('Number of qubits: $_numQubits');
    debugPrint('Initial state: $_initialState');
    debugPrint('Available gates: $_availableGates');
    debugPrint('Solution vector: $_solutionVector');
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _adaptiveInsightAutoDismissTimer?.cancel();
    _gatesScrollController.removeListener(_updateScrollButtonStates);
    _gatesScrollController.dispose(); // Dispose the controller
    _circuitScrollController
      ..removeListener(_refreshCircuitDragDestinationAfterScroll)
      ..dispose();
    _notebookPulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuantumComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?._detach();
    widget.controller?._attach(_insertGateFromController);
  }

  CircuitEditOutcome _insertGateFromController({
    required Gate gate,
    required CircuitLocation location,
    int? controlQubit,
    int? secondControlQubit,
  }) {
    final CircuitEditOutcome outcome;
    if (gate.type == SelectedGateType.ccnot) {
      if (controlQubit == null || secondControlQubit == null) {
        return const CircuitEditOutcome(
          CircuitEditStatus.invalid,
          detail: 'CCNOT requires two controls.',
        );
      }
      outcome = _circuit.insertTripleGateWithOutcome(
        gate,
        location.column,
        location.qubit,
        controlQubit,
        secondControlQubit,
      );
    } else if (gate.type == SelectedGateType.cnot ||
        gate.type == SelectedGateType.cz) {
      if (controlQubit == null) {
        return const CircuitEditOutcome(
          CircuitEditStatus.invalid,
          detail: 'Controlled gate requires a control.',
        );
      }
      outcome = _circuit.insertDoubleGateWithOutcome(
        gate,
        location.column,
        location.qubit,
        controlQubit,
      );
    } else {
      outcome = _circuit.insertSingleGateWithOutcome(
        gate,
        location.column,
        location.qubit,
      );
    }
    _handleCommittedCircuitEdit(outcome);
    return outcome;
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
  Offset? _gatePositionToViewport(Offset offset) {
    final RenderBox? renderBox =
        _gestureDetectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.attached) {
      return renderBox.globalToLocal(offset);
    }
    final cachedBounds = _circuitViewportBounds;
    if (cachedBounds != null) return offset - cachedBounds.topLeft;
    debugPrint('Error: Could not resolve the circuit viewport bounds.');
    return null;
  }

  void _captureCircuitViewportBounds() {
    final renderBox =
        _gestureDetectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;
    _circuitViewportBounds =
        renderBox.localToGlobal(Offset.zero) & renderBox.size;
  }

  Offset? _gatePositionToContent(Offset globalPosition) {
    final viewportPosition = _gatePositionToViewport(globalPosition);
    if (viewportPosition == null) return null;
    final scrollOffset = _circuitScrollController.hasClients
        ? _circuitScrollController.offset
        : 0.0;
    return CircuitCoordinateMapper.viewportToContent(
      viewportPosition,
      horizontalScrollOffset: scrollOffset,
    );
  }

  CircuitDropDestination? _resolveCircuitDrop(Offset globalPosition) {
    final contentPosition = _gatePositionToContent(globalPosition);
    if (contentPosition == null) return null;
    return CircuitGeometry.dropDestinationForPoint(
      circuit: _circuit,
      contentPoint: contentPosition,
    );
  }

  // Method to handle a gate being dropped onto the circuit area
  Future<void> _handleGateDrop(
      DragTargetDetails<CircuitDragData> details) async {
    // Corrected: Use details.offset for the local drop position
    debugPrint(
        'Gate dropped at local position: ${details.offset}'); // localPosition relative to the DragTarget
    debugPrint(
        'Dropped gate type: ${details.data}'); // The data from the Draggable

    // DragTarget move/accept share this resolved content-space destination.
    // Falling back keeps programmatic drops safe if no move event was delivered.
    final fallbackDestination = _resolveCircuitDrop(details.offset);
    final destination = _draggingDestination ??
        (fallbackDestination == null
            ? null
            : _logicalMoveDestination(fallbackDestination, details.data));

    if (destination == null) {
      debugPrint('Error: Could not convert global position to local.');
      return;
    }

    final droppedGate = details.data.gate;
    final droppedGateType = droppedGate.type;
    CircuitEditOutcome editOutcome = CircuitEditOutcome.same;
    final tappedQubitLine = destination.location.qubit;
    final insertionPosition = destination.location.column;

    debugPrint(
        'Dropped on Qubit line: $tappedQubitLine at insertion position: $insertionPosition');

    if (details.data.isPlaced) {
      final sourceId = details.data.sourceId!;
      final plan = _draggingMovePlan ??
          _circuit.planLogicalGateMove(
            sourceId,
            CircuitLocation(
              qubit: tappedQubitLine,
              column: insertionPosition,
            ),
          );
      final result = _circuit.commitLogicalGateMovePlan(plan);
      _handleCommittedCircuitEdit(result, selectionAfter: sourceId);
      return;
    }

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
        editOutcome = _circuit.insertDoubleGateWithOutcome(
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
        editOutcome = _circuit.insertTripleGateWithOutcome(
            droppedGate,
            insertionPosition,
            tappedQubitLine,
            _ccnotControl1Qubit!,
            _ccnotControl2Qubit!);
        debugPrint(
            "Gate CCNOT inserted at position $insertionPosition on qubits $tappedQubitLine, $_ccnotControl1Qubit and $_ccnotControl2Qubit.");
      } else {
        debugPrint(
            'Invalid CCNOT placement (control == target or not enough qubits).');
        // Optionally provide feedback
        return;
      }
    } else if (requiresRotationAngleSelection(droppedGate)) {
      final selectedAngle = await _showRotationAngleSetDialog(
        context,
        gateType: droppedGateType,
      );
      if (selectedAngle == null) {
        debugPrint(
            'Rotation angle selection cancelled for $droppedGateType. Gate not inserted.');
        return;
      } else {
        Gate updatedRotationGate =
            Gate.fromIdentifier(droppedGateType, angle: selectedAngle);
        editOutcome = _circuit.insertSingleGateWithOutcome(
            updatedRotationGate, insertionPosition, tappedQubitLine);
      }
      debugPrint(
          "Gate inserted at position $insertionPosition on qubit $tappedQubitLine.");
    } else if (droppedGateType != SelectedGateType.draggedGate) {
      editOutcome = _circuit.insertSingleGateWithOutcome(
          droppedGate, insertionPosition, tappedQubitLine);
      debugPrint(
          "Gate inserted at position $insertionPosition on qubit $tappedQubitLine.");
    }

    _handleCommittedCircuitEdit(editOutcome);
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

  Future<double?> _showRotationAngleSetDialog(
    BuildContext context, {
    SelectedGateType? gateType,
    double? initialAngle,
  }) async {
    // Ensure dialog is not already shown
    if (ModalRoute.of(context)?.isCurrent != true) {
      // This is a crude check to avoid showing multiple dialogs.
      // A more robust solution might involve a global boolean or state for dialog visibility.
      return null;
    }

    final Map<String, dynamic>? selectedAngle =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return RotationGateDialog(
          gateType: gateType,
          initialAngle: initialAngle,
        );
      },
    );
    return selectedAngle?['angle1'] as double?;
  }

  Future<void> _editSelectedRotationAngle() async {
    final selectedId = _selectedGateId;
    if (selectedId == null) return;
    final footprint = _circuit.logicalGateById(selectedId);
    if (footprint == null || !footprint.isParameterEditable) return;
    if (footprint.gate.angle == null) {
      assert(() {
        debugPrint(
          'Selected ${footprint.type} gate ${footprint.id} has no angle; '
          'opening the picker so it can be repaired.',
        );
        return true;
      }());
    }

    final selectedAngle = await _showRotationAngleSetDialog(
      context,
      gateType: footprint.type,
      initialAngle: footprint.gate.angle,
    );
    if (!mounted || selectedAngle == null) return;
    final outcome = _circuit.updateGateParametersWithOutcome(
      selectedId,
      angle: selectedAngle,
    );
    _handleCommittedCircuitEdit(outcome, selectionAfter: selectedId);
    if (outcome.status == CircuitEditStatus.invalid && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Choose a valid rotation angle.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _replaceSelectedGate() async {
    final selectedId = _selectedGateId;
    if (selectedId == null) return;
    final footprint = _circuit.logicalGateById(selectedId);
    if (footprint == null || !footprint.isEditable) return;

    final candidates = _circuit.availableSingleQubitReplacementTypes
        .where((type) => type != footprint.type)
        .toList(growable: false);
    if (candidates.isEmpty) return;
    final replacementType = await showDialog<SelectedGateType>(
      context: context,
      builder: (dialogContext) => GateReplacementDialog(
        gateTypes: candidates,
      ),
    );
    if (!mounted || replacementType == null) return;

    double? angle;
    final unconfiguredReplacement = Gate.fromIdentifier(replacementType);
    if (unconfiguredReplacement.requiresAngle) {
      angle = await _showRotationAngleSetDialog(
        context,
        gateType: replacementType,
      );
      if (!mounted || angle == null) return;
    }

    final outcome = _circuit.replaceSingleGateWithOutcome(
      selectedId,
      Gate.fromIdentifier(replacementType, angle: angle),
    );
    _handleCommittedCircuitEdit(outcome, selectionAfter: selectedId);
    if (outcome.status == CircuitEditStatus.invalid && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('That gate cannot replace the selected gate.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _duplicateSelectedGate() {
    final selectedId = _selectedGateId;
    if (selectedId == null) return;
    final outcome = _circuit.duplicateLogicalGateWithOutcome(selectedId);
    _handleCommittedCircuitEdit(
      outcome,
      selectionAfter: outcome.changed ? outcome.affectedGateId : selectedId,
    );
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

  // ** Add a GlobalKey for the GestureDetector **
  final GlobalKey _gestureDetectorKey = GlobalKey();
  // *****************************************

  void _handleCircuitTap(TapDownDetails details) {
    debugPrint('Tap detected.');
    // final localPosition = _gatePositionToLocal(details.globalPosition);
    final localPosition = CircuitCoordinateMapper.viewportToContent(
      details.localPosition,
      horizontalScrollOffset: _circuitScrollController.hasClients
          ? _circuitScrollController.offset
          : 0,
    );

    debugPrint('Local tap position: $localPosition');

    if (_currentMode == SelectedGateType.delete) {
      debugPrint('In delete mode.');
      // Use the painter's hit-testing method to find if a gate was tapped
      final hit = CircuitGeometry.hitTestGate(_circuit, localPosition);
      final outcome = hit == null
          ? CircuitEditOutcome.notFound
          : _circuit.removeLogicalGateByIdWithOutcome(hit.id);
      final gateRemoved = outcome.changed;

      if (gateRemoved) {
        _handleCommittedCircuitEdit(outcome, clearSelection: true);
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

    final hit = CircuitGeometry.hitTestGate(_circuit, localPosition);
    setState(() {
      _selectedGateId = hit?.id;
      _currentInstructionMessage = hit == null
          ? 'Drag a gate onto the circuit.'
          : hit.isMovable
              ? 'Selected gate. Drag to move.'
              : 'Selected gate is fixed.';
    });
  }

  void _validateSelection() {
    final selected = _selectedGateId;
    if (selected != null && !_circuit.containsGate(selected)) {
      _selectedGateId = null;
    }
  }

  void _handleCommittedCircuitEdit(
    CircuitEditOutcome outcome, {
    GateId? selectionAfter,
    bool clearSelection = false,
  }) {
    if (!outcome.changed) {
      if (mounted) setState(_validateSelection);
      return;
    }
    if (clearSelection) {
      _selectedGateId = null;
    } else if (selectionAfter != null) {
      _selectedGateId = selectionAfter;
    }
    _runSimulation();
    if (mounted) setState(_validateSelection);
  }

  void _startPlacedDrag(PlacedGateRef source) {
    final pointerPosition = _latestPlacedDragPointerPosition;
    setState(() {
      _selectedGateId = source.id;
      _placedDragWasCancelled = false;
      _activeDragData = CircuitDragData.placed(
        sourceId: source.id,
        gate: source.gate,
      );
      _placedDragOutsideCircuit = pointerPosition != null &&
          _isClearlyOutsideCircuitForDeletion(pointerPosition);
    });
  }

  void _finishPlacedDrag() {
    if (!mounted) return;
    setState(() {
      _activeDragData = null;
      _latestPlacedDragPointerPosition = null;
      _placedDragAnchorRowOffset = 0;
      _placedDragOutsideCircuit = false;
      _placedDragWasCancelled = false;
      _onDragLeaveStateOnly();
    });
  }

  void _onDragLeaveStateOnly() {
    _draggingOffset = null;
    _draggingDestination = null;
    _draggingMovePlan = null;
    _latestCircuitDragGlobalPosition = null;
    _draggingGate = Gate.fromIdentifier(SelectedGateType.none);
  }

  void _capturePlacedDragOrigin(
    PointerDownEvent event,
    LogicalGateFootprint footprint,
  ) {
    _latestPlacedDragPointerPosition = event.position;
    final contentPosition = _gatePositionToContent(event.position);
    final grabbedRow = contentPosition == null
        ? null
        : CircuitGeometry.qubitForPoint(contentPosition, _numQubits);
    _placedDragAnchorRowOffset =
        grabbedRow == null ? 0 : footprint.anchor.qubit - grabbedRow;
  }

  CircuitDropDestination _logicalMoveDestination(
    CircuitDropDestination destination,
    CircuitDragData data,
  ) {
    if (!data.isPlaced) return destination;
    return CircuitDropDestination(
      contentPoint: destination.contentPoint,
      location: CircuitLocation(
        qubit: destination.location.qubit + _placedDragAnchorRowOffset,
        column: destination.location.column,
      ),
    );
  }

  bool _isValidMovePlan(LogicalMovePlan plan) =>
      plan.status == CircuitEditStatus.changed ||
      plan.status == CircuitEditStatus.same;

  bool _isClearlyOutsideCircuitForDeletion(Offset pointerPosition) {
    final renderBox =
        _gestureDetectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return false;
    final circuitRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    return CircuitGeometry.isClearlyOutsideCircuitForDeletion(
      circuitBounds: circuitRect,
      pointerPosition: pointerPosition,
    );
  }

  void _updatePlacedDragPosition(Offset pointerPosition) {
    if (!mounted) return;
    _latestPlacedDragPointerPosition = pointerPosition;
    if (!(_activeDragData?.isPlaced ?? false)) return;
    final shouldShowDelete =
        _isClearlyOutsideCircuitForDeletion(pointerPosition);
    if (_placedDragOutsideCircuit == shouldShowDelete) return;
    setState(() {
      _placedDragOutsideCircuit = shouldShowDelete;
    });
  }

  void _handlePlacedDragCancelled(PlacedGateRef source) {
    final pointerPosition = _latestPlacedDragPointerPosition;
    if (!mounted ||
        _placedDragWasCancelled ||
        pointerPosition == null ||
        !_isClearlyOutsideCircuitForDeletion(pointerPosition)) {
      _finishPlacedDrag();
      return;
    }
    final result = _circuit.removeLogicalGateByIdWithOutcome(source.id);
    _handleCommittedCircuitEdit(result, clearSelection: true);
    _finishPlacedDrag();
  }

  void _runSimulation({bool manualCheck = false}) {
    debugPrint("Running simulation...");

    // ** Call the void simulation method on the circuit **
    // This method executes the simulation and updates circuit.currentState internally.
    debugPrint(_circuit.toString());
    _circuit.runSimulation();
    final simulationError = _circuit.lastSimulationError;
    if (simulationError != null) {
      if (manualCheck && !runningAsQuantumComposer()) {
        _showInvalidCircuitMessage(simulationError.userMessage);
      }
      debugPrint("Simulation blocked by malformed circuit.");
      return;
    }

    // ** Access the updated circuit.currentState property to get the final state **
    // Now that runSimulation is complete, circuit.currentState holds the result.

    // ** Calculate measurement probabilities from the final state **
    // measurementProbabilities = finalState.state.map((amplitude) {
    //   return amplitude.abs() * amplitude.abs();
    // }).cast<double>().toList();
    //
    // debugPrint("Calculated probabilities: $measurementProbabilities");

    if (!runningAsQuantumComposer() && manualCheck) {
      // Format the final state vector for display
      // Access the state data via the finalState object obtained from circuit.currentState
      // simulationResult = "Final State Vector:\n${_circuit.initialState}"; // Assuming formatStateVector helper
      _checkLevelCompletion(manual: manualCheck);
    } else if (!manualCheck && (_checkFeedbackTitle != null || _levelSolved)) {
      setState(() {
        _levelSolved = false;
        _checkFeedbackTitle = null;
        _checkFeedbackMessage = null;
        _checkFeedbackSuccess = false;
      });
    }
    debugPrint("Simulation finished.");
  }

  void _showInvalidCircuitMessage(String message) {
    _setCheckFeedback(
      success: false,
      title: 'Circuit incomplete',
      message: message,
    );
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _handleCheckResultPressed() {
    _runSimulation(manualCheck: true);
  }

  void _setCheckFeedback({
    required bool success,
    required String title,
    required String message,
    AdaptiveLearningInsight? adaptiveInsight,
  }) {
    if (!mounted) return;
    setState(() {
      _checkFeedbackSuccess = success;
      _checkFeedbackTitle = title;
      _checkFeedbackMessage = message;
      _adaptiveInsight = adaptiveInsight;
      _adaptiveInsightDismissed = false;
    });
    _scheduleAdaptiveInsightAutoDismiss(adaptiveInsight);
  }

  void _scheduleAdaptiveInsightAutoDismiss(AdaptiveLearningInsight? insight) {
    _adaptiveInsightAutoDismissTimer?.cancel();
    if (insight == null) return;

    _adaptiveInsightAutoDismissTimer = Timer(const Duration(seconds: 9), () {
      if (!mounted || _adaptiveInsight != insight) return;
      setState(() {
        _adaptiveInsightDismissed = true;
      });
    });
  }

  void _dismissAdaptiveInsight() {
    _adaptiveInsightAutoDismissTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _adaptiveInsightDismissed = true;
    });
  }

  Future<void> _checkLevelCompletion({bool manual = false}) async {
    if (_isShowingCompletionDialog) return;

    // Only check if not already completed to avoid re-triggering
    bool match = widget.level.validateCircuit(_circuit);
    if (match) {
      final discoveryTitle = widget.level.discoveryTitle?.trim();
      final unlocksNotebookEntry = discoveryTitle != null &&
          notebookEntriesByDiscoveryTitle.containsKey(discoveryTitle);
      final String keyInsight = _completionKeyInsight();

      setState(() {
        _levelSolved = true;
        _checkFeedbackTitle = LevelHeaderRouter.isMasteryLevel(widget.levelId)
            ? 'Challenge Complete'
            : null;
        _checkFeedbackMessage = LevelHeaderRouter.isMasteryLevel(widget.levelId)
            ? keyInsight
            : null;
        _checkFeedbackSuccess =
            LevelHeaderRouter.isMasteryLevel(widget.levelId);
        _adaptiveInsight = null;
        _adaptiveInsightDismissed = false;
        _isCompleted = LevelHeaderRouter.isMasteryLevel(widget.levelId)
            ? true
            : _isCompleted;
      });
      _adaptiveInsightAutoDismissTimer?.cancel();
      if (unlocksNotebookEntry) {
        _playNotebookUnlockPulse();
      }

      _isShowingCompletionDialog = true;
      try {
        await Future.delayed(const Duration(milliseconds: 420));
        if (!mounted) return;

        widget.onLevelUnlocked?.call(widget.levelId + 1);

        if (LevelHeaderRouter.isMasteryLevel(widget.levelId)) {
          final action = await _showMasteryChallengeCompletionDialog(
            keyInsight: keyInsight,
          );
          if (!mounted) return;
          if (action == _MasteryChallengeCompletionAction.continueJourney) {
            Navigator.of(context).pop(LevelCompletionAction.nextLevel);
          }
          return;
        }

        if (!mounted) return;
        Navigator.of(context).pop(LevelCompletionAction.nextLevel);
      } finally {
        _isShowingCompletionDialog = false;
      }
    } else {
      _levelSolved = false;
      if (manual) {
        final adaptiveInsight = _adaptiveLearningSession.recordComposerAttempt(
          signature: _adaptiveCircuitSignature(),
          gateCounts: _adaptiveGateCounts(),
          correct: false,
        );
        _setCheckFeedback(
          success: false,
          title: 'Not yet',
          message: 'Adjust the gates and try again.',
          adaptiveInsight: adaptiveInsight,
        );
      } else if (_checkFeedbackSuccess) {
        setState(() {
          _checkFeedbackTitle = null;
          _checkFeedbackMessage = null;
          _checkFeedbackSuccess = false;
          _adaptiveInsight = null;
          _adaptiveInsightDismissed = false;
        });
        _adaptiveInsightAutoDismissTimer?.cancel();
      }
    }
  }

  String _completionKeyInsight() {
    final explanation = widget.level.solutionExplanation?.trim();
    if (explanation == null || explanation.isEmpty) {
      return 'You solved this challenge.';
    }

    final firstSentenceMatch = RegExp(r'^(.+?[.!?])(?:\s|$)')
        .firstMatch(explanation.replaceAll(RegExp(r'\s+'), ' '));
    final candidate = firstSentenceMatch?.group(1) ?? explanation;
    if (candidate.length <= 180) return candidate;
    return '${candidate.substring(0, 177).trimRight()}...';
  }

  Future<_MasteryChallengeCompletionAction>
      _showMasteryChallengeCompletionDialog({
    required String keyInsight,
  }) async {
    final action = await showDialog<_MasteryChallengeCompletionAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return QubitQuestDialog(
          title: 'Challenge Complete',
          maxWidth: 560,
          actions: [
            QubitQuestDialogButton.secondary(
              label: 'Review Challenge',
              onPressed: () => Navigator.of(context)
                  .pop(_MasteryChallengeCompletionAction.review),
            ),
            QubitQuestDialogButton.primary(
              label: 'Continue',
              onPressed: () => Navigator.of(context)
                  .pop(_MasteryChallengeCompletionAction.continueJourney),
            ),
          ],
          child: _MasteryChallengeCompletionBody(
            challengeTitle: _goalTitle(),
            keyInsight: keyInsight,
            solutionExplanation: widget.level.solutionExplanation,
          ),
        );
      },
    );

    return action ?? _MasteryChallengeCompletionAction.review;
  }

  void _playNotebookUnlockPulse() {
    if (!mounted) return;
    _notebookPulseController
      ..stop()
      ..reset()
      ..forward();
  }

  Future<void> _loadNotebookAttentionState() async {
    final hasUnopened = await DiscoveryProgress.hasUnopenedNotebookEntries(
      notebookEntriesByDiscoveryTitle.keys,
    );
    if (!mounted) return;
    setState(() {
      _hasUnopenedNotebookEntries = hasUnopened;
    });
    if (hasUnopened) {
      _playNotebookUnlockPulse();
    }
  }

  NotebookEntry? _notebookEntryForLevel() {
    final discoveryTitle = widget.level.discoveryTitle?.trim();
    if (discoveryTitle == null || discoveryTitle.isEmpty) return null;
    return notebookEntriesByDiscoveryTitle[discoveryTitle];
  }

  String _adaptiveCircuitSignature() {
    final maxDepth = _circuit.placedGates.fold<int>(
      0,
      (depth, line) => line.length > depth ? line.length : depth,
    );
    if (maxDepth == 0) return 'empty';

    final columns = <String>[];
    for (int column = 0; column < maxDepth; column++) {
      final gates = <String>[];
      for (int qubit = 0; qubit < _circuit.placedGates.length; qubit++) {
        if (column >= _circuit.placedGates[qubit].length) continue;
        final gate = _circuit.placedGates[qubit][column];
        if (gate.gate.type == SelectedGateType.none) continue;
        gates.add(_adaptiveGateSignature(qubit, gate));
      }
      if (gates.isNotEmpty) columns.add(gates.join('+'));
    }
    return columns.isEmpty ? 'empty' : columns.join('|');
  }

  String _adaptiveGateSignature(int qubit, PlacedQuantumGate gate) {
    final role = gate.isControl
        ? 'control'
        : gate.isControl2
            ? 'control2'
            : gate.isTarget
                ? 'target'
                : gate.isLink
                    ? 'link'
                    : 'single';
    final control =
        gate.controlQubitIndex == null ? '' : ':c${gate.controlQubitIndex}';
    final target =
        gate.targetQubitIndex == null ? '' : ':t${gate.targetQubitIndex}';
    return 'q$qubit:${gate.gate.type.name}:$role$control$target';
  }

  Map<SelectedGateType, int> _adaptiveGateCounts() {
    final counts = <SelectedGateType, int>{};
    for (final line in _circuit.placedGates) {
      for (final placedGate in line) {
        final type = placedGate.gate.type;
        if (type == SelectedGateType.none) continue;
        if (placedGate.isLink) continue;
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }
    return counts;
  }

  void _showConceptIntro(String intro) {
    showDialog(
      context: context,
      builder: (ctx) => QubitQuestDialog(
        title: 'Before You Start',
        actions: [
          QubitQuestDialogButton.primary(
            label: 'Got it',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
        child: Text(
          intro,
          style: const TextStyle(
            color: Color(0xFFD6E3F8),
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showNextHint() {
    final nextIndex = _currentHintIndex + 1;
    if (nextIndex >= _hints.length) return;
    setState(() => _currentHintIndex = nextIndex);
    showDialog(
      context: context,
      builder: (ctx) => QubitQuestDialog(
        title: 'Hint ${nextIndex + 1} / ${_hints.length}',
        actions: [
          QubitQuestDialogButton.primary(
            label: 'OK',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: QubitQuestDialog.innerColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: QubitQuestDialog.borderSoftColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              _hints[nextIndex],
              style: const TextStyle(
                color: Color(0xFFD6E3F8),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearCircuit() {
    final outcome = _circuit.clearPlacedGatesWithOutcome();
    if (!outcome.changed) {
      _handleCommittedCircuitEdit(outcome, clearSelection: true);
      return;
    }
    debugPrint('Circuit cleared.');
    _setInteractionMode(SelectedGateType.none); // Reset mode
    _cnotControlQubit = null;
    _ccnotControl1Qubit = null;
    _ccnotControl2Qubit = null;
    _levelSolved = false;
    _checkFeedbackTitle = null;
    _checkFeedbackMessage = null;
    _adaptiveInsight = null;
    _adaptiveInsightDismissed = false;
    _adaptiveInsightAutoDismissTimer?.cancel();
    _handleCommittedCircuitEdit(outcome, clearSelection: true);
  }

  Future<void> _openQuantumNotebook() async {
    _adaptiveLearningSession.recordNotebookOpened();
    final entry = _notebookEntryForLevel();
    final unlocked = await DiscoveryProgress.loadUnlocked();
    if (!mounted) return;

    setState(() {
      _hasUnopenedNotebookEntries = false;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          if (entry != null && unlocked.contains(entry.discoveryTitle)) {
            return NotebookEntryScreen(entry: entry);
          }
          return const DiscoveriesScreen();
        },
      ),
    );
  }

  void _openGateNotebook(NotebookEntry entry) {
    _adaptiveLearningSession.recordNotebookOpened();
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NotebookEntryScreen(entry: entry),
      ),
    );
  }

  void _openInspectorRelatedConcept(String discoveryTitle) {
    final entry = notebookEntriesByDiscoveryTitle[discoveryTitle];
    if (entry != null) _openGateNotebook(entry);
  }

  Future<void> _inspectSelectedGate() async {
    final selected = _selectedGateId;
    if (selected == null) return;
    final footprint = _circuit.logicalGateById(selected);
    if (footprint == null) {
      if (mounted) setState(_validateSelection);
      return;
    }
    final info = GateEducationalCatalog.forType(footprint.type);
    final notebookTitle = info?.notebookDiscoveryTitle;
    final notebook = notebookTitle == null
        ? null
        : notebookEntriesByDiscoveryTitle[notebookTitle];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => GateInspectorDialog(
        footprint: footprint,
        info: info,
        onOpenNotebook:
            notebook == null ? null : () => _openGateNotebook(notebook),
        onOpenRelatedConcept: _openInspectorRelatedConcept,
      ),
    );
  }

  void _selectComposerMenuAction(String action) {
    switch (action) {
      case 'matrix':
        _showOperatorMatrixDialog();
        break;
      case 'notebook':
        _openQuantumNotebook();
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

  void _onDragEnter(Offset offset, CircuitDragData data) {
    if (data.isPlaced) {
      final source = _circuit.logicalGateById(data.sourceId!);
      if (source == null || !source.isMovable) {
        setState(_onDragLeaveStateOnly);
        return;
      }
    }
    final localPosition = _gatePositionToContent(offset);
    if (localPosition == null) {
      debugPrint('Error: Could not convert global position to local.');
      return;
    }
    final rawDestination = CircuitGeometry.dropDestinationForPoint(
      circuit: _circuit,
      contentPoint: localPosition,
    );
    var destination = rawDestination == null
        ? null
        : _logicalMoveDestination(rawDestination, data);
    final movePlan = data.isPlaced && destination != null
        ? _circuit.planLogicalGateMove(data.sourceId!, destination.location)
        : null;
    if (movePlan != null && !_isValidMovePlan(movePlan)) {
      destination = null;
    }
    setState(() {
      _latestCircuitDragGlobalPosition = offset;
      _draggingOffset = localPosition;
      _draggingDestination = destination;
      _draggingMovePlan = movePlan;
      _draggingGate = data.gate;
    });
  }

  void _refreshCircuitDragDestinationAfterScroll() {
    final pointer = _latestCircuitDragGlobalPosition;
    if (!mounted ||
        pointer == null ||
        _draggingGate.type == SelectedGateType.none) {
      return;
    }
    final contentPosition = _gatePositionToContent(pointer);
    if (contentPosition == null) return;
    final rawDestination = CircuitGeometry.dropDestinationForPoint(
      circuit: _circuit,
      contentPoint: contentPosition,
    );
    final dragData = _activeDragData;
    var destination = dragData == null
        ? rawDestination
        : rawDestination == null
            ? null
            : _logicalMoveDestination(rawDestination, dragData);
    final movePlan = dragData?.isPlaced == true && destination != null
        ? _circuit.planLogicalGateMove(
            dragData!.sourceId!,
            destination.location,
          )
        : null;
    if (movePlan != null && !_isValidMovePlan(movePlan)) {
      destination = null;
    }
    setState(() {
      _draggingOffset = contentPosition;
      _draggingDestination = destination;
      _draggingMovePlan = movePlan;
    });
  }

  void _onDragLeave() {
    setState(() {
      _onDragLeaveStateOnly();
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
    final position = _gatesScrollController.position;
    final target = (position.pixels + offset).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _gatesScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollLeft() {
    if (!_gatesScrollController.hasClients) return;
    double scrollAmount = _gatesScrollController.position.viewportDimension;
    _scroll(-scrollAmount);
  }

  void _scrollRight() {
    if (!_gatesScrollController.hasClients) return;
    double scrollAmount = _gatesScrollController.position.viewportDimension;
    _scroll(scrollAmount);
  }

  @override
  Widget build(BuildContext context) {
    final bool compactAppBar = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
        backgroundColor: qqBlack,
        appBar: LevelHeaderRouter.headerFor(
          level: widget.level,
          levelId: widget.levelId,
          compact: compactAppBar,
          title: runningAsQuantumComposer()
              ? 'Composer'
              : LevelHeaderRouter.displayLabel(widget.levelId),
          subtitle: runningAsQuantumComposer() ? '' : _goalTitle(),
          isCompleted: _isCompleted,
          actions: _buildAppBarActions(compactAppBar),
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final bool compact = constraints.maxWidth < 720;
            final bool short = constraints.maxHeight < 560;
            final Widget circuitCard = _buildCircuitCard(
              compact: short,
              showHeader: false,
            );
            final Widget statePanel = _buildPortraitStateSection(short: short);
            final double contentTopPadding = short ? 3 : 5;
            final double contentBottomPadding = short ? 6 : (compact ? 8 : 10);
            final double contentHeight = math.max(
              0,
              constraints.maxHeight - contentTopPadding - contentBottomPadding,
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 16,
                contentTopPadding,
                compact ? 12 : 16,
                contentBottomPadding,
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
                        : _buildLandscapeComposerLayout(
                            circuitCard: circuitCard,
                            short: short,
                            availableHeight: contentHeight,
                          ),
                  ),
                ],
              ),
            );
          }),
        ));
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
    const double sectionGap = 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool composer = runningAsQuantumComposer();
        final metrics = CircuitCanvasMetrics.calculate(
          qubitCount: _numQubits,
          orientation: Orientation.portrait,
          availableHeight: constraints.maxHeight,
          cardPadding: _circuitCardPadding(compact: short),
        );
        final Widget circuitSection = SizedBox(
          height: metrics.height,
          child: circuitCard,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!composer) ...[
              _buildPortraitGoalSection(short: short),
              const SizedBox(height: sectionGap),
            ],
            circuitSection,
            const SizedBox(height: sectionGap),
            _buildGatePalette(compact: true, dense: true),
            const SizedBox(height: sectionGap),
            Expanded(child: statePanel),
            if (!composer) ...[
              const SizedBox(height: sectionGap),
              _buildPortraitCheckArea(compact: short),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPortraitStateSection({required bool short}) {
    final List<Complex>? targetStateVector =
        runningAsQuantumComposer() ? null : _targetStateVector();
    final String? targetExpression = _targetStateDisplayExpression();

    if (targetStateVector == null) {
      return _buildStatePanel(
        summaryTitle: 'Current State',
        tone: StateVectorDisplayTone.current,
        showHeader: false,
        showToggleInSummary: true,
        showSummarySubtitle: false,
        dense: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildStatePanel(
            summaryTitle: 'Current State',
            tone: StateVectorDisplayTone.current,
            showHeader: false,
            showToggleInSummary: true,
            showSummarySubtitle: false,
            showVisibilityControl: false,
            nonZeroOnly: _sharedNonZeroOnly,
            visibilityControl: _buildSharedStateFilterControl(),
            dense: true,
          ),
        ),
        SizedBox(height: short ? 6 : 8),
        Expanded(
          child: _buildStatePanel(
            stateVector: targetStateVector,
            summaryTitle: 'Target State',
            stateExpression: targetExpression,
            tone: StateVectorDisplayTone.target,
            showHeader: false,
            showToggleInSummary: true,
            showSummarySubtitle: false,
            showVisibilityControl: false,
            nonZeroOnly: _sharedNonZeroOnly,
            dense: true,
          ),
        ),
      ],
    );
  }

  String? _targetStateDisplayExpression() {
    final String? expression = widget.level.targetStateExpression?.trim();
    if (expression == null || expression.isEmpty) {
      return null;
    }
    if (expression.contains('=')) {
      return expression;
    }

    final String? label = widget.level.targetStateLabel?.trim();
    final String leftSide = label == null || label.isEmpty ? '|ψ⟩' : label;

    return '$leftSide = $expression';
  }

  Widget _buildSharedStateFilterControl() {
    return InkWell(
      onTap: () {
        setState(() => _sharedNonZeroOnly = !_sharedNonZeroOnly);
      },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.52,
            child: Checkbox(
              value: _sharedNonZeroOnly,
              onChanged: (value) {
                setState(() => _sharedNonZeroOnly = value ?? false);
              },
              activeColor: qqCyan,
              checkColor: Colors.black,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.54),
                width: 1,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Text(
            'Non-zero only',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeComposerLayout({
    required Widget circuitCard,
    required bool short,
    required double availableHeight,
  }) {
    final double gap = short ? 6 : 10;
    final double toolbarHeight = short ? 76 : 116;
    final double actionHeight = _landscapeActionHeight(short: short);
    final List<Complex>? targetStateVector =
        runningAsQuantumComposer() ? null : _targetStateVector();
    final bool showGoal = !runningAsQuantumComposer();
    final double goalHeight = showGoal ? (short ? 58 : 68) : 0;
    final double circuitAvailableHeight = math.max(
      0,
      availableHeight - toolbarHeight - gap - (showGoal ? goalHeight + gap : 0),
    );
    final metrics = CircuitCanvasMetrics.calculate(
      qubitCount: _numQubits,
      orientation: Orientation.landscape,
      availableHeight: circuitAvailableHeight,
      cardPadding: _circuitCardPadding(compact: short),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 68,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showGoal) ...[
                SizedBox(
                  height: goalHeight,
                  child: _buildGoalBanner(compact: short),
                ),
                SizedBox(height: gap),
              ],
              SizedBox(
                height: metrics.height,
                child: circuitCard,
              ),
              SizedBox(height: gap),
              SizedBox(
                height: toolbarHeight,
                child: _buildGatePalette(compact: false, dense: short),
              ),
            ],
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 32,
          child: _buildLandscapeResultColumn(
            targetStateVector: targetStateVector,
            actionHeight: actionHeight,
            gap: gap,
            short: short,
          ),
        ),
      ],
    );
  }

  double _landscapeActionHeight({required bool short}) {
    if (runningAsQuantumComposer()) {
      return 0;
    }
    if (_adaptiveInsight != null && !_adaptiveInsightDismissed) {
      return short ? 176 : 196;
    }
    if (_checkFeedbackTitle != null) {
      return short ? 98 : 108;
    }
    return short ? 40 : 44;
  }

  Widget _buildLandscapeResultColumn({
    required List<Complex>? targetStateVector,
    required double actionHeight,
    required double gap,
    required bool short,
  }) {
    final bool hasTargetState = targetStateVector != null;
    final String? targetExpression = _targetStateDisplayExpression();
    final Widget currentStatePanel = _buildStatePanel(
      summaryTitle: 'Current State',
      tone: StateVectorDisplayTone.current,
      showHeader: false,
      showToggleInSummary: true,
      showSummarySubtitle: false,
      showVisibilityControl: !hasTargetState,
      nonZeroOnly: hasTargetState ? _sharedNonZeroOnly : null,
      visibilityControl:
          hasTargetState ? _buildSharedStateFilterControl() : null,
      dense: true,
    );
    final Widget? targetStatePanel = targetStateVector == null
        ? null
        : _buildStatePanel(
            stateVector: targetStateVector,
            summaryTitle: 'Target State',
            stateExpression: targetExpression,
            tone: StateVectorDisplayTone.target,
            showHeader: false,
            showToggleInSummary: true,
            showSummarySubtitle: false,
            showVisibilityControl: false,
            nonZeroOnly: _sharedNonZeroOnly,
            dense: true,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: currentStatePanel),
        if (targetStatePanel != null) ...[
          SizedBox(height: gap),
          Expanded(child: targetStatePanel),
        ],
        if (actionHeight > 0) ...[
          SizedBox(height: gap),
          SizedBox(
            height: actionHeight,
            child: _buildCheckActionArea(compact: short),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildAppBarActions(bool compact) {
    return [
      if (_selectedGateId != null) ...[
        _buildInspectGateHeaderAction(compact: compact),
        SizedBox(width: compact ? 6 : 8),
      ],
      if (_selectedGateId != null &&
          (_circuit.logicalGateById(_selectedGateId!)?.isEditable ?? false) &&
          _circuit.availableSingleQubitReplacementTypes.any(
            (type) => type != _circuit.logicalGateById(_selectedGateId!)?.type,
          )) ...[
        _buildReplaceGateHeaderAction(compact: compact),
        SizedBox(width: compact ? 6 : 8),
      ],
      if (_selectedGateId != null &&
          (_circuit.logicalGateById(_selectedGateId!)?.isParameterEditable ??
              false)) ...[
        _buildEditAngleHeaderAction(compact: compact),
        SizedBox(width: compact ? 6 : 8),
      ],
      if (_selectedGateId != null &&
          _circuit.canDuplicateLogicalGate(_selectedGateId!)) ...[
        _buildDuplicateGateHeaderAction(compact: compact),
        SizedBox(width: compact ? 6 : 8),
      ],
      _buildNotebookHeaderAction(compact: compact),
      SizedBox(width: compact ? 6 : 8),
      _buildMenuHeaderAction(compact: compact),
      SizedBox(width: compact ? 10 : 12),
    ];
  }

  Widget _buildInspectGateHeaderAction({required bool compact}) {
    final content = compact
        ? const _HeaderActionShell(
            size: 34,
            child: Icon(Icons.info_outline_rounded, size: 18, color: qqCyan),
          )
        : SizedBox(
            width: 52,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _HeaderActionShell(
                  size: 32,
                  child:
                      Icon(Icons.info_outline_rounded, size: 17, color: qqCyan),
                ),
                const SizedBox(height: 2),
                Text(
                  'Inspect',
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
    return Semantics(
      label: 'Inspect gate',
      button: true,
      child: Tooltip(
        message: 'Inspect gate',
        child: InkWell(
          key: const ValueKey('inspect-selected-gate'),
          onTap: _inspectSelectedGate,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      ),
    );
  }

  Widget _buildReplaceGateHeaderAction({required bool compact}) {
    final content = compact
        ? _HeaderActionShell(
            size: 34,
            child: Icon(Icons.swap_horiz_rounded, size: 19, color: qqPurple),
          )
        : SizedBox(
            width: 54,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderActionShell(
                  size: 32,
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: qqPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Replace',
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
    return Semantics(
      label: 'Replace gate',
      button: true,
      child: Tooltip(
        message: 'Replace gate',
        child: InkWell(
          key: const ValueKey('replace-selected-gate'),
          onTap: _replaceSelectedGate,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      ),
    );
  }

  Widget _buildEditAngleHeaderAction({required bool compact}) {
    final content = compact
        ? _HeaderActionShell(
            size: 34,
            child: Icon(Icons.tune_rounded, size: 18, color: qqCyan),
          )
        : SizedBox(
            width: 62,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderActionShell(
                  size: 32,
                  child: Icon(Icons.tune_rounded, size: 17, color: qqCyan),
                ),
                const SizedBox(height: 2),
                Text(
                  'Edit angle',
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
    return Semantics(
      label: 'Edit angle',
      button: true,
      child: Tooltip(
        message: 'Edit angle',
        child: InkWell(
          key: const ValueKey('edit-selected-gate-angle'),
          onTap: _editSelectedRotationAngle,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      ),
    );
  }

  Widget _buildDuplicateGateHeaderAction({required bool compact}) {
    final content = compact
        ? _HeaderActionShell(
            size: 34,
            child: Icon(Icons.copy_rounded, size: 17, color: qqCyan),
          )
        : SizedBox(
            width: 58,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderActionShell(
                  size: 32,
                  child: Icon(Icons.copy_rounded, size: 16, color: qqCyan),
                ),
                const SizedBox(height: 2),
                Text(
                  'Duplicate',
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
    return Semantics(
      label: 'Duplicate gate',
      button: true,
      child: Tooltip(
        message: 'Duplicate gate',
        child: InkWell(
          key: const ValueKey('duplicate-selected-gate'),
          onTap: _duplicateSelectedGate,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      ),
    );
  }

  Widget _buildMenuHeaderAction({required bool compact}) {
    final menuButton = PopupMenuButton<String>(
      tooltip: 'Menu',
      color: qqCard,
      offset: const Offset(0, 10),
      onSelected: _selectComposerMenuAction,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'matrix',
          child: ListTile(
            leading: Icon(Icons.grid_on, color: Colors.white),
            title: Text(
              'Operator Matrix',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'clear',
          child: ListTile(
            leading: Icon(Icons.cleaning_services, color: Colors.white),
            title: Text(
              'Clear',
              style: TextStyle(color: Colors.white),
            ),
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
              title: Text(
                _currentHintIndex < 0
                    ? 'Hint'
                    : 'Hint ${_currentHintIndex + 1}/${_hints.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
      child: _HeaderActionShell(
        size: compact ? 34 : 32,
        child: Icon(
          Icons.settings_outlined,
          size: compact ? 18 : 17,
          color: Colors.white.withValues(alpha: 0.94),
        ),
      ),
    );

    if (compact) return menuButton;

    return SizedBox(
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          menuButton,
          const SizedBox(height: 2),
          Text(
            'Menu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 9,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotebookHeaderAction({required bool compact}) {
    return Tooltip(
      message: 'Quantum Notebook',
      child: ScaleTransition(
        scale: _notebookPulseScale,
        child: InkWell(
          onTap: _openQuantumNotebook,
          borderRadius: BorderRadius.circular(16),
          child: compact
              ? _NotebookAttentionBadge(
                  visible: _hasUnopenedNotebookEntries,
                  child: _HeaderActionShell(
                    child: Icon(
                      Icons.school_outlined,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
                  ),
                )
              : SizedBox(
                  width: 54,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NotebookAttentionBadge(
                        visible: _hasUnopenedNotebookEntries,
                        child: _HeaderActionShell(
                          size: 32,
                          child: Icon(
                            Icons.school_outlined,
                            size: 17,
                            color: Colors.white.withValues(alpha: 0.94),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Notebook',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 9,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  bool runningAsQuantumComposer() => widget.levelId == -1;

  String _goalTitle() {
    if (runningAsQuantumComposer()) {
      return 'Composer';
    }
    return widget.level.title ?? LevelHeaderRouter.displayLabel(widget.levelId);
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

  void _showComposerIntro() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return QubitQuestDialog(
          title: 'Composer',
          actions: [
            QubitQuestDialogButton.primary(
              label: 'Start Composing',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          child: Text(
            _taskDescription,
            style: const TextStyle(
              color: Color(0xFFD6E3F8),
              fontSize: 14,
              height: 1.42,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
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
        border: Border.all(color: qqComposerCardBorder.color),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: _circuitCardPadding(compact: compact),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            _buildCircuitSurfaceHeader(
              compact: compact,
              isDraggingGate: isDraggingGate,
            ),
            SizedBox(height: compact ? 5 : 7),
          ],
          Expanded(child: _buildCircuitDragTarget()),
        ],
      ),
    );
  }

  EdgeInsets _circuitCardPadding({required bool compact}) {
    return EdgeInsets.fromLTRB(
      compact ? 8 : 12,
      compact ? 6 : 9,
      compact ? 8 : 12,
      compact ? 6 : 10,
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
                        : LevelHeaderRouter.displayLabel(widget.levelId),
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
        borderRadius: BorderRadius.circular(10),
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
          color: checkSurfaceBorder.withValues(alpha: 0.86),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: checkSurfaceBottom.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
        label: const Text('Check Result'),
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
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
        SizedBox(
          height: compact ? 32 : 34,
          child: _buildCheckResultButton(compact: true),
        ),
        if (_checkFeedbackTitle != null) ...[
          SizedBox(height: compact ? 5 : 6),
          _buildCheckFeedbackBanner(compact: compact),
        ],
        if (_adaptiveInsight != null && !_adaptiveInsightDismissed) ...[
          SizedBox(height: compact ? 5 : 6),
          _buildAdaptiveLearningCard(compact: compact),
        ],
      ],
    );
  }

  Widget _buildCheckActionArea({required bool compact}) {
    if (runningAsQuantumComposer()) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: compact ? 40 : 44,
          child: _buildCheckResultButton(compact: compact),
        ),
        if (_checkFeedbackTitle != null) ...[
          SizedBox(height: compact ? 6 : 8),
          _buildCheckFeedbackBanner(compact: compact),
        ],
        if (_adaptiveInsight != null && !_adaptiveInsightDismissed) ...[
          SizedBox(height: compact ? 6 : 8),
          _buildAdaptiveLearningCard(compact: compact),
        ],
      ],
    );
  }

  Widget _buildAdaptiveLearningCard({required bool compact}) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: compact ? 108 : 148,
      ),
      child: AdaptiveLearningCard(
        insight: _adaptiveInsight!,
        compact: compact,
        onReviewNotebook: _openQuantumNotebook,
        onDismiss: _dismissAdaptiveInsight,
      ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _captureCircuitViewportBounds();
    });
    final bool isDraggingGate = _draggingOffset != null &&
        _draggingGate.type != SelectedGateType.none &&
        _draggingGate.type != SelectedGateType.delete;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: const Color(0xFF020713),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: qqComposerInnerBorder.color),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
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
        final double minRequiredWidth = CircuitGeometry.contentWidth(_circuit);

        final double sizedBoxWidth =
            max(minRequiredWidth, availableContainerWidth);
        final double sizedBoxHeight =
            QuantumCircuitPainter.requiredDrawingHeightFor(_numQubits);
        final double viewportHeight =
            max(sizedBoxHeight, constraints.maxHeight);
        final bool circuitIsEmpty = _circuit.isCircuitEmpty();
        debugPrint(
            "  Calculated SizedBox size: Size($sizedBoxWidth, $sizedBoxHeight)");

        return DragTarget<CircuitDragData>(
          onAcceptWithDetails: (details) async {
            await _handleGateDrop(details);
            _onDragLeave();
          },
          onLeave: (data) {
            _onDragLeave();
          },
          onMove: (data) {
            _onDragEnter(data.offset, data.data);
          },
          onWillAcceptWithDetails: (details) {
            _onDragEnter(details.offset, details.data);
            bool isNotDelete =
                details.data.gate.type != SelectedGateType.delete;
            return isNotDelete;
          },
          builder: (context, candidateData, rejectedData) {
            return KeyedSubtree(
              key: const ValueKey('circuit-interaction-surface'),
              child: GestureDetector(
                key: _gestureDetectorKey,
                onTapDown: _handleCircuitTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SingleChildScrollView(
                      key: const ValueKey('circuit-horizontal-scroll'),
                      controller: _circuitScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: sizedBoxWidth,
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
                                destination: _draggingDestination,
                              ),
                            ),
                            CustomPaint(
                              painter: QuantumCircuitPainter(
                                _circuit,
                                previewGates: isDraggingGate &&
                                        _draggingDestination != null
                                    ? _buildCircuitDragPreview()
                                    : null,
                                selectedGateId: _selectedGateId,
                                ghostedGateId: _activeDragData?.isPlaced == true
                                    ? _activeDragData!.sourceId
                                    : null,
                                highlightedQubit:
                                    _draggingDestination?.location.qubit,
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
                              Align(
                                alignment: const Alignment(0, -0.42),
                                child: _EmptyCircuitPrompt(
                                    isDragging: isDraggingGate),
                              ),
                            ..._buildPlacedGateDragOverlays(),
                          ],
                        ),
                      ),
                    ),
                    if (_placedDragOutsideCircuit &&
                        (_activeDragData?.isPlaced ?? false))
                      const Positioned(
                        right: 12,
                        top: 10,
                        child: _ReleaseToRemovePill(),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  List<Widget> _buildPlacedGateDragOverlays() {
    final draggableGates =
        _circuit.logicalGates.where((gate) => gate.isDeletable);

    return draggableGates.map((footprint) {
      final placed = footprint.toPlacedGateRef();
      final bounds = CircuitGeometry.logicalGateBounds(_circuit, placed.id);
      if (bounds == null) return const SizedBox.shrink();
      final isSelected = placed.id == _selectedGateId;
      final isControlled = !placed.isSingleQubit;
      return Positioned.fromRect(
        rect: bounds.inflate(5),
        child: Listener(
          onPointerDown: (event) => _capturePlacedDragOrigin(event, footprint),
          onPointerMove: (event) => _updatePlacedDragPosition(event.position),
          onPointerCancel: (_) => _placedDragWasCancelled = true,
          child: Semantics(
            label: isSelected
                ? 'Selected gate ${placed.gate.label}'
                : 'Gate ${placed.gate.label}',
            hint: isControlled
                ? 'Drag to move. Drag outside circuit to remove.'
                : 'Drag to move. Drag outside circuit to remove.',
            child: Draggable<CircuitDragData>(
              key: ValueKey('placed-gate-drag-${placed.id.value}'),
              data: CircuitDragData.placed(
                sourceId: placed.id,
                gate: placed.gate,
              ),
              dragAnchorStrategy: pointerDragAnchorStrategy,
              onDragStarted: () => _startPlacedDrag(placed),
              onDragUpdate: (details) =>
                  _updatePlacedDragPosition(details.globalPosition),
              onDragCompleted: _finishPlacedDrag,
              onDraggableCanceled: (velocity, offset) =>
                  _handlePlacedDragCancelled(placed),
              feedback: const SizedBox(
                key: ValueKey('placed-drag-transparent-feedback'),
                width: 1,
                height: 1,
              ),
              childWhenDragging: const SizedBox.expand(),
              child: Tooltip(
                message: isSelected
                    ? isControlled
                        ? 'Selected gate • Drag to move'
                        : 'Selected gate • Drag to move'
                    : isControlled
                        ? 'Drag gate to move'
                        : 'Drag gate to move',
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<List<PlacedQuantumGate>>? _buildCircuitDragPreview() {
    final destination = _draggingDestination;
    if (destination == null) return null;
    final dragData = _activeDragData;
    if (dragData?.isPlaced ?? false) {
      return _draggingMovePlan?.proposedRows;
    }
    return CircuitGeometry.insertionPreview(
      circuit: _circuit,
      destination: destination,
      gate: _draggingGate,
    );
  }

  Widget _buildPaletteUtilityButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required bool dense,
  }) {
    final Color foreground = onPressed == null
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.78);

    return IconButton(
      key: key,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: dense ? 18 : 24,
        height: dense ? 20 : 24,
      ),
      iconSize: dense ? 15 : 17,
      color: foreground.withValues(alpha: dense ? 0.70 : 0.84),
      disabledColor: Colors.white.withValues(alpha: 0.28),
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: dense ? 15 : 16,
    );
  }

  Widget _buildGatePalette({required bool compact, required bool dense}) {
    final Widget gateRow = Row(
      children: [
        _buildPaletteUtilityButton(
          key: const ValueKey('palette-scroll-left'),
          icon: Icons.chevron_left_rounded,
          tooltip: 'Scroll gates left',
          onPressed: _canScrollLeft ? _scrollLeft : null,
          dense: dense,
        ),
        SizedBox(width: dense ? 0 : 1),
        Expanded(
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: 0.24),
              ),
              trackVisibility: const WidgetStatePropertyAll(false),
            ),
            child: Scrollbar(
              key: const ValueKey('gate-palette-scrollbar'),
              controller: _gatesScrollController,
              thumbVisibility: true,
              thickness: 2,
              radius: const Radius.circular(99),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _gatesScrollController,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ..._availableGates.map((gateType) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: dense ? 1.0 : 2.0,
                          ),
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
        ),
        SizedBox(width: dense ? 0 : 1),
        _buildPaletteUtilityButton(
          key: const ValueKey('palette-scroll-right'),
          icon: Icons.chevron_right_rounded,
          tooltip: 'Scroll gates right',
          onPressed: _canScrollRight ? _scrollRight : null,
          dense: dense,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool hasBoundedHeight = constraints.hasBoundedHeight;

        return Container(
          padding: EdgeInsets.fromLTRB(4, dense ? 4 : 8, 4, dense ? 4 : 9),
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
              SizedBox(
                height: dense ? 18 : 34,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Gates",
                    style: TextStyle(
                      fontSize: dense ? 11.5 : 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: dense ? 0 : 3),
              if (hasBoundedHeight)
                Flexible(
                  fit: FlexFit.loose,
                  child: gateRow,
                )
              else
                gateRow,
            ],
          ),
        );
      },
    );
  }

  List<Complex> _targetStateVector() {
    return _solutionVector.map((col) => col.first).toList();
  }

  Widget _buildStatePanel({
    bool secondary = false,
    List<Complex>? stateVector,
    List<Complex>? targetStateVector,
    String? title,
    String? summaryTitle,
    String? summarySubtitle,
    String? stateExpression,
    StateVectorDisplayTone tone = StateVectorDisplayTone.current,
    bool showHeader = true,
    bool showToggleInSummary = false,
    bool showSummarySubtitle = true,
    bool showVisibilityControl = true,
    bool? nonZeroOnly,
    Widget? visibilityControl,
    bool dense = false,
  }) {
    return Container(
      padding: EdgeInsets.all(dense ? 4.0 : (secondary ? 5.0 : 7.0)),
      decoration: BoxDecoration(
        color: secondary ? qqCard.withValues(alpha: 0.78) : qqCard,
        borderRadius: BorderRadius.circular(secondary ? 10.0 : 12.0),
        border: Border.all(
          color: secondary
              ? qqComposerInnerBorder.color
              : qqComposerCardBorder.color,
          width: qqComposerCardBorder.width,
        ),
      ),
      child: StateVectorDisplay(
        stateVector: stateVector ?? _circuit.currentState.stateVector,
        numQubits: _numQubits,
        targetStateVector: targetStateVector,
        titleOverride: title,
        summaryTitleOverride: summaryTitle,
        summarySubtitleOverride: summarySubtitle,
        stateExpression: stateExpression,
        tone: tone,
        showHeader: showHeader,
        showToggleInSummary: showToggleInSummary,
        showSummarySubtitle: showSummarySubtitle,
        showVisibilityControl: showVisibilityControl,
        nonZeroOnlyOverride: nonZeroOnly,
        visibilityControlOverride: visibilityControl,
        dense: dense,
      ),
    );
  }

  Widget _buildDraggableGateButton(Gate gate, {bool dense = false}) {
    double fontSizeW;
    if (gate.type == SelectedGateType.ccnot) {
      fontSizeW = dense ? 11 : 14;
    } else if ((gate.type == SelectedGateType.rx ||
            gate.type == SelectedGateType.ry ||
            gate.type == SelectedGateType.rz) &&
        gate.angle != null) {
      fontSizeW = dense ? 8.5 : 10;
    } else {
      fontSizeW = dense ? 14 : 18;
    }

    final double buttonSize = dense ? 38 : 52;
    return Draggable<CircuitDragData>(
      // Draggable for Hadamard
      data: CircuitDragData.palette(gate), // Data carried by the drag
      feedback: Material(
        color: Colors.transparent,
        child: QubitQuestGateTile(
          gate: gate,
          size: buttonSize,
          fontSize: fontSizeW,
          onPressed: null,
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
  Widget build(BuildContext context) => QubitQuestGateTile(
        gate: gate,
        size: buttonSize,
        fontSize: fontSize,
        onPressed: onPressed,
      );
}

class _ReleaseToRemovePill extends StatelessWidget {
  const _ReleaseToRemovePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('release-to-remove'),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5350).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFEF5350).withValues(alpha: 0.72),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Color(0xFFFFB4B1), size: 14),
            SizedBox(width: 5),
            Text(
              'Release to remove',
              style: TextStyle(
                color: Color(0xFFFFDAD8),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
              isDragging ? Icons.add_circle_outline : Icons.touch_app_outlined,
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
    );
  }
}

class _HeaderActionShell extends StatelessWidget {
  final Widget child;
  final double size;

  const _HeaderActionShell({
    required this.child,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _QuantumComposerState.qqCard2,
        shape: BoxShape.circle,
        border: Border.all(
          color: _QuantumComposerState.qqComposerCardBorder.color,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _NotebookAttentionBadge extends StatelessWidget {
  const _NotebookAttentionBadge({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (visible)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _QuantumComposerState.qqYellow,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _QuantumComposerState.qqBlack,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MasteryChallengeCompletionBody extends StatefulWidget {
  const _MasteryChallengeCompletionBody({
    required this.challengeTitle,
    required this.keyInsight,
    required this.solutionExplanation,
  });

  final String challengeTitle;
  final String keyInsight;
  final String? solutionExplanation;

  @override
  State<_MasteryChallengeCompletionBody> createState() =>
      _MasteryChallengeCompletionBodyState();
}

class _MasteryChallengeCompletionBodyState
    extends State<_MasteryChallengeCompletionBody> {
  bool _showFullSolution = false;

  @override
  Widget build(BuildContext context) {
    final fullSolution = widget.solutionExplanation?.trim();
    final hasFullSolution = fullSolution != null && fullSolution.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: QubitQuestDialog.cyan.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: QubitQuestDialog.cyan.withValues(alpha: 0.32),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: QubitQuestDialog.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: QubitQuestDialog.borderColor),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: QubitQuestDialog.cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.challengeTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Solved. You can review the completed circuit or continue to the next challenge.',
                        style: TextStyle(
                          color: QubitQuestDialog.mutedText,
                          fontSize: 13,
                          height: 1.32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Key Insight',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: QubitQuestDialog.innerColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: QubitQuestDialog.borderSoftColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.keyInsight,
              style: const TextStyle(
                color: Color(0xFFD6E3F8),
                fontSize: 14,
                height: 1.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (hasFullSolution) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: QubitQuestDialog.cyan,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onPressed: () {
                setState(() {
                  _showFullSolution = !_showFullSolution;
                });
              },
              icon: Icon(
                _showFullSolution
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
              ),
              label: Text(
                _showFullSolution ? 'Hide Full Solution' : 'View Full Solution',
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: DecoratedBox(
              decoration: BoxDecoration(
                color: QubitQuestDialog.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: QubitQuestDialog.borderSoftColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  fullSolution,
                  style: const TextStyle(
                    color: Color(0xFFD6E3F8),
                    fontSize: 13,
                    height: 1.42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            crossFadeState: _showFullSolution
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ],
    );
  }
}

class _CircuitGuidePainter extends CustomPainter {
  final int numQubits;
  final int columns;
  final bool isDragging;
  final CircuitDropDestination? destination;

  const _CircuitGuidePainter({
    required this.numQubits,
    required this.columns,
    required this.isDragging,
    required this.destination,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint lanePaint = Paint()
      ..color = _QuantumComposerState.qqInner2.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final Paint depthGuidePaint = Paint()
      ..color = _QuantumComposerState.qqCyan.withValues(alpha: 0.025)
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

    final activeQubit = destination?.location.qubit;
    final activeColumn = destination?.location.column;

    if (isDragging) {
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
    }

    for (int qubit = 0; qubit < numQubits; qubit++) {
      final double centerY = QuantumCircuitPainter.qubitCenterYFor(qubit);
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

  @override
  bool shouldRepaint(covariant _CircuitGuidePainter oldDelegate) {
    return oldDelegate.numQubits != numQubits ||
        oldDelegate.columns != columns ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.destination != destination;
  }
}
