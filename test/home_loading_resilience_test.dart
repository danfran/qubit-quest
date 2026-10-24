import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/screens/home_page.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

class _Storage extends InMemoryAppStorage {
  _Storage([super.initialValues]);
  bool failRead = false;
  bool failStage = false;
  int writes = 0;
  int deletes = 0;

  @override
  Future<String?> readString(String key) async {
    if (failRead) throw PlatformException(code: 'storage_unavailable');
    return super.readString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    writes++;
    if (failStage) throw StateError('staging unavailable');
    await super.writeString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    deletes++;
    await super.delete(key);
  }
}

class _DelayedStore extends InMemoryCampaignProgressStore {
  final pending = Completer<CampaignProgressState>();
  int calls = 0;
  bool firstFails = false;

  @override
  Future<CampaignProgressState> load() {
    calls++;
    if (firstFails && calls == 1) return Future.error(StateError('transient'));
    return pending.future;
  }
}

void main() {
  const packageChannel =
      MethodChannel('dev.fluttercommunity.plus/package_info');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageChannel, (_) async {
      throw PlatformException(code: 'package_info_unavailable');
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageChannel, null);
  });

  Future<void> mount(WidgetTester tester, CampaignProgressStore store) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: QubitQuestTheme.mobile(),
      home: HomePage(
          progressController: CampaignProgressController(store: store)),
    ));
  }

  SharedPreferencesCampaignProgressStore backed(_Storage storage) =>
      SharedPreferencesCampaignProgressStore(storage: storage);

  testWidgets('successful load moves from spinner to Home', (tester) async {
    final store = _DelayedStore();
    await mount(tester, store);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const ValueKey('home-action-Continue Journey')),
        findsNothing);
    store.pending.complete(CampaignProgressState.fresh());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-action-Continue Journey')),
        findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('platform read failure is actionable and a retry recovers',
      (tester) async {
    final storage = _Storage()..failRead = true;
    await mount(tester, backed(storage));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load your progress'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(storage.writes, 0);
    expect(storage.deletes, 0);
    storage.failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-action-Continue Journey')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final raw in ['{invalid json', '{"schema":99}']) {
    testWidgets('invalid active record stays intact: $raw', (tester) async {
      final storage = _Storage({
        SharedPreferencesCampaignProgressStore.activeV3Key:
            SharedPreferencesCampaignProgressStore.recordV3AKey,
        SharedPreferencesCampaignProgressStore.recordV3AKey: raw,
      });
      await mount(tester, backed(storage));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load your progress'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-action-Continue Journey')),
          findsNothing);
      expect(
          await storage
              .readString(SharedPreferencesCampaignProgressStore.recordV3AKey),
          raw);
      expect(
          await storage
              .readString(SharedPreferencesCampaignProgressStore.activeV3Key),
          SharedPreferencesCampaignProgressStore.recordV3AKey);
      expect(storage.writes, 0);
      expect(storage.deletes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('migration stage failure preserves legacy records and retries',
      (tester) async {
    final storage = _Storage({
      SharedPreferencesCampaignProgressStore.schemaVersionKey: 2,
      SharedPreferencesCampaignProgressStore.completedLessonIdsKey: ['1'],
      SharedPreferencesCampaignProgressStore.maxUnlockedLevelKey: 2,
    })
      ..failStage = true;
    await mount(tester, backed(storage));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load your progress'), findsOneWidget);
    expect(
        await storage
            .readString(SharedPreferencesCampaignProgressStore.activeV3Key),
        isNull);
    expect(
        await storage.readStringList(
            SharedPreferencesCampaignProgressStore.completedLessonIdsKey),
        ['1']);
    expect(storage.deletes, 0);
    storage.failStage = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-action-Continue Journey')),
        findsOneWidget);
    expect((await backed(storage).load()).completedLessonIds, {1});
  });

  testWidgets('repeated retry callbacks cannot create concurrent loads',
      (tester) async {
    final store = _DelayedStore()..firstFails = true;
    await mount(tester, store);
    await tester.pumpAndSettle();
    final retry = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Retry'))
        .onPressed!;
    retry();
    retry();
    retry();
    await tester.pump();
    expect(store.calls, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    store.pending.complete(CampaignProgressState.fresh());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-action-Continue Journey')),
        findsOneWidget);
  });

  for (final failure in [false, true]) {
    testWidgets('dispose Home before progress completion (failure=$failure)',
        (tester) async {
      final store = _DelayedStore();
      await mount(tester, store);
      await tester.pumpWidget(const SizedBox());
      if (failure) {
        store.pending.completeError(StateError('late storage failure'));
      } else {
        store.pending.complete(CampaignProgressState.fresh());
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('PackageInfo failure leaves Home and About functional',
      (tester) async {
    await mount(tester, InMemoryCampaignProgressStore());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-action-Continue Journey')),
        findsOneWidget);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('About Qubit Quest'), findsOneWidget);
    expect(find.text('Unavailable'), findsNWidgets(3));
    expect(find.text('qubitquestapp@gmail.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dispose Home before PackageInfo completes', (tester) async {
    final pending = Completer<Map<String, String>>();
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(packageChannel, (_) => pending.future);
    await mount(tester, InMemoryCampaignProgressStore());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-action-Continue Journey')),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    pending.complete({
      'appName': 'Qubit Quest',
      'packageName': 'com.qubitquest',
      'version': '2.5.0',
      'buildNumber': '35',
      'buildSignature': ''
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
