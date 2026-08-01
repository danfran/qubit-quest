import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<QuantumCircuit> pumpComposer(
    WidgetTester tester, {
    Gate? placedGate,
    bool isDeletable = true,
    int qubits = 2,
    List<Gate>? palette,
    Size viewportSize = const Size(1200, 800),
    int placedGateCount = 1,
    int levelId = -1,
    String? levelTitle,
  }) async {
    SharedPreferences.setMockInitialValues({});
    QuantumCircuit? capturedModel;
    final level = ComposerLevel(
      title: levelTitle,
      taskDescription: 'Editing test',
      numQubits: qubits,
      initialQubitsStateStr: '0' * qubits,
      initialQubitsState: ComposerLevel.getZeroStateVector(qubits),
      availableGates: palette ??
          [
            Gate.fromIdentifier(SelectedGateType.hadamard),
            Gate.fromIdentifier(SelectedGateType.rx),
          ],
      solutionFinalVector: levelId == -1
          ? const []
          : ComposerLevel.getZeroStateVector(qubits)
              .map((amplitude) => [amplitude])
              .toList(),
      preInsertedGates: (circuit) {
        capturedModel ??= circuit;
        if (placedGate != null) {
          for (var column = 0; column < placedGateCount; column++) {
            circuit.insertSinglePlacedGateAt(
              placedGate,
              column,
              0,
              isDeletable: isDeletable,
            );
          }
        }
      },
    );
    tester.view.physicalSize = viewportSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: QuantumComposer(
          key: UniqueKey(),
          levelId: levelId,
          level: level,
          onLevelUnlocked: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final intro = find.text('Start Composing');
    if (intro.evaluate().isNotEmpty) {
      await tester.tap(intro);
      await tester.pumpAndSettle();
    }
    return capturedModel!;
  }

  Offset circuitPoint(WidgetTester tester, int qubit, int column) {
    final surface = find.byKey(const ValueKey('circuit-interaction-surface'));
    return tester.getTopLeft(surface) +
        Offset(40 + column * 40, 20 + qubit * 40);
  }

  Future<void> selectFirstGate(WidgetTester tester) async {
    await tester.tapAt(circuitPoint(tester, 0, 0));
    await tester.pump();
  }

  Rect circuitSurfaceRect(WidgetTester tester) => tester.getRect(
        find.byKey(const ValueKey('circuit-interaction-surface')),
      );

  Future<TestGesture> startSelectedGateDrag(WidgetTester tester) async {
    return tester.startGesture(circuitPoint(tester, 0, 0));
  }

  testWidgets('sandbox omits duplicate title while lessons keep context',
      (tester) async {
    await pumpComposer(tester);
    expect(find.text('Composer'), findsOneWidget);

    await pumpComposer(
      tester,
      levelId: 1,
      levelTitle: 'Contextual lesson title',
    );
    expect(find.text('Lesson 1'), findsWidgets);
    expect(find.text('Contextual lesson title'), findsOneWidget);

    await pumpComposer(
      tester,
      levelId: 61,
      levelTitle: 'Contextual mastery title',
    );
    expect(find.text('Mastery Challenge 1'), findsWidgets);
    expect(find.text('Contextual mastery title'), findsOneWidget);
  });

  testWidgets('tap selects a single gate and empty space clears selection',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
    );
    final id = model.placedGates[0][0].id!;
    await selectFirstGate(tester);
    expect(model.placedGateById(id)!.location,
        const CircuitLocation(qubit: 0, column: 0));
    expect(
        find.byKey(ValueKey('placed-gate-drag-${id.value}')), findsOneWidget);
    expect(find.bySemanticsLabel('Selected gate H'), findsOneWidget);

    await tester.tapAt(circuitPoint(tester, 0, 2));
    await tester.pump();
    expect(
        find.byKey(ValueKey('placed-gate-drag-${id.value}')), findsOneWidget);
    expect(find.bySemanticsLabel('Selected gate H'), findsNothing);
  });

  testWidgets('selected gate movement drag starts without a hold delay',
      (tester) async {
    for (final viewport in const [Size(430, 850), Size(1200, 800)]) {
      final model = await pumpComposer(
        tester,
        placedGate: Gate.fromIdentifier(SelectedGateType.x),
        viewportSize: viewport,
      );
      final id = model.placedGates[0][0].id!;
      await selectFirstGate(tester);

      final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
      await gesture.moveTo(circuitPoint(tester, 1, 1));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final moved = model.placedGateById(id)!;
      expect(moved.location.qubit, 1);
      expect(moved.id, id);
      expect(
          find.byKey(ValueKey('placed-gate-drag-${id.value}')), findsOneWidget);
    }
  });

  testWidgets('tap selected gate without movement is a no-op', (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.x),
    );
    final id = model.placedGates[0][0].id!;
    await selectFirstGate(tester);
    await tester.tapAt(circuitPoint(tester, 0, 0));
    await tester.pumpAndSettle();
    expect(model.placedGateById(id)!.location,
        const CircuitLocation(qubit: 0, column: 0));
    expect(
        find.byKey(ValueKey('placed-gate-drag-${id.value}')), findsOneWidget);
  });

  testWidgets('unselected gate moves and selects in one gesture',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.x),
    );
    final id = model.placedGates[0][0].id!;
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(circuitPoint(tester, 1, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.placedGateById(id)!.location,
        const CircuitLocation(qubit: 1, column: 0));
    expect(
        find.byKey(ValueKey('placed-gate-drag-${id.value}')), findsOneWidget);
    expect(find.bySemanticsLabel('Selected gate X'), findsOneWidget);
  });

  testWidgets('same-slot drag is a no-op', (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
    );
    final id = model.placedGates[0][0].id!;
    var notifications = 0;
    model.addListener(() => notifications++);
    await selectFirstGate(tester);
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveBy(const Offset(0, 19));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.placedGateById(id)!.location,
        const CircuitLocation(qubit: 0, column: 0));
    expect(notifications, 0);
  });

  testWidgets('drag clearly outside deletes a selected deletable gate',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.x),
    );
    final id = model.placedGates[0][0].id!;
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(const Offset(11, 10));
    await gesture.moveTo(const Offset(10, 10));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.placedGateById(id), isNull);
    expect(find.byKey(ValueKey('placed-gate-drag-${id.value}')), findsNothing);
  });

  testWidgets('delete affordance exactly predicts placed drag release outcome',
      (tester) async {
    Future<void> verifyRelease({
      required Offset Function(Rect) destination,
      required bool showsDelete,
      required bool deletes,
    }) async {
      final model = await pumpComposer(
        tester,
        placedGate: Gate.fromIdentifier(SelectedGateType.x),
      );
      final id = model.placedGates[0][0].id!;
      await selectFirstGate(tester);
      final surface = circuitSurfaceRect(tester);
      final gesture = await startSelectedGateDrag(tester);
      final releasePosition = destination(surface);
      // The first post-long-press movement starts the draggable; the second
      // represents the pointer update used by the live affordance.
      await gesture.moveTo(releasePosition + const Offset(1, 0));
      await gesture.moveTo(releasePosition);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('release-to-remove')),
        showsDelete ? findsOneWidget : findsNothing,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(model.placedGateById(id) == null, deletes);
    }

    await verifyRelease(
      destination: (rect) => rect.topLeft + const Offset(80, 60),
      showsDelete: false,
      deletes: false,
    );
    await verifyRelease(
      destination: (rect) => Offset(rect.center.dx, rect.bottom - 1),
      showsDelete: false,
      deletes: false,
    );
    await verifyRelease(
      destination: (rect) => Offset(rect.left - 6, rect.center.dy),
      showsDelete: false,
      deletes: false,
    );
    await verifyRelease(
      destination: (rect) => Offset(rect.left - 20, rect.center.dy),
      showsDelete: true,
      deletes: true,
    );
  });

  testWidgets('palette drag outside never shows or performs placed deletion',
      (tester) async {
    final model = await pumpComposer(tester, placedGateCount: 0);
    final paletteDrag = find.byType(Draggable<CircuitDragData>).first;
    final gesture = await tester.startGesture(tester.getCenter(paletteDrag));
    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(find.byKey(const ValueKey('release-to-remove')), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.isCircuitEmpty(), isTrue);
  });

  testWidgets('visible deletion bounds remain stable after horizontal scroll',
      (tester) async {
    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.x),
      placedGateCount: 24,
      viewportSize: const Size(900, 700),
    );
    final before = circuitSurfaceRect(tester);
    final circuitScrollable = find.descendant(
      of: find.byKey(const ValueKey('circuit-horizontal-scroll')),
      matching: find.byType(Scrollable),
    );
    final scrollPosition =
        tester.state<ScrollableState>(circuitScrollable).position;
    await tester.drag(
      find.byKey(const ValueKey('circuit-interaction-surface')),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    expect(scrollPosition.pixels, greaterThan(0));
    final after = circuitSurfaceRect(tester);
    expect(after, before);
    expect(
      CircuitGeometry.isClearlyOutsideCircuitForDeletion(
        circuitBounds: after,
        pointerPosition: Offset(after.left - 6, after.center.dy),
      ),
      isFalse,
    );
    expect(
      CircuitGeometry.isClearlyOutsideCircuitForDeletion(
        circuitBounds: after,
        pointerPosition: Offset(after.left - 20, after.center.dy),
      ),
      isTrue,
    );
  });

  testWidgets('fixed and controlled gates have no move drag source',
      (tester) async {
    final fixed = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.x),
      isDeletable: false,
    );
    final fixedId = fixed.placedGates[0][0].id!;
    await selectFirstGate(tester);
    expect(find.bySemanticsLabel('Selected gate X'), findsNothing);
    expect(find.byKey(ValueKey('placed-gate-drag-${fixedId.value}')),
        findsNothing);
  });

  testWidgets('configured rotation movement retains angle without dialog',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2),
    );
    final id = model.placedGates[0][0].id!;
    await selectFirstGate(tester);
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(circuitPoint(tester, 1, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.placedGateById(id)!.gate.angle, math.pi / 2);
    expect(find.text('Select Rotation Angle'), findsNothing);
  });

  testWidgets('palette remains a unified CircuitDragData source',
      (tester) async {
    await pumpComposer(tester);
    expect(find.byType(Draggable<CircuitDragData>), findsWidgets);
  });

  testWidgets('palette omits delete control and uses a subtle scrollbar',
      (tester) async {
    for (final viewport in const [Size(430, 850), Size(1200, 800)]) {
      await pumpComposer(
        tester,
        viewportSize: viewport,
        palette: List.generate(
          20,
          (_) => Gate.fromIdentifier(SelectedGateType.hadamard),
        ),
      );

      expect(find.byTooltip('Delete gate mode'), findsNothing);
      expect(find.byTooltip('Delete selected gate'), findsNothing);

      final scrollbarFinder =
          find.byKey(const ValueKey('gate-palette-scrollbar'));
      final scrollbar = tester.widget<Scrollbar>(scrollbarFinder);
      expect(scrollbar.thumbVisibility, isTrue);
      expect(scrollbar.thickness, 2);
      expect(scrollbar.radius, const Radius.circular(99));

      final scrollableFinder = find.descendant(
        of: scrollbarFinder,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollableFinder).position;
      expect(position.maxScrollExtent, greaterThan(0));

      Finder arrowFinder(String direction) =>
          find.byKey(ValueKey('palette-scroll-$direction'));
      IconButton arrow(String direction) =>
          tester.widget<IconButton>(arrowFinder(direction));

      expect(arrow('left').onPressed, isNull);
      expect(arrow('right').onPressed, isNotNull);

      final scrollableRect = tester.getRect(scrollableFinder);
      await tester.dragFrom(
        Offset(scrollableRect.center.dx, scrollableRect.bottom - 4),
        const Offset(-80, 0),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(arrow('left').onPressed, isNotNull);

      await tester.tap(arrowFinder('left'));
      await tester.pumpAndSettle();
      expect(position.pixels, closeTo(position.minScrollExtent, 0.1));
      expect(arrow('left').onPressed, isNull);

      await tester.tap(arrowFinder('right'));
      await tester.pumpAndSettle();
      expect(
        position.pixels,
        closeTo(
          math.min(position.viewportDimension, position.maxScrollExtent),
          0.1,
        ),
      );

      while (arrow('right').onPressed != null) {
        await tester.tap(arrowFinder('right'));
        await tester.pumpAndSettle();
      }
      expect(position.pixels, closeTo(position.maxScrollExtent, 0.1));
      expect(arrow('right').onPressed, isNull);
      expect(arrow('left').onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    }
  });
}
