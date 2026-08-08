/// Bridges the designations shown on Staff Creation and the `role` value the
/// CRM API accepts.
///
/// ASSUMPTION — the two are not the same vocabulary. "Manager", "BDE",
/// "Team Lead" and "Driver" are job titles the UI has always offered; the only
/// `role` value the API is documented to accept for a staff record is
/// `employee` (it is what `POST /api/create-staff` echoes back, and what
/// `GET /api/profile` returns for a staff account). Nothing in this project maps
/// one onto the other, so every designation is sent as [_defaultApiRole] rather
/// than guessing at values — `role=manager` would be a 422 if the backend's
/// `in:` rule does not list it.
///
/// When the backend publishes its real role list, change the right-hand side of
/// [_apiValues]; no other file needs to move.
class StaffRoles {
  StaffRoles._();

  /// Every staff member created from this screen is an employee of the shop.
  static const String _defaultApiRole = 'employee';

  /// Designations offered in the Role picker, in display order.
  static const List<String> options = <String>[
    'Manager',
    'BDE',
    'Team Lead',
    'Driver',
  ];

  static const Map<String, String> _apiValues = <String, String>{
    'Manager': _defaultApiRole,
    'BDE': _defaultApiRole,
    'Team Lead': _defaultApiRole,
    'Driver': _defaultApiRole,
  };

  /// The `role` field for [label]. Falls back to [_defaultApiRole] so a
  /// designation added to [options] without a mapping still submits.
  static String apiValue(String? label) =>
      _apiValues[label] ?? _defaultApiRole;
}
