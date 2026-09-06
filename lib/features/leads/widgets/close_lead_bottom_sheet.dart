import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/model/lead_details_model.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/shared/widgets/app_form_field.dart';
import 'package:nimmys_crm/shared/widgets/app_text_field.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

import '../../../enum/status.dart';

class CloseLeadBottomSheet extends StatefulWidget {
  const CloseLeadBottomSheet({super.key, required this.lead});

  final LeadDetailsData lead;

  @override
  State<CloseLeadBottomSheet> createState() => CloseLeadBottomSheetState();
}

class CloseLeadBottomSheetState extends State<CloseLeadBottomSheet> {
  String? _selectedStatus; // 'won' or 'lost'
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: palette.line)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.faint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Title
              Text(
                'Close Lead',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Mark this lead as Won or Lost',
                style: context.type.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Status selection
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatusOption('Won', 'won', palette)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatusOption('Lost', 'lost', palette)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Reason (required when Lost)
              AppFormField(
                label: 'Reason',
                isRequired: _selectedStatus == 'lost',
                child: AppTextField(
                  hint: _selectedStatus == 'lost'
                      ? 'Why did you lose this lead?'
                      : 'Optional reason (won)',
                  controller: _reasonController,
                  icon: Icons.comment_outlined,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: AppOutlineButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Close Lead',
                      onPressed: _submit,
                      isLoading:
                          context
                              .watch<LeadsCubit>()
                              .state
                              .closeLeadUIState
                              ?.status ==
                          Status.LOADING,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(String label, String value, AppPalette palette) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? palette.redWash : palette.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.red : palette.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value == 'won' ? Icons.emoji_events_rounded : Icons.close_rounded,
              color: isSelected ? AppColors.red : palette.slate,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isSelected ? AppColors.red : palette.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_selectedStatus == null) {
      ToastMessages.error(message: 'Please select a status (Won or Lost).');
      return;
    }
    if (_selectedStatus == 'lost' && _reasonController.text.trim().isEmpty) {
      ToastMessages.error(
        message: 'Please provide a reason for losing the lead.',
      );
      return;
    }

    final cubit = context.read<LeadsCubit>();
    cubit.closeLead(
      leadId: widget.lead.id!,
      status: _selectedStatus!,
      lostReason: _reasonController.text.trim().isNotEmpty
          ? _reasonController.text.trim()
          : null,
    );

    // Close the bottom sheet (the cubit listener will show toast and reload)
    Navigator.pop(context);
  }
}
