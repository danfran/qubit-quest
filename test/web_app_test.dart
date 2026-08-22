import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/bloch_explorer_panels.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/composer_gate_palette.dart';

void main() {
  Future<void> setSize(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(QubitQuestWebApp(storage: InMemoryAppStorage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('wide shell defaults to Journey and switches workspaces',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);

    expect(
        find.byKey(const ValueKey('web-navigation-sidebar')), findsOneWidget);
    expect(find.byType(LearningMapScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    expect(find.byType(ComposerGatePalette), findsOneWidget);
    expect(find.byType(ComposerCircuitCanvas), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();
    expect(find.byType(BlochSpherePanel), findsOneWidget);
    expect(find.byType(BlochGatePanel), findsOneWidget);
    expect(find.byType(BlochPlaybackControls), findsOneWidget);
    expect(find.byType(BlochHistoryPanel), findsOneWidget);
    expect(find.byType(BlochStateMathPanel), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
    await tester.pump();
    expect(find.byType(DiscoveriesScreen), findsOneWidget);
  });

  testWidgets('narrow shell uses a drawer instead of permanent navigation',
      (tester) async {
    await setSize(tester, const Size(600, 900));
    await pumpApp(tester);

    expect(find.byKey(const ValueKey('web-navigation-sidebar')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('web-navigation-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('web-navigation-drawer')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pumpAndSettle();
    expect(find.byType(ComposerCircuitCanvas), findsOneWidget);
    expect(find.byKey(const ValueKey('web-navigation-drawer')), findsNothing);
  });

  testWidgets('Composer restores the existing Sandbox workspace',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    final storage = InMemoryAppStorage();
    final circuit = QuantumCircuit(currentLevel: createSandboxComposerLevel(3));
    circuit.insertSingleGateWithOutcome(
      Gate.fromIdentifier(SelectedGateType.hadamard),
      0,
      1,
    );
    await SandboxPersistenceStore(storage: storage).saveCircuit(circuit);

    await tester.pumpWidget(QubitQuestWebApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();

    expect(find.text('Restored 1 saved operation(s).'), findsOneWidget);
  });

  testWidgets('Bloch Instant off animates to the gate endpoint',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('bloch-gate-z')));
    await tester.pump();
    final initial = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    expect((initial.painter! as BlochSpherePainter).state.x, closeTo(1, .001));

    await tester.pump(const Duration(milliseconds: 325));
    final midway = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    final midwayX = (midway.painter! as BlochSpherePainter).state.x;
    expect(midwayX, lessThan(.99));
    expect(midwayX, greaterThan(-.99));

    await tester.pump(const Duration(milliseconds: 400));
    final finished = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    expect(
        (finished.painter! as BlochSpherePainter).state.x, closeTo(-1, .001));
  });

  testWidgets('Bloch Instant on applies the endpoint without a tween',
      (tester) async {
    await setSize(tester, const Size(1440, 1000));
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('web-nav-bloch')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bloch-gate-z')));
    await tester.pump();

    final canvas = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    expect((canvas.painter! as BlochSpherePainter).state.x, closeTo(-1, .001));
  });
}
