import 'dart:async';

import '../storage/auth_tokens.dart';
import '../storage/token_storage.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

/// Why a session ended, so the UI can say something true.
///
/// "You have been signed out" after a deliberate tap is fine; after a silent
/// token expiry it is confusing. Carrying the reason lets one listener handle
/// both without guessing.
enum SessionEndReason {
  /// The user asked to sign out.
  userInitiated,

  /// The refresh token was rejected or absent when a 401 arrived.
  expired,

  /// The server revoked the session (password change, admin action).
  revoked,
}

/// The app's single source of truth for "is someone signed in".
///
/// Everything that cares about auth reads this one object: the interceptor
/// takes tokens from it, the login flow pushes tokens into it, and the router
/// listens to [changes] to bounce to the login screen. Without a central
/// owner, a forced logout has to be plumbed through every repository that
/// might be the one to see the 401.
class SessionManager {
  SessionManager(this._storage);

  final TokenStorage _storage;

  final StreamController<SessionStatus> _statusController =
      StreamController<SessionStatus>.broadcast();

  final StreamController<SessionEndReason> _endedController =
      StreamController<SessionEndReason>.broadcast();

  SessionStatus _status = SessionStatus.unknown;
  AuthTokens? _tokens;

  /// Status transitions. Broadcast, so the router, an analytics listener and
  /// a push-notification de-registration can all subscribe independently.
  Stream<SessionStatus> get changes => _statusController.stream;

  /// Fires only on sign-out, carrying the cause. Listen here to show the
  /// "your session expired" message exactly once.
  Stream<SessionEndReason> get onEnded => _endedController.stream;

  SessionStatus get status => _status;

  AuthTokens? get tokens => _tokens;

  bool get isAuthenticated => _status == SessionStatus.authenticated;

  /// Loads any persisted session. Call once during start-up, before the first
  /// frame, so the app opens on the right screen instead of flashing login.
  Future<SessionStatus> restore() async {
    _tokens = await _storage.read();
    _setStatus(
      _tokens == null
          ? SessionStatus.unauthenticated
          : SessionStatus.authenticated,
    );
    return _status;
  }

  /// Records a successful sign-in.
  Future<void> onSignedIn(AuthTokens tokens) async {
    _tokens = tokens;
    await _storage.write(tokens);
    _setStatus(SessionStatus.authenticated);
  }

  /// Records a refreshed access token.
  ///
  /// Does not touch [status]: a refresh is invisible to the user and must not
  /// make the router think anything changed.
  Future<void> onTokensRefreshed(AuthTokens tokens) async {
    _tokens = tokens;
    await _storage.write(tokens);
  }

  /// Clears the session and tells everyone why.
  ///
  /// Idempotent, because several in-flight requests can each conclude the
  /// session is dead at the same moment and they must not produce a stack of
  /// "signed out" dialogs.
  Future<void> signOut({
    SessionEndReason reason = SessionEndReason.userInitiated,
  }) async {
    if (_status == SessionStatus.unauthenticated) {
      return;
    }
    _tokens = null;
    await _storage.clear();
    _setStatus(SessionStatus.unauthenticated);
    if (!_endedController.isClosed) {
      _endedController.add(reason);
    }
  }

  void _setStatus(SessionStatus status) {
    if (_status == status) {
      return;
    }
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<void> dispose() async {
    await _statusController.close();
    await _endedController.close();
  }
}
