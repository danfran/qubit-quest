import 'package:advance_math/advance_math.dart';
import 'package:flutter/foundation.dart'; // Import this for ChangeNotifier
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart'; // Import PlacedQuantumGate
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/qubit_state.dart'; // Assuming you have this class
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';

class MalformedCircuitException implements Exception {
  final SelectedGateType gateType;
  final int columnIndex;
  final int qubitIndex;
  final String parameterName;

  const MalformedCircuitException({
    required this.gateType,
    required this.columnIndex,
    required this.qubitIndex,
    required this.parameterName,
  });

  String get gateLabel => Gate.fromIdentifier(gateType).label;

  String get userMessage {
    return 'Choose an angle for the $gateLabel gate before checking the circuit.';
  }

  @override
  String toString() {
    return 'MalformedCircuitException(gate: $gateType, column: $columnIndex, '
        'qubit: $qubitIndex, missing/invalid parameter: $parameterName)';
  }
}

// Make QuantumCircuit extend ChangeNotifier
class QuantumCircuit extends ChangeNotifier {
  int _nextGateId = 1;

  GateId _allocateGateId() => GateId(_nextGateId++);
  // List to store the placed gate instances that define the circuit structure
  List<List<PlacedQuantumGate>> placedGates;

  // The number of qubits in the circuit (assuming fixed)
  final ComposerLevel currentLevel;
  // final List<Complex> initialQubitsState;
  // Property to hold the current/final quantum state vector (updated by simulation)
  final QubitState initialState;
  QubitState currentState;
  MalformedCircuitException? lastSimulationError;
  @visibleForTesting
  int simulationRunCount = 0;

  // Constructor
  QuantumCircuit({required this.currentLevel})
      :
        // Initialize the currentState to the ground state |00...0>
        // Assuming QubitState has a constructor or static method to create the initial state
        initialState = QubitState.fromList(currentLevel.initialQubitsState),
        currentState = QubitState.fromList(currentLevel.initialQubitsState),
        placedGates = List.generate(currentLevel.numQubits, (index) => []) {
    currentLevel.preInsertGates(this);
    runSimulation(); // Automatically calls the simulation method
    debugPrint(
        'QuantumCircuit initialized and simulation started automatically!');
  }

  int maxCircuitDepth() => placedGates.map((e) => e.length).reduce(max);

  bool isCircuitEmpty() => maxCircuitDepth() == 0;

  // New method to insert a placed gate at a specific position
  void insertSinglePlacedGateAt(
      Gate gate, int insertionPosition, int tappedQubitIndex,
      {bool isDeletable = true, GateId? gateId, bool notifyChange = true}) {
    if (!gate.hasValidRequiredParameters) {
      throw ArgumentError(
        'Cannot insert ${gate.type} without a valid rotation angle.',
      );
    }
    insertSingleGateWithOutcome(
      gate,
      insertionPosition,
      tappedQubitIndex,
      isDeletable: isDeletable,
      gateId: gateId,
      notifyChange: notifyChange,
    );
  }

  CircuitEditOutcome insertSingleGateWithOutcome(
      Gate gate, int insertionPosition, int tappedQubitIndex,
      {bool isDeletable = true, GateId? gateId, bool notifyChange = true}) {
    if (tappedQubitIndex < 0 ||
        tappedQubitIndex >= currentLevel.numQubits ||
        insertionPosition < 0 ||
        gate.type == SelectedGateType.none ||
        gate.type == SelectedGateType.delete ||
        gate.type == SelectedGateType.draggedGate) {
      return CircuitEditOutcome.invalid;
    }
    if (!gate.hasValidRequiredParameters) {
      return CircuitEditOutcome.invalid;
    }

    final resolvedId = gateId ?? _allocateGateId();
    PlacedQuantumGate gateToInsert = PlacedQuantumGate(
      id: resolvedId,
      gate: gate,
      isDeletable: isDeletable,
    );

    if (placedGates[tappedQubitIndex].length <= insertionPosition) {
      insertionPosition =
          min(insertionPosition, placedGates[tappedQubitIndex].length);
      placedGates[tappedQubitIndex].insert(insertionPosition, gateToInsert);
    } else if (placedGates[tappedQubitIndex][insertionPosition].gate.type ==
        SelectedGateType.none) {
      placedGates[tappedQubitIndex][insertionPosition] = gateToInsert;
    } else {
      // Fill a vertical line to preserve simultaneous-column alignment.
      for (int i = 0; i < currentLevel.numQubits; i++) {
        if (i == tappedQubitIndex) {
          insertGateAt(gateToInsert, insertionPosition, i);
        } else {
          insertGateAt(PlacedQuantumGate.emptyGate(), insertionPosition, i);
        }
      }
      shiftLeft();
      trimCircuit();
    }

    if (notifyChange) notifyListeners();
    return CircuitEditOutcome(
      CircuitEditStatus.changed,
      affectedGateId: resolvedId,
      resultingLocation: logicalGateById(resolvedId)?.anchor,
    );
  }

  List<LogicalGateFootprint> get logicalGates {
    final ids = <GateId>{};
    for (final row in placedGates) {
      for (final gate in row) {
        if (gate.id != null) ids.add(gate.id!);
      }
    }
    return ids
        .map(logicalGateById)
        .whereType<LogicalGateFootprint>()
        .toList(growable: false);
  }

  LogicalGateFootprint? logicalGateById(GateId id) {
    final fragments = <LogicalGateFragment>[];
    for (final (qubit, row) in placedGates.indexed) {
      for (final (column, placedGate) in row.indexed) {
        if (placedGate.id == id) {
          fragments.add(LogicalGateFragment(
            location: CircuitLocation(qubit: qubit, column: column),
            placedGate: placedGate,
          ));
        }
      }
    }
    if (fragments.isEmpty) return null;
    fragments.sort((a, b) {
      final column = a.location.column.compareTo(b.location.column);
      return column != 0
          ? column
          : a.location.qubit.compareTo(b.location.qubit);
    });
    final canonical = fragments.first.placedGate;
    final anchorFragment = fragments.firstWhere(
      (fragment) => fragment.placedGate.isTarget,
      orElse: () => fragments.first,
    );
    return LogicalGateFootprint(
      id: id,
      gate: canonical.gate,
      fragments: List.unmodifiable(fragments),
      anchor: anchorFragment.location,
      controlQubit: canonical.controlQubitIndex,
      secondControlQubit: canonical.control2QubitIndex,
      targetQubit: canonical.targetQubitIndex,
      isDeletable:
          fragments.every((fragment) => fragment.placedGate.isDeletable),
    );
  }

  LogicalGateFootprint? footprintForGateId(GateId id) => logicalGateById(id);

  PlacedGateRef? placedGateById(GateId id) {
    return logicalGateById(id)?.toPlacedGateRef();
  }

  bool containsGate(GateId id) => placedGateById(id) != null;

  MoveResult moveSingleGate(GateId id, CircuitLocation destination) {
    final outcome = moveSingleGateWithOutcome(id, destination);
    return switch (outcome.status) {
      CircuitEditStatus.changed => MoveResult.moved,
      CircuitEditStatus.same => MoveResult.sameSlot,
      CircuitEditStatus.notFound => MoveResult.notFound,
      CircuitEditStatus.protected ||
      CircuitEditStatus.unsupported =>
        MoveResult.notMovable,
      _ => MoveResult.invalid,
    };
  }

  CircuitEditOutcome moveSingleGateWithOutcome(
      GateId id, CircuitLocation destination) {
    final source = logicalGateById(id);
    if (source != null && !source.isSingleQubit) {
      return CircuitEditOutcome.unsupported;
    }
    return commitLogicalGateMovePlan(planLogicalGateMove(id, destination));
  }

  CircuitEditOutcome validateLogicalGateHorizontalMove(
    GateId id,
    int destinationColumn,
  ) {
    final footprint = logicalGateById(id);
    if (footprint == null) return CircuitEditOutcome.notFound;
    return planLogicalGateMove(
      id,
      CircuitLocation(
        qubit: footprint.anchor.qubit,
        column: destinationColumn,
      ),
    ).outcome;
  }

  List<List<PlacedQuantumGate>>? previewLogicalGateHorizontalMove(
    GateId id,
    int destinationColumn,
  ) {
    final footprint = logicalGateById(id);
    if (footprint == null) return null;
    return planLogicalGateMove(
      id,
      CircuitLocation(
        qubit: footprint.anchor.qubit,
        column: destinationColumn,
      ),
    ).proposedRows;
  }

  CircuitEditOutcome moveLogicalGateHorizontallyWithOutcome(
    GateId id,
    int destinationColumn,
  ) {
    final footprint = logicalGateById(id);
    if (footprint == null) return CircuitEditOutcome.notFound;
    if (footprint.isSingleQubit) return CircuitEditOutcome.unsupported;
    return commitLogicalGateMovePlan(
      planLogicalGateMove(
        id,
        CircuitLocation(
          qubit: footprint.anchor.qubit,
          column: destinationColumn,
        ),
      ),
    );
  }

  LogicalMovePlan planLogicalGateMove(
    GateId id,
    CircuitLocation destination,
  ) {
    final baseRows = _copyRows(placedGates);
    LogicalMovePlan rejected(CircuitEditStatus status, String reason) =>
        LogicalMovePlan(
          status: status,
          sourceId: id,
          baseRows: baseRows,
          reason: reason,
        );

    final footprint = logicalGateById(id);
    if (footprint == null) {
      return rejected(CircuitEditStatus.notFound, 'Source GateId not found.');
    }
    if (!footprint.isDeletable) {
      return rejected(CircuitEditStatus.protected, 'Source gate is protected.');
    }
    if (!footprint.canTranslateRigidly) {
      return rejected(
        CircuitEditStatus.unsupported,
        'Logical gate does not support movement.',
      );
    }
    if (destination.column < 0 || destination.column > maxCircuitDepth()) {
      return rejected(CircuitEditStatus.invalid, 'Column is outside circuit.');
    }
    final rowDelta = destination.qubit - footprint.anchor.qubit;
    final translatedRows = footprint.fragments
        .map((fragment) => fragment.location.qubit + rowDelta)
        .toList(growable: false);
    if (translatedRows.any(
      (qubit) => qubit < 0 || qubit >= currentLevel.numQubits,
    )) {
      return rejected(
        CircuitEditStatus.invalid,
        'Translated footprint is outside the circuit qubit bounds.',
      );
    }
    final requestedLocation = CircuitLocation(
      qubit: destination.qubit,
      column: destination.column,
    );
    if (requestedLocation == footprint.anchor) {
      return rejected(
          CircuitEditStatus.same, 'Destination is the source slot.');
    }

    final proposal = _copyRows(placedGates);
    for (final fragment in footprint.fragments) {
      proposal[fragment.location.qubit][fragment.location.column] =
          PlacedQuantumGate.emptyGate();
    }
    final compacted = _compactDetachedRows(proposal);
    if (compacted == null) {
      return rejected(
        CircuitEditStatus.invalid,
        'Existing logical footprint is malformed.',
      );
    }
    _trimDetachedRows(compacted);

    final resolvedColumn = min(destination.column, _maxDepthOf(compacted));
    final resultingLocation = CircuitLocation(
      qubit: requestedLocation.qubit,
      column: resolvedColumn,
    );
    if (resultingLocation == footprint.anchor) {
      return rejected(
        CircuitEditStatus.same,
        'Compaction resolves to the source slot.',
      );
    }

    final destinationQubits = translatedRows;
    final collision = destinationQubits.any(
      (qubit) =>
          _cellAt(compacted, qubit, resolvedColumn).gate.type !=
          SelectedGateType.none,
    );
    if (collision) {
      final displacedProtected = _detachedLogicalFragments(compacted)
          .values
          .any((fragments) =>
              fragments.first.$3 >= resolvedColumn &&
              fragments.any((fragment) => !fragment.$2.isDeletable));
      if (displacedProtected) {
        return rejected(
          CircuitEditStatus.protected,
          'Making room would displace a protected logical gate.',
        );
      }
      for (final row in compacted) {
        while (row.length < resolvedColumn) {
          row.add(PlacedQuantumGate.emptyGate());
        }
        row.insert(resolvedColumn, PlacedQuantumGate.emptyGate());
      }
    } else {
      for (final row in compacted) {
        while (row.length <= resolvedColumn) {
          row.add(PlacedQuantumGate.emptyGate());
        }
      }
    }

    for (final fragment in footprint.fragments) {
      final translatedQubit = fragment.location.qubit + rowDelta;
      compacted[translatedQubit][resolvedColumn] = _translatePlacedGate(
        fragment.placedGate,
        rowDelta,
      );
    }
    _trimDetachedRows(compacted);
    if (!_isValidLogicalGrid(
      compacted,
      baseRows,
      movedId: id,
      rowDelta: rowDelta,
    )) {
      return rejected(
        CircuitEditStatus.invalid,
        'Proposal would corrupt a logical footprint.',
      );
    }

    return LogicalMovePlan(
      status: CircuitEditStatus.changed,
      sourceId: id,
      baseRows: baseRows,
      proposedRows: compacted,
      resultingLocation: resultingLocation,
    );
  }

  CircuitEditOutcome commitLogicalGateMovePlan(LogicalMovePlan plan) {
    if (!plan.changed || plan.proposedRows == null) return plan.outcome;
    if (!_sameGridIdentity(placedGates, plan.baseRows)) {
      return const CircuitEditOutcome(
        CircuitEditStatus.cancelled,
        detail: 'Circuit changed after the move was planned.',
      );
    }
    placedGates = _copyRows(plan.proposedRows!);
    notifyListeners();
    return plan.outcome;
  }

  static List<List<PlacedQuantumGate>> _copyRows(
    List<List<PlacedQuantumGate>> rows,
  ) =>
      rows
          .map((row) => List<PlacedQuantumGate>.from(row))
          .toList(growable: false);

  static PlacedQuantumGate _translatePlacedGate(
    PlacedQuantumGate gate,
    int rowDelta,
  ) {
    int? translated(int? qubit) => qubit == null ? null : qubit + rowDelta;
    return PlacedQuantumGate(
      id: gate.id,
      gate: gate.gate,
      controlQubitIndex: translated(gate.controlQubitIndex),
      control2QubitIndex: translated(gate.control2QubitIndex),
      targetQubitIndex: translated(gate.targetQubitIndex),
      isTarget: gate.isTarget,
      isLink: gate.isLink,
      isControl: gate.isControl,
      isControl2: gate.isControl2,
      isDeletable: gate.isDeletable,
    );
  }

  static int _maxDepthOf(List<List<PlacedQuantumGate>> rows) =>
      rows.fold<int>(0, (depth, row) => max(depth, row.length));

  static PlacedQuantumGate _cellAt(
    List<List<PlacedQuantumGate>> rows,
    int qubit,
    int column,
  ) {
    final row = rows[qubit];
    return column < row.length ? row[column] : PlacedQuantumGate.emptyGate();
  }

  static void _trimDetachedRows(List<List<PlacedQuantumGate>> rows) {
    for (final row in rows) {
      while (row.isNotEmpty && row.last.gate.type == SelectedGateType.none) {
        row.removeLast();
      }
    }
  }

  static Map<GateId, List<(int, PlacedQuantumGate, int)>>
      _detachedLogicalFragments(List<List<PlacedQuantumGate>> rows) {
    final fragments = <GateId, List<(int, PlacedQuantumGate, int)>>{};
    for (final (qubit, row) in rows.indexed) {
      for (final (column, gate) in row.indexed) {
        final id = gate.id;
        if (id == null) continue;
        fragments.putIfAbsent(id, () => []).add((qubit, gate, column));
      }
    }
    return fragments;
  }

  static List<List<PlacedQuantumGate>>? _compactDetachedRows(
    List<List<PlacedQuantumGate>> rows,
  ) {
    var moved = true;
    while (moved) {
      moved = false;
      final footprints = _detachedLogicalFragments(rows).entries.toList()
        ..sort((a, b) => a.value.first.$3.compareTo(b.value.first.$3));
      for (final entry in footprints) {
        final fragments = entry.value;
        final columns = fragments.map((fragment) => fragment.$3).toSet();
        if (columns.length != 1) return null;
        final column = columns.single;
        if (column == 0 ||
            fragments.any((fragment) => !fragment.$2.isDeletable)) {
          continue;
        }
        final canMove = fragments.every(
          (fragment) =>
              _cellAt(rows, fragment.$1, column - 1).gate.type ==
              SelectedGateType.none,
        );
        if (!canMove) continue;
        for (final fragment in fragments) {
          rows[fragment.$1][column] = PlacedQuantumGate.emptyGate();
        }
        for (final fragment in fragments) {
          rows[fragment.$1][column - 1] = fragment.$2;
        }
        moved = true;
      }
    }
    return rows;
  }

  static bool _isValidLogicalGrid(
    List<List<PlacedQuantumGate>> proposed,
    List<List<PlacedQuantumGate>> original, {
    required GateId movedId,
    required int rowDelta,
  }) {
    final proposedFootprints = _detachedLogicalFragments(proposed);
    final originalFootprints = _detachedLogicalFragments(original);
    if (proposedFootprints.length != originalFootprints.length ||
        !proposedFootprints.keys.toSet().containsAll(originalFootprints.keys)) {
      return false;
    }
    for (final entry in originalFootprints.entries) {
      final result = proposedFootprints[entry.key];
      if (result == null || result.length != entry.value.length) return false;
      if (result.map((fragment) => fragment.$3).toSet().length != 1) {
        return false;
      }
      if (entry.key == movedId) {
        for (final originalFragment in entry.value) {
          final translatedQubit = originalFragment.$1 + rowDelta;
          final matching = result.where(
            (fragment) =>
                fragment.$1 == translatedQubit &&
                fragment.$2.gate == originalFragment.$2.gate &&
                fragment.$2.isControl == originalFragment.$2.isControl &&
                fragment.$2.isControl2 == originalFragment.$2.isControl2 &&
                fragment.$2.isTarget == originalFragment.$2.isTarget &&
                fragment.$2.isLink == originalFragment.$2.isLink &&
                fragment.$2.isDeletable == originalFragment.$2.isDeletable &&
                fragment.$2.controlQubitIndex ==
                    _translatedQubit(
                      originalFragment.$2.controlQubitIndex,
                      rowDelta,
                    ) &&
                fragment.$2.control2QubitIndex ==
                    _translatedQubit(
                      originalFragment.$2.control2QubitIndex,
                      rowDelta,
                    ) &&
                fragment.$2.targetQubitIndex ==
                    _translatedQubit(
                      originalFragment.$2.targetQubitIndex,
                      rowDelta,
                    ),
          );
          if (matching.length != 1) return false;
        }
      } else {
        final originalCells =
            entry.value.map((fragment) => fragment.$2).toSet();
        final resultCells = result.map((fragment) => fragment.$2).toSet();
        if (originalCells.length != resultCells.length ||
            !resultCells.containsAll(originalCells)) {
          return false;
        }
      }
    }
    return true;
  }

  static int? _translatedQubit(int? qubit, int rowDelta) =>
      qubit == null ? null : qubit + rowDelta;

  static bool _sameGridIdentity(
    List<List<PlacedQuantumGate>> current,
    List<List<PlacedQuantumGate>> plannedBase,
  ) {
    if (current.length != plannedBase.length) return false;
    for (var qubit = 0; qubit < current.length; qubit++) {
      if (current[qubit].length != plannedBase[qubit].length) return false;
      for (var column = 0; column < current[qubit].length; column++) {
        if (!identical(current[qubit][column], plannedBase[qubit][column])) {
          return false;
        }
      }
    }
    return true;
  }

  RemoveGateResult removeSingleGateById(GateId id) {
    final source = placedGateById(id);
    if (source == null) return RemoveGateResult.notFound;
    if (!source.isSingleQubit) return RemoveGateResult.notSingleQubit;
    return removeLogicalGateById(id);
  }

  RemoveGateResult removeLogicalGateById(GateId id) {
    final outcome = removeLogicalGateByIdWithOutcome(id);
    return switch (outcome.status) {
      CircuitEditStatus.changed => RemoveGateResult.removed,
      CircuitEditStatus.notFound => RemoveGateResult.notFound,
      CircuitEditStatus.protected => RemoveGateResult.notDeletable,
      _ => RemoveGateResult.notFound,
    };
  }

  CircuitEditOutcome removeLogicalGateByIdWithOutcome(GateId id) {
    final footprint = logicalGateById(id);
    if (footprint == null) return CircuitEditOutcome.notFound;
    if (!footprint.isDeletable) return CircuitEditOutcome.protected;

    for (final fragment in footprint.fragments) {
      placedGates[fragment.location.qubit][fragment.location.column] =
          PlacedQuantumGate.emptyGate();
    }
    shiftLeft();
    trimCircuit();
    notifyListeners();
    return CircuitEditOutcome(
      CircuitEditStatus.changed,
      affectedGateId: id,
    );
  }

  CircuitEditOutcome updateGateParametersWithOutcome(
    GateId id, {
    required double? angle,
  }) {
    final footprint = logicalGateById(id);
    if (footprint == null) return CircuitEditOutcome.notFound;
    if (!footprint.supportsParameterEditing) {
      return CircuitEditOutcome.unsupported;
    }
    if (!footprint.isParameterEditable) return CircuitEditOutcome.protected;
    if (angle == null || !angle.isFinite) return CircuitEditOutcome.invalid;
    final currentAngle = footprint.gate.angle;
    if (currentAngle != null && _anglesEquivalent(currentAngle, angle)) {
      return CircuitEditOutcome.same;
    }

    final updatedGate = Gate.fromIdentifier(footprint.type, angle: angle);
    if (!updatedGate.hasValidRequiredParameters) {
      return CircuitEditOutcome.invalid;
    }
    final fragment = footprint.fragments.single;
    final existing = fragment.placedGate;
    placedGates[fragment.location.qubit][fragment.location.column] =
        PlacedQuantumGate(
      id: existing.id,
      gate: updatedGate,
      controlQubitIndex: existing.controlQubitIndex,
      control2QubitIndex: existing.control2QubitIndex,
      targetQubitIndex: existing.targetQubitIndex,
      isTarget: existing.isTarget,
      isLink: existing.isLink,
      isControl: existing.isControl,
      isControl2: existing.isControl2,
      isDeletable: existing.isDeletable,
    );
    notifyListeners();
    return CircuitEditOutcome(
      CircuitEditStatus.changed,
      affectedGateId: id,
      resultingLocation: footprint.anchor,
    );
  }

  static bool _anglesEquivalent(double a, double b) {
    const tolerance = 1e-9;
    return (a - b).abs() <= tolerance * max(1.0, max(a.abs(), b.abs()));
  }

  static const Set<SelectedGateType> supportedSingleQubitReplacementTypes = {
    SelectedGateType.hadamard,
    SelectedGateType.s,
    SelectedGateType.t,
    SelectedGateType.x,
    SelectedGateType.y,
    SelectedGateType.z,
    SelectedGateType.rx,
    SelectedGateType.ry,
    SelectedGateType.rz,
  };

  List<SelectedGateType> get availableSingleQubitReplacementTypes {
    final available = <SelectedGateType>[];
    for (final gate in currentLevel.availableGates) {
      if (supportedSingleQubitReplacementTypes.contains(gate.type) &&
          !available.contains(gate.type)) {
        available.add(gate.type);
      }
    }
    return List.unmodifiable(available);
  }

  bool _isReplacementTypeAvailable(SelectedGateType type) =>
      availableSingleQubitReplacementTypes.contains(type);

  CircuitEditOutcome replaceSingleGateWithOutcome(
    GateId id,
    Gate replacement,
  ) {
    final footprint = logicalGateById(id);
    if (footprint == null) return CircuitEditOutcome.notFound;
    if (!footprint.isSingleQubit) return CircuitEditOutcome.unsupported;
    if (!footprint.isEditable) return CircuitEditOutcome.protected;
    if (!supportedSingleQubitReplacementTypes.contains(replacement.type)) {
      return CircuitEditOutcome.unsupported;
    }
    if (!_isReplacementTypeAvailable(replacement.type)) {
      return CircuitEditOutcome.protected;
    }
    if (!replacement.hasValidRequiredParameters) {
      return CircuitEditOutcome.invalid;
    }

    final current = footprint.gate;
    final sameConfiguration = current.type == replacement.type &&
        (!current.requiresAngle ||
            (current.angle != null &&
                replacement.angle != null &&
                _anglesEquivalent(current.angle!, replacement.angle!)));
    if (sameConfiguration) return CircuitEditOutcome.same;

    final fragment = footprint.fragments.single;
    final existing = fragment.placedGate;
    placedGates[fragment.location.qubit][fragment.location.column] =
        PlacedQuantumGate(
      id: existing.id,
      gate: replacement,
      controlQubitIndex: existing.controlQubitIndex,
      control2QubitIndex: existing.control2QubitIndex,
      targetQubitIndex: existing.targetQubitIndex,
      isTarget: existing.isTarget,
      isLink: existing.isLink,
      isControl: existing.isControl,
      isControl2: existing.isControl2,
      isDeletable: existing.isDeletable,
    );
    notifyListeners();
    return CircuitEditOutcome(
      CircuitEditStatus.changed,
      affectedGateId: id,
      resultingLocation: footprint.anchor,
    );
  }

  void insertDoublePlacedGateAt(Gate gate, int insertionPosition,
      int targetQubitIndex, int controlQubitIndex,
      {bool isDeletable = true}) {
    insertDoubleGateWithOutcome(
      gate,
      insertionPosition,
      targetQubitIndex,
      controlQubitIndex,
      isDeletable: isDeletable,
    );
  }

  CircuitEditOutcome insertDoubleGateWithOutcome(Gate gate,
      int insertionPosition, int targetQubitIndex, int controlQubitIndex,
      {bool isDeletable = true}) {
    if ((gate.type != SelectedGateType.cnot &&
            gate.type != SelectedGateType.cz) ||
        insertionPosition < 0 ||
        targetQubitIndex < 0 ||
        targetQubitIndex >= currentLevel.numQubits ||
        controlQubitIndex < 0 ||
        controlQubitIndex >= currentLevel.numQubits ||
        targetQubitIndex == controlQubitIndex) {
      return CircuitEditOutcome.invalid;
    }
    final gateId = _allocateGateId();
    // need to check if the area to place the gate is fully empty then,
    int from = min(controlQubitIndex, targetQubitIndex);
    int to = max(controlQubitIndex, targetQubitIndex);

    debugPrint('Insertion position: $insertionPosition, from: $from, to: $to');

    insertionPosition = min(insertionPosition, maxCircuitDepth());

    bool allEmpty = true;
    for (int i = from; i <= to; i++) {
      if (insertionPosition < placedGates[i].length &&
          placedGates[i][insertionPosition].gate.type !=
              SelectedGateType.none) {
        allEmpty = false;
        break;
      }
    }

    // There is no need to scroll,
    if (allEmpty) {
      for (int i = from; i <= to; i++) {
        if (i == controlQubitIndex) {
          PlacedQuantumGate controlGate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
            isControl: true,
            controlQubitIndex: controlQubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(controlGate, insertionPosition, i);
        } else if (i == targetQubitIndex) {
          PlacedQuantumGate targetGate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
            isTarget: true,
            controlQubitIndex: controlQubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(targetGate, insertionPosition, i);
        } else {
          PlacedQuantumGate linkGate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
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
            id: gateId,
            gate: gate,
            isControl: true,
            controlQubitIndex: controlQubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(controlGate, insertionPosition, i);
        } else if (i == targetQubitIndex) {
          PlacedQuantumGate targetGate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
            isTarget: true,
            controlQubitIndex: controlQubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(targetGate, insertionPosition, i);
        } else if (i > controlQubitIndex && i < targetQubitIndex ||
            i < controlQubitIndex && i > targetQubitIndex) {
          PlacedQuantumGate linkGate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
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
    }

    // Second phase, we need to scroll left what is scrollable.
    shiftLeft();

    trimCircuit();

    // Notify listeners that the state has changed
    notifyListeners();
    return CircuitEditOutcome(
      CircuitEditStatus.changed,
      affectedGateId: gateId,
      resultingLocation: logicalGateById(gateId)?.anchor,
    );
  }

  void insertTriplePlacedGateAt(Gate gate, int insertionPosition,
      int targetQubitIndex, int control1QubitIndex, int control2QubitIndex,
      {bool isDeletable = true}) {
    insertTripleGateWithOutcome(
      gate,
      insertionPosition,
      targetQubitIndex,
      control1QubitIndex,
      control2QubitIndex,
      isDeletable: isDeletable,
    );
  }

  CircuitEditOutcome insertTripleGateWithOutcome(
      Gate gate,
      int insertionPosition,
      int targetQubitIndex,
      int control1QubitIndex,
      int control2QubitIndex,
      {bool isDeletable = true}) {
    final qubits = {targetQubitIndex, control1QubitIndex, control2QubitIndex};
    if (gate.type != SelectedGateType.ccnot ||
        insertionPosition < 0 ||
        qubits.length != 3 ||
        qubits.any((qubit) => qubit < 0 || qubit >= currentLevel.numQubits)) {
      return CircuitEditOutcome.invalid;
    }
    final gateId = _allocateGateId();
    // need to check if the area to place the gate is fully empty then,
    List<int> controls = [
      control1QubitIndex,
      control2QubitIndex,
      targetQubitIndex
    ];
    int from = controls.reduce(min);
    int to = controls.reduce(max);

    bool allEmpty = true;
    for (int i = from; i <= to; i++) {
      if (insertionPosition < placedGates[i].length &&
          placedGates[i][insertionPosition].gate.type !=
              SelectedGateType.none) {
        allEmpty = false;
        break;
      }
    }

    // There is no need to scroll,
    if (allEmpty) {
      for (int i = from; i <= to; i++) {
        if (i == control1QubitIndex) {
          PlacedQuantumGate controlGate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
            isControl: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(controlGate, insertionPosition, i);
        } else if (i == targetQubitIndex) {
          PlacedQuantumGate targetGate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
            isTarget: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(targetGate, insertionPosition, i);
        } else if (i == control2QubitIndex) {
          PlacedQuantumGate control2Gate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
            isControl2: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(control2Gate, insertionPosition, i);
        } else {
          PlacedQuantumGate linkGate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
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
            id: gateId,
            gate: gate,
            isControl: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(controlGate, insertionPosition, i);
        } else if (i == targetQubitIndex) {
          PlacedQuantumGate targetGate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
            isTarget: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(targetGate, insertionPosition, i);
        } else if (i == control2QubitIndex) {
          PlacedQuantumGate control2Gate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
            isControl2: true,
            controlQubitIndex: control1QubitIndex,
            control2QubitIndex: control2QubitIndex,
            targetQubitIndex: targetQubitIndex,
            isDeletable: isDeletable,
          );
          insertGateAt(control2Gate, insertionPosition, i);
        } else if (i > control1QubitIndex && i < targetQubitIndex ||
            i < control1QubitIndex && i > targetQubitIndex) {
          PlacedQuantumGate linkGate = PlacedQuantumGate(
            id: gateId,
            gate: gate,
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
    }

    // Second phase, we need to scroll left what is scrollable.
    shiftLeft();

    trimCircuit();

    // Notify listeners that the state has changed
    notifyListeners();
    return CircuitEditOutcome(
      CircuitEditStatus.changed,
      affectedGateId: gateId,
      resultingLocation: logicalGateById(gateId)?.anchor,
    );
  }

  // Method to remove a specific placed gate instance from the circuit
  bool removePlacedGate(int gatePosition, int qubitLine) {
    PlacedQuantumGate gateToRemove = placedGates[qubitLine][gatePosition];
    final logicalId = gateToRemove.id;
    if (logicalId != null) {
      return removeLogicalGateById(logicalId) == RemoveGateResult.removed;
    }
    if (gateToRemove.gate.type == SelectedGateType.none) {
      return false;
    } else if ((gateToRemove.gate.type == SelectedGateType.cnot ||
            gateToRemove.gate.type == SelectedGateType.cz) &&
        gateToRemove.isDeletable) {
      List<int> controls = [
        gateToRemove.controlQubitIndex!,
        gateToRemove.targetQubitIndex!
      ];
      for (int i = controls.reduce(min); i <= controls.reduce(max); i++) {
        placedGates[i][gatePosition] = PlacedQuantumGate.emptyGate();
      }
    } else if (gateToRemove.gate.type == SelectedGateType.ccnot &&
        gateToRemove.isDeletable) {
      List<int> controls = [
        gateToRemove.controlQubitIndex!,
        gateToRemove.control2QubitIndex!,
        gateToRemove.targetQubitIndex!
      ];
      for (int i = controls.reduce(min); i <= controls.reduce(max); i++) {
        placedGates[i][gatePosition] = PlacedQuantumGate.emptyGate();
      }
    } else if (gateToRemove.isDeletable) {
      placedGates[qubitLine][gatePosition] = PlacedQuantumGate.emptyGate();
    } else {
      debugPrint(
          'Gate type [${gateToRemove.gate.type}] not deletable at qubit line: $qubitLine and gate position: $gatePosition');
      return false;
    }

    debugPrint(
        'Gate type [${gateToRemove.gate.type}] removed at qubit line: $qubitLine and gate position: $gatePosition');

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
      while (rightPosition >= 1) {
        for (int i = 0; i < currentLevel.numQubits; i++) {
          if (rightPosition < placedGates[i].length &&
              placedGates[i][rightPosition].gate.type !=
                  SelectedGateType.none) {
            var rightGate = placedGates[i][rightPosition];
            if (rightGate.gate.type == SelectedGateType.cnot ||
                rightGate.gate.type == SelectedGateType.cz) {
              int endLine = rightGate.isTarget
                  ? rightGate.controlQubitIndex!
                  : rightGate.targetQubitIndex!;
              bool canBeMoved = true;
              for (int j = i; j <= endLine; j++) {
                if (placedGates[j][rightPosition - 1].gate.type !=
                    SelectedGateType.none) {
                  canBeMoved = false;
                  break;
                }
              }
              if (canBeMoved) {
                for (int j = i; j <= endLine; j++) {
                  placedGates[j][rightPosition - 1] =
                      placedGates[j][rightPosition];
                  placedGates[j][rightPosition] = PlacedQuantumGate.emptyGate();
                  repeat = true;
                }
              }
              i = max(i, endLine);
            } else if (rightGate.gate.type == SelectedGateType.ccnot) {
              int endLine = [
                rightGate.controlQubitIndex!,
                rightGate.control2QubitIndex!,
                rightGate.targetQubitIndex!
              ].reduce(max);
              bool canBeMoved = true;
              for (int j = i; j <= endLine; j++) {
                if (placedGates[j][rightPosition - 1].gate.type !=
                    SelectedGateType.none) {
                  canBeMoved = false;
                  break;
                }
              }
              if (canBeMoved) {
                for (int j = i; j <= endLine; j++) {
                  placedGates[j][rightPosition - 1] =
                      placedGates[j][rightPosition];
                  placedGates[j][rightPosition] = PlacedQuantumGate.emptyGate();
                }
                repeat = true;
              }
              i = max(i, endLine);
            } else {
              if (placedGates[i][rightPosition - 1].gate.type ==
                  SelectedGateType.none) {
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
    } while (repeat);
  }

  void insertGateAt(PlacedQuantumGate gateToInsert, int insertionPosition,
      int targetQubitIndex) {
    if (insertionPosition > placedGates[targetQubitIndex].length) {
      // Insert empty filler
      final int lengthFiller =
          (placedGates[targetQubitIndex].length - insertionPosition).abs();
      final fillerList = List<PlacedQuantumGate>.filled(
          lengthFiller, PlacedQuantumGate.emptyGate());
      placedGates[targetQubitIndex].addAll(fillerList);
    }
    placedGates[targetQubitIndex].insert(insertionPosition, gateToInsert);
  }

  void trimCircuit() {
    for (int i = 0; i < currentLevel.numQubits; i++) {
      while (placedGates[i].isNotEmpty &&
          placedGates[i].last.gate.type == SelectedGateType.none) {
        placedGates[i].removeLast();
      }
    }
  }

  // Method to clear all placed gates from the circuit
  void clearPlacedGates() {
    clearPlacedGatesWithOutcome();
  }

  CircuitEditOutcome clearPlacedGatesWithOutcome() {
    if (isCircuitEmpty()) return CircuitEditOutcome.same;
    // placedGates.clear();
    placedGates = List.generate(currentLevel.numQubits, (index) => []);
    // Reset the currentState back to the initial ground state
    currentState = QubitState.fromList(currentLevel.initialQubitsState);
    currentLevel.preInsertGates(this);
    debugPrint(
        "Circuit cleared. Total placed gates: ${placedGates.length}"); // Debug debugPrint
    // ** Notify listeners that the state has changed **
    notifyListeners();
    return const CircuitEditOutcome(CircuitEditStatus.changed);
  }

  List<List<PlacedQuantumGate>> clone(List<List<PlacedQuantumGate>> gates) =>
      placedGates = gates
          .map((element) => List<PlacedQuantumGate>.from(element))
          .toList();

  // --- BACKEND MATRIX GENERATION LOGIC ---

  /// Builds the system matrix for a single placed quantum gate.
  QuantumMatrix _buildSystemMatrixForPlacedGate(
    PlacedQuantumGate gate, {
    required int columnIndex,
    required int qubitIndex,
  }) {
    switch (gate.gate.type) {
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
      case SelectedGateType.rx:
        _requireRotationAngle(gate, columnIndex, qubitIndex);
        return QuantumMatrix.rx(gate.gate.angle!);
      case SelectedGateType.ry:
        _requireRotationAngle(gate, columnIndex, qubitIndex);
        return QuantumMatrix.ry(gate.gate.angle!);
      case SelectedGateType.rz:
        _requireRotationAngle(gate, columnIndex, qubitIndex);
        return QuantumMatrix.rz(gate.gate.angle!);
      case SelectedGateType
            .cz: // at this point we consider only CZ gates control
        return QuantumMatrix.cz(
            control: gate.controlQubitIndex!, target: gate.targetQubitIndex!);
      case SelectedGateType
            .cnot: // at this point we consider only CNOT gates control
        return QuantumMatrix.cnot(
            control: gate.controlQubitIndex!, target: gate.targetQubitIndex!);
      case SelectedGateType.ccnot:
        return QuantumMatrix.ccnot(
            control1: gate.controlQubitIndex!,
            control2: gate.control2QubitIndex!,
            target: gate.targetQubitIndex!);
      case SelectedGateType.none:
        return QuantumMatrix.identity(2);
      default:
        throw UnimplementedError();
    }
  }

  void _requireRotationAngle(
    PlacedQuantumGate gate,
    int columnIndex,
    int qubitIndex,
  ) {
    if (gate.gate.angle == null || !gate.gate.angle!.isFinite) {
      throw MalformedCircuitException(
        gateType: gate.gate.type,
        columnIndex: columnIndex,
        qubitIndex: qubitIndex,
        parameterName: 'angle',
      );
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
      QuantumMatrix gateSystemMatrix = _buildSystemMatrixForPlacedGate(
        gate,
        columnIndex: columnIndex,
        qubitIndex: q,
      );
      columnOverallMatrix = columnOverallMatrix == null
          ? gateSystemMatrix
          : gateSystemMatrix.tensorProduct(columnOverallMatrix);

      debugPrint(gateSystemMatrix.toString());

      if (gate.gate.type == SelectedGateType.cnot ||
          gate.gate.type == SelectedGateType.cz) {
        // skip to the next qubit after the CNOT/CZ
        q = max(gate.controlQubitIndex!, gate.targetQubitIndex!);
        continue;
      } else if (gate.gate.type == SelectedGateType.ccnot) {
        // skip to the next qubit after the CCNOT
        q = [
          gate.controlQubitIndex!,
          gate.targetQubitIndex!,
          gate.control2QubitIndex!
        ].reduce(max);
        continue;
      }
    }
    return columnOverallMatrix!;
  }

  /// Generates the overall unitary matrix representing the entire quantum circuit.
  /// This is the "transform operator".
  QuantumMatrix getOverallCircuitMatrix() {
    lastSimulationError = null;
    int totalDepth = maxCircuitDepth();
    if (totalDepth == 0) {
      return QuantumMatrix.identity(
          1 << currentLevel.numQubits); // Empty circuit is identity
    }

    QuantumMatrix overallMatrix =
        QuantumMatrix.identity(1 << currentLevel.numQubits);

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
    simulationRunCount++;
    try {
      QuantumMatrix circuitMatrix = getOverallCircuitMatrix();
      debugPrint("Initial state: $initialState");
      currentState = initialState.applyMatrix(circuitMatrix);
      debugPrint("Final state: $initialState");
      lastSimulationError = null;
    } on MalformedCircuitException catch (error) {
      lastSimulationError = error;
      assert(() {
        debugPrint('Circuit simulation blocked: $error');
        return true;
      }());
    }
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
          if (gate.gate.type == SelectedGateType.cz) {
            if (gate.isControl) {
              gateChar = "C";
            } else if (gate.isTarget) {
              gateChar = "Z";
            } else if (gate.isLink) {
              gateChar = "|";
            } else {
              gateChar = "?"; // Should not happen for CZ
            }
          }
          if (gate.gate.type == SelectedGateType.cnot) {
            if (gate.isControl) {
              gateChar = "C";
            } else if (gate.isTarget) {
              gateChar = "X";
            } else if (gate.isLink) {
              gateChar = "|";
            } else {
              gateChar = "?"; // Should not happen for CNOT
            }
          } else if (gate.gate.type == SelectedGateType.ccnot) {
            if (gate.isControl) gateChar = "C";
            if (gate.isControl2) {
              gateChar = "C";
            } else if (gate.isTarget) {
              gateChar = "T";
            } else if (gate.isLink) {
              gateChar = "|";
            } else {
              gateChar = "?"; // Should not happen for CCNOT
            }
          } else if (gate.gate.type == SelectedGateType.none) {
            gateChar = "-";
          } else {
            gateChar = gate.gate.label;
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
