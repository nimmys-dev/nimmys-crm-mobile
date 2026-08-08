import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/features/authentication/model/logout_model.dart';
import 'package:nimmys_crm/features/authentication/repository/auth_repository.dart';
part 'logout_state.dart';

class LogoutCubit extends BaseCubit<LogoutState> {
  final AuthRepository _authRepository;
  LogoutCubit(this._authRepository) : super(const LogoutState());


  // Logout Api Call
  void _setLogoutUIState(UIState<LogoutSuccessModel>? uiState){
    emit(state.copyWith(logoutUIState: uiState));
  }

  Future<void> logout() async {
    _setLogoutUIState(UIState.loading());
    Result result = await _authRepository.logout();
    if (result is Success<LogoutSuccessModel>) {
      _setLogoutUIState(UIState.success(result.value));
    }
    if (result is Error) {
      // ERROR reports what the server said; the device session is already gone
      // either way, so the screen routes to login on both outcomes.
      _setLogoutUIState(UIState.error(result.type));
    }
  }

  void resetLogoutState() {
    _setLogoutUIState(resetUIState<LogoutSuccessModel>(state.logoutUIState));
  }

}
