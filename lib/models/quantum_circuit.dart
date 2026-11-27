import 'circuit_program.dart';
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
    if (parameterName != 'angle') {
      return 'The $gateLabel gate is incomplete. Remove it and place it again.';
    }
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
  bool _suppressStructuralNotifications = false;

  GateId _allocateGateId() {
    final used = <int>{
      for (final row in placedGates)
        for (final cell in row)
          if (cell.id != null) cell.id!.value,
    };
    while (used.contains(_nextGateId)) {
      _nextGateId++;
    }
    return GateId(_nextGateId++);
  }

  // ── Measurements ─────────────────────────────────────────────────────────
  //
  // A measurement is a single-qubit grid cell ([SelectedGateType.measureZ])
  // carrying its classical destination. Living in the grid, measurements take
  // part in the same column shifting, compaction and move planning as gates,
  // which never reorder cells within one qubit row. Ordering rules that the
  // grid alone cannot express are enforced by [_orderingFacts].

  /// Exclusive upper bound for classical destinations (schema-2 width limit).
  static const int maxClassicalBits = 1024;

  static PlacedQuantumGate _measurementCell(GateId id, int classicalBit) =>
      PlacedQuantumGate(
        id: id,
        gate: Gate.fromIdentifier(SelectedGateType.measureZ),
        classicalBit: classicalBit,
      );

  /// Measurements stored in [rows], ordered by column then qubit.
  static List<MeasureZOperation> measurementsInRows(
    List<List<PlacedQuantumGate>> rows,
  ) {
    final result = <MeasureZOperation>[];
    for (final (qubit, row) in rows.indexed) {
      for (final (column, cell) in row.indexed) {
        if (cell.isMeasurement && cell.id != null) {
          result.add(MeasureZOperation(
            id: cell.id!,
            column: column,
            qubit: qubit,
            classicalBit: cell.classicalBit ?? 0,
          ));
        }
      }
    }
    result.sort((a, b) {
      final column = a.column.compareTo(b.column);
      return column != 0 ? column : a.qubit.compareTo(b.qubit);
    });
    return result;
  }

  List<MeasureZOperation> get measurements =>
      List.unmodifiable(measurementsInRows(placedGates));
  bool get hasMeasurements =>
      placedGates.any((row) => row.any((cell) => cell.isMeasurement));

  MeasureZOperation? measurementById(GateId id) {
    for (final m in measurementsInRows(placedGates)) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Ordering facts an edit must never newly create:
  /// * `t:m:op` — an operation acts on a qubit after that qubit's
  ///   measurement `m` (terminal-measurement policy; links are not operands);
  /// * `c:a:b` / `c=a:b` — measurements sharing a classical bit, ordered or
  ///   in one column.
  /// Legacy circuits may already contain such facts; edits keep them (IDs are
  /// stable) but cannot add new ones.
  static Set<String> _orderingFacts(List<List<PlacedQuantumGate>> rows) {
    final facts = <String>{};
    final measured = measurementsInRows(rows);
    for (final m in measured) {
      final row = rows[m.qubit];
      for (var column = m.column + 1; column < row.length; column++) {
        final cell = row[column];
        if (cell.id == null ||
            cell.gate.type == SelectedGateType.none ||
            cell.isLink) {
          continue;
        }
        facts.add('t:${m.id.value}:${cell.id!.value}');
      }
    }
    for (final a in measured) {
      for (final b in measured) {
        if (a.id == b.id || a.classicalBit != b.classicalBit) continue;
        if (a.column < b.column) {
          facts.add('c:${a.id.value}:${b.id.value}');
        } else if (a.column == b.column && a.id.value < b.id.value) {
          facts.add('c=${a.id.value}:${b.id.value}');
        }
      }
    }
    return facts;
  }

  static const String terminalMeasurementReason =
      'A measured qubit cannot receive further operations. Place gates '
      'before the measurement on that qubit.';
  static const String classicalOrderReason =
      'Each classical bit can be written by one measurement.';

  static String? _orderingRegression(
    List<List<PlacedQuantumGate>> before,
    List<List<PlacedQuantumGate>> after,
  ) {
    final added = _orderingFacts(after).difference(_orderingFacts(before));
    if (added.isEmpty) return null;
    return added.any((fact) => fact.startsWith('t:'))
        ? terminalMeasurementReason
        : classicalOrderReason;
  }

  /// Whether the circuit already breaks the terminal-measurement policy
  /// (possible only for circuits saved before it existed). Such circuits stay
  /// as saved; edits may not add further violations.
  bool get hasPostMeasurementOperations =>
      _orderingFacts(placedGates).any((fact) => fact.startsWith('t:'));

  int _deferredNotificationDepth = 0;
  bool _pendingNotification = false;

  @override
  void notifyListeners() {
    if (_deferredNotificationDepth > 0) {
      _pendingNotification = true;
      return;
    }
    super.notifyListeners();
  }

  /// Runs [edit] with notifications deferred, then keeps it only if it
  /// changed the circuit without adding ordering violations and [dryRun] is
  /// false. Otherwise the grid and ID allocator are restored exactly (cell
  /// identities included) and listeners never observe the attempt.
  ({CircuitEditOutcome outcome, List<List<PlacedQuantumGate>> rows})
      _transaction(CircuitEditOutcome Function() edit, {bool dryRun = false}) {
    final baseRows = _copyRows(placedGates);
    final baseNextId = _nextGateId;
    final wasPending = _pendingNotification;
    _pendingNotification = false;
    _deferredNotificationDepth++;
    CircuitEditOutcome outcome;
    try {
      outcome = edit();
    } catch (_) {
      placedGates = baseRows;
      _nextGateId = baseNextId;
      _pendingNotification = wasPending;
      rethrow;
    } finally {
      _deferredNotificationDepth--;
    }
    if (outcome.changed) {
      final reason = _orderingRegression(baseRows, placedGates);
      if (reason != null) {
        outcome = CircuitEditOutcome(CircuitEditStatus.invalid, detail: reason);
      }
    }
    final proposed = _copyRows(placedGates);
    final keep = outcome.changed && !dryRun;
    if (!keep) {
      placedGates = baseRows;
      _nextGateId = baseNextId;
    }
    final notify = keep && _pendingNotification;
    _pendingNotification = wasPending;
    if (notify) notifyListeners();
    return (outcome: outcome, rows: proposed);
  }

  /// Gate edits are unchanged for unmeasured circuits; with measurements they
  /// are validated against the ordering rules and rolled back if rejected.
  CircuitEditOutcome _guardOrdering(CircuitEditOutcome Function() edit) =>
      hasMeasurements ? _transaction(edit).outcome : edit();

  /// Low-level exact placement into an empty cell (tests and constructed
  /// programs). Never shifts, compacts or applies editing policy; Composer
  /// editing uses [insertMeasurementWithOutcome].
  MeasureZOperation addMeasurement(
      {required int column, required int qubit, required int classicalBit}) {
    if (classicalBit < 0 ||
        classicalBit >= maxClassicalBits ||
        qubit < 0 ||
        qubit >= currentLevel.numQubits ||
        column < 0 ||
        _cellAt(placedGates, qubit, column).gate.type !=
            SelectedGateType.none) {
      throw const InvalidCircuitProgram('Invalid or occupied measurement slot');
    }
    final id = _allocateGateId();
    final row = placedGates[qubit];
    while (row.length <= column) {
      row.add(PlacedQuantumGate.emptyGate());
    }
    row[column] = _measurementCell(id, classicalBit);
    notifyListeners();
    return measurementById(id)!;
  }

  CircuitEditOutcome _insertMeasurement(int qubit, int column, int? bit) {
    final classicalBit = bit ?? qubit;
    if (qubit < 0 ||
        qubit >= currentLevel.numQubits ||
        column < 0 ||
        classicalBit < 0 ||
        classicalBit >= maxClassicalBits) {
      return CircuitEditOutcome.invalid;
    }
    final id = _allocateGateId();
    return _insertSingleCell(_measurementCell(id, classicalBit), column, qubit);
  }

  /// Inserts a measurement like a single-qubit gate: into an empty slot, or
  /// by shifting later operations right. The classical destination defaults
  /// to the measured qubit index. Rejected (without change) when the qubit
  /// already has later operations or the classical bit is in use.
  CircuitEditOutcome insertMeasurementWithOutcome({
    required int qubit,
    required int column,
    int? classicalBit,
  }) =>
      _transaction(() => _insertMeasurement(qubit, column, classicalBit))
          .outcome;

  /// Dry run of [insertMeasurementWithOutcome]; returns the proposed grid for
  /// previews. Never mutates or notifies.
  ({CircuitEditOutcome outcome, List<List<PlacedQuantumGate>> rows})
      previewMeasurementInsertion({
    required int qubit,
    required int column,
    int? classicalBit,
  }) =>
          _transaction(() => _insertMeasurement(qubit, column, classicalBit),
              dryRun: true);

  /// Dry run of a single-qubit gate insertion, used for drop previews.
  ({
    CircuitEditOutcome outcome,
    List<List<PlacedQuantumGate>> rows
  }) previewSingleGateInsertion(Gate gate, CircuitLocation location) =>
      _transaction(
        () => _insertSingleGate(gate, location.column, location.qubit),
        dryRun: true,
      );

  /// Horizontal move of a measurement on its own qubit, using the shared
  /// logical move planner (shifting and compaction included).
  LogicalMovePlan planMeasurementMove(GateId id, int column) {
    final footprint = _footprintById(id);
    if (footprint == null || !footprint.isMeasurement) {
      return LogicalMovePlan(
        status: CircuitEditStatus.notFound,
        sourceId: id,
        baseRows: _copyRows(placedGates),
        reason: 'Measurement not found.',
      );
    }
    return _planMove(
      id,
      CircuitLocation(qubit: footprint.anchor.qubit, column: column),
      footprint,
    );
  }

  CircuitEditOutcome moveMeasurementWithOutcome(GateId id, int column) =>
      commitLogicalGateMovePlan(planMeasurementMove(id, column));

  /// Changes only the classical destination; ID, qubit and column are kept.
  CircuitEditOutcome updateMeasurementClassicalBitWithOutcome(
    GateId id,
    int classicalBit,
  ) {
    if (classicalBit < 0 || classicalBit >= maxClassicalBits) {
      return const CircuitEditOutcome(
        CircuitEditStatus.invalid,
        detail: 'Invalid classical bit.',
      );
    }
    final current = measurementById(id);
    if (current == null) return CircuitEditOutcome.notFound;
    if (current.classicalBit == classicalBit) return CircuitEditOutcome.same;
    return _transaction(() {
      placedGates[current.qubit][current.column] =
          _measurementCell(id, classicalBit);
      notifyListeners();
      return CircuitEditOutcome(CircuitEditStatus.changed, affectedGateId: id);
    }).outcome;
  }

  /// Returns false when nothing changed; throws when the update is invalid.
  bool updateMeasurementClassicalBit(GateId id, int classicalBit) {
    final outcome = updateMeasurementClassicalBitWithOutcome(id, classicalBit);
    if (outcome.status == CircuitEditStatus.invalid ||
        outcome.status == CircuitEditStatus.notFound) {
      throw InvalidCircuitProgram(outcome.detail ?? 'Measurement not found');
    }
    return outcome.changed;
  }

  CircuitEditOutcome removeMeasurementWithOutcome(GateId id) {
    final current = measurementById(id);
    if (current == null) return CircuitEditOutcome.notFound;
    return _transaction(() {
      placedGates[current.qubit][current.column] =
          PlacedQuantumGate.emptyGate();
      shiftLeft();
      trimCircuit();
      notifyListeners();
      return CircuitEditOutcome(CircuitEditStatus.changed, affectedGateId: id);
    }).outcome;
  }

  bool removeMeasurement(GateId id) => removeMeasurementWithOutcome(id).changed;

  // ── Edit snapshots (session-local undo/redo) ─────────────────────────────

  /// Lossless in-memory capture of the editable definition: the grid with
  /// gate identities, fixed-gate flags, rotation parameters, control/target
  /// roles and measurement destinations, plus the classical width and the
  /// ID allocator. The level (qubit count, initial state, available gates)
  /// is not captured because it never changes for one circuit. Never
  /// persisted and independent of the schema-2 Sandbox format.
  CircuitEditSnapshot captureEditSnapshot() => CircuitEditSnapshot._(
        rows: List<List<PlacedQuantumGate>>.unmodifiable([
          for (final row in placedGates)
            List<PlacedQuantumGate>.unmodifiable(row),
        ]),
        nextGateId: _nextGateId,
        reservedClassicalBits: _reservedClassicalBits,
        numQubits: currentLevel.numQubits,
      );

  /// Replaces the definition with [snapshot] exactly (same cell identities)
  /// and notifies once. Never applies editing rules: the snapshot was
  /// captured from a valid committed state of this circuit. The ID allocator
  /// only moves forward, so IDs of gates removed by a restore are never
  /// reused. The caller re-runs simulation where applicable.
  void restoreEditSnapshot(CircuitEditSnapshot snapshot) {
    if (snapshot.numQubits != currentLevel.numQubits) {
      throw ArgumentError.value(
        snapshot.numQubits,
        'snapshot.numQubits',
        'does not match this circuit (${currentLevel.numQubits} qubits)',
      );
    }
    placedGates = [
      for (final row in snapshot.rows) List<PlacedQuantumGate>.from(row),
    ];
    _nextGateId = max(_nextGateId, snapshot.nextGateId);
    _reservedClassicalBits = snapshot.reservedClassicalBits;
    notifyListeners();
  }

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

  final Map<GateId, int> _restoredOrder = {};
  int? restoredOrderFor(GateId id) => _restoredOrder[id];
  int _reservedClassicalBits = 0;
  int get classicalBitCount => measurementsInRows(placedGates).fold(
      _reservedClassicalBits, (width, m) => max(width, m.classicalBit + 1));

  /// Validated definition restoration only: no editing compaction or simulation.
  QuantumCircuit.restoreProgram(
      {required this.currentLevel, required CircuitProgram program})
      : initialState = QubitState.fromList(program.initialState),
        currentState = QubitState.fromList(program.initialState),
        placedGates = List.generate(program.qubitCount, (_) => []) {
    if (currentLevel.numQubits != program.qubitCount ||
        !listEquals(currentLevel.initialQubitsState, program.initialState)) {
      throw const InvalidCircuitProgram(
          'Restoration level does not match program');
    }
    _reservedClassicalBits = program.classicalBitCount;
    for (final op in program.operations) {
      _restoredOrder[op.id] = _restoredOrder.length;
      _nextGateId = max(_nextGateId, op.id.value + 1);
      switch (op) {
        case MeasureZOperation():
          final row = placedGates[op.qubit];
          while (row.length <= op.column) {
            row.add(PlacedQuantumGate.emptyGate());
          }
          if (row[op.column].gate.type != SelectedGateType.none) {
            throw const InvalidCircuitProgram('Overlapping editor footprints');
          }
          row[op.column] = _measurementCell(op.id, op.classicalBit);
        case UnitaryOperation():
          final operands = [op.target, ...op.controls];
          final controlled = op.controls.isNotEmpty;
          final from = controlled ? operands.reduce(min) : op.target;
          final to = controlled ? operands.reduce(max) : op.target;
          for (var q = from; q <= to; q++) {
            final row = placedGates[q];
            while (row.length <= op.column) {
              row.add(PlacedQuantumGate.emptyGate());
            }
            if (row[op.column].gate.type != SelectedGateType.none) {
              throw const InvalidCircuitProgram(
                  'Overlapping editor footprints');
            }
            row[op.column] = PlacedQuantumGate(
                id: op.id,
                gate: op.gate,
                isDeletable: op.isDeletable,
                controlQubitIndex: op.control,
                control2QubitIndex: op.secondControl,
                controlQubitIndices: op.multiControls,
                targetQubitIndex: controlled ? op.target : null,
                isControl:
                    q == op.control || (op.multiControls?.contains(q) ?? false),
                isControl2: q == op.secondControl,
                isTarget: controlled && q == op.target,
                isLink: controlled && !operands.contains(q));
          }
      }
    }
    if (logicalGates.any((g) => !g.hasValidTopology(program.qubitCount))) {
      throw const InvalidCircuitProgram('Invalid restored footprint');
    }
  }

  int maxCircuitDepth() => placedGates.map((e) => e.length).reduce(max);

  /// The first column after all protected authored operations.
  ///
  /// This describes the authored prefix depth for presentation and auditing.
  /// Editing remains footprint-aware: protected operations cannot move, while
  /// independent learner operations on other wires may share their columns.
  int get learnerEditableStartColumn {
    var boundary = 0;
    for (final footprint in logicalGates) {
      if (!footprint.isDeletable) {
        boundary = max(boundary, footprint.column + 1);
      }
    }
    return boundary;
  }

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
          {bool isDeletable = true,
          GateId? gateId,
          bool notifyChange = true}) =>
      _guardOrdering(() => _insertSingleGate(
            gate,
            insertionPosition,
            tappedQubitIndex,
            isDeletable: isDeletable,
            gateId: gateId,
            notifyChange: notifyChange,
          ));

  CircuitEditOutcome _insertSingleGate(
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

    if (gateId != null && measurementById(gateId) != null) {
      return CircuitEditOutcome.invalid;
    }
    final resolvedId = gateId ?? _allocateGateId();
    final outcome = _insertSingleCell(
      PlacedQuantumGate(id: resolvedId, gate: gate, isDeletable: isDeletable),
      insertionPosition,
      tappedQubitIndex,
      notifyChange: notifyChange,
    );
    return CircuitEditOutcome(
      outcome.status,
      affectedGateId: resolvedId,
      resultingLocation: logicalGateById(resolvedId)?.anchor,
    );
  }

  /// Places one single-qubit cell (gate or measurement): into an empty slot,
  /// or by inserting a vertical line that shifts later operations right, then
  /// compacts. Shared by gate and measurement insertion.
  CircuitEditOutcome _insertSingleCell(
    PlacedQuantumGate gateToInsert,
    int insertionPosition,
    int tappedQubitIndex, {
    bool notifyChange = true,
  }) {
    insertionPosition = _firstColumnWithoutProtectedCollision(
      placedGates,
      destinationQubits: [tappedQubitIndex],
      requestedColumn: insertionPosition,
    );

    if (placedGates[tappedQubitIndex].length <= insertionPosition) {
      insertGateAt(gateToInsert, insertionPosition, tappedQubitIndex);
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
    }

    shiftLeft();
    trimCircuit();

    if (notifyChange && !_suppressStructuralNotifications) notifyListeners();
    final id = gateToInsert.id!;
    final measurement = measurementById(id);
    return CircuitEditOutcome(
      CircuitEditStatus.changed,
      affectedGateId: id,
      resultingLocation: measurement == null
          ? logicalGateById(id)?.anchor
          : CircuitLocation(
              qubit: measurement.qubit, column: measurement.column),
    );
  }

  /// Unitary gate footprints only; measurements are listed by [measurements].
  List<LogicalGateFootprint> get logicalGates {
    final ids = <GateId>{};
    for (final row in placedGates) {
      for (final gate in row) {
        if (gate.id != null && !gate.isMeasurement) ids.add(gate.id!);
      }
    }
    return ids
        .map(logicalGateById)
        .whereType<LogicalGateFootprint>()
        .toList(growable: false);
  }

  /// Unitary gate footprint; null for measurements and unknown IDs.
  LogicalGateFootprint? logicalGateById(GateId id) {
    final footprint = _footprintById(id);
    return footprint == null || footprint.type == SelectedGateType.measureZ
        ? null
        : footprint;
  }

  /// Any grid footprint, measurements included (editing internals only).
  LogicalGateFootprint? _footprintById(GateId id) {
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
      controlQubits: canonical.controlQubitIndices,
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
  ) =>
      _planMove(id, destination, logicalGateById(id));

  LogicalMovePlan _planMove(
    GateId id,
    CircuitLocation destination,
    LogicalGateFootprint? footprint,
  ) {
    final baseRows = _copyRows(placedGates);
    LogicalMovePlan rejected(CircuitEditStatus status, String reason) =>
        LogicalMovePlan(
          status: status,
          sourceId: id,
          baseRows: baseRows,
          reason: reason,
        );

    if (footprint == null) {
      return rejected(CircuitEditStatus.notFound, 'Source GateId not found.');
    }
    if (!footprint.isDeletable) {
      return rejected(CircuitEditStatus.protected, 'Source gate is protected.');
    }
    if (!footprint.hasValidTopology(currentLevel.numQubits)) {
      return rejected(
        CircuitEditStatus.invalid,
        'Source logical footprint is malformed.',
      );
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
      final makeRoomStatus = _shiftConflictingLogicalGatesRight(
        compacted,
        destinationQubits: destinationQubits,
        destinationColumn: resolvedColumn,
      );
      if (makeRoomStatus == CircuitEditStatus.protected) {
        return rejected(
          CircuitEditStatus.protected,
          'Making room would displace a protected logical gate.',
        );
      }
      if (makeRoomStatus != CircuitEditStatus.changed) {
        return rejected(
          CircuitEditStatus.invalid,
          'Conflicting logical footprints could not be displaced safely.',
        );
      }
    }
    for (final qubit in destinationQubits) {
      final row = compacted[qubit];
      while (row.length <= resolvedColumn) {
        row.add(PlacedQuantumGate.emptyGate());
      }
    }

    for (final fragment in footprint.fragments) {
      final translatedQubit = fragment.location.qubit + rowDelta;
      compacted[translatedQubit][resolvedColumn] = _translatePlacedGate(
        fragment.placedGate,
        rowDelta,
      );
    }
    if (_compactDetachedRows(compacted) == null) {
      return rejected(
        CircuitEditStatus.invalid,
        'Moved logical footprint could not be compacted safely.',
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

    final movedFragments = _detachedLogicalFragments(compacted)[id]!;
    final movedAnchor = movedFragments.firstWhere(
      (fragment) => fragment.$2.isTarget,
      orElse: () => movedFragments.first,
    );
    final canonicalLocation = CircuitLocation(
      qubit: movedAnchor.$1,
      column: movedAnchor.$3,
    );
    if (_sameGridIdentity(baseRows, compacted)) {
      return rejected(
        CircuitEditStatus.same,
        'Canonical compaction resolves to the original circuit.',
      );
    }
    final orderingReason = _orderingRegression(baseRows, compacted);
    if (orderingReason != null) {
      return rejected(CircuitEditStatus.invalid, orderingReason);
    }

    return LogicalMovePlan(
      status: CircuitEditStatus.changed,
      sourceId: id,
      baseRows: baseRows,
      proposedRows: compacted,
      resultingLocation: canonicalLocation,
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
    if (!_suppressStructuralNotifications) notifyListeners();
    return plan.outcome;
  }

  static const Set<SelectedGateType> supportedLogicalDuplicationTypes = {
    SelectedGateType.hadamard,
    SelectedGateType.s,
    SelectedGateType.t,
    SelectedGateType.x,
    SelectedGateType.y,
    SelectedGateType.z,
    SelectedGateType.rx,
    SelectedGateType.ry,
    SelectedGateType.rz,
    SelectedGateType.cnot,
    SelectedGateType.cz,
    SelectedGateType.ccnot,
    SelectedGateType.cy,
    SelectedGateType.mcx,
  };

  bool _isGateTypeAvailable(SelectedGateType type) =>
      currentLevel.availableGates.any((gate) => gate.type == type);

  bool canDuplicateLogicalGate(GateId id) {
    final footprint = logicalGateById(id);
    return footprint != null &&
        footprint.isDeletable &&
        supportedLogicalDuplicationTypes.contains(footprint.type) &&
        _isGateTypeAvailable(footprint.type);
  }

  GateId _nextAvailableGateIdCandidate() {
    var value = _nextGateId;
    final existing = logicalGates.map((gate) => gate.id).toSet();
    while (existing.contains(GateId(value))) {
      value++;
    }
    return GateId(value);
  }

  LogicalDuplicationPlan planLogicalGateDuplication(GateId sourceId) {
    final baseRows = _copyRows(placedGates);
    LogicalDuplicationPlan rejected(
      CircuitEditStatus status,
      String reason,
    ) =>
        LogicalDuplicationPlan(
          status: status,
          sourceId: sourceId,
          baseRows: baseRows,
          reason: reason,
        );

    final source = logicalGateById(sourceId);
    if (source == null) {
      return rejected(CircuitEditStatus.notFound, 'Source GateId not found.');
    }
    if (!source.isDeletable) {
      return rejected(CircuitEditStatus.protected, 'Source gate is protected.');
    }
    if (!source.hasValidTopology(currentLevel.numQubits)) {
      return rejected(
        CircuitEditStatus.invalid,
        'Source logical footprint is malformed.',
      );
    }
    if (!supportedLogicalDuplicationTypes.contains(source.type)) {
      return rejected(
        CircuitEditStatus.unsupported,
        'Logical gate does not support duplication.',
      );
    }
    if (!_isGateTypeAvailable(source.type)) {
      return rejected(
        CircuitEditStatus.protected,
        'Gate is unavailable under the current level policy.',
      );
    }
    if (!source.gate.hasValidRequiredParameters) {
      return rejected(
        CircuitEditStatus.invalid,
        'Source gate configuration is invalid.',
      );
    }

    final duplicateId = _nextAvailableGateIdCandidate();
    final destinationColumn = source.column + 1;
    final proposal = _copyRows(placedGates);
    final destinationQubits = source.fragments
        .map((fragment) => fragment.location.qubit)
        .toList(growable: false);
    final collision = destinationQubits.any(
      (qubit) =>
          _cellAt(proposal, qubit, destinationColumn).gate.type !=
          SelectedGateType.none,
    );
    if (collision) {
      final makeRoomStatus = _shiftConflictingLogicalGatesRight(
        proposal,
        destinationQubits: destinationQubits,
        destinationColumn: destinationColumn,
      );
      if (makeRoomStatus == CircuitEditStatus.protected) {
        return rejected(
          CircuitEditStatus.protected,
          'Making room would displace a protected logical gate.',
        );
      }
      if (makeRoomStatus != CircuitEditStatus.changed) {
        return rejected(
          CircuitEditStatus.invalid,
          'Conflicting logical footprints could not be displaced safely.',
        );
      }
    }

    for (final fragment in source.fragments) {
      final row = proposal[fragment.location.qubit];
      while (row.length <= destinationColumn) {
        row.add(PlacedQuantumGate.emptyGate());
      }
      if (row[destinationColumn].gate.type != SelectedGateType.none) {
        return rejected(
          CircuitEditStatus.invalid,
          'Duplicate destination remains occupied.',
        );
      }
      row[destinationColumn] = _copyPlacedGateWithId(
        fragment.placedGate,
        duplicateId,
      );
    }
    _trimDetachedRows(proposal);
    if (!_isValidDuplicatedLogicalGrid(
      proposal,
      baseRows,
      source: source,
      duplicateId: duplicateId,
    )) {
      return rejected(
        CircuitEditStatus.invalid,
        'Proposal would corrupt a logical footprint.',
      );
    }
    final orderingReason = _orderingRegression(baseRows, proposal);
    if (orderingReason != null) {
      return rejected(CircuitEditStatus.invalid, orderingReason);
    }

    return LogicalDuplicationPlan(
      status: CircuitEditStatus.changed,
      sourceId: sourceId,
      duplicateId: duplicateId,
      baseRows: baseRows,
      proposedRows: proposal,
      resultingLocation: CircuitLocation(
        qubit: source.anchor.qubit,
        column: destinationColumn,
      ),
    );
  }

  CircuitEditOutcome commitLogicalGateDuplicationPlan(
    LogicalDuplicationPlan plan,
  ) {
    if (!plan.changed ||
        plan.proposedRows == null ||
        plan.duplicateId == null) {
      return plan.outcome;
    }
    if (!_sameGridIdentity(placedGates, plan.baseRows) ||
        containsGate(plan.duplicateId!)) {
      return const CircuitEditOutcome(
        CircuitEditStatus.cancelled,
        detail: 'Circuit changed after duplication was planned.',
      );
    }
    placedGates = _copyRows(plan.proposedRows!);
    _nextGateId = max(_nextGateId, plan.duplicateId!.value + 1);
    if (!_suppressStructuralNotifications) notifyListeners();
    return plan.outcome;
  }

  CircuitEditOutcome duplicateLogicalGateWithOutcome(GateId sourceId) =>
      commitLogicalGateDuplicationPlan(
        planLogicalGateDuplication(sourceId),
      );

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
      controlQubitIndices:
          gate.controlQubitIndices?.map((qubit) => qubit + rowDelta).toList(),
      targetQubitIndex: translated(gate.targetQubitIndex),
      isTarget: gate.isTarget,
      isLink: gate.isLink,
      isControl: gate.isControl,
      isControl2: gate.isControl2,
      isDeletable: gate.isDeletable,
      classicalBit: gate.classicalBit,
    );
  }

  static PlacedQuantumGate _copyPlacedGateWithId(
    PlacedQuantumGate gate,
    GateId id,
  ) =>
      PlacedQuantumGate(
        id: id,
        gate: gate.gate,
        controlQubitIndex: gate.controlQubitIndex,
        control2QubitIndex: gate.control2QubitIndex,
        controlQubitIndices: gate.controlQubitIndices,
        targetQubitIndex: gate.targetQubitIndex,
        isTarget: gate.isTarget,
        isLink: gate.isLink,
        isControl: gate.isControl,
        isControl2: gate.isControl2,
        isDeletable: gate.isDeletable,
        classicalBit: gate.classicalBit,
      );

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

  static int _firstColumnWithoutProtectedCollision(
    List<List<PlacedQuantumGate>> rows, {
    required List<int> destinationQubits,
    required int requestedColumn,
  }) {
    var column = requestedColumn;
    while (destinationQubits.any(
      (qubit) {
        final cell = _cellAt(rows, qubit, column);
        return cell.gate.type != SelectedGateType.none && !cell.isDeletable;
      },
    )) {
      column++;
    }
    return column;
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

  static CircuitEditStatus _shiftConflictingLogicalGatesRight(
    List<List<PlacedQuantumGate>> rows, {
    required List<int> destinationQubits,
    required int destinationColumn,
  }) {
    final footprints = _detachedLogicalFragments(rows);
    final pending = <GateId>[];
    final required = <GateId>{};

    void requireGateAt(int qubit, int column) {
      final id = _cellAt(rows, qubit, column).id;
      if (id != null && required.add(id)) pending.add(id);
    }

    for (final qubit in destinationQubits) {
      requireGateAt(qubit, destinationColumn);
    }

    while (pending.isNotEmpty) {
      final id = pending.removeLast();
      final fragments = footprints[id];
      if (fragments == null || fragments.isEmpty) {
        return CircuitEditStatus.invalid;
      }
      if (fragments.any((fragment) => !fragment.$2.isDeletable)) {
        return CircuitEditStatus.protected;
      }
      final columns = fragments.map((fragment) => fragment.$3).toSet();
      if (columns.length != 1) return CircuitEditStatus.invalid;
      final nextColumn = columns.single + 1;
      for (final fragment in fragments) {
        requireGateAt(fragment.$1, nextColumn);
      }
    }

    final ordered = required.toList()
      ..sort((a, b) {
        final aColumn = footprints[a]!.first.$3;
        final bColumn = footprints[b]!.first.$3;
        return bColumn.compareTo(aColumn);
      });
    for (final id in ordered) {
      final fragments = footprints[id]!;
      for (final fragment in fragments) {
        rows[fragment.$1][fragment.$3] = PlacedQuantumGate.emptyGate();
      }
      for (final fragment in fragments) {
        final destination = fragment.$3 + 1;
        final row = rows[fragment.$1];
        while (row.length <= destination) {
          row.add(PlacedQuantumGate.emptyGate());
        }
        if (row[destination].gate.type != SelectedGateType.none) {
          return CircuitEditStatus.invalid;
        }
        row[destination] = fragment.$2;
      }
    }
    return CircuitEditStatus.changed;
  }

  List<List<PlacedQuantumGate>>? _compactDetachedRows(
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
                    ) &&
                listEquals(
                    fragment.$2.controlQubitIndices,
                    originalFragment.$2.controlQubitIndices
                        ?.map((qubit) => qubit + rowDelta)
                        .toList()),
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

  static bool _isValidDuplicatedLogicalGrid(
    List<List<PlacedQuantumGate>> proposed,
    List<List<PlacedQuantumGate>> original, {
    required LogicalGateFootprint source,
    required GateId duplicateId,
  }) {
    final proposedFootprints = _detachedLogicalFragments(proposed);
    final originalFootprints = _detachedLogicalFragments(original);
    if (proposedFootprints.length != originalFootprints.length + 1 ||
        !proposedFootprints.keys.toSet().containsAll(originalFootprints.keys)) {
      return false;
    }
    for (final entry in originalFootprints.entries) {
      final result = proposedFootprints[entry.key];
      if (result == null || result.length != entry.value.length) return false;
      if (result.map((fragment) => fragment.$3).toSet().length != 1) {
        return false;
      }
      final originalCells = entry.value.map((fragment) => fragment.$2).toSet();
      final resultCells = result.map((fragment) => fragment.$2).toSet();
      if (originalCells.length != resultCells.length ||
          !resultCells.containsAll(originalCells)) {
        return false;
      }
    }

    final duplicate = proposedFootprints[duplicateId];
    if (duplicate == null || duplicate.length != source.fragments.length) {
      return false;
    }
    if (duplicate.map((fragment) => fragment.$3).toSet().length != 1) {
      return false;
    }
    for (final sourceFragment in source.fragments) {
      final matching = duplicate.where(
        (fragment) =>
            fragment.$1 == sourceFragment.location.qubit &&
            fragment.$2.gate == sourceFragment.placedGate.gate &&
            fragment.$2.isControl == sourceFragment.placedGate.isControl &&
            fragment.$2.isControl2 == sourceFragment.placedGate.isControl2 &&
            fragment.$2.isTarget == sourceFragment.placedGate.isTarget &&
            fragment.$2.isLink == sourceFragment.placedGate.isLink &&
            fragment.$2.isDeletable == sourceFragment.placedGate.isDeletable &&
            fragment.$2.controlQubitIndex ==
                sourceFragment.placedGate.controlQubitIndex &&
            fragment.$2.control2QubitIndex ==
                sourceFragment.placedGate.control2QubitIndex &&
            fragment.$2.targetQubitIndex ==
                sourceFragment.placedGate.targetQubitIndex &&
            listEquals(fragment.$2.controlQubitIndices,
                sourceFragment.placedGate.controlQubitIndices),
      );
      if (matching.length != 1) return false;
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

  CircuitEditOutcome removeLogicalGateByIdWithOutcome(GateId id) =>
      _guardOrdering(() => _removeLogicalGate(id));

  CircuitEditOutcome _removeLogicalGate(GateId id) {
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
          {bool isDeletable = true}) =>
      _guardOrdering(() => _insertDoubleGate(
          gate, insertionPosition, targetQubitIndex, controlQubitIndex,
          isDeletable: isDeletable));

  CircuitEditOutcome _insertDoubleGate(Gate gate, int insertionPosition,
      int targetQubitIndex, int controlQubitIndex,
      {bool isDeletable = true}) {
    if (!singleControlGateTypes.contains(gate.type)) {
      return CircuitEditOutcome.invalid;
    }
    return _insertControlledGate(
        gate, insertionPosition, targetQubitIndex, [controlQubitIndex],
        isDeletable: isDeletable);
  }

  /// Controlled gates with exactly one control.
  static const Set<SelectedGateType> singleControlGateTypes = {
    SelectedGateType.cnot,
    SelectedGateType.cz,
    SelectedGateType.cy,
  };

  /// Smallest number of controls of a multi-controlled X ([SelectedGateType.mcx]);
  /// one and two controls are CX and CCX (v2.6 M7).
  static const int minMultiControlCount = 3;

  /// Inserts a multi-controlled X with [controlQubitIndices] (three or more,
  /// distinct, any rows) and one target (v2.6 M7).
  CircuitEditOutcome insertMultiControlledGateWithOutcome(
          Gate gate,
          int insertionPosition,
          int targetQubitIndex,
          List<int> controlQubitIndices,
          {bool isDeletable = true}) =>
      _guardOrdering(() => gate.type != SelectedGateType.mcx ||
              controlQubitIndices.length < minMultiControlCount
          ? CircuitEditOutcome.invalid
          : _insertControlledGate(
              gate, insertionPosition, targetQubitIndex, controlQubitIndices,
              isDeletable: isDeletable));

  /// The one insertion routine for controlled gates (v2.6 M7): one logical
  /// gate spanning its lowest to highest operand, with a control cell per
  /// control, a target cell and link cells between them.
  CircuitEditOutcome _insertControlledGate(Gate gate, int insertionPosition,
      int targetQubitIndex, List<int> controls,
      {bool isDeletable = true}) {
    final operands = [...controls, targetQubitIndex];
    if (insertionPosition < 0 ||
        controls.isEmpty ||
        operands.toSet().length != operands.length ||
        operands.any((qubit) => qubit < 0 || qubit >= currentLevel.numQubits)) {
      return CircuitEditOutcome.invalid;
    }
    final from = operands.reduce(min);
    final to = operands.reduce(max);
    insertionPosition = min(insertionPosition, maxCircuitDepth());
    insertionPosition = _firstColumnWithoutProtectedCollision(
      placedGates,
      destinationQubits: [for (var qubit = from; qubit <= to; qubit++) qubit],
      requestedColumn: insertionPosition,
    );
    final gateId = _allocateGateId();
    final multi = gate.type == SelectedGateType.mcx;
    PlacedQuantumGate cell(int row) => PlacedQuantumGate(
          id: gateId,
          gate: gate,
          isControl: multi ? controls.contains(row) : row == controls.first,
          isControl2: !multi && controls.length > 1 && row == controls[1],
          isTarget: row == targetQubitIndex,
          isLink: !operands.contains(row),
          controlQubitIndex: multi ? null : controls.first,
          control2QubitIndex:
              !multi && controls.length > 1 ? controls[1] : null,
          controlQubitIndices: multi ? controls : null,
          targetQubitIndex: targetQubitIndex,
          isDeletable: isDeletable,
        );

    final allEmpty = [for (var i = from; i <= to; i++) i].every((i) =>
        insertionPosition >= placedGates[i].length ||
        placedGates[i][insertionPosition].gate.type == SelectedGateType.none);
    if (allEmpty) {
      for (var i = from; i <= to; i++) {
        insertGateAt(cell(i), insertionPosition, i);
      }
    } else {
      // Open a column across the register, then compact what can move left.
      for (var i = 0; i < currentLevel.numQubits; i++) {
        insertGateAt(
            i >= from && i <= to ? cell(i) : PlacedQuantumGate.emptyGate(),
            insertionPosition,
            i);
      }
    }
    shiftLeft();
    trimCircuit();
    if (!_suppressStructuralNotifications) notifyListeners();
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
          {bool isDeletable = true}) =>
      _guardOrdering(() => _insertTripleGate(gate, insertionPosition,
          targetQubitIndex, control1QubitIndex, control2QubitIndex,
          isDeletable: isDeletable));

  CircuitEditOutcome _insertTripleGate(Gate gate, int insertionPosition,
      int targetQubitIndex, int control1QubitIndex, int control2QubitIndex,
      {bool isDeletable = true}) {
    if (gate.type != SelectedGateType.ccnot) return CircuitEditOutcome.invalid;
    return _insertControlledGate(gate, insertionPosition, targetQubitIndex,
        [control1QubitIndex, control2QubitIndex],
        isDeletable: isDeletable);
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
    } else if (gateToRemove.controlQubits.isNotEmpty &&
        gateToRemove.targetQubitIndex != null &&
        gateToRemove.isDeletable) {
      final operands = [
        ...gateToRemove.controlQubits,
        gateToRemove.targetQubitIndex!
      ];
      for (int i = operands.reduce(min); i <= operands.reduce(max); i++) {
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
    _compactDetachedRows(placedGates);
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
    // An empty circuit is already reset, unless its level authors gates
    // (a Notebook experiment whose gates were all deleted): then reset must
    // restore them (fixed in v2.6 M7).
    if (isCircuitEmpty() && currentLevel.preInsertedGates == null) {
      return CircuitEditOutcome.same;
    }
    // placedGates.clear();
    placedGates = List.generate(currentLevel.numQubits, (index) => []);
    // Reset the currentState back to the initial ground state
    currentState = QubitState.fromList(currentLevel.initialQubitsState);
    _suppressStructuralNotifications = true;
    try {
      currentLevel.preInsertGates(this);
    } finally {
      _suppressStructuralNotifications = false;
    }
    debugPrint(
        "Circuit cleared. Total placed gates: ${placedGates.length}"); // Debug debugPrint
    // ** Notify listeners that the state has changed **
    notifyListeners();
    return const CircuitEditOutcome(CircuitEditStatus.changed);
  }

  List<List<PlacedQuantumGate>> clone(List<List<PlacedQuantumGate>> gates) {
    if (hasMeasurements) throw const NonUnitaryProgram();
    return placedGates =
        gates.map((element) => List<PlacedQuantumGate>.from(element)).toList();
  }

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
      case SelectedGateType.cy:
        return QuantumMatrix.cy(
            control: gate.controlQubitIndex!, target: gate.targetQubitIndex!);
      case SelectedGateType.mcx:
        return QuantumMatrix.mcx(
            controls: gate.controlQubits, target: gate.targetQubitIndex!);
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

      if (gate.targetQubitIndex != null && gate.controlQubits.isNotEmpty) {
        // A controlled operator spans to its highest operand; skip past it.
        q = [...gate.controlQubits, gate.targetQubitIndex!].reduce(max);
        continue;
      }
    }
    return columnOverallMatrix!;
  }

  /// Generates the overall unitary matrix representing the entire quantum circuit.
  /// This is the "transform operator".
  QuantumMatrix getOverallCircuitMatrix() {
    if (hasMeasurements) throw const NonUnitaryProgram();
    lastSimulationError = null;
    for (final footprint in logicalGates) {
      if (!footprint.hasValidTopology(currentLevel.numQubits)) {
        throw MalformedCircuitException(
          gateType: footprint.type,
          columnIndex: footprint.anchor.column,
          qubitIndex: footprint.anchor.qubit,
          parameterName: 'logical footprint',
        );
      }
    }
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
    if (hasMeasurements) throw const NonUnitaryProgram();
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

/// Immutable, in-memory definition of a [QuantumCircuit] for undo/redo.
/// See [QuantumCircuit.captureEditSnapshot].
@immutable
class CircuitEditSnapshot {
  const CircuitEditSnapshot._({
    required this.rows,
    required this.nextGateId,
    required this.reservedClassicalBits,
    required this.numQubits,
  });

  final List<List<PlacedQuantumGate>> rows;
  final int nextGateId;
  final int reservedClassicalBits;
  final int numQubits;

  /// Whether both snapshots describe the same circuit definition: identical
  /// gate identities, types, parameters, roles, protection and measurement
  /// destinations in every cell. Allocator state is ignored.
  /// The classical register width this definition implies: the reserved
  /// width or the widest measured bit, whichever is larger (the same rule as
  /// [QuantumCircuit.classicalBitCount]).
  int get effectiveClassicalBits => QuantumCircuit.measurementsInRows(rows).fold(
      reservedClassicalBits, (width, m) => max(width, m.classicalBit + 1));

  /// v2.6 M9: compares the effective classical width, not the raw reserved
  /// value, which differs between a built and a restored circuit with the
  /// same measurements.
  bool sameDefinitionAs(CircuitEditSnapshot other) {
    if (numQubits != other.numQubits ||
        effectiveClassicalBits != other.effectiveClassicalBits) {
      return false;
    }
    for (var q = 0; q < numQubits; q++) {
      final a = _trimmed(rows[q]);
      final b = _trimmed(other.rows[q]);
      if (a.length != b.length) return false;
      for (var c = 0; c < a.length; c++) {
        if (!_sameCell(a[c], b[c])) return false;
      }
    }
    return true;
  }

  static List<PlacedQuantumGate> _trimmed(List<PlacedQuantumGate> row) {
    var end = row.length;
    while (end > 0 && row[end - 1].gate.type == SelectedGateType.none) {
      end--;
    }
    return row.sublist(0, end);
  }

  static bool _sameCell(PlacedQuantumGate a, PlacedQuantumGate b) =>
      a.id == b.id &&
      a.gate.type == b.gate.type &&
      a.gate.angle == b.gate.angle &&
      a.controlQubitIndex == b.controlQubitIndex &&
      a.control2QubitIndex == b.control2QubitIndex &&
      a.targetQubitIndex == b.targetQubitIndex &&
      listEquals(a.controlQubitIndices, b.controlQubitIndices) &&
      a.isControl == b.isControl &&
      a.isControl2 == b.isControl2 &&
      a.isTarget == b.isTarget &&
      a.isLink == b.isLink &&
      a.isDeletable == b.isDeletable &&
      a.classicalBit == b.classicalBit;
}
