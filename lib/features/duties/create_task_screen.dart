import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_form_field.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_segmented_tabs.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../shared/widgets/app_text_field.dart';
import 'domain/entities/task_schedule.dart';
import 'widgets/task_schedule_fields.dart';

/// Create Task form — task name, owner, approver, cadence, dates and notes.
class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key, this.initialSchedule});

  /// The recurrence of the task being edited. Null when creating, which
  /// starts the form on an empty daily schedule.
  final TaskSchedule? initialSchedule;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  static const List<String> _employees = <String>[
    'Abin Babu',
    'Sejun Thomas',
    'Sajeesh Kumar',
    'Madhu Nair',
    'Ajith Canon',
  ];
  static const List<String> _approvers = <String>[
    'Ajith Canon (Manager)',
    'Nimmy Joseph (Owner)',
    'Rahul Menon (Team Lead)',
  ];
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _assignee;
  String? _approver;

  /// Every frequency's selections in one object, so switching task type keeps
  /// what was already picked and an edit restores in a single assignment.
  late TaskSchedule _schedule = widget.initialSchedule ?? const TaskSchedule();

  /// Set when a save is attempted with the schedule incomplete, cleared as
  /// soon as the user changes anything.
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

  /// Keeps the frequency but drops the stale error, so the message goes away
  /// the moment the user starts filling the new frequency in.
  void _updateSchedule(TaskSchedule schedule) {
    setState(() {
      _schedule = schedule;
      _scheduleError = null;
    });
  }

  /// Moves the yearly window's start. A start after the current due date
  /// would leave the window reversed, so the due date drops rather than going
  /// stale behind it.
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

  /// Blocks the save while the chosen frequency is missing its selection.
  void _submit() {
    FocusScope.of(context).unfocus();
    final String? error = _schedule.validationError;
    setState(() => _scheduleError = error);
    if (error == null) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final bool repeats = _schedule.repeat;
    final bool isYearly = repeats && _schedule.frequency == TaskFrequency.yearly;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: Column(
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
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
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
                            options: _employees,
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
                            options: _approvers,
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
                          onChanged: (bool value) =>
                              _updateSchedule(_schedule.copyWith(repeat: value)),
                        ),
                        // Off means a one-off task, so the schedule inputs go
                        // away entirely rather than sitting there unused.
                        if (repeats) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          AppFormField(
                            label: 'Task Type',
                            isRequired: true,
                            // Yearly renders nothing below, so the tabs are the
                            // last thing in the card and take no bottom gap.
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
                          // Only the selected frequency's inputs render here —
                          // a daily task asks for a time range, a weekly one
                          // for dates and days.
                          TaskScheduleFields(
                            schedule: _schedule,
                            onChanged: _updateSchedule,
                            // A yearly error belongs under the date fields it
                            // is about, which live in the card below.
                            errorText: isYearly ? null : _scheduleError,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Daily, weekly, monthly and quarterly tasks describe a
                  // repeating time or day and have no use for a date window.
                  // Yearly is the only frequency that asks for one, and it is
                  // the whole of its schedule.
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
                                    // Cannot open before the start date, so a
                                    // reversed window is not reachable.
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
                  AppPrimaryButton(
                    label: 'Create Task',
                    icon: Icons.add_task_rounded,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AppHintBanner(
                    icon: Icons.tips_and_updates_outlined,
                    title: 'Assign with clarity',
                    message:
                        'Tasks with an approver are routed for sign-off once '
                        'the assignee marks them complete.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
