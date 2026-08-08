import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/features/authentication/api_request/login_api_request.dart';
import 'package:nimmys_crm/features/authentication/model/login_model.dart';
import 'package:nimmys_crm/features/authentication/repository/auth_repository.dart';
import 'package:nimmys_crm/features/authentication/repository/login_repository.dart';
part 'login_state.dart';

class LoginCubit extends BaseCubit<LoginState> {
  final LoginRepository _repository;
  final AuthRepository _authRepository;
  LoginCubit(this._repository, this._authRepository) : super(const LoginState());


  // Login Api Call
  void _setLoginUIState(UIState<LoginSuccessModel>? uiState){
    emit(state.copyWith(loginUIState: uiState));
  }

  Future<void> login(LoginApiRequest request) async {
    _setLoginUIState(UIState.loading());
    Result result = await _repository.login(request);
    if (result is Success<LoginSuccessModel>) {
      // Session first, SUCCESS second: the listener navigates on SUCCESS, and the
      // next screen's request needs the token already in secure storage.
      // `Error<bool>`, not a bare `Error`: `Result<bool>` is not a subtype of
      // `Error<dynamic>`, so the bare form never promotes and `.type` is unresolved.
      final Result<bool> saved = await _authRepository.saveUserInfoFromLogin(result.value);
      if (saved is Error<bool>) {
        _setLoginUIState(UIState.error(saved.type));
        return;
      }
      _setLoginUIState(UIState.success(result.value));
    }
    if (result is Error) {
      _setLoginUIState(UIState.error(result.type));
    }
  }

  // Drops the terminal state so a dismissed error or a return to this screen
  // does not replay the old toast / navigation.
  void resetLoginState() {
    _setLoginUIState(resetUIState<LoginSuccessModel>(state.loginUIState));
  }

}
