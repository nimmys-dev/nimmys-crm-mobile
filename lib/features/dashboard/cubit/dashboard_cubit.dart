import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/dashboard/model/dashboard_count_model.dart';
import 'package:nimmys_crm/features/dashboard/repository/dashboard_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends BaseCubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit(this._repository) : super(const DashboardState());

  // ---------------------------------------------------------------------------
  // Dashboard Count
  // ---------------------------------------------------------------------------

  void _setDashboardCountUIState(UIState<DashboardCount>? uiState) {
    emit(state.copyWith(dashboardCountUIState: uiState));
  }

  /// Fetches dashboard counts (leads, duties, etc.)
  Future<void> getDashboardCount() async {
    _setDashboardCountUIState(UIState.loading());

    final Result<DashboardCount> result = await _repository.getDashboardCount();

    if (result is Success<DashboardCount>) {
      _setDashboardCountUIState(UIState.success(result.value));
    } else if (result is Error<DashboardCount>) {
      _setDashboardCountUIState(UIState.error(result.type));
    }
  }

  /// Resets the dashboard count state to initial (null).
  void resetDashboardCountState() {
    _setDashboardCountUIState(
      resetUIState<DashboardCount>(state.dashboardCountUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Reset Entire State
  // ---------------------------------------------------------------------------

  void resetDashboardState() {
    emit(const DashboardState());
  }
}