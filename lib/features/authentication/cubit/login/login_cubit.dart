import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/features/authentication/api_request/login_api_request.dart';
import 'package:nimmys_crm/features/authentication/model/login_model.dart';
import 'package:nimmys_crm/features/authentication/model/forgot_password_response.dart'; // ✅ ensure import
import 'package:nimmys_crm/features/authentication/repository/auth_repository.dart';
import 'package:nimmys_crm/features/authentication/repository/login_repository.dart';

part 'login_state.dart';

class LoginCubit extends BaseCubit<LoginState> {
  final LoginRepository _repository;
  final AuthRepository _authRepository;
  LoginCubit(this._repository, this._authRepository)
    : super(const LoginState());

  // ---- Login ----
  void _setLoginUIState(UIState<LoginSuccessModel>? uiState) {
    emit(state.copyWith(loginUIState: uiState));
  }

  Future<void> login(LoginApiRequest request) async {
    _setLoginUIState(UIState.loading());
    Result result = await _repository.login(request);
    if (result is Success<LoginSuccessModel>) {
      final Result<bool> saved = await _authRepository.saveUserInfoFromLogin(
        result.value,
      );
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

  void resetLoginState() {
    _setLoginUIState(resetUIState<LoginSuccessModel>(state.loginUIState));
  }

  // ---- Forgot Password ----
  void _setForgotPasswordUIState(UIState<ForgotPasswordResponse>? uiState) {
    emit(state.copyWith(forgotPasswordUIState: uiState));
  }

  Future<void> forgotPassword(String email) async {
    _setForgotPasswordUIState(UIState.loading());
    final Result<ForgotPasswordResponse> result = await _authRepository
        .forgotPassword(email);
    if (result is Success<ForgotPasswordResponse>) {
      _setForgotPasswordUIState(UIState.success(result.value));
    } else if (result is Error<ForgotPasswordResponse>) {
      _setForgotPasswordUIState(
        UIState.error(result.type),
      ); // ✅ now 'type' is resolved
    }
  }

  void resetForgotPasswordState() {
    _setForgotPasswordUIState(
      resetUIState<ForgotPasswordResponse>(state.forgotPasswordUIState),
    );
  } // Drops the terminal state so a dismissed error or a return to this screen
}
