import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../routing/app_route_name.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_segmented_tabs.dart';
import '../../shared/widgets/app_select_field.dart';
import 'domain/entities/duty_item.dart';

/// Duty list — today's, overdue and upcoming duties behind one set of tabs.
///
/// The dashboard's three duty tiles all land here, each opening on its own tab
/// via `?filter=`. One screen rather than three: see [DutyFilter].
///
/// DATA — the rows below are sample data. This project has no duties endpoint
/// yet (`ApiUrls` covers auth, profile and staff only), and the dashboard
/// counters this screen is opened from are hard-coded for the same reason. When
/// a duties API lands, replace [_allDuties] with a cubit following the staff
/// list; nothing else in this file has to change.
class DutyListScreen extends StatefulWidget {
  const DutyListScreen({super.key, this.initialFilter = DutyFilter.today});

  final DutyFilter initialFilter;

  @override
  State<DutyListScreen> createState() => _DutyListScreenState();
}

class _DutyListScreenState extends State<DutyListScreen> {
  /// Dated relative to today so the three tabs always partition correctly,
  /// however long after this was written the app is opened.
  static final List<DutyItem> _allDuties = <DutyItem>[
    DutyItem(
      title: 'Call back Sejun about the Sigma lens',
      detail: 'Confirm availability and share the revised quotation.',
      dueAt: _at(0, 10, 30),
      assignee: 'Abin Babu',
    ),
    DutyItem(
      title: 'Stock check — Sony bodies',
      detail: 'Verify the display units against the counter register.',
      dueAt: _at(0, 15, 0),
      assignee: 'Sijo',
    ),
    DutyItem(
      title: 'Send invoice to Madhu',
      detail: 'Mac Mini M4 order — invoice and warranty card.',
      dueAt: _at(0, 17, 45),
      assignee: 'Mathew Thomas',
    ),
    DutyItem(
      title: 'Service follow-up — Canon repair',
      detail: 'Workshop promised an update on the shutter replacement.',
      dueAt: _at(-1, 12, 0),
      assignee: 'Abin Babu',
    ),
    DutyItem(
      title: 'Submit weekly sales report',
      detail: 'Branch-wise numbers for the Ettumanoor and Hill Palace stores.',
      dueAt: _at(-3, 18, 0),
      assignee: 'Thomas John',
    ),
    DutyItem(
      title: 'Reconcile petty cash',
      detail: 'Closed last week — kept for the record.',
      dueAt: _at(-4, 19, 0),
      assignee: 'Sijo',
      isCompleted: true,
    ),
    DutyItem(
      title: 'Tripod stock arrival',
      detail: 'Receive and shelve the Manfrotto consignment.',
      dueAt: _at(1, 11, 0),
      assignee: 'Mathew Thomas',
    ),
    DutyItem(
      title: 'Quarterly stock audit',
      detail: 'Full count across both branches with the accounts team.',
      dueAt: _at(4, 9, 30),
      assignee: 'Thomas John',
    ),
  ];

  /// Sample timestamp [days] from today at [hour]:[minute].
  static DateTime _at(int days, int hour, int minute) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days, hour, minute);
  }

  final TextEditingController _searchController = TextEditingController();
  late DutyFilter _filter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Rows for the active tab, narrowed further by the search box. The search
  /// text is deliberately kept when the tab changes — it reads as a filter over
  /// the whole list, not a property of one tab.
  List<DutyItem> get _visibleDuties {
    final List<DutyItem> inWindow =
        _allDuties.where((DutyItem duty) => duty.matches(_filter)).toList()
          ..sort((DutyItem a, DutyItem b) => a.dueAt.compareTo(b.dueAt));

    final String needle = _query.trim().toLowerCase();
    if (needle.isEmpty) {
      return inWindow;
    }
    return inWindow.where((DutyItem duty) {
      return duty.title.toLowerCase().contains(needle) ||
          duty.detail.toLowerCase().contains(needle) ||
          duty.assignee.toLowerCase().contains(needle);
    }).toList();
  }

  int _countFor(DutyFilter filter) =>
      _allDuties.where((DutyItem duty) => duty.matches(filter)).length;

  @override
  Widget build(BuildContext context) {
    final List<DutyItem> duties = _visibleDuties;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: Column(
          children: <Widget>[
            AppGradientHeader(
              title: _filter.title,
              eyebrow: 'MY DUTIES',
              leading: const AppBackButton(),
              actions: const <Widget>[AppAvatar(initials: 'AB')],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.sm,
              ),
              child: Column(
                children: <Widget>[
                  AppSegmentedTabs(
                    options: DutyFilter.labels,
                    selectedIndex: DutyFilter.values.indexOf(_filter),
                    onChanged: (int index) =>
                        setState(() => _filter = DutyFilter.values[index]),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSearchField(
                    hint: 'Search duties, people…',
                    controller: _searchController,
                    onChanged: (String value) => setState(() => _query = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: duties.isEmpty
                  ? DutyEmptyState(filter: _filter, hasQuery: _query.isNotEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.gutter,
                        right: AppSpacing.gutter,
                        bottom: AppSpacing.xl,
                      ),
                      itemCount: duties.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return DutyListCount(
                            count: duties.length,
                            total: _countFor(_filter),
                          );
                        }
                        return DutyListTile(
                          duty: duties[index - 1],
                          filter: _filter,
                        );
                      },
                    ),
            ),
          ],
        ),
        // Same red compose affordance the follow-up list uses, pointing at the
        // duty form that already exists.
        floatingActionButton: DutyListFab(
          onPressed: () => context.push(AppRouteName.dutyAdd),
        ),
      ),
    );
  }
}

/// "3 of 3 duties" strip above the rows.
class DutyListCount extends StatelessWidget {
  const DutyListCount({super.key, required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final String label = count == total
        ? '$count dut${count == 1 ? 'y' : 'ies'}'
        : 'Showing $count of $total duties';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 2),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.fact_check_outlined,
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

/// One duty row.
class DutyListTile extends StatelessWidget {
  const DutyListTile({
    super.key,
    required this.duty,
    required this.filter,
    this.onTap,
  });

  final DutyItem duty;
  final DutyFilter filter;
  final VoidCallback? onTap;

  /// "10:30 AM" — 12-hour regardless of the device's 24-hour setting, matching
  /// `AppTimeField.format`.
  static String _time(DateTime value) {
    final int rawHour = value.hour % 12;
    final int hour = rawHour == 0 ? 12 : rawHour;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String period = value.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final int lateBy = duty.daysOverdue();
    final bool isOverdue = filter == DutyFilter.overdue && lateBy > 0;

    return AppSectionCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      accentBorder: isOverdue,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIconChip(
                icon: duty.isCompleted
                    ? Icons.check_circle_outline_rounded
                    : Icons.fact_check_outlined,
                size: 38,
                tone: isOverdue ? AppIconChipTone.red : AppIconChipTone.ink,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      duty.title,
                      style: context.type.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      duty.detail,
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
                          label: filter == DutyFilter.today
                              ? _time(duty.dueAt)
                              : AppDateField.format(duty.dueAt),
                          icon: Icons.schedule_rounded,
                          isAccent: isOverdue,
                        ),
                        if (isOverdue)
                          AppTag(
                            label: lateBy == 1
                                ? '1 day late'
                                : '$lateBy days late',
                            icon: Icons.error_outline_rounded,
                          ),
                        if (duty.isCompleted)
                          const AppTag(
                            label: 'DONE',
                            icon: Icons.check_rounded,
                            isAccent: false,
                          ),
                        AppTag(
                          label: duty.assignee,
                          icon: Icons.person_outline_rounded,
                          isAccent: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nothing in this window — which for "overdue" is good news, and is worded
/// that way rather than as a failure.
class DutyEmptyState extends StatelessWidget {
  const DutyEmptyState({
    super.key,
    required this.filter,
    required this.hasQuery,
  });

  final DutyFilter filter;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String title;
    final String message;

    if (hasQuery) {
      icon = Icons.search_off_rounded;
      title = 'No matching duties';
      message = 'Nothing in ${filter.label.toLowerCase()} matches that search.';
    } else {
      switch (filter) {
        case DutyFilter.today:
          icon = Icons.event_available_outlined;
          title = 'Nothing due today';
          message = 'You are all caught up. Enjoy the quiet.';
        case DutyFilter.overdue:
          icon = Icons.verified_outlined;
          title = 'No overdue duties';
          message = 'Everything assigned to you has been handled on time.';
        case DutyFilter.upcoming:
          icon = Icons.schedule_rounded;
          title = 'Nothing scheduled';
          message = 'No duties are booked beyond today yet.';
      }
    }

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

/// Red compose button, matching the follow-up list's.
class DutyListFab extends StatelessWidget {
  const DutyListFab({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
