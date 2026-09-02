class DashboardCount {
  bool? status;
  int? statusCode;
  String? message;
  DashboardCountData? data;

  DashboardCount({
    this.status,
    this.statusCode,
    this.message,
    this.data,
  });

  DashboardCount.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    statusCode = json['status_code'];
    message = json['message'];
    data = json['data'] != null
        ? DashboardCountData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['status'] = status;
    data['status_code'] = statusCode;
    data['message'] = message;

    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }

    return data;
  }
}

class DashboardCountData {
  dynamic filter;
  DashboardCounts? counts;
  List<dynamic>? tasks;
  dynamic pagination;

  DashboardCountData({
    this.filter,
    this.counts,
    this.tasks,
    this.pagination,
  });

  DashboardCountData.fromJson(Map<String, dynamic> json) {
    filter = json['filter'];
    counts = json['counts'] != null
        ? DashboardCounts.fromJson(json['counts'])
        : null;
    tasks = json['tasks'] != null
        ? List<dynamic>.from(json['tasks'])
        : null;
    pagination = json['pagination'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['filter'] = filter;

    if (counts != null) {
      data['counts'] = counts!.toJson();
    }

    if (tasks != null) {
      data['tasks'] = tasks;
    }

    data['pagination'] = pagination;

    return data;
  }
}

class DashboardCounts {
  int? todayDuty;
  int? overdueDuty;
  int? upcomingDuty;
  int? approvalPending;

  DashboardCounts({
    this.todayDuty,
    this.overdueDuty,
    this.upcomingDuty,
    this.approvalPending,
  });

  DashboardCounts.fromJson(Map<String, dynamic> json) {
    todayDuty = json['today_duty'];
    overdueDuty = json['overdue_duty'];
    upcomingDuty = json['upcoming_duty'];
    approvalPending = json['approvalPending'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['today_duty'] = todayDuty;
    data['overdue_duty'] = overdueDuty;
    data['upcoming_duty'] = upcomingDuty;
    data['approvalPending'] = approvalPending;

    return data;
  }
}