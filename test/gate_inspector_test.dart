import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/widgets/latex_text.dart';

LogicalGateFootprint footprint(
  SelectedGateType type, {
  double? angle,
  int? control,
  int? secondControl,
  int? target,
}) {
  const id = GateId(1);
  final gate = Gate.fromIdentifier(type, angle: angle);
  final anchorQubit = target ?? 0;
  final placed = PlacedQuantumGate(
    id: id,
    gate: gate,
    controlQubitIndex: control,
    control2QubitIndex: secondControl,
    targetQubitIndex: target,
    isTarget: target != null,
  );
  return LogicalGateFootprint(
    id: id,
    gate: gate,
    fragments: [
      LogicalGateFragment(
        location: CircuitLocation(qubit: anchorQubit, column: 0),
        placedGate: placed,
      ),
    ],
    anchor: CircuitLocation(qubit: anchorQubit, column: 0),
    controlQubit: control,
    secondControlQubit: secondControl,
    targetQubit: target,
    isDeletable: true,
  );
}

void main() {
  test('all production gate types have educational metadata', () {
    expect(GateEducationalCatalog.productionGateTypes, hasLength(12));
    for (final type in GateEducationalCatalog.productionGateTypes) {
      final info = GateEducationalCatalog.forType(type);
      expect(info, isNotNull, reason: type.name);
      expect(info!.type, type);
      expect(info.name, isNotEmpty);
      expect(info.intuition, isNotEmpty);
      expect(info.matrix, isNotEmpty);
      expect(info.properties, isNotEmpty);
      expect(info.relatedConcepts, isNotEmpty);
      expect(info.visual.kind, isNotNull);
    }
    for (final sentinel in [
      SelectedGateType.none,
      SelectedGateType.delete,
      SelectedGateType.draggedGate,
    ]) {
      expect(GateEducationalCatalog.forType(sentinel), isNull);
    }
  });

  testWidgets('Hadamard dialog renders educational metadata', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GateInspectorDialog(
        footprint: footprint(SelectedGateType.hadamard),
        info: GateEducationalCatalog.forType(SelectedGateType.hadamard),
      ),
    ));

    expect(find.text('Hadamard gate'), findsOneWidget);
    expect(find.byKey(const ValueKey('gate-inspector-summary-card')),
        findsOneWidget);
    expect(find.byType(LatexText), findsWidgets);
    await tester.ensureVisible(find.text('Mathematical definition'));
    await tester.tap(find.text('Mathematical definition'));
    await tester.pump();
    expect(find.byKey(const ValueKey('gate-inspector-matrix-latex')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('gate-inspector-visual-slot')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('gate-inspector-static-visual')),
        findsOneWidget);
  });

  testWidgets('Inspector uses primary secondary and tertiary math hierarchy',
      (tester) async {
    final selectedFootprint = footprint(SelectedGateType.hadamard);
    await tester.pumpWidget(MaterialApp(
      home: GateInspectorDialog(
        footprint: selectedFootprint,
        info: GateEducationalCatalog.forType(SelectedGateType.hadamard),
      ),
    ));

    final stateMath = tester.widget<LatexText>(
        find.byKey(const ValueKey('gate-inspector-state-math-0')));
    final identityMath = tester.widget<LatexText>(
        find.byKey(const ValueKey('gate-inspector-identity-math-0')));
    final matrix = find.byKey(const ValueKey('gate-inspector-matrix'));
    await tester.ensureVisible(matrix);
    await tester.tap(matrix);
    await tester.pumpAndSettle();
    final matrixMath = tester.widget<LatexText>(
        find.byKey(const ValueKey('gate-inspector-matrix-latex')));

    expect(
        matrixMath.displayMathHeight, greaterThan(stateMath.displayMathHeight));
    expect(stateMath.displayMathHeight,
        greaterThan(identityMath.displayMathHeight));
    expect(identityMath.inlineMathHeight, lessThan(stateMath.inlineMathHeight));
  });

  testWidgets('rotation shows configured angle and axis', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GateInspectorDialog(
        footprint: footprint(SelectedGateType.rx, angle: math.pi / 4),
        info: GateEducationalCatalog.forType(SelectedGateType.rx),
      ),
    ));

    expect(find.textContaining('Configured angle: Rx 1/4π'), findsOneWidget);
    expect(find.textContaining('Axis: X'), findsOneWidget);
  });

  testWidgets('fixed gate visual does not repeat axis below illustration',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GateInspectorDialog(
        footprint: footprint(SelectedGateType.z),
        info: GateEducationalCatalog.forType(SelectedGateType.z),
      ),
    ));

    expect(find.textContaining('Axis:'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'π rotation about the Z axis')),
        findsOneWidget);
  });

  test('fixed rotation visual metadata uses canonical angles', () {
    final x = GateEducationalCatalog.forType(SelectedGateType.x)!.visual;
    final s = GateEducationalCatalog.forType(SelectedGateType.s)!.visual;
    final t = GateEducationalCatalog.forType(SelectedGateType.t)!.visual;
    expect(x.rotationRadians, closeTo(math.pi, 1e-12));
    expect(s.rotationRadians, closeTo(math.pi / 2, 1e-12));
    expect(t.rotationRadians, closeTo(math.pi / 4, 1e-12));
    expect(x.axisLabel, 'X');
    expect(s.axisLabel, 'Z');
    expect(t.axisLabel, 'Z');
  });

  test('controlled gates retain non-Bloch visual kinds', () {
    expect(
      GateEducationalCatalog.forType(SelectedGateType.cnot)!.visual.kind,
      GateEducationalVisualKind.controlledX,
    );
    expect(
      GateEducationalCatalog.forType(SelectedGateType.cz)!.visual.kind,
      GateEducationalVisualKind.controlledPhase,
    );
    expect(
      GateEducationalCatalog.forType(SelectedGateType.ccnot)!.visual.kind,
      GateEducationalVisualKind.multiControlledX,
    );
  });

  testWidgets('controlled dialog shows roles and notebook link',
      (tester) async {
    var notebookOpened = false;
    await tester.pumpWidget(MaterialApp(
      home: GateInspectorDialog(
        footprint: footprint(
          SelectedGateType.cnot,
          control: 0,
          target: 2,
        ),
        info: GateEducationalCatalog.forType(SelectedGateType.cnot),
        onOpenNotebook: () => notebookOpened = true,
      ),
    ));

    expect(find.textContaining('Control: Q0'), findsOneWidget);
    expect(find.textContaining('Target: Q2'), findsOneWidget);
    expect(find.text('Why one Bloch sphere is not enough'), findsOneWidget);
    expect(find.text('Open Notebook'), findsOneWidget);
    await tester.tap(find.text('Open Notebook'));
    expect(notebookOpened, isTrue);
  });

  testWidgets('related concepts optionally open existing Notebook content',
      (tester) async {
    String? opened;
    await tester.pumpWidget(MaterialApp(
      home: GateInspectorDialog(
        footprint: footprint(SelectedGateType.hadamard),
        info: GateEducationalCatalog.forType(SelectedGateType.hadamard),
        onOpenRelatedConcept: (title) => opened = title,
      ),
    ));

    final chip = find.byKey(const ValueKey('gate-concept-Superposition'));
    expect(chip, findsOneWidget);
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    expect(opened, 'Superposition');
  });

  testWidgets('empty optional sections are hidden', (tester) async {
    const sparse = GateEducationalInfo(
      type: SelectedGateType.x,
      name: 'Sparse gate',
      intuition: 'Short summary.',
      physicalChange: '',
      commonUse: '',
      transformations: [],
      matrix: '',
      properties: [],
      identities: [],
      relatedConcepts: [],
      visual: GateEducationalVisual(
        kind: GateEducationalVisualKind.staticGate,
      ),
    );
    await tester.pumpWidget(MaterialApp(
      home: GateInspectorDialog(
        footprint: footprint(SelectedGateType.x),
        info: sparse,
      ),
    ));

    expect(find.text('State action'), findsNothing);
    expect(find.text('Mathematical definition'), findsNothing);
    expect(find.text('Properties'), findsNothing);
    expect(find.text('Important identities'), findsNothing);
    expect(find.text('Related concepts'), findsNothing);
    expect(find.text('Open Notebook'), findsNothing);
  });

  testWidgets('dialog remains usable in compact landscape', (tester) async {
    tester.view.physicalSize = const Size(720, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: GateInspectorDialog(
        footprint: footprint(SelectedGateType.ccnot,
            control: 0, secondControl: 1, target: 2),
        info: GateEducationalCatalog.forType(SelectedGateType.ccnot),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('visual is accessible and large text remains scrollable',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(2),
        ),
        child: child!,
      ),
      home: GateInspectorDialog(
        footprint: footprint(SelectedGateType.rx, angle: math.pi / 4),
        info: GateEducationalCatalog.forType(SelectedGateType.rx),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(RegExp(r'rotation about the X axis')),
        findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('unsupported gate degrades gracefully', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GateInspectorDialog(
        footprint: footprint(SelectedGateType.none),
        info: null,
      ),
    ));

    expect(find.byKey(const ValueKey('gate-inspector-unsupported')),
        findsOneWidget);
    expect(find.textContaining('not available'), findsOneWidget);
  });
}
