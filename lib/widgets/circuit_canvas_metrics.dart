import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';

class CircuitCanvasMetrics {
  final double height;
  final double drawingHeight;
  final double minimumInteractiveHeight;

  const CircuitCanvasMetrics({
    required this.height,
    required this.drawingHeight,
    required this.minimumInteractiveHeight,
  });

  static CircuitCanvasMetrics calculate({
    required int qubitCount,
    required Orientation orientation,
    required double availableHeight,
    EdgeInsets cardPadding = EdgeInsets.zero,
    double headerHeight = 0,
  }) {
    final double drawingHeight =
        QuantumCircuitPainter.requiredDrawingHeightFor(qubitCount);
    final double chromeHeight =
        cardPadding.vertical + math.max(0, headerHeight);
    final double contentHeight = drawingHeight + chromeHeight;
    final double minimumInteractiveHeight = contentHeight;

    if (orientation == Orientation.landscape) {
      return CircuitCanvasMetrics(
        height: _fitToAvailable(
          preferredHeight: math.max(contentHeight, minimumInteractiveHeight),
          availableHeight: availableHeight,
        ),
        drawingHeight: drawingHeight,
        minimumInteractiveHeight: minimumInteractiveHeight,
      );
    }

    final double heightCap = _finiteAvailableHeight(availableHeight) * 0.45;
    final double preferredHeight = math.min(
      contentHeight,
      math.max(minimumInteractiveHeight, heightCap),
    );

    return CircuitCanvasMetrics(
      height: _fitToAvailable(
        preferredHeight: preferredHeight,
        availableHeight: availableHeight,
      ),
      drawingHeight: drawingHeight,
      minimumInteractiveHeight: minimumInteractiveHeight,
    );
  }

  static double _fitToAvailable({
    required double preferredHeight,
    required double availableHeight,
  }) {
    final double finiteAvailableHeight =
        _finiteAvailableHeight(availableHeight);
    if (finiteAvailableHeight <= 0) {
      return preferredHeight;
    }
    return math.min(preferredHeight, finiteAvailableHeight);
  }

  static double _finiteAvailableHeight(double availableHeight) {
    return availableHeight.isFinite ? math.max(0, availableHeight) : 0;
  }
}

class WebCircuitWorkbenchMetrics {
  const WebCircuitWorkbenchMetrics({
    required this.canvasHeight,
    required this.circuitPaneHeight,
    required this.inspectorHeight,
    required this.mainRowHeight,
  });

  final double canvasHeight;
  final double circuitPaneHeight;
  final double inspectorHeight;
  final double mainRowHeight;

  static WebCircuitWorkbenchMetrics calculate({
    required int qubitCount,
    required bool hasTargetState,
  }) {
    final drawingHeight =
        QuantumCircuitPainter.requiredDrawingHeightFor(qubitCount);
    final double canvasHeight = math.max(88.0, drawingHeight + 8.0);
    final double circuitPaneHeight = canvasHeight + 200.0;
    final inspectorHeight =
        hasTargetState ? (qubitCount >= 3 ? 384.0 : 344.0) : 284.0;

    return WebCircuitWorkbenchMetrics(
      canvasHeight: canvasHeight,
      circuitPaneHeight: circuitPaneHeight,
      inspectorHeight: inspectorHeight,
      mainRowHeight: math.max(circuitPaneHeight, inspectorHeight),
    );
  }
}
