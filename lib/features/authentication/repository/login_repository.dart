import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/authentication/api_request/login_api_request.dart';
import 'package:nimmys_crm/features/authentication/model/login_model.dart';
import 'package:nimmys_crm/features/authentication/service/login_service.dart';

class LoginRepository {
  final LoginService _service;
  LoginRepository(this._service);

  // Login Repo
  Future<Result<LoginModel>> login(LoginApiRequest request) async {
    try {
      return await _service.login(request);
    } catch (e) {
      return Error(ErrorWithMessage(message: e.toString()));
    }
  }

}