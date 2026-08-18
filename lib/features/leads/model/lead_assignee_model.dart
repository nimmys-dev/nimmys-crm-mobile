/// `GET /api/lead-assignees` response — staff members who can be assigned a lead.
class LeadAssigneeSuccess {
  LeadAssigneeSuccess({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final bool? status;
  final int? statusCode;
  final String? message;
  final List<LeadAssigneeData> data;

  factory LeadAssigneeSuccess.fromJson(Map<String, dynamic> json) {
    return LeadAssigneeSuccess(
      status: json["status"] as bool?,
      statusCode: json["status_code"] as int?,
      message: json["message"] as String?,
      data: json["data"] == null
          ? <LeadAssigneeData>[]
          : List<LeadAssigneeData>.from(
              (json["data"] as List<dynamic>).map(
                (dynamic x) =>
                    LeadAssigneeData.fromJson(x as Map<String, dynamic>),
              ),
            ),
    );
  }

  /// The assignees that have both an id and a valid name.
  List<LeadAssigneeData> get validAssignees =>
      data
          .where(
            (LeadAssigneeData item) =>
                item.id != null &&
                (item.name != null && item.name!.trim().isNotEmpty),
          )
          .toList(growable: false);
}

/// One assignee candidate for a lead.
class LeadAssigneeData {
  LeadAssigneeData({
    required this.id,
    required this.name,
  });

  final int? id;
  final String? name;

  factory LeadAssigneeData.fromJson(Map<String, dynamic> json) {
    return LeadAssigneeData(
      id: _asInt(json["id"]),
      name: json["name"] as String?,
    );
  }

  /// Parses both integer numbers and string-encoded integers defensibly.
  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    "id": id,
    "name": name,
  };
}
