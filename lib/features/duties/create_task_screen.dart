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

/// Create Task form — task name, owner, approver, cadence, dates and notes.
class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

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
  static const List<String> _taskTypes = <String>[
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _assignee;
  String? _approver;
  int _taskTypeIndex = 0;
  DateTime? _startDate;
  DateTime? _dueDate;

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
      _taskTypeIndex = 0;
      _startDate = null;
      _dueDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    child: AppFormField(
                      label: 'Task Type',
                      isRequired: true,
                      bottomSpacing: 0,
                      child: AppSegmentedTabs(
                        options: _taskTypes,
                        selectedIndex: _taskTypeIndex,
                        onChanged: (int index) =>
                            setState(() => _taskTypeIndex = index),
                      ),
                    ),
                  ),
                  AppSectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: AppFormField(
                            label: 'Start Date',
                            isRequired: true,
                            bottomSpacing: 0,
                            child: AppDateField(
                              hint: 'Select start date',
                              value: _startDate,
                              onChanged: (DateTime value) =>
                                  setState(() => _startDate = value),
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
                              value: _dueDate,
                              onChanged: (DateTime value) =>
                                  setState(() => _dueDate = value),
                            ),
                          ),
                        ),
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
                    onPressed: () {},
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
