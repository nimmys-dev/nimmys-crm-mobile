import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../domain/entities/lead.dart';

/// Card heading with the red rule, icon and an optional trailing action.
class LeadSectionTitle extends StatelessWidget {
  const LeadSectionTitle({
    super.key,
    required this.title,
    required this.icon,
    this.action,
  });

  final String title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(icon, size: 17, color: AppColors.red),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: context.type.cardTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Label-over-value tile used inside the customer details grid.
class LeadDetailTile extends StatelessWidget {
  const LeadDetailTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.isAccent = false,
  });

  final String label;
  final String value;
  final IconData? icon;

  /// Accent tiles use the red wash — reserved for dates that need attention.
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isAccent
            ? context.palette.redWashSoft
            : context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isAccent ? context.palette.redBorder : context.palette.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 12,
                  color: isAccent ? AppColors.red : context.palette.muted,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAccent ? AppColors.red : context.palette.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: context.palette.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Wide tile whose value wraps — for an address, which does not fit the
/// single ellipsised line a [LeadDetailTile] gives.
class LeadDetailBlock extends StatelessWidget {
  const LeadDetailBlock({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 12, color: context.palette.muted),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: context.palette.ink,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// The quotation captured with the lead.
///
/// Rendered only when there is a quotation — see how the details screen
/// guards it — so nothing here has to handle the empty case beyond the
/// individual fields the user chose to skip.
class LeadQuotationDetails extends StatelessWidget {
  const LeadQuotationDetails({super.key, required this.quotation});

  final LeadQuotation quotation;

  /// Indian digit grouping, and paise only when the rate actually has them.
  static String formatRate(double rate) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: rate == rate.roundToDouble() ? 0 : 2,
  ).format(rate);

  @override
  Widget build(BuildContext context) {
    final List<QuotationItem> items = quotation.filledItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LeadDetailBlock(
          label: 'Customer Address',
          value: quotation.customerAddress ?? '—',
          icon: Icons.location_on_outlined,
        ),
        if (items.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          // A table rather than a stack of tiles: a quotation can carry any
          // number of lines, and columns keep them comparable.
          LeadQuotationItemsTable(items: items, total: quotation.total),
        ],
      ],
    );
  }
}

/// The quoted lines, one row each, with a total when the figures allow one.
class LeadQuotationItemsTable extends StatelessWidget {
  const LeadQuotationItemsTable({super.key, required this.items, this.total});

  final List<QuotationItem> items;
  final double? total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Container(
            color: context.palette.inkWash,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 8,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 46,
                  child: Text('ITEM / PRODUCT', style: _headerStyle(context)),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    'QTY',
                    style: _headerStyle(context),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 38,
                  child: Text(
                    'RATE',
                    style: _headerStyle(context),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          for (int index = 0; index < items.length; index++)
            LeadQuotationItemRow(
              item: items[index],
              isLast: index == items.length - 1 && total == null,
            ),
          if (total != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: context.palette.redWashSoft,
                border: Border(top: BorderSide(color: context.palette.line)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text('Total', style: _headerStyle(context))),
                  Text(
                    LeadQuotationDetails.formatRate(total!),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static TextStyle _headerStyle(BuildContext context) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: context.palette.slate,
    letterSpacing: 0.5,
  );
}

/// A single quoted line.
class LeadQuotationItemRow extends StatelessWidget {
  const LeadQuotationItemRow({
    super.key,
    required this.item,
    required this.isLast,
  });

  final QuotationItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.palette.line)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 46,
            child: Text(
              item.item ?? '—',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.palette.ink,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              item.quantity?.toString() ?? '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.palette.slate,
              ),
            ),
          ),
          Expanded(
            flex: 38,
            child: Text(
              item.rate == null
                  ? '—'
                  : LeadQuotationDetails.formatRate(item.rate!),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.palette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One requested product on the lead.
class LeadItemRow extends StatelessWidget {
  const LeadItemRow({super.key, required this.name, this.isLast = false});

  final String name;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.palette.line),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: context.type.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// A logged phone call against the lead.
class CallLogEntry {
  const CallLogEntry({
    required this.outcome,
    required this.remarks,
    required this.calledBy,
    required this.calledAt,
    this.isAnswered = true,
  });

  final String outcome;
  final String remarks;
  final String calledBy;
  final String calledAt;
  final bool isAnswered;
}

/// Renders one [CallLogEntry] as a readable card instead of a cramped table.
class CallLogCard extends StatelessWidget {
  const CallLogCard({super.key, required this.entry, this.onTap});

  final CallLogEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: context.palette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: entry.isAnswered
                        ? context.palette.redWash
                        : context.palette.inkWash,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    entry.isAnswered
                        ? Icons.phone_in_talk_rounded
                        : Icons.phone_missed_rounded,
                    size: 15,
                    color: entry.isAnswered
                        ? AppColors.red
                        : context.palette.ink,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppTag(
                    label: entry.outcome,
                    isAccent: entry.isAnswered,
                  ),
                ),
                Text(
                  entry.calledAt,
                  style: context.type.caption.copyWith(fontSize: 11),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: context.palette.faint,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              entry.remarks,
              style: context.type.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Icon(
                  Icons.person_outline_rounded,
                  size: 13,
                  color: context.palette.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Called by ${entry.calledBy}',
                  style: context.type.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide row of quick actions (call / WhatsApp / note) on the lead detail page.
class LeadQuickActions extends StatelessWidget {
  const LeadQuickActions({super.key, this.onCall, this.onMessage, this.onNote});

  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onNote;

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
            label: 'Message',
            onTap: onMessage,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: LeadQuickAction(
            icon: Icons.note_add_outlined,
            label: 'Note',
            onTap: onNote,
          ),
        ),
      ],
    );
  }
}

/// A single button inside [LeadQuickActions].
class LeadQuickAction extends StatelessWidget {
  const LeadQuickAction({
    super.key,
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isPrimary ? AppColors.actionGradient : null,
            color: isPrimary ? null : context.palette.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isPrimary ? Colors.transparent : context.palette.line,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: isPrimary ? AppColors.white : context.palette.ink,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? AppColors.white : context.palette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
