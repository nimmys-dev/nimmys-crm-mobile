import 'dart:io'; // add for File type
import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/features/profile/model/company_details_model.dart';
import 'package:nimmys_crm/features/profile/repository/profile_repository.dart';

part 'company_profile_state.dart';

class CompanyProfileCubit extends BaseCubit<CompanyProfileState> {
  final ProfileRepository _repository;

  CompanyProfileCubit(this._repository) : super(const CompanyProfileState());

  void _setCompanyProfileUIState(UIState<CompanyProfileResponse>? uiState) {
    emit(state.copyWith(companyProfileUIState: uiState));
  }

  // ---------- GET ----------
  Future<void> getCompanyProfile({bool force = false}) async {
    if (!force && state.companyProfileUIState?.data != null) {
      return;
    }

    _setCompanyProfileUIState(UIState.loading());
    final Result result = await _repository.getCompanyProfile();

    if (result is Success<CompanyProfileResponse>) {
      _setCompanyProfileUIState(UIState.success(result.value));
    } else if (result is Error) {
      _setCompanyProfileUIState(UIState.error(result.type));
    }
  }

  // ---------- UPDATE ----------
  Future<void> updateCompanyProfile({
    required String name,
    required String addressLine,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required String phone,
    required String email,
    File? logo,
  }) async {
    _setCompanyProfileUIState(UIState.loading());

    final Result result = await _repository.updateCompanyProfile(
      name: name,
      addressLine: addressLine,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      phone: phone,
      email: email,
      logo: logo,
    );

    if (result is Success<CompanyProfileResponse>) {
      _setCompanyProfileUIState(UIState.success(result.value));
    } else if (result is Error) {
      _setCompanyProfileUIState(UIState.error(result.type));
    }
  }

  // ---------- RESET ----------
  void resetCompanyProfileState() {
    _setCompanyProfileUIState(
      resetUIState<CompanyProfileResponse>(state.companyProfileUIState),
    );
  }
}