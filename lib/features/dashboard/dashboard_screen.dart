import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

/// Home screen: duty counters, lead counters, totals and the report shortcut.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    // Named header, real account. Cached after the first call, so returning to
    // the dashboard does not re-hit the API — the profile sheet forces a refresh
    // when the details actually matter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileCubit>().getProfile();
      }
    });
  }

  /// "Good morning" until noon, "Good afternoon" until 17:00, "Good evening"
  /// after — the header greeted every user with "Good morning" before.
  String get _greeting {
    final int hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

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

  /// Approvals are an admin/manager concern, so the counter that leads into
  /// them is not shown to an employee at all — a tile they can never act on is
  /// noise at best and an invitation at worst.
  static List<StatItem> _dutyStatsFor(UserRole role) {
    return <StatItem>[
      _todaysDuty,
      _overdueDuty,
      _upcomingDuty,
      if (role.canAccessApprovals) _approvalPending,
    ];
  }

  /// The "My Leads" tiles. All four open the leads list except today's
  /// follow-up, which has a screen of its own already.
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
      route: AppRouteName.followUpToday,
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

  static const AppNavItem _dashboardNav = AppNavItem(
    label: 'Dashboard',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  );
  static final AppNavItem _dutyNav = AppNavItem(
    label: 'My Duty',
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment_rounded,
    route: AppRouteName.dutiesFiltered('today'),
  );
  static const AppNavItem _leadsNav = AppNavItem(
    label: 'Leads',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups_rounded,
    route: AppRouteName.leads,
  );
  static const AppNavItem _staffNav = AppNavItem(
    label: 'Staff',
    icon: Icons.groups_2_outlined,
    activeIcon: Icons.groups_2_rounded,
    route: AppRouteName.staffList,
  );
  static const AppNavItem _reportsNav = AppNavItem(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    route: AppRouteName.reports,
  );

  /// Destinations the role can actually reach. Reports is the org-wide
  /// performance view, so it follows the full-dashboard permission; duties and
  /// leads stay for everyone because both scope themselves to "mine" for an
  /// employee. Staff is admin/manager only — it is the one destination here
  /// that currently has a screen behind it.
  static List<AppNavItem> _navItemsFor(UserRole role) {
    return <AppNavItem>[
      _dashboardNav,
      if (role.canViewTasks) _dutyNav,
      if (role.canViewLeads) _leadsNav,
      if (role.canAccessStaff) _staffNav,
      if (role.hasFullDashboard) _reportsNav,
    ];
  }

  /// Items that own a route navigate; Dashboard is the screen already showing,
  /// so it only moves the selection.
  void _onNavTap(BuildContext context, List<AppNavItem> items, int index) {
    final String? route = items[index].route;
    if (route != null) {
      context.push(route);
      return;
    }
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
          // The item list shrinks with the role, so a stale index from a
          // previous session could point past the end of it.
          final int navIndex = _navIndex.clamp(0, navItems.length - 1);

          return Scaffold(
            backgroundColor: context.palette.canvas,
            body: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // The bell badge tracks the same counter as the launcher badge, so
                // the two never disagree.
                ValueListenableBuilder<int>(
                  valueListenable: NotificationService.unreadNotifications,
                  builder: (BuildContext context, int unread, _) {
                    return BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (BuildContext context, ProfileState state) {
                        final ProfileUser? user =
                            state.profileUIState?.data?.user;
                        return DashboardHeader(
                          // Placeholders only until the profile call lands; the
                          // header is drawn before the response either way.
                          userInitials: user?.initials ?? '··',
                          greeting: _greeting,
                          userName: user?.name ?? 'Loading…',
                          notificationCount: unread,
                          onAvatarTap: () => showProfileSheet(context),
                        );
                      },
                    );
                  },
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    child: Column(
                      children: <Widget>[
                        DashboardDutySection(items: _dutyStatsFor(role)),
                        DashboardLeadsSection(items: _leads),
                        AppSectionCard(
                          // "Total Leads" is the org-wide figure. An employee sees
                          // their own count only, so the tile is dropped rather
                          // than shown blank.
                          child: DashboardTotalsCard(
                            yourLeads: '40',
                            totalLeads: role.can(AppPermission.viewAllLeads)
                                ? '126'
                                : null,
                            onTap: () => context.push(AppRouteName.leads),
                          ),
                        ),
                        // The performance report spans the whole team.
                        if (role.hasFullDashboard)
                          AppSectionCard(
                            child: Column(
                              children: <Widget>[
                                AppSectionHeader(
                                  title: 'Report',
                                  actionLabel: 'View All',
                                  onAction: () =>
                                      context.push(AppRouteName.reports),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                DashboardReportCard(
                                  onTap: () =>
                                      context.push(AppRouteName.reports),
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
            ),
            bottomNavigationBar: AppBottomNav(
              items: navItems,
              currentIndex: navIndex,
              onTap: (int index) => _onNavTap(context, navItems, index),
              // Lead capture is the one create action an employee keeps, so the
              // centre button follows the permission rather than the role.
              centerAction: role.canCreateLead
                  ? const AppNavItem(label: 'Add Lead', icon: Icons.add_rounded)
                  : null,
              // Navigating by name, not by pushing the widget: the router's
              // permission guard only runs on named routes.
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
            onAction: () => context.push(AppRouteName.leads),
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
