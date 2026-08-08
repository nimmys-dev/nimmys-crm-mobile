import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/staff/api_request/create_staff_api_request.dart';
import 'package:nimmys_crm/features/staff/model/create_staffsuccess_model.dart';
import 'package:nimmys_crm/features/staff/model/staff_list_model.dart';
import 'package:nimmys_crm/features/staff/model/store_success_model.dart';
import 'package:nimmys_crm/features/staff/model/user_role_model.dart';
import 'package:nimmys_crm/features/staff/service/staff_service.dart';

class StaffRepository {
  final StaffService _service;
  StaffRepository(this._service);

  // Branches Repo
  Future<Result<StoreModelSuccess>> getBranches() async {
    try {
      return await _service.getBranches();
    } catch (e) {
      return Error(ErrorWithMessage(message: e.toString()));
    }
  }

  // User Roles Repo
  Future<Result<UserRoleSuccess>> getUserRoles() async {
    try {
      return await _service.getUserRoles();
    } catch (e) {
      return Error(ErrorWithMessage(message: e.toString()));
    }
  }

  // Staff List Repo
  Future<Result<StaffListSuccess>> getStaffList({
    required int page,
    required int perPage,
  }) async {
    try {
      return await _service.getStaffList(page: page, perPage: perPage);
    } catch (e) {
      return Error(ErrorWithMessage(message: e.toString()));
    }
  }

  // Create Staff Repo
  Future<Result<CreateStaffSuccess>> createStaff(
    CreateStaffApiRequest request,
  ) async {
    try {
      return await _service.createStaff(request);
    } catch (e) {
      return Error(ErrorWithMessage(message: e.toString()));
    }
  }

}
