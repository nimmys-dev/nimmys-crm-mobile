part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  final UIState<DashboardCount>? dashboardCountUIState;

  const DashboardState({
    this.dashboardCountUIState,
  });

  DashboardState copyWith({
    UIState<DashboardCount>? dashboardCountUIState,
  }) {
    return DashboardState(
      dashboardCountUIState: dashboardCountUIState ?? this.dashboardCountUIState,
    );
  }

  @override
  List<Object?> get props => [
        dashboardCountUIState,
        dashboardCountUIState?.status,
        dashboardCountUIState?.data,
        dashboardCountUIState?.errorType,
      ];
}