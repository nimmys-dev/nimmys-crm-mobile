import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';

class DashboardCount {
  bool? status;
  int? statusCode;
  String? message;
  Data? data;

  DashboardCount({this.status, this.statusCode, this.message, this.data});

  factory DashboardCount.fromJson(Map<String, dynamic> json) {
    return DashboardCount(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? Data.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class Data {
  String? filter; // nullable, can be any type
  String? scope;
  Counts? counts;
  List<Task>? tasks; // empty list, but can hold task objects if needed
  LeadPagination? pagination; // nullable

  Data({this.filter, this.scope, this.counts, this.tasks, this.pagination});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      filter: json['filter'] as String?,
      scope: json['scope'] as String?,
      counts: json['counts'] != null
          ? Counts.fromJson(json['counts'] as Map<String, dynamic>)
          : null,
      tasks: json['tasks'] != null
          ? List<Task>.from(
              (json['tasks'] as List<dynamic>).map(
                (e) => Task.fromJson(e as Map<String, dynamic>),
              ),
            )
          : null,
      pagination: json['pagination'] != null
          ? LeadPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filter': filter,
      'scope': scope,
      'counts': counts?.toJson(),
      'tasks': tasks,
      'pagination': pagination,
    };
  }
}

class Counts {
  MyTasks? myTasks;
  AllTasks? allTasks;

  Counts({this.myTasks, this.allTasks});

  factory Counts.fromJson(Map<String, dynamic> json) {
    return Counts(
      myTasks: json['myTasks'] != null
          ? MyTasks.fromJson(json['myTasks'] as Map<String, dynamic>)
          : null,
      allTasks: json['allTasks'] != null
          ? AllTasks.fromJson(json['allTasks'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'myTasks': myTasks?.toJson(), 'allTasks': allTasks?.toJson()};
  }
}

class MyTasks {
  int? todayDuty;
  int? overdueDuty;
  int? upcomingDuty;
  int? approvalPending;
  int? sendingApproval;

  MyTasks({
    this.todayDuty,
    this.overdueDuty,
    this.upcomingDuty,
    this.approvalPending,
    this.sendingApproval,
  });

  factory MyTasks.fromJson(Map<String, dynamic> json) {
    return MyTasks(
      todayDuty: json['todayDuty'] as int?,
      overdueDuty: json['overdueDuty'] as int?,
      upcomingDuty: json['upcomingDuty'] as int?,
      approvalPending: json['approvalPending'] as int?,
      sendingApproval: json['sendingApproval'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayDuty': todayDuty,
      'overdueDuty': overdueDuty,
      'upcomingDuty': upcomingDuty,
      'approvalPending': approvalPending,
      'sendingApproval': sendingApproval,
    };
  }
}

class AllTasks {
  int? todayDuty;
  int? overdueDuty;
  int? upcomingDuty;
  int? approvalPending;

  AllTasks({
    this.todayDuty,
    this.overdueDuty,
    this.upcomingDuty,
    this.approvalPending,
  });

  factory AllTasks.fromJson(Map<String, dynamic> json) {
    return AllTasks(
      todayDuty: json['todayDuty'] as int?,
      overdueDuty: json['overdueDuty'] as int?,
      upcomingDuty: json['upcomingDuty'] as int?,
      approvalPending: json['approvalPending'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayDuty': todayDuty,
      'overdueDuty': overdueDuty,
      'upcomingDuty': upcomingDuty,
      'approvalPending': approvalPending,
    };
  }
}
