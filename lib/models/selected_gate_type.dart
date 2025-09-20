import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SelectedGateType {
  none,
  hadamard,
  cz,
  cnot,
  ccnot,
  s,
  t,
  x,
  y,
  z,
  rx,
  ry,
  rz,
  delete,
  draggedGate,
  // Add other gate types here
}

/// A typedef for the function that will generate a gate's label.
/// This improves type safety and readability for the label function field.
typedef GateLabelFunction = String Function();

/// The main class that represents a gate object in the circuit.
/// It holds the static type from the enum and any dynamic properties.
class Gate {
  final SelectedGateType type;
  final double angle;
  final Color color;
  final String label;

  Gate({required this.type, required this.color, required this.label, this.angle = 0.0});

  /// Factory constructor to create a gate instance from a SelectedGateType.
  /// This ensures that only valid gate types can be created via this factory.
  factory Gate.fromIdentifier(SelectedGateType type, {double angle = 0.0}) {
    Color gateColor;
    GateLabelFunction gateLabel;

    String _formatAngle(double angle) {
      const double pi = math.pi;
      const double tolerance = 1e-6;
      final double piMultiplied = angle / pi;

      if ((piMultiplied - piMultiplied.round()).abs() < tolerance) {
        final int n = piMultiplied.round();
        if (n == 0) return '0';
        if (n == 1) return '\u03c0';
        if (n == -1) return '-\u03c0';
        return '${n}\u03c0';
      }

      final double halfPiMultiplied = angle / (pi / 2);
      if ((halfPiMultiplied - halfPiMultiplied.round()).abs() < tolerance) {
        final int n = halfPiMultiplied.round();
        if (n == 1) return '\u03c0/2';
        if (n == -1) return '-\u03c0/2';
        return '${n}\u03c0/2';
      }

      return angle.toStringAsFixed(3);
    }

    switch (type) {
      case SelectedGateType.hadamard:
        gateColor = Colors.red;
        gateLabel = () => 'H';
        break;
      case SelectedGateType.x:
        gateColor = Colors.lightBlueAccent;
        gateLabel = () => 'X';
        break;
      case SelectedGateType.y:
        gateColor = Colors.lightBlueAccent;
        gateLabel = () => 'Y';
        break;
      case SelectedGateType.z:
        gateColor = Colors.lightBlueAccent;
        gateLabel = () => 'Z';
        break;
      case SelectedGateType.s:
        gateColor = Colors.blueAccent;
        gateLabel = () => 'S';
        break;
      case SelectedGateType.t:
        gateColor = Colors.blueAccent;
        gateLabel = () => 'T';
        break;
      case SelectedGateType.cz:
        gateColor = Colors.blue;
        gateLabel = () => 'CZ';
        break;
      case SelectedGateType.cnot:
        gateColor = Colors.blue;
        gateLabel = () => 'CX';
        break;
      case SelectedGateType.ccnot:
        gateColor = Colors.blue;
        gateLabel = () => 'CCX';
        break;
      case SelectedGateType.rx:
        gateColor = Colors.blue.shade600;
        gateLabel = () => 'Rx\n${_formatAngle(angle)}';
        break;
      case SelectedGateType.ry:
        gateColor = Colors.green.shade600;
        gateLabel = () => 'Ry\n${_formatAngle(angle)}';
        break;
      case SelectedGateType.rz:
        gateColor = Colors.purple.shade600;
        gateLabel = () => 'Rz\n${_formatAngle(angle)}';
        break;
      default:
        gateColor = Colors.transparent;
        gateLabel = () => '';
        break;
    }
    return Gate(type: type, color: gateColor, label: gateLabel(), angle: angle);
  }
}
