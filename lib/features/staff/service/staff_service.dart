import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/staff/api_request/create_staff_api_request.dart';
import 'package:nimmys_crm/features/staff/model/create_staffsuccess_model.dart';
import 'package:nimmys_crm/features/staff/model/staff_list_model.dart';
import 'package:nimmys_crm/features/staff/model/store_success_model.dart';

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

  // Staff List Service
  //
  // GET /api/staff. Paginated: the response carries a `pagination` block, and
  // the next page is requested by number rather than by following
  // `next_page_url` — that URL is absolute and would bypass ApiUrls entirely.
  Future<Result<StaffListSuccess>> getStaffList({
    required int page,
    required int perPage,
  }) async {
    try {
      final url = ApiUrls.staffList;
      final result = await _apiService.get(
        url,
        queryParams: <String, dynamic>{"page": page, "per_page": perPage},
      );
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

}
