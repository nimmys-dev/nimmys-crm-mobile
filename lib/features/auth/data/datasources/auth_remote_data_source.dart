import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/storage/auth_tokens.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/auth_user.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthUser> currentUser();

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final ApiResponse<AuthSession> response = await _client.post<AuthSession>(
      Endpoints.login,
      body: <String, dynamic>{'email': email.trim(), 'password': password},
      // Public: no token to attach, and — more importantly — a 401 here means
      // "wrong password", not "expired session". Without this flag the auth
      // interceptor would try to refresh and then force a logout on what is
      // really just a typo.
      config: RequestConfig.public,
      parser: (dynamic json) {
        final Map<String, dynamic> map = json as Map<String, dynamic>;
        return AuthSession(
          user: _userFrom(map.mapOrNull('user') ?? map),
          tokens: AuthTokens.fromJson(map),
        );
      },
    );
    return response.data;
  }

  @override
  Future<AuthUser> currentUser() async {
    final ApiResponse<AuthUser> response = await _client.get<AuthUser>(
      Endpoints.currentUser,
      parser: (dynamic json) => _userFrom(json as Map<String, dynamic>),
    );
    return response.data;
  }

  @override
  Future<void> logout() => _client.post<void>(
    Endpoints.logout,
    // Replaying a logout is harmless, but there is nothing to gain from it
    // either — the local session is cleared regardless of the outcome.
    config: const RequestConfig(allowRetry: false),
    parser: (dynamic _) {},
  );

  static AuthUser _userFrom(Map<String, dynamic> json) => AuthUser(
    id: json.stringOr('id'),
    name: json.stringOr('name'),
    email: json.stringOr('email'),
    role: json.stringOrNull('role'),
    avatarUrl: json.stringOrNull('avatar_url') ?? json.stringOrNull('avatar'),
  );
}
