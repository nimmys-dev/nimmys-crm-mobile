import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/features/dashboard/widgets/dashboard_drawer.dart';
import 'package:nimmys_crm/features/leads/my_leads_screen.dart';
import 'package:nimmys_crm/features/reports/reports_screen.dart';
import 'package:nimmys_crm/features/staff/staff_list_screen.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/auth/app_permission.dart';
import '../../core/auth/user_role.dart';
import '../../core/theme/app_dimens.dart';
import '../../routing/app_route_name.dart';
import '../../service/push_notification/notification_service.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_section_card.dart';
import '../authentication/cubit/session/session_cubit.dart';
import '../profile/cubit/profile/profile_cubit.dart';
import '../profile/model/profile_model.dart';
import '../profile/profile_sheet.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_panels.dart';
import 'widgets/stat_cards.dart';

/// Home screen with bottom navigation tabs.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileCubit>().getProfile();
      }
    });
  }

  String get _greeting {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ---- Tab titles ----
  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Leads';
      case 2:
        return 'Staff';
      case 3:
        return 'Reports';
      default:
        return 'Dashboard';
    }
  }

  // ---- Stat items ----
  static final StatItem _todaysDuty = StatItem(
    label: "Today's My Duty",
    value: '12',
    icon: Icons.fact_check_outlined,
    tone: StatTone.red,
    route: AppRouteName.dutiesFiltered('today'),
  );
  static final StatItem _overdueDuty = StatItem(
    label: 'Overdue Duty',
    value: '5',
    icon: Icons.event_busy_outlined,
    tone: StatTone.ink,
    route: AppRouteName.dutiesFiltered('overdue'),
  );
  static final StatItem _upcomingDuty = StatItem(
    label: 'Upcoming Duty',
    value: '8',
    icon: Icons.schedule_rounded,
    tone: StatTone.red,
    route: AppRouteName.dutiesFiltered('upcoming'),
  );
  static final StatItem _approvalPending = StatItem(
    label: 'Approval Pending',
    value: '3',
    icon: Icons.assignment_turned_in_outlined,
    tone: StatTone.ink,
    route: AppRouteName.approvals,
  );

  static List<StatItem> _dutyStatsFor(UserRole role) {
    return <StatItem>[
      _todaysDuty,
      _overdueDuty,
      _upcomingDuty,
      if (role.canAccessApprovals) _approvalPending,
    ];
  }

  static final List<StatItem> _leads = <StatItem>[
    StatItem(
      label: 'Unattended Leads',
      value: '12',
      icon: Icons.groups_outlined,
      tone: StatTone.red,
      route: AppRouteName.leads,
    ),
    StatItem(
      label: "Today's Follow Up",
      value: '18',
      icon: Icons.person_add_alt_1_outlined,
      tone: StatTone.ink,
      route: AppRouteName.leads,
    ),
    StatItem(
      label: 'Overdue Follow Up',
      value: '7',
      icon: Icons.history_toggle_off_rounded,
      tone: StatTone.ink,
      route: AppRouteName.leads,
    ),
    StatItem(
      label: 'Upcoming Follow Up',
      value: '9',
      icon: Icons.event_available_outlined,
      tone: StatTone.red,
      route: AppRouteName.leads,
    ),
  ];

  // ---- Bottom Nav Items ----
  static const AppNavItem _dashboardNav = AppNavItem(
    label: 'Dashboard',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  );
  static const AppNavItem _leadsNav = AppNavItem(
    label: 'Leads',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups_rounded,
  );
  static const AppNavItem _staffNav = AppNavItem(
    label: 'Staff',
    icon: Icons.groups_2_outlined,
    activeIcon: Icons.groups_2_rounded,
  );
  static const AppNavItem _reportsNav = AppNavItem(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
  );

  static List<AppNavItem> _navItemsFor(UserRole role) {
    return <AppNavItem>[
      _dashboardNav,
      if (role.canViewLeads) _leadsNav,
      if (role.canAccessStaff) _staffNav,
      if (role.hasFullDashboard) _reportsNav,
    ];
  }

  // ---- Tab content builders ----
  Widget _buildDashboardContent(BuildContext context, UserRole role) {
    // This is the original dashboard content (the ListView)
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        SizedBox(height: 50),
        Transform.translate(
          offset: const Offset(0, -22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              children: <Widget>[
                DashboardDutySection(items: _dutyStatsFor(role)),
                DashboardLeadsSection(items: _leads),
                AppSectionCard(
                  child: DashboardTotalsCard(
                    yourLeads: '40',
                    totalLeads: role.can(AppPermission.viewAllLeads)
                        ? '126'
                        : null,
                    onTap: () => context.push(
                      '${AppRouteName.leads}?isAppHeaderRequired=true',
                    ),
                  ),
                ),
                if (role.hasFullDashboard)
                  AppSectionCard(
                    child: Column(
                      children: <Widget>[
                        AppSectionHeader(
                          title: 'Report',
                          actionLabel: 'View All',
                          onAction: () => context.push(AppRouteName.reports),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DashboardReportCard(
                          onTap: () => context.push(AppRouteName.reports),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(int index, UserRole role) {
    switch (index) {
      case 0:
        return _buildDashboardContent(context, role);
      case 1:
        return const MyLeadsScreen(isAppHeaderRequired: false);
      case 2:
        return const StaffListScreen();
      case 3:
        return const ReportsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---- Navigation ----
  void _onNavTap(int index) {
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: BlocBuilder<SessionCubit, SessionState>(
        builder: (BuildContext context, SessionState session) {
          final UserRole role = session.role;
          final List<AppNavItem> navItems = _navItemsFor(role);
          final int navIndex = _navIndex.clamp(0, navItems.length - 1);
          final String tabTitle = _getTabTitle(navIndex);

          return Scaffold(
            key: _scaffoldKey,
            drawer: const DashboardDrawer(),
            backgroundColor: context.palette.canvas,
            body: Column(
              children: <Widget>[
                // Persistent header
                ValueListenableBuilder<int>(
                  valueListenable: NotificationService.unreadNotifications,
                  builder: (BuildContext context, int unread, _) {
                    return BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (BuildContext context, ProfileState state) {
                        final ProfileUser? user =
                            state.profileUIState?.data?.user;
                        return DashboardHeader(
                          onMenuTap: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          userInitials: user?.initials ?? '··',
                          greeting: _greeting,
                          userName: user?.name ?? 'Loading…',
                          notificationCount: unread,
                          onAvatarTap: () => showProfileSheet(context),
                          dashboardText: tabTitle,
                        );
                      },
                    );
                  },
                ),
                // Tab content
                Expanded(
                  child: IndexedStack(
                    index: navIndex,
                    children: navItems.map((item) {
                      final int idx = navItems.indexOf(item);
                      return _buildTabContent(idx, role);
                    }).toList(),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: AppBottomNav(
              items: navItems,
              currentIndex: navIndex,
              onTap: _onNavTap, // <-- now just updates index
              centerAction: role.canCreateLead
                  ? const AppNavItem(label: 'Add Lead', icon: Icons.add_rounded)
                  : null,
              onCenterTap: () => context.push(AppRouteName.leadNew),
            ),
          );
        },
      ),
    );
  }
}

/// "MY DUTIES" card holding the four duty counters in one row.
///
/// Every tile carrying a [StatItem.route] is tappable and opens the duty list
/// on the matching tab.
class DashboardDutySection extends StatelessWidget {
  const DashboardDutySection({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        children: <Widget>[
          AppSectionHeader(
            title: 'My Duties',
            actionLabel: 'View All',
            onAction: () => context.push(AppRouteName.dutiesFiltered('today')),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
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

/// Tap handler for a stat tile, or null when the tile has no screen behind it.
///
/// Shared by both dashboard sections so a counter is wired the same way
/// wherever it appears — and so a tile with no route stays visibly inert
/// instead of swallowing taps.
VoidCallback? openStatRoute(BuildContext context, StatItem item) {
  final String? route = item.route;
  if (route == null) {
    return null;
  }
  return () => context.push(route);
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
          AppSectionHeader(
            title: 'My Leads',
            actionLabel: 'View All',
            onAction: () =>
                context.push('${AppRouteName.leads}?isAppHeaderRequired=false'),
          ),
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
            itemBuilder: (BuildContext context, int index) => LeadStatCard(
              item: items[index],
              onTap: openStatRoute(context, items[index]),
            ),
          ),
        ],
      ),
    );
  }
}
