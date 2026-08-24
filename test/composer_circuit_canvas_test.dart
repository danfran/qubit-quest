import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
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
    expect(
      tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
          .enableDesktopHorizontalScrolling,
      isFalse,
    );

    final surface = find.byKey(const ValueKey('circuit-interaction-surface'));
    await tester.tapAt(tester.getTopLeft(surface) + const Offset(40, 60));
    await tester.pump();

    expect(tapped?.id, id);
    expect(tapped?.location.qubit, 2);
    expect(tapped?.location.column, 0);
  });

  testWidgets('desktop affordance reaches and selects a far-right gate',
      (tester) async {
    final circuit = QuantumCircuit(
      currentLevel: ComposerLevel(
        taskDescription: 'Long desktop circuit',
        numQubits: 1,
        initialQubitsStateStr: '0',
        initialQubitsState: ComposerLevel.getZeroStateVector(1),
        availableGates: const [],
        solutionFinalVector: const [],
      ),
    );
    for (var column = 0; column < 14; column++) {
      circuit.insertSinglePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.x),
        column,
        0,
      );
    }
    PlacedGateRef? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 72,
            child: ComposerCircuitCanvas(
              circuit: circuit,
              selectedGateId: null,
              enableDesktopHorizontalScrolling: true,
              onGateTap: (gate) => tapped = gate,
              onDropRequested: (_) async {},
              onPlacedGateDragStarted: (_) {},
              onDeletePlacedGateRequested: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, isTrue);
    final scrollView = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('circuit-horizontal-scroll')),
    );
    expect(scrollView.controller!.position.maxScrollExtent, greaterThan(0));

    final surface = find.byKey(const ValueKey('circuit-interaction-surface'));
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: tester.getCenter(surface),
        scrollDelta: const Offset(0, 10000),
      ),
    );
    await tester.pump();
    expect(
      scrollView.controller!.offset,
      scrollView.controller!.position.maxScrollExtent,
    );

    final lastGate = circuit.logicalGates.last;
    final bounds = CircuitGeometry.logicalGateBounds(circuit, lastGate.id)!;
    final visiblePoint = tester.getTopLeft(surface) +
        Offset(
          bounds.center.dx - scrollView.controller!.offset,
          bounds.center.dy,
        );
    await tester.tapAt(visiblePoint);
    await tester.pump();

    expect(tapped?.id, lastGate.id);
  });
}
