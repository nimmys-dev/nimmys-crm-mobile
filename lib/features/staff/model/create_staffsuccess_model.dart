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

    factory CreateStaffSuccess.fromJson(Map<String, dynamic> json){ 
        return CreateStaffSuccess(
            status: json["status"],
            statusCode: json["status_code"],
            message: json["message"],
            data: json["CreateStaffData"] == null ? null : CreateStaffData.fromJson(json["CreateStaffData"]),
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

    factory CreateStaffData.fromJson(Map<String, dynamic> json){ 
        return CreateStaffData(
            id: json["id"],
            employeeCode: json["employee_code"],
            name: json["name"],
            email: json["email"],
            phone: json["phone"],
            shopId: json["shop_id"],
            role: json["role"],
            status: json["status"],
            photo: json["photo"],
            photoUrl: json["photo_url"],
        );
    }

}
