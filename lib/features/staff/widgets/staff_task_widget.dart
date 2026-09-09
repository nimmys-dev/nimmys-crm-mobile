import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/duties/cubit/tasks_cubit.dart';
import 'package:nimmys_crm/features/staff/cubit/staff/staff_cubit.dart';
import 'package:nimmys_crm/features/staff/model/staff_list_model.dart';
import 'package:nimmys_crm/shared/widgets/app_search_field.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';
import 'package:nimmys_crm/shared/widgets/app_select_field.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

class StaffTasksSection extends StatefulWidget {
  const StaffTasksSection({
    super.key,
    required this.staffId,
    required this.staffList,
  });

  final int staffId;
  final List<StaffListItem> staffList;

  @override
  State<StaffTasksSection> createState() => _StaffTasksSectionState();
}

class _StaffTasksSectionState extends State<StaffTasksSection> {
  final TextEditingController _searchController = TextEditingController();
  Set<int> _selectedTaskIds = {};
  Timer? _debounce;
  bool _isSelectingAll = false;
  bool _selectAllMode = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadTasks() {
    context.read<TasksCubit>().getTasksByStaffId(
      staffId: widget.staffId,
      refresh: true,
      search: _searchController.text.trim(),
      status: null,
    );
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<TasksCubit>().getTasksByStaffId(
        staffId: widget.staffId,
        refresh: true,
        search: query.trim(),
        status: null,
      );
      if (mounted) {
        setState(() {
          _selectedTaskIds.clear();
          _selectAllMode = false;
        });
      }
    });
  }

  // -------------------------------------------------------------------------
  // Select All
  // -------------------------------------------------------------------------

  Future<void> _selectall_tasks() async {
    final cubit = context.read<TasksCubit>();
    if (_isSelectingAll) return;

    setState(() => _isSelectingAll = true);

    try {
      // Load first page
      await cubit.getTasksByStaffId(
        staffId: widget.staffId,
        refresh: false,
        search: _searchController.text.trim(),
        status: null,
      );

      // Load all remaining pages
      bool hasMore = cubit.state.tasksByStaffIdPagination?.hasNextPage ?? false;
      while (hasMore) {
        await cubit.loadMoreTasksByStaffId(staffId: widget.staffId);
        hasMore = cubit.state.tasksByStaffIdPagination?.hasNextPage ?? false;
      }

      // Select all IDs from the complete list
      final allIds = cubit.state.tasksByStaffIdList
          .where((t) => t.id != null)
          .map((t) => t.id!)
          .toSet();

      if (mounted) {
        setState(() {
          _selectedTaskIds = allIds;
          _selectAllMode = true;
          _isSelectingAll = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSelectingAll = false);
        ToastMessages.error(message: 'Failed to select all tasks.');
      }
    }
  }

  void _toggleTask(int id) {
    setState(() {
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
      } else {
        _selectedTaskIds.add(id);
      }
      if (_selectAllMode) _selectAllMode = false;
    });
  }

  void _toggleAll(bool? checked) {
    if (checked == true) {
      _selectall_tasks();
    } else {
      setState(() {
        _selectedTaskIds.clear();
        _selectAllMode = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Pagination (manual buttons)
  // -------------------------------------------------------------------------

  Future<void> _goToPreviousPage() async {
    final cubit = context.read<TasksCubit>();
    final pagination = cubit.state.tasksByStaffIdPagination;
    if (pagination == null) return;

    final currentPage = pagination.currentPage ?? 1;
    if (currentPage <= 1) return;

    await cubit.goToTasksByStaffIdPage(
      staffId: widget.staffId,
      page: currentPage - 1,
    );

    if (mounted) {
      setState(() {
        _selectedTaskIds.clear();
        _selectAllMode = false;
      });
    }
  }

  Future<void> _goToNextPage() async {
    final cubit = context.read<TasksCubit>();
    final pagination = cubit.state.tasksByStaffIdPagination;
    if (pagination == null || !pagination.hasNextPage) return;

    final nextPage = pagination.nextPage;
    await cubit.goToTasksByStaffIdPage(staffId: widget.staffId, page: nextPage);

    if (mounted) {
      setState(() {
        _selectedTaskIds.clear();
        _selectAllMode = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Transfer
  // -------------------------------------------------------------------------

  void _showTransferSheet() {
    if (_selectedTaskIds.isEmpty) {
      ToastMessages.error(message: 'No tasks selected.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TransferTasksSheet(
        staffList: widget.staffList,
        selectedCount: _selectedTaskIds.length,
        totalCount: context.read<TasksCubit>().state.tasksByStaffIdList.length,
        onTransfer: (targetStaffId, transferAll) async {
          final staffCubit = context.read<StaffCubit>();
          final tasksCubit = context.read<TasksCubit>();

          final List<int> taskIds = transferAll
              ? tasksCubit.state.tasksByStaffIdList
                    .where((t) => t.id != null)
                    .map((t) => t.id!)
                    .toList()
              : _selectedTaskIds.toList();

          await staffCubit.reassignTasks(
            taskIds: taskIds,
            assignedTo: targetStaffId,
          );

          if (mounted) {
            _loadTasks();
            setState(() {
              _selectedTaskIds.clear();
              _selectAllMode = false;
            });
          }
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // TasksCubit listener for errors
        BlocListener<TasksCubit, TasksState>(
          listenWhen: (prev, curr) =>
              prev.tasksByStaffIdUIState?.status !=
              curr.tasksByStaffIdUIState?.status,
          listener: (context, state) {
            if (state.tasksByStaffIdUIState?.status == Status.ERROR) {
              ToastMessages.error(
                message:
                    state.tasksByStaffIdUIState?.errorType?.getText(context) ??
                    'Failed to load tasks',
              );
            }
          },
        ),
        // StaffCubit listener for reassign results
        BlocListener<StaffCubit, StaffState>(
          listenWhen: (prev, curr) =>
              prev.reassignTasksUIState?.status !=
              curr.reassignTasksUIState?.status,
          listener: (context, state) {
            if (state.reassignTasksUIState?.status == Status.SUCCESS) {
              ToastMessages.success(
                message:
                    state.reassignTasksUIState?.data?.message ??
                    'Tasks reassigned successfully!',
              );
              context.read<StaffCubit>().resetReassignTasksState();
              _loadTasks();
            } else if (state.reassignTasksUIState?.status == Status.ERROR) {
              ToastMessages.error(
                message:
                    state.reassignTasksUIState?.errorType?.getText(context) ??
                    'Failed to reassign tasks.',
              );
              context.read<StaffCubit>().resetReassignTasksState();
            }
          },
        ),
      ],
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          final tasks = state.tasksByStaffIdList;
          final pagination = state.tasksByStaffIdPagination;
          final isLoading =
              state.tasksByStaffIdUIState?.status == Status.LOADING ||
              state.tasksByStaffIdUIState?.status == null ||
              state.tasksByStaffIdUIState?.status == Status.INITIAL;

          final currentPage = pagination?.currentPage ?? 1;
          final hasPrevious = currentPage > 1;
          final hasNext = pagination?.hasNextPage ?? false;
          final isPaginationLoading =
              state.tasksByStaffIdUIState?.status == Status.LOADING;

          // Clear selection when list changes (e.g., new search or page)
          if (_selectedTaskIds.isNotEmpty &&
              _selectedTaskIds.any((id) => !tasks.any((t) => t.id == id))) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedTaskIds.clear();
                  _selectAllMode = false;
                });
              }
            });
          }

          return AppSectionCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSectionHeader(title: 'Tasks'),
                const SizedBox(height: AppSpacing.xs),

                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AppSearchField(
                    hint: 'Search tasks...',
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Select All + Transfer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value:
                                _selectAllMode ||
                                (tasks.isNotEmpty &&
                                    _selectedTaskIds.length == tasks.length),
                            onChanged: _isSelectingAll ? null : _toggleAll,
                            activeColor: AppColors.red,
                          ),
                          if (_isSelectingAll) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Loading all tasks...',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.palette.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else
                            const Text(
                              'Select All',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _selectedTaskIds.isEmpty
                                  ? null
                                  : _showTransferSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTaskIds.isEmpty
                                      ? context.palette.surfaceAlt
                                      : context.palette.redWash,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedTaskIds.isEmpty
                                        ? context.palette.line
                                        : context.palette.redBorder,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.share_rounded,
                                      size: 16,
                                      color: _selectedTaskIds.isEmpty
                                          ? context.palette.faint
                                          : AppColors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Transfer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: _selectedTaskIds.isEmpty
                                            ? context.palette.faint
                                            : AppColors.red,
                                      ),
                                    ),
                                    if (_selectedTaskIds.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.red,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${_selectedTaskIds.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 8),

                // Task list
                if (isLoading && tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.red,
                        ),
                      ),
                    ),
                  )
                else if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No tasks assigned.',
                      style: context.type.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: tasks.map((task) {
                      final id = task.id!;
                      final isSelected = _selectedTaskIds.contains(id);
                      return CheckboxListTile(
                        key: ValueKey('task_$id'),
                        title: Text(task.title ?? 'Task'),
                        subtitle: Text(
                          'Due: ${_formatDate(task.createdAt)} | '
                          'By: ${task.assignedUser?.name ?? '—'}',
                        ),
                        value: isSelected,
                        onChanged: (_) => _toggleTask(id),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 8),

                // Pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Previous page',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: !hasPrevious || isPaginationLoading
                          ? null
                          : _goToPreviousPage,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Page $currentPage',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next page',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: !hasNext || isPaginationLoading
                          ? null
                          : _goToNextPage,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Date formatter
  // -------------------------------------------------------------------------

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      final day = date.day;
      final suffix = _ordinalSuffix(day);
      final month = _monthName(date.month);
      return '$day$suffix $month ${date.year}';
    } catch (_) {
      return isoString;
    }
  }

  String _ordinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

// -----------------------------------------------------------------------------
// Transfer Bottom Sheet (unchanged)
// -----------------------------------------------------------------------------

class _TransferTasksSheet extends StatefulWidget {
  const _TransferTasksSheet({
    required this.staffList,
    required this.selectedCount,
    required this.totalCount,
    required this.onTransfer,
  });

  final List<StaffListItem> staffList;
  final int selectedCount;
  final int totalCount;
  final Future<void> Function(int targetStaffId, bool transferAll) onTransfer;

  @override
  State<_TransferTasksSheet> createState() => __TransferTasksSheetState();
}

class __TransferTasksSheetState extends State<_TransferTasksSheet> {
  StaffListItem? _selectedStaff;
  bool _transferAll = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final staffNames = widget.staffList
        .where((s) => s.name != null && s.name!.isNotEmpty)
        .map((s) => s.name!)
        .toList();

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.faint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Transfer Tasks To',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AppSelectField(
              hint: 'Select staff to transfer to',
              sheetTitle: 'Transfer to',
              icon: Icons.person_outline,
              options: staffNames,
              value: _selectedStaff?.name,
              onChanged: (name) {
                final matched = widget.staffList.firstWhere(
                  (s) => s.name == name,
                  orElse: () => widget.staffList.first,
                );
                setState(() => _selectedStaff = matched);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _transferAll,
                  onChanged: (v) => setState(() => _transferAll = v ?? false),
                  activeColor: AppColors.red,
                ),
                Expanded(
                  child: Text(
                    _transferAll
                        ? 'Transfer all ${widget.totalCount} tasks'
                        : 'Transfer only ${widget.selectedCount} selected tasks',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _selectedStaff == null
                      ? null
                      : () {
                          final targetId = _selectedStaff!.id;
                          if (targetId == null) return;
                          Navigator.pop(context);
                          widget.onTransfer(targetId, _transferAll);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Transfer'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
