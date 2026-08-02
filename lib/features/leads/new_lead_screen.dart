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
  static const List<String> _assignees = <String>[
    'Abin Babu',
    'Sejun Thomas',
    'Sajeesh Kumar',
    'Ajith Canon',
  ];

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _requirementController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  /// One controller set per quotation line. Starts with a single row, which
  /// is also the minimum while the quotation toggle is on.
  final List<QuotationItemControllers> _quotationItems =
      <QuotationItemControllers>[QuotationItemControllers()];

  String? _assignee;
  LeadSource? _source;
  DateTime? _nextFollowUp;
  bool _addQuotation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    _requirementController.dispose();
    _addressController.dispose();
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
    return quotation.hasContent
        ? LeadQuotation(
            customerAddress: quotation.customerAddress,
            items: quotation.filledItems,
          )
        : null;
  }

  /// Everything the form knows, in the shape a create actually posts.
  ///
  /// The assignee is deliberately absent: `assignedToId` wants an employee
  /// id and this screen's picker only has display names to offer.
  LeadDraft _buildDraft() => LeadDraft(
    name: _nameController.text,
    mobile: _mobileController.text,
    source: _source,
    quotation: _quotation,
    requiredItems: _requirementController.text.trim().isEmpty
        ? null
        : _requirementController.text.trim(),
    nextFollowUpAt: _nextFollowUp,
  );

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final LeadDraft draft = _buildDraft();
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isSubmitting = false);
      widget.onSubmit?.call(draft);
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

  /// What this row is worth on submit. Blank fields stay null, which is what
  /// makes an untouched row drop out of the saved quotation.
  QuotationItem toItem() => QuotationItem(
    item: item.text,
    quantity: int.tryParse(quantity.text.trim()),
    rate: double.tryParse(rate.text.trim()),
  );

  void dispose() {
    item.dispose();
    quantity.dispose();
    rate.dispose();
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
    required this.items,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  final TextEditingController addressController;
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
                    // Digits with at most one decimal point, so `double.parse`
                    // on save cannot fail on what the field allowed.
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
              ),
            ),
          ],
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
