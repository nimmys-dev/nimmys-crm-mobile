import 'package:flutter/material.dart';
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
import 'package:nimmys_crm/features/dashboard/model/lead_count_model.dart';
import 'package:nimmys_crm/features/dashboard/widgets/dashboard_panels.dart';
import 'package:nimmys_crm/features/dashboard/widgets/my_tasks_widget.dart';
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
    super.initState();
    context.read<DashboardCubit>().getDashboardCount();
    context.read<DashboardCubit>().getLeadCount();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardCubit, DashboardState>(
      listenWhen: (prev, curr) =>
          prev.dashboardCountUIState?.status !=
              curr.dashboardCountUIState?.status ||
          prev.leadCountUIState?.status != curr.leadCountUIState?.status,
      listener: (context, state) {
        if (state.dashboardCountUIState?.status == Status.ERROR) {
          ToastMessages.error(
            message:
                state.dashboardCountUIState?.errorType?.getText(context) ??
                'Failed to load dashboard data',
          );
        }
        if (state.leadCountUIState?.status == Status.ERROR) {
          ToastMessages.error(
            message:
                state.leadCountUIState?.errorType?.getText(context) ??
                'Failed to load lead data',
          );
        }
      },
      builder: (context, state) {
        // ---- Duty counts ----
        final dutyState = state.dashboardCountUIState;
        final isLoadingDuty =
            dutyState?.status == Status.LOADING ||
            dutyState?.status == null ||
            dutyState?.status == Status.INITIAL;
        final counts = dutyState?.data;

        // ---- Lead counts ----
        final leadState = state.leadCountUIState;
        final isLoadingLead =
            leadState?.status == Status.LOADING ||
            leadState?.status == null ||
            leadState?.status == Status.INITIAL;
        final leadCounts = leadState?.data?.data?.counts;

        final isLoading = isLoadingDuty || isLoadingLead;

        // Build stat items
        final myDutyStats = _buildMyDutyStats(widget.role, counts);
        final allTaskStats = _buildAllDutyStats(widget.role, counts);
        final myLeadStats = _buildMyLeadStats(leadCounts);
        final allLeadStats = _buildAllLeadStats(leadCounts);
        final yourLeads = leadCounts?.myLeads?.yourLeads?.toString() ?? '0';
        final totalLeads = widget.role.can(AppPermission.viewAllLeads)
            ? leadCounts?.myLeads?.totalLeads?.toString() ?? '0'
            : null;

        Future<void> refreshDashboard() async {
          await context.read<DashboardCubit>().getDashboardCount();
          await context.read<DashboardCubit>().getLeadCount();
        }

        return RefreshIndicator(
          onRefresh: refreshDashboard,
          color: AppColors.red,
          child: ListView(
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
                        DashboardDutySection(
                          items: myDutyStats,
                          taskTitle: 'My Tasks',
                        ),
                        Visibility(
                          visible:
                              UserRole.admin == widget.role ||
                              UserRole.manager == widget.role,
                          child: DashboardDutySection(
                            items: allTaskStats,
                            taskTitle: 'All Tasks',
                          ),
                        ),
                        DashboardLeadsSection(
                          items: myLeadStats,
                          title: 'My Leads',
                        ),
                        Visibility(
                          visible:
                              UserRole.admin == widget.role ||
                              UserRole.manager == widget.role,
                          child: DashboardLeadsSection(
                            items: allLeadStats,
                            title: 'All Leads',
                          ),
                        ),
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
          ),
        );
      },
    );
  }

  // Helper to build duty stat items (from DashboardCount)
  List<StatItem> _buildMyDutyStats(UserRole role, DashboardCount? counts) {
    final today = counts?.data?.counts?.myTasks?.todayDuty?.toString() ?? '0';
    final overdue =
        counts?.data?.counts?.myTasks?.overdueDuty?.toString() ?? '0';
    final upcoming =
        counts?.data?.counts?.myTasks?.upcomingDuty?.toString() ?? '0';
    final approval =
        counts?.data?.counts?.myTasks?.approvalPending?.toString() ?? '0';

    return [
      StatItem(
        label: "Today's My Duty",
        value: today,
        icon: Icons.fact_check_outlined,
        tone: StatTone.red,
        route: AppRouteName.dutiesFiltered('ongoing'),
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

  // Helper to build duty stat items (from DashboardCount)
  List<StatItem> _buildAllDutyStats(UserRole role, DashboardCount? counts) {
    final today = counts?.data?.counts?.allTasks?.todayDuty?.toString() ?? '0';
    final overdue =
        counts?.data?.counts?.allTasks?.overdueDuty?.toString() ?? '0';
    final upcoming =
        counts?.data?.counts?.allTasks?.upcomingDuty?.toString() ?? '0';
    final approval =
        counts?.data?.counts?.allTasks?.approvalPending?.toString() ?? '0';

    return [
      StatItem(
        label: "Today's All Duty",
        value: today,
        icon: Icons.fact_check_outlined,
        tone: StatTone.red,
        route: AppRouteName.dutiesFiltered('ongoing'),
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

  // Helper to build lead stat items (from LeadCounts)
  List<StatItem> _buildMyLeadStats(LeadCounts? leadCounts) {
    final unattended = leadCounts?.myLeads?.unattended?.toString() ?? '0';
    final todayFollow = leadCounts?.myLeads?.todayFollowup?.toString() ?? '0';
    final overdueFollow =
        leadCounts?.myLeads?.overdueFollowup?.toString() ?? '0';
    final upcomingFollow =
        leadCounts?.myLeads?.upcomingFollowup?.toString() ?? '0';

    return [
      StatItem(
        label: 'Unattended Leads',
        value: unattended,
        icon: Icons.groups_outlined,
        tone: StatTone.red,
        route: AppRouteName.leadsWithStatus('open'),
      ),
      StatItem(
        label: "Today's Follow Up",
        value: todayFollow,
        icon: Icons.person_add_alt_1_outlined,
        tone: StatTone.ink,
        route: AppRouteName.leadsWithStatus('today'),
      ),
      StatItem(
        label: 'Overdue Follow Up',
        value: overdueFollow,
        icon: Icons.history_toggle_off_rounded,
        tone: StatTone.ink,
        route: AppRouteName.leadsWithStatus('overdue'),
      ),
      StatItem(
        label: 'Upcoming Follow Up',
        value: upcomingFollow,
        icon: Icons.event_available_outlined,
        tone: StatTone.red,
        route: AppRouteName.leadsWithStatus('upcoming'),
      ),
    ];
  }

  // Helper to build lead stat items (from LeadCounts)
  List<StatItem> _buildAllLeadStats(LeadCounts? leadCounts) {
    final unattended = leadCounts?.allLeads?.unattended?.toString() ?? '0';
    final todayFollow = leadCounts?.allLeads?.todayFollowup?.toString() ?? '0';
    final overdueFollow =
        leadCounts?.allLeads?.overdueFollowup?.toString() ?? '0';
    final upcomingFollow =
        leadCounts?.allLeads?.upcomingFollowup?.toString() ?? '0';

    return [
      StatItem(
        label: 'Unattended Leads',
        value: unattended,
        icon: Icons.groups_outlined,
        tone: StatTone.red,
        route: AppRouteName.leadsWithStatus('open'),
      ),
      StatItem(
        label: "Today's Follow Up",
        value: todayFollow,
        icon: Icons.person_add_alt_1_outlined,
        tone: StatTone.ink,
        route: AppRouteName.leadsWithStatus('today'),
      ),
      StatItem(
        label: 'Overdue Follow Up',
        value: overdueFollow,
        icon: Icons.history_toggle_off_rounded,
        tone: StatTone.ink,
        route: AppRouteName.leadsWithStatus('overdue'),
      ),
      StatItem(
        label: 'Upcoming Follow Up',
        value: upcomingFollow,
        icon: Icons.event_available_outlined,
        tone: StatTone.red,
        route: AppRouteName.leadsWithStatus('upcoming'),
      ),
    ];
  }
}
