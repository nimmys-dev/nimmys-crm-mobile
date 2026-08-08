class LoginSuccessModel {
  final bool? status;
  final int? statusCode;
  final String? message;
  final String? token;
  final User? user;

  LoginSuccessModel({
    this.status,
    this.statusCode,
    this.message,
    this.token,
    this.user,
  });

  factory LoginSuccessModel.fromJson(Map<String, dynamic> json) {
    return LoginSuccessModel(
      status: json['status'],
      statusCode: json['status_code'],
      message: json['message'],
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
      'token': token,
      'user': user?.toJson(),
    };
  }
}

class User {
  final int? id;
  final String? name;
  final String? email;
  final String? role;

  User({
    this.id,
    this.name,
    this.email,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}