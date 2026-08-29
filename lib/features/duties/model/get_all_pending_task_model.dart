import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';

/// Response for fetching approval pending tasks.
class ApprovalTaskResponse {
  final bool? status;
  final String? message;
  final ApprovalTaskData? data;

  ApprovalTaskResponse({
    this.status,
    this.message,
    this.data,
  });

  factory ApprovalTaskResponse.fromJson(Map<String, dynamic> json) {
    return ApprovalTaskResponse(
      status: json["status"] as bool?,
      message: json["message"] as String?,
      data: json["data"] == null
          ? null
          : ApprovalTaskData.fromJson(json["data"] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "status": status,
        "message": message,
        if (data != null) "data": data!.toJson(),
      };
}

/// Paginated data wrapper for approval tasks.
class ApprovalTaskData {
  final int? currentPage;
  final List<Task>? data;
  final String? firstPageUrl;
  final int? from;
  final int? lastPage;
  final String? lastPageUrl;
  final List<Link>? links;
  final String? nextPageUrl;
  final String? path;
  final int? perPage;
  final String? prevPageUrl;
  final int? to;
  final int? total;

  ApprovalTaskData({
    this.currentPage,
    this.data,
    this.firstPageUrl,
    this.from,
    this.lastPage,
    this.lastPageUrl,
    this.links,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
  });

  factory ApprovalTaskData.fromJson(Map<String, dynamic> json) {
    return ApprovalTaskData(
      currentPage: _asInt(json["current_page"]),
      data: (json["data"] as List?)
          ?.map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList(),
      firstPageUrl: json["first_page_url"] as String?,
      from: _asInt(json["from"]),
      lastPage: _asInt(json["last_page"]),
      lastPageUrl: json["last_page_url"] as String?,
      links: (json["links"] as List?)
          ?.map((item) => Link.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextPageUrl: json["next_page_url"] as String?,
      path: json["path"] as String?,
      perPage: _asInt(json["per_page"]),
      prevPageUrl: json["prev_page_url"] as String?,
      to: _asInt(json["to"]),
      total: _asInt(json["total"]),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "current_page": currentPage,
        if (data != null) "data": data!.map((e) => e.toJson()).toList(),
        if (firstPageUrl != null) "first_page_url": firstPageUrl,
        "from": from,
        "last_page": lastPage,
        if (lastPageUrl != null) "last_page_url": lastPageUrl,
        if (links != null) "links": links!.map((e) => e.toJson()).toList(),
        if (nextPageUrl != null) "next_page_url": nextPageUrl,
        if (path != null) "path": path,
        "per_page": perPage,
        if (prevPageUrl != null) "prev_page_url": prevPageUrl,
        "to": to,
        "total": total,
      };
}


/// User who approved the task.
class ApprovedBy {
  final int? id;
  final String? name;

  ApprovedBy({
    this.id,
    this.name,
  });

  factory ApprovedBy.fromJson(Map<String, dynamic> json) {
    return ApprovedBy(
      id: _asInt(json["id"]),
      name: json["name"] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        if (name != null) "name": name,
      };
}

/// User assigned to the task.
class AssignedUser {
  final int? id;
  final String? name;

  AssignedUser({
    this.id,
    this.name,
  });

  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(
      id: _asInt(json["id"]),
      name: json["name"] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        if (name != null) "name": name,
      };
}

/// Pagination link.
class Link {
  final String? url;
  final String? label;
  final bool? active;

  Link({
    this.url,
    this.label,
    this.active,
  });

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      url: json["url"] as String?,
      label: json["label"] as String?,
      active: json["active"] as bool?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "url": url,
        if (label != null) "label": label,
        "active": active,
      };
}

/// Helper to safely parse int from dynamic.
int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value.trim());
  return null;
}