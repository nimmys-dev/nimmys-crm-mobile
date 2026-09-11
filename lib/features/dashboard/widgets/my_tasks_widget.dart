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
          AppSectionHeader(title: taskTitle),
          const SizedBox(height: AppSpacing.sm),

          LayoutBuilder(
            builder: (context, constraints) {
              const double minCardWidth = 80;
              const double spacing = 7;

              final int columns =
                  ((constraints.maxWidth + spacing) / (minCardWidth + spacing))
                      .floor()
                      .clamp(1, items.length);

              final double cardWidth =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

              return Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  spacing: spacing,
                  runSpacing: spacing,
                  children: <Widget>[
                    for (int index = 0; index < items.length; index++)
                      SizedBox(
                        width: cardWidth,
                        child: DutyStatCard(
                          item: items[index],
                          onTap: openStatRoute(context, items[index]),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
