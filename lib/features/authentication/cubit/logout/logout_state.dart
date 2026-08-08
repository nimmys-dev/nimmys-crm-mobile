part of 'logout_cubit.dart';

class LogoutState extends Equatable {
  final UIState<LogoutSuccessModel>? logoutUIState;
  const LogoutState({
    this.logoutUIState,
  });

  LogoutState copyWith({
    UIState<LogoutSuccessModel>? logoutUIState,
  }) {
    return LogoutState(
      logoutUIState: logoutUIState ?? this.logoutUIState,
    );
  }

  @override
  List<Object?> get props => [
    logoutUIState,
    logoutUIState?.status,
    logoutUIState?.data,
    logoutUIState?.errorType,
  ];
}
