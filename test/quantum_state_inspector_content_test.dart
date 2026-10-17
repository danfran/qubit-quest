import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'package:quantumquiz/widgets/quantum_state_inspector_content.dart';
import 'package:quantumquiz/widgets/state_vector_display.dart';
import 'support/mastery_math_test_platform.dart';

void main() {
  useMasteryMathTestPlatform();
  List<Complex> basis(int qubits, int index) => List.generate(
      1 << qubits, (i) => i == index ? Complex.one() : Complex.zero());

  Future<void> pumpContent(
    WidgetTester tester, {
    int qubits = 2,
    List<Complex>? target,
    String? expression,
    bool contentDriven = true,
    bool? filter,
  }) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
      width: 320,
      height: 450,
      child: QuantumStateInspectorContent(
        currentStateVector: basis(qubits, 1),
        numQubits: qubits,
        targetStateVector: target,
        targetStateExpression: expression,
        targetStateLabel: 'Authored goal',
        contentDriven: contentDriven,
        nonZeroOnly: filter ?? defaultNonZeroOnlyForQubitCount(qubits),
        onNonZeroOnlyChanged: (_) {},
      ),
    ))));
    await tester.pumpAndSettle();
  }

  testWidgets('current vector, bit order and authored-only target contract',
      (tester) async {
    for (final target in [null, <Complex>[]]) {
      await pumpContent(tester, target: target, expression: '|11⟩');
      expect(find.text('Current State'), findsOneWidget);
      expect(find.text('Target State'), findsNothing);
      expect(find.text('|01⟩'), findsOneWidget);
      expect(
          tester
              .widget<StateVectorDisplay>(find.byType(StateVectorDisplay))
              .stateVector,
          basis(2, 1));
    }
    final target = basis(2, 3);
    await pumpContent(tester, target: target, expression: '|11⟩');
    final panels = tester
        .widgetList<StateVectorDisplay>(find.byType(StateVectorDisplay))
        .toList();
    expect(panels, hasLength(2));
    expect(panels.last.stateVector, same(target));
    expect(panels.last.stateExpression, '|11⟩');
    expect(panels.last.stateExpressionLabel, 'Authored goal');
    expect(panels.last.showVisibilityControl, isFalse);
    expect(panels.every((panel) => panel.lightweightTypography), isTrue);
    expect(find.text('Target State'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final qubits in [1, 2, 3]) {
    testWidgets('$qubits qubits retain adaptive filter default',
        (tester) async {
      await pumpContent(tester, qubits: qubits);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, qubits >= 3);
      await pumpContent(tester, qubits: qubits, filter: qubits < 3);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, qubits < 3);
    });
  }

  testWidgets(
      'narrow content has no vertical scroller; wide panels scroll within bounds',
      (tester) async {
    await pumpContent(tester, target: basis(2, 0));
    expect(find.byType(Scrollbar), findsNothing);
    expect(
        find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down),
        findsNothing);
    await pumpContent(tester,
        qubits: 5, target: basis(5, 0), contentDriven: false, filter: false);
    expect(find.byType(Scrollbar), findsNWidgets(2));
    final vertical = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    expect(vertical, findsNWidgets(2));
    for (final state in tester.stateList<ScrollableState>(vertical)) {
      expect(state.position.maxScrollExtent, greaterThan(0));
    }
    expect(
        tester.getSize(find.byType(QuantumStateInspectorContent)).height, 450);
    expect(tester.takeException(), isNull);
  });

  for (final mastery in [false, true]) {
    testWidgets(
        '${mastery ? 'Mastery' : 'Journey'} live edits preserve authored target and filter without extra simulations',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1000);
      addTearDown(tester.view.reset);
      final level = mastery
          ? mastery2Catalogue
              .requireBySemanticId('inverse_phase_synthesis')
              .levelDefinition as ComposerLevel
          : getQQLevelById(2)! as ComposerLevel;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: WebComposerLesson(
        level: level,
        enabled: true,
        desktopWorkspace: true,
        onSolved: () async {},
      ))));
      await tester.pumpAndSettle();
      final shared = find.byType(QuantumStateInspectorContent);
      expect(shared, findsOneWidget);
      final canvas = tester
          .widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));
      final initialState = canvas.circuit.currentState.stateVector;
      final runs = canvas.circuit.simulationRunCount;
      final authoredTarget =
          level.solutionFinalVector.map((column) => column.first).toList();
      expect(
          tester
              .widget<QuantumStateInspectorContent>(shared)
              .currentStateVector,
          same(initialState));
      expect(
          tester.widget<QuantumStateInspectorContent>(shared).targetStateVector,
          authoredTarget);
      expect(find.text('Current State'), findsOneWidget);
      expect(find.text('Target State'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(canvas.circuit.simulationRunCount, runs);
      await canvas.onDropRequested(ComposerCircuitDropIntent(
        data: CircuitDragData.palette(Gate.fromIdentifier(
            mastery ? SelectedGateType.hadamard : SelectedGateType.x)),
        destination: const CircuitDropDestination(
            contentPoint: Offset(80, 20),
            location: CircuitLocation(qubit: 0, column: 1)),
      ));
      await tester.pumpAndSettle();
      final content = tester.widget<QuantumStateInspectorContent>(shared);
      expect(content.currentStateVector,
          same(canvas.circuit.currentState.stateVector));
      expect(content.currentStateVector, isNot(initialState));
      expect(content.targetStateVector, authoredTarget);
      expect(content.targetStateExpression, level.targetStateExpression);
      expect(canvas.circuit.simulationRunCount, runs + 1);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await tester.tap(find.text('Bloch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('State'));
      await tester.pumpAndSettle();
      expect(
          tester.widget<QuantumStateInspectorContent>(shared).targetStateVector,
          authoredTarget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(canvas.circuit.simulationRunCount, runs + 1);
      expect(tester.takeException(), isNull);
    });
  }
}
