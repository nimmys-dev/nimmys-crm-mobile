import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';

/// Response for `POST /api/tasks/{id}/approve`.
class ApproveTaskSuccessResponse {
  final bool? status;
  final String? message;
  final Task? data;

  const ApproveTaskSuccessResponse({
    this.status,
    this.message,
    this.data,
  });

  factory ApproveTaskSuccessResponse.fromJson(Map<String, dynamic> json) {
    return ApproveTaskSuccessResponse(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? Task.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}
