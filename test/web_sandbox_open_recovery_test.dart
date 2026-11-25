// Phase W1: Web Sandbox workspace opening, failure handling and isolation.
//
// These run on the Dart VM. The original defect (`nextInt(1 << 32)` evaluating
// to `nextInt(0)` under JavaScript's 32-bit shifts) cannot occur on the VM, so
// the session-ID tests assert the Web-safe bound directly and the failure test
// injects the same class of initialization error.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/sandbox_program_snapshot.dart';
import 'package:quantumquiz/models/sandbox_workspace_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/widgets/composer_circuit_canvas.dart';

import 'sandbox_activation_test.dart' show definition;
import 'web_sandbox_measurement_test.dart' show tapVisible;

class _RecordingRandom implements Random {
  final bounds = <int>[];
  final _inner = Random(7);
  @override
  int nextInt(int max) {
    bounds.add(max);
    return _inner.nextInt(max);
  }

  @override
  bool nextBool() => _inner.nextBool();
  @override
  double nextDouble() => _inner.nextDouble();
}

final _canvas = find.byType(ComposerCircuitCanvas);
final _openError = find.byKey(const ValueKey('web-composer-open-error'));

Future<void> _openComposer(WidgetTester tester, AppStorage storage) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(QubitQuestWebApp(storage: storage));
  await tester.pumpAndSettle();
  final menu = find.byKey(const ValueKey('web-navigation-menu'));
  if (menu.evaluate().isNotEmpty) await tapVisible(tester, menu);
  await tapVisible(tester, find.byKey(const ValueKey('web-nav-composer')));
}

Future<void> _chooseQubits(WidgetTester tester, int n) =>
    tapVisible(tester, find.byKey(ValueKey('web-composer-qubits-$n')));

Future<void> _changeQubits(WidgetTester tester) => tapVisible(
    tester, find.byKey(const ValueKey('web-composer-change-qubits')));

QuantumCircuit _openCircuit(WidgetTester tester) =>
    tester.widget<ComposerCircuitCanvas>(_canvas).circuit;

/// A distinct, unitary definition per qubit count: X on the last qubit.
SandboxProgramSnapshot _distinct(int n) {
  final c = QuantumCircuit(currentLevel: createSandboxComposerLevel(n));
  c.insertSingleGateWithOutcome(
      Gate.fromIdentifier(SelectedGateType.x), 0, n - 1);
  final s = SandboxProgramSnapshot.capture(c);
  c.dispose();
  return s;
}

void main() {
  tearDown(() => SandboxWorkspacePersistence.secureRandom = Random.secure);

  group('session identifier', () {
    test('uses only Web-safe nextInt bounds', () {
      final random = _RecordingRandom();
      SandboxWorkspacePersistence.createSessionId(random: random);
      expect(random.bounds, hasLength(4));
      // JavaScript bitwise semantics are 32-bit; bounds must stay < 2^31.
      expect(random.bounds.every((b) => b > 0 && b < 0x80000000), isTrue);
      expect(SandboxWorkspacePersistence.sessionChunkBound, 0x10000);
    });

    test('is staging-key compatible and collision resistant', () {
      final now = DateTime.utc(2026, 11, 7);
      final ids = {
        for (var i = 0; i < 2000; i++)
          SandboxWorkspacePersistence.createSessionId(now: now)
      };
      expect(ids, hasLength(2000), reason: '64 random bits per session');
      for (final id in ids.take(20)) {
        expect(id, matches(RegExp(r'^\d+_[0-9a-f]{16}$')));
        // Staging IDs are '<session>_<sequence>' and must satisfy stage().
        expect('${id}_123456', matches(RegExp(r'^[A-Za-z0-9_-]{1,80}$')));
      }
    });

    test('a fresh owner initializes with the real secure source', () async {
      final storage = InMemoryAppStorage();
      final owner = SandboxWorkspacePersistence(storage);
      await owner.queue(2).saveProgram(definition());
      expect((await SandboxWorkspacePersistence(storage).load(2))!.encode(),
          definition().encode());
    });
  });

  testWidgets('each qubit selector opens its workspace', (tester) async {
    await _openComposer(tester, InMemoryAppStorage());
    for (var n = 1; n <= 5; n++) {
      await _chooseQubits(tester, n);
      expect(_canvas, findsOneWidget, reason: '$n-qubit selector');
      expect(_openCircuit(tester).currentLevel.numQubits, n);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('web-composer-qubit-count')))
              .data,
          startsWith('$n qubit'));
      await _changeQubits(tester);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialization failure is reported and can be retried',
      (tester) async {
    final storage = InMemoryAppStorage();
    final saved = _distinct(3);
    await SandboxWorkspacePersistence(storage).queue(3).saveProgram(saved);
    final before =
        await storage.readString(SandboxWorkspacePersistence.activeKey(3));
    // Same failure class as the Web defect: owner construction throws.
    SandboxWorkspacePersistence.secureRandom =
        () => throw RangeError('max must be in range 0 < max ≤ 2^32, was 0');
    await _openComposer(tester, storage);

    await _chooseQubits(tester, 3);
    expect(_canvas, findsNothing, reason: 'no empty circuit substituted');
    expect(_openError, findsOneWidget);
    expect(find.textContaining('Could not open the 3-qubit Sandbox'),
        findsWidgets);
    expect(await storage.readString(SandboxWorkspacePersistence.activeKey(3)),
        before);

    // Still failing: the button is not stuck behind the _opening guard.
    await _chooseQubits(tester, 3);
    expect(_openError, findsOneWidget);

    SandboxWorkspacePersistence.secureRandom = Random.secure;
    await _chooseQubits(tester, 3);
    expect(_openError, findsNothing);
    expect(SandboxProgramSnapshot.capture(_openCircuit(tester)).encode(),
        saved.encode());
    expect(tester.takeException(), isNull);
  });

  testWidgets('recoverable load errors keep Cancel/Retry behaviour',
      (tester) async {
    final storage = InMemoryAppStorage();
    await storage.writeString(
        SandboxWorkspacePersistence.activeKey(1), 'invalid');
    await _openComposer(tester, storage);

    await _chooseQubits(tester, 1);
    expect(find.text('Sandbox could not be restored'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_canvas, findsNothing);
    expect(_openError, findsNothing, reason: 'cancel is not an error');

    // Reopening after cancel works; Retry succeeds once storage is readable.
    await _chooseQubits(tester, 1);
    expect(find.text('Sandbox could not be restored'), findsOneWidget);
    await storage.delete(SandboxWorkspacePersistence.activeKey(1));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(_canvas, findsOneWidget);
    expect(_openCircuit(tester).currentLevel.numQubits, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved circuits load without losing operations', (tester) async {
    final storage = InMemoryAppStorage();
    final measured = definition(n: 2, measurements: 2);
    await SandboxWorkspacePersistence(storage).queue(2).saveProgram(measured);
    // A schema-1 record from before schema 2 existed.
    final legacy = QuantumCircuit(currentLevel: createSandboxComposerLevel(4))
      ..insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.hadamard), 0, 1)
      ..insertSingleGateWithOutcome(
          Gate.fromIdentifier(SelectedGateType.x), 1, 3);
    await SandboxPersistenceStore(storage: storage).saveCircuit(legacy);
    final legacyProgram = SandboxProgramSnapshot.capture(legacy);
    legacy.dispose();
    await _openComposer(tester, storage);

    await _chooseQubits(tester, 2);
    final restored = _openCircuit(tester);
    expect(restored.measurements, hasLength(2));
    expect(
        SandboxProgramSnapshot.capture(restored).encode(), measured.encode());
    await _changeQubits(tester);

    await _chooseQubits(tester, 4);
    final converted = SandboxProgramSnapshot.capture(_openCircuit(tester));
    expect(converted.program.operations, hasLength(2));
    expect(converted.encode(), legacyProgram.encode());
    expect(tester.takeException(), isNull);
  });

  testWidgets('the five qubit-count workspaces stay isolated', (tester) async {
    final storage = InMemoryAppStorage();
    final owner = SandboxWorkspacePersistence(storage);
    for (var n = 1; n <= 5; n++) {
      await owner.queue(n).saveProgram(_distinct(n));
    }
    await _openComposer(tester, storage);

    for (var n = 1; n <= 5; n++) {
      await _chooseQubits(tester, n);
      final circuit = _openCircuit(tester);
      expect(circuit.currentLevel.numQubits, n);
      expect(SandboxProgramSnapshot.capture(circuit).encode(),
          _distinct(n).encode());
      if (n == 3) {
        circuit.clearPlacedGates();
        await tester.pumpAndSettle();
      }
      await _changeQubits(tester);
    }

    final reader = SandboxWorkspacePersistence(storage);
    for (var n = 1; n <= 5; n++) {
      final ops = (await reader.load(n))!.program.operations;
      expect(ops, n == 3 ? isEmpty : hasLength(1), reason: '$n qubits');
    }
    expect(tester.takeException(), isNull);
  });
}
