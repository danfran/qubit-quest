import 'dart:math' as math;

import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

const _searchH0 =
    CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0);
const _searchH1 =
    CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 1);
const _searchX0 =
    CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0);
const _searchX1 =
    CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 1);
const _searchCz = CanonicalCircuitStep.controlled(SelectedGateType.cz,
    controlQubit: 0, targetQubit: 1);
const _searchPrepare = [_searchH0, _searchH1];
const _searchOracle = [_searchX0, _searchCz, _searchX0];
const _searchReflect = [
  ..._searchPrepare,
  _searchX0,
  _searchX1,
  _searchCz,
  _searchX0,
  _searchX1,
  ..._searchPrepare
];
const _searchH2 =
    CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 2);
const _searchX2 =
    CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 2);
const _searchCcz = [
  _searchH2,
  CanonicalCircuitStep.toffoli(
      controlQubit: 0, secondControlQubit: 1, targetQubit: 2),
  _searchH2
];
const _searchPrepare8 = [_searchH0, _searchH1, _searchH2];
const _searchOracle8 = [_searchX0, ..._searchCcz, _searchX0];
const _searchReflect8 = [
  ..._searchPrepare8,
  _searchX0,
  _searchX1,
  _searchX2,
  ..._searchCcz,
  _searchX0,
  _searchX1,
  _searchX2,
  ..._searchPrepare8
];

final List<ExecutableNotebookExample> executableNotebookExamples =
    List.unmodifiable([
  ExecutableNotebookExample(
    id: 'x_from_zero',
    title: 'Run the X gate',
    description: 'Flip |0⟩ to |1⟩.',
    qubitCount: 1,
    initialBinaryState: '0',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.x, targetQubit: 0),
    ],
    expectedState: const [NotebookAmplitude(0), NotebookAmplitude(1)],
    relatedConcept: 'Information',
    allowOpenInBlochExplorer: true,
  ),
  ExecutableNotebookExample(
    id: 'h_superposition',
    title: 'Create |+⟩',
    description: 'Apply H to a qubit prepared in |0⟩.',
    qubitCount: 1,
    initialBinaryState: '0',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
    ],
    expectedState: const [
      NotebookAmplitude(math.sqrt1_2),
      NotebookAmplitude(math.sqrt1_2),
    ],
    relatedConcept: 'Superposition',
    allowOpenInBlochExplorer: true,
  ),
  ExecutableNotebookExample(
    id: 'z_on_plus',
    title: 'Reveal relative phase',
    description: 'Prepare |+⟩, then use Z to create |−⟩.',
    qubitCount: 1,
    initialBinaryState: '0',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
      CanonicalCircuitStep.single(SelectedGateType.z, targetQubit: 0),
    ],
    expectedState: const [
      NotebookAmplitude(math.sqrt1_2),
      NotebookAmplitude(-math.sqrt1_2),
    ],
    relatedConcept: 'Relative Phase',
    allowOpenInBlochExplorer: true,
  ),
  ExecutableNotebookExample(
    id: 's_on_plus',
    title: 'Create |+i⟩',
    description: 'Prepare |+⟩ and rotate its relative phase with S.',
    qubitCount: 1,
    initialBinaryState: '0',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
      CanonicalCircuitStep.single(SelectedGateType.s, targetQubit: 0),
    ],
    expectedState: const [
      NotebookAmplitude(math.sqrt1_2),
      NotebookAmplitude(0, math.sqrt1_2),
    ],
    relatedConcept: 'Phase Information',
    allowOpenInBlochExplorer: true,
  ),
  ExecutableNotebookExample(
    id: 'ry_rotation',
    title: 'Rotate around Y',
    description: 'Apply Ry(π/2) to move |0⟩ to |+⟩.',
    qubitCount: 1,
    initialBinaryState: '0',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.ry,
          targetQubit: 0, angle: math.pi / 2),
    ],
    expectedState: const [
      NotebookAmplitude(math.sqrt1_2),
      NotebookAmplitude(math.sqrt1_2),
    ],
    relatedConcept: 'Precise Superposition',
    allowOpenInBlochExplorer: true,
  ),
  ExecutableNotebookExample(
    id: 'bell_phi_plus',
    title: 'Build a Bell state',
    description: 'Create a shared superposition with H and CX.',
    qubitCount: 2,
    initialBinaryState: '00',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
      CanonicalCircuitStep.controlled(SelectedGateType.cnot,
          controlQubit: 0, targetQubit: 1),
    ],
    expectedState: const [
      NotebookAmplitude(math.sqrt1_2),
      NotebookAmplitude(0),
      NotebookAmplitude(0),
      NotebookAmplitude(math.sqrt1_2),
    ],
    relatedConcept: 'Bell State',
  ),
  ExecutableNotebookExample(
    id: 'interference_hzh',
    title: 'Turn phase into probability',
    description: 'Prepare, phase-shift, and recombine with H → Z → H.',
    qubitCount: 1,
    initialBinaryState: '0',
    operations: const [
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
      CanonicalCircuitStep.single(SelectedGateType.z, targetQubit: 0),
      CanonicalCircuitStep.single(SelectedGateType.hadamard, targetQubit: 0),
    ],
    expectedState: const [NotebookAmplitude(0), NotebookAmplitude(1)],
    relatedConcept: 'Interference',
    allowOpenInBlochExplorer: true,
  ),
  ExecutableNotebookExample(
      id: 'search_marked_input',
      title: 'Prepare the signed search input',
      description:
          'Basis order 00,01,10,11; q0 is the top wire. Reflection uses -D.',
      qubitCount: 2,
      initialBinaryState: '00',
      operations: const [..._searchPrepare, ..._searchOracle],
      expectedState: const [
        NotebookAmplitude(0.5),
        NotebookAmplitude(0.5),
        NotebookAmplitude(-0.5),
        NotebookAmplitude(0.5)
      ],
      relatedConcept: 'Reflection About the Mean'),
  ExecutableNotebookExample(
      id: 'search_reflection',
      title: 'Apply the reusable reflection',
      description:
          'Basis order 00,01,10,11; q0 is the top wire. Reflection uses -D.',
      qubitCount: 2,
      initialBinaryState: '00',
      operations: const [..._searchReflect],
      expectedState: const [
        NotebookAmplitude(0.5),
        NotebookAmplitude(-0.5),
        NotebookAmplitude(-0.5),
        NotebookAmplitude(-0.5)
      ],
      relatedConcept: 'Diffusion as a Circuit'),
  ExecutableNotebookExample(
      id: 'search_correct_order',
      title: 'Mark then amplify',
      description:
          'Basis order 00,01,10,11; q0 is the top wire. Reflection uses -D.',
      qubitCount: 2,
      initialBinaryState: '00',
      operations: const [
        ..._searchPrepare,
        ..._searchOracle,
        ..._searchReflect
      ],
      expectedState: const [
        NotebookAmplitude(0),
        NotebookAmplitude(0),
        NotebookAmplitude(-1),
        NotebookAmplitude(0)
      ],
      relatedConcept: 'Four-State Quantum Search'),
  ExecutableNotebookExample(
      id: 'search_reordered',
      title: 'Reflect before marking',
      description:
          'Basis order 00,01,10,11; q0 is the top wire. Reflection uses -D.',
      qubitCount: 2,
      initialBinaryState: '00',
      operations: const [
        ..._searchPrepare,
        ..._searchReflect,
        ..._searchOracle
      ],
      expectedState: const [
        NotebookAmplitude(-0.5),
        NotebookAmplitude(-0.5),
        NotebookAmplitude(0.5),
        NotebookAmplitude(-0.5)
      ],
      relatedConcept: 'Search Round Order'),
  ExecutableNotebookExample(
      id: 'search_two_rounds',
      title: 'Run two four-state rounds',
      description:
          'Basis order 00,01,10,11; q0 is the top wire. Reflection uses -D.',
      qubitCount: 2,
      initialBinaryState: '00',
      operations: const [
        ..._searchPrepare,
        ..._searchOracle,
        ..._searchReflect,
        ..._searchOracle,
        ..._searchReflect
      ],
      expectedState: const [
        NotebookAmplitude(-0.5),
        NotebookAmplitude(-0.5),
        NotebookAmplitude(0.5),
        NotebookAmplitude(-0.5)
      ],
      relatedConcept: 'Search Stopping Point'),
  ExecutableNotebookExample(
      id: 'search_eight_1',
      title: 'Eight-state search: 1 round(s)',
      description: 'Mark 110; run 1 oracle/-D rounds. Basis order q2 q1 q0.',
      qubitCount: 3,
      initialBinaryState: '000',
      operations: const [
        ..._searchPrepare8,
        ..._searchOracle8,
        ..._searchReflect8
      ],
      expectedState: [
        for (var i = 0; i < 8; i++)
          NotebookAmplitude(-1 * (i == 6 ? 2.5 : 0.5) / math.sqrt(8))
      ],
      relatedConcept: 'Quantitative Search'),
  ExecutableNotebookExample(
      id: 'search_eight_2',
      title: 'Eight-state search: 2 round(s)',
      description: 'Mark 110; run 2 oracle/-D rounds. Basis order q2 q1 q0.',
      qubitCount: 3,
      initialBinaryState: '000',
      operations: const [
        ..._searchPrepare8,
        ..._searchOracle8,
        ..._searchReflect8,
        ..._searchOracle8,
        ..._searchReflect8
      ],
      expectedState: [
        for (var i = 0; i < 8; i++)
          NotebookAmplitude(1 * (i == 6 ? 2.75 : -0.25) / math.sqrt(8))
      ],
      relatedConcept: 'Quantitative Search'),
  ExecutableNotebookExample(
      id: 'search_eight_3',
      title: 'Eight-state search: 3 round(s)',
      description: 'Mark 110; run 3 oracle/-D rounds. Basis order q2 q1 q0.',
      qubitCount: 3,
      initialBinaryState: '000',
      operations: const [
        ..._searchPrepare8,
        ..._searchOracle8,
        ..._searchReflect8,
        ..._searchOracle8,
        ..._searchReflect8,
        ..._searchOracle8,
        ..._searchReflect8
      ],
      expectedState: [
        for (var i = 0; i < 8; i++)
          NotebookAmplitude(-1 * (i == 6 ? 1.625 : -0.875) / math.sqrt(8))
      ],
      relatedConcept: 'Quantitative Search'),
]);

final Map<String, ExecutableNotebookExample> executableNotebookExamplesById =
    Map.unmodifiable({
  for (final example in executableNotebookExamples) example.id: example,
});

final Map<String, List<ExecutableNotebookExample>>
    executableNotebookExamplesByDiscovery = Map.unmodifiable(
  <String, List<ExecutableNotebookExample>>{
    for (final example in executableNotebookExamples)
      example.relatedConcept!: List<ExecutableNotebookExample>.unmodifiable([
        for (final candidate in executableNotebookExamples)
          if (candidate.relatedConcept == example.relatedConcept) candidate,
      ]),
  },
);
