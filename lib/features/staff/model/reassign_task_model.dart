/// Response for reassigning tasks.
class ReassignTaskResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final ReassignTaskData? data;

  ReassignTaskResponse({
    this.status,
    this.statusCode,
    this.message,
    this.data,
  });

  factory ReassignTaskResponse.fromJson(Map<String, dynamic> json) {
    return ReassignTaskResponse(
      status: json["status"] as bool?,
      statusCode: json["status_code"] as int?,
      message: json["message"] as String?,
      data: json["data"] == null
          ? null
          : ReassignTaskData.fromJson(json["data"] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "status": status,
        "status_code": statusCode,
        "message": message,
        if (data != null) "data": data!.toJson(),
      };
}

/// Data part of the reassign response.
class ReassignTaskData {
  final List<int>? taskIds;
  final AssignedTo? assignedTo;

  ReassignTaskData({
    this.taskIds,
    this.assignedTo,
  });

  factory ReassignTaskData.fromJson(Map<String, dynamic> json) {
    return ReassignTaskData(
      taskIds: (json["task_ids"] as List?)
          ?.map((e) => e as int)
          .toList(),
      assignedTo: json["assigned_to"] == null
          ? null
          : AssignedTo.fromJson(json["assigned_to"] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "task_ids": taskIds,
        if (assignedTo != null) "assigned_to": assignedTo!.toJson(),
      };
}

/// Staff the tasks were reassigned to.
class AssignedTo {
  final int? id;
  final String? name;
  final String? role;

  AssignedTo({
    this.id,
    this.name,
    this.role,
  });

  factory AssignedTo.fromJson(Map<String, dynamic> json) {
    return AssignedTo(
      id: _asInt(json["id"]),
      name: json["name"] as String?,
      role: json["role"] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        if (name != null) "name": name,
        if (role != null) "role": role,
      };

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}