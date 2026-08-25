import 'dart:math' as math;

import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

CanonicalCircuitStep _s(SelectedGateType type, int target, [double? angle]) =>
    CanonicalCircuitStep.single(type, targetQubit: target, angle: angle);

CanonicalCircuitStep _c(SelectedGateType type, int control, int target) =>
    CanonicalCircuitStep.controlled(
      type,
      controlQubit: control,
      targetQubit: target,
    );

CanonicalCircuitStep _cc(int control, int secondControl, int target) =>
    CanonicalCircuitStep.toffoli(
      controlQubit: control,
      secondControlQubit: secondControl,
      targetQubit: target,
    );

CanonicalComposerSolution _q(List<CanonicalCircuitStep> steps) =>
    CanonicalComposerSolution(steps);

/// Canonical learner-authored operations keyed by active campaign level ID.
///
/// Entries are transcribed from explicit authored hints/solutions and the
/// production-validation regression circuits. Fixed pre-inserted operations
/// are intentionally omitted.
final Map<int, CanonicalComposerSolution> canonicalComposerSolutionCatalog = {
  // Guided Discovery — Information through Superposition.
  2: _q([_s(SelectedGateType.x, 0)]),
  3: _q([
    _s(SelectedGateType.x, 0),
    _s(SelectedGateType.x, 0),
    _s(SelectedGateType.x, 0)
  ]),
  4: _q([_s(SelectedGateType.x, 0), _s(SelectedGateType.x, 1)]),
  5: _q([_s(SelectedGateType.x, 0), _s(SelectedGateType.x, 1)]),
  6: _q([_s(SelectedGateType.z, 0)]),
  7: _q([_s(SelectedGateType.z, 0)]),
  8: _q([_s(SelectedGateType.z, 0)]),
  9: _q([_s(SelectedGateType.z, 0)]),
  10: _q([_s(SelectedGateType.z, 0), _s(SelectedGateType.hadamard, 0)]),
  11: _q([_s(SelectedGateType.hadamard, 0)]),
  12: _q([_s(SelectedGateType.hadamard, 0)]),
  13: _q([_s(SelectedGateType.hadamard, 0)]),
  14: _q([_s(SelectedGateType.x, 0), _s(SelectedGateType.hadamard, 0)]),
  15: _q([_s(SelectedGateType.x, 1), _s(SelectedGateType.hadamard, 1)]),
  16: _q([_s(SelectedGateType.z, 0)]),
  18: _q([
    _s(SelectedGateType.hadamard, 0),
    _s(SelectedGateType.x, 0),
    _s(SelectedGateType.hadamard, 0)
  ]),
  19: _q([_s(SelectedGateType.z, 0), _s(SelectedGateType.hadamard, 0)]),
  20: _q([_s(SelectedGateType.hadamard, 0)]),

  // Guided Discovery — Entanglement, Information Flow and GHZ.
  21: _q([_s(SelectedGateType.x, 0), _s(SelectedGateType.x, 1)]),
  22: _q([_c(SelectedGateType.cnot, 1, 0)]),
  24: _q([_s(SelectedGateType.hadamard, 0), _c(SelectedGateType.cnot, 0, 1)]),
  25: _q([_s(SelectedGateType.hadamard, 0), _c(SelectedGateType.cnot, 0, 1)]),
  26: _q([_c(SelectedGateType.cnot, 0, 1)]),
  27: _q([_c(SelectedGateType.cnot, 0, 1)]),
  28: _q([_s(SelectedGateType.x, 0), _c(SelectedGateType.cnot, 0, 1)]),
  29: _q([
    _c(SelectedGateType.cnot, 1, 0),
    _c(SelectedGateType.cnot, 0, 1),
    _c(SelectedGateType.cnot, 1, 0)
  ]),
  30: _q([
    _s(SelectedGateType.x, 0),
    _c(SelectedGateType.cnot, 1, 0),
    _c(SelectedGateType.cnot, 0, 1),
    _c(SelectedGateType.cnot, 1, 0)
  ]),
  31: _q([
    _s(SelectedGateType.x, 0),
    _s(SelectedGateType.x, 1),
    _s(SelectedGateType.x, 2)
  ]),
  32: _q([_c(SelectedGateType.cnot, 0, 1), _c(SelectedGateType.cnot, 0, 2)]),
  34: _q([
    _s(SelectedGateType.hadamard, 0),
    _c(SelectedGateType.cnot, 0, 1),
    _c(SelectedGateType.cnot, 0, 2)
  ]),

  // Guided Discovery — Phase Kickback, Oracles and Amplification.
  36: _q([_c(SelectedGateType.cz, 0, 1)]),
  37: _q([_c(SelectedGateType.cnot, 0, 1)]),
  38: _q([_c(SelectedGateType.cnot, 0, 1)]),
  39: _q([_c(SelectedGateType.cnot, 0, 1)]),
  40: _q([_c(SelectedGateType.cnot, 0, 1), _s(SelectedGateType.hadamard, 0)]),
  41: _q([_c(SelectedGateType.cz, 0, 1)]),
  42: _q([_s(SelectedGateType.z, 0)]),
  43: _q([
    _s(SelectedGateType.x, 0),
    _c(SelectedGateType.cz, 0, 1),
    _s(SelectedGateType.x, 0)
  ]),
  44: _q([
    _s(SelectedGateType.x, 1),
    _c(SelectedGateType.cz, 0, 1),
    _s(SelectedGateType.x, 1)
  ]),
  45: _q([
    _s(SelectedGateType.x, 0),
    _s(SelectedGateType.x, 1),
    _c(SelectedGateType.cz, 0, 1),
    _s(SelectedGateType.x, 0),
    _s(SelectedGateType.x, 1)
  ]),
  46: _q([_c(SelectedGateType.cz, 0, 1)]),
  47: _q([_s(SelectedGateType.hadamard, 0)]),
  48: _q([_c(SelectedGateType.cz, 0, 1), _s(SelectedGateType.hadamard, 0)]),

  // Mastery Challenges. Non-Composer challenges intentionally have no
  // canonical circuit entry. IDs 65, 74, 78, 88, 98, 102 and 103 already
  // carry inline phase-one metadata and are deliberately not duplicated here.
  65: _q([
    _s(SelectedGateType.x, 0),
    _s(SelectedGateType.z, 0),
    _s(SelectedGateType.x, 0)
  ]),
  67: _q([_s(SelectedGateType.hadamard, 0), _s(SelectedGateType.t, 0)]),
  70: _q([_s(SelectedGateType.hadamard, 1), _s(SelectedGateType.x, 0)]),
  72: _q([
    _s(SelectedGateType.s, 0),
    _s(SelectedGateType.hadamard, 0),
    _s(SelectedGateType.x, 0)
  ]),
  73: _q([
    _s(SelectedGateType.hadamard, 0),
    _s(SelectedGateType.s, 0),
    _s(SelectedGateType.t, 0),
    _s(SelectedGateType.z, 0)
  ]),
  75: _q([_c(SelectedGateType.cnot, 0, 1)]),
  76: _q([_c(SelectedGateType.cnot, 2, 0)]),
  77: _q([_c(SelectedGateType.cnot, 0, 1), _s(SelectedGateType.x, 0)]),
  79: _q([_cc(0, 1, 2)]),
  80: _q([_cc(1, 2, 0)]),
  81: _q([_s(SelectedGateType.x, 0), _cc(0, 1, 2)]),
  82: _q([_s(SelectedGateType.hadamard, 0), _c(SelectedGateType.cnot, 0, 1)]),
  83: _q([_s(SelectedGateType.hadamard, 0), _c(SelectedGateType.cnot, 0, 1)]),
  84: _q([_c(SelectedGateType.cnot, 0, 1), _s(SelectedGateType.hadamard, 0)]),
  85: _q([
    _s(SelectedGateType.hadamard, 0),
    _c(SelectedGateType.cnot, 0, 1),
    _s(SelectedGateType.z, 1)
  ]),
  86: _q([
    _s(SelectedGateType.hadamard, 0),
    _c(SelectedGateType.cnot, 0, 1),
    _s(SelectedGateType.z, 0)
  ]),
  87: _q([
    _s(SelectedGateType.z, 0),
    _c(SelectedGateType.cnot, 0, 1),
    _s(SelectedGateType.hadamard, 0)
  ]),
  89: _q([
    _s(SelectedGateType.hadamard, 0),
    _c(SelectedGateType.cnot, 0, 1),
    _s(SelectedGateType.hadamard, 0)
  ]),
  90: _q([
    _s(SelectedGateType.x, 1),
    _s(SelectedGateType.hadamard, 0),
    _c(SelectedGateType.cnot, 0, 1)
  ]),
  91: _q([
    _s(SelectedGateType.x, 1),
    _s(SelectedGateType.hadamard, 0),
    _c(SelectedGateType.cnot, 0, 1),
    _s(SelectedGateType.z, 0)
  ]),
  92: _q([_c(SelectedGateType.cnot, 1, 0)]),
  93: _q([_c(SelectedGateType.cnot, 0, 2)]),
  94: _q([_c(SelectedGateType.cnot, 2, 1), _c(SelectedGateType.cnot, 2, 0)]),
  95: _q([_s(SelectedGateType.x, 0)]),
  96: _q([_s(SelectedGateType.hadamard, 0), _s(SelectedGateType.hadamard, 1)]),
  97: _q([
    _s(SelectedGateType.x, 0),
    _s(SelectedGateType.hadamard, 0),
    _c(SelectedGateType.cnot, 0, 1),
    _c(SelectedGateType.cnot, 1, 2),
    _s(SelectedGateType.z, 2)
  ]),
  99: _q([
    _c(SelectedGateType.cz, 0, 1),
    _s(SelectedGateType.hadamard, 0),
    _s(SelectedGateType.hadamard, 1)
  ]),
  100: _q([_s(SelectedGateType.rx, 0, math.pi / 2)]),
  101: _q([_s(SelectedGateType.ry, 0, math.pi / 2)]),
  104: _q([_s(SelectedGateType.ry, 0, math.pi / 2)]),
  105: _q([_s(SelectedGateType.rz, 1, math.pi / 4)]),
  106: _q([
    _s(SelectedGateType.ry, 0, math.pi / 3),
    _s(SelectedGateType.rz, 0, math.pi / 2)
  ]),
};
