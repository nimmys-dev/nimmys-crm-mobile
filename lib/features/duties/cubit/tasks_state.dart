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

  // ---------------------------------------------------------------------------
  // Complete Task
  // ---------------------------------------------------------------------------

  /// POST /api/approval-task/{id} state.
  final UIState<TaskCompleteResponse>? completeTaskUIState;

  // ---------------------------------------------------------------------------
  // Approval Pending Tasks
  // ---------------------------------------------------------------------------

  /// GET /api/approval-pending-tasks state.
  final UIState<ApprovalTaskResponse>? approvalPendingTasksUIState;

  /// List of approval pending tasks (type: ApprovalTaskItem).
  final List<Task> approvalPendingTasksList;

  /// Pagination information for approval tasks.
  final LeadPagination? approvalPendingTasksPagination;

  /// Current search query for approval tasks.
  final String approvalPendingTasksSearchQuery;

  /// True while fetching a follow-on page.
  final bool isLoadingMoreApprovalTasks;

  // ---------------------------------------------------------------------------
  // Approve Task
  // ---------------------------------------------------------------------------

  /// POST /api/approve-task/{id} state.
  final UIState<TaskCompleteResponse>? approveTaskUIState;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  const TasksState({
    this.tasksListUIState,
    this.tasksList = const <Task>[],
    this.tasksPagination,
    this.tasksSearchQuery = '',
    this.taskDetailsUIState,
    this.createTaskUIState,
    this.updateTaskUIState,
    this.deleteTaskUIState,
    this.completeTaskUIState,
    this.approvalPendingTasksUIState,
    this.approvalPendingTasksList = const <Task>[],
    this.approvalPendingTasksPagination,
    this.approvalPendingTasksSearchQuery = '',
    this.isLoadingMoreApprovalTasks = false,
    this.approveTaskUIState,
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  TasksState copyWith({
    UIState<TaskListResponse>? tasksListUIState,
    List<Task>? tasksList,
    LeadPagination? tasksPagination,
    String? tasksSearchQuery,
    UIState<TaskDetailsResponse>? taskDetailsUIState,
    UIState<dynamic>? createTaskUIState,
    UIState<TaskDetailsResponse>? updateTaskUIState,
    UIState<dynamic>? deleteTaskUIState,
    UIState<TaskCompleteResponse>? completeTaskUIState,
    UIState<ApprovalTaskResponse>? approvalPendingTasksUIState,
    List<Task>? approvalPendingTasksList,
    LeadPagination? approvalPendingTasksPagination,
    String? approvalPendingTasksSearchQuery,
    bool? isLoadingMoreApprovalTasks,
    UIState<TaskCompleteResponse>? approveTaskUIState,
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
      completeTaskUIState: completeTaskUIState ?? this.completeTaskUIState,
      approvalPendingTasksUIState:
          approvalPendingTasksUIState ?? this.approvalPendingTasksUIState,
      approvalPendingTasksList:
          approvalPendingTasksList ?? this.approvalPendingTasksList,
      approvalPendingTasksPagination:
          approvalPendingTasksPagination ?? this.approvalPendingTasksPagination,
      approvalPendingTasksSearchQuery:
          approvalPendingTasksSearchQuery ?? this.approvalPendingTasksSearchQuery,
      isLoadingMoreApprovalTasks:
          isLoadingMoreApprovalTasks ?? this.isLoadingMoreApprovalTasks,
      approveTaskUIState: approveTaskUIState ?? this.approveTaskUIState,
    );
  }

  // ---------------------------------------------------------------------------
  // Equatable props
  // ---------------------------------------------------------------------------

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

    // Complete task
    completeTaskUIState,
    completeTaskUIState?.status,
    completeTaskUIState?.data,
    completeTaskUIState?.errorType,

    // Approval tasks
    approvalPendingTasksUIState,
    approvalPendingTasksUIState?.status,
    approvalPendingTasksUIState?.data,
    approvalPendingTasksUIState?.errorType,
    approvalPendingTasksList,
    approvalPendingTasksPagination,
    approvalPendingTasksSearchQuery,
    isLoadingMoreApprovalTasks,

    // Approve task
    approveTaskUIState,
    approveTaskUIState?.status,
    approveTaskUIState?.data,
    approveTaskUIState?.errorType,
  ];
}