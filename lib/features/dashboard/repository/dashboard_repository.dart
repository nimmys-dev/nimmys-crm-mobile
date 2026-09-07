import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/dashboard/model/dashboard_count_model.dart';
import 'package:nimmys_crm/features/dashboard/model/lead_count_model.dart';
import 'package:nimmys_crm/features/dashboard/service/dashboard_count_service.dart';

class DashboardRepository {
  DashboardRepository(this._service);

  final DashboardCountService _service;

  // ──────────────────────────────────────────────────────────────
  // 1. Summary counts (no filters)
  // ──────────────────────────────────────────────────────────────
  Future<Result<DashboardCount>> getDashboardCount() async {
    try {
      return await _service.getDashboardCount();
    } catch (e) {
      // Use GenericError if ErrorWithMessage is not imported
      return Error<DashboardCount>(GenericError());
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 2. Filtered + paginated task counts
  // ──────────────────────────────────────────────────────────────
  Future<Result<DashboardCount>> getTaskCounts({
    required String filter,
    int perPage = 10,
    int page = 1,
    String? scope,
  }) async {
    try {
      return await _service.getTaskCounts(
        filter: filter,
        perPage: perPage,
        page: page,
        scope: scope,
      );
    } catch (e) {
      return Error<DashboardCount>(GenericError());
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 3. Lead counts (with corrected method name)
  // ──────────────────────────────────────────────────────────────
  Future<Result<LeadCountModel>> getLeadCount({
    String? filter,
    int perPage = 10,
    int page = 1,
    String? scope,
  }) async {
    try {
      // Service method is now getLeadCount() (renamed from getleadCount)
      return await _service.getleadCount(
        filter: filter,
        page: page,
        scope: scope,
        perPage: perPage,
      );
    } catch (e) {
      return Error<LeadCountModel>(GenericError());
    }
  }

  // dashboard_repository.dart (add this method)

  Future<Result<LeadCountModel>> getLeadList({
    required String filter,
    int perPage = 10,
    int page = 1,
    String? scope,
  }) async {
    try {
      return await _service.getleadCount(
        filter: filter,
        perPage: perPage,
        page: page,
        scope: scope,
      );
    } catch (e) {
      return Error<LeadCountModel>(GenericError());
    }
  }
}
