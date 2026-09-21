import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
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
    required this.overdueFollowUp,
  });

  final String yourLeads;
  final String overdueFollowUp;

  /// Null hides the second half of the panel entirely.
  final String? totalLeads;

  @override
  Widget build(BuildContext context) {
    return _buildPanel(context);
  }

  Widget _buildPanel(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: () => context.push(AppRouteName.viewMyLeads),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: DashboardTotalsTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Your Leads',
                  value: yourLeads,
                  tone: DashboardTotalsTileTone.yourLeads,
                ),
              ),
            ),
            if (totalLeads != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: InkWell(
                  onTap: () => context.push(AppRouteName.viewAllLeads),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: DashboardTotalsTile(
                    icon: Icons.layers_outlined,
                    label: 'Total Leads',
                    value: totalLeads!,
                    tone: DashboardTotalsTileTone.totalLeads,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () => context.push(
            AppRouteName.leadsWithStatus(
              status: 'overdue_followup',
              scope: 'all_leads',
            ),
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: DashboardTotalsTile(
            icon: Icons.history_toggle_off_rounded,
            label: 'All Overdue Follow Up',
            value: overdueFollowUp,
            tone: DashboardTotalsTileTone.overdue,
          ),
        ),
      ],
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
    this.tone = DashboardTotalsTileTone.yourLeads,
  });

  final IconData icon;
  final String label;
  final String value;
  final DashboardTotalsTileTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color tint, Color background) colors = switch (tone) {
      DashboardTotalsTileTone.yourLeads => (
        const Color(0xFFF3A900),
        const Color(0xFFFFF6D9),
      ),
      DashboardTotalsTileTone.totalLeads => (
        const Color(0xFF09AE50),
        const Color(0xFFDFFBEA),
      ),
      DashboardTotalsTileTone.overdue => (
        AppColors.red,
        const Color(0xFFFFE8EC),
      ),
    };
    final Color tint = colors.$1;
    final Color background = colors.$2;
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 13, color: tint),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: context.type.cardTitle.copyWith(fontSize: 9),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: context.type.statValue.copyWith(
                    fontSize: 12,
                    color: context.palette.ink,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: tint, size: 26),
        ],
      ),
    );
  }
}

enum DashboardTotalsTileTone { yourLeads, totalLeads, overdue }

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
