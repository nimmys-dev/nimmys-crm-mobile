/// `GET /api/staff?page=&per_page=` response.
class StaffListSuccess {
  StaffListSuccess({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
    required this.pagination,
  });

  final bool? status;
  final int? statusCode;
  final String? message;
  final List<StaffListItem> data;
  final StaffPagination? pagination;

  factory StaffListSuccess.fromJson(Map<String, dynamic> json) {
    return StaffListSuccess(
      status: json["status"],
      statusCode: json["status_code"],
      message: json["message"],
      data: json["data"] == null
          ? <StaffListItem>[]
          : List<StaffListItem>.from(
              json["data"]!.map((x) => StaffListItem.fromJson(x)),
            ),
      pagination: json["pagination"] == null
          ? null
          : StaffPagination.fromJson(json["pagination"]),
    );
  }
}

/// One row of the staff list.
///
/// Everything past `id` is nullable because the list carries real records that
/// were never completed — the seeded Admin and Manager accounts come back with
/// no phone, no shop and no photo.
class StaffListItem {
  StaffListItem({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.shopId,
    required this.role,
    required this.status,
    required this.photo,
    required this.photoUrl,
    required this.createdAt,
  });

  final int? id;
  final String? employeeCode;
  final String? name;
  final String? email;
  final String? phone;

  /// An int here, unlike the string `shop_id` Create Staff echoes back — parsed
  /// leniently so neither shape breaks the list.
  final int? shopId;
  final String? role;
  final String? status;
  final String? photo;
  final String? photoUrl;
  final DateTime? createdAt;

  factory StaffListItem.fromJson(Map<String, dynamic> json) {
    return StaffListItem(
      id: _asInt(json["id"]),
      employeeCode: json["employee_code"],
      name: json["name"],
      email: json["email"],
      phone: json["phone"],
      shopId: _asInt(json["shop_id"]),
      role: json["role"],
      status: json["status"],
      photo: json["photo"],
      photoUrl: json["photo_url"],
      createdAt: json["created_at"] == null
          ? null
          : DateTime.tryParse(json["created_at"].toString()),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  bool get isActive => status?.toLowerCase() == 'active';

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Up to two letters for the row avatar, matching the dashboard header's
  /// treatment: "Thomas John" → "TJ", "Admin" → "AD", empty → "?".
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
      return (single.length == 1 ? single : single.substring(0, 2))
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

/// The `pagination` block that rides alongside the list.
class StaffPagination {
  StaffPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
    required this.nextPageUrl,
    required this.previousPageUrl,
  });

  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;
  final int? from;
  final int? to;
  final String? nextPageUrl;
  final String? previousPageUrl;

  factory StaffPagination.fromJson(Map<String, dynamic> json) {
    return StaffPagination(
      currentPage: _asInt(json["current_page"]),
      lastPage: _asInt(json["last_page"]),
      perPage: _asInt(json["per_page"]),
      total: _asInt(json["total"]),
      from: _asInt(json["from"]),
      to: _asInt(json["to"]),
      nextPageUrl: json["next_page_url"],
      previousPageUrl: json["previous_page_url"],
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Page numbers rather than `next_page_url`: the list is fetched through
  /// `ApiUrls.staffList` with query parameters, so the server's absolute URL is
  /// never followed directly. Falling back to the URL keeps the check working
  /// if `last_page` is ever absent.
  bool get hasNextPage {
    final int? current = currentPage;
    final int? last = lastPage;
    if (current != null && last != null) {
      return current < last;
    }
    return nextPageUrl != null && nextPageUrl!.isNotEmpty;
  }

  int get nextPage => (currentPage ?? 1) + 1;
}
