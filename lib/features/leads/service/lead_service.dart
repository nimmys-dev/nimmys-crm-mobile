import 'dart:io';

import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/leads/model/call_history_list_model.dart';
import 'package:nimmys_crm/features/leads/model/call_log_model.dart';
import 'package:nimmys_crm/features/leads/model/closed_lead_response.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_details_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_source_model.dart';
import 'package:nimmys_crm/features/leads/model/not_interested_reason_model.dart';
import 'package:nimmys_crm/features/leads/model/quotation_pdf_model.dart';

/// Network access for lead reads, writes and lookups.
class LeadService {
  LeadService(this._apiService);

  final ApiService _apiService;

  /// GET /api/leads?per_page=10&page=1
  Future<Result<LeadListResponse>> getLeads({
    int page = 1,
    int perPage = 10,
    String? search,
    String? status,
    required bool isUniversalLeadList,
  }) async {
    try {
      final String url = isUniversalLeadList
          ? ApiUrls.leads
          : ApiUrls.closedLeads;
      final Map<String, dynamic> queryParams = <String, dynamic>{
        "page": page,
        "per_page": perPage,
        if (search != null && search.trim().isNotEmpty) "search": search.trim(),
        if (status != null && status != 'null' && status.trim().isNotEmpty)
          "status": status.trim(),
      };
      final Result<dynamic> result = await _apiService.get(
        url,
        queryParams: queryParams,
      );
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<LeadListResponse>(
          result.value,
          (dynamic json) =>
              LeadListResponse.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<LeadListResponse>(result.type);
      } else {
        return Error<LeadListResponse>(GenericError());
      }
    } catch (_) {
      return Error<LeadListResponse>(DeserializationError());
    }
  }

  /// GET /api/view-lead/{id}. Returns details for a single lead.
  Future<Result<LeadDetailsSuccess>> getLeadDetails(int id) async {
    try {
      final String url = ApiUrls.viewLead(id);
      final Result<dynamic> result = await _apiService.get(url);
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<LeadDetailsSuccess>(
          result.value,
          (dynamic json) =>
              LeadDetailsSuccess.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<LeadDetailsSuccess>(result.type);
      } else {
        return Error<LeadDetailsSuccess>(GenericError());
      }
    } catch (_) {
      return Error<LeadDetailsSuccess>(DeserializationError());
    }
  }

  /// GET /api/lead-assignees. Returns staff members who can be assigned a lead.
  Future<Result<LeadAssigneeSuccess>> getLeadAssignees() async {
    try {
      final String url = ApiUrls.leadAssignees;
      final Result<dynamic> result = await _apiService.get(url);
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<LeadAssigneeSuccess>(
          result.value,
          (dynamic json) =>
              LeadAssigneeSuccess.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<LeadAssigneeSuccess>(result.type);
      } else {
        return Error<LeadAssigneeSuccess>(GenericError());
      }
    } catch (_) {
      return Error<LeadAssigneeSuccess>(DeserializationError());
    }
  }

  /// POST /api/create-leads. [ApiService] supplies the signed-in user's bearer
  /// token and the JSON headers for this request.
  Future<Result<dynamic>> createLead(Map<String, dynamic> payload) async {
    try {
      final Result<dynamic> result = await _apiService.post(
        ApiUrls.createLead,
        body: payload,
      );
      if (result is Success<dynamic> &&
          result.value is Map &&
          result.value['status'] == false) {
        final Object? message = result.value['message'];
        return Error(
          ErrorWithMessage(
            message: message is String ? message : 'Could not create lead.',
          ),
        );
      }
      return result;
    } catch (_) {
      return Error(GenericError());
    }
  }

  /// POST /api/update-lead/{id}. Same payload shape as create.
  Future<Result<LeadDetailsSuccess>> updateLead(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final Result<dynamic> result = await _apiService.post(
        ApiUrls.updateLead(id),
        body: payload,
      );
      if (result is Success<dynamic>) {
        if (result.value is Map && result.value['status'] == false) {
          final Object? message = result.value['message'];
          return Error<LeadDetailsSuccess>(
            ErrorWithMessage(
              message: message is String ? message : 'Could not update lead.',
            ),
          );
        }
        return await _apiService.getResponseStatus<LeadDetailsSuccess>(
          result.value,
          (dynamic json) =>
              LeadDetailsSuccess.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<LeadDetailsSuccess>(result.type);
      } else {
        return Error<LeadDetailsSuccess>(GenericError());
      }
    } catch (_) {
      return Error<LeadDetailsSuccess>(DeserializationError());
    }
  }

  /// GET /api/view-lead/{id}. Returns details for a single lead.
  Future<Result<LeadSourceModel>> getLeadSources() async {
    try {
      final String url = ApiUrls.leadSources;
      final Result<dynamic> result = await _apiService.get(url);
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<LeadSourceModel>(
          result.value,
          (dynamic json) =>
              LeadSourceModel.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<LeadSourceModel>(result.type);
      } else {
        return Error<LeadSourceModel>(GenericError());
      }
    } catch (_) {
      return Error<LeadSourceModel>(DeserializationError());
    }
  }

  /// GET quotationpdf details api
  Future<Result<QuotationPdfResponse>> getQuotationPdf(int leadId) async {
    try {
      final String url = ApiUrls.quotationPdf(leadId);
      final Result<dynamic> result = await _apiService.get(url);
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<QuotationPdfResponse>(
          result.value,
          (dynamic json) =>
              QuotationPdfResponse.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<QuotationPdfResponse>(result.type);
      } else {
        return Error<QuotationPdfResponse>(GenericError());
      }
    } catch (_) {
      return Error<QuotationPdfResponse>(DeserializationError());
    }
  }

  /// POST /api/leads/{leadId}/calls
  Future<Result<TeleCallDetailResponseModel>> createCallLog(
    int leadId, {
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
      final String url = ApiUrls.leadCalls(leadId);

      final Map<String, String> fields = <String, String>{
        if (callStatus != null && callStatus.trim().isNotEmpty)
          'call_status': callStatus.trim(),

        if (calledDate != null && calledDate.trim().isNotEmpty)
          'called_date': calledDate.trim(),

        if (calledTime != null && calledTime.trim().isNotEmpty)
          'called_time': calledTime.trim(),

        if (duration != null && duration.trim().isNotEmpty)
          'duration': duration.trim(),

        if (interest != null) 'interest': interest ? '1' : '0',

        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),

        if (isItemSold != null) 'is_item_sold': isItemSold ? '1' : '0',

        if (invoiceNumber != null && invoiceNumber.trim().isNotEmpty)
          'invoice_number': invoiceNumber.trim(),

        if (remarks != null && remarks.trim().isNotEmpty)
          'remarks': remarks.trim(),

        if (nextFollowupDate != null && nextFollowupDate.trim().isNotEmpty)
          'next_followup_date': nextFollowupDate.trim(),
      };

      final Result<dynamic> result = await _apiService.multipart(
        url,
        invoiceFile,
        fields: fields,
        pathName: 'invoice_file',
      );

      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<TeleCallDetailResponseModel>(
          result.value,
          (dynamic json) => TeleCallDetailResponseModel.fromJson(
            json as Map<String, dynamic>,
          ),
        );
      }

      if (result is Error<dynamic>) {
        return Error<TeleCallDetailResponseModel>(result.type);
      }

      return Error<TeleCallDetailResponseModel>(GenericError());
    } catch (_) {
      return Error<TeleCallDetailResponseModel>(DeserializationError());
    }
  }

  /// GET call history api

  Future<Result<CallHistoryResponseListModel>> getCallHistory(
    int leadId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final String url = ApiUrls.getcallHistory(leadId);
      final Map<String, dynamic> queryParams = <String, dynamic>{
        "page": page,
        "per_page": perPage,
      };
      final Result<dynamic> result = await _apiService.get(
        url,
        queryParams: queryParams,
      );
      if (result is Success<dynamic>) {
        return await _apiService
            .getResponseStatus<CallHistoryResponseListModel>(
              result.value,
              (dynamic json) => CallHistoryResponseListModel.fromJson(
                json as Map<String, dynamic>,
              ),
            );
      } else if (result is Error<dynamic>) {
        return Error<CallHistoryResponseListModel>(result.type);
      } else {
        return Error<CallHistoryResponseListModel>(GenericError());
      }
    } catch (_) {
      return Error<CallHistoryResponseListModel>(DeserializationError());
    }
  }

  /// PUT /api/leads/{id}/close
  /// Closes a lead with a given status and optional lost reason.
  Future<Result<CloseLeadResponse>> closeLead({
    required int leadId,
    required String status,
    String? lostReason,
  }) async {
    try {
      final String url = '${ApiUrls.leads}/$leadId/close';
      final Map<String, dynamic> body = <String, dynamic>{
        'status': status,
        if (lostReason != null && lostReason.trim().isNotEmpty)
          'lost_reason': lostReason.trim(),
      };

      final Result<dynamic> result = await _apiService.put(url, body: body);

      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<CloseLeadResponse>(
          result.value,
          (json) => CloseLeadResponse.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<CloseLeadResponse>(result.type);
      } else {
        return Error<CloseLeadResponse>(GenericError());
      }
    } catch (_) {
      return Error<CloseLeadResponse>(DeserializationError());
    }
  }

  /// GET /api/lead-assignees. Returns staff members who can be assigned a lead.
  Future<Result<NotInterestedReasonModel>> getNotInterestedReasonModel() async {
    try {
      final String url = ApiUrls.notInterestedReason;
      final Result<dynamic> result = await _apiService.get(url);
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<NotInterestedReasonModel>(
          result.value,
          (dynamic json) =>
              NotInterestedReasonModel.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<NotInterestedReasonModel>(result.type);
      } else {
        return Error<NotInterestedReasonModel>(GenericError());
      }
    } catch (_) {
      return Error<NotInterestedReasonModel>(DeserializationError());
    }
  }
}
