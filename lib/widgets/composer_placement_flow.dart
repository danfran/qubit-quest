import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/controlled_gate_placement_dialog.dart';
import 'package:quantumquiz/screens/gate_replacement_dialog.dart';
import 'package:quantumquiz/screens/rotation_gate_dialog.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';

/// Asks the learner for a rotation angle; null means cancelled.
typedef ComposerAngleChooser = Future<double?> Function(
  BuildContext context,
  SelectedGateType type, {
  double? initialAngle,
});

/// Asks the learner for the control qubits of a controlled gate whose target
/// is [targetQubit]; null means cancelled. Returns exactly
/// [controlCountFor] controls.
typedef ComposerControlsChooser = Future<List<int>?> Function(
  BuildContext context, {
  required SelectedGateType gateType,
  required int targetQubit,
  required int numQubits,
});

/// UI adapter that gathers the parameters a [ComposerSession] command needs
/// (rotation angle, control qubits, replacement type) and then issues exactly
/// one command. It never validates or edits the circuit itself.
///
/// Cancelling any step returns [CircuitEditOutcome.cancelled] without
/// touching the session, so no partial gate is ever placed. After every
/// await the flow re-checks that the [BuildContext] is mounted and the
/// session is still alive; a host that switched or disposed its session
/// meanwhile gets a cancelled outcome.
///
/// The choosers are injectable so the M3 workspace can replace modal
/// prompts (for example with inspector-first angle editing) without
/// duplicating the command logic.
class ComposerPlacementFlow {
  const ComposerPlacementFlow({
    this.chooseAngle = rotationAngleDialog,
    this.chooseControls = controlledPlacementDialog,
  });

  final ComposerAngleChooser chooseAngle;
  final ComposerControlsChooser chooseControls;

  static Future<double?> rotationAngleDialog(
    BuildContext context,
    SelectedGateType type, {
    double? initialAngle,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => RotationGateDialog(
        gateType: type,
        initialAngle: initialAngle,
      ),
    );
    return result?['angle1'] as double?;
  }

  /// The existing web role picker (auto-selects when only one role is valid).
  static Future<List<int>?> controlledPlacementDialog(
    BuildContext context, {
    required SelectedGateType gateType,
    required int targetQubit,
    required int numQubits,
  }) async {
    final placement = await showControlledGatePlacementDialog(
      context,
      gateType: gateType,
      targetQubit: targetQubit,
      numQubits: numQubits,
    );
    if (placement == null) return null;
    return [
      placement.controlQubit,
      if (placement.secondControlQubit != null) placement.secondControlQubit!,
    ];
  }

  /// Handles a gate drop from the canvas: moves a placed gate, or configures
  /// and inserts a palette gate. Measurement drags use the session's
  /// measurement commands directly and are not handled here.
  Future<CircuitEditOutcome> drop(
    BuildContext context,
    ComposerSession session,
    ComposerCircuitDropIntent intent,
  ) async {
    final location = intent.destination.location;
    if (intent.data.isPlaced) {
      return session.moveGate(
        intent.data.sourceId!,
        location,
        plan: intent.movePlan,
      );
    }
    var gate = intent.data.gate;
    if (gate.requiresAngle && gate.angle == null) {
      final angle = await _angleForNewRotation(context, session, gate.type);
      if (!context.mounted || session.isDisposed || angle == null) {
        return CircuitEditOutcome.cancelled;
      }
      gate = Gate.fromIdentifier(gate.type, angle: angle);
    }
    var controls = const <int>[];
    if (controlCountFor(gate.type) > 0) {
      final chosen = await chooseControls(
        context,
        gateType: gate.type,
        targetQubit: location.qubit,
        numQubits: session.circuit.currentLevel.numQubits,
      );
      if (!context.mounted || session.isDisposed || chosen == null) {
        return CircuitEditOutcome.cancelled;
      }
      controls = chosen;
    }
    return session.insertGate(
      GatePlacementRequest(gate: gate, target: location, controls: controls),
    );
  }

  /// Angle for a rotation that has none yet, per the session's policy:
  /// the documented default (inspector-first), a prompt, or none at all for
  /// lesson palettes, which always carry their own angle.
  Future<double?> _angleForNewRotation(
    BuildContext context,
    ComposerSession session,
    SelectedGateType type,
  ) async =>
      switch (session.policy.angleEntry) {
        ComposerAngleEntry.defaultOnPlacement =>
          ComposerPolicy.defaultRotationAngle,
        ComposerAngleEntry.promptOnPlacement =>
          await chooseAngle(context, type),
        ComposerAngleEntry.palettePreset => null,
      };

  /// Edits the angle of the placed rotation [id], starting from its angle.
  Future<CircuitEditOutcome> editAngle(
    BuildContext context,
    ComposerSession session,
    GateId id,
  ) async {
    final footprint = session.circuit.logicalGateById(id);
    if (footprint == null || !footprint.isParameterEditable) {
      return CircuitEditOutcome.unsupported;
    }
    final angle = await chooseAngle(
      context,
      footprint.type,
      initialAngle: footprint.gate.angle,
    );
    if (!context.mounted || session.isDisposed || angle == null) {
      return CircuitEditOutcome.cancelled;
    }
    return session.editRotationAngle(id, angle);
  }

  /// Valid replacement types for the gate [id]: the level's single-qubit
  /// palette minus the gate's own type. Empty when it cannot be replaced.
  static List<SelectedGateType> replacementCandidates(
    ComposerSession session,
    GateId id,
  ) {
    final footprint = session.circuit.logicalGateById(id);
    if (footprint == null || !footprint.isEditable) return const [];
    return session.circuit.availableSingleQubitReplacementTypes
        .where((type) => type != footprint.type)
        .toList(growable: false);
  }

  /// Replaces the single-qubit gate [id] with a type the learner picks from
  /// the level's palette, asking for an angle when the new type needs one.
  ///
  /// [type] is a choice the host already collected (the desktop inspector's
  /// anchored menu); it must be one of [replacementCandidates]. Without it
  /// the existing replacement dialog asks.
  Future<CircuitEditOutcome> replace(
    BuildContext context,
    ComposerSession session,
    GateId id, {
    SelectedGateType? type,
  }) async {
    final footprint = session.circuit.logicalGateById(id);
    if (footprint == null || !footprint.isEditable) {
      return CircuitEditOutcome.unsupported;
    }
    final candidates = replacementCandidates(session, id);
    if (candidates.isEmpty) return CircuitEditOutcome.unsupported;
    if (type != null && !candidates.contains(type)) {
      return CircuitEditOutcome.unsupported;
    }
    type ??= await showDialog<SelectedGateType>(
      context: context,
      builder: (_) => GateReplacementDialog(gateTypes: candidates),
    );
    if (!context.mounted || session.isDisposed || type == null) {
      return CircuitEditOutcome.cancelled;
    }
    double? angle;
    if (Gate.fromIdentifier(type).requiresAngle) {
      angle = await _angleForNewRotation(context, session, type);
      if (!context.mounted || session.isDisposed || angle == null) {
        return CircuitEditOutcome.cancelled;
      }
    }
    return session.replaceGate(id, Gate.fromIdentifier(type, angle: angle));
  }
}
