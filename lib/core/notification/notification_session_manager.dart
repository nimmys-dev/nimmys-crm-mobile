import '../storage/secured_shared_preferences.dart';
import '../utils/custom_log.dart';

/// Remembers which device raised the most recent alert of each kind.
///
/// A push carries the device name only in the payload that triggered it. A
/// cold start replays the *tap* long after that payload is gone, so the name is
/// written the moment the alert arrives and read back when the dialog opens.
///
/// A singleton on purpose: the background isolate reaches it statically, and
/// two instances would mean two views of the same key.
class NotificationSessionManager {
  factory NotificationSessionManager() => _instance;

  NotificationSessionManager._internal();

  static final NotificationSessionManager _instance =
      NotificationSessionManager._internal();

  static const String _keyLastDeviceName = 'notification.device.last';
  static const String _keySosDeviceName = 'notification.device.sos';
  static const String _keyPowerCutDeviceName = 'notification.device.power_cut';
  static const String _keySpyModeDeviceName = 'notification.device.spy_mode';
  static const String _keyLatestType = 'notification.type.latest';

  SecuredSharedPreferences? _prefs;

  /// Called once from `NotificationService.init`.
  void initialize(SecuredSharedPreferences prefs) => _prefs = prefs;

  // ------------------------------------------------------------------ Writes

  Future<void> saveLastNotificationDeviceName(String name) =>
      _save(_keyLastDeviceName, name);

  Future<void> saveSOSDeviceName(String name) =>
      _save(_keySosDeviceName, name);

  Future<void> savePowerCutDeviceName(String name) =>
      _save(_keyPowerCutDeviceName, name);

  Future<void> saveSpyModeDeviceName(String name) =>
      _save(_keySpyModeDeviceName, name);

  Future<void> setNewNotificationType(String type) =>
      _save(_keyLatestType, type);

  // ------------------------------------------------------------------- Reads

  Future<String> getLastNotificationDeviceName() => _read(_keyLastDeviceName);

  Future<String> getSOSDeviceName() => _read(_keySosDeviceName);

  Future<String> getPowerCutDeviceName() => _read(_keyPowerCutDeviceName);

  Future<String> getSpyModeDeviceName() => _read(_keySpyModeDeviceName);

  Future<String> getNewNotificationType() => _read(_keyLatestType);

  /// Drops everything. Call on sign-out so the next account does not inherit
  /// the previous one's alert history.
  Future<void> clear() async {
    final SecuredSharedPreferences? prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await Future.wait(<Future<void>>[
      prefs.remove(_keyLastDeviceName),
      prefs.remove(_keySosDeviceName),
      prefs.remove(_keyPowerCutDeviceName),
      prefs.remove(_keySpyModeDeviceName),
      prefs.remove(_keyLatestType),
    ]);
  }

  // ----------------------------------------------------------------- Backing

  Future<void> _save(String key, String value) async {
    final SecuredSharedPreferences? prefs = _prefs;
    if (prefs == null) {
      CustomLog.error(this, 'initialize() has not run — dropped write to $key');
      return;
    }
    await prefs.saveKey(key, value);
  }

  /// Missing reads come back as an empty string, which every caller already
  /// treats as "no device name known" via `isNotEmpty`.
  Future<String> _read(String key) async {
    final SecuredSharedPreferences? prefs = _prefs;
    if (prefs == null) {
      CustomLog.error(this, 'initialize() has not run — dropped read of $key');
      return '';
    }
    return await prefs.get(key) ?? '';
  }
}
