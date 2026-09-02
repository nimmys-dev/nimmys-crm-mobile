class LeadCountModel {
  bool? status;
  int? statusCode;
  String? message;
  LeadCountData? data;

  LeadCountModel({
    this.status,
    this.statusCode,
    this.message,
    this.data,
  });

  LeadCountModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    statusCode = json['status_code'];
    message = json['message'];
    data = json['data'] != null
        ? LeadCountData.fromJson(json['data'])
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

class LeadCountData {
  dynamic filter;
  LeadCounts? counts;
  dynamic filteredCount;
  List<dynamic>? leads;
  dynamic pagination;

  LeadCountData({
    this.filter,
    this.counts,
    this.filteredCount,
    this.leads,
    this.pagination,
  });

  LeadCountData.fromJson(Map<String, dynamic> json) {
    filter = json['filter'];

    counts = json['counts'] != null
        ? LeadCounts.fromJson(json['counts'])
        : null;

    filteredCount = json['filtered_count'];

    leads = json['leads'] != null
        ? List<dynamic>.from(json['leads'])
        : null;

    pagination = json['pagination'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['filter'] = filter;

    if (counts != null) {
      data['counts'] = counts!.toJson();
    }

    data['filtered_count'] = filteredCount;
    data['leads'] = leads;
    data['pagination'] = pagination;

    return data;
  }
}

class LeadCounts {
  int? unattended;
  int? todayFollowup;
  int? overdueFollowup;
  int? upcomingFollowup;
  int? myLeads;
  int? totalLeads;

  LeadCounts({
    this.unattended,
    this.todayFollowup,
    this.overdueFollowup,
    this.upcomingFollowup,
    this.myLeads,
    this.totalLeads,
  });

  LeadCounts.fromJson(Map<String, dynamic> json) {
    unattended = json['unattended'];
    todayFollowup = json['today_followup'];
    overdueFollowup = json['overdue_followup'];
    upcomingFollowup = json['upcoming_followup'];
    myLeads = json['my_leads'];
    totalLeads = json['total_leads'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['unattended'] = unattended;
    data['today_followup'] = todayFollowup;
    data['overdue_followup'] = overdueFollowup;
    data['upcoming_followup'] = upcomingFollowup;
    data['my_leads'] = myLeads;
    data['total_leads'] = totalLeads;

    return data;
  }
}