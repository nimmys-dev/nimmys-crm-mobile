/// `GET /api/leads?per_page=10&page=1` response.
class LeadListResponse {
  LeadListResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
    required this.pagination,
  });

  final bool? status;
  final int? statusCode;
  final String? message;
  final List<LeadItemData> data;
  final LeadPagination? pagination;

  factory LeadListResponse.fromJson(Map<String, dynamic> json) {
    return LeadListResponse(
      status: json["status"] as bool?,
      statusCode: json["status_code"] as int?,
      message: json["message"] as String?,
      data: json["data"] == null
          ? <LeadItemData>[]
          : List<LeadItemData>.from(
              (json["data"] as List<dynamic>).map(
                (dynamic x) => LeadItemData.fromJson(x as Map<String, dynamic>),
              ),
            ),
      pagination: json["pagination"] == null
          ? null
          : LeadPagination.fromJson(json["pagination"] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    "status": status,
    "status_code": statusCode,
    "message": message,
    "data": data.map((LeadItemData x) => x.toJson()).toList(),
    if (pagination != null) "pagination": pagination!.toJson(),
  };
}

/// One row of the leads list from `GET /api/leads`.
class LeadItemData {
  LeadItemData({
    required this.id,
    this.reference,
    this.name,
    this.phone,
    this.source,
    this.assignedTo,
    this.createdBy,
    this.description,
    this.has_quotation,
  });

  final int? id;
  final String? reference;
  final String? name;
  final String? phone;
  final String? source;
  final String? assignedTo;
  final String? createdBy;
  final String? description;
  final bool? has_quotation;

  factory LeadItemData.fromJson(Map<String, dynamic> json) {
    return LeadItemData(
      id: _asInt(json["id"]),
      reference: json["reference"] as String?,
      name: json["name"] as String?,
      phone: json["phone"] as String?,
      source: json["source"] as String?,
      assignedTo: json["assigned_to"] as String?,
      createdBy: json["created_by"] as String?,
      description: json["description"] as String?,
      has_quotation: json["has_quotation"] as bool?
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
    if (has_quotation != null) "has_quotation": has_quotation,
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

  /// Up to two letters for the initial bubble (e.g., "Sijo" -> "S", "John Doe" -> "JD").
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

/// The `pagination` metadata object returned with `/api/leads`.
class LeadPagination {
  LeadPagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
  });

  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;
  final int? from;
  final int? to;

  factory LeadPagination.fromJson(Map<String, dynamic> json) {
    return LeadPagination(
      currentPage: _asInt(json["current_page"]),
      lastPage: _asInt(json["last_page"]),
      perPage: _asInt(json["per_page"]),
      total: _asInt(json["total"]),
      from: _asInt(json["from"]),
      to: _asInt(json["to"]),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (currentPage != null) "current_page": currentPage,
    if (lastPage != null) "last_page": lastPage,
    if (perPage != null) "per_page": perPage,
    if (total != null) "total": total,
    if (from != null) "from": from,
    if (to != null) "to": to,
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

  bool get hasNextPage {
    if (currentPage != null && lastPage != null) {
      return currentPage! < lastPage!;
    }
    return false;
  }

  bool get hasPreviousPage {
    if (currentPage != null) {
      return currentPage! > 1;
    }
    return false;
  }

  int get nextPage => (currentPage ?? 1) + 1;
  int get previousPage => (currentPage ?? 2) - 1;
}
