part of 'company_profile_cubit.dart';

class CompanyProfileState extends Equatable {
  final UIState<CompanyProfileResponse>? companyProfileUIState;

  const CompanyProfileState({
    this.companyProfileUIState,
  });

  CompanyProfileState copyWith({
    UIState<CompanyProfileResponse>? companyProfileUIState,
  }) {
    return CompanyProfileState(
      companyProfileUIState: companyProfileUIState ?? this.companyProfileUIState,
    );
  }

  @override
  List<Object?> get props => [
        companyProfileUIState,
        companyProfileUIState?.status,
        companyProfileUIState?.data,
        companyProfileUIState?.errorType,
      ];
}