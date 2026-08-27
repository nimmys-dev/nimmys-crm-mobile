part of 'tasks_cubit.dart';

class TasksState extends Equatable {
  // ---------------------------------------------------------------------------
  // Tasks List
  // ---------------------------------------------------------------------------

  /// Status of the current tasks page request.
  final UIState<TaskListResponse>? tasksListUIState;

  /// Current page rows.
  final List<Task> tasksList;

  /// Pagination information.
  final LeadPagination? tasksPagination;

  /// Current search query.
  final String tasksSearchQuery;

  // ---------------------------------------------------------------------------
  // Task Details
  // ---------------------------------------------------------------------------

  /// GET /api/tasks/{id} state.
  final UIState<TaskDetailsResponse>? taskDetailsUIState;

  // ---------------------------------------------------------------------------
  // Create Task
  // ---------------------------------------------------------------------------

  /// POST /api/tasks state.
  final UIState<dynamic>? createTaskUIState;

  // ---------------------------------------------------------------------------
  // Update Task
  // ---------------------------------------------------------------------------

  /// PUT /api/tasks/{id} state.
  final UIState<TaskDetailsResponse>? updateTaskUIState;

  // ---------------------------------------------------------------------------
  // Delete Task
  // ---------------------------------------------------------------------------

  /// DELETE /api/tasks/{id} state.
  final UIState<dynamic>? deleteTaskUIState;

  const TasksState({
    this.tasksListUIState,
    this.tasksList = const <Task>[],
    this.tasksPagination,
    this.tasksSearchQuery = '',
    this.taskDetailsUIState,
    this.createTaskUIState,
    this.updateTaskUIState,
    this.deleteTaskUIState,
  });

  TasksState copyWith({
    UIState<TaskListResponse>? tasksListUIState,
    List<Task>? tasksList,
    LeadPagination? tasksPagination,
    String? tasksSearchQuery,
    UIState<TaskDetailsResponse>? taskDetailsUIState,
    UIState<dynamic>? createTaskUIState,
    UIState<TaskDetailsResponse>? updateTaskUIState,
    UIState<dynamic>? deleteTaskUIState,
  }) {
    return TasksState(
      tasksListUIState: tasksListUIState ?? this.tasksListUIState,
      tasksList: tasksList ?? this.tasksList,
      tasksPagination: tasksPagination ?? this.tasksPagination,
      tasksSearchQuery: tasksSearchQuery ?? this.tasksSearchQuery,
      taskDetailsUIState: taskDetailsUIState ?? this.taskDetailsUIState,
      createTaskUIState: createTaskUIState ?? this.createTaskUIState,
      updateTaskUIState: updateTaskUIState ?? this.updateTaskUIState,
      deleteTaskUIState: deleteTaskUIState ?? this.deleteTaskUIState,
    );
  }

  @override
  List<Object?> get props => [
    // Tasks list
    tasksListUIState,
    tasksListUIState?.status,
    tasksListUIState?.data,
    tasksListUIState?.errorType,
    tasksList,
    tasksPagination,
    tasksSearchQuery,

    // Task details
    taskDetailsUIState,
    taskDetailsUIState?.status,
    taskDetailsUIState?.data,
    taskDetailsUIState?.errorType,

    // Create task
    createTaskUIState,
    createTaskUIState?.status,
    createTaskUIState?.data,
    createTaskUIState?.errorType,

    // Update task
    updateTaskUIState,
    updateTaskUIState?.status,
    updateTaskUIState?.data,
    updateTaskUIState?.errorType,

    // Delete task
    deleteTaskUIState,
    deleteTaskUIState?.status,
    deleteTaskUIState?.data,
    deleteTaskUIState?.errorType,
  ];
}
