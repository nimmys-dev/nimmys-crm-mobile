import 'package:flutter/material.dart';
import 'package:nimmys_crm/features/duties/cubit/tasks_cubit.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../enum/status.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_form_field.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_segmented_tabs.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../shared/widgets/app_text_field.dart';
import 'domain/entities/task_schedule.dart';
import 'widgets/task_schedule_fields.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key, this.initialSchedule});

  final TaskSchedule? initialSchedule;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  // Dummy employee/approver data – replace with actual API data.
  // Format: name -> id
  static const Map<String, int> _employeeIds = <String, int>{
    'Abin Babu': 4,
    'Sejun Thomas': 6,
    'Sajeesh Kumar': 7,
    'Madhu Nair': 8,
    'Ajith Canon': 9,
  };

  static const Map<String, int> _approverIds = <String, int>{
    'Ajith Canon (Manager)': 2,
    'Nimmy Joseph (Owner)': 1,
    'Rahul Menon (Team Lead)': 3,
  };

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _assignee;
  String? _approver;

  late TaskSchedule _schedule = widget.initialSchedule ?? const TaskSchedule();
  String? _scheduleError;

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
      _assignee = null;
      _approver = null;
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

  /// Builds the API payload based on the current schedule and inputs.
  Map<String, dynamic> _buildPayload() {
    final bool repeats = _schedule.repeat;
    final TaskFrequency frequency = _schedule.frequency;

    final Map<String, dynamic> payload = <String, dynamic>{
      'title': _taskController.text.trim(),
      'description': _descriptionController.text.trim(),
      'assigned_to': _employeeIds[_assignee],
      'approved_by': _approverIds[_approver],
      'task_type': frequency.wireValue,
      'repeat_mode': repeats,
    };

    if (!repeats) {
      // One-time task: no schedule fields
      return payload;
    }

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
        payload['monthly_start_date'] = _formatDate(_schedule.monthlyRange.from!);
        payload['monthly_end_date'] = _formatDate(_schedule.monthlyRange.to!);
        break;
      case TaskFrequency.quarterly:
        payload['quarters'] = _schedule.selectedQuarters
            .map((TaskQuarter quarter) {
              final TaskDateRange range = _schedule.rangeFor(quarter);
              return <String, dynamic>{
                'quarter': quarter.wireValue,
                'start_date': _formatDate(range.from!),
                'end_date': _formatDate(range.to!),
              };
            })
            .toList();
        break;
      case TaskFrequency.yearly:
        payload['yearly_start_date'] = _formatDate(_schedule.yearlyRange.from!);
        payload['yearly_end_date'] = _formatDate(_schedule.yearlyRange.to!);
        break;
    }
    return payload;
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

  /// Validates form fields and schedule, then calls the cubit.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // Basic field validation
    if (_taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task name.')),
      );
      return;
    }
    if (_assignee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an assignee.')),
      );
      return;
    }
    if (_approver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an approver.')),
      );
      return;
    }

    // Schedule validation
    final String? scheduleError = _schedule.validationError;
    setState(() => _scheduleError = scheduleError);
    if (scheduleError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(scheduleError)));
      return;
    }

    final payload = _buildPayload();

    // Call cubit
    await context.read<TasksCubit>().createTask(payload);
  }

  @override
  Widget build(BuildContext context) {
    final bool repeats = _schedule.repeat;
    final bool isYearly =
        repeats && _schedule.frequency == TaskFrequency.yearly;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: BlocListener<TasksCubit, TasksState>(
          listener: (context, state) {
            final createState = state.createTaskUIState;
            if (createState?.status == Status.SUCCESS) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task created successfully.')),
              );
              // Optionally navigate back
              // context.pop();
            } else if (createState?.status == Status.ERROR) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to create task.')));
            }
          },
          child: Column(
            children: <Widget>[
              AppGradientHeader(
                title: 'Create Task',
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
                    AppSectionCard(
                      child: Column(
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
                          AppFormField(
                            label: 'Assign to',
                            isRequired: true,
                            child: AppSelectField(
                              hint: 'Select employee',
                              sheetTitle: 'Assign task to',
                              icon: Icons.person_outline_rounded,
                              options: _employeeIds.keys.toList(),
                              value: _assignee,
                              onChanged: (String value) =>
                                  setState(() => _assignee = value),
                            ),
                          ),
                          AppFormField(
                            label: 'Approve to',
                            bottomSpacing: 0,
                            child: AppSelectField(
                              hint: 'Select approver',
                              sheetTitle: 'Approval by',
                              icon: Icons.verified_user_outlined,
                              options: _approverIds.keys.toList(),
                              value: _approver,
                              onChanged: (String value) =>
                                  setState(() => _approver = value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSectionCard(
                      child: Column(
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
                          if (repeats) ...<Widget>[
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
                        ],
                      ),
                    ),
                    if (isYearly)
                      AppSectionCard(
                        child: Column(
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
                            if (_scheduleError != null) ...<Widget>[
                              const SizedBox(height: AppSpacing.xs),
                              TaskScheduleError(message: _scheduleError!),
                            ],
                          ],
                        ),
                      ),
                    AppSectionCard(
                      child: AppFormField(
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
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    BlocBuilder<TasksCubit, TasksState>(
                      builder: (context, state) {
                        final isLoading =
                            state.createTaskUIState?.status == Status.LOADING;
                        return AppPrimaryButton(
                          label: isLoading ? 'Creating...' : 'Create Task',
                          icon: isLoading ? null : Icons.add_task_rounded,
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
