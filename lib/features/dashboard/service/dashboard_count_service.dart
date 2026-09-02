import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/dashboard/model/dashboard_count_model.dart';
import 'package:nimmys_crm/features/dashboard/model/lead_count_model.dart';

/// Network access for task reads, writes and lookups.
class DashboardCountService {
  DashboardCountService(this._apiService);

  final ApiService _apiService;

  Future<Result<DashboardCount>> getDashboardCount() async {
    try {
      final String url = ApiUrls.getDashboardCount;
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

  Future<Result<LeadCountModel>> getleadCount() async {
    try {
      final String url = ApiUrls.getLeadsCount;
      final Result<dynamic> result = await _apiService.get(url);
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
