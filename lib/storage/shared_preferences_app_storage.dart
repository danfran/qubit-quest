import 'package:quantumquiz/storage/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAppStorage implements AppStorage {
  const SharedPreferencesAppStorage();

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<String?> readString(String key) async =>
      (await _preferences).getString(key);

  @override
  Future<void> writeString(String key, String value) async {
    await (await _preferences).setString(key, value);
  }

  @override
  Future<bool?> readBool(String key) async => (await _preferences).getBool(key);

  @override
  Future<void> writeBool(String key, bool value) async {
    await (await _preferences).setBool(key, value);
  }

  @override
  Future<int?> readInt(String key) async => (await _preferences).getInt(key);

  @override
  Future<void> writeInt(String key, int value) async {
    await (await _preferences).setInt(key, value);
  }

  @override
  Future<List<String>?> readStringList(String key) async =>
      (await _preferences).getStringList(key);

  @override
  Future<void> writeStringList(String key, List<String> value) async {
    await (await _preferences).setStringList(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await (await _preferences).remove(key);
  }
}
