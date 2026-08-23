import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/executable_notebook_catalog.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/screens/bloch_explorer_screen.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/widgets/executable_notebook_example_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Executable Notebook corpus contract', () {
    test('every discovered example is unique, valid, executable and normalized',
        () {
      expect(executableNotebookExamples, hasLength(7));
      final ids = <String>{};
      for (final example in executableNotebookExamples) {
        expect(ids.add(example.id), isTrue, reason: example.id);
        expect(example.validate(), isEmpty, reason: example.id);
        final result = example.execute();
        expect(result.circuit.lastSimulationError, isNull, reason: example.id);
        final norm = result.state.fold<double>(
          0,
          (sum, amplitude) => sum + amplitude.magnitude * amplitude.magnitude,
        );
        expect(norm, closeTo(1, 1e-9), reason: example.id);
        expect(example.resultMatchesExpected(result.state), isTrue,
            reason: example.id);
        for (final footprint in result.circuit.logicalGates) {
          expect(footprint.hasValidTopology(example.qubitCount), isTrue,
              reason: example.id);
        }
      }
    });

    test('Notebook content references every example exactly once', () {
      final referencedIds = notebookEntries
          .expand((entry) => entry.executableExampleIds)
          .toList(growable: false);
      expect(
          referencedIds.toSet(), executableNotebookExamplesById.keys.toSet());
      expect(referencedIds, hasLength(referencedIds.toSet().length));
    });

    test('Composer handoff is an editable, semantically lossless copy', () {
      for (final example in executableNotebookExamples) {
        final direct = example.execute();
        final composerLevel = example.createEditableComposerLevel();
        final handedOff = ExecutableNotebookResult(
          circuit: _buildComposerCircuit(composerLevel),
        );
        expect(handedOff.state, hasLength(direct.state.length));
        for (var index = 0; index < direct.state.length; index++) {
          expect(handedOff.state[index].real,
              closeTo(direct.state[index].real, 1e-9),
              reason: '${example.id} amplitude $index');
          expect(handedOff.state[index].imaginary,
              closeTo(direct.state[index].imaginary, 1e-9),
              reason: '${example.id} amplitude $index');
        }
        expect(handedOff.circuit.logicalGates,
            hasLength(example.operations.length));
        expect(
          handedOff.circuit.logicalGates.map((gate) => gate.id).toSet(),
          hasLength(example.operations.length),
        );
        expect(
          handedOff.circuit.logicalGates.every((gate) => gate.isDeletable),
          isTrue,
          reason: example.id,
        );
      }
    });

    test('single-qubit Bloch handoffs preserve probability and relative phase',
        () {
      for (final example in executableNotebookExamples
          .where((item) => item.allowOpenInBlochExplorer)) {
        final state = example.execute().state;
        final bloch = BlochState.fromAmplitudes(state[0], state[1]);
        expect(bloch.probabilityZero,
            closeTo(state[0].magnitude * state[0].magnitude, 1e-9));
        expect(bloch.probabilityOne,
            closeTo(state[1].magnitude * state[1].magnitude, 1e-9));
        expect(bloch.x * bloch.x + bloch.y * bloch.y + bloch.z * bloch.z,
            closeTo(1, 1e-9));
        final alpha = state[0];
        final beta = state[1];
        final norm =
            alpha.magnitude * alpha.magnitude + beta.magnitude * beta.magnitude;
        final relativeReal =
            alpha.real * beta.real + alpha.imaginary * beta.imaginary;
        final relativeImaginary =
            alpha.real * beta.imaginary - alpha.imaginary * beta.real;
        expect(bloch.x, closeTo(2 * relativeReal / norm, 1e-9));
        expect(bloch.y, closeTo(2 * relativeImaginary / norm, 1e-9));
        expect(
          bloch.z,
          closeTo(
            (alpha.magnitude * alpha.magnitude -
                    beta.magnitude * beta.magnitude) /
                norm,
            1e-9,
          ),
        );
      }
    });

    test('Bell example does not expose an invalid Bloch handoff', () {
      final bell = executableNotebookExamples.singleWhere(
        (example) => example.id == 'bell_phi_plus',
      );
      expect(bell.qubitCount, 2);
      expect(bell.allowOpenInBlochExplorer, isFalse);
    });

    test(
        'all platform presentations derive actions from canonical capabilities',
        () {
      final blochIds = <String>{};
      for (final example in executableNotebookExamples) {
        expect(
          example.capabilities,
          containsAll({
            ExecutableNotebookCapability.run,
            ExecutableNotebookCapability.reset,
          }),
          reason: example.id,
        );
        expect(
          example.supports(ExecutableNotebookCapability.composer),
          example.allowOpenInComposer,
          reason: example.id,
        );
        expect(
          example.supports(ExecutableNotebookCapability.blochExplorer),
          example.allowOpenInBlochExplorer,
          reason: example.id,
        );
        if (example.supports(ExecutableNotebookCapability.blochExplorer)) {
          blochIds.add(example.id);
        }
      }
      expect(
        blochIds,
        {
          'x_from_zero',
          'h_superposition',
          'z_on_plus',
          's_on_plus',
          'ry_rotation',
          'interference_hzh',
        },
      );
    });
  });

  group('Executable Notebook interactions', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    testWidgets('Run shows result and Reset restores ready state',
        (tester) async {
      final example = executableNotebookExamples.first;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ExecutableNotebookExampleView(example: example),
        ),
      ));
      expect(
          find.byKey(ValueKey('result-example-${example.id}')), findsNothing);
      await tester.tap(find.byKey(ValueKey('run-example-${example.id}')));
      await tester.pump();
      expect(
          find.byKey(ValueKey('result-example-${example.id}')), findsOneWidget);
      expect(find.textContaining('|1⟩'), findsWidgets);
      await tester.tap(find.byKey(ValueKey('reset-example-${example.id}')));
      await tester.pump();
      expect(
          find.byKey(ValueKey('result-example-${example.id}')), findsNothing);
    });

    testWidgets('handoff callbacks and Bloch eligibility follow the contract',
        (tester) async {
      final single = executableNotebookExamples.first;
      var composerOpened = false;
      var blochOpened = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ExecutableNotebookExampleView(
            example: single,
            onOpenInComposer: (_) => composerOpened = true,
            onOpenInBlochExplorer: (_, __) => blochOpened = true,
          ),
        ),
      ));
      await tester.tap(find.byKey(ValueKey('composer-example-${single.id}')));
      expect(composerOpened, isTrue);
      expect(find.byKey(ValueKey('bloch-example-${single.id}')), findsNothing);
      await tester.tap(find.byKey(ValueKey('run-example-${single.id}')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('bloch-example-${single.id}')));
      expect(blochOpened, isTrue);
    });

    testWidgets('multiple examples remain isolated and wrap on a phone',
        (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final first = executableNotebookExamples[0];
      final second = executableNotebookExamples[1];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(children: [
            ExecutableNotebookExampleView(example: first),
            ExecutableNotebookExampleView(example: second),
          ]),
        ),
      ));
      await tester.tap(find.byKey(ValueKey('run-example-${first.id}')));
      await tester.pump();
      expect(
          find.byKey(ValueKey('result-example-${first.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('result-example-${second.id}')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Notebook routes an authored example into Composer',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final entry = notebookEntriesByDiscoveryTitle['Information']!;
      await tester.pumpWidget(
        MaterialApp(home: NotebookEntryScreen(entry: entry)),
      );
      await tester.pumpAndSettle();
      final open = find.byKey(const ValueKey('composer-example-x_from_zero'));
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byType(QuantumComposer), findsOneWidget);
    });

    testWidgets('Notebook routes the executed result into Bloch Explorer',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final entry = notebookEntriesByDiscoveryTitle['Information']!;
      await tester.pumpWidget(
        MaterialApp(home: NotebookEntryScreen(entry: entry)),
      );
      await tester.pumpAndSettle();
      final run = find.byKey(const ValueKey('run-example-x_from_zero'));
      await tester.tap(run);
      await tester.pump();
      final open = find.byKey(const ValueKey('bloch-example-x_from_zero'));
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byType(BlochExplorerScreen), findsOneWidget);
    });
  });
}

QuantumCircuit _buildComposerCircuit(ComposerLevel level) {
  final circuit = QuantumCircuit(currentLevel: level);
  circuit.runSimulation();
  return circuit;
}
