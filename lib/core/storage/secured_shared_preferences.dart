import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../utils/custom_log.dart';

/// Loose-key storage backed by the Keychain / EncryptedSharedPreferences.
///
/// [TokenStorage] already covers auth credentials as one typed record. This is
/// its untyped counterpart, for the handful of values the notification stack
/// has to remember across launches — the FCM token, the device that raised the
/// last alert — which have no business sitting in a plain-text XML file.
///
/// Every method swallows platform failures and degrades to "nothing stored".
/// An invalidated Android keystore (the user changed their lock screen) must
/// not be able to take down notification setup.
class SecuredSharedPreferences {
  SecuredSharedPreferences(this._storage);

  /// The same hardening [SecureTokenStorage] uses: AES-backed on Android, and
  /// out of iCloud Keychain sync on iOS while still readable in the background.
  factory SecuredSharedPreferences.standard() => SecuredSharedPreferences(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  );

  final FlutterSecureStorage _storage;

  Future<void> saveKey(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      CustomLog.error(this, 'Failed to write "$key"', e);
    }
  }

  Future<String?> get(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      CustomLog.error(this, 'Failed to read "$key"', e);
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      CustomLog.error(this, 'Failed to delete "$key"', e);
    }
  }

  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      CustomLog.error(this, 'Failed to clear storage', e);
    }
  }
}
