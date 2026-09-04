part of 'login_cubit.dart';

class LoginState extends Equatable {
  final UIState<LoginSuccessModel>? loginUIState;
  final UIState<ForgotPasswordResponse>? forgotPasswordUIState;
  const LoginState({this.loginUIState, this.forgotPasswordUIState});

  LoginState copyWith({
    UIState<LoginSuccessModel>? loginUIState,
    UIState<ForgotPasswordResponse>? forgotPasswordUIState,
  }) {
    return LoginState(
      loginUIState: loginUIState ?? this.loginUIState,
      forgotPasswordUIState:
          forgotPasswordUIState ?? this.forgotPasswordUIState,
    );
  }

  @override
  List<Object?> get props => [
    // login
    loginUIState,
    loginUIState?.status,
    loginUIState?.data,
    loginUIState?.errorType,

    // forgot password
    forgotPasswordUIState,
    forgotPasswordUIState?.status,
    forgotPasswordUIState?.data,
    forgotPasswordUIState?.errorType,
  ];
}
