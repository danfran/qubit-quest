import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
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
    void Function(QuantumCircuit circuit)? preInsertGates,
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
        if (preInsertGates != null) {
          preInsertGates(circuit);
        } else if (placedGate != null) {
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

  void insertControlledGate(
    QuantumCircuit circuit,
    SelectedGateType type, {
    bool isDeletable = true,
  }) {
    if (type == SelectedGateType.ccnot) {
      circuit.insertTriplePlacedGateAt(
        Gate.fromIdentifier(type),
        0,
        2,
        0,
        1,
        isDeletable: isDeletable,
      );
    } else {
      circuit.insertDoublePlacedGateAt(
        Gate.fromIdentifier(type),
        0,
        2,
        0,
        isDeletable: isDeletable,
      );
    }
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
    final simulationsBefore = model.simulationRunCount;
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(circuitPoint(tester, 1, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.placedGateById(id)!.location,
        const CircuitLocation(qubit: 1, column: 0));
    expect(
        find.byKey(ValueKey('placed-gate-drag-${id.value}')), findsOneWidget);
    expect(find.bySemanticsLabel('Selected gate X'), findsOneWidget);
    expect(model.simulationRunCount, simulationsBefore + 1);
  });

  testWidgets('same-slot drag is a no-op', (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
    );
    final id = model.placedGates[0][0].id!;
    var notifications = 0;
    model.addListener(() => notifications++);
    final simulationsBefore = model.simulationRunCount;
    await selectFirstGate(tester);
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveBy(const Offset(0, 19));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.placedGateById(id)!.location,
        const CircuitLocation(qubit: 0, column: 0));
    expect(notifications, 0);
    expect(model.simulationRunCount, simulationsBefore);
  });

  testWidgets('drag clearly outside deletes a selected deletable gate',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.x),
    );
    final id = model.placedGates[0][0].id!;
    final simulationsBefore = model.simulationRunCount;
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(const Offset(11, 10));
    await gesture.moveTo(const Offset(10, 10));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.placedGateById(id), isNull);
    expect(find.byKey(ValueKey('placed-gate-drag-${id.value}')), findsNothing);
    expect(model.simulationRunCount, simulationsBefore + 1);
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

  testWidgets('valid internal drag uses preview without Drop ready text',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.x),
    );
    final id = model.placedGates[0][0].id!;
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(circuitPoint(tester, 1, 1));
    await tester.pump();

    expect(find.text('Drop ready'), findsNothing);
    expect(find.byKey(const ValueKey('release-to-remove')), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.placedGateById(id)?.location.qubit, 1);
  });

  testWidgets('delete affordance stays fixed to viewport while scrolled',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.x),
      placedGateCount: 24,
      viewportSize: const Size(900, 700),
    );
    final surface = circuitSurfaceRect(tester);
    final outside = Offset(surface.left - 20, surface.center.dy);

    Future<(Rect, TestGesture)> dragOutside(GateId id) async {
      final source = tester.getCenter(
        find.byKey(ValueKey('placed-gate-drag-${id.value}')),
      );
      final gesture = await tester.startGesture(source);
      await gesture.moveTo(outside + const Offset(1, 0));
      await gesture.moveTo(outside);
      await tester.pump();
      final pill = find.byKey(const ValueKey('release-to-remove'));
      expect(pill, findsOneWidget);
      return (tester.getRect(pill), gesture);
    }

    final leftId = model.placedGates[0].first.id!;
    final (leftRect, leftGesture) = await dragOutside(leftId);
    await leftGesture.moveTo(surface.center);
    await tester.pump();
    expect(find.byKey(const ValueKey('release-to-remove')), findsNothing);
    await leftGesture.cancel();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('release-to-remove')), findsNothing);

    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('circuit-horizontal-scroll')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    final rightId = model.placedGates[0].last.id!;
    final (rightRect, rightGesture) = await dragOutside(rightId);
    expect(rightRect.topLeft, leftRect.topLeft);
    await rightGesture.cancel();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('release-to-remove')), findsNothing);
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

  testWidgets(
      'one-qubit palette drag uses one candidate for wire preview and commit',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 1,
      placedGateCount: 0,
      palette: [Gate.fromIdentifier(SelectedGateType.hadamard)],
    );
    final paletteDrag = find.byType(Draggable<CircuitDragData>).first;
    final surface = circuitSurfaceRect(tester);
    final destination = Offset(surface.center.dx, surface.bottom - 3);
    final gesture = await tester.startGesture(tester.getCenter(paletteDrag));
    await gesture.moveTo(destination);
    await tester.pump();

    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<QuantumCircuitPainter>()
        .firstWhere((candidate) => candidate.previewGates != null);
    expect(painter.highlightedQubit, 0);
    expect(painter.previewGates![0].single.gate.type,
        SelectedGateType.draggedGate);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.logicalGates, hasLength(1));
    expect(model.logicalGates.single.anchor.qubit, 0);
    expect(model.logicalGates.single.type, SelectedGateType.hadamard);
  });

  testWidgets(
      'outside horizontal area shows no wire candidate and does not insert',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 1,
      placedGateCount: 0,
      palette: [Gate.fromIdentifier(SelectedGateType.hadamard)],
    );
    final paletteDrag = find.byType(Draggable<CircuitDragData>).first;
    final surface = circuitSurfaceRect(tester);
    final gesture = await tester.startGesture(tester.getCenter(paletteDrag));
    await gesture.moveTo(Offset(surface.left - 4, surface.center.dy));
    await tester.pump();

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<QuantumCircuitPainter>();
    expect(
        painters.every((painter) => painter.highlightedQubit == null), isTrue);
    expect(painters.every((painter) => painter.previewGates == null), isTrue);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.isCircuitEmpty(), isTrue);
  });

  testWidgets(
      'controlled control, target, second control and link select one ID',
      (tester) async {
    final cnot = await pumpComposer(
      tester,
      qubits: 3,
      preInsertGates: (circuit) =>
          insertControlledGate(circuit, SelectedGateType.cnot),
    );
    final cnotId = cnot.placedGates[0][0].id!;
    for (final qubit in [0, 2, 1]) {
      await tester.tapAt(circuitPoint(tester, qubit, 0));
      await tester.pump();
      expect(
        find.bySemanticsLabel(
          'Selected gate ${Gate.fromIdentifier(SelectedGateType.cnot).label}',
        ),
        findsOneWidget,
      );
      expect(cnot.placedGateById(cnotId), isNotNull);
      await tester.tapAt(circuitPoint(tester, 0, 2));
      await tester.pump();
    }

    await pumpComposer(
      tester,
      qubits: 3,
      preInsertGates: (circuit) =>
          insertControlledGate(circuit, SelectedGateType.ccnot),
    );
    await tester.tapAt(circuitPoint(tester, 1, 0));
    await tester.pump();
    expect(
      find.bySemanticsLabel(
        'Selected gate ${Gate.fromIdentifier(SelectedGateType.ccnot).label}',
      ),
      findsOneWidget,
    );
  });

  for (final gateType in [
    SelectedGateType.cnot,
    SelectedGateType.cz,
    SelectedGateType.ccnot,
  ]) {
    testWidgets('dragging $gateType outside deletes every logical fragment',
        (tester) async {
      final viewports = gateType == SelectedGateType.cnot
          ? const [Size(430, 850), Size(1200, 800)]
          : const [Size(1200, 800)];
      for (final viewport in viewports) {
        final model = await pumpComposer(
          tester,
          qubits: 3,
          viewportSize: viewport,
          preInsertGates: (circuit) {
            insertControlledGate(circuit, gateType);
            circuit.insertSinglePlacedGateAt(
              Gate.fromIdentifier(SelectedGateType.hadamard),
              1,
              2,
            );
          },
        );
        final id = model.placedGates[0][0].id!;
        final remainingId = model.placedGates[2]
            .firstWhere((cell) => cell.gate.type == SelectedGateType.hadamard)
            .id!;
        final surface = circuitSurfaceRect(tester);
        final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
        final outside = Offset(surface.left - 20, surface.center.dy);
        await gesture.moveTo(outside + const Offset(1, 0));
        await gesture.moveTo(outside);
        await tester.pump();
        expect(find.byKey(const ValueKey('release-to-remove')), findsOneWidget);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(model.placedGateById(id), isNull);
        expect(
          model.placedGates.expand((row) => row).where((cell) => cell.id == id),
          isEmpty,
        );
        expect(model.placedGateById(remainingId), isNotNull);
        expect(
            find.bySemanticsLabel(
                'Selected gate ${Gate.fromIdentifier(gateType).label}'),
            findsNothing);
      }
    });
  }

  testWidgets('controlled move composes with neighbour edits and deletion',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 4,
      palette: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.rx),
      ],
      preInsertGates: (circuit) {
        insertControlledGate(circuit, SelectedGateType.cnot);
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard),
          0,
          3,
        );
      },
    );
    final cxId = model.logicalGates
        .firstWhere((gate) => gate.type == SelectedGateType.cnot)
        .id;
    final neighbourId = model.logicalGates
        .firstWhere((gate) => gate.type == SelectedGateType.hadamard)
        .id;

    var gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(circuitPoint(tester, 0, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.logicalGateById(cxId)!.column, 1);

    await tester.tapAt(circuitPoint(tester, 3, 0));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('replace-selected-gate')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('replacement-gate-rx')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('fractional-angle-denominator')), '2');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(model.logicalGateById(neighbourId)!.type, SelectedGateType.rx);

    await tester.tap(find.byKey(const ValueKey('edit-selected-gate-angle')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('fractional-angle-denominator')), '4');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(model.logicalGateById(neighbourId)!.gate.angle,
        closeTo(math.pi / 4, 1e-12));

    final surface = circuitSurfaceRect(tester);
    gesture = await tester.startGesture(circuitPoint(tester, 0, 1));
    final outside = Offset(surface.left - 30, surface.center.dy);
    await gesture.moveTo(outside + const Offset(1, 0));
    await gesture.moveTo(outside);
    await tester.pump();
    expect(find.byKey(const ValueKey('release-to-remove')), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(model.logicalGateById(cxId), isNull);
    final neighbour = model.logicalGateById(neighbourId)!;
    expect(neighbour.type, SelectedGateType.rx);
    expect(neighbour.gate.angle, closeTo(math.pi / 4, 1e-12));
  });

  testWidgets('controlled internal drop and cancelled drag are non-destructive',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 3,
      preInsertGates: (circuit) =>
          insertControlledGate(circuit, SelectedGateType.cnot),
    );
    final id = model.placedGates[0][0].id!;
    List<(int, int)> fragmentLocations() => [
          for (final (qubit, row) in model.placedGates.indexed)
            for (final (column, cell) in row.indexed)
              if (cell.id == id) (qubit, column),
        ];
    final original = fragmentLocations();
    var notifications = 0;
    model.addListener(() => notifications++);
    final simulationsBefore = model.simulationRunCount;

    var gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(circuitPoint(tester, 2, 2));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(fragmentLocations(), original);
    expect(notifications, 0);

    final surface = circuitSurfaceRect(tester);
    gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(Offset(surface.left - 30, surface.center.dy));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(fragmentLocations(), original);
    expect(notifications, 0);
    expect(model.simulationRunCount, simulationsBefore);
  });

  testWidgets('dense CX preview is the exact full circuit committed on drop',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 3,
      preInsertGates: (circuit) {
        for (final (column, type) in [
          SelectedGateType.hadamard,
          SelectedGateType.t,
          SelectedGateType.hadamard,
          SelectedGateType.z,
          SelectedGateType.x,
        ].indexed) {
          circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(type),
            column,
            0,
          );
        }
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          5,
          2,
          0,
        );
      },
    );
    final cx = model.logicalGates.firstWhere(
      (gate) => gate.type == SelectedGateType.cnot,
    );
    final beforeTypes = model.logicalGates
        .where((gate) => gate.controlQubit == 0 || gate.anchor.qubit == 0)
        .toList()
      ..sort((a, b) => a.column.compareTo(b.column));
    expect(
      beforeTypes.map((gate) => gate.type),
      [
        SelectedGateType.hadamard,
        SelectedGateType.t,
        SelectedGateType.hadamard,
        SelectedGateType.z,
        SelectedGateType.x,
        SelectedGateType.cnot,
      ],
    );
    var notifications = 0;
    model.addListener(() => notifications++);
    final simulationsBefore = model.simulationRunCount;

    final gesture = await tester.startGesture(circuitPoint(tester, 0, 5));
    final destination = circuitPoint(tester, 0, 2);
    await gesture.moveTo(destination + const Offset(1, 0));
    await gesture.moveTo(destination);
    await tester.pump();

    final previewPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<QuantumCircuitPainter>()
        .firstWhere((painter) => painter.previewGates != null);
    final preview = previewPainter.previewGates!;
    List<SelectedGateType> firstRowLogicalTypes(
      List<List<PlacedQuantumGate>> rows,
    ) {
      final seen = <GateId>{};
      return [
        for (final cell in rows[0])
          if (cell.id != null && seen.add(cell.id!)) cell.gate.type,
      ];
    }

    expect(
      firstRowLogicalTypes(preview),
      [
        SelectedGateType.hadamard,
        SelectedGateType.t,
        SelectedGateType.cnot,
        SelectedGateType.hadamard,
        SelectedGateType.z,
        SelectedGateType.x,
      ],
    );
    expect(model.logicalGateById(cx.id)!.column, 5);
    expect(notifications, 0);
    expect(model.simulationRunCount, simulationsBefore);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.logicalGateById(cx.id)!.column, 2);
    expect(
        firstRowLogicalTypes(model.placedGates), firstRowLogicalTypes(preview));
    expect(notifications, 2); // structural edit and simulation result
    expect(model.simulationRunCount, simulationsBefore + 1);
    expect(
      find.bySemanticsLabel('Selected gate ${cx.gate.label}'),
      findsOneWidget,
    );
  });

  testWidgets('move preview shifts only the colliding row in independent rows',
      (tester) async {
    late GateId movedId;
    late GateId unaffectedId;
    final model = await pumpComposer(
      tester,
      qubits: 4,
      preInsertGates: (circuit) {
        final upper = <CircuitEditOutcome>[];
        for (final type in [
          SelectedGateType.z,
          SelectedGateType.t,
          SelectedGateType.s,
          SelectedGateType.z,
        ]) {
          upper.add(circuit.insertSingleGateWithOutcome(
            Gate.fromIdentifier(type),
            upper.length,
            2,
          ));
        }
        movedId = upper[2].affectedGateId!;
        circuit.insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.z),
          0,
          3,
        );
        unaffectedId = circuit
            .insertSingleGateWithOutcome(
              Gate.fromIdentifier(SelectedGateType.z),
              1,
              3,
            )
            .affectedGateId!;
      },
    );
    var notifications = 0;
    model.addListener(() => notifications++);
    final simulationsBefore = model.simulationRunCount;
    final gesture = await tester.startGesture(circuitPoint(tester, 2, 2));
    await gesture.moveTo(circuitPoint(tester, 2, 1));
    await tester.pump();

    final previewPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<QuantumCircuitPainter>()
        .firstWhere((painter) => painter.previewGates != null);
    final preview = previewPainter.previewGates!;
    expect(
      preview[2].where((gate) => gate.id != null).map((gate) => gate.gate.type),
      [
        SelectedGateType.z,
        SelectedGateType.s,
        SelectedGateType.t,
        SelectedGateType.z,
      ],
    );
    expect(preview[3][1].id, unaffectedId);
    expect(model.logicalGateById(unaffectedId)!.column, 1);
    expect(model.logicalGateById(movedId)!.column, 2);
    expect(notifications, 0);
    expect(model.simulationRunCount, simulationsBefore);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.logicalGateById(movedId)!.column, 1);
    expect(model.logicalGateById(unaffectedId)!.column, 1);
    expect(
      model.placedGates
          .map((row) => row.map((gate) => gate.id).toList())
          .toList(),
      preview.map((row) => row.map((gate) => gate.id).toList()).toList(),
    );
    expect(notifications, 2); // structural edit and simulation result
    expect(model.simulationRunCount, simulationsBefore + 1);
  });

  testWidgets('CX translates rigidly from q2-q4 to q0-q2 before commit',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 5,
      preInsertGates: (circuit) {
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          1,
          4,
          2,
        );
        circuit.insertSinglePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.hadamard),
          0,
          0,
        );
      },
    );
    final id = model.logicalGates
        .firstWhere((gate) => gate.type == SelectedGateType.cnot)
        .id;
    var notifications = 0;
    model.addListener(() => notifications++);
    final simulationsBefore = model.simulationRunCount;

    final gesture = await tester.startGesture(circuitPoint(tester, 2, 0));
    final destination = circuitPoint(tester, 0, 0);
    await gesture.moveTo(destination + const Offset(1, 0));
    await gesture.moveTo(destination);
    await tester.pump();
    final previewPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<QuantumCircuitPainter>()
        .firstWhere((painter) => painter.previewGates != null);
    final previewFragments = [
      for (final (qubit, row) in previewPainter.previewGates!.indexed)
        for (final cell in row)
          if (cell.id == id) (qubit, cell),
    ];
    expect(previewFragments.map((fragment) => fragment.$1), [0, 1, 2]);
    expect(
      previewFragments.firstWhere((fragment) => fragment.$2.isControl).$1,
      0,
    );
    expect(
      previewFragments.firstWhere((fragment) => fragment.$2.isTarget).$1,
      2,
    );
    expect(model.logicalGateById(id)!.controlQubit, 2);
    expect(model.logicalGateById(id)!.targetQubit, 4);
    expect(notifications, 0);
    expect(model.simulationRunCount, simulationsBefore);

    await gesture.up();
    await tester.pumpAndSettle();
    final moved = model.logicalGateById(id)!;
    expect(moved.controlQubit, 0);
    expect(moved.targetQubit, 2);
    expect(moved.column, 0);
    expect(notifications, 2); // structural edit and simulation result
    expect(model.simulationRunCount, simulationsBefore + 1);

    final back = await tester.startGesture(circuitPoint(tester, 2, 0));
    await back.moveTo(circuitPoint(tester, 4, 1));
    await back.up();
    await tester.pumpAndSettle();
    expect(model.logicalGateById(id)!.controlQubit, 2);
    expect(model.logicalGateById(id)!.targetQubit, 4);
    expect(model.logicalGateById(id)!.column, 1);
  });

  for (final type in [SelectedGateType.cz, SelectedGateType.ccnot]) {
    testWidgets(
        '$type translates from a connector/control grab without reshaping',
        (tester) async {
      final model = await pumpComposer(
        tester,
        qubits: 6,
        preInsertGates: (circuit) {
          if (type == SelectedGateType.ccnot) {
            circuit.insertTriplePlacedGateAt(
              Gate.fromIdentifier(type),
              0,
              4,
              1,
              3,
            );
          } else {
            circuit.insertDoublePlacedGateAt(
              Gate.fromIdentifier(type),
              0,
              4,
              2,
            );
          }
        },
      );
      final before = model.logicalGates.firstWhere((gate) => gate.type == type);
      final offsets = before.fragments
          .map((fragment) => fragment.location.qubit - before.anchor.qubit)
          .toList();
      const grabbedRow = 3;
      final destinationGrabRow = grabbedRow - 1;

      final gesture =
          await tester.startGesture(circuitPoint(tester, grabbedRow, 0));
      await gesture.moveTo(circuitPoint(tester, destinationGrabRow, 1));
      await tester.pump();
      final previewPainter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<QuantumCircuitPainter>()
          .firstWhere((painter) => painter.previewGates != null);
      final previewRows = [
        for (final (qubit, row) in previewPainter.previewGates!.indexed)
          if (row.any((gate) => gate.id == before.id)) qubit,
      ];
      expect(
        previewRows,
        before.fragments
            .map((fragment) => fragment.location.qubit - 1)
            .toList(),
      );

      await gesture.up();
      await tester.pumpAndSettle();
      final moved = model.logicalGateById(before.id)!;
      expect(moved.column, 0);
      expect(
        moved.fragments
            .map((fragment) => fragment.location.qubit - moved.anchor.qubit),
        offsets,
      );
      expect(moved.controlQubit, before.controlQubit! - 1);
      expect(moved.targetQubit, before.targetQubit! - 1);
      if (type == SelectedGateType.ccnot) {
        expect(moved.secondControlQubit, before.secondControlQubit! - 1);
      }
    });
  }

  testWidgets(
      'controlled translation beyond row bounds has no preview or commit',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 5,
      preInsertGates: (circuit) => circuit.insertDoublePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.cnot),
        0,
        4,
        2,
      ),
    );
    final footprint = model.logicalGates.single;
    final original = footprint.occupiedLocations;
    var notifications = 0;
    model.addListener(() => notifications++);
    final simulationsBefore = model.simulationRunCount;

    var gesture = await tester.startGesture(circuitPoint(tester, 4, 0));
    await gesture.moveTo(circuitPoint(tester, 0, 1));
    await tester.pump();
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<QuantumCircuitPainter>()
          .where((painter) => painter.previewGates != null),
      isEmpty,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.logicalGateById(footprint.id)!.occupiedLocations, original);

    gesture = await tester.startGesture(circuitPoint(tester, 2, 0));
    await gesture.moveTo(circuitPoint(tester, 4, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.logicalGateById(footprint.id)!.occupiedLocations, original);
    expect(notifications, 0);
    expect(model.simulationRunCount, simulationsBefore);
  });

  testWidgets('placed drag uses source ghost and transparent pointer feedback',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
      viewportSize: const Size(430, 850),
    );
    final id = model.logicalGates.single.id;
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(circuitPoint(tester, 1, 1));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('placed-drag-transparent-feedback')),
      findsOneWidget,
    );
    final dragPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<QuantumCircuitPainter>()
        .firstWhere((painter) => painter.ghostedGateId == id);
    expect(dragPainter.previewGates, isNotNull);
    expect(
      dragPainter.previewGates!
          .expand((row) => row)
          .where((gate) => gate.id == id),
      hasLength(1),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('placed-drag-transparent-feedback')),
      findsNothing,
    );
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<QuantumCircuitPainter>()
          .where((painter) => painter.ghostedGateId != null),
      isEmpty,
    );
  });

  testWidgets('source ghost survives invalid drag and disappears on cancel',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 5,
      preInsertGates: (circuit) => circuit.insertDoublePlacedGateAt(
        Gate.fromIdentifier(SelectedGateType.cnot),
        0,
        4,
        2,
      ),
    );
    final id = model.logicalGates.single.id;
    final gesture = await tester.startGesture(circuitPoint(tester, 4, 0));
    await gesture.moveTo(circuitPoint(tester, 0, 1));
    await tester.pump();

    final invalidPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<QuantumCircuitPainter>()
        .firstWhere((painter) => painter.ghostedGateId == id);
    expect(invalidPainter.previewGates, isNull);
    expect(
      find.byKey(const ValueKey('placed-drag-transparent-feedback')),
      findsOneWidget,
    );

    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(model.logicalGateById(id), isNotNull);
    expect(
      find.byKey(const ValueKey('placed-drag-transparent-feedback')),
      findsNothing,
    );
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<QuantumCircuitPainter>()
          .where((painter) => painter.ghostedGateId != null),
      isEmpty,
    );
  });

  testWidgets('controlled source ghost disappears after outside deletion',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 4,
      viewportSize: const Size(1200, 800),
      preInsertGates: (circuit) =>
          insertControlledGate(circuit, SelectedGateType.ccnot),
    );
    final id = model.logicalGates.single.id;
    final surface = circuitSurfaceRect(tester);
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    final outside = Offset(surface.left - 30, surface.center.dy);
    await gesture.moveTo(outside + const Offset(1, 0));
    await gesture.moveTo(outside);
    await tester.pump();
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<QuantumCircuitPainter>()
          .any((painter) => painter.ghostedGateId == id),
      isTrue,
    );
    expect(find.byKey(const ValueKey('release-to-remove')), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.logicalGateById(id), isNull);
    expect(
      find.byKey(const ValueKey('placed-drag-transparent-feedback')),
      findsNothing,
    );
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<QuantumCircuitPainter>()
          .where((painter) => painter.ghostedGateId != null),
      isEmpty,
    );
  });

  for (final gateType in [
    SelectedGateType.cnot,
    SelectedGateType.cz,
    SelectedGateType.ccnot,
  ]) {
    testWidgets('$gateType moves horizontally as one selected footprint',
        (tester) async {
      final viewport = gateType == SelectedGateType.cnot
          ? const Size(430, 850)
          : const Size(1200, 800);
      final model = await pumpComposer(
        tester,
        qubits: 4,
        viewportSize: viewport,
        preInsertGates: (circuit) {
          insertControlledGate(circuit, gateType);
          circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard),
            0,
            3,
          );
        },
      );
      final footprint = model.logicalGates.firstWhere(
        (gate) => gate.type == gateType,
      );
      final id = footprint.id;
      final rolesBefore = footprint.fragments
          .map((fragment) => (
                fragment.location.qubit,
                fragment.placedGate.isControl,
                fragment.placedGate.isControl2,
                fragment.placedGate.isTarget,
                fragment.placedGate.isLink,
              ))
          .toList();
      var notifications = 0;
      model.addListener(() => notifications++);
      final simulationsBefore = model.simulationRunCount;

      final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
      final destination = circuitPoint(tester, 0, 1);
      await gesture.moveTo(destination + const Offset(1, 0));
      await gesture.moveTo(destination);
      await tester.pump();
      final previewPainter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<QuantumCircuitPainter>()
          .firstWhere((painter) => painter.previewGates != null);
      final previewFragments = previewPainter.previewGates!
          .expand((row) => row)
          .where((gate) => gate.id == id);
      expect(previewFragments, hasLength(footprint.fragments.length));

      await gesture.up();
      await tester.pumpAndSettle();
      final moved = model.logicalGateById(id)!;
      expect(moved.id, id);
      expect(moved.column, 1);
      expect(
        moved.fragments
            .map((fragment) => (
                  fragment.location.qubit,
                  fragment.placedGate.isControl,
                  fragment.placedGate.isControl2,
                  fragment.placedGate.isTarget,
                  fragment.placedGate.isLink,
                ))
            .toList(),
        rolesBefore,
      );
      expect(notifications, 2); // structural edit and simulation result
      expect(model.simulationRunCount, simulationsBefore + 1);
      expect(
        find.bySemanticsLabel('Selected gate ${moved.gate.label}'),
        findsOneWidget,
      );
    });
  }

  testWidgets('controlled horizontal movement uses scrolled content columns',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 4,
      viewportSize: const Size(430, 850),
      preInsertGates: (circuit) {
        for (var column = 0; column < 10; column++) {
          circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard),
            column,
            1,
          );
        }
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          10,
          2,
          1,
        );
        for (var column = 0; column < 12; column++) {
          circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard),
            column,
            3,
          );
        }
      },
    );
    final id = model.logicalGates
        .firstWhere((gate) => gate.type == SelectedGateType.cnot)
        .id;
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('circuit-horizontal-scroll')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final surface = circuitSurfaceRect(tester);
    Offset visiblePoint(int qubit, int column) =>
        surface.topLeft +
        Offset(
          40 + column * 40 - position.pixels,
          20 + qubit * 40,
        );

    final gesture = await tester.startGesture(visiblePoint(1, 10));
    await gesture.moveTo(visiblePoint(1, 11));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(model.logicalGateById(id)!.column, 11);
    expect(model.logicalGateById(id)!.controlQubit, 1);
    expect(model.logicalGateById(id)!.targetQubit, 2);
  });

  testWidgets(
      'protected controlled gate selects but has no deletion drag source',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 3,
      preInsertGates: (circuit) => insertControlledGate(
        circuit,
        SelectedGateType.cz,
        isDeletable: false,
      ),
    );
    final id = model.placedGates[0][0].id!;
    await tester.tapAt(circuitPoint(tester, 2, 0));
    await tester.pump();
    expect(model.placedGateById(id), isNotNull);
    expect(find.byKey(ValueKey('placed-gate-drag-${id.value}')), findsNothing);
  });

  testWidgets('controlled deletion uses visible bounds after horizontal scroll',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 3,
      viewportSize: const Size(900, 700),
      preInsertGates: (circuit) {
        for (var column = 0; column < 14; column++) {
          circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard),
            column,
            0,
          );
        }
        circuit.insertDoublePlacedGateAt(
          Gate.fromIdentifier(SelectedGateType.cnot),
          14,
          2,
          0,
        );
      },
    );
    final id = model.placedGates
        .expand((row) => row)
        .firstWhere((cell) => cell.gate.type == SelectedGateType.cnot)
        .id!;
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('circuit-horizontal-scroll')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    final surface = circuitSurfaceRect(tester);
    final source = surface.topLeft + Offset(40 + 14 * 40 - position.pixels, 20);
    final outside = Offset(surface.left - 20, surface.center.dy);
    final gesture = await tester.startGesture(source);
    await gesture.moveTo(outside + const Offset(1, 0));
    await gesture.moveTo(outside);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.placedGateById(id), isNull);
  });

  testWidgets('Check Result remains functional after controlled deletion',
      (tester) async {
    final model = await pumpComposer(
      tester,
      qubits: 3,
      levelId: 1,
      levelTitle: 'Controlled deletion check',
      preInsertGates: (circuit) =>
          insertControlledGate(circuit, SelectedGateType.cnot),
    );
    final id = model.placedGates[0][0].id!;
    final surface = circuitSurfaceRect(tester);
    final outside = Offset(surface.left - 20, surface.center.dy);
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(outside + const Offset(1, 0));
    await gesture.moveTo(outside);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.placedGateById(id), isNull);

    expect(find.text('Check Result'), findsOneWidget);
    await tester.tap(find.text('Check Result'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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

  testWidgets('palette preview and commit append at scrolled circuit end',
      (tester) async {
    final model = await pumpComposer(
      tester,
      viewportSize: const Size(700, 700),
      palette: [Gate.fromIdentifier(SelectedGateType.x)],
      preInsertGates: (circuit) {
        for (var column = 0; column < 18; column++) {
          circuit.insertSinglePlacedGateAt(
            Gate.fromIdentifier(SelectedGateType.hadamard),
            column,
            0,
          );
        }
      },
    );
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('circuit-horizontal-scroll')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    final paletteDrag = find.byWidgetPredicate(
      (widget) =>
          widget is Draggable<CircuitDragData> &&
          widget.data?.isPlaced == false,
    );
    final viewport = tester.getRect(
      find.byKey(const ValueKey('circuit-horizontal-scroll')),
    );
    final visibleGateId = model.placedGates[0].last.id!;
    final visibleGate =
        find.byKey(ValueKey('placed-gate-drag-${visibleGateId.value}'));
    final desiredFeedbackOffset =
        Offset(viewport.right - 30, tester.getCenter(visibleGate).dy);
    final source = tester.getCenter(paletteDrag);
    final childAnchor = source - tester.getTopLeft(paletteDrag);
    final pointerDestination = desiredFeedbackOffset + childAnchor;
    await tester.dragFrom(source, pointerDestination - source);
    await tester.pumpAndSettle();
    expect(model.placedGates[0], hasLength(19));
    expect(model.placedGates[0].last.gate.type, SelectedGateType.x);
    expect(position.maxScrollExtent, greaterThan(0));
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

  for (final gateType in [
    SelectedGateType.rx,
    SelectedGateType.ry,
    SelectedGateType.rz,
  ]) {
    testWidgets('selecting $gateType shows contextual Edit angle action',
        (tester) async {
      await pumpComposer(
        tester,
        placedGate: Gate.fromIdentifier(gateType, angle: math.pi / 4),
      );
      expect(find.text('Edit angle'), findsNothing);
      await selectFirstGate(tester);
      expect(find.text('Edit angle'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });
  }

  testWidgets(
      'non-rotation, controlled, empty, and protected selections hide edit',
      (tester) async {
    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
    );
    await selectFirstGate(tester);
    expect(find.text('Edit angle'), findsNothing);

    await pumpComposer(
      tester,
      qubits: 3,
      preInsertGates: (circuit) =>
          insertControlledGate(circuit, SelectedGateType.cnot),
    );
    await tester.tapAt(circuitPoint(tester, 0, 0));
    await tester.pump();
    expect(find.text('Edit angle'), findsNothing);

    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
      isDeletable: false,
    );
    await selectFirstGate(tester);
    expect(find.text('Edit angle'), findsNothing);
  });

  testWidgets('editing opens at current angle and commits once',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
    );
    final id = model.placedGates[0][0].id!;
    await selectFirstGate(tester);
    await tester.tap(find.text('Edit angle'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Edit Rx'), findsOneWidget);
    final numerator = tester.widget<TextField>(
      find.byKey(const ValueKey('fractional-angle-numerator')),
    );
    final denominator = tester.widget<TextField>(
      find.byKey(const ValueKey('fractional-angle-denominator')),
    );
    expect(numerator.controller!.text, '1');
    expect(denominator.controller!.text, '4');

    await tester.enterText(
        find.byKey(const ValueKey('fractional-angle-denominator')), '2');
    final simulationsBefore = model.simulationRunCount;
    final stateBefore = List.of(model.currentState.stateVector);
    var notifications = 0;
    model.addListener(() => notifications++);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    final updated = model.logicalGateById(id)!;
    expect(updated.gate.angle, closeTo(math.pi / 2, 1e-12));
    expect(model.simulationRunCount, simulationsBefore + 1);
    expect(model.currentState.stateVector, isNot(equals(stateBefore)));
    expect(notifications, 2); // one structural and one simulation notification
    expect(find.bySemanticsLabel('Selected gate ${updated.gate.label}'),
        findsOneWidget);
  });

  testWidgets('cancel and same-angle confirmation are non-mutating',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.ry, angle: -math.pi / 2),
    );
    final id = model.placedGates[0][0].id!;
    await selectFirstGate(tester);
    final angleBefore = model.logicalGateById(id)!.gate.angle;
    final simulationsBefore = model.simulationRunCount;
    var notifications = 0;
    model.addListener(() => notifications++);

    await tester.tap(find.text('Edit angle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(model.logicalGateById(id)!.gate.angle, angleBefore);
    expect(model.simulationRunCount, simulationsBefore);
    expect(notifications, 0);

    await tester.tap(find.text('Edit angle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(model.logicalGateById(id)!.gate.angle, angleBefore);
    expect(model.simulationRunCount, simulationsBefore);
    expect(notifications, 0);
    expect(find.text('Edit angle'), findsOneWidget);
  });

  testWidgets('rotation gate remains directly draggable without opening editor',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.rz, angle: math.pi / 4),
    );
    final id = model.placedGates[0][0].id!;
    final gesture = await tester.startGesture(circuitPoint(tester, 0, 0));
    await gesture.moveTo(circuitPoint(tester, 1, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.logicalGateById(id)!.anchor.qubit, 1);
    expect(find.textContaining('Edit Rz'), findsNothing);
    expect(find.text('Edit angle'), findsOneWidget);
  });

  testWidgets('Edit angle action remains accessible in compact portrait',
      (tester) async {
    await pumpComposer(
      tester,
      viewportSize: const Size(430, 850),
      placedGate: Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
    );
    await selectFirstGate(tester);
    expect(
        find.byKey(const ValueKey('edit-selected-gate-angle')), findsOneWidget);
    expect(find.bySemanticsLabel('Edit angle'), findsOneWidget);
  });

  testWidgets('selected gate exposes Inspect and opens educational dialog',
      (tester) async {
    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
    );
    expect(find.byKey(const ValueKey('inspect-selected-gate')), findsNothing);
    await selectFirstGate(tester);
    final inspect = find.byKey(const ValueKey('inspect-selected-gate'));
    expect(inspect, findsOneWidget);
    expect(
      find.descendant(
        of: inspect,
        matching: find.byIcon(Icons.info_outline_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: inspect, matching: find.byIcon(Icons.school_outlined)),
      findsNothing,
    );
    expect(find.byTooltip('Inspect gate'), findsOneWidget);
    expect(
      find.ancestor(
        of: inspect,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Inspect gate',
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(inspect);
    await tester.pumpAndSettle();
    expect(find.text('Hadamard gate'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('gate-inspector-content')), findsOneWidget);
    expect(find.text('Open Notebook'), findsOneWidget);
  });

  testWidgets('selection exposes replacement actions only for editable singles',
      (tester) async {
    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
      palette: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.x),
      ],
    );
    expect(find.byKey(const ValueKey('replace-selected-gate')), findsNothing);
    await selectFirstGate(tester);
    expect(find.byKey(const ValueKey('replace-selected-gate')), findsOneWidget);
    expect(find.text('Edit angle'), findsNothing);

    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
      palette: [
        Gate.fromIdentifier(SelectedGateType.rx),
        Gate.fromIdentifier(SelectedGateType.x),
      ],
    );
    await selectFirstGate(tester);
    expect(find.byKey(const ValueKey('replace-selected-gate')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('edit-selected-gate-angle')), findsOneWidget);

    await pumpComposer(
      tester,
      qubits: 3,
      palette: [Gate.fromIdentifier(SelectedGateType.x)],
      preInsertGates: (circuit) =>
          insertControlledGate(circuit, SelectedGateType.cnot),
    );
    await tester.tapAt(circuitPoint(tester, 0, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey('replace-selected-gate')), findsNothing);

    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
      isDeletable: false,
      palette: [Gate.fromIdentifier(SelectedGateType.x)],
    );
    await selectFirstGate(tester);
    expect(find.byKey(const ValueKey('replace-selected-gate')), findsNothing);
  });

  testWidgets('replacement picker contains only permitted single gates',
      (tester) async {
    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
      palette: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.x),
        Gate.fromIdentifier(SelectedGateType.rx),
        Gate.fromIdentifier(SelectedGateType.cnot),
      ],
    );
    await selectFirstGate(tester);
    await tester.tap(find.byKey(const ValueKey('replace-selected-gate')));
    await tester.pumpAndSettle();
    expect(find.text('Replace gate'), findsOneWidget);
    expect(find.byKey(const ValueKey('replacement-gate-x')), findsOneWidget);
    expect(find.byKey(const ValueKey('replacement-gate-rx')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('replacement-gate-hadamard')), findsNothing);
    expect(find.byKey(const ValueKey('replacement-gate-cnot')), findsNothing);
    expect(find.byKey(const ValueKey('replacement-gate-z')), findsNothing);
  });

  testWidgets('H to X replaces atomically, simulates once, and keeps selection',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
      palette: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.x),
      ],
    );
    final id = model.placedGates[0][0].id!;
    await selectFirstGate(tester);
    final simulationsBefore = model.simulationRunCount;
    var notifications = 0;
    model.addListener(() => notifications++);
    await tester.tap(find.byKey(const ValueKey('replace-selected-gate')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('replacement-gate-x')));
    await tester.pumpAndSettle();

    final replacement = model.logicalGateById(id)!;
    expect(replacement.type, SelectedGateType.x);
    expect(replacement.id, id);
    expect(model.simulationRunCount, simulationsBefore + 1);
    expect(notifications, 2); // structural edit and simulation result
    expect(find.bySemanticsLabel('Selected gate X'), findsOneWidget);
  });

  testWidgets('rotation replacement requires an explicit angle and can cancel',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
      palette: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.rx),
      ],
    );
    final id = model.placedGates[0][0].id!;
    await selectFirstGate(tester);
    final simulationsBefore = model.simulationRunCount;

    await tester.tap(find.byKey(const ValueKey('replace-selected-gate')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('replacement-gate-rx')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rx Angle'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(model.logicalGateById(id)!.type, SelectedGateType.hadamard);
    expect(model.simulationRunCount, simulationsBefore);

    await tester.tap(find.byKey(const ValueKey('replace-selected-gate')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('replacement-gate-rx')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('fractional-angle-denominator')), '2');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    final replacement = model.logicalGateById(id)!;
    expect(replacement.type, SelectedGateType.rx);
    expect(replacement.gate.angle, closeTo(math.pi / 2, 1e-12));
    expect(replacement.id, id);
    expect(
        find.byKey(const ValueKey('edit-selected-gate-angle')), findsOneWidget);
  });

  testWidgets('rotation-to-rotation replacement does not carry old angle',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 2),
      palette: [
        Gate.fromIdentifier(SelectedGateType.rx),
        Gate.fromIdentifier(SelectedGateType.ry),
      ],
    );
    final id = model.placedGates[0][0].id!;
    await selectFirstGate(tester);
    await tester.tap(find.byKey(const ValueKey('replace-selected-gate')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('replacement-gate-ry')));
    await tester.pumpAndSettle();
    final denominator = tester.widget<TextField>(
      find.byKey(const ValueKey('fractional-angle-denominator')),
    );
    expect(denominator.controller!.text, '1');
    await tester.enterText(
        find.byKey(const ValueKey('fractional-angle-denominator')), '4');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(model.logicalGateById(id)!.type, SelectedGateType.ry);
    expect(model.logicalGateById(id)!.gate.angle, closeTo(math.pi / 4, 1e-12));
  });

  testWidgets('replacement composes with angle edit, move, and deletion',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
      palette: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.rx),
      ],
    );
    final id = model.placedGates[0][0].id!;
    await selectFirstGate(tester);

    var simulations = model.simulationRunCount;
    await tester.tap(find.byKey(const ValueKey('replace-selected-gate')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('replacement-gate-rx')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('fractional-angle-denominator')), '2');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(model.simulationRunCount, ++simulations);
    expect(model.logicalGateById(id)!.id, id);
    expect(model.logicalGateById(id)!.gate.angle, closeTo(math.pi / 2, 1e-12));

    await tester.tap(find.byKey(const ValueKey('edit-selected-gate-angle')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('fractional-angle-denominator')), '4');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(model.simulationRunCount, ++simulations);
    expect(model.logicalGateById(id)!.id, id);
    expect(model.logicalGateById(id)!.gate.angle, closeTo(math.pi / 4, 1e-12));

    final move = await tester.startGesture(circuitPoint(tester, 0, 0));
    await move.moveTo(circuitPoint(tester, 1, 1));
    await move.up();
    await tester.pumpAndSettle();
    expect(model.simulationRunCount, ++simulations);
    expect(model.logicalGateById(id)!.id, id);
    expect(model.logicalGateById(id)!.anchor.qubit, 1);
    expect(model.logicalGateById(id)!.gate.angle, closeTo(math.pi / 4, 1e-12));

    final surface = circuitSurfaceRect(tester);
    final deletion = await tester.startGesture(circuitPoint(tester, 1, 0));
    final outside = surface.bottomRight + const Offset(90, 90);
    await deletion.moveTo(outside + const Offset(1, 0));
    await deletion.moveTo(outside);
    await tester.pump();
    expect(find.byKey(const ValueKey('release-to-remove')), findsOneWidget);
    await deletion.up();
    await tester.pumpAndSettle();
    expect(model.simulationRunCount, ++simulations);
    expect(model.logicalGateById(id), isNull);
    expect(
        find.byKey(const ValueKey('edit-selected-gate-angle')), findsNothing);
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

  testWidgets('Duplicate is contextual and respects editability policy',
      (tester) async {
    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
      palette: [Gate.fromIdentifier(SelectedGateType.hadamard)],
    );
    expect(find.byKey(const ValueKey('duplicate-selected-gate')), findsNothing);
    await selectFirstGate(tester);
    expect(
        find.byKey(const ValueKey('duplicate-selected-gate')), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);

    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
      palette: [
        Gate.fromIdentifier(SelectedGateType.rx),
        Gate.fromIdentifier(SelectedGateType.x),
      ],
    );
    await selectFirstGate(tester);
    expect(
        find.byKey(const ValueKey('duplicate-selected-gate')), findsOneWidget);
    expect(find.byKey(const ValueKey('replace-selected-gate')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('edit-selected-gate-angle')), findsOneWidget);

    await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
      isDeletable: false,
      palette: [Gate.fromIdentifier(SelectedGateType.hadamard)],
    );
    await selectFirstGate(tester);
    expect(find.byKey(const ValueKey('duplicate-selected-gate')), findsNothing);
  });

  testWidgets('Duplicate H selects new copy and commits/simulates once',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.hadamard),
      palette: [
        Gate.fromIdentifier(SelectedGateType.hadamard),
        Gate.fromIdentifier(SelectedGateType.x),
      ],
    );
    final sourceId = model.placedGates[0][0].id!;
    await selectFirstGate(tester);
    final simulationsBefore = model.simulationRunCount;
    var notifications = 0;
    model.addListener(() => notifications++);

    await tester.tap(find.byKey(const ValueKey('duplicate-selected-gate')));
    await tester.pumpAndSettle();

    expect(model.logicalGates, hasLength(2));
    final duplicate = model.logicalGates.singleWhere(
      (gate) => gate.id != sourceId,
    );
    expect(duplicate.type, SelectedGateType.hadamard);
    expect(duplicate.column, 1);
    expect(model.simulationRunCount, simulationsBefore + 1);
    expect(notifications, 2); // one structural and one simulation notification
    expect(find.bySemanticsLabel('Selected gate H'), findsOneWidget);

    final gesture = await tester.startGesture(circuitPoint(tester, 0, 1));
    await gesture.moveTo(circuitPoint(tester, 1, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(model.logicalGateById(duplicate.id)!.anchor.qubit, 1);
  });

  testWidgets('rotation duplicate keeps angle and can be edited independently',
      (tester) async {
    final model = await pumpComposer(
      tester,
      placedGate: Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
      palette: [
        Gate.fromIdentifier(SelectedGateType.rx),
        Gate.fromIdentifier(SelectedGateType.x),
      ],
    );
    final sourceId = model.placedGates[0][0].id!;
    await selectFirstGate(tester);
    await tester.tap(find.byKey(const ValueKey('duplicate-selected-gate')));
    await tester.pumpAndSettle();
    final duplicate = model.logicalGates.singleWhere(
      (gate) => gate.id != sourceId,
    );
    expect(duplicate.gate.angle, math.pi / 4);
    expect(find.text('Select Rotation Angle'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('edit-selected-gate-angle')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('fractional-angle-denominator')), '2');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(model.logicalGateById(sourceId)!.gate.angle, math.pi / 4);
    expect(model.logicalGateById(duplicate.id)!.gate.angle, math.pi / 2);
  });

  for (final type in [
    SelectedGateType.cnot,
    SelectedGateType.cz,
    SelectedGateType.ccnot,
  ]) {
    testWidgets('selected $type exposes Duplicate and copies full footprint',
        (tester) async {
      final model = await pumpComposer(
        tester,
        qubits: 3,
        palette: [Gate.fromIdentifier(type)],
        preInsertGates: (circuit) => insertControlledGate(circuit, type),
      );
      final sourceId = model.logicalGates.single.id;
      await tester.tapAt(circuitPoint(tester, 0, 0));
      await tester.pump();
      expect(find.byKey(const ValueKey('duplicate-selected-gate')),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('duplicate-selected-gate')));
      await tester.pumpAndSettle();
      final duplicate = model.logicalGates.singleWhere(
        (gate) => gate.id != sourceId,
      );
      expect(duplicate.fragments,
          hasLength(model.logicalGateById(sourceId)!.fragments.length));
      expect(duplicate.fragments.map((part) => part.placedGate.id).toSet(),
          {duplicate.id});
      expect(find.bySemanticsLabel('Selected gate ${duplicate.gate.label}'),
          findsWidgets);
    });
  }

  testWidgets('Duplicate action remains layout-safe in portrait and landscape',
      (tester) async {
    for (final viewport in const [Size(430, 850), Size(900, 500)]) {
      await pumpComposer(
        tester,
        viewportSize: viewport,
        placedGate:
            Gate.fromIdentifier(SelectedGateType.rx, angle: math.pi / 4),
        palette: [
          Gate.fromIdentifier(SelectedGateType.rx),
          Gate.fromIdentifier(SelectedGateType.x),
        ],
      );
      await selectFirstGate(tester);
      expect(find.byKey(const ValueKey('duplicate-selected-gate')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
