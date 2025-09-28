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
  final Color color;
  final String label;
  final double? angle;

  Gate({required this.type, required this.color, required this.label, this.angle});

  /// Factory constructor to create a gate instance from a SelectedGateType.
  /// This ensures that only valid gate types can be created via this factory.
  factory Gate.fromIdentifier(SelectedGateType type, {double? angle}) {
    Color gateColor;
    GateLabelFunction gateLabel;

    int _gcd(int a, int b) {
      a = a.abs();
      b = b.abs();
      while (b != 0) {
        final int t = b;
        b = a % b;
        a = t;
      }
      return a;
    }

    String _formatAngle(double angle) {
      if (angle == 0.0) {
        return '0';
      }

      // Use a small tolerance for floating point comparisons
      const double tolerance = 1e-5;

      // The sign is handled separately for cleaner fraction formatting
      final String sign = angle.isNegative ? '-' : '';
      final double absAngle = angle.abs();

      // Common denominators to check: 1, 2, 4, 8, 16
      const List<int> denominators = [1, 2, 3, 4, 5, 6, 7, 8, 9, 16];

      for (int d in denominators) {
        // Check if the angle is close to n * pi / d
        final double fractionUnit = math.pi / d;
        final double multiplier = absAngle / fractionUnit;

        // Check if the multiplier is very close to an integer (n)
        if ((multiplier - multiplier.round()).abs() < tolerance) {
          final int n = multiplier.round();

          if (n == 0) continue; // Skip zero angle, handled at the start

          // Simplify the fraction n/d
          final int gcd = _gcd(n, d);
          final int numerator = n ~/ gcd;
          final int denominator = d ~/ gcd;

          if (denominator == 1) {
            // e.g., 2*pi/2 -> 1*pi. 4*pi/2 -> 2*pi
            if (numerator == 1) return '${sign}\u03c0';
            return '$sign$numerator\u03c0';
          } else {
            // e.g., pi/2, 3*pi/4, 5*pi/8
            return '$sign$numerator/$denominator\u03c0';
          }
        }
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
        gateLabel = () => angle == null ? 'Rx' : 'Rx\n${_formatAngle(angle)}';
        break;
      case SelectedGateType.ry:
        gateColor = Colors.green.shade600;
        gateLabel = () => angle == null ? 'Ry' : 'Ry\n${_formatAngle(angle)}';
        break;
      case SelectedGateType.rz:
        gateColor = Colors.purple.shade600;
        gateLabel = () => angle == null ? 'Rz' : 'Rz\n${_formatAngle(angle)}';
        break;
      default:
        gateColor = Colors.transparent;
        gateLabel = () => '';
        break;
    }
    return Gate(type: type, color: gateColor, label: gateLabel(), angle: angle);
  }
}
