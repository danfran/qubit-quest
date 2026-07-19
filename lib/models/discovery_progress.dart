import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/discovery_catalog.dart' as catalog;

class DiscoveryProgress {
  static const String storageKey =
      SharedPreferencesCampaignProgressStore.legacyUnlockedDiscoveriesKey;
  static const String openedNotebookEntriesKey =
      SharedPreferencesCampaignProgressStore.legacyOpenedNotebookEntriesKey;

  static const List<String> discoveryOrder = catalog.discoveryOrder;

  static Future<Set<String>> loadUnlocked() async {
    final controller = CampaignProgressController.instance;
    await controller.load();
    return controller.unlockedDiscoveryTitles();
  }

  static Future<void> unlock(String discoveryTitle) async {
    final String normalized = discoveryTitle.trim();
    if (normalized.isEmpty) return;

    final controller = CampaignProgressController.instance;
    await controller.load();
    await controller.unlockDiscovery(normalized);
  }

  static Future<Set<String>> loadOpenedNotebookEntries() async {
    final controller = CampaignProgressController.instance;
    await controller.load();
    return controller.openedDiscoveryTitles();
  }

  static Future<void> markNotebookEntryOpened(String discoveryTitle) async {
    final String normalized = discoveryTitle.trim();
    if (normalized.isEmpty) return;

    final controller = CampaignProgressController.instance;
    await controller.load();
    await controller.markNotebookEntryOpened(normalized);
  }

  static Future<bool> hasUnopenedNotebookEntries(
    Iterable<String> notebookDiscoveryTitles,
  ) async {
    final controller = CampaignProgressController.instance;
    await controller.load();
    return controller.hasUnopenedNotebookEntries(notebookDiscoveryTitles);
  }
}
