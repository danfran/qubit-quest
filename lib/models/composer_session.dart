import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/circuit_executor.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/circuit_save_queue.dart';
import 'package:quantumquiz/models/composer_gate_capabilities.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/edit_history.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/models/measured_circuit_runner.dart';
import 'package:quantumquiz/models/measurement_distribution.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

/// Number of control qubits a controlled gate type needs, or 0 for an
/// uncontrolled gate. The command boundary ([GatePlacementRequest.controls])
/// is a list, so a future multi-controlled X can carry any count without a
/// new command; only this table and the model's insertion grow.
int controlCountFor(SelectedGateType type) => switch (type) {
      SelectedGateType.cnot || SelectedGateType.cz => 1,
      SelectedGateType.ccnot => 2,
      _ => 0,
    };

/// A fully configured gate insertion: the gate (with its angle, if any), the
/// target slot and the control qubits in the order they were chosen.
@immutable
class GatePlacementRequest {
  GatePlacementRequest({
    required this.gate,
    required this.target,
    List<int> controls = const [],
  }) : controls = List.unmodifiable(controls);

  final Gate gate;

  /// Target qubit and insertion column.
  final CircuitLocation target;
  final List<int> controls;
}

enum ComposerFeedbackKind { committed, unchanged, rejected }

/// The outcome of the most recent command, for transient host messages.
@immutable
class ComposerFeedback {
  const ComposerFeedback(this.kind, this.outcome);
  final ComposerFeedbackKind kind;
  final CircuitEditOutcome outcome;
  String? get detail => outcome.detail;
}

/// One Composer editing session: a circuit, its mode policy, selection,
/// undo/redo history, measurement results and (for the Sandbox) autosave.
///
/// Platform-neutral: no BuildContext, dialogs, layout or web APIs. Hosts
/// gather missing parameters (see `ComposerPlacementFlow`), call commands and
/// present the results. Validation stays in [QuantumCircuit]; the session
/// only orchestrates what happens after the model accepts or rejects an edit:
///
/// * a committed edit notifies once, re-simulates unitary circuits, clears
///   stale results, bumps [revision], records one history entry and (Sandbox
///   only) autosaves once;
/// * a rejected, cancelled or no-op command changes nothing and records no
///   history.
class ComposerSession extends ChangeNotifier {
  ComposerSession({
    required QuantumCircuit circuit,
    required this.policy,
    CircuitSaveQueue? saveQueue,
    MeasuredCircuitRunner? runner,
    FinalStateSampler? sampler,
    int historyLimit = EditHistory.defaultLimit,
    Future<void> Function()? beforeRun,
    this.ownsCircuit = true,
  })  : _circuit = circuit,
        _saveQueue = saveQueue,
        _runner = runner ?? MeasuredCircuitRunner(),
        _sampler = sampler ?? FinalStateSampler(),
        _beforeRun = beforeRun ?? (() => Future<void>.value()),
        _history = EditHistory(
          circuit.captureEditSnapshot(),
          limit: historyLimit,
        ) {
    if (policy.persistsToSandbox && saveQueue == null) {
      throw ArgumentError('A Sandbox session needs a save queue.');
    }
    if (!policy.persistsToSandbox && saveQueue != null) {
      throw ArgumentError('Only Sandbox sessions persist.');
    }
    circuit.addListener(_circuitNotified);
  }

  /// True while the session itself is changing or simulating the circuit.
  bool _applying = false;

  /// Adopts definition changes made directly on the circuit (outside the
  /// session's commands) exactly like a committed command, so results,
  /// history, autosave and selection can never go stale. Notifications that
  /// leave the definition unchanged (for example simulation) are ignored.
  void _circuitNotified() {
    if (_applying || _disposed) return;
    final snapshot = _circuit.captureEditSnapshot();
    if (snapshot.sameDefinitionAs(_history.current)) return;
    _definitionChanged();
    _history.record(snapshot);
    _persist();
    _revalidateSelection();
    notifyListeners();
  }

  final QuantumCircuit _circuit;
  final ComposerPolicy policy;
  final CircuitSaveQueue? _saveQueue;
  final MeasuredCircuitRunner _runner;
  final FinalStateSampler _sampler;
  final Future<void> Function() _beforeRun;
  final EditHistory<CircuitEditSnapshot> _history;

  /// Whether [dispose] also disposes the circuit.
  final bool ownsCircuit;

  QuantumCircuit get circuit => _circuit;
  CircuitSaveQueue? get saveQueue => _saveQueue;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  int _revision = 0;

  /// Increments on every committed definition change, undo and redo.
  int get revision => _revision;

  ComposerFeedback? _feedback;
  ComposerFeedback? get lastFeedback => _feedback;

  // ── Selection ───────────────────────────────────────────────────────────

  GateId? _selectedId;
  GateId? get selectedId => _selectedId;

  LogicalGateFootprint? get selectedGate =>
      _selectedId == null ? null : _circuit.logicalGateById(_selectedId!);

  MeasureZOperation? get selectedMeasurement =>
      _selectedId == null ? null : _circuit.measurementById(_selectedId!);

  /// Model capabilities for the selection, narrowed by the policy.
  ComposerSelectedGateCapabilities get selectedCapabilities {
    final capabilities =
        ComposerSelectedGateCapabilities.forSelection(_circuit, _selectedId);
    final gate = selectedGate;
    if (gate != null && !policy.allowsAngleEditing(gate.type)) {
      return capabilities.without(ComposerSelectedGateAction.editAngle);
    }
    return capabilities;
  }

  /// Selects a gate or measurement by ID, or clears the selection. Selection
  /// changes never enter the undo history.
  void select(GateId? id) {
    if (_disposed) return;
    final next = id != null && _exists(id) ? id : null;
    if (next == _selectedId) return;
    _selectedId = next;
    notifyListeners();
  }

  bool _exists(GateId id) =>
      _circuit.logicalGateById(id) != null ||
      _circuit.measurementById(id) != null;

  void _revalidateSelection() {
    final id = _selectedId;
    if (id != null && !_exists(id)) _selectedId = null;
  }

  // ── Undo / redo ─────────────────────────────────────────────────────────

  bool get canUndo => !_disposed && !_readOnly && _history.canUndo;
  bool get canRedo => !_disposed && !_readOnly && _history.canRedo;

  // ── Review lock (v2.6 M6a) ──────────────────────────────────────────────

  bool _readOnly = false;

  /// True while the circuit is kept for review, for example after an
  /// exercise's successful Check. Every editing command, undo, redo and
  /// clear is rejected (enforced here, not only by disabled controls);
  /// selection, inspection and running experiments stay available.
  bool get readOnly => _readOnly;
  set readOnly(bool value) {
    if (_disposed || _readOnly == value) return;
    _readOnly = value;
    notifyListeners();
  }

  static const CircuitEditOutcome readOnlyOutcome = CircuitEditOutcome(
    CircuitEditStatus.protected,
    detail: 'This circuit is complete and kept for review.',
  );

  /// Restores the previous committed circuit. Returns false when there is
  /// nothing to undo.
  bool undo() => !_readOnly && _restore(_history.undo());

  /// Re-applies the next committed circuit. Returns false when there is
  /// nothing to redo.
  bool redo() => !_readOnly && _restore(_history.redo());

    bool _restore(CircuitEditSnapshot? snapshot) {
    if (_disposed || snapshot == null) return false;
    _applying = true;
    try {
      _circuit.restoreEditSnapshot(snapshot);
    } finally {
      _applying = false;
    }
    _definitionChanged();
    _revalidateSelection();
    _persist();
    _feedback = const ComposerFeedback(
      ComposerFeedbackKind.committed,
      CircuitEditOutcome(CircuitEditStatus.changed),
    );
    notifyListeners();
    return true;
  }

  // ── Editing commands ────────────────────────────────────────────────────

  /// Inserts a fully configured gate. Rejects gates outside the policy's
  /// palette, rotations without an angle (no partial gates) and control
  /// counts the gate type does not take.
  CircuitEditOutcome insertGate(GatePlacementRequest request) {
    if (_readOnly) return _reject(readOnlyOutcome);
    final gate = request.gate;
    if (!policy.allowsGateType(gate.type)) {
      return _reject(const CircuitEditOutcome(
        CircuitEditStatus.unsupported,
        detail: 'This gate is not available here.',
      ));
    }
    if (!gate.hasValidRequiredParameters) {
      return _reject(const CircuitEditOutcome(
        CircuitEditStatus.invalid,
        detail: 'Choose an angle before placing this gate.',
      ));
    }
    if (request.controls.length != controlCountFor(gate.type)) {
      return _reject(const CircuitEditOutcome(
        CircuitEditStatus.invalid,
        detail: 'Choose the control qubits for this gate.',
      ));
    }
    final column = request.target.column;
    final target = request.target.qubit;
    final controls = request.controls;
    return _commit(
      () => switch (controls.length) {
        0 => _circuit.insertSingleGateWithOutcome(gate, column, target),
        1 => _circuit.insertDoubleGateWithOutcome(
            gate, column, target, controls[0]),
        2 => _circuit.insertTripleGateWithOutcome(
            gate, column, target, controls[0], controls[1]),
        // Multi-controlled X (M7) extends the model here; the request shape
        // already carries any number of controls.
        _ => CircuitEditOutcome.unsupported,
      },
    );
  }

  /// Moves a placed gate, committing [plan] when the canvas already computed
  /// one for its preview.
  CircuitEditOutcome moveGate(
    GateId id,
    CircuitLocation destination, {
    LogicalMovePlan? plan,
  }) =>
      _commit(() => _circuit.commitLogicalGateMovePlan(
            plan ?? _circuit.planLogicalGateMove(id, destination),
          ));

  CircuitEditOutcome replaceGate(GateId id, Gate replacement) =>
      _commit(() => _circuit.replaceSingleGateWithOutcome(id, replacement));

  CircuitEditOutcome duplicateGate(GateId id) =>
      _commit(() => _circuit.duplicateLogicalGateWithOutcome(id));

  CircuitEditOutcome editRotationAngle(GateId id, double angle) {
    if (_readOnly) return _reject(readOnlyOutcome);
    final gate = _circuit.logicalGateById(id);
    if (gate != null && !policy.allowsAngleEditing(gate.type)) {
      return _reject(const CircuitEditOutcome(
        CircuitEditStatus.protected,
        detail: 'This activity sets the angle for you.',
      ));
    }
    return _commit(
      () => _circuit.updateGateParametersWithOutcome(id, angle: angle),
    );
  }

  /// Deletes a gate or a measurement and clears the selection.
  CircuitEditOutcome deleteOperation(GateId id) {
    final outcome = _commit(
      () => _circuit.measurementById(id) != null
          ? _circuit.removeMeasurementWithOutcome(id)
          : _circuit.removeLogicalGateByIdWithOutcome(id),
      selectAffected: false,
    );
    if (outcome.changed && _selectedId != null) {
      _selectedId = null;
      notifyListeners();
    }
    return outcome;
  }

  CircuitEditOutcome insertMeasurement(CircuitLocation location) {
    if (_readOnly) return _reject(readOnlyOutcome);
    if (!policy.allowsMeasurement) {
      return _reject(const CircuitEditOutcome(
        CircuitEditStatus.unsupported,
        detail: 'Measurements are not part of this activity.',
      ));
    }
    return _commit(() => _circuit.insertMeasurementWithOutcome(
          qubit: location.qubit,
          column: location.column,
        ));
  }

  CircuitEditOutcome moveMeasurement(GateId id, int column) =>
      _commit(() => _circuit.moveMeasurementWithOutcome(id, column));

  CircuitEditOutcome setClassicalBit(GateId id, int classicalBit) => _commit(
        () =>
            _circuit.updateMeasurementClassicalBitWithOutcome(id, classicalBit),
        selectAffected: false,
      );

  /// Clear (Sandbox, Notebook) or Reset (exercises, challenges): restores the
  /// level's authored starting circuit, fixed gates included. Undoable.
  CircuitEditOutcome clear() {
    final outcome = _commit(
      _circuit.clearPlacedGatesWithOutcome,
      selectAffected: false,
    );
    if (_selectedId != null) {
      _selectedId = null;
      notifyListeners();
    }
    return outcome;
  }

  CircuitEditOutcome _reject(CircuitEditOutcome outcome) {
    if (_disposed) return CircuitEditOutcome.cancelled;
    _feedback = ComposerFeedback(ComposerFeedbackKind.rejected, outcome);
    notifyListeners();
    return outcome;
  }

  CircuitEditOutcome _commit(
    CircuitEditOutcome Function() edit, {
    bool selectAffected = true,
  }) {
    if (_disposed) return CircuitEditOutcome.cancelled;
    if (_readOnly) return _reject(readOnlyOutcome);
    final CircuitEditOutcome outcome;
    _applying = true;
    try {
      outcome = edit();
    } finally {
      _applying = false;
    }
    if (!outcome.changed) {
      _feedback = ComposerFeedback(
        outcome.status == CircuitEditStatus.same ||
                outcome.status == CircuitEditStatus.cancelled
            ? ComposerFeedbackKind.unchanged
            : ComposerFeedbackKind.rejected,
        outcome,
      );
      notifyListeners();
      return outcome;
    }
    // Some model edits report `changed` but settle back to the same
    // definition (for example a move that gravity compaction returns to its
    // slot). Those keep results, revision, history and storage untouched.
    final snapshot = _circuit.captureEditSnapshot();
    if (!snapshot.sameDefinitionAs(_history.current)) {
      _definitionChanged();
      _history.record(snapshot);
      _persist();
    }
    if (selectAffected && outcome.affectedGateId != null) {
      _selectedId = outcome.affectedGateId;
    }
    _revalidateSelection();
    _feedback = ComposerFeedback(ComposerFeedbackKind.committed, outcome);
    notifyListeners();
    return outcome;
  }

  /// Bookkeeping for every committed definition change, undo and redo.
  void _definitionChanged() {
    // Measured circuits are never simulated as one unitary; their state is
    // derived on demand ([preMeasurement]).
    if (!_circuit.hasMeasurements) {
      _applying = true;
      try {
        _circuit.runSimulation();
      } finally {
        _applying = false;
      }
    }
    _revision++;
    _preMeasurementRevision = null;
    _clearResults();
  }

  void _persist() {
    final queue = _saveQueue;
    if (queue == null) return;
    unawaited(queue.saveProgram(SandboxProgramSnapshot.capture(_circuit)));
  }

  // ── Measurement execution and results ───────────────────────────────────

  int? _shots = MeasuredCircuitRunner.defaultShots;

  /// Requested shot count; null while the typed value is invalid, which
  /// disables Run shots.
  int? get shots => _shots;
  set shots(int? value) {
    if (_shots == value) return;
    _shots = value;
    notifyListeners();
  }

  bool _running = false;
  bool get running => _running;
  SingleShotOutcome? _singleShot;
  SingleShotOutcome? get singleShot => _singleShot;
  ShotsOutcome? _shotsResult;
  ShotsOutcome? get shotsResult => _shotsResult;
  String? _runError;
  String? get runError => _runError;
  int _resultsRevision = 0;

  void _clearResults() {
    _singleShot = null;
    _shotsResult = null;
    _runError = null;
    _resultsRevision++;
  }

  /// Discards results, for example when the host is deactivated. Does not
  /// touch the circuit or its history.
  void clearResults() {
    if (_disposed) return;
    _clearResults();
    notifyListeners();
  }

  PreMeasurementState? _preMeasurement;
  int? _preMeasurementRevision;

  /// For measured circuits, the exact state just before measurement (or why
  /// it is undefined); null for unmeasured circuits. Cached per [revision].
  PreMeasurementState? get preMeasurement {
    if (!_circuit.hasMeasurements) return null;
    if (_preMeasurementRevision != _revision) {
      _preMeasurement =
          PreMeasurementState.of(() => CircuitProgram.fromCircuit(_circuit));
      _preMeasurementRevision = _revision;
    }
    return _preMeasurement;
  }

  ExactMeasurementDistribution? _exact;
  int? _exactRevision;

  /// The exact outcome distribution of the experiment Run once and Run shots
  /// perform on the current circuit (v2.6 M4), keyed like their results.
  /// Without M operations: |αₓ|² of the ideal final state; with them: the
  /// executor's exact branching distribution of the measured classical bits.
  /// Unavailable (with a reason) when the circuit cannot be simulated.
  /// Cached per [revision]; computing it never changes the session.
  ExactMeasurementDistribution get exactDistribution {
    if (_exactRevision != _revision || _exact == null) {
      final circuit = _circuit;
      final n = circuit.currentLevel.numQubits;
      if (!circuit.hasMeasurements) {
        final error = circuit.lastSimulationError;
        _exact = error != null
            ? ExactMeasurementDistribution.unavailable(
                MeasurementMode.finalStateSampling,
                ClassicalReadout.finalState(n),
                error.userMessage)
            : ExactMeasurementDistribution.finalState(
                circuit.currentState.stateVector, n);
      } else {
        try {
          _exact = ExactMeasurementDistribution.explicit(
              CircuitProgram.fromCircuit(circuit));
        } on InvalidCircuitProgram catch (e) {
          _exact = ExactMeasurementDistribution.unavailable(
              MeasurementMode.explicitMeasurement,
              ClassicalReadout.finalState(n),
              'The exact distribution is unavailable: ${e.message}.');
        }
      }
      _exactRevision = _revision;
    }
    return _exact!;
  }

  /// One Measure experience, two engines. With M operations it executes the
  /// circuit's ordered program ([MeasuredCircuitRunner]); without them it
  /// samples the ideal final state in the Z basis ([FinalStateSampler]).
  /// Both read only immutable data: the circuit, its initial state, its
  /// history and its saved workspace are never touched.
  Future<void> run({required bool manyShots}) async {
    final shots = _shots;
    if (_disposed || _running || (manyShots && shots == null)) return;
    final circuit = _circuit;
    final revision = _resultsRevision;
    _running = true;
    _runError = null;
    notifyListeners();
    // Let the host paint the disabled controls before the synchronous run.
    await _beforeRun();
    SingleShotOutcome? single;
    ShotsOutcome? many;
    String? error;
    try {
      if (!circuit.hasMeasurements) {
        final simulationError = circuit.lastSimulationError;
        if (simulationError != null) {
          error = '${simulationError.userMessage} The circuit was not run.';
        } else {
          final state = circuit.currentState.stateVector;
          final n = circuit.currentLevel.numQubits;
          if (manyShots) {
            many = _sampler.runShots(state, n, shots: shots!);
          } else {
            single = _sampler.runOnce(state, n);
          }
        }
      } else {
        final program = CircuitProgram.fromCircuit(circuit);
        if (manyShots) {
          many = _runner.runShots(program, shots: shots!);
        } else {
          single = _runner.runOnce(program);
        }
      }
    } on CircuitExecutionException catch (e) {
      error = e.message == 'Execution budget exceeded'
          ? manyShots
              ? 'This circuit is too large to run ${formatCount(shots!)} '
                  'shots here. Reduce the shot count and run again. The '
                  'circuit was not changed.'
              : 'This circuit is too large to run here. It was not changed.'
          : 'The circuit could not be run: ${e.message}. It was not changed.';
    } on InvalidCircuitProgram catch (e) {
      error = 'The circuit could not be run: ${e.message}. It was not changed.';
    } on ArgumentError {
      error = 'This circuit cannot be measured. Check its state and try again.';
    } catch (e) {
      error = 'The circuit could not be run ($e). It was not changed.';
    }
    if (_disposed) return;
    _running = false;
    // Edited, undone or cleared meanwhile: discard the stale result.
    if (revision == _resultsRevision) {
      _runError = error;
      if (error != null) {
        // A failed run never sits beside older results.
        _singleShot = null;
        _shotsResult = null;
      }
      if (single != null) _singleShot = single;
      if (many != null) _shotsResult = many;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _circuit.removeListener(_circuitNotified);
    if (ownsCircuit) _circuit.dispose();
    super.dispose();
  }
}
