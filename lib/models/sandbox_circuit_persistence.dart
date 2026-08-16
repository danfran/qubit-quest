import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<SelectedGateType> sandboxGatePaletteTypes = [
  SelectedGateType.x,
  SelectedGateType.y,
  SelectedGateType.z,
  SelectedGateType.hadamard,
  SelectedGateType.s,
  SelectedGateType.t,
  SelectedGateType.cz,
  SelectedGateType.cnot,
  SelectedGateType.ccnot,
  SelectedGateType.rx,
  SelectedGateType.ry,
  SelectedGateType.rz,
];

const Set<SelectedGateType> sandboxGateTypes = {
  ...sandboxGatePaletteTypes,
};

ComposerLevel createSandboxComposerLevel(
  int qubitCount, {
  String? initialBinaryState,
}) {
  final initial = initialBinaryState ?? '0' * qubitCount;
  return ComposerLevel.fromBinaryString(
    taskDescription:
        'Experiment with any combination of gates on your chosen number of '
        'qubits. Build circuits, visualize the resulting quantum state, and '
        'generate the overall unitary operator matrix for your circuit.',
    numQubits: qubitCount,
    initialQubitsStateString: initial,
    availableGates: [
      for (final type in sandboxGatePaletteTypes) Gate.fromIdentifier(type),
    ],
    solutionFinalVector: const [],
  );
}

@immutable
class SandboxCircuitOperation {
  const SandboxCircuitOperation({
    required this.gateType,
    required this.column,
    required this.targetQubit,
    this.controlQubit,
    this.secondControlQubit,
    this.angle,
  });

  final SelectedGateType gateType;
  final int column;
  final int targetQubit;
  final int? controlQubit;
  final int? secondControlQubit;
  final double? angle;

  Map<String, Object> toJson() => {
        'gateType': gateType.name,
        'column': column,
        'targetQubit': targetQubit,
        if (controlQubit != null) 'controlQubit': controlQubit!,
        if (secondControlQubit != null)
          'secondControlQubit': secondControlQubit!,
        if (angle != null) 'angle': angle!,
      };

  factory SandboxCircuitOperation.fromJson(Map<String, dynamic> json) {
    final gateName = json['gateType'];
    final column = json['column'];
    final target = json['targetQubit'];
    if (gateName is! String || column is! int || target is! int) {
      throw const FormatException('Malformed Sandbox operation.');
    }
    SelectedGateType? type;
    for (final candidate in SelectedGateType.values) {
      if (candidate.name == gateName) {
        type = candidate;
        break;
      }
    }
    if (type == null || !sandboxGateTypes.contains(type)) {
      throw FormatException('Unsupported Sandbox gate: $gateName.');
    }
    int? optionalInt(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! int) throw FormatException('Invalid $key.');
      return value;
    }

    final rawAngle = json['angle'];
    if (rawAngle != null && rawAngle is! num) {
      throw const FormatException('Invalid rotation angle.');
    }
    return SandboxCircuitOperation(
      gateType: type,
      column: column,
      targetQubit: target,
      controlQubit: optionalInt('controlQubit'),
      secondControlQubit: optionalInt('secondControlQubit'),
      angle: (rawAngle as num?)?.toDouble(),
    );
  }
}

@immutable
class SandboxCircuitSnapshot {
  static const int currentSchemaVersion = 1;

  SandboxCircuitSnapshot({
    this.schemaVersion = currentSchemaVersion,
    required this.qubitCount,
    required this.initialBinaryState,
    required Iterable<SandboxCircuitOperation> operations,
  }) : operations = List.unmodifiable(operations);

  final int schemaVersion;
  final int qubitCount;
  final String initialBinaryState;
  final List<SandboxCircuitOperation> operations;

  factory SandboxCircuitSnapshot.empty(int qubitCount) =>
      SandboxCircuitSnapshot(
        qubitCount: qubitCount,
        initialBinaryState: '0' * qubitCount,
        operations: const [],
      );

  factory SandboxCircuitSnapshot.capture(QuantumCircuit circuit) {
    final footprints = [...circuit.logicalGates]..sort((first, second) {
        final column = first.column.compareTo(second.column);
        return column != 0
            ? column
            : first.anchor.qubit.compareTo(second.anchor.qubit);
      });
    return SandboxCircuitSnapshot(
      qubitCount: circuit.currentLevel.numQubits,
      initialBinaryState: circuit.currentLevel.initialQubitsStateStr,
      operations: [for (final gate in footprints) _captureGate(gate)],
    );
  }

  static SandboxCircuitOperation _captureGate(LogicalGateFootprint gate) =>
      SandboxCircuitOperation(
        gateType: gate.type,
        column: gate.column,
        targetQubit: gate.targetQubit ?? gate.anchor.qubit,
        controlQubit: gate.controlQubit,
        secondControlQubit: gate.secondControlQubit,
        angle: gate.gate.angle,
      );

  Map<String, Object> toJson() => {
        'schemaVersion': schemaVersion,
        'qubitCount': qubitCount,
        'initialState': initialBinaryState,
        'operations': [for (final operation in operations) operation.toJson()],
      };

  String encode() => jsonEncode(toJson());

  factory SandboxCircuitSnapshot.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Sandbox snapshot must be a JSON object.');
    }
    final version = decoded['schemaVersion'];
    final qubits = decoded['qubitCount'];
    final initial = decoded['initialState'];
    final rawOperations = decoded['operations'];
    if (version is! int || qubits is! int || initial is! String) {
      throw const FormatException('Malformed Sandbox snapshot header.');
    }
    if (version != currentSchemaVersion) {
      throw FormatException('Unsupported Sandbox schema version: $version.');
    }
    if (rawOperations is! List) {
      throw const FormatException('Malformed Sandbox operations.');
    }
    return SandboxCircuitSnapshot(
      schemaVersion: version,
      qubitCount: qubits,
      initialBinaryState: initial,
      operations: [
        for (final operation in rawOperations)
          if (operation is Map<String, dynamic>)
            SandboxCircuitOperation.fromJson(operation)
          else
            throw const FormatException('Malformed Sandbox operation.'),
      ],
    );
  }

  QuantumCircuit restoreCircuit() {
    if (schemaVersion != currentSchemaVersion ||
        qubitCount < 1 ||
        qubitCount > 5 ||
        initialBinaryState.length != qubitCount ||
        !RegExp(r'^[01]+$').hasMatch(initialBinaryState)) {
      throw const FormatException('Invalid Sandbox snapshot metadata.');
    }
    final circuit = QuantumCircuit(
      currentLevel: createSandboxComposerLevel(
        qubitCount,
        initialBinaryState: initialBinaryState,
      ),
    );
    for (final operation in operations) {
      final outcome = _restoreOperation(circuit, operation);
      if (!outcome.changed) {
        throw FormatException(
            'Invalid Sandbox operation: ${operation.toJson()}');
      }
    }
    circuit.runSimulation();
    if (circuit.lastSimulationError != null ||
        circuit.logicalGates.any(
          (gate) => !gate.hasValidTopology(qubitCount),
        )) {
      throw const FormatException('Restored Sandbox circuit is malformed.');
    }
    final restored = SandboxCircuitSnapshot.capture(circuit);
    if (!_sameOperations(operations, restored.operations)) {
      throw const FormatException('Sandbox operation placement is invalid.');
    }
    return circuit;
  }

  static CircuitEditOutcome _restoreOperation(
    QuantumCircuit circuit,
    SandboxCircuitOperation operation,
  ) {
    if (operation.column < 0 ||
        operation.targetQubit < 0 ||
        operation.targetQubit >= circuit.currentLevel.numQubits) {
      return CircuitEditOutcome.invalid;
    }
    final rotation = const {
      SelectedGateType.rx,
      SelectedGateType.ry,
      SelectedGateType.rz,
    }.contains(operation.gateType);
    if ((rotation && (operation.angle == null || !operation.angle!.isFinite)) ||
        (!rotation && operation.angle != null)) {
      return CircuitEditOutcome.invalid;
    }
    final gate =
        Gate.fromIdentifier(operation.gateType, angle: operation.angle);
    if (operation.gateType == SelectedGateType.ccnot) {
      final control = operation.controlQubit;
      final second = operation.secondControlQubit;
      if (control == null || second == null) return CircuitEditOutcome.invalid;
      return circuit.insertTripleGateWithOutcome(
        gate,
        operation.column,
        operation.targetQubit,
        control,
        second,
      );
    }
    if (operation.gateType == SelectedGateType.cnot ||
        operation.gateType == SelectedGateType.cz) {
      final control = operation.controlQubit;
      if (control == null || operation.secondControlQubit != null) {
        return CircuitEditOutcome.invalid;
      }
      return circuit.insertDoubleGateWithOutcome(
        gate,
        operation.column,
        operation.targetQubit,
        control,
      );
    }
    if (operation.controlQubit != null ||
        operation.secondControlQubit != null) {
      return CircuitEditOutcome.invalid;
    }
    return circuit.insertSingleGateWithOutcome(
      gate,
      operation.column,
      operation.targetQubit,
    );
  }

  static bool _sameOperations(
    List<SandboxCircuitOperation> first,
    List<SandboxCircuitOperation> second,
  ) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      final a = first[index];
      final b = second[index];
      if (a.gateType != b.gateType ||
          a.column != b.column ||
          a.targetQubit != b.targetQubit ||
          a.controlQubit != b.controlQubit ||
          a.secondControlQubit != b.secondControlQubit ||
          a.angle != b.angle) {
        return false;
      }
    }
    return true;
  }
}

class SandboxPersistenceStore {
  const SandboxPersistenceStore();

  static const String storageKey = 'sandbox_circuit_snapshot';

  Future<void> saveCircuit(QuantumCircuit circuit) =>
      saveSnapshot(SandboxCircuitSnapshot.capture(circuit));

  Future<void> saveSnapshot(SandboxCircuitSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(storageKey, snapshot.encode());
  }

  Future<SandboxCircuitSnapshot?> loadSnapshot() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(storageKey);
    if (encoded == null) return null;
    try {
      final snapshot = SandboxCircuitSnapshot.decode(encoded);
      snapshot.restoreCircuit();
      return snapshot;
    } catch (error) {
      assert(() {
        debugPrint('Discarding invalid Sandbox snapshot: $error');
        return true;
      }());
      await preferences.remove(storageKey);
      return null;
    }
  }
}
