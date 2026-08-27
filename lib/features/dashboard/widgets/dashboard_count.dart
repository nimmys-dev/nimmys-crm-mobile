import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/core/auth/app_permission.dart';
import 'package:nimmys_crm/core/auth/user_role.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:nimmys_crm/features/dashboard/dashboard_screen.dart';
import 'package:nimmys_crm/features/dashboard/model/dashboard_count_model.dart';
import 'package:nimmys_crm/features/dashboard/widgets/dashboard_panels.dart';
import 'package:nimmys_crm/features/dashboard/widgets/stat_cards.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key, required this.role});

  final UserRole role;

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  @override
  void initState() {
    // TODO: implement initState
    context.read<DashboardCubit>().getDashboardCount();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardCubit, DashboardState>(
      listener: (context, state) {
        if (state.dashboardCountUIState?.status == Status.ERROR) {
          ToastMessages.error(
            message:
                state.dashboardCountUIState?.errorType?.getText(context) ??
                'Failed to load dashboard data',
          );
        }
      },
      builder: (context, state) {
        final countState = state.dashboardCountUIState;
        final isLoading =
            countState?.status == Status.LOADING ||
            countState?.status == null ||
            countState?.status == Status.INITIAL;
        final counts = countState?.data;

        // Build stat items from counts
        final dutyStats = _buildDutyStats(widget.role, counts);
        final leadStats = _buildLeadStats(counts);
        final yourLeads = counts?.data?.approvalPending?.toString() ?? '0';
        final totalLeads = widget.role.can(AppPermission.viewAllLeads)
            ? counts?.data?.approvalPending?.toString() ?? '0'
            : null;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 50),
            Transform.translate(
              offset: const Offset(0, -22),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                child: Column(
                  children: [
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.red,
                          ),
                        ),
                      )
                    else ...[
                      DashboardDutySection(items: dutyStats),
                      DashboardLeadsSection(items: leadStats),
                      AppSectionCard(
                        child: DashboardTotalsCard(
                          yourLeads: yourLeads,
                          totalLeads: totalLeads,
                          onTap: () => context.push(
                            '${AppRouteName.leads}?isAppHeaderRequired=true',
                          ),
                        ),
                      ),
                      if (widget.role.hasFullDashboard)
                        AppSectionCard(
                          child: Column(
                            children: [
                              AppSectionHeader(
                                title: 'Report',
                                actionLabel: 'View All',
                                onAction: () => context.push(
                                  '${AppRouteName.reports}?isAppHeaderRequired=true',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              DashboardReportCard(
                                onTap: () => context.push(
                                  '${AppRouteName.reports}?isAppHeaderRequired=true',
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper to build duty stat items
  List<StatItem> _buildDutyStats(UserRole role, DashboardCount? counts) {
    final today = counts?.data?.todayDuty?.toString() ?? '0';
    final overdue = counts?.data?.overdueDuty?.toString() ?? '0';
    final upcoming = counts?.data?.upcomingDuty?.toString() ?? '0';
    final approval = counts?.data?.approvalPending?.toString() ?? '0';

    return [
      StatItem(
        label: "Today's My Duty",
        value: today,
        icon: Icons.fact_check_outlined,
        tone: StatTone.red,
        route: AppRouteName.dutiesFiltered('today'),
      ),
      StatItem(
        label: 'Overdue Duty',
        value: overdue,
        icon: Icons.event_busy_outlined,
        tone: StatTone.ink,
        route: AppRouteName.dutiesFiltered('overdue'),
      ),
      StatItem(
        label: 'Upcoming Duty',
        value: upcoming,
        icon: Icons.schedule_rounded,
        tone: StatTone.red,
        route: AppRouteName.dutiesFiltered('upcoming'),
      ),
      if (role.canAccessApprovals)
        StatItem(
          label: 'Approval Pending',
          value: approval,
          icon: Icons.assignment_turned_in_outlined,
          tone: StatTone.ink,
          route: AppRouteName.approvals,
        ),
    ];
  }

  // Helper to build lead stat items
  List<StatItem> _buildLeadStats(DashboardCount? counts) {
    final unattended = counts?.data?.approvalPending?.toString() ?? '0';
    final todayFollow = counts?.data?.approvalPending?.toString() ?? '0';
    final overdueFollow = counts?.data?.approvalPending?.toString() ?? '0';
    final upcomingFollow = counts?.data?.approvalPending?.toString() ?? '0';

    return [
      StatItem(
        label: 'Unattended Leads',
        value: unattended,
        icon: Icons.groups_outlined,
        tone: StatTone.red,
        route: AppRouteName.leads,
      ),
      StatItem(
        label: "Today's Follow Up",
        value: todayFollow,
        icon: Icons.person_add_alt_1_outlined,
        tone: StatTone.ink,
        route: AppRouteName.leads,
      ),
      StatItem(
        label: 'Overdue Follow Up',
        value: overdueFollow,
        icon: Icons.history_toggle_off_rounded,
        tone: StatTone.ink,
        route: AppRouteName.leads,
      ),
      StatItem(
        label: 'Upcoming Follow Up',
        value: upcomingFollow,
        icon: Icons.event_available_outlined,
        tone: StatTone.red,
        route: AppRouteName.leads,
      ),
    ];
  }
}
