import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_form_field.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_segmented_tabs.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../shared/widgets/app_text_field.dart';

/// Add New Duty — recurring responsibility with frequency and repeat window.
class AddDutyScreen extends StatefulWidget {
  const AddDutyScreen({super.key});

  @override
  State<AddDutyScreen> createState() => _AddDutyScreenState();
}

class _AddDutyScreenState extends State<AddDutyScreen> {
  static const List<String> _staff = <String>[
    'Abin Babu',
    'Sejun Thomas',
    'Sajeesh Kumar',
    'Madhu Nair',
  ];
  static const List<String> _approvers = <String>[
    'Ajith Canon (Manager)',
    'Nimmy Joseph (Owner)',
  ];
  static const List<String> _frequencies = <String>[
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];
  static const List<String> _monthDays = <String>[
    '1st Every Month',
    '5th Every Month',
    '10th Every Month',
    '15th Every Month',
    '20th Every Month',
    '25th Every Month',
    'Last Day of Month',
  ];

  final TextEditingController _dutyNameController = TextEditingController();

  String? _assignee;
  String? _approver;
  int _frequencyIndex = 1;
  bool _repeatAutomatically = true;
  String? _openingDate;
  String? _closingDate;
  int _navIndex = 1;

  @override
  void dispose() {
    _dutyNameController.dispose();
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
            AppGradientHeader(
              title: 'Add New Duty',
              eyebrow: 'RECURRING WORK',
              leading: const AppBackButton(),
              actions: const <Widget>[
                AppHeaderIconButton(icon: Icons.playlist_add_check_rounded),
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
                          label: 'Duty Name',
                          isRequired: true,
                          child: AppTextField(
                            hint: 'Enter duty name',
                            controller: _dutyNameController,
                            icon: Icons.description_outlined,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        AppFormField(
                          label: 'Assign to',
                          isRequired: true,
                          child: AppSelectField(
                            hint: 'Select staff member',
                            sheetTitle: 'Assign duty to',
                            icon: Icons.person_outline_rounded,
                            options: _staff,
                            value: _assignee,
                            onChanged: (String value) =>
                                setState(() => _assignee = value),
                          ),
                        ),
                        AppFormField(
                          label: 'Approved By',
                          isRequired: true,
                          bottomSpacing: 0,
                          child: AppSelectField(
                            hint: 'Select approver',
                            sheetTitle: 'Approved by',
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
                        AppFormField(
                          label: 'Frequency',
                          child: AppSegmentedTabs(
                            options: _frequencies,
                            selectedIndex: _frequencyIndex,
                            onChanged: (int index) =>
                                setState(() => _frequencyIndex = index),
                          ),
                        ),
                        AppToggleRow(
                          title: 'Repeat Automatically',
                          subtitle:
                              'Recreate this duty on the selected frequency',
                          icon: Icons.autorenew_rounded,
                          value: _repeatAutomatically,
                          onChanged: (bool value) =>
                              setState(() => _repeatAutomatically = value),
                        ),
                      ],
                    ),
                  ),
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppFormField(
                          label: 'Opening Date',
                          isRequired: true,
                          child: AppSelectField(
                            hint: 'Select opening date',
                            sheetTitle: 'Opening date',
                            icon: Icons.event_available_outlined,
                            options: _monthDays,
                            value: _openingDate,
                            onChanged: (String value) =>
                                setState(() => _openingDate = value),
                          ),
                        ),
                        AppFormField(
                          label: 'Closing Date',
                          isRequired: true,
                          bottomSpacing: 0,
                          child: AppSelectField(
                            hint: 'Select closing date',
                            sheetTitle: 'Closing date',
                            icon: Icons.event_busy_outlined,
                            options: _monthDays,
                            value: _closingDate,
                            onChanged: (String value) =>
                                setState(() => _closingDate = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppPrimaryButton(
                    label: 'Save Duty',
                    icon: Icons.save_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AppHintBanner(
                    icon: Icons.event_repeat_rounded,
                    title: 'Plan. Assign. Repeat.',
                    message:
                        'Create recurring duties once and stay organised '
                        'effortlessly — every cycle is generated for you.',
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          items: const <AppNavItem>[
            AppNavItem(
              label: 'Home',
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
            ),
            AppNavItem(
              label: 'Duties',
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment_rounded,
            ),
            AppNavItem(label: 'Reports', icon: Icons.bar_chart_rounded),
            AppNavItem(label: 'More', icon: Icons.more_horiz_rounded),
          ],
          currentIndex: _navIndex,
          onTap: (int index) => setState(() => _navIndex = index),
          centerAction: const AppNavItem(label: 'New', icon: Icons.add_rounded),
        ),
      ),
    );
  }
}
