part of 'profile_cubit.dart';

class ProfileState extends Equatable {
  final UIState<ProfileSuccessModel>? profileUIState;
  const ProfileState({
    this.profileUIState,
  });

  ProfileState copyWith({
    UIState<ProfileSuccessModel>? profileUIState,
  }) {
    return ProfileState(
      profileUIState: profileUIState ?? this.profileUIState,
    );
  }

  @override
  List<Object?> get props => [
    profileUIState,
    profileUIState?.status,
    profileUIState?.data,
    profileUIState?.errorType,
  ];
}
