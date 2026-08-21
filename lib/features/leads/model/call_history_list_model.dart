/// Response wrapper for call history list.
class CallHistoryResponseListModel {
  final bool? status;
  final int? statusCode;
  final String? message;
  final List<CallHistoryItem>? data;
  final Pagination? pagination;

  CallHistoryResponseListModel({
    this.status,
    this.statusCode,
    this.message,
    this.data,
    this.pagination,
  });

  factory CallHistoryResponseListModel.fromJson(Map<String, dynamic> json) {
    return CallHistoryResponseListModel(
      status: json["status"] as bool?,
      statusCode: json["status_code"] as int?,
      message: json["message"] as String?,
      data: (json["data"] as List?)
          ?.map((item) => CallHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: json["pagination"] == null
          ? null
          : Pagination.fromJson(json["pagination"] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "status": status,
        "status_code": statusCode,
        "message": message,
        if (data != null) "data": data!.map((e) => e.toJson()).toList(),
        if (pagination != null) "pagination": pagination!.toJson(),
      };
}

/// Single call history entry.
class CallHistoryItem {
  final int? id;
  final String? calledDate;
  final String? calledTime;
  final String? callStatus;
  final bool? interest;
  final String? reason;
  final bool? isItemSold;
  final String? invoiceNumber;
  final String? invoiceFilePath;
  final String? invoiceUrl;
  final String? nextFollowupDate;
  final CalledBy? calledBy;
  final String? remarks;
  final String? createdAt;

  CallHistoryItem({
    this.id,
    this.calledDate,
    this.calledTime,
    this.callStatus,
    this.interest,
    this.reason,
    this.isItemSold,
    this.invoiceNumber,
    this.invoiceFilePath,
    this.invoiceUrl,
    this.nextFollowupDate,
    this.calledBy,
    this.remarks,
    this.createdAt,
  });

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
    return CallHistoryItem(
      id: _asInt(json["id"]),
      calledDate: json["called_date"] as String?,
      calledTime: json["called_time"] as String?,
      callStatus: json["call_status"] as String?,
      interest: json["interest"] as bool?,
      reason: json["reason"] as String?,
      isItemSold: json["is_item_sold"] as bool?,
      invoiceNumber: json["invoice_number"] as String?,
      invoiceFilePath: json["invoice_file_path"] as String?,
      invoiceUrl: json["invoice_url"] as String?,
      nextFollowupDate: json["next_followup_date"] as String?,
      calledBy: json["called_by"] == null
          ? null
          : CalledBy.fromJson(json["called_by"] as Map<String, dynamic>),
      remarks: json["remarks"] as String?,
      createdAt: json["created_at"] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        if (calledDate != null) "called_date": calledDate,
        if (calledTime != null) "called_time": calledTime,
        if (callStatus != null) "call_status": callStatus,
        if (interest != null) "interest": interest,
        if (reason != null) "reason": reason,
        if (isItemSold != null) "is_item_sold": isItemSold,
        if (invoiceNumber != null) "invoice_number": invoiceNumber,
        if (invoiceFilePath != null) "invoice_file_path": invoiceFilePath,
        if (invoiceUrl != null) "invoice_url": invoiceUrl,
        if (nextFollowupDate != null) "next_followup_date": nextFollowupDate,
        if (calledBy != null) "called_by": calledBy!.toJson(),
        if (remarks != null) "remarks": remarks,
        if (createdAt != null) "created_at": createdAt,
      };
}

/// User who made the call.
class CalledBy {
  final int? id;
  final String? name;

  CalledBy({this.id, this.name});

  factory CalledBy.fromJson(Map<String, dynamic> json) {
    return CalledBy(
      id: _asInt(json["id"]),
      name: json["name"] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        if (name != null) "name": name,
      };
}

/// Pagination metadata.
class Pagination {
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;
  final int? from;
  final int? to;

  Pagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: _asInt(json["current_page"]),
      lastPage: _asInt(json["last_page"]),
      perPage: _asInt(json["per_page"]),
      total: _asInt(json["total"]),
      from: _asInt(json["from"]),
      to: _asInt(json["to"]),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "current_page": currentPage,
        "last_page": lastPage,
        "per_page": perPage,
        "total": total,
        "from": from,
        "to": to,
      };
}

/// Helper to safely parse int from dynamic.
int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value.trim());
  return null;
}
