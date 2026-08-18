import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_details_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';

/// Network access for lead reads, writes and lookups.
class LeadService {
  LeadService(this._apiService);

  final ApiService _apiService;

  /// GET /api/leads?per_page=10&page=1
  Future<Result<LeadListResponse>> getLeads({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    try {
      final String url = ApiUrls.leads;
      final Map<String, dynamic> queryParams = <String, dynamic>{
        "page": page,
        "per_page": perPage,
        if (search != null && search.trim().isNotEmpty) "search": search.trim(),
      };
      final Result<dynamic> result =
          await _apiService.get(url, queryParams: queryParams);
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
}
