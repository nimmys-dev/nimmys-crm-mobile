import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/model/call_log_model.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/shared/widgets/app_form_field.dart';
import 'package:nimmys_crm/shared/widgets/app_select_field.dart';
import 'package:nimmys_crm/shared/widgets/app_text_field.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';
import 'lead_detail_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';

// ---------- Tele Call Details Section ----------
class TeleCallDetailsSection extends StatelessWidget {
  const TeleCallDetailsSection({
    super.key,
    required this.teleCallDetails,
    required this.onAddTeleCallDetail,
    required this.leadId,
  });

  final List<Map<String, dynamic>> teleCallDetails;
  final void Function(Map<String, dynamic> detail) onAddTeleCallDetail;
  final int leadId;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LeadSectionTitle(
            title: 'Tele Call Details',
            icon: Icons.phone_in_talk_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),

          AppOutlineButton(
            label: 'Add Call Detail',
            icon: Icons.add_ic_call_outlined,
            onPressed: () => _showAddTeleCallSheet(context),
          ),

          const SizedBox(height: AppSpacing.md),

          if (teleCallDetails.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No tele call details recorded yet.',
                style: context.type.bodyMuted,
                textAlign: TextAlign.center,
              ),
            )
          else
            ...teleCallDetails.map(
              (detail) => TeleCallDetailCard(detail: detail),
            ),
        ],
      ),
    );
  }

  void _showAddTeleCallSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) {
        return AddTeleCallDetailSheet(
          leadId: leadId,
          onSave: onAddTeleCallDetail,
        );
      },
    );
  }
}

// ---------- Single Tele Call Detail Card ----------
class TeleCallDetailCard extends StatelessWidget {
  const TeleCallDetailCard({super.key, required this.detail});

  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final calledBy = detail['called_by']?.toString() ?? '—';
    final date = detail['called_date']?.toString() ?? '';
    final time = detail['called_time']?.toString() ?? '';
    final status =
        detail['call_status_label']?.toString() ??
        detail['call_status']?.toString() ??
        '—';
    final interest = detail['interest'] == true ? 'Yes' : 'No';
    final itemSold = detail['is_item_sold'] == true ? 'Yes' : 'No';
    final nextFollowUp = detail['next_followup_date']?.toString() ?? '—';
    final remarks = detail['remarks']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: palette.slate),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  calledBy,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.phone_in_talk, size: 16, color: AppColors.red),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: status.toLowerCase() == 'answered'
                      ? Colors.green
                      : AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildInfoChip(Icons.calendar_today, date, context),
              _buildInfoChip(Icons.access_time, time, context),
              _buildInfoChip(Icons.percent, 'Interest: $interest', context),
              _buildInfoChip(Icons.sell_outlined, 'Sold: $itemSold', context),
            ],
          ),
          if (nextFollowUp != '—') ...[
            const SizedBox(height: 6),
            _buildInfoChip(
              Icons.event_available,
              'Next follow-up: $nextFollowUp',
              context,
            ),
          ],
          if (remarks.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(remarks, style: const TextStyle(fontSize: 13, height: 1.3)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.palette.slate),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ---------- Add Tele Call Detail Bottom Sheet ----------
class AddTeleCallDetailSheet extends StatefulWidget {
  const AddTeleCallDetailSheet({
    super.key,
    required this.leadId,
    required this.onSave,
  });

  final int leadId;
  final void Function(Map<String, dynamic> detail) onSave;

  @override
  State<AddTeleCallDetailSheet> createState() => _AddTeleCallDetailSheetState();
}

class _AddTeleCallDetailSheetState extends State<AddTeleCallDetailSheet> {
  final _calledByController = TextEditingController();
  final _calledDateController = TextEditingController();
  final _calledTimeController = TextEditingController();
  final _durationController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _nextFollowUpDateController = TextEditingController();
  final _remarksController = TextEditingController();
  final _invoiceFileController = TextEditingController();

  String? _selectedCallStatus;
  bool _interest = false;
  bool _isItemSold = false;

  @override
  void dispose() {
    _calledByController.dispose();
    _calledDateController.dispose();
    _calledTimeController.dispose();
    _durationController.dispose();
    _invoiceNumberController.dispose();
    _nextFollowUpDateController.dispose();
    _remarksController.dispose();
    _invoiceFileController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Date
  // ---------------------------------------------------------------------------

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      // API expects yyyy-MM-dd
      controller.text =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
  }

  // ---------------------------------------------------------------------------
  // Time
  // ---------------------------------------------------------------------------

  Future<void> _pickTime(TextEditingController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      // API expects HH:mm
      controller.text =
          '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    }
  }

  // ---------------------------------------------------------------------------
  // Close
  // ---------------------------------------------------------------------------

  void _closeSheet() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  void _save() {
    if (_calledByController.text.trim().isEmpty) {
      ToastMessages.error(message: 'Called By is required');
      return;
    }

    if (_calledDateController.text.trim().isEmpty) {
      ToastMessages.error(message: 'Called Date is required');
      return;
    }

    if (_calledTimeController.text.trim().isEmpty) {
      ToastMessages.error(message: 'Called Time is required');
      return;
    }

    if (_selectedCallStatus == null || _selectedCallStatus!.isEmpty) {
      ToastMessages.error(message: 'Call Status is required');
      return;
    }

    final String callStatus = _selectedCallStatus!.toLowerCase();

    final Map<String, dynamic> detail = <String, dynamic>{
      'called_by': _calledByController.text.trim(),
      'called_date': _calledDateController.text.trim(),
      'called_time': _calledTimeController.text.trim(),
      'duration': _durationController.text.trim(),
      'call_status': callStatus,
      'call_status_label': _selectedCallStatus,
      'interest': _interest,
      'is_item_sold': _isItemSold,
      'invoice_number': _invoiceNumberController.text.trim(),
      'next_followup_date': _nextFollowUpDateController.text.trim(),
      'remarks': _remarksController.text.trim(),
      'invoice_file': _invoiceFileController.text.trim(),
    };

    // Send data to parent/Cubit; the sheet will be closed after API success.
    widget.onSave(detail);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<LeadsCubit, LeadsState>(
      listenWhen: (previous, current) =>
          previous.addCallLogUIState?.status !=
          current.addCallLogUIState?.status,
      listener: (context, state) {
        final UIState<TeleCallDetailResponseModel>? uiState =
            state.addCallLogUIState;

        if (uiState?.status == Status.SUCCESS) {
          FocusScope.of(context).unfocus();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          return;
        }

        if (uiState?.status == Status.ERROR) {
          final errorType = uiState?.errorType;
          ToastMessages.error(
            message:
                errorType?.toString() ??
                'Failed to add call detail. Please try again.',
          );
        }
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: FractionallySizedBox(
          heightFactor: 0.90,
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: palette.line)),
            ),
            child: Column(
              children: [
                // --------------------------------------------------
                // HEADER
                // --------------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Add Tele Call Detail',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: palette.ink,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: _closeSheet,
                            icon: Icon(Icons.close, color: palette.ink),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --------------------------------------------------
                // FORM
                // --------------------------------------------------
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      0,
                      AppSpacing.gutter,
                      AppSpacing.gutter,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Called By
                        AppFormField(
                          label: 'Called By',
                          child: AppTextField(
                            hint: 'Name of caller',
                            controller: _calledByController,
                            icon: Icons.person_outline,
                          ),
                        ),

                        // Date + Time
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppFormField(
                                label: 'Date',
                                child: AppTextField(
                                  hint: 'Select date',
                                  controller: _calledDateController,
                                  icon: Icons.calendar_today,
                                  readOnly: true,
                                  onTap: () => _pickDate(_calledDateController),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: AppFormField(
                                label: 'Time',
                                child: AppTextField(
                                  hint: 'Select time',
                                  controller: _calledTimeController,
                                  icon: Icons.access_time,
                                  readOnly: true,
                                  onTap: () => _pickTime(_calledTimeController),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Duration
                        AppFormField(
                          label: 'Duration (optional)',
                          child: AppTextField(
                            hint: 'e.g., 5 mins',
                            controller: _durationController,
                            icon: Icons.timer_outlined,
                          ),
                        ),

                        // Call Status
                        AppFormField(
                          label: 'Call Status',
                          child: AppSelectField(
                            hint: 'Select status',
                            sheetTitle: 'Call status',
                            icon: Icons.phone_in_talk,
                            options: const ['Answered', 'Not Answered', 'Busy'],
                            value: _selectedCallStatus,
                            onChanged: (value) {
                              setState(() {
                                _selectedCallStatus = value;
                              });
                            },
                          ),
                        ),

                        // Interest
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Interest'),
                          value: _interest,
                          onChanged: (value) {
                            setState(() {
                              _interest = value;
                            });
                          },
                          activeColor: AppColors.red,
                        ),

                        // Item Sold
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Item Sold'),
                          value: _isItemSold,
                          onChanged: (value) {
                            setState(() {
                              _isItemSold = value;
                            });
                          },
                          activeColor: AppColors.red,
                        ),

                        // Invoice Number
                        AppFormField(
                          label: 'Invoice Number (optional)',
                          child: AppTextField(
                            hint: 'Invoice #',
                            controller: _invoiceNumberController,
                            icon: Icons.receipt_long,
                          ),
                        ),

                        // Next Follow-up
                        AppFormField(
                          label: 'Next Follow-up Date',
                          child: AppTextField(
                            hint: 'Select date',
                            controller: _nextFollowUpDateController,
                            icon: Icons.event_available,
                            readOnly: true,
                            onTap: () => _pickDate(_nextFollowUpDateController),
                          ),
                        ),

                        // Remarks
                        AppFormField(
                          label: 'Remarks',
                          child: AppTextField(
                            hint: 'Notes / remarks',
                            controller: _remarksController,
                            icon: Icons.notes,
                            maxLines: 3,
                          ),
                        ),

                        // Invoice File
                        AppFormField(
                          label: 'Invoice File (optional)',
                          child: AppTextField(
                            hint: 'File path / URL',
                            controller: _invoiceFileController,
                            icon: Icons.attach_file,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Save Button
                        _buildSaveButton(),

                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save Button
  // ---------------------------------------------------------------------------

  Widget _buildSaveButton() {
    return BlocBuilder<LeadsCubit, LeadsState>(
      buildWhen: (previous, current) =>
          previous.addCallLogUIState?.status !=
          current.addCallLogUIState?.status,
      builder: (context, state) {
        final bool isLoading =
            state.addCallLogUIState?.status == Status.LOADING;

        return AbsorbPointer(
          absorbing: isLoading,
          child: Opacity(
            opacity: isLoading ? 0.6 : 1,
            child: AppPrimaryButton(
              label: isLoading ? 'Saving...' : 'Save Call Detail',
              onPressed: _save,
            ),
          ),
        );
      },
    );
  }
}
