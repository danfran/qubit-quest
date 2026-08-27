import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/composer_gate_capabilities.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  const singleTypes = [
    SelectedGateType.x,
    SelectedGateType.y,
    SelectedGateType.z,
    SelectedGateType.hadamard,
    SelectedGateType.s,
    SelectedGateType.t,
    SelectedGateType.rx,
    SelectedGateType.ry,
    SelectedGateType.rz,
  ];
  const controlledTypes = [
    SelectedGateType.cnot,
    SelectedGateType.cz,
    SelectedGateType.ccnot,
  ];

  Gate configured(SelectedGateType type) => Gate.fromIdentifier(
        type,
        angle: const {
          SelectedGateType.rx,
          SelectedGateType.ry,
          SelectedGateType.rz,
        }.contains(type)
            ? math.pi / 4
            : null,
      );

  test('mobile and Web Sandbox palette consume canonical level order', () {
    final level = createSandboxComposerLevel(3);
    expect(
      level.availableGates.map((gate) => gate.type),
      orderedEquals(sandboxGatePaletteTypes),
    );
    expect(
      level.availableGates
          .map((gate) => GateEducationalCatalog.forType(gate.type)),
      everyElement(isNotNull),
    );
    expect(
      level.availableGates.map((gate) => gate.type).toSet(),
      GateEducationalCatalog.productionGateTypes,
    );
  });

  test('single-qubit selected actions match mobile capability rules', () {
    for (final type in singleTypes) {
      final circuit =
          QuantumCircuit(currentLevel: createSandboxComposerLevel(3));
      final outcome =
          circuit.insertSingleGateWithOutcome(configured(type), 0, 0);
      final capabilities = ComposerSelectedGateCapabilities.forSelection(
        circuit,
        outcome.affectedGateId,
      );
      expect(capabilities.supports(ComposerSelectedGateAction.inspect), isTrue,
          reason: '$type inspect');
      expect(capabilities.supports(ComposerSelectedGateAction.replace), isTrue,
          reason: '$type replace');
      expect(
          capabilities.supports(ComposerSelectedGateAction.duplicate), isTrue,
          reason: '$type duplicate');
      expect(capabilities.supports(ComposerSelectedGateAction.move), isTrue,
          reason: '$type move');
      expect(capabilities.supports(ComposerSelectedGateAction.delete), isTrue,
          reason: '$type delete');
      expect(
        capabilities.supports(ComposerSelectedGateAction.editAngle),
        const {
          SelectedGateType.rx,
          SelectedGateType.ry,
          SelectedGateType.rz,
        }.contains(type),
        reason: '$type angle editing',
      );
      circuit.dispose();
    }
  });

  test('controlled selected actions preserve logical footprint capabilities',
      () {
    for (final type in controlledTypes) {
      final circuit =
          QuantumCircuit(currentLevel: createSandboxComposerLevel(3));
      final outcome = type == SelectedGateType.ccnot
          ? circuit.insertTripleGateWithOutcome(configured(type), 0, 2, 0, 1)
          : circuit.insertDoubleGateWithOutcome(configured(type), 0, 2, 0);
      final footprint = circuit.logicalGateById(outcome.affectedGateId!);
      final capabilities = ComposerSelectedGateCapabilities.forSelection(
        circuit,
        outcome.affectedGateId,
      );
      expect(footprint, isNotNull, reason: '$type identity');
      expect(footprint!.hasValidTopology(3), isTrue, reason: '$type topology');
      expect(capabilities.supports(ComposerSelectedGateAction.inspect), isTrue);
      expect(
          capabilities.supports(ComposerSelectedGateAction.duplicate), isTrue);
      expect(capabilities.supports(ComposerSelectedGateAction.move), isTrue);
      expect(capabilities.supports(ComposerSelectedGateAction.delete), isTrue);
      expect(
          capabilities.supports(ComposerSelectedGateAction.replace), isFalse);
      expect(
          capabilities.supports(ComposerSelectedGateAction.editAngle), isFalse);
      circuit.dispose();
    }
  });
}
