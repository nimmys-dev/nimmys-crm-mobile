class ReassignLeadResponse {
  ReassignLeadResponse({this.success, this.message});

  final bool? success;
  final String? message;

  factory ReassignLeadResponse.fromJson(Map<String, dynamic> json) {
    return ReassignLeadResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }
}
