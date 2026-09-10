import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:nimmys_crm/features/duties/cubit/tasks_cubit.dart';
import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';
import 'package:nimmys_crm/shared/widgets/app_avatar.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/shared/widgets/app_gradient_header.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';
import 'package:nimmys_crm/shared/widgets/app_search_field.dart';
import 'package:nimmys_crm/shared/widgets/app_select_field.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

class ApprovalsScreen extends StatefulWidget {
  final String scope;
  const ApprovalsScreen({super.key, required this.scope});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().getLeads(
        filter: 'approvalPending',
        refresh: true,
        scope: widget.scope,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<DashboardCubit>().getLeads(
        filter: 'approvalPending',
        refresh: true,
        scope: widget.scope,
      );
    });
  }

  Future<void> _refresh() async {
    await context.read<DashboardCubit>().getLeads(
      filter: 'approvalPending',
      refresh: true,
      scope: widget.scope,
    );
  }

  void _onScroll() {
    final cubit = context.read<DashboardCubit>();
    final currentState = cubit.state;
    // Only trigger if not already loading, there is a next page, and near bottom
    if (currentState.leadListUIState?.status == Status.LOADING) return;
    final pagination = currentState.leadPagination;
    if (pagination == null || !pagination.hasNextPage) return;
    const threshold = 200.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      cubit.goToLeadPage(pagination.nextPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: context.palette.canvas,
          body: BlocListener<TasksCubit, TasksState>(
            listenWhen: (previous, current) =>
                previous.approveTaskUIState?.status !=
                current.approveTaskUIState?.status,
            listener: (context, state) {
              if (state.approveTaskUIState?.status == Status.SUCCESS) {
                ToastMessages.success(
                  message:
                      state.approveTaskUIState?.data?.message ??
                      'Task approved successfully!',
                );
                context.read<TasksCubit>().resetApproveTaskState();
                _refresh();
                context.read<DashboardCubit>().getDashboardCount();
              } else if (state.approveTaskUIState?.status == Status.ERROR) {
                ToastMessages.error(
                  message:
                      state.approveTaskUIState?.errorType?.getText(context) ??
                      'Failed to approve task.',
                );
                context.read<TasksCubit>().resetApproveTaskState();
              }
            },
            child: BlocConsumer<DashboardCubit, DashboardState>(
              listenWhen: (prev, curr) =>
                  prev.leadListUIState?.status != curr.leadListUIState?.status,
              listener: (context, state) {
                if (state.leadListUIState?.status == Status.ERROR &&
                    (state.leadList?.isEmpty ?? true)) {
                  ToastMessages.error(
                    message:
                        state.leadListUIState?.errorType?.getText(context) ??
                        'Failed to load approval leads.',
                  );
                }
              },
              builder: (context, state) {
                final isLoading =
                    state.leadListUIState?.status == Status.LOADING ||
                    state.leadListUIState?.status == null ||
                    state.leadListUIState?.status == Status.INITIAL;
                final leads = state.leadList ?? <LeadItemData>[];
                final pagination = state.leadPagination;
                final hasMore = pagination?.hasNextPage ?? false;
                final isLoadingMore = state.isLoadingMoreLeads;

                final child = isLoading && leads.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.red,
                          ),
                        ),
                      )
                    : leads.isEmpty
                    ? _EmptyState()
                    : Column(
                        children: [
                          // Count header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.gutter,
                            ),
                            child: _CountHeader(
                              count: leads.length,
                              total: pagination?.total ?? leads.length,
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _refresh,
                              color: AppColors.red,
                              child: ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.gutter,
                                  right: AppSpacing.gutter,
                                  bottom: AppSpacing.xs,
                                ),
                                itemCount: leads.length + 1, // +1 for footer
                                itemBuilder: (context, index) {
                                  if (index == leads.length) {
                                    // Footer
                                    return _buildFooter(hasMore, isLoadingMore);
                                  }
                                  final lead = leads[index];
                                  return ApprovalTile(
                                    lead: lead,
                                    onApprove: lead.id == null
                                        ? null
                                        : () => context
                                              .read<TasksCubit>()
                                              .approveTask(lead.id!),
                                    onReject: () {
                                      ToastMessages.alert(
                                        message:
                                            'Reject functionality coming soon.',
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );

                return Column(
                  children: <Widget>[
                    const AppGradientHeader(
                      title: 'Approvals',
                      eyebrow: 'TEAM',
                      leading: AppBackButton(),
                      actions: <Widget>[],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.md,
                        AppSpacing.gutter,
                        AppSpacing.sm,
                      ),
                      child: AppSearchField(
                        hint: 'Search approvals…',
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    Expanded(child: child),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool hasMore, bool isLoadingMore) {
    if (!hasMore && !isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No more tasks',
            style: TextStyle(fontSize: 12, color: context.palette.muted),
          ),
        ),
      );
    }
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------
// Helper widgets (unchanged)
// ---------------------------------------------------------------------

class _CountHeader extends StatelessWidget {
  const _CountHeader({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 2),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 15,
            color: context.palette.muted,
          ),
          const SizedBox(width: 5),
          Text(
            'Showing $count of $total approval request${total == 1 ? '' : 's'}',
            style: context.type.caption,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: context.palette.redWash,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_outlined,
                size: 32,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nothing to approve',
              style: context.type.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'All requests have been dealt with. Nice work!',
              style: context.type.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ApprovalTile extends StatelessWidget {
  const ApprovalTile({
    super.key,
    required this.lead,
    this.onApprove,
    this.onReject,
  });

  final LeadItemData lead;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  // The approval API returns lead data and does not include a task date.
  // Keep the existing date tag's empty-state presentation until that field is
  // supplied by the endpoint.
  Task get task => Task();

  @override
  Widget build(BuildContext context) {
    final isPending = lead.status?.toLowerCase() != 'approved';

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      accentBorder: isPending,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIconChip(
                icon: isPending
                    ? Icons.hourglass_top_rounded
                    : lead.status?.toLowerCase() == 'approved'
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
                size: 38,
                tone: isPending ? AppIconChipTone.red : AppIconChipTone.ink,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      lead.name?.trim().isNotEmpty == true
                          ? lead.name!.trim()
                          : 'Unnamed Lead',
                      style: context.type.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lead.cleanDescription,
                      style: context.type.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        AppTag(
                          label: lead.assignedTo ?? 'Unassigned',
                          icon: Icons.person_outline_rounded,
                          isAccent: false,
                        ),
                        AppTag(
                          label: task.createdAt != null
                              ? AppDateField.format(
                                  DateTime.parse(task.createdAt!),
                                )
                              : '—',
                          icon: Icons.schedule_rounded,
                          isAccent: false,
                        ),
                        AppTag(
                          label: lead.status?.toUpperCase() ?? 'UNKNOWN',
                          icon: lead.status?.toLowerCase() == 'approved'
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          isAccent: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    height: 46,
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
