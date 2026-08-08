part of 'login_cubit.dart';

class LoginState extends Equatable {
  final UIState<LoginSuccessModel>? loginUIState;
  const LoginState({
    this.loginUIState,
 });

  LoginState copyWith({
    UIState<LoginSuccessModel>? loginUIState,
  }) {
    return LoginState(
      loginUIState: loginUIState ?? this.loginUIState,
    );
  }

  @override
  List<Object?> get props => [
    loginUIState,
    loginUIState?.status,
    loginUIState?.data,
    loginUIState?.errorType,
  ];
}
