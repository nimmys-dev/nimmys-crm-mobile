import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/profile/model/profile_model.dart';

class ProfileService {
  final ApiService _apiService;
  ProfileService(this._apiService);

  // Profile Service
  //
  // GET /api/profile. No parameters — the bearer token ApiService attaches
  // identifies the staff member, so this always returns the signed-in user.
  Future<Result<ProfileSuccessModel>> getProfile() async {
    try {
      final url = ApiUrls.profile;
      final result = await _apiService.get(url);
      if (result is Success) {
        return await _apiService.getResponseStatus<ProfileSuccessModel>(
          result.value,
          (json) => ProfileSuccessModel.fromJson(json),
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
