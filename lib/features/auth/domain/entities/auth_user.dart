import 'package:equatable/equatable.dart';

import '../../../../core/storage/auth_tokens.dart';

/// The signed-in person.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;

  /// Drives what the UI offers — an agent does not see the staff screens.
  final String? role;

  final String? avatarUrl;

  bool get isAdmin => role?.toLowerCase() == 'admin';

  @override
  List<Object?> get props => <Object?>[id, name, email, role, avatarUrl];
}

/// What a successful sign-in produces: who you are, and what proves it.
///
/// Kept together because the login response carries both and they must be
/// stored in one step — persisting the user without the tokens leaves the app
/// believing it is signed in with no way to make a request.
class AuthSession extends Equatable {
  const AuthSession({required this.user, required this.tokens});

  final AuthUser user;
  final AuthTokens tokens;

  @override
  List<Object?> get props => <Object?>[user, tokens];
}
