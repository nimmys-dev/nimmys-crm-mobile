/// `POST /api/create-staff` response.
class CreateStaffSuccess {
  CreateStaffSuccess({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final bool? status;
  final int? statusCode;
  final String? message;
  final CreateStaffData? data;

  factory CreateStaffSuccess.fromJson(Map<String, dynamic> json) {
    // The created record arrives under "data" — the same envelope every other
    // CRM endpoint uses.
    return CreateStaffSuccess(
      status: json["status"],
      statusCode: json["status_code"],
      message: json["message"],
      data: json["data"] == null
          ? null
          : CreateStaffData.fromJson(json["data"]),
    );
  }
}

class CreateStaffData {
  CreateStaffData({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.shopId,
    required this.role,
    required this.status,
    required this.photo,
    required this.photoUrl,
  });

  final int? id;
  final String? employeeCode;
  final String? name;
  final String? email;
  final String? phone;
  final String? shopId;
  final String? role;
  final String? status;
  final String? photo;
  final String? photoUrl;

  factory CreateStaffData.fromJson(Map<String, dynamic> json) {
    return CreateStaffData(
      id: _asInt(json["id"]),
      employeeCode: json["employee_code"],
      name: json["name"],
      email: json["email"],
      phone: json["phone"],
      shopId: json["shop_id"]?.toString(),
      role: json["role"],
      status: json["status"],
      photo: json["photo"],
      photoUrl: json["photo_url"],
    );
  }

  /// `shop_id` comes back as the string `"2"` while `id` comes back as a
  /// number, so neither field can assume its JSON type.
  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
