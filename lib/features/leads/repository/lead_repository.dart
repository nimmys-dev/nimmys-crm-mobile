import 'dart:io';

import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/leads/model/call_history_list_model.dart';
import 'package:nimmys_crm/features/leads/model/call_log_model.dart';
import 'package:nimmys_crm/features/leads/model/closed_lead_response.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_details_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_source_model.dart';
import 'package:nimmys_crm/features/leads/model/not_interested_reason_model.dart';
import 'package:nimmys_crm/features/leads/model/quotation_pdf_model.dart';
import 'package:nimmys_crm/features/leads/service/lead_service.dart';

class LeadRepository {
  LeadRepository(this._service);

  final LeadService _service;

  Future<Result<LeadListResponse>> getLeads({
    int page = 1,
    int perPage = 10,
    String? search,
    String? status,
    required int isUniversalLeadList
  }) async {
    try {
      return await _service.getLeads(
        page: page,
        perPage: perPage,
        search: search,
        status: status,
        isUniversalLeadList: isUniversalLeadList,
      );
    } catch (e) {
      return Error<LeadListResponse>(ErrorWithMessage(message: e.toString()));
    }
  }

  Future<Result<LeadDetailsSuccess>> getLeadDetails(int id) async {
    try {
      return await _service.getLeadDetails(id);
    } catch (e) {
      return Error<LeadDetailsSuccess>(ErrorWithMessage(message: e.toString()));
    }
  }

  Future<Result<LeadAssigneeSuccess>> getLeadAssignees() async {
    try {
      return await _service.getLeadAssignees();
    } catch (e) {
      return Error<LeadAssigneeSuccess>(
        ErrorWithMessage(message: e.toString()),
      );
    }
  }

  Future<Result<dynamic>> createLead(Map<String, dynamic> payload) async {
    try {
      return await _service.createLead(payload);
    } catch (e) {
      return Error<dynamic>(ErrorWithMessage(message: e.toString()));
    }
  }

  Future<Result<LeadDetailsSuccess>> updateLead(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _service.updateLead(id, payload);
    } catch (e) {
      return Error<LeadDetailsSuccess>(ErrorWithMessage(message: e.toString()));
    }
  }

  Future<Result<LeadSourceModel>> getLeadSources() async {
    try {
      return await _service.getLeadSources();
    } catch (e) {
      return Error<LeadSourceModel>(ErrorWithMessage(message: e.toString()));
    }
  }

  Future<Result<QuotationPdfResponse>> getQuotationPdf(int leadId) async {
    try {
      return await _service.getQuotationPdf(leadId);
    } catch (e) {
      return Error<QuotationPdfResponse>(
        ErrorWithMessage(message: e.toString()),
      );
    }
  }

  Future<Result<TeleCallDetailResponseModel>> addCallLog({
    required int leadId,
    String? callStatus,
    String? calledDate,
    String? calledTime,
    String? duration,
    bool? interest,
    String? reason,
    bool? isItemSold,
    String? invoiceNumber,
    String? remarks,
    String? nextFollowupDate,
    File? invoiceFile,
  }) async {
    try {
      return await _service.createCallLog(
        leadId,
        callStatus: callStatus,
        calledDate: calledDate,
        calledTime: calledTime,
        duration: duration,
        interest: interest,
        reason: reason,
        isItemSold: isItemSold,
        invoiceNumber: invoiceNumber,
        remarks: remarks,
        nextFollowupDate: nextFollowupDate,
        invoiceFile: invoiceFile,
      );
    } catch (e) {
      return Error<TeleCallDetailResponseModel>(
        ErrorWithMessage(message: e.toString()),
      );
    }
  }

  Future<Result<CallHistoryResponseListModel>> getCallHistory(
    int leadId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      return await _service.getCallHistory(
        leadId,
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      return Error<CallHistoryResponseListModel>(
        ErrorWithMessage(message: e.toString()),
      );
    }
  }

  Future<Result<CloseLeadResponse>> closeLead({
    required int leadId,
    required String status,
    String? lostReason,
  }) async {
    try {
      return await _service.closeLead(
        leadId: leadId,
        status: status,
        lostReason: lostReason,
      );
    } catch (e) {
      return Error<CloseLeadResponse>(ErrorWithMessage(message: e.toString()));
    }
  }

    Future<Result<NotInterestedReasonModel>> getNotInterestedReasons() async {
    try {
      return await _service.getNotInterestedReasonModel();
    } catch (e) {
      return Error<NotInterestedReasonModel>(
        ErrorWithMessage(message: e.toString()),
      );
    }
  }
}
