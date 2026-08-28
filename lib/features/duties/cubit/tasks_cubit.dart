import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/enum/status.dart';
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

  // Future<void> deleteTask(int id) async {
  //   if (state.deleteTaskUIState?.status == Status.LOADING) {
  //     return;
  //   }

  //   _setDeleteTaskUIState(UIState.loading());

  //   final Result<dynamic> result = await _repository.deleteTask(id);

  //   if (result is Success<dynamic>) {
  //     _setDeleteTaskUIState(UIState.success(result.value));
  //     unawaited(getTasks(refresh: true));
  //   } else if (result is Error<dynamic>) {
  //     _setDeleteTaskUIState(UIState.error(result.type));
  //   }
  // }

  void resetDeleteTaskState() {
    _setDeleteTaskUIState(resetUIState<dynamic>(state.deleteTaskUIState));
  }

  // ---------------------------------------------------------------------------
  // Reset Entire State
  // ---------------------------------------------------------------------------

  void resetTasksState() {
    emit(const TasksState());
  }
}
