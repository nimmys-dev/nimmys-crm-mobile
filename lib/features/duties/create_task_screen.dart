import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:nimmys_crm/features/duties/cubit/tasks_cubit.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/shared/widgets/app_form_field.dart';
import 'package:nimmys_crm/shared/widgets/app_gradient_header.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';
import 'package:nimmys_crm/shared/widgets/app_segmented_tabs.dart';
import 'package:nimmys_crm/shared/widgets/app_select_field.dart';
import 'package:nimmys_crm/shared/widgets/app_text_field.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';
import 'domain/entities/task_schedule.dart';
import 'model/task_details_model.dart';
import 'widgets/task_schedule_fields.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key, this.initialSchedule, this.taskToEdit});

  final TaskSchedule? initialSchedule;
  final TaskDetail? taskToEdit;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Dynamic assignee/approver using LeadsCubit
  LeadAssigneeData? _selectedAssignee;
  LeadAssigneeData? _selectedApprover;

  late TaskSchedule _schedule = widget.initialSchedule ?? const TaskSchedule();
  String? _scheduleError;

  bool get _isEditing => widget.taskToEdit?.id != null;

  @override
  void initState() {
    super.initState();
    context.read<TasksCubit>().resetUpdateTaskState();
    // Fetch assignees from LeadsCubit (force refresh)
    context.read<LeadsCubit>().getLeadAssignees(force: true);

    final TaskDetail? task = widget.taskToEdit;
    if (task == null) return;

    _taskController.text = task.title ?? '';
    _descriptionController.text = task.description ?? '';
    _schedule = _scheduleFromTask(task);
    // Pre‑selection will happen in the builder after the list loads
  }

  @override
  void dispose() {
    _taskController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _taskController.clear();
      _descriptionController.clear();
      _selectedAssignee = null;
      _selectedApprover = null;
      _schedule = const TaskSchedule();
      _scheduleError = null;
    });
  }

  void _updateSchedule(TaskSchedule schedule) {
    setState(() {
      _schedule = schedule;
      _scheduleError = null;
    });
  }

  void _setStartDate(DateTime value) {
    final TaskDateRange range = _schedule.yearlyRange;
    _updateSchedule(
      _schedule.copyWith(
        yearlyRange: range.to != null && range.to!.isBefore(value)
            ? TaskDateRange(from: value)
            : range.copyWith(from: value),
      ),
    );
  }

  /// Builds the API payload with dynamic assignee/approver IDs
  Map<String, dynamic> _buildPayload() {
    final bool repeats = _schedule.repeat;
    final TaskFrequency frequency = _schedule.frequency;

    final Map<String, dynamic> payload = <String, dynamic>{
      'title': _taskController.text.trim(),
      'description': _descriptionController.text.trim(),
      'assigned_to': _selectedAssignee?.id,
      'approved_by': _selectedApprover?.id,
      'task_type': frequency.wireValue,
      'repeat_mode': repeats,
    };

    switch (frequency) {
      case TaskFrequency.daily:
        payload['start_time'] = _formatTime(_schedule.startTimeMinutes!);
        payload['end_time'] = _formatTime(_schedule.endTimeMinutes!);
        break;
      case TaskFrequency.weekly:
        payload['week_start_day'] = weekdayWireValue(_schedule.weekStartDay!);
        payload['week_end_day'] = weekdayWireValue(_schedule.weekEndDay!);
        break;
      case TaskFrequency.monthly:
        final List<int> selectedDays = _schedule.monthDays.toList()..sort();
        payload['monthly_start_date'] = _formatDate(
          _dateInCurrentMonth(selectedDays.first),
        );
        payload['monthly_end_date'] = _formatDate(
          _dateInCurrentMonth(selectedDays.last),
        );
        break;
      case TaskFrequency.quarterly:
        payload['quarters'] = _schedule.selectedQuarters.map((quarter) {
          final TaskDateRange range = _schedule.rangeFor(quarter);
          return <String, dynamic>{
            'quarter': quarter.wireValue,
            'start_date': _formatDate(range.from!),
            'end_date': _formatDate(range.to!),
          };
        }).toList();
        break;
      case TaskFrequency.yearly:
        payload['yearly_start_date'] = _formatDate(_schedule.yearlyRange.from!);
        payload['yearly_end_date'] = _formatDate(_schedule.yearlyRange.to!);
        break;
    }
    return payload;
  }

  // ---------- Helper methods (unchanged) ----------
  TaskSchedule _scheduleFromTask(TaskDetail task) {
    final Map<TaskQuarter, TaskDateRange> quarters =
        <TaskQuarter, TaskDateRange>{
          for (final Quarter item in task.quarters ?? <Quarter>[])
            if (TaskQuarter.fromWire(item.quarter)
                case final TaskQuarter quarter)
              quarter: TaskDateRange(
                from: _parseApiDate(item.startDate),
                to: _parseApiDate(item.endDate),
              ),
        };
    return TaskSchedule(
      repeat: task.repeatMode ?? false,
      frequency: TaskFrequency.fromWire(task.taskType),
      startTimeMinutes: _parseApiTime(task.startTime),
      endTimeMinutes: _parseApiTime(task.endTime),
      weekStartDay: _weekdayFromWire(task.weekStartDay),
      weekEndDay: _weekdayFromWire(task.weekEndDay),
      monthlyRange: TaskDateRange(
        from: _parseApiDate(task.monthlyStartDate),
        to: _parseApiDate(task.monthlyEndDate),
      ),
      monthDays: _monthDaysForRange(
        _parseApiDate(task.monthlyStartDate),
        _parseApiDate(task.monthlyEndDate),
      ),
      quarterRanges: quarters,
      yearlyRange: TaskDateRange(
        from: _parseApiDate(task.yearlyStartDate),
        to: _parseApiDate(task.yearlyEndDate),
      ),
    );
  }

  DateTime? _parseApiDate(String? value) {
    if (value == null) return null;
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final DateTime local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  Set<int> _monthDaysForRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return <int>{};
    final int first = start.day.clamp(1, kMaxMonthDay);
    final int last = end.day.clamp(1, kMaxMonthDay);
    return <int>{for (int day = first; day <= last; day++) day};
  }

  int? _parseApiTime(String? value) {
    if (value == null) return null;
    final List<String> parts = value.split(':');
    if (parts.length < 2) return null;
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  int? _weekdayFromWire(String? value) {
    for (final int weekday in kWeekdayOrder) {
      if (weekdayWireValue(weekday) == value?.toLowerCase()) return weekday;
    }
    return null;
  }

  String _formatTime(int minutes) {
    final int hour = minutes ~/ 60;
    final int minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DateTime _dateInCurrentMonth(int day) {
    final DateTime now = DateTime.now();
    final int lastDay = DateTime(now.year, now.month + 1, 0).day;
    return DateTime(now.year, now.month, day.clamp(1, lastDay));
  }

  // ---------- Form submission ----------
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_taskController.text.trim().isEmpty) {
      ToastMessages.error(message: 'Please enter a task name.');
      return;
    }
    if (_selectedAssignee == null) {
      ToastMessages.error(message: 'Please select an assignee.');
      return;
    }
    if (_selectedApprover == null) {
      ToastMessages.error(message: 'Please select an approver.');
      return;
    }

    final String? scheduleError = _schedule.validationError;
    setState(() => _scheduleError = scheduleError);
    if (scheduleError != null) {
      ToastMessages.error(message: scheduleError);
      return;
    }

    final payload = _buildPayload();
    if (_isEditing) {
      await context.read<TasksCubit>().updateTask(
        widget.taskToEdit!.id!,
        payload,
      );
    } else {
      await context.read<TasksCubit>().createTask(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool repeats = _schedule.repeat;
    final bool isYearly = _schedule.frequency == TaskFrequency.yearly;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: MultiBlocListener(
          listeners: [
            // TasksCubit listener for create/update
            BlocListener<TasksCubit, TasksState>(
              listener: (context, state) {
                final createState = state.createTaskUIState;
                final updateState = state.updateTaskUIState;
                if (!_isEditing && createState?.status == Status.SUCCESS) {
                  context.read<TasksCubit>().resetCreateTaskState();
                  context.read<DashboardCubit>().getDashboardCount();
                  context.go(AppRouteName.duties);
                } else if (_isEditing &&
                    updateState?.status == Status.SUCCESS) {
                  context.read<TasksCubit>().resetUpdateTaskState();
                  context.read<DashboardCubit>().getDashboardCount();
                  context.go(AppRouteName.duties);
                } else {
                  final requestStatus = _isEditing
                      ? updateState?.status
                      : createState?.status;
                  if (requestStatus == Status.ERROR) {
                    ToastMessages.error(
                      message: _isEditing
                          ? 'Failed to update task.'
                          : 'Failed to create task.',
                    );
                  }
                }
              },
            ),
            // LeadsCubit listener for assignees errors
            BlocListener<LeadsCubit, LeadsState>(
              listenWhen: (prev, curr) =>
                  prev.leadAssigneesUIState?.status !=
                  curr.leadAssigneesUIState?.status,
              listener: (context, state) {
                if (state.leadAssigneesUIState?.status == Status.ERROR) {
                  ToastMessages.error(
                    message:
                        state.leadAssigneesUIState?.errorType?.getText(
                          context,
                        ) ??
                        'Failed to load assignees.',
                  );
                }
              },
            ),
          ],
          child: Column(
            children: <Widget>[
              AppGradientHeader(
                title: _isEditing ? 'Edit Task' : 'Create Task',
                eyebrow: 'DUTY MANAGEMENT',
                leading: const AppBackButton(),
                actions: <Widget>[
                  TextButton(
                    onPressed: _clearForm,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                    child: Text(
                      'Clear',
                      style: context.type.link.copyWith(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    left: AppSpacing.gutter,
                    right: AppSpacing.gutter,
                    top: AppSpacing.md,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom +
                        AppSpacing.xl,
                  ),
                  children: <Widget>[
                    // ------------------------------------------------------------
                    // TASK + ASSIGNEE + APPROVER SECTION
                    // ------------------------------------------------------------
                    AppSectionCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // <-- FIX OVERFLOW
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppFormField(
                            label: 'Task',
                            isRequired: true,
                            child: AppTextField(
                              hint: 'Enter task name',
                              controller: _taskController,
                              icon: Icons.assignment_outlined,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                          // ---- Assignee Dropdown ----
                          AppFormField(
                            label: 'Assign to',
                            isRequired: true,
                            child: BlocBuilder<LeadsCubit, LeadsState>(
                              builder: (context, leadsState) {
                                final assignees =
                                    leadsState
                                        .leadAssigneesUIState
                                        ?.data
                                        ?.validAssignees ??
                                    [];
                                final isLoading =
                                    leadsState.leadAssigneesUIState?.status ==
                                        Status.LOADING ||
                                    leadsState.leadAssigneesUIState?.status ==
                                        null ||
                                    leadsState.leadAssigneesUIState?.status ==
                                        Status.INITIAL;

                                // Pre‑select when editing
                                if (_isEditing &&
                                    assignees.isNotEmpty &&
                                    _selectedAssignee == null) {
                                  final task = widget.taskToEdit;
                                  if (task != null && task.assignedTo != null) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          final matched = assignees.firstWhere(
                                            (a) => a.id == task.assignedTo,
                                            orElse: () => assignees.first,
                                          );
                                          if (mounted) {
                                            setState(() {
                                              _selectedAssignee = matched;
                                            });
                                          }
                                        });
                                  }
                                }

                                final assigneeNames = assignees
                                    .map((a) => a.name ?? '')
                                    .toList();

                                return AppSelectField(
                                  hint: isLoading
                                      ? 'Loading assignees…'
                                      : 'Select employee',
                                  sheetTitle: 'Assign task to',
                                  icon: Icons.person_outline_rounded,
                                  options: assigneeNames,
                                  value: _selectedAssignee?.name,
                                  onChanged: (value) {
                                    final matched = assignees.firstWhere(
                                      (a) => a.name == value,
                                      orElse: () => assignees.first,
                                    );
                                    setState(() => _selectedAssignee = matched);
                                  },
                                );
                              },
                            ),
                          ),
                          // ---- Approver Dropdown ----
                          AppFormField(
                            label: 'Approve to',
                            bottomSpacing: 0,
                            child: BlocBuilder<LeadsCubit, LeadsState>(
                              builder: (context, leadsState) {
                                final assignees =
                                    leadsState
                                        .leadAssigneesUIState
                                        ?.data
                                        ?.validAssignees ??
                                    [];
                                final isLoading =
                                    leadsState.leadAssigneesUIState?.status ==
                                        Status.LOADING ||
                                    leadsState.leadAssigneesUIState?.status ==
                                        null ||
                                    leadsState.leadAssigneesUIState?.status ==
                                        Status.INITIAL;

                                // Pre‑select approver when editing
                                if (_isEditing &&
                                    assignees.isNotEmpty &&
                                    _selectedApprover == null) {
                                  final task = widget.taskToEdit;
                                  if (task != null &&
                                      task.approvedBy?.id != null) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          final matched = assignees.firstWhere(
                                            (a) => a.id == task.approvedBy?.id,
                                            orElse: () => assignees.first,
                                          );
                                          if (mounted) {
                                            setState(() {
                                              _selectedApprover = matched;
                                            });
                                          }
                                        });
                                  }
                                }

                                final approverNames = assignees
                                    .map((a) => a.name ?? '')
                                    .toList();

                                return AppSelectField(
                                  hint: isLoading
                                      ? 'Loading approvers…'
                                      : 'Select approver',
                                  sheetTitle: 'Approval by',
                                  icon: Icons.verified_user_outlined,
                                  options: approverNames,
                                  value: _selectedApprover?.name,
                                  onChanged: (value) {
                                    final matched = assignees.firstWhere(
                                      (a) => a.name == value,
                                      orElse: () => assignees.first,
                                    );
                                    setState(() {
                                      _selectedApprover = matched;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ------------------------------------------------------------
                    // REPEAT / SCHEDULE SECTION
                    // ------------------------------------------------------------
                    AppSectionCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // <-- FIX OVERFLOW
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppToggleRow(
                            title: 'Repeat Mode',
                            subtitle: repeats
                                ? 'This task repeats on the schedule below'
                                : 'This task runs once — no recurring schedule',
                            icon: Icons.autorenew_rounded,
                            value: repeats,
                            onChanged: (bool value) => _updateSchedule(
                              _schedule.copyWith(repeat: value),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppFormField(
                            label: 'Task Type',
                            isRequired: true,
                            bottomSpacing: isYearly ? 0 : AppSpacing.md,
                            child: AppSegmentedTabs(
                              options: TaskFrequency.labels,
                              selectedIndex: TaskFrequency.values.indexOf(
                                _schedule.frequency,
                              ),
                              onChanged: (int index) => _updateSchedule(
                                _schedule.copyWith(
                                  frequency: TaskFrequency.values[index],
                                ),
                              ),
                            ),
                          ),
                          TaskScheduleFields(
                            schedule: _schedule,
                            onChanged: _updateSchedule,
                            errorText: isYearly ? null : _scheduleError,
                          ),
                        ],
                      ),
                    ),

                    // ------------------------------------------------------------
                    // YEARLY EXTRA FIELDS (shown only when yearly and repeating)
                    // ------------------------------------------------------------
                    if (isYearly)
                      AppSectionCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // <-- FIX OVERFLOW
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: AppFormField(
                                    label: 'Start Date',
                                    isRequired: true,
                                    bottomSpacing: 0,
                                    child: AppDateField(
                                      hint: 'Select start date',
                                      value: _schedule.yearlyRange.from,
                                      onChanged: _setStartDate,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: AppFormField(
                                    label: 'Due Date',
                                    isRequired: true,
                                    bottomSpacing: 0,
                                    child: AppDateField(
                                      hint: 'Select due date',
                                      value: _schedule.yearlyRange.to,
                                      firstDate: _schedule.yearlyRange.from,
                                      onChanged: (DateTime value) =>
                                          _updateSchedule(
                                            _schedule.copyWith(
                                              yearlyRange: _schedule.yearlyRange
                                                  .copyWith(to: value),
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_scheduleError != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              TaskScheduleError(message: _scheduleError!),
                            ],
                          ],
                        ),
                      ),

                    // ------------------------------------------------------------
                    // DESCRIPTION SECTION
                    // ------------------------------------------------------------
                    AppSectionCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // <-- FIX OVERFLOW
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppFormField(
                            label: 'Description',
                            bottomSpacing: 0,
                            child: AppTextField(
                              hint: 'Enter task description',
                              controller: _descriptionController,
                              icon: Icons.notes_rounded,
                              maxLines: 4,
                              maxLength: 300,
                              showCounter: true,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // ------------------------------------------------------------
                    // SUBMIT BUTTON
                    // ------------------------------------------------------------
                    BlocBuilder<TasksCubit, TasksState>(
                      builder: (context, state) {
                        final bool isLoading = _isEditing
                            ? state.updateTaskUIState?.status == Status.LOADING
                            : state.createTaskUIState?.status == Status.LOADING;
                        return AppPrimaryButton(
                          label: isLoading
                              ? (_isEditing ? 'Updating...' : 'Creating...')
                              : (_isEditing ? 'Update Task' : 'Create Task'),
                          icon: isLoading
                              ? null
                              : (_isEditing
                                    ? Icons.save_outlined
                                    : Icons.add_task_rounded),
                          onPressed: isLoading ? null : _submit,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppHintBanner(
                      icon: Icons.tips_and_updates_outlined,
                      title: 'Assign with clarity',
                      message:
                          'Tasks with an approver are routed for sign-off once '
                          'the assignee marks them complete.',
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
