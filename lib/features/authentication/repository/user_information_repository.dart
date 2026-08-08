import 'package:nimmys_crm/data/storage/secured_shared_preferences.dart';
import 'package:nimmys_crm/utils/app_string.dart';

class UserInformationRepository {
  final SecuredSharedPreferences _securedSharedPref;
  UserInformationRepository(this._securedSharedPref);


  Future<String?> getUserToken() async {
    return await _securedSharedPref.get(AppString.sessionKey.userToken);
  }

  Future<String?> getUserID() async {
    return await _securedSharedPref.get(AppString.sessionKey.userId);
  }

  Future<String?> getUsername() async {
    return  await _securedSharedPref.get(AppString.sessionKey.userFullName);
  }


  Future<String?> getUserEmail() async {
    return  await _securedSharedPref.get(AppString.sessionKey.userEmail);
  }


  /// The `user.role` from the login response, stored under `userType` by
  /// [AuthRepository.saveUserInfoFromLogin]. Drives every permission check in
  /// the app — see `core/auth/app_permission.dart`.
  Future<String?> getUserRole() async {
    return  await _securedSharedPref.get(AppString.sessionKey.userType);
  }


  Future<String?> getAddress() async {
    return  await _securedSharedPref.get(AppString.sessionKey.userAddress);
  }


  Future<String?> getFcmToken() async {
    return  await _securedSharedPref.get(AppString.sessionKey.fcmToken);
  }


}