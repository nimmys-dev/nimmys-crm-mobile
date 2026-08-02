import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/phone_dialer.dart';
import '../../../shared/widgets/app_avatar.dart';

/// One row of the follow-up list.
class FollowUpEntry {
  const FollowUpEntry({
    required this.name,
    required this.mobile,
    required this.requiredItems,
    required this.nextFollowUp,
    this.isPriority = false,
  });

  final String name;
  final String mobile;
  final String requiredItems;
  final String nextFollowUp;

  /// Priority rows get the red treatment on their initial bubble and date.
  final bool isPriority;
}

/// Card-wrapped list of today's follow-ups.
///
/// This was a four-column table. On a 360dp phone those columns left the date
/// about 50dp of width, so every `12-05-2024` came out clipped — and the
/// columns only got narrower as text scale went up. The row is now two zones:
/// a stacked customer block that takes the remaining width, and a fixed call
/// button. Nothing competes for horizontal space, so nothing truncates.
class FollowUpTable extends StatelessWidget {
  const FollowUpTable({
    super.key,
    required this.entries,
    this.onEntryTap,
    this.onCall,
  });

  final List<FollowUpEntry> entries;
  final ValueChanged<FollowUpEntry>? onEntryTap;

  /// Overrides what the call button does — useful once calls need logging
  /// against the lead. Left null, the button opens the platform dialer.
  final ValueChanged<FollowUpEntry>? onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.palette.line),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          const FollowUpTableHeader(),
          for (int index = 0; index < entries.length; index++)
            FollowUpTableRow(
              entry: entries[index],
              isLast: index == entries.length - 1,
              onTap: onEntryTap == null
                  ? null
                  : () => onEntryTap!(entries[index]),
              onCall: onCall == null ? null : () => onCall!(entries[index]),
            ),
          if (entries.isEmpty) const FollowUpEmptyState(),
        ],
      ),
    );
  }
}

/// Gradient heading strip above the rows.
class FollowUpTableHeader extends StatelessWidget {
  const FollowUpTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 11,
      ),
      child: Row(
        children: const <Widget>[
          Expanded(
            child: FollowUpHeaderCell(
              label: 'CUSTOMER',
              icon: Icons.person_outline_rounded,
            ),
          ),
          FollowUpHeaderCell(label: 'CALL', icon: Icons.call_outlined),
        ],
      ),
    );
  }
}

/// A single heading cell with its icon.
class FollowUpHeaderCell extends StatelessWidget {
  const FollowUpHeaderCell({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: AppColors.white.withValues(alpha: 0.75)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: context.type.tableHeader,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// One data row of [FollowUpTable].
class FollowUpTableRow extends StatelessWidget {
  const FollowUpTableRow({
    super.key,
    required this.entry,
    required this.isLast,
    this.onTap,
    this.onCall,
  });

  final FollowUpEntry entry;
  final bool isLast;
  final VoidCallback? onTap;

  /// Null means "just open the dialer" — see [FollowUpTable.onCall].
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: palette.line)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppInitialBubble(
              letter: entry.name,
              size: 34,
              isAccent: entry.isPriority,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.requiredItems,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.slate,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Wrap, not Row: at large text scales the number and the
                  // date drop onto separate lines instead of being clipped.
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    children: <Widget>[
                      FollowUpMetaChip(
                        icon: Icons.call_outlined,
                        label: entry.mobile,
                      ),
                      FollowUpMetaChip(
                        icon: Icons.event_rounded,
                        label: entry.nextFollowUp,
                        isAccent: entry.isPriority,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            FollowUpCallButton(
              name: entry.name,
              mobile: entry.mobile,
              onPressed: onCall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon + value pair used for the mobile number and the next follow-up date.
class FollowUpMetaChip extends StatelessWidget {
  const FollowUpMetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.isAccent = false,
  });

  final IconData icon;
  final String label;

  /// Accent meta is red — the treatment priority rows used to get on the date.
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final Color tint = isAccent ? AppColors.red : context.palette.muted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: tint),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isAccent ? AppColors.red : context.palette.slate,
          ),
        ),
      ],
    );
  }
}

/// Round red call button at the end of a follow-up row.
class FollowUpCallButton extends StatelessWidget {
  const FollowUpCallButton({
    super.key,
    required this.name,
    required this.mobile,
    this.onPressed,
    this.size = 38,
  });

  final String name;
  final String mobile;

  /// Null falls back to [PhoneDialer.call] with [mobile].
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Call $name',
      child: Material(
        color: context.palette.redWash,
        shape: CircleBorder(
          side: BorderSide(color: context.palette.redBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? () => PhoneDialer.call(context, mobile),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.call_rounded,
              size: size * 0.47,
              color: AppColors.red,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when there is nothing to follow up on.
class FollowUpEmptyState extends StatelessWidget {
  const FollowUpEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.event_available_outlined,
            size: 34,
            color: context.palette.faint,
          ),
          SizedBox(height: AppSpacing.xs),
          Text('No follow ups for this day', style: context.type.bodyMuted),
        ],
      ),
    );
  }
}
