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
  // Summary Lead Count
  // ────────────────────────────────────────────────────────────────────────────
  void _setLeadCountUIState(UIState<LeadCountModel>? uiState) {
    emit(state.copyWith(leadCountUIState: uiState));
  }

  Future<void> getLeadCount() async {
    _setLeadCountUIState(UIState.loading());
    final result = await _repository.getLeadCount(); // no pagination params
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
  // Task Counts (filtered + paginated)
  // ────────────────────────────────────────────────────────────────────────────
  void _setTaskCountsUIState(UIState<DashboardCount>? uiState) {
    emit(state.copyWith(taskCountsUIState: uiState));
  }

  Future<void> getTaskCounts({
    bool refresh = false,
    String? filter,
    String? scope,
    int page = 1,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      emit(state.copyWith(isLoadingMoreTasks: true));
    }

    emit(state.copyWith(currentTaskFilter: filter, currentTaskScope: scope));

    final filterChanged = filter != state.lastFetchedTaskFilter;
    final scopeChanged = scope != state.lastFetchedTaskScope;
    final shouldReplace = page == 1 || refresh || filterChanged || scopeChanged;

    if (!refresh &&
        state.taskCountsUIState?.data != null &&
        page == (state.taskPagination?.currentPage ?? 1) &&
        !filterChanged &&
        !scopeChanged &&
        !isLoadMore) {
      return;
    }

    emit(
      state.copyWith(
        taskCountsUIState: UIState.loading(),
        // An empty list must replace old rows. Passing null to DashboardState's
        // copyWith keeps the previous value and leaves stale tasks on screen.
        taskList: shouldReplace ? const <Task>[] : state.taskList,
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
          taskList: updatedTasks,
          taskPagination: pagination,
          lastFetchedTaskFilter: filter,
          lastFetchedTaskScope: scope,
          isLoadingMoreTasks: false,
        ),
      );
    } else if (result is Error<DashboardCount>) {
      emit(
        state.copyWith(
          taskCountsUIState: UIState.error(result.type),
          isLoadingMoreTasks: false,
        ),
      );
    }
  }

  Future<void> refreshTaskCounts() async {
    await getTaskCounts(
      refresh: true,
      filter: state.currentTaskFilter,
      scope: state.currentTaskScope,
      page: 1,
    );
  }

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
  // LEAD LIST (filtered + paginated) – NEW
  // ────────────────────────────────────────────────────────────────────────────
  void _setLeadListUIState(UIState<LeadCountModel>? uiState) {
    emit(state.copyWith(leadListUIState: uiState));
  }

  Future<void> getLeads({
    bool refresh = false,
    String? filter,
    String? scope,
    int page = 1,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      emit(state.copyWith(isLoadingMoreLeads: true));
    }

    emit(state.copyWith(currentLeadFilter: filter, currentLeadScope: scope));

    final filterChanged = filter != state.lastFetchedLeadFilter;
    final scopeChanged = scope != state.lastFetchedLeadScope;
    final shouldReplace = page == 1 || refresh || filterChanged || scopeChanged;

    if (!refresh &&
        state.leadListUIState?.data != null &&
        page == (state.leadPagination?.currentPage ?? 1) &&
        !filterChanged &&
        !scopeChanged &&
        !isLoadMore) {
      return;
    }

    emit(
      state.copyWith(
        leadListUIState: UIState.loading(),
        // As above, explicitly clear stale rows while the replacement page loads.
        leadList: shouldReplace ? const <LeadItemData>[] : state.leadList,
        leadPagination: shouldReplace ? null : state.leadPagination,
      ),
    );

    final result = await _repository.getLeadCount(
      filter: filter ?? state.currentLeadFilter ?? '',
      perPage: _pageSize,
      page: page,
      scope: scope ?? state.currentLeadScope,
    );

    if (result is Success<LeadCountModel>) {
      final data = result.value;
      final newLeads = data.data?.leads ?? [];
      final pagination = data.data?.pagination;

      final List<LeadItemData> updatedLeads = shouldReplace
          ? newLeads
          : [...?state.leadList, ...newLeads];

      emit(
        state.copyWith(
          leadListUIState: UIState.success(data),
          leadList: updatedLeads,
          leadPagination: pagination,
          lastFetchedLeadFilter: filter,
          lastFetchedLeadScope: scope,
          isLoadingMoreLeads: false,
        ),
      );
    } else if (result is Error<LeadCountModel>) {
      emit(
        state.copyWith(
          leadListUIState: UIState.error(result.type),
          isLoadingMoreLeads: false,
        ),
      );
    }
  }

  Future<void> refreshLeads() async {
    await getLeads(
      refresh: true,
      filter: state.currentLeadFilter,
      scope: state.currentLeadScope,
      page: 1,
    );
  }

  Future<void> goToLeadPage(int page) async {
    if (page < 1) return;
    final currentPage = state.leadPagination?.currentPage ?? 1;
    if (page == currentPage) return;
    final isLoadMore = page > currentPage;
    await getLeads(
      filter: state.currentLeadFilter,
      scope: state.currentLeadScope,
      page: page,
      isLoadMore: isLoadMore,
    );
  }

  void resetLeadListState() {
    emit(
      state.copyWith(
        leadListUIState: resetUIState<LeadCountModel>(state.leadListUIState),
        leadList: null,
        leadPagination: null,
        lastFetchedLeadFilter: null,
        lastFetchedLeadScope: null,
        isLoadingMoreLeads: false,
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
