import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/features/authentication/api_request/login_api_request.dart';
import 'package:nimmys_crm/features/authentication/model/login_model.dart';
import 'package:nimmys_crm/features/authentication/repository/login_repository.dart';
part 'login_state.dart';

class LoginCubit extends BaseCubit<LoginState> {
  final LoginRepository _repository;
  LoginCubit(this._repository) : super(const LoginState());


  // Login Api Call
  void _setLoginIState(UIState<LoginModel>? uiState){
    emit(state.copyWith(sendOtpState: uiState));
  }
  Future<void> login(LoginApiRequest request) async {
    _setLoginIState(UIState.loading());
    Result result = await _repository.login(request);
    if (result is Success<LoginModel>) {
      _setLoginIState(UIState.success(result.value));
    }
    if (result is Error) {
      _setLoginIState(UIState.error(result.type));
    }
  }

}
