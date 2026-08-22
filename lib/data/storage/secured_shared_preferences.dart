import 'package:shared_preferences/shared_preferences.dart';

class SecuredSharedPreferences {
  final SharedPreferences _preferences;

  SecuredSharedPreferences(this._preferences);

  Future<void> saveKey(String key, String value) async {
    await _preferences.setString(key, value);
  }

  Future<String?> get(String key) async {
    return _preferences.getString(key);
  }

  Future<void> deleteKey(String key) async {
    await _preferences.remove(key);
  }

  Future<void> reset() async {
    await _preferences.clear();
  }

  Future<void> saveInt(String key, int value) async {
    await _preferences.setInt(key, value);
  }

  Future<void> saveBoolean(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  Future<int?> getInt(String key) async {
    return _preferences.getInt(key);
  }

  Future<bool?> getBoolean(String key) async {
    return _preferences.getBool(key);
  }
}