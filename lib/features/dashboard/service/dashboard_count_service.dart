import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/dashboard/model/dashboard_count_model.dart';
import 'package:nimmys_crm/features/dashboard/model/lead_count_model.dart';

/// Network access for dashboard counts (summary & task‑counts).
class DashboardCountService {
  DashboardCountService(this._apiService);

  final ApiService _apiService;

  // ────────────────────────────────────────────────────────────────────────────
  // 1. Summary dashboard counts (no parameters)
  // ────────────────────────────────────────────────────────────────────────────
  Future<Result<DashboardCount>> getDashboardCount() async {
    try {
      final String url = ApiUrls.getDashboardCount; // e.g. '/dashboard/counts'
      final Result<dynamic> result = await _apiService.get(url);
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<DashboardCount>(
          result.value,
          (dynamic json) =>
              DashboardCount.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<DashboardCount>(result.type);
      } else {
        return Error<DashboardCount>(GenericError());
      }
    } catch (_) {
      return Error<DashboardCount>(DeserializationError());
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 2. Filtered + paginated task counts (with parameters)
  // ────────────────────────────────────────────────────────────────────────────
  Future<Result<DashboardCount>> getTaskCounts({
    required String filter,
    int perPage = 10,
    int page = 1,
    String? scope,
  }) async {
    try {
      // Build query map, omitting null values
      final Map<String, dynamic> query = {
        'filter': filter.trim(), // ensure no extra spaces
        'per_page': perPage,
        'page': page,
      };
      // Add scope only if not null and not empty
      if (scope != null && scope.isNotEmpty) {
        query['scope'] = scope;
      } else {}
      // Use a dedicated URL for the task‑counts endpoint
      final String url =
          ApiUrls.getTaskCounts; // define as '/dashboard/task-counts'
      final Result<dynamic> result = await _apiService.get(
        url,
        queryParams: query,
      );
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<DashboardCount>(
          result.value,
          (dynamic json) =>
              DashboardCount.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<DashboardCount>(result.type);
      } else {
        return Error<DashboardCount>(GenericError());
      }
    } catch (_) {
      return Error<DashboardCount>(DeserializationError());
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 3. Lead count (rename to getLeadCount for consistency)
  // ────────────────────────────────────────────────────────────────────────────
  Future<Result<LeadCountModel>> getleadCount({
    String? filter,
    int perPage = 10,
    int page = 1,
    String? scope,
  }) async {
    try {
      // Build query map, omitting null values
      final Map<String, dynamic> query = {
        'filter': filter?.trim(), // ensure no extra spaces
        'per_page': perPage,
        'page': page,
      };
      // Add scope only if not null and not empty
      if (scope != null && scope.isNotEmpty) {
        query['scope'] = scope;
      } else {}
      final String url = ApiUrls.getLeadsCount;
      final Result<dynamic> result = await _apiService.get(
        url,
        queryParams: query,
      );
      if (result is Success<dynamic>) {
        return await _apiService.getResponseStatus<LeadCountModel>(
          result.value,
          (dynamic json) =>
              LeadCountModel.fromJson(json as Map<String, dynamic>),
        );
      } else if (result is Error<dynamic>) {
        return Error<LeadCountModel>(result.type);
      } else {
        return Error<LeadCountModel>(GenericError());
      }
    } catch (_) {
      return Error<LeadCountModel>(DeserializationError());
    }
  }
}
