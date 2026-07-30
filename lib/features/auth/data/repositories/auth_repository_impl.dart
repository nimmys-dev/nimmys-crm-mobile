import '../../../../core/error/app_exception.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Owns the sign-in and sign-out side effects.
///
/// This is the only place that writes tokens. Everything else — the
/// interceptor, the router, the profile screen — reads them through
/// [SessionManager], so there is exactly one path into an authenticated
/// state and exactly one out.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SessionManager session,
    required NetworkInfo networkInfo,
  }) : _remote = remote,
       _session = session,
       _networkInfo = networkInfo;

  final AuthRemoteDataSource _remote;
  final SessionManager _session;
  final NetworkInfo _networkInfo;

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) => guard(() async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException();
    }

    final AuthSession session = await _remote.login(
      email: email,
      password: password,
    );

    // Persist before returning: the caller will navigate immediately, and the
    // first screen it lands on will fire a request that needs this token.
    await _session.onSignedIn(session.tokens);
    return session.user;
  });

  @override
  Future<Result<AuthUser>> currentUser() => guard(_remote.currentUser);

  /// Clears the local session whether or not the server agrees.
  ///
  /// The server call is best-effort — it revokes the refresh token, which is
  /// worth attempting — but a user who taps "sign out" on a train with no
  /// signal must still end up signed out. Letting a network failure block it
  /// would leave valid tokens on the device, which is the worse outcome.
  @override
  Future<Result<void>> logout() => guard(() async {
    try {
      await _remote.logout();
    } on AppException {
      // Intentionally swallowed; the local clear below is what matters.
    }
    await _session.signOut();
  });
}
