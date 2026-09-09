import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/authentication/model/change_password_response.dart';
import 'package:nimmys_crm/features/authentication/repository/auth_repository.dart';

part 'change_password_state.dart';

class ChangePasswordCubit extends BaseCubit<ChangePasswordState> {
  ChangePasswordCubit(this._authRepository) : super(const ChangePasswordState());

  final AuthRepository _authRepository;

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (state.changePasswordUIState?.status == Status.LOADING) return;
    emit(state.copyWith(changePasswordUIState: UIState.loading()));
    final result = await _authRepository.changePassword(
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    if (result is Success<ChangePasswordResponse>) {
      emit(state.copyWith(changePasswordUIState: UIState.success(result.value)));
    } else if (result is Error<ChangePasswordResponse>) {
      emit(state.copyWith(changePasswordUIState: UIState.error(result.type)));
    }
  }

  void reset() => emit(state.copyWith(
    changePasswordUIState: resetUIState<ChangePasswordResponse>(
      state.changePasswordUIState,
    ),
  ));
}
