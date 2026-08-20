import 'dart:math' as math;

import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

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
