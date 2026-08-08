import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Split panel showing "Your Leads" against "Total Leads".
///
/// Collapses to the single "Your Leads" tile when [totalLeads] is null, which
/// is what an employee sees — the org-wide total is not theirs to know.
class DashboardTotalsCard extends StatelessWidget {
  const DashboardTotalsCard({
    super.key,
    required this.yourLeads,
    required this.totalLeads,
    this.onTap,
  });

  final String yourLeads;

  /// Null hides the second half of the panel entirely.
  final String? totalLeads;

  /// Opens the leads list. Null leaves the panel as a read-only summary, which
  /// is how the reports screen uses it.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget panel = _buildPanel(context);
    if (onTap == null) {
      return panel;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: panel,
    );
  }

  Widget _buildPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: context.palette.inkGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: DashboardTotalsTile(
              icon: Icons.person_outline_rounded,
              label: 'Your Leads',
              value: yourLeads,
              isAccent: true,
            ),
          ),
          if (totalLeads != null) ...<Widget>[
            Container(
              width: 1,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              color: AppColors.white.withValues(alpha: 0.14),
            ),
            Expanded(
              child: DashboardTotalsTile(
                icon: Icons.layers_outlined,
                label: 'Total Leads',
                value: totalLeads!,
                isAccent: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One half of [DashboardTotalsCard].
class DashboardTotalsTile extends StatelessWidget {
  const DashboardTotalsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isAccent,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isAccent ? AppColors.actionGradient : null,
            color: isAccent ? null : AppColors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 19, color: AppColors.white),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                value,
                style: context.type.statValue.copyWith(
                  color: AppColors.white,
                  fontSize: 23,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: context.type.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.68),
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Performance report entry point.
class DashboardReportCard extends StatelessWidget {
  const DashboardReportCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.palette.redWashSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.palette.redBorder),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.actionGradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 21,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Your Performance', style: context.type.cardTitle),
                  SizedBox(height: 2),
                  Text(
                    'Track your leads and performance',
                    style: context.type.caption,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.red,
            ),
          ],
        ),
      ),
    );
  }
}
