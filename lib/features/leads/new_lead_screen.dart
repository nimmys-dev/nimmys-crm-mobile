import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_source_model.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../enum/status.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_form_field.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_segmented_tabs.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../shared/widgets/app_text_field.dart';
import 'domain/entities/lead.dart'; // ← contains LeadSource enum and LeadDraft

/// New Lead capture — mobile, name, requirement, source, owner and an
/// optional quotation.
class NewLeadScreen extends StatefulWidget {
  const NewLeadScreen({super.key, this.onSubmit});

  /// Receives the assembled draft — source and quotation included — when the
  /// form is submitted. Null on the demo route, which leaves the existing
  /// no-op submit behaviour untouched.
  final ValueChanged<LeadDraft>? onSubmit;

  @override
  State<NewLeadScreen> createState() => _NewLeadScreenState();
}

class _NewLeadScreenState extends State<NewLeadScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _requirementController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  /// One controller set per quotation line. Starts with a single row, which
  /// is also the minimum while the quotation toggle is on.
  final List<QuotationItemControllers> _quotationItems =
      <QuotationItemControllers>[QuotationItemControllers()];

  LeadAssigneeData? _selectedAssignee;

  LeadSourceData? _source; // ✅ Now using the enum, not LeadSourceData
  DateTime? _nextFollowUp;
  bool _addQuotation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LeadsCubit>()
          ..resetCreateLeadState()
          ..getLeadAssignees()
          ..getLeadSources(); // ← fetches API sources and stores as LeadSourceData
      }
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    _requirementController.dispose();
    _addressController.dispose();
    _termsController.dispose();
    for (final QuotationItemControllers item in _quotationItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addQuotationItem() =>
      setState(() => _quotationItems.add(QuotationItemControllers()));

  void _removeQuotationItem(int index) {
    if (_quotationItems.length <= 1) return;
    setState(() => _quotationItems.removeAt(index).dispose());
  }

  LeadQuotation? get _quotation {
    if (!_addQuotation) return null;
    final quotation = LeadQuotation(
      customerAddress: _addressController.text,
      items: _quotationItems.map((c) => c.toItem()).toList(),
    );
    final hasTerms = _termsController.text.trim().isNotEmpty;
    return (quotation.hasContent || hasTerms)
        ? LeadQuotation(
            customerAddress: quotation.customerAddress,
            items: quotation.filledItems,
          )
        : null;
  }

  LeadDraft _buildDraft() => LeadDraft(
    name: _nameController.text,
    mobile: _mobileController.text,
    source:
        _source?.value.toString() ?? 'Call', // ✅ now matches LeadSource? type
    quotation: _quotation,
    requiredItems: _requirementController.text.trim().isEmpty
        ? null
        : _requirementController.text.trim(),
    nextFollowUpAt: _nextFollowUp,
    assignedToId: _selectedAssignee?.id?.toString(),
  );

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _buildPayload() {
    final quotation = _quotation;
    return <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _mobileController.text.trim(),
      'source':
          _source?.value.toString() ?? 'Call', // ✅ now matches LeadSource? type
      'assigned_to': _selectedAssignee?.id,
      if (_nextFollowUp != null)
        'next_follow_up_date': _dateOnly(_nextFollowUp!),
      if (_requirementController.text.trim().isNotEmpty)
        'description': _requirementController.text.trim(),
      if (quotation != null)
        'quotation': <String, dynamic>{
          'customer_name': _nameController.text.trim(),
          if (quotation.customerAddress?.trim().isNotEmpty ?? false)
            'customer_address': quotation.customerAddress!.trim(),
          'issue_date': _dateOnly(DateTime.now()),
          if (_termsController.text.trim().isNotEmpty)
            'terms': _termsController.text.trim(),
          'items': _quotationItems
              .where((item) => item.toItem().hasContent)
              .map((item) => item.toApiJson())
              .toList(growable: false),
        },
    };
  }

  String? _validationMessage() {
    if (_mobileController.text.trim().length != 10) {
      return 'Enter a valid 10-digit mobile number.';
    }
    if (_nameController.text.trim().isEmpty) return 'Enter the customer name.';
    if (_source == null) return 'Select a lead source.';
    if (_selectedAssignee == null) return 'Select an assignee.';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final validationMessage = _validationMessage();
    if (validationMessage != null) {
      ToastMessages.alert(message: validationMessage);
      return;
    }
    await context.read<LeadsCubit>().createLead(_buildPayload());
  }

  void _onLeadsStateChanged(BuildContext context, LeadsState state) {
    if (!mounted) return;

    // Handle assignees errors
    if (state.leadAssigneesUIState?.status == Status.ERROR) {
      ToastMessages.error(
        message:
            state.leadAssigneesUIState?.errorType?.getText(context) ??
            'Could not load assignees',
      );
    }

    // Handle sources errors
    if (state.leadSourcesUIState?.status == Status.ERROR) {
      ToastMessages.error(
        message:
            state.leadSourcesUIState?.errorType?.getText(context) ??
            'Could not load lead sources',
      );
    }

    // Handle create lead
    switch (state.createLeadUIState?.status) {
      case Status.SUCCESS:
        final value = state.createLeadUIState?.data;
        final message = (value is Map && value['message'] is String)
            ? value['message'] as String
            : 'Lead created successfully.';
        ToastMessages.success(message: message);
        widget.onSubmit?.call(_buildDraft());
        context.read<LeadsCubit>().resetCreateLeadState();
        if (context.canPop()) context.pop(true);
      case Status.ERROR:
        ToastMessages.error(
          message:
              state.createLeadUIState?.errorType?.getText(context) ??
              'Could not create lead, Please try again later',
        );
        context.read<LeadsCubit>().resetCreateLeadState();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: BlocConsumer<LeadsCubit, LeadsState>(
        listenWhen: (previous, current) =>
            previous.createLeadUIState?.status !=
                current.createLeadUIState?.status ||
            previous.leadAssigneesUIState?.status !=
                current.leadAssigneesUIState?.status ||
            previous.leadSourcesUIState?.status !=
                current.leadSourcesUIState?.status,
        listener: _onLeadsStateChanged,
        builder: (context, state) {
          // ---- Assignees ----
          final assignees =
              state.leadAssigneesUIState?.data?.validAssignees ?? [];
          final isLoadingAssignees =
              state.leadAssigneesUIState?.status == Status.LOADING ||
              state.leadAssigneesUIState?.status == null ||
              state.leadAssigneesUIState?.status == Status.INITIAL;

          // ---- Sources ----
          // Convert API LeadSourceData to enum LeadSource
          final sources =
              state.leadSourcesUIState?.data?.data ?? <LeadSourceData>[];
          final isLoadingSources =
              state.leadSourcesUIState?.status == Status.LOADING ||
              state.leadSourcesUIState?.status == null ||
              state.leadSourcesUIState?.status == Status.INITIAL;
          final sourceLabels = sources.map((s) => s.label ?? '').toList();
          print('Lead sources: ${sourceLabels}'); // Debug print
          print(
            'Lead sources UI state: ${state.leadSourcesUIState}',
          ); // Debug print
          final isSubmitting =
              state.createLeadUIState?.status == Status.LOADING;

          return Scaffold(
            backgroundColor: context.palette.canvas,
            body: Column(
              children: [
                const AppGradientHeader(
                  title: 'New Lead',
                  eyebrow: 'CAPTURE ENQUIRY',
                  leading: AppBackButton(),
                  actions: [
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
                          MediaQuery.of(context).viewInsets.bottom +
                          AppSpacing.xl,
                    ),
                    children: [
                      AppSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppFormField(
                              label: 'Customer Mobile',
                              isRequired: true,
                              child: AppTextField(
                                hint: 'Enter mobile number',
                                controller: _mobileController,
                                icon: Icons.call_outlined,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
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
                          children: [
                            AppFormField(
                              label: 'Source',
                              isRequired: true,
                              child: AppSelectField(
                                hint: isLoadingSources
                                    ? 'Loading sources…'
                                    : 'Select lead source',
                                sheetTitle: 'Where did this lead come from?',
                                icon: Icons.campaign_outlined,
                                options: sourceLabels,
                                value: _source?.label,
                                onChanged: (selectedLabel) {
                                  final matched = sources.firstWhere(
                                    (s) => s.label == selectedLabel,
                                    orElse: () => sources.first,
                                  );
                                  setState(() => _source = matched);
                                },
                              ),
                            ),
                            AppFormField(
                              label: 'Assigned To',
                              isRequired: true,
                              child: AppSelectField(
                                hint: isLoadingAssignees
                                    ? 'Loading assignees…'
                                    : 'Select assignee',
                                sheetTitle: 'Assign lead to',
                                icon: Icons.badge_outlined,
                                options: assignees
                                    .map((a) => a.name!)
                                    .toList(growable: false),
                                value: _selectedAssignee?.name,
                                onChanged: (value) {
                                  final matched = assignees.firstWhere(
                                    (a) => a.name == value,
                                    orElse: () => assignees.first,
                                  );
                                  setState(() => _selectedAssignee = matched);
                                },
                              ),
                            ),
                            AppFormField(
                              label: 'Next Follow Up',
                              bottomSpacing: 0,
                              child: AppDateField(
                                hint: 'Select follow up date',
                                value: _nextFollowUp,
                                onChanged: (value) =>
                                    setState(() => _nextFollowUp = value),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppToggleRow(
                              title: 'Add Quotation',
                              subtitle: 'Capture a price quote with this lead',
                              icon: Icons.request_quote_outlined,
                              value: _addQuotation,
                              onChanged: (value) =>
                                  setState(() => _addQuotation = value),
                            ),
                            if (_addQuotation) ...[
                              const SizedBox(height: AppSpacing.md),
                              NewLeadQuotationFields(
                                addressController: _addressController,
                                termsController: _termsController,
                                items: _quotationItems,
                                onAddItem: _addQuotationItem,
                                onRemoveItem: _removeQuotationItem,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppPrimaryButton(
                        label: 'CREATE LEAD',
                        icon: Icons.person_add_alt_1_rounded,
                        isLoading: isSubmitting,
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
                      SizedBox(
                        height: 70 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Quotation controllers and sub‑widgets (unchanged)
// ----------------------------------------------------------------------------

class QuotationItemControllers {
  QuotationItemControllers();

  final TextEditingController item = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController rate = TextEditingController();
  final TextEditingController taxPercent = TextEditingController(text: '0');

  QuotationItem toItem() => QuotationItem(
    item: item.text,
    quantity: int.tryParse(quantity.text.trim()),
    rate: double.tryParse(rate.text.trim().replaceAll(',', '')),
  );

  Map<String, dynamic> toApiJson() => <String, dynamic>{
    if (item.text.trim().isNotEmpty) 'description': item.text.trim(),
    if (int.tryParse(quantity.text.trim()) != null)
      'quantity': int.parse(quantity.text.trim()),
    if (double.tryParse(rate.text.trim().replaceAll(',', '')) != null)
      'rate': double.parse(rate.text.trim().replaceAll(',', '')),
    'tax_percent':
        double.tryParse(taxPercent.text.trim().replaceAll(',', '')) ?? 0,
  };

  void dispose() {
    item.dispose();
    quantity.dispose();
    rate.dispose();
    taxPercent.dispose();
  }
}

class NewLeadQuotationFields extends StatelessWidget {
  const NewLeadQuotationFields({
    super.key,
    required this.addressController,
    required this.termsController,
    required this.items,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  final TextEditingController addressController;
  final TextEditingController termsController;
  final List<QuotationItemControllers> items;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: 'Customer Address',
          child: AppTextField(
            hint: 'Enter billing or delivery address',
            controller: addressController,
            icon: Icons.location_on_outlined,
            maxLines: 3,
            maxLength: 250,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        AppFormField(
          label: 'Terms',
          child: AppTextField(
            hint: 'Enter quotation terms',
            controller: termsController,
            icon: Icons.description_outlined,
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        for (int index = 0; index < items.length; index++)
          NewLeadQuotationItemFields(
            key: ObjectKey(items[index]),
            controllers: items[index],
            index: index,
            onRemove: items.length > 1 ? () => onRemoveItem(index) : null,
          ),
        const SizedBox(height: AppSpacing.xs),
        AppOutlineButton(
          label: 'Add Item',
          icon: Icons.add_rounded,
          onPressed: onAddItem,
        ),
      ],
    );
  }
}

class NewLeadQuotationItemFields extends StatelessWidget {
  const NewLeadQuotationItemFields({
    super.key,
    required this.controllers,
    required this.index,
    this.onRemove,
  });

  final QuotationItemControllers controllers;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: 'Item / Product',
          trailing: onRemove == null
              ? null
              : QuotationItemRemoveButton(onPressed: onRemove),
          child: AppTextField(
            hint: 'Which product is being quoted?',
            controller: controllers.item,
            icon: Icons.inventory_2_outlined,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppFormField(
                label: 'Quantity',
                bottomSpacing: 0,
                child: AppTextField(
                  hint: '1',
                  controller: controllers.quantity,
                  icon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppFormField(
                label: 'Rate',
                bottomSpacing: 0,
                child: AppTextField(
                  hint: '25,000',
                  controller: controllers.rate,
                  icon: Icons.currency_rupee_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFormField(
          label: 'Tax %',
          bottomSpacing: 0,
          child: AppTextField(
            hint: '0',
            controller: controllers.taxPercent,
            icon: Icons.percent_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
        ),
        if (onRemove != null || index > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Divider(height: 1, color: context.palette.line),
          ),
      ],
    );
  }
}

class QuotationItemRemoveButton extends StatelessWidget {
  const QuotationItemRemoveButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              size: 15,
              color: AppColors.red,
            ),
            const SizedBox(width: 3),
            Text('Remove', style: context.type.link.copyWith(fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

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
            children: [
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
