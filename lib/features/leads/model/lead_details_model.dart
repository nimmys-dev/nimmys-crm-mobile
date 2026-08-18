/// `GET /api/view-lead/{leadId}` response.
class LeadDetailsSuccess {
  LeadDetailsSuccess({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final bool? status;
  final int? statusCode;
  final String? message;
  final LeadDetailsData? data;

  factory LeadDetailsSuccess.fromJson(Map<String, dynamic> json) {
    return LeadDetailsSuccess(
      status: json["status"] as bool?,
      statusCode: json["status_code"] as int?,
      message: json["message"] as String?,
      data: json["data"] == null
          ? null
          : LeadDetailsData.fromJson(json["data"] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    "status": status,
    "status_code": statusCode,
    "message": message,
    if (data != null) "data": data!.toJson(),
  };
}

/// Detailed data for a single lead.
class LeadDetailsData {
  LeadDetailsData({
    required this.id,
    this.reference,
    this.name,
    this.phone,
    this.source,
    this.assignedTo,
    this.createdBy,
    this.description,
  });

  final int? id;
  final String? reference;
  final String? name;
  final String? phone;
  final String? source;
  final String? assignedTo;
  final String? createdBy;
  final String? description;

  factory LeadDetailsData.fromJson(Map<String, dynamic> json) {
    return LeadDetailsData(
      id: _asInt(json["id"]),
      reference: json["reference"] as String?,
      name: json["name"] as String?,
      phone: json["phone"] as String?,
      source: json["source"] as String?,
      assignedTo: json["assigned_to"] as String?,
      createdBy: json["created_by"] as String?,
      description: json["description"] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    "id": id,
    if (reference != null) "reference": reference,
    if (name != null) "name": name,
    if (phone != null) "phone": phone,
    if (source != null) "source": source,
    if (assignedTo != null) "assigned_to": assignedTo,
    if (createdBy != null) "created_by": createdBy,
    if (description != null) "description": description,
  };

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  /// Plain display text from the description, stripping HTML tags like `<p>`.
  String get cleanDescription {
    if (description == null || description!.trim().isEmpty) {
      return '';
    }
    return description!
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Up to two letters for the initial avatar.
  String get initials {
    final List<String> parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final String single = parts.first;
      return (single.length == 1 ? single : single.substring(0, 1))
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}
