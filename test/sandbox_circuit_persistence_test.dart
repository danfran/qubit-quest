import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  QuantumCircuit circuit(int qubits) => QuantumCircuit(
        currentLevel: createSandboxComposerLevel(qubits),
      );

  void insertSingle(
    QuantumCircuit value,
    SelectedGateType type,
    int column,
    int target, {
    double? angle,
  }) {
    expect(
      value
          .insertSingleGateWithOutcome(
            Gate.fromIdentifier(type, angle: angle),
            column,
            target,
          )
          .changed,
      isTrue,
    );
  }

  void expectEquivalent(QuantumCircuit original, QuantumCircuit restored) {
    final before = SandboxCircuitSnapshot.capture(original);
    final after = SandboxCircuitSnapshot.capture(restored);
    expect(after.toJson(), before.toJson());
    original.runSimulation();
    restored.runSimulation();
    expect(restored.lastSimulationError, isNull);
    expect(
      restored.currentState.state.almostEqualTo(original.currentState.state),
      isTrue,
    );
    final ids = restored.logicalGates.map((gate) => gate.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(
      restored.logicalGates.every(
        (gate) => gate.hasValidTopology(restored.currentLevel.numQubits),
      ),
      isTrue,
    );
  }

  group('SandboxCircuitSnapshot serialization', () {
    test('empty snapshot is versioned and round trips', () {
      final snapshot = SandboxCircuitSnapshot.empty(4);
      final decoded = SandboxCircuitSnapshot.decode(snapshot.encode());
      expect(decoded.schemaVersion, 1);
      expect(decoded.qubitCount, 4);
      expect(decoded.initialBinaryState, '0000');
      expect(decoded.operations, isEmpty);
      expect(decoded.restoreCircuit().logicalGates, isEmpty);
    });

    test('single and multiple gates round trip', () {
      final value = circuit(2);
      insertSingle(value, SelectedGateType.hadamard, 0, 0);
      insertSingle(value, SelectedGateType.x, 1, 1);
      final snapshot = SandboxCircuitSnapshot.capture(value);
      expect(snapshot.operations, hasLength(2));
      expectEquivalent(
          value,
          SandboxCircuitSnapshot.decode(
            snapshot.encode(),
          ).restoreCircuit());
    });

    test('Rx Ry Rz preserve finite configured angles', () {
      final value = circuit(1);
      insertSingle(value, SelectedGateType.rx, 0, 0, angle: math.pi / 4);
      insertSingle(value, SelectedGateType.ry, 1, 0, angle: -math.pi / 3);
      insertSingle(value, SelectedGateType.rz, 2, 0, angle: math.pi * 1.5);
      expectEquivalent(
        value,
        SandboxCircuitSnapshot.capture(value).restoreCircuit(),
      );
    });

    test('CX CZ and CCNOT topology round trips', () {
      final value = circuit(4);
      expect(
        value
            .insertDoubleGateWithOutcome(
              Gate.fromIdentifier(SelectedGateType.cnot),
              0,
              2,
              0,
            )
            .changed,
        isTrue,
      );
      expect(
        value
            .insertDoubleGateWithOutcome(
              Gate.fromIdentifier(SelectedGateType.cz),
              1,
              3,
              1,
            )
            .changed,
        isTrue,
      );
      expect(
        value
            .insertTripleGateWithOutcome(
              Gate.fromIdentifier(SelectedGateType.ccnot),
              2,
              3,
              0,
              2,
            )
            .changed,
        isTrue,
      );
      expectEquivalent(
          value, SandboxCircuitSnapshot.capture(value).restoreCircuit());
    });

    test('long multi-qubit circuits retain logical ordering', () {
      final value = circuit(5);
      for (var column = 0; column < 24; column++) {
        insertSingle(
          value,
          column.isEven ? SelectedGateType.hadamard : SelectedGateType.z,
          column,
          column % 5,
        );
      }
      expectEquivalent(
          value, SandboxCircuitSnapshot.capture(value).restoreCircuit());
    });
  });

  group('Sandbox corruption handling', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> expectDiscarded(String encoded) async {
      SharedPreferences.setMockInitialValues({
        SandboxPersistenceStore.storageKey: encoded,
      });
      const store = SandboxPersistenceStore();
      expect(await store.loadSnapshot(), isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(
          preferences.containsKey(SandboxPersistenceStore.storageKey), isFalse);
    }

    test('malformed JSON and unknown schema are discarded', () async {
      await expectDiscarded('{bad json');
      await expectDiscarded(
        '{"schemaVersion":99,"qubitCount":1,"initialState":"0","operations":[]}',
      );
    });

    test('unknown gate and out-of-range qubit are discarded', () async {
      await expectDiscarded(
        '{"schemaVersion":1,"qubitCount":1,"initialState":"0",'
        '"operations":[{"gateType":"futureGate","column":0,"targetQubit":0}]}',
      );
      await expectDiscarded(
        '{"schemaVersion":1,"qubitCount":1,"initialState":"0",'
        '"operations":[{"gateType":"x","column":0,"targetQubit":2}]}',
      );
    });

    test('malformed controlled topology is discarded', () async {
      await expectDiscarded(
        '{"schemaVersion":1,"qubitCount":2,"initialState":"00",'
        '"operations":[{"gateType":"cnot","column":0,"targetQubit":0,'
        '"controlQubit":0}]}',
      );
      await expectDiscarded(
        '{"schemaVersion":1,"qubitCount":3,"initialState":"000",'
        '"operations":[{"gateType":"ccnot","column":0,"targetQubit":2,'
        '"controlQubit":0,"secondControlQubit":0}]}',
      );
    });

    test('missing, NaN-like and infinite rotations are rejected', () async {
      await expectDiscarded(
        '{"schemaVersion":1,"qubitCount":1,"initialState":"0",'
        '"operations":[{"gateType":"rx","column":0,"targetQubit":0}]}',
      );
      await expectDiscarded(
        '{"schemaVersion":1,"qubitCount":1,"initialState":"0",'
        '"operations":[{"gateType":"rx","column":0,"targetQubit":0,'
        '"angle":"NaN"}]}',
      );
      expect(
        () => SandboxCircuitSnapshot(
          qubitCount: 1,
          initialBinaryState: '0',
          operations: const [
            SandboxCircuitOperation(
              gateType: SelectedGateType.rz,
              column: 0,
              targetQubit: 0,
              angle: double.infinity,
            ),
          ],
        ).restoreCircuit(),
        throwsFormatException,
      );
    });
  });

  group('Sandbox Composer persistence ownership', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<QuantumCircuit> pumpComposer(
      WidgetTester tester, {
      required ComposerSessionOwnership ownership,
      SandboxCircuitSnapshot? snapshot,
      QuantumComposerController? controller,
      ComposerLevel? level,
      int? levelId,
    }) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: QuantumComposer(
            levelId: levelId ??
                (ownership == ComposerSessionOwnership.campaign ? 1 : -1),
            level:
                level ?? createSandboxComposerLevel(snapshot?.qubitCount ?? 2),
            onLevelUnlocked: null,
            sessionOwnership: ownership,
            initialSandboxSnapshot: snapshot,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final intro = find.text('Start Composing');
      if (intro.evaluate().isNotEmpty) {
        await tester.tap(intro);
        await tester.pumpAndSettle();
      }
      return tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<QuantumCircuitPainter>()
          .first
          .circuit;
    }

    testWidgets('committed edit survives leaving and reopening Sandbox',
        (tester) async {
      final controller = QuantumComposerController();
      final original = await pumpComposer(
        tester,
        ownership: ComposerSessionOwnership.sandbox,
        controller: controller,
      );
      expect(
        controller
            .insertGate(
              gate: Gate.fromIdentifier(SelectedGateType.hadamard),
              location: const CircuitLocation(column: 0, qubit: 0),
            )
            .changed,
        isTrue,
      );
      await tester.pumpAndSettle();
      final expectedState = List.of(original.currentState.stateVector);
      final stored = await const SandboxPersistenceStore().loadSnapshot();
      expect(stored, isNotNull);
      expect(stored!.operations, hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final restored = await pumpComposer(
        tester,
        ownership: ComposerSessionOwnership.sandbox,
        snapshot: stored,
      );
      expect(restored.logicalGates, hasLength(1));
      expect(restored.logicalGates.single.type, SelectedGateType.hadamard);
      expect(restored.currentState.stateVector, expectedState);
    });

    testWidgets('Clear persists an empty workspace', (tester) async {
      final value = circuit(2);
      insertSingle(value, SelectedGateType.x, 0, 0);
      final snapshot = SandboxCircuitSnapshot.capture(value);
      await pumpComposer(
        tester,
        ownership: ComposerSessionOwnership.sandbox,
        snapshot: snapshot,
      );
      await tester.tap(find.byKey(const ValueKey('composer-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('clear-circuit')));
      await tester.pumpAndSettle();
      final stored = await const SandboxPersistenceStore().loadSnapshot();
      expect(stored, isNotNull);
      expect(stored!.operations, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(stored.restoreCircuit().logicalGates, isEmpty);
    });

    testWidgets('campaign and temporary Composer do not overwrite Sandbox',
        (tester) async {
      final saved = circuit(2);
      insertSingle(saved, SelectedGateType.z, 0, 1);
      const store = SandboxPersistenceStore();
      await store.saveCircuit(saved);
      final before = (await store.loadSnapshot())!.encode();

      final composerEntries = allQQLevels.indexed
          .where((entry) => entry.$2 is ComposerLevel)
          .toList(growable: false);
      final sessions = [
        (
          ComposerSessionOwnership.campaign,
          composerEntries.first.$2 as ComposerLevel,
          composerEntries.first.$1 + 1,
        ),
        (
          ComposerSessionOwnership.campaign,
          composerEntries.last.$2 as ComposerLevel,
          composerEntries.last.$1 + 1,
        ),
        (
          ComposerSessionOwnership.temporary,
          createSandboxComposerLevel(2),
          -1,
        ),
      ];
      for (final session in sessions) {
        final controller = QuantumComposerController();
        await pumpComposer(
          tester,
          ownership: session.$1,
          controller: controller,
          level: session.$2,
          levelId: session.$3,
        );
        final gate = session.$2.availableGates.firstWhere(
          (candidate) =>
              !candidate.requiresAngle &&
              candidate.type != SelectedGateType.cnot &&
              candidate.type != SelectedGateType.cz &&
              candidate.type != SelectedGateType.ccnot,
          orElse: () => Gate.fromIdentifier(SelectedGateType.x),
        );
        expect(
          controller
              .insertGate(
                gate: gate,
                location: const CircuitLocation(column: 0, qubit: 0),
              )
              .changed,
          isTrue,
        );
        await tester.pumpAndSettle();
      }
      expect((await store.loadSnapshot())!.encode(), before);
    });
  });
}
