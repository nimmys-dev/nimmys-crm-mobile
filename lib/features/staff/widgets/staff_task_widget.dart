import 'package:flutter/material.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/features/staff/model/staff_list_model.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';
import 'package:nimmys_crm/shared/widgets/app_select_field.dart';

/// A stateful widget that displays a paginated list of tasks with checkboxes,
/// and provides a transfer action to move selected (or all) tasks to another staff member.
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
  static const int _perPage = 10;
  List<Map<String, dynamic>> _tasks = [];
  int _page = 0;
  bool _hasMore = false;
  Set<int> _selectedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadTasks(0);
  }

  Future<void> _loadTasks(int page) async {
    // Simulate API – replace with real call
    final totalTasks = 25;
    final start = page * _perPage;
    final end = (start + _perPage).clamp(0, totalTasks);
    final List<Map<String, dynamic>> newTasks = [];
    for (int i = start; i < end; i++) {
      newTasks.add({
        'id': i,
        'description': 'Task ${i + 1}',
        'due_date': DateTime(2026, 8, (i % 28) + 1).toIso8601String(),
        'assigned_by': 'Admin',
      });
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _tasks = newTasks;
        _page = page;
        _hasMore = end < totalTasks;
        _selectedTaskIds.clear();
      });
    }
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
    if (checked == true) {
      setState(() {
        _selectedTaskIds = _tasks.map((t) => t['id'] as int).toSet();
      });
    } else {
      setState(() {
        _selectedTaskIds.clear();
      });
    }
  }

  void _showTransferSheet() {
    if (_selectedTaskIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No tasks selected.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TransferTasksSheet(
        staffList: widget.staffList, // use staff list
        selectedCount: _selectedTaskIds.length,
        totalCount: _tasks.length,
        onTransfer: (targetStaffId, transferAll) async {
          // Simulate API call – replace with real logic
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            _loadTasks(_page);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tasks transferred successfully!')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- "Select All" + Transfer button row ----
          const AppSectionHeader(title: 'Task'),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Left: Select All checkbox
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value:
                          _tasks.isNotEmpty &&
                          _selectedTaskIds.length == _tasks.length,
                      onChanged: _toggleAll,
                      activeColor: AppColors.red,
                    ),
                    const Text(
                      'Select All',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                // Right: Modern Transfer Chip
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
          if (_tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No tasks assigned.', style: context.type.bodyMuted),
            )
          else
            ..._tasks.map(
              (task) => CheckboxListTile(
                title: Text(task['description'] ?? 'Task'),
                subtitle: Text(
                  'Due: ${_formatDate(task['due_date'])} | By: ${task['assigned_by'] ?? '—'}',
                ),
                value: _selectedTaskIds.contains(task['id']),
                onChanged: (checked) => _toggleTask(task['id']),
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
                onPressed: _page > 0 ? () => _loadTasks(_page - 1) : null,
              ),
              Text('Page ${_page + 1}'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _hasMore ? () => _loadTasks(_page + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ---------- Date formatter (e.g., "24th Aug 2026") ----------
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
