import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';

enum ComposerSelectedGateAction {
  inspect,
  replace,
  editAngle,
  duplicate,
  move,
  delete,
}

@immutable
class ComposerSelectedGateCapabilities {
  const ComposerSelectedGateCapabilities._(this.actions);

  static const none = ComposerSelectedGateCapabilities._({});

  final Set<ComposerSelectedGateAction> actions;

  bool supports(ComposerSelectedGateAction action) => actions.contains(action);

  static ComposerSelectedGateCapabilities forSelection(
    QuantumCircuit circuit,
    GateId? selectedGateId,
  ) {
    if (selectedGateId == null) return none;
    final footprint = circuit.logicalGateById(selectedGateId);
    if (footprint == null) return none;
    return ComposerSelectedGateCapabilities._({
      ComposerSelectedGateAction.inspect,
      if (footprint.isEditable &&
          circuit.availableSingleQubitReplacementTypes
              .any((type) => type != footprint.type))
        ComposerSelectedGateAction.replace,
      if (footprint.isParameterEditable) ComposerSelectedGateAction.editAngle,
      if (circuit.canDuplicateLogicalGate(selectedGateId))
        ComposerSelectedGateAction.duplicate,
      if (footprint.isMovable) ComposerSelectedGateAction.move,
      if (footprint.isDeletable) ComposerSelectedGateAction.delete,
    });
  }
}
