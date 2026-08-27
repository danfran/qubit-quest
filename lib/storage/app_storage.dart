abstract class AppStorage {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, bool value);

  Future<int?> readInt(String key);

  Future<void> writeInt(String key, int value);

  Future<List<String>?> readStringList(String key);

  Future<void> writeStringList(String key, List<String> value);

  Future<void> delete(String key);
}

class InMemoryAppStorage implements AppStorage {
  InMemoryAppStorage([Map<String, Object>? initialValues])
      : _values = Map<String, Object>.from(initialValues ?? const {});

  final Map<String, Object> _values;

  @override
  Future<String?> readString(String key) async => _values[key] as String?;

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<bool?> readBool(String key) async => _values[key] as bool?;

  @override
  Future<void> writeBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<int?> readInt(String key) async => _values[key] as int?;

  @override
  Future<void> writeInt(String key, int value) async {
    _values[key] = value;
  }

  @override
  Future<List<String>?> readStringList(String key) async {
    final value = _values[key] as List<String>?;
    return value == null ? null : List<String>.from(value);
  }

  @override
  Future<void> writeStringList(String key, List<String> value) async {
    _values[key] = List<String>.from(value);
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
