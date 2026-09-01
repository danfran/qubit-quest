import 'package:flutter/material.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/circuit_layout_metrics.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';

/// Read-only circuit presentation using the same painter and geometry as the
/// Qubit Quest Composer and Circuit Reading workspaces.
class QubitQuestCircuitPreview extends StatelessWidget {
  const QubitQuestCircuitPreview({
    super.key,
    required this.circuit,
    this.missingGateColumn,
    this.missingGateQubit = 0,
    this.minimumWidth = 260,
    this.showInitialStateValues = true,
    this.centerWhenFitted = false,
  });

  final QuantumCircuit circuit;
  final int? missingGateColumn;
  final int missingGateQubit;
  final double minimumWidth;
  final bool showInitialStateValues;
  final bool centerWhenFitted;

  @override
  Widget build(BuildContext context) {
    final depth = missingGateColumn == null
        ? circuit.maxCircuitDepth()
        : missingGateColumn! + 1;
    final contentWidth = CircuitLayoutMetrics.contentWidthForDepth(
      depth,
      trailingColumns: 1,
    );
    final height = QuantumCircuitPainter.requiredDrawingHeightFor(
      circuit.currentLevel.numQubits,
    );

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              contentWidth < minimumWidth ? minimumWidth : contentWidth;
          final circuitCanvas = SizedBox(
            key: const ValueKey('circuit-preview-canvas'),
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: QuantumCircuitPainter(
                      circuit,
                      showInitialStateValues: showInitialStateValues,
                    ),
                  ),
                ),
                if (missingGateColumn case final column?)
                  Positioned(
                    left: CircuitLayoutMetrics.padding +
                        column * CircuitLayoutMetrics.gateSpacing +
                        (CircuitLayoutMetrics.gateSpacing -
                                CircuitLayoutMetrics.gateSize) /
                            2,
                    top: CircuitLayoutMetrics.wireCenterY(missingGateQubit) -
                        CircuitLayoutMetrics.gateSize / 2,
                    child: const QubitQuestMissingGateSlot(),
                  ),
              ],
            ),
          );

          if (centerWhenFitted &&
              constraints.maxWidth.isFinite &&
              width <= constraints.maxWidth) {
            return Center(
              key: const ValueKey('centered-circuit-preview'),
              child: circuitCanvas,
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: circuitCanvas,
          );
        },
      ),
    );
  }
}

/// Neutral placeholder for an unknown circuit operation.
class QubitQuestMissingGateSlot extends StatelessWidget {
  const QubitQuestMissingGateSlot({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Missing gate',
        image: true,
        child: ExcludeSemantics(
          child: Container(
            key: const ValueKey('missing-gate-slot'),
            width: CircuitLayoutMetrics.gateSize,
            height: CircuitLayoutMetrics.gateSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: QubitQuestColors.surfaceInsetRaised,
              borderRadius: QubitQuestRadii.control,
              border: Border.all(
                color: QubitQuestColors.borderFocus,
                width: 1.5,
              ),
            ),
            child: Text(
              '?',
              style: QubitQuestTypography.heading.copyWith(
                color: QubitQuestColors.textBody,
              ),
            ),
          ),
        ),
      );
}
