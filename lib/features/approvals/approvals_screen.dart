import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/duties/cubit/tasks_cubit.dart';
import 'package:nimmys_crm/features/duties/model/get_all_pending_task_model.dart';
import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';
import 'package:nimmys_crm/shared/widgets/app_avatar.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/shared/widgets/app_gradient_header.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';
import 'package:nimmys_crm/shared/widgets/app_segmented_tabs.dart';
import 'package:nimmys_crm/shared/widgets/app_search_field.dart';
import 'package:nimmys_crm/shared/widgets/app_select_field.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

/// Filter status for approval tabs.
enum ApprovalFilter { pending, approved, rejected }

/// Approvals screen – shows tasks pending approval.
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  int _tabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksCubit>().getApprovalPendingTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  ApprovalFilter get _filter => ApprovalFilter.values[_tabIndex];

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<TasksCubit>().getApprovalPendingTasks(
            search: value.trim(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: BlocConsumer<TasksCubit, TasksState>(
          listenWhen: (prev, curr) =>
              prev.approveTaskUIState?.status !=
                  curr.approveTaskUIState?.status ||
              prev.approvalPendingTasksUIState?.status !=
                  curr.approvalPendingTasksUIState?.status,
          listener: (context, state) {
            // Handle approve action result
            if (state.approveTaskUIState?.status == Status.SUCCESS) {
              ToastMessages.success(
                message: state.approveTaskUIState?.data?.message ??
                    'Task approved successfully!',
              );
              context.read<TasksCubit>().resetApproveTaskState();
              // Refresh the list
              context.read<TasksCubit>().getApprovalPendingTasks(
                    search: state.approvalPendingTasksSearchQuery,
                  );
            } else if (state.approveTaskUIState?.status == Status.ERROR) {
              ToastMessages.error(
                message: state.approveTaskUIState?.errorType?.getText(
                      context,
                    ) ??
                    'Failed to approve task.',
              );
              context.read<TasksCubit>().resetApproveTaskState();
            }

            // Handle list loading error
            if (state.approvalPendingTasksUIState?.status == Status.ERROR) {
              ToastMessages.error(
                message: state.approvalPendingTasksUIState?.errorType
                        ?.getText(context) ??
                    'Failed to load approval tasks.',
              );
            }
          },
          builder: (context, state) {
            final isLoading = state.approvalPendingTasksUIState?.status ==
                    Status.LOADING ||
                state.approvalPendingTasksUIState?.status == null ||
                state.approvalPendingTasksUIState?.status == Status.INITIAL;
            final tasks = state.approvalPendingTasksList;
            final pagination = state.approvalPendingTasksPagination;
            final isLoadingMore = state.isLoadingMoreApprovalTasks;

            // Filter tasks based on selected tab
            final filteredTasks = tasks.where((task) {
              final status = task.status?.toLowerCase() ?? '';
              switch (_filter) {
                case ApprovalFilter.pending:
                  return status != 'approved';
                case ApprovalFilter.approved:
                  return status == 'approved';
                case ApprovalFilter.rejected:
                  return status == 'rejected';
              }
            }).toList();

            final totalPending = tasks
                .where(
                  (t) =>
                      t.status?.toLowerCase() == 'pending' ||
                      t.status?.toLowerCase() == 'ongoing',
                )
                .length;

            return Column(
              children: <Widget>[
                const AppGradientHeader(
                  title: 'Approvals',
                  eyebrow: 'TEAM',
                  leading: AppBackButton(),
                  actions: <Widget>[AppAvatar(initials: 'AB')],
                ),
                // ---- Search Bar ----
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
                // ---- Tabs ----
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  child: AppSegmentedTabs(
                    options: const ['Pending', 'Approved', 'Rejected'],
                    selectedIndex: _tabIndex,
                    onChanged: (int index) =>
                        setState(() => _tabIndex = index),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // ---- Content ----
                Expanded(
                  child: isLoading && tasks.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.red,
                            ),
                          ),
                        )
                      : filteredTasks.isEmpty
                          ? ApprovalsEmptyState(filter: _filter)
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(
                                      left: AppSpacing.gutter,
                                      right: AppSpacing.gutter,
                                      bottom: AppSpacing.xs,
                                    ),
                                    itemCount: filteredTasks.length + 1,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      if (index == 0) {
                                        return ApprovalsCount(
                                          count: filteredTasks.length,
                                          pending: totalPending,
                                          filter: _filter,
                                        );
                                      }
                                      final task = filteredTasks[index - 1];
                                      return ApprovalTile(
                                        task: task,
                                        onApprove: () {
                                          context
                                              .read<TasksCubit>()
                                              .approveTask(task.id!);
                                        },
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
                                // ---- Pagination Bar ----
                                if (pagination != null &&
                                    (pagination.lastPage ?? 0) > 1)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: AppSpacing.gutter,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed:
                                              (pagination.hasPreviousPage &&
                                                      !isLoadingMore)
                                                  ? () => context
                                                      .read<TasksCubit>()
                                                      .goToApprovalPendingTasksPage(
                                                        pagination
                                                            .currentPage! -
                                                            1,
                                                      )
                                                  : null,
                                        ),
                                        Text(
                                          'Page ${pagination.currentPage} of ${pagination.lastPage}',
                                          style: context.type.body,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed:
                                              (pagination.hasNextPage &&
                                                      !isLoadingMore)
                                                  ? () => context
                                                      .read<TasksCubit>()
                                                      .goToApprovalPendingTasksPage(
                                                        pagination
                                                            .currentPage! +
                                                            1,
                                                      )
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Helper widgets (unchanged, but we keep them for completeness)
// ---------------------------------------------------------------------

class ApprovalsCount extends StatelessWidget {
  const ApprovalsCount({
    super.key,
    required this.count,
    required this.pending,
    required this.filter,
  });

  final int count;
  final int pending;
  final ApprovalFilter filter;

  @override
  Widget build(BuildContext context) {
    final String label = switch (filter) {
      ApprovalFilter.pending => '$count awaiting your decision',
      ApprovalFilter.approved => '$count approved requests',
      ApprovalFilter.rejected => '$count rejected requests',
    };

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
          Text(label, style: context.type.caption),
        ],
      ),
    );
  }
}

class ApprovalTile extends StatelessWidget {
  const ApprovalTile({
    super.key,
    required this.task,
    this.onApprove,
    this.onReject,
  });

  final Task task; // Using Task for now; adjust to ApprovalTaskItem if needed
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = task.status?.toLowerCase() != 'approved';

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
                    : task.status?.toLowerCase() == 'approved' ||
                            task.status?.toLowerCase() == 'completed'
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
                      task.title ?? 'Untitled',
                      style: context.type.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.description ?? '',
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
                          label: task.assignedUser?.name ?? 'Unassigned',
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
                        if (!isPending)
                          AppTag(
                            label: task.status?.toUpperCase() ?? 'UNKNOWN',
                            icon: task.status?.toLowerCase() == 'approved' ||
                                    task.status?.toLowerCase() == 'completed'
                                ? Icons.check_rounded
                                : Icons.close_rounded,
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
                  child: AppOutlineButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    onPressed: onReject,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
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

class ApprovalsEmptyState extends StatelessWidget {
  const ApprovalsEmptyState({super.key, required this.filter});

  final ApprovalFilter filter;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String message) = switch (filter) {
      ApprovalFilter.pending => (
          Icons.verified_outlined,
          'Nothing to approve',
          'Every request has been dealt with. Nice work.',
        ),
      ApprovalFilter.approved => (
          Icons.check_circle_outline_rounded,
          'No approved requests',
          'Requests you approve will be listed here.',
        ),
      ApprovalFilter.rejected => (
          Icons.cancel_outlined,
          'No rejected requests',
          'Requests you turn down will be listed here.',
        ),
    };

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
              child: Icon(icon, size: 32, color: AppColors.red),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: context.type.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: context.type.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}