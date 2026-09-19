import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:nimmys_crm/features/duties/cubit/tasks_cubit.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

/// Shows the same complete-task dialog used on the task details screen.
///
/// Returns `true` when the task was marked complete successfully.
Future<bool> showCompleteTaskDialog(
  BuildContext context, {
  required int taskId,
}) async {
  final bool? completed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _CompleteTaskDialog(taskId: taskId);
    },
  );

  if (completed != true) return false;
  if (!context.mounted) return true;

  ToastMessages.success(message: 'Task marked as completed!');
  context.read<TasksCubit>().resetCompleteTaskState();
  unawaited(context.read<DashboardCubit>().refreshDashboardTasks());
  return true;
}

class _CompleteTaskDialog extends StatefulWidget {
  const _CompleteTaskDialog({required this.taskId});

  final int taskId;

  @override
  State<_CompleteTaskDialog> createState() => _CompleteTaskDialogState();
}

class _CompleteTaskDialogState extends State<_CompleteTaskDialog> {
  final TextEditingController _remarksController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final String remarks = _remarksController.text.trim();
    final TasksCubit cubit = context.read<TasksCubit>();

    await cubit.completeTask(
      widget.taskId,
      remarks: remarks.isEmpty ? null : remarks,
    );

    if (!mounted) return;

    final Status? status = cubit.state.completeTaskUIState?.status;
    if (status == Status.SUCCESS) {
      // Pop first so list/cubit refreshes do not rebuild this dialog.
      Navigator.of(context).pop(true);
      return;
    }

    final String message =
        cubit.state.completeTaskUIState?.errorType?.getText(context) ??
        'Failed to complete task.';
    ToastMessages.error(message: message);
    cubit.resetCompleteTaskState();
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark as Complete'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to mark this task as completed?'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _remarksController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                hintText: 'Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}
