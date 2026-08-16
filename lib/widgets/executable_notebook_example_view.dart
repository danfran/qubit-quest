import 'package:flutter/material.dart';
import 'package:quantumquiz/models/canonical_composer_solution.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

class ExecutableNotebookExampleView extends StatefulWidget {
  const ExecutableNotebookExampleView({
    super.key,
    required this.example,
    this.onOpenInComposer,
    this.onOpenInBlochExplorer,
  });

  final ExecutableNotebookExample example;
  final ValueChanged<ExecutableNotebookExample>? onOpenInComposer;
  final void Function(
    ExecutableNotebookExample example,
    ExecutableNotebookResult result,
  )? onOpenInBlochExplorer;

  @override
  State<ExecutableNotebookExampleView> createState() =>
      _ExecutableNotebookExampleViewState();
}

class _ExecutableNotebookExampleViewState
    extends State<ExecutableNotebookExampleView> {
  ExecutableNotebookResult? _result;
  Object? _error;

  void _run() {
    try {
      final result = widget.example.execute();
      setState(() {
        _result = result;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _result = null;
        _error = error;
      });
    }
  }

  void _reset() => setState(() {
        _result = null;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final example = widget.example;
    return Container(
      key: ValueKey('executable-example-${example.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(example.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(example.description,
              style: const TextStyle(color: QubitQuestDialog.mutedText)),
          const SizedBox(height: 10),
          Text(
            'Start |${example.initialBinaryState}⟩',
            style: const TextStyle(
              color: QubitQuestDialog.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          CompactCircuitPreview(example: example),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              key: ValueKey('run-example-${example.id}'),
              onPressed: _run,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Run'),
            ),
            OutlinedButton.icon(
              key: ValueKey('reset-example-${example.id}'),
              onPressed: _result == null && _error == null ? null : _reset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset'),
            ),
            if (example.allowOpenInComposer && widget.onOpenInComposer != null)
              OutlinedButton.icon(
                key: ValueKey('composer-example-${example.id}'),
                onPressed: () => widget.onOpenInComposer!(example),
                icon: const Icon(Icons.schema_rounded, size: 18),
                label: const Text('Open in Composer'),
              ),
            if (_result != null &&
                example.allowOpenInBlochExplorer &&
                widget.onOpenInBlochExplorer != null)
              OutlinedButton.icon(
                key: ValueKey('bloch-example-${example.id}'),
                onPressed: () =>
                    widget.onOpenInBlochExplorer!(example, _result!),
                icon: const Icon(Icons.public_rounded, size: 18),
                label: const Text('Explore in Bloch'),
              ),
          ]),
          if (_result != null) ...[
            const SizedBox(height: 10),
            Text(
              formatQuantumStateExpression(
                _result!.state,
                numQubits: example.qubitCount,
              ),
              key: ValueKey('result-example-${example.id}'),
              style: const TextStyle(
                  color: QubitQuestDialog.cyan, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final (index, amplitude) in _result!.state.indexed)
                  if (amplitude.magnitude > 1e-9)
                    Text(
                      'P(|${index.toRadixString(2).padLeft(example.qubitCount, '0')}⟩) '
                      '= ${(amplitude.magnitude * amplitude.magnitude * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Color(0xFFD6E3F8)),
                    ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            const Text(
              'This example could not run. The authored circuit remains shown above.',
              key: ValueKey('executable-example-error'),
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ],
        ],
      ),
    );
  }
}

/// A display-only circuit sequence built from the shared production gate tile.
class CompactCircuitPreview extends StatelessWidget {
  const CompactCircuitPreview({super.key, required this.example});

  final ExecutableNotebookExample example;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 7,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (index, step) in example.operations.indexed) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QubitQuestGateTile(
                  key: ValueKey('example-${example.id}-step-$index'),
                  gate: Gate.fromIdentifier(step.gateType, angle: step.angle),
                  onPressed: null,
                  size: 38,
                ),
                const SizedBox(height: 2),
                Text(
                  _location(step),
                  style: const TextStyle(
                    color: QubitQuestDialog.mutedText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (index + 1 < example.operations.length)
              const Icon(Icons.arrow_forward_rounded,
                  size: 15, color: QubitQuestDialog.mutedText),
          ],
        ],
      );

  static String _location(CanonicalCircuitStep step) {
    if (step.secondControlQubit case final second?) {
      return 'Q${step.controlQubit}, Q$second → Q${step.targetQubit}';
    }
    if (step.controlQubit case final control?) {
      return 'Q$control → Q${step.targetQubit}';
    }
    return 'Q${step.targetQubit}';
  }
}
