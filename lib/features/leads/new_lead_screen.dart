import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_form_field.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../shared/widgets/app_text_field.dart';

/// New Lead capture — mobile, name, requirement and owner.
class NewLeadScreen extends StatefulWidget {
  const NewLeadScreen({super.key});

  @override
  State<NewLeadScreen> createState() => _NewLeadScreenState();
}

class _NewLeadScreenState extends State<NewLeadScreen> {
  static const List<String> _assignees = <String>[
    'Abin Babu',
    'Sejun Thomas',
    'Sajeesh Kumar',
    'Ajith Canon',
  ];

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _requirementController = TextEditingController();

  String? _assignee;
  DateTime? _nextFollowUp;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    _requirementController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
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
              title: 'New Lead',
              eyebrow: 'CAPTURE ENQUIRY',
              leading: AppBackButton(),
              actions: <Widget>[
                AppHeaderIconButton(icon: Icons.upload_file_rounded),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppFormField(
                          label: 'Customer Mobile',
                          isRequired: true,
                          child: AppTextField(
                            hint: 'Enter mobile number',
                            controller: _mobileController,
                            icon: Icons.call_outlined,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            suffix: const NewLeadLookupButton(),
                          ),
                        ),
                        AppFormField(
                          label: 'Customer Name',
                          isRequired: true,
                          bottomSpacing: 0,
                          child: AppTextField(
                            hint: 'Enter customer name',
                            controller: _nameController,
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSectionCard(
                    child: AppFormField(
                      label: 'Lead Details / Requirements',
                      bottomSpacing: 0,
                      child: AppTextField(
                        hint: 'Which products is the customer asking for?',
                        controller: _requirementController,
                        icon: Icons.inventory_2_outlined,
                        maxLines: 4,
                        maxLength: 500,
                        showCounter: true,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppFormField(
                          label: 'Assigned To',
                          isRequired: true,
                          child: AppSelectField(
                            hint: 'Select assignee',
                            sheetTitle: 'Assign lead to',
                            icon: Icons.badge_outlined,
                            options: _assignees,
                            value: _assignee,
                            onChanged: (String value) =>
                                setState(() => _assignee = value),
                          ),
                        ),
                        AppFormField(
                          label: 'Next Follow Up',
                          bottomSpacing: 0,
                          child: AppDateField(
                            hint: 'Select follow up date',
                            value: _nextFollowUp,
                            onChanged: (DateTime value) =>
                                setState(() => _nextFollowUp = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppPrimaryButton(
                    label: 'CREATE LEAD',
                    icon: Icons.person_add_alt_1_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AppHintBanner(
                    icon: Icons.bolt_rounded,
                    title: 'Capture it while it is warm',
                    message:
                        'Leads logged within the first hour convert far more '
                        'often. Add the requirement in the customer\'s words.',
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

/// Inline action that looks up an existing customer by mobile number.
class NewLeadLookupButton extends StatelessWidget {
  const NewLeadLookupButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.redWash,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Check', style: context.type.link.copyWith(fontSize: 11.5)),
              const Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: AppColors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
