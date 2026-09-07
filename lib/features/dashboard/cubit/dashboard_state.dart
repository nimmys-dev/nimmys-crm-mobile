part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  // ─── Summary ──────────────────────────────────────────────────────────────
  final UIState<DashboardCount>? dashboardCountUIState;

  // ─── Task Counts (filtered + paginated) ──────────────────────────────────
  final UIState<DashboardCount>? taskCountsUIState;
  final List<Task>? taskList;
  final LeadPagination? taskPagination;
  final String? currentTaskFilter;
  final String? currentTaskScope;
  final String? lastFetchedTaskFilter;
  final String? lastFetchedTaskScope;

  // ─── Loading state for pagination ────────────────────────────────────────
  final bool isLoadingMoreTasks; // <-- NEW

  // ─── Lead Count ───────────────────────────────────────────────────────────
  final UIState<LeadCountModel>? leadCountUIState;

  const DashboardState({
    this.dashboardCountUIState,
    this.taskCountsUIState,
    this.taskList,
    this.taskPagination,
    this.currentTaskFilter,
    this.currentTaskScope,
    this.lastFetchedTaskFilter,
    this.lastFetchedTaskScope,
    this.isLoadingMoreTasks = false, // <-- default false
    this.leadCountUIState,
  });

  DashboardState copyWith({
    UIState<DashboardCount>? dashboardCountUIState,
    UIState<DashboardCount>? taskCountsUIState,
    List<Task>? taskList,
    LeadPagination? taskPagination,
    String? currentTaskFilter,
    String? currentTaskScope,
    String? lastFetchedTaskFilter,
    String? lastFetchedTaskScope,
    bool? isLoadingMoreTasks,
    UIState<LeadCountModel>? leadCountUIState,
  }) {
    return DashboardState(
      dashboardCountUIState: dashboardCountUIState ?? this.dashboardCountUIState,
      taskCountsUIState: taskCountsUIState ?? this.taskCountsUIState,
      taskList: taskList ?? this.taskList,
      taskPagination: taskPagination ?? this.taskPagination,
      currentTaskFilter: currentTaskFilter ?? this.currentTaskFilter,
      currentTaskScope: currentTaskScope ?? this.currentTaskScope,
      lastFetchedTaskFilter: lastFetchedTaskFilter ?? this.lastFetchedTaskFilter,
      lastFetchedTaskScope: lastFetchedTaskScope ?? this.lastFetchedTaskScope,
      isLoadingMoreTasks: isLoadingMoreTasks ?? this.isLoadingMoreTasks,
      leadCountUIState: leadCountUIState ?? this.leadCountUIState,
    );
  }

  @override
  List<Object?> get props => [
        dashboardCountUIState,
        dashboardCountUIState?.status,
        dashboardCountUIState?.data,
        dashboardCountUIState?.errorType,
        taskCountsUIState,
        taskCountsUIState?.status,
        taskCountsUIState?.data,
        taskCountsUIState?.errorType,
        taskList,
        taskPagination,
        currentTaskFilter,
        currentTaskScope,
        lastFetchedTaskFilter,
        lastFetchedTaskScope,
        isLoadingMoreTasks, // <-- added
        leadCountUIState,
        leadCountUIState?.status,
        leadCountUIState?.data,
        leadCountUIState?.errorType,
      ];
}