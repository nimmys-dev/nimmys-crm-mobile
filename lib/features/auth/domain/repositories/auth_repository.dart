import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  /// Signs in and, on success, hands the tokens to the session manager so
  /// every later request is authenticated. Callers only see the user.
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  });

  /// Re-reads the profile for an already-restored session, which is also the
  /// cheapest way to find out whether a persisted token is still good.
  Future<Result<AuthUser>> currentUser();

  /// Ends the session locally even if the server call fails — see the
  /// implementation for why that is the right way round.
  Future<Result<void>> logout();
}
