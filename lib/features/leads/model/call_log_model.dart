class TeleCallDetailResponseModel {
  final bool? status;
  final int? statusCode;
  final String? message;
  final TeleCallDetailDataModel? data;

  const TeleCallDetailResponseModel({
    this.status,
    this.statusCode,
    this.message,
    this.data,
  });

  factory TeleCallDetailResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TeleCallDetailResponseModel(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: json['data'] is Map<String, dynamic>
          ? TeleCallDetailDataModel.fromJson(
              json['data'] as Map<String, dynamic>,
            )
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

class TeleCallDetailDataModel {
  final int? id;
  final int? leadId;
  final String? leadReference;
  final String? leadName;
  final String? calledBy;
  final String? calledDate;
  final String? calledTime;
  final String? duration;
  final String? callStatus;
  final String? callStatusLabel;
  final bool? interest;
  final String? reason;
  final bool? isItemSold;
  final String? invoiceNumber;
  final String? nextFollowupDate;
  final String? remarks;
  final String? invoiceFile;
  final String? createdAt;

  const TeleCallDetailDataModel({
    this.id,
    this.leadId,
    this.leadReference,
    this.leadName,
    this.calledBy,
    this.calledDate,
    this.calledTime,
    this.duration,
    this.callStatus,
    this.callStatusLabel,
    this.interest,
    this.reason,
    this.isItemSold,
    this.invoiceNumber,
    this.nextFollowupDate,
    this.remarks,
    this.invoiceFile,
    this.createdAt,
  });

  factory TeleCallDetailDataModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TeleCallDetailDataModel(
      id: json['id'] as int?,
      leadId: json['lead_id'] as int?,
      leadReference: json['lead_reference'] as String?,
      leadName: json['lead_name'] as String?,
      calledBy: json['called_by'] as String?,
      calledDate: json['called_date'] as String?,
      calledTime: json['called_time'] as String?,
      duration: json['duration'] as String?,
      callStatus: json['call_status'] as String?,
      callStatusLabel: json['call_status_label'] as String?,
      interest: json['interest'] as bool?,
      reason: json['reason'] as String?,
      isItemSold: json['is_item_sold'] as bool?,
      invoiceNumber: json['invoice_number'] as String?,
      nextFollowupDate: json['next_followup_date'] as String?,
      remarks: json['remarks'] as String?,
      invoiceFile: json['invoice_file'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'lead_reference': leadReference,
      'lead_name': leadName,
      'called_by': calledBy,
      'called_date': calledDate,
      'called_time': calledTime,
      'duration': duration,
      'call_status': callStatus,
      'call_status_label': callStatusLabel,
      'interest': interest,
      'reason': reason,
      'is_item_sold': isItemSold,
      'invoice_number': invoiceNumber,
      'next_followup_date': nextFollowupDate,
      'remarks': remarks,
      'invoice_file': invoiceFile,
      'created_at': createdAt,
    };
  }
}