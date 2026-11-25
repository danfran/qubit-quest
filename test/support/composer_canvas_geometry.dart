import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/widgets/circuit_layout_metrics.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';

/// Maps a logical circuit content point ([CircuitLayoutMetrics]
/// coordinates) to a global position, through the canvas's real scale
/// transform and horizontal scroll offset. Tests use it instead of
/// hard-coded pixel offsets, so they hold at every circuit scale.
Offset circuitContentToGlobal(WidgetTester tester, Offset content) {
  final surface = find.byKey(const ValueKey('circuit-interaction-surface'));
  final box = tester.renderObject<RenderBox>(surface);
  final scroll = find.byKey(const ValueKey('circuit-horizontal-scroll'));
  final scrollOffset = scroll.evaluate().isEmpty
      ? 0.0
      : tester
          .state<ScrollableState>(
              find.descendant(of: scroll, matching: find.byType(Scrollable)))
          .position
          .pixels;
  return box.localToGlobal(content - Offset(scrollOffset, 0));
}

/// Global centre of the slot at ([qubit], [column]).
Offset circuitSlotGlobal(WidgetTester tester, int qubit, int column) =>
    circuitContentToGlobal(
      tester,
      CircuitLayoutMetrics.slotCenter(
          CircuitLocation(qubit: qubit, column: column)),
    );

/// The display scale of the (single) Composer canvas under test.
double circuitScaleOf(WidgetTester tester) => tester
    .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas))
    .scale;
