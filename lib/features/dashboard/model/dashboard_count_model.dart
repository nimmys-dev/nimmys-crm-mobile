class DashboardCount {
  final bool? status;
  final int? statusCode;
  final String? message;
  final DashboardCountData? data;

  DashboardCount({this.status, this.statusCode, this.message, this.data});

  factory DashboardCount.fromJson(Map<String, dynamic> json) {
    return DashboardCount(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? DashboardCountData.fromJson(json['data'] as Map<String, dynamic>)
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

class DashboardCountData {
  final int? todayDuty;
  final int? overdueDuty;
  final int? upcomingDuty;
  final int? approvalPending;

  DashboardCountData({
    this.todayDuty,
    this.overdueDuty,
    this.upcomingDuty,
    this.approvalPending,
  });

  factory DashboardCountData.fromJson(Map<String, dynamic> json) {
    return DashboardCountData(
      todayDuty: json['today_duty'] as int?,
      overdueDuty: json['overdue_duty'] as int?,
      upcomingDuty: json['upcoming_duty'] as int?,
      approvalPending: json['approvalPending'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'today_duty': todayDuty,
      'overdue_duty': overdueDuty,
      'upcoming_duty': upcomingDuty,
      'approvalPending': approvalPending,
    };
  }
}
