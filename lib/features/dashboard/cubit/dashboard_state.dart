part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  // ─── Summary counts ──────────────────────────────────────────
  final UIState<DashboardCount>? dashboardCountUIState;
  final UIState<LeadCountModel>? leadCountUIState;   // keep summary

  // ─── Task list (paginated) ──────────────────────────────────
  final UIState<DashboardCount>? taskCountsUIState;
  final List<Task>? taskList;
  final LeadPagination? taskPagination;
  final String? currentTaskFilter;
  final String? currentTaskScope;
  final String? lastFetchedTaskFilter;
  final String? lastFetchedTaskScope;
  final bool isLoadingMoreTasks;

  // ─── Lead list (paginated) ──────────────────────────────────
  final UIState<LeadCountModel>? leadListUIState;   // new
  final List<LeadItemData>? leadList;               // extracted from data.leads
  final LeadPagination? leadPagination;             // extracted from data.pagination
  final String? currentLeadFilter;
  final String? currentLeadScope;
  final String? lastFetchedLeadFilter;
  final String? lastFetchedLeadScope;
  final bool isLoadingMoreLeads;

  const DashboardState({
    this.dashboardCountUIState,
    this.leadCountUIState,
    this.taskCountsUIState,
    this.taskList,
    this.taskPagination,
    this.currentTaskFilter,
    this.currentTaskScope,
    this.lastFetchedTaskFilter,
    this.lastFetchedTaskScope,
    this.isLoadingMoreTasks = false,
    this.leadListUIState,
    this.leadList,
    this.leadPagination,
    this.currentLeadFilter,
    this.currentLeadScope,
    this.lastFetchedLeadFilter,
    this.lastFetchedLeadScope,
    this.isLoadingMoreLeads = false,
  });

  DashboardState copyWith({
    UIState<DashboardCount>? dashboardCountUIState,
    UIState<LeadCountModel>? leadCountUIState,
    UIState<DashboardCount>? taskCountsUIState,
    List<Task>? taskList,
    LeadPagination? taskPagination,
    String? currentTaskFilter,
    String? currentTaskScope,
    String? lastFetchedTaskFilter,
    String? lastFetchedTaskScope,
    bool? isLoadingMoreTasks,
    UIState<LeadCountModel>? leadListUIState,
    List<LeadItemData>? leadList,
    LeadPagination? leadPagination,
    String? currentLeadFilter,
    String? currentLeadScope,
    String? lastFetchedLeadFilter,
    String? lastFetchedLeadScope,
    bool? isLoadingMoreLeads,
  }) {
    return DashboardState(
      dashboardCountUIState: dashboardCountUIState ?? this.dashboardCountUIState,
      leadCountUIState: leadCountUIState ?? this.leadCountUIState,
      taskCountsUIState: taskCountsUIState ?? this.taskCountsUIState,
      taskList: taskList ?? this.taskList,
      taskPagination: taskPagination ?? this.taskPagination,
      currentTaskFilter: currentTaskFilter ?? this.currentTaskFilter,
      currentTaskScope: currentTaskScope ?? this.currentTaskScope,
      lastFetchedTaskFilter: lastFetchedTaskFilter ?? this.lastFetchedTaskFilter,
      lastFetchedTaskScope: lastFetchedTaskScope ?? this.lastFetchedTaskScope,
      isLoadingMoreTasks: isLoadingMoreTasks ?? this.isLoadingMoreTasks,
      leadListUIState: leadListUIState ?? this.leadListUIState,
      leadList: leadList ?? this.leadList,
      leadPagination: leadPagination ?? this.leadPagination,
      currentLeadFilter: currentLeadFilter ?? this.currentLeadFilter,
      currentLeadScope: currentLeadScope ?? this.currentLeadScope,
      lastFetchedLeadFilter: lastFetchedLeadFilter ?? this.lastFetchedLeadFilter,
      lastFetchedLeadScope: lastFetchedLeadScope ?? this.lastFetchedLeadScope,
      isLoadingMoreLeads: isLoadingMoreLeads ?? this.isLoadingMoreLeads,
    );
  }

  @override
  List<Object?> get props => [
        dashboardCountUIState,
        dashboardCountUIState?.status,
        dashboardCountUIState?.data,
        dashboardCountUIState?.errorType,
        leadCountUIState,
        leadCountUIState?.status,
        leadCountUIState?.data,
        leadCountUIState?.errorType,
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
        isLoadingMoreTasks,
        leadListUIState,
        leadListUIState?.status,
        leadListUIState?.data,
        leadListUIState?.errorType,
        leadList,
        leadPagination,
        currentLeadFilter,
        currentLeadScope,
        lastFetchedLeadFilter,
        lastFetchedLeadScope,
        isLoadingMoreLeads,
      ];
}