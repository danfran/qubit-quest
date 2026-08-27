import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';

void main() {
  testWidgets('renders supplied gates in order with palette drag payloads',
      (tester) async {
    final gates = [
      Gate.fromIdentifier(SelectedGateType.x),
      Gate.fromIdentifier(SelectedGateType.hadamard),
      Gate.fromIdentifier(SelectedGateType.rz),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComposerGatePalette(
            gates: gates,
            onGateTap: (_) {},
            onInspectGate: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final tiles = tester
        .widgetList<QubitQuestGateTile>(find.byType(QubitQuestGateTile))
        .toList();
    expect(tiles.map((tile) => tile.gate.type), [
      SelectedGateType.x,
      SelectedGateType.hadamard,
      SelectedGateType.rz,
    ]);

    final draggables = tester
        .widgetList<Draggable<CircuitDragData>>(
          find.byType(Draggable<CircuitDragData>),
        )
        .toList();
    expect(draggables, hasLength(3));
    expect(draggables[1].data!.source, CircuitDragSource.palette);
    expect(draggables[1].data!.gate.type, SelectedGateType.hadamard);
  });

  testWidgets('forwards tap and long-press inspection intents', (tester) async {
    final gate = Gate.fromIdentifier(SelectedGateType.hadamard);
    Gate? tapped;
    Gate? inspected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComposerGatePalette(
            gates: [gate],
            onGateTap: (value) => tapped = value,
            onInspectGate: (value) => inspected = value,
          ),
        ),
      ),
    );

    final draggable = find.byType(Draggable<CircuitDragData>);
    await tester.tap(draggable);
    expect(tapped, same(gate));
    expect(inspected, isNull);

    await tester.longPress(draggable);
    expect(inspected, same(gate));
  });

  testWidgets('keeps horizontal scroll controls and stable keys',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: ComposerGatePalette(
              gates: List.generate(
                12,
                (_) => Gate.fromIdentifier(SelectedGateType.hadamard),
              ),
              onGateTap: (_) {},
              onInspectGate: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final left = find.byKey(const ValueKey('palette-scroll-left'));
    final right = find.byKey(const ValueKey('palette-scroll-right'));
    expect(
        find.byKey(const ValueKey('gate-palette-scrollbar')), findsOneWidget);
    expect(tester.widget<IconButton>(left).onPressed, isNull);
    expect(tester.widget<IconButton>(right).onPressed, isNotNull);

    await tester.tap(right);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(left).onPressed, isNotNull);
  });
}
