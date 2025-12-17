import 'package:shared_preferences/shared_preferences.dart';

class StorageUtils {
  static Future<SharedPreferences> get prefs async {
    return SharedPreferences.getInstance();
  }

  static Future<void> setString(String key, String value) async {
    final p = await prefs;
    await p.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  static Future<void> setStringList(String key, List<String> value) async {
    final p = await prefs;
    await p.setStringList(key, value);
  }

  static Future<List<String>> getStringList(String key) async {
    final p = await prefs;
    return p.getStringList(key) ?? <String>[];
  }
}
