import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/duties/cubit/tasks_cubit.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

/// Confirms and submits `POST /api/tasks/{id}/approve`.
///
/// Returns:
/// - `true` when approved successfully
/// - `false` when the API call failed
/// - `null` when the user cancelled without posting
Future<bool?> showApproveTaskDialog(
  BuildContext context, {
  required int taskId,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _ApproveTaskDialog(taskId: taskId);
    },
  );
}

class _ApproveTaskDialog extends StatefulWidget {
  const _ApproveTaskDialog({required this.taskId});

  final int taskId;

  @override
  State<_ApproveTaskDialog> createState() => _ApproveTaskDialogState();
}

class _ApproveTaskDialogState extends State<_ApproveTaskDialog> {
  bool _isSubmitting = false;

  Future<void> _confirm() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final TasksCubit cubit = context.read<TasksCubit>();
    await cubit.approveTask(widget.taskId);

    if (!mounted) return;

    final Status? status = cubit.state.approveTaskUIState?.status;
    if (status == Status.SUCCESS) {
      Navigator.of(context).pop(true);
      return;
    }

    final String message =
        cubit.state.approveTaskUIState?.errorType?.getText(context) ??
        'Failed to approve task.';
    ToastMessages.error(message: message);
    cubit.resetApproveTaskState();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approve Task'),
      content: const Text('Are you sure you want to approve this task?'),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
              : const Text('Approve'),
        ),
      ],
    );
  }
}
