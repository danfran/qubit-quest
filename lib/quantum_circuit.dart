// quantum_circuit.dart

import 'package:flutter/foundation.dart'; // Import this for ChangeNotifier
import 'package:complex/complex.dart';
import 'package:quantumquiz/placed_quantum_gate.dart'; // Import PlacedQuantumGate
import 'package:quantumquiz/qubit_state.dart'; // Assuming you have this class
import 'dart:math';

import 'math_utils.dart'; // For max in _getNextGatePosition if it's in this class

// Make QuantumCircuit extend ChangeNotifier
class QuantumCircuit extends ChangeNotifier {
  // List to store the placed gate instances that define the circuit structure
  List<PlacedQuantumGate> placedGates = [];

  // The number of qubits in the circuit (assuming fixed)
  final int numQubits;

  // Property to hold the current/final quantum state vector (updated by simulation)
  QubitState currentState;

  // Constructor
  QuantumCircuit({required this.numQubits}) :
  // Initialize the currentState to the ground state |00...0>
  // Assuming QubitState has a constructor or static method to create the initial state
        currentState = QubitState.initial(numQubits);

  // New method to insert a placed gate at a specific position
  void insertPlacedGateAt(PlacedQuantumGate gateToInsert, int insertionPosition, int targetQubitIndex) {
    // Find all gates that are at or after the insertion position
    final gatesToShift = placedGates.where((placedGate) => placedGate.position >= insertionPosition).toList();

    // Increment the position of all gates that need to be shifted
    for (var gate in gatesToShift) {
      // Create a new PlacedQuantumGate object with the incremented position
      // PlacedQuantumGate is immutable, so we create a new one.
      final shiftedGate = PlacedQuantumGate(
        type: gate.type,
        position: gate.position + 1, // Increment the horizontal position
        singleQubitIndex: gate.singleQubitIndex,
        controlQubitIndex: gate.controlQubitIndex,
        targetQubitIndex: gate.targetQubitIndex,
      );
      // Replace the old gate object with the new shifted one in the list
      final index = placedGates.indexOf(gate);
      if (index != -1) {
        placedGates[index] = shiftedGate;
      }
    }

    // Update the position of the gate being inserted
    final PlacedQuantumGate gateWithCorrectedPosition = PlacedQuantumGate(
      type: gateToInsert.type,
      position: insertionPosition, // Set the position to the calculated insertion position
      singleQubitIndex: gateToInsert.singleQubitIndex,
      controlQubitIndex: gateToInsert.controlQubitIndex,
      targetQubitIndex: gateToInsert.targetQubitIndex,
    );

    // Add the gate to the list
    placedGates.add(gateWithCorrectedPosition);

    // Sort the list by position to maintain order (important for drawing and simulation)
    placedGates.sort((a, b) => a.position.compareTo(b.position));

    print("Gate inserted at position $insertionPosition. Total placed gates: ${placedGates.length}");
    // Notify listeners that the state has changed
    notifyListeners();
  }


  // Method to add a placed gate instance to the circuit
  void addPlacedGate(PlacedQuantumGate gate) {
    placedGates.add(gate);
    // Optional: Keep the list sorted by position for easier simulation processing later
    // placedGates.sort((a, b) => a.position.compareTo(b.position));
    print("Gate added to circuit. Total placed gates: ${placedGates.length}"); // Debug print
    // ** Notify listeners that the state has changed **
    notifyListeners();
  }

  // Method to remove a specific placed gate instance from the circuit
  void removePlacedGate(PlacedQuantumGate gate) {
    placedGates.remove(gate); // Removes the specific object instance
    // Optional: Re-sort the list if keeping it sorted
    // placedGates.sort((a, b) => a.position.compareTo(b.position));
    print("Gate removed from circuit. Total placed gates: ${placedGates.length}"); // Debug print
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
    print("Starting simulation for ${placedGates.length} gates...");

    // Start with the initial state vector for this specific run
    QubitState stateVector = QubitState.initial(numQubits);

    // 1. Group placed gates by their horizontal position (column index)
    Map<int, List<PlacedQuantumGate>> gatesByPosition = {};
    for (var placedGate in placedGates) {
      gatesByPosition.putIfAbsent(placedGate.position, () => []).add(placedGate);
    }

    // 2. Get a sorted list of positions (columns) to process them left-to-right
    List<int> sortedPositions = gatesByPosition.keys.toList()..sort();

    // 3. Process each column (position) sequentially
    for (int position in sortedPositions) {
      List<PlacedQuantumGate> gatesInColumn = gatesByPosition[position]!;
      // print("Processing column $position with ${gatesInColumn.length} gates.");

      // 4. Calculate the single combined matrix for all gates acting in this column
      List<List<Complex>> columnOverallMatrix = calculateColumnMatrix(gatesInColumn, numQubits); // <-- You need to implement calculateColumnMatrix

      // 5. Apply the combined column matrix to the current state vector for this run
      stateVector = stateVector.applyMatrix(columnOverallMatrix); // Assuming QubitState has an applyMatrix method

      // print("State after column $position: ${stateVector.toString()}");
    }

    // 6. Update the internal currentState property with the final state vector result
    this.currentState = stateVector;

    print("Simulation finished. Internal currentState updated.");
    // We don't notifyListeners here because runSimulation is typically called
    // right before updating the simulationResult text, and setState is called there.
  }

  // --- Helper Methods for Simulation (Need Implementation) ---

  // You need to implement this method based on your matrix library and QuantumGate definitions.
  List<List<Complex>> calculateColumnMatrix(List<PlacedQuantumGate> gatesInColumn, int numQubits) {
    // This involves building the identity matrix of size 2^numQubits,
    // then for each gate in the column, getting its 2^numQubits x 2^numQubits matrix
    // (tensoring with identities for unaffected qubits), and multiplying these together.
    // The order of multiplication for simultaneous gates in a column doesn't matter mathematically,
    // but implement consistently.

    // Example (Conceptual - implementation depends on your math library):
    // Assuming identityMatrix and multiplyMatrices helpers are available
    List<List<Complex>> identity = identityMatrix(1 << numQubits);

    List<List<Complex>> combinedMatrix = identity;

    for (var placedGate in gatesInColumn) {
      // Get the full system matrix for this single placed gate operation
      List<List<Complex>> gateSystemMatrix = buildSystemMatrixForPlacedGate(placedGate, numQubits); // <-- Needs implementation

      // Multiply the combined matrix by this gate's system matrix
      combinedMatrix = multiplyMatrices(gateSystemMatrix, combinedMatrix); // Assuming multiplyMatrices helper exists
    }

    return combinedMatrix;
  }

  // You need to implement this based on your original QuantumGate definitions and matrix library.
  // This function takes a PlacedQuantumGate and returns its 2^numQubits x 2^numQubits matrix representation
  List<List<Complex>> buildSystemMatrixForPlacedGate(PlacedQuantumGate placedGate, int numQubits) {
    // This is complex logic depending on the gate type and how your original getMatrix works.
    // You'll need to map the PlacedQuantumGate type and qubits to the correct matrix
    // from your QuantumGate definitions and potentially expand it using tensor products.
    throw UnimplementedError("buildSystemMatrixForPlacedGate needs implementation");
  }

// Assuming you have matrix multiplication and identity matrix helper functions
// List<List<Complex>> multiplyMatrices(List<List<Complex>> matrix1, List<List<Complex>> matrix2) { ... }
// List<List<Complex>> identityMatrix(int size) { ... }
}
