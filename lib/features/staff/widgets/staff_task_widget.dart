import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/features/staff/model/staff_list_model.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';
import 'package:nimmys_crm/shared/widgets/app_select_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/staff/cubit/staff/staff_cubit.dart';
import 'package:nimmys_crm/shared/widgets/app_text_field.dart';
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
    context.read<StaffCubit>().getMyTasks(refresh: true);
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<StaffCubit>().getMyTasks(search: query.trim());
    });
  }

  void _toggleTask(int id) {
    setState(() {
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
      } else {
        _selectedTaskIds.add(id);
      }
    });
  }

  void _toggleAll(bool? checked) {
    final tasks = context.read<StaffCubit>().state.myTasksList;
    setState(() {
      if (checked == true) {
        _selectedTaskIds = tasks.map((t) => t.id!).toSet();
      } else {
        _selectedTaskIds.clear();
      }
    });
  }

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
        totalCount: context.read<StaffCubit>().state.myTasksList.length,
        onTransfer: (targetStaffId, transferAll) async {
          // --- REAL API CALL ---
          final cubit = context.read<StaffCubit>();
          final taskIds = transferAll
              ? cubit.state.myTasksList.map((t) => t.id!).toList()
              : _selectedTaskIds.toList();

          await cubit.reassignTasks(
            taskIds: taskIds,
            assignedTo: targetStaffId,
          );

          // Check result via cubit listener or manually check state after a delay.
          // For simplicity, we'll refresh and clear selection, and let the cubit listener handle errors.
          if (mounted) {
            _loadTasks();
            setState(() => _selectedTaskIds.clear());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StaffCubit, StaffState>(
      listenWhen: (prev, curr) =>
          prev.myTasksListUIState?.status != curr.myTasksListUIState?.status ||
          prev.reassignTasksUIState?.status !=
              curr.reassignTasksUIState?.status,
      listener: (context, state) {
        // Handle staff tasks error
        if (state.myTasksListUIState?.status == Status.ERROR) {
          ToastMessages.error(
            message:
                state.myTasksListUIState?.errorType?.getText(context) ??
                'Failed to load tasks',
          );
        }
        // Handle reassign result
        if (state.reassignTasksUIState?.status == Status.SUCCESS) {
          ToastMessages.success(
            message:
                state.reassignTasksUIState?.data?.message ??
                'Tasks reassigned successfully!',
          );
          context.read<StaffCubit>().resetReassignTasksState();
          _loadTasks(); // refresh list
        } else if (state.reassignTasksUIState?.status == Status.ERROR) {
          ToastMessages.error(
            message:
                state.reassignTasksUIState?.errorType?.getText(context) ??
                'Failed to reassign tasks.',
          );
          context.read<StaffCubit>().resetReassignTasksState();
        }
      },
      builder: (context, state) {
        final tasks = state.myTasksList;
        final pagination = state.myTasksPagination;
        final isLoading =
            state.myTasksListUIState?.status == Status.LOADING ||
            state.myTasksListUIState?.status == null ||
            state.myTasksListUIState?.status == Status.INITIAL;
        final currentPage = pagination?.currentPage ?? 1;
        final hasNext = pagination?.hasNextPage ?? false;

        // Clear selection when task list changes (e.g., new search)
        if (_selectedTaskIds.isNotEmpty &&
            _selectedTaskIds.any((id) => !tasks.any((t) => t.id == id))) {
          setState(() => _selectedTaskIds.clear());
        }

        return AppSectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSectionHeader(title: 'Tasks'),
              const SizedBox(height: AppSpacing.xs),

              // ---- Search Bar ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppTextField(
                  hint: 'Search tasks...',
                  controller: _searchController,
                  icon: Icons.search_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // ---- "Select All" + Transfer row ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value:
                              tasks.isNotEmpty &&
                              _selectedTaskIds.length == tasks.length,
                          onChanged: _toggleAll,
                          activeColor: AppColors.red,
                        ),
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
                                        borderRadius: BorderRadius.circular(12),
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

              // ---- Task list ----
              if (isLoading && tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
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
                ...tasks.map(
                  (task) => CheckboxListTile(
                    title: Text(task.title ?? 'Task'),
                    subtitle: Text(
                      'Due: ${_formatDate(task.createdAt ?? task.createdAt)} | By: ${task.createdAt ?? '—'}',
                    ),
                    value: _selectedTaskIds.contains(task.id),
                    onChanged: (checked) => _toggleTask(task.id!),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),

              const SizedBox(height: 8),

              // ---- Pagination controls ----
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 1
                        ? () {
                            context.read<StaffCubit>().getMyTasks();
                          }
                        : null,
                  ),
                  Text('Page $currentPage'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: hasNext
                        ? () {
                            context.read<StaffCubit>().loadMoreMyTasks();
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  // ---------- Date formatter ----------
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

// ---------- Transfer bottom sheet (uses staff list) ----------
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
                setState(() {
                  _selectedStaff = matched;
                });
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
