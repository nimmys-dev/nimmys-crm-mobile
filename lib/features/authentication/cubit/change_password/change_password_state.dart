part of 'change_password_cubit.dart';

class ChangePasswordState extends Equatable {
  const ChangePasswordState({this.changePasswordUIState});
  final UIState<ChangePasswordResponse>? changePasswordUIState;

  ChangePasswordState copyWith({
    UIState<ChangePasswordResponse>? changePasswordUIState,
  }) => ChangePasswordState(
    changePasswordUIState: changePasswordUIState ?? this.changePasswordUIState,
  );

  @override
  List<Object?> get props => <Object?>[
    changePasswordUIState,
    changePasswordUIState?.status,
    changePasswordUIState?.data,
    changePasswordUIState?.errorType,
  ];
}
