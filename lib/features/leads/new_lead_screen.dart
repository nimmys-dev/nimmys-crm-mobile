import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
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
import 'domain/entities/lead.dart';

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

  LeadSource? _source;
  DateTime? _nextFollowUp;
  bool _addQuotation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LeadsCubit>()
          ..resetCreateLeadState()
          ..getLeadAssignees();
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

  /// Removes a line and disposes its controllers. The last row stays: an
  /// enabled quotation always has somewhere to type.
  void _removeQuotationItem(int index) {
    if (_quotationItems.length <= 1) {
      return;
    }
    setState(() => _quotationItems.removeAt(index).dispose());
  }

  /// The quotation to save with the lead, or null when the toggle is off or
  /// nothing was typed into it — an empty quotation is not worth storing and
  /// would render an empty section on the details screen.
  LeadQuotation? get _quotation {
    if (!_addQuotation) {
      return null;
    }
    final LeadQuotation quotation = LeadQuotation(
      customerAddress: _addressController.text,
      // Rows left blank are dropped by `filledItems` on the way out.
      items: _quotationItems
          .map((QuotationItemControllers item) => item.toItem())
          .toList(),
    );
    final bool hasTerms = _termsController.text.trim().isNotEmpty;
    return (quotation.hasContent || hasTerms)
        ? LeadQuotation(
            customerAddress: quotation.customerAddress,
            items: quotation.filledItems,
          )
        : null;
  }

  /// Everything the form knows, retained for the optional screen callback.
  LeadDraft _buildDraft() => LeadDraft(
    name: _nameController.text,
    mobile: _mobileController.text,
    source: _source,
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
    final LeadQuotation? quotation = _quotation;
    return <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _mobileController.text.trim(),
      'source': _source!.wireValue,
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
              .where((QuotationItemControllers item) => item.toItem().hasContent)
              .map(
                (QuotationItemControllers item) => item.toApiJson(),
              )
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
    final String? validationMessage = _validationMessage();
    if (validationMessage != null) {
      ToastMessages.alert(message: validationMessage);
      return;
    }

    await context.read<LeadsCubit>().createLead(_buildPayload());
  }

  void _onLeadsStateChanged(BuildContext context, LeadsState state) {
    if (!mounted) {
      return;
    }

    switch (state.leadAssigneesUIState?.status) {
      case Status.ERROR:
        ToastMessages.error(
          message:
              state.leadAssigneesUIState?.errorType?.getText(context) ??
              'Could not load assignees',
        );
      case Status.SUCCESS:
      case Status.LOADING:
      case Status.INITIAL:
      case null:
        break;
    }

    switch (state.createLeadUIState?.status) {
      case Status.SUCCESS:
        final dynamic value = state.createLeadUIState?.data;
        final String message = value is Map && value['message'] is String
            ? value['message'] as String
            : 'Lead created successfully.';
        ToastMessages.success(message: message);
        widget.onSubmit?.call(_buildDraft());
        context.read<LeadsCubit>().resetCreateLeadState();
        if (context.canPop()) {
          context.pop(true);
        }
      case Status.ERROR:
        ToastMessages.error(
          message:
              state.createLeadUIState?.errorType?.getText(context) ??
              'Could not create lead, Please try again later',
        );
        context.read<LeadsCubit>().resetCreateLeadState();
      case Status.LOADING:
      case Status.INITIAL:
      case null:
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
        listenWhen: (LeadsState previous, LeadsState current) =>
            previous.createLeadUIState?.status !=
                current.createLeadUIState?.status ||
            previous.leadAssigneesUIState?.status !=
                current.leadAssigneesUIState?.status,
        listener: _onLeadsStateChanged,
        builder: (BuildContext context, LeadsState state) {
          final List<LeadAssigneeData> assignees =
              state.leadAssigneesUIState?.data?.validAssignees ??
              <LeadAssigneeData>[];
          final bool isLoadingAssignees =
              state.leadAssigneesUIState?.status == Status.LOADING ||
              state.leadAssigneesUIState?.status == null ||
              state.leadAssigneesUIState?.status == Status.INITIAL;
          final bool isSubmitting =
              state.createLeadUIState?.status == Status.LOADING;

          return Scaffold(
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
                            inputFormatters: <TextInputFormatter>[
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
                      children: <Widget>[
                        AppFormField(
                          label: 'Source',
                          isRequired: true,
                          child: AppSelectField(
                            hint: 'Select lead source',
                            sheetTitle: 'Where did this lead come from?',
                            icon: Icons.campaign_outlined,
                            options: LeadSource.labels,
                            value: _source?.label,
                            onChanged: (String value) => setState(
                              () => _source = LeadSource.fromLabel(value),
                            ),
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
                                .map((LeadAssigneeData a) => a.name!)
                                .toList(growable: false),
                            value: _selectedAssignee?.name,
                            onChanged: (String value) {
                              LeadAssigneeData? matched;
                              for (final LeadAssigneeData assignee
                                  in assignees) {
                                if (assignee.name == value) {
                                  matched = assignee;
                                  break;
                                }
                              }
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
                            onChanged: (DateTime value) =>
                                setState(() => _nextFollowUp = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppToggleRow(
                          title: 'Add Quotation',
                          subtitle: 'Capture a price quote with this lead',
                          icon: Icons.request_quote_outlined,
                          value: _addQuotation,
                          onChanged: (bool value) =>
                              setState(() => _addQuotation = value),
                        ),
                        // Off by default, and the fields only exist while it
                        // is on — a lead without a quote stays a short form.
                        if (_addQuotation) ...<Widget>[
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

/// The text fields behind one quotation line.
///
/// The screen owns a list of these — one per line — so each row keeps its own
/// text, and adding or removing a line is a list operation rather than a
/// shuffle of shared controllers.
class QuotationItemControllers {
  QuotationItemControllers();

  final TextEditingController item = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController rate = TextEditingController();
  final TextEditingController taxPercent = TextEditingController(text: '0');

  /// What this row is worth on submit. Blank fields stay null, which is what
  /// makes an untouched row drop out of the saved quotation.
  QuotationItem toItem() => QuotationItem(
    item: item.text,
    quantity: int.tryParse(quantity.text.trim()),
    rate: double.tryParse(rate.text.trim().replaceAll(',', '')),
  );

  /// The API's quotation line shape. The domain model does not carry tax yet,
  /// so it remains an input concern until quote totals support tax as well.
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

/// The quotation half of the capture form, shown only while the toggle is on.
///
/// One address, then any number of item lines inside the same section — the
/// lines are rows within this card, not cards of their own.
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
      children: <Widget>[
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
            // Keyed by identity so removing a middle row does not hand its
            // fields to the row that shifts up into its place.
            key: ObjectKey(items[index]),
            controllers: items[index],
            index: index,
            // The last remaining row cannot be removed: an enabled quotation
            // always keeps one line to type into.
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

/// One item line: product, quantity and rate, with its own remove action.
class NewLeadQuotationItemFields extends StatelessWidget {
  const NewLeadQuotationItemFields({
    super.key,
    required this.controllers,
    required this.index,
    this.onRemove,
  });

  final QuotationItemControllers controllers;
  final int index;

  /// Null on the only remaining line, which hides the remove action.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
          children: <Widget>[
            Expanded(
              child: AppFormField(
                label: 'Quantity',
                bottomSpacing: 0,
                child: AppTextField(
                  hint: '1',
                  controller: controllers.quantity,
                  icon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
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
                  inputFormatters: <TextInputFormatter>[
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
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
        ),
        // Separates this line from the next without turning it into a card.
        if (onRemove != null || index > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Divider(height: 1, color: context.palette.line),
          ),
      ],
    );
  }
}

/// Small red "remove" affordance sitting on an item line's label row.
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
          children: <Widget>[
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
