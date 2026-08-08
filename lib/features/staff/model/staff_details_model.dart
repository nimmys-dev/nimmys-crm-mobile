/// `GET /api/view-staff/{id}` response — and, since the two share the same
/// envelope and `data` shape, `POST /api/update-staff/{id}`'s response too.
class StaffDetailsSuccess {
  StaffDetailsSuccess({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final bool? status;
  final int? statusCode;
  final String? message;
  final StaffDetailsData? data;

  factory StaffDetailsSuccess.fromJson(Map<String, dynamic> json) {
    return StaffDetailsSuccess(
      status: json["status"],
      statusCode: json["status_code"],
      message: json["message"],
      data: json["data"] == null
          ? null
          : StaffDetailsData.fromJson(json["data"]),
    );
  }
}

/// The full staff record — every field Staff Creation's form can edit, plus
/// the record's own identity and timestamps.
///
/// Everything but [id] is nullable: a view-staff call the app made mid-session
/// returned a record with no `alternate_phone`, `joining_date`, `salary`,
/// `increment_date`, `increment_amount`, `increment_notification`,
/// `lead_module_access` or `description` at all — those columns simply were
/// not set on that staff member yet, and the API omits rather than nulls them.
class StaffDetailsData {
  StaffDetailsData({
    required this.id,
    this.employeeCode,
    this.name,
    this.email,
    this.phone,
    this.alternatePhone,
    this.shopId,
    this.role,
    this.status,
    this.joiningDate,
    this.salary,
    this.incrementDate,
    this.incrementAmount,
    this.incrementNotification,
    this.leadModuleAccess,
    this.description,
    this.photo,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? employeeCode;
  final String? name;
  final String? email;
  final String? phone;
  final String? alternatePhone;
  final int? shopId;
  final String? role;
  final String? status;

  /// Parsed from the API's ISO 8601 timestamp. Requests send `dd-MM-yyyy` (see
  /// `DateTimeHelper.getApiDateFormat`) — the two formats never mix, since one
  /// is only ever read and the other only ever written.
  final DateTime? joiningDate;

  /// Decimal string as the API sends it, e.g. `"20000.00"` — left unparsed so
  /// the screen decides how to present it rather than the model rounding on
  /// its behalf.
  final String? salary;
  final DateTime? incrementDate;
  final String? incrementAmount;
  final bool? incrementNotification;
  final bool? leadModuleAccess;
  final String? description;
  final String? photo;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StaffDetailsData.fromJson(Map<String, dynamic> json) {
    return StaffDetailsData(
      id: _asInt(json["id"]),
      employeeCode: json["employee_code"],
      name: json["name"],
      email: json["email"],
      phone: json["phone"],
      alternatePhone: json["alternate_phone"],
      shopId: _asInt(json["shop_id"]),
      role: json["role"],
      status: json["status"],
      joiningDate: _asDate(json["joining_date"]),
      salary: json["salary"]?.toString(),
      incrementDate: _asDate(json["increment_date"]),
      incrementAmount: json["increment_amount"]?.toString(),
      incrementNotification: _asBool(json["increment_notification"]),
      leadModuleAccess: _asBool(json["lead_module_access"]),
      description: json["description"],
      photo: json["photo"],
      photoUrl: json["photo_url"],
      createdAt: _asDate(json["created_at"]),
      updatedAt: _asDate(json["updated_at"]),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// `increment_notification`/`lead_module_access` come back as real booleans
  /// on this endpoint, unlike the `"1"`/`"0"` the create/update request sends —
  /// tolerated alongside numbers and stringly-typed booleans in case a future
  /// response shape changes it again.
  static bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return null;
  }

  static DateTime? _asDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  bool get isActive => status?.toLowerCase() == 'active';

  /// Up to two letters for the details header avatar, matching
  /// `StaffListItem.initials`/`ProfileUser.initials`: "Thomas John" → "TJ",
  /// "Admin" → "AD", empty → "?".
  String get initials {
    final List<String> parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final String single = parts.first;
      return (single.length == 1 ? single : single.substring(0, 2))
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}
