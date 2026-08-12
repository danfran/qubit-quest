import 'package:quantumquiz/models/selected_gate_type.dart';

/// Author-owned, display-neutral construction metadata for a Composer level.
///
/// Steps are applied in list order and appended to circuit time. Independent
/// operations are deliberately serialized: this preserves their semantics
/// without coupling canonical content to compacted visual columns.
class CanonicalComposerSolution {
  final List<CanonicalCircuitStep> steps;

  CanonicalComposerSolution(Iterable<CanonicalCircuitStep> steps)
      : steps = List.unmodifiable(steps);

  @override
  String toString() => steps.join(' -> ');
}

class CanonicalCircuitStep {
  final SelectedGateType gateType;
  final int targetQubit;
  final int? controlQubit;
  final int? secondControlQubit;
  final double? angle;

  const CanonicalCircuitStep({
    required this.gateType,
    required this.targetQubit,
    this.controlQubit,
    this.secondControlQubit,
    this.angle,
  });

  const CanonicalCircuitStep.single(
    this.gateType, {
    required this.targetQubit,
    this.angle,
  })  : controlQubit = null,
        secondControlQubit = null;

  const CanonicalCircuitStep.controlled(
    this.gateType, {
    required this.controlQubit,
    required this.targetQubit,
  })  : secondControlQubit = null,
        angle = null;

  const CanonicalCircuitStep.toffoli({
    required this.controlQubit,
    required this.secondControlQubit,
    required this.targetQubit,
  })  : gateType = SelectedGateType.ccnot,
        angle = null;

  @override
  String toString() {
    final controls = [controlQubit, secondControlQubit]
        .whereType<int>()
        .map((qubit) => 'q$qubit')
        .join(',');
    return '${gateType.name}(target:q$targetQubit'
        '${controls.isEmpty ? '' : ', controls:$controls'}'
        '${angle == null ? '' : ', angle:$angle'})';
  }
}
