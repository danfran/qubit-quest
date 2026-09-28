import 'package:flutter/material.dart';
import 'package:quantumquiz/models/quantum_measurement_result.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

/// Classical observed frequencies, deliberately separate from ideal inspection.
class MeasurementResultsView extends StatelessWidget {
  const MeasurementResultsView({super.key, required this.result});

  final QuantumMeasurementResult result;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('RESULTS', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('${result.shots} shots · Z basis',
              style: QubitQuestTypography.supporting),
          const SizedBox(height: 6),
          Text(
            'Bit order: ${List.generate(result.numQubits, (index) => 'q${result.numQubits - 1 - index}').join(' ')}',
            style: QubitQuestTypography.supporting,
          ),
          const SizedBox(height: 6),
          const Text(
            'Inspector shows the ideal quantum state. '
            'Results show finite-shot measurement observations.',
            style: QubitQuestTypography.supporting,
          ),
          const SizedBox(height: 14),
          for (final entry in result.counts.entries) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 4,
              children: [
                Text(entry.key,
                    style: const TextStyle(fontFamily: 'monospace')),
                Text('${entry.value}/${result.shots} · '
                    '${(100 * entry.value / result.shots).toStringAsFixed(1)}% observed'),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: entry.value / result.shots,
              minHeight: 8,
              color: QubitQuestColors.accentInteractive,
              backgroundColor: QubitQuestColors.surface,
            ),
            const SizedBox(height: 14),
          ],
          const Text('Outcomes not listed were not observed in this run.',
              style: QubitQuestTypography.supporting),
        ],
      );
}
