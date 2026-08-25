class TaskTypeModel {
  final bool? status;
  final int? statusCode;
  final String? message;
  final List<TaskTypeItem>? data;

  TaskTypeModel({
    this.status,
    this.statusCode,
    this.message,
    this.data,
  });

  factory TaskTypeModel.fromJson(Map<String, dynamic> json) {
    return TaskTypeModel(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => TaskTypeItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class TaskTypeItem {
  final String? value;
  final String? label;

  TaskTypeItem({
    this.value,
    this.label,
  });

  factory TaskTypeItem.fromJson(Map<String, dynamic> json) {
    return TaskTypeItem(
      value: json['value'] as String?,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}