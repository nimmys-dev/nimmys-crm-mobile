/// Response wrapper for the lead sources list.
class LeadSourceModel {
  final bool? status;
  final int? statusCode;
  final String? message;
  final List<LeadSourceData>? data;

  LeadSourceModel({
    this.status,
    this.statusCode,
    this.message,
    this.data,
  });

  factory LeadSourceModel.fromJson(Map<String, dynamic> json) {
    return LeadSourceModel(
      status: json["status"] as bool?,
      statusCode: json["status_code"] as int?,
      message: json["message"] as String?,
      data: (json["data"] as List?)
          ?.map((item) => LeadSourceData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "status": status,
        "status_code": statusCode,
        "message": message,
        if (data != null) "data": data!.map((e) => e.toJson()).toList(),
      };
}

/// A single lead source (value-label pair).
class LeadSourceData {
  final String? value;
  final String? label;

  LeadSourceData({
    this.value,
    this.label,
  });

  factory LeadSourceData.fromJson(Map<String, dynamic> json) {
    return LeadSourceData(
      value: json["value"] as String?,
      label: json["label"] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "value": value,
        "label": label,
      };
}