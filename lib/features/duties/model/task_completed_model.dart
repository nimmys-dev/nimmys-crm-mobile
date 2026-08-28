/// Response for completing a task.
class TaskCompleteResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final TaskCompleteData? data;

  TaskCompleteResponse({
    this.status,
    this.statusCode,
    this.message,
    this.data,
  });

  factory TaskCompleteResponse.fromJson(Map<String, dynamic> json) {
    return TaskCompleteResponse(
      status: json["status"] as bool?,
      statusCode: json["status_code"] as int?,
      message: json["message"] as String?,
      data: json["data"] == null
          ? null
          : TaskCompleteData.fromJson(json["data"] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "status": status,
        "status_code": statusCode,
        "message": message,
        if (data != null) "data": data!.toJson(),
      };
}

/// Data part of the task completion response.
class TaskCompleteData {
  final int? taskId;
  final String? status;
  final String? remarks;

  TaskCompleteData({
    this.taskId,
    this.status,
    this.remarks,
  });

  factory TaskCompleteData.fromJson(Map<String, dynamic> json) {
    return TaskCompleteData(
      taskId: json["task_id"] as int?,
      status: json["status"] as String?,
      remarks: json["remarks"] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "task_id": taskId,
        if (status != null) "status": status,
        if (remarks != null) "remarks": remarks,
      };
}