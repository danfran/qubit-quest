import 'package:flutter/foundation.dart'; // Import this for ChangeNotifier
import 'package:quantumquiz/placed_quantum_gate.dart'; // Import PlacedQuantumGate
import 'package:quantumquiz/qubit_state.dart'; // Assuming you have this class
import 'dart:math';

import 'package:quantumquiz/selected_gate_type.dart';

// Make QuantumCircuit extend ChangeNotifier
class QuantumCircuit extends ChangeNotifier {
  // List to store the placed gate instances that define the circuit structure
  List<List<PlacedQuantumGate>> placedGates;

  // The number of qubits in the circuit (assuming fixed)
  final int numQubits;

  // Property to hold the current/final quantum state vector (updated by simulation)
  QubitState currentState;

  // Constructor
  QuantumCircuit({required this.numQubits}) :
  // Initialize the currentState to the ground state |00...0>
  // Assuming QubitState has a constructor or static method to create the initial state
        currentState = QubitState.initial(numQubits), placedGates = List.generate(numQubits, (index) => []);

  int maxCircuitDepth() => placedGates.map((e) => e.length).reduce(max);

  bool isCircuitEmpty() => maxCircuitDepth() == 0;

  // New method to insert a placed gate at a specific position
  void insertSinglePlacedGateAt(SelectedGateType gateType, int insertionPosition, int tappedQubitIndex) {
    PlacedQuantumGate gateToInsert = PlacedQuantumGate(
      type: gateType,
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
    for (int i = 0; i < numQubits; i++) {
      if (i == tappedQubitIndex) {
        insertGateAt(gateToInsert, insertionPosition, i);
      } else {
        PlacedQuantumGate emptyGate = PlacedQuantumGate.emptyGate();
        insertGateAt(emptyGate, insertionPosition, i);
      }
    }

    // Second phase, we need to scroll left what is scrollable.
    shiftLeft(insertionPosition);

    trimCircuit();

    // Notify listeners that the state has changed
    notifyListeners();
  }

  // currently specific to CNOT only
  void insertDoublePlacedGateAt(SelectedGateType gateType, int insertionPosition, int tappedQubitIndex, int targetQubitIndex) {
    // need to check if the area to place the gate is fully empty then,
    bool allEmpty = true;
    for (int i = min(tappedQubitIndex, targetQubitIndex); i <= max(tappedQubitIndex, targetQubitIndex); i++) {
      if(insertionPosition < placedGates[i].length && placedGates[i][insertionPosition].type != SelectedGateType.none) {
        allEmpty = false;
        break;
      }
    }

    // There is no need to scroll,
    if (allEmpty) {
      for (int i = min(tappedQubitIndex, targetQubitIndex); i <= max(tappedQubitIndex, targetQubitIndex); i++) {
        if (i == tappedQubitIndex) {
          PlacedQuantumGate controlGate = PlacedQuantumGate(
            type: gateType,
            isControl: true,
            targetQubitIndex: targetQubitIndex, // for the painter
          );
          insertGateAt(controlGate, insertionPosition, i);
        } else if (i == targetQubitIndex) {
          PlacedQuantumGate targetGate = PlacedQuantumGate(
            type: gateType,
            isTarget: true,
            controlQubitIndex: tappedQubitIndex,
          );
          insertGateAt(targetGate, insertionPosition, i);
        } else {
          PlacedQuantumGate linkGate = PlacedQuantumGate(
            type: gateType,
            isLink: true,
          );
          insertGateAt(linkGate, insertionPosition, i);
        }
      }
      return;
    }

    // Else, this will fill a vertical line in the circuit with gates as first phase.
    for (int i = 0; i < numQubits; i++) {
      if (i == tappedQubitIndex) {
        PlacedQuantumGate controlGate = PlacedQuantumGate(
          type: gateType,
          isControl: true,
          targetQubitIndex: targetQubitIndex, // for the painter
        );
        insertGateAt(controlGate, insertionPosition, i);
      } else if (i == targetQubitIndex) {
        PlacedQuantumGate targetGate = PlacedQuantumGate(
          type: gateType,
          isTarget: true,
          controlQubitIndex: tappedQubitIndex,
        );
        insertGateAt(targetGate, insertionPosition, i);
      } else if (i > tappedQubitIndex && i < targetQubitIndex || i < tappedQubitIndex && i > targetQubitIndex) {
        PlacedQuantumGate linkGate = PlacedQuantumGate(
          type: gateType,
          isLink: true,
        );
        insertGateAt(linkGate, insertionPosition, i);
      } else {
        PlacedQuantumGate emptyGate = PlacedQuantumGate.emptyGate();
        insertGateAt(emptyGate, insertionPosition, i);
      }
    }

    // Second phase, we need to scroll left what is scrollable.
    shiftLeft(insertionPosition);

    trimCircuit();

    // Notify listeners that the state has changed
    notifyListeners();
  }

  void shiftLeft(int insertionPosition) {
    int rightPosition = insertionPosition + 1;
    while(rightPosition - 1 < maxCircuitDepth() - 1) {
      for (int i = 0; i < numQubits; i++) {
        if (rightPosition < placedGates[i].length && placedGates[i][rightPosition].type != SelectedGateType.none) {
          var rightGate = placedGates[i][rightPosition];
          if (rightGate.type == SelectedGateType.cnot) {
            int endLine = rightGate.isTarget ? rightGate.controlQubitIndex! : rightGate.targetQubitIndex!;
            bool canBeMoved = true;
            for (int j = i; j <= endLine; j++) {
              if (placedGates[i][rightPosition - 1].type != SelectedGateType.none) {
                canBeMoved = false;
                break;
              }
            }
            if (canBeMoved) {
              for (int j = i; j <= endLine; j++) {
                placedGates[i][rightPosition - 1] = rightGate;
                placedGates[i][rightPosition] = PlacedQuantumGate.emptyGate();
              }
            }
            i = max(i, endLine);
          } else {
            if (placedGates[i][rightPosition - 1].type == SelectedGateType.none) {
              placedGates[i][rightPosition - 1] = rightGate;
              placedGates[i][rightPosition] = PlacedQuantumGate.emptyGate();
            }
          }
        }
      }
      rightPosition++;
    }
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
    for (int i = 0; i < numQubits; i++) {
      while (placedGates[i].isNotEmpty && placedGates[i].last.type == SelectedGateType.none) {
        placedGates[i].removeLast();
      }
    }
  }

  // Method to remove a specific placed gate instance from the circuit
  void removePlacedGate(int gatePosition, int qubitLine) {
    print('Gate removed at qubit line: $qubitLine and gate position: $gatePosition');
    placedGates[qubitLine].removeAt(gatePosition);

    // ** Notify listeners that the state has changed **
    notifyListeners();
  }

  // Method to clear all placed gates from the circuit
  void clearPlacedGates() {
    placedGates.clear();
    // Reset the currentState back to the initial ground state
    currentState = QubitState.initial(numQubits);
    print("Circuit cleared. Total placed gates: ${placedGates.length}"); // Debug print
    // ** Notify listeners that the state has changed **
    notifyListeners();
  }

  // The main simulation method - it returns void and updates the internal currentState property
  void runSimulation() {
    // print("Starting simulation for ${placedGates.length} gates...");
    //
    // // Start with the initial state vector for this specific run
    // QubitState stateVector = QubitState.initial(numQubits);
    //
    // // 1. Group placed gates by their horizontal position (column index)
    // Map<int, List<PlacedQuantumGate>> gatesByPosition = {};
    // for (var placedGate in placedGates) {
    //   gatesByPosition.putIfAbsent(placedGate.position, () => []).add(placedGate);
    // }
    //
    // // 2. Get a sorted list of positions (columns) to process them left-to-right
    // List<int> sortedPositions = gatesByPosition.keys.toList()..sort();
    //
    // // 3. Process each column (position) sequentially
    // for (int position in sortedPositions) {
    //   List<PlacedQuantumGate> gatesInColumn = gatesByPosition[position]!;
    //   // print("Processing column $position with ${gatesInColumn.length} gates.");
    //
    //   // 4. Calculate the single combined matrix for all gates acting in this column
    //   List<List<Complex>> columnOverallMatrix = calculateColumnMatrix(gatesInColumn, numQubits); // <-- You need to implement calculateColumnMatrix
    //
    //   // 5. Apply the combined column matrix to the current state vector for this run
    //   stateVector = stateVector.applyMatrix(columnOverallMatrix); // Assuming QubitState has an applyMatrix method
    //
    //   // print("State after column $position: ${stateVector.toString()}");
    // }
    //
    // // 6. Update the internal currentState property with the final state vector result
    // this.currentState = stateVector;
    //
    // print("Simulation finished. Internal currentState updated.");
    // // We don't notifyListeners here because runSimulation is typically called
    // // right before updating the simulationResult text, and setState is called there.
  }

  // --- Helper Methods for Simulation (Need Implementation) ---

  // You need to implement this method based on your matrix library and QuantumGate definitions.
  // List<List<Complex>> calculateColumnMatrix(List<PlacedQuantumGate> gatesInColumn, int numQubits) {
  //   // This involves building the identity matrix of size 2^numQubits,
  //   // then for each gate in the column, getting its 2^numQubits x 2^numQubits matrix
  //   // (tensoring with identities for unaffected qubits), and multiplying these together.
  //   // The order of multiplication for simultaneous gates in a column doesn't matter mathematically,
  //   // but implement consistently.
  //
  //   // Example (Conceptual - implementation depends on your math library):
  //   // Assuming identityMatrix and multiplyMatrices helpers are available
  //   List<List<Complex>> identity = identityMatrix(1 << numQubits);
  //
  //   List<List<Complex>> combinedMatrix = identity;
  //
  //   for (var placedGate in gatesInColumn) {
  //     // Get the full system matrix for this single placed gate operation
  //     List<List<Complex>> gateSystemMatrix = buildSystemMatrixForPlacedGate(placedGate, numQubits); // <-- Needs implementation
  //
  //     // Multiply the combined matrix by this gate's system matrix
  //     combinedMatrix = multiplyMatrices(gateSystemMatrix, combinedMatrix); // Assuming multiplyMatrices helper exists
  //   }
  //
  //   return combinedMatrix;
  // }
  //
  // // You need to implement this based on your original QuantumGate definitions and matrix library.
  // // This function takes a PlacedQuantumGate and returns its 2^numQubits x 2^numQubits matrix representation
  // List<List<Complex>> buildSystemMatrixForPlacedGate(PlacedQuantumGate placedGate, int numQubits) {
  //   // This is complex logic depending on the gate type and how your original getMatrix works.
  //   // You'll need to map the PlacedQuantumGate type and qubits to the correct matrix
  //   // from your QuantumGate definitions and potentially expand it using tensor products.
  //   throw UnimplementedError("buildSystemMatrixForPlacedGate needs implementation");
  // }

// Assuming you have matrix multiplication and identity matrix helper functions
// List<List<Complex>> multiplyMatrices(List<List<Complex>> matrix1, List<List<Complex>> matrix2) { ... }
// List<List<Complex>> identityMatrix(int size) { ... }
}
