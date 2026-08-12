import 'package:flutter/material.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/gate_visual_style.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

class GateReplacementDialog extends StatelessWidget {
  const GateReplacementDialog({
    super.key,
    required this.gateTypes,
  });

  final List<SelectedGateType> gateTypes;

  @override
  Widget build(BuildContext context) {
    return QubitQuestDialog(
      title: 'Replace gate',
      maxWidth: 440,
      actions: [
        QubitQuestDialogButton.secondary(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: gateTypes.map((type) {
          final gate = Gate.fromIdentifier(type);
          final style = QubitQuestGateStyle.forGate(gate);
          return Semantics(
            button: true,
            label: 'Replace with ${gate.label}',
            child: InkWell(
              key: ValueKey('replacement-gate-${type.name}'),
              onTap: () => Navigator.of(context).pop(type),
              borderRadius: BorderRadius.circular(
                QubitQuestGateStyle.buttonRadius,
              ),
              child: Container(
                width: 64,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    QubitQuestGateStyle.buttonRadius,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: style.colors,
                  ),
                  border: Border.all(
                    color: QubitQuestGateStyle.border,
                    width: QubitQuestGateStyle.borderWidth,
                  ),
                ),
                child: Text(
                  gate.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
