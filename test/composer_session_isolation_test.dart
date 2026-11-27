// v2.6 M2 (D11): the Sandbox and the active Notebook example are separate
// Composer sessions in the web shell.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/screens/web_exercise_workspace.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';
import 'support/laboratory_composer_finders.dart';

class _KeyedStorage extends InMemoryAppStorage {
  final List<String> writtenKeys = [];
  @override
  Future<void> writeString(String key, String value) {
    writtenKeys.add(key);
    return super.writeString(key, value);
  }
}

ComposerCircuitCanvas _canvas(WidgetTester tester) =>
    tester.widget<ComposerCircuitCanvas>(find.byType(ComposerCircuitCanvas));

Future<void> _drop(
  WidgetTester tester,
  SelectedGateType type,
  int qubit,
  int column,
) async {
  await _canvas(tester).onDropRequested(
    ComposerCircuitDropIntent(
      data: CircuitDragData.palette(Gate.fromIdentifier(type)),
      destination: CircuitDropDestination(
        contentPoint: Offset.zero,
        location: CircuitLocation(qubit: qubit, column: column),
      ),
    ),
  );
  await tester.pump();
}

List<SelectedGateType> _types(QuantumCircuit circuit) =>
    [for (final gate in circuit.logicalGates) gate.type];

/// Opens the X example as an in-Notebook experiment (v2.6 M6b).
Future<void> _openXExample(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
  await tester.pump();
  final entry = notebookEntries.first;
  final row = find.byKey(ValueKey('web-notebook-entry-${entry.id}'));
  if (row.evaluate().isEmpty) {
    await tester.tap(find.byKey(
        ValueKey('web-notebook-category-chapter-${entry.chapterIndex}')));
    await tester.pumpAndSettle();
  }
  await tester.tap(row);
  await tester.pumpAndSettle();
  final explore = find.byKey(const ValueKey('notebook-explore-x_from_zero'));
  await tester.ensureVisible(explore);
  await tester.pumpAndSettle();
  await tester.tap(explore);
  await tester.pumpAndSettle();
}

/// The experiment's canvas (the Sandbox's canvas is in another destination).
QuantumCircuit _experimentCircuit(WidgetTester tester) => tester
    .widget<ComposerCircuitCanvas>(find.descendant(
        of: find.byKey(const ValueKey('notebook-experiment-workspace')),
        matching: find.byType(ComposerCircuitCanvas)))
    .circuit;

void main() {
  // These tests cover the classic Composer layout (lessons, Mastery and
  // Notebook examples until M11D) through the Sandbox host (v2.6 M11C).
  setUpAll(() => debugClassicSandboxLayout = true);
  tearDownAll(() => debugClassicSandboxLayout = false);
  testWidgets(
      'Notebook examples never overwrite, edit or save the Sandbox session',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.reset);
    final storage = _KeyedStorage();
    await tester.pumpWidget(QubitQuestWebApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await CampaignProgressController.instance
        .unlockDiscovery(notebookEntries.first.discoveryTitle);
    await tester.pump();

    // Sandbox: 2 qubits with H on q1.
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-2')));
    await tester.pumpAndSettle();
    await _drop(tester, SelectedGateType.hadamard, 1, 0);
    await tester.pumpAndSettle();
    final sandbox = _canvas(tester).circuit;
    expect(_types(sandbox), [SelectedGateType.hadamard]);

    // Open the X example: a different session with its own circuit.
    await _openXExample(tester);
    expect(find.byKey(const ValueKey('notebook-experiment-title')),
        findsOneWidget);
    final example = _experimentCircuit(tester);
    expect(identical(example, sandbox), isFalse);
    final exampleStart = _types(example);

    final sandboxWritesBefore =
        storage.writtenKeys.where((k) => k.startsWith('sandbox')).length;
    final experimentCanvas = tester.widget<ComposerCircuitCanvas>(
        find.descendant(
            of: find.byKey(const ValueKey('notebook-experiment-workspace')),
            matching: find.byType(ComposerCircuitCanvas)));
    await experimentCanvas.onDropRequested(ComposerCircuitDropIntent(
      data: CircuitDragData.palette(Gate.fromIdentifier(SelectedGateType.x)),
      destination: const CircuitDropDestination(
        contentPoint: Offset.zero,
        location: CircuitLocation(qubit: 0, column: 3),
      ),
    ));
    await tester.pumpAndSettle();
    expect(_types(example), hasLength(exampleStart.length + 1));
    expect(
      storage.writtenKeys.where((k) => k.startsWith('sandbox')).length,
      sandboxWritesBefore,
      reason: 'Notebook edits never write Sandbox storage',
    );
    expect(_types(sandbox), [SelectedGateType.hadamard]);

    // Back to the Sandbox: the same circuit, no qubit chooser.
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    expect(find.text('Choose Number of Qubits'), findsNothing);
    expect(identical(_canvas(tester).circuit, sandbox), isTrue);
    expect(_types(sandbox), [SelectedGateType.hadamard]);

    // Reopening the example starts from its original circuit.
    await tester.tap(find.byKey(const ValueKey('web-nav-notebook')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notebook-experiment-back')));
    await tester.pumpAndSettle();
    await _openXExample(tester);
    final reopened = _experimentCircuit(tester);
    expect(identical(reopened, example), isFalse);
    expect(_types(reopened), exampleStart);
  });

  ComposerLevel lessonLevel({bool fixedX = false}) => ComposerLevel(
        title: 'Parity lesson',
        taskDescription: 'Parity.',
        numQubits: 2,
        initialQubitsStateStr: '00',
        initialQubitsState: ComposerLevel.getZeroStateVector(2),
        availableGates: [
          Gate.fromIdentifier(SelectedGateType.hadamard),
          Gate.fromIdentifier(SelectedGateType.cnot),
          Gate.fromIdentifier(SelectedGateType.x),
        ],
        solutionFinalVector: ComposerLevel.getOneStateVector(2)
            .map((amplitude) => [amplitude])
            .toList(),
        preInsertedGates: fixedX
            ? (circuit) => circuit.insertSinglePlacedGateAt(
                  Gate.fromIdentifier(SelectedGateType.x),
                  0,
                  0,
                  isDeletable: false,
                )
            : null,
      );

  Future<void> pumpLesson(WidgetTester tester, ComposerLevel level) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WebComposerExercise(
          level: level,
          mode: ComposerMode.journeyExercise,
          contextLabel: 'Lesson',
          onCompleted: () async {},
          onNext: () {},
          onOpenNotebook: () {},
        ),
      ),
    ));
    await tester.pump();
  }

  Future<void> buildParityCircuit(WidgetTester tester) async {
    await _drop(tester, SelectedGateType.hadamard, 0, 0);
    await _drop(tester, SelectedGateType.cnot, 1, 1); // only control: q0
    await tester.pumpAndSettle();
    await _drop(tester, SelectedGateType.x, 1, 0);
    await tester.pumpAndSettle();
  }

  testWidgets('both web hosts build identical circuits from identical drops',
      (tester) async {
    await pumpLesson(tester, lessonLevel());
    await buildParityCircuit(tester);
    final lesson =
        SandboxProgramSnapshot.capture(_canvas(tester).circuit).toJson();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(QubitQuestWebApp(storage: InMemoryAppStorage()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('web-nav-composer')));
    await tester.pump();
    await pumpUntilSandboxOpen(tester);
    await tester.tap(find.byKey(const ValueKey('web-composer-qubits-2')));
    await tester.pumpAndSettle();
    await buildParityCircuit(tester);
    final sandbox =
        SandboxProgramSnapshot.capture(_canvas(tester).circuit).toJson();

    // Full schema-2 operation records: IDs, columns, types, roles, angles.
    expect(sandbox['operations'], lesson['operations']);
    expect(sandbox['operations'] as List, hasLength(3));
    expect(sandbox['initialState'], lesson['initialState']);
  });

  testWidgets('lesson Reset restores fixed gates and clears learner gates',
      (tester) async {
    await pumpLesson(tester, lessonLevel(fixedX: true));
    final circuit = _canvas(tester).circuit;
    final fixed = circuit.logicalGates.single;
    await _drop(tester, SelectedGateType.hadamard, 1, 0);
    expect(circuit.logicalGates, hasLength(2));
    // M6a: Reset is the shared toolbar's clear action, worded for exercises.
    final reset = find.byKey(const ValueKey('web-clear-circuit'));
    expect(find.descendant(of: reset, matching: find.text('Reset')),
        findsOneWidget);
    await tester.tap(reset);
    await tester.pump();
    final remaining = _canvas(tester).circuit.logicalGates.single;
    expect(remaining.isDeletable, isFalse);
    expect(remaining.type, fixed.type);
    expect(remaining.anchor, fixed.anchor);
  });
}
