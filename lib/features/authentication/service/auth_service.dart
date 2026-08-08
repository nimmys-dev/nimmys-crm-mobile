import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/authentication/model/logout_model.dart';

class AuthService {
  final ApiService _apiService;
  AuthService(this._apiService);

  // Logout Service
  //
  // POST /api/logout, authorised by the bearer token ApiService attaches from
  // secure storage. A 401 is treated as success: the token the server is
  // rejecting is the very one being revoked, so the session is already gone.
  Future<Result<LogoutSuccessModel>> logout() async {
    try {
      final url = ApiUrls.logout;
      final result = await _apiService.post(url);
      if (result is Success) {
        return await _apiService.getResponseStatus<LogoutSuccessModel>(
          result.value,
          (json) => LogoutSuccessModel.fromJson(json),
        );
      } else if (result is Error) {
        if (result.type is UnauthenticatedError || result.type is InvalidTokenError) {
          return Success(LogoutSuccessModel(status: true, statusCode: 200, message: "Logout successful"));
        }
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch (e) {
      return Error(DeserializationError());
    }
  }

}
