import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_form_field.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_segmented_tabs.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../shared/widgets/app_text_field.dart';
import 'widgets/staff_widgets.dart';

/// Staff Creation — personal profile plus employment and increment settings.
class StaffCreationScreen extends StatefulWidget {
  const StaffCreationScreen({super.key});

  @override
  State<StaffCreationScreen> createState() => _StaffCreationScreenState();
}

class _StaffCreationScreenState extends State<StaffCreationScreen> {
  static const List<AppUnderlineTabItem> _tabs = <AppUnderlineTabItem>[
    AppUnderlineTabItem(
      label: 'Personal Details',
      icon: Icons.person_outline_rounded,
    ),
    AppUnderlineTabItem(label: 'Employment', icon: Icons.work_outline_rounded),
  ];

  static const List<String> _branches = <String>[
    'Ernakulam',
    'Kottayam',
    'Ettamanur',
  ];

  static const List<IncrementRecord> _history = <IncrementRecord>[
    IncrementRecord(
      effectiveDate: '15 May 2025',
      salary: '₹27,500',
      incrementSalary: '₹2,500',
      remarks: 'Annual increment',
    ),
    IncrementRecord(
      effectiveDate: '15 May 2024',
      salary: '₹25,000',
      incrementSalary: '₹2,000',
      remarks: 'Annual increment',
    ),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _altMobileController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _incrementController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  int _tabIndex = 0;
  String? _branch;
  DateTime? _joiningDate;
  DateTime? _nextIncrementDate;
  bool _incrementReminder = true;
  bool _leadManagement = true;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _altMobileController.dispose();
    _salaryController.dispose();
    _incrementController.dispose();
    _remarksController.dispose();
    super.dispose();
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
            const AppGradientHeader(
              title: 'Staff Creation',
              eyebrow: 'TEAM',
              leading: AppBackButton(),
              actions: <Widget>[
                AppHeaderIconButton(icon: Icons.local_fire_department_rounded),
                SizedBox(width: AppSpacing.xs),
                AppAvatar(initials: 'AB'),
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppUnderlineTabs(
                          tabs: _tabs,
                          selectedIndex: _tabIndex,
                          onChanged: (int index) =>
                              setState(() => _tabIndex = index),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_tabIndex == 0)
                          StaffPersonalDetailsForm(
                            nameController: _nameController,
                            mobileController: _mobileController,
                            altMobileController: _altMobileController,
                          )
                        else
                          StaffEmploymentDetailsForm(
                            salaryController: _salaryController,
                            incrementController: _incrementController,
                            remarksController: _remarksController,
                            branches: _branches,
                            branch: _branch,
                            onBranchChanged: (String value) =>
                                setState(() => _branch = value),
                            joiningDate: _joiningDate,
                            nextIncrementDate: _nextIncrementDate,
                            reminderEnabled: _incrementReminder,
                            onJoiningDateChanged: (DateTime value) =>
                                setState(() => _joiningDate = value),
                            onIncrementDateChanged: (DateTime value) =>
                                setState(() => _nextIncrementDate = value),
                            onReminderChanged: (bool value) =>
                                setState(() => _incrementReminder = value),
                          ),
                      ],
                    ),
                  ),
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const StaffSubsectionTitle(title: 'Optional'),
                        AppToggleRow(
                          title: 'Lead Management',
                          subtitle: 'Allow this staff member to own leads',
                          icon: Icons.groups_outlined,
                          value: _leadManagement,
                          onChanged: (bool value) =>
                              setState(() => _leadManagement = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppPrimaryButton(
                    label: 'Save Staff',
                    icon: Icons.save_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const AppSectionHeader(title: 'Increment History'),
                        const SizedBox(height: AppSpacing.sm),
                        IncrementHistoryTable(records: _history),
                      ],
                    ),
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

/// Name, contact numbers and photo.
class StaffPersonalDetailsForm extends StatelessWidget {
  const StaffPersonalDetailsForm({
    super.key,
    required this.nameController,
    required this.mobileController,
    required this.altMobileController,
  });

  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController altMobileController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppFormField(
          label: 'Name',
          isRequired: true,
          child: AppTextField(
            hint: 'Enter full name',
            controller: nameController,
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        AppFormField(
          label: 'Mobile No.',
          isRequired: true,
          child: AppTextField(
            hint: '98765 43210',
            controller: mobileController,
            icon: Icons.call_outlined,
            keyboardType: TextInputType.phone,
            maxLength: 10,
          ),
        ),
        AppFormField(
          label: 'Alternate Mobile No.',
          child: AppTextField(
            hint: '91234 56789',
            controller: altMobileController,
            icon: Icons.add_ic_call_outlined,
            keyboardType: TextInputType.phone,
            maxLength: 10,
          ),
        ),
        const AppFieldLabelRow(label: 'Photo'),
        const StaffPhotoPicker(),
      ],
    );
  }
}

/// Thin wrapper so the photo label matches every other field caption.
class AppFieldLabelRow extends StatelessWidget {
  const AppFieldLabelRow({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(label, style: context.type.label),
    );
  }
}

/// Joining date, salary and the increment schedule.
class StaffEmploymentDetailsForm extends StatelessWidget {
  const StaffEmploymentDetailsForm({
    super.key,
    required this.salaryController,
    required this.incrementController,
    required this.remarksController,
    required this.branches,
    required this.branch,
    required this.joiningDate,
    required this.nextIncrementDate,
    required this.reminderEnabled,
    this.onBranchChanged,
    this.onJoiningDateChanged,
    this.onIncrementDateChanged,
    this.onReminderChanged,
  });

  final TextEditingController salaryController;
  final TextEditingController incrementController;
  final TextEditingController remarksController;
  final List<String> branches;
  final String? branch;
  final ValueChanged<String>? onBranchChanged;
  final DateTime? joiningDate;
  final DateTime? nextIncrementDate;
  final bool reminderEnabled;
  final ValueChanged<DateTime>? onJoiningDateChanged;
  final ValueChanged<DateTime>? onIncrementDateChanged;
  final ValueChanged<bool>? onReminderChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppFormField(
          label: 'Branch',
          isRequired: true,
          child: AppSelectField(
            hint: 'Select branch',
            sheetTitle: 'Assign to branch',
            icon: Icons.storefront_outlined,
            options: branches,
            value: branch,
            onChanged: onBranchChanged,
          ),
        ),
        AppFormField(
          label: 'Joining Date',
          isRequired: true,
          child: AppDateField(
            hint: 'Select joining date',
            value: joiningDate,
            onChanged: onJoiningDateChanged,
          ),
        ),
        AppFormField(
          label: 'Salary',
          isRequired: true,
          child: AppTextField(
            hint: '25,000',
            controller: salaryController,
            icon: Icons.currency_rupee_rounded,
            keyboardType: TextInputType.number,
          ),
        ),
        const StaffSubsectionTitle(title: 'Increment Details', showInfo: true),
        AppFormField(
          label: 'Next Increment Date',
          child: AppDateField(
            hint: 'Select next increment date',
            value: nextIncrementDate,
            onChanged: onIncrementDateChanged,
          ),
        ),
        AppToggleRow(
          title: 'Increment Reminder',
          subtitle: 'Notify me when the increment date arrives',
          icon: Icons.notifications_active_outlined,
          value: reminderEnabled,
          onChanged: onReminderChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        AppFormField(
          label: 'Increment Salary',
          child: AppTextField(
            hint: '2,500',
            controller: incrementController,
            icon: Icons.trending_up_rounded,
            keyboardType: TextInputType.number,
          ),
        ),
        AppFormField(
          label: 'Description',
          bottomSpacing: AppSpacing.md,
          child: AppTextField(
            hint: 'Annual increment based on performance and company policy.',
            controller: remarksController,
            icon: Icons.notes_rounded,
            maxLines: 3,
            maxLength: 250,
            showCounter: true,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        AppOutlineButton(
          label: 'View Increment History',
          icon: Icons.history_rounded,
          onPressed: () {},
        ),
      ],
    );
  }
}
