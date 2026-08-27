import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';
import 'package:nimmys_crm/features/staff/api_request/create_staff_api_request.dart';
import 'package:nimmys_crm/features/staff/model/create_staffsuccess_model.dart';
import 'package:nimmys_crm/features/staff/api_request/update_staff_api_request.dart';
import 'package:nimmys_crm/features/staff/model/delete_staff_model.dart';
import 'package:nimmys_crm/features/staff/model/staff_details_model.dart';
import 'package:nimmys_crm/features/staff/model/staff_list_model.dart';
import 'package:nimmys_crm/features/staff/model/store_success_model.dart';
import 'package:nimmys_crm/features/staff/model/user_role_model.dart';

class StaffService {
  final ApiService _apiService;
  StaffService(this._apiService);

  // Branches Service
  //
  // GET /api/branches. No parameters — the bearer token ApiService attaches
  // scopes the list to the signed-in account's shops.
  Future<Result<StoreModelSuccess>> getBranches() async {
    try {
      final url = ApiUrls.branches;
      final result = await _apiService.get(url);
      if (result is Success) {
        return await _apiService.getResponseStatus<StoreModelSuccess>(
          result.value,
          (json) => StoreModelSuccess.fromJson(json),
        );
      } else if (result is Error) {
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }

  // User Roles Service
  //
  // GET /api/user-roles. Supplies both halves of each role — the label the
  // picker shows and the value Create Staff sends — so neither is hard-coded.
  Future<Result<UserRoleSuccess>> getUserRoles() async {
    try {
      final url = ApiUrls.userRoles;
      final result = await _apiService.get(url);
      if (result is Success) {
        return await _apiService.getResponseStatus<UserRoleSuccess>(
          result.value,
          (json) => UserRoleSuccess.fromJson(json),
        );
      } else if (result is Error) {
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }

  // Staff List Service
  //
  // GET /api/staff. Paginated: the response carries a `pagination` block, and
  // the next page is requested by number rather than by following
  // `next_page_url` — that URL is absolute and would bypass ApiUrls entirely.
  Future<Result<StaffListSuccess>> getStaffList({
    required int page,
    required int perPage,
    String? search,
  }) async {
    try {
      final url = ApiUrls.staffList;
      final Map<String, dynamic> queryParams = <String, dynamic>{
        "page": page,
        "per_page": perPage,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams["search"] = search.trim();
      }
      final result = await _apiService.get(url, queryParams: queryParams);
      if (result is Success) {
        return await _apiService.getResponseStatus<StaffListSuccess>(
          result.value,
          (json) => StaffListSuccess.fromJson(json),
        );
      } else if (result is Error) {
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }

  // Create Staff Service
  //
  // POST /api/create-staff as multipart/form-data. The photo goes through the
  // `files` argument under the `photo` part name; everything else is a form
  // field. A null photo simply means no file part is attached.
  Future<Result<CreateStaffSuccess>> createStaff(
    CreateStaffApiRequest request,
  ) async {
    try {
      final url = ApiUrls.createStaff;
      final result = await _apiService.multipart(
        url,
        request.photo,
        fields: request.toFormFields(),
        pathName: "photo",
      );
      if (result is Success) {
        return await _apiService.getResponseStatus<CreateStaffSuccess>(
          result.value,
          (json) => CreateStaffSuccess.fromJson(json),
        );
      } else if (result is Error) {
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }

  // View Staff Service
  //
  // GET /api/view-staff/{id}. Shares its response shape — and so its model —
  // with the update call below.
  Future<Result<StaffDetailsSuccess>> getStaffDetails(int id) async {
    try {
      final url = ApiUrls.viewStaff(id);
      final result = await _apiService.get(url);
      if (result is Success) {
        return await _apiService.getResponseStatus<StaffDetailsSuccess>(
          result.value,
          (json) => StaffDetailsSuccess.fromJson(json),
        );
      } else if (result is Error) {
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }

  // Update Staff Service
  //
  // POST /api/update-staff/{id} as multipart/form-data, same shape as create.
  // A null photo means "no file part attached", which leaves the staff
  // member's existing photo untouched server-side.
  Future<Result<StaffDetailsSuccess>> updateStaff(
    int id,
    UpdateStaffApiRequest request,
  ) async {
    try {
      final url = ApiUrls.updateStaff(id);
      final result = await _apiService.multipart(
        url,
        request.photo,
        fields: request.toFormFields(),
        pathName: "photo",
      );
      if (result is Success) {
        return await _apiService.getResponseStatus<StaffDetailsSuccess>(
          result.value,
          (json) => StaffDetailsSuccess.fromJson(json),
        );
      } else if (result is Error) {
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }

  // Delete Staff Service
  //
  // DELETE /api/delete-staff/{id}, authorised by the bearer token ApiService
  // attaches. Uses the existing `ApiService.delete` — no earlier caller had
  // needed it before this.
  Future<Result<DeleteStaffSuccess>> deleteStaff(int id) async {
    try {
      final url = ApiUrls.deleteStaff(id);
      final result = await _apiService.delete(url);
      if (result is Success) {
        return await _apiService.getResponseStatus<DeleteStaffSuccess>(
          result.value,
          (json) => DeleteStaffSuccess.fromJson(json),
        );
      } else if (result is Error) {
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }

  // Get My Tasks List
    Future<Result<TaskListResponse>> getmyTasksList({
    required int page,
    required int perPage,
    String? search,
  }) async {
    try {
      final url = ApiUrls.getMyTasksList;
      final Map<String, dynamic> queryParams = <String, dynamic>{
        "page": page,
        "per_page": perPage,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams["search"] = search.trim();
      }
      final result = await _apiService.get(url, queryParams: queryParams);
      if (result is Success) {
        return await _apiService.getResponseStatus<TaskListResponse>(
          result.value,
          (json) => TaskListResponse.fromJson(json),
        );
      } else if (result is Error) {
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }
}
