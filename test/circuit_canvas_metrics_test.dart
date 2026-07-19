import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/widgets/circuit_canvas_metrics.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';

void main() {
  group('CircuitCanvasMetrics', () {
    const compactPadding = EdgeInsets.fromLTRB(8, 6, 8, 6);

    test('uses compact portrait height for one-qubit circuits', () {
      final metrics = CircuitCanvasMetrics.calculate(
        qubitCount: 1,
        orientation: Orientation.portrait,
        availableHeight: 700,
        cardPadding: compactPadding,
      );

      expect(
        metrics.height,
        QuantumCircuitPainter.requiredDrawingHeightFor(1) +
            compactPadding.vertical,
      );
    });

    test('drawing height uses wire span without an extra qubit interval', () {
      expect(QuantumCircuitPainter.wireSpanFor(1), 0);
      expect(
        QuantumCircuitPainter.requiredDrawingHeightFor(1),
        QuantumCircuitPainter.topExtent + QuantumCircuitPainter.bottomExtent,
      );
      expect(
        QuantumCircuitPainter.requiredDrawingHeightFor(2),
        QuantumCircuitPainter.topExtent +
            QuantumCircuitPainter.qubitSpacing +
            QuantumCircuitPainter.bottomExtent,
      );
      expect(
        QuantumCircuitPainter.requiredDrawingHeightFor(3),
        QuantumCircuitPainter.topExtent +
            2 * QuantumCircuitPainter.qubitSpacing +
            QuantumCircuitPainter.bottomExtent,
      );
      expect(
        QuantumCircuitPainter.requiredDrawingHeightFor(5),
        QuantumCircuitPainter.topExtent +
            4 * QuantumCircuitPainter.qubitSpacing +
            QuantumCircuitPainter.bottomExtent,
      );
    });

    test('one-qubit canvas keeps top and bottom interaction extents', () {
      expect(QuantumCircuitPainter.firstWireY, QuantumCircuitPainter.topExtent);
      expect(
        QuantumCircuitPainter.requiredDrawingHeightFor(1) -
            QuantumCircuitPainter.lastWireYFor(1),
        QuantumCircuitPainter.bottomExtent,
      );
      expect(
        QuantumCircuitPainter.topExtent,
        greaterThanOrEqualTo(QuantumCircuitPainter.hitTolerance),
      );
      expect(
        QuantumCircuitPainter.bottomExtent,
        greaterThanOrEqualTo(QuantumCircuitPainter.hitTolerance),
      );
    });

    test('multi-qubit canvases contain the expected inter-wire spacing', () {
      expect(
        QuantumCircuitPainter.lastWireYFor(2) -
            QuantumCircuitPainter.firstWireY,
        QuantumCircuitPainter.qubitSpacing,
      );
      expect(
        QuantumCircuitPainter.lastWireYFor(3) -
            QuantumCircuitPainter.firstWireY,
        2 * QuantumCircuitPainter.qubitSpacing,
      );
      expect(
        QuantumCircuitPainter.lastWireYFor(5) -
            QuantumCircuitPainter.firstWireY,
        4 * QuantumCircuitPainter.qubitSpacing,
      );
    });

    test('five-qubit drawing height preserves controlled gate bounds', () {
      final requiredHeight = QuantumCircuitPainter.requiredDrawingHeightFor(5);
      final lastWireY = QuantumCircuitPainter.lastWireYFor(5);

      expect(QuantumCircuitPainter.firstWireY, greaterThanOrEqualTo(20));
      expect(
        requiredHeight - lastWireY,
        greaterThanOrEqualTo(
          QuantumCircuitPainter.targetRadius +
              1 +
              QuantumCircuitPainter.gateShadowYOffset +
              QuantumCircuitPainter.gateShadowBlurRadius,
        ),
      );
    });

    test('keeps two-qubit portrait circuits compact', () {
      final oneQubit = CircuitCanvasMetrics.calculate(
        qubitCount: 1,
        orientation: Orientation.portrait,
        availableHeight: 700,
        cardPadding: compactPadding,
      );
      final twoQubit = CircuitCanvasMetrics.calculate(
        qubitCount: 2,
        orientation: Orientation.portrait,
        availableHeight: 700,
        cardPadding: compactPadding,
      );

      expect(twoQubit.height, greaterThan(oneQubit.height));
      expect(twoQubit.height, lessThan(160));
    });

    test('preserves readable spacing for five-qubit circuits', () {
      final metrics = CircuitCanvasMetrics.calculate(
        qubitCount: 5,
        orientation: Orientation.portrait,
        availableHeight: 900,
        cardPadding: compactPadding,
      );

      expect(
        metrics.height,
        QuantumCircuitPainter.requiredDrawingHeightFor(5) +
            compactPadding.vertical,
      );
    });

    test('keeps five-qubit portrait circuits within short viewports', () {
      final metrics = CircuitCanvasMetrics.calculate(
        qubitCount: 5,
        orientation: Orientation.portrait,
        availableHeight: 540,
        cardPadding: compactPadding,
      );

      expect(metrics.height, lessThanOrEqualTo(540));
      expect(
        metrics.height - compactPadding.vertical,
        greaterThanOrEqualTo(
          QuantumCircuitPainter.requiredDrawingHeightFor(5),
        ),
      );
    });

    test('landscape circuits remain within available viewport', () {
      final metrics = CircuitCanvasMetrics.calculate(
        qubitCount: 5,
        orientation: Orientation.landscape,
        availableHeight: 540,
        cardPadding: compactPadding,
      );

      expect(metrics.height, lessThanOrEqualTo(540));
      expect(
        metrics.height,
        QuantumCircuitPainter.requiredDrawingHeightFor(5) +
            compactPadding.vertical,
      );
    });

    test('respects constrained viewport height', () {
      final metrics = CircuitCanvasMetrics.calculate(
        qubitCount: 5,
        orientation: Orientation.landscape,
        availableHeight: 180,
        cardPadding: compactPadding,
      );

      expect(metrics.height, 180);
    });

    test('landscape sizing uses height after composer page padding', () {
      const double outerSafeAreaHeight = 334;
      const double topPadding = 3;
      const double bottomPadding = 6;
      const double gatePaletteHeight = 76;
      const double circuitPaletteGap = 6;
      const double innerContentHeight =
          outerSafeAreaHeight - topPadding - bottomPadding;
      const double remainingCircuitHeight =
          innerContentHeight - gatePaletteHeight - circuitPaletteGap;

      final metrics = CircuitCanvasMetrics.calculate(
        qubitCount: 5,
        orientation: Orientation.landscape,
        availableHeight: remainingCircuitHeight,
        cardPadding: compactPadding,
      );
      final oldMetrics = CircuitCanvasMetrics.calculate(
        qubitCount: 5,
        orientation: Orientation.landscape,
        availableHeight:
            outerSafeAreaHeight - gatePaletteHeight - circuitPaletteGap,
        cardPadding: compactPadding,
      );
      const double oldDrawingHeight = 5 * QuantumCircuitPainter.qubitSpacing +
          QuantumCircuitPainter.padding * 2;
      final double oldCardHeight = oldDrawingHeight + compactPadding.vertical;

      expect(
        metrics.height + gatePaletteHeight + circuitPaletteGap,
        lessThanOrEqualTo(innerContentHeight),
      );

      final oldColumnHeight =
          oldCardHeight + gatePaletteHeight + circuitPaletteGap;
      expect(oldColumnHeight - innerContentHeight, 9);
      expect(oldMetrics.height, lessThan(oldCardHeight));
    });
  });
}
