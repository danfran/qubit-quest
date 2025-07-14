import 'package:flutter/material.dart';

enum SelectedGateType {
  none,
  hadamard,
  cnot,
  s,
  t,
  x,
  y,
  z,
  delete,
  draggedGate,
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
      case SelectedGateType.s:
        return 'S';
      case SelectedGateType.t:
        return 'T';
      case SelectedGateType.x:
        return 'X';
      case SelectedGateType.y:
        return 'Y';
      case SelectedGateType.z:
        return 'Z';
      default:
        return '';
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
      case SelectedGateType.s:
        return Colors.blueAccent;
      case SelectedGateType.t:
        return Colors.blueAccent;
      case SelectedGateType.x:
        return Colors.lightBlueAccent;
      case SelectedGateType.y:
        return Colors.lightBlueAccent;
      case SelectedGateType.z:
        return Colors.lightBlueAccent;
      default:
        return Colors.black;
    }
  }
}