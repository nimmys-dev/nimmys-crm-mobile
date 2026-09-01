import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin typed wrapper around [SharedPreferences].
///
/// Call [init] once during app start-up; every getter afterwards is
/// synchronous, so widgets can read persisted state during `build`.
class AppPreferences {
  AppPreferences._(this._prefs);

  final SharedPreferences _prefs;

  static AppPreferences? _instance;

  /// The initialised singleton. Throws if [init] has not completed.
  static AppPreferences get instance {
    final AppPreferences? value = _instance;
    if (value == null) {
      throw StateError(
        'AppPreferences.init() must be awaited before accessing instance.',
      );
    }
    return value;
  }

  /// Whether [init] has already run.
  static bool get isReady => _instance != null;

  static Future<AppPreferences> init() async {
    final AppPreferences prefs = AppPreferences._(
      await SharedPreferences.getInstance(),
    );
    _instance = prefs;
    return prefs;
  }

  // ------------------------------------------------------------------- Keys
  static const String _keyThemeMode = 'settings.theme_mode';
  static const String _keyRememberMe = 'auth.remember_me';
  static const String _keySavedEmail = 'auth.saved_email';
  static const String _keyLastUserName = 'auth.user_name';
  static const String _keyUserId = 'auth.user_id';

  // -------------------------------------------------------------- Theme mode
  ThemeMode get themeMode {
    switch (_prefs.getString(_keyThemeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) {
    return _prefs.setString(_keyThemeMode, mode.name);
  }

  // ------------------------------------------------------------------- Login
  bool get rememberMe => _prefs.getBool(_keyRememberMe) ?? true;

  Future<void> setRememberMe(bool value) =>
      _prefs.setBool(_keyRememberMe, value);

  String get savedEmail => _prefs.getString(_keySavedEmail) ?? '';

  Future<void> setSavedEmail(String value) =>
      _prefs.setString(_keySavedEmail, value);

  Future<void> clearSavedEmail() => _prefs.remove(_keySavedEmail);

  String get userName => _prefs.getString(_keyLastUserName) ?? 'Abin Babu';

  Future<void> setUserName(String value) =>
      _prefs.setString(_keyLastUserName, value);
  int? get userId => _prefs.getInt(_keyUserId);

  Future<void> setUserId(int value) => _prefs.setInt(_keyUserId, value);

  Future<void> clearUserId() => _prefs.remove(_keyUserId);

  Future<int?> getUserIdAsync() async => _prefs.getInt(_keyUserId);
}
