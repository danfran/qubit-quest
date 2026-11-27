import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

enum GateEducationalVisualKind {
  blochAxis,
  superposition,
  controlledX,
  controlledPhase,

  /// Controlled-Y: a control dot and a Y target (v2.6 M7).
  controlledY,
  multiControlledX,
  staticGate,
}

@immutable
class GateEducationalVisual {
  const GateEducationalVisual({
    required this.kind,
    this.axisLabel,
    this.rotationRadians,
    this.representativeTransition,
    this.controlCount,
  });

  final GateEducationalVisualKind kind;

  /// Controls drawn by [GateEducationalVisualKind.multiControlledX]
  /// (two when null: the Toffoli).
  final int? controlCount;
  final String? axisLabel;
  final double? rotationRadians;
  final String? representativeTransition;
}

@immutable
class GateRelatedConcept {
  const GateRelatedConcept(this.label, {this.notebookDiscoveryTitle});

  final String label;
  final String? notebookDiscoveryTitle;
}

@immutable
class GateEducationalInfo {
  const GateEducationalInfo({
    required this.type,
    required this.name,
    required this.intuition,
    required this.physicalChange,
    required this.commonUse,
    required this.transformations,
    required this.matrix,
    required this.properties,
    required this.identities,
    required this.relatedConcepts,
    required this.visual,
    this.axis,
    this.notebookDiscoveryTitle,
    this.keyIdeas = const [],
  });

  /// Longer explanations for the Notebook gate article (v2.6 M7); inline
  /// LaTeX allowed. Empty for gates whose summary already suffices.
  final List<String> keyIdeas;

  final SelectedGateType type;
  final String name;
  final String intuition;
  final String physicalChange;
  final String commonUse;
  final List<String> transformations;
  final String matrix;
  final List<String> properties;
  final List<String> identities;
  final List<GateRelatedConcept> relatedConcepts;
  final GateEducationalVisual visual;
  final String? axis;
  final String? notebookDiscoveryTitle;
}

class GateEducationalCatalog {
  const GateEducationalCatalog._();

  static const productionGateTypes = <SelectedGateType>{
    SelectedGateType.x,
    SelectedGateType.y,
    SelectedGateType.z,
    SelectedGateType.hadamard,
    SelectedGateType.s,
    SelectedGateType.t,
    SelectedGateType.rx,
    SelectedGateType.ry,
    SelectedGateType.rz,
    SelectedGateType.cnot,
    SelectedGateType.cz,
    SelectedGateType.ccnot,
    SelectedGateType.cy,
    SelectedGateType.mcx,
  };

  static GateEducationalInfo? forType(SelectedGateType type) => _entries[type];

  static const _entries = <SelectedGateType, GateEducationalInfo>{
    SelectedGateType.x: GateEducationalInfo(
      type: SelectedGateType.x,
      name: 'Pauli-X gate',
      intuition:
          r'The quantum bit flip: it exchanges \(|0\rangle\) and \(|1\rangle\).',
      physicalChange:
          'Rotates a single qubit by π around the Bloch-sphere X axis.',
      commonUse:
          'Preparing basis states, reversible NOT logic, and conjugating phase operations.',
      transformations: [
        r'\(|0\rangle \rightarrow |1\rangle\)',
        r'\(|1\rangle \rightarrow |0\rangle\)'
      ],
      matrix: r'\[X=\begin{bmatrix}0&1\\1&0\end{bmatrix}\]',
      properties: ['Unitary', 'Hermitian', 'Self-inverse'],
      identities: [r'\(X^2=I\)', r'\(HXH=Z\)'],
      relatedConcepts: [
        GateRelatedConcept('Bit flip',
            notebookDiscoveryTitle: 'State Transformations'),
        GateRelatedConcept('Reversibility'),
        GateRelatedConcept('State preparation'),
      ],
      visual: GateEducationalVisual(
        kind: GateEducationalVisualKind.blochAxis,
        axisLabel: 'X',
        rotationRadians: 3.141592653589793,
        representativeTransition: '|0⟩ → |1⟩',
      ),
      axis: 'X axis',
      notebookDiscoveryTitle: 'State Transformations',
    ),
    SelectedGateType.y: GateEducationalInfo(
      type: SelectedGateType.y,
      name: 'Pauli-Y gate',
      intuition: 'Flips the basis state while adding an imaginary phase.',
      physicalChange:
          'Rotates a single qubit by π around the Bloch-sphere Y axis.',
      commonUse: 'Combined bit-and-phase changes and Y-axis rotations.',
      transformations: [
        r'\(|0\rangle \rightarrow i|1\rangle\)',
        r'\(|1\rangle \rightarrow -i|0\rangle\)'
      ],
      matrix: r'\[Y=\begin{bmatrix}0&-i\\i&0\end{bmatrix}\]',
      properties: ['Unitary', 'Hermitian', 'Self-inverse'],
      identities: [r'\(Y^2=I\)', r'\(Y=iXZ\)'],
      relatedConcepts: [
        GateRelatedConcept('Complex phase',
            notebookDiscoveryTitle: 'Phase Information'),
        GateRelatedConcept('Bloch sphere'),
        GateRelatedConcept('Pauli gates'),
      ],
      visual: GateEducationalVisual(
        kind: GateEducationalVisualKind.blochAxis,
        axisLabel: 'Y',
        rotationRadians: 3.141592653589793,
      ),
      axis: 'Y axis',
      notebookDiscoveryTitle: 'State Transformations',
    ),
    SelectedGateType.z: GateEducationalInfo(
      type: SelectedGateType.z,
      name: 'Pauli-Z gate',
      intuition:
          r'Leaves basis values in place and reverses the phase of \(|1\rangle\).',
      physicalChange:
          'Rotates a single qubit by π around the Bloch-sphere Z axis.',
      commonUse:
          'Phase marking, interference, and changing between X and Z behavior.',
      transformations: [
        r'\(|0\rangle \rightarrow |0\rangle\)',
        r'\(|1\rangle \rightarrow -|1\rangle\)'
      ],
      matrix: r'\[Z=\begin{bmatrix}1&0\\0&-1\end{bmatrix}\]',
      properties: ['Unitary', 'Hermitian', 'Self-inverse'],
      identities: [r'\(Z^2=I\)', r'\(HZH=X\)'],
      relatedConcepts: [
        GateRelatedConcept('Relative phase',
            notebookDiscoveryTitle: 'Relative Phase'),
        GateRelatedConcept('Interference'),
        GateRelatedConcept('Phase marking'),
      ],
      visual: GateEducationalVisual(
        kind: GateEducationalVisualKind.blochAxis,
        axisLabel: 'Z',
        rotationRadians: 3.141592653589793,
      ),
      axis: 'Z axis',
      notebookDiscoveryTitle: 'Relative Phase',
    ),
    SelectedGateType.hadamard: GateEducationalInfo(
      type: SelectedGateType.hadamard,
      name: 'Hadamard gate',
      intuition: 'Creates and recombines superposition, enabling interference.',
      physicalChange: 'Changes between the computational and diagonal bases.',
      commonUse:
          'Preparing |+⟩/|−⟩, interference, Bell states, and quantum algorithms.',
      transformations: [
        r'\(|0\rangle \rightarrow |+\rangle\)',
        r'\(|1\rangle \rightarrow |-\rangle\)'
      ],
      matrix: r'\[H=\frac{1}{\sqrt{2}}\begin{bmatrix}1&1\\1&-1\end{bmatrix}\]',
      properties: ['Unitary', 'Hermitian', 'Self-inverse'],
      identities: [r'\(H^2=I\)', r'\(HXH=Z\)', r'\(HZH=X\)'],
      relatedConcepts: [
        GateRelatedConcept('Superposition',
            notebookDiscoveryTitle: 'Superposition'),
        GateRelatedConcept('Interference'),
        GateRelatedConcept('Basis change'),
      ],
      visual:
          GateEducationalVisual(kind: GateEducationalVisualKind.superposition),
      notebookDiscoveryTitle: 'Superposition',
    ),
    SelectedGateType.s: GateEducationalInfo(
      type: SelectedGateType.s,
      name: 'S phase gate',
      intuition: r'Adds a quarter-turn phase to the \(|1\rangle\) amplitude.',
      physicalChange:
          r'Applies phase \(i\) to \(|1\rangle\) while leaving \(|0\rangle\) unchanged.',
      commonUse:
          'Clifford circuits, phase preparation, and interference control.',
      transformations: [
        r'\(|0\rangle \rightarrow |0\rangle\)',
        r'\(|1\rangle \rightarrow i|1\rangle\)'
      ],
      matrix: r'\[S=\begin{bmatrix}1&0\\0&i\end{bmatrix}\]',
      properties: ['Unitary', 'Phase gate', 'S† is its inverse'],
      identities: [
        r'\(S^2=Z\)',
        r'\(S^4=I\)',
        r'\(S^\dagger=S^3\)',
        r'\(S=e^{i\pi/4}R_z(\pi/2)\)'
      ],
      relatedConcepts: [
        GateRelatedConcept('Relative phase',
            notebookDiscoveryTitle: 'Relative Phase'),
        GateRelatedConcept('Clifford gates'),
        GateRelatedConcept('Interference'),
      ],
      visual: GateEducationalVisual(
        kind: GateEducationalVisualKind.blochAxis,
        axisLabel: 'Z',
        rotationRadians: 1.5707963267948966,
        representativeTransition: '|+⟩ → |+i⟩',
      ),
      axis: 'Z axis',
      notebookDiscoveryTitle: 'Phase Information',
    ),
    SelectedGateType.t: GateEducationalInfo(
      type: SelectedGateType.t,
      name: 'T phase gate',
      intuition: r'Adds an eighth-turn phase to \(|1\rangle\).',
      physicalChange: r'Applies phase \(e^{i\pi/4}\) to \(|1\rangle\).',
      commonUse:
          'Universal fault-tolerant circuits and precise phase construction.',
      transformations: [
        r'\(|0\rangle \rightarrow |0\rangle\)',
        r'\(|1\rangle \rightarrow e^{i\pi/4}|1\rangle\)'
      ],
      matrix: r'\[T=\begin{bmatrix}1&0\\0&e^{i\pi/4}\end{bmatrix}\]',
      properties: ['Unitary', 'Non-Clifford', 'T† is its inverse'],
      identities: [
        r'\(T^2=S\)',
        r'\(T^4=Z\)',
        r'\(T^\dagger=T^7\)',
        r'\(T=e^{i\pi/8}R_z(\pi/4)\)'
      ],
      relatedConcepts: [
        GateRelatedConcept('Phase',
            notebookDiscoveryTitle: 'Phase Information'),
        GateRelatedConcept('Universal gate sets'),
        GateRelatedConcept('Precision'),
      ],
      visual: GateEducationalVisual(
        kind: GateEducationalVisualKind.blochAxis,
        axisLabel: 'Z',
        rotationRadians: 0.7853981633974483,
        representativeTransition: '|+⟩ → equatorial phase π/4',
      ),
      axis: 'Z axis',
      notebookDiscoveryTitle: 'Phase Information',
    ),
    SelectedGateType.rx: GateEducationalInfo(
      type: SelectedGateType.rx,
      name: 'Rx rotation gate',
      intuition: 'Rotates a qubit continuously around the X axis.',
      physicalChange:
          'Mixes |0⟩ and |1⟩ with an angle-dependent imaginary phase.',
      commonUse:
          'Parameterized circuits, state preparation, and variational algorithms.',
      transformations: [r'\(R_x(\theta)=\cos(\theta/2)I-i\sin(\theta/2)X\)'],
      matrix:
          r'\[R_x(\theta)=\begin{bmatrix}\cos(\theta/2)&-i\sin(\theta/2)\\-i\sin(\theta/2)&\cos(\theta/2)\end{bmatrix}\]',
      properties: ['Unitary', 'Parameterized', 'Continuous rotation'],
      identities: [
        r'\(R_x(0)=I\)',
        r'\(R_x(\pi)=-iX\)',
        r'\(R_x(-\theta)=R_x(\theta)^\dagger\)'
      ],
      relatedConcepts: [
        GateRelatedConcept('Bloch sphere'),
        GateRelatedConcept('Parameterized gates',
            notebookDiscoveryTitle: 'Precise Superposition'),
        GateRelatedConcept('State preparation'),
      ],
      visual: GateEducationalVisual(
          kind: GateEducationalVisualKind.blochAxis, axisLabel: 'X'),
      axis: 'X',
      notebookDiscoveryTitle: 'Precise Superposition',
    ),
    SelectedGateType.ry: GateEducationalInfo(
      type: SelectedGateType.ry,
      name: 'Ry rotation gate',
      intuition: 'Rotates a qubit continuously around the Y axis.',
      physicalChange:
          'Changes real |0⟩ and |1⟩ amplitudes according to the angle.',
      commonUse:
          'Preparing arbitrary real superpositions and variational circuits.',
      transformations: [
        r'\(R_y(\theta)|0\rangle=\cos(\theta/2)|0\rangle+\sin(\theta/2)|1\rangle\)'
      ],
      matrix:
          r'\[R_y(\theta)=\begin{bmatrix}\cos(\theta/2)&-\sin(\theta/2)\\\sin(\theta/2)&\cos(\theta/2)\end{bmatrix}\]',
      properties: ['Unitary', 'Parameterized', 'Continuous rotation'],
      identities: [
        r'\(R_y(0)=I\)',
        r'\(R_y(\pi)=-iY\)',
        r'\(R_y(-\theta)=R_y(\theta)^\dagger\)'
      ],
      relatedConcepts: [
        GateRelatedConcept('Bloch sphere'),
        GateRelatedConcept('Superposition',
            notebookDiscoveryTitle: 'Superposition'),
        GateRelatedConcept('State preparation'),
      ],
      visual: GateEducationalVisual(
          kind: GateEducationalVisualKind.blochAxis, axisLabel: 'Y'),
      axis: 'Y',
      notebookDiscoveryTitle: 'Precise Superposition',
    ),
    SelectedGateType.rz: GateEducationalInfo(
      type: SelectedGateType.rz,
      name: 'Rz rotation gate',
      intuition:
          'Rotates around the Z axis, changing relative phase when both basis amplitudes are present.',
      physicalChange:
          r'Adds opposite angle-dependent phases to \(|0\rangle\) and \(|1\rangle\).',
      commonUse:
          'Phase encoding, parameterized circuits, and interference control.',
      transformations: [
        r'\(R_z(\theta)|0\rangle=e^{-i\theta/2}|0\rangle\)',
        r'\(R_z(\theta)|1\rangle=e^{i\theta/2}|1\rangle\)'
      ],
      matrix:
          r'\[R_z(\theta)=\begin{bmatrix}e^{-i\theta/2}&0\\0&e^{i\theta/2}\end{bmatrix}\]',
      properties: [
        'Unitary',
        'Parameterized',
        'Does not change basis probabilities'
      ],
      identities: [
        r'\(R_z(0)=I\)',
        r'\(R_z(\pi)=-iZ\)',
        r'\(R_z(-\theta)=R_z(\theta)^\dagger\)'
      ],
      relatedConcepts: [
        GateRelatedConcept('Relative phase',
            notebookDiscoveryTitle: 'Relative Phase'),
        GateRelatedConcept('Phase encoding',
            notebookDiscoveryTitle: 'Phase Information'),
        GateRelatedConcept('Interference'),
      ],
      visual: GateEducationalVisual(
          kind: GateEducationalVisualKind.blochAxis, axisLabel: 'Z'),
      axis: 'Z',
      notebookDiscoveryTitle: 'Phase Information',
    ),
    SelectedGateType.cnot: GateEducationalInfo(
      type: SelectedGateType.cnot,
      name: 'Controlled-X (CX / CNOT)',
      intuition: r'Flips the target exactly when the control is \(|1\rangle\).',
      physicalChange:
          'Performs target := target XOR control without changing the control.',
      commonUse:
          'Entanglement, reversible logic, information transfer, and error correction.',
      transformations: [r'\(|c,t\rangle \rightarrow |c,t\oplus c\rangle\)'],
      matrix:
          r'\[\mathrm{CX}=\begin{bmatrix}1&0&0&0\\0&1&0&0\\0&0&0&1\\0&0&1&0\end{bmatrix}\]',
      properties: ['Two-qubit', 'Self-inverse', 'Can create entanglement'],
      identities: [r'\(\mathrm{CX}^2=I\)'],
      relatedConcepts: [
        GateRelatedConcept('Control', notebookDiscoveryTitle: 'Control'),
        GateRelatedConcept('Entanglement',
            notebookDiscoveryTitle: 'Entanglement'),
        GateRelatedConcept('Reversible XOR'),
      ],
      visual:
          GateEducationalVisual(kind: GateEducationalVisualKind.controlledX),
      notebookDiscoveryTitle: 'Control',
    ),
    SelectedGateType.cz: GateEducationalInfo(
      type: SelectedGateType.cz,
      name: 'Controlled-Z (CZ)',
      intuition: r'Adds a minus sign only when both qubits are \(|1\rangle\).',
      physicalChange: r'Marks the \(|11\rangle\) component with phase \(-1\).',
      commonUse:
          'Entanglement, graph states, phase kickback, and oracle marking.',
      transformations: [
        r'\(|11\rangle \rightarrow -|11\rangle\); other basis states are unchanged'
      ],
      matrix: r'\[\mathrm{CZ}=\operatorname{diag}(1,1,1,-1)\]',
      properties: ['Two-qubit', 'Symmetric', 'Self-inverse'],
      identities: [
        r'\(\mathrm{CZ}^2=I\)',
        r'\(\mathrm{CZ}=(I\otimes H)\,\mathrm{CX}\,(I\otimes H)\)'
      ],
      relatedConcepts: [
        GateRelatedConcept('Conditional phase',
            notebookDiscoveryTitle: 'Phase Kickback'),
        GateRelatedConcept('Phase kickback',
            notebookDiscoveryTitle: 'Phase Kickback'),
        GateRelatedConcept('Entanglement',
            notebookDiscoveryTitle: 'Entanglement'),
      ],
      visual: GateEducationalVisual(
          kind: GateEducationalVisualKind.controlledPhase),
      notebookDiscoveryTitle: 'Phase Kickback',
    ),
    SelectedGateType.ccnot: GateEducationalInfo(
      type: SelectedGateType.ccnot,
      name: 'Toffoli (CCX / CCNOT)',
      intuition:
          r'Flips one target only when two controls are both \(|1\rangle\).',
      physicalChange: 'Performs target := target XOR (control₁ AND control₂).',
      commonUse:
          'Reversible classical logic, arithmetic, and multi-condition circuits.',
      transformations: [
        r'\(|a,b,t\rangle \rightarrow |a,b,t\oplus(a\cdot b)\rangle\)'
      ],
      matrix:
          r'\[\mathrm{CCX}:\quad |a,b,t\rangle\mapsto|a,b,t\oplus(a\cdot b)\rangle\]',
      properties: [
        'Three-qubit',
        'Self-inverse',
        'Universal for reversible classical logic'
      ],
      identities: [r'\(\mathrm{CCX}^2=I\)'],
      relatedConcepts: [
        GateRelatedConcept('Reversibility'),
        GateRelatedConcept('Quantum AND',
            notebookDiscoveryTitle: 'Information Flow'),
        GateRelatedConcept('Multi-qubit control',
            notebookDiscoveryTitle: 'Control'),
      ],
      visual: GateEducationalVisual(
          kind: GateEducationalVisualKind.multiControlledX),
      notebookDiscoveryTitle: 'Information Flow',
    ),
    // v2.6 M7. Local ordering |control, target⟩ (control written first) for
    // the matrix and basis actions; the register itself is |q(n−1)…q0⟩.
    SelectedGateType.cy: GateEducationalInfo(
      type: SelectedGateType.cy,
      name: 'Controlled-Y (CY)',
      intuition:
          r'Applies Pauli-Y to the target exactly in the components where the control is \(|1\rangle\).',
      physicalChange:
          r'Where the control is \(|1\rangle\), the target bit flips and gains a phase: \(|0\rangle\to i|1\rangle\), \(|1\rangle\to -i|0\rangle\). Unlike CX, it changes amplitude phases.',
      commonUse:
          'Controlled rotations and transformations, entangling gates with a built-in phase, and gate decompositions.',
      transformations: [
        r'\(|00\rangle \rightarrow |00\rangle\)',
        r'\(|01\rangle \rightarrow |01\rangle\)',
        r'\(|10\rangle \rightarrow i|11\rangle\)',
        r'\(|11\rangle \rightarrow -i|10\rangle\)',
      ],
      matrix:
          r'\[\mathrm{CY}=\begin{bmatrix}1&0&0&0\\0&1&0&0\\0&0&0&-i\\0&0&i&0\end{bmatrix}\]',
      properties: [
        'Two-qubit',
        'Self-inverse (CY² = I)',
        'Hermitian (CY† = CY)',
        'Can create entanglement',
        r'Matrix and basis actions use the local order \(|\mathrm{control},\mathrm{target}\rangle\)',
      ],
      identities: [
        r'\(\mathrm{CY}^2=I\)',
        r'\(\mathrm{CY}^\dagger=\mathrm{CY}\)',
        r'\(\mathrm{CY}=(I\otimes S)\,\mathrm{CX}\,(I\otimes S^\dagger)\)',
      ],
      relatedConcepts: [
        GateRelatedConcept('Conditional phase',
            notebookDiscoveryTitle: 'Conditional Phase'),
        GateRelatedConcept('Control', notebookDiscoveryTitle: 'Control'),
        GateRelatedConcept('Relative phase',
            notebookDiscoveryTitle: 'Relative Phase'),
        GateRelatedConcept('Entanglement',
            notebookDiscoveryTitle: 'Entanglement'),
      ],
      visual:
          GateEducationalVisual(kind: GateEducationalVisualKind.controlledY),
      notebookDiscoveryTitle: 'Control',
      keyIdeas: [
        r'CY is not just a controlled bit flip. CX swaps the target amplitudes; CY swaps them and multiplies them by \(i\) and \(-i\). On a single basis state that factor is unobservable, but in a superposition it becomes a relative phase.',
        r'From \(|00\rangle\), H on the control and then CY give \((|00\rangle + i|11\rangle)/\sqrt{2}\). Measured in the Z basis it gives 50% \(|00\rangle\) and 50% \(|11\rangle\), exactly like the CX Bell state \((|00\rangle+|11\rangle)/\sqrt{2}\). The two states differ only in the relative phase \(i\), which interference reveals (see the comparison experiment).',
        r'\(\mathrm{CY}=(I\otimes S)\,\mathrm{CX}\,(I\otimes S^\dagger)\): conjugating the target by S turns X into Y, since \(SXS^\dagger=Y\). Read right to left: \(S^\dagger\) acts first.',
        r'Basis order: the matrix uses the local order \(|\mathrm{control},\mathrm{target}\rangle\). Qubit Quest writes register kets as \(|q_{n-1}\ldots q_0\rangle\), so with control q0 and target q1 the register ket \(|q_1q_0\rangle=|01\rangle\) is the local \(|10\rangle\).',
        r'CY is Hermitian and unitary, so it is its own inverse: applying it twice restores any input.',
      ],
    ),
    SelectedGateType.mcx: GateEducationalInfo(
      type: SelectedGateType.mcx,
      name: 'Multi-controlled X (MCX)',
      intuition:
          r'Flips the target in exactly the basis components where every control is \(|1\rangle\).',
      physicalChange:
          r'Performs \(t := t\oplus(c_1\cdot c_2\cdots c_k)\) on each basis component, coherently. The controls are not measured and nothing classical is decided.',
      commonUse:
          'Reversible computation, multi-condition logic, and oracle construction (marking states that satisfy several conditions).',
      transformations: [
        r'\(|c_1\ldots c_k,t\rangle \rightarrow |c_1\ldots c_k,\;t\oplus(c_1 c_2\cdots c_k)\rangle\)',
        r'\(|c_1\ldots c_k,0\rangle \rightarrow |c_1\ldots c_k,\;c_1\cdots c_k\rangle\)',
      ],
      // The rule on the target (controls unchanged), not a 2ⁿ×2ⁿ matrix.
      matrix: r'\[t\;\mapsto\;t\oplus(c_1 c_2\cdots c_k)\]',
      properties: [
        'Three or more controls, one target',
        'Self-inverse (MCX² = I)',
        'Hermitian (MCX† = MCX)',
        'Permutes basis states: no phases, no measurement',
        'CX and CCX are the one- and two-control cases',
      ],
      identities: [
        r'\(\mathrm{MCX}^2=I\)',
        r'\(\mathrm{MCX}^\dagger=\mathrm{MCX}\)',
      ],
      relatedConcepts: [
        GateRelatedConcept('Multi-qubit control',
            notebookDiscoveryTitle: 'Control'),
        GateRelatedConcept('Multi-controlled logic',
            notebookDiscoveryTitle: 'Multi-Controlled Logic'),
        GateRelatedConcept('Coherent conditions',
            notebookDiscoveryTitle: 'Coherent Conditions'),
        GateRelatedConcept('Condition becomes phase',
            notebookDiscoveryTitle: 'Condition Becomes Phase'),
        GateRelatedConcept('Reusable phase oracle',
            notebookDiscoveryTitle: 'Reusable Phase Oracle'),
        GateRelatedConcept('Reversible logic',
            notebookDiscoveryTitle: 'Information Flow'),
      ],
      visual: GateEducationalVisual(
          kind: GateEducationalVisualKind.multiControlledX, controlCount: 3),
      notebookDiscoveryTitle: 'Information Flow',
      keyIdeas: [
        r'CX, CCX and MCX are one family: X on the target, conditioned on one, two, or three or more controls. Qubit Quest keeps CX and CCX as their own gates; MCX covers three and four controls in the five-qubit register.',
        r'The condition is checked per basis component, not by looking at the qubits. A control in superposition makes the flip happen in one component and not the other, producing a coherent (often entangled) superposition.',
        r'MCX is not a measurement and does not compute an irreversible classical AND: it never discards information. With the target prepared in \(|0\rangle\) it ends holding the AND of the controls in every component, and applying MCX again uncomputes it.',
        r'Because it permutes basis states, MCX is its own inverse \((\mathrm{MCX}^2=I)\) and is Hermitian. Its full matrix is 2ⁿ × 2ⁿ (16 × 16 for four qubits, 32 × 32 for five), so the conditional rule is the clearer description.',
        r'Oracles use multi-controlled gates to mark the inputs that satisfy several conditions at once, and reversible arithmetic uses them to compute without erasing.',
      ],
    ),
  };
}
