import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/shared/widgets/app_form_field.dart';
import 'package:nimmys_crm/shared/widgets/app_select_field.dart';
import 'package:nimmys_crm/shared/widgets/app_text_field.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';
import 'lead_detail_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ---------- Tele Call Details Section ----------
class TeleCallDetailsSection extends StatefulWidget {
  const TeleCallDetailsSection({
    super.key,
    required this.teleCallDetails,
    required this.onAddTeleCallDetail,
    required this.leadId,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.totalCount,
  });

  final List<Map<String, dynamic>> teleCallDetails;
  final Future<bool> Function(Map<String, dynamic> detail) onAddTeleCallDetail;
  final int leadId;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final int? totalCount;

  @override
  State<TeleCallDetailsSection> createState() => _TeleCallDetailsSectionState();
}

class _TeleCallDetailsSectionState extends State<TeleCallDetailsSection> {
  static const int _rowsPerPage = 10;
  int _currentPage = 0;
  int _previousItemCount = 0;
  bool _waitingForNextPage = false;

  @override
  void initState() {
    super.initState();
    _previousItemCount = widget.teleCallDetails.length;
  }

  @override
  void didUpdateWidget(covariant TeleCallDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final int itemCount = widget.teleCallDetails.length;
    if (itemCount > _previousItemCount && _waitingForNextPage) {
      _currentPage++;
      _waitingForNextPage = false;
    }
    _previousItemCount = itemCount;

    final int lastPage = _pageCount(itemCount) - 1;
    if (_currentPage > lastPage) {
      _currentPage = lastPage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> details = widget.teleCallDetails;
    final int pageCount = _pageCount(details.length);
    final int firstRow = _currentPage * _rowsPerPage;
    final int lastRow = (firstRow + _rowsPerPage).clamp(0, details.length);
    final List<Map<String, dynamic>> pageItems = details.sublist(
      firstRow,
      lastRow,
    );

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

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Total calls: ${widget.totalCount ?? details.length}',
              style: context.type.bodyMuted,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          if (details.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No tele call details recorded yet.',
                style: context.type.bodyMuted,
                textAlign: TextAlign.center,
              ),
            )
          else
            ...pageItems.map((detail) => TeleCallDetailCard(detail: detail)),

          if (details.isNotEmpty && (pageCount > 1 || widget.hasMore)) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildPaginationControls(context, pageCount),
          ],
          if (widget.isLoadingMore) ...[
            const SizedBox(height: AppSpacing.xs),
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _pageCount(int itemCount) {
    if (itemCount == 0) return 1;
    return (itemCount + _rowsPerPage - 1) ~/ _rowsPerPage;
  }

  Widget _buildPaginationControls(BuildContext context, int pageCount) {
    final bool canGoPrevious = _currentPage > 0;

    // Use API total count when available so pagination shows:
    // 1 of 3, 2 of 3, 3 of 3
    final int totalItems = widget.totalCount ?? widget.teleCallDetails.length;

    final int totalPages = totalItems == 0
        ? 1
        : (totalItems + _rowsPerPage - 1) ~/ _rowsPerPage;

    final bool canGoNext = _currentPage < totalPages - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Previous page',
          onPressed: canGoPrevious && !widget.isLoadingMore
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),

        Text(
          'Page ${_currentPage + 1} of $totalPages',
          style: context.type.bodyMuted,
        ),

        IconButton(
          tooltip: 'Next page',
          onPressed: canGoNext && !widget.isLoadingMore ? _goToNextPage : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  void _goToNextPage() {
    if (_currentPage < _pageCount(widget.teleCallDetails.length) - 1) {
      setState(() => _currentPage++);
      return;
    }
    _waitingForNextPage = true;
    widget.onLoadMore?.call();
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
          leadId: widget.leadId,
          onSave: widget.onAddTeleCallDetail,
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

    final String date = detail['called_date']?.toString() ?? '';

    final String time = detail['called_time']?.toString() ?? '';

    final String status =
        detail['call_status_label']?.toString() ??
        detail['call_status']?.toString() ??
        '—';

    final String interest = detail['interest'] == true ? 'Yes' : 'No';

    final String itemSold = detail['is_item_sold'] == true ? 'Yes' : 'No';

    final String? nextFollowUpRaw = detail['next_followup_date']?.toString();

    final String nextFollowUp = _formatNextFollowUpDate(nextFollowUpRaw);

    final String remarks = detail['remarks']?.toString() ?? '';

    final String reason = detail['reason']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // CALL STATUS
          // --------------------------------------------------
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: palette.slate),
              const SizedBox(width: 6),

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

          const SizedBox(height: 8),

          // --------------------------------------------------
          // CALL INFORMATION
          // --------------------------------------------------
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildInfoChip(Icons.calendar_today, date, context),

              _buildInfoChip(Icons.access_time, time, context),

              _buildInfoChip(Icons.percent, 'Interest: $interest', context),

              _buildInfoChip(Icons.sell_outlined, 'Sold: $itemSold', context),
            ],
          ),

          // --------------------------------------------------
          // NEXT FOLLOW-UP
          // --------------------------------------------------
          if (nextFollowUp != '—') ...[
            const SizedBox(height: 10),

            _buildNextFollowUpCard(context, nextFollowUp),
          ],

          // --------------------------------------------------
          // REMARKS
          // --------------------------------------------------
          if (remarks.isNotEmpty) ...[
            const SizedBox(height: 10),

            Text(
              'Remarks : $remarks',
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 10),

            Text(
              'Reason : $reason',
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------
  // FORMAT NEXT FOLLOW-UP DATE
  // --------------------------------------------------

  String _formatNextFollowUpDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '—';
    }

    try {
      final DateTime date = DateTime.parse(value).toLocal();

      final DateTime now = DateTime.now();

      final DateTime today = DateTime(now.year, now.month, now.day);

      final DateTime targetDate = DateTime(date.year, date.month, date.day);

      final int difference = targetDate.difference(today).inDays;

      String relativeText = '';

      if (difference == 0) {
        relativeText = 'Today';
      } else if (difference == 1) {
        relativeText = 'Tomorrow';
      } else if (difference == -1) {
        relativeText = 'Yesterday';
      } else if (difference > 1 && difference < 7) {
        relativeText = 'In $difference days';
      } else if (difference < -1 && difference > -7) {
        relativeText = '${difference.abs()} days ago';
      }

      final String formattedDate =
          '${date.day.toString().padLeft(2, '0')} '
          '${_monthName(date.month)} '
          '${date.year}';

      if (relativeText.isEmpty) {
        return formattedDate;
      }

      return '$formattedDate · $relativeText';
    } catch (_) {
      return value;
    }
  }

  // --------------------------------------------------
  // MONTH NAME
  // --------------------------------------------------

  String _monthName(int month) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  // --------------------------------------------------
  // NEXT FOLLOW-UP CARD
  // --------------------------------------------------

  Widget _buildNextFollowUpCard(BuildContext context, String date) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 18,
              color: AppColors.red,
            ),
          ),

          const SizedBox(width: 10),

          // Date information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next follow-up',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: palette.slate,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ],
            ),
          ),

          Icon(Icons.chevron_right_rounded, size: 20, color: palette.slate),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // INFORMATION CHIP
  // --------------------------------------------------

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

// ======================================================
// ADD TELE CALL DETAIL BOTTOM SHEET
// ======================================================

class AddTeleCallDetailSheet extends StatefulWidget {
  const AddTeleCallDetailSheet({
    super.key,
    required this.leadId,
    required this.onSave,
  });

  final int leadId;

  final Future<bool> Function(Map<String, dynamic> detail) onSave;

  @override
  State<AddTeleCallDetailSheet> createState() => _AddTeleCallDetailSheetState();
}

class _AddTeleCallDetailSheetState extends State<AddTeleCallDetailSheet> {
  final _calledByController = TextEditingController();

  final _calledDateController = TextEditingController();

  final _calledTimeController = TextEditingController();

  final _invoiceNumberController = TextEditingController();

  final _nextFollowUpDateController = TextEditingController();

  final _remarksController = TextEditingController();

  final _invoiceFileController = TextEditingController();

  final _reasonController = TextEditingController();

  String? _selectedCallStatus = 'Answered';

  bool _interest = true;

  bool _isItemSold = false;

  File? _invoiceFile;

  Map<String, String>? _reasonMap;
  String? _selectedReasonName;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calledDateController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _calledTimeController.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final cubit = context.read<LeadsCubit>();
    if (cubit.state.notInterestedReasonsUIState?.data == null) {
      cubit.getNotInterestedReasons(force: false);
    }
  }

  @override
  void dispose() {
    _calledByController.dispose();
    _calledDateController.dispose();
    _calledTimeController.dispose();
    _invoiceNumberController.dispose();
    _nextFollowUpDateController.dispose();
    _remarksController.dispose();
    _invoiceFileController.dispose();
    _reasonController.dispose();

    super.dispose();
  }

  // ======================================================
  // FILE PICKER
  // ======================================================

  // ======================================================
  // DATE PICKER
  // ======================================================

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      controller.text =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
  }

  // ======================================================
  // TIME PICKER
  // ======================================================

  // ======================================================
  // CLOSE
  // ======================================================

  void _closeSheet() {
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop();
  }

  // ======================================================
  // SAVE
  // ======================================================

  Future<void> _save() async {
    // --- Validation (unchanged) ---
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
    if (_remarksController.text.trim().isEmpty) {
      ToastMessages.error(message: 'Remarks is required');
      return;
    }
    if (!_interest) {
      if (_selectedReasonName == null || _selectedReasonName!.isEmpty) {
        ToastMessages.error(message: 'Not Interested Reason is required');
        return;
      }
    }
    if (!_isItemSold &&
        _interest &&
        _nextFollowUpDateController.text.trim().isEmpty) {
      ToastMessages.error(message: 'Next Follow-up Date is required');
      return;
    }
    if (_isItemSold && _invoiceNumberController.text.trim().isEmpty) {
      ToastMessages.error(
        message: 'Invoice Number is required when Item is sold.',
      );
      return;
    }

    // --- Compute reason value ---
    String? reasonValue;
    if (!_interest) {
      reasonValue = _reasonMap?[_selectedReasonName!];
    }

    final String callStatus = _selectedCallStatus == 'Answered'
        ? 'answered'
        : 'not_answered';

    final Map<String, dynamic> detail = <String, dynamic>{
      'called_date': _calledDateController.text.trim(),
      'called_time': _calledTimeController.text.trim(),
      'call_status': callStatus,
      'call_status_label': _selectedCallStatus,
      'interest': _interest,
      'is_item_sold': _isItemSold,
      'invoice_number': _invoiceNumberController.text.trim(),
      'next_followup_date': _nextFollowUpDateController.text.trim(),
      'remarks': _remarksController.text.trim(),
      'invoice_file': _invoiceFile,
      'reason': reasonValue ?? '', // now defined
    };

    final bool success = await widget.onSave(detail);
    if (!mounted) return;
    if (success) {
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop();
    }
  }
  // ======================================================
  // BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<LeadsCubit, LeadsState>(
      listenWhen: (previous, current) =>
          previous.addCallLogUIState?.status !=
          current.addCallLogUIState?.status,

      listener: (context, state) {
        final uiState = state.addCallLogUIState;

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
                errorType?.getText(context) ??
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
                // ==================================================
                // HEADER
                // ==================================================
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

                // ==================================================
                // FORM
                // ==================================================
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
                        AppFormField(
                          label: 'Call Status',
                          isRequired: true,
                          child: AppSelectField(
                            hint: 'Select status',
                            sheetTitle: 'Call status',
                            icon: Icons.phone_in_talk,
                            options: const ['Answered', 'Not Answered'],
                            value: _selectedCallStatus,
                            onChanged: (value) {
                              setState(() {
                                _selectedCallStatus = value;
                              });
                            },
                          ),
                        ),

                        // ==================================================
                        // INTEREST
                        // ==================================================
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,

                          title: const Text('Interest'),

                          value: _interest,

                          onChanged: (value) {
                            setState(() {
                              _interest = value;

                              if (_interest) {
                                _selectedReasonName = null;
                                _reasonController.clear();
                              }
                            });
                          },

                          activeColor: AppColors.red,
                        ),

                        // ==================================================
                        // NOT INTERESTED REASON
                        // ==================================================
                        Visibility(
                          visible: !_interest,
                          child: BlocBuilder<LeadsCubit, LeadsState>(
                            buildWhen: (previous, current) =>
                                previous.notInterestedReasonsUIState !=
                                current.notInterestedReasonsUIState,
                            builder: (context, state) {
                              final reasonsState =
                                  state.notInterestedReasonsUIState;
                              List<String> options = [];
                              if (reasonsState?.data != null) {
                                // Build the map and options list
                                _reasonMap = {
                                  for (var item
                                      in reasonsState!.data!.data ?? [])
                                    item.name ?? '': item.value ?? '',
                                };
                                options = _reasonMap!.keys.toList();
                              } else if (reasonsState?.status ==
                                  Status.LOADING) {
                                options = ['Loading...'];
                              }

                              return AppFormField(
                                isRequired: !_interest,
                                label: 'Not Interested Reason',
                                child: AppSelectField(
                                  hint: 'Select reason',
                                  sheetTitle: 'Not Interested Reason',
                                  icon: Icons.report,
                                  options: options,
                                  value: _selectedReasonName,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedReasonName = value;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        // ==================================================
                        // ITEM SOLD
                        // ==================================================
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

                        // ==================================================
                        // INVOICE NUMBER
                        // ==================================================
                        Visibility(
                          visible: _isItemSold,
                          child: AppFormField(
                            isRequired: _isItemSold,

                            label: 'Invoice Number',

                            child: AppTextField(
                              hint: 'Invoice #',

                              controller: _invoiceNumberController,

                              icon: Icons.receipt_long,
                            ),
                          ),
                        ),

                        // ==================================================
                        // NEXT FOLLOW-UP
                        // ==================================================
                        Visibility(
                          visible: _interest && !_isItemSold,
                          child: AppFormField(
                            label: 'Next Follow-up Date',
                            child: AppTextField(
                              hint: 'Select date',
                              controller: _nextFollowUpDateController,
                              icon: Icons.event_available,
                              readOnly: true,
                              onTap: () =>
                                  _pickDate(_nextFollowUpDateController),
                            ),
                          ),
                        ),

                        // ==================================================
                        // REMARKS
                        // ==================================================
                        AppFormField(
                          isRequired: true,
                          label: 'Remarks',
                          child: AppTextField(
                            hint: 'Notes / remarks',

                            controller: _remarksController,

                            icon: Icons.notes,

                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // ==================================================
                        // SAVE BUTTON
                        // ==================================================
                        _buildSaveButton(),

                        const SizedBox(height: AppSpacing.md),

                        const SizedBox(height: 45),

                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom,
                        ),
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

  // ======================================================
  // SAVE BUTTON
  // ======================================================

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
