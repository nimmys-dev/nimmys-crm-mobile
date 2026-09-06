// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/core/utils/phone_dialer.dart';
import 'package:nimmys_crm/core/utils/whatsapp_launcher.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/features/leads/model/call_history_list_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_details_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_source_model.dart';
import 'package:nimmys_crm/features/leads/widgets/lead_details_status_chip.dart';
import 'package:nimmys_crm/features/leads/widgets/tele_call_details.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../data/ui_state/ui_state.dart';
import '../../enum/status.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_form_field.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../shared/widgets/app_text_field.dart';
import 'widgets/lead_detail_widgets.dart';

/// Lead Details — customer profile, assignment, source and requirements
/// retrieved from `GET /api/view-lead/{leadId}`.
class LeadDetailsScreen extends StatefulWidget {
  const LeadDetailsScreen({super.key, this.leadId});

  final int? leadId;

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  final List<Map<String, dynamic>> _teleCallDetails = [];
  int? _totalCallHistoryCount;
  int _callHistoryPage = 0;
  bool _hasMoreCallHistory = false;
  bool _isLoadingMoreCallHistory = false;
  int? _requestedCallHistoryPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final int? id = widget.leadId;
      if (id != null) {
        context.read<LeadsCubit>()
          ..getLeadDetails(id)
          ..getLeadSources()
          ..getLeadAssignees()
          ..getCallHistory(id, page: 1);
      }
    });
  }

  Future<void> _reload() async {
    final int? id = widget.leadId;
    if (id == null) return;
    _resetCallHistory();
    await context.read<LeadsCubit>().getLeadDetails(id);
    await _loadCallHistoryPage();
  }

  void _resetCallHistory() {
    _teleCallDetails.clear();
    _totalCallHistoryCount = null;
    _callHistoryPage = 0;
    _hasMoreCallHistory = false;
    _requestedCallHistoryPage = null;
  }

  Future<void> _loadCallHistoryPage() async {
    final int? id = widget.leadId;
    if (id == null || _isLoadingMoreCallHistory) return;

    final int page = _callHistoryPage + 1;
    _requestedCallHistoryPage = page;
    _isLoadingMoreCallHistory = true;
    await context.read<LeadsCubit>().getCallHistory(id, page: page);
  }

  void _onCallHistoryLoaded(LeadsState state) {
    final CallHistoryResponseListModel? response =
        state.callHistoryUIState?.data;
    if (response == null) return;

    final int page =
        response.pagination?.currentPage ?? _requestedCallHistoryPage ?? 1;
    final List<Map<String, dynamic>> pageItems = (response.data ?? [])
        .map((CallHistoryItem item) => item.toJson())
        .toList();

    if (page <= 1) {
      _teleCallDetails
        ..clear()
        ..addAll(pageItems);
    } else {
      _teleCallDetails.addAll(pageItems);
    }

    _callHistoryPage = page;
    _totalCallHistoryCount =
        response.pagination?.total ??
        _totalCallHistoryCount ??
        _teleCallDetails.length;
    _hasMoreCallHistory = page < (response.pagination?.lastPage ?? page);
    _isLoadingMoreCallHistory = false;
    _requestedCallHistoryPage = null;
  }

  void _onLeadDetailsStateChanged(BuildContext context, LeadsState state) {
    final uiState = state.leadDetailsUIState;
    if (uiState?.status == Status.ERROR) {
      ToastMessages.error(
        message:
            uiState?.errorType?.getText(context) ??
            'Failed to load lead details',
      );
    }
  }

  void _onUpdateStateChanged(BuildContext context, LeadsState state) {
    final uiState = state.updateLeadUIState;
    if (uiState?.status == Status.SUCCESS) {
      ToastMessages.success(message: 'Lead updated successfully');
      _reload();
      context.read<LeadsCubit>().resetUpdateLeadState();
    } else if (uiState?.status == Status.ERROR) {
      ToastMessages.error(
        message:
            uiState?.errorType?.getText(context) ?? 'Failed to update lead',
      );
      context.read<LeadsCubit>().resetUpdateLeadState();
    }
  }

  void _onCallHistoryStateChanged(BuildContext context, LeadsState state) {
    final uiState = state.callHistoryUIState;
    if (uiState?.status == Status.SUCCESS) {
      setState(() => _onCallHistoryLoaded(state));
    } else if (uiState?.status == Status.ERROR) {
      _isLoadingMoreCallHistory = false;
    }
    if (uiState?.status == Status.ERROR) {
      ToastMessages.error(
        message:
            uiState?.errorType?.getText(context) ??
            'Failed to load call history',
      );
    }
  }

  void _onAddCallLogStateChanged(LeadsState state) {
    if (state.addCallLogUIState?.status == Status.SUCCESS) {
      _resetCallHistory();
      _loadCallHistoryPage();
      context.read<LeadsCubit>().resetAddCallLogState();
    }
  }


  void _onCloseLeadStateChanged(BuildContext context, LeadsState state) {
    final uiState = state.closeLeadUIState;
    if (uiState?.status == Status.SUCCESS) {
      ToastMessages.success(message: 'Lead closed successfully!');
      context.read<LeadsCubit>().resetCloseLeadState();
      _reload(); // refresh details and history
    } else if (uiState?.status == Status.ERROR) {
      ToastMessages.error(
        message: uiState?.errorType?.getText(context) ?? 'Failed to close lead',
      );
      context.read<LeadsCubit>().resetCloseLeadState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: BlocConsumer<LeadsCubit, LeadsState>(
        listenWhen: (prev, curr) =>
            prev.leadDetailsUIState?.status !=
                curr.leadDetailsUIState?.status ||
            prev.updateLeadUIState?.status != curr.updateLeadUIState?.status ||
            prev.callHistoryUIState?.status !=
                curr.callHistoryUIState?.status ||
            prev.addCallLogUIState?.status != curr.addCallLogUIState?.status ||
            prev.closeLeadUIState?.status != curr.closeLeadUIState?.status,
        listener: (context, state) {
          _onLeadDetailsStateChanged(context, state);
          _onUpdateStateChanged(context, state);
          _onCallHistoryStateChanged(context, state);
          _onAddCallLogStateChanged(state);
          _onCloseLeadStateChanged(context, state);
        },
        builder: (context, state) {
          final lead = state.leadDetailsUIState?.data?.data;
          final eyebrow = lead?.reference?.trim().isNotEmpty == true
              ? lead!.reference!.trim()
              : (widget.leadId != null
                    ? 'LEAD #${widget.leadId}'
                    : 'LEAD DETAILS');

          return Scaffold(
            backgroundColor: context.palette.canvas,
            body: Column(
              children: [
                AppGradientHeader(
                  title: 'Lead Details',
                  eyebrow: eyebrow,
                  leading: const AppBackButton(),
                  actions: [
                    // if (lead != null && lead.status?.toLowerCase() == 'open')
                    //   GestureDetector(
                    //     onTap: () => _showCloseLeadSheet(context, lead),
                    //     child: Container(
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 10,
                    //         vertical: 6,
                    //       ),
                    //       decoration: BoxDecoration(
                    //         color: AppColors.red.withOpacity(0.15),
                    //         borderRadius: BorderRadius.circular(20),
                    //         border: Border.all(
                    //           color: AppColors.red.withOpacity(0.3),
                    //         ),
                    //       ),
                    //       child: Row(
                    //         mainAxisSize: MainAxisSize.min,
                    //         children: const [
                    //           Icon(
                    //             Icons.close_rounded,
                    //             color: AppColors.white,
                    //             size: 18,
                    //           ),
                    //           SizedBox(width: 4),
                    //           Text(
                    //             'Close Lead',
                    //             style: TextStyle(
                    //               color: AppColors.white,
                    //               fontWeight: FontWeight.w600,
                    //               fontSize: 13,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    if (lead != null)
                      LeadDetailsSatausChip(status: lead.status ?? 'Closed'),
                  ],
                ),
                Expanded(
                  child: _LeadDetailsBody(
                    leadId: widget.leadId,
                    state: state,
                    onRetry: _reload,
                    teleCallDetails: _teleCallDetails,
                    totalCallHistoryCount: _totalCallHistoryCount,
                    hasMoreCallHistory: _hasMoreCallHistory,
                    isLoadingMoreCallHistory: _isLoadingMoreCallHistory,
                    onLoadMoreCallHistory: _loadCallHistoryPage,
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
            floatingActionButton: lead != null
                ? FloatingActionButton(
                    onPressed: () => _showEditBottomSheet(context, lead, state),
                    backgroundColor: AppColors.red,
                    child: const Icon(Icons.edit_rounded),
                  )
                : null,
          );
        },
      ),
    );
  }

  void _showEditBottomSheet(
    BuildContext context,
    LeadDetailsData lead,
    LeadsState state,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditLeadBottomSheet(lead: lead, state: state),
    );
  }
}

/// Bottom sheet for editing lead details and quotation.

/// Bottom sheet for editing lead details and quotation.
class EditLeadBottomSheet extends StatefulWidget {
  const EditLeadBottomSheet({
    super.key,
    required this.lead,
    required this.state,
  });

  final LeadDetailsData lead;
  final LeadsState state;

  @override
  State<EditLeadBottomSheet> createState() => _EditLeadBottomSheetState();
}

class _EditLeadBottomSheetState extends State<EditLeadBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;

  LeadSourceData? _selectedSource;
  LeadAssigneeData? _selectedAssignee;

  // Quotation fields
  late List<TextEditingController> _itemControllers;
  late List<TextEditingController> _qtyControllers;
  late List<TextEditingController> _rateControllers;
  late TextEditingController _addressController;
  late TextEditingController _termsController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.lead.name ?? '');

    _phoneController = TextEditingController(text: widget.lead.phone ?? '');

    _descriptionController = TextEditingController(
      text: widget.lead.description ?? '',
    );

    // Source
    final sources = widget.state.leadSourcesUIState?.data?.data ?? [];

    _selectedSource = sources.isEmpty
        ? null
        : sources.firstWhere(
            (s) => s.value == widget.lead.source,
            orElse: () => sources.first,
          );

    // Assignee
    final assignees =
        widget.state.leadAssigneesUIState?.data?.validAssignees ?? [];

    if (widget.lead.assignedTo != null && assignees.isNotEmpty) {
      _selectedAssignee = assignees.firstWhere(
        (a) =>
            a.name == widget.lead.assignedTo ||
            a.id?.toString() == widget.lead.assignedTo,
        orElse: () => assignees.first,
      );
    }

    // Quotation
    final quotation = widget.lead.quotation;

    if (quotation != null) {
      _addressController = TextEditingController(
        text: quotation.customerAddress ?? '',
      );

      _termsController = TextEditingController(text: quotation.terms ?? '');

      _itemControllers =
          quotation.items
              ?.map(
                (item) => TextEditingController(text: item.description ?? ''),
              )
              .toList() ??
          [];

      _qtyControllers =
          quotation.items
              ?.map((item) => TextEditingController(text: item.quantity ?? ''))
              .toList() ??
          [];

      _rateControllers =
          quotation.items
              ?.map((item) => TextEditingController(text: item.rate ?? ''))
              .toList() ??
          [];
    } else {
      _addressController = TextEditingController();
      _termsController = TextEditingController();
      _itemControllers = [];
      _qtyControllers = [];
      _rateControllers = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _termsController.dispose();

    for (final controller in _itemControllers) {
      controller.dispose();
    }

    for (final controller in _qtyControllers) {
      controller.dispose();
    }

    for (final controller in _rateControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _addItem() {
    setState(() {
      _itemControllers.add(TextEditingController());
      _qtyControllers.add(TextEditingController());
      _rateControllers.add(TextEditingController());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemControllers[index].dispose();
      _itemControllers.removeAt(index);

      _qtyControllers[index].dispose();
      _qtyControllers.removeAt(index);

      _rateControllers[index].dispose();
      _rateControllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    final id = widget.lead.id;

    if (id == null) return;

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'source': _selectedSource?.value ?? '',
      'description': _descriptionController.text.trim(),
      'assigned_to': _selectedAssignee?.id,
    };

    // Quotation
    final hasQuotation =
        _addressController.text.trim().isNotEmpty ||
        _termsController.text.trim().isNotEmpty ||
        _itemControllers.any((controller) => controller.text.trim().isNotEmpty);

    if (hasQuotation) {
      final items = <Map<String, dynamic>>[];

      for (int i = 0; i < _itemControllers.length; i++) {
        final description = _itemControllers[i].text.trim();

        if (description.isEmpty) continue;

        final quantity = int.tryParse(_qtyControllers[i].text.trim()) ?? 1;

        final rate =
            double.tryParse(
              _rateControllers[i].text.trim().replaceAll(',', ''),
            ) ??
            0.0;

        items.add({
          'description': description,
          'quantity': quantity,
          'rate': rate,
          'tax_percent': 0,
        });
      }

      if (items.isNotEmpty) {
        payload['quotation'] = {
          'customer_name': _nameController.text.trim(),
          if (_addressController.text.trim().isNotEmpty)
            'customer_address': _addressController.text.trim(),
          'issue_date': DateTime.now().toIso8601String().split('T').first,
          if (_termsController.text.trim().isNotEmpty)
            'terms': _termsController.text.trim(),
          'items': items,
        };
      }
    }

    await context.read<LeadsCubit>().updateLead(id, payload);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final sources = widget.state.leadSourcesUIState?.data?.data ?? [];

    final sourceLabels = sources.map((s) => s.label ?? '').toList();

    final assignees =
        widget.state.leadAssigneesUIState?.data?.validAssignees ?? [];

    final assigneeLabels = assignees.map((a) => a.name ?? '').toList();

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: palette.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------------
                // Drag handle
                // ------------------------------------------------------
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

                // ------------------------------------------------------
                // Title
                // ------------------------------------------------------
                Text(
                  'Edit Lead',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // --------------------------------------------------
                      // Name
                      // --------------------------------------------------
                      AppFormField(
                        label: 'Name',
                        child: AppTextField(
                          hint: 'Customer name',
                          controller: _nameController,
                          icon: Icons.person_outline_rounded,
                        ),
                      ),

                      // --------------------------------------------------
                      // Phone
                      // --------------------------------------------------
                      AppFormField(
                        label: 'Phone',
                        child: AppTextField(
                          hint: 'Mobile number',
                          controller: _phoneController,
                          icon: Icons.call_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),

                      // --------------------------------------------------
                      // Source
                      // --------------------------------------------------
                      AppFormField(
                        label: 'Source',
                        child: AppSelectField(
                          hint: 'Select source',
                          sheetTitle: 'Lead source',
                          icon: Icons.campaign_outlined,
                          options: sourceLabels,
                          value: _selectedSource?.label,
                          onChanged: (label) {
                            if (sources.isEmpty) return;

                            final matched = sources.firstWhere(
                              (s) => s.label == label,
                              orElse: () => sources.first,
                            );

                            setState(() {
                              _selectedSource = matched;
                            });
                          },
                        ),
                      ),

                      // --------------------------------------------------
                      // Assigned To
                      // --------------------------------------------------
                      AppFormField(
                        label: 'Assigned To',
                        child: AppSelectField(
                          hint: assignees.isEmpty
                              ? 'Loading assignees…'
                              : 'Select assignee',
                          sheetTitle: 'Assign lead to',
                          icon: Icons.badge_outlined,
                          options: assigneeLabels,
                          value: _selectedAssignee?.name,
                          onChanged: (label) {
                            if (assignees.isEmpty) return;

                            final matched = assignees.firstWhere(
                              (a) => a.name == label,
                              orElse: () => assignees.first,
                            );

                            setState(() {
                              _selectedAssignee = matched;
                            });
                          },
                        ),
                      ),

                      // --------------------------------------------------
                      // Description
                      // --------------------------------------------------
                      AppFormField(
                        label: 'Description',
                        child: AppTextField(
                          hint: 'Requirements / notes',
                          controller: _descriptionController,
                          icon: Icons.description_outlined,
                          maxLines: 3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Divider(height: 32, color: palette.line),

                      // --------------------------------------------------
                      // Quotation header
                      // --------------------------------------------------
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: palette.redWashSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.redBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: palette.redWash,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 19,
                                color: AppColors.red,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Quotation',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: palette.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // --------------------------------------------------
                      // Address
                      // --------------------------------------------------
                      AppFormField(
                        label: 'Address',
                        child: AppTextField(
                          hint: 'Customer address',
                          controller: _addressController,
                          icon: Icons.location_on_outlined,
                        ),
                      ),

                      // --------------------------------------------------
                      // Terms
                      // --------------------------------------------------
                      AppFormField(
                        label: 'Terms',
                        child: AppTextField(
                          hint: 'Payment terms',
                          controller: _termsController,
                          icon: Icons.description_outlined,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // --------------------------------------------------
                      // Items
                      // --------------------------------------------------
                      if (_itemControllers.isNotEmpty) ...[
                        Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),

                        const SizedBox(height: 8),

                        for (int i = 0; i < _itemControllers.length; i++)
                          _buildItemRow(i),
                      ],

                      // --------------------------------------------------
                      // Add Item
                      // --------------------------------------------------
                      AppOutlineButton(
                        label: 'Add Item',
                        icon: Icons.add_rounded,
                        onPressed: _addItem,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // --------------------------------------------------
                      // Save
                      // --------------------------------------------------
                      AppPrimaryButton(
                        label: 'Save Changes',
                        onPressed: _save,
                        isLoading:
                            widget.state.updateLeadUIState?.status ==
                            Status.LOADING,
                      ),

                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemRow(int index) {
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ------------------------------------------------------------
          // Description
          // ------------------------------------------------------------
          Expanded(
            child: TextField(
              controller: _itemControllers[index],
              style: TextStyle(
                fontSize: 13,
                color: palette.ink,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.red,
              decoration: InputDecoration(
                hintText: 'Item description',
                hintStyle: TextStyle(fontSize: 13, color: palette.faint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ------------------------------------------------------------
          // Quantity
          // ------------------------------------------------------------
          SizedBox(
            width: 52,
            child: TextField(
              controller: _qtyControllers[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: palette.ink,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.red,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Qty',
                hintStyle: TextStyle(fontSize: 12, color: palette.faint),
                filled: true,
                fillColor: palette.inkWash,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: palette.inkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: palette.inkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: AppColors.red,
                    width: 1.2,
                  ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ------------------------------------------------------------
          // Rate
          // ------------------------------------------------------------
          SizedBox(
            width: 82,
            child: TextField(
              controller: _rateControllers[index],
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                color: palette.ink,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.red,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'Rate',
                hintStyle: TextStyle(fontSize: 12, color: palette.faint),
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontSize: 12,
                  color: palette.slate,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: palette.inkWash,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: palette.inkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: palette.inkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: AppColors.red,
                    width: 1.2,
                  ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),

          // ------------------------------------------------------------
          // Delete
          // ------------------------------------------------------------
          IconButton(
            tooltip: 'Remove item',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.red,
            ),
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    );
  }
}

class _LeadDetailsBody extends StatelessWidget {
  const _LeadDetailsBody({
    required this.leadId,
    required this.state,
    required this.onRetry,
    required this.teleCallDetails,
    required this.totalCallHistoryCount,
    required this.hasMoreCallHistory,
    required this.isLoadingMoreCallHistory,
    required this.onLoadMoreCallHistory,
  });

  final int? leadId;
  final LeadsState state;
  final Future<void> Function() onRetry;
  final List<Map<String, dynamic>> teleCallDetails;
  final int? totalCallHistoryCount;
  final bool hasMoreCallHistory;
  final bool isLoadingMoreCallHistory;
  final VoidCallback onLoadMoreCallHistory;

  @override
  Widget build(BuildContext context) {
    final UIState<LeadDetailsSuccess>? detailsState = state.leadDetailsUIState;
    final LeadDetailsData? lead = detailsState?.data?.data;
    final Status? status = detailsState?.status;

    if (leadId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Text(
            'No Lead ID specified.',
            style: context.type.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (lead == null &&
        (status == Status.LOADING ||
            status == null ||
            status == Status.INITIAL)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
        ),
      );
    }

    if (lead == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.red.withValues(alpha: 0.8),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Failed to load lead details',
                style: context.type.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                detailsState?.errorType?.getText(context) ??
                    'Something went wrong. Please try again.',
                style: context.type.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              AppOutlineButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: () => onRetry(),
              ),
            ],
          ),
        ),
      );
    }

    final String displayName = lead.name?.trim().isNotEmpty == true
        ? lead.name!.trim()
        : 'Unnamed Lead';
    final String phone = lead.phone?.trim() ?? '';
    final String description = lead.cleanDescription;
    final Quotation? quotation = lead.quotation; // <-- NEW

    return RefreshIndicator(
      onRefresh: onRetry,
      color: AppColors.red,
      child: ListView(
        padding: const EdgeInsets.only(
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          top: AppSpacing.md,
          bottom: AppSpacing.xl,
        ),
        children: <Widget>[
          LeadSummaryCard(
            name: displayName,
            mobile: phone.isNotEmpty ? phone : 'No phone number',
            reference: lead.reference,
            onCall: phone.isNotEmpty
                ? () => PhoneDialer.call(context, phone)
                : null,
            onWhatsApp: phone.isNotEmpty
                ? () => WhatsAppLauncher.openChat(
                    context,
                    phone,
                    message:
                        'Hi $displayName, following up on your enquiry (${lead.reference ?? "Lead #${lead.id}"}).',
                  )
                : null,
          ),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const LeadSectionTitle(
                  title: 'Customer Details',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                LeadDetailsGrid(
                  name: displayName,
                  phone: phone.isNotEmpty ? phone : '—',
                  reference: lead.reference,
                  source: lead.source,
                  assignedTo: lead.assignedTo,
                  createdBy: lead.createdBy,
                ),
              ],
            ),
          ),
          if (description.isNotEmpty)
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const LeadSectionTitle(
                    title: 'Description / Notes',
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LeadDetailBlock(
                    label: 'Requirements / Notes',
                    value: description,
                    icon: Icons.notes_rounded,
                  ),
                ],
              ),
            ),
          if (quotation != null) ...[
            const SizedBox(height: AppSpacing.md),
            QuotationCard(quotation: quotation),
          ],
          SizedBox(height: 20),
          Text("Tele Call Details", style: context.type.cardTitle),
          SizedBox(height: 10),
          TeleCallDetailsSection(
            leadId: lead.id ?? 5,
            teleCallDetails: teleCallDetails,
            totalCount: totalCallHistoryCount,
            hasMore: hasMoreCallHistory,
            isLoadingMore: isLoadingMoreCallHistory,
            onLoadMore: onLoadMoreCallHistory,
            onAddTeleCallDetail: (detail) async {
              final cubit = context.read<LeadsCubit>();

              await cubit.addCallLog(
                leadId: lead.id ?? 5,
                callStatus: detail['call_status']?.toString(),
                calledDate: detail['called_date']?.toString(),
                calledTime: detail['called_time']?.toString(),
                duration: detail['duration']?.toString(),
                interest: detail['interest'] as bool?,
                reason: detail['reason']?.toString(),
                isItemSold: detail['is_item_sold'] as bool?,
                invoiceNumber: detail['invoice_number']?.toString(),
                remarks: detail['remarks']?.toString(),
                nextFollowupDate: detail['next_followup_date']?.toString(),
                invoiceFile: detail['invoice_file'] as File?,
              );

              return cubit.state.addCallLogUIState?.status == Status.SUCCESS;
            },
          ),
          SizedBox(height: 120),
        ],
      ),
    );
  }
}

/// Card that displays quotation details and its items.
class QuotationCard extends StatelessWidget {
  const QuotationCard({super.key, required this.quotation});

  final Quotation quotation;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const LeadSectionTitle(
            title: 'Quotation',
            icon: Icons.receipt_long_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Quotation summary
          QuotationSummary(quotation: quotation),
          const SizedBox(height: AppSpacing.md),
          // Items list
          if (quotation.items != null && quotation.items!.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Items',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...quotation.items!.map((item) => QuotationItemTile(item: item)),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Totals
          _buildTotals(context),
        ],
      ),
    );
  }

  Widget _buildTotals(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '₹ ${quotation.total ?? '0.00'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays quotation header fields (reference, customer, dates, terms, amounts).
class QuotationSummary extends StatelessWidget {
  const QuotationSummary({super.key, required this.quotation});

  final Quotation quotation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: [
            Expanded(
              child: LeadDetailTile(
                label: 'Quotation #',
                value: quotation.reference ?? '—',
                icon: Icons.receipt_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: LeadDetailTile(
                label: 'Date',
                value: quotation.issueDate != null
                    ? _formatDate(quotation.issueDate!)
                    : '—',
                icon: Icons.calendar_today_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: LeadDetailTile(
                label: 'Customer',
                value: quotation.customerName ?? '—',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: LeadDetailTile(
                label: 'Terms',
                value: quotation.terms ?? '—',
                icon: Icons.description_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (quotation.subtotal != null ||
            quotation.discountPercent != null ||
            quotation.taxPercent != null)
          Row(
            children: [
              if (quotation.subtotal != null)
                Expanded(
                  child: LeadDetailTile(
                    label: 'Subtotal',
                    value: '₹ ${quotation.subtotal!}',
                    icon: Icons.currency_rupee_rounded,
                  ),
                ),
              if (quotation.discountPercent != null)
                Expanded(
                  child: LeadDetailTile(
                    label: 'Discount',
                    value: '${quotation.discountPercent!}%',
                    icon: Icons.percent_rounded,
                  ),
                ),
              if (quotation.taxPercent != null)
                Expanded(
                  child: LeadDetailTile(
                    label: 'Tax',
                    value: '${quotation.taxPercent!}%',
                    icon: Icons.percent_rounded,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoString;
    }
  }
}

/// A single item row in the quotation.
class QuotationItemTile extends StatelessWidget {
  const QuotationItemTile({super.key, required this.item});

  final QuotationItem item;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ----------------------------------------------------------
          // Item description
          // ----------------------------------------------------------
          Expanded(
            child: Text(
              item.description?.trim().isNotEmpty == true
                  ? item.description!
                  : 'Item',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: palette.ink,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ----------------------------------------------------------
          // Quantity
          // ----------------------------------------------------------
          Container(
            constraints: const BoxConstraints(minWidth: 42),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: palette.inkWash,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: palette.inkBorder, width: 0.8),
            ),
            child: Text(
              '× ${item.quantity ?? 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.slate,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ----------------------------------------------------------
          // Price
          // ----------------------------------------------------------
          SizedBox(
            width: 95,
            child: Text(
              '₹ ${item.amount ?? '0.00'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Identity strip at the top of the lead: avatar, name, reference and quick actions.
class LeadSummaryCard extends StatelessWidget {
  const LeadSummaryCard({
    super.key,
    required this.name,
    required this.mobile,
    this.reference,
    this.onCall,
    this.onWhatsApp,
  });

  final String name;
  final String mobile;
  final String? reference;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final String initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';

    return AppSectionCard(
      accentBorder: true,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(initials: initial, size: 48, tone: AppAvatarTone.solid),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      name,
                      style: context.type.pageHeading.copyWith(fontSize: 19),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.call_outlined,
                          size: 13,
                          color: context.palette.muted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            mobile,
                            style: context.type.bodyMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (reference != null && reference!.trim().isNotEmpty)
                AppTag(label: reference!.trim(), icon: Icons.tag_rounded),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LeadQuickActions(onCall: onCall, onWhatsApp: onWhatsApp),
        ],
      ),
    );
  }
}

/// Two-column grid of the lead's core attributes.
class LeadDetailsGrid extends StatelessWidget {
  const LeadDetailsGrid({
    super.key,
    required this.name,
    required this.phone,
    this.reference,
    this.source,
    this.assignedTo,
    this.createdBy,
  });

  final String name;
  final String phone;
  final String? reference;
  final String? source;
  final String? assignedTo;
  final String? createdBy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: LeadDetailTile(
                label: 'Name',
                value: name,
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: LeadDetailTile(
                label: 'Mobile No',
                value: phone,
                icon: Icons.call_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Expanded(
              child: LeadDetailTile(
                label: 'Assigned To',
                value: assignedTo != null && assignedTo!.trim().isNotEmpty
                    ? assignedTo!.trim()
                    : '—',
                icon: Icons.assignment_ind_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: LeadDetailTile(
                label: 'Created By',
                value: createdBy != null && createdBy!.trim().isNotEmpty
                    ? createdBy!.trim()
                    : '—',
                icon: Icons.badge_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Expanded(
              child: LeadDetailTile(
                label: 'Source',
                value: source != null && source!.trim().isNotEmpty
                    ? source!.trim().toUpperCase()
                    : '—',
                icon: Icons.campaign_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: LeadDetailTile(
                label: 'Reference',
                value: reference != null && reference!.trim().isNotEmpty
                    ? reference!.trim()
                    : '—',
                icon: Icons.tag_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Wide row of quick actions (call / WhatsApp) on the lead detail page.
class LeadQuickActions extends StatelessWidget {
  const LeadQuickActions({super.key, this.onCall, this.onWhatsApp});

  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: LeadQuickAction(
            icon: Icons.call_rounded,
            label: 'Call',
            isPrimary: true,
            onTap: onCall,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: LeadQuickAction(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'WhatsApp',
            onTap: onWhatsApp,
          ),
        ),
      ],
    );
  }
}
