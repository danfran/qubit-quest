import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/quantum_inspector_views.dart';

void main() {
  Future<void> pumpInspector(
    WidgetTester tester, {
    Size size = const Size(340, 264),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: QuantumInspectorViews(
              stateView: const SizedBox(),
              currentStateVector: [Complex.one(), Complex.zero()],
              numQubits: 1,
              contentDriven: false,
              targetStateExpression: '|1⟩',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Bloch'));
    await tester.pump();
  }

  testWidgets('compact Bloch view preserves Explorer telemetry placement',
      (tester) async {
    await pumpInspector(tester);

    final region = tester.getRect(
      find.byKey(const ValueKey('quantum-inspector-bloch-sphere-region')),
    );
    final angles = tester.getRect(
      find.byKey(const ValueKey('bloch-live-angles')),
    );
    final cartesian = tester.getRect(
      find.byKey(const ValueKey('bloch-live-cartesian')),
    );
    final probabilities = tester.getRect(
      find.byKey(const ValueKey('bloch-live-probabilities')),
    );
    final target = tester.getRect(
      find.byKey(
        const ValueKey('quantum-inspector-bloch-target-reference'),
      ),
    );

    expect(angles.center.dx, lessThan(region.center.dx));
    expect(angles.center.dy, lessThan(region.center.dy));
    expect(cartesian.center.dx, greaterThan(region.center.dx));
    expect(cartesian.center.dy, lessThan(region.center.dy));
    expect(probabilities.center.dx, lessThan(region.center.dx));
    expect(probabilities.center.dy, greaterThan(region.center.dy));
    expect(target.top, greaterThanOrEqualTo(region.bottom));
    expect(target.overlaps(region), isFalse);

    final panel =
        tester.widget<BlochSpherePanel>(find.byType(BlochSpherePanel));
    expect(panel.reserveOverlaySafeRegions, isTrue);
    expect(panel.showHelper, isFalse);
    expect(panel.compactAnnotations, isTrue);
    expect(find.text('Live circuit state'), findsNothing);
    final canvas = tester.getRect(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    final painter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('bloch-sphere-canvas')),
        )
        .painter! as BlochSpherePainter;
    final paintedRadius = canvas.shortestSide * .38 * painter.camera.zoom;
    expect(paintedRadius * 2, inInclusiveRange(130, 170));
    bool clearsPaintedSphere(Rect telemetry) {
      final closestPoint = Offset(
        canvas.center.dx.clamp(telemetry.left, telemetry.right),
        canvas.center.dy.clamp(telemetry.top, telemetry.bottom),
      );
      return (closestPoint - canvas.center).distance >= paintedRadius - 4;
    }

    expect(clearsPaintedSphere(angles), isTrue);
    expect(clearsPaintedSphere(cartesian), isTrue);
    expect(clearsPaintedSphere(probabilities), isTrue);
    final angleText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('bloch-live-angles')),
        matching: find.text('θ = 0.000'),
      ),
    );
    final probabilityStyle = tester.widget<DefaultTextStyle>(
      find
          .descendant(
            of: find.byKey(const ValueKey('bloch-live-probabilities')),
            matching: find.byType(DefaultTextStyle),
          )
          .last,
    );
    expect(angleText.style?.fontSize, blochTelemetryTextStyle.fontSize);
    expect(probabilityStyle.style.fontSize, blochTelemetryTextStyle.fontSize);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Bloch layout fits a narrow web inspector',
      (tester) async {
    await pumpInspector(tester, size: const Size(280, 430));

    final view = tester.getRect(
      find.byKey(const ValueKey('quantum-inspector-bloch-view')),
    );
    expect(view.width, lessThanOrEqualTo(280));
    expect(find.byType(BlochSpherePanel), findsOneWidget);
    expect(find.text('Live circuit state'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
