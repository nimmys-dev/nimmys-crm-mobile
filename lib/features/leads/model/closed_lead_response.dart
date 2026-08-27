/// Response for closing a lead.
class CloseLeadResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final CloseLeadData? data;

  CloseLeadResponse({
    this.status,
    this.statusCode,
    this.message,
    this.data,
  });

  factory CloseLeadResponse.fromJson(Map<String, dynamic> json) {
    return CloseLeadResponse(
      status: json["status"] as bool?,
      statusCode: json["status_code"] as int?,
      message: json["message"] as String?,
      data: json["data"] == null
          ? null
          : CloseLeadData.fromJson(json["data"] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "status": status,
        "status_code": statusCode,
        "message": message,
        if (data != null) "data": data!.toJson(),
      };
}

/// Data part of the close lead response.
class CloseLeadData {
  final int? id;
  final String? reference;
  final String? status; // e.g., "won", "lost"

  CloseLeadData({
    this.id,
    this.reference,
    this.status,
  });

  factory CloseLeadData.fromJson(Map<String, dynamic> json) {
    return CloseLeadData(
      id: _asInt(json["id"]),
      reference: json["reference"] as String?,
      status: json["status"] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        if (reference != null) "reference": reference,
        if (status != null) "status": status,
      };

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}