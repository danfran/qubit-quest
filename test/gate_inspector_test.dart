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
import 'package:quantumquiz/widgets/gate_inspector_theme.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/native_math_text.dart';

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

LogicalGateFootprint _productionFootprint(SelectedGateType type) =>
    switch (type) {
      SelectedGateType.rx ||
      SelectedGateType.ry ||
      SelectedGateType.rz =>
        footprint(type, angle: math.pi / 4),
      SelectedGateType.cnot ||
      SelectedGateType.cz =>
        footprint(type, control: 0, target: 1),
      SelectedGateType.ccnot =>
        footprint(type, control: 0, secondControl: 1, target: 2),
      _ => footprint(type),
    };

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
    expect(
      find.bySemanticsLabel(
          'Hadamard changes a basis state into superposition'),
      findsOneWidget,
    );
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

    final stateMath = tester.widget<NativeMathText>(find.descendant(
      of: find.byKey(const ValueKey('gate-inspector-state-math-0')),
      matching: find.byType(NativeMathText),
    ));
    final identityMath = tester.widget<NativeMathText>(find.descendant(
      of: find.byKey(const ValueKey('gate-inspector-identity-math-0')),
      matching: find.byType(NativeMathText),
    ));
    final matrix = find.byKey(const ValueKey('gate-inspector-matrix'));
    await tester.ensureVisible(matrix);
    await tester.tap(matrix);
    await tester.pumpAndSettle();
    final matrixMath = tester.widget<LatexText>(
        find.byKey(const ValueKey('gate-inspector-matrix-latex')));

    expect(matrixMath.textStyle, GateInspectorTheme.mathPrimary);
    expect(matrixMath.displayMathHeight,
        GateInspectorTheme.mathPrimaryDisplayHeight);
    expect(stateMath.style, GateInspectorTheme.mathSecondary);
    expect(identityMath.style, GateInspectorTheme.mathTertiary);
    expect(identityMath.style.fontSize,
        lessThan(GateInspectorTheme.body.fontSize!));
  });

  testWidgets('all production gates inherit shared Inspector math styles',
      (tester) async {
    for (final type in GateEducationalCatalog.productionGateTypes) {
      final info = GateEducationalCatalog.forType(type)!;
      await tester.pumpWidget(MaterialApp(
        home: GateInspectorDialog(
          footprint: _productionFootprint(type),
          info: info,
        ),
      ));
      await tester.pump();

      final title = tester.widget<Text>(find.text(info.name));
      expect(title.style, GateInspectorTheme.title, reason: type.name);
      if (info.transformations.isNotEmpty) {
        final container =
            find.byKey(const ValueKey('gate-inspector-state-math-0'));
        if (NativeMathText.supports(info.transformations.first)) {
          final finder = find.descendant(
              of: container, matching: find.byType(NativeMathText));
          expect(tester.widget<NativeMathText>(finder).style,
              GateInspectorTheme.mathSecondary,
              reason: type.name);
        } else {
          final finder =
              find.descendant(of: container, matching: find.byType(LatexText));
          expect(tester.widget<LatexText>(finder).textStyle,
              GateInspectorTheme.mathSecondary,
              reason: type.name);
        }
      }
      if (info.identities.isNotEmpty) {
        final container =
            find.byKey(const ValueKey('gate-inspector-identity-math-0'));
        if (NativeMathText.supports(info.identities.first)) {
          final finder = find.descendant(
              of: container, matching: find.byType(NativeMathText));
          expect(tester.widget<NativeMathText>(finder).style,
              GateInspectorTheme.mathTertiary,
              reason: type.name);
        } else {
          final finder =
              find.descendant(of: container, matching: find.byType(LatexText));
          expect(tester.widget<LatexText>(finder).textStyle,
              GateInspectorTheme.mathTertiary,
              reason: type.name);
        }
      }
      expect(tester.takeException(), isNull, reason: type.name);
    }
  });

  testWidgets('all production dialogs remain usable at supported text scales',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final scale in [1.0, 1.5, 2.0]) {
      for (final type in GateEducationalCatalog.productionGateTypes) {
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: GateInspectorDialog(
            footprint: _productionFootprint(type),
            info: GateEducationalCatalog.forType(type),
          ),
        ));
        await tester.pump();
        expect(find.byType(SingleChildScrollView), findsWidgets,
            reason: '${type.name} at ${scale}x');
        expect(tester.takeException(), isNull,
            reason: '${type.name} at ${scale}x');
      }
    }
  });

  testWidgets('long identity lists use tertiary style and wrap in scroll view',
      (tester) async {
    final base = GateEducationalCatalog.forType(SelectedGateType.x)!;
    final longInfo = GateEducationalInfo(
      type: base.type,
      name: base.name,
      intuition: base.intuition,
      physicalChange: base.physicalChange,
      commonUse: base.commonUse,
      transformations: base.transformations,
      matrix: base.matrix,
      properties: base.properties,
      identities: List.generate(12,
          (index) => r'\(X^{2}=I\) — supporting relation number ${index + 1}'),
      relatedConcepts: base.relatedConcepts,
      visual: base.visual,
    );
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: GateInspectorDialog(
        footprint: footprint(SelectedGateType.x),
        info: longInfo,
      ),
    ));

    expect(find.byKey(const ValueKey('gate-inspector-identity-math-11')),
        findsOneWidget);
    final last = tester.widget<NativeMathText>(find.descendant(
      of: find.byKey(const ValueKey('gate-inspector-identity-math-11')),
      matching: find.byType(NativeMathText),
    ));
    expect(last.style, GateInspectorTheme.mathTertiary);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
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
