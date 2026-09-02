part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  final UIState<DashboardCount>? dashboardCountUIState;
  final UIState<LeadCountModel>? leadCountUIState;

  const DashboardState({this.dashboardCountUIState, this.leadCountUIState});

  DashboardState copyWith({
    UIState<DashboardCount>? dashboardCountUIState,
    UIState<LeadCountModel>? leadCountUIState,
  }) {
    return DashboardState(
      dashboardCountUIState:
          dashboardCountUIState ?? this.dashboardCountUIState,
      leadCountUIState: leadCountUIState ?? this.leadCountUIState,
    );
  }

  @override
  List<Object?> get props => [

    // Dashboard Count
    dashboardCountUIState,
    dashboardCountUIState?.status,
    dashboardCountUIState?.data,
    dashboardCountUIState?.errorType,

    // Lead Count 
    leadCountUIState,
    leadCountUIState?.status,
    leadCountUIState?.data,
    leadCountUIState?.errorType,
  ];
}
