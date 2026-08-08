/// `GET /api/profile` response.
///
/// Every field is nullable because the API sends `null` for anything the staff
/// record has not filled in yet — `shop_id`, `phone` and `photo` all arrive that
/// way on a manager account.
class ProfileSuccessModel {
  final bool? status;
  final int? statusCode;
  final String? message;
  final ProfileUser? user;

  ProfileSuccessModel({
    this.status,
    this.statusCode,
    this.message,
    this.user,
  });

  factory ProfileSuccessModel.fromJson(Map<String, dynamic> json) {
    return ProfileSuccessModel(
      status: json['status'],
      statusCode: json['status_code'],
      message: json['message'],
      user: json['user'] != null ? ProfileUser.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
      'user': user?.toJson(),
    };
  }
}

class ProfileUser {
  final int? id;
  final int? shopId;
  final String? employeeCode;
  final String? name;
  final String? email;
  final String? phone;
  final String? photo;
  final String? role;
  final String? status;

  ProfileUser({
    this.id,
    this.shopId,
    this.employeeCode,
    this.name,
    this.email,
    this.phone,
    this.photo,
    this.role,
    this.status,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: _asInt(json['id']),
      shopId: _asInt(json['shop_id']),
      employeeCode: json['employee_code'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      photo: json['photo'],
      role: json['role'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'employee_code': employeeCode,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'role': role,
      'status': status,
    };
  }

  /// Ids come back as numbers today, but Laravel serialises them as strings
  /// under some driver/column combinations — parsing both keeps a config change
  /// on the server from turning into a cast crash on the phone.
  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Up to two letters for the header avatar: "Manager" → "MA",
  /// "Abin Babu" → "AB", empty → "?" so the circle is never blank.
  String get initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final single = parts.first;
      return (single.length == 1 ? single : single.substring(0, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isActive => status?.toLowerCase() == 'active';
}
