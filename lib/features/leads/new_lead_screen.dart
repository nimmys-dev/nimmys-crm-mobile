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
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

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
    _itemController.dispose();
    _rateController.dispose();
    _quantityController.dispose();
    super.dispose();
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
      item: _itemController.text,
      quantity: int.tryParse(_quantityController.text.trim()),
      rate: double.tryParse(_rateController.text.trim()),
    );
    return quotation.hasContent ? quotation : null;
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
                            itemController: _itemController,
                            quantityController: _quantityController,
                            rateController: _rateController,
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

/// The quotation half of the capture form, shown only while the toggle is on.
class NewLeadQuotationFields extends StatelessWidget {
  const NewLeadQuotationFields({
    super.key,
    required this.addressController,
    required this.itemController,
    required this.quantityController,
    required this.rateController,
  });

  final TextEditingController addressController;
  final TextEditingController itemController;
  final TextEditingController quantityController;
  final TextEditingController rateController;

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
          label: 'Item / Product',
          child: AppTextField(
            hint: 'Which product is being quoted?',
            controller: itemController,
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
                  controller: quantityController,
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
                  controller: rateController,
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
      ],
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
