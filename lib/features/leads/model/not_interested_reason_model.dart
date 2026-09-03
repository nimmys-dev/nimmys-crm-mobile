class NotInterestedReasonModel {
  bool? status;
  int? statusCode;
  String? message;
  List<ReasonData>? data;

  NotInterestedReasonModel({
    this.status,
    this.statusCode,
    this.message,
    this.data,
  });

  factory NotInterestedReasonModel.fromJson(Map<String, dynamic> json) {
    return NotInterestedReasonModel(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: (json['data'] as List?)
          ?.map((e) => ReasonData.fromJson(e as Map<String, dynamic>))
          .toList(),
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

class ReasonData {
  String? name;
  String? value;

  ReasonData({
    this.name,
    this.value,
  });

  factory ReasonData.fromJson(Map<String, dynamic> json) {
    return ReasonData(
      name: json['name'] as String?,
      value: json['value'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}