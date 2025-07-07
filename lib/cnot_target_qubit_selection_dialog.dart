import 'dart:math';

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

    // Calculate the actual number of columns to use, ensuring it doesn't exceed the number of available qubits
    final int crossAxisCount = min(numQubits - 1, availableTargetQubits.length);

    return AlertDialog(
      title: const Text('Select Target Qubit', style: const TextStyle(color: Colors.white)),
      content: SizedBox( // Use SizedBox to give the grid a defined height if needed, or let it size itself
        width: MediaQuery.of(context).size.width * 0.38, // Take 70% of screen width for content
        child: GridView.builder(
          shrinkWrap: true, // Important: Makes GridView take only necessary space
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling if content fits
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount == 0 ? 1 : crossAxisCount, // Ensure at least 1 column if no qubits (though handled by empty check)
            crossAxisSpacing: 8.0, // Horizontal space between buttons
            mainAxisSpacing: 8.0, // Vertical space between buttons
            childAspectRatio: 2.0, // Adjust this ratio for button shape (width / height)
          ),
          itemCount: availableTargetQubits.length,
          itemBuilder: (context, index) {
            final int qubitIndex = availableTargetQubits[index];
            return ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(qubitIndex); // Return selected qubit index
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent[700], // Button background color
                foregroundColor: Colors.white, // Text color for the button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                // padding: const EdgeInsets.symmetric(vertical: 10.0), // Adjust button internal padding
              ),
              child: Text(
                'q$qubitIndex',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            );
          },
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