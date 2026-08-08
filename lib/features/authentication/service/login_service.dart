import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/network/api_urls.dart';
import 'package:nimmys_crm/features/authentication/api_request/login_api_request.dart';
import 'package:nimmys_crm/features/authentication/model/login_model.dart';

class LoginService {
  final ApiService _apiService;
  LoginService(this._apiService);

  // Login Service
  //
  // POST /api/login with {email, password}. The API answers with both an HTTP
  // status and a `status` flag in the body, so both are checked: bad credentials
  // come back as 401 + {"status":false,"message":"Invalid credentials"}, and a
  // missing field as 422 with the offending field named.
  Future<Result<LoginSuccessModel>> login(LoginApiRequest request) async {
    try {
      final url = ApiUrls.login;
      final result = await _apiService.post(url, body: request.toJson());
      if (result is Success) {
        return await _apiService.getResponseStatus<LoginSuccessModel>(
          result.value,
          (json) => LoginSuccessModel.fromJson(json),
        );
      } else if (result is Error) {
        // A 401 here is a rejected email/password, not an expired session — the
        // generic "Authentication Required" copy would only confuse.
        if (result.type is UnauthenticatedError) {
          return Error(ErrorWithMessage(message: "Email or password is incorrect"));
        }
        return Error(result.type);
      } else {
        return Error(GenericError());
      }
    } catch(e) {
      return Error(DeserializationError());
    }
  }

}
