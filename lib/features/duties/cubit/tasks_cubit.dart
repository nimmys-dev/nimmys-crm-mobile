import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/duties/model/get_all_pending_task_model.dart';
import 'package:nimmys_crm/features/duties/model/task_completed_model.dart';
import 'package:nimmys_crm/features/duties/model/task_details_model.dart';
import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';
import 'package:nimmys_crm/features/duties/repository/tasks_repository.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';

part 'tasks_state.dart';

class TasksCubit extends BaseCubit<TasksState> {
  final TasksRepository _repository;

  TasksCubit(this._repository) : super(const TasksState());

  static const int _pageSize = 10;

  // ---------------------------------------------------------------------------
  // Tasks List
  // ---------------------------------------------------------------------------

  Future<void> getTasks({bool refresh = false, String? search}) async {
    await _fetchTasksPage(page: 1, search: search, skipIfCached: !refresh);
  }

  Future<void> refreshTasks() async {
    await _fetchTasksPage(page: 1, skipIfCached: false);
  }

  Future<void> goToTasksPage(int page) async {
    if (page < 1 || page == state.tasksPagination?.currentPage) {
      return;
    }
    await _fetchTasksPage(page: page, skipIfCached: false);
  }

  Future<void> _fetchTasksPage({
    required int page,
    String? search,
    bool skipIfCached = false,
  }) async {
    if (state.tasksListUIState?.status == Status.LOADING) {
      return;
    }

    final String query = (search ?? state.tasksSearchQuery).trim();
    final bool searchChanged = query != state.tasksSearchQuery;

    if (!searchChanged &&
        skipIfCached &&
        state.tasksList.isNotEmpty &&
        page == (state.tasksPagination?.currentPage ?? 1)) {
      return;
    }

    emit(
      state.copyWith(
        tasksListUIState: UIState.loading(),
        tasksSearchQuery: query,
        tasksList: searchChanged ? <Task>[] : state.tasksList,
      ),
    );

    final Result<TaskListResponse> result = await _repository.getTasks(
      page: page,
      perPage: _pageSize,
      search: query,
    );

    if (result is Success<TaskListResponse>) {
      final bool shouldReplace = page == 1 || searchChanged;
      final List<Task> newItems = result.value.data ?? <Task>[];

      final List<Task> updatedTasks = shouldReplace
          ? newItems
          : [...state.tasksList, ...newItems];

      emit(
        state.copyWith(
          tasksListUIState: UIState.success(result.value),
          tasksList: updatedTasks,
          tasksPagination: result.value.pagination,
        ),
      );
    } else if (result is Error<TaskListResponse>) {
      emit(state.copyWith(tasksListUIState: UIState.error(result.type)));
    }
  }

  // ---------------------------------------------------------------------------
  // Task Details
  // ---------------------------------------------------------------------------

  void _setTaskDetailsUIState(UIState<TaskDetailsResponse>? uiState) {
    emit(state.copyWith(taskDetailsUIState: uiState));
  }

  Future<void> getTaskDetails(int id) async {
    _setTaskDetailsUIState(UIState.loading());

    final Result<TaskDetailsResponse> result = await _repository.getTaskDetails(
      id,
    );

    if (result is Success<TaskDetailsResponse>) {
      _setTaskDetailsUIState(UIState.success(result.value));
    } else if (result is Error<TaskDetailsResponse>) {
      _setTaskDetailsUIState(UIState.error(result.type));
    }
  }

  void resetTaskDetailsState() {
    _setTaskDetailsUIState(
      resetUIState<TaskDetailsResponse>(state.taskDetailsUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Create Task
  // ---------------------------------------------------------------------------

  void _setCreateTaskUIState(UIState<dynamic>? uiState) {
    emit(state.copyWith(createTaskUIState: uiState));
  }

  Future<void> createTask(Map<String, dynamic> payload) async {
    if (state.createTaskUIState?.status == Status.LOADING) {
      return;
    }

    _setCreateTaskUIState(UIState.loading());

    final Result<dynamic> result = await _repository.createTask(payload);

    if (result is Success<dynamic>) {
      _setCreateTaskUIState(UIState.success(result.value));
      unawaited(getTasks(refresh: true));
    } else if (result is Error<dynamic>) {
      _setCreateTaskUIState(UIState.error(result.type));
    }
  }

  void resetCreateTaskState() {
    _setCreateTaskUIState(resetUIState<dynamic>(state.createTaskUIState));
  }

  // ---------------------------------------------------------------------------
  // Update Task
  // ---------------------------------------------------------------------------

  void _setUpdateTaskUIState(UIState<TaskDetailsResponse>? uiState) {
    emit(state.copyWith(updateTaskUIState: uiState));
  }

  Future<void> updateTask(int id, Map<String, dynamic> payload) async {
    if (state.updateTaskUIState?.status == Status.LOADING) return;

    _setUpdateTaskUIState(UIState.loading());
    final Result<TaskDetailsResponse> result = await _repository.updateTask(
      id,
      payload,
    );

    if (result is Success<TaskDetailsResponse>) {
      _setUpdateTaskUIState(UIState.success(result.value));
      if (state.taskDetailsUIState?.data?.data?.id == id) {
        _setTaskDetailsUIState(UIState.success(result.value));
      }
      unawaited(getTasks(refresh: true));
    } else if (result is Error<TaskDetailsResponse>) {
      _setUpdateTaskUIState(UIState.error(result.type));
    }
  }

  void resetUpdateTaskState() {
    _setUpdateTaskUIState(
      resetUIState<TaskDetailsResponse>(state.updateTaskUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Complete Task
  // ---------------------------------------------------------------------------

  void _setCompleteTaskUIState(UIState<TaskCompleteResponse>? uiState) {
    emit(state.copyWith(completeTaskUIState: uiState));
  }

  /// Marks a task as completed.
  Future<void> completeTask(int id, {String? remarks}) async {
    if (state.completeTaskUIState?.status == Status.LOADING) return;

    _setCompleteTaskUIState(UIState.loading());

    final result = await _repository.completeTask(id, remarks: remarks);

    if (result is Success<TaskCompleteResponse>) {
      _setCompleteTaskUIState(UIState.success(result.value));
      // Refresh the task list after completion
      unawaited(getTasks(refresh: true));
      // Optionally refresh task details if the current details screen is showing this task
      if (state.taskDetailsUIState?.data?.data?.id == id) {
        unawaited(getTaskDetails(id));
      }
    } else if (result is Error<TaskCompleteResponse>) {
      _setCompleteTaskUIState(UIState.error(result.type));
    }
  }

  void resetCompleteTaskState() {
    _setCompleteTaskUIState(
      resetUIState<TaskCompleteResponse>(state.completeTaskUIState),
    );
  }
  // ---------------------------------------------------------------------------
  // Delete Task
  // ---------------------------------------------------------------------------

  void _setDeleteTaskUIState(UIState<dynamic>? uiState) {
    emit(state.copyWith(deleteTaskUIState: uiState));
  }

  Future<void> deleteTask(int id) async {
    if (state.deleteTaskUIState?.status == Status.LOADING) {
      return;
    }

    _setDeleteTaskUIState(UIState.loading());

    final Result<dynamic> result = await _repository.deleteTask(id);

    if (result is Success<dynamic>) {
      _setDeleteTaskUIState(UIState.success(result.value));
      // Refresh the task list after deletion
      unawaited(getTasks(refresh: true));
    } else if (result is Error<dynamic>) {
      _setDeleteTaskUIState(UIState.error(result.type));
    }
  }

  void resetDeleteTaskState() {
    _setDeleteTaskUIState(resetUIState<dynamic>(state.deleteTaskUIState));
  }
  // ---------------------------------------------------------------------------
  // Approval Pending Tasks
  // ---------------------------------------------------------------------------

  void _setApprovalPendingTasksUIState(UIState<ApprovalTaskResponse>? uiState) {
    final tasks = uiState?.data?.data?.data ?? <Task>[];
    final pagination = uiState?.data != null
        ? LeadPagination(
            currentPage: uiState!.data!.data?.currentPage,
            lastPage: uiState.data!.data?.lastPage,
            perPage: uiState.data!.data?.perPage,
            total: uiState.data!.data?.total,
            from: uiState.data!.data?.from,
            to: uiState.data!.data?.to,
            // assuming LeadPagination has these fields
          )
        : null;

    emit(
      state.copyWith(
        approvalPendingTasksUIState: uiState,
        approvalPendingTasksList: tasks,
        approvalPendingTasksPagination: pagination,
        isLoadingMoreApprovalTasks: false,
      ),
    );
  }

  /// Fetch approval pending tasks (page 1, with optional search).
  Future<void> getApprovalPendingTasks({
    bool refresh = false,
    String? search,
  }) async {
    if (state.approvalPendingTasksUIState?.status == Status.LOADING) return;

    final query = (search ?? state.approvalPendingTasksSearchQuery).trim();
    final searchChanged = query != state.approvalPendingTasksSearchQuery;

    // If not refreshing and not search changed and we already have data, skip.
    if (!refresh &&
        !searchChanged &&
        state.approvalPendingTasksList.isNotEmpty) {
      return;
    }

    // Set loading, clear list if search changed.
    emit(
      state.copyWith(
        approvalPendingTasksUIState: UIState.loading(),
        approvalPendingTasksSearchQuery: query,
        approvalPendingTasksList: searchChanged
            ? <Task>[]
            : state.approvalPendingTasksList,
      ),
    );

    final result = await _repository.getAllApprovalPendingTasks(
      page: 1,
      perPage: 10, // or use a constant
      search: query,
    );

    if (result is Success<ApprovalTaskResponse>) {
      _setApprovalPendingTasksUIState(UIState.success(result.value));
    } else if (result is Error<ApprovalTaskResponse>) {
      emit(
        state.copyWith(
          approvalPendingTasksUIState: UIState.error(result.type),
          isLoadingMoreApprovalTasks: false,
        ),
      );
    }
  }

  /// Loads the next page of approval pending tasks and appends to the list.
  Future<void> loadMoreApprovalTasks() async {
    final pagination = state.approvalPendingTasksPagination;
    if (state.isLoadingMoreApprovalTasks ||
        state.approvalPendingTasksUIState?.status == Status.LOADING ||
        pagination == null ||
        !pagination.hasNextPage) {
      return;
    }

    emit(state.copyWith(isLoadingMoreApprovalTasks: true));

    final result = await _repository.getAllApprovalPendingTasks(
      page: pagination.nextPage,
      perPage: 10,
      search: state.approvalPendingTasksSearchQuery,
    );

    if (result is Success<ApprovalTaskResponse>) {
      final newTasks = result.value.data?.data ?? <Task>[];
      final updatedList = [...state.approvalPendingTasksList, ...newTasks];
      emit(
        state.copyWith(
          approvalPendingTasksUIState: UIState.success(result.value),
          approvalPendingTasksList: updatedList,
          approvalPendingTasksPagination: result.value.data != null
              ? LeadPagination(
                  currentPage: result.value.data!.currentPage,
                  lastPage: result.value.data!.lastPage,
                  perPage: result.value.data!.perPage,
                  total: result.value.data!.total,
                  from: result.value.data!.from,
                  to: result.value.data!.to,
                )
              : null,
          isLoadingMoreApprovalTasks: false,
        ),
      );
    } else if (result is Error<ApprovalTaskResponse>) {
      emit(
        state.copyWith(
          approvalPendingTasksUIState: UIState.error(result.type),
          isLoadingMoreApprovalTasks: false,
        ),
      );
    }
  }

  /// Navigate to a specific page.
  Future<void> goToApprovalPendingTasksPage(int page) async {
    if (page < 1 ||
        page == state.approvalPendingTasksPagination?.currentPage ||
        state.isLoadingMoreApprovalTasks) {
      return;
    }

    emit(state.copyWith(isLoadingMoreApprovalTasks: true));

    final result = await _repository.getAllApprovalPendingTasks(
      page: page,
      perPage: 10,
      search: state.approvalPendingTasksSearchQuery,
    );

    if (result is Success<ApprovalTaskResponse>) {
      final tasks = result.value.data?.data ?? <Task>[];
      final pagination = result.value.data != null
          ? LeadPagination(
              currentPage: result.value.data!.currentPage,
              lastPage: result.value.data!.lastPage,
              perPage: result.value.data!.perPage,
              total: result.value.data!.total,
              from: result.value.data!.from,
              to: result.value.data!.to,
            )
          : null;

      emit(
        state.copyWith(
          approvalPendingTasksUIState: UIState.success(result.value),
          approvalPendingTasksList: tasks,
          approvalPendingTasksPagination: pagination,
          isLoadingMoreApprovalTasks: false,
        ),
      );
    } else if (result is Error<ApprovalTaskResponse>) {
      emit(
        state.copyWith(
          approvalPendingTasksUIState: UIState.error(result.type),
          isLoadingMoreApprovalTasks: false,
        ),
      );
    }
  }

  /// Refresh the current page.
  Future<void> refreshApprovalPendingTasks() async {
    await getApprovalPendingTasks(refresh: true);
  }

  void resetApprovalPendingTasksState() {
    emit(
      state.copyWith(
        approvalPendingTasksUIState: null,
        approvalPendingTasksList: const <Task>[],
        approvalPendingTasksPagination: null,
        approvalPendingTasksSearchQuery: '',
        isLoadingMoreApprovalTasks: false,
      ),
    );
  }
  // ---------------------------------------------------------------------------
  // Approve Task
  // ---------------------------------------------------------------------------

  void _setApproveTaskUIState(UIState<TaskCompleteResponse>? uiState) {
    emit(state.copyWith(approveTaskUIState: uiState));
  }

  /// Marks a task as approved.
  Future<void> approveTask(int id) async {
    if (state.approveTaskUIState?.status == Status.LOADING) return;

    _setApproveTaskUIState(UIState.loading());

    final result = await _repository.markTasksAsApproved(id);

    if (result is Success<TaskCompleteResponse>) {
      _setApproveTaskUIState(UIState.success(result.value));
      // Optionally refresh the task list or details after approval
      unawaited(getTasks(refresh: true));
      if (state.taskDetailsUIState?.data?.data?.id == id) {
        unawaited(getTaskDetails(id));
      }
    } else if (result is Error<TaskCompleteResponse>) {
      _setApproveTaskUIState(UIState.error(result.type));
    }
  }

  void resetApproveTaskState() {
    _setApproveTaskUIState(
      resetUIState<TaskCompleteResponse>(state.approveTaskUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Tasks By Staff ID
  // ---------------------------------------------------------------------------

  /// Fetch a specific page of tasks for a staff member.
  Future<void> fetchTasksByStaffIdPage({
    required int staffId,
    required int page,
    String? search,
    bool replace = true,
    String? status,
  }) async {
    if (state.tasksByStaffIdUIState?.status == Status.LOADING) return;

    final query = (search ?? state.tasksByStaffIdSearchQuery).trim();
    final searchChanged = query != state.tasksByStaffIdSearchQuery;
    final staffChanged = staffId != state.currentStaffIdForTasks;

    // Skip if same staff, same search, and we already have data.
    if (!replace &&
        !searchChanged &&
        !staffChanged &&
        state.tasksByStaffIdList.isNotEmpty &&
        page == (state.tasksByStaffIdPagination?.currentPage ?? 1)) {
      return;
    }

    emit(
      state.copyWith(
        tasksByStaffIdUIState: UIState.loading(),
        tasksByStaffIdSearchQuery: query,
        currentStaffIdForTasks: staffId,
        tasksByStaffIdList: (replace || staffChanged || searchChanged)
            ? []
            : state.tasksByStaffIdList,
        isLoadingMoreTasksByStaffId: false,
      ),
    );

    final result = await _repository.getTasksByStaffId(
      staffId: staffId,
      page: page,
      perPage: _pageSize,
      search: query,
      status: status,
    );

    if (result is Success<TaskListResponse>) {
      final newItems = result.value.data ?? [];
      final updatedList = (replace || staffChanged || searchChanged)
          ? newItems
          : [...state.tasksByStaffIdList, ...newItems];
      emit(
        state.copyWith(
          tasksByStaffIdUIState: UIState.success(result.value),
          tasksByStaffIdList: updatedList,
          tasksByStaffIdPagination: result.value.pagination,
          isLoadingMoreTasksByStaffId: false,
        ),
      );
    } else if (result is Error<TaskListResponse>) {
      emit(
        state.copyWith(
          tasksByStaffIdUIState: UIState.error(result.type),
          isLoadingMoreTasksByStaffId: false,
        ),
      );
    }
  }

  /// Fetch the first page of tasks assigned to a specific staff member.
  Future<void> getTasksByStaffId({
    required int staffId,
    bool refresh = false,
    String? search,
    String? status,
  }) async {
    // If same staff and search, and not refreshing, skip if data exists.
    if (!refresh &&
        state.currentStaffIdForTasks == staffId &&
        state.tasksByStaffIdSearchQuery == (search ?? '').trim() &&
        state.tasksByStaffIdList.isNotEmpty) {
      return;
    }
    await fetchTasksByStaffIdPage(
      staffId: staffId,
      page: 1,
      search: search,
      replace: true,
      status: status,
    );
  }

  /// Refresh the current page of tasks for a staff member.
  Future<void> refreshTasksByStaffId(int staffId) async {
    await getTasksByStaffId(staffId: staffId, refresh: true);
  }

  /// Navigate to a specific page (replaces the list).
  Future<void> goToTasksByStaffIdPage({
    required int staffId,
    required int page,
  }) async {
    if (page < 1 ||
        page == state.tasksByStaffIdPagination?.currentPage ||
        state.isLoadingMoreTasksByStaffId) {
      return;
    }
    await fetchTasksByStaffIdPage(
      staffId: staffId,
      page: page,
      search: state.tasksByStaffIdSearchQuery,
      replace: true,
    );
  }

  /// Load the next page (appends to the list).
  Future<void> loadMoreTasksByStaffId(int staffId, String? status) async {
    final pagination = state.tasksByStaffIdPagination;
    if (state.isLoadingMoreTasksByStaffId ||
        state.tasksByStaffIdUIState?.status == Status.LOADING ||
        pagination == null ||
        !pagination.hasNextPage) {
      return;
    }
    await fetchTasksByStaffIdPage(
      staffId: staffId,
      page: pagination.nextPage,
      search: state.tasksByStaffIdSearchQuery,
      status: status,
      replace: false,
    );
  }

  /// Clear the tasks‑by‑staff state.
  void resetTasksByStaffIdState() {
    emit(
      state.copyWith(
        tasksByStaffIdUIState: null,
        tasksByStaffIdList: const <Task>[],
        tasksByStaffIdPagination: null,
        tasksByStaffIdSearchQuery: '',
        currentStaffIdForTasks: null,
        isLoadingMoreTasksByStaffId: false,
      ),
    );
  }
  // ---------------------------------------------------------------------------
  // Reset Entire State
  // ---------------------------------------------------------------------------

  void resetTasksState() {
    emit(const TasksState());
  }
}
