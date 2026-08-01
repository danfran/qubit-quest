import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';

void main() {
  group('drag-to-delete bounds', () {
    for (final bounds in <Rect>[
      const Rect.fromLTWH(20, 80, 360, 240),
      const Rect.fromLTWH(100, 30, 900, 160),
    ]) {
      test('uses the same safety margin for ${bounds.width}x${bounds.height}',
          () {
        expect(
          CircuitGeometry.isClearlyOutsideCircuitForDeletion(
            circuitBounds: bounds,
            pointerPosition: bounds.center,
          ),
          isFalse,
        );
        expect(
          CircuitGeometry.isClearlyOutsideCircuitForDeletion(
            circuitBounds: bounds,
            pointerPosition: Offset(bounds.left - 6, bounds.center.dy),
          ),
          isFalse,
        );
        expect(
          CircuitGeometry.isClearlyOutsideCircuitForDeletion(
            circuitBounds: bounds,
            pointerPosition: Offset(bounds.left - 13, bounds.center.dy),
          ),
          isTrue,
        );
      });
    }
  });
}
