import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
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

/// Column widths shared by the header and every data row so they stay aligned.
class FollowUpColumnFlex {
  const FollowUpColumnFlex._();

  static const int name = 30;
  static const int mobile = 26;
  static const int items = 26;
  static const int followUp = 24;
}

/// Card-wrapped table listing today's follow-ups.
class FollowUpTable extends StatelessWidget {
  const FollowUpTable({super.key, required this.entries, this.onEntryTap});

  final List<FollowUpEntry> entries;
  final ValueChanged<FollowUpEntry>? onEntryTap;

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
            ),
          if (entries.isEmpty) const FollowUpEmptyState(),
        ],
      ),
    );
  }
}

/// Gradient column headings.
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
            flex: FollowUpColumnFlex.name,
            child: FollowUpHeaderCell(
              label: 'NAME',
              icon: Icons.person_outline_rounded,
            ),
          ),
          Expanded(
            flex: FollowUpColumnFlex.mobile,
            child: FollowUpHeaderCell(
              label: 'MOBILE',
              icon: Icons.call_outlined,
            ),
          ),
          Expanded(
            flex: FollowUpColumnFlex.items,
            child: FollowUpHeaderCell(
              label: 'ITEMS',
              icon: Icons.inventory_2_outlined,
            ),
          ),
          Expanded(
            flex: FollowUpColumnFlex.followUp,
            child: FollowUpHeaderCell(label: 'NEXT', icon: Icons.event_rounded),
          ),
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
  });

  final FollowUpEntry entry;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: context.palette.line)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: FollowUpColumnFlex.name,
              child: Row(
                children: <Widget>[
                  AppInitialBubble(
                    letter: entry.name,
                    size: 28,
                    isAccent: entry.isPriority,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      entry.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: context.palette.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: FollowUpColumnFlex.mobile,
              child: Text(
                entry.mobile,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.palette.slate,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: FollowUpColumnFlex.items,
              child: Text(
                entry.requiredItems,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.palette.ink,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: FollowUpColumnFlex.followUp,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      entry.nextFollowUp,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: entry.isPriority
                            ? AppColors.red
                            : context.palette.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: context.palette.faint,
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
