import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/controlled_gate_placement_dialog.dart';
import 'package:quantumquiz/screens/three_qubits_gate_target_qubits_selection_dialog.dart';
import 'package:quantumquiz/screens/two_qubits_gate_target_qubit_selection_dialog.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

void main() {
  test('controlled role validation rejects duplicate and out-of-range roles',
      () {
    expect(
      const ControlledGatePlacement(targetQubit: 1, controlQubit: 1)
          .isValidFor(gateType: SelectedGateType.cnot, numQubits: 3),
      isFalse,
    );
    expect(
      const ControlledGatePlacement(
        targetQubit: 2,
        controlQubit: 0,
        secondControlQubit: 0,
      ).isValidFor(gateType: SelectedGateType.ccnot, numQubits: 3),
      isFalse,
    );
    expect(
      const ControlledGatePlacement(
        targetQubit: 2,
        controlQubit: 0,
        secondControlQubit: 1,
      ).isValidFor(gateType: SelectedGateType.ccnot, numQubits: 3),
      isTrue,
    );
  });

  testWidgets('CX and CZ use the production one-control role picker',
      (tester) async {
    for (final gateType in [SelectedGateType.cnot, SelectedGateType.cz]) {
      ControlledGatePlacement? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                selected = await showControlledGatePlacementDialog(
                  context,
                  gateType: gateType,
                  targetQubit: 2,
                  numQubits: 3,
                );
              },
              child: const Text('Place'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Place'));
      await tester.pumpAndSettle();
      expect(
        find.byType(TwoQubitsGateTargetQubitSelectionDialog),
        findsOneWidget,
      );
      expect(
        tester
            .widget<QubitQuestQubitButton>(
              find.widgetWithText(QubitQuestQubitButton, 'q2'),
            )
            .disabled,
        isTrue,
      );
      await tester.tap(find.widgetWithText(QubitQuestQubitButton, 'q0'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(selected?.targetQubit, 2);
      expect(selected?.controlQubit, 0);
      expect(
        selected!.isValidFor(gateType: gateType, numQubits: 3),
        isTrue,
      );
    }
  });

  testWidgets('CCX requires two distinct controls and one fixed target',
      (tester) async {
    ControlledGatePlacement? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              selected = await showControlledGatePlacementDialog(
                context,
                gateType: SelectedGateType.ccnot,
                targetQubit: 2,
                numQubits: 3,
              );
            },
            child: const Text('Place'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Place'));
    await tester.pumpAndSettle();
    expect(
      find.byType(ThreeQubitsGateTargetQubitsSelectionDialog),
      findsOneWidget,
    );
    expect(
      tester
          .widget<QubitQuestDialogButton>(
            find.widgetWithText(QubitQuestDialogButton, 'Apply'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.widgetWithText(QubitQuestQubitButton, 'q0').first,
    );
    await tester.pump();
    expect(
      tester
          .widget<QubitQuestQubitButton>(
            find.widgetWithText(QubitQuestQubitButton, 'q0').last,
          )
          .disabled,
      isTrue,
    );
    await tester.tap(
      find.widgetWithText(QubitQuestQubitButton, 'q1').last,
    );
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(selected?.targetQubit, 2);
    expect(selected?.controlQubit, 0);
    expect(selected?.secondControlQubit, 1);
  });
}
