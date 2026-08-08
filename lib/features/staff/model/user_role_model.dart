/// `GET /api/user-roles` response — the roles a staff record may be given.
class UserRoleSuccess {
  UserRoleSuccess({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final bool? status;
  final int? statusCode;
  final String? message;
  final List<UserRoleOption> data;

  factory UserRoleSuccess.fromJson(Map<String, dynamic> json) {
    return UserRoleSuccess(
      status: json["status"],
      statusCode: json["status_code"],
      message: json["message"],
      data: json["data"] == null
          ? <UserRoleOption>[]
          : List<UserRoleOption>.from(
              json["data"]!.map((x) => UserRoleOption.fromJson(x)),
            ),
    );
  }

  /// The roles worth offering: anything the API can actually accept back.
  /// A row with no `value` has nothing to send as `role`, so it is dropped
  /// rather than shown as a choice that would 422 on save.
  List<UserRoleOption> get selectableRoles =>
      data.where((UserRoleOption role) => role.isSelectable).toList();
}

/// One role: what the user reads, and what the API is sent.
///
/// This pair is the whole reason the endpoint exists — the picker shows
/// [label] ("Manager") while Create Staff sends [value] ("manager"). Nothing in
/// the app has to hard-code that mapping any more.
class UserRoleOption {
  UserRoleOption({required this.value, required this.label});

  /// What `role` is set to on the create request.
  final String? value;

  /// What the picker displays.
  final String? label;

  factory UserRoleOption.fromJson(Map<String, dynamic> json) {
    return UserRoleOption(value: json["value"], label: json["label"]);
  }

  bool get isSelectable => value != null && value!.isNotEmpty;

  /// Falls back to the raw value so a role the API sends without a label is
  /// still readable rather than blank.
  String get displayLabel {
    final String? text = label;
    if (text != null && text.trim().isNotEmpty) {
      return text;
    }
    return value ?? '';
  }
}
