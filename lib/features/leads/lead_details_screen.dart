import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/core/utils/phone_dialer.dart';
import 'package:nimmys_crm/core/utils/whatsapp_launcher.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/model/lead_details_model.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../data/ui_state/ui_state.dart';
import '../../enum/status.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
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
  int _navIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final int? id = widget.leadId;
      if (id != null) {
        context.read<LeadsCubit>().getLeadDetails(id);
      }
    });
  }

  Future<void> _reload() async {
    final int? id = widget.leadId;
    if (id == null) {
      return;
    }
    await context.read<LeadsCubit>().getLeadDetails(id);
  }

  void _onLeadDetailsStateChanged(BuildContext context, LeadsState state) {
    final UIState<LeadDetailsSuccess>? uiState = state.leadDetailsUIState;
    if (uiState?.status != Status.ERROR) {
      return;
    }
    ToastMessages.error(
      message:
          uiState?.errorType?.getText(context) ?? 'Failed to load lead details',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: BlocConsumer<LeadsCubit, LeadsState>(
        listenWhen: (LeadsState previous, LeadsState current) =>
            previous.leadDetailsUIState?.status !=
            current.leadDetailsUIState?.status,
        listener: _onLeadDetailsStateChanged,
        builder: (BuildContext context, LeadsState state) {
          final LeadDetailsData? lead = state.leadDetailsUIState?.data?.data;
          final String eyebrow =
              lead?.reference != null && lead!.reference!.trim().isNotEmpty
              ? lead.reference!.trim()
              : (widget.leadId != null
                    ? 'LEAD #${widget.leadId}'
                    : 'LEAD DETAILS');

          return Scaffold(
            backgroundColor: context.palette.canvas,
            body: Column(
              children: <Widget>[
                AppGradientHeader(
                  title: 'Lead Details',
                  eyebrow: eyebrow,
                  leading: const AppBackButton(),
                  actions: <Widget>[
                    AppAvatar(initials: lead?.initials ?? 'LD'),
                  ],
                ),
                Expanded(
                  child: _LeadDetailsBody(
                    leadId: widget.leadId,
                    state: state,
                    onRetry: _reload,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: AppBottomNav(
              items: const <AppNavItem>[
                AppNavItem(
                  label: 'Dashboard',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                ),
                AppNavItem(
                  label: 'Leads',
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups_rounded,
                ),
                AppNavItem(
                  label: 'Calendar',
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                ),
                AppNavItem(
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                ),
              ],
              currentIndex: _navIndex,
              onTap: (int index) => setState(() => _navIndex = index),
              centerAction: const AppNavItem(
                label: 'Add',
                icon: Icons.add_rounded,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LeadDetailsBody extends StatelessWidget {
  const _LeadDetailsBody({
    required this.leadId,
    required this.state,
    required this.onRetry,
  });

  final int? leadId;
  final LeadsState state;
  final Future<void> Function() onRetry;

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
          // ⬇️ NEW: Quotation Section (shown only if quotation exists)
          if (quotation != null) ...[
            const SizedBox(height: AppSpacing.md),
            QuotationCard(quotation: quotation),
          ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.description ?? 'Item',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '× ${item.quantity ?? '1'}',
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '₹ ${item.amount ?? '0.00'}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
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
