import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/profile/model/profile_model.dart';
import 'package:nimmys_crm/features/profile/service/profile_service.dart';

class ProfileRepository {
  final ProfileService _service;
  ProfileRepository(this._service);

  // Profile Repo
  Future<Result<ProfileSuccessModel>> getProfile() async {
    try {
      return await _service.getProfile();
    } catch (e) {
      return Error(ErrorWithMessage(message: e.toString()));
    }
  }

}
