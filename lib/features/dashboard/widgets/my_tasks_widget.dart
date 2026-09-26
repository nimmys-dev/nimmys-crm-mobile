import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/features/dashboard/dashboard_screen.dart';
import 'package:nimmys_crm/features/dashboard/widgets/stat_cards.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';

/// "MY DUTIES" card holding the duty counters.
class DashboardDutySection extends StatelessWidget {
  final String taskTitle;
  final String scope;

  const DashboardDutySection({
    super.key,
    required this.items,
    required this.taskTitle,
    required this.scope,
  });

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionHeader(
            title: taskTitle,
            actionLabel: 'View All',
            onAction: () {
              if (scope == "my_tasks") {
                context.push(AppRouteName.dutiesFiltered(scope: 'my_tasks'));
              } else {
                context.push(AppRouteName.dutiesFiltered(scope: 'all_tasks'));
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int index = 0; index < items.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: 7),
                Expanded(
                  child: DutyStatCard(
                    item: items[index],
                    onTap: openStatRoute(context, items[index]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
