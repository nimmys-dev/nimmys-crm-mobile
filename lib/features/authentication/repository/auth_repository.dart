import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/storage/secured_shared_preferences.dart';
import 'package:nimmys_crm/features/authentication/model/forgot_password_response.dart';
import 'package:nimmys_crm/features/authentication/model/login_model.dart';
import 'package:nimmys_crm/features/authentication/model/logout_model.dart';
import 'package:nimmys_crm/features/authentication/model/change_password_response.dart';
import 'package:nimmys_crm/features/authentication/service/auth_service.dart';
import 'package:nimmys_crm/service/push_notification/notification_service.dart';
import 'package:nimmys_crm/utils/app_string.dart';
import 'package:nimmys_crm/utils/custom_log.dart';

class AuthRepository {
  final SecuredSharedPreferences _securedSharedPref;
  final NotificationService _notificationService;
  final AuthService _authService;
  AuthRepository(
    this._securedSharedPref,
    this._notificationService,
    this._authService,
  );

  // Save user data from login
  //
  // The token is what every later request authenticates with, so a failure here
  // has to surface as an Error — a "logged in" session with no stored token
  // would 401 on the very next call.
  Future<Result<bool>> saveUserInfoFromLogin(LoginSuccessModel login) async {
    try {
      final token = login.token;
      if (token == null || token.isEmpty) {
        CustomLog.error(this, "Login response carried no token", null);
        return Error(
          ErrorWithMessage(message: AppString.errorType.loginAttemptError),
        );
      }
      await _securedSharedPref.saveKey(AppString.sessionKey.userToken, token);

      final user = login.user;
      if (user != null) {
        await _securedSharedPref.saveKey(
          AppString.sessionKey.userId,
          user.id?.toString() ?? "",
        );
        await _securedSharedPref.saveKey(
          AppString.sessionKey.userFullName,
          user.name ?? "",
        );
        await _securedSharedPref.saveKey(
          AppString.sessionKey.userEmail,
          user.email ?? "",
        );
        await _securedSharedPref.saveKey(
          AppString.sessionKey.userType,
          user.role ?? "",
        );
      }
      CustomLog.debug(this, "Save user from login saved successfully");
      return const Success(true);
    } catch (e) {
      CustomLog.error(this, "Save Resident user info to preferences error", e);
      return Error(GenericError());
    }
  }

  // Logged in check
  Future<bool> isLoggedIn() async {
    final token = await _securedSharedPref.get(AppString.sessionKey.userToken);
    return token != null && token.isNotEmpty;
  }

  // Clear auth & cache
  Future<void> _clearAuthData() async {
    await _securedSharedPref.reset();
    await _notificationService.clearBadgeCount();
    await _notificationService.clearFcmToken();
  }

  // Logout
  //
  // The local session is cleared whichever way the API call goes: the user asked
  // to leave, and leaving a token on the device that they believe is gone is the
  // worse failure. The Result still reports what the server said, so the caller
  // can show the real error — it just has no bearing on being signed out.
  Future<Result<LogoutSuccessModel>> logout() async {
    try {
      final result = await _authService.logout();
      return result;
    } catch (e) {
      CustomLog.error(this, "Logout attempt error", e);
      return Error(GenericError());
    } finally {
      await _clearAuthData();
    }
  }

  // Sign out
  Future<Result<bool>> signOut() async {
    try {
      await _clearAuthData();
      return const Success(true);
    } catch (e) {
      CustomLog.error(this, "SignOut attempt error", e);
      return Error(GenericError());
    }
  }

  // Returns the API response (success/failure) without modifying local storage.
  Future<Result<ForgotPasswordResponse>> forgotPassword(String email) async {
    try {
      return await _authService.forgotPassword(email);
    } catch (e) {
      CustomLog.error(this, "Forgot password attempt error", e);
      return Error(GenericError());
    }
  }

  Future<Result<ChangePasswordResponse>> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) => _authService.changePassword(
    currentPassword: currentPassword,
    password: password,
    passwordConfirmation: passwordConfirmation,
  );
}
