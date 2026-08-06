import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:quantumquiz/models/circuit_editing.dart';

class CircuitLayoutMetrics {
  const CircuitLayoutMetrics._();

  static const double qubitSpacing = 40;
  static const double gateSpacing = 40;
  static const double gateSize = 30;
  static const double padding = 20;
  static const double hitTolerance = 20;
  static const double targetRadius = 12;
  static const double controlDotRadius = 4;
  static const double gateShadowYOffset = 3;
  static const double gateShadowBlurRadius = 8;
  static const double firstWireY = qubitSpacing / 2;
  static const double bottomExtent =
      gateSize / 2 + gateShadowYOffset + gateShadowBlurRadius;
  static const double topExtent = firstWireY;

  static double wireCenterY(int qubit) => qubit * qubitSpacing + firstWireY;

  static Offset slotCenter(CircuitLocation location) => Offset(
        padding + location.column * gateSpacing + gateSpacing / 2,
        wireCenterY(location.qubit),
      );

  static double wireSpan(int qubitCount) =>
      (math.max(1, qubitCount) - 1) * qubitSpacing;

  static double drawingHeight(int qubitCount) =>
      topExtent + wireSpan(qubitCount) + bottomExtent;

  static double contentWidthForDepth(int depth, {int trailingColumns = 3}) =>
      (math.max(0, depth) + trailingColumns) * gateSpacing + padding * 2;
}
