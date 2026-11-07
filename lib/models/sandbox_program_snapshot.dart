import 'dart:convert';
import 'package:advance_math/advance_math.dart';
import 'circuit_program.dart';
import 'gate_id.dart';
import 'qq_level.dart';
import 'quantum_circuit.dart';
import 'sandbox_circuit_persistence.dart';
import 'selected_gate_type.dart';
import '../storage/app_storage.dart';

/// Schema 2 definition only. Separate from schema-1 autosave and activation.
class SandboxProgramSnapshot {
  SandboxProgramSnapshot(this.program, {required this.initialStateLabel}) {
    if (program.qubitCount > 5 ||
        initialStateLabel.isEmpty ||
        program.classicalBitCount > 1024 ||
        program.operations.any((o) => o.id.value < 1 || o.column > 10000)) {
      throw const FormatException(
          'Invalid Sandbox metadata or resource bounds');
    }
    final circuit = restoreCircuit();
    circuit.dispose();
  }
  final CircuitProgram program;
  final String initialStateLabel;
  static const schemaVersion = 2;

  factory SandboxProgramSnapshot.capture(QuantumCircuit circuit) =>
      SandboxProgramSnapshot(CircuitProgram.fromCircuit(circuit),
          initialStateLabel: circuit.currentLevel.initialQubitsStateStr);

  QuantumCircuit restoreCircuit() => QuantumCircuit.restoreProgram(
      program: program,
      currentLevel: ComposerLevel(
        taskDescription:
            createSandboxComposerLevel(program.qubitCount).taskDescription,
        numQubits: program.qubitCount,
        initialQubitsStateStr: initialStateLabel,
        initialQubitsState: program.initialState,
        availableGates: [
          for (final g in sandboxGatePaletteTypes) Gate.fromIdentifier(g)
        ],
        solutionFinalVector: const [],
      ));

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'qubitCount': program.qubitCount,
        'classicalBitCount': program.classicalBitCount,
        'initialStateLabel': initialStateLabel,
        'initialState': [
          for (final a in program.initialState) [a.real, a.imaginary]
        ],
        'operations': [
          for (final op in program.operations)
            {
              'id': op.id.value,
              'column': op.column,
              ...switch (op) {
                MeasureZOperation() => <String, Object?>{
                    'kind': 'measureZ',
                    'qubit': op.qubit,
                    'classicalBit': op.classicalBit
                  },
                UnitaryOperation() => <String, Object?>{
                    'kind': 'unitary',
                    'gateType': op.gate.type.name,
                    'target': op.target,
                    if (op.control != null) 'control': op.control,
                    if (op.secondControl != null)
                      'secondControl': op.secondControl,
                    if (op.gate.angle != null) 'angle': op.gate.angle,
                    'isDeletable': op.isDeletable
                  },
              }
            }
        ],
      };
  String encode() => jsonEncode(toJson());

  /// Pure, deterministic conversion. Never reads/writes/deletes storage records.
  factory SandboxProgramSnapshot.decode(String source) {
    final root = jsonDecode(source);
    if (root is! Map<String, dynamic>)
      throw const FormatException('Expected snapshot object');
    if (root['schemaVersion'] == 1) {
      final circuit = SandboxCircuitSnapshot.decode(source).restoreCircuit();
      try {
        return SandboxProgramSnapshot.capture(circuit);
      } finally {
        circuit.dispose();
      }
    }
    if (root['schemaVersion'] != 2)
      throw const FormatException('Unsupported Sandbox schema');
    int integer(Map<String, dynamic> m, String k) {
      final v = m[k];
      if (v is! int) throw FormatException('Missing/invalid $k');
      return v;
    }

    int? optional(Map<String, dynamic> m, String k) =>
        m.containsKey(k) ? integer(m, k) : null;
    final n = integer(root, 'qubitCount');
    final width = integer(root, 'classicalBitCount');
    final label = root['initialStateLabel'];
    final raw = root['initialState'];
    final ops = root['operations'];
    if (n < 1 ||
        n > 5 ||
        width < 0 ||
        width > 1024 ||
        label is! String ||
        raw is! List ||
        ops is! List) {
      throw const FormatException('Invalid Sandbox header');
    }
    final state = <Complex>[];
    for (final a in raw) {
      if (a is! List || a.length != 2 || a[0] is! num || a[1] is! num)
        throw const FormatException('Invalid amplitude');
      state.add(Complex(a[0], a[1]));
    }
    final operations = <CircuitOperation>[];
    for (final op in ops) {
      if (op is! Map<String, dynamic>)
        throw const FormatException('Invalid operation');
      final id = GateId(integer(op, 'id'));
      final column = integer(op, 'column');
      switch (op['kind']) {
        case 'measureZ':
          operations.add(MeasureZOperation(
              id: id,
              column: column,
              qubit: integer(op, 'qubit'),
              classicalBit: integer(op, 'classicalBit')));
        case 'unitary':
          final types = sandboxGateTypes.where((t) => t.name == op['gateType']);
          if (types.length != 1 ||
              op['isDeletable'] is! bool ||
              (op.containsKey('angle') && op['angle'] is! num)) {
            throw const FormatException('Invalid unitary fields');
          }
          operations.add(UnitaryOperation(
              id: id,
              column: column,
              gate: Gate.fromIdentifier(types.single,
                  angle: (op['angle'] as num?)?.toDouble()),
              target: integer(op, 'target'),
              control: optional(op, 'control'),
              secondControl: optional(op, 'secondControl'),
              isDeletable: op['isDeletable']));
        default:
          throw const FormatException('Unsupported operation kind');
      }
    }
    return SandboxProgramSnapshot(
        CircuitProgram(
            qubitCount: n,
            classicalBitCount: width,
            initialState: state,
            operations: operations),
        initialStateLabel: label);
  }

  /// Writes only a caller-unique staging key. No active pointer or legacy mutation.
  /// Readback verifies API visibility, not a durable disk flush. Activation is
  /// deliberately deferred until lifecycle owners can safely select schema 2.
  Future<String> stage(AppStorage storage, {required String stagingId}) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(stagingId))
      throw ArgumentError.value(stagingId);
    final encoded = encode();
    final verified = SandboxProgramSnapshot.decode(encoded);
    if (verified.encode() != encoded)
      throw StateError('Snapshot verification failed');
    final key = 'sandbox_circuit_v2_stage_q${program.qubitCount}_$stagingId';
    final existing = await storage.readString(key);
    if (existing != null && existing != encoded)
      throw StateError('Staging key already occupied');
    if (existing == null) await storage.writeString(key, encoded);
    final readback = await storage.readString(key);
    if (readback != encoded ||
        SandboxProgramSnapshot.decode(readback!).encode() != encoded) {
      throw StateError('Staged snapshot verification failed');
    }
    return key;
  }
}
