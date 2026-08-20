import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/bloch_explorer_screen.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingSandboxPersistenceStore extends SandboxPersistenceStore {
  const _FailingSandboxPersistenceStore();

  @override
  Future<void> saveSnapshot(SandboxCircuitSnapshot snapshot) =>
      Future<void>.error(StateError('storage unavailable'));
}

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

    test('X and H each round trip independently', () {
      for (final type in [
        SelectedGateType.x,
        SelectedGateType.hadamard,
      ]) {
        final value = circuit(1);
        insertSingle(value, type, 0, 0);
        expectEquivalent(
          value,
          SandboxCircuitSnapshot.decode(
            SandboxCircuitSnapshot.capture(value).encode(),
          ).restoreCircuit(),
        );
      }
    });

    test('mixed single-qubit gates round trip', () {
      final value = circuit(2);
      const types = [
        SelectedGateType.x,
        SelectedGateType.y,
        SelectedGateType.z,
        SelectedGateType.hadamard,
        SelectedGateType.s,
        SelectedGateType.t,
      ];
      for (final (column, type) in types.indexed) {
        insertSingle(value, type, column, column % 2);
      }
      final snapshot = SandboxCircuitSnapshot.capture(value);
      expect(snapshot.operations, hasLength(types.length));
      expectEquivalent(
          value,
          SandboxCircuitSnapshot.decode(
            snapshot.encode(),
          ).restoreCircuit());
    });

    test('Rx Ry Rz preserve finite configured angles', () {
      final value = circuit(1);
      insertSingle(value, SelectedGateType.rx, 0, 0, angle: math.pi / 7);
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

    test('restored gates remain fully editable through production APIs', () {
      final source = circuit(3);
      insertSingle(source, SelectedGateType.rx, 0, 0, angle: math.pi / 7);
      insertSingle(source, SelectedGateType.hadamard, 1, 1);
      expect(
        source
            .insertDoubleGateWithOutcome(
              Gate.fromIdentifier(SelectedGateType.cnot),
              2,
              2,
              0,
            )
            .changed,
        isTrue,
      );

      final restored = SandboxCircuitSnapshot.capture(source).restoreCircuit();
      final rx = restored.logicalGates
          .singleWhere((gate) => gate.type == SelectedGateType.rx);
      final hadamard = restored.logicalGates
          .singleWhere((gate) => gate.type == SelectedGateType.hadamard);
      final cnot = restored.logicalGates
          .singleWhere((gate) => gate.type == SelectedGateType.cnot);

      expect(
        restored
            .moveSingleGateWithOutcome(
              rx.id,
              const CircuitLocation(qubit: 2, column: 2),
            )
            .changed,
        isTrue,
      );
      expect(
        restored
            .updateGateParametersWithOutcome(rx.id, angle: -math.pi / 5)
            .changed,
        isTrue,
      );
      expect(restored.duplicateLogicalGateWithOutcome(cnot.id).changed, isTrue);
      expect(
        restored
            .replaceSingleGateWithOutcome(
              hadamard.id,
              Gate.fromIdentifier(SelectedGateType.z),
            )
            .changed,
        isTrue,
      );
      expect(restored.removeLogicalGateByIdWithOutcome(hadamard.id).changed,
          isTrue);
      expect(
        restored
            .insertSingleGateWithOutcome(
              Gate.fromIdentifier(SelectedGateType.s),
              restored.maxCircuitDepth(),
              1,
            )
            .changed,
        isTrue,
      );
      restored.runSimulation();
      expect(restored.lastSimulationError, isNull);
      expect(
        restored.logicalGates.every(
          (gate) => gate.hasValidTopology(restored.currentLevel.numQubits),
        ),
        isTrue,
      );
      final ids = restored.logicalGates.map((gate) => gate.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('Sandbox corruption handling', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> expectDiscarded(String encoded) async {
      SharedPreferences.setMockInitialValues({
        SandboxPersistenceStore.storageKey: encoded,
      });
      const store = SandboxPersistenceStore();
      expect(await store.loadSnapshot(1), isNull);
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

    test('missing fields and invalid qubit counts are discarded', () async {
      await expectDiscarded(
        '{"schemaVersion":1,"qubitCount":1,"initialState":"0"}',
      );
      await expectDiscarded(
        '{"schemaVersion":1,"qubitCount":0,"initialState":"",'
        '"operations":[]}',
      );
      await expectDiscarded(
        '{"schemaVersion":1,"qubitCount":6,"initialState":"000000",'
        '"operations":[]}',
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
      await expectDiscarded(
        '{"schemaVersion":1,"qubitCount":2,"initialState":"00",'
        '"operations":[{"gateType":"cnot","column":0,"targetQubit":0,'
        '"controlQubit":2}]}',
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

  group('moved circuit persistence regression', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('single-gate move saves and restores the compact non-empty circuit',
        () async {
      final value = circuit(2);
      insertSingle(value, SelectedGateType.hadamard, 0, 0);
      insertSingle(value, SelectedGateType.x, 1, 0);
      insertSingle(value, SelectedGateType.z, 2, 0);
      final z = value.logicalGates
          .singleWhere((gate) => gate.type == SelectedGateType.z);
      expect(
        value
            .moveSingleGateWithOutcome(
              z.id,
              const CircuitLocation(qubit: 1, column: 2),
            )
            .changed,
        isTrue,
      );
      expect(value.logicalGateById(z.id)!.column, 0);
      value.runSimulation();
      final before = value.currentState.state;

      const store = SandboxPersistenceStore();
      await store.saveCircuit(value);
      final loaded = await store.loadSnapshot(2);

      expect(loaded, isNotNull);
      expect(loaded!.operations, hasLength(3));
      final restored = loaded.restoreCircuit();
      expect(restored.logicalGates, hasLength(3));
      restored.runSimulation();
      expect(restored.currentState.state.almostEqualTo(before), isTrue);
      final restoredZ = restored.logicalGates
          .singleWhere((gate) => gate.type == SelectedGateType.z);
      expect(restored.removeLogicalGateByIdWithOutcome(restoredZ.id).changed,
          isTrue);
    });

    test('controlled move saves and restores its compact rigid footprint',
        () async {
      final value = circuit(4);
      final cx = value.insertDoubleGateWithOutcome(
        Gate.fromIdentifier(SelectedGateType.cnot),
        0,
        1,
        0,
      );
      insertSingle(value, SelectedGateType.hadamard, 1, 3);
      insertSingle(value, SelectedGateType.x, 2, 3);
      expect(
        value
            .commitLogicalGateMovePlan(
              value.planLogicalGateMove(
                cx.affectedGateId!,
                const CircuitLocation(qubit: 2, column: 2),
              ),
            )
            .changed,
        isTrue,
      );
      final moved = value.logicalGateById(cx.affectedGateId!)!;
      expect(moved.column, 0);
      expect(moved.hasValidTopology(4), isTrue);
      value.runSimulation();
      final before = value.currentState.state;

      const store = SandboxPersistenceStore();
      await store.saveCircuit(value);
      final loaded = await store.loadSnapshot(4);

      expect(loaded, isNotNull);
      expect(loaded!.operations, hasLength(3));
      final restored = loaded.restoreCircuit();
      final restoredCx = restored.logicalGates
          .singleWhere((gate) => gate.type == SelectedGateType.cnot);
      expect(restoredCx.column, 0);
      expect(restoredCx.controlQubit, 1);
      expect(restoredCx.targetQubit, 2);
      expect(restoredCx.hasValidTopology(4), isTrue);
      restored.runSimulation();
      expect(restored.currentState.state.almostEqualTo(before), isTrue);
      expect(restored.duplicateLogicalGateWithOutcome(restoredCx.id).changed,
          isTrue);
    });
  });

  group('per-qubit Sandbox workspaces', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('3- and 5-qubit workspaces persist independently across store owners',
        () async {
      final five = circuit(5);
      insertSingle(five, SelectedGateType.hadamard, 0, 4);
      final three = circuit(3);
      insertSingle(three, SelectedGateType.x, 0, 1);

      const firstOwner = SandboxPersistenceStore();
      await firstOwner.saveCircuit(five);
      await firstOwner.saveCircuit(three);

      const recreatedOwner = SandboxPersistenceStore();
      final restoredFive = (await recreatedOwner.loadSnapshot(5))!;
      final restoredThree = (await recreatedOwner.loadSnapshot(3))!;
      expect(restoredFive.qubitCount, 5);
      expect(
          restoredFive.operations.single.gateType, SelectedGateType.hadamard);
      expect(restoredFive.operations.single.targetQubit, 4);
      expect(restoredThree.qubitCount, 3);
      expect(restoredThree.operations.single.gateType, SelectedGateType.x);
      expect(restoredThree.operations.single.targetQubit, 1);
    });

    test('a never-used qubit count opens without another workspace', () async {
      final five = circuit(5);
      insertSingle(five, SelectedGateType.z, 0, 4);
      const store = SandboxPersistenceStore();
      await store.saveCircuit(five);

      expect(await store.loadSnapshot(4), isNull);
      expect((await store.loadSnapshot(5))!.operations, hasLength(1));
    });

    test('clearing one qubit count leaves the other workspace intact',
        () async {
      final three = circuit(3);
      insertSingle(three, SelectedGateType.s, 0, 0);
      final five = circuit(5);
      insertSingle(five, SelectedGateType.t, 0, 4);
      const store = SandboxPersistenceStore();
      await store.saveCircuit(three);
      await store.saveCircuit(five);

      await store.saveSnapshot(SandboxCircuitSnapshot.empty(5));

      expect((await store.loadSnapshot(5))!.operations, isEmpty);
      final restoredThree = await store.loadSnapshot(3);
      expect(restoredThree, isNotNull);
      expect(restoredThree!.operations.single.gateType, SelectedGateType.s);
    });

    test('legacy single snapshot migrates only to its recorded qubit count',
        () async {
      final legacyCircuit = circuit(5);
      insertSingle(legacyCircuit, SelectedGateType.hadamard, 0, 2);
      final legacy = SandboxCircuitSnapshot.capture(legacyCircuit);
      SharedPreferences.setMockInitialValues({
        SandboxPersistenceStore.storageKey: legacy.encode(),
      });
      const store = SandboxPersistenceStore();

      expect(await store.loadSnapshot(3), isNull);
      expect((await store.loadSnapshot(5))!.operations, hasLength(1));
      final preferences = await SharedPreferences.getInstance();
      expect(
          preferences.containsKey(SandboxPersistenceStore.storageKey), isFalse);
      expect(
        preferences
            .containsKey(SandboxPersistenceStore.storageKeyForQubitCount(5)),
        isTrue,
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
      SandboxPersistenceStore store = const SandboxPersistenceStore(),
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
            sandboxPersistenceStore: store,
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
      final stored = await const SandboxPersistenceStore().loadSnapshot(2);
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
      final stored = await const SandboxPersistenceStore().loadSnapshot(2);
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
      final before = (await store.loadSnapshot(2))!.encode();

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
      expect((await store.loadSnapshot(2))!.encode(), before);
    });

    testWidgets('save failure does not make the Sandbox unusable',
        (tester) async {
      final controller = QuantumComposerController();
      final value = await pumpComposer(
        tester,
        ownership: ComposerSessionOwnership.sandbox,
        controller: controller,
        store: const _FailingSandboxPersistenceStore(),
      );
      expect(
        controller
            .insertGate(
              gate: Gate.fromIdentifier(SelectedGateType.x),
              location: const CircuitLocation(column: 0, qubit: 0),
            )
            .changed,
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(value.logicalGates.single.type, SelectedGateType.x);
      expect(value.lastSimulationError, isNull);
    });

    testWidgets('Bloch Explorer interaction leaves Sandbox storage unchanged',
        (tester) async {
      final saved = circuit(2);
      insertSingle(saved, SelectedGateType.s, 0, 1);
      const store = SandboxPersistenceStore();
      await store.saveCircuit(saved);
      final before = (await store.loadSnapshot(2))!.encode();

      await tester.pumpWidget(const MaterialApp(home: BlochExplorerScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
      await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
      await tester.pumpAndSettle();

      expect((await store.loadSnapshot(2))!.encode(), before);
    });
  });
}
