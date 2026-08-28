import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/duties/cubit/tasks_cubit.dart';
import 'package:nimmys_crm/features/duties/create_task_screen.dart';
import 'package:nimmys_crm/features/duties/model/task_details_model.dart';
import 'package:nimmys_crm/features/duties/widgets/task_details_shimmer.dart';
import 'package:nimmys_crm/helpers/date_helper.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final int taskId;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksCubit>().getTaskDetails(widget.taskId);
    });
  }

  @override
  void dispose() {
    context.read<TasksCubit>().resetTaskDetailsState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.canvas,
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          final uiState = state.taskDetailsUIState;

          if (uiState?.status == Status.LOADING) {
            return const TaskDetailsLoadingView();
          }

          if (uiState?.status == Status.ERROR || uiState?.data == null) {
            return _ErrorView(
              onRetry: () =>
                  context.read<TasksCubit>().getTaskDetails(widget.taskId),
            );
          }

          final TaskDetailsResponse response = uiState!.data!;
          final TaskDetail? taskDetail = response.data;

          if (taskDetail == null) {
            return _ErrorView(
              onRetry: () =>
                  context.read<TasksCubit>().getTaskDetails(widget.taskId),
            );
          }

          return _TaskDetailsContent(task: taskDetail);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / Error Views
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.error_outline, size: 48, color: context.palette.muted),
          const SizedBox(height: AppSpacing.sm),
          Text('Could not load task', style: context.type.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Please check your connection and try again.',
            style: context.type.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main Content
// ---------------------------------------------------------------------------

class _TaskDetailsContent extends StatefulWidget {
  const _TaskDetailsContent({required this.task});

  final TaskDetail task;

  @override
  State<_TaskDetailsContent> createState() => _TaskDetailsContentState();
}

class _TaskDetailsContentState extends State<_TaskDetailsContent> {
  void _showCompleteDialog(BuildContext context, int taskId) {
    final TextEditingController remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to mark this task as completed?'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                hintText: 'Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          BlocConsumer<TasksCubit, TasksState>(
            listenWhen: (prev, curr) =>
                prev.completeTaskUIState?.status !=
                curr.completeTaskUIState?.status,
            listener: (context, state) {
              final uiState = state.completeTaskUIState;
              if (uiState?.status == Status.SUCCESS) {
                ToastMessages.success(message: 'Task marked as completed!');
                context.read<TasksCubit>().resetCompleteTaskState();
                // Refresh task details
                context.read<TasksCubit>().getTaskDetails(taskId);
                Navigator.pop(ctx); // close dialog
              } else if (uiState?.status == Status.ERROR) {
                ToastMessages.error(
                  message:
                      uiState?.errorType?.getText(context) ??
                      'Failed to complete task.',
                );
                context.read<TasksCubit>().resetCompleteTaskState();
                // Keep dialog open on error
              }
            },
            builder: (context, state) {
              final isLoading =
                  state.completeTaskUIState?.status == Status.LOADING;
              return ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        final remarks = remarksController.text.trim();
                        context.read<TasksCubit>().completeTask(
                          taskId,
                          remarks: remarks.isEmpty ? null : remarks,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppGradientHeader(
          // title: task.title ?? 'Task Details',
          eyebrow: 'TASK DETAILS',
          leading: const AppBackButton(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.gutter,
              right: AppSpacing.gutter,
              top: AppSpacing.md,
              bottom: AppSpacing.xl,
            ),
            children: <Widget>[
              StatusCard(task: widget.task),
              const SizedBox(height: AppSpacing.sm),
              AssignmentCard(task: widget.task),
              const SizedBox(height: AppSpacing.sm),
              ScheduleCard(task: widget.task),
              if (widget.task.description?.isNotEmpty ?? false) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                DescriptionCard(task: widget.task),
              ],
              // ---- Action Buttons ----
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  // Complete button
                  if (widget.task.status?.toLowerCase() != 'completed') ...[
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Complete',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: () =>
                            _showCompleteDialog(context, widget.task.id!),
                        isLoading:
                            context
                                .watch<TasksCubit>()
                                .state
                                .completeTaskUIState
                                ?.status ==
                            Status.LOADING,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      onPressed: widget.task.id == null
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CreateTaskScreen(taskToEdit: widget.task),
                                ),
                              );
                              if (context.mounted) {
                                context.read<TasksCubit>().getTaskDetails(
                                  widget.task.id!,
                                );
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      onPressed: () {
                        // Implement delete confirmation (optional)
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual Section Cards
// ---------------------------------------------------------------------------

class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final status = task.status ?? 'Unknown';

    final Color statusColor = switch (status.toLowerCase()) {
      'completed' => AppColors.green,
      'ongoing' => AppColors.blue,
      'pending' => AppColors.orange,
      'upcoming' => AppColors.purple,
      _ => AppColors.muted,
    };

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Task Details", style: context.type.caption),

          const SizedBox(height: AppSpacing.xs),
          Text(task.description ?? ""),
          const SizedBox(height: AppSpacing.xs),
          Text('Status', style: context.type.caption),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: context.type.label.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (task.repeatMode == true) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                AppTag(
                  label: 'REPEATS',
                  icon: Icons.autorenew_rounded,
                  isAccent: false,
                ),
              ],
            ],
          ),
          if (task.remarks != null && task.remarks!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text('Remarks:', style: context.type.caption),
            const SizedBox(height: 2),
            Text(task.remarks!, style: context.type.body),
          ],
        ],
      ),
    );
  }
}

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({super.key, required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final assignee = task.assignedUser;
    final approver = task.approvedBy;
    print('approver ${approver?.id}${approver?.name}');
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Assignment', style: context.type.caption),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Assigned to',
            value: assignee?.name ?? 'Unassigned',
          ),
          const SizedBox(height: AppSpacing.xs),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Approved by',
            value: task.approvedBy?.name ?? 'Not set',
          ),
        ],
      ),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({super.key, required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final type = task.taskType ?? 'one-time';
    final List<Widget> rows = <Widget>[];

    rows.add(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Task Type',
          value: type.toUpperCase(),
        ),
      ),
    );

    switch (type) {
      case 'daily':
        rows.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Time',
              value:
                  "${DateTimeHelper.get12HourTimeFormat(task.startTime)} - ${DateTimeHelper.get12HourTimeFormat(task.endTime)}",
            ),
          ),
        );
        break;
      case 'weekly':
        rows.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _InfoRow(
              icon: Icons.date_range_outlined,
              label: 'Days',
              value: '${task.weekStartDay ?? '—'} to ${task.weekEndDay ?? '—'}',
            ),
          ),
        );
        break;
      case 'monthly':
        rows.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _InfoRow(
              icon: Icons.date_range_outlined,
              label: 'Date Range',
              value:
                  '${DateTimeHelper.getFormattedDateWithOrdinal('${task.monthlyStartDate}')} to ${DateTimeHelper.getFormattedDateWithOrdinal('${task.monthlyEndDate}')}',
            ),
          ),
        );
        break;
      case 'quarterly':
        if (task.quarters != null && task.quarters!.isNotEmpty) {
          for (final quarter in task.quarters!) {
            rows.add(
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _InfoRow(
                  icon: Icons.event_note_outlined,
                  label: '${quarter.quarter?.toUpperCase()}',
                  value:
                      '${quarter.startDate ?? '—'} to ${quarter.endDate ?? '—'}',
                ),
              ),
            );
          }
        } else {
          rows.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _InfoRow(
                icon: Icons.date_range_outlined,
                label: 'Quarter',
                value: task.quarter ?? '—',
              ),
            ),
          );
        }
        break;
      case 'yearly':
        rows.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _InfoRow(
              icon: Icons.date_range_outlined,
              label: 'Yearly Range',
              value:
                  '${DateTimeHelper.getFormattedDateWithOrdinal('${task.yearlyStartDate}')}  to ${DateTimeHelper.getFormattedDateWithOrdinal('${task.yearlyEndDate}')}',
            ),
          ),
        );
        break;
      default:
        rows.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: const _InfoRow(
              icon: Icons.info_outline_rounded,
              label: 'Schedule',
              value: 'One-time task',
            ),
          ),
        );
    }

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}

class DescriptionCard extends StatelessWidget {
  const DescriptionCard({super.key, required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Description', style: context.type.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(task.description!, style: context.type.body),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: context.palette.muted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: context.type.caption),
              const SizedBox(height: 2),
              Text(value, style: context.type.body),
            ],
          ),
        ),
      ],
    );
  }
}
