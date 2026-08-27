import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';

class TaskListResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final List<Task>? data;
  final LeadPagination? pagination;

  TaskListResponse({
    this.status,
    this.statusCode,
    this.message,
    this.data,
    this.pagination,
  });

  factory TaskListResponse.fromJson(Map<String, dynamic> json) {
    return TaskListResponse(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
                .map((e) => Task.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      pagination: json['pagination'] != null
          ? LeadPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
      'data': data?.map((e) => e.toJson()).toList(),
      'pagination': pagination?.toJson(),
    };
  }
}

class Task {
  final int? id;
  final String? title;
  final int? assignedTo;
  final User? approvedBy;
  final String? taskType;
  final bool? repeatMode;
  final String? startTime;
  final String? endTime;
  final String? weekStartDay;
  final String? weekEndDay;
  final String? monthlyStartDate;
  final String? monthlyEndDate;
  final String? quarter;
  final String? quarterStartDate;
  final String? quarterEndDate;
  final String? yearlyStartDate;
  final String? yearlyEndDate;
  final String? description;
  final String? status;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final User? assignedUser;
  final List<Quarter>? quarters;

  Task({
    this.id,
    this.title,
    this.assignedTo,
    this.approvedBy,
    this.taskType,
    this.repeatMode,
    this.startTime,
    this.endTime,
    this.weekStartDay,
    this.weekEndDay,
    this.monthlyStartDate,
    this.monthlyEndDate,
    this.quarter,
    this.quarterStartDate,
    this.quarterEndDate,
    this.yearlyStartDate,
    this.yearlyEndDate,
    this.description,
    this.status,
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.assignedUser,
    this.quarters,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String?,
      assignedTo: json['assigned_to'] as int?,
      approvedBy: json['approved_by'] != null
          ? User.fromJson(json['approved_by'] as Map<String, dynamic>)
          : null,
      taskType: json['task_type'] as String?,
      repeatMode: json['repeat_mode'] as bool?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      weekStartDay: json['week_start_day'] as String?,
      weekEndDay: json['week_end_day'] as String?,
      monthlyStartDate: json['monthly_start_date'] as String?,
      monthlyEndDate: json['monthly_end_date'] as String?,
      quarter: json['quarter'] as String?,
      quarterStartDate: json['quarter_start_date'] as String?,
      quarterEndDate: json['quarter_end_date'] as String?,
      yearlyStartDate: json['yearly_start_date'] as String?,
      yearlyEndDate: json['yearly_end_date'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      deletedAt: json['deleted_at'] as String?,
      assignedUser: json['assigned_user'] != null
          ? User.fromJson(json['assigned_user'] as Map<String, dynamic>)
          : null,
      quarters: json['quarters'] != null
          ? (json['quarters'] as List)
                .map((e) => Quarter.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'assigned_to': assignedTo,
      'approved_by': approvedBy?.toJson(),
      'task_type': taskType,
      'repeat_mode': repeatMode,
      'start_time': startTime,
      'end_time': endTime,
      'week_start_day': weekStartDay,
      'week_end_day': weekEndDay,
      'monthly_start_date': monthlyStartDate,
      'monthly_end_date': monthlyEndDate,
      'quarter': quarter,
      'quarter_start_date': quarterStartDate,
      'quarter_end_date': quarterEndDate,
      'yearly_start_date': yearlyStartDate,
      'yearly_end_date': yearlyEndDate,
      'description': description,
      'status': status,
      'remarks': remarks,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'assigned_user': assignedUser?.toJson(),
      'quarters': quarters?.map((e) => e.toJson()).toList(),
    };
  }
}

class User {
  final int? id;
  final String? name;
  final String? email;
  final String? role;

  User({this.id, this.name, this.email, this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role};
  }
}

class Quarter {
  final int? id;
  final int? taskId;
  final String? quarter;
  final String? startDate;
  final String? endDate;

  Quarter({this.id, this.taskId, this.quarter, this.startDate, this.endDate});

  factory Quarter.fromJson(Map<String, dynamic> json) {
    return Quarter(
      id: json['id'] as int?,
      taskId: json['task_id'] as int?,
      quarter: json['quarter'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'quarter': quarter,
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}

class Pagination {
  final int? currentPage;
  final int? perPage;
  final int? total;
  final int? lastPage;
  final int? from;
  final int? to;

  Pagination({
    this.currentPage,
    this.perPage,
    this.total,
    this.lastPage,
    this.from,
    this.to,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] as int?,
      perPage: json['per_page'] as int?,
      total: json['total'] as int?,
      lastPage: json['last_page'] as int?,
      from: json['from'] as int?,
      to: json['to'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'per_page': perPage,
      'total': total,
      'last_page': lastPage,
      'from': from,
      'to': to,
    };
  }
}
