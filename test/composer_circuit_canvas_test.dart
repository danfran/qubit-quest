import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';

void main() {
  QuantumCircuit circuitWithControlledGate() {
    final circuit = QuantumCircuit(
      currentLevel: ComposerLevel(
        taskDescription: 'Canvas component test',
        numQubits: 3,
        initialQubitsStateStr: '000',
        initialQubitsState: ComposerLevel.getZeroStateVector(3),
        availableGates: const [],
        solutionFinalVector: const [],
      ),
    );
    circuit.insertDoublePlacedGateAt(
      Gate.fromIdentifier(SelectedGateType.cnot),
      0,
      2,
      0,
    );
    return circuit;
  }

  testWidgets('renders and reports one logical controlled gate independently',
      (tester) async {
    final circuit = circuitWithControlledGate();
    final id = circuit.logicalGates.single.id;
    PlacedGateRef? tapped;
    final dragStarts = <PlacedGateRef>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 122,
            child: ComposerCircuitCanvas(
              circuit: circuit,
              selectedGateId: null,
              onGateTap: (gate) => tapped = gate,
              onDropRequested: (_) async {},
              onPlacedGateDragStarted: dragStarts.add,
              onDeletePlacedGateRequested: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(ValueKey('placed-gate-drag-${id.value}')),
      findsOneWidget,
    );

    final surface = find.byKey(const ValueKey('circuit-interaction-surface'));
    await tester.tapAt(tester.getTopLeft(surface) + const Offset(40, 60));
    await tester.pump();

    expect(tapped?.id, id);
    expect(tapped?.location.qubit, 2);
    expect(tapped?.location.column, 0);
  });
}
