class ForgotPasswordResponse {
  final bool status;
  final int statusCode;
  final String message;

  ForgotPasswordResponse({required this.status, required this.statusCode, required this.message});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      status: json['status'] ?? false,
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}