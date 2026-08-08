/// `DELETE /api/delete-staff/{id}` response.
class DeleteStaffSuccess {
  DeleteStaffSuccess({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final bool? status;
  final int? statusCode;
  final String? message;
  final DeleteStaffData? data;

  factory DeleteStaffSuccess.fromJson(Map<String, dynamic> json) {
    return DeleteStaffSuccess(
      status: json["status"],
      statusCode: json["status_code"],
      message: json["message"],
      data: json["data"] == null
          ? null
          : DeleteStaffData.fromJson(json["data"]),
    );
  }
}

class DeleteStaffData {
  DeleteStaffData({required this.id, this.deletedAt});

  final int? id;
  final DateTime? deletedAt;

  factory DeleteStaffData.fromJson(Map<String, dynamic> json) {
    return DeleteStaffData(
      id: _asInt(json["id"]),
      deletedAt: json["deleted_at"] is String
          ? DateTime.tryParse(json["deleted_at"])
          : null,
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
}
