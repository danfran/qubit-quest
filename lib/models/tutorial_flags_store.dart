import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/storage/shared_preferences_app_storage.dart';

class TutorialFlagsStore {
  const TutorialFlagsStore({
    this.storage = const SharedPreferencesAppStorage(),
  });

  final AppStorage storage;

  Future<bool> markSeenIfNeeded(String key) async {
    if (await storage.readBool(key) == true) return false;
    await storage.writeBool(key, true);
    return true;
  }
}
