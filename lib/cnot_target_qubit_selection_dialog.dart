import 'package:flutter/material.dart';

class CNOTTargetQubitSelectionDialog extends StatelessWidget {
  final int controlQubitIndex;
  final int numQubits;

  const CNOTTargetQubitSelectionDialog({
    super.key,
    required this.controlQubitIndex,
    required this.numQubits,
  });

  @override
  Widget build(BuildContext context) {
    List<int> availableTargetQubits = List.generate(numQubits, (i) => i)
        .where((i) => i != controlQubitIndex)
        .toList();

    return AlertDialog(
      title: const Text('Select Target Qubit', style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: ListBody(
          children: availableTargetQubits.map((qubitIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(qubitIndex); // Return selected qubit index
                },
                child: Text('Qubit $qubitIndex', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () {
            Navigator.of(context).pop(null); // Return null on cancel
          },
        ),
      ],
    );
  }
}