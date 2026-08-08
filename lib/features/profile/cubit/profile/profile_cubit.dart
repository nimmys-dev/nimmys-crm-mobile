import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/features/profile/model/profile_model.dart';
import 'package:nimmys_crm/features/profile/repository/profile_repository.dart';
part 'profile_state.dart';

class ProfileCubit extends BaseCubit<ProfileState> {
  final ProfileRepository _repository;
  ProfileCubit(this._repository) : super(const ProfileState());


  // Profile Api Call
  void _setProfileUIState(UIState<ProfileSuccessModel>? uiState){
    emit(state.copyWith(profileUIState: uiState));
  }

  /// [force] re-fetches even when a profile is already loaded. The dashboard
  /// calls this on every mount, so without the guard a returning user would see
  /// the header blank out and refill on each visit.
  Future<void> getProfile({bool force = false}) async {
    if (!force && state.profileUIState?.data?.user != null) {
      return;
    }
    _setProfileUIState(UIState.loading());
    Result result = await _repository.getProfile();
    if (result is Success<ProfileSuccessModel>) {
      _setProfileUIState(UIState.success(result.value));
    }
    if (result is Error) {
      _setProfileUIState(UIState.error(result.type));
    }
  }

  /// Called on sign-out: the cubit outlives the screen, so without this the next
  /// account to sign in would see the previous user's name in the header.
  void resetProfileState() {
    _setProfileUIState(resetUIState<ProfileSuccessModel>(state.profileUIState));
  }

}
