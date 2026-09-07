import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/features/dashboard/model/dashboard_count_model.dart';
import 'package:nimmys_crm/features/dashboard/model/lead_count_model.dart';
import 'package:nimmys_crm/features/dashboard/repository/dashboard_repository.dart';
import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';

part 'dashboard_state.dart';

class DashboardCubit extends BaseCubit<DashboardState> {
  final DashboardRepository _repository;
  static const int _pageSize = 10;

  DashboardCubit(this._repository) : super(const DashboardState());

  // ────────────────────────────────────────────────────────────────────────────
  // Summary Dashboard Count
  // ────────────────────────────────────────────────────────────────────────────
  void _setDashboardCountUIState(UIState<DashboardCount>? uiState) {
    emit(state.copyWith(dashboardCountUIState: uiState));
  }

  Future<void> getDashboardCount() async {
    _setDashboardCountUIState(UIState.loading());
    final result = await _repository.getDashboardCount();
    if (result is Success<DashboardCount>) {
      _setDashboardCountUIState(UIState.success(result.value));
    } else if (result is Error<DashboardCount>) {
      _setDashboardCountUIState(UIState.error(result.type));
    }
  }

  void resetDashboardCountState() {
    _setDashboardCountUIState(
      resetUIState<DashboardCount>(state.dashboardCountUIState),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Lead Count
  // ────────────────────────────────────────────────────────────────────────────
  void _setLeadCountUIState(UIState<LeadCountModel>? uiState) {
    emit(state.copyWith(leadCountUIState: uiState));
  }

  Future<void> getLeadCount() async {
    _setLeadCountUIState(UIState.loading());
    final result = await _repository.getLeadCount();
    if (result is Success<LeadCountModel>) {
      _setLeadCountUIState(UIState.success(result.value));
    } else if (result is Error<LeadCountModel>) {
      _setLeadCountUIState(UIState.error(result.type));
    }
  }

  void resetLeadCountState() {
    _setLeadCountUIState(resetUIState<LeadCountModel>(state.leadCountUIState));
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Task Counts (filtered + paginated) – follows LeadCubit pattern
  // ────────────────────────────────────────────────────────────────────────────
  void _setTaskCountsUIState(UIState<DashboardCount>? uiState) {
    emit(state.copyWith(taskCountsUIState: uiState));
  }

  /// Fetches a specific page of task counts.
  /// - [refresh] – if true, forces a fresh fetch (replaces list).
  /// - [filter] – the filter to apply (e.g., 'overdue_duty').
  /// - [scope] – the scope (default 'all_tasks').
  /// - [page] – the page number to fetch (default 1).
  /// - [isLoadMore] – internal flag to control the loading‑more indicator.
  Future<void> getTaskCounts({
    bool refresh = false,
    String? filter,
    String? scope,
    int page = 1,
    bool isLoadMore = false,
  }) async {
    // If loading more, show the footer loader
    if (isLoadMore) {
      emit(state.copyWith(isLoadingMoreTasks: true));
    }

    // Update the current filter/scope in state
    emit(state.copyWith(currentTaskFilter: filter, currentTaskScope: scope));

    // Determine if filter or scope changed since last fetch
    final filterChanged = filter != state.lastFetchedTaskFilter;
    final scopeChanged = scope != state.lastFetchedTaskScope;
    final shouldReplace = page == 1 || refresh || filterChanged || scopeChanged;

    // If not refreshing and we already have data and page is the current one, skip
    if (!refresh &&
        state.taskCountsUIState?.data != null &&
        page == (state.taskPagination?.currentPage ?? 1) &&
        !filterChanged &&
        !scopeChanged &&
        !isLoadMore) {
      // No need to reset loading flag because we haven't changed state
      return;
    }

    // Set loading state, and clear list if replacing
    emit(
      state.copyWith(
        taskCountsUIState: UIState.loading(),
        taskList: shouldReplace ? null : state.taskList,
        taskPagination: shouldReplace ? null : state.taskPagination,
      ),
    );

    final result = await _repository.getTaskCounts(
      filter: filter ?? state.currentTaskFilter ?? '',
      perPage: _pageSize,
      page: page,
      scope: scope ?? state.currentTaskScope,
    );

    if (result is Success<DashboardCount>) {
      final data = result.value;
      final newTasks = data.data?.tasks ?? [];
      final pagination = data.data?.pagination;

      final List<Task> updatedTasks = shouldReplace
          ? newTasks
          : [...?state.taskList, ...newTasks];

      emit(
        state.copyWith(
          taskCountsUIState: UIState.success(data),
          taskList: updatedTasks.isEmpty ? null : updatedTasks,
          taskPagination: pagination,
          lastFetchedTaskFilter: filter,
          lastFetchedTaskScope: scope,
          isLoadingMoreTasks: false, // Reset loader flag
        ),
      );
    } else if (result is Error<DashboardCount>) {
      emit(
        state.copyWith(
          taskCountsUIState: UIState.error(result.type),
          isLoadingMoreTasks: false, // Reset loader flag
        ),
      );
    }
  }

  /// Convenience method to refresh the current task list (page 1).
  Future<void> refreshTaskCounts() async {
    await getTaskCounts(
      refresh: true,
      filter: state.currentTaskFilter,
      scope: state.currentTaskScope,
      page: 1,
    );
  }

  /// Navigate to a specific page (used for pagination).
  /// If the page is greater than the current page, it's treated as "load more".
  Future<void> goToTaskPage(int page) async {
    if (page < 1) return;
    final currentPage = state.taskPagination?.currentPage ?? 1;
    if (page == currentPage) return;
    final isLoadMore = page > currentPage;
    await getTaskCounts(
      filter: state.currentTaskFilter,
      scope: state.currentTaskScope,
      page: page,
      isLoadMore: isLoadMore,
    );
  }

  /// Resets the task counts state to initial (null).
  void resetTaskCountsState() {
    emit(
      state.copyWith(
        taskCountsUIState: resetUIState<DashboardCount>(
          state.taskCountsUIState,
        ),
        taskList: null,
        taskPagination: null,
        lastFetchedTaskFilter: null,
        lastFetchedTaskScope: null,
        isLoadingMoreTasks: false,
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Reset Entire State
  // ────────────────────────────────────────────────────────────────────────────
  void resetDashboardState() {
    emit(const DashboardState());
  }
}
