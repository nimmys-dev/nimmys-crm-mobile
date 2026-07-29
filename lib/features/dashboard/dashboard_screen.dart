import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_section_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_panels.dart';
import 'widgets/stat_cards.dart';

/// Home screen: duty counters, lead counters, totals and the report shortcut.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  static const List<StatItem> _duties = <StatItem>[
    StatItem(
      label: "Today's My Duty",
      value: '12',
      icon: Icons.fact_check_outlined,
      tone: StatTone.red,
    ),
    StatItem(
      label: 'Overdue Duty',
      value: '5',
      icon: Icons.event_busy_outlined,
      tone: StatTone.ink,
    ),
    StatItem(
      label: 'Upcoming Duty',
      value: '8',
      icon: Icons.schedule_rounded,
      tone: StatTone.red,
    ),
    StatItem(
      label: 'Approval Pending',
      value: '3',
      icon: Icons.assignment_turned_in_outlined,
      tone: StatTone.ink,
    ),
  ];

  static const List<StatItem> _leads = <StatItem>[
    StatItem(
      label: 'Unattended Leads',
      value: '12',
      icon: Icons.groups_outlined,
      tone: StatTone.red,
    ),
    StatItem(
      label: "Today's Follow Up",
      value: '18',
      icon: Icons.person_add_alt_1_outlined,
      tone: StatTone.ink,
    ),
    StatItem(
      label: 'Overdue Follow Up',
      value: '7',
      icon: Icons.history_toggle_off_rounded,
      tone: StatTone.ink,
    ),
    StatItem(
      label: 'Upcoming Follow Up',
      value: '9',
      icon: Icons.event_available_outlined,
      tone: StatTone.red,
    ),
  ];

  static const List<AppNavItem> _navItems = <AppNavItem>[
    AppNavItem(
      label: 'Dashboard',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    AppNavItem(
      label: 'My Duty',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
    ),
    AppNavItem(
      label: 'Leads',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    AppNavItem(
      label: 'Reports',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DashboardHeader(
              userInitials: 'AB',
              greeting: 'Good morning',
              userName: 'Abin Babu',
              notificationCount: 3,
            ),
            Transform.translate(
              offset: const Offset(0, -22),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                child: Column(
                  children: <Widget>[
                    const DashboardDutySection(items: _duties),
                    const DashboardLeadsSection(items: _leads),
                    const AppSectionCard(
                      child: DashboardTotalsCard(
                        yourLeads: '40',
                        totalLeads: '126',
                      ),
                    ),
                    AppSectionCard(
                      child: Column(
                        children: const <Widget>[
                          AppSectionHeader(
                            title: 'Report',
                            actionLabel: 'View All',
                          ),
                          SizedBox(height: AppSpacing.sm),
                          DashboardReportCard(),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          items: _navItems,
          currentIndex: _navIndex,
          onTap: (int index) => setState(() => _navIndex = index),
          centerAction: const AppNavItem(
            label: 'Add Lead',
            icon: Icons.add_rounded,
          ),
        ),
      ),
    );
  }
}

/// "MY DUTIES" card holding the four duty counters in one row.
class DashboardDutySection extends StatelessWidget {
  const DashboardDutySection({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        children: <Widget>[
          const AppSectionHeader(title: 'My Duties', actionLabel: 'View All'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              for (int index = 0; index < items.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: 7),
                Expanded(child: DutyStatCard(item: items[index])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// "MY LEADS" card holding the four lead counters as a 2×2 grid.
class DashboardLeadsSection extends StatelessWidget {
  const DashboardLeadsSection({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        children: <Widget>[
          const AppSectionHeader(title: 'My Leads', actionLabel: 'View All'),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              mainAxisExtent: 134,
            ),
            itemBuilder: (BuildContext context, int index) =>
                LeadStatCard(item: items[index]),
          ),
        ],
      ),
    );
  }
}
