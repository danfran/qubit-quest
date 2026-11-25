import 'package:flutter/material.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/circuit_preview.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';

/// A small, scientifically specific circuit for a Journey chapter, drawn with
/// the Composer's own read-only painter, and a caption describing exactly
/// what that circuit does (each caption is checked against the simulator in
/// `test/journey_curriculum_test.dart`).
///
/// Chapters without a single representative circuit (Grover loops, algorithm
/// structure, search stopping) have none: their detail stays text-first
/// rather than showing an unrelated diagram.
@immutable
class JourneyIllustrationSpec {
  const JourneyIllustrationSpec({
    required this.qubits,
    required this.build,
    required this.caption,
    this.initial,
  });

  final int qubits;

  /// Initial computational basis state, written q(n−1)…q0 like lesson
  /// definitions; all zeros when null.
  final String? initial;
  final void Function(QuantumCircuit circuit) build;
  final String caption;

  /// A fresh circuit (the caller owns and disposes it).
  QuantumCircuit createCircuit() {
    final circuit = QuantumCircuit(
      currentLevel: ComposerLevel.fromBinaryString(
        taskDescription: 'Journey illustration',
        initialQubitsStateString: initial ?? '0' * qubits,
        availableGates: const [],
        solutionFinalVector: const [],
      ),
    );
    build(circuit);
    return circuit;
  }
}

Gate _g(SelectedGateType type) => Gate.fromIdentifier(type);
const _h = SelectedGateType.hadamard;
const _x = SelectedGateType.x;
const _z = SelectedGateType.z;
const _cx = SelectedGateType.cnot;
const _cz = SelectedGateType.cz;

/// Illustrations by chapter number (1-based).
final Map<int, JourneyIllustrationSpec> journeyChapterIllustrations = {
  // v2.6 M6a: no preview is the complete solution of any Journey lesson
  // (checked in test/journey_curriculum_test.dart). Concepts are shown on a
  // different input or with a different circuit than the lessons ask for.
  // Chapter 1 has no circuit: every chapter-1 lesson offers only X, so any
  // X circuit would be a lesson's answer. Its detail stays text-first.
  2: JourneyIllustrationSpec(
    qubits: 1,
    build: (c) => c
      ..insertSingleGateWithOutcome(_g(_h), 0, 0)
      ..insertSingleGateWithOutcome(_g(_z), 1, 0),
    caption: 'After H, Z flips the sign of the |1⟩ amplitude: '
        '(|0⟩ − |1⟩)/√2. Measurement probabilities stay 50/50, so the change '
        'is hidden.',
  ),
  3: JourneyIllustrationSpec(
    qubits: 2,
    build: (c) => c.insertSingleGateWithOutcome(_g(_h), 0, 1),
    caption: 'H puts q1 alone in an equal superposition: (|00⟩ + |10⟩)/√2, '
        'while q0 stays |0⟩.',
  ),
  4: JourneyIllustrationSpec(
    qubits: 1,
    build: (c) => c
      ..insertSingleGateWithOutcome(_g(_h), 0, 0)
      ..insertSingleGateWithOutcome(_g(_h), 1, 0),
    caption: 'H twice returns |0⟩ with certainty: the two paths to |1⟩ carry '
        'opposite signs and cancel.',
  ),
  5: JourneyIllustrationSpec(
    qubits: 2,
    build: (c) => c
      ..insertSingleGateWithOutcome(_g(_h), 0, 0)
      ..insertDoubleGateWithOutcome(_g(_cx), 1, 1, 0)
      ..insertSingleGateWithOutcome(_g(_x), 2, 1),
    caption: 'H and CX entangle the pair, then X flips q1: (|01⟩ + |10⟩)/√2. '
        'Measured in the Z basis, the two qubits always give opposite '
        'results; neither qubit has a state of its own.',
  ),
  6: JourneyIllustrationSpec(
    qubits: 3,
    build: (c) => c
      ..insertSingleGateWithOutcome(_g(_x), 0, 0)
      ..insertDoubleGateWithOutcome(_g(_cx), 1, 1, 0)
      ..insertDoubleGateWithOutcome(_g(_cx), 2, 2, 1),
    caption: 'Information flows along a chain: X sets q0, then each CX passes '
        'that basis value to the next qubit, giving |111⟩. (CX copies basis '
        'values, not arbitrary quantum states.)',
  ),
  7: JourneyIllustrationSpec(
    qubits: 3,
    build: (c) => c
      ..insertSingleGateWithOutcome(_g(_h), 0, 2)
      ..insertDoubleGateWithOutcome(_g(_cx), 1, 1, 2)
      ..insertDoubleGateWithOutcome(_g(_cx), 2, 0, 2),
    caption: 'H on q2 and two CX gates spread one superposition over three '
        'qubits: the GHZ state (|000⟩ + |111⟩)/√2. It is a coherent '
        'superposition, not a 50/50 mix of 000 and 111.',
  ),
  8: JourneyIllustrationSpec(
    qubits: 2,
    build: (c) => c
      ..insertSingleGateWithOutcome(_g(_x), 0, 1)
      ..insertSingleGateWithOutcome(_g(_h), 0, 0)
      ..insertSingleGateWithOutcome(_g(_h), 1, 1)
      ..insertDoubleGateWithOutcome(_g(_cx), 2, 1, 0)
      ..insertSingleGateWithOutcome(_g(_h), 3, 0),
    caption: 'The target q1 is prepared in |−⟩. CX kicks its phase back onto '
        'the control, and the final H reveals it: q0 reads 1 with certainty.',
  ),
  9: JourneyIllustrationSpec(
    qubits: 2,
    build: (c) => c
      ..insertSingleGateWithOutcome(_g(_h), 0, 0)
      ..insertSingleGateWithOutcome(_g(_h), 0, 1)
      ..insertDoubleGateWithOutcome(_g(_cz), 1, 1, 0),
    caption: 'A phase oracle: CZ marks |11⟩ with a minus sign. Every outcome '
        'stays at 25%; the mark lives in the phase.',
  ),
  10: JourneyIllustrationSpec(
    qubits: 2,
    build: (c) {
      for (final q in [0, 1]) {
        c.insertSingleGateWithOutcome(_g(_h), 0, q);
      }
      c.insertDoubleGateWithOutcome(_g(_cz), 1, 1, 0);
      for (final (column, gate) in [(2, _h), (3, _x)]) {
        for (final q in [0, 1]) {
          c.insertSingleGateWithOutcome(_g(gate), column, q);
        }
      }
      c.insertDoubleGateWithOutcome(_g(_cz), 4, 1, 0);
      for (final (column, gate) in [(5, _x), (6, _h)]) {
        for (final q in [0, 1]) {
          c.insertSingleGateWithOutcome(_g(gate), column, q);
        }
      }
    },
    caption: 'One oracle-and-reflection round on two qubits: the marked '
        '|11⟩ is amplified until it is measured with certainty.',
  ),
};

/// The chapter's illustration with its caption, or nothing.
class JourneyChapterIllustration extends StatefulWidget {
  const JourneyChapterIllustration({super.key, required this.chapterNumber});
  final int chapterNumber;

  @override
  State<JourneyChapterIllustration> createState() =>
      _JourneyChapterIllustrationState();
}

class _JourneyChapterIllustrationState
    extends State<JourneyChapterIllustration> {
  QuantumCircuit? _circuit;

  @override
  void initState() {
    super.initState();
    _circuit =
        journeyChapterIllustrations[widget.chapterNumber]?.createCircuit();
  }

  @override
  void didUpdateWidget(covariant JourneyChapterIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterNumber != widget.chapterNumber) {
      _circuit?.dispose();
      _circuit =
          journeyChapterIllustrations[widget.chapterNumber]?.createCircuit();
    }
  }

  @override
  void dispose() {
    _circuit?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circuit = _circuit;
    final spec = journeyChapterIllustrations[widget.chapterNumber];
    if (circuit == null || spec == null) return const SizedBox.shrink();
    // A compact card sized to the circuit, with the circuit drawn 1.3× so
    // gates and qubit labels read at desktop distance.
    final height =
        QuantumCircuitPainter.requiredDrawingHeightFor(spec.qubits) * 1.3;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          key: ValueKey('journey-illustration-${widget.chapterNumber}'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: QubitQuestColors.surfaceInset,
            borderRadius: QubitQuestRadii.card,
            border: Border.all(color: QubitQuestColors.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: height,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  child: QubitQuestCircuitPreview(
                    circuit: circuit,
                    minimumWidth: 160,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                keepKetsTogether(spec.caption),
                key: ValueKey(
                    'journey-illustration-caption-${widget.chapterNumber}'),
                style: QubitQuestTypography.supporting
                    .copyWith(color: QubitQuestColors.textBody),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Joins each ket's characters with word joiners (U+2060) so a line never
/// breaks inside |…⟩, e.g. between "(|" and "000⟩".
String keepKetsTogether(String text) => text.replaceAllMapped(
      RegExp(r'\|([^|⟩\s]+)⟩'),
      (m) => '\u2060|\u2060${m[1]!.split('').join('\u2060')}\u2060⟩',
    );
