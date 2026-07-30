import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_tokens.dart';

/// Where credentials live between launches.
abstract interface class TokenStorage {
  Future<AuthTokens?> read();

  Future<void> write(AuthTokens tokens);

  Future<void> clear();
}

/// Keychain-backed storage, with the current tokens mirrored in memory.
///
/// The mirror matters: the auth interceptor reads tokens on *every* request,
/// and a Keychain/KeyStore round trip is a platform-channel hop costing
/// milliseconds each time. Reading from memory keeps request setup free while
/// the encrypted store stays the source of truth across launches.
///
/// Deliberately not `SharedPreferences` — that is a plain XML file, readable
/// on a rooted or jailbroken device and included in some backup flows.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  /// Builds the platform-hardened configuration.
  ///
  /// `encryptedSharedPreferences` opts Android into the AES-backed
  /// implementation; `first_unlock_this_device` keeps iOS tokens out of
  /// iCloud Keychain sync while still allowing background refresh.
  factory SecureTokenStorage.standard() => SecureTokenStorage(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  );

  static const String _key = 'auth.tokens.v1';

  final FlutterSecureStorage _storage;

  AuthTokens? _cached;
  bool _loaded = false;

  @override
  Future<AuthTokens?> read() async {
    if (_loaded) {
      return _cached;
    }
    try {
      _cached = AuthTokens.decode(await _storage.read(key: _key));
    } catch (_) {
      // A read can fail on Android if the keystore was invalidated (for
      // example the user changed their lock screen). Treat it as signed out
      // instead of blocking launch behind an unrecoverable error.
      _cached = null;
    }
    _loaded = true;
    return _cached;
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    // Cache first so a concurrent request never reads a stale token while
    // the platform write is still in flight.
    _cached = tokens;
    _loaded = true;
    await _storage.write(key: _key, value: tokens.encode());
  }

  @override
  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _key);
  }
}

/// In-memory storage for tests and previews.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this._tokens]);

  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
