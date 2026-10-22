import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/tutorial_flags_store.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/storage/shared_preferences_app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesAppStorage', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('preserves all supported typed values and deletion', () async {
      const storage = SharedPreferencesAppStorage();

      await storage.writeString('string', 'value');
      await storage.writeBool('bool', true);
      await storage.writeInt('int', 42);
      await storage.writeStringList('list', ['one', 'two']);

      expect(await storage.readString('string'), 'value');
      expect(await storage.readBool('bool'), isTrue);
      expect(await storage.readInt('int'), 42);
      expect(await storage.readStringList('list'), ['one', 'two']);

      await storage.delete('string');
      expect(await storage.readString('string'), isNull);
    });
  });

  group('InMemoryAppStorage injection', () {
    test('campaign progress uses injected storage and existing keys', () async {
      final storage = InMemoryAppStorage();
      final store = SharedPreferencesCampaignProgressStore(storage: storage);
      final saved = CampaignProgressPolicy.completeLesson(
        CampaignProgressState.fresh(),
        3,
      );

      await store.save(saved);
      final loaded = await store.load();

      expect(loaded.maxUnlockedLevel, 4);
      expect(loaded.completedLessonIds, {1, 2, 3});
      final active = await storage
          .readString(SharedPreferencesCampaignProgressStore.activeV3Key);
      expect(
          active,
          isIn([
            SharedPreferencesCampaignProgressStore.recordV3AKey,
            SharedPreferencesCampaignProgressStore.recordV3BKey
          ]));
      final record = jsonDecode((await storage.readString(active!))!)
          as Map<String, dynamic>;
      expect(record['schema'], CampaignProgressState.currentSchemaVersion);
      expect(record['journey'], {
        'frontier': 4,
        'completed': [1, 2, 3]
      });
      expect(
          await storage.readInt(
              SharedPreferencesCampaignProgressStore.maxUnlockedLevelKey),
          isNull,
          reason: 'Schema 3 must not overwrite the separate legacy namespace');
    });

    test('tutorial flags persist once with their authoritative key', () async {
      final storage = InMemoryAppStorage();
      final flags = TutorialFlagsStore(storage: storage);
      const key = 'chapter_intro_seen_chapter_1_information_vertical_slice';

      expect(await flags.markSeenIfNeeded(key), isTrue);
      expect(await flags.markSeenIfNeeded(key), isFalse);
      expect(await storage.readBool(key), isTrue);
    });

    test('string-list reads and writes do not expose mutable storage state',
        () async {
      final storage = InMemoryAppStorage();
      final original = ['one'];
      await storage.writeStringList('list', original);
      original.add('two');
      final loaded = (await storage.readStringList('list'))!;
      loaded.add('three');

      expect(await storage.readStringList('list'), ['one']);
    });
  });
}
