import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

/// Opens the staff picker and reassigns [leadId] to the selected staff member.
void showLeadReassignBottomSheet(BuildContext context, {required int leadId}) {
  final LeadsCubit cubit = context.read<LeadsCubit>();
  cubit
    ..resetReassignLeadState()
    ..getLeadAssignees();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _LeadReassignSheet(leadId: leadId),
    ),
  );
}

class _LeadReassignSheet extends StatefulWidget {
  const _LeadReassignSheet({required this.leadId});

  final int leadId;

  @override
  State<_LeadReassignSheet> createState() => _LeadReassignSheetState();
}

class _LeadReassignSheetState extends State<_LeadReassignSheet> {
  int? _selectedStaffId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LeadsCubit, LeadsState>(
      listenWhen: (previous, current) =>
          previous.reassignLeadUIState?.status !=
          current.reassignLeadUIState?.status,
      listener: (context, state) {
        final status = state.reassignLeadUIState?.status;
        if (status == Status.SUCCESS) {
          ToastMessages.success(
            message:
                state.reassignLeadUIState?.data?.message ??
                'Lead reassigned successfully.',
          );
          context.read<LeadsCubit>().resetReassignLeadState();
          Navigator.of(context).pop();
        } else if (status == Status.ERROR) {
          ToastMessages.error(
            message:
                state.reassignLeadUIState?.errorType?.getText(context) ??
                'Failed to reassign lead.',
          );
          context.read<LeadsCubit>().resetReassignLeadState();
        }
      },
      builder: (context, state) {
        final List<LeadAssigneeData> assignees =
            state.leadAssigneesUIState?.data?.validAssignees ??
            const <LeadAssigneeData>[];
        final bool loadingStaff =
            state.leadAssigneesUIState?.status == Status.LOADING;
        final bool submitting =
            state.reassignLeadUIState?.status == Status.LOADING;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.gutter,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.palette.faint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Reassign lead', style: context.type.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    'Choose the staff member responsible for this lead.',
                    style: context.type.bodyMuted,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (loadingStaff)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (assignees.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'No staff members are available for assignment.',
                        style: context.type.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: assignees.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: context.palette.line),
                        itemBuilder: (context, index) {
                          final assignee = assignees[index];
                          final id = assignee.id!;
                          return RadioListTile<int>(
                            value: id,
                            groupValue: _selectedStaffId,
                            activeColor: AppColors.red,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              assignee.name!,
                              style: context.type.body,
                            ),
                            onChanged: submitting
                                ? null
                                : (value) =>
                                      setState(() => _selectedStaffId = value),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  AppPrimaryButton(
                    label: 'Reassign Lead',
                    icon: Icons.person_add_alt_1_rounded,
                    isLoading: submitting,
                    onPressed: _selectedStaffId == null || submitting
                        ? null
                        : () => context.read<LeadsCubit>().reassignLead(
                            leadId: widget.leadId,
                            assignedTo: _selectedStaffId!,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
