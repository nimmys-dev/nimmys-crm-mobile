import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/dashboard/model/dashboard_count_model.dart';
import 'package:nimmys_crm/features/dashboard/model/lead_count_model.dart';
import 'package:nimmys_crm/features/dashboard/service/dashboard_count_service.dart';

class DashboardRepository {
  DashboardRepository(this._service);

  final DashboardCountService _service;
  Future<Result<DashboardCount>> getDashboardCount() async {
    try {
      return await _service.getDashboardCount();
    } catch (e) {
      return Error<DashboardCount>(ErrorWithMessage(message: e.toString()));
    }
  }

  Future<Result<LeadCountModel>> getLeadsCount() async {
    try {
      return await _service.getleadCount();
    } catch (e) {
      return Error<LeadCountModel>(ErrorWithMessage(message: e.toString()));
    }
  }
}
