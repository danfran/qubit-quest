import 'package:flutter/material.dart';

enum SelectedGateType {
  none,
  hadamard,
  cnot,
  x,
  y,
  z,
  delete,
  // Add other gate types here
}

extension GateVisualProperties on SelectedGateType {
  String get label {
    switch (this) {
      case SelectedGateType.hadamard:
        return 'H';
      case SelectedGateType.cnot:
        return 'CNOT';
      case SelectedGateType.delete:
        return 'Del'; // Not typically placed visually
      case SelectedGateType.none:
        return ''; // Not typically placed visually
      case SelectedGateType.x:
        return 'X';
      case SelectedGateType.y:
        return 'Y';
      case SelectedGateType.z:
        return 'Z';
    }
  }

  Color get color {
    switch (this) {
      case SelectedGateType.hadamard:
        return Colors.red;
      case SelectedGateType.cnot:
        return Colors.blue;
      case SelectedGateType.delete:
        return Colors.green; // Not typically placed visually
      case SelectedGateType.none:
        return Colors.black; // Not typically placed visually
      case SelectedGateType.x:
        return Colors.lightBlueAccent;
      case SelectedGateType.y:
        return Colors.lightBlueAccent;
      case SelectedGateType.z:
        return Colors.lightBlueAccent;
    }
  }
}