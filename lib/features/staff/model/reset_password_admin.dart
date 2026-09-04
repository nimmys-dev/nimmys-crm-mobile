class StaffPasswordResetFromAdmin {
  final bool? status;
  final String? message;
  final Data? data;

  StaffPasswordResetFromAdmin({
    this.status,
    this.message,
    this.data,
  });

  factory StaffPasswordResetFromAdmin.fromJson(Map<String, dynamic> json) {
    return StaffPasswordResetFromAdmin(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? Data.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class Data {
  final int? id;
  final String? name;
  final String? email;
  final String? updatedAt;

  Data({
    this.id,
    this.name,
    this.email,
    this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'updated_at': updatedAt,
    };
  }
}