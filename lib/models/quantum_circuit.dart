import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart'; // Import this for ChangeNotifier
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart'; // Import PlacedQuantumGate
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/qubit_state.dart'; // Assuming you have this class
import 'package:quantumquiz/models/selected_gate_type.dart';

// Make QuantumCircuit extend ChangeNotifier
class QuantumCircuit extends ChangeNotifier {
  // List to store the placed gate instances that define the circuit structure
  List<List<PlacedQuantumGate>> placedGates;

  // The number of qubits in the circuit (assuming fixed)
  final QQLevel currentLevel;
  // final List<Complex> initialQubitsState;
  // Property to hold the current/final quantum state vector (updated by simulation)
  final QubitState initialState;
  QubitState currentState;

  // Constructor
  QuantumCircuit._internal({required this.currentLevel}):
  // Initialize the currentState to the ground state |00...0>
  // Assuming QubitState has a constructor or static method to create the initial state
        initialState = QubitState.fromList(currentLevel.initialQubitsState),
        currentState = QubitState.fromList(currentLevel.initialQubitsState),
        placedGates = List.generate(currentLevel.numQubits, (index) => []);

  factory QuantumCircuit({required QQLevel currentLevel}) {
    var quantumCircuit = QuantumCircuit._internal(currentLevel: currentLevel);
    currentLevel.preInsertGates(quantumCircuit);
    return quantumCircuit;
  }

  int maxCircuitDepth() => placedGates.map((e) => e.length).reduce(max);

  bool isCircuitEmpty() => maxCircuitDepth() == 0;

  // New method to insert a placed gate at a specific position
  void insertSinglePlacedGateAt(SelectedGateType gateType, int insertionPosition, int tappedQubitIndex, {bool isDeletable = true}) {
    PlacedQuantumGate gateToInsert = PlacedQuantumGate(
      type: gateType,
      isDeletable: isDeletable,
    );

    if (placedGates[tappedQubitIndex].length <= insertionPosition) {
      insertionPosition = min(insertionPosition, placedGates[tappedQubitIndex].length);
      placedGates[tappedQubitIndex].insert(insertionPosition, gateToInsert);
      return;
    } else if (placedGates[tappedQubitIndex][insertionPosition].type == SelectedGateType.none) {
      placedGates[tappedQubitIndex][insertionPosition] = gateToInsert;
      return;
    }

    // else, this will fill a vertical line in the circuit with gates as first phase.
    for (int i = 0; i < currentLevel.numQubits; i++) {
      if (i == tappedQubitIndex) {
        insertGateAt(gateToInsert, insertionPosition, i);
      } else {
        PlacedQuantumGate emptyGate = PlacedQuantumGate.emptyGate();
        insertGateAt(emptyGate, insertionPosition, i);
      }
    }

    // Second phase, we need to scroll left what is scrollable.
    shiftLeft();

    trimCircuit();

    // Notify listeners that the state has changed
    notifyListeners();
  }

  // currently specific to CNOT only
  void insertDoublePlacedGateAt(SelectedGateType gateType, int insertionPosition, int targetQubitIndex, int controlQubitIndex, {bool isDeletable = true}) {
    // need to check if the area to place the gate is fully empty then,
    int from = min(controlQubitIndex, targetQubitIndex);
    int to = max(controlQubitIndex, targetQubitIndex);

    debugPrint('Insertion position: $insertionPosition, from: $from, to: $to');

    insertionPosition = min(insertionPosition, maxCircuitDepth());

    bool allEmpty = true;
    for (int i = from; i <= to; i++) {
      if(insertionPosition < placedGates[i].length && placedGates[i][insertionPosition].type != SelectedGateType.none) {
        allEmpty = false;
        break;
      }
    }

    // There is no need to scroll,
    if (allEmpty) {
      for (int i = from; i <= to; i++) {
        if (i == controlQubitIndex) {
          PlacedQuantumGate controlGate = PlacedQuantumGate(
            type: gateType,
            isControl: true,
            controlQubitIndex: controlQubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(controlGate, insertionPosition, i);
        } else if (i == targetQubitIndex) {
          PlacedQuantumGate targetGate = PlacedQuantumGate(
            type: gateType,
            isTarget: true,
            controlQubitIndex: controlQubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(targetGate, insertionPosition, i);
        } else {
          PlacedQuantumGate linkGate = PlacedQuantumGate(
            type: gateType,
            isLink: true,
            controlQubitIndex: controlQubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(linkGate, insertionPosition, i);
        }
      }
    } else {
      // This will fill a vertical line in the circuit with gates as first phase.
      for (int i = 0; i < currentLevel.numQubits; i++) {
        if (i == controlQubitIndex) {
          PlacedQuantumGate controlGate = PlacedQuantumGate(
            type: gateType,
            isControl: true,
            controlQubitIndex: controlQubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(controlGate, insertionPosition, i);
        } else if (i == targetQubitIndex) {
          PlacedQuantumGate targetGate = PlacedQuantumGate(
            type: gateType,
            isTarget: true,
            controlQubitIndex: controlQubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(targetGate, insertionPosition, i);
        } else if (i > controlQubitIndex && i < targetQubitIndex || i < controlQubitIndex && i > targetQubitIndex) {
          PlacedQuantumGate linkGate = PlacedQuantumGate(
            type: gateType,
            isLink: true,
            controlQubitIndex: controlQubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(linkGate, insertionPosition, i);
        } else {
          PlacedQuantumGate emptyGate = PlacedQuantumGate.emptyGate();
          insertGateAt(emptyGate, insertionPosition, i);
        }
      }

      // Second phase, we need to scroll left what is scrollable.
      shiftLeft();

      trimCircuit();
    }

    // Notify listeners that the state has changed
    notifyListeners();
  }

  // currently specific to CCNOT only
  void insertTriplePlacedGateAt(SelectedGateType gateType, int insertionPosition, int targetQubitIndex, int control1QubitIndex, int control2QubitIndex, {bool isDeletable = true}) {
    // need to check if the area to place the gate is fully empty then,
    List<int> controls = [control1QubitIndex, control2QubitIndex, targetQubitIndex];
    int from = controls.reduce(min);
    int to = controls.reduce(max);

    bool allEmpty = true;
    for (int i = from; i <= to; i++) {
      if(insertionPosition < placedGates[i].length && placedGates[i][insertionPosition].type != SelectedGateType.none) {
        allEmpty = false;
        break;
      }
    }

    // There is no need to scroll,
    if (allEmpty) {
      for (int i = from; i <= to; i++) {
        if (i == control1QubitIndex) {
          PlacedQuantumGate controlGate = PlacedQuantumGate(
            type: gateType,
            isControl: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(controlGate, insertionPosition, i);
        } else if (i == targetQubitIndex) {
          PlacedQuantumGate targetGate = PlacedQuantumGate(
            type: gateType,
            isTarget: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(targetGate, insertionPosition, i);
        } else if (i == control2QubitIndex) {
          PlacedQuantumGate control2Gate = PlacedQuantumGate(
            type: gateType,
            isControl2: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(control2Gate, insertionPosition, i);
        } else {
          PlacedQuantumGate linkGate = PlacedQuantumGate(
            type: gateType,
            isLink: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(linkGate, insertionPosition, i);
        }
      }
    } else {
      // This will fill a vertical line in the circuit with gates as first phase.
      for (int i = 0; i < currentLevel.numQubits; i++) {
        if (i == control1QubitIndex) {
          PlacedQuantumGate controlGate = PlacedQuantumGate(
            type: gateType,
            isControl: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(controlGate, insertionPosition, i);
        } else if (i == targetQubitIndex) {
          PlacedQuantumGate targetGate = PlacedQuantumGate(
            type: gateType,
            isTarget: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(targetGate, insertionPosition, i);
        } else if (i == control2QubitIndex) {
          PlacedQuantumGate control2Gate = PlacedQuantumGate(
            type: gateType,
            isControl2: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(control2Gate, insertionPosition, i);
        } else if (i > control1QubitIndex && i < targetQubitIndex || i < control1QubitIndex && i > targetQubitIndex) {
          PlacedQuantumGate linkGate = PlacedQuantumGate(
            type: gateType,
            isLink: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(linkGate, insertionPosition, i);
        } else {
          PlacedQuantumGate emptyGate = PlacedQuantumGate.emptyGate();
          insertGateAt(emptyGate, insertionPosition, i);
        }
      }

      // Second phase, we need to scroll left what is scrollable.
      shiftLeft();

      trimCircuit();
    }

    // Notify listeners that the state has changed
    notifyListeners();
  }

  // Method to remove a specific placed gate instance from the circuit
  bool removePlacedGate(int gatePosition, int qubitLine) {
    PlacedQuantumGate gateToRemove = placedGates[qubitLine][gatePosition];
    if (gateToRemove.type == SelectedGateType.none) {
      return false;
    }
    else if ((gateToRemove.type == SelectedGateType.cnot || gateToRemove.type == SelectedGateType.cz) && gateToRemove.isDeletable) {
      List<int> controls = [gateToRemove.controlQubitIndex!, gateToRemove.targetQubitIndex!];
      for (int i = controls.reduce(min); i <= controls.reduce(max); i++) {
        placedGates[i][gatePosition] = PlacedQuantumGate.emptyGate();
      }
    }
    else if (gateToRemove.type == SelectedGateType.ccnot && gateToRemove.isDeletable) {
      List<int> controls = [gateToRemove.controlQubitIndex!, gateToRemove.control2QubitIndex!, gateToRemove.targetQubitIndex!];
      for (int i = controls.reduce(min); i <= controls.reduce(max); i++) {
        placedGates[i][gatePosition] = PlacedQuantumGate.emptyGate();
      }
    } else if (gateToRemove.isDeletable) {
      placedGates[qubitLine][gatePosition] = PlacedQuantumGate.emptyGate();
    } else {
      debugPrint('Gate type [${gateToRemove.type}] not deletable at qubit line: $qubitLine and gate position: $gatePosition');
      return false;
    }

    debugPrint('Gate type [${gateToRemove.type}] removed at qubit line: $qubitLine and gate position: $gatePosition');

    // Second phase, we need to scroll left what is scrollable.
    shiftLeft();

    trimCircuit();

    // ** Notify listeners that the state has changed **
    notifyListeners();

    return true;
  }

  void shiftLeft() {
    bool repeat;
    do {
      repeat = false;
      int maxDepth = maxCircuitDepth();
      int rightPosition = maxDepth - 1;
      int leftPosition = rightPosition - 1;
      while(rightPosition >= 1) {
        for (int i = 0; i < currentLevel.numQubits; i++) {
          if (rightPosition < placedGates[i].length && placedGates[i][rightPosition].type != SelectedGateType.none) {
            var rightGate = placedGates[i][rightPosition];
            if (rightGate.type == SelectedGateType.cnot || rightGate.type == SelectedGateType.cz) {
              int endLine = rightGate.isTarget ? rightGate.controlQubitIndex! : rightGate.targetQubitIndex!;
              bool canBeMoved = true;
              for (int j = i; j <= endLine; j++) {
                if (placedGates[j][rightPosition - 1].type != SelectedGateType.none) {
                  canBeMoved = false;
                  break;
                }
              }
              if (canBeMoved) {
                for (int j = i; j <= endLine; j++) {
                  placedGates[j][rightPosition - 1] = placedGates[j][rightPosition];
                  placedGates[j][rightPosition] = PlacedQuantumGate.emptyGate();
                  repeat = true;
                }
              }
              i = max(i, endLine);
            } else if (rightGate.type == SelectedGateType.ccnot) {
              int endLine = [rightGate.controlQubitIndex!, rightGate.control2QubitIndex!, rightGate.targetQubitIndex!].reduce(max);
              bool canBeMoved = true;
              for (int j = i; j <= endLine; j++) {
                if (placedGates[j][rightPosition - 1].type != SelectedGateType.none) {
                  canBeMoved = false;
                  break;
                }
              }
              if (canBeMoved) {
                for (int j = i; j <= endLine; j++) {
                  placedGates[j][rightPosition - 1] = placedGates[j][rightPosition];
                  placedGates[j][rightPosition] = PlacedQuantumGate.emptyGate();
                }
                repeat = true;
              }
              i = max(i, endLine);
            } else {
              if (placedGates[i][rightPosition - 1].type == SelectedGateType.none) {
                placedGates[i][rightPosition - 1] = rightGate;
                placedGates[i][rightPosition] = PlacedQuantumGate.emptyGate();
                repeat = true;
              }
            }
          }
        }
        if (rightPosition < maxDepth) {
          rightPosition--;
        } else {
          leftPosition--;
          rightPosition = leftPosition - 1;
        }
      }
    } while(repeat);
  }

  void insertGateAt(PlacedQuantumGate gateToInsert, int insertionPosition, int targetQubitIndex) {
    if (insertionPosition > placedGates[targetQubitIndex].length) { // Insert empty filler
      final int lengthFiller = (placedGates[targetQubitIndex].length - insertionPosition).abs();
      final fillerList = List<PlacedQuantumGate>.filled(lengthFiller, PlacedQuantumGate.emptyGate());
      placedGates[targetQubitIndex].addAll(fillerList);
    }
    placedGates[targetQubitIndex].insert(insertionPosition, gateToInsert);
  }

  void trimCircuit() {
    for (int i = 0; i < currentLevel.numQubits; i++) {
      while (placedGates[i].isNotEmpty && placedGates[i].last.type == SelectedGateType.none) {
        placedGates[i].removeLast();
      }
    }
  }

  // Method to clear all placed gates from the circuit
  void clearPlacedGates() {
    // placedGates.clear();
    placedGates = List.generate(currentLevel.numQubits, (index) => []);
    // Reset the currentState back to the initial ground state
    currentState = QubitState.fromList(currentLevel.initialQubitsState);
    currentLevel.preInsertGates(this);
    debugPrint("Circuit cleared. Total placed gates: ${placedGates.length}"); // Debug debugPrint
    // ** Notify listeners that the state has changed **
    notifyListeners();
  }

  List<List<PlacedQuantumGate>> clone(List<List<PlacedQuantumGate>> gates) =>
      placedGates = gates.map((element) => List<PlacedQuantumGate>.from(element)).toList();

  // --- BACKEND MATRIX GENERATION LOGIC ---

  /// Builds the system matrix for a single placed quantum gate.
  QuantumMatrix _buildSystemMatrixForPlacedGate(PlacedQuantumGate gate) {
    switch (gate.type) {
      case SelectedGateType.hadamard:
        return QuantumMatrix.hadamard();
      case SelectedGateType.s:
        return QuantumMatrix.phaseS();
      case SelectedGateType.t:
        return QuantumMatrix.t();
      case SelectedGateType.x:
        return QuantumMatrix.pauliX();
      case SelectedGateType.y:
        return QuantumMatrix.pauliY();
      case SelectedGateType.z:
        return QuantumMatrix.pauliZ();
      case SelectedGateType.cz: // at this point we consider only CZ gates control
        return QuantumMatrix.cz(
            control: gate.controlQubitIndex!,
            target: gate.targetQubitIndex!
        );
      case SelectedGateType.cnot: // at this point we consider only CNOT gates control
        return QuantumMatrix.cnot(
            control: gate.controlQubitIndex!,
            target: gate.targetQubitIndex!
        );
      case SelectedGateType.ccnot:
        List<int> controls = [gate.controlQubitIndex!, gate.control2QubitIndex!, gate.targetQubitIndex!];
        return QuantumMatrix.ccnot(
            control1: gate.controlQubitIndex!,
            control2: gate.control2QubitIndex!,
            target: gate.targetQubitIndex!
        );
      case SelectedGateType.none:
        return QuantumMatrix.identity(2);
      default:
        throw UnimplementedError();
    }
  }

  /// Calculates the combined matrix for all *logical* gates in a single circuit column (time step).
  /// Gates in the same column acting on different qubits act simultaneously.
  QuantumMatrix _calculateColumnMatrix(int columnIndex) {
    QuantumMatrix? columnOverallMatrix;

    // Keep track of which logical gates (especially CNOTs) have already been processed
    for (int q = 0; q < currentLevel.numQubits; q++) {
      PlacedQuantumGate? gate;

      if (columnIndex >= placedGates[q].length) {
        gate = PlacedQuantumGate.emptyGate();
      } else {
        gate = placedGates[q][columnIndex];
      }

      // Multiply into the column's overall matrix.
      // Order of multiplication for simultaneous gates (e.g., (H on Q0) and (X on Q1))
      // is usually equivalent to (Gate_on_MSB_Qubit_Sys) * (Gate_on_LSB_Qubit_Sys)
      // or (M_MSB_qubit) ⊗ (M_LSB_qubit).
      // Here, we accumulate by multiplying new gate matrix from the left.
      // For Q0 LSB convention, `overallMatrix = multiplyMatrices(gateSystemMatrix, overallMatrix)` is correct.
      QuantumMatrix gateSystemMatrix = _buildSystemMatrixForPlacedGate(gate);
      columnOverallMatrix = columnOverallMatrix == null ? gateSystemMatrix : gateSystemMatrix.tensorProduct(columnOverallMatrix);

      debugPrint(gateSystemMatrix.toString());

      if (gate.type == SelectedGateType.cnot || gate.type == SelectedGateType.cz) {
        // skip to the next qubit after the CNOT/CZ
        q = max(gate.controlQubitIndex!, gate.targetQubitIndex!);
        continue;
      } else if (gate.type == SelectedGateType.ccnot) {
        // skip to the next qubit after the CCNOT
        q = [gate.controlQubitIndex!, gate.targetQubitIndex!, gate.control2QubitIndex!].reduce(max);
        continue;
      }
    }
    return columnOverallMatrix!;
  }

  /// Generates the overall unitary matrix representing the entire quantum circuit.
  /// This is the "transform operator".
  QuantumMatrix getOverallCircuitMatrix() {
    int totalDepth = maxCircuitDepth();
    if (totalDepth == 0) {
      return QuantumMatrix.identity(1 << currentLevel.numQubits); // Empty circuit is identity
    }

    QuantumMatrix overallMatrix = QuantumMatrix.identity(1 << currentLevel.numQubits);

    // Iterate through each column (time step) from left to right
    for (int col = 0; col < totalDepth; col++) {
      QuantumMatrix columnMatrix = _calculateColumnMatrix(col);
      // Multiply the current overall matrix by the new column matrix.
      // U_total = U_column_N * U_column_{N-1} * ... * U_column_0
      // So, new_overall = current_column * old_overall
      overallMatrix = columnMatrix.dot(overallMatrix);
    }
    return overallMatrix;
  }

  /// Runs the quantum simulation, updating the current state vector.
  void runSimulation() {
    QuantumMatrix circuitMatrix = getOverallCircuitMatrix();
    debugPrint("Initial state: $initialState");
    currentState = initialState.applyMatrix(circuitMatrix);
    debugPrint("Final state: $initialState");
    notifyListeners();
  }


// Helper to visually represent the circuit state for debugging in tests
  @override
  String toString() {
    if (isCircuitEmpty()) {
      return "Empty Circuit\n";
    }

    // Determine max depth across all qubit lines
    int maxDepth = 0;
    for (int i = 0; i < currentLevel.numQubits; i++) {
      if (placedGates[i].length > maxDepth) {
        maxDepth = placedGates[i].length;
      }
    }

    String result = "";
    for (int q = 0; q < currentLevel.numQubits; q++) {
      result += "Q$q: ";
      for (int pos = 0; pos < maxDepth; pos++) {
        if (pos < placedGates[q].length) {
          PlacedQuantumGate gate = placedGates[q][pos];
          // Use a concise representation for each gate type
          String gateChar = "";
          if (gate.type == SelectedGateType.cz) {
            if (gate.isControl) gateChar = "C";
            else if (gate.isTarget) gateChar = "Z";
            else if (gate.isLink) gateChar = "|";
            else gateChar = "?"; // Should not happen for CZ
          }
          if (gate.type == SelectedGateType.cnot) {
            if (gate.isControl) gateChar = "C";
            else if (gate.isTarget) gateChar = "X";
            else if (gate.isLink) gateChar = "|";
            else gateChar = "?"; // Should not happen for CNOT
          }
          else if (gate.type == SelectedGateType.ccnot) {
            if (gate.isControl) gateChar = "C";
            if (gate.isControl2) gateChar = "C";
            else if (gate.isTarget) gateChar = "T";
            else if (gate.isLink) gateChar = "|";
            else gateChar = "?"; // Should not happen for CCNOT
          }
          else if (gate.type == SelectedGateType.none) {
            gateChar = "-";
          }
          else {
            gateChar = gate.type.label;
          }
          result += "$gateChar ";
        } else {
          result += "- "; // Represents empty space beyond the end of a line
        }
      }
      result += "\n";
    }
    return result;
  }
}
