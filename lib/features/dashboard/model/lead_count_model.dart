import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';

class LeadCountModel {
  bool? status;
  int? statusCode;
  String? message;
  LeadData? data;

  LeadCountModel({this.status, this.statusCode, this.message, this.data});

  factory LeadCountModel.fromJson(Map<String, dynamic> json) {
    return LeadCountModel(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? LeadData.fromJson(json['data'] as Map<String, dynamic>)
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

class LeadData {
  dynamic filter; // null, can be any type
  String? scope;
  LeadCounts? counts;
  dynamic filteredCount; // null
  List<dynamic>? leads; // empty list
  LeadPagination? pagination; // null

  LeadData({
    this.filter,
    this.scope,
    this.counts,
    this.filteredCount,
    this.leads,
    this.pagination,
  });

  factory LeadData.fromJson(Map<String, dynamic> json) {
    return LeadData(
      filter: json['filter'],
      scope: json['scope'] as String?,
      counts: json['counts'] != null
          ? LeadCounts.fromJson(json['counts'] as Map<String, dynamic>)
          : null,
      filteredCount: json['filtered_count'],
      leads: json['leads'] as List<dynamic>?,
      pagination: json['pagination'] as LeadPagination?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filter': filter,
      'scope': scope,
      'counts': counts?.toJson(),
      'filtered_count': filteredCount,
      'leads': leads,
      'pagination': pagination,
    };
  }
}

class LeadCounts {
  MyLeads? myLeads;
  AllLeads? allLeads;

  LeadCounts({this.myLeads, this.allLeads});

  factory LeadCounts.fromJson(Map<String, dynamic> json) {
    return LeadCounts(
      myLeads: json['my_leads'] != null
          ? MyLeads.fromJson(json['my_leads'] as Map<String, dynamic>)
          : null,
      allLeads: json['all_leads'] != null
          ? AllLeads.fromJson(json['all_leads'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'my_leads': myLeads?.toJson(), 'all_leads': allLeads?.toJson()};
  }
}

class MyLeads {
  int? unattended;
  int? todayFollowup;
  int? overdueFollowup;
  int? upcomingFollowup;
  int? yourLeads;
  int? totalLeads;

  MyLeads({
    this.unattended,
    this.todayFollowup,
    this.overdueFollowup,
    this.upcomingFollowup,
    this.yourLeads,
    this.totalLeads,
  });

  factory MyLeads.fromJson(Map<String, dynamic> json) {
    return MyLeads(
      unattended: json['unattended'] as int?,
      todayFollowup: json['today_followup'] as int?,
      overdueFollowup: json['overdue_followup'] as int?,
      upcomingFollowup: json['upcoming_followup'] as int?,
      yourLeads: json['your_leads'] as int?,
      totalLeads: json['total_leads'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unattended': unattended,
      'today_followup': todayFollowup,
      'overdue_followup': overdueFollowup,
      'upcoming_followup': upcomingFollowup,
      'your_leads': yourLeads,
      'total_leads': totalLeads,
    };
  }
}

class AllLeads {
  int? unattended;
  int? todayFollowup;
  int? overdueFollowup;
  int? upcomingFollowup;
  int? totalLeads;

  AllLeads({
    this.unattended,
    this.todayFollowup,
    this.overdueFollowup,
    this.upcomingFollowup,
    this.totalLeads,
  });

  factory AllLeads.fromJson(Map<String, dynamic> json) {
    return AllLeads(
      unattended: json['unattended'] as int?,
      todayFollowup: json['today_followup'] as int?,
      overdueFollowup: json['overdue_followup'] as int?,
      upcomingFollowup: json['upcoming_followup'] as int?,
      totalLeads: json['total_leads'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unattended': unattended,
      'today_followup': todayFollowup,
      'overdue_followup': overdueFollowup,
      'upcoming_followup': upcomingFollowup,
      'total_leads': totalLeads,
    };
  }
}
