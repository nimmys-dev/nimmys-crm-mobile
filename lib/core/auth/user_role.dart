/// The roles the CRM API issues in `user.role` on login.
///
/// [apiValue] is the wire format — matching is case-insensitive and trimmed
/// because a role is compared against a value that travelled through JSON and
/// secure storage, not against a literal typed in this file.
enum UserRole {
  admin('admin'),
  manager('manager'),
  employee('employee'),

  /// No session yet, or a role this build does not know. Carries no
  /// permissions, so an unrecognised role fails closed rather than inheriting
  /// admin by accident.
  unknown('');

  const UserRole(this.apiValue);

  final String apiValue;

  static UserRole fromApi(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return UserRole.unknown;
    }
    for (final UserRole role in UserRole.values) {
      if (role != UserRole.unknown && role.apiValue == normalized) {
        return role;
      }
    }
    return UserRole.unknown;
  }

  /// Display form for the profile chip and the access-denied screen.
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.employee:
        return 'Employee';
      case UserRole.unknown:
        return 'Staff';
    }
  }
}
