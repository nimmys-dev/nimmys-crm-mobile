/// `POST /api/logout` response. The body carries no payload beyond the envelope —
/// revoking the token is the whole point of the call.
class LogoutSuccessModel {
  final bool? status;
  final int? statusCode;
  final String? message;

  LogoutSuccessModel({
    this.status,
    this.statusCode,
    this.message,
  });

  factory LogoutSuccessModel.fromJson(Map<String, dynamic> json) {
    return LogoutSuccessModel(
      status: json['status'],
      statusCode: json['status_code'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
    };
  }
}
