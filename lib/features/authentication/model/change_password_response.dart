class ChangePasswordResponse {
  const ChangePasswordResponse({this.status, this.statusCode, this.message});

  final bool? status;
  final int? statusCode;
  final String? message;

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) =>
      ChangePasswordResponse(
        status: json['status'] as bool?,
        statusCode: json['status_code'] as int?,
        message: json['message'] as String?,
      );
}
